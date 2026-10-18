---@class TornadoInsuranceStateEvent
---@description server -> the players of one farm (or one joining player): that farm's insurance state, so the
--- control panel can show it. The server owns the state; clients only display it.
---   farm id, premiums paid, payouts received, crop policy (plan, coverage, status, open claims),
---   inbox (key + parameters, day, read) - the newest MAX_INBOX

-- Events may only be registered while no mission exists (when the mod's scripts load). If this file is
-- loaded again for another savegame in the same game session, keep using the class registered the first time.
TornadoInsuranceStateEvent = EventIds.getEventClassByName("TornadoInsuranceStateEvent") or {}
local TornadoInsuranceStateEvent_mt = Class(TornadoInsuranceStateEvent, Event)

if EventIds.getEventClassByName("TornadoInsuranceStateEvent") == nil then
    InitEventClass(TornadoInsuranceStateEvent, "TornadoInsuranceStateEvent")
end

TornadoInsuranceStateEvent.MAX_INBOX = 50   -- 6 bits
TornadoInsuranceStateEvent.MAX_PARAMS = 15  -- 4 bits

function TornadoInsuranceStateEvent.emptyNew()
    return Event.new(TornadoInsuranceStateEvent_mt)
end

function TornadoInsuranceStateEvent.new(farmId, farm)
    local self = TornadoInsuranceStateEvent.emptyNew()
    self.farmId = farmId or 0
    self.state = farm
    return self
end

local function isNumberParam(paramType)
    return paramType == TornadoText.PARAM_NUMBER or paramType == TornadoText.PARAM_MONEY
end

function TornadoInsuranceStateEvent:writeStream(streamId, connection)
    local state = self.state or {}
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    streamWriteFloat32(streamId, state.premiumsTotal or 0)
    streamWriteFloat32(streamId, state.payoutsTotal or 0)

    local crop = state.crop
    streamWriteString(streamId, crop ~= nil and crop.plan or "")
    streamWriteFloat32(streamId, crop ~= nil and crop.coverage or 0)
    streamWriteString(streamId, crop ~= nil and crop.status or "")
    local openClaims = TornadoInsuranceCrop ~= nil and TornadoInsuranceCrop:getOpenClaimCount(state) or 0
    streamWriteUIntN(streamId, math.min(openClaims, 255), 8)

    local inbox = state.inbox or {}
    local first = math.max(1, #inbox - TornadoInsuranceStateEvent.MAX_INBOX + 1)
    streamWriteUIntN(streamId, #inbox - first + 1, 6)
    for i = first, #inbox do
        local message = inbox[i]
        streamWriteString(streamId, message.key or "")
        streamWriteInt32(streamId, message.day or 0)
        streamWriteBool(streamId, message.read == true)
        local params = message.params or {}
        local count = math.min(#params, TornadoInsuranceStateEvent.MAX_PARAMS)
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

function TornadoInsuranceStateEvent:readStream(streamId, connection)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    local state = { inbox = {} }
    state.premiumsTotal = streamReadFloat32(streamId)
    state.payoutsTotal = streamReadFloat32(streamId)
    state.cropPlan = streamReadString(streamId)
    state.cropCoverage = streamReadFloat32(streamId)
    state.cropStatus = streamReadString(streamId)
    state.openClaims = streamReadUIntN(streamId, 8)
    local count = streamReadUIntN(streamId, 6)
    for _ = 1, count do
        local message = { params = {} }
        message.key = streamReadString(streamId)
        message.day = streamReadInt32(streamId)
        message.read = streamReadBool(streamId)
        local numParams = streamReadUIntN(streamId, 4)
        for p = 1, numParams do
            local paramType = streamReadUIntN(streamId, 2)
            local value
            if isNumberParam(paramType) then
                value = streamReadFloat32(streamId)
            else
                value = streamReadString(streamId)
            end
            message.params[p] = { type = paramType, value = value }
        end
        table.insert(state.inbox, message)
    end
    self.state = state
    self:run(connection)
end

function TornadoInsuranceStateEvent:run(connection)
    if not connection:getIsServer() or TornadoInsurance == nil then
        return
    end
    TornadoInsurance:applyFarmState(self.farmId, self.state)
end
