---@class TornadoMapUI
---@version 4.4 (Option A: map overlay card; stable hooks; no extra hotspot; bigger icon; avoid balance overlay; Radius/Distance labels)
---@description Draws a custom tornado info overlay on the in-game map when the tornado hotspot is selected.

TornadoMapUI = TornadoMapUI or {}

-- ============================================================================
-- CONFIG (tweak as you like)
-- ============================================================================
TornadoMapUI.enabled = TornadoMapUI.enabled ~= false
TornadoMapUI.onlyWhenSelected = (TornadoMapUI.onlyWhenSelected ~= false)

-- Overlay and hotspot text.
TornadoMapUI.lineSize = 0.016
TornadoMapUI.lineGap = 0.004
TornadoMapUI.fontSize = 0.015

-- Screen-space position (relative). These are safe defaults.
TornadoMapUI.anchorX = TornadoMapUI.anchorX or 0.62
TornadoMapUI.anchorY = TornadoMapUI.anchorY or 0.90

-- Icon next to the overlay text
TornadoMapUI.iconSize = TornadoMapUI.iconSize or 0.060
TornadoMapUI.iconPadding = TornadoMapUI.iconPadding or 0.010
TornadoMapUI.iconYOffset = TornadoMapUI.iconYOffset or -0.012

-- If true, nudges the overlay down a bit when anchored in the top-right (so it won't sit under the BALANCE box).
TornadoMapUI.avoidBalanceOverlay = (TornadoMapUI.avoidBalanceOverlay ~= false)
TornadoMapUI.avoidBalanceNudgeY = TornadoMapUI.avoidBalanceNudgeY or 0.10


-- ============================================================================
-- Logging helpers
-- ============================================================================
local function dbg(msg)
    if TornadoDebug ~= nil and TornadoDebug.verboseMode == true and TornadoDebug.log ~= nil then
        TornadoDebug:log("MAPUI", tostring(msg))
    end
end

local function info(msg)
    if TornadoDebug ~= nil and TornadoDebug.info ~= nil then
        TornadoDebug:info("MAPUI", tostring(msg))
    end
end

-- ============================================================================
-- Internal state
-- ============================================================================
TornadoMapUI._installed = TornadoMapUI._installed or false
TornadoMapUI._mapFrame = TornadoMapUI._mapFrame or nil
TornadoMapUI._mapElement = TornadoMapUI._mapElement or nil
TornadoMapUI._hotspot = TornadoMapUI._hotspot or nil
TornadoMapUI._npc = TornadoMapUI._npc or nil
TornadoMapUI._selected = TornadoMapUI._selected or false
TornadoMapUI._modDir = TornadoMapUI._modDir or TornadoMapUI._modDir or nil
TornadoMapUI._img = TornadoMapUI._img or nil
TornadoMapUI._imgOverlay = TornadoMapUI._imgOverlay or nil

-- ============================================================================
-- Helpers
-- ============================================================================
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

local function getPlayerXZ()
    -- Use the same robust strategy you used in husbandry debugKillTest()
    if g_currentMission == nil then return nil, nil, "no mission" end

    if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.rootNode ~= nil then
        local x, _, z = getWorldTranslation(g_currentMission.controlledVehicle.rootNode)
        if x ~= nil then return x, z, "vehicle" end
    end

    if g_currentMission.player ~= nil and g_currentMission.player.rootNode ~= nil then
        local x, _, z = getWorldTranslation(g_currentMission.player.rootNode)
        if x ~= nil then return x, z, "player" end
    end

    -- camera fallback
    local cam = (getMainCamera ~= nil and getMainCamera()) or (getCamera ~= nil and getCamera())
    if cam ~= nil then
        local x, _, z = getWorldTranslation(cam)
        if x ~= nil then return x, z, "camera" end
    end

    return nil, nil, "none"
end

local function efColor(efNum)
    -- Simple cue: returns r,g,b,a (no background, but used for text)
    if efNum == nil then return 1, 1, 1, 1 end
    if efNum >= 4 then return 1, 0.2, 0.2, 1 end
    if efNum >= 2 then return 1, 0.6, 0.1, 1 end
    return 1, 1, 1, 1
end

function TornadoMapUI:_syncRefs(forceLog)
    -- Pull live refs from TornadoHotspot module (single source of truth)
    local hs = (TornadoHotspot ~= nil) and TornadoHotspot.hotspot or nil
    local npc = (TornadoHotspot ~= nil) and TornadoHotspot.npc or nil

    self._hotspot = hs
    self._npc = npc

    if self._img == nil and npc ~= nil and npc.imageFilename ~= nil then
        self._img = npc.imageFilename
    end

    if self._imgOverlay == nil and self._img ~= nil and fileExists(self._img) then
        -- Overlay is optional; if Overlay class isn't available it will just stay nil
        if Overlay ~= nil and Overlay.new ~= nil then
            self._imgOverlay = Overlay.new(self._img, 0, 0, self.iconSize, self.iconSize)
        end
    end

    if forceLog == true then
        dbg("syncRefs: hotspot=" ..
        tostring(self._hotspot) .. " npc=" .. tostring(self._npc) .. " img=" .. tostring(self._img))
    end
end

function TornadoMapUI:_syncSelection()
    if self._mapFrame ~= nil and self._hotspot ~= nil then
        self._selected = (self._mapFrame.currentHotspot == self._hotspot)
    else
        self._selected = false
    end
end

-- ============================================================================
-- Hooks
-- ============================================================================
function TornadoMapUI:installHooks()
    if self._installed then return end
    self._installed = true

    if InGameMenuMapFrame ~= nil then
        if InGameMenuMapFrame.onFrameOpen ~= nil then
            InGameMenuMapFrame.onFrameOpen = Utils.appendedFunction(InGameMenuMapFrame.onFrameOpen, function(frame)
                TornadoMapUI._mapFrame = frame
                TornadoMapUI._mapElement = frame.ingameMap
                info("Map frame opened")
            end)
        end

        if InGameMenuMapFrame.onFrameClose ~= nil then
            InGameMenuMapFrame.onFrameClose = Utils.appendedFunction(InGameMenuMapFrame.onFrameClose, function(frame)
                TornadoMapUI._mapFrame = nil
                TornadoMapUI._mapElement = nil
                TornadoMapUI._selected = false
                info("Map frame closed")
            end)
        end

        if InGameMenuMapFrame.update ~= nil then
            InGameMenuMapFrame.update = Utils.appendedFunction(InGameMenuMapFrame.update, function(frame, dt)
                -- Always grab refs here too so enabling MapUI while map is already open still works.
                TornadoMapUI._mapFrame = frame
                TornadoMapUI._mapElement = frame.ingameMap

                TornadoMapUI:_syncRefs(false)
                TornadoMapUI:_syncSelection()
            end)
        end
    end

    if IngameMapElement ~= nil and IngameMapElement.draw ~= nil then
        IngameMapElement.draw = Utils.appendedFunction(IngameMapElement.draw, function(mapElement)
            if not TornadoMapUI.enabled then return end
            if TornadoMapUI._mapElement ~= nil and mapElement ~= TornadoMapUI._mapElement then return end
            if TornadoMapUI.onlyWhenSelected and not TornadoMapUI._selected then return end
            TornadoMapUI:drawOverlay()
        end)
    end

    dbg("Hooks installed.")
end

-- ============================================================================
-- Lifecycle
-- ============================================================================
function TornadoMapUI:loadMap(modDir)
    self._modDir = modDir or self._modDir or g_currentModDirectory
    self._img = self._img or pickFirstExisting(self._modDir, {
        "FX/tornadoCard.dds",
        "modIcon.dds",
        "textures/tornadoCard.dds"
    })
    self:installHooks()
end

function TornadoMapUI:deleteMap()
    self._mapFrame = nil
    self._mapElement = nil
    self._hotspot = nil
    self._npc = nil
    self._selected = false
    self._imgOverlay = nil
end

-- ============================================================================
-- Draw
-- ============================================================================
function TornadoMapUI:drawOverlay()
    -- Ensure refs are fresh (helps if map opens before hooks set)
    self:_syncRefs(false)
    self:_syncSelection()

    -- If no hotspot yet, nothing to draw
    if self._hotspot == nil then return end

    -- If tornado isn't active, don't draw the overlay at all. This avoids showing stale data.
    local tornadoNode = TornadoPhysics and TornadoPhysics.tornadoNode
    if not (tornadoNode and entityExists(tornadoNode)) then
        return
    end

    local efNum = TornadoPhysics ~= nil and TornadoPhysics.currentEfNum or 0
    local windMin = TornadoPhysics ~= nil and TornadoPhysics.currentWindMin or 65
    local windMax = TornadoPhysics ~= nil and TornadoPhysics.currentWindMax or 85
    local radiusM = TornadoPhysics ~= nil and TornadoPhysics.currentRadiusM or 35

    -- Distance
    local tX, tZ = self._hotspot:getWorldPosition()
    local pX, pZ, src = getPlayerXZ()
    local distStr = "n/a"
    local distM = nil
    if tX ~= nil and tZ ~= nil and pX ~= nil and pZ ~= nil then
        distM = math.floor(MathUtil.vector2Length(tX - pX, tZ - pZ) + 0.5)
        distStr = tostring(distM) .. "m"
    else
        dbg("Distance is n/a (playerPos=" .. tostring(pX) .. "," .. tostring(pZ) .. " src=" .. tostring(src) .. ")")
    end

    -- Match your compact, single-line format due to tooltip limits
    local text = string.format("EF:%d  Wind:%d-%dmph  Radius:%dm  Distance:%s", efNum or 0, windMin or 0, windMax or 0,
        radiusM or 0, distStr)

    -- Optional: keep the NPC popup title in sync (so the stock UI also looks right)
    if TornadoHotspot ~= nil and TornadoHotspot.updateStats ~= nil then
        TornadoHotspot:updateStats(efNum, windMin, windMax, radiusM, distM)
    end

    -- -- Draw icon (optional)
    -- local x = self.anchorX
    -- local y = self.anchorY

    -- -- Avoid the top-right \"BALANCE\" overlay if we're anchored up there
    -- if self.avoidBalanceOverlay and x > 0.6 and y > 0.78 then
    --     y = y - (self.avoidBalanceNudgeY or 0.07)
    -- end
    -- if self._imgOverlay ~= nil then
    --     self._imgOverlay:setPosition(x, y + (self.iconYOffset or 0.004))
    --     self._imgOverlay:render()
    --     x = x + (self.iconSize or 0.045) + (self.iconPadding or 0.008)
    -- end
    -- Draw icon (optional)
    local x = self.anchorX
    local y = self.anchorY

    -- Avoid the top-right "BALANCE" overlay if we're anchored up there
    if self.avoidBalanceOverlay and x > 0.6 and y > 0.78 then
        y = y - (self.avoidBalanceNudgeY or 0.10) -- was 0.07; bump it down a bit more
    end

    if self._imgOverlay ~= nil then
        local iconSize    = (self.iconSize or 0.060) -- bigger (try 0.055–0.070)
        local iconPad     = (self.iconPadding or 0.010)
        local iconYOffset = (self.iconYOffset or -0.012) -- negative moves DOWN

        self._imgOverlay:setPosition(x, y + iconYOffset)
        self._imgOverlay:setDimension(iconSize, iconSize) -- <-- THIS is the important scaling step
        self._imgOverlay:render()

        x = x + iconSize + iconPad
    end


    local r, g, b, a = efColor(efNum)
    setTextColor(r, g, b, a)
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_LEFT)

    renderText(x, y, self.fontSize, text)

    setTextBold(false)
    setTextColor(1, 1, 1, 1)
end

-- ============================================================================
-- CLI / Debug
-- ============================================================================
function TornadoMapUI:dumpState()
    self:_syncRefs(true)
    self:_syncSelection()

    local efNum = TornadoPhysics ~= nil and TornadoPhysics.currentEfNum or 0
    local windMin = TornadoPhysics ~= nil and TornadoPhysics.currentWindMin or 65
    local windMax = TornadoPhysics ~= nil and TornadoPhysics.currentWindMax or 85
    local radiusM = TornadoPhysics ~= nil and TornadoPhysics.currentRadiusM or 35

    local img = self._img
    if img == nil and self._npc ~= nil then img = self._npc.imageFilename end

    info("dumpState: enabled=" .. tostring(self.enabled)
        .. " onlyWhenSelected=" .. tostring(self.onlyWhenSelected)
        .. " mapOpen=" .. tostring(self._mapFrame ~= nil)
        .. " selected=" .. tostring(self._selected)
        .. " hotspot=" .. tostring(self._hotspot)
        .. " npc=" .. tostring(self._npc)
        .. " xz=" .. tostring(self._hotspot ~= nil and ({ self._hotspot:getWorldPosition() })[1] or nil)
        .. "," .. tostring(self._hotspot ~= nil and ({ self._hotspot:getWorldPosition() })[2] or nil)
        .. " ef=" .. tostring(efNum)
        .. " wind=" .. tostring(windMin) .. "-" .. tostring(windMax)
        .. " radius=" .. tostring(radiusM)
        .. " img=" .. tostring(img))
end
