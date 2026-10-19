---@class TornadoMenuPage
---@version 1.0
---@description Shared plumbing for one tab of the Tornado control panel.
--- A page is a plain table of control definitions keyed by the element ids in gui/TornadoMenu.xml.
--- TornadoMenu (the screen) owns the GUI elements and forwards every click to the page that owns
--- the element; the page reads/writes the live module state, mostly by calling the same
--- TornadoConsole handlers the t_ commands use, so the panel and the console never disagree.
---
--- Control definition fields:
---   id        element id in TornadoMenu.xml (required)
---   kind      TornadoMenuPage.KIND_BOOL | KIND_NUMBER | KIND_CHOICE | KIND_ACTION
---   requires  function() -> bool, row is greyed out when false (module not loaded)
---   get       function() -> current value               (bool / number / choice value)
---   set       function(value) -> status string          (bool / number / choice value)
---   options   function() -> { {value = v, text = "label"}, ... }   (choice)
---   run       function() -> status string               (action)
---   min, max, step  value grid for numbers
---   format    printf pattern or function(value) -> string
---   confirm   text key (translations) for a yes/no prompt before an action runs
---   keepClean true when the change must not mark the panel dirty (auto-save)
---   localOnly  true for personal settings (sound, ring, overlay, debug); every player may change them.
---              Everything else is shared gameplay: in multiplayer only the host / server admins can change it.
---   serverOnly true for tools that only do something on the server (greyed out on multiplayer clients)

TornadoMenuPage = {}
local TornadoMenuPage_mt = { __index = TornadoMenuPage }

TornadoMenuPage.KIND_BOOL   = "bool"
TornadoMenuPage.KIND_NUMBER = "number"
TornadoMenuPage.KIND_CHOICE = "choice"
TornadoMenuPage.KIND_ACTION = "action"

function TornadoMenuPage.new(key, title, defs)
    local self = setmetatable({}, TornadoMenuPage_mt)
    self.key = key        -- "Physics" -> tabPhysics / pagePhysics / layoutPhysics
    self.title = title
    self.defs = defs or {}
    self.menu = nil
    return self
end

-- =========================================================================
-- CONSOLE BRIDGE
-- =========================================================================

--- Calls a TornadoConsole handler exactly as the console would.
function TornadoMenuPage.console(method, ...)
    if TornadoConsole == nil or TornadoConsole[method] == nil then
        return "Error: Console module missing."
    end
    return TornadoConsole[method](TornadoConsole, ...)
end

--- Console toggles flip state; only call them when the wanted state differs.
function TornadoMenuPage.flipTo(want, current, method, ...)
    if (current == true) == (want == true) then
        return nil
    end
    return TornadoMenuPage.console(method, ...)
end

-- =========================================================================
-- BINDING
-- =========================================================================

function TornadoMenuPage:bind(menu)
    self.menu = menu
    self.tabElement = menu["tab" .. self.key]
    self.pageElement = menu["page" .. self.key]
    self.layoutElement = menu["layout" .. self.key]

    if self.pageElement == nil or (self.layoutElement == nil and not self.noLayout) then
        print(string.format("TORNADO MENU: page '%s' has no container/layout in TornadoMenu.xml", self.key))
    end

    for _, def in ipairs(self.defs) do
        def.element = menu[def.id]
        if def.element == nil then
            print(string.format("TORNADO MENU: element '%s' (%s tab) missing in TornadoMenu.xml", def.id, self.key))
        else
            menu:registerControl(def.element, self, def)
        end
    end

    self:applyRowShading()
end

--- Alternating row tint like the vanilla settings pages; restarts after every section header.
function TornadoMenuPage:applyRowShading()
    if self.layoutElement == nil or InGameMenuSettingsFrame == nil or InGameMenuSettingsFrame.COLOR_ALTERNATING == nil then
        return
    end

    local isEven = false
    for _, row in ipairs(self.layoutElement.elements) do
        if row.name == "sectionHeader" then
            isEven = false
        elseif row.setImageColor ~= nil then
            local color = InGameMenuSettingsFrame.COLOR_ALTERNATING[isEven]
            if color ~= nil then
                row:setImageColor(nil, (table.unpack or unpack)(color))
            end
            isEven = not isEven
        end
    end
end

-- =========================================================================
-- DISPLAY
-- =========================================================================

function TornadoMenuPage:isAvailable(def)
    if TornadoSync ~= nil then
        if def.serverOnly and TornadoSync:isClient() then
            return false
        end
        if not def.localOnly and not TornadoSync:canEditSettings() then
            return false
        end
    end
    if def.requires == nil then
        return true
    end
    return def.requires() == true
end

function TornadoMenuPage:refresh()
    for _, def in ipairs(self.defs) do
        local element = def.element
        if element ~= nil then
            local available = self:isAvailable(def)
            if element.setDisabled ~= nil then
                element:setDisabled(not available)
            end

            if available then
                if def.kind == TornadoMenuPage.KIND_BOOL then
                    element:setIsChecked(def.get() == true, true)
                elseif def.kind == TornadoMenuPage.KIND_NUMBER then
                    self:populateNumber(def)
                elseif def.kind == TornadoMenuPage.KIND_CHOICE then
                    self:populateChoice(def)
                end
            end
        end
    end

    if self.onRefresh ~= nil then
        self:onRefresh()
    end
end

--- Value grid from min..max in step increments, rounded to the precision of `step`.
function TornadoMenuPage.buildRange(min, max, step)
    local decimals = 0
    while decimals < 6 and math.abs(step * 10 ^ decimals - math.floor(step * 10 ^ decimals + 0.5)) > 1e-9 do
        decimals = decimals + 1
    end
    local scale = 10 ^ decimals

    local values = {}
    local count = math.floor((max - min) / step + 0.5)
    for i = 0, count do
        values[#values + 1] = math.floor((min + i * step) * scale + 0.5) / scale
    end
    return values
end

function TornadoMenuPage:formatValue(def, value)
    if type(def.format) == "function" then
        return def.format(value)
    end
    local pattern = def.format or "%.2f"
    if string.find(pattern, "%%d") ~= nil then
        -- off-grid live values can be fractional; %d must get a whole number
        value = math.floor(value + 0.5)
    end
    return string.format(pattern, value)
end

--- Fills a MultiTextOption with the def's grid and selects the live value.
--- A live value that is off the grid (set from the console / XML) gets its own entry so it is never lost.
function TornadoMenuPage:populateNumber(def)
    local values = TornadoMenuPage.buildRange(def.min, def.max, def.step)

    local current = tonumber(def.get())

    local index = 1
    if current ~= nil then
        local tolerance = def.step * 0.001
        index = nil
        for i, value in ipairs(values) do
            if math.abs(value - current) <= tolerance then
                index = i
                break
            elseif value > current then
                table.insert(values, i, current)
                index = i
                break
            end
        end
        if index == nil then
            values[#values + 1] = current
            index = #values
        end
    end

    local texts = {}
    for i, value in ipairs(values) do
        texts[i] = self:formatValue(def, value)
    end

    def.values = values
    def.element:setTexts(texts)
    def.element:setState(index)
end

--- Fills a MultiTextOption with a list of named options and selects the current value.
function TornadoMenuPage:populateChoice(def)
    local options = def.options()
    local current = def.get()

    local texts, index = {}, 1
    for i, option in ipairs(options) do
        texts[i] = option.text
        if option.value == current then
            index = i
        end
    end

    def.choices = options
    def.element:setTexts(texts)
    def.element:setState(index)
end

-- =========================================================================
-- INPUT (called by TornadoMenu)
-- =========================================================================

function TornadoMenuPage:onBoolChanged(def, element)
    local want = element:getIsChecked()
    self:apply(def, function() return def.set(want) end)
end

function TornadoMenuPage:onNumberChanged(def, element, state)
    local value = def.values ~= nil and def.values[state or element:getState()] or nil
    if value == nil then
        return
    end
    self:apply(def, function() return def.set(value) end)
end

function TornadoMenuPage:onChoiceChanged(def, element, state)
    local option = def.choices ~= nil and def.choices[state or element:getState()] or nil
    if option == nil then
        return
    end
    self:apply(def, function() return def.set(option.value) end)
end

function TornadoMenuPage:onAction(def)
    local run = function()
        self:apply(def, def.run)
    end

    if def.confirm ~= nil then
        self.menu:confirm(TornadoText.get(def.confirm), run)
    else
        run()
    end
end

--- Runs a change, reports the console-style result line and refreshes every tab,
--- because several actions (resets, verbose "all") touch rows on other pages too.
--- Every def guards its own module access through `requires`, so no error trapping is needed here.
function TornadoMenuPage:apply(def, fn)
    local result = fn()
    if not def.keepClean then
        self.menu:markDirty()
    end

    if result ~= nil then
        self.menu:setStatus(tostring(result))
    end
    self.menu:refreshAllPages()
end

--- First enabled control, used to put keyboard / controller focus on the page.
function TornadoMenuPage:getFirstFocusElement()
    for _, def in ipairs(self.defs) do
        local element = def.element
        if element ~= nil and not (element.getIsDisabled ~= nil and element:getIsDisabled()) then
            return element
        end
    end
    return nil
end
