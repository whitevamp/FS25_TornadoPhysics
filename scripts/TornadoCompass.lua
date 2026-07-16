-- ==============================================================================
-- Tornado Physics Mod - Cross-Mod Compatibility Layer
-- Author: whitevamp
-- 
-- Integrates with:
--   - "Compass Heading" by RocklandUSA Gaming
-- ==============================================================================

---@class TornadoCompass
---@version 1.2 (Hard Override)
---@description Pushes dynamic EF ratings and live coordinates to the RocklandUSA Compass Mod while completely suppressing vanilla trackers.

TornadoCompass = {}

function TornadoCompass:loadMap(name)
    self.isHooked = false
    if TornadoDebug then TornadoDebug:log("COMPASS", "TornadoCompass Module Initialized") end
end

function TornadoCompass:deleteMap()
    self.isHooked = false
end

function TornadoCompass:update(dt)
    if g_currentMission == nil then return end

    if not self.isHooked and g_currentMission.compassHeading ~= nil then
        local compass = g_currentMission.compassHeading
        
        -- 1. Disable the native setting flag
        if type(compass.setSetting) == "function" then
            compass.setSetting("showTornadoMarker", false)
        else
            compass.showTornadoMarker = false
        end

        -- 2. HARD OVERRIDE: Evict and break their native internal scanning values
        -- This stops their native update loop from recreating or drawing the default icon.
        compass._tornadoNode = nil
        compass._tornadoScanTimer = 999999 -- Freeze their scanner from running again
        
        -- Clear out any existing native tornado markers from their active render table
        if compass._markers ~= nil then
            for id, marker in pairs(compass._markers) do
                if string.find(string.lower(id), "tornado") then
                    compass._markers[id] = nil
                end
            end
        end

        -- 3. Register our clean, custom dynamic EF-Rating provider
        if g_currentMission.compassHeadingRegistry ~= nil then
            g_currentMission.compassHeadingRegistry:register({
                id = "tornado_physics_custom",
                category = "emergency",
                getPoints = function()
                    if TornadoPhysics and TornadoPhysics.tornadoNode ~= nil and entityExists(TornadoPhysics.tornadoNode) then
                        local tX, _, tZ = getWorldTranslation(TornadoPhysics.tornadoNode)
                        local efRating = TornadoPhysics.currentEfNum or 0
                        
                        return {
                            {
                                x = tX,
                                z = tZ,
                                -- orignal 14 characters long : too long for the hard coded 8 charicter limit of compassheading.lua
                                --label = string.format("TORNADO (EF-%d)", efRating),
                                -- EF-(n)
                                --label = string.format("EF-%d", efRating),
                                -- EF-(n) ALRT
                                label = string.format("EF%d ALRT", efRating),
                                color = {r=1.0, g=0.15, b=0.15, a=1.0},
                                style = "diamond",
                                scale = 1.3,
                                urgent = true,
                                priority = 99
                            }
                        }
                    end
                    return {}
                end
            })
            if TornadoDebug then TornadoDebug:log("COMPASS", "Successfully hooked into client CompassHeading API with Hard Override!") end
        end
        
        self.isHooked = true
    end
end