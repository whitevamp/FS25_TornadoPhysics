---@class TornadoMessageLogEvent
---@description Message history (TornadoMessageLog) in multiplayer:
---   STATE  server -> the players of one farm (or a joining player): farm id, recent + saved messages
---          (id, key, parameters, in-game time)
---   ACTION client -> server: farm id, save / remove / remove all saved, message id (the server checks the
---          player is on that farm)

-- Events may only be registered while no mission exists (when the mod's scripts load). If this file is
-- loaded again for another savegame in the same game session, keep using the class registered the first time.
TornadoMessageLogEvent = EventIds.getEventClassByName("TornadoMessageLogEvent") or {}
local TornadoMessageLogEvent_mt = Class(TornadoMessageLogEvent, Event)

if EventIds.getEventClassByName("TornadoMessageLogEvent") == nil then
    InitEventClass(TornadoMessageLogEvent, "TornadoMessageLogEvent")
end

TornadoMessageLogEvent.MODE_STATE = 0
TornadoMessageLogEvent.MODE_ACTION = 1
TornadoMessageLogEvent.ACTION_SAVE = 1
TornadoMessageLogEvent.ACTION_REMOVE = 2
TornadoMessageLogEvent.ACTION_REMOVE_ALL = 3   -- every saved message of the farm (id unused)
TornadoMessageLogEvent.MAX_ENTRIES = 63     -- 6 bits per list
TornadoMessageLogEvent.MAX_PARAMS = 15      -- 4 bits

function TornadoMessageLogEvent.emptyNew()
    return Event.new(TornadoMessageLogEvent_mt)
end

function TornadoMessageLogEvent.newState(farmId, farm)
    local self = TornadoMessageLogEvent.emptyNew()
    self.mode = TornadoMessageLogEvent.MODE_STATE
    self.farmId = farmId or 0
    self.recent = farm ~= nil and farm.recent or {}
    self.saved = farm ~= nil and farm.saved or {}
    return self
end

function TornadoMessageLogEvent.newAction(farmId, action, id)
    local self = TornadoMessageLogEvent.emptyNew()
    self.mode = TornadoMessageLogEvent.MODE_ACTION
    self.farmId = farmId or 0
    self.action = action
    self.id = id or 0
    return self
end

local function isNumberParam(paramType)
    return paramType == TornadoText.PARAM_NUMBER or paramType == TornadoText.PARAM_MONEY
end

local function writeList(streamId, list)
    local first = math.max(1, #list - TornadoMessageLogEvent.MAX_ENTRIES + 1)
    streamWriteUIntN(streamId, #list - first + 1, 6)
    for i = first, #list do
        local entry = list[i]
        streamWriteInt32(streamId, entry.id or 0)
        streamWriteString(streamId, entry.key or "")
        streamWriteFloat32(streamId, entry.time or 0)
        local params = entry.params or {}
        local count = math.min(#params, TornadoMessageLogEvent.MAX_PARAMS)
        streamWriteUIntN(streamId, count, 4)
        for p = 1, count do
            local param = params[p]
            streamWriteUIntN(streamId, param.type or 0, 2)
            if isNumberParam(param.type) then
                streamWriteFloat32(streamId, tonumber(param.value) or 0)
            else
                streamWriteString(streamId, tostring(param.value or ""))
            end
        end
    end
end

local function readList(streamId)
    local list = {}
    local count = streamReadUIntN(streamId, 6)
    for _ = 1, count do
        local entry = { params = {} }
        entry.id = streamReadInt32(streamId)
        entry.key = streamReadString(streamId)
        entry.time = streamReadFloat32(streamId)
        local numParams = streamReadUIntN(streamId, 4)
        for p = 1, numParams do
            local paramType = streamReadUIntN(streamId, 2)
            local value
            if isNumberParam(paramType) then
                value = streamReadFloat32(streamId)
            else
                value = streamReadString(streamId)
            end
            entry.params[p] = { type = paramType, value = value }
        end
        table.insert(list, entry)
    end
    return list
end

function TornadoMessageLogEvent:writeStream(streamId, connection)
    streamWriteUIntN(streamId, self.mode, 1)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    if self.mode == TornadoMessageLogEvent.MODE_STATE then
        writeList(streamId, self.recent)
        writeList(streamId, self.saved)
    else
        streamWriteUIntN(streamId, self.action or 0, 2)
        streamWriteInt32(streamId, self.id or 0)
    end
end

function TornadoMessageLogEvent:readStream(streamId, connection)
    self.mode = streamReadUIntN(streamId, 1)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    if self.mode == TornadoMessageLogEvent.MODE_STATE then
        self.recent = readList(streamId)
        self.saved = readList(streamId)
    else
        self.action = streamReadUIntN(streamId, 2)
        self.id = streamReadInt32(streamId)
    end
    self:run(connection)
end

function TornadoMessageLogEvent:run(connection)
    if TornadoMessageLog == nil then
        return
    end
    if self.mode == TornadoMessageLogEvent.MODE_STATE then
        if connection:getIsServer() then
            TornadoMessageLog:applyState(self.farmId, self.recent, self.saved)
        end
    elseif not connection:getIsServer() then
        TornadoMessageLog:handleAction(connection, self.farmId, self.action, self.id)
    end
end
