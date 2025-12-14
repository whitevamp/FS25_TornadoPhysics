---@class TornadoHusbandry
---@version 1.8 (Argument Fix)
---@description Fixes console command parsing for t_immunity.

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

-- =============================================================
-- 2. INITIALIZATION
-- =============================================================

function TornadoHusbandry:loadMap(name)
    self.victimCache = {}
    self.scanTimer = 0

-- print("--------------------------------------------------")
-- print("TORNADO HUSBANDRY V1.9: DYNAMIC TIMER")
-- print("--------------------------------------------------")
    
    -- NEW: Get the dynamically calculated immunity, but only if user hasn't set a custom value
    if TornadoPhysics and TornadoPhysics.dynamicImmunityMS and not self.customImmunitySet then
        -- This only runs once at map load if no custom setting was loaded from XML.
        self.IMMUNITY_DURATION = TornadoPhysics.dynamicImmunityMS
        -- print(string.format("TORNADO HUSBANDRY: Using dynamic base immunity of %.1fs", self.IMMUNITY_DURATION / 1000))
    end

    addConsoleCommand("t_immunity", "Set Pasture Immunity Time", "consoleImmunity", self)
    addConsoleCommand("t_kill_debug", "Test Kill Logic", "consoleDebugKill", self)
    addConsoleCommand("t_husbandry", "Toggle Animal Death", "consoleToggle", self)
end

function TornadoHusbandry:deleteMap()
    self.isActive = false
    self.victimCache = {}
    removeConsoleCommand("t_immunity")
    removeConsoleCommand("t_kill_debug")
    removeConsoleCommand("t_husbandry")
end

-- =============================================================
-- 3. MAIN LOOP
-- =============================================================

function TornadoHusbandry:runCycle(dt, tX, tY, tZ, radius)
    if not self.isActive then return end

    self.scanTimer = self.scanTimer + dt
    if self.scanTimer < 2000 then return end
    self.scanTimer = 0

    local currentTime = g_currentMission.time
    local radiusSq = radius * radius

    if g_currentMission.placeableSystem and g_currentMission.placeableSystem.placeables then
        for _, placeable in pairs(g_currentMission.placeableSystem.placeables) do
            if placeable.spec_husbandry then
                self:checkPasture(placeable, tX, tZ, radiusSq, currentTime)
            end
        end
    end
end

function TornadoHusbandry:checkPasture(placeable, tX, tZ, radiusSq, currentTime)
    local lastHit = self.victimCache[placeable] or 0
    if (currentTime - lastHit) < self.IMMUNITY_DURATION then
        return 
    end

    if placeable.rootNode then
        local bX, _, bZ = getWorldTranslation(placeable.rootNode)
        local distSq = (tX - bX)^2 + (tZ - bZ)^2

        if distSq < radiusSq then
            local lostCount = self:executeKill(placeable)
            
            if lostCount > 0 then
                self.victimCache[placeable] = currentTime
                local name = placeable:getName() or "Livestock Pen"
                local msg = string.format("STORM DAMAGE: %s lost %d animals! (Structure Safe for %.0fs)", name, lostCount, self.IMMUNITY_DURATION/1000)
                g_currentMission:showBlinkingWarning(msg, 5000)
                -- print("TORNADO HUSBANDRY: " .. msg)
            end
        end
    end
end

-- =============================================================
-- 4. THE REAPER LOGIC
-- =============================================================

function TornadoHusbandry:executeKill(placeable)
    if not placeable.spec_husbandry then return 0 end

    local clusters = nil
    if placeable.spec_husbandry.getClusters then
        clusters = placeable.spec_husbandry:getClusters()
    elseif placeable.spec_husbandry.clusters then
        clusters = placeable.spec_husbandry.clusters
    end

    if not clusters then return 0 end

    local totalKilled = 0
    local targetKill = math.random(self.LOSS_MIN, self.LOSS_MAX)

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
            if g_currentMission:getIsServer() then
                if cluster.changeNumAnimals then
                    cluster:changeNumAnimals(-take)
                    totalKilled = totalKilled + take
                    targetKill = targetKill - take
                end
            end
        end
    end
    
    if totalKilled > 0 and placeable.spec_husbandry.updateVisuals then
        placeable.spec_husbandry:updateVisuals()
    end

    return totalKilled
end

-- =============================================================
-- 5. CONSOLE COMMANDS
-- =============================================================

function TornadoHusbandry:consoleToggle()
    self.isActive = not self.isActive
    print(string.format("Tornado Husbandry: Lethality is now %s", self.isActive and "ON (ACTIVE)" or "OFF (SAFE)"))
end

-- function TornadoHusbandry:consoleImmunity(arg1, arg2)
--     -- Check both arguments for the number
--     local val = tonumber(arg1)
--     if not val then val = tonumber(arg2) end

--     if val then
--         self.IMMUNITY_DURATION = val * 1000 
--         print(string.format("Tornado Husbandry: Immunity set to %.1f seconds", val))
--     else
--         print("Usage: t_immunity [seconds]")
--         print(string.format("Current Immunity: %.1f seconds", self.IMMUNITY_DURATION / 1000))
--     end
-- end
function TornadoHusbandry:consoleImmunity(arg1, arg2)
    -- Check both arguments for the number
    local val = tonumber(arg1)
    if not val then val = tonumber(arg2) end

    if val then
        self.IMMUNITY_DURATION = val * 1000 
        -- NEW: Flag that the user has manually set a time, preventing dynamic override
        self.customImmunitySet = true 
        print(string.format("Tornado Husbandry: Custom Immunity set to %.1f seconds", val))
    else
        print("Usage: t_immunity [seconds]")
        print(string.format("Current Immunity: %.1f seconds", self.IMMUNITY_DURATION / 1000))
    end
end

function TornadoHusbandry:consoleDebugKill()
    print("------------------------------------------------")
    print("TORNADO HUSBANDRY: MANUAL DEBUG TRIGGERED")
    
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
        print("CRITICAL ERROR: Could not locate position (Vehicle/Player/Camera missing).")
        return
    end

    print(string.format("Searching from: %s at [%.1f, %.1f, %.1f]", source, px, py, pz))

    local hit = false
    if g_currentMission.placeableSystem and g_currentMission.placeableSystem.placeables then
        for _, placeable in pairs(g_currentMission.placeableSystem.placeables) do
            if placeable.spec_husbandry then
                local bX, _, bZ = getWorldTranslation(placeable.rootNode)
                local dist = MathUtil.vector2Length(px - bX, pz - bZ)
                
                if dist < 60.0 then 
                    local name = placeable:getName() or "Unknown Barn"
                    print(string.format(" > TARGET: '%s' (%.1fm)", name, dist))
                    print("   >>> Attempting Kill...")
                    local killed = self:executeKill(placeable)
                    print(string.format("   >>> RESULT: Killed %d animals.", killed))
                    hit = true
                end
            end
        end
    end
    
    if not hit then print("No barns within 60m found.") end
    print("------------------------------------------------")
end

addModEventListener(TornadoHusbandry)