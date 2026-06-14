


========================================================================
                     TORNADO PHYSICS (Release 4.0.0.0)
                   Advanced Weather Destruction Engine
                            by whitevamp
========================================================================

Version: 4.0.0.0
GAME:    Farming Simulator 25
DATE:    June 2026

------------------------------------------------------------------------
[1] OVERVIEW
------------------------------------------------------------------------
This mod is a full physics overhaul for the in-game tornado. It turns
the standard visual effect into a dynamic vortex that calculates lift,
drag, and mass resistance.

NEW IN v4.0.0.0 (REFACTOR UPDATE):
- Complete Code Rewrite: Modular architecture for better stability.
- Cargo Spilling: Trailers dump contents based on cover state.
- ADS Support: Integration with "Advanced Damage System".
- Siren Audio: 3-minute warning siren loops on spawn.
- Smoke Effects: Vehicles emit smoke when damaged by the storm.
- Shader Mesh Support: Volumetric visuals for the funnel.

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
   Vehicles are lifted, orbited, and ejected. Heavier tractors resist 
   suction longer than light balers or pallets.

>> CARGO SPILLING (NEW)
   If enabled, Trailers caught in the storm will lose their crop.
   - Uncovered: 100% loss (Dumped to ground).
   - Covered: Chance to leak or "pop" the cover open.

>> ADVANCED DAMAGE SYSTEM (ADS) SUPPORT
   If you use the ADS mod, the tornado applies damage in stages:
   - 15s: Minor Damage
   - 30s: Moderate Damage
   - 50s: Total Destruction

>> HUSBANDRY & LIVESTOCK
   If enabled, tornadoes passing over pastures will kill animals.
   - Includes "Dynamic Immunity": After a strike, the pasture is safe for
   - set time (scales automatically with map size).
   - Pasture-Only Targeting: The Reaper logic now strictly targets outdoor pastures, fences, and meadows by reading Giants' `spec_husbandryFence` data.
   - Indoor Immunity: Animals housed inside enclosed barns are now 100% safe from storm loss.
   - Dynamic Map Scaling: Livestock immunity timers now automatically adjust based on the physical size of the map (e.g., 2km vs 8km maps).

>> The Destruction Engine
   If enabled, tornadoes passing over vehicles will dynamically destroy them.
   - Targeted Vehicle Destruction: Tornadoes physically rip specific parts off of vehicles caught within the storm's damage zone.
   - Smart Categorization: Automatically sorts vehicle components into "Trash" (e.g., hoses, decals, wires) and "Structural" (e.g., mirrors, glass, pipes) utilizing a custom database and an intelligent ignore list.
   - Persistent Damage States: Vehicle damage is flawlessly synchronized with the base game's save cycle, ensuring damaged machines remain broken even after exiting and reloading a save.
   - Automated 24-Hour Repairs: Damaged vehicles receive an in-game 24-hour repair cooldown. Once this internal timer expires, all missing parts are automatically restored.
   - Safe Save Injection: Safely bypasses the native Giants event listener to hardwire destruction data directly into the core `FSBaseMission.saveSavegame` queue, completely preventing Lua panics and corrupted weather states.
   - Compatibility Note: Not all vehicles are fully supported. Modded or custom vehicles utilizing unique 3D nodes that are not mapped in the mod's global database may be ignored by the destruction system.

>> GEO-FENCING
   Prevents vehicles from being thrown off the map edge.

------------------------------------------------------------------------
[4] CONFIGURATION & COMMANDS (NEW SYSTEM)
------------------------------------------------------------------------
You can tune the mod live using the console (~).
Settings are saved to: "modSettings/TornadoPhysics_Config.xml"

NOTE: The old commands (t_toggle, t_status) have been replaced!

1. Help (t_help)
   - t_help [command] for more details.
   - t_physics                  : Adjust Physics: radius, power, heavy, fence, randomize...
   - t_sfx: Adjust SFX          : sound, ring, particles...
   - t_set: Module Settings     : cargo, husbandry, destruction, save...
   - t_dev: Developer Tools     : status, verbose, hud, hotspotdump, kill_test...
   - t_tune                     : Fine-tune Physics Constants
   - t_reset                    : Reset Settings: all, physics, tuning, cargo...

2. PHYSICS CONTROL (t_physics)
   - t_physics radius [x]     : Manually override storm size (Default: 35)
   - t_physics power [x]      : Change ejection strength (Default: 20)
   - t_physics heavy [x]      : Set mass threshold for heavy vehicles
   - t_physics fence [x]      : Set safe distance from map edge
   - t_physics lift_bales     : Toggle handling of bales/pallets

2. MODULE SETTINGS (t_set)
   - t_set save               : Save current configuration to XML
   - t_set cargo              : Toggle Cargo Spilling System
   - t_set husbandry          : Toggle Animal Lethality
   - t_set husbandry immunity [x] : Set barn safety timer (seconds)

3. VISUALS & AUDIO (t_sfx)
   - t_sfx sound              : Toggle Siren Audio ON/OFF
   - t_sfx ring               : Toggle Debug Ring (Visual Safety Zone)

4. HARDCORE TUNING (t_tune)
   Fine-tune the simulation constants live.
   - t_tune suction [x]     : Speed of suction towards center
   - t_tune lift [x]        : Speed of vertical lift
   - t_tune chaos [x]       : Randomness of movement
   - t_tune bale_orbit [x]  : Orbital speed for bales
   - t_tune hover [x]       : Max height before 
   
5. Debug logging (t_dev)
   - t_dev verbose destruction       : Tracks XML saves, relinking, and 24-hour repair timers.
   - t_dev verbose physics           : Tracks suction, mass calculation, and ejection forces.
   - t_dev verbose all               : Enables master logging.
   - t_dev pos                       : Toggles real-time coordinate tracking for the tornado node.

------------------------------------------------------------------------
[5] MAP SCALING GUIDE
------------------------------------------------------------------------
The mod attempts to auto-detect map size, but you can manually tune the
Base Radius (using "t_physics radius") to make the storm fit better.

Recommended Values:
- Standard Map (2km):  Radius 35  (Max EF-5 size: 175m)
- 4x Map       (4km):  Radius 70  (Max EF-5 size: 350m)
- 16x Map      (8km):  Radius 140 (Max EF-5 size: 700m)
- 64x Map      (16km): Radius 280 (Max EF-5 size: 1400m)

------------------------------------------------------------------------
[6] CREDITS
------------------------------------------------------------------------
Scripting & Physics Engine: whitevamp
ADS Integration Support: id577
Testing & Feedback: Community

You are free to use this mod in videos/streams.
Please do not re-upload to other sites without permission.



========================================================================
                     TORNADO PHYSICS V3
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
