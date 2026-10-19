---@class TornadoMenu
---@version 1.0
---@description Tornado control panel screen. Opened with the TORNADO_MENU key (default RCtrl + RShift + T).
--- Owns gui/TornadoMenu.xml, switches tabs and routes every control callback to the page script
--- (scripts/gui/pages/*.lua) that owns the element. Registration, teardown and the key binding live
--- here too, so TornadoMain only needs register() / unregister().

TornadoMenu = {}
TornadoMenu.GUI_NAME = "TornadoMenu"
TornadoMenu.PROFILE_MARKER = "tornado_actionButton" -- any profile from gui/guiProfiles.xml

-- Session preference (Settings tab). Class-level so it survives the screen instance.
TornadoMenu.autoSaveOnClose = true

local TornadoMenu_mt = Class(TornadoMenu, ScreenElement)

function TornadoMenu.new(target, custom_mt)
    local self = ScreenElement.new(target, custom_mt or TornadoMenu_mt)

    self.pages = {}
    self.controls = {}        -- element -> { page, def }
    self.activePageIndex = 1
    self.isDirty = false

    return self
end

-- =========================================================================
-- SETUP
-- =========================================================================

function TornadoMenu:onGuiSetupFinished()
    TornadoMenu:superClass().onGuiSetupFinished(self)

    -- Tab order. Missing page scripts are skipped so one broken file never takes the panel down.
    local order = { TornadoPageSettings, TornadoPagePhysics, TornadoPageTuning, TornadoPageEffects, TornadoPageModules,
        TornadoPageMessages, TornadoPageDeveloper }
    for i = 1, 7 do
        local page = order[i]
        if page ~= nil then
            self.pages[#self.pages + 1] = page
            page:bind(self)
        end
    end

    -- Only the active page is visible, even before the first onOpen().
    for i, page in ipairs(self.pages) do
        if page.pageElement ~= nil then
            page.pageElement:setVisible(i == self.activePageIndex)
        end
    end

    -- Tab highlight: the tab styles ask getIsSelected() each frame, so answer it from the active page
    -- (both the button and its "background" bitmap are asked).
    for i, page in ipairs(self.pages) do
        local tab = page.tabElement
        if tab ~= nil then
            local isSelected = function()
                return self.activePageIndex == i
            end
            tab.getIsSelected = isSelected
            local background = tab:getDescendantByName("background")
            if background ~= nil then
                background.getIsSelected = isSelected
            end
        end
    end

    -- Hide tab buttons whose page script did not load.
    for _, key in ipairs({ "Settings", "Physics", "Tuning", "Effects", "Modules", "Messages", "Developer" }) do
        if self:getPageIndexByKey(key) == nil then
            if self["tab" .. key] ~= nil then self["tab" .. key]:setVisible(false) end
            if self["page" .. key] ~= nil then self["page" .. key]:setVisible(false) end
        end
    end
end

function TornadoMenu:registerControl(element, page, def)
    self.controls[element] = { page = page, def = def }
end

function TornadoMenu:getPageIndexByKey(key)
    for i, page in ipairs(self.pages) do
        if page.key == key then
            return i
        end
    end
    return nil
end

-- =========================================================================
-- LIFECYCLE
-- =========================================================================

function TornadoMenu:onOpen()
    TornadoMenu:superClass().onOpen(self)

    self.isDirty = false
    self:setStatus("")
    self:refreshAllPages()
    self:selectPage(self.activePageIndex)
end

function TornadoMenu:onClose()
    if self.isDirty and TornadoMenu.autoSaveOnClose and TornadoSettings ~= nil then
        TornadoSettings:saveToXML()
        print("TORNADO MENU: Changes auto-saved to XML.")
    end
    self.isDirty = false

    TornadoMenu:superClass().onClose(self)
end

function TornadoMenu:refreshAllPages()
    for _, page in ipairs(self.pages) do
        page:refresh()
    end
end

function TornadoMenu:markDirty()
    self.isDirty = true
end

function TornadoMenu:setStatus(text)
    if self.statusText ~= nil then
        self.statusText:setText(text or "")
    end
end

-- =========================================================================
-- TABS
-- =========================================================================

function TornadoMenu:selectPage(index)
    if #self.pages == 0 then
        return
    end
    index = math.max(1, math.min(index or 1, #self.pages))
    self.activePageIndex = index

    for i, page in ipairs(self.pages) do
        local isActive = i == index
        if page.pageElement ~= nil then
            page.pageElement:setVisible(isActive)
        end
    end

    local page = self.pages[index]
    if page.layoutElement ~= nil then
        page.layoutElement:invalidateLayout()
        if self.settingsSlider ~= nil then
            self.settingsSlider:setDataElement(page.layoutElement)
        end
    end
    -- Full-width pages (no scrolling settings list) have no use for the shared scrollbar.
    if self.settingsSliderBox ~= nil then
        self.settingsSliderBox:setVisible(page.layoutElement ~= nil)
    end
    if page.onShow ~= nil then
        page:onShow()
    end

    local focusElement = page:getFirstFocusElement()
    if focusElement ~= nil then
        self:setSoundSuppressed(true)
        FocusManager:setFocus(focusElement)
        self:setSoundSuppressed(false)
    end
end

function TornadoMenu:onClickTab(element)
    for i, page in ipairs(self.pages) do
        if page.tabElement == element then
            self:selectPage(i)
            return
        end
    end
end

--- Page prev / next keys (and shoulder buttons) cycle through the tabs.
function TornadoMenu:inputEvent(action, value, eventUsed)
    eventUsed = TornadoMenu:superClass().inputEvent(self, action, value, eventUsed)

    if not eventUsed and self.inputDisableTime <= 0 and #self.pages > 0 then
        if action == InputAction.MENU_PAGE_PREV then
            self:selectPage(self.activePageIndex == 1 and #self.pages or self.activePageIndex - 1)
            eventUsed = true
        elseif action == InputAction.MENU_PAGE_NEXT then
            self:selectPage(self.activePageIndex == #self.pages and 1 or self.activePageIndex + 1)
            eventUsed = true
        end
    end

    return eventUsed
end

-- =========================================================================
-- CONTROL CALLBACKS (from TornadoMenu.xml)
-- =========================================================================

function TornadoMenu:onClickBinary(state, element)
    local entry = self.controls[element]
    if entry ~= nil then
        entry.page:onBoolChanged(entry.def, element)
    end
end

function TornadoMenu:onClickNumber(state, element)
    local entry = self.controls[element]
    if entry ~= nil then
        entry.page:onNumberChanged(entry.def, element, state)
    end
end

function TornadoMenu:onClickChoice(state, element)
    local entry = self.controls[element]
    if entry ~= nil then
        entry.page:onChoiceChanged(entry.def, element, state)
    end
end

function TornadoMenu:onClickAction(element)
    local entry = self.controls[element]
    if entry ~= nil then
        entry.page:onAction(entry.def)
    end
end

--- Row focus (controller / keyboard) on a table page: the page selects that row.
function TornadoMenu:onFocusRow(element)
    local entry = self.controls[element]
    if entry ~= nil and entry.page.onRowFocus ~= nil then
        entry.page:onRowFocus(entry.def)
    end
end

--- Mouse wheel over a table page's rows scrolls the table.
function TornadoMenu:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
    eventUsed = TornadoMenu:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed)
    if not eventUsed and isDown and Input ~= nil
        and (button == Input.MOUSE_BUTTON_WHEEL_UP or button == Input.MOUSE_BUTTON_WHEEL_DOWN) then
        local page = self.pages[self.activePageIndex]
        if page ~= nil and page.onMouseWheel ~= nil then
            local direction = button == Input.MOUSE_BUTTON_WHEEL_UP and -1 or 1
            if page:onMouseWheel(posX, posY, direction) then
                eventUsed = true
            end
        end
    end
    return eventUsed
end

function TornadoMenu:onClickSave()
    if TornadoSettings == nil then
        self:setStatus("Error: Settings Module missing.")
        return
    end
    TornadoSettings:saveToXML()
    self.isDirty = false
    self:setStatus("Settings: Configuration Saved to XML.")
end

function TornadoMenu:onClickBack()
    g_gui:changeScreen(nil)
    return false
end

--- Yes/No prompt before destructive actions; runs `callback` straight away if the dialog is unavailable.
function TornadoMenu:confirm(text, callback)
    if YesNoDialog ~= nil and YesNoDialog.show ~= nil then
        YesNoDialog.show(function(_, yes)
            if yes then
                callback()
            end
        end, self, text)
    else
        callback()
    end
end

-- =========================================================================
-- REGISTRATION (called from TornadoMain)
-- =========================================================================

function TornadoMenu.register(modDir)
    if g_gui == nil or g_dedicatedServer ~= nil then
        return
    end

    -- A previous savegame in this game session left its screen behind; drop it first.
    TornadoMenu.unregister()

    if g_gui.profiles == nil or g_gui.profiles[TornadoMenu.PROFILE_MARKER] == nil then
        g_gui:loadProfiles(modDir .. "gui/guiProfiles.xml")
    end

    local controller = TornadoMenu.new()
    g_gui:loadGui(modDir .. "gui/TornadoMenu.xml", TornadoMenu.GUI_NAME, controller)

    -- loadGui() fails silently (it only logs), so check the result instead of trusting it.
    if g_gui.guis[TornadoMenu.GUI_NAME] ~= nil then
        TornadoMenu.INSTANCE = controller
        print("TORNADO MENU: Control panel registered.")
    else
        print("TORNADO MENU ERROR: Control panel failed to load (see the GUI errors above in the log).")
    end
end

function TornadoMenu.unregister()
    if g_gui == nil then
        return
    end

    if g_gui.screenControllers ~= nil then
        for screenClass, controller in pairs(g_gui.screenControllers) do
            if controller.name == TornadoMenu.GUI_NAME then
                if controller.isOpen then
                    g_gui:changeScreen(nil)
                end
                g_gui.screenControllers[screenClass] = nil
                if g_gui.screens ~= nil then
                    g_gui.screens[screenClass] = nil
                end
                controller:delete()
            end
        end
    end
    if g_gui.guis ~= nil then
        g_gui.guis[TornadoMenu.GUI_NAME] = nil
    end
    if g_gui.nameScreenTypes ~= nil then
        g_gui.nameScreenTypes[TornadoMenu.GUI_NAME] = nil
    end

    TornadoMenu.INSTANCE = nil
end

function TornadoMenu.open()
    if TornadoMenu.INSTANCE == nil or g_gui == nil then
        return
    end
    -- Never stack on top of another menu or dialog.
    if g_gui:getIsGuiVisible() then
        return
    end
    g_gui:showGui(TornadoMenu.GUI_NAME)
end

-- =========================================================================
-- KEY BINDING
-- Global player events are active both on foot and in vehicles. The hook is installed once per
-- game session (flag on the engine class) and always calls the CURRENT TornadoMenu global, because
-- TornadoMain re-sources this file for every savegame.
-- =========================================================================

function TornadoMenu.onInputOpenMenu(_, actionName, inputValue)
    TornadoMenu.open()
end

function TornadoMenu.registerInput(inputComponent)
    if g_inputBinding == nil or InputAction.TORNADO_MENU == nil then
        return
    end
    if inputComponent ~= nil and inputComponent.player ~= nil and inputComponent.player.isOwner == false then
        return
    end

    local _, eventId = g_inputBinding:registerActionEvent(InputAction.TORNADO_MENU, TornadoMenu, TornadoMenu.onInputOpenMenu, false, true, false, true, nil, true)
    if eventId ~= nil then
        g_inputBinding:setActionEventTextPriority(eventId, GS_PRIO_VERY_LOW)
        g_inputBinding:setActionEventTextVisibility(eventId, false)
    end
end

if PlayerInputComponent ~= nil and PlayerInputComponent.registerGlobalPlayerActionEvents ~= nil and not PlayerInputComponent.tornadoMenuHookInstalled then
    PlayerInputComponent.tornadoMenuHookInstalled = true
    PlayerInputComponent.registerGlobalPlayerActionEvents = Utils.appendedFunction(PlayerInputComponent.registerGlobalPlayerActionEvents, function(inputComponent, ...)
        if TornadoMenu ~= nil and TornadoMenu.registerInput ~= nil then
            TornadoMenu.registerInput(inputComponent)
        end
    end)
end
