---@class TornadoPersistence
---@version 1.0
---@description Saves the active tornado and a running outbreak with the savegame (TornadoState.xml, next to
--- TornadoDestructionState.xml), so a reload carries on instead of starting over:
---   * the tornado restored by the game keeps its EF rating, size, stats, climate roll and storm weather
---     (no new roll, no second touchdown alert, no siren replay)
---   * a running outbreak keeps its count and its next spawn time (no second outbreak roll)
--- Server only; clients get the restored state through the normal multiplayer events.

TornadoPersistence = {}
TornadoPersistence.FILE = "TornadoState.xml"
-- The saved tornado is only matched to a twister found this soon after the map loaded (mission ms).
TornadoPersistence.RESTORE_WINDOW_MS = 120000

local function isServer()
    return g_currentMission ~= nil and g_currentMission:getIsServer()
end

function TornadoPersistence:getPath()
    if TornadoDestruction == nil or TornadoDestruction._resolveSavegamePath == nil then
        return nil
    end
    local dir = TornadoDestruction:_resolveSavegamePath()
    return dir ~= nil and (dir .. self.FILE) or nil
end

-- =========================================================================
-- LOAD
-- =========================================================================

--- Call after TornadoOutbreak:loadMap() (it resets the outbreak state this restores).
function TornadoPersistence:loadMap()
    self.pendingTornado = nil
    if not isServer() then
        return
    end
    local path = self:getPath()
    if path == nil or not fileExists(path) then
        return
    end
    local xmlId = loadXMLFile("TornadoState", path)
    if xmlId == nil or xmlId == 0 then
        return
    end

    if getXMLBool(xmlId, "TornadoState.tornado#active") == true then
        local t = {
            scale = getXMLFloat(xmlId, "TornadoState.tornado#scale") or 1,
            outerRadius = getXMLFloat(xmlId, "TornadoState.tornado#outerRadius"),
            sizeMultiplier = getXMLFloat(xmlId, "TornadoState.tornado#sizeMultiplier") or 1,
            efNum = getXMLInt(xmlId, "TornadoState.tornado#efNum") or 0,
            windMin = getXMLInt(xmlId, "TornadoState.tornado#windMin") or 65,
            windMax = getXMLInt(xmlId, "TornadoState.tornado#windMax") or 85,
            radiusM = getXMLInt(xmlId, "TornadoState.tornado#radiusM") or 35,
        }
        local rollRegion = getXMLString(xmlId, "TornadoState.tornado.roll#region")
        if rollRegion ~= nil then
            local width = getXMLFloat(xmlId, "TornadoState.tornado.roll#width") or -1
            t.roll = {
                region = rollRegion,
                regionName = getXMLString(xmlId, "TornadoState.tornado.roll#regionName") or rollRegion,
                ef = getXMLInt(xmlId, "TornadoState.tornado.roll#ef") or t.efNum,
                width = width >= 0 and width or nil,
                scale = t.scale,
            }
        end
        local weatherIndex = getXMLInt(xmlId, "TornadoState.weather#index")
        if weatherIndex ~= nil then
            local function optional(key)
                local value = getXMLFloat(xmlId, "TornadoState.weather#" .. key)
                return (value ~= nil and value >= 0) and value or nil
            end
            local region = getXMLString(xmlId, "TornadoState.weather#region")
            t.weather = {
                index = weatherIndex,
                rain = getXMLFloat(xmlId, "TornadoState.weather#rain") or 0,
                hail = getXMLFloat(xmlId, "TornadoState.weather#hail") or 0,
                hailCm = optional("hailCm"),
                gustKmh = optional("gustKmh"),
                severeWind = getXMLBool(xmlId, "TornadoState.weather#severe") == true,
                windMps = optional("windMps"),
                headingDeg = optional("headingDeg"),
                region = (region ~= nil and region ~= "") and region or nil,
            }
        end
        self.pendingTornado = t
    end

    if TornadoOutbreak ~= nil and getXMLBool(xmlId, "TornadoState.outbreak#active") == true then
        TornadoOutbreak.isActive = true
        TornadoOutbreak.total = getXMLInt(xmlId, "TornadoState.outbreak#total") or 2
        TornadoOutbreak.remaining = getXMLInt(xmlId, "TornadoState.outbreak#remaining") or 0
        TornadoOutbreak.day = getXMLInt(xmlId, "TornadoState.outbreak#day")
        local nextSpawnAt = getXMLFloat(xmlId, "TornadoState.outbreak#nextSpawnAt") or -1
        TornadoOutbreak.nextSpawnAt = nextSpawnAt >= 0 and nextSpawnAt or nil
        if TornadoDebug then
            TornadoDebug:info("OUTBREAK", string.format("Outbreak restored from savegame: %s.", TornadoOutbreak:getStatusText()))
        end
    end

    delete(xmlId)
end

--- The saved tornado, once, for the first twister found right after loading; nil otherwise.
function TornadoPersistence:takeTornadoRestore()
    local t = self.pendingTornado
    self.pendingTornado = nil
    if t == nil or g_currentMission == nil or (g_currentMission.time or 0) > self.RESTORE_WINDOW_MS then
        return nil
    end
    return t
end

-- =========================================================================
-- SAVE (called from the FSBaseMission.saveSavegame hook in TornadoMain)
-- =========================================================================

function TornadoPersistence:save()
    if not isServer() then
        return
    end
    local path = self:getPath()
    if path == nil then
        return
    end
    local xmlId = createXMLFile("TornadoState", path, "TornadoState")
    if xmlId == nil or xmlId == 0 then
        return
    end

    local physics = TornadoPhysics
    local active = physics ~= nil and physics.tornadoNode ~= nil and entityExists(physics.tornadoNode) and getVisibility(physics.tornadoNode)
    setXMLBool(xmlId, "TornadoState.tornado#active", active == true)
    if active then
        setXMLFloat(xmlId, "TornadoState.tornado#scale", physics.currentScale or 1)
        setXMLFloat(xmlId, "TornadoState.tornado#outerRadius", physics:getOuterRadius() or 0)
        setXMLFloat(xmlId, "TornadoState.tornado#sizeMultiplier", physics.sizeMultiplier or 1)
        setXMLInt(xmlId, "TornadoState.tornado#efNum", physics.currentEfNum or 0)
        setXMLInt(xmlId, "TornadoState.tornado#windMin", physics.currentWindMin or 0)
        setXMLInt(xmlId, "TornadoState.tornado#windMax", physics.currentWindMax or 0)
        setXMLInt(xmlId, "TornadoState.tornado#radiusM", physics.currentRadiusM or 0)

        local roll = TornadoClimate ~= nil and TornadoClimate.lastRoll or nil
        if roll ~= nil and roll.region ~= nil then
            setXMLString(xmlId, "TornadoState.tornado.roll#region", roll.region)
            setXMLString(xmlId, "TornadoState.tornado.roll#regionName", roll.regionName or roll.region)
            setXMLInt(xmlId, "TornadoState.tornado.roll#ef", roll.ef or 0)
            setXMLFloat(xmlId, "TornadoState.tornado.roll#width", roll.width or -1)
        end

        local p = TornadoWeather ~= nil and TornadoWeather.lastProfile or nil
        if p ~= nil and p.index ~= nil then
            setXMLInt(xmlId, "TornadoState.weather#index", p.index)
            setXMLFloat(xmlId, "TornadoState.weather#rain", p.rain or 0)
            setXMLFloat(xmlId, "TornadoState.weather#hail", p.hail or 0)
            setXMLFloat(xmlId, "TornadoState.weather#hailCm", p.hailCm or -1)
            setXMLFloat(xmlId, "TornadoState.weather#gustKmh", p.gustKmh or -1)
            setXMLBool(xmlId, "TornadoState.weather#severe", p.severeWind == true)
            setXMLFloat(xmlId, "TornadoState.weather#windMps", p.windMps or -1)
            setXMLFloat(xmlId, "TornadoState.weather#headingDeg", p.headingDeg or -1)
            setXMLString(xmlId, "TornadoState.weather#region", p.region or "")
        end
    end

    local outbreak = TornadoOutbreak
    local outbreakActive = outbreak ~= nil and outbreak.isActive == true
    setXMLBool(xmlId, "TornadoState.outbreak#active", outbreakActive)
    if outbreakActive then
        setXMLInt(xmlId, "TornadoState.outbreak#total", outbreak.total or 0)
        setXMLInt(xmlId, "TornadoState.outbreak#remaining", outbreak.remaining or 0)
        setXMLInt(xmlId, "TornadoState.outbreak#day", outbreak.day or 0)
        setXMLFloat(xmlId, "TornadoState.outbreak#nextSpawnAt", outbreak.nextSpawnAt or -1)
    end

    saveXMLFile(xmlId)
    delete(xmlId)
    if TornadoDebug then
        TornadoDebug:log("PHYSICS", string.format("Tornado state saved (tornado active: %s, outbreak: %s).",
            tostring(active == true), outbreakActive and outbreak:getStatusText() or "none"))
    end
end
