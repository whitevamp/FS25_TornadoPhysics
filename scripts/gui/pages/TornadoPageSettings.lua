---@class TornadoPageSettings
---@description Settings tab: save to XML and factory resets (t_set save, t_reset ...).

local Page = TornadoMenuPage
local console = TornadoMenuPage.console

local function hasSettings()
    return TornadoSettings ~= nil
end

local function resetAction(id, category, confirmKey)
    return {
        id = id,
        kind = Page.KIND_ACTION,
        requires = hasSettings,
        confirm = confirmKey,
        keepClean = true, -- resetToDefaults() already writes the XML
        run = function()
            return console("cmdReset", category)
        end,
    }
end

TornadoPageSettings = TornadoMenuPage.new("Settings", "Settings", {
    {
        id = "setAutoSave",
        kind = Page.KIND_BOOL,
        keepClean = true,
        localOnly = true,
        get = function()
            return TornadoMenu.autoSaveOnClose
        end,
        set = function(value)
            TornadoMenu.autoSaveOnClose = value
            return "Panel: Auto-save on close = " .. tostring(value)
        end,
    },
    {
        id = "setSave",
        kind = Page.KIND_ACTION,
        requires = hasSettings,
        keepClean = true,
        localOnly = true,   -- saves this player's own file (personal settings only on a multiplayer client)
        run = function()
            local result = console("cmdSet", "save")
            if TornadoMenu.INSTANCE ~= nil then
                TornadoMenu.INSTANCE.isDirty = false
            end
            return result
        end,
    },
    resetAction("setResetPhysics", "physics", "tp_confirm_reset_physics"),
    resetAction("setResetTuning", "tuning", "tp_confirm_reset_tuning"),
    resetAction("setResetCargo", "cargo", "tp_confirm_reset_cargo"),
    resetAction("setResetHusbandry", "husbandry", "tp_confirm_reset_husbandry"),
    resetAction("setResetTraffic", "traffic", "tp_confirm_reset_traffic"),
    resetAction("setResetClimate", "climate", "tp_confirm_reset_climate"),
    resetAction("setResetAll", "all", "tp_confirm_reset_all"),
})

--- Multiplayer hint: who owns the gameplay settings.
function TornadoPageSettings:onRefresh()
    local note = self.menu ~= nil and self.menu.setHostNote or nil
    if note == nil then
        return
    end

    if TornadoSync == nil or not TornadoSync:isClient() then
        note:setText(TornadoText.get("tp_note_key"))
    elseif TornadoSync:canEditSettings() then
        note:setText(TornadoText.get("tp_note_mp_admin"))
    else
        note:setText(TornadoText.get("tp_note_mp_client"))
    end
end
