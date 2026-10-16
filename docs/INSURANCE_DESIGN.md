# Tornado Physics – Insurance Module (Design Document)

**Status:** Draft / planning – crop data builder done (`tools/build_crop_insurance.py` → `DB/CropInsurance_US.xml`), module not implemented yet
**Target:** Tornado Physics v5.x or later (module inside the mod, OFF by default)
**Last updated:** 2026-10-15

> All game-API names in this document were checked against the decrypted FS25 base-game scripts
> (`dataS/scripts_decoded`). Real-life numbers marked **(verify)** are from memory and must be checked
> against the original sources before they are used as defaults.

---

## 1. Summary

An optional, per-farm insurance system modelled on real-life farm insurance:

- **Equipment insurance** – vehicles and tools damaged or destroyed by a tornado are repaired at the
  insurer's cost, or written off as a **total loss** with a payout. Totaled vehicles can be **bought back**
  and carry a permanent **rebuilt title** that lowers their resale value.
- **Crop insurance** – crops destroyed by the tornado (and by hail) are paid out per field, based on
  real US crop insurance rules (Yield Protection / Revenue Protection / Revenue Protection with
  Harvest Price Exclusion) and real premium, subsidy and payout data from USDA RMA.
- Monthly **premiums**, **deductibles**, **waiting periods**, a **claims process with an adjuster delay**,
  and an in-game **inbox** of letters / texts, all on its own **Insurance** tab in the control panel.

## 2. Goals and non-goals

**Goals**

- Turn tornado damage into a risk-management decision instead of pure punishment.
- Feel like real insurance: premiums, deductibles, waiting periods, adjusters, total-loss rules.
- Work for every player in multiplayer independently (**per farm**).
- Work with any days-per-month setting and with price-changing mods, without special cases.
- Stay optional: the whole module is OFF by default, like Real-Life Climate mode.

**Non-goals (first version)**

- Insuring buildings / placeables (possible later, see §15).
- Insuring against non-tornado damage (normal wear, breakdowns, base-game fires). The module only
  handles damage the tornado (or tornado hail) caused.
- Being a generic insurance framework for other mods (the module boundary keeps that possible later).

## 3. Why inside Tornado Physics (not a separate mod)

- Claims depend on *how* the tornado damaged something (destroyed nodes, recovery bill, total-loss
  check, storm path). That data is internal to Tornado Physics; exposing all of it through the public
  `g_tornadoPhysicsAPI` would be a large, fragile API.
- Reuses existing systems: settings save, multiplayer sync (`TornadoSync`), translations (`TornadoText`),
  control panel, savegame persistence, recovery bill.
- Written as a self-contained module (`scripts/insurance/…`) so it can be split into its own mod later
  if it grows too large.

## 4. Prerequisites

### 4.1 Crop damage measurement (required for crop insurance)

The base game already destroys crops – the mod does not need to:

- `Twister:updateDestructionAreas()` runs `FSDensityMapUtil.updateDisasterArea(polygon, perlinPercentage)`
  over the twister's destruction polygons. Every fruit type with `minDisasterDestructionState` /
  `maxDisasterDestructionState` is set to its destroyed state (patchy, Perlin-noise pattern).
- Hail does the same (`WeatherObjectHail.lua`).
- Both only destroy crops when the savegame setting **Disaster destruction** is `ENABLED`
  (`g_currentMission.missionInfo.disasterDestructionState`, enum `DisasterDestructionState`:
  `ENABLED = 1`, `VISUALS_ONLY = 2`, `DISABLED = 3`).

**What is missing:** the game does not record *which* fields were hit or *how much*. The module must
measure it. Options (to be prototyped):

1. **Path log + post-storm sampling** – hook `Twister.updateDestructionAreas` (class function, hook
   once with a guard flag like the other Twister hooks) to log the polygons' world positions. After the
   tornado despawns, sample each field crossed by the path on a grid and count destroyed vs. healthy
   crop cells.
2. **Before/after field state** – read field states when the tornado approaches and again after it
   leaves; the difference is the damage.

Hail damage: the same sampling, triggered when a hail weather object ends over owned fields.

If **Disaster destruction** is not `ENABLED`, crop claims never happen and the Crop policy page says so.

### 4.2 Pre-storm vehicle value snapshot (required for equipment insurance)

The first time the tornado touches a vehicle, store its pre-storm value (see §7.1).

## 5. Time model (days per month)

FS25 lets the player choose days per month: `g_currentMission.environment.daysPerPeriod` (default 1,
changeable mid-game; one "period" = one month, `Environment.PERIODS_IN_YEAR = 12`).

Rules:

- **Monthly billing** happens on the game's `MessageType.PERIOD_CHANGED`, never "every X days".
  Correct at any days-per-month setting.
- **Durations** (waiting periods, adjuster delay) are defined in **real-life days** and converted to a
  share of a month: `months = realDays / 30`.
  Example: 7 real days → 0.233 months → 1.17 in-game days at 5 days/month, ~5.6 in-game hours at 1 day/month.
- **Countdowns tick down by time actually played**, not toward a stored end date: every update,
  `remainingMonths -= dtGameMs / (daysPerPeriod × 24 h)`. Read `daysPerPeriod` each time, so a
  mid-game change adjusts the remaining time fairly instead of jumping.
- **Yearly rules** (policy changes allowed once a year) use the period: "before planting" = a
  configurable cut-off period (default: before Early Spring ends).
- **UI** always shows remaining time in in-game units ("about 1 day 4 h left").

## 6. Policies

All policies are **per farm**. Only the farm manager (`Farm:isUserFarmManager`) or a server admin
can buy, change or cancel them – the same rule as other farm-finance actions.

### 6.1 Equipment policy

| Setting | Meaning |
|---|---|
| Deductible | Chosen per policy, e.g. $1,000 / $2,500 / $5,000 / $10,000. Higher deductible → lower premium. |
| Insured items | All owned vehicles and tools of the farm (no per-vehicle selection in v1). |
| Premium | Yearly rate × insured value ÷ 12, billed monthly. Rate **≈ 0.5–2 % of value per year (educated guess, tunable)**, adjusted by deductible. |
| Insured value | Sum of `Vehicle:getSellPrice()` over the farm's owned vehicles, recalculated at billing time. |

**Not insurable:**

- Leased vehicles (`VehiclePropertyState.LEASED`) – in real life the lessor's policy covers them; FS
  leasing has no buyout.
- Mission / contract vehicles (`VehiclePropertyState.MISSION`).
- Shop preview vehicles (`VehiclePropertyState.SHOP_CONFIG`).

### 6.2 Crop policy

Based on US federal crop insurance (USDA Risk Management Agency).

| Setting | Meaning |
|---|---|
| Plan | **YP**, **RPHPE** or **RP** (default) – see below. Specialty crops only offer **APH**. |
| Coverage level | 50 %–85 % in 5 % steps (confirmed by the RMA data; only levels with enough real policies are offered per crop). |
| Insured fields | All owned fields of the farm with an insurable crop. |
| Expected yield | v1: the crop's standard yield per hectare from the game. Later: the farm's own harvest history (real-life *Actual Production History*). |
| Locked price | Crop price recorded when the policy year starts (real-life *projected price*). |
| Premium | From the RMA data (§9.3): real premium rate and subsidy per crop, plan and coverage level, adjusted by state and by the crop's price volatility. |

**Plans** (the three main US crop insurance plans, plus APH):

| Plan | Covers | Price used | Real-life cost (example: corn, 75 %) |
|---|---|---|---|
| **YP** – Yield Protection | Yield losses only | Locked price | cheapest |
| **RPHPE** – Revenue Protection with Harvest Price Exclusion | Yield and revenue losses | Locked price (never rises) | in between |
| **RP** – Revenue Protection | Yield and revenue losses | Higher of locked and claim-time price (capped) | most expensive, most popular |
| **APH** – yield-based plan for specialty crops | Yield losses only | Locked price | crop-specific |

- **YP / APH** – guarantee = expected yield × coverage × **locked price**.
- **RPHPE** – guarantee = expected yield × coverage × **locked price**; also pays when revenue
  (yield × claim-time price) falls below the guarantee.
- **RP** – guarantee = expected yield × coverage × **max(locked price, claim-time price)**, with the
  claim-time price **capped at 200 % of the locked price** (real RP harvest-price cap **(verify)**).

**Plans per FS25 crop** (from the RMA plan listings and the 2020–2024 data):

| FS25 crops | Plans offered |
|---|---|
| Wheat, soybeans, maize (corn) | RP, RPHPE, YP |
| Barley, canola, sorghum, sunflowers, cotton, rice, long-grain rice, peas | RP, YP (RPHPE where the data has enough policies) |
| Oats | RP, YP, APH |
| Potatoes, sugar beets, sugarcane, grapes, olives, green beans, grass | APH only (yield cover) |
| Spinach, carrots, parsnips, red beets | APH, numbers borrowed from potatoes / sugar beets (no RMA programme of their own) |
| Crops from other mods (with a sell point) | The **DEFAULT** curves (all field crops together) |
| Poplar, oilseed radish, meadow | Not insurable |

**Not insurable:** crops with no sell point on the current map (the UI explains why); fields the farm
does not own.

## 7. Equipment claims

### 7.1 Value snapshot

The first time a vehicle enters the tornado's damage zone (the same check `TornadoPhysics` /
`TornadoDestruction` already use), store:

- `preStormValue = vehicle:getSellPrice()` – the game's own formula
  (`Vehicle.calculateSellPrice`: price × lifetime factor × age factor − repair price − repaint price,
  floor 3 % of price). Existing wear is already deducted, which matches real *actual cash value*.
- Storm id, time, the vehicle's `uniqueId` (`vehicle:getUniqueId()`).

### 7.2 Repair estimate

After the storm, the repair estimate comes from **`TornadoRecovery:estimateRepairCost(vehicle)`** – the
same itemized calculation the emergency tow bill uses, without charging or repairing anything (tow fee,
structural / trash parts, wheels, tracks, engine work, total) – plus the base-game repair/repaint price
increase since the snapshot.

### 7.3 Decision

| Condition | Outcome |
|---|---|
| Repair estimate ≤ deductible | Claim closed, nothing paid (the player is told why). |
| Repair estimate < total-loss threshold × pre-storm value | **Repair**: the insurer pays repair − deductible. The vehicle is repaired (existing restore logic) and the recovery bill is covered. |
| Repair estimate ≥ threshold × pre-storm value | **Total loss** (§7.4). |

Total-loss threshold: setting, default **75 %** (real insurers commonly use ~70–80 % **(verify)**).

### 7.4 Total loss

The player chooses (inbox letter with two buttons):

1. **Accept the total loss** – payout = pre-storm value − deductible. If the setting
   *Remove totaled vehicles* is ON, the vehicle is deleted on the server (`vehicle:delete()`, the same
   removal `SellVehicleEvent` does) **without** the game's sell money – only the insurance payout is paid.
   If it is OFF, the wreck stays on the farm, marked *Salvage*, and can be scrapped.
2. **Buy back (owner-retained salvage)** – payout = pre-storm value − deductible − salvage value. The
   player keeps the vehicle, which gets a **Salvage** title; once repaired it becomes **Rebuilt**.

Salvage value: setting, default 15 % of pre-storm value (to tune).

### 7.5 Branded titles (Salvage / Rebuilt)

- Stored per vehicle by `uniqueId` in the module's savegame file.
- `Vehicle.getSellPrice` is wrapped once at class level (guard flag, like the other Vehicle hooks): a
  branded vehicle returns `originalPrice × (1 − titlePenalty)`. Every place the game shows or pays a sell
  price (shop sell list, selling) then uses the reduced value automatically.
- Title penalty: setting. Real-life rebuilt vehicles are commonly said to sell **~20–40 % lower**
  **(verify)**; the author would like −50 % to −75 % for gameplay. Default to be decided (open question).
- The title is permanent and shown in the Insurance tab and the vehicle's insurance status.

## 8. Crop claims

1. After a tornado (or hail) over an insured field, the damage sampling (§4.1) produces the
   **destroyed share** of the field.
2. A claim opens automatically (the player is notified; no manual filing needed in v1).
3. **Adjuster delay** (§10) – the adjuster "visits", then the decision letter arrives.
4. Payout:
   - Loss = destroyed share × field area × expected yield × price (locked for YP; capped max for RP).
   - Guarantee covers `coverage level` of the expected revenue; the payout is the loss beyond the
     uninsured part, never more than the guarantee.
5. **Write-off option** – if the destroyed share is above a threshold (e.g. 50 %), the letter offers to
   write the whole field off: full guarantee paid, the player may clear the field and replant.

Prices are always read from the game (§9.1).

## 9. Prices and premiums

### 9.1 Price source (price-mod compatibility)

**Never compute prices in the module.** Always read what the player sees on the Prices page:

- Per sell point: `SellingStation:getEffectiveFillTypePrice(fillType, toolType)`
  (includes the sell point's own swings and great-demand events).
- The insurance price = the **best** (or average – to decide) price across sell points that accept the
  crop.
- Fallback: `g_currentMission.economyManager:getPricePerLiter(fillTypeIndex)` (base price × difficulty
  multiplier × seasonal factor).

Price mods hook one of these layers, so any price mod (constant all-year prices, extra volatility, new
crops with sell points) is respected automatically:

- **Constant prices** – RP and YP behave the same; nothing breaks.
- **Extra volatility** – kept fair by the 200 % cap and volatility-based premiums.

### 9.2 Equipment premium

`monthly premium = insured value × yearly rate(deductible) ÷ 12`

### 9.3 Crop premium

`monthly premium = liability × farmerRate(crop, plan, coverage) × stateRateFactor(crop) × volatility factor ÷ 12`

- **farmerRate** – the real farmer-paid premium per dollar insured, from `DB/CropInsurance_US.xml`
  (US curves per crop, plan and coverage level). It already includes the real **subsidy**, which falls
  as coverage rises. Raw US 2020–2024 averages (the XML curves are smoothed, see §13.2):

  | Coverage | 50 % | 60 % | 70 % | 75 % | 80 % | 85 % |
  |---|---|---|---|---|---|---|
  | Subsidy share (wheat RP) | 71 % | 67 % | 65 % | 68 % | 59 % | 42 % |
  | Farmer cost per acre (wheat RP) | $4.36 | $9.59 | $12.68 | $13.56 | $19.26 | $27.55 |

  The UI can show the full price and the subsidy separately (`premiumRate`, `subsidyShare`), like a real quote.
- **stateRateFactor** – how expensive cover is in the map's state compared with the US (e.g. Kansas
  maize 1.42, Kansas wheat 1.07). The state comes from the climate region (same `US_xx` ids). No state
  data or no region → 1.0.
- **Volatility factor** – the module samples each crop's price once a month and keeps 12 months of
  history. Larger swings → higher factor; flat prices → lower factor. (Real premiums are also partly based
  on expected price swings.) Default factor 1.0 until enough history exists.
- **Currency** – the data is in US dollars per dollar insured, so the rates are unit-free and work with the
  game's own crop prices; only `farmerPerAcre` is a dollar figure (display / sanity checks only).

**Missing data at runtime** (thin samples are left out of the XML on purpose):

1. Coverage level missing for a plan → offer only the levels that exist (do not invent levels).
2. Plan missing for a crop (e.g. RPHPE for barley) → plan not offered for that crop.
3. Crop missing or too thin (e.g. olives: one APH level) → use the **DEFAULT** crop's curve for that plan.
4. `borrowedFrom` crops → use the named crop's data.

**Balance note:** the real loss ratio (payouts ÷ full premium) is about 0.6–1.2 at most levels and
about 1.7 at 85 % – real insurers lose money at high coverage because the government reinsures them.
The game uses the farmer-paid rate for prices and the real loss ratios only for tuning.

### 9.4 Premium history

- Claims raise the next year's premium; claim-free years lower it (no-claims discount). Setting, small
  effect by default.

## 10. Waiting periods and delays

All in real-life days, converted with §5:

| Rule | Default | Purpose |
|---|---|---|
| New equipment policy becomes active | 3 days | No buying cover when the siren sounds. |
| New / increased crop policy | Only before the planting cut-off; active after 7 days | Mirrors sales closing dates. |
| Adjuster visit after a claim opens | 3 days | Real "claim under review" feel. |
| Decision after adjuster visit | 2 days | |
| Payout after acceptance | 1 day | |
| Policy changes (plan / coverage / deductible) | Once per policy year, at renewal | Real policies are annual. |

During an active **outbreak** (TornadoOutbreak) or while a tornado is on the ground, new policies and
upgrades are refused outright (not just delayed).

## 11. User interface

New control-panel tab group **Insurance** (only shown when the module is ON):

- **Overview** – active policies, next premium date and amount, open claims with countdowns,
  a bar chart of *premiums paid vs. payouts received* per month (last 12 months).
  FS25 has no reusable chart element, so bars are drawn with plain bitmap elements.
- **Equipment** – deductible choice, insured value, premium, insurable / non-insurable vehicles,
  vehicles with Salvage / Rebuilt titles.
- **Crops** – plan (RP/YP, one-line explanation each), coverage level, per-field insured value,
  locked prices, premium. Shows a clear note when Disaster destruction is not ENABLED.
- **Claims** – open and closed claims, status timeline (*received → adjuster visit → decision → paid*),
  decision letters with the choice buttons (accept total loss / buy back / write off field).
- **Inbox** – letters, emails and text messages from the insurer:
  *Policy confirmed*, *Premium charged*, *Claim received*, *Adjuster visiting in 2 days*,
  *Claim approved: total loss, $612,000*, *Premium change for next year*. New ones also appear as
  in-game notifications.

All texts through the existing translation system (`tools/translations_source.py`, 7 languages).
Every money value is formatted in the receiving player's currency (`TornadoText.money`).

## 12. Settings

| Setting | Default | Scope |
|---|---|---|
| Insurance module | OFF | Server (gameplay) |
| Total-loss threshold | 75 % | Server |
| Remove totaled vehicles | ON | Server |
| Salvage value | 15 % | Server |
| Rebuilt-title value penalty | to decide (§16) | Server |
| Equipment base rate | educated guess, tunable | Server |
| Crop base rates / subsidy table | from RMA data | Server (data file) |
| Waiting periods / delays | §10 | Server |
| No-claims discount strength | small | Server |

Policies themselves are per-farm data, not settings.

**Money scaling (implemented, shared with the recovery bill):** every amount the module charges is
multiplied by `TornadoSettings:getCostScale()` = the game's cost multiplier for the savegame's economic
difficulty (`EconomyManager.getCostMultiplier()`: Easy 0.4 / Normal 0.7 / Hard 1.0) × the player's
"Cost scale" setting (25–200 %). Premiums are already a share of in-game values (crop prices from the
sell points, vehicle sell prices), so price-changing mods are covered without detecting them.

## 13. Data and persistence

- **Settings** – `modSettings/TornadoPhysics_Config.xml` like the other modules; synced through
  `TornadoSync` (`fieldSetting` entries) so the server owns them.
- **Per-farm insurance state** – a new savegame file (e.g. `TornadoInsurance.xml` next to
  `TornadoState.xml`, written from the same save hook):
  policies per farm, policy-year dates, open/closed claims with remaining countdowns, inbox messages,
  premium/payout history, price history per crop, vehicle snapshots and branded titles by `uniqueId`.
- **Crop insurance data** – **done:** `tools/build_crop_insurance.py` (standard library only, same
  pattern as the climate builders) turns the USDA RMA *Summary of Business* files into
  `DB/CropInsurance_US.xml` (~86 KB). Public-domain US government data; credit RMA in modDesc / README.
  Canada: provincial programmes, later.

### 13.1 RMA source data and processing rules

- **Source:** RMA *State/County/Crop Summary of Business*, "State/County/Crop/Coverage Level
  1989 – Present" zip files, years **2020–2024** (newer years are left out until their payouts are
  settled). Record layout: `SOB_State_County_Crop_with_Coverage_Level_1989_Forward`. Raw files live in
  `USDA_RMA/archives/` (never shipped).
- **Format:** pipe-delimited text, 28 columns per row (state × county × crop × plan × coverage level).
- **Rules:**
  - only **buy-up** rows (coverage category `A`); CAT (`C`, flat-fee catastrophic cover) is left out,
  - only rows measured in **acres**,
  - *Total Premium* is before subsidy; **farmer cost = total premium − subsidy − state/private subsidy**,
  - **Additional Subsidy is ignored** (2021–2022: one-off Pandemic Cover Crop Program), the EFA
    (beginning / veteran farmer) discount is ignored as well,
  - entries need ≥ 20,000 acres and ≥ 30 policies over the five years.
- **Plan availability** per state/county: RMA *Insurance counties and commodities* listings
  (`USDA_RMA/AllStatesCropInsurancePlan-*_2025/2026.xlsx`; the 2027 listing is incomplete until spring
  crops are published). Not needed by the builder – the Summary of Business data already shows which
  plans are sold.

### 13.2 `DB/CropInsurance_US.xml` format

```xml
<cropInsurance version="1" source="USDA RMA Summary of Business" years="2020-2024" currency="USD">
    <region id="US" name="United States">
        <crop fillType="WHEAT" rma="Wheat">
            <plan id="RP">
                <level coverage="0.75" premiumRate="0.169" farmerRate="0.0536" subsidyShare="0.683"
                       lossRatio="0.941" claimShare="0.391" farmerPerAcre="13.56" acres="64812078" policies="201816"/>
                ...
            </plan>
            ...
        </crop>
        <crop fillType="SPINACH" borrowedFrom="POTATO"/>
        <crop fillType="DEFAULT" rma="all field crops"> ... </crop>
    </region>
    <region id="US_KS" name="Kansas" parent="US">
        <crop fillType="WHEAT" rateFactor="1.065" lossRatio="1.071" acres="32529453"/>
        ...
    </region>
</cropInsurance>
```

`claimShare` (share of policies with a payout in a year) can drive how often the adjuster finds a
payable loss in balancing tests; it is not used for gameplay decisions directly.

**Smoothing:** in the raw national averages the premium rate often *falls* at high coverage (low-risk
farms choose high coverage – selection bias), which would make 80 % cover cheaper per acre than 70 %.
The builder smooths every curve to the closest non-decreasing curve with the same liability-weighted
average (weighted pool-adjacent-violators). `premiumRate` and `farmerRate` therefore never fall as
coverage rises; `subsidyShare` is derived from them. `lossRatio`, `claimShare` and `farmerPerAcre`
stay raw.

### 13.3 Canada: `DB/CropInsurance_CA.xml`

Canadian AgriInsurance is provincial and publishes programme totals, not per-crop rates. The builder's
`CANADA` section turns a few published numbers into curves:

| Item | Value | Source |
|---|---|---|
| Plan | Yield cover only (written as `YP`) | SCIC / AFSC programme pages |
| Coverage levels | 50 / 60 / 70 / 80 % (potatoes, soybeans, grain corn, green beans max 70 %) | SCIC |
| Producer share | 40 % flat (federal 36 %, provincial 24 %) | SCIC annual report 2024-25 p. 33 / 63 |
| Average total rate | 8.08 % of liability, crop years 2020-21 – 2024-25 | SCIC p. 69 |
| Coverage mix (calibration) | 50 %: 6.8 %, 60 %: 5.6 %, 70 %: 33.6 %, 80 %: 54.8 % of acres | SCIC p. 62 |
| Loss ratio | 1.46 (5 years, 2021 drought), 0.95 (10 years) | SCIC p. 69 |
| Curve shape | US YP curves (APH for crops without YP) × the neighbouring US state's rateFactor (AB←MT, SK←ND, MB←MN, ON←MI, QC←NY) | RMA |
| Level | one calibration factor (×0.674) so Saskatchewan's acre-weighted average at its coverage mix equals 8.08 %; used for all provinces | builder |
| Hail-only (Alberta) | `hailPolicy`: full-cover rate 3–14 % (typical 6 %), 10 % deductible ×0.75, 25 % ×0.5 | AFSC 2026 Full Cover Hail rates |

Region ids match the climate file (`CAN`, `CAN_AB`, `CAN_SK`, …). `CAN` uses the Saskatchewan curves
(the largest programme). Other provinces have no published totals yet: they share Saskatchewan's
calibration. Raw PDFs live in `CA_insurance/` (never shipped).

**Reuse terms:**
- **AFSC** (https://afsc.ca/disclaimer/): non-commercial reproduction allowed if the materials are not
  modified, AFSC is named as the source, and the use is not presented as official or AFSC-endorsed. Only
  published figures are used (the hail rate range and deductible factors, unchanged); `rateTypical` is our
  own estimate and is marked `rateTypicalIsEstimate="true"`.
- **SCIC:** no reuse terms on scic.ca (only a privacy statement). SCIC is a Crown corporation of the
  Government of Saskatchewan, whose copyright page (https://www.saskatchewan.ca/copyright) allows
  non-commercial reproduction if reproduced accurately, not represented as an official version, and
  acknowledged as "© 2026, Government of Saskatchewan" (no government logos). Whether this covers SCIC's own
  publications is not stated; only published figures are used. For certainty: ask SCIC
  (customer.service@scic.ca) or the King's Printer (publications@gov.sk.ca).
- **Credit text when shipping** (modDesc + README): *"Alberta hail insurance rates from Agriculture
  Financial Services Corporation (AFSC), 2026 Full Cover Hail Insurance premium rates. Saskatchewan crop
  insurance figures from the Saskatchewan Crop Insurance Corporation (SCIC) 2024-25 annual report. Used for
  a free, non-commercial mod; not an official version and not affiliated with or endorsed by AFSC or SCIC.
  SCIC figures © 2026, Government of Saskatchewan."*

## 14. Multiplayer

- All decisions, billing and payouts run on the **server**.
- Policy changes: client → server request event (`TornadoInsuranceActionEvent`), validated against
  the farm-manager / admin rule.
- State for clients: server → client events for each farm's policy state, claims and inbox
  (only to that farm: `g_currentMission:broadcastEventToFarm`).
- Joining players get their farm's state in `TornadoSync:sendInitialState`.
- Messages use key + parameters (`TornadoSync:sendMessage`) so each player reads them in their own
  language and currency.

## 15. Integration with existing modules

| Module | Use |
|---|---|
| `TornadoPhysics` | Damage-zone check → value snapshot trigger. |
| `TornadoDestruction` | Destroyed nodes → repair estimate; restore on repair. |
| `TornadoRecovery` | Repair cost formula; recovery bill is covered by an approved claim. |
| `TornadoWeather` / climate hail | Hail events → crop hail claims. |
| `TornadoOutbreak` | Blocks new policies during an outbreak. |
| `TornadoSync`, `TornadoText`, `TornadoSettings`, `TornadoPersistence` | Sync, translations, settings, savegame. |
| Base game `Twister`, `WeatherObjectHail` | Crop destruction (already done by the game); hook only to log the path. |
| Base game `Vehicle.getSellPrice` | Value snapshot; branded-title price reduction. |
| Base game `MoneyType` | Register own money types for the finance page via `MoneyType.register(name, l10nKey)`, e.g. *Insurance premiums* and *Insurance payouts*. |

**Later:** buildings / placeables (only if the destruction module ever damages them).

## 16. Open questions

1. Rebuilt-title value penalty default: real-life ~20–40 % vs. the author's −50 % to −75 %.
2. Insurance crop price: best sell-point price or average across sell points?
3. Expected yield: game standard yield (simple) or the farm's own harvest history (realistic, needs
   history tracking and a default for new fields)?
4. Damage sampling method for crops (§4.1 option 1 vs. 2) – needs a prototype for accuracy and cost.
5. Does a write-off require the player to clear the field before replanting, or is that left to them?
6. Equipment policy: all vehicles (simple) or per-vehicle opt-in (more control, more UI)?
7. What happens to open claims when a farm is deleted or a vehicle is sold before the decision?

## 17. Real-life references to verify before release

- USDA RMA – YP/RP/RPHPE rules, projected/harvest price and the 200 % harvest-price cap, sales
  closing dates. (Coverage levels, premium rates and subsidy shares: **confirmed** from the Summary of
  Business data.)
- Typical crop-hail policy waiting periods.
- Typical equipment insurance rates and deductibles.
- Total-loss thresholds and rebuilt-title resale values.

## 18. Implementation phases

1. **Crop damage measurement** (prototype the sampling, §4.1) – useful on its own: a "storm damage
   report" per field even without insurance.
2. **Equipment insurance** – snapshot, claims, total loss, buy-back, branded titles, removal toggle.
   Builds directly on Destruction / Recovery; no external data needed.
3. **Crop insurance** – ~~RMA data builder~~ (done), YP/RPHPE/RP/APH, price locking, cap, volatility
   premiums, write-off.
4. **UI polish** – inbox, charts, premium history, no-claims discount.

## 19. Rules for the implementation

- No `pcall` / `xpcall` (GIANTS ModHub rule) – explicit nil checks only.
- Hooks on persistent classes (`Vehicle`, `Twister`, …) are added once, with a guard flag.
- Console and log output in English; all player-visible text through the translation files.
- Never ship base-game or DLC files; reference only.
- Module OFF by default; with it OFF, nothing is hooked into money or vehicle prices.
