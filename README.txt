TORNADO PHYSICS MOD (FS25)
Version: 1.0
Author: whitevamp

DESCRIPTION:
This mod adds real physics to the Farming Simulator 25 Tornado.
By default, the game's tornado is just a visual effect. This mod makes it dangerous.

FEATURES:
- Suction: Drag force pulls vehicles toward the funnel.
- Lift: Vehicles will be lifted into the air based on their mass.
- Destruction: If a vehicle hits the "Eye" of the storm, it will take 100% Damage, 100% Wear, and 100% Dirt instantly. The engine will break.
- Physics Tuning: Heavy vehicles (30t+) will struggle to lift, while light vehicles (<6t) will fly easily.

HOW TO TEST (CONSOLE COMMANDS):
This mod works with natural weather, but you can force a tornado for testing:
1. Enable Developer Console in game settings.
2. Press '~' to open the console.
3. Type: gsWeatherTwisterSpawn
   (This spawns a tornado directly in front of you).

DEBUG COMMANDS:
If the physics do not seem to engage, you can use these commands in the console:
- t_status       : Shows if the script has found the tornado object.
- t_scan_root    : Forces the script to re-scan the engine for the tornado.
- t_lock <ID>    : Manually locks physics to a specific Node ID (advanced users).

INSTALLATION:
Place the FS25_TornadoPhysics.zip into your mods folder.
