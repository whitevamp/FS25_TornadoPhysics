---@class TornadoConsole
---@version 1.1 (RESET + VERBOSE)
---@description Central Command Hub. Now includes Master Reset and Selective Logging.

TornadoConsole = {}

function TornadoConsole:loadMap()
    print("--------------------------------------------------")
    print("TORNADO CONSOLE: SYSTEM ONLINE")

    -- 1. PHYSICS
    addConsoleCommand("t_physics", "Adjust Physics: radius, power, heavy, fence, randomize...", "cmdPhysics", self)

    -- 2. SFX
    addConsoleCommand("t_sfx", "Adjust SFX: sound, ring, particles...", "cmdSFX", self)

    -- 3. SET
    addConsoleCommand("t_set", "Module Settings: cargo, husbandry, save...", "cmdSet", self)

    -- 4. DEV
    addConsoleCommand("t_dev", "Developer Tools: status, verbose, hud, hotspotdump, kill_test...", "cmdDev", self)

    -- 5. TUNE
    addConsoleCommand("t_tune", "Fine-tune Physics Constants", "cmdTune", self)

    -- 6. RESET
    addConsoleCommand("t_reset", "Reset Settings: all, physics, tuning, cargo...", "cmdReset", self)

    -- 7. HELP
    addConsoleCommand("t_help", "Lists all commands or shows details for one. Usage: t_help [command]", "cmdHelp", self)

    --8. Toggle for the emergency DLC.
    -- addConsoleCommand("t_emergency", "Toggle DLC Emergency triggers on vehicle destruction (true/false)", "cmdEmergency", self)
end

function TornadoConsole:deleteMap()
    removeConsoleCommand("t_physics")
    removeConsoleCommand("t_sfx")
    removeConsoleCommand("t_set")
    removeConsoleCommand("t_dev")
    removeConsoleCommand("t_tune")
    removeConsoleCommand("t_reset")
    removeConsoleCommand("t_help")
    -- removeConsoleCommand("t_emergency")
end

-- =========================================================================
-- HELP COMMAND
-- =========================================================================
function TornadoConsole:cmdHelp(command)
    if command == nil then
        print("---------------- TORNADO ENGINE HELP ----------------")
        print("Usage: t_help [command] for more details.")
        print("t_physics: Adjust Physics: radius, power, heavy, fence, randomize...")
        print("t_sfx: Adjust SFX: sound, ring, particles...")
        print("t_set: Module Settings: cargo, husbandry, destruction, traffic, wildlife, climate, save...")
        print("t_dev: Developer Tools: status, verbose, hud, hotspotdump, kill_test...")
        print("t_tune: Fine-tune Physics Constants")
        print("t_reset: Reset Settings: all, physics, tuning, cargo...")
        print("--------------------------------------------------")
        return "Command list printed. Use 't_help [command]' for more details."
    end

    if command == "t_physics" then
        print("---------------- t_physics HELP ----------------")
        print("Usage: t_physics [sub-command] [value]")
        print(" ")
        print("Sub-commands:")
        print("  radius <number>       - Sets the tornado's base radius. Ex: t_physics radius 40")
        print("  power <number>        - Sets the ejection force. Ex: t_physics power 25")
        print("  heavy <number>        - Sets mass threshold for heavy vehicles (tons). Ex: t_physics heavy 4.0")
        print("  fence <number>        - Sets safety distance from map border (meters). Ex: t_physics fence 50")
        print("  dmg_in <number>       - Sets damage/sec inside the core (0-100). Ex: t_physics dmg_in 0.3")
        print("  dmg_out <number>      - Sets damage/sec in outer winds (0-100). Ex: t_physics dmg_out 0.1")
        print("  lift_bales            - Toggles lifting bales.")
        print("  lift_logs             - Toggles lifting logs.")
        print("  border                - Toggles map border safety protection.")
        print("  indoor_damage         - Toggles damage to vehicles inside sheds.")
        print("  outdoor_damage        - Toggles damage to vehicles outside.")
        print("  randomize             - Forces a new tornado size/rating immediately.")
        print("--------------------------------------------------")
    elseif command == "t_sfx" then
        print("---------------- t_sfx HELP ----------------")
        print("Usage: t_sfx [sub-command]")
        print(" ")
        print("Sub-commands:")
        print("  sound                 - Mutes/Unmutes the tornado siren.")
        print("  ring                  - Toggles the red 'Danger Zone' debug ring.")
        print("  fire_random           - Toggles random fire effects ON/OFF.")
        print("--------------------------------------------------")
    elseif command == "t_set" then
        print("---------------- t_set HELP ----------------")
        print("Usage: t_set [module] [sub-command] [value]")
        print(" ")
        print("Modules:")
        print("  save                  - Saves all settings to XML. Ex: t_set save")
        print(" ")
        print("  destruction [on|off]  - Toggles the visual destruction system.")
        print(" ")
        print("  recovery              - Toggles the hardcore emergency tow bill ON/OFF.")
        print(" ")
        print("  mapui [sub-command]   - Controls the map overlay.")
        print("    (no sub-command)    - Toggles the overlay ON/OFF.")
        print("    on|off              - Explicitly turns the overlay ON or OFF.")
        print("    sel                 - Toggles 'only show when selected' mode.")
        print("    dump                - Prints Map UI state to console.")
        print(" ")
        print("  cargo [sub-command]   - Controls cargo spilling.")
        print("    toggle              - Toggles the cargo spill system ON/OFF.")
        print("    verbose             - Toggles detailed debug logs for cargo.")
        print("    spill_height <num>  - Min height to spill (meters). Ex: t_set cargo spill_height 2.0")
        print("    spill_angle <num>   - Angle to spill (0-1). Ex: t_set cargo spill_angle 0.6")
        print("    drain_rate <num>    - Speed of cargo loss. Ex: t_set cargo drain_rate 0.15")
        print("    spread <num>        - Radius of spilled cargo piles. Ex: t_set cargo spread 5.0")
        print("    leak_chance <num>   - Chance for covered trailers to leak (0-1). Ex: t_set cargo leak_chance 0.1")
        print(" ")
        print("  husbandry [sub-command] - Controls animal safety.")
        print("    toggle              - Toggles animal death system ON/OFF.")
        print("    immunity <seconds>  - Sets post-impact immunity duration. Ex: t_set husbandry immunity 180")
        print(" ")
        print("  traffic [sub-command] - AI road traffic and pedestrians stop before the tornado.")
        print("    (no sub-command)    - Toggles the roadblocks ON/OFF.")
        print("    on|off              - Explicitly turns the roadblocks ON or OFF.")
        print("    buffer <meters>     - Distance beyond the tornado radius where cars stop. Ex: t_set traffic buffer 60")
        print("    status              - Shows how many roadblocks are active.")
        print(" ")
        print("  money [percent|status] - Scale for everything the mod charges (tow bill ...). 25 - 200, default 100.")
        print("                          Also scaled by the savegame's economic difficulty. Ex: t_set money 50")
        print(" ")
        print("  wildlife [sub-command] - Wildlife flees the tornado (caught animals vanish); the farm dog runs home.")
        print("    (no sub-command)    - Toggles it ON/OFF.")
        print("    on|off              - Explicitly turns it ON or OFF.")
        print("    distance <meters>   - How far beyond the tornado radius animals start to flee. Ex: t_set wildlife distance 200")
        print("    status              - Shows the settings and how many animals were caught.")
        print(" ")
        print("  climate [sub-command] - Real-life tornado climate (EF rating, size, hail and wind from NOAA data).")
        print("    (no sub-command)    - Toggles real-life mode ON/OFF (OFF = classic random tornadoes).")
        print("    on|off              - Explicitly turns real-life mode ON or OFF.")
        print("    region <name|auto>  - Region to use. Ex: t_set climate region oklahoma | OK | US | auto")
        print("    list                - Prints all available regions.")
        print("    status              - Shows the mode, region in use, last roll, storm and outbreak state.")
        print("    seasons [on|off]    - Tornado timing follows the region's months and time of day.")
        print("    direction [on|off]  - Tornado tracks follow the region's real directions (mostly toward NE in the US).")
        print("    outbreaks [on|off]  - Busy storm days: more tornadoes the same day, with the region's odds.")
        print("    frequency <x>       - Multiplier on the map's tornado rate (0.25 - 4). Ex: t_set climate frequency 2")
        print("    outbreakmax <n>     - Max tornadoes in one outbreak day, first one included (2 - 10).")
        print("--------------------------------------------------")
    elseif command == "t_dev" then
        print("---------------- t_dev HELP ----------------")
        print("Usage: t_dev [sub-command]")
        print(" ")
        print("Sub-commands:")
        print("  verbose               - Toggles global verbose logging for all modules.")
        print("  hud                   - Toggles the physics telemetry HUD over vehicles.")
        print("  status                - Prints a status summary to the console.")
        print("  hotspotdump           - Prints internal state of Hotspot and MapUI modules.")
        print("  kill_test             - Triggers a test of the husbandry kill logic.")
        print("  wildlife list         - Lists this map's wildlife species and how many are spawned around you.")
        print("  wildlife spawn <species> [distance] [count] [rotation]")
        print("                        - Spawns wildlife in front of you (to test fleeing). Ex: t_dev wildlife spawn crow 60 5")
        print("--------------------------------------------------")
    elseif command == "t_tune" then
        print("---------------- t_tune HELP ----------------")
        print("Usage: t_tune [parameter] [value]")
        print(" ")
        print("Parameters:")
        print("  suction <number>      - Inward pull speed. Ex: t_tune suction 55")
        print("  lift <number>         - Vertical lift speed. Ex: t_tune lift 15")
        print("  bale_orbit <number>   - Orbit speed for bales. Ex: t_tune bale_orbit 25")
        print("  bale_suction <number> - Suction speed for bales. Ex: t_tune bale_suction 20")
        print("  purge_time <ms>       - Duration of ejection phase. Ex: t_tune purge_time 6000")
        print("  purge_int <ms>        - Interval between ejections. Ex: t_tune purge_int 25000")
        print("  chaos <number>        - Randomness factor for movement. Ex: t_tune chaos 6")
        print("  hover <number>        - Max height for floating objects. Ex: t_tune hover 40")
        print("  max_speed <number>    - Physics speed cap. Ex: t_tune max_speed 40")
        print("  destruct_ratio <num>  - Percent of radius for core destruction (0-1). Ex: t_tune destruct_ratio 0.25")
        print("--------------------------------------------------")
    elseif command == "t_reset" then
        print("---------------- t_reset HELP ----------------")
        print("Usage: t_reset [category]")
        print(" ")
        print("Categories:")
        print("  all                   - Resets ALL settings to factory defaults.")
        print("  physics               - Resets main physics settings (radius, power, etc).")
        print("  tuning                - Resets advanced tuning values.")
        print("  cargo                 - Resets cargo module settings.")
        print("  husbandry             - Resets husbandry module settings.")
        print("  traffic               - Resets traffic roadblock settings.")
        print("  wildlife              - Resets wildlife settings (ON, flee distance 150 m).")
        print("  climate               - Resets real-life climate mode (OFF, region Auto).")
        print("--------------------------------------------------")
    else
        return string.format("Unknown command '%s'. Use 't_help' to see all commands.", tostring(command))
    end
end

-- =========================================================================
-- 1. PHYSICS COMMANDS
-- =========================================================================
function TornadoConsole:cmdPhysics(setting, value)
    if not TornadoPhysics or not TornadoPhysics.settings then return "Error: Physics module missing." end
    local val = tonumber(value)

    if setting == "radius" then
        if val then
            TornadoPhysics.settings.base_radius = val
            TornadoPhysics:randomizeTornado()
            return string.format("Physics: Base Radius set to %.1fm", val)
        end
        return "Usage: t_physics radius [number]"
    elseif setting == "power" then
        if val then
            TornadoPhysics.settings.ejection_power = val
            return string.format("Physics: Ejection Power set to %.1f", val)
        end
        return "Usage: t_physics power [number]"
    elseif setting == "heavy" then
        if val then
            TornadoPhysics.settings.heavy_threshold = val
            return string.format("Physics: Heavy Mass Threshold set to %.1ft", val)
        end
        return "Usage: t_physics heavy [number]"
    elseif setting == "fence" then
        if val then
            TornadoPhysics.settings.geo_fence = val
            return string.format("Physics: Geo-Fence Buffer set to %.1fm", val)
        end
        return "Usage: t_physics fence [number]"
    elseif setting == "dmg_in" then
        if val then
            TornadoPhysics.settings.damage_center = val
            return string.format("Physics: Inner Damage Rate set to %.3f", val)
        end
        return "Usage: t_physics dmg_in [number]"
    elseif setting == "dmg_out" then
        if val then
            TornadoPhysics.settings.damage_outer = val
            return string.format("Physics: Outer Damage Rate set to %.3f", val)
        end
        return "Usage: t_physics dmg_out [number]"
    elseif setting == "lift_bales" then
        TornadoPhysics.settings.lift_bales = not TornadoPhysics.settings.lift_bales
        return "Physics: Lift Bales = " .. tostring(TornadoPhysics.settings.lift_bales)
    elseif setting == "lift_logs" then
        TornadoPhysics.settings.lift_logs = not TornadoPhysics.settings.lift_logs
        return "Physics: Lift Logs = " .. tostring(TornadoPhysics.settings.lift_logs)
    elseif setting == "border" then
        TornadoPhysics.settings.border_safety = not TornadoPhysics.settings.border_safety
        return "Physics: Border Safety = " .. tostring(TornadoPhysics.settings.border_safety)
    elseif setting == "indoor_damage" then
        TornadoPhysics.settings.indoor_damage = not TornadoPhysics.settings.indoor_damage
        return "Physics: Indoor Damage = " .. tostring(TornadoPhysics.settings.indoor_damage)
    elseif setting == "outdoor_damage" then
        TornadoPhysics.settings.outdoor_damage = not TornadoPhysics.settings.outdoor_damage
        return "Physics: Outdoor Damage = " .. tostring(TornadoPhysics.settings.outdoor_damage)
    elseif setting == "randomize" then
        TornadoPhysics:randomizeTornado()
        return "Physics: Forcing new Tornado scale/rating..."
    else
        return "Unknown Physics CMD. Try: radius, power, heavy, fence, dmg_in, dmg_out, lift_bales, lift_logs, border, indoor_damage, outdoor_damage, randomize..."
    end
end

-- =========================================================================
-- 2. SFX COMMANDS
-- =========================================================================
function TornadoConsole:cmdSFX(setting, value)
    if setting == "sound" then
        if TornadoSFX then
            TornadoSFX:toggleSound()
            return "SFX: Toggled Sound System."
        end
        return "Error: SFX Module missing."
    elseif setting == "ring" then
        if TornadoPhysics then
            TornadoPhysics.showRing = not TornadoPhysics.showRing
            return "SFX: Debug Ring Visible = " .. tostring(TornadoPhysics.showRing)
        end
    elseif setting == "fire_random" then
        if TornadoEffects then
            TornadoEffects.CONFIG.RANDOM_FIRE_MODE = not TornadoEffects.CONFIG.RANDOM_FIRE_MODE
            return "SFX: Random Fire Mode = " .. tostring(TornadoEffects.CONFIG.RANDOM_FIRE_MODE)
        end
    else
        return "Unknown SFX CMD. Try: sound, ring, fire_random"
    end
end

-- =========================================================================
-- 3. SET COMMANDS
-- =========================================================================
function TornadoConsole:cmdSet(module, subCmd, value, ...)


-- ------------------------------------------------------------
-- ------------------------------------------------------------
-- MapUI overlay controls
--   t_set mapui            -> toggle enable
--   t_set mapui on|off     -> explicit
--   t_set mapui sel        -> toggle only-when-selected
--   t_set mapui dump       -> print MapUI state
-- ------------------------------------------------------------
if module == "mapui" then
    if TornadoMapUI == nil then
        return "MapUI: not loaded."
    end

    local sub = subCmd  -- cmdSet signature: (module, subCmd, value)

    if sub == "dump" then
        if TornadoMapUI.dumpState ~= nil then
            TornadoMapUI:dumpState()
        end
        return "MapUI: dump printed."
    end

    if sub == "sel" then
        TornadoMapUI.onlyWhenSelected = not TornadoMapUI.onlyWhenSelected
        return "MapUI: onlyWhenSelected = " .. tostring(TornadoMapUI.onlyWhenSelected)
    end

    if sub == "on" then
        TornadoMapUI.enabled = true
        return "MapUI: Enabled = true"
    end

    if sub == "off" then
        TornadoMapUI.enabled = false
        return "MapUI: Enabled = false"
    end

    TornadoMapUI.enabled = not TornadoMapUI.enabled
    return "MapUI: Enabled = " .. tostring(TornadoMapUI.enabled)
end
    if module == "save" then
        if TornadoSettings then
            TornadoSettings:saveToXML()
            return "Settings: Configuration Saved to XML."
        end
        return "Error: Settings Module missing."
    end

    if module == "destruction" then
        if not (TornadoPhysics and TornadoPhysics.settings) then return "Error: Physics module missing." end
        local s = TornadoPhysics.settings
        if subCmd == "on" or subCmd == "true" then
            s.destructionEnabled = true
        elseif subCmd == "off" or subCmd == "false" then
            s.destructionEnabled = false
        else
            s.destructionEnabled = not s.destructionEnabled
        end
        return "Destruction: System Enabled = " .. tostring(s.destructionEnabled)
    end

    if module == "money" then
        if not TornadoSettings then return "Error: Settings module missing." end
        local val = tonumber(subCmd)
        if val ~= nil then
            -- Given in per cent (25 - 200)
            TornadoSettings.moneyScale = math.max(TornadoSettings.MONEY_SCALE_MIN,
                math.min(TornadoSettings.MONEY_SCALE_MAX, val / 100))
        elseif subCmd ~= nil and subCmd ~= "status" then
            return "Usage: t_set money [percent 25-200 | status]"
        end
        local costMultiplier = TornadoSettings.moneyScale > 0 and TornadoSettings:getCostScale() / TornadoSettings.moneyScale or 1
        return string.format("Money: scale = %.0f%% | game difficulty cost multiplier = x%.2f | charges = %.0f%% of normal",
            TornadoSettings.moneyScale * 100, costMultiplier, TornadoSettings:getCostScale() * 100)
    end

    if module == "recovery" then
        if TornadoSettings then
            -- Flip the master flag
            TornadoSettings.recoveryEnabled = not TornadoSettings.recoveryEnabled
            
            -- Auto-save it to XML so it persists between sessions!
            TornadoSettings:saveToXML()
            
            if TornadoSettings.recoveryEnabled then
                return "ECONOMY: Hardcore Recovery Bill ENABLED."
            else
                return "ECONOMY: Hardcore Recovery Bill DISABLED."
            end
        end
        return "Error: Settings Module missing."
    end

    if module == "cargo" then
        if not TornadoCargo then return "Error: Cargo Module missing." end

        if subCmd == nil or subCmd == "toggle" then
            TornadoCargo:toggle()
            return "Cargo: System Enabled = " .. tostring(TornadoCargo.isEnabled)
        
        -- Verbose Logging Toggle
        elseif subCmd == "verbose" then
            TornadoCargo.isVerbose = not TornadoCargo.isVerbose
            return "Cargo: Verbose Logging = " .. tostring(TornadoCargo.isVerbose)
        end

        local val = tonumber(value)
        if TornadoCargo.settings then
            if subCmd == "spill_height" and val then
                TornadoCargo.settings.spillHeight = val
                return string.format("Cargo: Spill Height set to %.1f", val)
            elseif subCmd == "drain_rate" and val then
                TornadoCargo.settings.drainRate = val
                return string.format("Cargo: Drain Rate set to %.3f", val)
            elseif subCmd == "spill_angle" and val then
                TornadoCargo.settings.spillAngle = val
                return string.format("Cargo: Spill Angle set to %.2f", val)
            elseif subCmd == "spread" and val then
                TornadoCargo.settings.spreadRadius = val
                return string.format("Cargo: Spread Radius set to %.1fm", val)
            elseif subCmd == "leak_chance" and val then
                TornadoCargo.settings.coverLeakChance = val
                return string.format("Cargo: Cover Leak Chance set to %.4f", val)
            else
                return "Unknown Cargo CMD. Try: verbose, spill_height, drain_rate, spill_angle, spread, leak_chance..."
            end
        end
    end

    if module == "husbandry" then
        if not TornadoHusbandry then return "Error: Husbandry Module missing." end
        if subCmd == nil or subCmd == "toggle" then
            TornadoHusbandry.isActive = not TornadoHusbandry.isActive
            return "Husbandry: Lethality = " .. tostring(TornadoHusbandry.isActive)
        elseif subCmd == "immunity" then
            local val = tonumber(value)
            if val then
                TornadoHusbandry.IMMUNITY_DURATION = val * 1000
                TornadoHusbandry.customImmunitySet = true
                return string.format("Husbandry: Immunity set to %.1fs", val)
            end
            return "Usage: t_set husbandry immunity [seconds]"
        else
            return "Unknown Husbandry CMD. Try: immunity, toggle"
        end
    end

    if module == "wildlife" then
        if not TornadoWildlife then return "Error: Wildlife Module missing." end

        if subCmd == "on" or subCmd == "true" then
            TornadoWildlife.isEnabled = true
        elseif subCmd == "off" or subCmd == "false" then
            TornadoWildlife.isEnabled = false
        elseif subCmd == "distance" then
            local val = tonumber(value)
            if val == nil then return "Usage: t_set wildlife distance [meters]" end
            TornadoWildlife.fleeDistance = math.max(0, val)
            return string.format("Wildlife: Flee distance beyond tornado radius set to %.0fm", TornadoWildlife.fleeDistance)
        elseif subCmd == "status" then
            return TornadoWildlife:getStatusText()
        elseif subCmd == nil or subCmd == "toggle" then
            TornadoWildlife.isEnabled = not TornadoWildlife.isEnabled
        else
            return "Unknown Wildlife CMD. Try: on, off, distance, status"
        end
        return "Wildlife: Flees the tornado = " .. tostring(TornadoWildlife.isEnabled)
    end

    if module == "traffic" then
        if not TornadoTraffic then return "Error: Traffic Module missing." end

        if subCmd == "on" or subCmd == "true" then
            TornadoTraffic.isEnabled = true
        elseif subCmd == "off" or subCmd == "false" then
            TornadoTraffic.isEnabled = false
        elseif subCmd == "buffer" then
            local val = tonumber(value)
            if val == nil then return "Usage: t_set traffic buffer [meters]" end
            TornadoTraffic.bufferDistance = math.max(0, val)
            return string.format("Traffic: Stop distance beyond tornado radius set to %.0fm", TornadoTraffic.bufferDistance)
        elseif subCmd == "status" then
            return string.format("Traffic: Enabled = %s | Buffer = %.0fm | Active roadblocks = %d | Pedestrian blocks (this machine) = %d",
                tostring(TornadoTraffic.isEnabled), TornadoTraffic.bufferDistance, TornadoTraffic:getNumActiveBlocks(),
                TornadoTraffic:getNumActivePedestrianBlocks())
        elseif subCmd == nil or subCmd == "toggle" then
            TornadoTraffic.isEnabled = not TornadoTraffic.isEnabled
        else
            return "Unknown Traffic CMD. Try: on, off, buffer, status"
        end
        return "Traffic: Roadblocks Enabled = " .. tostring(TornadoTraffic.isEnabled)
    end

    if module == "climate" then
        if not TornadoClimate then return "Error: Climate Module missing." end

        if subCmd == "on" or subCmd == "true" then
            TornadoClimate.isEnabled = true
        elseif subCmd == "off" or subCmd == "false" then
            TornadoClimate.isEnabled = false
        elseif subCmd == "region" then
            if value == nil then return "Usage: t_set climate region [name | postal code | US | auto]" end
            -- The console splits on spaces; glue multi-word names back together ("new york").
            local regionName = table.concat({ value, ... }, " ")
            if not TornadoClimate:setRegion(regionName) then
                return string.format("Climate: Unknown region '%s'. Use 't_set climate list'.", regionName)
            end
            return "Climate: Region = " .. TornadoClimate:getRegionLabel(TornadoClimate.regionSetting)
        elseif subCmd == "list" then
            if not TornadoClimate:hasData() then return "Climate: No climate data loaded (DB/TornadoClimate.xml missing)." end
            print("---------------- CLIMATE REGIONS ----------------")
            for _, id in ipairs(TornadoClimate.regionOrder) do
                print(string.format("  %-6s %s", id, TornadoClimate.regions[id].name))
            end
            print("-------------------------------------------------")
            return string.format("Climate: %d regions listed.", #TornadoClimate.regionOrder)
        elseif subCmd == "status" then
            local active = TornadoClimate:getActiveRegion()
            local last = TornadoClimate.lastRoll
            return string.format("Climate: Real-life = %s | Setting = %s | In use = %s | Last roll = %s | Last storm = %s | Seasons = %s, Direction = %s, Outbreaks = %s (max %d), Frequency = x%.2f | Outbreak = %s",
                tostring(TornadoClimate.isEnabled), TornadoClimate:getRegionLabel(TornadoClimate.regionSetting),
                active ~= nil and active.name or "none (classic)",
                last ~= nil and string.format("%s EF-%d", last.regionName, last.ef) or "none yet",
                TornadoWeather ~= nil and TornadoWeather:getLastProfileText() or "n/a",
                tostring(TornadoClimate.useSeasonality), tostring(TornadoClimate.useDirection),
                tostring(TornadoClimate.useOutbreaks), TornadoClimate.outbreakMax, TornadoClimate.frequency,
                TornadoOutbreak ~= nil and TornadoOutbreak:getStatusText() or "n/a")
        elseif subCmd == "seasons" or subCmd == "direction" or subCmd == "outbreaks" then
            local field = ({ seasons = "useSeasonality", direction = "useDirection", outbreaks = "useOutbreaks" })[subCmd]
            if value == "on" or value == "true" then
                TornadoClimate[field] = true
            elseif value == "off" or value == "false" then
                TornadoClimate[field] = false
            else
                TornadoClimate[field] = not TornadoClimate[field]
            end
            return string.format("Climate: %s = %s", subCmd, tostring(TornadoClimate[field]))
        elseif subCmd == "frequency" then
            local val = tonumber(value)
            if val == nil then return "Usage: t_set climate frequency [0.25 - 4]" end
            TornadoClimate.frequency = math.max(0.25, math.min(4, val))
            return string.format("Climate: Tornado frequency = x%.2f", TornadoClimate.frequency)
        elseif subCmd == "outbreakmax" then
            local val = tonumber(value)
            if val == nil then return "Usage: t_set climate outbreakmax [2 - 10]" end
            TornadoClimate.outbreakMax = math.max(2, math.min(10, math.floor(val + 0.5)))
            return string.format("Climate: Max tornadoes per outbreak = %d", TornadoClimate.outbreakMax)
        elseif subCmd == nil or subCmd == "toggle" then
            TornadoClimate.isEnabled = not TornadoClimate.isEnabled
        else
            return "Unknown Climate CMD. Try: on, off, region, list, status, seasons, direction, outbreaks, frequency, outbreakmax"
        end
        return "Climate: Real-life tornado climate = " .. tostring(TornadoClimate.isEnabled)
    end

   return "Unknown Set CMD. Try: save, cargo, husbandry, destruction, recovery, traffic, wildlife, climate"
end

-- =========================================================================
-- 4. DEV COMMANDS
-- =========================================================================
function TornadoConsole:cmdDev(tool, arg1, arg2, arg3, arg4, arg5)
    if tool == "verbose" then
        if TornadoDebug then
            -- Read the second word (arg1). If empty, default to "all"
            local target = arg1 and string.lower(arg1) or "all"

            if target == "destruction" then
                TornadoDebug.verboseDestruction = not TornadoDebug.verboseDestruction
                return "DEV: Destruction Verbose = " .. tostring(TornadoDebug.verboseDestruction)
            
            elseif target == "destruction_indoor_bypass" then
                TornadoDebug.verboseIndoorBypass = not TornadoDebug.verboseIndoorBypass
                return "DEV: Indoor Bypass Verbose = " .. tostring(TornadoDebug.verboseIndoorBypass)
                
            elseif target == "physics" then
                TornadoDebug.verbosePhysics = not TornadoDebug.verbosePhysics
                return "DEV: Physics Verbose = " .. tostring(TornadoDebug.verbosePhysics)
                
            elseif target == "all" then
                local newState = not TornadoDebug.verboseMode
                TornadoDebug.verboseMode = newState
                TornadoDebug.verboseDestruction = newState
                TornadoDebug.verbosePhysics = newState
                -- this one is way to noisy to be included into the all debug channel. 
                -- and didnt feal like adding it into a dedicated channel.
                -- but left here just for the sake of it.
                --TornadoDebug.verboseIndoorBypass = newState
                return "DEV: ALL Verbose Logging = " .. tostring(newState)
                
            else
                return "Unknown verbose target. Use: all, destruction, destruction_indoor_bypass, or physics"
            end
        end
        return "TornadoDebug not found."

    elseif tool == "wildlife" then
        if not TornadoWildlife then return "Error: Wildlife Module missing." end
        return TornadoWildlife:consoleCommand(arg1, arg2, arg3, arg4, arg5)

    elseif tool == "pos" then 
        if TornadoDebug then
            TornadoDebug.showPosition = not TornadoDebug.showPosition
            return "Position Tracking: " .. tostring(TornadoDebug.showPosition)
        end

    elseif tool == "hud" then
        if TornadoPhysics then
            TornadoPhysics.debugMode = not TornadoPhysics.debugMode
            return "DEV: Physics Telemetry HUD = " .. tostring(TornadoPhysics.debugMode)
        end

    elseif tool == "status" then
        if TornadoPhysics then
            local c = 0
            for _ in pairs(TornadoPhysics.activeNodes) do c = c + 1 end
            print(string.format("[STATUS] Active Nodes: %d | Purge: %.1f/%.1f",
                c, TornadoPhysics.purgeTimer / 1000, TornadoPhysics:getPurgeInterval() / 1000))
            return "Check Console for Status."
        end

    elseif tool == "hotspotdump" then
        if TornadoHotspot and TornadoHotspot.dumpState ~= nil then
            TornadoHotspot:dumpState()
            return "DEV: Hotspot dump printed."
        elseif TornadoMapUI and TornadoMapUI.dumpState ~= nil then
            TornadoMapUI:dumpState()
            return "DEV: MapUI dump printed."
        end
        return "DEV: Hotspot/MapUI dump not available."

    elseif tool == "kill_test" then
        if TornadoHusbandry then
            TornadoHusbandry:debugKillTest()
            return "DEV: Kill Test Triggered (Check Logs)"
        end

    else
        return "Unknown Dev CMD. Try: verbose, hud, pos, status, hotspotdump, kill_test"
    end
end

-- =========================================================================
-- 5. TUNING COMMANDS
-- =========================================================================
function TornadoConsole:cmdTune(param, value)
    if not TornadoPhysics or not TornadoPhysics.settings then return "Error: Physics module missing." end
    local val = tonumber(value)
    if not val then return "Usage: t_tune [param] [number]" end

    local s = TornadoPhysics.settings
    if param == "suction" then s.suction_speed = val
    elseif param == "lift" then s.lift_speed = val
    elseif param == "bale_orbit" then s.bale_orbit = val
    elseif param == "bale_suction" then s.bale_suction = val
    elseif param == "purge_time" then s.purge_duration = val
    elseif param == "purge_int" then s.purge_interval = val
    elseif param == "chaos" then s.chaos_factor = val
    elseif param == "hover" then s.hover_height = val
    elseif param == "max_speed" then s.max_safe_speed = val
    elseif param == "destruct_ratio" then s.destruction_ratio = val
    else return "Unknown param. Try: suction, lift, bale_orbit, chaos, hover, max_speed..." end

    return string.format("Tuning: '%s' set to %.2f", param, val)
end

-- =========================================================================
-- 6. RESET COMMANDS
-- =========================================================================
function TornadoConsole:cmdReset(category)
    if not TornadoSettings then return "Error: Settings module missing." end
    
    if category == "all" or category == "physics" or category == "tuning" or category == "cargo" or category == "husbandry" or category == "traffic" or category == "wildlife" or category == "climate" then
        TornadoSettings:resetToDefaults(category)
        return string.format("RESET COMPLETE: '%s' settings restored to factory defaults.", category)
    else
        return "Usage: t_reset [all | physics | tuning | cargo | husbandry | traffic | wildlife | climate]"
    end
end

-- =========================================================================
-- 7. Emergency COMMANDS
-- =========================================================================
-- function TornadoConsole:cmdEmergency(state)
--     -- If no argument is provided, just report the current status
--     if state == nil then
--         local current = TornadoSettings.emergencyScenariosEnabled and "ENABLED" or "DISABLED"
--         return string.format("Emergency triggers are currently: %s. Use 't_emergency true' or 't_emergency false' to change.", current)
--     end

--     -- Sanitize input string to boolean
--     state = string.lower(tostring(state))
--     local targetState = nil
--     if state == "true" or state == "1" or state == "on" then
--         targetState = true
--     elseif state == "false" or state == "0" or state == "off" then
--         targetState = false
--     else
--         return "Invalid argument. Use: true, false, on, off, 1, or 0."
--     end

--     -- Apply the state to your settings tracking variable
--     TornadoSettings.emergencyScenariosEnabled = targetState

--     -- Force a save configuration rewrite so it persists across sessions
--     if TornadoSettings.saveToXML then
--         TornadoSettings:saveToXML()
--     elseif TornadoSettings.createDefaultXML then
--         TornadoSettings:createDefaultXML() -- Or whichever method writes out TornadoPhysics_Config.xml
--     end

--     local resultStr = targetState and "ENABLED" or "DISABLED"
--     return string.format("Tornado Emergency Pack triggers have been %s.", resultStr)
-- end