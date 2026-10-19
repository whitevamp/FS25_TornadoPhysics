==============================================================================
                    TORNADO PHYSICS - CONSOLE COMMANDS LIST
                         (v5.0.0.0, updated 2026-10-18)
==============================================================================
To use these commands:
1. Enable the Developer Console in your game.xml.
2. Press the tilde key (~) to open the console in-game.
3. Type the command and press Enter.

Most settings are also in the Tornado Control Panel (Right Ctrl + Right Shift
+ T). The console additionally has the test and debug tools (section [4]).
Settings changed here are saved with "t_set save" (or when the panel closes
with auto-save on). In multiplayer, settings and test tools are for the host /
server admin.

Notation: <value> = required, [value] = optional, a|b = one of these.

------------------------------------------------------------------------------
[0] HELP
Command: t_help [command]
------------------------------------------------------------------------------
t_help                          - Lists the command groups.
t_help t_set                    - Every sub-command of one group (t_physics, t_sfx,
                                  t_set, t_dev, t_tune, t_reset).

------------------------------------------------------------------------------
[1] PHYSICS (main settings)
Command: t_physics <setting> [value]
------------------------------------------------------------------------------
t_physics radius <m>            - Base radius of the tornado (default 35).
t_physics power <number>        - Ejection force (default 20).
t_physics heavy <tons>          - Mass above which vehicles count as heavy (default 3).
t_physics fence <m>             - Safety distance from the map border (default 40).
t_physics dmg_in <number>       - Vehicle damage per second in the core (default 0.25).
t_physics dmg_out <number>      - Vehicle damage per second in the outer winds (default 0.08).
t_physics lift_bales            - Toggles lifting bales (default ON).
t_physics lift_logs             - Toggles lifting logs (default ON).
t_physics border                - Toggles map border protection (default ON).
t_physics indoor_damage         - Toggles damage to vehicles inside sheds (default OFF).
t_physics outdoor_damage        - Toggles damage to vehicles outside (default ON).
t_physics randomize             - New tornado size / EF rating right now.

------------------------------------------------------------------------------
[2] EFFECTS
Command: t_sfx <setting>
------------------------------------------------------------------------------
t_sfx sound                     - Mutes / unmutes the tornado siren.
t_sfx ring                      - Toggles the red danger-zone ring on the ground.
t_sfx fire_random               - Vehicle fires ON / OFF (default ON). ON: an engine past
                                  the ignite damage can burn - 5 % at EF0, 10 % EF1, 15 % EF2,
                                  25 % EF3, 35 % EF4, 45 % EF5, decided once per vehicle until
                                  it is repaired. OFF: no vehicle fires.

------------------------------------------------------------------------------
[3] MODULES
Command: t_set <module> [sub-command] [value]
------------------------------------------------------------------------------
-- SAVE --
t_set save                      - Saves all settings to modSettings/TornadoPhysics_Config.xml.

-- DESTRUCTION + EMERGENCY TOW --
t_set destruction [on|off]      - Visual destruction (parts, wheels, glass) (default OFF).
t_set recovery                  - Toggles the emergency tow bill on vehicle reset (default OFF).
t_set money <25-200 | status>   - Scale in % for everything the mod charges (tow bill,
                                  insurance) - also scaled by the economic difficulty (default 100).

-- MAP OVERLAY --
t_set mapui                     - Toggles the map overlay (default ON).
t_set mapui on|off              - Turns it ON or OFF.
t_set mapui sel                 - Toggles "only when the hotspot is selected" (default ON).
t_set mapui dump                - Prints the overlay state.

-- CARGO SPILLING --
t_set cargo toggle              - Cargo spilling ON / OFF (default OFF).
t_set cargo verbose             - Detailed spill log.
t_set cargo spill_height <m>    - Height above ground before spilling starts (default 1.5).
t_set cargo spill_angle <0-1>   - Tilt needed to spill, lower = steeper (default 0.7).
t_set cargo drain_rate <num>    - How fast cargo empties (default 0.10).
t_set cargo spread <m>          - How far spill piles spread (default 4.0).
t_set cargo leak_chance <0-1>   - Chance a covered trailer leaks (default 0.25).

-- LIVESTOCK --
t_set husbandry toggle          - Animals in outdoor pastures can be killed (default OFF).
t_set husbandry immunity <s>    - Safe time for a pasture after a hit (default 120).

-- ROAD TRAFFIC --
t_set traffic [on|off]          - AI cars and pedestrians stop before the tornado (default ON).
t_set traffic buffer <m>        - Distance beyond the radius where cars stop (default 40).
t_set traffic status            - Active roadblocks.

-- WILDLIFE --
t_set wildlife [on|off]         - Wildlife flees, the farm dog runs home (default ON).
t_set wildlife distance <m>     - Flee distance beyond the radius (default 150).
t_set wildlife status           - Settings and animals caught.

-- NATURAL HAZARDS (OFF by default) --
t_set hazards [on|off]          - Drought, floods and field fires damage crops.
t_set hazards drought [on|off]  - Drought on its own (default ON).
t_set hazards flood [on|off]    - Floods on low-lying fields after heavy rain (default ON).
t_set hazards fire [on|off]     - Field fires on ripe dry fields in a hot drought (default ON).
t_set hazards owned [on|off]    - Only fields a farm owns (default OFF = every field).
t_set hazards intensity <25-300> - Crop damage strength in % (default 100).
t_set hazards frequency <25-300> - How fast the soil dries out in % (default 100).
t_set hazards status            - Soil water, dry days, drought state, settings.

-- REAL-LIFE TORNADO CLIMATE (OFF by default) --
t_set climate [on|off]          - EF rating, size, hail and wind from real data (NOAA / BoM / NTP).
t_set climate region <name|auto> - Region, e.g. oklahoma | OK | US | auto.
t_set climate list              - All regions.
t_set climate status            - Mode, region, last roll, storm and outbreak state.
t_set climate seasons [on|off]  - Tornadoes follow the region's months and hours (default ON).
t_set climate direction [on|off] - Real track directions (default ON).
t_set climate outbreaks [on|off] - Busy storm days with several tornadoes (default ON).
t_set climate frequency <0.25-4> - Multiplier on the map's tornado rate (default 1).
t_set climate outbreakmax <2-10> - Max tornadoes on one outbreak day (default 3).

-- INSURANCE (OFF by default) --
t_set insurance [on|off]        - Per-farm crop and equipment insurance.
t_set insurance managers farm|admin - Who may buy policies: farm managers + admin (default),
                                  or the server admin only.
t_set insurance region <value|auto> - Whose insurance rules apply, e.g. DE | US_KS | auto.
t_set insurance list            - All insurance regions.
t_set insurance sales auto|on|off - Crop policies only in late winter / early spring
                                  (auto = only with seasonal growth; default auto).
t_set insurance value game|real - Crop sum insured: game values or the data's real sums
                                  per hectare (default game).
t_set insurance replacement on|off - Equipment paid at the replacement value, +15 %
                                  (default OFF = sell price).
t_set insurance totaled remove|keep - An accepted equipment total loss removes the wreck
                                  (default) or keeps it like a buy-back.
t_set insurance salvage <0-90>  - Sell price -% with a Salvage title (default 50).
t_set insurance rebuilt <0-90>  - Sell price -% with a Rebuilt title (default 30).
t_set insurance status          - Region, data, settings, records.

------------------------------------------------------------------------------
[4] DEVELOPER + TEST TOOLS
Command: t_dev <tool> [...]
------------------------------------------------------------------------------
Commands marked (!) change your savegame (crops destroyed, money booked,
animals killed). Most test tools run on the host / in single player only.

-- GENERAL --
t_dev verbose [all|physics|destruction|destruction_indoor_bypass]
                                - Toggles verbose log channels (default all).
t_dev hud                       - Physics telemetry over vehicles (mass, speed).
t_dev pos                       - Toggles position tracking.
t_dev status                    - Active objects and timers.
t_dev hotspotdump               - Hotspot and map overlay state.
t_dev twister                   - Twister at your position right now, in any season (the map's
                                  summer twister when the current season has none).
t_dev twister areas             - Prints the running twister's crop destruction areas (perlin, points,
                                  convex or not) and draws them on the ground; again = drawing off.
t_dev kill_test (!)             - Husbandry kill test on the nearest pasture (kills animals).

-- WILDLIFE --
t_dev wildlife list             - Wildlife species of this map and how many are around you.
t_dev wildlife spawn <species> [distance] [count] [rotation]
                                - Spawns wildlife in front of you, e.g. t_dev wildlife spawn crow 60 5

-- NATURAL HAZARDS --
t_dev hazards water <0-100>     - Sets the soil water, e.g. t_dev hazards water 15
t_dev hazards drought           - Forces a drought now.
t_dev hazards damage (!)        - Applies the next drought day of crop damage now.
t_dev hazards end               - Ends the drought, refills the soil.
t_dev hazards flood (!)         - Forces a flood on the low-lying growing fields.
t_dev hazards fire [field] (!)  - Starts a field fire (random grain field, or the given field).
t_dev hazards fireout           - Puts the field fire out.
t_dev hazards log               - Last 20 hazard events.

-- MOISTURE SYSTEM (FS25_MoistureSystem by Ozz) --
t_dev moisture status           - Integration status.
t_dev moisture field <n>        - Moisture of field n and the wither / fire thresholds of its crop.
t_dev moisture wither <n> [count] (!) - Moisture System withers patches on field n now.

-- INSURANCE: GENERAL --
t_dev insurance status          - Region, data, settings, countdowns.
t_dev insurance bill (!)        - Runs the monthly premium billing now.
t_dev insurance testpremium <amount> - Test premium per month for every farm (0 = off, not saved).
t_dev insurance charge|pay <amount> [farm] (!) - Books a premium / payout.
t_dev insurance timer <days> [farm] - Test countdown of <days> real-life days.
t_dev insurance timers          - Running countdowns (adjuster visits, decisions, payouts ...).
t_dev insurance inbox [farm]    - A farm's insurance letters and totals.
t_dev insurance regions         - All insurance regions.

-- INSURANCE: CROPS --
t_dev insurance crops           - Every crop of this map and how it is rated (map crops -> base crops).
t_dev insurance rate <FILLTYPE> <PLAN> <coverage %> - Rate lookup (US data), e.g. MAIZE RP 75
t_dev insurance damage [farm]   - Storm damage log: field, cause, crop, share lost.
t_dev insurance hit <field|here> [radius] [perlin] (!) - Destroys crop at the field centre, or where
                                  you stand ("here"), e.g. t_dev insurance hit here 50 2500
t_dev insurance crop plans      - Plans and coverage levels of this region, sales open or not.
t_dev insurance crop quote <PLAN> <coverage %> - Price for your farm, field by field.
t_dev insurance crop buy <PLAN> <coverage %> - Buys / changes your farm's crop policy.
t_dev insurance crop cancel     - Cancels it (open claims carry on).
t_dev insurance crop claims     - Your crop policy and claims.
t_dev insurance crop unlock     - Opens switched-off countries for testing (this session only).

-- INSURANCE: EQUIPMENT --
t_dev insurance equip quote     - Your vehicles, their values and the price of each deductible.
t_dev insurance equip buy <1000|2500|5000|10000> - Buys / changes the policy (deductible
                                  before the money scale).
t_dev insurance equip cancel    - Cancels it (open claims carry on).
t_dev insurance equip claims    - Claims, titles and the values recorded in the running storm.
t_dev insurance equip accept [claim]  - Accepts a total loss (the wreck goes to the insurer).
t_dev insurance equip buyback [claim] - Buys it back (Salvage title). Without a claim number:
                                  the oldest one waiting.
t_dev insurance equip hit <damage 0-1> [fire] (!) - The vehicle you sit in is hit: value
                                  recorded, damage added, parts broken ("fire" = it burned).
t_dev insurance equip end       - Ends the storm for the insurance: claims open now.
t_dev insurance equip title salvage|rebuilt|none - Title of the vehicle you sit in.

Note: equipment claims open when the tornado ENDS (reaches the map border,
despawns or a new one spawns) - nothing is logged for them while it is
still on the ground.

------------------------------------------------------------------------------
[5] TUNING (advanced physics)
Command: t_tune <param> <value>
------------------------------------------------------------------------------
t_tune suction <number>         - Inward pull speed (default 50).
t_tune lift <number>            - Vertical lift speed (default 12).
t_tune bale_orbit <number>      - Orbit speed for bales (default 20).
t_tune bale_suction <number>    - Suction speed for bales (default 15).
t_tune purge_time <ms>          - Length of the ejection phase (default 5000).
t_tune purge_int <ms>           - Time between ejection phases (default 45000).
t_tune chaos <number>           - Randomness of movement (default 5).
t_tune hover <m>                - Max height of floating objects (default 35).
t_tune max_speed <number>       - Physics speed cap (default 35).
t_tune destruct_ratio <0-1>     - Share of the radius that is the core destruction zone (default 0.2).

------------------------------------------------------------------------------
[6] RESET
Command: t_reset <category>
------------------------------------------------------------------------------
t_reset all                     - Every setting back to the defaults.
t_reset physics | tuning | cargo | husbandry | traffic | wildlife | hazards |
        insurance | climate     - One category. Insurance resets only the settings -
                                  policies, claims and letters are savegame data.

==============================================================================
