# Tornado Physics (FS25)

**Tornado Physics** is a gameplay script mod for *Farming Simulator 25* that transforms tornadoes from simple visual effects into dangerous, physics-based weather events.

Unlike the base game where tornadoes pass harmlessly through equipment, this mod hooks into the game engine to apply real suction, lift, and destruction forces to vehicles caught in the storm.

## 🔥 Features

* **Physics-Based Suction:** Vehicles are physically dragged across the ground toward the funnel.
* **Realistic Lift:** Once inside the "Eye," vehicles are lifted into the air and spun around.
* **Mass-Dependent Physics:**
    * **Heavy Vehicles (30t+):** Will struggle, hover low, and resist the wind.
    * **Light Vehicles (<6t):** Will be launched high into the air and tossed violently.
* **Total Destruction System:**
    * Vehicles caught in the center take **100% Mechanical Damage** (Engine failure).
    * Instantly applies **100% Dirt** and **100% Paint Wear**.
    * Vehicles must be towed to a shop for repair.
* **Performance Optimized:** The script allows vehicles to "sleep" (save FPS) until the tornado is nearby.
* **Shop Safety:** Vehicles currently being configured in the Store are protected from physics to prevent accidents.

## 📦 Installation

1.  Download the latest release.
2.  Ensure the zip file is named `FS25_TornadoPhysics.zip`.
3.  Place the zip file into your Farming Simulator 25 mods folder:
    * `Documents/My Games/FarmingSimulator2025/mods`
4.  Activate the mod in the game menu.

## 🎮 Console Commands

This mod works automatically with natural weather, but you can use the Developer Console (`~` key) to test or force events.

| Command | Description |
| :--- | :--- |
| `gsWeatherTwisterSpawn` | Spawns a tornado directly in front of the player (Game Default). |
| `t_status` | Checks if the script has successfully locked onto the tornado object. |
| `t_scan_root` | Forces a re-scan of the engine root. Use this if the physics don't seem to engage. |
| `t_lock [ID]` | (Advanced) Manually locks physics to a specific Node ID if auto-scan fails. |

## 🛠️ Technical Details

The mod uses a hybrid physics approach to overcome the game engine's heavy gravity and braking friction:
* **Suction Zone (Outer):** Uses `addImpulse` to drag vehicles while respecting tire friction.
* **Lift Zone (Inner):** Applies a calculated vertical impulse that scales based on vehicle mass (`mass^0.7`), ensuring that heavy equipment feels heavy while lighter equipment flies.

## ⚠️ Compatibility

* **Multiplayer:** Fully supported. Physics runs server-side to keep client positions synchronized.
* **Dedicated Servers:** Supported.

## 📝 Credits

* **Author:** whitevamp
* **Scripting & Physics:** whitevamp

---
*Disclaimer: This mod is designed to destroy vehicles. Use with caution on save games where you cannot afford repairs!*
