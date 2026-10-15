---@class TornadoWildlife
---@version 1.0
---@description Wildlife and the farm dog react to the tornado.
---
--- Wildlife (crows and other birds, deer, boar, foxes, rabbits ... whatever the map spawns) is purely
--- local in FS25: every player's game spawns its own animals around that player, nothing is networked.
--- So this part runs on every machine that has a player (not on a dedicated server):
---   * Animals within "flee distance" of the tornado's outer radius run / fly away from it:
---       - simple animals (birds, small animals) use the game's own flee state and run off the map
---       - herds (deer, boar ...) are told to avoid the tornado instead of the player
---       - fly-by bird flocks turn away
---   * Animals that get inside the tornado's outer radius are caught and vanish.
---
--- The farm dog is a real (networked, server-owned) animal that belongs to a doghouse, so it is never
--- deleted: when the storm gets close it runs home to its doghouse (the same "go home" order the dog
--- menu gives).
--- Do NOT teleport the dog (Dog:teleportToSpawn) here: doing that while it follows the player or walks
--- froze the whole game in the engine (2026-10-14). The base game only teleports an idle, abandoned dog.

TornadoWildlife = {}

-- Settings (saved by TornadoSettings, synced by TornadoSync, changed via t_set wildlife / control panel)
TornadoWildlife.isEnabled = true
TornadoWildlife.fleeDistance = 150        -- metres beyond the tornado's outer radius where animals flee

-- Tuning
TornadoWildlife.SCAN_INTERVAL = 250       -- ms between wildlife checks
TornadoWildlife.DOG_HOME_RADIUS = 10      -- metres from the doghouse spot that count as "home"
TornadoWildlife.DOG_RESEND_INTERVAL = 5000 -- ms between "go home" orders while the dog is away

function TornadoWildlife:loadMap()
    self.scanTimer = 0
    self.threat = nil       -- { x, z, radius, fleeRadius } while a tornado is on the ground
    self.dogState = {}
    self.numCaught = 0
    self:installCompanionHook()

    if TornadoDebug then TornadoDebug:info("WILDLIFE", "V1.0 Initialized (Wildlife flees the tornado)") end
end

function TornadoWildlife:deleteMap()
    self.threat = nil
    self.dogState = {}
    if self.avoidNode ~= nil then
        if entityExists(self.avoidNode) then
            delete(self.avoidNode)
        end
        self.avoidNode = nil
    end
end

--- Herds (deer, boar ...) are steered by the engine and only "avoid the player". Their update sets that
--- every frame, so the hook runs after it and points the avoidance at the tornado while one is close.
--- The class survives savegame reloads; flag it so the hook is only added once.
function TornadoWildlife:installCompanionHook()
    if WildlifeInstanceCompanion == nil or WildlifeInstanceCompanion.update == nil
        or WildlifeInstanceCompanion.tornadoAvoidHooked then
        return
    end
    WildlifeInstanceCompanion.tornadoAvoidHooked = true
    local originalUpdate = WildlifeInstanceCompanion.update
    WildlifeInstanceCompanion.update = function(instance, dt)
        originalUpdate(instance, dt)
        if TornadoWildlife ~= nil and TornadoWildlife.onCompanionUpdate ~= nil then
            TornadoWildlife:onCompanionUpdate(instance)
        end
    end
end

function TornadoWildlife:onCompanionUpdate(instance)
    local threat = self.threat
    if threat == nil or instance.companionId == nil or self.avoidNode == nil then
        return
    end
    if instance:calculateDistanceFrom(threat.x, threat.z) < threat.fleeRadius then
        setCompanionAvoidPlayer(instance.companionId, self.avoidNode, threat.fleeRadius)
    end
end

-- =========================================================================
-- UPDATE
-- =========================================================================

function TornadoWildlife:update(dt)
    local node = TornadoPhysics ~= nil and TornadoPhysics.tornadoNode or nil
    if not self.isEnabled or node == nil or not entityExists(node) then
        self.threat = nil
        self.dogState = {}
        return
    end

    local tX, _, tZ = getWorldTranslation(node)
    local radius = TornadoPhysics.getOuterRadius ~= nil and TornadoPhysics:getOuterRadius() or 35
    local fleeRadius = radius + math.max(0, self.fleeDistance or 0)
    self.threat = { x = tX, z = tZ, radius = radius, fleeRadius = fleeRadius }

    -- A node at the tornado's foot for the herds to avoid.
    if self.avoidNode == nil then
        self.avoidNode = createTransformGroup("tornadoWildlifeAvoid")
        link(getRootNode(), self.avoidNode)
    end
    local groundY = getTerrainHeightAtWorldPos(g_terrainNode, tX, 0, tZ)
    setWorldTranslation(self.avoidNode, tX, groundY, tZ)

    self.scanTimer = self.scanTimer + dt
    if self.scanTimer < self.SCAN_INTERVAL then
        return
    end
    self.scanTimer = 0

    self:updateWildlife(tX, tZ, radius, fleeRadius)

    if g_currentMission ~= nil and g_currentMission:getIsServer() then
        self:updateDogs(tX, groundY, tZ, radius, fleeRadius)
    end
end

--- Local wildlife of this machine's player.
function TornadoWildlife:updateWildlife(tX, tZ, radius, fleeRadius)
    if g_wildlifeManager == nil or g_wildlifeManager.species == nil or g_localPlayer == nil then
        return
    end

    for _, species in ipairs(g_wildlifeManager.species) do
        local instances = species.instances
        if instances ~= nil then
            -- Backwards: despawn() removes the instance from this list.
            for i = #instances, 1, -1 do
                local instance = instances[i]
                if instance ~= nil and instance.calculateDistanceFrom ~= nil then
                    local dist = instance:calculateDistanceFrom(tX, tZ)
                    if dist < radius then
                        species:despawn(instance)
                        self.numCaught = self.numCaught + 1
                        if TornadoDebug then
                            TornadoDebug:log("WILDLIFE", string.format("%s caught by the tornado (%.0fm).", tostring(species.name), dist))
                        end
                    elseif dist < fleeRadius then
                        self:fleeInstance(instance, tX, tZ)
                    end
                end
            end
        end
    end
end

--- Direction (x, z) from the tornado to a point, normalised.
local function awayFrom(tX, tZ, x, z)
    local dx, dz = x - tX, z - tZ
    local len = math.sqrt(dx * dx + dz * dz)
    if len < 0.01 then
        local angle = math.random() * 2 * math.pi
        return math.cos(angle), math.sin(angle)
    end
    return dx / len, dz / len
end

function TornadoWildlife:fleeInstance(instance, tX, tZ)
    -- Simple animals (birds, small animals): the game's flee state, running off the map.
    local stateMachine = instance.stateMachine
    if stateMachine ~= nil and stateMachine.states ~= nil and stateMachine.states.flee ~= nil and instance.getCurrentPosition ~= nil then
        local flee = stateMachine.states.flee
        if flee.fleeingToDespawn then
            return
        end
        local x, _, z = instance:getCurrentPosition()
        local dirX, dirZ = awayFrom(tX, tZ, x, z)
        stateMachine:changeState(flee)
        flee.pendingTargetCheck = nil -- drop the "run from the player" target the state just asked for
        flee:fleeToDespawn(dirX, dirZ, true)
        return
    end

    -- Fly-by bird flocks: turn away once per flight.
    if instance.animals ~= nil and instance.setFlyDirection ~= nil and instance.animals[1] ~= nil then
        if instance.tornadoTurnedAt == instance.spawnedAtTimestamp then
            return
        end
        instance.tornadoTurnedAt = instance.spawnedAtTimestamp
        local x, _, z = getWorldTranslation(instance.animals[1].rootNode)
        local dirX, dirZ = awayFrom(tX, tZ, x, z)
        instance:setFlyDirection(dirX, dirZ)
    end

    -- Herds are steered in onCompanionUpdate().
end

--- Server: a farm dog within the flee distance that is away from its doghouse is sent home. The order is
--- repeated every few seconds while it stays away (the player can lure it out again with the ball, and a
--- dog that was home when the tornado arrived must still be sent back later).
function TornadoWildlife:updateDogs(tX, tY, tZ, radius, fleeRadius)
    if g_currentMission.doghouses == nil then
        return
    end
    for _, doghouse in pairs(g_currentMission.doghouses) do
        local dog = doghouse.getDog ~= nil and doghouse:getDog() or nil
        if dog ~= nil and dog.dogInstance ~= nil and dog.dogInstance ~= 0 and dog.getDistanceTo ~= nil then
            local state = self.dogState[dog]
            if state == nil then
                state = {}
                self.dogState[dog] = state
            end
            local dist = dog:getDistanceTo(tX, tY, tZ) or math.huge
            if dist < fleeRadius then
                local homeDist = dog:getDistanceTo(dog.spawnX or 0, dog.spawnY or 0, dog.spawnZ or 0) or 0
                local now = g_currentMission.time or 0
                if homeDist > self.DOG_HOME_RADIUS
                    and (state.sentAt == nil or now - state.sentAt >= self.DOG_RESEND_INTERVAL) then
                    state.sentAt = now
                    dog:goToSpawn()
                    if TornadoDebug then
                        TornadoDebug:log("WILDLIFE", string.format("Farm dog runs home from the tornado (%.0fm from the doghouse, %.0fm from the tornado).", homeDist, dist))
                    end
                end
            end
        end
    end
end

-- =========================================================================
-- TEST TOOLS (t_dev wildlife)
-- The game's own gsWildlifeSpawn only exists in GIANTS' development build; this is the same spawn.
-- Wildlife is local, so this only spawns animals on this player's machine.
-- =========================================================================

function TornadoWildlife:consoleCommand(sub, a, b, c, d)
    if g_wildlifeManager == nil or g_wildlifeManager.species == nil or g_localPlayer == nil then
        return "Wildlife: not available (no wildlife system or no local player)."
    end

    if sub == nil or sub == "list" then
        local parts = {}
        for _, species in ipairs(g_wildlifeManager.species) do
            local spawnable = species.spawnInstances ~= nil and "" or " (no test spawn)"
            parts[#parts + 1] = string.format("%s: %d%s", tostring(species.name), species:getNumInstances(), spawnable)
        end
        if #parts == 0 then
            return "Wildlife: this map defines no wildlife species."
        end
        return "Wildlife species (spawned around you): " .. table.concat(parts, ", ")
    end

    if sub == "spawn" then
        if a == nil then
            return "Usage: t_dev wildlife spawn <species> [distance] [count] [rotation]  (t_dev wildlife list shows the species)"
        end
        local species = g_wildlifeManager.nameToSpecies ~= nil and g_wildlifeManager.nameToSpecies[string.upper(a)] or nil
        if species == nil then
            return string.format("Wildlife: no species '%s' on this map. Try t_dev wildlife list.", tostring(a))
        end
        -- A species type without its own spawn would stay "spawn pending" forever and never spawn again.
        if species.spawnInstances == nil or species.debugSpawn == nil then
            return string.format("Wildlife: '%s' cannot be test-spawned.", tostring(species.name))
        end
        local distance = math.max(5, tonumber(b) or 50)
        local count = math.max(1, math.min(20, math.floor(tonumber(c) or 1)))
        local rotation = math.rad(tonumber(d) or 0)
        local x, z, yaw = g_localPlayer:getMapPositionAndLookYaw()
        local dirX, dirZ = MathUtil.getDirectionFromYRotation(yaw)
        local sx, sz = x + dirX * distance, z + dirZ * distance
        species:debugSpawn(sx, getTerrainHeightAtWorldPos(g_terrainNode, sx, 0, sz), sz, count, rotation)
        return string.format("Wildlife: spawned %d x %s %.0fm in front of you.", count, tostring(species.name), distance)
    end

    return "Usage: t_dev wildlife [list | spawn <species> [distance] [count] [rotation]]"
end

function TornadoWildlife:getStatusText()
    return string.format("Wildlife: Enabled = %s | Flee distance = %.0fm | Caught this session = %d",
        tostring(self.isEnabled), self.fleeDistance or 0, self.numCaught or 0)
end
