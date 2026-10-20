---@class TornadoMessageEvent
---@description server -> clients: on-screen messages from server-side gameplay
--- (animal losses, emergency tow bills, ...). Kinds are TornadoSync.MSG_*.
--- The text travels as a key plus parameters (TornadoText), so each player reads it in their own language.
--- The text travels as a key plus parameters (TornadoText), so each player reads it in their own language.

-- Events may only be registered while no mission exists (when the mod's scripts load). If this file is
-- loaded again for another savegame in the same game session, keep using the class registered the first time.
TornadoMessageEvent = EventIds.getEventClassByName("TornadoMessageEvent") or {}
local TornadoMessageEvent_mt = Class(TornadoMessageEvent, Event)

if EventIds.getEventClassByName("TornadoMessageEvent") == nil then
    InitEventClass(TornadoMessageEvent, "TornadoMessageEvent")
end

TornadoMessageEvent.BLINK_DURATION = 10000

function TornadoMessageEvent.emptyNew()
    return Event.new(TornadoMessageEvent_mt)
end

TornadoMessageEvent.MAX_PARAMS = 15

function TornadoMessageEvent.new(key, params, kind)
    local self = TornadoMessageEvent.emptyNew()
    self.key = key
    self.params = params or {}
    self.kind = kind
    return self
end

function TornadoMessageEvent:writeStream(streamId, connection)
    streamWriteString(streamId, self.key or "")
    streamWriteUIntN(streamId, self.kind or TornadoSync.MSG_INFO, 2)
    local count = math.min(#self.params, TornadoMessageEvent.MAX_PARAMS)
    streamWriteUIntN(streamId, count, 4)
    for i = 1, count do
        local param = self.params[i]
        streamWriteUIntN(streamId, param.type, 2)
        if param.type == TornadoText.PARAM_NUMBER or param.type == TornadoText.PARAM_MONEY then
            streamWriteFloat32(streamId, param.value)
        else
            streamWriteString(streamId, param.value)
        end
    end
end

function TornadoMessageEvent:readStream(streamId, connection)
    self.key = streamReadString(streamId)
    self.kind = streamReadUIntN(streamId, 2)
    self.params = {}
    local count = streamReadUIntN(streamId, 4)
    for i = 1, count do
        local paramType = streamReadUIntN(streamId, 2)
        local value
        if paramType == TornadoText.PARAM_NUMBER or paramType == TornadoText.PARAM_MONEY then
            value = streamReadFloat32(streamId)
        else
            value = streamReadString(streamId)
        end
        self.params[i] = { type = paramType, value = value }
    end
    self:run(connection)
end

function TornadoMessageEvent:run(connection)
    if self.key ~= nil and self.key ~= "" then
        TornadoMessageEvent.show(TornadoText.formatMessage(self.key, self.params), self.kind)
    end
end

-- The game's side notifications do not wrap: a long letter would run across the screen (over the key help).
-- On screen only its first sentence shows (half a list of choices would mislead); the Messages tab keeps the whole letter.
TornadoMessageEvent.MAX_SCREEN_CHARS = 140

--- Text for the side notification: as is when short, else the first sentence + "(full letter on the Messages tab)".
function TornadoMessageEvent.shortenForScreen(text)
    if text == nil or string.len(text) <= TornadoMessageEvent.MAX_SCREEN_CHARS then
        return text
    end
    local limit = TornadoMessageEvent.MAX_SCREEN_CHARS
    local cut = string.find(text, "[%.!?] ")
    if cut ~= nil and cut > limit then
        cut = nil
    end
    local short
    local start
    if cut ~= nil then
        short = string.sub(text, 1, cut)
    else
        -- No sentence end in reach: cut at the last space (never inside a multi-byte character).
        local space = nil
        start = 1
        while true do
            local pos = string.find(text, " ", start, true)
            if pos == nil or pos > limit then
                break
            end
            space = pos
            start = pos + 1
        end
        short = string.sub(text, 1, (space or limit) - 1) .. " ..."
    end
    return short .. " " .. TornadoText.get("tp_msg_more_on_tab")
end

--- Shows a message on this machine (no-op on a dedicated server, which has no screen).
function TornadoMessageEvent.show(text, kind)
    if g_currentMission == nil or text == nil or text == "" or g_dedicatedServer ~= nil then
        return
    end
    if kind ~= TornadoSync.MSG_BLINKING then
        text = TornadoMessageEvent.shortenForScreen(text)
    end
    if kind == TornadoSync.MSG_BLINKING then
        g_currentMission:showBlinkingWarning(text, TornadoMessageEvent.BLINK_DURATION)
    elseif kind == TornadoSync.MSG_CRITICAL then
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, text)
    else
        g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_INFO, text)
    end
end
