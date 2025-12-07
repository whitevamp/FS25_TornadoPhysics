TORNADO PHYSICS MOD (FS25)

Version: 2.0
Author: whitevamp
🌪️ Tornado Physics Mod - Update 2.0.0.0

Summary: This update is a complete rewrite of the physics engine. It addresses performance issues (FPS drops), adds realistic indoor safety checks, and introduces new gameplay mechanics like player ejection and distance-based damage scaling.
Changelog 2.0.0.0

🚀 Performance & Optimization

    Target List System: Replaced the global vehicle loop with a "Target List." The script now only calculates physics for objects actually near the tornado, eliminating FPS lag on maps with high vehicle counts.
    Chunked Searching: The tornado searcher now scans the map in small batches (chunks) rather than all at once, preventing game freezes when the tornado spawns.
    Smart Caching: Roof detection checks are now cached for 1 second, significantly reducing CPU usage during storms.

🛡️ Indoor Safety System (New)

    5-Point Roof Scanner: Implemented a multi-point laser scan (Center, Front, Back, Left, Right) to detect building roofs. Vehicles inside barns are now safe from suction.
    High-Clearance Scanning: Scanners now start 2.5m above the object to prevent large machines (like Combines) from blocking their own safety checks.
    Safety Buffer: Newly detected objects have a 2.0-second "Safety Lock" to ensure the script confirms they are outdoors before applying any lift forces. Fixes the "floating tractor" bug inside sheds.

⚙️ Physics & Gameplay Improvements

    Player Ejection: Added a safety system that automatically kicks the player out of the vehicle if it gets sucked into the tornado core (< 35m) to prevent motion sickness.
    Distance-Based Damage: Damage now scales with proximity.
        Outer Zone (80-100%): Wind only, no damage.
        Mid Zone (50-80%): Light paint scratches.
        Eye (0-50%): Heavy damage and mechanical failure.
    Engine Kill: Vehicles with >90% damage now have their engines stalled continuously, simulating a "totaled" state, but can still be repaired/reset properly.
    Log "Tractor Beam": Added specific logic for logs to rotate and lift them realistically within the funnel. ( Do note that if this feature is enable you have a hi chance of losing the logs permanently, you have been warned.)
    Spawn Immunity: Added a 3-second grace period for vehicles bought from the shop to prevent instant damage if the shop is near a storm.

🐛 Bug Fixes

    Fixed "Bouncing Bales" where objects would repeatedly drop and catch.
    Fixed an issue where resetting a "Broken" vehicle would leave it permanently bricked.
    Fixed vehicles detecting their own cabs as "Roofs" and disabling physics outdoors.

🛠️ How to Enable Developer Mode (FS25)

To use the new console commands included in this mod (like t_set radius or t_status), you must enable the developer console in Farming Simulator 25.

    Navigate to your FS25 settings folder:
        Windows: Documents\My Games\FarmingSimulator2025\
        Steam (Linux/Proton): ~/.steam/steam/steamapps/compatdata/[AppID]/pfx/drive_c/users/steamuser/Documents/My Games/FarmingSimulator2025/
    Open the file game.xml with a text editor (Notepad, VS Code, etc.).
    Scroll to the very bottom and look for the <development> tag.
    Change <controls>false</controls> to <controls>true</controls>.
    Save the file and launch the game.

How to use:

    Press the Tilde (~) or Backtick (`) key (usually under ESC) once to open the log.
    Press it a second time to open the command input line.
    Press Tab to cycle through available commands.

Mod Commands:
    indoor_damage - vehicles inside buildings will take damage (though physics are disabled).  (Default off)
    outdoor_damage - vehicles outside will take damage and physics forces.  (Default on)
    random_size - the tornado scale is randomized upon spawning.   (Default on) (note: default set in the script is 0.5% min to 5.0% max size increase. so 1/2 of original (game default size.) to 5x larger.)
    t_toggle lift_bales - Turns bale physics on/off on the fly. (Default is on.)
    t_toggle  lift_logs - Turns logs physics on/off on the fly. (Default is off.) ( Do note that if this feature is enable you have a hi chance of losing the logs permanently, you have been warned.)




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
