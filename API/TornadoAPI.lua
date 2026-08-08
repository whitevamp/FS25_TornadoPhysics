---@class TornadoAPI
---@version 4.0.0
---@description Public API for FS25 Tornado Physics. Allows third-party mods to read telemetry, register event callbacks, and protect specific nodes from destruction.

TornadoAPI = {}
TornadoAPI._touchdownCallbacks = {}
TornadoAPI._despawnCallbacks = {}
TornadoAPI._destructionCallbacks = {}
TornadoAPI._protectedNodes = {}

-- Initialize the global registry for other mods to interact with
if g_tornadoPhysicsAPI == nil then
    g_tornadoPhysicsAPI = {}
end

-- ==========================================================
-- 1. TELEMETRY (Getters)
-- ==========================================================

--- Returns true if a tornado is currently active in the world
function g_tornadoPhysicsAPI.getIsActive()
    return TornadoPhysics ~= nil and TornadoPhysics.tornadoNode ~= nil and entityExists(TornadoPhysics.tornadoNode)
end

--- Returns a table of current tornado stats, or nil if inactive
function g_tornadoPhysicsAPI.getStats()
    if not g_tornadoPhysicsAPI.getIsActive() then return nil end
    return {
        efRating = TornadoPhysics.currentEfNum or 0,
        radius = TornadoPhysics.currentRadiusM or 0,
        windMin = TornadoPhysics.currentWindMin or 0,
        windMax = TornadoPhysics.currentWindMax or 0
    }
end

--- Returns the current world X and Z coordinates of the tornado, or nil
function g_tornadoPhysicsAPI.getPosition()
    if not g_tornadoPhysicsAPI.getIsActive() then return nil, nil end
    local tX, _, tZ = getWorldTranslation(TornadoPhysics.tornadoNode)
    return tX, tZ
end


-- ==========================================================
-- 2. EVENTS (Callbacks)
-- ==========================================================

--- Registers a function to be called when a tornado spawns
function g_tornadoPhysicsAPI.registerOnTouchdown(modId, callbackFunc)
    if type(callbackFunc) == "function" then
        TornadoAPI._touchdownCallbacks[modId] = callbackFunc
        if TornadoDebug then TornadoDebug:log("API", "Mod '" .. tostring(modId) .. "' registered Touchdown callback.") end
    end
end

--- Registers a function to be called when a tornado dissipates
function g_tornadoPhysicsAPI.registerOnDespawn(modId, callbackFunc)
    if type(callbackFunc) == "function" then
        TornadoAPI._despawnCallbacks[modId] = callbackFunc
        if TornadoDebug then TornadoDebug:log("API", "Mod '" .. tostring(modId) .. "' registered Despawn callback.") end
    end
end

--- Registers a function to be called right BEFORE an entity is destroyed
function g_tornadoPhysicsAPI.registerOnDestruction(modId, callbackFunc)
    if type(callbackFunc) == "function" then
        TornadoAPI._destructionCallbacks[modId] = callbackFunc
        if TornadoDebug then TornadoDebug:log("API", "Mod '" .. tostring(modId) .. "' registered Destruction callback.") end
    end
end


-- ==========================================================
-- 3. IMMUNITY (Protection Setters)
-- ==========================================================

--- Protects a specific entity node from being targeted by the destruction script
function g_tornadoPhysicsAPI.addProtectedNode(nodeId)
    if nodeId ~= nil and nodeId ~= 0 then
        TornadoAPI._protectedNodes[nodeId] = true
        if TornadoDebug then TornadoDebug:log("API", "Node " .. tostring(nodeId) .. " added to protection list.") end
    end
end

--- Removes protection from a specific entity node
function g_tornadoPhysicsAPI.removeProtectedNode(nodeId)
    if nodeId ~= nil then
        TornadoAPI._protectedNodes[nodeId] = nil
    end
end


-- ==========================================================
-- INTERNAL FIREWALL (Your mod calls these)
-- ==========================================================

function TornadoAPI:fireTouchdownEvent()
    local stats = g_tornadoPhysicsAPI.getStats()
    for modId, callback in pairs(self._touchdownCallbacks) do
        pcall(callback, stats)
    end
end

function TornadoAPI:fireDespawnEvent()
    for modId, callback in pairs(self._despawnCallbacks) do
        pcall(callback)
    end
end

function TornadoAPI:fireDestructionEvent(targetNode)
    for modId, callback in pairs(self._destructionCallbacks) do
        pcall(callback, targetNode)
    end
end

function TornadoAPI:isNodeProtected(nodeId)
    return self._protectedNodes[nodeId] == true
end