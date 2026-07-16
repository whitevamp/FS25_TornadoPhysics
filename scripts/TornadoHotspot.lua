---@class TornadoHotspot
---@version 6.9 (FS25 NPCHotspot: twister icon + card image + teleport rotation + stats bridge for MapUI; title labels Radius/Distance)
---@description Provides a clickable tornado hotspot (NPC-style popup + teleport) and exposes stable refs for TornadoMapUI.

TornadoHotspot = TornadoHotspot or {}

-- ============================================================================
-- Logging helpers (respect t_dev verbose)
-- ============================================================================
local function dbg(msg)
    if TornadoDebug ~= nil and TornadoDebug.verboseMode == true and TornadoDebug.log ~= nil then
        TornadoDebug:log("HOTSPOT", tostring(msg))
    end
end

local function info(msg)
    if TornadoDebug ~= nil and TornadoDebug.info ~= nil then
        TornadoDebug:info("HOTSPOT", tostring(msg))
    end
end

local function pickFirstExisting(baseDir, relList)
    if baseDir == nil then return nil end
    for _, rel in ipairs(relList) do
        local p = Utils.getFilename(rel, baseDir)
        if p ~= nil and fileExists(p) then
            return p
        end
    end
    return nil
end

local function buildTitle(efNum, windMin, windMax, radiusM, distanceM)
    local windStr = (windMin ~= nil and windMax ~= nil) and string.format("%d-%d mph", windMin, windMax) or "n/a"
    local distStr = (distanceM ~= nil) and (tostring(distanceM) .. "m") or "n/a"
    return string.format("EF:%d  Wind:%s  Radius:%sm  Distance:%s", efNum or 0, windStr, radiusM ~= nil and tostring(radiusM) or "n/a", distStr)
end

-- ============================================================================
-- Fake NPC object for NPCHotspot & PlayerMover teleport
-- ============================================================================
TornadoHotspotNPC = {}
local TornadoHotspotNPC_mt = { __index = TornadoHotspotNPC }

function TornadoHotspotNPC.new(imageFilename)
    local self = setmetatable({}, TornadoHotspotNPC_mt)
    self.imageFilename = imageFilename
    self.title = buildTitle(0, 65, 85, 35, nil)

    self.x, self.y, self.z = 0, 0, 0
    self.rotY = 0 -- radians (yaw)

    self._imgInfoOnce = false
    return self
end

function TornadoHotspotNPC:getTitle()
    return self.title
end

function TornadoHotspotNPC:setTitle(t)
    self.title = t
end

function TornadoHotspotNPC:getImageFilename()
    if self._imgInfoOnce ~= true then
        self._imgInfoOnce = true
        info("Hotspots UI requested image: " .. tostring(self.imageFilename))
    end
    dbg("npc:getImageFilename() -> " .. tostring(self.imageFilename))
    return self.imageFilename
end

function TornadoHotspotNPC:getBeVisited()
    return true
end

function TornadoHotspotNPC:setTeleportWorldPosition(x, y, z)
    self.x, self.y, self.z = x, y, z
end

function TornadoHotspotNPC:getTeleportWorldPosition()
    local terrainY = getTerrainHeightAtWorldPos(g_terrainNode, self.x, 0, self.z)
    return self.x, math.max(terrainY, self.y or terrainY), self.z
end

function TornadoHotspotNPC:setTeleportWorldRotation(rotY)
    if rotY ~= nil then
        self.rotY = rotY
    end
end

function TornadoHotspotNPC:getTeleportWorldRotation()
    return self.rotY or 0
end

-- ============================================================================
-- Hotspot class (NPCHotspot, but with twister icon)
-- ============================================================================
TornadoPersistentNPCHotspot = {}
local TornadoPersistentNPCHotspot_mt = Class(TornadoPersistentNPCHotspot, NPCHotspot)

function TornadoPersistentNPCHotspot.new(npc, customMt)
    local self = NPCHotspot.new(npc, customMt or TornadoPersistentNPCHotspot_mt)

    -- Override icon to twister so it stays a tornado even when selected
    if self.icon ~= nil then
        local w, h = self.width, self.height
        self.icon = g_overlayManager:createOverlay("mapHotspots.twister", 0, 0, w, h)
    end

    -- Keep the minimap icon red-ish (optional)
    if self.iconSmall ~= nil then
        self.iconSmall:setColor(1, 0.2, 0.2, 1)
    end

    return self
end

-- Some game code paths may call teleport on the hotspot instead of npc; forward it.
function TornadoPersistentNPCHotspot:getTeleportWorldPosition()
    if self.npc ~= nil and self.npc.getTeleportWorldPosition ~= nil then
        return self.npc:getTeleportWorldPosition()
    end
    return 0, 0, 0
end

function TornadoPersistentNPCHotspot:getTeleportWorldRotation()
    if self.npc ~= nil and self.npc.getTeleportWorldRotation ~= nil then
        return self.npc:getTeleportWorldRotation()
    end
    return 0
end

-- ============================================================================
-- Module state
-- ============================================================================
TornadoHotspot.hotspot = TornadoHotspot.hotspot or nil
TornadoHotspot.npc = TornadoHotspot.npc or nil
TornadoHotspot.modDir = TornadoHotspot.modDir or nil

-- Cached stats (optional; MapUI primarily reads TornadoPhysics exports)
TornadoHotspot._efNum = TornadoHotspot._efNum or 0
TornadoHotspot._windMin = TornadoHotspot._windMin or 65
TornadoHotspot._windMax = TornadoHotspot._windMax or 85
TornadoHotspot._radiusM = TornadoHotspot._radiusM or 35
TornadoHotspot._distanceM = TornadoHotspot._distanceM or nil

-- ============================================================================
-- Public API
-- ============================================================================
function TornadoHotspot:loadMap(modDir)
    if self.hotspot ~= nil then return end
    if g_currentMission == nil then return end

    local dir = modDir or self.modDir or g_currentModDirectory
    self.modDir = dir

    local img = pickFirstExisting(dir, {
        "FX/tornadoCard.dds",
        "modIcon.dds",
        "textures/tornadoCard.dds"
    })

    info("Initializing Tornado hotspot. cardImage=" .. tostring(img) .. " modDir=" .. tostring(dir))

    self.npc = TornadoHotspotNPC.new(img)
    self.hotspot = TornadoPersistentNPCHotspot.new(self.npc)
    self.hotspot:setVisible(false) -- stays hidden until we see a tornado

    g_currentMission:addMapHotspot(self.hotspot)
    dbg("Hotspot added to map system.")
end

function TornadoHotspot:deleteMap()
    if g_currentMission ~= nil and self.hotspot ~= nil then
        g_currentMission:removeMapHotspot(self.hotspot)
    end
    self.hotspot = nil
    self.npc = nil
end

function TornadoHotspot:setActive(isActive)
    if self.hotspot ~= nil then
        self.hotspot:setVisible(isActive == true)
    end
end

function TornadoHotspot:updateStats(efNum, windMin, windMax, radiusM, distanceM)
    self._efNum = efNum or self._efNum or 0
    self._windMin = windMin or self._windMin
    self._windMax = windMax or self._windMax
    self._radiusM = radiusM or self._radiusM
    self._distanceM = distanceM or self._distanceM

    if self.npc ~= nil then
        self.npc:setTitle(buildTitle(self._efNum, self._windMin, self._windMax, self._radiusM, self._distanceM))
    end
end

function TornadoHotspot:updatePosition(tX, tZ, rotY)
    if self.hotspot == nil then return end
    if tX == nil or tZ == nil then
        self:setActive(false)
        return
    end

    self:setActive(true)
    self.hotspot:setWorldPosition(tX, tZ)

    if self.npc ~= nil then
        self.npc:setTeleportWorldPosition(tX, 0, tZ)
        self.npc:setTeleportWorldRotation(rotY or 0)
    end

    --dbg(string.format("Position updated: x=%.1f z=%.1f rotY=%s", tX, tZ, tostring(rotY)))
    -- Only print if the specific "t_dev pos" flag is ON
    if TornadoDebug and TornadoDebug.showPosition then
        TornadoDebug:logPos(string.format("Hotspot Moved: x=%.1f z=%.1f", tX, tZ))
    end
end

-- Optional CLI dump helper (already route it via t_dev hotspotdump)
function TornadoHotspot:dumpState()
    info("dumpState: hotspot=" .. tostring(self.hotspot)
        .. " npc=" .. tostring(self.npc)
        .. " ef=" .. tostring(self._efNum)
        .. " wind=" .. tostring(self._windMin) .. "-" .. tostring(self._windMax)
        .. " radius=" .. tostring(self._radiusM)
        .. " dist=" .. tostring(self._distanceM)
        .. " modDir=" .. tostring(self.modDir)
        .. " img=" .. tostring(self.npc ~= nil and self.npc.imageFilename or nil))
end
