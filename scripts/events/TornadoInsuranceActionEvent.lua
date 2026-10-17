---@class TornadoInsuranceActionEvent
---@description client -> server: a player asks the insurance for something (refresh, read inbox; buy / change /
--- cancel a policy in later phases). The server checks the permission (TornadoInsurance:canManage) and runs it;
--- the result comes back as a message (TornadoMessageEvent) and as the farm's new state.
---   farm id, action name, arguments (one string, the action reads it)

-- Events may only be registered while no mission exists (when the mod's scripts load). If this file is
-- loaded again for another savegame in the same game session, keep using the class registered the first time.
TornadoInsuranceActionEvent = EventIds.getEventClassByName("TornadoInsuranceActionEvent") or {}
local TornadoInsuranceActionEvent_mt = Class(TornadoInsuranceActionEvent, Event)

if EventIds.getEventClassByName("TornadoInsuranceActionEvent") == nil then
    InitEventClass(TornadoInsuranceActionEvent, "TornadoInsuranceActionEvent")
end

function TornadoInsuranceActionEvent.emptyNew()
    return Event.new(TornadoInsuranceActionEvent_mt)
end

function TornadoInsuranceActionEvent.new(farmId, action, args)
    local self = TornadoInsuranceActionEvent.emptyNew()
    self.farmId = farmId or 0
    self.action = action or ""
    self.args = args or ""
    return self
end

function TornadoInsuranceActionEvent:writeStream(streamId, connection)
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    streamWriteString(streamId, self.action)
    streamWriteString(streamId, self.args)
end

function TornadoInsuranceActionEvent:readStream(streamId, connection)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    self.action = streamReadString(streamId)
    self.args = streamReadString(streamId)
    self:run(connection)
end

function TornadoInsuranceActionEvent:run(connection)
    if connection:getIsServer() or TornadoInsurance == nil then
        return
    end
    local resultKey = TornadoInsurance:handleAction(connection, self.farmId, self.action, self.args)
    if resultKey ~= nil and TornadoMessageEvent ~= nil then
        connection:sendEvent(TornadoMessageEvent.new(resultKey, {}, TornadoSync ~= nil and TornadoSync.MSG_INFO or 3))
    end
end
