---@class TornadoPageMessages
---@version 2.0 (full-width table)
---@description Messages tab: the message history of the player's farm (TornadoMessageLog) as a table.
--- Top: Recent / Saved switch (with counts and "new"), type filter. Left: a TornadoTable of ROWS rows
--- (Time | Type | Message), scrolled with the mouse wheel, the scroll buttons or controller focus. Right: the
--- selected message in full, Save (Recent) or Remove (Saved), Remove all saved. A dot marks messages that came in
--- since the tab was last opened in this session; the tab button shows how many. Saving / removing is checked on
--- the server; nothing here is a setting, so the panel is never marked dirty.
--- Uses the normal TornadoMenuPage defs (actions / one choice) - only the drawing is page-specific.

local Page = TornadoMenuPage

local ROWS = 12
local NEW_MARK = "*"   -- plain ASCII: the game's font has no bullet / circle character (log warning "Character 9679")
local MESSAGE_CHARS = 64

local function hasLog()
    return TornadoMessageLog ~= nil and TornadoMessageLog.farms ~= nil
end

-- Page state (this machine only).
local state = {
    list = "recent",          -- "recent" | "saved"
    filter = "ALL",           -- "ALL" or one of TornadoMessageLog.TYPES
    seenUpTo = nil,           -- newest message time when the tab was last opened (nil = not set yet)
    baseline = nil,           -- seenUpTo before the current visit: newer messages get the dot
}
local table_ = TornadoTable.new(ROWS)

local function getAll(list)
    return hasLog() and TornadoMessageLog:getPlayerMessages(list) or {}
end

local function getFiltered()
    local entries = {}
    for _, entry in ipairs(getAll(state.list)) do
        if state.filter == "ALL" or TornadoMessageLog.getType(entry) == state.filter then
            table.insert(entries, entry)
        end
    end
    -- Newest first by message time (the Saved list is otherwise in the order things were saved).
    table.sort(entries, function(a, b)
        if (a.time or 0) ~= (b.time or 0) then
            return (a.time or 0) > (b.time or 0)
        end
        return (a.id or 0) > (b.id or 0)
    end)
    return entries
end

local function newestTime()
    local newest = 0
    for _, list in ipairs({ "recent", "saved" }) do
        for _, entry in ipairs(getAll(list)) do
            newest = math.max(newest, entry.time or 0)
        end
    end
    return newest
end

local function countNewer(list, since)
    local count = 0
    if since == nil then
        return 0
    end
    for _, entry in ipairs(getAll(list)) do
        if (entry.time or 0) > since then
            count = count + 1
        end
    end
    return count
end

local function shorten(text, length)
    text = string.gsub(text or "", "\n", " ")
    if string.len(text) <= length then
        return text
    end
    return string.sub(text, 1, length - 3) .. "..."
end

local function typeText(entry)
    return TornadoText.get(TornadoMessageLog.TYPE_KEYS[TornadoMessageLog.getType(entry)] or "tp_msgtype_other")
end

local function switchList(list)
    state.list = list
    table_:reset(getFiltered())
    return nil
end

-- =========================================================================
-- CONTROL DEFINITIONS
-- =========================================================================

local function actionDef(id, run, extra)
    local def = { id = id, kind = Page.KIND_ACTION, requires = hasLog, localOnly = true, keepClean = true, run = run }
    for k, v in pairs(extra or {}) do
        def[k] = v
    end
    return def
end

local defs = {
    actionDef("msgTabRecent", function() return switchList("recent") end),
    actionDef("msgTabSaved", function() return switchList("saved") end),
    {
        id = "msgFilter",
        kind = Page.KIND_CHOICE,
        requires = hasLog,
        localOnly = true,
        keepClean = true,
        options = function()
            local options = { { value = "ALL", text = TornadoText.get("tp_msgtype_all") } }
            for _, kind in ipairs(TornadoMessageLog ~= nil and TornadoMessageLog.TYPES or {}) do
                options[#options + 1] = { value = kind, text = TornadoText.get(TornadoMessageLog.TYPE_KEYS[kind]) }
            end
            return options
        end,
        get = function() return state.filter end,
        set = function(value)
            state.filter = value
            table_:reset(getFiltered())
            return nil
        end,
    },
}
for slot = 1, ROWS do
    defs[#defs + 1] = actionDef("msgRow" .. slot, function()
        table_:selectSlot(slot)
        return nil
    end, { slot = slot })
end
defs[#defs + 1] = actionDef("msgScrollUp", function() table_:scroll(-ROWS) return nil end)
defs[#defs + 1] = actionDef("msgScrollDown", function() table_:scroll(ROWS) return nil end)
defs[#defs + 1] = actionDef("msgAction", function()
    local entry = table_:getSelected()
    if entry == nil then
        return TornadoText.get("tp_msg_none")
    end
    if state.list == "recent" then
        TornadoMessageLog:request(TornadoMessageLogEvent.ACTION_SAVE, entry.id)
        return TornadoText.get("tp_msg_saved_done")
    end
    TornadoMessageLog:request(TornadoMessageLogEvent.ACTION_REMOVE, entry.id)
    return TornadoText.get("tp_msg_removed_done")
end)
defs[#defs + 1] = actionDef("msgRemoveAll", function()
    TornadoMessageLog:request(TornadoMessageLogEvent.ACTION_REMOVE_ALL, 0)
    return TornadoText.get("tp_msg_removed_all_done")
end, { confirm = "tp_confirm_msg_remove_all" })

TornadoPageMessages = TornadoMenuPage.new("Messages", "Messages", defs)
TornadoPageMessages.noLayout = true      -- full-width page: no scrolling settings list, no tooltip column
TornadoPageMessages.table = table_
TornadoPageMessages.state = state

local function findDef(id)
    for _, def in ipairs(TornadoPageMessages.defs) do
        if def.id == id then
            return def
        end
    end
    return nil
end

-- =========================================================================
-- BINDING + DRAWING
-- =========================================================================

local baseBind = TornadoMenuPage.bind
function TornadoPageMessages:bind(menu)
    baseBind(self, menu)
    self.tableElement = menu.msgTable
    -- Selected row look: the row and every child ask getIsSelected() (same trick as the tab buttons).
    for slot = 1, ROWS do
        local row = menu["msgRow" .. slot]
        if row ~= nil then
            local isSelected = function()
                return table_:getSelectedSlot() == slot
            end
            row.getIsSelected = isSelected
            for _, child in ipairs(row.elements or {}) do
                child.getIsSelected = isSelected
            end
        end
    end
end

local function setText(element, text)
    if element ~= nil then
        element:setText(text or "")
    end
end

local function getChild(row, name)
    return row ~= nil and row.getDescendantByName ~= nil and row:getDescendantByName(name) or nil
end

--- Draws rows, detail panel, buttons and counts from the current state (after the base refresh).
function TornadoPageMessages:onRefresh()
    local menu = self.menu
    if menu == nil or not hasLog() then
        return
    end
    if state.seenUpTo == nil then
        state.seenUpTo = newestTime()   -- messages already there at load are not "new"
    end
    table_:setEntries(getFiltered())

    local isActive = menu.activePageIndex ~= nil and menu.pages[menu.activePageIndex] == self
    local since = isActive and state.baseline or state.seenUpTo
    for slot = 1, ROWS do
        local row = menu["msgRow" .. slot]
        local entry = table_:getVisible(slot)
        if row ~= nil then
            row:setVisible(entry ~= nil)
            row:setDisabled(entry == nil)
            if entry ~= nil then
                setText(getChild(row, "mark"), (since ~= nil and (entry.time or 0) > since) and NEW_MARK or "")
                setText(getChild(row, "time"), TornadoMessageLog.getTimeText(entry))
                setText(getChild(row, "type"), typeText(entry))
                setText(getChild(row, "text"), shorten(TornadoMessageLog.getText(entry), MESSAGE_CHARS))
            end
        end
    end

    -- Recent / Saved buttons with counts.
    local numRecent, numSaved = #getAll("recent"), #getAll("saved")
    local newRecent = countNewer("recent", since)
    setText(menu.msgTabRecent, newRecent > 0 and TornadoText.format("tp_msg_recent_tab_new", numRecent, newRecent)
        or TornadoText.format("tp_msg_recent_tab", numRecent))
    setText(menu.msgTabSaved, TornadoText.format("tp_msg_saved_tab", numSaved))
    -- The panel's tab button: how many arrived since the tab was last opened.
    local unseen = isActive and 0 or (countNewer("recent", state.seenUpTo) + countNewer("saved", state.seenUpTo))
    setText(self.tabElement, unseen > 0 and TornadoText.format("tp_tab_messages_new", unseen) or TornadoText.get("tp_tab_messages"))

    -- Scroll buttons + "showing x - y of n".
    if menu.msgScrollUp ~= nil then menu.msgScrollUp:setDisabled(not table_:canScrollUp()) end
    if menu.msgScrollDown ~= nil then menu.msgScrollDown:setDisabled(not table_:canScrollDown()) end
    local first, last, total = table_:getRange()
    local hidden = #getAll(state.list) - total     -- messages the type filter hides
    local infoText
    if total > 0 then
        infoText = TornadoText.format("tp_msg_showing", first, last, total)
        if hidden > 0 then
            infoText = infoText .. " " .. TornadoText.format("tp_msg_hidden_short", hidden)
        end
    elseif hidden > 0 then
        infoText = TornadoText.format("tp_msg_hidden", hidden)
    else
        infoText = TornadoText.get(state.list == "recent" and "tp_msg_none_recent" or "tp_msg_none_saved")
    end
    setText(menu.msgInfo, infoText)

    -- Detail panel + actions.
    local entry = table_:getSelected()
    setText(menu.msgDetailTime, entry ~= nil and TornadoMessageLog.getTimeText(entry) or "")
    setText(menu.msgDetailType, entry ~= nil and typeText(entry) or "")
    local emptyText = hidden > 0 and TornadoText.format("tp_msg_hidden", hidden) or TornadoText.get("tp_msg_none")
    setText(menu.msgDetailText, entry ~= nil and TornadoMessageLog.getText(entry) or emptyText)
    local actionDefinition = findDef("msgAction")
    if actionDefinition ~= nil then
        actionDefinition.confirm = state.list == "saved" and "tp_confirm_msg_remove" or nil
    end
    if menu.msgAction ~= nil then
        setText(menu.msgAction, TornadoText.get(state.list == "recent" and "tp_btn_save" or "tp_btn_remove"))
        menu.msgAction:setDisabled(entry == nil)
    end
    if menu.msgRemoveAll ~= nil then
        menu.msgRemoveAll:setVisible(state.list == "saved")
        menu.msgRemoveAll:setDisabled(numSaved == 0)
    end
end

--- The tab became the active one: everything newer than the last visit gets the dot during this visit.
--- The type filter starts at "All" on every visit, so a filter left over from before never hides new messages.
function TornadoPageMessages:onShow()
    state.baseline = state.seenUpTo
    state.seenUpTo = newestTime()
    if state.filter ~= "ALL" then
        state.filter = "ALL"
        table_:reset(getFiltered())
    end
    self:refresh()
end

--- Row focus (controller / keyboard) selects that row; redraws this page only.
function TornadoPageMessages:onRowFocus(def)
    if def ~= nil and def.slot ~= nil and table_:selectSlot(def.slot) then
        self:refresh()
    end
end

--- Mouse wheel over the table: one row per notch.
function TornadoPageMessages:onMouseWheel(posX, posY, direction)
    local area = self.tableElement
    if area == nil or area.absPosition == nil or area.absSize == nil or GuiUtils == nil then
        return false
    end
    if not GuiUtils.checkOverlayOverlap(posX, posY, area.absPosition[1], area.absPosition[2], area.absSize[1], area.absSize[2]) then
        return false
    end
    if table_:scroll(direction) then
        self:refresh()
    end
    return true
end

--- t_dev messages: what the page holds and what every row element shows (to find display problems in game).
function TornadoPageMessages:debugDump()
    local menu = self.menu
    print("---------------- MESSAGES PAGE ----------------")
    print(string.format("  list %s  filter %s  recent %d  saved %d  filtered %d  offset %d  selected %s  seenUpTo %s  baseline %s",
        state.list, state.filter, #getAll("recent"), #getAll("saved"), #table_.entries, table_.offset,
        tostring(table_.selectedKey), tostring(state.seenUpTo), tostring(state.baseline)))
    if menu == nil then
        print("  panel not built (no GUI)")
        return "Messages page: no panel."
    end
    print(string.format("  panel open %s  active tab %s  info '%s'", tostring(menu.isOpen),
        tostring(menu.pages[menu.activePageIndex] ~= nil and menu.pages[menu.activePageIndex].key), tostring(menu.msgInfo ~= nil and menu.msgInfo.text)))
    for slot = 1, ROWS do
        local row = menu["msgRow" .. slot]
        if row == nil then
            print(string.format("  row %2d MISSING", slot))
        else
            local textCell = getChild(row, "text")
            print(string.format("  row %2d visible %-5s disabled %-5s parent visible %-5s pos %.3f %.3f size %.3f %.3f  text '%s'",
                slot, tostring(row:getIsVisible()), tostring(row:getIsDisabled()),
                tostring(row.parent ~= nil and row.parent:getIsVisible()), row.absPosition ~= nil and row.absPosition[1] or -1,
                row.absPosition ~= nil and row.absPosition[2] or -1, row.absSize ~= nil and row.absSize[1] or -1,
                row.absSize ~= nil and row.absSize[2] or -1, tostring(textCell ~= nil and textCell.text)))
        end
    end
    print("-----------------------------------------------")
    return "Messages page: state printed above."
end

--- Focus on the selected row when it is visible, else on the Recent button.
function TornadoPageMessages:getFirstFocusElement()
    local slot = table_:getSelectedSlot()
    local menu = self.menu
    if slot ~= nil and menu ~= nil and menu["msgRow" .. slot] ~= nil then
        return menu["msgRow" .. slot]
    end
    return menu ~= nil and menu.msgTabRecent or nil
end
