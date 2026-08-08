==============================================================================
                    TORNADO PHYSICS - CONSOLE COMMANDS LIST
==============================================================================
To use these commands:
1. Enable the Developer Console in your game.xml.
2. Press the tilde key (~) to open the console in-game.
3. Type the command and press Enter.

------------------------------------------------------------------------------
[0] HELP COMMAND
Command: t_help
------------------------------------------------------------------------------
Lists all available commands and a brief description of each.

------------------------------------------------------------------------------
[1] PHYSICS COMMANDS (Main Settings)
Command: t_physics [setting] [value]
------------------------------------------------------------------------------
Adjusts the core behavior of the tornado.

t_physics radius [number]       - Sets the base radius of the tornado (e.g., 35.0).
t_physics power [number]        - Sets the ejection force power (e.g., 20.0).
t_physics heavy [number]        - Sets the mass threshold for "heavy" vehicles (e.g., 3.0 tons).
t_physics fence [number]        - Sets the safety distance from the map border (e.g., 40.0m).
t_physics dmg_in [number]       - Sets damage/sec inside the tornado core (0.0 - 100.0).
t_physics dmg_out [number]      - Sets damage/sec in the outer wind field (0.0 - 100.0).
t_physics lift_bales            - Toggles picking up Bales (true/false).
t_physics lift_logs             - Toggles picking up Logs (true/false).
t_physics border                - Toggles Border Safety protection (true/false).
t_physics indoor_damage         - Toggles if vehicles take damage inside sheds (true/false).
t_physics outdoor_damage        - Toggles if vehicles take damage outside (true/false).
t_physics randomize             - Forces the tornado to change size/EF-Rating immediately.

------------------------------------------------------------------------------
[2] SFX COMMANDS (Audio & Visuals)
Command: t_sfx [setting]
------------------------------------------------------------------------------
Controls the visual effects and sound system.

t_sfx sound                     - Mutes/Unmutes the tornado siren.
t_sfx ring                      - Toggles the red "Danger Zone" debug ring on the ground.
t_sfx fire_random               - Toggles random fire effects ON/OFF.

------------------------------------------------------------------------------
[3] MODULE SETTINGS (Gameplay Features)
Command: t_set [module] [sub_command] [value]
------------------------------------------------------------------------------
Controls specific gameplay modules like Cargo Spilling and Animal Deaths.

-- SAVE SYSTEM --
t_set save                      - Saves ALL current settings to modSettings/TornadoPhysics_Config.xml.

-- MAP UI --
t_set mapui                     - Toggles the map overlay ON/OFF.
t_set mapui on|off              - Explicitly turns the overlay ON or OFF.
t_set mapui sel                 - Toggles "only show when hotspot is selected" mode.
t_set mapui dump                - Prints the current state of the Map UI to the console.

-- CARGO SPILLING --
t_set cargo toggle              - Turns Cargo Spilling ON/OFF.
t_set cargo verbose             - Toggles detailed cargo spill logs for debugging.
t_set cargo spill_height [num]  - Height (meters) above ground before spilling starts (Default: 1.5).
t_set cargo spill_angle [num]   - Angle (0.0-1.0) required to spill. Lower is steeper (Default: 0.7).
t_set cargo drain_rate [num]    - How fast cargo empties (Default: 0.10).
t_set cargo spread [num]        - How far spill piles are spread out (Default: 4.0).
t_set cargo leak_chance [num]   - Probability of a covered trailer leaking (Default: 0.25).

-- HUSBANDRY (ANIMALS) --
t_set husbandry toggle          - Turns Animal Death Logic ON/OFF.
t_set husbandry immunity [num]  - Sets safe time (seconds) for a barn after it gets hit (Default: 120).

------------------------------------------------------------------------------
[4] DEVELOPER TOOLS (Debugging)
Command: t_dev [tool]
------------------------------------------------------------------------------
Tools for testing and verifying the mod is working.

t_dev verbose                   - Toggles global system logs (Debug prints).
t_dev hud                       - Toggles the Physics Telemetry HUD (shows Mass/Speed above vehicles).
t_dev status                    - Prints current active objects and timer status to console.
t_dev hotspotdump               - Prints the internal state of the TornadoHotspot and TornadoMapUI modules.
t_dev kill_test                 - Manually triggers a Husbandry Death event on the nearest barn.

------------------------------------------------------------------------------
[5] TUNING COMMANDS (Advanced Physics)
Command: t_tune [param] [value]
------------------------------------------------------------------------------
For advanced users who want to fine-tune the wind physics math.

t_tune suction [number]         - Speed at which objects are pulled inward (Default: 50.0).
t_tune lift [number]            - Vertical lift speed for heavy objects (Default: 12.0).
t_tune bale_orbit [number]      - Orbit speed for bales (Default: 20.0).
t_tune bale_suction [number]    - Suction speed for bales (Default: 15.0).
t_tune purge_time [number]      - Duration (ms) of the Ejection Phase (Default: 5000).
t_tune purge_int [number]       - Interval (ms) between Ejection Phases (Default: 20000).
t_tune chaos [number]           - Randomness factor for bale movement (Default: 5.0).
t_tune hover [number]           - Max height objects will float (Default: 35.0).
t_tune max_speed [number]       - Physics speed cap to prevent glitching (Default: 35.0).
t_tune destruct_ratio [number]  - % of radius considered "Core Destruction Zone" (Default: 0.2).

------------------------------------------------------------------------------
[6] RESET COMMANDS
Command: t_reset [category]
------------------------------------------------------------------------------
Resets settings for a specific category to their default values.

t_reset all                     - Resets ALL settings to factory defaults.
t_reset physics                 - Resets only the main physics settings.
t_reset tuning                  - Resets only the advanced tuning values.
t_reset cargo                   - Resets only the cargo module settings.
t_reset husbandry               - Resets only the husbandry module settings.

==============================================================================