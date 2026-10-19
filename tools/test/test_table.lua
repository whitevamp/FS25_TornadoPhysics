-- Offline test for scripts/gui/TornadoTable.lua (scroll / selection state of the Messages table) - Lua 5.1.
-- Run from the mod root:
--     lua-5.1.5_Win64_bin/lua5.1.exe tools/test/test_table.lua
-- Exit code 0 = all checks passed.

dofile("scripts/gui/TornadoTable.lua")

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
local function entries(n, firstId)
    local list = {}
    for i = 1, n do list[i] = { id = (firstId or 1) + i - 1 } end
    return list
end

local t = TornadoTable.new(12)
t:setEntries({})
check("empty: nothing selected", t:getSelected(), nil)
check("empty: range 0", select(3, t:getRange()), 0)
check("empty: cannot scroll", t:canScrollDown() or t:canScrollUp(), false)

t:setEntries(entries(37))
check("first entry selected", t:getSelected().id, 1)
check("range 1 - 12 of 37", table.concat({ t:getRange() }, " "), "1 12 37")
check("can scroll down", t:canScrollDown(), true)
check("slot 3 shows entry 3", t:getVisible(3).id, 3)

-- Scroll a page down, select a row there
t:scroll(12)
check("after a page: range 13 - 24", table.concat({ t:getRange() }, " "), "13 24 37")
check("selected entry scrolled out: no visible slot", t:getSelectedSlot(), nil)
check("select slot 2 = entry 14", t:selectSlot(2) and t:getSelected().id, 14)
check("selected slot is 2", t:getSelectedSlot(), 2)
check("selecting the same slot again: no change", t:selectSlot(2), false)
check("empty slot cannot be selected", (function() t:scroll(100) return t:selectSlot(12) end)(), true)

-- Clamp at the end and the top
t:scroll(100)
check("clamped at the end: range 26 - 37", table.concat({ t:getRange() }, " "), "26 37 37")
check("cannot scroll further down", t:canScrollDown(), false)
check("wheel at the end does not move", t:scroll(1), false)
t:scroll(-1000)
check("clamped at the top", t:canScrollUp(), false)

-- New message on top: the selection stays on the same entry
t:selectSlot(5)
local selected = t:getSelected().id
local newer = entries(1, 100)
for _, e in ipairs(t.entries) do table.insert(newer, e) end
t:setEntries(newer)
check("new entry on top: same entry still selected", t:getSelected().id, selected)

-- Selected entry removed: first one selected
local without = {}
for _, e in ipairs(t.entries) do if e.id ~= selected then table.insert(without, e) end end
t:setEntries(without)
check("selected entry removed: first one selected", t:getSelected().id, 100)

-- Fewer entries than rows: no scrolling, offset clamped
t:scroll(20)
t:setEntries(entries(5))
check("5 entries: back at the top", t.offset, 0)
check("5 entries: range 1 - 5", table.concat({ t:getRange() }, " "), "1 5 5")
check("slot 6 is empty", t:getVisible(6), nil)

-- reset: list switch / filter
t:selectSlot(4)
t:reset(entries(30, 200))
check("reset: first entry of the new list", t:getSelected().id, 200)
check("reset: at the top", t.offset, 0)

print(string.format("\n%d / %d checks passed", total - failures, total))
os.exit(failures == 0 and 0 or 1)
