---@class TornadoSync
---@version 1.0
---@description Multiplayer support. The server (host or dedicated) runs all tornado gameplay; this module
--- keeps clients in step with it:
---   * gameplay settings: one set for everyone, owned by the server. Only the host / server admins may change
---     them (same rule as the base game's savegame settings); changes are sent to the server and re-broadcast.
---     Personal settings (siren sound, danger ring, map overlay, debug tools, auto-save) stay per player.
---   * tornado state (EF, size, warning, siren), storm weather, vehicle destruction, smoke / fire and
---     messages are sent from the server by the events in scripts/events/.
---   * players joining a running game get the full current state (sendInitialClientState).
--- In single player every helper here is a no-op (or runs locally), so nothing changes there.

TornadoSync = {}

-- Message kinds for TornadoMessageEvent
TornadoSync.MSG_BLINKING = 1          -- big blinking warning in the middle of the screen
TornadoSync.MSG_CRITICAL = 2          -- red in-game notification
TornadoSync.MSG_INFO = 3              -- normal in-game notification

-- Smoke / fire kinds for TornadoFxEvent
TornadoSync.FX_CONTACT = 1            -- vehicle is being hit (smoke)
TornadoSync.FX_BURN = 2               -- vehicle will catch fire

-- =========================================================================
-- GAMEPLAY SETTINGS REGISTRY (order is the network order - same on every machine)
-- =========================================================================

local function physicsSetting(key, valueType)
    return {
        valueType = valueType,
        has = function() return TornadoPhysics ~= nil and TornadoPhysics.settings ~= nil end,
        get = function() return TornadoPhysics.settings[key] end,
        set = function(value) TornadoPhysics.settings[key] = value end,
    }
end

local function fieldSetting(getTable, key, valueType)
    return {
        valueType = valueType,
        has = function() return getTable() ~= nil end,
        get = function() return getTable()[key] end,
        set = function(value) getTable()[key] = value end,
    }
end

local function cargoSettings() return TornadoCargo ~= nil and TornadoCargo.settings or nil end
local function effectsConfig() return TornadoEffects ~= nil and TornadoEffects.CONFIG or nil end

TornadoSync.SETTINGS = {
    -- t_physics
    physicsSetting("base_radius", "f"),
    physicsSetting("ejection_power", "f"),
    physicsSetting("heavy_threshold", "f"),
    physicsSetting("geo_fence", "f"),
    physicsSetting("damage_center", "f"),
    physicsSetting("damage_outer", "f"),
    physicsSetting("lift_bales", "b"),
    physicsSetting("lift_logs", "b"),
    physicsSetting("border_safety", "b"),
    physicsSetting("indoor_damage", "b"),
    physicsSetting("outdoor_damage", "b"),
    physicsSetting("destructionEnabled", "b"),
    -- t_tune
    physicsSetting("suction_speed", "f"),
    physicsSetting("lift_speed", "f"),
    physicsSetting("chaos_factor", "f"),
    physicsSetting("bale_orbit", "f"),
    physicsSetting("bale_suction", "f"),
    physicsSetting("bale_lift", "f"),
    physicsSetting("hover_height", "f"),
    physicsSetting("max_safe_speed", "f"),
    physicsSetting("destruction_ratio", "f"),
    physicsSetting("mass_penalty", "f"),
    physicsSetting("purge_duration", "f"),
    physicsSetting("purge_interval", "f"),
    -- t_set recovery
    fieldSetting(function() return TornadoSettings end, "recoveryEnabled", "b"),
    fieldSetting(function() return TornadoSettings end, "moneyScale", "f"),
    -- t_set cargo
    fieldSetting(function() return TornadoCargo end, "isEnabled", "b"),
    fieldSetting(cargoSettings, "spillHeight", "f"),
    fieldSetting(cargoSettings, "spillAngle", "f"),
    fieldSetting(cargoSettings, "drainRate", "f"),
    fieldSetting(cargoSettings, "spreadRadius", "f"),
    fieldSetting(cargoSettings, "coverLeakChance", "f"),
    -- t_set husbandry
    fieldSetting(function() return TornadoHusbandry end, "isActive", "b"),
    {
        valueType = "f",
        has = function() return TornadoHusbandry ~= nil end,
        get = function() return TornadoHusbandry.IMMUNITY_DURATION end,
        set = function(value)
            TornadoHusbandry.IMMUNITY_DURATION = value
            TornadoHusbandry.customImmunitySet = true
        end,
    },
    -- t_sfx fire_random (decides on the server whether damaged engines burn)
    fieldSetting(effectsConfig, "RANDOM_FIRE_MODE", "b"),
    -- t_set traffic
    fieldSetting(function() return TornadoTraffic end, "isEnabled", "b"),
    fieldSetting(function() return TornadoTraffic end, "bufferDistance", "f"),
    -- t_set wildlife
    fieldSetting(function() return TornadoWildlife end, "isEnabled", "b"),
    fieldSetting(function() return TornadoWildlife end, "fleeDistance", "f"),
    -- t_set hazards
    fieldSetting(function() return TornadoHazards end, "isEnabled", "b"),
    fieldSetting(function() return TornadoHazards end, "droughtEnabled", "b"),
    fieldSetting(function() return TornadoHazards end, "intensity", "f"),
    fieldSetting(function() return TornadoHazards end, "frequency", "f"),
    fieldSetting(function() return TornadoHazards end, "floodEnabled", "b"),
    fieldSetting(function() return TornadoHazards end, "fireEnabled", "b"),
    fieldSetting(function() return TornadoHazards end, "ownedOnly", "b"),
    -- t_set insurance
    fieldSetting(function() return TornadoInsurance end, "isEnabled", "b"),
    fieldSetting(function() return TornadoInsurance end, "adminOnly", "b"),
    fieldSetting(function() return TornadoInsurance end, "regionSetting", "s"),
    fieldSetting(function() return TornadoInsurance end, "salesClosing", "s"),
    -- t_set climate
    fieldSetting(function() return TornadoClimate end, "isEnabled", "b"),
    fieldSetting(function() return TornadoClimate end, "regionSetting", "s"),
    fieldSetting(function() return TornadoClimate end, "useSeasonality", "b"),
    fieldSetting(function() return TornadoClimate end, "useDirection", "b"),
    fieldSetting(function() return TornadoClimate end, "useOutbreaks", "b"),
    fieldSetting(function() return TornadoClimate end, "frequency", "f"),
    fieldSetting(function() return TornadoClimate end, "outbreakMax", "f"),
}

function TornadoSync.writeSettings(streamId)
    for _, setting in ipairs(TornadoSync.SETTINGS) do
        local available = setting.has()
        streamWriteBool(streamId, available)
        if available then
            local value = setting.get()
            if setting.valueType == "f" then
                streamWriteFloat32(streamId, tonumber(value) or 0)
            elseif setting.valueType == "b" then
                streamWriteBool(streamId, value == true)
            else
                streamWriteString(streamId, tostring(value or ""))
            end
        end
    end
end

--- Returns { [index] = value } for every setting the sender had.
function TornadoSync.readSettings(streamId)
    local values = {}
    for i, setting in ipairs(TornadoSync.SETTINGS) do
        if streamReadBool(streamId) then
            if setting.valueType == "f" then
                values[i] = streamReadFloat32(streamId)
            elseif setting.valueType == "b" then
                values[i] = streamReadBool(streamId)
            else
                values[i] = streamReadString(streamId)
            end
        end
    end
    return values
end

function TornadoSync.applySettings(values)
    local oldRadius = TornadoPhysics ~= nil and TornadoPhysics.settings ~= nil and TornadoPhysics.settings.base_radius or nil

    for i, setting in ipairs(TornadoSync.SETTINGS) do
        if values[i] ~= nil and setting.has() then
            setting.set(values[i])
        end
    end

    -- Same as t_physics radius: a new base radius re-rolls the active tornado (server only).
    if oldRadius ~= nil and TornadoPhysics.settings.base_radius ~= oldRadius
        and g_currentMission ~= nil and g_currentMission:getIsServer() then
        TornadoPhysics:randomizeTornado()
    end

    -- Show the new values if the control panel is open.
    if TornadoMenu ~= nil and TornadoMenu.INSTANCE ~= nil and TornadoMenu.INSTANCE.isOpen then
        TornadoMenu.INSTANCE:refreshAllPages()
    end
end

--- Plain list of the current values, to see whether a command changed anything.
function TornadoSync.snapshot()
    local values = {}
    for i, setting in ipairs(TornadoSync.SETTINGS) do
        values[i] = setting.has() and setting.get() or nil
    end
    return values
end

local function snapshotsDiffer(a, b)
    for i = 1, #TornadoSync.SETTINGS do
        if a[i] ~= b[i] then
            return true
        end
    end
    return false
end

-- =========================================================================
-- STATE / PERMISSIONS
-- =========================================================================

function TornadoSync:isMultiplayer()
    return g_currentMission ~= nil and g_currentMission.missionDynamicInfo ~= nil
        and g_currentMission.missionDynamicInfo.isMultiplayer == true
end

--- True on a multiplayer client (not the host / dedicated server).
function TornadoSync:isClient()
    return g_currentMission ~= nil and not g_currentMission:getIsServer()
end

--- Host, dedicated server console and server admins may change gameplay settings.
function TornadoSync:canEditSettings()
    if g_currentMission == nil or g_currentMission:getIsServer() then
        return true
    end
    return g_currentMission.isMasterUser == true
end

--- Server: send an event to every client (not run locally). No-op in single player.
function TornadoSync:broadcast(event)
    if g_server ~= nil and self:isMultiplayer() then
        g_server:broadcastEvent(event, false)
    end
end

-- =========================================================================
-- CONSOLE / CONTROL PANEL HOOK
-- Every gameplay change goes through a TornadoConsole handler (the control panel calls the same ones).
-- The wrappers block non-admin clients, and send changed settings to the server / other players.
-- =========================================================================

local LOCAL_SET_MODULES = { save = true, mapui = true }

--- Whether a console call changes shared gameplay (true) or only this player's own view (false).
function TornadoSync:isGameplayCommand(method, a, b)
    if method == "cmdPhysics" or method == "cmdTune" or method == "cmdReset" then
        return true
    end
    if method == "cmdSFX" then
        return a == "fire_random"
    end
    if method == "cmdSet" then
        if a == nil or LOCAL_SET_MODULES[a] then return false end
        if a == "cargo" and b == "verbose" then return false end
        if (a == "traffic" or a == "climate" or a == "wildlife" or a == "money" or a == "hazards" or a == "insurance") and (b == "status" or b == "list") then return false end
        return true
    end
    return false
end

function TornadoSync:wrapConsole()
    if TornadoConsole == nil then
        return
    end
    for _, method in ipairs({ "cmdPhysics", "cmdTune", "cmdReset", "cmdSet", "cmdSFX" }) do
        local original = TornadoConsole[method]
        if original ~= nil then
            TornadoConsole[method] = function(console, a, b, ...)
                if not TornadoSync:isGameplayCommand(method, a, b) then
                    return original(console, a, b, ...)
                end
                if not TornadoSync:canEditSettings() then
                    return "Multiplayer: only the host or a server admin can change tornado gameplay settings."
                end

                -- Randomize is an action, not a setting: a client asks the server to do it.
                if method == "cmdPhysics" and a == "randomize" and TornadoSync:isClient() then
                    g_client:getServerConnection():sendEvent(TornadoActionEvent.new(TornadoActionEvent.RANDOMIZE))
                    return "Physics: New tornado size requested from the server."
                end

                local before = TornadoSync.snapshot()
                local result = original(console, a, b, ...)
                if snapshotsDiffer(before, TornadoSync.snapshot()) then
                    TornadoSync:onSettingsChangedLocally()
                end
                return result
            end
        end
    end
end

--- After a local gameplay change: clients send it to the server, the server re-broadcasts it.
function TornadoSync:onSettingsChangedLocally()
    if not self:isMultiplayer() then
        return
    end
    if self:isClient() then
        g_client:getServerConnection():sendEvent(TornadoSettingsEvent.new())
    else
        self:broadcast(TornadoSettingsEvent.new())
    end
end

-- =========================================================================
-- SERVER -> CLIENT HELPERS (called by the gameplay modules)
-- =========================================================================

--- Touchdown / despawn / size change.
function TornadoSync:sendTornadoState(isActive, isNewTouchdown)
    self:broadcast(TornadoStateEvent.new(isActive, isNewTouchdown))
end

function TornadoSync:sendWeather(profile)
    if profile ~= nil then
        self:broadcast(TornadoWeatherEvent.new(profile))
    end
end

function TornadoSync:sendDestruction(vehicle, nodes, isRepair)
    if vehicle ~= nil and vehicle.components ~= nil then
        self:broadcast(TornadoDestructionEvent.new(vehicle, nodes, isRepair))
    end
end

function TornadoSync:sendFx(vehicle, kind)
    if vehicle ~= nil then
        self:broadcast(TornadoFxEvent.new(vehicle, kind))
    end
end

--- Shows a message to everyone (farmId nil) or one farm, including the host. key = text key,
--- params = TornadoText.str/num/key/cash list; every player formats it in their own language.
function TornadoSync:sendMessage(key, params, kind, farmId)
    if not self:isMultiplayer() then
        TornadoMessageEvent.show(TornadoText.formatMessage(key, params), kind)
        return
    end
    local event = TornadoMessageEvent.new(key, params, kind)
    if farmId ~= nil and farmId ~= 0 and g_currentMission.broadcastEventToFarm ~= nil then
        g_currentMission:broadcastEventToFarm(event, farmId, true)
    else
        g_server:broadcastEvent(event, true)
    end
end

-- =========================================================================
-- JOINING PLAYERS
-- =========================================================================

function TornadoSync:sendInitialState(connection)
    connection:sendEvent(TornadoSettingsEvent.new())

    local tornadoActive = TornadoPhysics ~= nil and TornadoPhysics.tornadoNode ~= nil and entityExists(TornadoPhysics.tornadoNode)
    if tornadoActive then
        connection:sendEvent(TornadoStateEvent.new(true, false))
        if TornadoWeather ~= nil and TornadoWeather.lastProfile ~= nil then
            connection:sendEvent(TornadoWeatherEvent.new(TornadoWeather.lastProfile))
        end
    end

    if TornadoHazards ~= nil and TornadoHazards.fire ~= nil and TornadoFieldFireEvent ~= nil then
        connection:sendEvent(TornadoFieldFireEvent.new(TornadoFieldFireEvent.START, TornadoHazards:getFireData(TornadoHazards.fire)))
    end

    if TornadoInsurance ~= nil and TornadoInsurance.sendInitialState ~= nil then
        TornadoInsurance:sendInitialState(connection)
    end

    if TornadoDestruction ~= nil and TornadoDestruction._destroyedObjects ~= nil then
        for _, data in pairs(TornadoDestruction._destroyedObjects) do
            if data.obj ~= nil and data.obj.components ~= nil then
                connection:sendEvent(TornadoDestructionEvent.new(data.obj, data.nodes, false))
            end
        end
    end
end

function TornadoSync:installHooks()
    -- FSBaseMission survives savegame reloads; flag it so the hook is only appended once.
    if FSBaseMission.tornadoSyncHooked then
        return
    end
    FSBaseMission.tornadoSyncHooked = true
    FSBaseMission.sendInitialClientState = Utils.appendedFunction(FSBaseMission.sendInitialClientState,
        function(mission, connection, user, farm)
            if TornadoSync ~= nil then
                TornadoSync:sendInitialState(connection)
            end
        end)
end

-- =========================================================================
-- VEHICLE NODE PATHS
-- Node ids differ per machine, the i3d hierarchy does not: a node is sent as
-- (component index, child index path from that component).
-- =========================================================================

function TornadoSync.encodeNodePath(vehicle, node)
    if vehicle == nil or vehicle.components == nil or node == nil or node == 0 or not entityExists(node) then
        return nil
    end
    local componentIndex = {}
    for i, component in ipairs(vehicle.components) do
        if component.node ~= nil then
            componentIndex[component.node] = i
        end
    end

    local path = {}
    local current = node
    while current ~= nil and current ~= 0 do
        local index = componentIndex[current]
        if index ~= nil then
            -- Reverse into root -> leaf order.
            local ordered = {}
            for i = #path, 1, -1 do
                ordered[#ordered + 1] = path[i]
            end
            return { component = index, path = ordered }
        end
        path[#path + 1] = getChildIndex(current)
        current = getParent(current)
    end
    return nil
end

function TornadoSync.decodeNodePath(vehicle, entry)
    if vehicle == nil or vehicle.components == nil or vehicle.components[entry.component] == nil then
        return nil
    end
    local node = vehicle.components[entry.component].node
    for _, index in ipairs(entry.path) do
        if node == nil or node == 0 or index >= getNumOfChildren(node) then
            return nil
        end
        node = getChildAt(node, index)
    end
    return node
end
