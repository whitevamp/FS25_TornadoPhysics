-- Offline smoke test for scripts/gui/pages/TornadoPageMessages.lua (the Messages table page) - Lua 5.1.
-- Run from the mod root:
--     lua-5.1.5_Win64_bin/lua5.1.exe tools/test/test_msgpage.lua
-- Real: TornadoMenuPage, TornadoTable, TornadoMessageLog (stubbed game), the page. Fake GUI elements record what
-- the page draws. Exit code 0 = all checks passed.

-- ---------------------------------------------------------------- game stubs (like test_messagelog)
local files, handles, nextHandle = {}, {}, 1
function createXMLFile(_, path) local h = nextHandle nextHandle = nextHandle + 1 handles[h] = { path = path, data = {} } return h end
function loadXMLFile(_, path) if files[path] == nil then return 0 end local h = nextHandle nextHandle = nextHandle + 1 handles[h] = { path = path, data = files[path] } return h end
local function setter(h, key, value) handles[h].data[key] = value end
setXMLFloat, setXMLInt, setXMLBool, setXMLString = setter, setter, setter, setter
local function getter(h, key) return handles[h].data[key] end
getXMLFloat, getXMLInt, getXMLBool, getXMLString = getter, getter, getter, getter
function saveXMLFile(h) files[handles[h].path] = handles[h].data end
function delete(h) handles[h] = nil end
function fileExists(path) return files[path] ~= nil end
MessageType = { HOUR_CHANGED = 1 }
g_messageCenter = { subscribe = function() end, unsubscribeAll = function() end }
FarmManager = { SPECTATOR_FARM_ID = 0 }
g_farmManager = { getFarms = function() return { { farmId = 0 }, { farmId = 1 } } end }
local environment = { currentMonotonicDay = 3, dayTime = 8 * 3600000 }
g_currentMission = { getIsServer = function() return true end, getFarmId = function() return 1 end, environment = environment }
TornadoSync = nil
local texts = {
    tp_msg_recent_tab = "Recent (%d)", tp_msg_recent_tab_new = "Recent (%d, %d new)", tp_msg_saved_tab = "Saved (%d)",
    tp_tab_messages = "Messages", tp_tab_messages_new = "Messages (%d)", tp_msg_showing = "Showing %d - %d of %d",
    tp_btn_save = "Save", tp_btn_remove = "Remove", tp_msg_day = "Day",
}
TornadoText = { PARAM_STRING = 0, PARAM_NUMBER = 1, PARAM_KEY = 2, PARAM_MONEY = 3,
    num = function(v) return { type = 1, value = v } end,
    get = function(k) return texts[k] or k end,
    format = function(k, ...) return string.format(texts[k] or k, ...) end,
    formatMessage = function(key, params) return key .. " " .. tostring(params[1] and params[1].value or "") end }
TornadoDestruction = { _resolveSavegamePath = function() return "savegame1/" end }
TornadoMessageLogEvent = { ACTION_SAVE = 1, ACTION_REMOVE = 2, ACTION_REMOVE_ALL = 3 }
GuiUtils = { checkOverlayOverlap = function(x, y, ax, ay, w, h) return x >= ax and x <= ax + w and y >= ay and y <= ay + h end }

dofile("scripts/TornadoMessageLog.lua")
dofile("scripts/gui/TornadoMenuPage.lua")
dofile("scripts/gui/TornadoTable.lua")
dofile("scripts/gui/pages/TornadoPageMessages.lua")
local P = TornadoPageMessages
local L = TornadoMessageLog

-- ---------------------------------------------------------------- fake GUI
local function element(name)
    local e = { name = name, text = "", visible = true, disabled = false, elements = {} }
    function e:setText(t) self.text = t end
    function e:setVisible(v) self.visible = v end
    function e:setDisabled(d) self.disabled = d end
    function e:getIsDisabled() return self.disabled end
    function e:setTexts(t) self.texts = t end
    function e:setState(s) self.state = s end
    function e:getState() return self.state end
    function e:getDescendantByName(n) for _, c in ipairs(self.elements) do if c.name == n then return c end end return nil end
    return e
end
local menu = { controls = {}, pages = {}, activePageIndex = 2, status = "" }
function menu:registerControl(el, page, def) self.controls[el] = { page = page, def = def } end
function menu:markDirty() self.dirty = true end
function menu:setStatus(t) self.status = t end
function menu:refreshAllPages() P:refresh() end
function menu:confirm(_, callback) self.confirmed = (self.confirmed or 0) + 1 callback() end
menu.tabMessages = element("tab")
menu.pageMessages = element("page")
for _, id in ipairs({ "msgTabRecent", "msgTabSaved", "msgFilter", "msgScrollUp", "msgScrollDown", "msgInfo",
    "msgDetailTime", "msgDetailType", "msgDetailText", "msgAction", "msgRemoveAll" }) do
    menu[id] = element(id)
end
menu.msgTable = element("table")
menu.msgTable.absPosition = { 0.1, 0.2 }
menu.msgTable.absSize = { 0.5, 0.6 }
for slot = 1, 12 do
    local row = element("row" .. slot)
    for _, child in ipairs({ "background", "mark", "time", "type", "text" }) do table.insert(row.elements, element(child)) end
    menu["msgRow" .. slot] = row
end
menu.pages = { {}, P }

local failures, total = 0, 0
local function check(label, got, want)
    total = total + 1
    if got ~= want then
        failures = failures + 1
        print(string.format("FAIL  %-58s got %s, want %s", label, tostring(got), tostring(want)))
    else
        print(string.format("ok    %-58s %s", label, tostring(got)))
    end
end
local function cell(slot, name) return menu["msgRow" .. slot]:getDescendantByName(name).text end
local function click(id) local entry = menu.controls[menu[id]] entry.page:onAction(entry.def) end

-- ---------------------------------------------------------------- run
L:loadMap()
for i = 1, 15 do
    environment.dayTime = environment.dayTime + 60000
    L:record(i % 3 == 0 and "tp_msg_ins_claim_paid" or "tp_msg_touchdown", { TornadoText.num(i) }, 3, 1)
end
P:bind(menu)
check("every control bound", menu.controls[menu.msgRow12] ~= nil and menu.controls[menu.msgFilter] ~= nil, true)
P:refresh()
check("12 rows visible", menu.msgRow12.visible, true)
check("newest first in row 1", cell(1, "text"), "tp_msg_ins_claim_paid 15")
check("type column", cell(1, "type"), "tp_msgtype_insurance")
check("info line", menu.msgInfo.text, "Showing 1 - 12 of 15")
check("Recent button count", menu.msgTabRecent.text, "Recent (15)")
check("loaded messages are not new", cell(1, "mark"), "")
check("detail shows the first entry", menu.msgDetailText.text, "tp_msg_ins_claim_paid 15")
check("action button = Save on Recent", menu.msgAction.text, "Save")
check("Remove all hidden on Recent", menu.msgRemoveAll.visible, false)
check("scroll up disabled at the top", menu.msgScrollUp.disabled, true)

-- Scroll + wheel
click("msgScrollDown")
check("scrolled: rows 13 - 15", menu.msgInfo.text, "Showing 4 - 15 of 15")
check("wheel outside the table: ignored", P:onMouseWheel(0.9, 0.9, -1), false)
check("wheel over the table: used", P:onMouseWheel(0.3, 0.5, -1), true)
check("wheel moved one row up", menu.msgInfo.text, "Showing 3 - 14 of 15")

-- Select a row by focus, save it
P:onRowFocus(menu.controls[menu.msgRow2].def)
local selected = P.table:getSelected()
check("focus selects row 2", menu.msgDetailText.text, L.getText(selected))
check("row 2 reports selected", menu.msgRow2.getIsSelected(), true)
check("row child reports selected too", menu.msgRow2:getDescendantByName("text").getIsSelected(), true)
click("msgAction")
check("saved", #L:getFarm(1).saved, 1)
check("panel never marked dirty", menu.dirty, nil)
click("msgTabSaved")
check("Saved list: 1 entry", menu.msgInfo.text, "Showing 1 - 1 of 1")
check("action button = Remove on Saved", menu.msgAction.text, "Remove")
check("Remove all shown on Saved", menu.msgRemoveAll.visible, true)

-- New message while away: dot + tab count; visiting clears the tab count
menu.activePageIndex = 1
environment.dayTime = environment.dayTime + 60000
L:record("tp_msg_flood", { TornadoText.num(99) }, 3, 1)
P:refresh()
check("tab shows 1 new", menu.tabMessages.text, "Messages (1)")
menu.activePageIndex = 2
P:onShow()
click("msgTabRecent")
check("new message has the dot", cell(1, "mark") ~= "", true)
check("Recent button: 1 new", menu.msgTabRecent.text, "Recent (15, 1 new)")
check("tab count cleared while on the tab", menu.tabMessages.text, "Messages")

-- Filter: hazards only
local filter = menu.controls[menu.msgFilter]
local index
for i, option in ipairs(filter.def.choices) do if option.value == "HAZARD" then index = i end end
filter.page:onChoiceChanged(filter.def, menu.msgFilter, index)
check("filter: only the flood", string.sub(menu.msgInfo.text, 1, 18), "Showing 1 - 1 of 1")
check("filtered row 2 hidden", menu.msgRow2.visible, false)
texts.tp_msg_hidden = "%d hidden"
texts.tp_msg_hidden_short = "(%d hidden)"
P:refresh()
check("info line says how many the filter hides", menu.msgInfo.text, "Showing 1 - 1 of 1 (14 hidden)")
for i, option in ipairs(filter.def.choices) do if option.value == "RECOVERY" then index = i end end
filter.page:onChoiceChanged(filter.def, menu.msgFilter, index)
check("everything filtered out: says so, not 'no messages'", menu.msgInfo.text, "15 hidden")
check("detail panel says so too", menu.msgDetailText.text, "15 hidden")
P:onShow()
check("next visit: filter back to All", P.state.filter, "ALL")
check("next visit: every message listed again", menu.msgInfo.text, "Showing 1 - 12 of 15")

-- Remove all saved (confirm)
click("msgTabSaved")
click("msgRemoveAll")
check("remove all asked to confirm", menu.confirmed, 1)
check("all saved removed", #L:getFarm(1).saved, 0)
check("empty saved list text", menu.msgInfo.text, "tp_msg_none_saved")
check("action disabled with nothing selected", menu.msgAction.disabled, true)

print(string.format("\n%d / %d checks passed", total - failures, total))
os.exit(failures == 0 and 0 or 1)
