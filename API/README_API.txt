===============================================================================
                       FS25 TORNADO PHYSICS - PUBLIC API
                                 Version 4.0.0
===============================================================================

Welcome to the Tornado Physics Developer API. This framework allows third-party
mod authors to safely hook into the tornado lifecycle, read real-time storm 
telemetry, trigger emergency events, or protect critical map infrastructure 
and custom vehicles from being destroyed.

The API is fully initialized and published at map load on the global table:
   g_tornadoPhysicsAPI

All callbacks are fully insulated using pcalls to prevent a third-party script 
failure from crashing the core tornado physics engine.

-------------------------------------------------------------------------------
1. TELEMETRY (GETTERS)
-------------------------------------------------------------------------------

g_tornadoPhysicsAPI.getIsActive()
    - Description: Checks if a tornado is currently active in the session.
    - Returns: boolean (true/false)

g_tornadoPhysicsAPI.getStats()
    - Description: Retrieves the real-time physical properties of the storm.
    - Returns: table or nil (if inactive)
    - Table Structure:
        {
            efRating = integer, -- Current Enhanced Fujita rating (0 to 5)
            radius   = float,   -- Destruction radius in meters
            windMin  = float,   -- Minimum wind velocity metric
            windMax  = float    -- Maximum wind velocity metric
        }

g_tornadoPhysicsAPI.getPosition()
    - Description: Grabs the live world coordinates of the tornado's funnel.
    - Returns: worldX (float), worldZ (float) or nil, nil (if inactive)


-------------------------------------------------------------------------------
2. EVENT REGISTRATION (CALLBACKS)
-------------------------------------------------------------------------------

g_tornadoPhysicsAPI.registerOnTouchdown(modId, callbackFunc)
    - Description: Registers a function to fire the exact moment a tornado spawns.
    - Parameters:
        - modId (string): Unique identifier for your mod (e.g., "MySirenMod").
        - callbackFunc (function): Pushes a 'stats' table (same format as getStats()) 
          as an argument to your function.

g_tornadoPhysicsAPI.registerOnDespawn(modId, callbackFunc)
    - Description: Registers a function to fire when the tornado safely dissipates.
    - Parameters:
        - modId (string): Unique identifier for your mod.
        - callbackFunc (function): Fires with no arguments. Ideal for clearing alarms.

g_tornadoPhysicsAPI.registerOnDestruction(modId, callbackFunc)
    - Description: Fires immediately BEFORE the destruction engine applies lethal
                   damage and modular physics states to an entity.
    - Parameters:
        - modId (string): Unique identifier for your mod.
        - callbackFunc (function): Pushes the target entity 'targetNode' id as an 
          argument. Useful for tracking specific property damage statistics.


-------------------------------------------------------------------------------
3. TARGET IMMUNITY (SETTERS)
-------------------------------------------------------------------------------

g_tornadoPhysicsAPI.addProtectedNode(nodeId)
    - Description: Explicitly flags a world object or vehicle node as invincible.
                   The destruction script will bypass this node entirely. Ideal for
                   quest-critical items, custom bunkers, or indestructible props.
    - Parameters:
        - nodeId (integer): The raw GIANTS Engine scene graph nodeId.

g_tornadoPhysicsAPI.removeProtectedNode(nodeId)
    - Description: Removes a node from the protection array, re-exposing it to
                   potential tornado destruction.
    - Parameters:
        - nodeId (integer): The raw GIANTS Engine scene graph nodeId.


===============================================================================
                           BASIC IMPLEMENTATION EXAMPLE
===============================================================================

local function myEmergencySirenCallback(stormStats)
    if stormStats ~= nil and stormStats.efRating >= 3 then
        print("[Siren Mod] Severe Weather Detected! Firing EF-" .. tostring(stormStats.efRating) .. " alarms!")
        -- Put your siren activation or custom HUD rendering triggers here
    end
end

-- Safely verify the user has Tornado Physics V4 installed before attempting hook
if g_tornadoPhysicsAPI ~= nil then
    g_tornadoPhysicsAPI.registerOnTouchdown("MySirenMod", myEmergencySirenCallback)
end
===============================================================================