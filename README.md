# 🌪️ Tornado Physics for FS25

![Version](https://img.shields.io/badge/Version-2.0.0.0-blue) ![Platform](https://img.shields.io/badge/Platform-PC%20%2F%20Console-green) ![FS25](https://img.shields.io/badge/Game-Farming%20Simulator%2025-orange)

**Tornado Physics** breathes life into the static visual "twister" event in Farming Simulator 25. It adds realistic suction, lift, and destruction mechanics, turning a simple visual effect into a genuine gameplay threat.

> **Note:** This mod is script-only and uses internal game engine physics. It is highly optimized for performance and multiplayer compatibility.

---

## 🚀 Key Features (v2.0)

### 🌪️ Realistic Physics Engine
* **Suction & Lift:** Objects are dragged toward the funnel and lifted into the air based on their mass.
* **Heavy Machinery Tuning:** Tractors and Combines feel "heavy" and resist lift longer than lighter objects like bales or logs.
* **Tractor Beam Logs:** Logs are captured in a special orbital physics loop, creating a debris field effect.

### 🛡️ Intelligent Safety Systems
* **Indoor Safety Check:** Vehicles and items inside barns or sheds are **safe**.
    * *Technical:* Uses a **5-Point High-Clearance Roof Scanner** to detect buildings above the object, ensuring large Combines don't accidentally block their own safety check.
* **Player Ejection:** If your vehicle is sucked into the "Eye" of the storm (< 35m), you are automatically ejected to prevent motion sickness.
* **Spawn Immunity:** Newly purchased vehicles have a 3-second immunity window to prevent instant damage if the shop is near a storm.

### ⚡ Performance Optimized
* **Zero-Lag Target System:** The script uses a cached "Target List" instead of looping through the entire vehicle table every frame.
* **Chunked Searching:** The tornado discovery logic runs in small chunks to prevent any FPS drops when a storm spawns.
* **Sleep Mode:** Physics calculations stop immediately when no tornado is present.

### 💥 Distance-Based Damage
* **Outer Zone (80-100%):** Strong wind, no damage.
* **Mid Zone (50-80%):** Paint scratches and dirt accumulation.
* **The Eye (0-50%):** Heavy mechanical damage. Vehicles >90% damaged will stall engine (simulating total failure).

---

## 📥 Installation

1.  Download the latest `FS25_TornadoPhysics.zip` from the [Releases](https://github.com/whitevamp/FS25_TornadoPhysics/releases) page (or ModHub).
2.  Place the zip file into your Farming Simulator 25 `mods` folder.
    * *Windows:* `Documents\My Games\FarmingSimulator2025\mods`
3.  Activate the mod in the in-game menu.

---

## 🛠️ Developer / Debug Commands

*Note: These commands are for testing/debugging purposes. The mod is fully tuned for gameplay by default.*

To use these, you must enable `development` controls in your `game.xml`.

| Command | Description |
| :--- | :--- |
| `t_status` | Shows current tracking stats (Active objects, radius, etc.) |
| `t_set radius <value>` | Manually sets the tornado influence radius (Default: 150) |
| `t_randomize` | Forces the tornado to rescale/randomize immediately |
| `t_toggle <feature>` | Toggles specific features (e.g., `lift_bales`, `indoor_damage`) |

---

## 🐛 Bug Reports & Feedback

If you encounter any issues, floating tractors, or performance drops, please open an [Issue](https://github.com/whitevamp/FS25_TornadoPhysics/issues) here on GitHub.

Please include:
* Map Name
* Vehicle Type (if specific)
* Log file (`log.txt`) if an error occurred.

---

**Credits:** Scripting & Physics by **whitevamp**.
