# 🌪️ Tornado Physics (v4.0.0.0 - The Destruction Update)

### [⬇️ Download TORNADO PHYSICS on the GIANTS ModHub](https://www.farming-simulator.com/mod.php?mod_id=344814)
*Approved and live on the official GIANTS ModHub — install directly in-game or via the link above.*

[![GitHub Release](https://img.shields.io/badge/GitHub-whitevamp%2FFS25__TornadoPhysics-blue)](https://github.com/whitevamp/FS25_TornadoPhysics)

---

## 📌 Overview
**Tornado Physics** is a complete physics overhaul for Farming Simulator 25. It replaces standard, static visual weather effects with an advanced, high-performance destruction engine that calculates mass, lift, drag, and structural disruption in real time.

---

## 🆕 What's New in v4.0.0.0 (The Destruction Update)

* 🏗️ **Complete Code Rewrite:** Rebuilt on a modular architecture for maximum stability, save-game safety, and performance.
* 🔌 **Modder API:** Open API allowing other developers to hook into storm state, intensity, and lifecycle events (see `/API` folder).
* 🧰 **Centralized Command System:** Streamlined console control via `t_help`, replacing 20+ disconnected commands.
* 📦 **Cargo Spilling:** Trailers and implements drop cargo based on cover state (Uncovered = 100% loss; Covered = leak/pop risk).
* 💥 **Vehicle Destruction & Auto-Repair:** Rips physical nodes off machines. Features an automated 24-hour repair cycle fully synced to your save game.
* 💰 **Hardcore Recovery System:** Charges an itemized tow and repair bill if you reset tornado-damaged equipment back to the shop.
* 🌧️ **Dynamic Weather Supercells:** Randomizes rain and hail intensity on storm spawn across 3 profiles (*LP*, *Classic*, and *HP* Supercells).
* 🚨 **Siren Warnings:** Features a 3-minute warning siren loop upon storm spawn.
* 🗺️ **Map UI & Teleportation:** Real-time ESC map hotspot with live storm telemetry (EF-Rating, Wind Speed, Radius) and instant teleportation.
* 🔥 **Visual Effects & Shader Support:** Motorized machines emit smoke/fire when critically damaged; volumetric funnel rendering via `smokeTrailSubUV`.
* 🧭 **Cross-Mod Integrations:** Native support for *Advanced Damage System (ADS)* by id577 and *CompassHeading* by RocklandUSA.

---

## 💾 Installation
1. Download `FS25_TornadoPhysics.zip` and place it in your game's `mods` directory:
   * **Path:** `Documents/My Games/FarmingSimulator2025/mods`
2. Activate **Tornado Physics** in the in-game mod selection screen.
3. *No new save game required.*

---

## ⚙️ Core Mechanics & Features

### 🚜 True Physics Engine & Geo-Fencing
Vehicles are orbited, lifted, and ejected based on physical mass. Heavy tractors resist suction longer than light balers or pallets. Automated geo-fencing prevents objects from being hurled off the map edge.

### 🐄 Husbandry & Animal Lethality
Tornadoes passing over pastures will kill exposed livestock. 
* **Pasture Detection:** Checks for outdoor pastures using GIANTS `spec_husbandryFence` data.
* **Indoor Immunity:** Animals inside enclosed, fully indoor barns are completely safe.
* **Dynamic Scaling:** Post-strike immunity timers automatically scale to map size.

### 🛠️ Advanced Damage System (ADS) Stages
When running alongside the *ADS* mod, storm exposure applies staged damage:
| Exposure Duration | Damage Severity |
| :--- | :--- |
| **15 Seconds** | Minor Damage |
| **30 Seconds** | Moderate Damage |
| **50 Seconds** | Total Destruction |

---

## 💻 Console Commands (`~`)

Configuration settings are live-tunable and auto-save to `modSettings/TornadoPhysics_Config.xml`.  
Type `t_help [command]` in the console for detailed sub-command info.

### Command Categories
| Command Group | Description | Default Status |
| :--- | :--- | :--- |
| `t_physics` | Manage storm radius, power, mass thresholds, and physical targets | Active |
| `t_set` | Toggle core gameplay modules (cargo, destruction, recovery, UI) | Modular |
| `t_sfx` | Toggle audio sirens, dual debug rings, and vehicle fires | Modular |
| `t_tune` | Live-tune hardcore simulation constants (suction, lift, chaos, hover) | Advanced |
| `t_dev` | Access telemetry HUDs, coordinate tracking, and master logging | Developer |
| `t_reset` | Factory reset config targets (`all`, `physics`, `tuning`, `cargo`, `husbandry`) | Utility |

### Quick Reference Command List
```text
=== PHYSICS CONTROL (t_physics) ===
t_physics radius [x]      : Override storm radius (Default: 35)
t_physics power [x]       : Ejection power (Default: 20)
t_physics heavy [x]       : Mass threshold for heavy vehicles
t_physics fence [x]       : Safe distance buffer from map edge
t_physics lift_bales      : Toggle lift for bales and pallets
t_physics lift_logs       : Toggle lift for timber/logs
t_physics indoor_damage   : Toggle structural damage inside sheds
t_physics randomize       : Force a new random storm size and EF rating

=== MODULE TOGGLES (t_set) ===
t_set cargo               : Cargo Spilling System (Default: OFF)
t_set husbandry           : Animal Lethality (Default: OFF)
t_set destruction         : Persistent Vehicle Destruction (Default: OFF)
t_set recovery            : Emergency Tow Billing on Shop Reset (Default: OFF)
t_set mapui               : Map Overlay Telemetry Widget (Default: OFF)
t_set save                : Force-save current settings to XML

=== VISUALS & AUDIO (t_sfx) ===
t_sfx sound               : Toggle 3-Minute Warning Siren
t_sfx ring                : Toggle Dual Debug Rings (Safety & Suction Zones) (Default: OFF)
t_sfx fire_random         : Toggle random vehicle fire ignition

=== HARDCORE TUNING (t_tune) ===
t_tune [suction|lift|chaos|bale_orbit|hover|max_speed|purge_time] [x]
Example: "t_tune chaos 20" (Extremely violent storm movement)

=== DEVELOPER TOOLS (t_dev) ===
t_dev hud                 : Toggle real-time physics telemetry over nodes
t_dev verbose all         : Enable master system logging
t_dev pos                 : Toggle real-time tornado node coordinates

```

---

## 🗺️ Map Radius & Scaling Guide

The mod automatically scales for custom map sizes, but manual radius overrides can be applied via `t_physics radius [x]`:

| Map Type | Physical Dimensions | Recommended Radius | Max EF-5 Width |
| --- | --- | --- | --- |
| **Standard** | 2km × 2km | `Radius 35` | 175m |
| **4x Map** | 4km × 4km | `Radius 70` | 350m |
| **16x Map** | 8km × 8km | `Radius 140` | 700m |
| **64x Map** | 16km × 16km | `Radius 280` | 1400m |

---

## ⚠️ Known Developer Tool Limitations

> [!NOTE]
> *Normal high-speed time acceleration and standard gameplay simulation function flawlessly.* The items below only apply when using external developer utilities:

1. **Extreme Time Fast-Forwarding:** Using external tools (e.g., *EasyDevControls*) to jump several months ahead in a single frame while a storm is active may freeze lingering smoke/fire effects.
2. **24-Hour Auto-Repair Countdown:** Single-frame multi-month time jumps will pause the 24-hour repair timer. To resume normally, simply pass time using standard game mechanics (such as sleeping).
3. **High Vehicle Density Performance:** If dozens of vehicles are packed tightly together (e.g., via stacking mods like *Used Equipment Yard*) and hit simultaneously, brief engine-level structural calculation stutters may occur.

---

## 👥 Credits & Modder Support

* **Main Author & Lead Developer:** whitevamp *(Core Engine, Modular Architecture, Mod API)*

* **ADS Mod Integration:** Original mod by *id577*

* **CompassHeading Integration:** Original mod by *RocklandUSA Gaming*

* **Testing & Feedback:** Community



*Bug reports, feature requests, and developer API documentation:*

🔗 **[GitHub Repository](https://github.com/whitevamp/FS25_TornadoPhysics)**
