---@class TornadoHusbandry
---@version 2.1 (PASTURE AREA HIT TEST, MAP-SCALED IMMUNITY)
---@description Only applies livestock losses to outdoor pens/pastures (fence/meadow), skipping indoor barns.

TornadoHusbandry = {}

-- =============================================================
-- 1. SETTINGS & DEFAULTS
-- =============================================================

TornadoHusbandry.IMMUNITY_DURATION = 120000
TornadoHusbandry.LOSS_MIN = 2
TornadoHusbandry.LOSS_MAX = 5

TornadoHusbandry.victimCache = {}
TornadoHusbandry.scanTimer = 0
TornadoHusbandry.isActive = false

-- Debug: set true to print pasture classification for husbandries within tornado radius (can spam the log!)
TornadoHusbandry.DEBUG_PASTURE_FLAGS = false
-- Throttle debug prints per-placeable (ms)
TornadoHusbandry.DEBUG_PASTURE_THROTTLE_MS = 5000


-- =============================================================
-- 2. INITIALIZATION
-- =============================================================

function TornadoHusbandry:loadMap(name)
    self.victimCache = {}
    self.scanTimer = 0
    self._debugPastureLastPrint = {}

    if TornadoDebug then
        TornadoDebug:log("--------------------------------------------------")
        TornadoDebug:log("TORNADO HUSBANDRY V2.1: PASTURE-ONLY")
        TornadoDebug:log("--------------------------------------------------")
    end
end

--- Immunity actually used: the setting is for a standard 2 km map, bigger maps scale it up because the
--- tornado needs longer to cross a pasture there (4 km map = 2x, 8 km = 4x ...).
function TornadoHusbandry:getImmunityMs()
    local base = tonumber(self.IMMUNITY_DURATION) or 120000
    local scale = 1.0
    if TornadoPhysics ~= nil and TornadoPhysics.getMapScaleFactor ~= nil then
        scale = TornadoPhysics:getMapScaleFactor() or 1.0
    end
    return base * math.max(scale, 1.0)
end

--- true if a circle (tornado / test radius) touches the husbandry's outdoor area.
--- Uses the pasture's real fence outline; the placeable's origin is often at the barn, far from the
--- pasture, so origin distance missed tornadoes crossing the pasture and hit pastures the tornado only
--- passed on the barn side. Falls back to the origin when the game has no outline.
function TornadoHusbandry:getIsPastureInRange(placeable, x, z, radius)
    local polygon = nil
    if placeable.getOutdoorContourPolygon ~= nil then
        polygon = placeable:getOutdoorContourPolygon()
    end
    if polygon ~= nil and polygon.getIsCircleIntersecting ~= nil and polygon.vertices ~= nil and #polygon.vertices >= 6 then
        return polygon:getIsCircleIntersecting(x, z, radius)
    end
    local bX, _, bZ = getWorldTranslation(placeable.rootNode)
    return MathUtil.vector2Length(x - bX, z - bZ) < radius
end

function TornadoHusbandry:deleteMap()
    self.isActive = false
    self.victimCache = {}
    self._debugPastureLastPrint = {}
end


-- =============================================================
-- 3. PASTURE DETECTION (NO RAYCASTS)
-- =============================================================

-- Returns true only for husbandries that actually have an outdoor pasture/pen system.
-- Uses GIANTS specializations instead of geometry checks (prevents false positives on indoor barns).
function TornadoHusbandry:isOutdoorPasture(placeable)
    if placeable == nil then return false end

    local spec = placeable.spec_husbandryFence
    if spec == nil then
        return false
    end

    -- strongest signal: GIANTS sets this when fence segments exist
    if spec.hasFence ~= nil then
        return spec.hasFence == true
    end

    -- fallback: check for segment data
    if spec.fenceSegmentsData ~= nil and #spec.fenceSegmentsData > 0 then
        return true
    end

    -- fallback: check for a fence object (if available)
    if placeable.getFence ~= nil then
        return placeable:getFence() ~= nil
    end

    return false
end


-- Optional compatibility alias if you referenced the old name elsewhere
function TornadoHusbandry:hasOutdoorPasture(placeable)
    return self:isOutdoorPasture(placeable)
end

-- Debug helper: prints which pasture flags are present on a placeable (throttled).
function TornadoHusbandry:debugPastureFlags(placeable)
    if placeable == nil then return end

    local now = g_currentMission and g_currentMission.time or 0
    self._debugPastureLastPrint = self._debugPastureLastPrint or {}

    local last = self._debugPastureLastPrint[placeable] or 0
    local throttle = tonumber(self.DEBUG_PASTURE_THROTTLE_MS) or 5000
    if (now - last) < throttle then
        return
    end
    self._debugPastureLastPrint[placeable] = now

    local name = placeable.configFileName or "(unnamed)"
    if placeable.getName ~= nil then
        name = placeable:getName() or name
    end

    local hasFenceSpec = (placeable.spec_husbandryFence ~= nil)
    local hasMeadowSpec = (placeable.spec_husbandryMeadow ~= nil)

    local isMeadow = false
    if placeable.getIsMeadow ~= nil then
        isMeadow = (placeable:getIsMeadow() == true)
    end

    local hasFence = "n/a"
    if placeable.spec_husbandryFence ~= nil and placeable.spec_husbandryFence.hasFence ~= nil then
        hasFence = tostring(placeable.spec_husbandryFence.hasFence)
    end

    print(string.format("[Tornado] PastureFlags: %s fenceSpec=%s hasFence=%s meadowSpec=%s getIsMeadow=%s",
        tostring(name), tostring(hasFenceSpec), tostring(hasFence), tostring(hasMeadowSpec), tostring(isMeadow)))
end


-- =============================================================
-- 4. MAIN LOOP
-- =============================================================

function TornadoHusbandry:runCycle(dt, tX, tY, tZ, radius)
    if not self.isActive then return end

    self.scanTimer = self.scanTimer + dt
    if self.scanTimer < 2000 then return end
    self.scanTimer = 0

    local currentTime = g_currentMission.time

    if g_currentMission.placeableSystem and g_currentMission.placeableSystem.placeables then
        for _, placeable in pairs(g_currentMission.placeableSystem.placeables) do
            if placeable.spec_husbandry and placeable.rootNode ~= nil then
                local inRange = self:getIsPastureInRange(placeable, tX, tZ, radius)

                -- Optional debug: log any husbandry within radius so you can verify pasture detection.
                if self.DEBUG_PASTURE_FLAGS and inRange then
                    self:debugPastureFlags(placeable)
                end

                -- Only apply tornado livestock losses to outdoor pastures/pens (skip indoor barns).
                if inRange and self:isOutdoorPasture(placeable) then
                    self:checkPasture(placeable, currentTime)
                end
            end
        end
    end
end

-- Called only for outdoor pastures already inside the tornado radius.
function TornadoHusbandry:checkPasture(placeable, currentTime)
    local immunity = self:getImmunityMs()
    local lastHit = self.victimCache[placeable] or 0
    if (currentTime - lastHit) < immunity then
        return
    end

    local lostCount = self:executeKill(placeable) or 0
    if lostCount > 0 then
        self.victimCache[placeable] = currentTime

        local name = (placeable.getName and placeable:getName()) or "Livestock Pen"
        local typeKey = "tp_pen_pasture"
        if placeable.spec_husbandryMeadow ~= nil or (placeable.getIsMeadow ~= nil and placeable:getIsMeadow() == true) then
            typeKey = "tp_pen_meadow"
        elseif placeable.spec_husbandryFence ~= nil then
            typeKey = "tp_pen_fence"
        end

        local params = { TornadoText.str(name), TornadoText.key(typeKey), TornadoText.num(lostCount),
            TornadoText.num(math.floor(immunity / 1000 + 0.5)) }
        local msg = TornadoText.formatMessage("tp_msg_storm_damage", params)

        -- Everyone sees it (the husbandry runs on the server).
        if TornadoSync ~= nil then
            TornadoSync:sendMessage("tp_msg_storm_damage", params, TornadoSync.MSG_BLINKING)
        else
            g_currentMission:showBlinkingWarning(msg, 10000)
        end

        if TornadoDebug then
            TornadoDebug:log("TORNADO HUSBANDRY: " .. msg)
        end
    end
end


-- =============================================================
-- 5. THE REAPER LOGIC
-- =============================================================

function TornadoHusbandry:executeKill(placeable)
    if placeable == nil or placeable.spec_husbandry == nil then return 0 end

    -- Safety: only kill animals for outdoor pastures/pens.
    if not self:isOutdoorPasture(placeable) then
        return 0
    end

    if not g_currentMission:getIsServer() then return 0 end

    local clusters = nil
    if placeable.getClusters ~= nil then
        clusters = placeable:getClusters()
    end

    if clusters == nil then return 0 end

    local minK = math.floor(tonumber(self.LOSS_MIN) or 2)
    local maxK = math.floor(tonumber(self.LOSS_MAX) or 5)
    if maxK < minK then minK, maxK = maxK, minK end
    if minK < 0 then minK = 0 end
    if maxK < 0 then maxK = 0 end

    local totalKilled = 0
    local targetKill = math.random(minK, maxK)

    for _, cluster in pairs(clusters) do
        if targetKill <= 0 then break end

        local count = 0
        if cluster.getNumAnimals then
            count = cluster:getNumAnimals()
        elseif cluster.numAnimals then
            count = cluster.numAnimals
        end

        if count > 0 then
            local take = math.min(count, targetKill)
            -- Livestock insurance: value of the animals (age + health) before they are removed.
            if cluster.changeNumAnimals and TornadoInsuranceLivestock ~= nil and TornadoInsuranceLivestock.onAnimalsKilled ~= nil then
                TornadoInsuranceLivestock:onAnimalsKilled(placeable, cluster, take)
            end
            if cluster.changeNumAnimals then
                cluster:changeNumAnimals(-take)
                totalKilled = totalKilled + take
                targetKill = targetKill - take
            end
        end
    end

    -- Apply now (same as selling animals): empty groups are removed, the animal count and the visible
    -- animals update, and every player is told.
    if totalKilled > 0 and placeable.getClusterSystem ~= nil then
        local clusterSystem = placeable:getClusterSystem()
        if clusterSystem ~= nil and clusterSystem.updateNow ~= nil then
            clusterSystem:updateNow()
        end
    end

    return totalKilled
end


-- =============================================================
-- 6. DEBUG TOOL
-- =============================================================

function TornadoHusbandry:debugKillTest()
    if TornadoDebug then
        TornadoDebug:log("------------------------------------------------")
        TornadoDebug:log("TORNADO HUSBANDRY: MANUAL DEBUG TRIGGERED")
    end

    local px, py, pz = nil, nil, nil
    local source = "Unknown"

    if g_currentMission.controlledVehicle then
        px, py, pz = getWorldTranslation(g_currentMission.controlledVehicle.rootNode)
        source = "Vehicle"
    elseif g_currentMission.player and g_currentMission.player.rootNode then
        px, py, pz = getWorldTranslation(g_currentMission.player.rootNode)
        source = "Player Body"
    elseif getCamera then
        local cam = getMainCamera and getMainCamera() or getCamera()
        if cam then
            px, py, pz = getWorldTranslation(cam)
            source = "Active Camera"
        end
    end

    if px == nil then
        if TornadoDebug then
            TornadoDebug:log("CRITICAL ERROR: Could not locate position (Vehicle/Player/Camera missing).")
        end
        return
    end

    if TornadoDebug then
        TornadoDebug:log(string.format("Searching from: %s at [%.1f, %.1f, %.1f]", source, px, py, pz))
    end

    local hit = false
    if g_currentMission.placeableSystem and g_currentMission.placeableSystem.placeables then
        for _, placeable in pairs(g_currentMission.placeableSystem.placeables) do
            if placeable.spec_husbandry and placeable.rootNode ~= nil then
                local bX, _, bZ = getWorldTranslation(placeable.rootNode)
                local dist = MathUtil.vector2Length(px - bX, pz - bZ)

                if self:getIsPastureInRange(placeable, px, pz, 60.0) then
                    local name = (placeable.getName and placeable:getName()) or "Unknown Husbandry"
                    local outdoor = self:isOutdoorPasture(placeable)

                    if TornadoDebug then
                        TornadoDebug:log(string.format(" > TARGET: '%s' (%.1fm) outdoorPasture=%s",
                            name, dist, tostring(outdoor)))
                    end

                    if self.DEBUG_PASTURE_FLAGS then
                        self:debugPastureFlags(placeable)
                    end

                    if outdoor then
                        if TornadoDebug then TornadoDebug:log("   >>> Attempting Kill...") end
                        local killed = self:executeKill(placeable)
                        if TornadoDebug then TornadoDebug:log(string.format("   >>> RESULT: Killed %d animals.", killed)) end
                    else
                        if TornadoDebug then TornadoDebug:log("   >>> SKIPPED: Indoor barn (no pasture/fence detected).") end
                    end

                    hit = true
                end
            end
        end
    end

    if TornadoDebug then
        if not hit then
            TornadoDebug:log("No husbandries within 60m found.")
        end
        TornadoDebug:log("------------------------------------------------")
    end
end
