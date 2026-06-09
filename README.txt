========================================================================
                     TORNADO PHYSICS (Release 3.0.0.1)
                   Advanced Weather Destruction Engine
                            by whitevamp
========================================================================

VERSION: 3.0.0.1 (The Refactor Update)
GAME:    Farming Simulator 25
DATE:    January 2026

------------------------------------------------------------------------
[1] OVERVIEW
------------------------------------------------------------------------
This mod is a full physics overhaul for the in-game tornado. It turns
the standard visual effect into a dynamic vortex that calculates lift,
drag, and mass resistance.

NEW IN v3.0.0.1 (REFACTOR UPDATE):
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
   Includes "Dynamic Immunity": After a strike, the pasture is safe for
   a set time (scales automatically with map size).

>> GEO-FENCING
   Prevents vehicles from being thrown off the map edge.

------------------------------------------------------------------------
[4] CONFIGURATION & COMMANDS (NEW SYSTEM)
------------------------------------------------------------------------
You can tune the mod live using the console (~).
Settings are saved to: "modSettings/TornadoPhysics_Config.xml"

NOTE: The old commands (t_toggle, t_status) have been replaced!

1. PHYSICS CONTROL (t_physics)
   t_physics radius [x]     : Manually override storm size (Default: 35)
   t_physics power [x]      : Change ejection strength (Default: 20)
   t_physics heavy [x]      : Set mass threshold for heavy vehicles
   t_physics fence [x]      : Set safe distance from map edge
   t_physics lift_bales     : Toggle handling of bales/pallets

2. MODULE SETTINGS (t_set)
   t_set save               : Save current configuration to XML
   t_set cargo              : Toggle Cargo Spilling System
   t_set husbandry          : Toggle Animal Lethality
   t_set husbandry immunity [x] : Set barn safety timer (seconds)

3. VISUALS & AUDIO (t_sfx)
   t_sfx sound              : Toggle Siren Audio ON/OFF
   t_sfx ring               : Toggle Debug Ring (Visual Safety Zone)

4. HARDCORE TUNING (t_tune)
   Fine-tune the simulation constants live.
   - t_tune suction [x]     : Speed of suction towards center
   - t_tune lift [x]        : Speed of vertical lift
   - t_tune chaos [x]       : Randomness of movement
   - t_tune bale_orbit [x]  : Orbital speed for bales
   - t_tune hover [x]       : Max height before dropping

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