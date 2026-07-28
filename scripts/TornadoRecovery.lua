---@class TornadoRecovery
---@description Intercepts vehicle resets to charge an Emergency Recovery fee for tornado-damaged vehicles.

TornadoRecovery = {}

-- ============================================================================
-- Configuration & Pricing
-- ============================================================================
-- TornadoRecovery.BASE_TOW_FEE = 1500        
-- TornadoRecovery.COST_STRUCTURAL = 500      
-- TornadoRecovery.COST_TRASH = 10            
-- TornadoRecovery.ENGINE_REPAIR_COST = 3500  
-- ============================================================================
-- Configuration & Pricing (Dynamic Scaling)
-- ============================================================================
TornadoRecovery.MIN_TOW_FEE = 500             -- Base dispatch minimum
TornadoRecovery.TOW_PRICE_FACTOR = 0.005      -- 0.5% of vehicle value added to towing
TornadoRecovery.COST_PER_STRUCT_NODE = 30     -- $30 per broken structural node
TornadoRecovery.COST_TRASH = 10               -- Flat per trash item
TornadoRecovery.ENGINE_MAX_FACTOR = 0.08      -- Up to 8% of purchase price for engine rebuild

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

    -- Get Farm ID for billing
    local farmId = vehicle:getOwnerFarmId()
    if farmId == nil or farmId == 0 then 
        if TornadoDebug and TornadoDebug.verboseMode then TornadoDebug:log("RECOVERY", "TRACE: Aborted. Invalid farm ID.") end
        return 
    end 

    -- Fetch store purchase price (fallback to 50,000 if base/mod fails to report it)
    local vehiclePrice = 50000
    if vehicle.getPrice ~= nil then
        vehiclePrice = vehicle:getPrice() or 50000
    end

    -- 3. Dynamic Calculation
    -- A. Base Towing: Min fee + 0.5% of vehicle purchase value
    local towFee = self.MIN_TOW_FEE + math.floor(vehiclePrice * self.TOW_PRICE_FACTOR)
    
    -- B. Structural: Scale by actual broken i3d nodes
    local structCost = structCount * self.COST_PER_STRUCT_NODE
    local trashCost = trashCount * self.COST_TRASH
    
    -- C. Engine Overhaul: Scaled to damage severity & vehicle value
    local engineCost = 0
    local rawDamage = 0
    if vehicle.getDamageAmount ~= nil then
        rawDamage = vehicle:getDamageAmount() or 0
    end

    if isEngineDead then
        -- Full overhaul if 100% dead (up to 8% of vehicle value, min $1500)
        engineCost = math.max(1500, math.floor(vehiclePrice * self.ENGINE_MAX_FACTOR))
    elseif rawDamage > 0.1 then
        -- Pro-rated engine work if partially damaged
        engineCost = math.floor((vehiclePrice * self.ENGINE_MAX_FACTOR) * rawDamage)
    end

    local totalCost = math.floor(towFee + structCost + trashCost + engineCost)

    -- 1. Fix the Mechanical Engine Damage (The Wrench Icon)
    if vehicle.setDamageAmount then
        vehicle:setDamageAmount(0)
    end

    -- 2. Fix the Paint and Wear
    if vehicle.setWearTotalAmount then
        vehicle:setWearTotalAmount(0)
    end

    -- 3. Wash the Vehicle
    if vehicle.setDirtAmount then
        vehicle:setDirtAmount(0)
    end

    -- 4. Extinguish the Fire & Reset FX Logic
    vehicle.tornadoIsOnFire = false
    if vehicle.rootNode and TornadoEffects and TornadoEffects.activeEffects[vehicle.rootNode] then
        TornadoEffects:cleanupEffectNodes(TornadoEffects.activeEffects[vehicle.rootNode])
        TornadoEffects.activeEffects[vehicle.rootNode] = nil
    end

    -- 5. Restore the Visual Destruction (Fix missing windows and meshes)
    if TornadoDestruction and TornadoDestruction.repairTarget then
        TornadoDestruction:repairTarget(vehicle)
    end

    -- 6. Deduct the Money 
    g_currentMission:addMoney(-totalCost, farmId, MoneyType.VEHICLE_REPAIR, true, true)

    -- 7. Notify the Player
    local msg = string.format("EMERGENCY TOW: Billed $%d (Tow: $%d | Nodes: %dx | Value: $%dk)", 
                                totalCost, towFee, structCount, math.floor(vehiclePrice / 1000))
    
    if engineCost > 0 then 
        msg = msg .. string.format(" + Engine Work ($%d)", engineCost) 
    end
    g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, msg)

    -- Detailed Console Audit Logging
    if TornadoDebug then 
        local logBreakdown = string.format("Charged Farm %d exactly $%d for resetting %s (Price: $%d) | MATH: Tow: $%d + (Struct: %d * $%d) + (Trash: %d * $%d) + (Engine: $%d)", 
            farmId, totalCost, destructionData.filename or "Vehicle", vehiclePrice, towFee, structCount, self.COST_PER_STRUCT_NODE, trashCount, self.COST_TRASH, engineCost)
        
        TornadoDebug:log("RECOVERY", logBreakdown)
    end

    -- 8. Clean up the memory
    TornadoDestruction._destroyedObjects[vehicle.rootNode] = nil
end


function TornadoRecovery:deleteMap()
    self.isHooked = false
end

return TornadoRecovery