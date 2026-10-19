---@class TornadoPageMessages
---@description Messages tab: the message history of the player's farm (TornadoMessageLog).
--- Recent messages (last 24 in-game hours): pick one, Show (full text in the game's info dialog), Save.
--- Saved messages: pick one, Show, Remove. Every player sees their own farm; saving / removing is checked on the
--- server. Nothing here is a setting, so the panel is never marked dirty.

local Page = TornadoMenuPage

local function hasLog()
    return TornadoMessageLog ~= nil and TornadoMessageLog.farms ~= nil
end

-- Selected message id per list (this machine only).
local selected = { recent = nil, saved = nil }

local function getMessages(list)
    return TornadoMessageLog:getPlayerMessages(list)
end

local function getSelected(list)
    local messages = getMessages(list)
    for _, entry in ipairs(messages) do
        if entry.id == selected[list] then
            return entry
        end
    end
    return messages[1]
end

local function shorten(text, length)
    if string.len(text) <= length then
        return text
    end
    return string.sub(text, 1, length - 3) .. "..."
end

local function listRow(id, list)
    return {
        id = id,
        kind = Page.KIND_CHOICE,
        requires = hasLog,
        localOnly = true,
        keepClean = true,
        options = function()
            local options = {}
            for _, entry in ipairs(getMessages(list)) do
                options[#options + 1] = { value = entry.id, text = TornadoMessageLog.getTimeText(entry) .. " - " ..
                    shorten(TornadoMessageLog.getText(entry), 60) }
            end
            if #options == 0 then
                options[1] = { value = 0, text = TornadoText.get("tp_msg_none") }
            end
            return options
        end,
        get = function()
            local entry = getSelected(list)
            return entry ~= nil and entry.id or 0
        end,
        set = function(value)
            selected[list] = value
            return nil
        end,
    }
end

local function showRow(id, list)
    return {
        id = id,
        kind = Page.KIND_ACTION,
        requires = hasLog,
        localOnly = true,
        keepClean = true,
        run = function()
            local entry = getSelected(list)
            if entry == nil then
                return TornadoText.get("tp_msg_none")
            end
            local text = TornadoMessageLog.getTimeText(entry) .. "\n\n" .. TornadoMessageLog.getText(entry)
            if InfoDialog ~= nil and InfoDialog.show ~= nil then
                InfoDialog.show(text)
                return nil
            end
            return text
        end,
    }
end

TornadoPageMessages = TornadoMenuPage.new("Messages", "Messages", {
    -- Recent (24 h)
    listRow("msgRecent", "recent"),
    showRow("msgRecentShow", "recent"),
    {
        id = "msgRecentSave",
        kind = Page.KIND_ACTION,
        requires = hasLog,
        localOnly = true,
        keepClean = true,
        run = function()
            local entry = getSelected("recent")
            if entry == nil then
                return TornadoText.get("tp_msg_none")
            end
            TornadoMessageLog:request(TornadoMessageLogEvent.ACTION_SAVE, entry.id)
            selected.recent = nil
            selected.saved = entry.id
            return TornadoText.get("tp_msg_saved_done")
        end,
    },

    -- Saved (until removed)
    listRow("msgSaved", "saved"),
    showRow("msgSavedShow", "saved"),
    {
        id = "msgSavedRemove",
        kind = Page.KIND_ACTION,
        requires = hasLog,
        localOnly = true,
        keepClean = true,
        confirm = "tp_confirm_msg_remove",
        run = function()
            local entry = getSelected("saved")
            if entry == nil then
                return TornadoText.get("tp_msg_none")
            end
            TornadoMessageLog:request(TornadoMessageLogEvent.ACTION_REMOVE, entry.id)
            selected.saved = nil
            return TornadoText.get("tp_msg_removed_done")
        end,
    },
})
