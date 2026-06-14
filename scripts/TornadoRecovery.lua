---@class TornadoRecovery
---@description Intercepts vehicle resets to charge an Emergency Recovery fee for tornado-damaged vehicles.

TornadoRecovery = {}

-- ============================================================================
-- Configuration & Pricing
-- ============================================================================
TornadoRecovery.BASE_TOW_FEE = 1500        
TornadoRecovery.COST_STRUCTURAL = 500      -- Glass, mirrors, pipes, etc.
TornadoRecovery.COST_TRASH = 10            -- Decals, stickers, hoses, etc.
TornadoRecovery.ENGINE_REPAIR_COST = 3500  

TornadoRecovery.isHooked = false

function TornadoRecovery:installHooks()
    if self.isHooked then return end

    if VehicleSystem ~= nil and VehicleSystem.resetVehicle ~= nil then
        local oldResetVehicle = VehicleSystem.resetVehicle
        
        VehicleSystem.resetVehicle = function(systemSelf, vehicle, ...)
            if g_server ~= nil and vehicle ~= nil then
                TornadoRecovery:processRecovery(vehicle)
            end
            return oldResetVehicle(systemSelf, vehicle, ...)
        end
        
        if TornadoDebug then TornadoDebug:log("RECOVERY", "Successfully hooked into VehicleSystem:resetVehicle") end
        self.isHooked = true
    end
end

function TornadoRecovery:processRecovery(vehicle)
    -- [THE GATEKEEPER] Master Opt-In Check
    if not (TornadoSettings and TornadoSettings.recoveryEnabled) then
        return 
    end

    if vehicle.rootNode == nil then return end

    -- 1. Check if the vehicle is currently on our destroyed list
    local destructionData = TornadoDestruction._destroyedObjects[vehicle.rootNode]
    if destructionData == nil then return end 

    -- 2. Itemized Damage Calculation (The Text Scanner)
    local trashCount = 0
    local structCount = 0
    
    if destructionData.nodes then
        for _, nodeInfo in ipairs(destructionData.nodes) do
            local isTrash = false
            local nameLower = string.lower(nodeInfo.name)
            
            -- Scan the name against the Destruction dictionary
            for _, trashKey in ipairs(TornadoDestruction.TRASH_KEYWORDS) do
                if string.find(nameLower, trashKey, 1, true) then
                    isTrash = true
                    break
                end
            end
            
            if isTrash then trashCount = trashCount + 1 else structCount = structCount + 1 end
        end
    end
    
    -- Native Engine Damage Check (Physics script maxes damage at 1.0)
    local isEngineDead = false
    if vehicle.getDamageAmount and vehicle:getDamageAmount() >= 1.0 then
        isEngineDead = true
    end
    
    -- 3. Calculate the Itemized Bill
    local totalCost = self.BASE_TOW_FEE + (structCount * self.COST_STRUCTURAL) + (trashCount * self.COST_TRASH)
    if isEngineDead then
        totalCost = totalCost + self.ENGINE_REPAIR_COST
    end

    local farmId = vehicle:getOwnerFarmId()
    if farmId == nil or farmId == 0 then return end 

    -- 4. Deduct the Money 
    g_currentMission:addMoney(-totalCost, farmId, MoneyType.VEHICLE_REPAIR, true, true)

    -- 5. Notify the Player
    local msg = string.format("EMERGENCY TOW: Billed $%d (Base: $%d | Struct: %dx | Trash: %dx)", 
                                totalCost, self.BASE_TOW_FEE, structCount, trashCount)
    
    if isEngineDead then msg = msg .. " + Engine Overhaul" end
    g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, msg)
    
    if TornadoDebug then 
        TornadoDebug:log("RECOVERY", string.format("Charged Farm %d exactly $%d for resetting %s", farmId, totalCost, destructionData.filename))
    end

    -- 6. Clean up the memory so they don't get charged again
    TornadoDestruction._destroyedObjects[vehicle.rootNode] = nil
end

function TornadoRecovery:deleteMap()
    self.isHooked = false
end

return TornadoRecovery