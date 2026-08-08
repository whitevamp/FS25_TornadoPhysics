-- ==============================================================================
-- Tornado Physics Mod - Cross-Mod Compatibility Layer
-- Author: whitevamp
-- 
-- Integrates with:
--   - "Advanced Damage System" by id577
-- ==============================================================================

---@class TornadoADS
---@version 2.1 (INDOOR SAFEGUARD)
---@description Now respects the 'indoor_damage' setting from TornadoPhysics.

TornadoADS              = {}
TornadoADS.isAvailable  = false
TornadoADS.timers       = {}
TornadoADS.damageLevel  = {}

local TIME_FOR_MINOR    = 15000
local TIME_FOR_MODERATE = 30000
local TIME_FOR_TOTAL    = 50000

function TornadoADS:loadMap()
    if g_modIsLoaded["FS25_AdvancedDamageSystem"] then
        self.isAvailable = true
        if TornadoDebug then TornadoDebug:info("ADS", "Connection Established!") end
    else
        self.isAvailable = false
        if TornadoDebug then TornadoDebug:info("ADS", "Advanced Damage System not found.") end
    end
end

function TornadoADS:update(dt, activeNodes)
    if not self.isAvailable then return end

    -- 1. CLEANUP
    for rootNodeId, _ in pairs(self.timers) do
        if activeNodes[rootNodeId] == nil then
            self.timers[rootNodeId] = nil
            self.damageLevel[rootNodeId] = nil
        end
    end

    -- 2. PROCESS ACTIVE VEHICLES
    for nodeId, data in pairs(activeNodes) do
        if data.type == "VEHICLE" or data.type == "PLAYER" then
            self:processVehicle(data.obj, dt)
        end
    end
end

function TornadoADS:processVehicle(vehicle, dt)
    if vehicle == nil then return end
    if not vehicle.getRandomBreakdown or not vehicle.addBreakdown then return end

    -- CHECK INDOOR SAFETY
    if TornadoPhysics and TornadoPhysics.checkIsIndoorsCached then
        -- Check if vehicle is indoors using Physics cache (2.0 height offset)
        local isIndoors = TornadoPhysics:checkIsIndoorsCached(vehicle.rootNode, 2.0)
        local allowIndoor = TornadoPhysics.settings.indoor_damage

        -- If it is indoors, and indoor damage is OFF -> SAFE
        if isIndoors and not allowIndoor then
            -- Reset timer so damage doesn't accumulate while hiding
            local id = vehicle.rootNode
            if self.timers[id] then self.timers[id] = 0 end
            return
        end
    end

    local id = vehicle.rootNode
    if self.timers[id] == nil then
        self.timers[id] = 0
        self.damageLevel[id] = 0
    end

    self.timers[id] = self.timers[id] + dt

    if self.timers[id] > TIME_FOR_MINOR and self.damageLevel[id] < 1 then
        self:applyRandomDamage(vehicle, 1)
        self.damageLevel[id] = 1
    end

    if self.timers[id] > TIME_FOR_MODERATE and self.damageLevel[id] < 2 then
        self:applyRandomDamage(vehicle, 2)
        self.damageLevel[id] = 2
    end

    if self.timers[id] > TIME_FOR_TOTAL and self.damageLevel[id] < 3 then
        self:applyTotalDestruction(vehicle)
        self.damageLevel[id] = 3
    end
end

-- Applies a single random breakdown at a specific stage
function TornadoADS:applyRandomDamage(vehicle, targetStage)
    local breakdownId = vehicle:getRandomBreakdown()
    if breakdownId then
        if TornadoDebug then
            TornadoDebug:log("ADS",
                string.format("Applying Stage %d Breakdown to %s (ID: %s)", targetStage, vehicle:getName(),
                    tostring(breakdownId)))
        end
        vehicle:addBreakdown(breakdownId, targetStage)
    end
end

-- Iterates EVERY breakdown and applies MAX stage
function TornadoADS:applyTotalDestruction(vehicle)
    if TornadoDebug then TornadoDebug:info("ADS", string.format("*** TOTAL DESTRUCTION *** for %s", vehicle:getName())) end

    if ADS_Breakdowns and ADS_Breakdowns.BreakdownRegistry then
        for breakdownId, data in pairs(ADS_Breakdowns.BreakdownRegistry) do
            -- 1. Is this breakdown possible for this vehicle? (e.g. Don't break Turbo on non-turbo car)
            if data.isApplicable and data.isApplicable(vehicle) then
                -- 2. Find the Max Stage (Usually 4, sometimes 1)
                local maxStage = 1
                if data.stages then maxStage = #data.stages end

                -- 3. Apply it
                -- We use pcall (Protected Call) to prevent crashing if one specific breakdown fails
                local success, err = pcall(function() vehicle:addBreakdown(breakdownId, maxStage) end)

                if not success then
                    TornadoDebug:log(string.format(" > Failed to apply %s: %s", tostring(breakdownId), tostring(err)))
                else
                    -- strictly for debug
                    TornadoDebug:log(string.format(" > Wrecked: %s (Stage %d)", tostring(breakdownId), maxStage))
                end
            end
        end
    else
        self:applyRandomDamage(vehicle, 4)
        self:applyRandomDamage(vehicle, 4)
        self:applyRandomDamage(vehicle, 4)
    end
end
