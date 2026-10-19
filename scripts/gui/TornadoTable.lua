---@class TornadoTable
---@version 1.0
---@description Scroll / selection state of a fixed-row table on a full-width control panel page (Messages tab;
--- meant for the insurance pages too). Pure logic, no GUI calls: the page draws the visible slots itself.
--- A fixed number of row widgets (numRows) shows entries[offset + 1 .. offset + numRows]. The selection is kept
--- by entry key (entry.id by default), so it survives new entries, filters and scrolling.

TornadoTable = {}
local TornadoTable_mt = { __index = TornadoTable }

function TornadoTable.new(numRows, keyOf)
    local self = setmetatable({}, TornadoTable_mt)
    self.numRows = numRows or 12
    self.entries = {}
    self.offset = 0                -- entries before the first visible row
    self.selectedKey = nil
    self.keyOf = keyOf or function(entry) return entry.id end
    return self
end

function TornadoTable:getMaxOffset()
    return math.max(0, #self.entries - self.numRows)
end

function TornadoTable:findIndex(key)
    if key == nil then
        return nil
    end
    for i, entry in ipairs(self.entries) do
        if self.keyOf(entry) == key then
            return i
        end
    end
    return nil
end

--- New contents: keeps the selected entry when it is still there (else the first one) and the scroll position.
function TornadoTable:setEntries(entries)
    self.entries = entries or {}
    if self:findIndex(self.selectedKey) == nil then
        self.selectedKey = self.entries[1] ~= nil and self.keyOf(self.entries[1]) or nil
    end
    self.offset = math.max(0, math.min(self.offset, self:getMaxOffset()))
end

--- Back to the top, first entry selected (list switch, filter change).
function TornadoTable:reset(entries)
    self.offset = 0
    self.selectedKey = nil
    self:setEntries(entries)
end

--- Scrolls by rows (mouse wheel: 1, scroll buttons: a page). Returns true when the view moved.
function TornadoTable:scroll(rows)
    local old = self.offset
    self.offset = math.max(0, math.min(self.offset + (rows or 0), self:getMaxOffset()))
    return self.offset ~= old
end

function TornadoTable:canScrollUp()
    return self.offset > 0
end

function TornadoTable:canScrollDown()
    return self.offset < self:getMaxOffset()
end

--- Entry shown in a row slot (1 .. numRows), or nil.
function TornadoTable:getVisible(slot)
    return self.entries[self.offset + slot]
end

--- Selects the entry in a slot. Returns true when it changed.
function TornadoTable:selectSlot(slot)
    local entry = self:getVisible(slot)
    if entry == nil then
        return false
    end
    local key = self.keyOf(entry)
    local changed = key ~= self.selectedKey
    self.selectedKey = key
    return changed
end

function TornadoTable:getSelected()
    local index = self:findIndex(self.selectedKey)
    return index ~= nil and self.entries[index] or nil
end

--- Slot of the selected entry when it is visible, else nil.
function TornadoTable:getSelectedSlot()
    local index = self:findIndex(self.selectedKey)
    if index == nil or index <= self.offset or index > self.offset + self.numRows then
        return nil
    end
    return index - self.offset
end

--- First / last visible entry number and the total ("showing 13 - 24 of 37"); 0, 0, 0 when empty.
function TornadoTable:getRange()
    local total = #self.entries
    if total == 0 then
        return 0, 0, 0
    end
    return self.offset + 1, math.min(total, self.offset + self.numRows), total
end
