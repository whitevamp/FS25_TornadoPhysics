========================================================================
                     TORNADO PHYSICS V3 (Release 107)
                   Advanced Weather Destruction Engine
                            by whitevamp
========================================================================

VERSION: 3.0 (Internal Build 107)
GAME:    Farming Simulator 25
DATE:    December 2025

------------------------------------------------------------------------
[1] OVERVIEW
------------------------------------------------------------------------
This is not just a script—it is a full physics overhaul for the in-game
tornado. Tornado Physics V3 takes the standard visual effect and gives
it real teeth.

Standard game tornadoes pass through objects like ghosts. With this mod,
the storm becomes a dynamic vortex that calculates lift, drag, and mass
resistance. Vehicles are lifted, spun Counter-Clockwise (matching the
visuals), and thrown based on their weight.

NEW IN V3:
- Livestock Destruction (Husbandry)
- Intelligent Map Scaling (Support for 4x, 16x, 64x maps)
- Full In-Game Configuration (Console Commands & XML)
- Geo-Fencing (Prevents vehicles from flying off the map)

------------------------------------------------------------------------
[2] INSTALLATION
------------------------------------------------------------------------
1. Place the "FS25_TornadoPhysics.zip" into your "mods" folder.
   (Usually: Documents/My Games/FarmingSimulator2025/mods)
2. Activate the mod in the game menu.
3. No new save game required.

------------------------------------------------------------------------
[3] KEY FEATURES
------------------------------------------------------------------------
>> TRUE PHYSICS ENGINE
   Vehicles are no longer just "deleted." They are physically lifted,
   orbited, and ejected. Heavier tractors resist suction longer than
   light balers or pallets.

>> HUSBANDRY & LIVESTOCK (Disabled by Default)
   If enabled, tornadoes passing over pastures will kill animals.
   Includes "Dynamic Immunity": After a strike, the pasture is safe for
   a set time. On large maps (4x, 16x), this timer automatically
   increases (up to 30+ mins) to account for the storm's travel time.

>> GEO-FENCING
   The mod detects the map size automatically. If a vehicle is about to
   be thrown into the "void" (map edge), the physics engine cuts power
   and drops it safely within the map boundary.

>> COMPATIBILITY
   - AutoRepair: Automatically pauses "AutoRepair" mods during storms
     so mechanics don't try to repair flying vehicles.
   - Multiplayer: Fully synced. All clients see the same destruction.

------------------------------------------------------------------------
[4] CONFIGURATION & COMMANDS
------------------------------------------------------------------------
You can tune the mod live using the console (~).
Settings are saved to: "modSettings/TornadoPhysics_Config.xml"

=== STANDARD COMMANDS ===
t_save             Save current settings to XML.
t_status           Check active storms and map scale.
t_husbandry        Toggle Animal Death ON/OFF.
t_immunity [sec]   Set how long pastures are safe after a strike.
t_toggle [option]  Toggle features (lift_bales, lift_logs, indoor_damage).

=== ADVANCED TUNING ===
t_set radius [x]   Set Base Radius (See Map Scaling below).
t_set power [x]    Set Ejection Power (Default: 20).
t_set heavy [x]    Set Heavy Mass Threshold (Default: 3.0 tons).
t_set dmg_in [x]   Damage per second inside the funnel (Default: 0.25).
t_debug            Toggle text labels above flying objects.
t_ring             Toggle the red debug ring showing the suction zone.

------------------------------------------------------------------------
[5] MAP SCALING GUIDE
------------------------------------------------------------------------
The mod attempts to auto-detect map size, but you can manually tune the
Base Radius to make the storm fit your map better.

Recommended "t_set radius" values:
- Standard Map (2km):  Radius 35  (Max EF-5 size: 175m)
- 4x Map       (4km):  Radius 70  (Max EF-5 size: 350m)
- 16x Map      (8km):  Radius 140 (Max EF-5 size: 700m)
- 64x Map      (16km): Radius 280 (Max EF-5 size: 1400m)

------------------------------------------------------------------------
[6] BUG FIXES IN V3
------------------------------------------------------------------------
- Fixed: Physics rotation now matches visual cloud spin (Counter-Clockwise).
- Fixed: Vehicles taking damage/dirt while inside the Store menu.
- Fixed: Borrowed Mission Vehicles taking storm damage.
- Fixed: "Infinite Repair Loop" when used with AutoRepair mods.

------------------------------------------------------------------------
[7] CREDITS
------------------------------------------------------------------------
Scripting & Physics Engine: whitevamp
Testing & Feedback: Community

You are free to use this mod in videos/streams.
Please do not re-upload to other sites without permission.
