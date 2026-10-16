---@class TornadoFieldFireFX
---@version 1.3
---@description Visuals of a field fire on every machine (host, single player and multiplayer clients):
--- a broken line of flickering flames along the burning edge (many small flame particle systems,
--- FX/fieldFireFlames.i3d, unevenly spaced), low smoke over the burnt area (FX/smokeTrailSubUV.i3d via
--- TornadoEffects), a tall smoke plume (particle system FX/fieldFireSmoke.i3d) that widens as it rises and
--- leans with the wind, and a red map marker. The ring grows at the fire's spread speed; start / stop come from TornadoHazards (server) or a
--- TornadoFieldFireEvent (clients). No gameplay here - the crop damage is done by TornadoHazards on the server.

TornadoFieldFireFX = {}

-- Flames: small particle emitters on the burning edge. Each has its own position jitter and flicker, so the
-- edge reads as an uneven fire line, not evenly spaced poles.
TornadoFieldFireFX.FLAME_FILE = "FX/fieldFireFlames.i3d"
TornadoFieldFireFX.MAX_FLAMES = 40
TornadoFieldFireFX.MIN_FLAMES = 6
TornadoFieldFireFX.FLAME_SPACING = 5         -- metres of edge per flame emitter (until MAX_FLAMES is reached)
TornadoFieldFireFX.FLAME_ANGLE_JITTER = 0.4  -- share of the slot an emitter may sit off its even spot
TornadoFieldFireFX.FLAME_RADIAL_JITTER = 1.5 -- metres in / out of the edge
TornadoFieldFireFX.FLAME_EMIT_MIN = 0.5      -- per-emitter strength range ...
TornadoFieldFireFX.FLAME_EMIT_MAX = 1.4
TornadoFieldFireFX.FLAME_FLICKER = 0.6       -- ... and how much it pulses (0 = steady, 1 = goes out at times)
TornadoFieldFireFX.NUM_SMOKE = 5
TornadoFieldFireFX.SMOKE_SCALE = { 6.0, 12.0, 6.0 }
-- Plume: one world-space particle system in the middle of the burnt area (sprites keep rising and widening,
-- so it reads as one column, not stacked pieces).
TornadoFieldFireFX.PLUME_FILE = "FX/fieldFireSmoke.i3d"
TornadoFieldFireFX.PLUME_MIN_EMIT = 0.35     -- emission share while the fire is small ...
TornadoFieldFireFX.PLUME_MAX_EMIT = 1.5      -- ... and at full size
TornadoFieldFireFX.PLUME_LEAN_PER_MS = 0.04  -- tilt of the emitter (radians) per m/s of wind
TornadoFieldFireFX.PLUME_MAX_LEAN = 0.5
TornadoFieldFireFX.PLUME_LINGER_MS = 25000   -- after the fire is out, the last smoke rises away (= particle life)
TornadoFieldFireFX.FADE_MS = 4000
TornadoFieldFireFX.FLICKER_SPEED = 0.004     -- the fire line drifts a little along the edge (radians per ms)

function TornadoFieldFireFX:loadMap(modDir)
    local dir = modDir or g_currentModDirectory
    self.plumeFilename = dir ~= nil and Utils.getFilename(self.PLUME_FILE, dir) or nil
    self.flameFilename = dir ~= nil and Utils.getFilename(self.FLAME_FILE, dir) or nil
    self.time = 0
    -- id -> { data, flames = {particles}, smoke = {nodes}, plume = particles, radius, alpha, stopping, angle, hotspot, npc }
    self.fires = {}
end

function TornadoFieldFireFX:deleteMap()
    for id in pairs(self.fires or {}) do
        self:remove(id)
    end
    self.fires = {}
end

--- Loads a particle system i3d at x, y, z. worldSpace: the particles stay where they were emitted (plume);
--- otherwise they move with the node (flames). Returns { root, ps } or nil.
local function loadParticles(filename, x, y, z, worldSpace)
    if filename == nil or ParticleUtil == nil then
        return nil
    end
    local root = loadI3DFile(filename, false, false, false)
    if root == nil or root == 0 then
        return nil
    end
    link(getRootNode(), root)
    setTranslation(root, x, y, z)
    if getNumOfChildren(root) == 0 then
        delete(root)
        return nil
    end
    local ps = {}
    -- in world space the emitter shape stays under root, so moving / tilting root moves the emitter
    ParticleUtil.loadParticleSystemFromNode(getChildAt(root, 0), ps, true, worldSpace, false)
    if not ps.isValid then
        delete(root)
        return nil
    end
    return { root = root, ps = ps }
end

local function deleteParticles(particles)
    if particles == nil then
        return
    end
    ParticleUtil.deleteParticleSystem(particles.ps)
    if entityExists(particles.root) then
        delete(particles.root)
    end
end

--- Normalised wind direction and speed (m/s); calm if the weather is not there.
local function getWind()
    local mission = g_currentMission
    local weather = mission ~= nil and mission.environment ~= nil and mission.environment.weather or nil
    if weather == nil or weather.windUpdater == nil then
        return 1, 0, 0
    end
    local dirX, dirZ, velocity = weather.windUpdater:getCurrentValues()
    if dirX == nil or dirZ == nil then
        return 1, 0, 0
    end
    local length = math.sqrt(dirX * dirX + dirZ * dirZ)
    if length < 0.0001 then
        return 1, 0, 0
    end
    return dirX / length, dirZ / length, velocity or 0
end

local function terrainY(x, z)
    if g_terrainNode == nil then
        return 0
    end
    return getTerrainHeightAtWorldPos(g_terrainNode, x, 0, z)
end

--- data = { id, fieldId, x, z, radius, maxRadius, speed }
function TornadoFieldFireFX:start(data)
    if data == nil or data.id == nil or TornadoEffects == nil or TornadoEffects.spawnFX == nil then
        return
    end
    if self.fires[data.id] ~= nil then
        self:remove(data.id)
    end
    local fire = { data = data, flames = {}, smoke = {}, radius = data.radius or 4, alpha = 0, stopping = false,
        angle = math.random() * math.pi * 2 }
    local y = terrainY(data.x, data.z)
    for _ = 1, self.MAX_FLAMES do
        local flame = loadParticles(self.flameFilename, data.x, y, data.z, false)
        if flame == nil then
            break
        end
        ParticleUtil.setEmitCountScale(flame.ps, 0)
        flame.angleJitter = (math.random() * 2 - 1) * self.FLAME_ANGLE_JITTER
        flame.radialJitter = (math.random() * 2 - 1) * self.FLAME_RADIAL_JITTER
        flame.strength = self.FLAME_EMIT_MIN + math.random() * (self.FLAME_EMIT_MAX - self.FLAME_EMIT_MIN)
        flame.flickerSpeed = 0.0015 + math.random() * 0.003   -- radians per ms
        flame.phase = math.random() * math.pi * 2
        table.insert(fire.flames, flame)
    end
    for _ = 1, self.NUM_SMOKE do
        local node = TornadoEffects:spawnFX(TornadoEffects.i3dFilename, data.x, y, data.z, self.SMOKE_SCALE, "smoke")
        if node ~= nil then
            table.insert(fire.smoke, node)
        end
    end
    fire.plume = loadParticles(self.plumeFilename, data.x, y, data.z, true)
    if fire.plume ~= nil then
        ParticleUtil.setEmitCountScale(fire.plume.ps, 0)
    end
    self:addHotspot(fire)
    self.fires[data.id] = fire
    self:place(fire)
end

function TornadoFieldFireFX:stop(id)
    local fire = self.fires[id]
    if fire ~= nil then
        fire.stopping = true
    end
end

function TornadoFieldFireFX:remove(id)
    local fire = self.fires[id]
    if fire == nil then
        return
    end
    for _, flame in ipairs(fire.flames) do
        deleteParticles(flame)
    end
    for _, node in ipairs(fire.smoke) do
        if entityExists(node) then delete(node) end
    end
    deleteParticles(fire.plume)
    fire.plume = nil
    if fire.hotspot ~= nil and g_currentMission ~= nil then
        g_currentMission:removeMapHotspot(fire.hotspot)
    end
    self.fires[id] = nil
end

function TornadoFieldFireFX:update(dt)
    if self.fires == nil or next(self.fires) == nil then
        return
    end
    self.time = self.time + dt
    local timeScale = (g_currentMission ~= nil and g_currentMission.missionInfo ~= nil and g_currentMission.missionInfo.timeScale) or 1
    for id, fire in pairs(self.fires) do
        if fire.stopping then
            fire.alpha = math.max(0, fire.alpha - dt / self.FADE_MS)
            if fire.alpha <= 0 then
                if fire.plume ~= nil then
                    ParticleUtil.setEmittingState(fire.plume.ps, false)
                end
                for _, flame in ipairs(fire.flames) do
                    ParticleUtil.setEmittingState(flame.ps, false)
                end
                -- the fire is out: drop the map marker now, not when the last smoke is gone
                if fire.hotspot ~= nil and g_currentMission ~= nil then
                    g_currentMission:removeMapHotspot(fire.hotspot)
                    fire.hotspot = nil
                end
            end
            fire.lingerMs = (fire.lingerMs or 0) + dt
            -- keep the node until the last plume smoke has risen away
            if fire.alpha <= 0 and (fire.plume == nil or fire.lingerMs >= self.FADE_MS + self.PLUME_LINGER_MS) then
                self:remove(id)
            end
        else
            fire.alpha = math.min(1, fire.alpha + dt / self.FADE_MS)
            fire.radius = math.min(fire.data.maxRadius, fire.radius + (fire.data.speed or 0) * dt / 1000 * timeScale)
        end
        if self.fires[id] ~= nil then
            fire.angle = fire.angle + self.FLICKER_SPEED * dt * 0.1
            self:place(fire)
        end
    end
end

--- Flames along the burning edge (as many as its length needs, each a bit off its even spot and flickering
--- on its own), smoke over the burnt area.
function TornadoFieldFireFX:place(fire)
    local data = fire.data
    local edge = 2 * math.pi * fire.radius
    local numActive = math.max(self.MIN_FLAMES, math.min(#fire.flames, math.floor(edge / self.FLAME_SPACING)))
    local slot = 2 * math.pi / numActive
    for i, flame in ipairs(fire.flames) do
        if entityExists(flame.root) then
            local emit = 0
            if i <= numActive then
                local a = fire.angle + (i - 1 + flame.angleJitter) * slot
                local r = math.max(1, fire.radius + flame.radialJitter)
                local x = data.x + math.cos(a) * r
                local z = data.z + math.sin(a) * r
                setTranslation(flame.root, x, terrainY(x, z), z)
                local pulse = 0.5 + 0.5 * math.sin(self.time * flame.flickerSpeed + flame.phase)
                emit = fire.alpha * flame.strength * (1 - self.FLAME_FLICKER * pulse)
            end
            ParticleUtil.setEmitCountScale(flame.ps, emit)
        end
    end
    for i, node in ipairs(fire.smoke) do
        if entityExists(node) then
            local a = fire.angle * 0.3 + (i - 1) * (2 * math.pi / math.max(1, #fire.smoke))
            local r = fire.radius * 0.6
            local x = data.x + math.cos(a) * r
            local z = data.z + math.sin(a) * r
            setTranslation(node, x, terrainY(x, z) + 2, z)
            TornadoEffects:applyOpacity(node, fire.alpha * 0.8, "smoke")
        end
    end
    -- The plume rises from the middle of the burnt area, thicker as the fire grows, and the emitter is
    -- tilted downwind so the column leans with the wind.
    if fire.plume ~= nil and entityExists(fire.plume.root) then
        local windX, windZ, windSpeed = getWind()
        local lean = math.min(self.PLUME_MAX_LEAN, windSpeed * self.PLUME_LEAN_PER_MS)
        -- small angles: rotating about X tips +Y towards +Z, about Z tips +Y towards -X
        setRotation(fire.plume.root, lean * windZ, 0, -lean * windX)
        local growth = fire.radius / math.max(1, data.maxRadius)
        local emit = self.PLUME_MIN_EMIT + (self.PLUME_MAX_EMIT - self.PLUME_MIN_EMIT) * growth
        ParticleUtil.setEmitCountScale(fire.plume.ps, emit * fire.alpha)
    end
    if fire.hotspot ~= nil then
        fire.hotspot:setWorldPosition(data.x, data.z)
    end
end

--- Red map marker (the tornado hotspot classes with a generic icon) - click it to teleport there.
function TornadoFieldFireFX:addHotspot(fire)
    if TornadoHotspotNPC == nil or TornadoPersistentNPCHotspot == nil or g_currentMission == nil
        or g_overlayManager == nil then
        return
    end
    local image = TornadoHotspot ~= nil and TornadoHotspot.npc ~= nil and TornadoHotspot.npc.imageFilename or nil
    local npc = TornadoHotspotNPC.new(image)
    local title = TornadoText ~= nil and TornadoText.format("tp_hotspot_field_fire", tostring(fire.data.fieldId or "?"))
        or ("Field fire " .. tostring(fire.data.fieldId))
    npc:setTitle(title)
    npc:setTeleportWorldPosition(fire.data.x + fire.data.maxRadius + 10, 0, fire.data.z)
    local hotspot = TornadoPersistentNPCHotspot.new(npc)
    if hotspot.icon ~= nil then
        hotspot.icon = g_overlayManager:createOverlay("mapHotspots.other", 0, 0, hotspot.width, hotspot.height)
        hotspot.icon:setColor(1, 0.25, 0.05, 1)
    end
    hotspot:setWorldPosition(fire.data.x, fire.data.z)
    hotspot:setVisible(true)
    g_currentMission:addMapHotspot(hotspot)
    fire.npc = npc
    fire.hotspot = hotspot
end
