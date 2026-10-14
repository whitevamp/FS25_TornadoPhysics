---@class TornadoPageEffects
---@description Effects tab: mirrors t_sfx (sound, ring, fire_random).

local Page = TornadoMenuPage
local flipTo = TornadoMenuPage.flipTo

TornadoPageEffects = TornadoMenuPage.new("Effects", "Effects", {
    {
        id = "sfxSound",
        kind = Page.KIND_BOOL,
        localOnly = true,
        requires = function()
            return TornadoSFX ~= nil
        end,
        get = function()
            return TornadoSFX.isEnabled
        end,
        set = function(value)
            return flipTo(value, TornadoSFX.isEnabled, "cmdSFX", "sound")
        end,
    },
    {
        id = "sfxRing",
        kind = Page.KIND_BOOL,
        localOnly = true,
        requires = function()
            return TornadoPhysics ~= nil
        end,
        get = function()
            return TornadoPhysics.showRing
        end,
        set = function(value)
            return flipTo(value, TornadoPhysics.showRing, "cmdSFX", "ring")
        end,
    },
    {
        id = "sfxFireRandom",
        kind = Page.KIND_BOOL,
        requires = function()
            return TornadoEffects ~= nil and TornadoEffects.CONFIG ~= nil
        end,
        get = function()
            return TornadoEffects.CONFIG.RANDOM_FIRE_MODE
        end,
        set = function(value)
            return flipTo(value, TornadoEffects.CONFIG.RANDOM_FIRE_MODE, "cmdSFX", "fire_random")
        end,
    },
})
