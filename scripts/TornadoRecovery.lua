---@class TornadoRecovery
---@description Intercepts vehicle resets to charge an Emergency Recovery fee for tornado-damaged vehicles.

TornadoRecovery = {}

-- ============================================================================
-- Configuration & Pricing
-- ============================================================================
TornadoRecovery.BASE_TOW_FEE = 1500        
TornadoRecovery.COST_STRUCTURAL = 500      
TornadoRecovery.COST_TRASH = 10            
TornadoRecovery.ENGINE_REPAIR_COST = 3500  

TornadoRecovery.isHooked = false

function TornadoRecovery:installHooks()
    if self.isHooked then return end

    -- [THE GOLDEN HOOK] 
    -- Derived directly from ResetVehicleEvent.lua. We hook the native Vehicle class!
    if Vehicle ~= nil and Vehicle.reset ~= nil then
        local oldVehicleReset = Vehicle.reset
        
        Vehicle.reset = function(vehicleSelf, clearFarmId, callback, connection)
            -- Only the server should handle the billing logic
            if g_server ~= nil then
                TornadoRecovery:processRecovery(vehicleSelf)
            end
            
            -- Continue with the engine's normal reset execution
            return oldVehicleReset(vehicleSelf, clearFarmId, callback, connection)
        end
        
        print("TornadoRecovery: SUCCESS - Hooked directly into Vehicle class!")
        self.isHooked = true
    else
        print("TORNADO RECOVERY CRITICAL ERROR: Could not find Vehicle class to hook!")
    end
end

function TornadoRecovery:processRecovery(vehicle)
    if TornadoDebug and TornadoDebug.verboseMode then
        TornadoDebug:log("RECOVERY", "TRACE: Vehicle reset intercepted for -> " .. tostring(vehicle.configFileName))
    end

    if not (TornadoSettings and TornadoSettings.recoveryEnabled) then
        if TornadoDebug and TornadoDebug.verboseMode then TornadoDebug:log("RECOVERY", "TRACE: Aborted. Recovery module disabled in settings.") end
        return 
    end

    if vehicle.rootNode == nil then return end

    -- 1. Check if the vehicle is currently on our destroyed list
    local destructionData = TornadoDestruction._destroyedObjects[vehicle.rootNode]
    if destructionData == nil then 
        if TornadoDebug and TornadoDebug.verboseMode then TornadoDebug:log("RECOVERY", "TRACE: Aborted. Vehicle is not damaged (Free Reset allowed).") end
        return 
    end 

    if TornadoDebug and TornadoDebug.verboseMode then TornadoDebug:log("RECOVERY", "TRACE: Damaged Vehicle Confirmed! Calculating bill...") end

    -- 2. Itemized Damage Calculation
    local trashCount = 0
    local structCount = 0
    
    if destructionData.nodes then
        for _, nodeInfo in ipairs(destructionData.nodes) do
            local isTrash = false
            local nameLower = string.lower(nodeInfo.name)
            
            for _, trashKey in ipairs(TornadoDestruction.TRASH_KEYWORDS) do
                if string.find(nameLower, trashKey, 1, true) then
                    isTrash = true
                    break
                end
            end
            
            if isTrash then trashCount = trashCount + 1 else structCount = structCount + 1 end
        end
    end
    
    -- Native Engine Damage Check
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
    if farmId == nil or farmId == 0 then 
        if TornadoDebug and TornadoDebug.verboseMode then TornadoDebug:log("RECOVERY", "TRACE: Aborted. Invalid farm ID.") end
        return 
    end 

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

    -- 6. Clean up the memory
    TornadoDestruction._destroyedObjects[vehicle.rootNode] = nil
end

function TornadoRecovery:deleteMap()
    self.isHooked = false
end

return TornadoRecovery