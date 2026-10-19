---@class TornadoMessageLog
---@version 1.0
---@description Message history for the control panel's Messages tab (user request 2026-10-17). Every message the
--- mod sends to players (TornadoSync:sendMessage - insurer letters, storm / damage reports, hazard alerts - and
--- the touchdown warning) is kept per farm:
---   * recent: kept for RECENT_HOURS in-game hours, then removed;
---   * saved: the player saves a recent message - it stays until the player removes it.
--- Messages to everybody are kept for every farm. The server owns the log (TornadoMessages.xml in the savegame)
--- and sends each farm its list (TornadoMessageLogEvent); players ask the server to save / remove (same event).
--- Works with or without the insurance. Texts are stored as key + parameters, so each player reads them in their
--- own language and currency.

TornadoMessageLog = {}

TornadoMessageLog.FILE = "TornadoMessages.xml"
TornadoMessageLog.RECENT_HOURS = 24
TornadoMessageLog.MAX_RECENT = 60
TornadoMessageLog.MAX_SAVED = 60
TornadoMessageLog.MS_PER_HOUR = 60 * 60 * 1000
TornadoMessageLog.MS_PER_DAY = 24 * 60 * 60 * 1000

local function isServer()
    return g_currentMission ~= nil and g_currentMission:getIsServer()
end

local function isMultiplayer()
    return TornadoSync ~= nil and TornadoSync.isMultiplayer ~= nil and TornadoSync:isMultiplayer()
end

local function getAbsoluteMs()
    local environment = g_currentMission ~= nil and g_currentMission.environment or nil
    if environment == nil then
        return 0
    end
    return (environment.currentMonotonicDay or 0) * TornadoMessageLog.MS_PER_DAY + (environment.dayTime or 0)
end

function TornadoMessageLog:loadMap()
    self.farms = {}      -- farmId -> { recent = { entry }, saved = { entry } }; entry = { id, key, params, time, kind }
    self.nextId = 1
    if isServer() then
        self:loadState()
        if g_messageCenter ~= nil then
            g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
        end
    end
end

function TornadoMessageLog:deleteMap()
    if g_messageCenter ~= nil then
        g_messageCenter:unsubscribeAll(self)
    end
    self.farms = {}
end

function TornadoMessageLog:getFarm(farmId)
    local farm = self.farms[farmId]
    if farm == nil then
        farm = { recent = {}, saved = {} }
        self.farms[farmId] = farm
    end
    return farm
end

--- Farms a message to "everybody" is kept for.
local function getAllFarmIds()
    local ids = {}
    if g_farmManager ~= nil and g_farmManager.getFarms ~= nil then
        for _, farm in ipairs(g_farmManager:getFarms()) do
            local spectator = FarmManager ~= nil and FarmManager.SPECTATOR_FARM_ID or 0
            if farm.farmId ~= nil and farm.farmId ~= spectator then
                table.insert(ids, farm.farmId)
            end
        end
    end
    return ids
end

--- Server: keeps a message (farmId nil / 0 = everybody).
function TornadoMessageLog:record(key, params, kind, farmId)
    if not isServer() or key == nil or key == "" or self.farms == nil then
        return
    end
    local farmIds = (farmId ~= nil and farmId ~= 0) and { farmId } or getAllFarmIds()
    local now = getAbsoluteMs()
    for _, id in ipairs(farmIds) do
        local farm = self:getFarm(id)
        table.insert(farm.recent, { id = self.nextId, key = key, params = params or {}, time = now, kind = kind or 3 })
        self.nextId = self.nextId + 1
        while #farm.recent > self.MAX_RECENT do
            table.remove(farm.recent, 1)
        end
        self:syncFarm(id)
    end
end

--- Recent messages older than RECENT_HOURS in-game hours are dropped (saved ones stay).
function TornadoMessageLog:onHourChanged()
    local limit = getAbsoluteMs() - self.RECENT_HOURS * self.MS_PER_HOUR
    for farmId, farm in pairs(self.farms) do
        local changed = false
        for i = #farm.recent, 1, -1 do
            if (farm.recent[i].time or 0) < limit then
                table.remove(farm.recent, i)
                changed = true
            end
        end
        if changed then
            self:syncFarm(farmId)
        end
    end
end

local function findIndex(list, id)
    for i, entry in ipairs(list) do
        if entry.id == id then
            return i
        end
    end
    return nil
end

--- Server: a recent message becomes a saved one.
function TornadoMessageLog:saveMessage(farmId, id)
    local farm = self:getFarm(farmId)
    local index = findIndex(farm.recent, id)
    if index == nil or findIndex(farm.saved, id) ~= nil then
        return false
    end
    table.insert(farm.saved, farm.recent[index])
    table.remove(farm.recent, index)
    while #farm.saved > self.MAX_SAVED do
        table.remove(farm.saved, 1)
    end
    self:syncFarm(farmId)
    return true
end

--- Server: removes a saved message.
function TornadoMessageLog:removeMessage(farmId, id)
    local farm = self:getFarm(farmId)
    local index = findIndex(farm.saved, id)
    if index == nil then
        return false
    end
    table.remove(farm.saved, index)
    self:syncFarm(farmId)
    return true
end

--- Server: removes every saved message of the farm.
function TornadoMessageLog:removeAllSaved(farmId)
    local farm = self:getFarm(farmId)
    if #farm.saved == 0 then
        return false
    end
    farm.saved = {}
    self:syncFarm(farmId)
    return true
end

--- Server: is the player behind this connection on that farm (or the admin / host)?
function TornadoMessageLog:canEdit(connection, farmId)
    if connection == nil then
        return true
    end
    local userManager = g_currentMission ~= nil and g_currentMission.userManager or nil
    local user = userManager ~= nil and userManager:getUserByConnection(connection) or nil
    if user == nil then
        return false
    end
    if user:getIsMasterUser() then
        return true
    end
    local farm = g_farmManager ~= nil and g_farmManager:getFarmByUserId(user:getId()) or nil
    return farm ~= nil and farm.farmId == farmId
end

--- Server: a player's save / remove request.
function TornadoMessageLog:handleAction(connection, farmId, action, id)
    if not self:canEdit(connection, farmId) then
        return
    end
    if action == TornadoMessageLogEvent.ACTION_SAVE then
        self:saveMessage(farmId, id)
    elseif action == TornadoMessageLogEvent.ACTION_REMOVE then
        self:removeMessage(farmId, id)
    elseif action == TornadoMessageLogEvent.ACTION_REMOVE_ALL then
        self:removeAllSaved(farmId)
    end
end

--- Any machine: asks the server to save / remove (runs directly on the server / in single player).
function TornadoMessageLog:request(action, id)
    local farmId = g_currentMission ~= nil and g_currentMission.getFarmId ~= nil and g_currentMission:getFarmId() or 0
    if farmId == nil or farmId == 0 then
        return
    end
    if isServer() then
        self:handleAction(nil, farmId, action, id)
    elseif g_client ~= nil and TornadoMessageLogEvent ~= nil then
        g_client:getServerConnection():sendEvent(TornadoMessageLogEvent.newAction(farmId, action, id))
    end
end

--- Server: sends a farm its list (multiplayer).
function TornadoMessageLog:syncFarm(farmId, connection)
    if not isServer() or not isMultiplayer() or TornadoMessageLogEvent == nil then
        if TornadoMenu ~= nil and TornadoMenu.INSTANCE ~= nil and TornadoMenu.INSTANCE.isOpen then
            TornadoMenu.INSTANCE:refreshAllPages()
        end
        return
    end
    local event = TornadoMessageLogEvent.newState(farmId, self:getFarm(farmId))
    if connection ~= nil then
        connection:sendEvent(event)
    elseif g_currentMission.broadcastEventToFarm ~= nil then
        g_currentMission:broadcastEventToFarm(event, farmId, false)
    end
end

function TornadoMessageLog:sendInitialState(connection)
    for farmId in pairs(self.farms) do
        self:syncFarm(farmId, connection)
    end
end

--- Client: the farm's list from the server.
function TornadoMessageLog:applyState(farmId, recent, saved)
    if self.farms == nil then
        return
    end
    self.farms[farmId] = { recent = recent or {}, saved = saved or {} }
    if TornadoMenu ~= nil and TornadoMenu.INSTANCE ~= nil and TornadoMenu.INSTANCE.isOpen then
        TornadoMenu.INSTANCE:refreshAllPages()
    end
end

--- The player's farm's messages, newest first: list = "recent" | "saved".
function TornadoMessageLog:getPlayerMessages(list)
    local farmId = g_currentMission ~= nil and g_currentMission.getFarmId ~= nil and g_currentMission:getFarmId() or 0
    local farm = self.farms ~= nil and self.farms[farmId] or nil
    local source = farm ~= nil and farm[list] or {}
    local messages = {}
    for i = #source, 1, -1 do
        table.insert(messages, source[i])
    end
    return messages
end

-- Message types (Messages tab filter and Type column), from the text key. Order = filter order.
TornadoMessageLog.TYPES = { "INSURANCE", "REPORT", "HAZARD", "TORNADO", "RECOVERY", "OTHER" }
TornadoMessageLog.TYPE_KEYS = {
    INSURANCE = "tp_msgtype_insurance", REPORT = "tp_msgtype_report", HAZARD = "tp_msgtype_hazard",
    TORNADO = "tp_msgtype_tornado", RECOVERY = "tp_msgtype_recovery", OTHER = "tp_msgtype_other",
}
-- Key prefixes per type (first match wins).
TornadoMessageLog.TYPE_PREFIXES = {
    { "tp_msg_ins_", "INSURANCE" },
    { "tp_msg_damage_report", "REPORT" }, { "tp_msg_storm_damage", "REPORT" },
    { "tp_msg_drought", "HAZARD" }, { "tp_msg_dry_spell", "HAZARD" }, { "tp_msg_field_fire", "HAZARD" },
    { "tp_msg_fire_out", "HAZARD" }, { "tp_msg_flood", "HAZARD" },
    { "tp_msg_touchdown", "TORNADO" }, { "tp_msg_outbreak", "TORNADO" },
    { "tp_msg_tow_bill", "RECOVERY" },
}

--- Type of a message (one of TYPES).
function TornadoMessageLog.getType(entry)
    local key = entry ~= nil and entry.key or ""
    for _, rule in ipairs(TornadoMessageLog.TYPE_PREFIXES) do
        if string.sub(key, 1, #rule[1]) == rule[1] then
            return rule[2]
        end
    end
    return "OTHER"
end

--- Text of a message in this player's language.
function TornadoMessageLog.getText(entry)
    if entry == nil or TornadoText == nil then
        return ""
    end
    return TornadoText.formatMessage(entry.key, entry.params)
end

--- "Day 6, 08:12" of a message.
function TornadoMessageLog.getTimeText(entry)
    local time = entry ~= nil and entry.time or 0
    local day = math.floor(time / TornadoMessageLog.MS_PER_DAY)
    local minutes = math.floor((time - day * TornadoMessageLog.MS_PER_DAY) / 60000)
    return string.format("%s %d, %02d:%02d", TornadoText ~= nil and TornadoText.get("tp_msg_day") or "Day", day,
        math.floor(minutes / 60), minutes % 60)
end

-- =========================================================================
-- SAVEGAME (TornadoMessages.xml)
-- =========================================================================

function TornadoMessageLog:getPath()
    if TornadoDestruction == nil or TornadoDestruction._resolveSavegamePath == nil then
        return nil
    end
    local dir = TornadoDestruction:_resolveSavegamePath()
    return dir ~= nil and (dir .. self.FILE) or nil
end

local function writeEntry(xmlId, key, entry)
    setXMLInt(xmlId, key .. "#id", entry.id)
    setXMLString(xmlId, key .. "#key", entry.key)
    setXMLFloat(xmlId, key .. "#time", entry.time or 0)
    setXMLInt(xmlId, key .. "#kind", entry.kind or 3)
    for p, param in ipairs(entry.params or {}) do
        local paramKey = string.format("%s.param(%d)", key, p - 1)
        setXMLInt(xmlId, paramKey .. "#type", param.type or 0)
        setXMLString(xmlId, paramKey .. "#value", tostring(param.value))
    end
end

local function readEntry(xmlId, key)
    local id = getXMLInt(xmlId, key .. "#id")
    if id == nil then
        return nil
    end
    local entry = { id = id, key = getXMLString(xmlId, key .. "#key") or "", time = getXMLFloat(xmlId, key .. "#time") or 0,
        kind = getXMLInt(xmlId, key .. "#kind") or 3, params = {} }
    local p = 0
    while true do
        local paramKey = string.format("%s.param(%d)", key, p)
        local paramType = getXMLInt(xmlId, paramKey .. "#type")
        if paramType == nil then break end
        local text = getXMLString(xmlId, paramKey .. "#value") or ""
        local value
        if TornadoText ~= nil and (paramType == TornadoText.PARAM_NUMBER or paramType == TornadoText.PARAM_MONEY) then
            value = tonumber(text) or 0
        else
            value = text
        end
        table.insert(entry.params, { type = paramType, value = value })
        p = p + 1
    end
    return entry
end

function TornadoMessageLog:loadState()
    local path = self:getPath()
    if path == nil or not fileExists(path) then
        return
    end
    local xmlId = loadXMLFile("TornadoMessages", path)
    if xmlId == nil or xmlId == 0 then
        return
    end
    self.nextId = getXMLInt(xmlId, "TornadoMessages#nextId") or 1
    local f = 0
    while true do
        local farmKey = string.format("TornadoMessages.farm(%d)", f)
        local farmId = getXMLInt(xmlId, farmKey .. "#id")
        if farmId == nil then break end
        local farm = self:getFarm(farmId)
        for _, list in ipairs({ "recent", "saved" }) do
            local i = 0
            while true do
                local entry = readEntry(xmlId, string.format("%s.%s.message(%d)", farmKey, list, i))
                if entry == nil then break end
                table.insert(farm[list], entry)
                self.nextId = math.max(self.nextId, entry.id + 1)
                i = i + 1
            end
        end
        f = f + 1
    end
    delete(xmlId)
end

function TornadoMessageLog:save()
    if not isServer() then
        return
    end
    local path = self:getPath()
    if path == nil then
        return
    end
    local xmlId = createXMLFile("TornadoMessages", path, "TornadoMessages")
    if xmlId == nil or xmlId == 0 then
        return
    end
    setXMLInt(xmlId, "TornadoMessages#nextId", self.nextId or 1)
    local farmIds = {}
    for farmId in pairs(self.farms or {}) do table.insert(farmIds, farmId) end
    table.sort(farmIds)
    for f, farmId in ipairs(farmIds) do
        local farmKey = string.format("TornadoMessages.farm(%d)", f - 1)
        setXMLInt(xmlId, farmKey .. "#id", farmId)
        for _, list in ipairs({ "recent", "saved" }) do
            for i, entry in ipairs(self.farms[farmId][list]) do
                writeEntry(xmlId, string.format("%s.%s.message(%d)", farmKey, list, i - 1), entry)
            end
        end
    end
    saveXMLFile(xmlId)
    delete(xmlId)
end
