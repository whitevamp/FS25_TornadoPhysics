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
        print("t_sfx: Adjust SFX: sound, ring, fire_random")
        print("t_set: Module Settings: cargo, husbandry, destruction, traffic, wildlife, hazards, insurance, climate, save...")
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
        print("  fire_random           - Vehicle fires ON (chance by EF: 5 % at EF0 ... 45 % at EF5) / OFF (none).")
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
        print("  hazards [sub-command] - Natural hazards: drought, floods and field fires damage crops (OFF by default).")
        print("    (no sub-command)    - Toggles hazards ON/OFF.")
        print("    on|off              - Explicitly turns hazards ON or OFF.")
        print("    drought [on|off]    - Drought on its own.")
        print("    flood [on|off]      - Floods on its own (heavy rain on soaked soil floods low-lying fields).")
        print("    fire [on|off]       - Field fires on their own (ripe dry fields can burn during a hot drought).")
        print("    owned [on|off]      - Only damage fields a farm owns (default OFF = every growing field).")
        print("    intensity <percent> - Crop damage strength, 25 - 300. 100 = mild. Ex: t_set hazards intensity 200")
        print("    frequency <percent> - How fast the soil dries out, 25 - 300. Ex: t_set hazards frequency 150")
        print("    status              - Soil water, dry days, drought state and settings.")
        print(" ")
        print("  insurance [sub-command] - Per-farm crop + equipment insurance (OFF by default).")
        print("    (no sub-command)    - Toggles insurance ON/OFF.")
        print("    on|off              - Explicitly turns insurance ON or OFF.")
        print("    managers <farm|admin> - Who may buy / change policies: farm managers + admin, or the admin only.")
        print("    region <value|auto> - Whose insurance rules apply. Ex: t_set insurance region DE | US_KS | auto")
        print("    sales <auto|on|off> - Crop policies only in late winter / early spring (auto: only with seasonal growth).")
        print("    value <game|real>   - Sum insured: game values (yield x price) or the real-world sums per ha of the data.")
        print("    replacement <on|off> - Equipment claims paid at the dealer's replacement value (+15 %) instead of the sell price.")
        print("    totaled <remove|keep> - An accepted equipment total loss removes the wreck, or keeps it (like a buy-back).")
        print("    salvage <0-90>      - Sell price reduction in % for a Salvage title (default 50).")
        print("    rebuilt <0-90>      - Sell price reduction in % for a Rebuilt title (default 30).")
        print("    list                - Prints all insurance regions.")
        print("    status              - Region, data file, settings, records.")
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
        print("  verbose [all|physics|destruction|destruction_indoor_bypass] - Toggles verbose logging (default all).")
        print("  hud                   - Toggles the physics telemetry HUD over vehicles.")
        print("  pos                   - Toggles position tracking (your coordinates in the log / HUD).")
        print("  status                - Prints a status summary to the console.")
        print("  hotspotdump           - Prints internal state of Hotspot and MapUI modules.")
        print("  kill_test             - Triggers a test of the husbandry kill logic.")
        print("  twister               - Spawns a twister at your position now, in any season (the map's own")
        print("                          twister weather; outside its season the summer one). Host / single player.")
        print("  twister areas         - Prints the running twister's crop destruction areas and draws them on the ground (toggle).")
        print("  wildlife list         - Lists this map's wildlife species and how many are spawned around you.")
        print("  wildlife spawn <species> [distance] [count] [rotation]")
        print("                        - Spawns wildlife in front of you (to test fleeing). Ex: t_dev wildlife spawn crow 60 5")
        print("  hazards water <0-100> - Sets the soil water (host only). Ex: t_dev hazards water 15")
        print("  hazards drought       - Forces a drought now (first damage day included).")
        print("  hazards damage        - Applies the next drought day of crop damage right now.")
        print("  hazards end           - Ends the drought and refills the soil.")
        print("  hazards flood         - Forces a flood now on the low-lying growing fields.")
        print("  hazards fire [field]  - Starts a field fire now (random grain-type field, or the given field number).")
        print("  hazards fireout       - Puts the burning field fire out.")
        print("  hazards log           - Prints the last 20 hazard events (field, farm, share).")
        print("  moisture status       - FS25_MoistureSystem integration status (hook, patches recorded).")
        print("  moisture field <n>    - Field moisture, wither / fire thresholds of its crop.")
        print("  moisture wither <n> [count] - DESTROYS crop: Moisture System withers patches on field n now (tests the report).")
        print("  insurance status      - Insurance status (region, data, settings, countdowns).")
        print("  insurance bill        - Runs the monthly premium billing now.")
        print("  insurance testpremium <amount> - Test premium per month for every farm (0 = off, not saved).")
        print("  insurance charge|pay <amount> [farm] - Books a premium / payout (finance + inbox).")
        print("  insurance timer <days> [farm] - Test countdown of <days> real-life days (inbox letter when done).")
        print("  insurance timers      - Lists the running countdowns.")
        print("  insurance inbox [farm] - Prints a farm's insurance letters and totals.")
        print("  insurance rate <FILLTYPE> <PLAN> <coverage %> - Rate lookup (US / Canada / Brazil data). Ex: t_dev insurance rate MAIZE RP 75")
        print("  insurance regions     - Prints all insurance regions.")
        print("  insurance crops       - Every crop of this map and how the insurance rates it (map crops -> base crops).")
        print("  insurance damage [farm] - Storm damage log: field, cause, crop, share lost (also open events).")
        print("  insurance crop plans  - Crop insurance plans and coverage levels of this region, sales open or not.")
        print("  insurance crop quote <PLAN> <coverage %> - Price of a crop policy for your farm, field by field.")
        print("  insurance crop buy <PLAN> <coverage %> | cancel - Buys / changes / cancels your farm's crop policy.")
        print("  insurance crop claims - Your farm's crop policy and claims.")
        print("  insurance crop unlock - Opens switched-off countries (data permission pending) for testing, this session only.")
        print("  insurance hit <field|here> [radius] [perlin] - DESTROYS crop in a circle at the field centre / where you stand.")
        print("  insurance equip quote - Your farm's vehicles, their values and the price of each deductible.")
        print("  insurance equip buy <1000|2500|5000|10000> | cancel - Buys / changes / cancels the equipment policy.")
        print("  insurance equip claims - Equipment claims, titles and the values recorded in the running storm.")
        print("  insurance equip accept|buyback [claim] - Decides a total loss (the oldest waiting one without a number).")
        print("  insurance equip hit <damage 0-1> [fire] - Test: the vehicle you sit in is hit (value recorded, damage added).")
        print("  insurance equip end   - Test: ends the storm for the insurance - claims open for the damaged vehicles.")
        print("  insurance equip title <salvage|rebuilt|none> - Test: sets the title of the vehicle you sit in.")
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
        print("  hazards               - Resets natural hazards (OFF, drought + flood + fire ON, all fields, 100 %).")
        print("  insurance             - Resets insurance settings (OFF, farm managers + admin, region Auto, equipment defaults).")
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
            return "SFX: Vehicle fires = " .. (TornadoEffects.CONFIG.RANDOM_FIRE_MODE and "ON (chance by EF: 5 / 10 / 15 / 25 / 35 / 45 %)" or "OFF (no vehicle fires)")
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

    if module == "hazards" then
        if not TornadoHazards then return "Error: Hazards Module missing." end

        if subCmd == "on" or subCmd == "true" then
            TornadoHazards.isEnabled = true
        elseif subCmd == "off" or subCmd == "false" then
            TornadoHazards.isEnabled = false
        elseif subCmd == "drought" then
            if value == "on" or value == "true" then
                TornadoHazards.droughtEnabled = true
            elseif value == "off" or value == "false" then
                TornadoHazards.droughtEnabled = false
            else
                TornadoHazards.droughtEnabled = not TornadoHazards.droughtEnabled
            end
            return "Hazards: Drought = " .. tostring(TornadoHazards.droughtEnabled)
        elseif subCmd == "flood" or subCmd == "owned" or subCmd == "fire" then
            local field = ({ flood = "floodEnabled", owned = "ownedOnly", fire = "fireEnabled" })[subCmd]
            if value == "on" or value == "true" then
                TornadoHazards[field] = true
            elseif value == "off" or value == "false" then
                TornadoHazards[field] = false
            else
                TornadoHazards[field] = not TornadoHazards[field]
            end
            return string.format("Hazards: %s = %s", ({ flood = "Flood", owned = "Only owned fields", fire = "Field fire" })[subCmd],
                tostring(TornadoHazards[field]))
        elseif subCmd == "intensity" or subCmd == "frequency" then
            local percent = tonumber(value)
            if percent == nil then return "Usage: t_set hazards " .. subCmd .. " <25-300>" end
            TornadoHazards[subCmd] = math.max(0.25, math.min(3.0, percent / 100))
            return string.format("Hazards: %s set to %d %%", subCmd, math.floor(TornadoHazards[subCmd] * 100 + 0.5))
        elseif subCmd == "status" then
            return TornadoHazards:getStatusText()
        elseif subCmd == nil or subCmd == "toggle" then
            TornadoHazards.isEnabled = not TornadoHazards.isEnabled
        else
            return "Unknown Hazards CMD. Try: on, off, drought, flood, fire, owned, intensity, frequency, status"
        end
        return "Hazards: Natural hazards = " .. tostring(TornadoHazards.isEnabled)
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
            return string.format("Climate: Real-life = %s | Setting = %s | In use = %s | Map = %s | Last roll = %s | Last storm = %s | Seasons = %s, Direction = %s, Outbreaks = %s (max %d), Frequency = x%.2f | Outbreak = %s",
                tostring(TornadoClimate.isEnabled), TornadoClimate:getRegionLabel(TornadoClimate.regionSetting),
                active ~= nil and active.name or "none (classic)",
                TornadoRegion ~= nil and TornadoRegion:getStatusText() or "n/a",
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

    if module == "insurance" then
        if not TornadoInsurance then return "Error: Insurance Module missing." end

        if subCmd == "on" or subCmd == "true" then
            TornadoInsurance.isEnabled = true
        elseif subCmd == "off" or subCmd == "false" then
            TornadoInsurance.isEnabled = false
        elseif subCmd == "managers" then
            if value == "admin" then
                TornadoInsurance.adminOnly = true
            elseif value == "farm" or value == "manager" then
                TornadoInsurance.adminOnly = false
            else
                return "Usage: t_set insurance managers <farm | admin>"
            end
            return "Insurance: Policy managers = " .. (TornadoInsurance.adminOnly and "server admin only" or "farm manager + admin")
        elseif subCmd == "region" then
            if value == nil then return "Usage: t_set insurance region <country | region | auto>  (list: t_set insurance list)" end
            if not TornadoInsurance:setRegion(value) then
                return string.format("Insurance: Unknown region '%s'. Use 't_set insurance list'.", tostring(value))
            end
            return "Insurance: Region = " .. (TornadoInsurance.regionSetting == TornadoInsurance.REGION_AUTO and "Auto - " or "") ..
                TornadoInsurance:getRegionName()
        elseif subCmd == "sales" then
            if value ~= "auto" and value ~= "on" and value ~= "off" then
                return "Usage: t_set insurance sales <auto | on | off>  (auto = closing date only with seasonal growth)"
            end
            TornadoInsurance.salesClosing = value
            return "Insurance: Sales closing date = " .. value
        elseif subCmd == "value" then
            if value ~= "game" and value ~= "real" then
                return "Usage: t_set insurance value <game | real>  (sum insured: game yield x price, or the real-world sums per ha)"
            end
            TornadoInsurance.valueBasis = value
            return "Insurance: Sum insured = " .. (value == "real" and "real-world sums per ha (converted)" or "game values")
        elseif subCmd == "replacement" then
            if value ~= "on" and value ~= "off" then
                return "Usage: t_set insurance replacement <on | off>  (equipment paid at the dealer's replacement value, +15 %)"
            end
            TornadoInsurance.replacementValue = value == "on"
            return "Insurance: Equipment value = " .. (TornadoInsurance.replacementValue and "replacement value (+15 %)" or "sell price")
        elseif subCmd == "totaled" or subCmd == "totalled" then
            if value ~= "remove" and value ~= "keep" then
                return "Usage: t_set insurance totaled <remove | keep>  (an accepted total loss removes the wreck or keeps it)"
            end
            TornadoInsurance.removeTotaled = value == "remove"
            return "Insurance: Accepted total losses = " .. (TornadoInsurance.removeTotaled and "wreck removed" or "wreck kept (like a buy-back)")
        elseif subCmd == "salvage" or subCmd == "rebuilt" then
            local percent = tonumber(value)
            if percent == nil or percent < 0 or percent > 90 then
                return "Usage: t_set insurance " .. subCmd .. " <0 - 90>  (sell price reduction in % for a " .. subCmd .. " title)"
            end
            if subCmd == "salvage" then
                TornadoInsurance.salvagePenalty = percent / 100
            else
                TornadoInsurance.rebuiltPenalty = percent / 100
            end
            return string.format("Insurance: %s title = sell price -%d %%", subCmd == "salvage" and "Salvage" or "Rebuilt", math.floor(percent + 0.5))
        elseif subCmd == "list" then
            return TornadoInsurance:consoleCommand("regions")
        elseif subCmd == "status" then
            return TornadoInsurance:getStatusText()
        elseif subCmd == nil or subCmd == "toggle" then
            TornadoInsurance.isEnabled = not TornadoInsurance.isEnabled
        else
            return "Unknown Insurance CMD. Try: on, off, managers, region, sales, value, replacement, totaled, salvage, rebuilt, list, status"
        end
        return "Insurance: Insurance = " .. tostring(TornadoInsurance.isEnabled)
    end

   return "Unknown Set CMD. Try: save, cargo, husbandry, destruction, recovery, traffic, wildlife, hazards, insurance, climate"
end

-- =========================================================================
-- 4. DEV COMMANDS
-- =========================================================================
--- t_dev twister: a twister at the player's position now, in any season. Works like the game's
--- gsWeatherTwisterSpawn (which fails when the map has no twister weather in the current season), but falls back
--- to the twister weather of another season (summer first). A forecast instance keeps its own season, so a summer
--- twister runs fine in autumn. Testing only: host / single player.
function TornadoConsole:devSpawnTwister()
    local mission = g_currentMission
    if mission == nil or not mission:getIsServer() then
        return "Twister: host / single player only."
    end
    local environment = mission.environment
    local weather = environment ~= nil and environment.weather or nil
    if weather == nil or weather.typeToWeatherObject == nil or WeatherType == nil or WeatherInstance == nil then
        return "Twister: weather system not ready."
    end
    if g_localPlayer == nil or g_localPlayer.getPosition == nil then
        return "Twister: needs a player in the world."
    end
    local twisterType = WeatherType.TWISTER or (WeatherType.getByName ~= nil and WeatherType.getByName("TWISTER")) or nil
    if twisterType == nil then
        return "Twister: this game version has no twister weather type."
    end
    local seasons = { environment.currentSeason }
    if Season ~= nil then
        for _, season in ipairs({ Season.SUMMER, Season.SPRING, Season.AUTUMN, Season.WINTER }) do
            if season ~= environment.currentSeason then
                table.insert(seasons, season)
            end
        end
    end
    local season, twister = nil, nil
    for _, candidate in ipairs(seasons) do
        local objects = weather.typeToWeatherObject[candidate]
        if objects ~= nil and objects[twisterType] ~= nil then
            season, twister = candidate, objects[twisterType]
            break
        end
    end
    if twister == nil then
        return "Twister: this map has no twister weather in any season."
    end

    -- Same steps as Weather:consoleCommandWeatherTwisterSpawn, with the season found above.
    local current = weather.forecastItems[1]
    local currentObject = current ~= nil and weather:getWeatherObjectByIndex(current.season, current.objectIndex) or nil
    weather.forecastItems = {}
    local variationIndex = twister:getRandomVariationIndex()
    local variation = twister:getVariationByIndex(variationIndex)
    local duration = MathUtil.hoursToMs(math.random(variation.minHours, variation.maxHours))
    local day, dayTime = environment:getDayAndDayTime(environment.dayTime + duration, environment.currentMonotonicDay)
    local instance = WeatherInstance.createInstance(twister.index, variationIndex, day, dayTime, duration, season)
    local x, _, z = g_localPlayer:getPosition()
    instance.twisterStartPosX = x
    instance.twisterStartPosZ = z
    table.insert(weather.forecastItems, 1, instance)
    weather:fillWeatherForecast()
    if currentObject ~= nil then
        currentObject:deactivate(1)
        currentObject:update(9999999)
    end
    weather:init()
    if g_localPlayer.getYaw ~= nil and weather.windUpdater ~= nil then
        local dirX, dirZ = MathUtil.getDirectionFromYRotation(g_localPlayer:getYaw())
        weather.windUpdater.targetDirX = dirX
        weather.windUpdater.targetDirZ = dirZ
    end
    local seasonNames = { "spring", "summer", "autumn", "winter" }
    return string.format("Twister: spawned at your position (%s twister weather%s).", seasonNames[season] or tostring(season),
        season ~= environment.currentSeason and ", the current season has none on this map" or "")
end

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

    elseif tool == "hazards" then
        if not TornadoHazards then return "Error: Hazards Module missing." end
        return TornadoHazards:consoleCommand(arg1, arg2)

    elseif tool == "moisture" then
        if not TornadoMoisture then return "Error: Moisture integration missing." end
        return TornadoMoisture:consoleCommand(arg1, arg2, arg3)

    elseif tool == "insurance" then
        if not TornadoInsurance then return "Error: Insurance Module missing." end
        return TornadoInsurance:consoleCommand(arg1, arg2, arg3, arg4)

    elseif tool == "twister" then
        if arg1 == "areas" then
            if TornadoPhysics == nil then return "Error: Physics module missing." end
            return TornadoPhysics:debugDestructionAreas()
        end
        return self:devSpawnTwister()

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
        return "Unknown Dev CMD. Try: verbose, hud, pos, status, hotspotdump, kill_test, twister"
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
    
    if category == "all" or category == "physics" or category == "tuning" or category == "cargo" or category == "husbandry" or category == "traffic" or category == "wildlife" or category == "hazards" or category == "insurance" or category == "climate" then
        TornadoSettings:resetToDefaults(category)
        return string.format("RESET COMPLETE: '%s' settings restored to factory defaults.", category)
    else
        return "Usage: t_reset [all | physics | tuning | cargo | husbandry | traffic | wildlife | hazards | insurance | climate]"
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