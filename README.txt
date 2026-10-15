========================================================================
                     TORNADO PHYSICS (Release 5.0.0.0)
                   Advanced Weather Destruction Engine
                        "The Real-Life Update"
                            by whitevamp
========================================================================

Version: 5.0.0.0
GAME:    Farming Simulator 25
DATE:    October 2026

------------------------------------------------------------------------
[1] OVERVIEW
------------------------------------------------------------------------
This mod is a full physics overhaul for the in-game tornado. It turns
the standard visual effect into a dynamic vortex that calculates lift,
drag, and mass resistance.

NEW IN v5.0.0.0 (THE REAL-LIFE UPDATE):
- Tornado Control Panel: every setting in an in-game menu
  (Right Ctrl + Right Shift + T), no console needed.
- Real-Life Tornado Climate (optional): EF rating, size, hail, wind,
  season, time of day, track direction and outbreak days follow real
  recorded statistics for the United States and Canada.
- AI Traffic Roadblocks: road traffic and pedestrians stop before entering
  a tornado.
- Wildlife flees the tornado (caught animals vanish); the farm dog runs
  home to its doghouse.
- Full Multiplayer Support: every player sees the same tornado, weather,
  damage and warnings.
- Tornado Saved With The Savegame: an active tornado (and outbreak) comes
  back exactly the same after loading.
- Translations: English, German, French, Polish, Spanish, Italian, Dutch.
- Map overlay shows storm type, hail, gusts and travel direction.
- Many bug fixes (see changlog.txt for the full list).

------------------------------------------------------------------------
[2] INSTALLATION
------------------------------------------------------------------------
1. Place the "FS25_TornadoPhysics.zip" into your "mods" folder.
   (Usually: Documents/My Games/FarmingSimulator2025/mods)
2. Activate the mod in the game menu.
3. No new save game required. Your v4 settings file is kept.

------------------------------------------------------------------------
[3] KEY FEATURES
------------------------------------------------------------------------
>> TRUE PHYSICS ENGINE
   Vehicles are lifted, orbited, and ejected. Heavier tractors resist
   suction longer than light balers or pallets.

>> TORNADO CONTROL PANEL (NEW IN v5)
   Open with Right Ctrl + Right Shift + T (rebind under Options >
   Controls as "Tornado Control Panel"). Six tabs:
   - Settings  : save to XML, auto-save on close, factory resets
   - Physics   : radius, power, heavy threshold, damage, lifting, border,
                 randomize, and all real-life climate options
   - Tuning    : suction, lift, chaos, hover, max speed, core ratio,
                 bale orbit/suction, ejection duration and interval
   - Effects   : siren, danger ring, random fire
   - Modules   : destruction, recovery bill, map overlay, cargo spilling,
                 livestock, road traffic
   - Developer : telemetry HUD, position tracking, verbose logging,
                 status / hotspot / map overlay dumps, husbandry kill test
   Every option has a tooltip. Changes apply instantly through the same
   code as the console commands. Resets and the kill test ask first.

>> REAL-LIFE TORNADO CLIMATE (NEW IN v5, OFF BY DEFAULT)
   Turn it on in the Physics tab (or "t_set climate on"). Off = classic
   random tornadoes, exactly as in v4.
   - Regions: United States (US-wide + all 50 states) and Canada
     (Canada-wide + AB, MB, ON, QC, SK). "Auto" picks the region from the
     map (US base map = United States; a mod map with a state, province
     or country in its name uses that region). Or pick one yourself.
   - EF rating from the region's real EF mix (US: about 56% EF0, 32% EF1
     ... 0.04% EF5). Size is placed inside the EF range from real track
     widths; your radius setting and map scaling still apply.
   - Storm weather: real hail odds and stone sizes, real severe-wind gusts.
   - Seasons and time of day: tornadoes come in the region's real tornado
     months, mostly in the late afternoon. Southern-hemisphere maps are
     shifted by six months. "Tornado frequency" multiplier 0.25x - 4x.
   - Track direction: natural tornadoes travel the way they do in the
     region (mostly toward the north-east in the US).
   - Outbreak days: a touchdown can start a busy storm day with more
     tornadoes 30-120 in-game minutes apart (default max 3, until 22:00).
   - Seasons, direction and outbreaks can each be switched on or off.

>> AI TRAFFIC ROADBLOCKS (NEW IN v5)
   AI road traffic and pedestrians stop and wait (like at a red light)
   before entering the tornado's zone. Cars and people already inside
   leave it. Adjustable stop distance (default 40 m). With the danger ring
   on, roadblocks show as red posts (yellow for pedestrians).

>> WILDLIFE (NEW IN v5, ON BY DEFAULT)
   Birds, deer, boar and other wild animals run or fly away when a
   tornado comes within the flee distance (default 150 m beyond its
   radius). Animals the tornado catches vanish. The farm dog runs home to
   its doghouse and is never lost or harmed. Modules tab or
   "t_set wildlife".

>> MULTIPLAYER (NEW IN v5)
   - The server runs the tornado; every client sees the same touchdown
     warning, siren, EF rating, radius, hotspot, overlay, compass marker,
     funnel, destroyed parts, smoke, fire and storm weather.
   - Players joining a running game get the current tornado and damage.
   - Gameplay settings belong to the server: only the host or a server
     admin can change them. Siren, danger ring, map overlay, debug tools
     and auto-save stay personal per player.
   - Messages (animal losses, tow bills, outbreak alerts) show in each
     player's own language and currency.

>> SAVEGAME PERSISTENCE (NEW IN v5)
   A tornado on the ground when you save comes back after loading with
   the same EF rating, size, weather and direction (no re-roll, no second
   alert). A running outbreak carries on.

>> ESC MAP OVERLAY
   EF rating, wind speed, radius and distance, plus (v5) a second line
   with storm type (LP / Classic / HP supercell), hail size, gusts and
   the direction the tornado is moving.

>> CARGO SPILLING
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
   - Dynamic Immunity: after a strike, the pasture is safe for a set time
     (the setting is for a 2 km map; 4 km maps get 2x, 8 km maps 4x).
   - Real pasture area (v5): the tornado must touch the pasture's fence
     outline, not just the barn.
   - Pasture-Only Targeting: only outdoor pastures, fences and meadows
     are hit. Animals inside enclosed barns are 100% safe.

>> THE DESTRUCTION ENGINE
   If enabled, tornadoes rip parts off vehicles in the damage zone.
   - Smart Categorization: "Trash" parts (hoses, decals, wires) and
     "Structural" parts (mirrors, glass, pipes).
   - Persistent: damaged vehicles stay damaged after save/reload.
   - Automated 24-Hour Repairs: missing parts come back after 24 in-game
     hours (v5: fast-forwarded time now counts fully).
   - Hardcore Recovery Bill: resetting a tornado-damaged vehicle to the
     shop charges an itemized tow and repair bill (v5: also restores the
     missing parts).
   - Compatibility Note: modded vehicles with unusual 3D nodes that are
     not in the mod's database may be ignored.

>> FIRE & SMOKE
   Damaged vehicles smoke; engines can catch fire (random 50/50 mode or
   every damaged engine).

>> GEO-FENCING
   Prevents vehicles from being thrown off the map edge.

------------------------------------------------------------------------
[4] CONFIGURATION & COMMANDS
------------------------------------------------------------------------
Everything below is also in the Tornado Control Panel.
Settings are saved to: "modSettings/TornadoPhysics_Config.xml"
In multiplayer, gameplay commands only work for the host / server admin.

1. Help (t_help)
   - t_help [command]           : details for one command
   - t_physics                  : radius, power, heavy, fence, randomize...
   - t_sfx                      : sound, ring, fire_random
   - t_set                      : modules, climate, traffic, save...
   - t_dev                      : status, verbose, hud, hotspotdump, kill_test
   - t_tune                     : fine-tune physics constants
   - t_reset                    : all, physics, tuning, cargo, husbandry,
                                  traffic, wildlife, climate

2. PHYSICS CONTROL (t_physics)
   - t_physics radius [x]       : Base storm size (Default: 35)
   - t_physics power [x]        : Ejection strength (Default: 20)
   - t_physics heavy [x]        : Mass threshold for heavy vehicles (tons)
   - t_physics fence [x]        : Safe distance from map edge (m)
   - t_physics dmg_in [x]       : Damage/sec inside the core
   - t_physics dmg_out [x]      : Damage/sec in the outer winds
   - t_physics lift_bales       : Toggle lifting bales/pallets
   - t_physics lift_logs        : Toggle lifting logs
   - t_physics border           : Toggle map border safety
   - t_physics indoor_damage    : Toggle damage inside sheds
   - t_physics outdoor_damage   : Toggle damage outside
   - t_physics randomize        : Force a new size / EF rating now

3. MODULE SETTINGS (t_set)
   - t_set save                 : Save current configuration to XML
   - t_set destruction [on|off] : Vehicle destruction
   - t_set recovery             : Hardcore tow bill
   - t_set mapui [on|off|sel|dump] : ESC map overlay
   - t_set cargo [toggle|verbose|spill_height|spill_angle|drain_rate|
                  spread|leak_chance] [x]
   - t_set husbandry [toggle|immunity <sec>]
   - t_set traffic [on|off|buffer <m>|status]            (NEW)
   - t_set wildlife [on|off|distance <m>|status]         (NEW)
   - t_set climate [on|off|region <name|code|auto>|list|status|
                    seasons|direction|outbreaks [on|off]|
                    frequency <x>|outbreakmax <n>]        (NEW)
     Examples: t_set climate region oklahoma | OK | US | auto
               t_set climate frequency 2

4. VISUALS & AUDIO (t_sfx)
   - t_sfx sound                : Toggle siren
   - t_sfx ring                 : Toggle danger-zone ring
   - t_sfx fire_random          : Toggle random fire

5. HARDCORE TUNING (t_tune)
   - t_tune suction [x]         : Speed of suction towards center
   - t_tune lift [x]            : Speed of vertical lift
   - t_tune chaos [x]           : Randomness of movement
   - t_tune hover [x]           : Max height for floating objects
   - t_tune max_speed [x]       : Physics speed cap
   - t_tune destruct_ratio [x]  : Share of radius that is the core (0-1)
   - t_tune bale_orbit [x]      : Orbital speed for bales
   - t_tune bale_suction [x]    : Suction speed for bales
   - t_tune purge_time [ms]     : Ejection phase duration
   - t_tune purge_int [ms]      : Time between ejections

6. DEBUG (t_dev)
   - t_dev status               : Status summary
   - t_dev hud                  : Physics telemetry over objects
   - t_dev pos                  : Real-time tornado coordinates
   - t_dev verbose [all|physics|destruction|destruction_indoor_bypass]
                                : log channels
   - t_dev hotspotdump          : Hotspot / map overlay state
   - t_dev kill_test            : Husbandry kill test (kills animals!)
   - t_dev wildlife list        : Wildlife species on this map
   - t_dev wildlife spawn <species> [distance] [count]
                                : Spawn wildlife in front of you (testing)

------------------------------------------------------------------------
[5] MAP SCALING GUIDE
------------------------------------------------------------------------
The mod attempts to auto-detect map size, but you can manually tune the
Base Radius (using "t_physics radius" or the Physics tab) to make the
storm fit better.

Recommended Values:
- Standard Map (2km):  Radius 35  (Max EF-5 size: 175m)
- 4x Map       (4km):  Radius 70  (Max EF-5 size: 350m)
- 16x Map      (8km):  Radius 140 (Max EF-5 size: 700m)
- 64x Map      (16km): Radius 280 (Max EF-5 size: 1400m)

------------------------------------------------------------------------
[6] DEVELOPER NOTES (GitHub dev branch)
------------------------------------------------------------------------
Folder layout:
- TornadoMain.lua            : loader; network events and TornadoText
                               are sourced at the top (events must be
                               registered before a mission exists)
- scripts/                   : one module per feature (Physics, Climate,
                               Weather, Outbreak, Traffic, Sync,
                               Persistence, Destruction, Recovery, ...)
- scripts/events/            : multiplayer network events
- scripts/gui/               : control panel controller + page base
- scripts/gui/pages/         : one Lua file per panel tab
- gui/TornadoMenu.xml        : panel layout (ASCII only, $l10n_ keys)
- gui/guiProfiles.xml        : panel profiles
- translations/              : GENERATED translation_xx.xml files
- DB/                        : climate data + destruction ignore list
- tools/                     : Python builders (not part of the mod zip)

Rules:
- No pcall / xpcall anywhere (GIANTS ModHub rejects it). Use explicit
  nil checks.
- Player-visible text goes through scripts/TornadoText.lua. Server ->
  client messages are sent as a text key + parameters
  (TornadoSync:sendMessage(key, params, kind, farmId)), never as finished
  text. Console and log output stay English.

Translations:
1. Edit tools/translations_source.py (every key needs all 7 languages).
2. Run:  python tools/build_translations.py
   It checks that every language uses the same %d / %s placeholders as
   English and rewrites translations/translation_xx.xml.
   Never edit the generated XML files by hand.

Climate data:
- python tools/build_tornado_climate.py  -> DB/TornadoClimate.xml
  (NOAA SPC tornado / hail / wind CSVs; re-run for a new NOAA year)
- python tools/build_au_ca_climate.py    -> DB/TornadoClimate_CA.xml
  (+ DB/TornadoClimate_AU.xml). Canada borrows hail from neighbouring
  US states: AB->MT, SK->ND, MB->MN, ON->MI, QC->NY.
- Raw CSV data stays outside the mod zip.
- The mod skips any climate file that is missing, so countries can be
  added or removed as separate files.

Release zip - leave these OUT:
- dataS/, tools/, images/, weather_csv_files_for_tornadophysics/
- screenshots (*.jpg) and old .rar / .zip builds
- DB/TornadoClimate_AU.xml (Bureau of Meteorology licence not yet
  confirmed - Australia does not ship until it is)

------------------------------------------------------------------------
[7] VERSION HISTORY
------------------------------------------------------------------------
v5.0.0.0 - The Real-Life Update (see changlog.txt for every change)
v4.0.0.0 - Refactor Update: complete code rewrite (modular), cargo
           spilling, ADS support, 3-minute siren, damage smoke, shader
           mesh funnel, vehicle destruction engine, new t_ commands.
v3.0     - Livestock, map scaling, console/XML configuration,
           geo-fencing (full v3 readme below).

------------------------------------------------------------------------
[8] CREDITS
------------------------------------------------------------------------
Scripting & Physics Engine: whitevamp
ADS Integration Support: id577
Testing & Feedback: Community

DATA SOURCES (Real-Life Tornado Climate mode):
- United States: tornado, hail and wind statistics derived from the
  NOAA / National Weather Service Storm Prediction Center Severe Weather
  Database (public domain).
- Canada: tornado statistics derived from Northern Tornadoes Project
  event data, Western University, licensed under CC BY-NC 4.0
  (https://creativecommons.org/licenses/by-nc/4.0/). The data was
  aggregated and modified for this mod. Canadian hail values are borrowed
  from neighbouring US states (NOAA SPC).
- This mod is free and non-commercial. The included climate data may not
  be used commercially.

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
