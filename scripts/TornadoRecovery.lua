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
TornadoRecovery.WHEEL_PRICE_FACTOR = 0.006    -- One wheel (tire + rim) = 0.6% of vehicle value...
TornadoRecovery.WHEEL_MIN_COST = 250          -- ...but at least $250 (small trailer wheel)
TornadoRecovery.WHEEL_MAX_COST = 8000         -- ...and at most $8,000 (large tractor / combine wheel)
TornadoRecovery.TRACK_PRICE_FACTOR = 0.03     -- One whole track (belt, rollers, idlers) = 3% of vehicle value...
TornadoRecovery.TRACK_MIN_COST = 2000         -- ...but at least $2,000 (small crawler)
TornadoRecovery.TRACK_MAX_COST = 40000        -- ...and at most $40,000 (large crawler tractor)
TornadoRecovery.ENGINE_MAX_FACTOR = 0.08      -- Up to 8% of purchase price for engine rebuild

TornadoRecovery.isHooked = false

function TornadoRecovery:installHooks()
    if self.isHooked then return end

    -- Vehicle is a base-game class that survives savegame reloads, while this file is sourced
    -- again for every savegame. Flag the class itself so the wrapper is only added once.
    if Vehicle ~= nil and Vehicle.tornadoRecoveryHooked then
        self.isHooked = true
        return
    end

    -- [THE GOLDEN HOOK]
    -- Derived directly from ResetVehicleEvent.lua. We hook the native Vehicle class!
    if Vehicle ~= nil and Vehicle.reset ~= nil then
        local oldVehicleReset = Vehicle.reset

        Vehicle.reset = function(vehicleSelf, forceDelete, callback, resetPlayer)
            -- Only the server should handle the billing logic.
            -- A reset loads a NEW copy at the reset spot in the background and deletes this one when it is
            -- ready (Vehicle:reset sets isResetInProgress meanwhile). Pressing reset again during that time
            -- must not bill a second time.
            if g_server ~= nil and TornadoRecovery ~= nil and not vehicleSelf.isResetInProgress
                and not vehicleSelf.markedForDeletion then
                TornadoRecovery:processRecovery(vehicleSelf)
            end

            -- Continue with the engine's normal reset execution
            return oldVehicleReset(vehicleSelf, forceDelete, callback, resetPlayer)
        end

        print("TornadoRecovery: SUCCESS - Hooked directly into Vehicle class!")
        Vehicle.tornadoRecoveryHooked = true
        self.isHooked = true
    else
        print("TORNADO RECOVERY CRITICAL ERROR: Could not find Vehicle class to hook!")
    end
end

--- Itemized repair cost of a tornado-damaged vehicle, WITHOUT charging, repairing or resetting anything.
--- Used by the emergency tow bill (processRecovery) and meant for other systems that need the same
--- numbers (e.g. an insurance adjuster's estimate). Returns nil when the tornado has not damaged the vehicle.
---   vehiclePrice, towFee,
---   structCount / trashCount / wheelCount / trackCount, partsCount (all broken parts),
---   costPerStruct / costPerTrash / costPerWheel / costPerTrack, structCost / trashCost / wheelCost / trackCost,
---   costScale (game difficulty cost multiplier x player money scale, already applied to every amount),
---   engineDamage (0..1), isEngineDead, engineCost, total
function TornadoRecovery:estimateRepairCost(vehicle)
    if vehicle == nil or vehicle.rootNode == nil or TornadoDestruction == nil then
        return nil
    end
    local destructionData = TornadoDestruction._destroyedObjects[vehicle.rootNode]
    if destructionData == nil then
        return nil
    end

    local trashCount = 0
    local structCount = 0
    local wheelCount = 0
    local trackCount = 0
    local wheelPrefix = TornadoDestruction.WHEEL_NODE_PREFIX or "wheel#"
    local trackPrefix = TornadoDestruction.CRAWLER_NODE_PREFIX or "crawler#"

    if destructionData.nodes then
        for _, nodeInfo in ipairs(destructionData.nodes) do
            local name = nodeInfo.name or ""
            -- Category recorded when the part was hidden (TornadoDestruction.KIND_*); older saves: guess from the name.
            if nodeInfo.kind == TornadoDestruction.KIND_WHEEL or string.sub(name, 1, #wheelPrefix) == wheelPrefix then
                wheelCount = wheelCount + 1
            elseif nodeInfo.kind == TornadoDestruction.KIND_TRACK or string.sub(name, 1, #trackPrefix) == trackPrefix then
                trackCount = trackCount + 1
            elseif nodeInfo.kind == TornadoDestruction.KIND_TRASH then
                trashCount = trashCount + 1
            elseif nodeInfo.kind == TornadoDestruction.KIND_STRUCT then
                structCount = structCount + 1
            else
                local isTrash = false
                local nameLower = string.lower(name)
                for _, trashKey in ipairs(TornadoDestruction.TRASH_KEYWORDS) do
                    if string.find(nameLower, trashKey, 1, true) then
                        isTrash = true
                        break
                    end
                end
                if isTrash then trashCount = trashCount + 1 else structCount = structCount + 1 end
            end
        end
    end

    -- Store purchase price (fallback to 50,000 if base/mod fails to report it)
    local vehiclePrice = 50000
    if vehicle.getPrice ~= nil then
        vehiclePrice = vehicle:getPrice() or 50000
    end

    -- Everything below is scaled by the game's economic difficulty (cost multiplier) and the player's
    -- money scale (TornadoSettings:getCostScale), so the bill fits Easy / Normal / Hard and any economy.
    local costScale = 1.0
    if TornadoSettings ~= nil and TornadoSettings.getCostScale ~= nil then
        costScale = TornadoSettings:getCostScale()
    end
    local function scaled(amount)
        return math.floor(amount * costScale + 0.5)
    end

    -- A. Base Towing: Min fee + 0.5% of vehicle purchase value
    local towFee = scaled(self.MIN_TOW_FEE + math.floor(vehiclePrice * self.TOW_PRICE_FACTOR))

    -- B. Structural: Scale by actual broken i3d nodes
    local costPerStruct = scaled(self.COST_PER_STRUCT_NODE)
    local costPerTrash = scaled(self.COST_TRASH)
    local structCost = structCount * costPerStruct
    local trashCost = trashCount * costPerTrash

    -- B2. Wheels: a whole tire + rim each, scaled to the vehicle (a tractor wheel costs more than a trailer's)
    local costPerWheel = scaled(math.min(self.WHEEL_MAX_COST, math.max(self.WHEEL_MIN_COST, math.floor(vehiclePrice * self.WHEEL_PRICE_FACTOR))))
    local wheelCost = wheelCount * costPerWheel

    -- B3. Tracks: a whole track each (belt, rollers, idlers), far more expensive than a tire
    local costPerTrack = scaled(math.min(self.TRACK_MAX_COST, math.max(self.TRACK_MIN_COST, math.floor(vehiclePrice * self.TRACK_PRICE_FACTOR))))
    local trackCost = trackCount * costPerTrack

    -- C. Engine Overhaul: Scaled to damage severity & vehicle value
    local engineDamage = 0
    if vehicle.getDamageAmount ~= nil then
        engineDamage = vehicle:getDamageAmount() or 0
    end
    local isEngineDead = engineDamage >= 1.0
    local engineCost = 0
    if isEngineDead then
        -- Full overhaul if 100% dead (up to 8% of vehicle value, min $1500)
        engineCost = scaled(math.max(1500, math.floor(vehiclePrice * self.ENGINE_MAX_FACTOR)))
    elseif engineDamage > 0.1 then
        -- Pro-rated engine work if partially damaged
        engineCost = scaled(math.floor((vehiclePrice * self.ENGINE_MAX_FACTOR) * engineDamage))
    end

    return {
        vehiclePrice = vehiclePrice,
        towFee = towFee,
        structCount = structCount, trashCount = trashCount, wheelCount = wheelCount, trackCount = trackCount,
        partsCount = structCount + wheelCount + trackCount,
        costPerStruct = costPerStruct, costPerTrash = costPerTrash,
        costPerWheel = costPerWheel, costPerTrack = costPerTrack, costScale = costScale,
        structCost = structCost, trashCost = trashCost, wheelCost = wheelCost, trackCost = trackCost,
        engineDamage = engineDamage, isEngineDead = isEngineDead, engineCost = engineCost,
        total = math.floor(towFee + structCost + trashCost + wheelCost + trackCost + engineCost),
    }
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

    -- Get Farm ID for billing
    local farmId = vehicle:getOwnerFarmId()
    if farmId == nil or farmId == 0 then
        if TornadoDebug and TornadoDebug.verboseMode then TornadoDebug:log("RECOVERY", "TRACE: Aborted. Invalid farm ID.") end
        return
    end

    -- 2. Itemized Damage Calculation (shared with anything else that needs the price, e.g. insurance)
    local estimate = self:estimateRepairCost(vehicle)
    if estimate == nil then
        return
    end
    local towFee, engineCost, totalCost = estimate.towFee, estimate.engineCost, estimate.total
    -- Equipment insurance: the storm's claim keeps this estimate (the vehicle is repaired now); Salvage -> Rebuilt.
    if TornadoInsuranceEquipment ~= nil and TornadoInsuranceEquipment.onVehicleRecovered ~= nil then
        TornadoInsuranceEquipment:onVehicleRecovered(vehicle, estimate)
    end
    local vehiclePrice = estimate.vehiclePrice

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
    if vehicle.rootNode and TornadoEffects and TornadoEffects.fireFate ~= nil then
        TornadoEffects.fireFate[vehicle.rootNode] = nil   -- repaired: a later storm rolls again
    end

    -- 5. Restore the Visual Destruction (Fix missing windows and meshes)
    if destructionData.nodes then
        for _, nodeInfo in ipairs(destructionData.nodes) do
            if nodeInfo.id ~= nil and nodeInfo.id ~= 0 and entityExists(nodeInfo.id) then
                setVisibility(nodeInfo.id, true)
            end
        end
    end
    if TornadoSync ~= nil then TornadoSync:sendDestruction(vehicle, nil, true) end

    -- 6. Deduct the Money
    g_currentMission:addMoney(-totalCost, farmId, MoneyType.VEHICLE_REPAIR, true, true)

    -- 7. Notify the Player
    local msgKey = "tp_msg_tow_bill"
    local params = { TornadoText.cash(totalCost), TornadoText.cash(towFee), TornadoText.num(estimate.partsCount),
        TornadoText.cash(vehiclePrice) }
    if engineCost > 0 then
        msgKey = "tp_msg_tow_bill_engine"
        table.insert(params, TornadoText.cash(engineCost))
    end
    local msg = TornadoText.formatMessage(msgKey, params)
    -- Shown to the vehicle owner's farm (in multiplayer the player who reset it is usually a client).
    if TornadoSync ~= nil then
        TornadoSync:sendMessage(msgKey, params, TornadoSync.MSG_CRITICAL, farmId)
    else
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, msg)
    end

    -- Detailed Console Audit Logging
    if TornadoDebug then
        local logBreakdown = string.format("Charged Farm %d exactly $%d for resetting %s (Price: $%d) | MATH: Tow: $%d + (Struct: %d * $%d) + (Trash: %d * $%d) + (Wheels: %d * $%d) + (Tracks: %d * $%d) + (Engine: $%d)",
            farmId, totalCost, destructionData.filename or "Vehicle", vehiclePrice, towFee, estimate.structCount, estimate.costPerStruct,
            estimate.trashCount, estimate.costPerTrash, estimate.wheelCount, estimate.costPerWheel, estimate.trackCount, estimate.costPerTrack, engineCost)
            .. string.format(" | Cost scale x%.2f", estimate.costScale)

        TornadoDebug:log("RECOVERY", logBreakdown)
    end

    -- 8. Clean up the memory
    TornadoDestruction._destroyedObjects[vehicle.rootNode] = nil
end


function TornadoRecovery:deleteMap()
    self.isHooked = false
end

return TornadoRecovery