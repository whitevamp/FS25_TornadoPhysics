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

All policies are **per farm**. Who may buy, change, renew or cancel them is a setting (§12, "Policy
managers"): **farm manager + server admin** (default – `Farm:isUserFarmManager`, the same rule as other
farm-finance actions) or **server admin only** (for servers that want the admin to run insurance).

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

### 6.3 Group (co-op) policies and renewal bonus

Real model: Spain's *contratación colectiva* – a cooperative or farmers' organisation takes out the
policy and its members join under it; each member gets **+6 points** of subsidy. Each member still has
its own fields, own claims and own payouts; the group is administrative, not a shared risk pool.

**In the mod (multiplayer):**
- A farm creates a **co-op group** for a crop policy; other farms join it. Joining needs the consent of
  each joining farm (its policy manager, see §6).
- Members get the **group discount** while the group has at least `Minimum members` farms (default 2).
  Mode setting: **flat** (default, like Spain: every member gets the same discount) or **per member**
  (discount grows by a step for every extra farm, up to a cap – an optional "more neighbours, cheaper"
  rule).
- Claims, payouts, deductibles and inbox messages stay **per farm**.
- Joining / leaving takes effect at the **next policy year** (no joining after a storm warning). A deleted
  farm leaves at once; if fewer than the minimum remain, the others fall back to the individual price at
  the next renewal (inbox message).

**Single player:** the same discount through a **local co-op membership** (toggle per farm) with a small
yearly membership fee, so single-player farms get the "group" price without other players.

**Renewal (continuity) bonus:** renewing the same cover without a gap gives a small discount (Spain:
+5 points, +7 for herbaceous crops, olive, vine and forage). Lost after a year without the cover.

**Per country:** Spain uses its real values (group +6, continuity +5 / +7). The other countries have no
real equivalent, so they use the setting defaults; the data files can carry their own `groupDiscount` /
`continuityDiscount` later if a real one is found.

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
  as coverage rises. Raw US 2020–2024 averages (the XML curves are shaped, see §13.2):

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
| Policy managers | farm manager + admin / admin only | Server |
| Group (co-op) policies | ON | Server |
| Group discount | country value (Spain 6 points), else 5 % | Server |
| Group discount mode | flat / per member (step 1 %, cap 10 %) | Server |
| Group minimum members | 2 | Server |
| Local co-op membership (single player) | ON, fee to decide | Server |
| Continuity (renewal) bonus | country value (Spain 5 / 7 points), else 3 % | Server |
| Insurance region | Auto (detection §13.16) / any profile or sub-region | Server |

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
  Canada: §13.3. Poland: §13.4. Brazil: §13.5. Germany: §13.6. France: §13.7. Netherlands: §13.8. Spain: §13.9. Italy: §13.10. Australia: §13.11. Argentina: §13.12. Chile: §13.13. United Kingdom: §13.14. South-East Asia: §13.15. Region detection: §13.16.

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

**Curve shape:** in the raw averages the premium rate *falls* at high coverage (low-risk farms choose
high coverage – selection bias), while the loss ratio of those policies climbs. Smoothing alone (the first
version, weighted pool-adjacent-violators) left the curves flat above ~65 – 70 %, so higher coverage cost
nothing extra and every player would pick the top level. The builder now shapes every curve
(`shaped_rates`, all countries; plans carry `shape="lossModel" shapeCv="0.3"`):
- `premiumRate` = the curve's liability-weighted average, spread over the levels by a yield-loss model
  (`coverage_shape`: yield ~ Normal(1, 0.30), rate = expected shortfall below the guarantee ÷ guarantee).
  Relative to 65 %: 50 % ≈ 0.43×, 70 % ≈ 1.3×, 75 % ≈ 1.6×, 80 % ≈ 2.0×, 85 % ≈ 2.5×.
- `farmerRate` = `premiumRate` × (1 − the measured subsidy share at that level) – the subsidy share is set
  per level by law and is kept as measured.
- `lossRatio`, `claimShare` and `farmerPerAcre` stay raw.

Example, US soybean YP: 50 % 1.80 %, 65 % 4.19 %, 80 % 8.56 %, 85 % 10.54 % premium rate (farmer 0.44 %,
1.54 %, 3.61 %, 5.82 %) – the flat smoothed curve was 5.82 % from 65 % to 85 %.

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
| Level | one calibration factor (×0.574) so Saskatchewan's acre-weighted average at its coverage mix equals 8.08 %; used for all provinces | builder |
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

### 13.4 Poland: `DB/CropInsurance_PL.xml`

Polish crop insurance is sold by private insurers as state-subsidised **named-peril** policies (no yield
guarantee or coverage levels). The law sets the rules; no average rate per crop is published. The builder's
`POLAND` section (needs no RMA data):

| Item | Value | Source |
|---|---|---|
| Plan | `namedPeril`: mandatory package hail, spring frost, winter kill, flood, drought (farmer picks ≥ 1); optional windstorm ("huragan", the tornado peril), torrential rain, lightning, landslide, avalanche | Ustawa z 7.07.2005 (Dz.U. 2025 poz. 251) |
| Subsidy | 65 % of the premium | gov.pl, 2026 subsidy rules |
| Rate cap | full subsidy only up to 9 % of the sum insured (field crops), 20 % (fruit, strawberries), 0.5 % (animals); above it the subsidy is 65 % of the capped premium. Soil classes V / VI (12 / 15 %) not used | gov.pl "Określenie stawek taryfowych" |
| Max sum insured | 2026, PLN / ha: cereals 16 300, maize 12 700, rapeseed 13 000, sunflower 6 300, potatoes 63 100, sugar beet 20 600, legumes 23 100, vegetables 340 500, fruit 171 900 (Dz.U. 2025 poz. 1628); per animal 2025 (cattle 16 000, pigs 2 900 …, Dz.U. 2024 poz. 1695). Converted at 4.25 PLN/EUR | regulations |
| Obligation | insure ≥ 50 % of the crop area against ≥ 1 mandatory peril or pay ~2 EUR/ha — optional rule, off by default | Ustawa |
| Rates | package / hail-only rate per crop group, windstorm and drought add-ons, deductible options 0 / 10 / 20 % — **estimates** (`isEstimate="true"`) of the relative cost | builder |
| Calibration | package rates ×1.42 so the area-weighted average is **3.82 %**: 2024 subsidy paid ~629 M PLN, 3.8 M ha + 20.5 M animals insured; estimated 90 % of it for crops and ~6 000 PLN/ha sum insured (`averageRateIsEstimate="true"`) | MRiRW via wiescirolnicze.pl / farmer.pl |

Crops without an own group borrow one (`borrowed="true"`: sorghum → cereals, grape → fruit). Cotton, rice, sugarcane, olives and forage grass are not insured in Poland (DEFAULT =
cereals). Region id `POL` (ISO-3 like `CAN` / `AUS`). Polish legal acts are not protected by copyright
(Prawo autorskie art. 4); credit the sources anyway: *"Polish crop insurance rules from the Act on crop and
livestock insurance and the Ministry of Agriculture and Rural Development (gov.pl). Rates are estimates,
not official figures."*

KNF statistics do not help here: crop insurance is part of non-life group 8 ("damage caused by natural
forces"), which also holds home and business property (~6.6 bn PLN premium in 2024). A better average needs
the total premium and sum insured of subsidised crop policies (MRiRW / ARiMR, not found published).

### 13.6 Germany: `DB/CropInsurance_DE.xml`

German crop insurance is private with **no federal subsidy**. Hail cover is bought by most farms (well over
60 % of the arable area, UBA indicator LW-I-3); drought is almost never insured (~0.02 % of the area). Some
states pay up to 50 % of multi-peril premiums. No rates are published; the builder's `GERMANY` section:

| Item | Value | Source |
|---|---|---|
| Plan | hail cover (`basePeril="HAIL"`) + add-ons windstorm, heavy rain, severe frost (frost + winter kill), drought; multi-peril package = all five | insurers (Vereinigte Hagel product range) |
| Insurance tax | 0.03 % of the sum insured per year (hail, storm, heavy rain, severe frost) | DLG-Merkblatt 434 |
| Bavaria (`DEU_BY`, since 2023) | up to 50 %; packages arable (hail, storm, heavy rain, severe frost, drought, bird damage – no choice), grassland (hail, drought, grubs), fruit / wine / hops (≥ 2 of hail, severe frost, storm, heavy rain); deductible ≥ 20 %, payout ≤ 80 %, max sums 5 000 €/ha arable, 15 000 root crops, 3 000 grassland, 30 000 fruit / wine; max 99 999 € per farm | StMELF Merkblatt MGV 2026 |
| Baden-Württemberg (`DEU_BW`, hail + hops from 2026) | up to 50 %, fruit / wine / hops, ≥ 2 of hail, frost, storm, heavy rain | Vereinigte Hagel |
| Lower Saxony (`DEU_NI`, since 2025, also HH / HB) | up to 50 %, max 25 000 € per farm, storm, heavy rain, severe frost, drought (**hail not subsidised**) | Vereinigte Hagel |
| Saxony (`DEU_SN`) | up to 50 %, wine | Vereinigte Hagel |
| Rates, sums insured | per crop group, **estimates**; hail rates ×0.769 so the area-weighted premium is **31.67 €/ha** = Vereinigte Hagel Germany 2022 (155.49 M € / 4.91 M ha). Drought 5 % (index cover costs 3 – 10 %) | agrarheute, topagrar, builder |

Market check (Vereinigte Hagel SFCR 2024): Germany 151.8 M € premium, 147.7 M € claims (loss ratio 97.3 %,
frost year), 2023 claims 128.5 M €. No per-state hail risk yet (`rateFactor` 1 everywhere) – the climate
files have no German regions.

**Credit text:** *"German crop insurance rules from the Bavarian State Ministry (StMELF) and the state
programmes of Baden-Württemberg, Lower Saxony and Saxony; market figures from published Vereinigte Hagel
reports; insurance tax from DLG-Merkblatt 434. Rates are estimates, not official figures; not affiliated with
or endorsed by any of them."*

### 13.7 France: `DB/CropInsurance_FR.xml`

Since the 2023 reform (loi n° 2022-298) France runs **three tiers**: small losses stay with the farmer,
a subsidised multi-risk policy (MRC) covers the middle, and **national solidarity (ISN)** pays above a
threshold – the whole loss for insured farms (state 90 % + insurer 10 %), a falling share for uninsured
ones. A good fit for an optional "state disaster aid" rule. The builder's `FRANCE` section:

| Item | Value | Source |
|---|---|---|
| Plan | `multiRisk`: ≥ 17 climatic perils (drought, heat, frost, excess water, hail, storm, whirlwind …); hail-only / hail + storm cover is **not** subsidised (`hailOnly`) | agriculture.gouv.fr FAQ 2026 |
| Subsidy | 70 % of the premium | same |
| Franchise (deductible) | 20 % minimum, up to 25 / 40 % by crop group; rate factors 1 / 0.8 / 0.63 / 0.37 for 20 / 25 / 30 / 40 % from the loss model (§13.2) | same + builder |
| Insured yield | 70 – 100 % of the historical yield (olympic average of 5 years, or average of 3) | same |
| ISN thresholds | 50 % field crops, vegetables, vine; 30 % orchards, grassland | same |
| ISN uninsured rates | field crops 28 / 21 / 14 % (2026 / 27 / 28); vine, vegetables, orchards, grassland 31.5 / 28 / 24.5 % (grassland: ministry table ambiguous, press gives 31.5 % for 2026) | same, echangesassurances.org |
| Insured area | field crops 31.1 → 36.6 %, vine 31.2 → 36.8 %, orchards 1.5 → 14.4 %, grassland 0.5 → 9.1 % (2022 → 2024) | Assemblée nationale, Jan. 2026 |
| Rates | anchored on cereals 2.7 % and orchards 14.8 % of the sum insured (La France Agricole, pre-reform), other groups **estimates**; ×1.412 so the total equals the 2024 subsidised premium (365.8 M € aid ÷ 70 % = 523 M €) over the insured area (sector areas = rounded estimates). Wheat 3.8 %, vine 7.1 %, orchards 20.9 % | builder |

**Credit text:** *"French crop insurance rules from the Ministère de l'Agriculture et de la Souveraineté
alimentaire (agriculture.gouv.fr); figures from the Assemblée nationale (commission des affaires économiques,
January 2026) and La France Agricole. Rates are estimates, not official figures; not affiliated with or
endorsed by any of them."*

### 13.8 Netherlands: `DB/CropInsurance_NL.xml`

The **brede weersverzekering** (broad weather insurance, BWV) is a subsidised multi-peril policy; hail-only
cover is sold unsubsidised (and pays the 21 % insurance tax). The subsidy comes from a **fixed pool**: if
more premium is applied for than the budget covers, every farmer's share is cut pro rata – a possible
gameplay rule ("subsidy pool ran dry", share known only after the season).

| Item | Value | Source |
|---|---|---|
| Plan | `multiRisk`: hail, rain, (night) frost, storm, drought, snow, freezing rain, lightning fire; pays only above a **20 %** loss of the average production (30 % before 2018) | RVO 2025 / 2026 |
| Subsidy | max **63.7 %** (EU 70 % of premium + tax, minus the 21 % tax exemption since 2020); budget **€17.5 M**, not indexed, pro-rata cut | RVO, evaluation |
| Actual share | 65 % (2015) … 63.7 % (2020), 60.4 % (2021), 54.5 % (2022), 53.2 % (2023), **46.3 % (2025)**; premium €12.0 M (2015) → €32.9 M (2023) → ~€37.8 M (2025) – full table in the XML | evaluation table 1, RVO |
| Insurer rule | 5-year cumulative loss ratio must stay ≥ 0.5 | evaluation |
| Uptake | 2 450 farms in 2022 (~15 % of farms with a weather-sensitive main crop); ~1/3 of arable area, ~60 % of apple / pear area | evaluation |
| Rates | per crop group, **estimates** inside Agriver's published 4 – 8 % of the insured value (fruit 8 %); hail-only 0.3 – 3 %. No insured-area total is published, so no calibration | Agriver, builder |

**Credit text:** *"Dutch crop insurance rules and subsidy figures from RVO (Rijksdienst voor Ondernemend
Nederland) and the 2024 Ecorys / WUR evaluation of the Subsidieregeling Brede Weersverzekering; premium
range from Agriver. Rates are estimates, not official figures; not affiliated with or endorsed by any of
them."*

### 13.9 Spain: `DB/CropInsurance_ES.xml`

Spanish crop insurance is sold through one pool (**Agroseguro**) under a yearly state plan; **ENESA** and the
regions pay part of the premium. Instead of coverage levels, farmers pick a **module**. The builder's
`SPAIN` section:

| Item | Value | Source |
|---|---|---|
| Modules | `1` whole farm, catastrophic only (single **75 %** subsidy); `2` all climatic risks per plot; `P` named perils (hail, fire …). Module rate factors 1 = 0.7, 2 = 1.0, P = 0.35 × (**estimates**; bananas sell P as their full cover, factor 1) | 47th plan, BOE-A-2025-27098 |
| Base subsidy (2026) | herbaceous crops 22 % (module 2) / 5 % (P; rice and beans 8 %); olive 22 / 8; wine grape 22 (SB+GA1 31) / 8; fruit, citrus, vegetables, industrial, forage 20 / 8; bananas P 25 % | same, Anexo I |
| Additional | young farmer +29 (P +27, herbaceous P +22.5); professional / priority farm +19 (17 / 12.5); collective +6; continuity +5 (+7 herbaceous, olive, vine, forage); new contract +3; shared ownership +5; risk practices +2; instalments +1. Module 2 floors: professionals ≥ 50 %, young ≥ 45 % in total | same |
| Limits | ENESA + regions ≤ **75 %**; rates above 20 % subsidised only up to 20 %; €60 fixed deduction per farmer; Canary Islands base × 1.65 | same |
| Modulation | withhold 10 % of the subsidy up to €5 000, 25 % (5 – 10 k), 35 % (10 – 20 k), 45 % (20 – 30 k), 50 % above €30 000; not for associations, the producer-organisation fixed-cost line, or farms wholly in the Canaries | same |
| History 2014 – 2023 | premium €586 M → €967 M, subsidy €241 M → €486 M (50.25 %), sum insured €11.1 bn → €16.7 bn, claims €497 M → €1 241 M (all lines) | Agroseguro "Sistema español …" 2024 |
| Claims by cause (2023, agricultural) | drought / no emergence 42.5 %, hail 27 %, other 10.8 %, rain / flood 7.3 %, wind 5.6 %, frost 5.0 %, poor fruit set 1.6 % | same |
| Rates | per crop group, **estimates**, ×0.952 so the capital-weighted average is **6.25 %** = 2024 group A + B premium (€935 M, minus an estimated 10 % livestock) ÷ agricultural sum insured (74.08 % of €18.17 bn). Wheat module 2 3.8 %, wine grape 7.6 %, bananas 7.6 % | Agroseguro annual report 2024, builder |

Regional (comunidad autónoma) top-ups are not modelled one by one – they only fill the gap up to the 75 % cap.

**Credit text:** *"Spanish crop insurance rules from the 47th Plan de Seguros Agrarios Combinados (BOE) and
ENESA; figures from Agroseguro's annual report 2024 and 'Sistema español de Seguros Agrarios Combinados'.
Rates are estimates, not official figures; not affiliated with or endorsed by ENESA or Agroseguro."*

### 13.10 Italy: `DB/CropInsurance_IT.xml`

Italian subsidised policies (*assicurazioni agevolate*) follow the yearly **PGRA** (MASAF). The farmer
builds the policy from **peril groups** – catastrophic (flood, drought, frost), frequency (snow, heavy
rain, hail, strong wind), accessory (hot wind / sunburn, temperature swing) – into one of six types. The
**AgriCat** fund (financed from direct payments) pays catastrophic losses on top, also for uninsured farms.

| Item | Value | Source |
|---|---|---|
| Policy types | a all risk, b catastrophic + ≥ 1 frequency, c frequency (≥ 3 perils), d catastrophic only: up to **70 %**; c with 1 – 2 frequency perils **65 %** (new 2026); f SMART simplified (quantitative loss only, ~50 % cheaper) fixed 70 %. Damage threshold **20 %** for all. Rate factors vs. type a (1 / 0.85 / 0.6 / 0.45 / 0.4 / 0.5) are **estimates** | PGRA 2026 (DM 22/12/2025), via Codima; ISMEA (SMART) |
| AgriCat | uninsured or frequency-only farms: 20 % franchise, max 55 % indemnity, loss > 20 % of average production; with a catastrophic policy (franchise ≥ 40 %, limit ≥ 80 %) the fund adds franchise 10 % / limit 40 %; 2026 budget ~€253 M | same |
| Budget 2026 | ~€300 M for subsidised policies | same |
| 2025 totals | crops €7.09 bn insured (all €9.94 bn), 1 222 985 ha, 57 047 farms, average rate **8.95 %**; North 80 % of value; package C ~2/3 | ISMEA via Terra e Vita / Askanews |
| Main crops | wine grape > €2 bn, rice €732 M, processing tomato €728 M, apples €535 M | same |
| Rates | all-risk rate per crop group, **estimates**, ×1.497 so the value-weighted average of the sold mix (2/3 type c, 1/3 types a / b) equals 8.95 %. Wheat / rice 7.5 %, vine 15 %, fruit 21 % (all risk) | builder |

**Credit text:** *"Italian crop insurance rules from the Piano di gestione dei rischi in agricoltura 2026
(MASAF); figures from ISMEA. Rates are estimates, not official figures; not affiliated with or endorsed by
MASAF or ISMEA."*

### 13.11 Australia: `DB/CropInsurance_AU.xml`

Australia has **no government crop insurance and no premium subsidy**. Farmers buy private **named-peril**
cover – mostly hail and fire (sometimes frost); one broker puts 90 % of broadacre claims down to hail.
Multi-peril cover has been tried several times (e.g. the 1999–2000 CBH / AON scheme in WA, dropped after
one year for low demand) and remains rare. The builder's `AUSTRALIA` section:

| Item | Value | Source |
|---|---|---|
| Plan | `namedPeril` hail + fire (frost optional); `multiPeril` only for some grain crops (`multiPeril="limited"`) | ABARES 2012, brokers |
| Rate ranges | named peril **0.55 – 3.5 %**, multi-peril **5 – 10 %** of the crop value | Deloitte |
| Taxes | **GST 10 %** on every premium + state stamp duty: NSW 9 %, VIC 10 %, QLD 9 %, SA 11 %, WA 10 %, TAS 10 %, NT 10 %, ACT 0 % | Insurance Council of Australia (2019) |
| Crop exemptions | NSW from 1 Jan 2018, VIC from 1 Jul 2017 (Duties Act 2000 s.196) – no stamp duty on crop insurance. VIC: an older report says oilseed / legume hail cover still paid the full rate – unclear, treated as exempt | Revenue NSW / Allianz, SRO Victoria |
| Rates | per crop group, **estimates** inside the ranges: cereals 1.5 %, canola / pulses 2.5 %, cotton 2 %, sugarcane 0.6 % (fire), vine / fruit 3.5 %; multi-peril 7 – 9 % for grains | builder |

No market totals are published, so there is no calibration. No per-state risk factor yet: the obvious source
(hail frequency in `DB/TornadoClimate_AU.xml`) is BoM data that is not cleared to ship, so it is **not** used.
Region ids match the climate file (`AUS`, `AUS_NSW` …).

**Credit text:** *"Australian insurance duty rates from the Insurance Council of Australia; crop exemptions
from Revenue NSW and the State Revenue Office Victoria; premium ranges from Deloitte; market overview from
ABARES. Rates are estimates, not official figures; not affiliated with or endorsed by any of them."*

### 13.12 Argentina: `DB/CropInsurance_AR.xml`

Private market, **no national subsidy**. Hail cover dominates; two provinces run their own schemes.

| Item | Value | Source |
|---|---|---|
| Covers (share of premiums) | hail **66.6 %**, hail + additional perils (wind, frost, fire …) 32.3 %, multi-peril 1.1 % | SSN survey 2024 |
| Totals (Jul 2023 – Jun 2024) | premiums ARS 357 152 M, insured capital ARS 9.2 trillion → average rate **3.88 %**; 24 M ha, 188 000 policies; loss ratio 88.9 % (2023 ~103 %), combined ratio 121.5 %. Soybean 8.1 M ha, ARS 204 000 M premiums (~57 %) | SSN via 100% Seguro, El Seguro en Acción |
| Province factors | `rateFactor` = premium share ÷ capital share: Buenos Aires 0.848 (36.7 / 43.3 %), Santa Fe 0.926 (20 / 21.6 %), Córdoba **1.36** (31 % premiums; capital share derived ≈ 22.8 %, estimate) – Córdoba is the hail hot spot | same |
| Mendoza | *Fondo Compensador Agrícola*: hail + frost, farms ≤ 30 ha, province pays ~80 % of the premium (an older official page says 100 %); total hail loss pays ARS 2 000 000 / ha (2025-26) | Los Andes, Infocampo, contingencias.mendoza.gov.ar |
| Córdoba | free multi-peril pilot (seven perils incl. drought, frost) on 550 000 ha of soybean / maize; 2025/26 ARS 276 M paid to 22 farms | Cadena 3, Infocampo |
| Rates | hail per crop group, **estimates** (soybean 4.0 %, maize 3.0 %, wheat 3.5 %, vine / fruit 8 %), hail + extras ×1.25, multi-peril 8 %; calibration ×0.999 to 3.88 % (sold mix). Sums insured in **USD** (Argentine crop prices are quoted in dollars; the peso figures only set the average rate) | builder |

**Credit text:** *"Argentine crop insurance figures from the Superintendencia de Seguros de la Nación (SSN),
Encuesta de Seguros en los Sectores Agropecuario y Forestal 2024; provincial schemes from the governments of
Mendoza and Córdoba. Rates are estimates, not official figures; not affiliated with or endorsed by any of
them."*

### 13.13 Chile: `DB/CropInsurance_CL.xml`

State-subsidised named-peril cover through **Agroseguros** (Comité de Seguros del Agro, Ministry of
Agriculture). Amounts are in **UF** (*unidad de fomento*, inflation-indexed, ISO code CLF).

| Item | Value | Source |
|---|---|---|
| Perils | drought (**rain-fed land only**), excessive / untimely rain, frost, wind, hail, snow | ChileAtiende |
| Subsidy | **40 %** of the net premium **+ 1 UF per policy**; caps 80 UF per policy, 80 UF per crop and commune, 160 UF per farmer and year; max 98 % of the net premium (usually 40 – 69 %) | ChileAtiende, Agroseguros |
| Bonuses (stackable) | renewal +2 – 10 %, collective +4 %, small policy (insured ≤ 1 000 UF) +5 %, cereals +5 %, extreme zones +5 % | same |
| Small farmers | without a tax start but with INDAP / BancoEstado credit: insured value ≤ 250 UF per season; INDAP adds a complementary subsidy (amount not published) | same |
| Uptake | 2.8 % of the sown area, < 7 % of farms (2023); average cost ~7.2 UF/ha | DIPRES evaluation |
| Rates | per crop group, **estimates** inside the published examples: 4.3 % (example), fruit 5.2 % (2014) – 2.6 % (2017); cereals 4.5 %, maize 3.5 %, fruit 4 %. No calibration | Mundoagro, Ministry of Agriculture |

Rain-fed vs. irrigated matters for the game: drought is only insurable on fields without irrigation.

**Credit text:** *"Chilean crop insurance rules from Agroseguros (Comité de Seguros del Agro) and ChileAtiende;
figures from DIPRES and the Ministerio de Agricultura. Rates are estimates, not official figures; not
affiliated with or endorsed by any of them."*

### 13.14 United Kingdom: `DB/CropInsurance_GB.xml`

**No public support**; growers buy private hail cover, fire is usually part of the farm policy, multi-peril
cover is rare. 11 ModHub maps plus the Highlands Fishing DLC (Scotland) – see `docs/MAP_SURVEY.md`.

| Item | Value | Source |
|---|---|---|
| Plan | `namedPeril` hail + fire (storm optional), `multiPeril="rare"` | NI Assembly research paper |
| Tax | **Insurance Premium Tax 12 %** of the premium | HMRC |
| Rate level | ~**1 %** of the insured value (UK and Germany; Spain / Portugal / Italy 6 – 8 %) | NI Assembly research paper |
| Rate shape | oilseed rape several times the cereal rate per acre (pods shatter) | Farmers Weekly (1990s – ratio only) |
| Rates | per crop group, **estimates**: cereals 0.6 %, rape 2 %, pulses 1.5 %, potatoes 1 %, sugar beet 0.5 %, top fruit 4 %; area-weighted check ≈ 1.1 % | builder |

One region `GBR` (England, Scotland, Wales, Northern Ireland – no published regional differences).

**Credit text:** *"UK crop insurance figures from the Northern Ireland Assembly research paper 'Agricultural
insurance' and Farmers Weekly; Insurance Premium Tax from HMRC. Rates are estimates, not official figures; not
affiliated with or endorsed by any of them."*

### 13.15 South-East Asia: `DB/CropInsurance_SEA.xml` (Hutan Pantai)

For the base-game map **Hutan Pantai** (fictional South-East Asia). Two real **state rice schemes** as
profiles; region `SEA` defaults to Indonesia. Both have a fixed premium and sum insured per hectare and
season, so no rate tables are needed.

| Item | Indonesia – AUTP (default) | Malaysia – Skim Takaful Tanaman Padi |
|---|---|---|
| Premium | Rp 180 000 / ha / season | RM 120 / ha / year (two seasons → RM 60 / season) |
| Subsidy | government **80 %** (farmer pays Rp 36 000) | government pays **100 %** in the first year |
| Sum insured | Rp 6 000 000 / ha / season → rate **3 %** | up to RM 3 000 / ha / season (natural disasters), RM 1 500 (pests / diseases) → **2 %** |
| Perils | pests and diseases, flood, drought | flood (natural disasters), pests / diseases; drought not confirmed |
| Claim threshold | commonly stated ≥ 75 % damage – **not confirmed** (`damageThresholdIsEstimate`) | – |
| Scale | ~305 000 ha insured in 2024; uptake low, compulsory cover under discussion | from Sept 2024; Selangor: 330 of 9 000+ farmers registered (Nov 2024) |
| Sources | Jasindo via Kontan, IDX Channel, Investortrust | Bernama, New Straits Times, The Star |

Only rice is covered; every other crop has no state scheme and borrows the rice terms
(`borrowedFrom="RICE" noStateScheme="true"`) – a setting could instead mark them "not insurable".

**Credit text:** *"Indonesian rice insurance (AUTP) figures from the Ministry of Agriculture and PT Asuransi
Jasa Indonesia (Jasindo); Malaysian padi crop takaful figures from Agrobank and the Ministry of Agriculture
and Food Security (KPKM), as reported by the press. Not affiliated with or endorsed by any of them."*

### 13.16 Region detection: `DB/InsuranceRegions.xml`

Which country profile a map uses. Generated from the `REGION DETECTION` config and
`tools/map_countries.csv` (284 ModHub maps, survey 2026-10-16). First hit wins:

| Step | Source in game | Result |
|---|---|---|
| 1. Setting | "Insurance region" (Auto / any profile or sub-region), server-owned | that region |
| 2. Known map | `g_mapManager:getMapById(missionInfo.mapId).customEnvironment` (the map's mod name, e.g. `FS25_Nordkirchen`) → `<knownMaps>` | country of that map |
| 3. Base map | `mapId` `MapUS` / `MapEU` / `MapAS` | US / Poland / South-East Asia |
| 4. Keywords | map title + description (`getMapById(...).title / .description`), whole words, longest match wins; plus the sub-region names of the loaded profiles (US states, provinces …) | that country / sub-region |
| 5. Climate | `g_currentMission.environment.xmlFilename` contains `maps/mapUS/` / `maps/mapEU/` / `maps/mapAS/` | US / EU / South-East Asia |
| 6. Default | `default="US"` (most complete, real data) | US |

**Country → profile:** a country with its own file uses it; otherwise `<nearest>` (Austria / Switzerland →
Germany, Ireland → UK, Portugal → Spain, Estonia / Hungary / Romania … → Poland, South Africa → Australia,
fictional European `EU` → Germany, no region `NONE` → default). Survey result: 73 US, 65 German, 27 no-region,
17 French, 17 Polish, 16 Brazilian, 14 UK, 13 fictional-European maps …

**UI:** the settings page shows the detected region and *why* ("Known map: Nordkirchen → Germany",
"Climate: base-game Europe → Germany", "Default → United States") so a wrong guess is easy to fix by hand.
New maps: add a line to `tools/map_countries.csv` and rebuild.

**Implemented (2026-10-16):** `scripts/TornadoRegion.lua` reads the file and runs steps 2 – 6
(`detect()`, `getProfileCountry()`, `getProfileRegion()`, `findLongestName()`, `getStatusText()`); each module
keeps its own manual setting (step 1). The climate module uses it already (`TornadoClimate:detectRegion`):
climate-region name in title / mod name → else the country from `detect()` (the *default* step is ignored, so
unknown maps keep the classic roll) refined to a state / province named in the description.

### 13.5 Brazil: `DB/CropInsurance_BR.xml`

Built from MAPA's **PSR open data** (SISSER, https://dados.agricultura.gov.br/dataset/sisser3, Creative
Commons Attribution): one row per subsidised policy with crop, state, coverage level, area, sum insured,
premium, rate, federal subsidy, indemnity and the **cause of loss**. Years 2020–2024 (the 2025 file has no
claims yet). Raw files in `BR_insurance/` — they contain farmer names and tax ids: git-ignored, never shipped;
the builder never reads those columns and writes totals only.

| Item | Value |
|---|---|
| Plans | `YP` = PRODUTIVIDADE (yield), `COST` = CUSTEIO (financed production cost), `FULL` = 100 % policies (mostly fruit, named-peril style; kept apart). Livestock / forest / parametric / revenue left out |
| Coverage levels | rounded to 5 %; in practice 65 – 85 % |
| Subsidy (measured) | soybeans ~21 %, other crops ~38 – 40 % — matches the rules |
| Program rules | `<program>`: 20 % soy / 40 % others, 30 % / 45 % in the North + Northeast (`northNortheast="true"` on those states), max R$ 60 000 per modality and R$ 120 000 per farmer and year (Plano Trienal 2025-2027) |
| Curve shape | Brazil's average rate per crop and plan, shaped by the yield-loss model of §13.2 (`shape="lossModel"`). The raw rates fall with coverage (selection) while loss ratios climb (soy YP 1.1 at 65 % → 5.9 at 80 %) |
| Perils | per crop `payoutShare` / `claimShare` by cause: drought, hail, frost, excessive rain, **windstorm**, flood/waterspout, temperature, fire, lightning, trellis collapse, other |
| States | `BRA_xx` rateFactor / lossRatio like the US states (21 states with enough data) |
| DLC crops | `COFFEE` (frost 38 % / drought 38 % / hail 12 % / wind 2.5 % of payouts), `BANANA` (`FULL` only, rate 9.7 %; **windstorm 90 %** of payouts) |

Crops with no Brazilian data borrow one: sugar beet → red beet (not grown in Brazil; only if red beet has
data), pea → green bean, spinach / parsnip → carrot, olive → grape.

**Credit text when shipping:** *"Brazilian crop insurance figures from the Ministério da Agricultura e
Pecuária (MAPA), PSR open data (SISSER), licensed under Creative Commons Attribution. Not an official MAPA
product."*

**US / Canada curves:** reshaped with the same loss model (§13.2).

## 14. Multiplayer

- All decisions, billing and payouts run on the **server**.
- Policy changes: client → server request event (`TornadoInsuranceActionEvent`), validated against
  the farm-manager / admin rule.
- State for clients: server → client events for each farm's policy state, claims and inbox
  (only to that farm: `g_currentMission:broadcastEventToFarm`).
- Joining players get their farm's state in `TornadoSync:sendInitialState`.
- Messages use key + parameters (`TornadoSync:sendMessage`) so each player reads them in their own
  language and currency.

- **Group policies:** group state (members, policy, discount) is server-owned and saved with the
  insurance state; every member farm receives the group's state, other farms only its name and size
  (for the "join" list).

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

### 15.1 Optional: FS25_RealisticWeather (Arrow-kb, GPL-3.0)

Compatibility layer like `TornadoADS` (new `scripts/TornadoRealisticWeather.lua`): detect the mod at runtime
and **read / hook** it – no code copied, so Tornado Physics keeps its own licence. The original author
stopped development and allows anyone to continue the mod with credit; a fork (GPL-3.0, own GitHub / ModHub
upload) can add a small public API where hooking is not enough. Checked against the user's local zip
**v1.2.1.0** (the GitHub README still describes 1.1.x – compare before forking).

| What | Where in RealisticWeather | Use for insurance / Tornado Physics |
|---|---|---|
| Detection | `g_modIsLoaded["FS25_RealisticWeather"]` and `g_currentMission.moistureSystem ~= nil` | `isAvailable` flag |
| Soil moisture per cell | `g_currentMission.moistureSystem:getValuesAtCoords(x, z, {"moisture", "retention", "trend", "witherChance"})`, `:getCellsInsidePolygon(polygon, targets)` (field polygons) | cause of a yield loss: drought (low) vs. excess water (high); optional: tornado rain adds moisture via `setValuesAtCoords` (server, sync flag) |
| Yield effect | overwrites `FSBaseMission.getHarvestScaleMultiplier` (moisture factor) | nothing to do: yield-based claims compare the real harvest, so RW's dry / wet losses are paid automatically – moisture only names the cause |
| Crop withering | `RWUtils.witherArea(sx, sz, wx, wz, hx, hz)` called from `MoistureSystem:onHourChanged` | record withered area per field → DROUGHT claim evidence. `RWUtils` lives in RW's mod environment – reachable as `FS25_RealisticWeather.RWUtils` (to verify in game); otherwise the fork publishes an event |
| Crop fires | `g_currentMission.fireSystem` (`fires`, `fieldId`, `startFire(x, z, fieldId)`, `endFire()`), `RWUtils.burnArea(...)`, setting `fireEnabled` | FIRE claims (Australia's main peril); optional: tornado debris / power-line hits may start a fire through `startFire` |
| Droughts / blizzards | `Weather.droughtsEnabled` / `blizzardsEnabled`, current weather `isDraught` / `isBlizzard`, `environment.weather.snowHeight` | drought / snow peril flags in the claim log |
| Flooding | `g_currentMission.puddleSystem` (visual puddles at high moisture) | FLOOD evidence where a country insures it |

**Suggested fork API** (only if hooking proves fragile): an `apiVersion` field on `g_realisticWeather`;
`g_messageCenter` messages `RW_CROP_WITHERED (fieldId, x, z, area, fruitTypeIndex)`, `RW_CROP_BURNED (...)`,
`RW_FIRE_STARTED / RW_FIRE_ENDED (fieldId)`; `getFieldMoisture(fieldId)` (average over the field cells).

**Rules:** server-side only; every call guarded by nil checks (no `pcall` – ModHub rule); all of it optional
(setting "Use RealisticWeather data", default ON when the mod is present).

### 15.2 Own lightweight perils (no extra mod required)

Decision (2026-10-15): the insurance system must work **without** any other mod. Base game + Tornado
Physics already cause hail, tornado and wind losses; drought, field fire and flood need a mechanic of our
own. Write a **small own version, designed from the game mechanics – not from RealisticWeather's code**
(ideas are free to reuse, code is GPL):
- per-field **dry spell / wet spell** state driven by the climate data and the game weather (not a
  full moisture grid), reducing the harvest yield in a mild, setting-controlled way;
- **field fire** risk during hot, dry spells (optionally lit by tornado debris);
- **flood** only as a claim cause on wet-spell fields after heavy rain.

When FS25_RealisticWeather is installed, our own drought / fire / flood mechanics **switch off** (both
change the harvest yield – running both would double the penalty) and §15.1 reads RW's data instead.

**Phase 1 implemented (2026-10-16): drought** – `scripts/TornadoHazards.lua`, OFF by default, mild by default
(user's choices; phases: 1 drought, 2 flood, 3 field fire with the mod's fire FX).
- Soil water (map-wide, 0 – 1, start 0.6) per in-game hour: + rain × 0.04 (+ snow × 0.3 × 0.04); − (0.0010 +
  0.00018 × (T − 5 °C)) × frequency, nothing below 5 °C. Warning < 30 % (again after > 40 %); drought after 2
  days < 20 %; ends > 35 %.
- Each drought day: `FSDensityMapUtil.updateDisasterArea(field:getDensityMapPolygon(), perlin)` on every growing
  field (the hail / twister disaster function: patchy, crop-defined damage, server-side, engine-synced); share
  0.03 × intensity per day up to 0.15 × intensity (max 0.9), perlin = 10000 − share × 10000 (**to calibrate in
  game**); rice spared, grass × 0.5; only with `disasterDestructionState == ENABLED`; skipped when the day's max
  temperature is below 5 °C.
- Event log `{ kind, day, fieldId, farmId, share }` (last 300) + water / dry days / drought day saved in
  `TornadoHazards.xml` (savegame folder) – the insurance claims source. Daily "N of your fields" message per farm.
- Settings `TornadoPhysics.hazards.*` (enabled, drought, intensity, frequency), synced; Modules tab section;
  `t_set hazards`, `t_dev hazards water|drought|damage|end|log`, `t_reset hazards`. Offline test
  `tools/test/test_hazards.lua`. Off while FS25_RealisticWeather is installed. Tested in game 2026-10-16 (OK).

**"Only damage owned fields"** (`ownedOnly`, default OFF, user's request): drought and flood skip fields whose
owner is `FarmlandManager.NO_OWNER_FARM_ID`.

**Phase 2 implemented (2026-10-16): flood** – heavy rain (`getRainFallScale() >= 0.6`) for 3 hours in a row on
soaked soil (water ≥ 85 %) → flood, then 2 days cooldown. "Low" fields: each field's lowest point (terrain height
on a 7 × 7 grid inside the field outline + the centre - not the outline itself, whose corners sit on raised edges /
tracks; cached), fields at or below the 20 % quantile of all fields' lowest points. Tested in game 2026-10-16 (OK;
first version sampled the outline corners and put the circles mid-field - changed to the grid).
Damage: `DensityMapCircle` at that point, radius 0.3 × √area (12 – 70 m), perlin for 50 % × intensity inside the
circle; logged share = inside share × circle / field area. Rice spared. `FLOOD` events, "FLOODING!" alert + per-farm
message, `t_dev hazards flood`, toggle `floodEnabled`. Offline test now 45 checks. Note: a circle near a field edge
can reach a neighbouring field (also low ground) even with "owned only".

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
