#!/usr/bin/env python3
"""
build_crop_insurance.py  -  Tornado Physics crop-insurance data builder
=========================================================================

Reads the USDA Risk Management Agency (RMA) "Summary of Business" files
(State/County/Crop/Coverage Level, 1989 - present, one pipe-delimited text file per year)
and condenses several years into one small XML file (DB/CropInsurance_US.xml) for the
planned insurance module (see docs/INSURANCE_DESIGN.md).

  ~140 MB of raw text (5 years)  ->  roughly 100 KB of XML

The raw files are never shipped with the mod; re-run this script when RMA publishes
a new complete year and ship the regenerated XML.

Requirements: Python 3.8+ and nothing else (standard library only).
Usage:        edit the CONFIG section below, then run
                  python build_crop_insurance.py

Data source:  https://www.rma.usda.gov/tools-reports/summary-of-business/state-county-crop-summary-business
              ("State/County/Crop/Coverage Level 1989 - Present" zip files, US government work, public domain)
Layout:       SOB_State_County_Crop_with_Coverage_Level_1989_Forward (same page)

----------------------------------------------------------------------------
What ends up in the XML
----------------------------------------------------------------------------
  US-wide, per game crop, per plan (RP / RPHPE / YP / APH), per coverage level (50 % - 85 %):
    premiumRate     total premium / liability                  (price of the cover before subsidy)
    farmerRate      farmer-paid premium / liability            (what the player pays, per $ insured)
                    premiumRate keeps the curve's average but rises with coverage by a loss model;
                    farmerRate uses the measured subsidy share per level (see shaped_rates).
    subsidyShare    government + state/private subsidy / total premium
    lossRatio       indemnity / total premium                  (payouts per $ of premium)
    claimShare      policies with a payout / policies earning premium
    farmerPerAcre   farmer-paid premium per acre, US dollars   (raw average, display / sanity checks only)
    acres, policies sample size (summed over all years)

  Per US state, per game crop:
    rateFactor      how expensive cover is in this state compared with the US for the same
                    plans and coverage levels (1.00 = US average). The mod multiplies the US
                    curves by this factor, so thin state data never produces odd curves.
    lossRatio       the state's payouts per $ of premium for that crop

  A "DEFAULT" crop (all field crops together) for crops the table below does not know,
  e.g. crops added by other mods.

Entries with fewer than MIN_ACRES acres or MIN_POLICIES policies (summed over the years)
are left out, so the mod falls back to the US value / the DEFAULT crop.

----------------------------------------------------------------------------
Canada (DB/CropInsurance_CA.xml)
----------------------------------------------------------------------------
Canadian crop insurance (AgriInsurance) is run by each province and does not publish rates per
crop, only programme totals. So the Canadian file is built from a few published numbers (see the
CANADA config section, every number carries its source) plus the US curves:

  * Plan: yield cover only (written as plan "YP") - Canada has no Revenue Protection.
  * Coverage levels 50 / 60 / 70 / 80 % (some crops only up to 70 %).
  * Producer pays a flat 40 % of the premium at every coverage level (60 % government).
  * Shape per crop and coverage level: the US Yield Protection curve (APH for crops without YP),
    times the neighbouring US state's rateFactor for that crop (AB <- MT, SK <- ND, MB <- MN,
    ON <- MI, QC <- NY - the same neighbours the Canadian climate data borrows hail from).
  * Level: one calibration factor so that Saskatchewan's acre-weighted average premium rate at its
    real coverage mix equals SCIC's published 2020-2024 average. The same factor is used for the
    other provinces (they publish no comparable totals yet).
  * Alberta also gets AFSC's straight hail policy (hail-only cover): full-cover rate 3 - 14 % of the
    insured value by township, with 10 % / 25 % deductible options.

----------------------------------------------------------------------------
Poland (DB/CropInsurance_PL.xml)
----------------------------------------------------------------------------
Polish crop insurance is private insurers selling state-subsidised named-peril policies. The law fixes the
rules but no average rates are published per crop, so the file holds (see the POLAND config section):

  * Plan: named-peril yield cover ("namedPeril"). Mandatory package: hail, spring frost, winter kill, flood,
    drought; optional add-ons: windstorm (tornadoes), torrential rain, lightning, landslide, avalanche.
  * Subsidy: 65 % of the premium, paid in full only up to a rate cap (9 % field crops, 20 % fruit,
    0.5 % animals); above the cap the subsidy is 65 % of the capped premium.
  * Maximum sum insured per hectare (2026) / per animal (2025 regulation), in PLN and converted to EUR.
  * Rates per crop group, deductible options: OUR ESTIMATES (isEstimate="true"). The package rates are scaled
    so their area-weighted average equals the average rate implied by the subsidy actually paid in 2024
    (subsidy / 65 % / insured area / an estimated sum insured per ha). Needs no RMA data.

----------------------------------------------------------------------------
Germany (DB/CropInsurance_DE.xml)
----------------------------------------------------------------------------
German crop insurance is private and unsubsidised at federal level: hail cover is bought by most farms
(well over 60 % of the arable area), the other perils are optional add-ons. Some states (Laender) pay up to
50 % of multi-peril premiums. No rates per crop are published, so the file holds (see the GERMANY config):

  * Plan: hail cover ("namedPeril", basePeril HAIL) with add-ons windstorm, heavy rain, severe frost
    (frost + winter kill), drought; and a multi-peril package (all five).
  * Insurance tax: 0.03 % of the sum insured per year for hail / storm / heavy rain / severe frost.
  * State subsidy programmes: Bavaria, Baden-Wuerttemberg, Lower Saxony, Saxony (regions DEU_xx).
  * Rates and sums insured per hectare: OUR ESTIMATES (isEstimate="true"), the hail rates scaled so the
    area-weighted premium per hectare equals Vereinigte Hagel's 2022 German average (premium / insured area).

----------------------------------------------------------------------------
France (DB/CropInsurance_FR.xml)
----------------------------------------------------------------------------
Since the 2023 reform (loi n. 2022-298) France has three tiers: small losses stay with the farmer, a
subsidised multi-risk policy ("multirisque climatique", MRC) covers the middle, and the state pays losses
above a threshold through national solidarity (ISN) - fully for insured farms, at a falling rate for
uninsured ones. The file holds (see the FRANCE config):

  * Plan "multiRisk": >= 17 climatic perils, 70 % subsidy, deductible (franchise) 20 - 40 %; hail-only cover
    is not subsidised ("hailOnly").
  * ISN thresholds and uninsured indemnity rates per sector and year (2026 - 2028).
  * Insured yield 70 - 100 % of the historical yield (olympic average of 5 years or average of 3).
  * Rates and sums insured per hectare: OUR ESTIMATES (isEstimate="true"), anchored on published averages
    (cereals 2.7 %, orchards 14.8 % of the sum insured) and scaled so the total matches the 2024 premium
    subsidy paid (Ministry of Agriculture via the Assemblee nationale report, January 2026).

----------------------------------------------------------------------------
Netherlands (DB/CropInsurance_NL.xml)
----------------------------------------------------------------------------
The "brede weersverzekering" (broad weather insurance, BWV) is a subsidised multi-peril policy; hail-only
cover is sold unsubsidised. The subsidy has a FIXED budget: when more premium is applied for, everyone's
share is cut pro rata (63.7 % maximum, 46.3 % actually paid in 2025). The file holds (see the NETHERLANDS
config):

  * Plan "multiRisk": hail, rain, (night) frost, storm, drought, snow, freezing rain, lightning fire;
    pays only above a 20 % loss of the average production. No 21 % insurance tax since 2020.
  * Subsidy pool: budget, maximum share and the history of budget / premium / actual share 2015 - 2025.
  * Rates and sums insured per hectare: OUR ESTIMATES (isEstimate="true") inside the published 4 - 8 % of
    the insured value (Agriver). No insured-area total is published, so there is no calibration.

----------------------------------------------------------------------------
Spain (DB/CropInsurance_ES.xml)
----------------------------------------------------------------------------
Spanish crop insurance ("seguros agrarios combinados") is sold through one pool of insurers (Agroseguro)
under a yearly state plan; ENESA (and the regions) pay part of the premium. The file holds (see the SPAIN
config):

  * Modules: "1" whole-farm catastrophic cover (single 75 % subsidy), "2" all climatic risks per plot,
    "P" named perils (hail, fire, ...) - base subsidy per line and module from the 47th plan (2026).
  * Additional subsidies (young farmer, professional, collective, continuity, ...), floors, the 75 % cap,
    the 20 % rate cap and the progressive reduction ("modulacion") of large subsidies.
  * National history 2014 - 2023 (premium, subsidy, sum insured, claims) and the 2023 claims by cause.
  * Rates and sums insured per hectare: OUR ESTIMATES (isEstimate="true"), scaled so their capital-weighted
    average equals the agricultural average implied by Agroseguro's 2024 totals.

----------------------------------------------------------------------------
Italy (DB/CropInsurance_IT.xml)
----------------------------------------------------------------------------
Italian subsidised policies ("assicurazioni agevolate") follow the yearly risk-management plan (PGRA): the
farmer combines groups of perils (catastrophic, frequency, accessory) into one of six policy types, all with
a 20 % damage threshold and up to 70 % public contribution. The AgriCat fund pays catastrophic losses
(flood, frost, drought) on top - also for uninsured farms. The file holds (see the ITALY config):

  * Peril groups and the six policy types with their contribution share; AgriCat rules.
  * 2025 totals (insured value, hectares, farms, average rate 8.95 %) and the insured value of the main crops.
  * Rates and sums insured per hectare: OUR ESTIMATES (isEstimate="true"), scaled so their capital-weighted
    average equals ISMEA's 2025 average rate.

----------------------------------------------------------------------------
Australia (DB/CropInsurance_AU.xml)
----------------------------------------------------------------------------
No government scheme and no premium subsidy: farmers buy private named-peril cover (hail and fire, sometimes
frost); multi-peril cover has been tried several times but is rare. Premiums carry 10 % GST plus state stamp
duty, which NSW and Victoria waive for crop insurance. The file holds (see the AUSTRALIA config):

  * Plan "namedPeril" (hail + fire) and the rare "multiPeril" cover.
  * GST and stamp duty per state, with the crop exemptions.
  * Rates and sums insured per hectare (AUD): OUR ESTIMATES (isEstimate="true") inside the published ranges
    (named peril 0.55 - 3.5 %, multi-peril 5 - 10 % of the crop value, Deloitte). No market totals are
    published, so there is no calibration and no per-state risk factor yet.
  * Region ids match the climate file (AUS, AUS_NSW ...); this insurance file uses no climate data.

----------------------------------------------------------------------------
Argentina (DB/CropInsurance_AR.xml)
----------------------------------------------------------------------------
Private market without a national subsidy; hail cover dominates (hail 66.6 %, hail + additional perils
32.3 %, multi-peril 1.1 % of premiums). Two provinces run their own schemes (Mendoza hail / frost fund,
Cordoba free multi-peril pilot). The file holds (see the ARGENTINA config):

  * Plans: "hail", "hailPlus" (hail + wind, frost, fire ...), rare "multiPeril".
  * National totals of the SSN survey 2024 (July 2023 - June 2024) and the province rate factors derived from
    the premium / insured-capital shares (Buenos Aires, Santa Fe; Cordoba derived, see the config).
  * Rates and sums insured per hectare: OUR ESTIMATES (isEstimate="true"), sums in USD (Argentine crop prices
    are quoted in dollars; the peso figures only give the average rate), scaled so the capital-weighted average
    of the sold mix equals the SSN average (premium / insured capital).

----------------------------------------------------------------------------
Chile (DB/CropInsurance_CL.xml)
----------------------------------------------------------------------------
State-subsidised named-peril cover through Agroseguros (Ministry of Agriculture): 40 % of the net premium
plus a fixed 1 UF per policy, with stackable bonuses and caps per policy and per farmer. Drought is covered
only on rain-fed (secano) land. Uptake is low (2.8 % of the sown area in 2023). The file holds (see the
CHILE config):

  * Perils, subsidy formula, bonuses, caps, INDAP small-farmer rule.
  * Rates and sums insured per hectare in UF (unidad de fomento, ISO code CLF): OUR ESTIMATES
    (isEstimate="true") inside the published examples (4.3 %; fruit 2.6 - 5.2 %). No calibration.

----------------------------------------------------------------------------
United Kingdom (DB/CropInsurance_GB.xml)
----------------------------------------------------------------------------
No public support; growers buy private hail cover (fire is usually part of the farm policy), multi-peril
cover is rare. Premiums carry 12 % Insurance Premium Tax. The file holds (see the UK config):

  * Plan "namedPeril" (hail, fire; storm optional), IPT.
  * Rates and sums insured per hectare (GBP): OUR ESTIMATES (isEstimate="true") around the published
    "about 1 % of the insured value" for the UK; oilseed rape far above cereals (Farmers Weekly, old).
  * One region GBR (England, Scotland incl. the Highlands Fishing DLC, Wales, Northern Ireland).

----------------------------------------------------------------------------
South-East Asia (DB/CropInsurance_SEA.xml)
----------------------------------------------------------------------------
For the base-game map Hutan Pantai (fictional South-East Asia). Two real state rice schemes as profiles:
Indonesia (AUTP, default for the map) and Malaysia (padi crop takaful). Both cover only rice; the other crops
have no state scheme and borrow the rice terms (borrowedFrom="RICE"). Fixed premium and sum insured per
hectare and season - no rate tables, no estimates needed except where marked.

----------------------------------------------------------------------------
Region detection (DB/InsuranceRegions.xml)
----------------------------------------------------------------------------
Which country profile a map uses. The mod tries, in this order (first hit wins):
  1. the player's / admin's setting (manual region);
  2. known maps: the map's mod name in tools/map_countries.csv (ModHub survey);
  3. base-game maps (MapUS / MapEU / MapAS);
  4. keywords in the map title and description (country names, native names, regions), longest match wins;
     the sub-region names of the loaded profiles (US states, Canadian provinces ...) count as keywords too;
  5. the base-game climate the map reuses (map.environment#filename -> $data/maps/mapXX/);
  6. the default profile.
A detected country without its own data uses its nearest profile (e.g. Austria -> Germany, Ireland -> UK);
fictional European maps use the "EU" profile (Germany: by far the most European maps).

----------------------------------------------------------------------------
Brazil (DB/CropInsurance_BR.xml)
----------------------------------------------------------------------------
Built from MAPA's PSR open data (SISSER, one row per subsidised policy, Creative Commons Attribution):
  https://dados.agricultura.gov.br/dataset/sisser3  ->  "PSR - 2016 a 2024" (dados_abertos_psr_2016a2024csv.csv)
The files hold farmer names and tax ids: those columns are never read, only totals are written, and the raw
folder (BR_insurance/) is git-ignored and never shipped.

  * Plans: "YP" = PRODUTIVIDADE (yield cover), "COST" = CUSTEIO (covers the financed production cost).
    Livestock, forest, parametric and revenue policies are left out (too few / not crops).
  * Coverage levels rounded to the nearest 5 %, 50 - 95 %. 100 % policies (mostly fruit, named-peril style
    cover with few claims) are written as their own plan "FULL" so they do not flatten the other curves.
  * Per crop / plan / level: the same attributes as the US file, per hectare instead of per acre
    (farmerPerHa, hectares), shaped the same way (shaped_rates). lossRatio / claimShare / farmerPerHa
    stay the raw values.
  * Per state (BRA_xx): rateFactor and lossRatio against the national curves, like the US states.
  * Per crop: perils = share of the payouts and claims per cause of loss (EVENTO_PREPONDERANTE): drought,
    hail, frost, excessive rain, windstorm ("VENTOS FORTES/FRIOS"), flood ...
  * Program rules (2025-2027 three-year plan, CGSR): subsidy 20 % soybeans / 40 % others, 30 % / 45 % in
    the North and Northeast, at most R$ 60 000 per modality and R$ 120 000 per farmer and year.

----------------------------------------------------------------------------
RMA data rules handled here (from the record layout)
----------------------------------------------------------------------------
  * Only buy-up coverage (coverage category "A"). CAT ("C") is the flat-fee catastrophic
    cover at 50 % and would distort the 50 % level.
  * Only rows measured in acres (no colonies, trees, tons, ...).
  * "Total Premium" is BEFORE subsidy. Farmer cost = total premium - subsidy - state/private subsidy.
  * "Additional Subsidy" is ignored: in 2021 and 2022 it is the one-off Pandemic Cover Crop
    Program. The EFA (beginning / veteran farmer) discount is ignored as well.
  * Plan abbreviations: RP = Revenue Protection, RPHPE = RP with Harvest Price Exclusion
    (price locked), YP = Yield Protection, APH = yield-based plan for specialty crops.
"""

import math
import os
import re
import sys
import time
import zipfile
from collections import defaultdict
from xml.sax.saxutils import quoteattr

# ============================================================================
# CONFIG  -  edit these paths / values
# ============================================================================

TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))

# Folder with the sobcov_YYYY folders / sobcov_YYYY.zip files (keep it out of the release zip).
DATA_DIR = os.path.join(TOOLS_DIR, "..", "USDA_RMA", "archives")

# Complete years to use. Leave out the newest year or two: their payouts are still being settled.
YEARS = [2020, 2021, 2022, 2023, 2024]

OUTPUT_XML = os.path.join(TOOLS_DIR, "..", "DB", "CropInsurance_US.xml")

# Optional: state names are taken from the climate file so region ids/names match (US_KS = Kansas).
CLIMATE_XML = os.path.join(TOOLS_DIR, "..", "DB", "TornadoClimate.xml")

PLANS = ["RP", "RPHPE", "YP", "APH"]
COVERAGE_LEVELS = [0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85]

# Minimum sample (summed over all YEARS) for an entry to be written.
MIN_ACRES = 20000
MIN_POLICIES = 30
MIN_STATE_ACRES = 20000      # per state and crop, for the state rateFactor

# FS25 fill type  ->  RMA commodity name(s). Several names are summed.
# "proxy" crops have no own RMA programme; they borrow the numbers of a similar insured crop
# and carry borrowedFrom="..." in the XML.
CROPS = {
    "WHEAT":         ["Wheat"],
    "BARLEY":        ["Barley"],
    "OAT":           ["Oats"],
    "CANOLA":        ["Canola"],
    "SORGHUM":       ["Grain Sorghum"],
    "SUNFLOWER":     ["Sunflowers"],
    "SOYBEAN":       ["Soybeans"],
    "MAIZE":         ["Corn"],
    "POTATO":        ["Potatoes"],
    "SUGARBEET":     ["Sugar Beets"],
    "SUGARCANE":     ["Sugarcane"],
    "COTTON":        ["Cotton"],
    "RICE":          ["Rice"],
    "RICELONGGRAIN": ["Rice"],
    "GRAPE":         ["Grapes"],
    "OLIVE":         ["Olives"],
    "PEA":           ["Dry Peas"],
    "GREENBEAN":     ["Processing Beans"],
    "GRASS":         ["Forage Production"],
}
PROXY_CROPS = {
    # No RMA programme of their own: borrow a similar yield-insured vegetable crop.
    "SPINACH": "POTATO",
    "CARROT":  "POTATO",
    "PARSNIP": "POTATO",
    "REDBEET": "SUGARBEET",
}

# Commodities that make up the DEFAULT crop (fallback for unknown / modded crops).
DEFAULT_COMMODITIES = {"Wheat", "Barley", "Oats", "Canola", "Grain Sorghum", "Sunflowers", "Soybeans",
                       "Corn", "Cotton", "Rice", "Dry Peas", "Dry Beans", "Rye", "Flax", "Millet"}

DECIMALS = 4

# Yield variability (coefficient of variation) of the loss model that shapes every rate curve (coverage_shape).
COVERAGE_SHAPE_CV = 0.30

# ============================================================================
# CANADA  -  published numbers (edit when newer reports are out)
# ============================================================================

CANADA_OUTPUT_XML = os.path.join(TOOLS_DIR, "..", "DB", "CropInsurance_CA.xml")

# Province -> neighbouring US state whose crop curves shape the province's curves.
CANADA_NEIGHBOUR = {"AB": "MT", "SK": "ND", "MB": "MN", "ON": "MI", "QC": "NY"}
CANADA_NAMES = {"AB": "Alberta", "SK": "Saskatchewan", "MB": "Manitoba", "ON": "Ontario", "QC": "Quebec"}

CANADA_COVERAGE_LEVELS = [0.50, 0.60, 0.70, 0.80]
# SCIC: "Coverage is only available up to 70 per cent for ... potatoes, soybeans, grain corn ..."
CANADA_MAX_70 = {"POTATO", "SOYBEAN", "MAIZE", "GREENBEAN"}

# SCIC annual report 2024-25, page 33 / 63: producer 40 %, federal 36 %, provincial 24 % (since 2006).
CANADA_PRODUCER_SHARE = 0.40

# SCIC annual report 2024-25, Appendix 7 (page 69), multi-peril annual grain crops, crop years 2020-21 .. 2024-25:
#   (liability $, total net premium $, indemnity $)
SCIC_YEARS = [
    (6030296529, 506156366, 155919176),
    (7560110863, 607441299, 2253607287),
    (11605408561, 894830845, 1042105564),
    (12180134175, 910856389, 1292368129),
    (10660689251, 963399455, 939663761),
]
SCIC_LOSS_RATIO_10Y = 0.95   # page 69, accumulated loss-to-premium ratio 2015-16 .. 2024-25

# SCIC annual report 2024-25, page 62: share of acres per coverage level, average of 2020 .. 2024.
SCIC_COVERAGE_MIX = {0.50: 0.068, 0.60: 0.056, 0.70: 0.336, 0.80: 0.548}

# SCIC annual report 2024-25, page 70: insured acres 2024-25 of the crops the game has (weights for the calibration).
SCIC_ACRES = {
    "WHEAT": 7490411 + 4881099 + 403236 + 18144 + 33274 + 1281 + 17566,  # HRS, durum, CPS, HWS, winter, ESR, khorasan
    "CANOLA": 10468852 + 1017338,                                        # canola + identity preserved canola
    "BARLEY": 1697468,
    "OAT": 765075,
    "PEA": 1511760,
    "SOYBEAN": 36372,
    "SUNFLOWER": 2611,
    "MAIZE": 2609,
    "POTATO": 978,
}

# AFSC 2026 Full Cover Hail Insurance premium rates (Straight-Hail-Insurance-Rates-for-South/North.pdf):
# full-cover rate by township 3 % .. 14 % of the insured value (highest in the Calgary - Red Deer corridor);
# 10 % deductible = 0.75 x the rate, 25 % deductible = 0.5 x the rate.
# rateMin / rateMax / deductibles are AFSC's published figures. rateTypical is OUR estimate read off the map
# (it is marked as an estimate in the XML so it is not presented as an AFSC number).
# AFSC terms (https://afsc.ca/disclaimer/): non-commercial use, identify AFSC as the source, do not present
# it as official or AFSC-endorsed.
AFSC_HAIL = {"rateMin": 0.03, "rateTypical": 0.06, "rateMax": 0.14,
             "deductibles": [(0.0, 1.0), (0.10, 0.75), (0.25, 0.5)]}

# ============================================================================
# POLAND  -  published rules (edit when newer regulations are out)
# ============================================================================

POLAND_OUTPUT_XML = os.path.join(TOOLS_DIR, "..", "DB", "CropInsurance_PL.xml")

# Ustawa z 7 lipca 2005 o ubezpieczeniach upraw rolnych i zwierzat gospodarskich (Dz.U. 2025 poz. 251) and
# gov.pl "Ubezpieczenie upraw rolnych i zwierzat gospodarskich w 2026 r. z doplata skladki z budzetu panstwa":
# the state pays 65 % of the premium.
POLAND_SUBSIDY_SHARE = 0.65

# gov.pl "Okreslenie stawek taryfowych ubezpieczenia": the 65 % is paid in full only while the premium rate is at
# most this share of the sum insured; above it the subsidy is 65 % of (cap x sum insured). (Soil classes V / VI
# get 12 / 15 % and 22 / 25 % - FS25 has no soil classes, so only the normal cap is written.)
POLAND_RATE_CAP = {"field": 0.09, "fruit": 0.20, "animal": 0.005}

# Farmers receiving direct payments must insure at least 50 % of their crop area against at least one
# mandatory peril, or pay a fee of the PLN equivalent of 2 EUR per hectare (written as an optional rule).
POLAND_OBLIGATION = {"areaShare": 0.50, "feePerHaEur": 2.0}

# Perils. "mandatory" = the subsidised package an insurer must offer (the farmer picks at least one);
# "optional" = may be added. Windstorm ("huragan") is the one a tornado claim falls under.
POLAND_PERILS = {
    "mandatory": ["HAIL", "SPRING_FROST", "WINTER_KILL", "FLOOD", "DROUGHT"],
    "optional": ["WINDSTORM", "TORRENTIAL_RAIN", "LIGHTNING", "LANDSLIDE", "AVALANCHE"],
}

# Maximum sum insured for 2026, PLN per ha: Dz.U. 2025 poz. 1628 (basket willow 60 000 and grass seed 30 000 added
# by Dz.U. 2026 poz. 1020). "legumes" = large-seeded legumes (small-seeded: 4 700, no game crop).
POLAND_MAX_SUM_YEAR = 2026
POLAND_MAX_SUM = {
    "cereals": 16300, "maize": 12700, "rapeseed": 13000, "sunflower": 6300, "hops": 50100, "tobacco": 57300,
    "vegetables": 340500, "fruit": 171900, "strawberries": 105100, "potatoes": 63100,
    "sugarbeet": 20600, "legumes": 23100, "grassSeed": 30000, "basketWillow": 60000,
}
# Per animal: 2025 regulation (Dz.U. 2024 poz. 1695); the 2026 animal values are not checked yet.
POLAND_MAX_SUM_ANIMAL = {
    "COW": 16000, "HORSE": 26300, "SHEEP": 1300, "GOAT": 800, "PIG": 2900, "CHICKEN": 60,
    "DUCK": 65, "GOOSE": 250, "TURKEY": 210, "OSTRICH": 2000,
}

# FS25 fill type -> Polish crop group. Crops without an own entry in the regulation borrow a similar group
# (marked borrowed="true"). Cotton, rice, sugarcane, olives and forage grass are not insured in Poland and
# are left out (the mod falls back to DEFAULT = cereals).
POLAND_CROPS = {
    "WHEAT": "cereals", "BARLEY": "cereals", "OAT": "cereals", "SORGHUM": "cereals",
    "MAIZE": "maize", "CANOLA": "rapeseed", "SUNFLOWER": "sunflower",
    "POTATO": "potatoes", "SUGARBEET": "sugarbeet",
    "SOYBEAN": "legumes", "PEA": "legumes", "GREENBEAN": "legumes",
    "CARROT": "vegetables", "PARSNIP": "vegetables", "REDBEET": "vegetables", "SPINACH": "vegetables",
    "GRAPE": "fruit",
    "DEFAULT": "cereals",
}
POLAND_BORROWED = {"SORGHUM", "GRAPE"}

# Typical premium rates (before subsidy, share of the sum insured) - OUR ESTIMATES of the RELATIVE cost per crop
# group; written with isEstimate="true". "package" = hail + spring frost + winter kill + flood (the usual
# multi-risk policy); "hail" = hail-only policy; add-ons are extra rate on top of either. The package rates are
# then scaled by one calibration factor so the area-weighted average matches POLAND_CALIBRATION (like Canada).
POLAND_RATES_ESTIMATE = {
    "cereals":    {"package": 0.025, "hail": 0.012, "WINDSTORM": 0.004, "DROUGHT": 0.050, "capGroup": "field"},
    "maize":      {"package": 0.020, "hail": 0.012, "WINDSTORM": 0.005, "DROUGHT": 0.060, "capGroup": "field"},
    "sunflower":  {"package": 0.025, "hail": 0.012, "WINDSTORM": 0.005, "DROUGHT": 0.050, "capGroup": "field"},
    "rapeseed":   {"package": 0.040, "hail": 0.015, "WINDSTORM": 0.005, "DROUGHT": 0.050, "capGroup": "field"},
    "potatoes":   {"package": 0.020, "hail": 0.010, "WINDSTORM": 0.003, "DROUGHT": 0.050, "capGroup": "field"},
    "sugarbeet":  {"package": 0.020, "hail": 0.010, "WINDSTORM": 0.003, "DROUGHT": 0.050, "capGroup": "field"},
    "legumes":    {"package": 0.030, "hail": 0.015, "WINDSTORM": 0.004, "DROUGHT": 0.060, "capGroup": "field"},
    "vegetables": {"package": 0.050, "hail": 0.025, "WINDSTORM": 0.005, "DROUGHT": 0.070, "capGroup": "field"},
    "fruit":      {"package": 0.100, "hail": 0.040, "WINDSTORM": 0.010, "DROUGHT": 0.080, "capGroup": "fruit"},
}
POLAND_ANIMAL_RATE_ESTIMATE = 0.004

# Calibration: average premium rate implied by the subsidy actually paid.
#   2024: ~629 M PLN subsidy paid, ~3.8 M ha of crops and ~20.5 M animals insured, ~209 300 crop contracts
#         (MRiRW figures as reported by wiescirolnicze.pl / farmer.pl for the 2026 subsidy regulation).
#   rate = subsidy x cropShare / subsidyShare / (area x sumPerHa)
# cropShare and sumPerHa are OUR ESTIMATES (no published split / average sum insured): livestock premiums are
# capped at 0.5 % and are mostly poultry and pigs, so ~10 % of the subsidy; ~6 000 PLN/ha is the value of an
# average cereal / rapeseed / maize crop. The area mix is an estimate of what is insured (rapeseed and cereals
# are insured far more often than other crops; fruit is left out - small area).
POLAND_CALIBRATION = {"subsidyPaidPln": 629e6, "areaHa": 3.8e6, "cropShare": 0.90, "sumPerHaPln": 6000,
                      "areaMix": {"cereals": 0.62, "rapeseed": 0.18, "maize": 0.14, "potatoes": 0.02,
                                  "sugarbeet": 0.02, "legumes": 0.02}}
# Deductible options (share of the loss the farmer keeps -> rate factor), also estimates.
POLAND_DEDUCTIBLES_ESTIMATE = [(0.0, 1.0), (0.10, 0.85), (0.20, 0.70)]
# PLN -> EUR for the sum-insured caps (2025 average, about 4.25 PLN per EUR). The mod then applies its own
# money scaling (TornadoSettings:getCostScale).
POLAND_EUR_PER_PLN = 1 / 4.25

# ============================================================================
# GERMANY  -  published rules + one market figure (edit when newer figures are out)
# ============================================================================

GERMANY_OUTPUT_XML = os.path.join(TOOLS_DIR, "..", "DB", "CropInsurance_DE.xml")

# Insurance tax (Versicherungsteuer) for hail, storm, heavy rain and severe frost: 0.3 per mille of the sum
# insured per year instead of a share of the premium (DLG-Merkblatt 434).
GERMANY_INSURANCE_TAX = 0.0003
GERMANY_TAXED_PERILS = ["HAIL", "WINDSTORM", "HEAVY_RAIN", "SEVERE_FROST"]
GERMANY_PERILS = {"base": ["HAIL"], "optional": ["WINDSTORM", "HEAVY_RAIN", "SEVERE_FROST", "DROUGHT"]}
GERMANY_PACKAGE = ["HAIL", "WINDSTORM", "HEAVY_RAIN", "SEVERE_FROST", "DROUGHT"]

# FS25 fill type -> crop group. OLIVE borrows fruit (borrowed="true"). Cotton, rice and sugarcane are not grown
# in Germany (the mod falls back to DEFAULT = cereals).
GERMANY_CROPS = {
    "WHEAT": "cereals", "BARLEY": "cereals", "OAT": "cereals", "SORGHUM": "cereals",
    "CANOLA": "rapeseed", "SUNFLOWER": "sunflower", "MAIZE": "maize",
    "SOYBEAN": "legumes", "PEA": "legumes", "GREENBEAN": "legumes",
    "POTATO": "potatoes", "SUGARBEET": "sugarbeet",
    "CARROT": "vegetables", "PARSNIP": "vegetables", "REDBEET": "vegetables", "SPINACH": "vegetables",
    "GRASS": "grassland", "GRAPE": "vine", "OLIVE": "fruit",
    "DEFAULT": "cereals",
}
GERMANY_BORROWED = {"OLIVE", "SORGHUM"}

# Per crop group, OUR ESTIMATES: typical sum insured per ha (EUR, yield x price; topagrar: cereals / rapeseed
# usually 1 000 - 1 600 EUR/ha), relative hail rate, add-on rates (extra rate on top of hail).
# Drought: index cover costs ~3 - 10 % of the sum insured (topagrar) -> 5 %.
GERMANY_GROUPS = {
    #              sumPerHa  hail    WINDSTORM HEAVY_RAIN SEVERE_FROST DROUGHT
    "cereals":    (1500,    0.012,  0.002,    0.002,     0.003,       0.05),
    "rapeseed":   (1600,    0.025,  0.004,    0.002,     0.006,       0.05),
    "sunflower":  (1000,    0.015,  0.004,    0.002,     0.002,       0.05),
    "maize":      (1700,    0.012,  0.004,    0.003,     0.001,       0.06),
    "legumes":    (1000,    0.015,  0.003,    0.003,     0.002,       0.05),
    "potatoes":   (5000,    0.012,  0.001,    0.004,     0.001,       0.06),
    "sugarbeet":  (2800,    0.008,  0.001,    0.003,     0.001,       0.05),
    "vegetables": (15000,   0.040,  0.005,    0.010,     0.010,       0.06),
    "grassland":  (1000,    0.005,  0.001,    0.001,     0.001,       0.05),
    "fruit":      (20000,   0.040,  0.005,    0.005,     0.060,       0.04),
    "vine":       (15000,   0.035,  0.005,    0.005,     0.040,       0.04),
}
GERMANY_DEDUCTIBLES_ESTIMATE = [(0.0, 1.0), (0.10, 0.85), (0.20, 0.70)]

# Calibration: Vereinigte Hagel (market leader) Germany 2022: ~4.91 M ha insured, 155.49 M EUR premium
# (agrarheute) -> premium per insured ha. The area mix of that insured area is OUR ESTIMATE (German crop areas,
# hail insurance is bought mostly for arable crops). The premium also holds some multi-peril cover, so the
# calibrated hail rates are slightly high rather than low. 2024 (SFCR): Germany 151.8 M EUR premium,
# 147.7 M EUR claims (loss ratio 97.3 %, frost year), 2023 claims 128.5 M EUR.
GERMANY_CALIBRATION = {"premiumEur": 155.49e6, "areaHa": 4.91e6,
                       "areaMix": {"cereals": 0.55, "rapeseed": 0.12, "maize": 0.20, "sugarbeet": 0.04,
                                   "potatoes": 0.03, "legumes": 0.02, "vegetables": 0.01, "fruit": 0.01,
                                   "vine": 0.01, "sunflower": 0.01}}

# State subsidy programmes (up to 50 % of the eligible premium). groups = crop groups the package covers;
# minPerils = how many of the perils must be chosen (0 = all, no choice).
GERMANY_STATES = {
    "BY": {"name": "Bavaria", "share": 0.50, "minDeductible": 0.20, "maxPayoutShare": 0.80, "maxPerFarm": 99999,
           "minAreaHa": 0.3, "since": 2023,
           "source": "StMELF Merkblatt Mehrgefahrenversicherung 2026",
           "packages": [("arable", "HAIL WINDSTORM HEAVY_RAIN SEVERE_FROST DROUGHT BIRD_DAMAGE", 0,
                         "cereals rapeseed sunflower maize legumes potatoes sugarbeet"),
                        ("grassland", "HAIL DROUGHT GRUB_DAMAGE", 0, "grassland"),
                        ("specialty", "HAIL SEVERE_FROST WINDSTORM HEAVY_RAIN", 2, "fruit vine")],
           # Hoechsthektarwerte: the subsidy only counts the premium up to these sums insured (EUR/ha).
           "maxSumPerHa": {"cereals": 5000, "rapeseed": 5000, "sunflower": 5000, "maize": 5000, "legumes": 5000,
                           "potatoes": 15000, "sugarbeet": 15000, "grassland": 3000, "fruit": 30000,
                           "vine": 30000}},
    "BW": {"name": "Baden-Wuerttemberg", "share": 0.50, "minAreaHa": 0.3, "since": 2026,
           "source": "Vereinigte Hagel, Foerderung Baden-Wuerttemberg",
           "packages": [("specialty", "HAIL SEVERE_FROST WINDSTORM HEAVY_RAIN", 2, "fruit vine")]},
    "NI": {"name": "Lower Saxony", "share": 0.50, "maxPerFarm": 25000, "minAreaHa": 1.0, "since": 2025,
           "source": "Vereinigte Hagel, Foerderung Niedersachsen (also Hamburg and Bremen)",
           # hail itself is not subsidised here
           "packages": [("multiPeril", "WINDSTORM HEAVY_RAIN SEVERE_FROST DROUGHT", 1,
                         "cereals rapeseed sunflower maize legumes potatoes sugarbeet grassland fruit vegetables")]},
    "SN": {"name": "Saxony", "share": 0.50, "source": "Vereinigte Hagel, Foerderprogramme (wine growing)",
           "packages": [("vine", "HAIL SEVERE_FROST WINDSTORM HEAVY_RAIN", 2, "vine")]},
}

# ============================================================================
# FRANCE  -  published rules + one market figure (edit when newer figures are out)
# ============================================================================

FRANCE_OUTPUT_XML = os.path.join(TOOLS_DIR, "..", "DB", "CropInsurance_FR.xml")

# agriculture.gouv.fr "Assurance recolte : reponses aux questions frequemment posees" (12 January 2026).
FRANCE_SUBSIDY_SHARE = 0.70
FRANCE_FRANCHISES = [0.20, 0.25, 0.30, 0.40]        # subsidised deductible / trigger: 20 % up to 25 or 40 %
FRANCE_MIN_PERILS = 17                               # drought, heat, frost, excess water, hail, storm, ...
FRANCE_INSURED_YIELD = (0.70, 1.00)                  # share of the historical (olympic 5 / average 3) yield

# ISN (national solidarity): threshold = loss share above which the state pays. Insured farms: 90 % state +
# 10 % insurer = the whole loss above the threshold. Uninsured: share of the loss above the threshold, per year.
# Grassland uninsured rates: the ministry table is ambiguous (45 % for "other productions"); 2026 press
# (echangesassurances.org) gives 31.5 % for grassland, so grassland follows the vine / orchard trajectory.
FRANCE_ISN = {
    "fieldCrops": {"threshold": 0.50, "uninsured": {2026: 0.28, 2027: 0.21, 2028: 0.14}},
    "vegetables": {"threshold": 0.50, "uninsured": {2026: 0.315, 2027: 0.28, 2028: 0.245}},
    "vine":       {"threshold": 0.50, "uninsured": {2026: 0.315, 2027: 0.28, 2028: 0.245}},
    "orchards":   {"threshold": 0.30, "uninsured": {2026: 0.315, 2027: 0.28, 2028: 0.245}},
    "grassland":  {"threshold": 0.30, "uninsured": {2026: 0.315, 2027: 0.28, 2028: 0.245}},
}
# Assemblee nationale, commission des affaires economiques (January 2026): share of the area insured.
FRANCE_INSURED_SHARE = {2022: {"fieldCrops": 0.311, "vine": 0.312, "orchards": 0.015, "grassland": 0.005},
                        2024: {"fieldCrops": 0.366, "vine": 0.368, "orchards": 0.144, "grassland": 0.091}}

# FS25 fill type -> crop group; group -> ISN sector. OLIVE borrows orchards, SORGHUM cereals.
FRANCE_CROPS = {
    "WHEAT": "cereals", "BARLEY": "cereals", "OAT": "cereals", "SORGHUM": "cereals", "RICE": "cereals",
    "RICELONGGRAIN": "cereals",
    "CANOLA": "rapeseed", "SUNFLOWER": "sunflower", "MAIZE": "maize",
    "SOYBEAN": "legumes", "PEA": "legumes", "GREENBEAN": "vegetables",
    "POTATO": "potatoes", "SUGARBEET": "sugarbeet",
    "CARROT": "vegetables", "PARSNIP": "vegetables", "REDBEET": "vegetables", "SPINACH": "vegetables",
    "GRASS": "grassland", "GRAPE": "vine", "OLIVE": "fruit",
    "DEFAULT": "cereals",
}
FRANCE_BORROWED = {"OLIVE", "SORGHUM", "RICE", "RICELONGGRAIN"}
FRANCE_SECTOR = {"cereals": "fieldCrops", "rapeseed": "fieldCrops", "sunflower": "fieldCrops",
                 "maize": "fieldCrops", "legumes": "fieldCrops", "potatoes": "fieldCrops",
                 "sugarbeet": "fieldCrops", "vegetables": "vegetables", "grassland": "grassland",
                 "vine": "vine", "fruit": "orchards"}

# Per crop group: sum insured per ha (EUR) and multi-risk rate at a 20 % franchise, hail-only rate.
# Anchors (La France Agricole, "Comprendre l'assurance multirisque climatique"): cereals 36 EUR/ha = 2.7 %,
# orchards 1 514 EUR/ha = 14.8 % of the sum insured (pre-reform, 25 - 30 % franchise). Everything else is OUR
# ESTIMATE relative to those.
FRANCE_GROUPS = {
    #              sumPerHa  multiRisk  hailOnly
    "cereals":    (1330,    0.027,     0.010),
    "rapeseed":   (1500,    0.040,     0.018),
    "sunflower":  (1100,    0.030,     0.012),
    "maize":      (1700,    0.030,     0.010),
    "legumes":    (1000,    0.035,     0.012),
    "potatoes":   (6000,    0.025,     0.010),
    "sugarbeet":  (3000,    0.020,     0.006),
    "vegetables": (15000,   0.060,     0.030),
    "grassland":  (600,     0.060,     0.004),
    "vine":       (8000,    0.050,     0.025),
    "fruit":      (10200,   0.148,     0.040),
}

# Calibration: 2024 premium subsidy paid 365.8 M EUR (70 %) -> subsidised premium. Insured area = sector area
# (OUR ESTIMATE, rounded Agreste orders of magnitude) x insured share 2024. Within field crops the group mix is
# also OUR ESTIMATE. One factor scales all multi-risk rates (the 2023 reform lowered the franchise to 20 %, so
# rates above the older anchors are expected).
FRANCE_CALIBRATION = {"subsidyPaidEur": 365.8e6, "year": 2024,
                      "sectorAreaHa": {"fieldCrops": 12.0e6, "vine": 0.75e6, "orchards": 0.17e6, "grassland": 12.6e6},
                      "fieldCropMix": {"cereals": 0.70, "rapeseed": 0.10, "maize": 0.10, "sunflower": 0.05,
                                       "legumes": 0.02, "sugarbeet": 0.02, "potatoes": 0.01},
                      "sectorGroup": {"vine": "vine", "orchards": "fruit", "grassland": "grassland"}}

# ============================================================================
# NETHERLANDS  -  published rules + subsidy history (edit when newer figures are out)
# ============================================================================

NETHERLANDS_OUTPUT_XML = os.path.join(TOOLS_DIR, "..", "DB", "CropInsurance_NL.xml")

# RVO "Brede weersverzekering 2025 / 2026" + Ecorys / WUR evaluation for the ministry (7 May 2024).
NETHERLANDS_PERILS = ["HAIL", "HEAVY_RAIN", "FROST", "WINDSTORM", "DROUGHT", "SNOW", "FREEZING_RAIN", "LIGHTNING_FIRE"]
NETHERLANDS_THRESHOLD = 0.20          # financial loss > 20 % of the average annual production (was 30 % before 2018)
NETHERLANDS_MAX_SUBSIDY = 0.637       # EU maximum 70 % of premium + tax, minus the 21 % tax exemption since 2020
NETHERLANDS_BUDGET_EUR = 17.5e6       # fixed, not indexed; over-subscription -> pro-rata cut for everyone
NETHERLANDS_INSURANCE_TAX = 0.21      # assurantiebelasting; BWV exempt since 2020 (hail-only cover is not)
NETHERLANDS_LOSS_RATIO_NORM = 0.5     # insurer's 5-year cumulative loss ratio must stay >= 0.5
# year: (budget M EUR, subsidy paid M EUR, premium M EUR, actual subsidy share). 2015 - 2023: evaluation table 1;
# 2025: RVO final share, premium = budget / share (the budget was used up).
NETHERLANDS_HISTORY = {
    2015: (9.0, 7.81, 12.02, 0.65), 2016: (9.0, 8.99, 14.50, 0.62), 2017: (11.2, 10.92, 16.81, 0.65),
    2018: (13.0, 11.03, 16.97, 0.65), 2019: (15.0, 12.18, 18.73, 0.65), 2020: (17.5, 15.95, 25.04, 0.637),
    2021: (17.5, 17.48, 28.97, 0.6035), 2022: (17.5, 17.50, 32.10, 0.5452), 2023: (17.5, 17.50, 32.88, 0.53225),
    2025: (17.5, 17.50, 17.5 / 0.46266, 0.46266),
}
# Evaluation: 2 450 farms with a BWV in 2022 (~15 % of farms with a weather-sensitive main crop); ~1/3 of the
# area on arable farms and ~60 % of apple / pear area insured.
NETHERLANDS_UPTAKE = {"farms2022": 2450, "farmShare2022": 0.15, "arableAreaShare2022": 0.33, "applePearAreaShare2022": 0.60}

NETHERLANDS_CROPS = {
    "WHEAT": "cereals", "BARLEY": "cereals", "OAT": "cereals", "SORGHUM": "cereals",
    "CANOLA": "rapeseed", "SUNFLOWER": "rapeseed", "MAIZE": "maize",
    "SOYBEAN": "legumes", "PEA": "legumes", "GREENBEAN": "vegetables",
    "POTATO": "potatoes", "SUGARBEET": "sugarbeet",
    "CARROT": "vegetables", "PARSNIP": "vegetables", "REDBEET": "vegetables", "SPINACH": "vegetables",
    "GRASS": "grassland", "GRAPE": "fruit", "OLIVE": "fruit",
    "DEFAULT": "cereals",
}
NETHERLANDS_BORROWED = {"SORGHUM", "SUNFLOWER", "GRAPE", "OLIVE"}

# Per crop group, OUR ESTIMATES: sum insured per ha (EUR, Dutch yields x prices), BWV rate (share of the sum
# insured, inside Agriver's 4 - 8 %; fruit at the top), hail-only rate (unsubsidised, plus 21 % tax).
NETHERLANDS_GROUPS = {
    #              sumPerHa  multiRisk  hailOnly
    "cereals":    (1800,    0.040,     0.006),
    "rapeseed":   (1800,    0.050,     0.010),
    "maize":      (2000,    0.040,     0.006),
    "legumes":    (2000,    0.050,     0.008),
    "potatoes":   (9000,    0.050,     0.008),
    "sugarbeet":  (3400,    0.040,     0.005),
    "vegetables": (10000,   0.060,     0.015),
    "grassland":  (1200,    0.040,     0.003),
    "fruit":      (25000,   0.080,     0.030),
}

# ============================================================================
# SPAIN  -  47th Plan de Seguros Agrarios Combinados (2026) + Agroseguro figures
# ============================================================================

SPAIN_OUTPUT_XML = os.path.join(TOOLS_DIR, "..", "DB", "CropInsurance_ES.xml")

# BOE-A-2025-27098 (47th plan, 2026). Base subsidy (share of the premium "base de calculo") per line and module;
# module 1 always gets a single 75 %. Lines: groups below -> plan line.
SPAIN_MODULE1_SUBSIDY = 0.75
SPAIN_BASE_SUBSIDY = {
    #              module 2  module P   plan line
    "cereals":    (0.22,    0.05,     "Cultivos herbaceos extensivos"),
    "maize":      (0.22,    0.05,     "Cultivos herbaceos extensivos"),
    "sunflower":  (0.22,    0.05,     "Cultivos herbaceos extensivos"),
    "rapeseed":   (0.22,    0.05,     "Cultivos herbaceos extensivos"),
    "legumes":    (0.22,    0.08,     "Cultivos herbaceos extensivos (habas: P 8 %)"),
    "rice":       (0.22,    0.08,     "Cultivos herbaceos extensivos (arroz: P 8 %)"),
    "potatoes":   (0.20,    0.08,     "Hortalizas al aire libre primavera-verano"),
    "sugarbeet":  (0.20,    0.08,     "Cultivos industriales no textiles"),
    "cotton":     (0.20,    0.08,     "Cultivos industriales textiles"),
    "vegetables": (0.20,    0.08,     "Hortalizas al aire libre"),
    "forage":     (0.20,    0.08,     "Cultivos forrajeros"),
    "vine":       (0.22,    0.08,     "Uva de vinificacion (SB+GA1+GA2: 22 %, SB+GA1: 31 %)"),
    "fruit":      (0.20,    0.08,     "Fruticolas"),
    "citrus":     (0.20,    0.08,     "Citricos"),
    "olive":      (0.22,    0.08,     "Olivar"),
    "banana":     (None,    0.25,     "Platanos (modules P and E only)"),
}
# Additional subsidies (percentage points on top of the base).
SPAIN_ADDITIONAL = {
    "youngFarmer":        {"module2": 0.29, "moduleP": 0.27, "moduleP_herbaceous": 0.225},
    "professional":       {"module2": 0.19, "moduleP": 0.17, "moduleP_herbaceous": 0.125},  # also priority farms, PO members
    "collective":         0.06,
    "continuity":         0.05,   # 7 % for herbaceous, nuts, olive, wine grape, forage
    "continuityHigh":     0.07,
    "instalments":        0.01,
    "riskPractices":      0.02,   # modules 2 / 3
    "sharedOwnership":    0.05,
    "newContract":        0.03,
    "complementary":      0.06,
}
SPAIN_FLOORS = {"professional": 0.50, "youngFarmer": 0.45}    # module 2 / 3: total topped up to at least this
SPAIN_MAX_SUBSIDY = 0.75            # ENESA + regions together
SPAIN_RATE_CAP = 0.20               # rates above 20 % are only subsidised up to 20 %
SPAIN_FIXED_DEDUCTION_EUR = 60      # per beneficiary
SPAIN_CANARY_BASE_UPLIFT = 0.65     # base subsidy x 1.65 for farms on the Canary Islands
# Progressive reduction of the subsidy per policy: share withheld from the part of the subsidy in each band.
SPAIN_MODULATION = [(0, 5000, 0.10), (5000, 10000, 0.25), (10000, 20000, 0.35), (20000, 30000, 0.45),
                    (30000, None, 0.50)]
SPAIN_MODULATION_EXEMPT = "associative entities, fixed-cost line for producer organisations, farms wholly in the Canary Islands"

# Agroseguro "Sistema espanol de Seguros Agrarios Combinados 2024": year -> (premium, subsidy ENESA + regions,
# sum insured, claims) in M EUR, all lines (incl. livestock).
SPAIN_HISTORY = {
    2014: (586.34, 241.41, 11104.09, 496.81), 2015: (665.43, 270.50, 12113.45, 484.65),
    2016: (706.56, 303.16, 12787.88, 485.69), 2017: (789.24, 317.50, 13770.34, 734.06),
    2018: (758.16, 296.72, 14079.25, 738.30), 2019: (783.97, 313.90, 14257.72, 625.75),
    2020: (797.82, 313.14, 15259.87, 616.20), 2021: (830.53, 341.09, 15672.28, 747.16),
    2022: (868.48, 427.21, 16364.65, 793.33), 2023: (967.46, 486.10, 16748.24, 1241.21),
}
# Same source: agricultural claims by cause, 2023 (share of claims).
SPAIN_CLAIM_CAUSES_2023 = {"DROUGHT": 0.4253, "HAIL": 0.2696, "OTHER": 0.1080, "HEAVY_RAIN": 0.0733,
                           "WINDSTORM": 0.0555, "FROST": 0.0497, "POOR_FRUIT_SET": 0.0162, "FIRE": 0.0024}

SPAIN_CROPS = {
    "WHEAT": "cereals", "BARLEY": "cereals", "OAT": "cereals", "SORGHUM": "cereals",
    "MAIZE": "maize", "SUNFLOWER": "sunflower", "CANOLA": "rapeseed",
    "SOYBEAN": "legumes", "PEA": "legumes", "GREENBEAN": "vegetables",
    "RICE": "rice", "RICELONGGRAIN": "rice",
    "POTATO": "potatoes", "SUGARBEET": "sugarbeet", "COTTON": "cotton",
    "CARROT": "vegetables", "PARSNIP": "vegetables", "REDBEET": "vegetables", "SPINACH": "vegetables",
    "GRASS": "forage", "GRAPE": "vine", "OLIVE": "olive", "BANANA": "banana",
    "DEFAULT": "cereals",
}
SPAIN_BORROWED = {"SORGHUM"}

# Per crop group, OUR ESTIMATES: sum insured per ha (EUR, Spanish yields x prices), typical rate of the cover as
# sold (before calibration) and the share of the agricultural sum insured (for the calibration).
SPAIN_GROUPS = {
    #              sumPerHa  rate    capitalShare
    "cereals":    (900,     0.040,  0.20),
    "maize":      (2600,    0.040,  0.04),
    "sunflower":  (700,     0.045,  0.03),
    "rapeseed":   (1100,    0.045,  0.01),
    "legumes":    (700,     0.050,  0.01),
    "rice":       (2500,    0.035,  0.01),
    "potatoes":   (9000,    0.040,  0.02),
    "sugarbeet":  (4000,    0.030,  0.005),
    "cotton":     (2500,    0.050,  0.01),
    "vegetables": (15000,   0.060,  0.15),
    "forage":     (800,     0.050,  0.02),
    "vine":       (3200,    0.080,  0.15),
    "fruit":      (15000,   0.120,  0.15),
    "citrus":     (10000,   0.060,  0.08),
    "olive":      (2500,    0.050,  0.07),
    "banana":     (30000,   0.080,  0.05),
}
# Module rate factors relative to the typical cover, OUR ESTIMATES: module P (named perils) is far cheaper,
# module 1 (whole farm, catastrophic only) cheaper than module 2.
SPAIN_MODULE_FACTORS = {"2": 1.0, "1": 0.7, "P": 0.35}

# Calibration (Agroseguro annual report 2024): imputed premium of the agricultural + livestock lines (groups A + B)
# 935.09 M EUR; agricultural share of the insured production 74.08 % of 18 173.39 M EUR. The livestock share of
# the A + B premium is OUR ESTIMATE (10 %).
SPAIN_CALIBRATION = {"premiumAB": 935.09e6, "livestockShare": 0.10, "insuredValue": 18173.39e6,
                     "agriculturalShare": 0.7408, "areaHa": 5.98e6, "year": 2024}

# ============================================================================
# ITALY  -  PGRA 2026 (MASAF) + ISMEA figures
# ============================================================================

ITALY_OUTPUT_XML = os.path.join(TOOLS_DIR, "..", "DB", "CropInsurance_IT.xml")

# Peril groups of the PGRA (unchanged since the 2015 plans).
ITALY_PERILS = {
    "catastrophic": ["FLOOD", "DROUGHT", "FROST"],                       # alluvione, siccita, gelo e brina
    "frequency":    ["SNOW", "HEAVY_RAIN", "HAIL", "WINDSTORM"],         # eccesso di neve / pioggia, grandine, venti forti
    "accessory":    ["HEAT_WIND", "TEMPERATURE_SWING"],                  # colpo di sole e vento caldo, sbalzo termico
}
ITALY_THRESHOLD = 0.20
# PGRA 2026 policy types (crops): (id, required groups, public contribution). Type c: 70 % with >= 3 frequency
# perils, 65 % with 1 - 2. Type f "simplified" (SMART): quantitative loss only, fixed 70 %.
ITALY_POLICY_TYPES = [
    ("a", "catastrophic frequency accessory", 0.70, "all risk"),
    ("b", "catastrophic frequency>=1", 0.70, "catastrophic + at least one frequency peril"),
    ("c", "frequency>=3", 0.70, "frequency perils (3 or more)"),
    ("c2", "frequency 1-2", 0.65, "frequency perils (1 or 2)"),
    ("d", "catastrophic", 0.70, "catastrophic perils only"),
    ("f", "simplified", 0.70, "SMART simplified policy, quantitative loss only"),
]
# Relative rate of each policy type vs. type a (all risk), OUR ESTIMATES. ISMEA: SMART costs ~50 % less.
ITALY_TYPE_FACTORS = {"a": 1.0, "b": 0.85, "c": 0.60, "c2": 0.45, "d": 0.40, "f": 0.50}
# AgriCat (catastrophic fund, financed from direct payments): uninsured / frequency-only farms: 20 % franchise,
# max 55 % indemnity (gross of franchise), loss must exceed 20 % of the average production. With a catastrophic
# policy (a, b, d, e) the fund adds on top: franchise 10 %, limit 40 %, if the policy has franchise >= 40 % and
# indemnity limit >= 80 %.
ITALY_AGRICAT = {"uninsuredFranchise": 0.20, "uninsuredMaxIndemnity": 0.55, "threshold": 0.20,
                 "withPolicyFranchise": 0.10, "withPolicyLimit": 0.40, "policyMinFranchise": 0.40,
                 "policyMinLimit": 0.80, "budget2026": 253e6}
ITALY_BUDGET_2026 = 300e6          # PSP 2023-2027 resources for subsidised policies available for 2026

# ISMEA 2025 campaign (Terra e Vita, Askanews): crops.
ITALY_TOTALS_2025 = {"insuredValueCrops": 7.09e9, "insuredValueAll": 9.941e9, "hectares": 1222985,
                     "farms": 57047, "averageRate": 0.0895, "northShare": 0.80, "centreShare": 0.09,
                     "southShare": 0.11, "packageCShare": 0.65}
ITALY_CROP_VALUES_2025 = {"vine": 2.0e9, "rice": 0.732e9, "tomato": 0.728e9, "apples": 0.535e9}

ITALY_CROPS = {
    "WHEAT": "cereals", "BARLEY": "cereals", "OAT": "cereals", "SORGHUM": "cereals",
    "MAIZE": "maize", "SUNFLOWER": "oilseeds", "CANOLA": "oilseeds", "SOYBEAN": "oilseeds",
    "PEA": "legumes", "GREENBEAN": "vegetables",
    "RICE": "rice", "RICELONGGRAIN": "rice",
    "POTATO": "potatoes", "SUGARBEET": "sugarbeet",
    "CARROT": "vegetables", "PARSNIP": "vegetables", "REDBEET": "vegetables", "SPINACH": "vegetables",
    "GRASS": "forage", "GRAPE": "vine", "OLIVE": "olive",
    "DEFAULT": "cereals",
}
ITALY_BORROWED = {"SORGHUM"}

# Per crop group, OUR ESTIMATES: sum insured per ha (EUR), rate of an all-risk (type a) policy before
# calibration, share of the insured crop value (vine / rice / tomato / apples from ISMEA 2025, rest estimated).
ITALY_GROUPS = {
    #              sumPerHa  rate    valueShare
    "vine":       (12000,   0.100,  0.282),
    "rice":       (2800,    0.050,  0.103),
    "vegetables": (12000,   0.070,  0.103),    # processing tomato is the bulk
    "fruit":      (20000,   0.140,  0.180),    # apples 0.075 + pears, stone fruit, kiwi
    "cereals":    (1500,    0.050,  0.090),
    "maize":      (2500,    0.060,  0.090),
    "oilseeds":   (1300,    0.050,  0.030),
    "legumes":    (1200,    0.060,  0.010),
    "potatoes":   (8000,    0.060,  0.020),
    "sugarbeet":  (3000,    0.050,  0.010),
    "olive":      (4000,    0.060,  0.050),
    "forage":     (1000,    0.040,  0.032),
}

# ============================================================================
# AUSTRALIA  -  private market, state taxes (edit when newer figures are out)
# ============================================================================

AUSTRALIA_OUTPUT_XML = os.path.join(TOOLS_DIR, "..", "DB", "CropInsurance_AU.xml")

AUSTRALIA_GST = 0.10
# Stamp duty on general insurance (Insurance Council of Australia 2019, from NSW Treasury interstate comparison)
# and crop exemptions: NSW since 1 Jan 2018 (Revenue NSW / Allianz), VIC since 1 Jul 2017 (SRO Victoria,
# Duties Act 2000 s.196; an older report says oilseed / legume hail cover still paid the full rate - unclear).
AUSTRALIA_STATES = {
    "NSW": {"name": "New South Wales", "stampDuty": 0.09, "cropExempt": True, "since": 2018},
    "VIC": {"name": "Victoria", "stampDuty": 0.10, "cropExempt": True, "since": 2017},
    "QLD": {"name": "Queensland", "stampDuty": 0.09, "cropExempt": False},
    "SA":  {"name": "South Australia", "stampDuty": 0.11, "cropExempt": False},
    "WA":  {"name": "Western Australia", "stampDuty": 0.10, "cropExempt": False},
    "TAS": {"name": "Tasmania", "stampDuty": 0.10, "cropExempt": False},
    "NT":  {"name": "Northern Territory", "stampDuty": 0.10, "cropExempt": False},
    "ACT": {"name": "Australian Capital Territory", "stampDuty": 0.0, "cropExempt": False},
}
AUSTRALIA_NAMED_PERILS = ["HAIL", "FIRE"]
AUSTRALIA_OPTIONAL_PERILS = ["FROST"]
# Deloitte "Multi-peril crop insurance in Australia: barriers and opportunities".
AUSTRALIA_RANGES = {"namedPerilMin": 0.0055, "namedPerilMax": 0.035, "multiPerilMin": 0.05, "multiPerilMax": 0.10}

AUSTRALIA_CROPS = {
    "WHEAT": "cereals", "BARLEY": "cereals", "OAT": "cereals",
    "SORGHUM": "sorghum", "MAIZE": "sorghum",
    "CANOLA": "canola", "SUNFLOWER": "canola",
    "SOYBEAN": "pulses", "PEA": "pulses", "GREENBEAN": "vegetables",
    "COTTON": "cotton", "SUGARCANE": "sugarcane", "RICE": "rice", "RICELONGGRAIN": "rice",
    "POTATO": "vegetables", "SUGARBEET": "vegetables",
    "CARROT": "vegetables", "PARSNIP": "vegetables", "REDBEET": "vegetables", "SPINACH": "vegetables",
    "GRASS": "pasture", "GRAPE": "vine", "OLIVE": "fruit", "BANANA": "fruit",
    "DEFAULT": "cereals",
}
AUSTRALIA_BORROWED = {"MAIZE", "SUNFLOWER", "SUGARBEET", "OLIVE"}

# Per crop group, OUR ESTIMATES: sum insured per ha (AUD, Australian yields x prices), named-peril (hail + fire)
# rate, multi-peril rate where it is offered at all (None = not offered).
AUSTRALIA_GROUPS = {
    #              sumPerHa  named   multiPeril
    "cereals":    (900,     0.015,  0.07),
    "sorghum":    (1000,    0.020,  0.08),
    "canola":     (1050,    0.025,  0.08),
    "pulses":     (900,     0.025,  0.09),
    "rice":       (4000,    0.010,  None),
    "cotton":     (6000,    0.020,  None),
    "sugarcane":  (3800,    0.006,  None),     # mostly fire cover
    "vegetables": (15000,   0.030,  None),
    "pasture":    (500,     0.0055, None),     # fire only
    "vine":       (8000,    0.035,  None),
    "fruit":      (30000,   0.035,  None),
}

# ============================================================================
# ARGENTINA  -  SSN survey 2024 + provincial schemes (edit when newer figures are out)
# ============================================================================

ARGENTINA_OUTPUT_XML = os.path.join(TOOLS_DIR, "..", "DB", "CropInsurance_AR.xml")

# SSN "Encuesta de Seguros en los Sectores Agropecuario y Forestal 2024" (July 2023 - June 2024), via 100% Seguro
# and El Seguro en Accion: premiums 357 152 M ARS, insured capital 9.2 billion (10^12) ARS, 24 M ha, 188 000
# policies, claims paid 328 437 M ARS, loss ratio 88.9 % (2023: ~102.9 %), combined ratio 121.5 %.
ARGENTINA_TOTALS_2024 = {"premiumArs": 357152e6, "capitalArs": 9.2e12, "hectares": 24e6, "policies": 188000,
                         "claimsArs": 328437e6, "lossRatio": 0.889, "lossRatio2023": 1.029, "combinedRatio": 1.215,
                         "soyHectares": 8.1e6, "soyPremiumArs": 204e9}
# Share of premiums by cover (same survey).
ARGENTINA_COVER_SHARES = {"hail": 0.666, "hailPlus": 0.323, "multiPeril": 0.011}
ARGENTINA_HAILPLUS_FACTOR = 1.25        # OUR ESTIMATE: hail + additional perils vs. hail only
ARGENTINA_MULTIPERIL_RATE = 0.08        # OUR ESTIMATE (multi-peril is rare and expensive)

# Province shares (premium, insured capital). Cordoba's capital share is not published: it is the capital not
# held by BA / SF minus the other provinces, whose capital share is taken equal to their premium share (OUR
# ESTIMATE), giving ~22.7 %.
ARGENTINA_PROVINCES = {
    "BA": {"name": "Buenos Aires", "premiumShare": 0.367, "capitalShare": 0.433},
    "SF": {"name": "Santa Fe", "premiumShare": 0.200, "capitalShare": 0.216},
    "CB": {"name": "Cordoba", "premiumShare": 0.310, "capitalShare": None, "insuredHa": 10.9e6},
}
# Provincial schemes.
ARGENTINA_SCHEMES = {
    "MZ": {"name": "Mendoza", "scheme": "Fondo Compensador Agricola", "perils": "HAIL FROST",
           "subsidy": 0.80, "maxFarmHa": 30, "totalLossHailPerHaArs": 2000000,
           "note": "province pays ~80 % of the premium (2025 press; an older official page says 100 %)"},
    "CB": {"name": "Cordoba", "scheme": "Seguro Multirriesgo Agricola (pilot)", "perils": "DROUGHT FROST",
           "subsidy": 1.0, "crops": "SOYBEAN MAIZE", "coveredHa": 550000,
           "note": "free multi-peril pilot, seven perils incl. drought and frost; 2025/26: 276 M ARS paid to 22 farms"},
}

ARGENTINA_CROPS = {
    "SOYBEAN": "soybean", "MAIZE": "maize", "WHEAT": "wheat", "BARLEY": "barley", "OAT": "barley",
    "SUNFLOWER": "sunflower", "CANOLA": "sunflower", "SORGHUM": "sorghum",
    "PEA": "pulses", "GREENBEAN": "pulses", "COTTON": "cotton", "SUGARCANE": "sugarcane",
    "RICE": "rice", "RICELONGGRAIN": "rice", "POTATO": "vegetables", "SUGARBEET": "vegetables",
    "CARROT": "vegetables", "PARSNIP": "vegetables", "REDBEET": "vegetables", "SPINACH": "vegetables",
    "GRASS": "pasture", "GRAPE": "vine", "OLIVE": "fruit",
    "DEFAULT": "soybean",
}
ARGENTINA_BORROWED = {"OAT", "CANOLA", "SUGARBEET", "OLIVE"}

# Per crop group, OUR ESTIMATES: sum insured per ha (USD, Argentine yields x prices), hail rate before
# calibration, share of the insured capital (for the calibration; soybean is ~57 % of premiums).
ARGENTINA_GROUPS = {
    #              sumPerHa  hail    capitalShare
    "soybean":    (870,     0.040,  0.45),
    "maize":      (1350,    0.030,  0.30),
    "wheat":      (630,     0.035,  0.15),
    "sunflower":  (660,     0.040,  0.05),
    "barley":     (700,     0.035,  0.03),
    "sorghum":    (720,     0.035,  0.01),
    "pulses":     (700,     0.040,  0.003),
    "cotton":     (1100,    0.030,  0.003),
    "sugarcane":  (2500,    0.015,  0.002),
    "rice":       (1600,    0.020,  0.002),
    "vegetables": (8000,    0.060,  0.0),
    "pasture":    (300,     0.020,  0.0),
    "vine":       (8000,    0.080,  0.0),       # Mendoza / San Juan: heavy hail
    "fruit":      (15000,   0.080,  0.0),       # Rio Negro / Neuquen apples and pears
}

# ============================================================================
# CHILE  -  Agroseguros subsidy rules (edit when newer figures are out)
# ============================================================================

CHILE_OUTPUT_XML = os.path.join(TOOLS_DIR, "..", "DB", "CropInsurance_CL.xml")

# ChileAtiende "Subsidio al seguro agricola" + agroseguros.gob.cl.
CHILE_PERILS = ["DROUGHT", "HEAVY_RAIN", "FROST", "WINDSTORM", "HAIL", "SNOW"]   # drought: rain-fed land only
CHILE_SUBSIDY = {"base": 0.40, "fixedPerPolicyUf": 1.0, "maxPerPolicyUf": 80, "maxPerCropCommuneUf": 80,
                 "maxPerFarmerUf": 160, "maxShareOfNetPremium": 0.98, "typicalMax": 0.69}
CHILE_BONUSES = {"renewalMin": 0.02, "renewalMax": 0.10, "collective": 0.04, "smallPolicy": 0.05,
                 "smallPolicyMaxInsuredUf": 1000, "cereals": 0.05, "extremeZone": 0.05}
# Farmers without a tax start but with INDAP / BancoEstado credit: insured value <= 250 UF per season; INDAP
# adds its own complementary subsidy (amount not published on the pages used).
CHILE_INDAP = {"maxInsuredUfWithoutTaxStart": 250, "complementarySubsidy": "yes, amount not published"}
# DIPRES evaluation (Agroseguros 2024): 2.8 % of the sown area insured in 2023, < 7 % of farms; average cost
# ~7.2 UF/ha. Ministry of Agriculture (answer to the Chamber of Deputies): fruit 2014 net premium 24 234 UF on
# 464 998 UF insured (5.2 %), 2017 113 836 UF on 4 448 581 UF (2.6 %). Mundoagro example rate 4.3 %.
CHILE_STATS = {"insuredAreaShare2023": 0.028, "farmShare2023": 0.07, "avgCostPerHaUf": 7.2,
               "fruitRate2014": 24234 / 464998, "fruitRate2017": 113836 / 4448581, "exampleRate": 0.043}

CHILE_CROPS = {
    "WHEAT": "cereals", "BARLEY": "cereals", "OAT": "cereals", "SORGHUM": "cereals",
    "MAIZE": "maize", "CANOLA": "rapeseed", "SUNFLOWER": "rapeseed",
    "SOYBEAN": "legumes", "PEA": "legumes", "GREENBEAN": "vegetables",
    "RICE": "rice", "RICELONGGRAIN": "rice",
    "POTATO": "potatoes", "SUGARBEET": "sugarbeet",
    "CARROT": "vegetables", "PARSNIP": "vegetables", "REDBEET": "vegetables", "SPINACH": "vegetables",
    "GRASS": "forage", "GRAPE": "vine", "OLIVE": "olive",
    "DEFAULT": "cereals",
}
CHILE_BORROWED = {"SORGHUM", "SUNFLOWER", "SOYBEAN"}
CHILE_CEREAL_GROUPS = {"cereals", "maize", "rice"}   # get the +5 % cereals bonus

# Per crop group, OUR ESTIMATES: sum insured per ha (UF, Chilean yields x prices at ~39 000 CLP per UF), rate.
CHILE_GROUPS = {
    #              sumPerHaUf  rate
    "cereals":    (50,        0.045),     # rain-fed wheat incl. drought
    "maize":      (74,        0.035),
    "rapeseed":   (58,        0.045),
    "legumes":    (30,        0.050),
    "rice":       (60,        0.035),
    "potatoes":   (225,       0.045),
    "sugarbeet":  (130,       0.035),
    "vegetables": (250,       0.050),
    "forage":     (25,        0.040),
    "vine":       (300,       0.035),
    "fruit":      (600,       0.040),     # cherries, apples, blueberries ...
    "olive":      (150,       0.035),
}

# ============================================================================
# UNITED KINGDOM  -  private market (edit when newer figures are out)
# ============================================================================

UK_OUTPUT_XML = os.path.join(TOOLS_DIR, "..", "DB", "CropInsurance_GB.xml")

UK_IPT = 0.12                      # Insurance Premium Tax, standard rate (HMRC), on the premium
UK_PERILS = ["HAIL", "FIRE"]
UK_OPTIONAL_PERILS = ["WINDSTORM"]
# Northern Ireland Assembly research paper "Agricultural insurance": premium rates ~1 % of the insured value in
# the UK and Germany (6 - 8 % in Spain, Portugal, Italy); hail / single-peril products, no public support.
# Farmers Weekly ("You can't stop the hail ...", 1990s): high-risk area hail cover ~GBP 1.08 - 1.24 / acre for
# wheat, GBP 5.50 / acre for oilseed rape - too old for prices, used only for the cereal / rape ratio.
UK_REFERENCE = {"averageRate": 0.01}

UK_CROPS = {
    "WHEAT": "cereals", "BARLEY": "cereals", "OAT": "cereals", "SORGHUM": "cereals",
    "CANOLA": "rapeseed", "SUNFLOWER": "rapeseed", "MAIZE": "maize",
    "SOYBEAN": "pulses", "PEA": "pulses", "GREENBEAN": "vegetables",
    "POTATO": "potatoes", "SUGARBEET": "sugarbeet",
    "CARROT": "vegetables", "PARSNIP": "vegetables", "REDBEET": "vegetables", "SPINACH": "vegetables",
    "GRASS": "grass", "GRAPE": "fruit", "OLIVE": "fruit",
    "DEFAULT": "cereals",
}
UK_BORROWED = {"SORGHUM", "SUNFLOWER", "SOYBEAN", "GRAPE", "OLIVE"}

# Per crop group, OUR ESTIMATES: sum insured per ha (GBP, UK yields x prices), hail + fire rate.
UK_GROUPS = {
    #              sumPerHa  rate
    "cereals":    (1600,    0.006),
    "rapeseed":   (1350,    0.020),    # pods shatter in hail: several times the cereal rate
    "maize":      (1400,    0.008),
    "pulses":     (1000,    0.015),
    "potatoes":   (9000,    0.010),
    "sugarbeet":  (2400,    0.005),
    "vegetables": (10000,   0.020),
    "grass":      (700,     0.003),    # fire only
    "fruit":      (20000,   0.040),    # top fruit: hail + frost
}

# ============================================================================
# SOUTH-EAST ASIA  -  state rice schemes (Hutan Pantai)
# ============================================================================

SEA_OUTPUT_XML = os.path.join(TOOLS_DIR, "..", "DB", "CropInsurance_SEA.xml")

# Indonesia: AUTP (Asuransi Usaha Tani Padi), Ministry of Agriculture + Jasindo. Premium Rp 180 000 / ha / season,
# government pays 80 % (farmer Rp 36 000), sum insured Rp 6 000 000 / ha / season; perils: pests and plant
# diseases, flood, drought (Jasindo via Kontan / IDX Channel, 2025). ~305 000 ha protected in 2024.
# Claim threshold: payouts are commonly stated to start at >= 75 % damage - NOT confirmed in the sources used.
# Malaysia: Skim Takaful Tanaman Padi (Agrobank + KPKM, from Sept 2024): up to RM 3 000 / ha / season for natural
# disasters (e.g. flood), RM 1 500 for pests / diseases; premium RM 120 / ha / year (two seasons), paid by the
# government in the first year (Bernama, NST). Drought not confirmed.
SEA_SCHEMES = {
    "IDN": {"name": "Indonesia", "scheme": "Asuransi Usaha Tani Padi (AUTP)", "currency": "IDR",
            "premiumPerHa": 180000, "subsidy": 0.80, "sumInsuredPerHa": 6000000, "perils": "PESTS FLOOD DROUGHT",
            "damageThreshold": 0.75, "damageThresholdIsEstimate": True, "insuredHa2024": 305000, "default": True},
    "MYS": {"name": "Malaysia", "scheme": "Skim Takaful Tanaman Padi", "currency": "MYR",
            "premiumPerHa": 60, "subsidy": 1.0, "sumInsuredPerHa": 3000, "pestSumInsuredPerHa": 1500,
            "perils": "FLOOD PESTS", "subsidyNote": "government pays the premium in the first year"},
}
SEA_INSURED_CROPS = {"RICE", "RICELONGGRAIN"}
SEA_OTHER_CROPS = ["WHEAT", "BARLEY", "OAT", "SORGHUM", "MAIZE", "CANOLA", "SUNFLOWER", "SOYBEAN", "PEA",
                   "GREENBEAN", "POTATO", "SUGARBEET", "SUGARCANE", "COTTON", "CARROT", "PARSNIP", "REDBEET",
                   "SPINACH", "GRASS", "GRAPE", "OLIVE", "COFFEE", "BANANA", "DEFAULT"]

# ============================================================================
# REGION DETECTION  -  which profile a map uses (DB/InsuranceRegions.xml)
# ============================================================================

REGIONS_OUTPUT_XML = os.path.join(TOOLS_DIR, "..", "DB", "InsuranceRegions.xml")
MAP_COUNTRIES_CSV = os.path.join(TOOLS_DIR, "map_countries.csv")

# Country code -> (data file, region id in that file, display name).
REGION_PROFILES = {
    "US": ("CropInsurance_US.xml", "US", "United States"), "CA": ("CropInsurance_CA.xml", "CAN", "Canada"),
    "PL": ("CropInsurance_PL.xml", "POL", "Poland"), "BR": ("CropInsurance_BR.xml", "BRA", "Brazil"),
    "DE": ("CropInsurance_DE.xml", "DEU", "Germany"), "FR": ("CropInsurance_FR.xml", "FRA", "France"),
    "NL": ("CropInsurance_NL.xml", "NLD", "Netherlands"), "ES": ("CropInsurance_ES.xml", "ESP", "Spain"),
    "IT": ("CropInsurance_IT.xml", "ITA", "Italy"), "AU": ("CropInsurance_AU.xml", "AUS", "Australia"),
    "AR": ("CropInsurance_AR.xml", "ARG", "Argentina"), "CL": ("CropInsurance_CL.xml", "CHL", "Chile"),
    "GB": ("CropInsurance_GB.xml", "GBR", "United Kingdom"), "SEA": ("CropInsurance_SEA.xml", "SEA", "South-East Asia"),
}
REGION_DEFAULT = "US"            # most complete (real) data
# Countries without own data -> the closest profile (similar market / climate). EU = fictional European maps.
REGION_NEAREST = {
    "EU": "DE", "AT": "DE", "CH": "DE", "LU": "DE", "BE": "NL", "DK": "DE", "NO": "DE", "SE": "DE", "FI": "DE",
    "IE": "GB", "PT": "ES", "EE": "PL", "LV": "PL", "LT": "PL", "CZ": "PL", "SK": "PL", "HU": "PL", "RO": "PL",
    "SI": "DE", "HR": "IT", "RS": "PL", "UA": "PL", "RU": "PL", "ZA": "AU", "NZ": "AU", "UY": "AR", "PY": "AR",
    "MX": "US", "ASIA": "SEA", "SAM": "BR", "NONE": REGION_DEFAULT,
}
REGION_BASE_MAPS = {"MapUS": "US", "MapEU": "PL", "MapAS": "SEA"}
# Base-game climate reused by a mod map (path part of map.environment#filename).
REGION_ENVIRONMENTS = {"maps/mapUS/": "US", "maps/mapEU/": "EU", "maps/mapAS/": "SEA"}
# Keywords per country, matched as whole words (case-insensitive) in title + description; longest match wins.
# Deliberately not used: "english" / "british" (descriptions say "English version"), "america" alone
# ("South America"), "frisian" alone (Dutch and German Frisia), short place names that are common words.
REGION_KEYWORDS = {
    "DE": "germany, german, deutschland, deutsche, deutschen, bavaria, bayern, bavarian, saxony, sachsen, thuringia, "
          "thüringen, mecklenburg, brandenburg, westphalia, westfalen, niedersachsen, lower saxony, schleswig, holstein, "
          "east frisia, east frisian, north frisia, north frisian, ostfriesland, nordfriesland, palatinate, pfalz, swabia, "
          "schwaben, swabian, allgäu, eifel, rhön, harz, gdr, ddr, münsterland, sauerland, odenwald, baden-württemberg, "
          "württemberg, hessen, rhineland, rheinland, kiel canal, mühlenkreis",
    "PL": "poland, polish, polska, polski, polskiej, mazury, masuria, podlasie, kujawy, wielkopolska, pomerania, silesia",
    "FR": "france, french, français, française, normandy, normandie, brittany, bretagne, burgundy, bourgogne, jura, doubs, "
          "anjou, vosges, picardie, occitanie, auvergne, lorraine, alsace, limousin, charente",
    "GB": "england, scotland, scottish, wales, welsh, great britain, united kingdom, yorkshire, cotswolds, "
          "northern ireland, ulster, county antrim, county down, county armagh, tyrone, highlands, devon, cornwall, "
          "norfolk, suffolk, lincolnshire, lancashire, oxfordshire",
    "IE": "ireland, irish, republic of ireland",
    "NL": "netherlands, dutch, holland, nederland, nederlandse, friesland, groningen, drenthe, zeeland, overijssel, limburg",
    "BE": "belgium, belgian, flanders, wallonia",
    "IT": "italy, italian, italia, italiana, tuscany, toscana, lombardy, veneto, sicily, sardinia, po valley, piedmont",
    "ES": "spain, spanish, españa, andalusia, andalucía, castile, castilla, galicia, catalonia, aragon, extremadura",
    "PT": "portugal, portuguese", "AT": "austria, austrian, österreich, tyrol, tirol, tyrolean",
    "CH": "switzerland, swiss, schweiz, suisse, helvetian", "CZ": "czech, česko, bohemia, moravia",
    "SK": "slovakia, slovak", "HU": "hungary, hungarian, magyar, puszta", "RO": "romania, romanian, transylvania",
    "EE": "estonia, estonian, eesti", "LV": "latvia, latvian", "LT": "lithuania, lithuanian",
    "FI": "finland, finnish, suomi", "SE": "sweden, swedish", "NO": "norway, norwegian, norge, norsk",
    "DK": "denmark, danish", "UA": "ukraine, ukrainian", "RU": "russia, russian", "LU": "luxembourg",
    "US": "united states, usa, american midwest, midwest, new england, appalachia",
    "CA": "canada, canadian", "BR": "brazil, brasil, brazilian, brasileira, brasileiro, cerrado, matopiba",
    "AR": "argentina, argentine, argentino, pampa, pampas, patagonia", "CL": "chile, chilean",
    "UY": "uruguay", "PY": "paraguay", "AU": "australia, australian, outback", "NZ": "new zealand",
    "ZA": "south africa, south african", "SEA": "indonesia, malaysia, thailand, vietnam, philippines, south-east asia, "
          "southeast asia, hutan pantai", "ASIA": "japan, china, chinese, india, korea, asia, asian",
    "SAM": "south america, latin america",
}

# ============================================================================
# BRAZIL  -  MAPA PSR open data (SISSER)
# ============================================================================

BRAZIL_OUTPUT_XML = os.path.join(TOOLS_DIR, "..", "DB", "CropInsurance_BR.xml")
BRAZIL_DATA = os.path.join(TOOLS_DIR, "..", "BR_insurance", "dados_abertos_psr_2016a2024csv.csv")
BRAZIL_YEARS = [2020, 2021, 2022, 2023, 2024]   # 2025 file: year not complete, no claims yet
BRAZIL_COVERAGE_LEVELS = [0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85, 0.90, 0.95, 1.00]
BRAZIL_PLANS = {"PRODUTIVIDADE": "YP", "CUSTEIO": "COST"}
BRAZIL_MIN_HECTARES = 2000     # per crop / plan / level (summed over the years); state: per crop
BRAZIL_MIN_POLICIES = 30

# FS25 fill type -> PSR crop names (NM_CULTURA_GLOBAL). COFFEE / BANANA: South America DLC.
BRAZIL_CROPS = {
    "WHEAT":         ["Trigo"],
    "BARLEY":        ["Cevada"],
    "OAT":           ["Aveia"],
    "CANOLA":        ["Canola"],
    "SORGHUM":       ["Sorgo"],
    "SUNFLOWER":     ["Girassol"],
    "SOYBEAN":       ["Soja"],
    "MAIZE":         ["Milho 1ª safra", "Milho 2ª safra"],
    "POTATO":        ["Batata"],
    "SUGARCANE":     ["Cana-de-açúcar"],
    "COTTON":        ["Algodão"],
    "RICE":          ["Arroz"],
    "RICELONGGRAIN": ["Arroz"],
    "GRAPE":         ["Uva"],
    "GREENBEAN":     ["Feijão 1ª safra", "Feijão 2ª safra", "Vagem"],
    "CARROT":        ["Cenoura"],
    "REDBEET":       ["Beterraba"],
    "COFFEE":        ["Café"],
    "BANANA":        ["Banana"],
}
BRAZIL_PROXY_CROPS = {
    "SUGARBEET": "REDBEET",   # sugar beet is not grown in Brazil
    "PEA": "GREENBEAN",
    "SPINACH": "CARROT",
    "PARSNIP": "CARROT",
    "OLIVE": "GRAPE",
}
BRAZIL_DEFAULT = {"Soja", "Milho 1ª safra", "Milho 2ª safra", "Trigo", "Arroz", "Sorgo", "Cevada", "Aveia",
                  "Feijão 1ª safra", "Feijão 2ª safra", "Algodão", "Canola", "Girassol", "Triticale"}

# Cause of loss (EVENTO_PREPONDERANTE) -> peril id.
BRAZIL_PERILS = {
    "SECA": "DROUGHT", "GRANIZO": "HAIL", "GEADA": "FROST", "CHUVA EXCESSIVA": "EXCESS_RAIN",
    "VENTOS FORTES/FRIOS": "WINDSTORM", "INUNDAÇÃO/TROMBA D´ÁGUA": "FLOOD",  # written with an acute accent, not an apostrophe
    "VARIAÇÃO EXCESSIVA DE TEMPERATURA": "TEMPERATURE", "INCÊNDIO": "FIRE", "RAIO": "LIGHTNING",
    "QUEDA DE PARREIRAL": "TRELLIS_COLLAPSE",
}

BRAZIL_STATES = {
    "AC": "Acre", "AL": "Alagoas", "AP": "Amapá", "AM": "Amazonas", "BA": "Bahia", "CE": "Ceará",
    "DF": "Distrito Federal", "ES": "Espírito Santo", "GO": "Goiás", "MA": "Maranhão", "MT": "Mato Grosso",
    "MS": "Mato Grosso do Sul", "MG": "Minas Gerais", "PA": "Pará", "PB": "Paraíba", "PR": "Paraná",
    "PE": "Pernambuco", "PI": "Piauí", "RJ": "Rio de Janeiro", "RN": "Rio Grande do Norte",
    "RS": "Rio Grande do Sul", "RO": "Rondônia", "RR": "Roraima", "SC": "Santa Catarina", "SP": "São Paulo",
    "SE": "Sergipe", "TO": "Tocantins",
}
# North and Northeast regions get the higher subsidy.
BRAZIL_NORTH_NORTHEAST = {"AC", "AP", "AM", "PA", "RO", "RR", "TO",
                          "AL", "BA", "CE", "MA", "PB", "PE", "PI", "RN", "SE"}
# Plano Trienal do Seguro Rural 2025-2027 (CGSR): subsidy share and annual limits per farmer (BRL).
BRAZIL_PROGRAM = {"subsidySoy": 0.20, "subsidyOther": 0.40, "subsidySoyNorthNortheast": 0.30,
                  "subsidyOtherNorthNortheast": 0.45, "maxSubsidyPerModality": 60000,
                  "maxSubsidyPerFarmer": 120000}

# ============================================================================
# READING
# ============================================================================

# Column indexes (record layout "Crop Insurance Experience with Coverage Level - 1989 Forward")
C_YEAR, C_STATE_CODE, C_STATE, C_COUNTY_CODE, C_COUNTY, C_COMMODITY_CODE, C_COMMODITY = range(7)
C_PLAN_CODE, C_PLAN, C_CATEGORY, C_DELIVERY, C_LEVEL = 7, 8, 9, 10, 11
C_POL_SOLD, C_POL_EARNING, C_POL_INDEMNIFIED, C_UNITS_EARNING, C_UNITS_INDEMNIFIED = 12, 13, 14, 15, 16
C_QTY_TYPE, C_QTY, C_ENDORSED, C_LIABILITY, C_PREMIUM, C_SUBSIDY, C_STATE_SUBSIDY = 17, 18, 19, 20, 21, 22, 23
C_ADD_SUBSIDY, C_EFA, C_INDEMNITY, C_LOSS_RATIO = 24, 25, 26, 27
NUM_COLUMNS = 28


def open_year(year):
    """Lines of sobcov_<year>.txt from the extracted folder, the folder root or the zip."""
    name = "sobcov_%d.txt" % year
    for path in (os.path.join(DATA_DIR, "sobcov_%d" % year, name), os.path.join(DATA_DIR, name)):
        if os.path.isfile(path):
            with open(path, encoding="latin-1") as f:
                for line in f:
                    yield line
            return
    zpath = os.path.join(DATA_DIR, "sobcov_%d.zip" % year)
    if os.path.isfile(zpath):
        with zipfile.ZipFile(zpath) as z:
            member = next((n for n in z.namelist() if n.lower().endswith(".txt")), None)
            if member is None:
                sys.exit("[ERROR] %s contains no .txt file" % zpath)
            with z.open(member) as f:
                for raw in f:
                    yield raw.decode("latin-1")
        return
    sys.exit("[ERROR] No data for %d: expected %s (folder or zip) in %s" % (year, name, os.path.abspath(DATA_DIR)))


def num(text):
    text = text.strip()
    if text == "":
        return 0.0
    return float(text)


class Totals:
    __slots__ = ("acres", "liability", "premium", "subsidy", "indemnity", "policies", "indemnified", "rows")

    def __init__(self):
        self.acres = self.liability = self.premium = self.subsidy = self.indemnity = 0.0
        self.policies = self.indemnified = 0.0
        self.rows = 0

    def add(self, acres, liability, premium, subsidy, indemnity, policies, indemnified):
        self.acres += acres
        self.liability += liability
        self.premium += premium
        self.subsidy += subsidy
        self.indemnity += indemnity
        self.policies += policies
        self.indemnified += indemnified
        self.rows += 1


def load():
    commodity_to_crops = defaultdict(list)
    for crop, names in CROPS.items():
        for name in names:
            commodity_to_crops[name.lower()].append(crop)
    default_names = {n.lower() for n in DEFAULT_COMMODITIES}
    levels = {("%.2f" % lv): lv for lv in COVERAGE_LEVELS}
    plans = set(PLANS)

    us = defaultdict(Totals)          # (crop, plan, level) -> Totals
    state = defaultdict(Totals)       # (state, crop, plan, level) -> Totals
    seen_commodities = defaultdict(float)
    skipped = defaultdict(int)

    for year in YEARS:
        t0 = time.time()
        rows = 0
        for line in open_year(year):
            p = line.rstrip("\r\n").split("|")
            if len(p) != NUM_COLUMNS:
                skipped["bad column count"] += 1
                continue
            if p[C_CATEGORY].strip() != "A":
                skipped["not buy-up (CAT etc.)"] += 1
                continue
            if p[C_QTY_TYPE].strip().lower() != "acres":
                skipped["not acres"] += 1
                continue
            plan = p[C_PLAN].strip().upper()
            if plan not in plans:
                skipped["other plan"] += 1
                continue
            level = levels.get("%.2f" % num(p[C_LEVEL]))
            if level is None:
                skipped["coverage level outside range"] += 1
                continue

            commodity = p[C_COMMODITY].strip()
            key = commodity.lower()
            crops = list(commodity_to_crops.get(key, []))
            if key in default_names:
                crops.append("DEFAULT")
            seen_commodities[commodity] += num(p[C_QTY])
            if not crops:
                skipped["commodity not used"] += 1
                continue

            acres = num(p[C_QTY])
            liability = num(p[C_LIABILITY])
            premium = num(p[C_PREMIUM])
            subsidy = num(p[C_SUBSIDY]) + num(p[C_STATE_SUBSIDY])
            indemnity = num(p[C_INDEMNITY])
            policies = num(p[C_POL_EARNING])
            indemnified = num(p[C_POL_INDEMNIFIED])
            st = p[C_STATE].strip().upper()
            for crop in crops:
                us[(crop, plan, level)].add(acres, liability, premium, subsidy, indemnity, policies, indemnified)
                state[(st, crop, plan, level)].add(acres, liability, premium, subsidy, indemnity, policies, indemnified)
            rows += 1
        print("  %d: %d rows used (%.1fs)" % (year, rows, time.time() - t0))

    print("  skipped rows: " + ", ".join("%s %d" % kv for kv in sorted(skipped.items())))
    return us, state, seen_commodities


# ============================================================================
# OUTPUT
# ============================================================================

def fmt(value, decimals=DECIMALS):
    text = ("%." + str(decimals) + "f") % value
    if "." in text:
        text = text.rstrip("0").rstrip(".")
    return text if text not in ("-0", "") else "0"


def state_names():
    """US_xx -> name from the climate file, so both files use the same region ids and names."""
    names = {}
    if os.path.isfile(CLIMATE_XML):
        with open(CLIMATE_XML, encoding="utf-8") as f:
            for m in re.finditer(r'<region id="US_([A-Z]{2})" name="([^"]+)"', f.read()):
                names[m.group(1)] = m.group(2)
    return names


def coverage_shape(level, cv=None):
    """Relative premium rate of yield cover at a coverage level, from a simple loss model.

    Yield ~ Normal(mean 1, sd cv); guarantee g = level; rate = expected shortfall E[max(g - Y, 0)] / g.
    With cv 0.30 the rate at 70 / 75 / 80 % is ~1.3 / 1.6 / 2.0 x the 65 % rate - the usual step-up of real
    rate tables (and close to the US data at 50 - 65 %, where selection does not distort it)."""
    cv = cv or COVERAGE_SHAPE_CV
    z = (level - 1.0) / cv
    pdf = math.exp(-0.5 * z * z) / math.sqrt(2 * math.pi)
    cdf = 0.5 * (1 + math.erf(z / math.sqrt(2)))
    return ((level - 1.0) * cdf + cv * pdf) / level


def shaped_rates(totals, levels=None, is_usable=None):
    """(crop, plan, level) -> (premiumRate, farmerRate), rising with the coverage level.

    The raw averages FALL at high coverage: low-risk farms buy high coverage (selection bias), while the
    loss ratio of those policies climbs (US / Brazil soybeans: payouts per $ of premium several times higher
    at 80 % than at 65 %). Real rate tables rise with coverage, so per crop and plan:
      premiumRate = the curve's liability-weighted average premium rate, spread over the levels by
                    coverage_shape (the average itself is kept);
      farmerRate  = premiumRate x (1 - the measured subsidy share at that level) - the subsidy share is set
                    per level by law (US: ~59 % at 70 %, ~38 % at 85 %) and is not distorted by selection."""
    levels = levels or COVERAGE_LEVELS
    is_usable = is_usable or usable
    result = {}
    for crop, plan in {(c, p) for (c, p, _) in totals}:
        rows = [(lv, totals[(crop, plan, lv)]) for lv in levels
                if (crop, plan, lv) in totals and is_usable(totals[(crop, plan, lv)])]
        if not rows:
            continue
        liability = sum(t.liability for _, t in rows)
        premium_avg = sum(t.premium for _, t in rows) / liability
        shape = [coverage_shape(lv) for lv, _ in rows]
        shape_avg = sum(t.liability * sh for (_, t), sh in zip(rows, shape)) / liability
        for (lv, t), sh in zip(rows, shape):
            rate = premium_avg * sh / shape_avg
            subsidy_share = min(max(t.subsidy / t.premium, 0.0), 1.0)
            result[(crop, plan, lv)] = (rate, rate * (1 - subsidy_share))
    return result


def level_attrs(t, rates, per="Acre", area="acres"):
    premium_rate, farmer_rate = rates
    subsidy_share = 1 - farmer_rate / premium_rate if premium_rate > 0 else 0
    farmer = t.premium - t.subsidy
    return ('premiumRate="%s" farmerRate="%s" subsidyShare="%s" lossRatio="%s" claimShare="%s" '
            'farmerPer%s="%s" %s="%d" policies="%d"' % (
                fmt(premium_rate), fmt(farmer_rate), fmt(subsidy_share, 3),
                fmt(t.indemnity / t.premium, 3), fmt(t.indemnified / t.policies if t.policies > 0 else 0, 3),
                per, fmt(farmer / t.acres, 2), area, round(t.acres), round(t.policies)))


def usable(t, min_acres=MIN_ACRES):
    return t.acres >= min_acres and t.policies >= MIN_POLICIES and t.liability > 0 and t.premium > 0


def write(us, state, out_path):
    names = state_names()
    crops = list(CROPS) + ["DEFAULT"]
    lines = ['<?xml version="1.0" encoding="utf-8" standalone="no" ?>',
             '<!-- Generated by tools/build_crop_insurance.py - do not edit by hand. -->',
             '<!-- Source: USDA RMA Summary of Business, State/County/Crop/Coverage Level, %d-%d (public domain). -->'
             % (min(YEARS), max(YEARS)),
             '<cropInsurance version="1" source="USDA RMA Summary of Business" years="%d-%d" currency="USD">'
             % (min(YEARS), max(YEARS))]

    # ---- US curves
    smooth = shaped_rates(us)
    us_rate = {}
    lines.append('    <region id="US" name="United States">')
    for crop in crops:
        plan_lines = []
        for plan in PLANS:
            level_lines = []
            for level in COVERAGE_LEVELS:
                t = us.get((crop, plan, level))
                if t is not None and usable(t):
                    us_rate[(crop, plan, level)] = smooth[(crop, plan, level)][0]
                    level_lines.append('                <level coverage="%s" %s/>' % (
                        fmt(level, 2), level_attrs(t, smooth[(crop, plan, level)])))
            if level_lines:
                plan_lines.append('            <plan id="%s"%s>' % (plan, (' shape="lossModel" shapeCv="%s"' % fmt(COVERAGE_SHAPE_CV, 2))))
                plan_lines += level_lines
                plan_lines.append('            </plan>')
        if plan_lines:
            rma = "all field crops" if crop == "DEFAULT" else ", ".join(CROPS[crop])
            lines.append('        <crop fillType=%s rma=%s>' % (quoteattr(crop), quoteattr(rma)))
            lines += plan_lines
            lines.append('        </crop>')
    for crop, source in PROXY_CROPS.items():
        if any(k[0] == source for k in us_rate):
            lines.append('        <crop fillType=%s borrowedFrom=%s/>' % (quoteattr(crop), quoteattr(source)))
    lines.append('    </region>')

    # ---- State factors (indirectly standardised against the US curves)
    per_state = defaultdict(lambda: defaultdict(lambda: [0.0, 0.0, 0.0, 0.0, 0.0]))  # st -> crop -> [acres, prem, expected, indem, policies]
    for (st, crop, plan, level), t in state.items():
        rate = us_rate.get((crop, plan, level))
        if rate is None:
            continue
        acc = per_state[st][crop]
        acc[0] += t.acres
        acc[1] += t.premium
        acc[2] += t.liability * rate
        acc[3] += t.indemnity
        acc[4] += t.policies
    num_states = 0
    for st in sorted(per_state):
        crop_lines = []
        for crop in crops:
            acc = per_state[st].get(crop)
            if acc is None or acc[0] < MIN_STATE_ACRES or acc[4] < MIN_POLICIES or acc[2] <= 0 or acc[1] <= 0:
                continue
            crop_lines.append('        <crop fillType=%s rateFactor="%s" lossRatio="%s" acres="%d"/>' % (
                quoteattr(crop), fmt(acc[1] / acc[2], 3), fmt(acc[3] / acc[1], 3), round(acc[0])))
        if crop_lines:
            num_states += 1
            lines.append('    <region id="US_%s" name=%s parent="US">' % (st, quoteattr(names.get(st, st))))
            lines += crop_lines
            lines.append('    </region>')
    lines.append('</cropInsurance>')
    lines.append('')

    out_path = os.path.abspath(out_path)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("wrote %s (%.0f KB, US + %d states)" % (out_path, os.path.getsize(out_path) / 1024, num_states))


def compute_us_rates(us):
    """(crop, plan, level) -> shaped total premium rate for usable US entries."""
    return {key: rates[0] for key, rates in shaped_rates(us).items()}


def compute_state_factors(state, us_rate):
    """state -> crop -> rateFactor (premium vs. the US curves for the same plans and levels)."""
    acc = defaultdict(lambda: defaultdict(lambda: [0.0, 0.0, 0.0, 0.0]))  # acres, premium, expected, policies
    for (st, crop, plan, level), t in state.items():
        rate = us_rate.get((crop, plan, level))
        if rate is None:
            continue
        a = acc[st][crop]
        a[0] += t.acres
        a[1] += t.premium
        a[2] += t.liability * rate
        a[3] += t.policies
    factors = defaultdict(dict)
    for st, crops in acc.items():
        for crop, a in crops.items():
            if a[0] >= MIN_STATE_ACRES and a[3] >= MIN_POLICIES and a[2] > 0 and a[1] > 0:
                factors[st][crop] = a[1] / a[2]
    return factors


def us_yield_rate(us_rate, crop, level):
    """US yield-cover rate for a crop at a coverage level: YP, else APH, nearest level with data, else DEFAULT."""
    for c in (crop, "DEFAULT"):
        for plan in ("YP", "APH"):
            levels = sorted(lv for (cc, pp, lv) in us_rate if cc == c and pp == plan)
            if levels:
                nearest = min(levels, key=lambda lv: abs(lv - level))
                return us_rate[(c, plan, nearest)], plan, c
    return None, None, None


def write_canada(us, state, out_path):
    us_rate = compute_us_rates(us)
    factors = compute_state_factors(state, us_rate)

    def shaped_rate(crop, province, level):
        base, _, _ = us_yield_rate(us_rate, crop, level)
        if base is None:
            return None
        neighbour = factors.get(CANADA_NEIGHBOUR[province], {})
        factor = neighbour.get(crop, neighbour.get("DEFAULT", 1.0))
        return base * factor

    # Calibrate on Saskatchewan: acre-weighted average rate at SCIC's coverage mix = SCIC's real average.
    target = sum(y[1] for y in SCIC_YEARS) / sum(y[0] for y in SCIC_YEARS)
    weighted = 0.0
    weight_sum = 0.0
    for crop, acres in SCIC_ACRES.items():
        for level, share in SCIC_COVERAGE_MIX.items():
            if crop in CANADA_MAX_70 and level > 0.70:
                continue
            rate = shaped_rate(crop, "SK", level)
            if rate is not None:
                weighted += acres * share * rate
                weight_sum += acres * share
    calibration = target / (weighted / weight_sum)
    loss_5y = sum(y[2] for y in SCIC_YEARS) / sum(y[1] for y in SCIC_YEARS)
    print("  Canada: SCIC average rate %.2f %%, US-shaped average %.2f %% -> calibration x%.3f" % (
        target * 100, weighted / weight_sum * 100, calibration))

    crops = list(CROPS) + ["DEFAULT"]
    lines = ['<?xml version="1.0" encoding="utf-8" standalone="no" ?>',
             '<!-- Generated by tools/build_crop_insurance.py - do not edit by hand. -->',
             '<!-- Sources: SCIC annual report 2024-25 (Saskatchewan Crop Insurance Corporation), AFSC 2026 hail rates -->',
             '<!-- (Agriculture Financial Services Corporation, Alberta); curve shapes from USDA RMA %d-%d (public domain). -->'
             % (min(YEARS), max(YEARS)),
             '<cropInsurance version="1" source="SCIC annual report 2024-25, AFSC, USDA RMA" years="2020-2024" currency="CAD">',
             '    <program plans="YP" coverageLevels="%s" producerShare="%s" max70=%s calibration="%s"/>' % (
                 " ".join(fmt(lv, 2) for lv in CANADA_COVERAGE_LEVELS), fmt(CANADA_PRODUCER_SHARE, 2),
                 quoteattr(" ".join(sorted(CANADA_MAX_70))), fmt(calibration, 3))]

    def region_lines(region_id, name, province, parent, hail):
        out = ['    <region id="%s" name=%s%s lossRatio="%s" lossRatio10y="%s" curvesFrom="US_%s">' % (
            region_id, quoteattr(name), (' parent="%s"' % parent) if parent else "", fmt(loss_5y, 3),
            fmt(SCIC_LOSS_RATIO_10Y, 2), CANADA_NEIGHBOUR[province])]
        for crop in crops:
            level_lines = []
            for level in CANADA_COVERAGE_LEVELS:
                if crop in CANADA_MAX_70 and level > 0.70:
                    continue
                rate = shaped_rate(crop, province, level)
                if rate is None:
                    continue
                rate *= calibration
                level_lines.append('                <level coverage="%s" premiumRate="%s" farmerRate="%s" subsidyShare="%s"/>' % (
                    fmt(level, 2), fmt(rate), fmt(rate * CANADA_PRODUCER_SHARE), fmt(1 - CANADA_PRODUCER_SHARE, 3)))
            if level_lines:
                out.append('        <crop fillType=%s>' % quoteattr(crop))
                out.append('            <plan id="YP"%s>' % (' shape="lossModel" shapeCv="%s"' % fmt(COVERAGE_SHAPE_CV, 2)))
                out += level_lines
                out.append('            </plan>')
                out.append('        </crop>')
        for crop, source in PROXY_CROPS.items():
            out.append('        <crop fillType=%s borrowedFrom=%s/>' % (quoteattr(crop), quoteattr(source)))
        if hail:
            out.append('        <hailPolicy rateMin="%s" rateTypical="%s" rateTypicalIsEstimate="true" rateMax="%s" '
                       'source="AFSC 2026 full cover hail rates (not official, not endorsed by AFSC)">' % (
                fmt(AFSC_HAIL["rateMin"], 3), fmt(AFSC_HAIL["rateTypical"], 3), fmt(AFSC_HAIL["rateMax"], 3)))
            for deductible, factor in AFSC_HAIL["deductibles"]:
                out.append('            <deductible share="%s" rateFactor="%s"/>' % (fmt(deductible, 2), fmt(factor, 2)))
            out.append('        </hailPolicy>')
        out.append('    </region>')
        return out

    # Canada-wide = Saskatchewan (by far the largest programme); provinces under it.
    lines += region_lines("CAN", "Canada", "SK", None, False)
    for province in sorted(CANADA_NEIGHBOUR):
        lines += region_lines("CAN_" + province, CANADA_NAMES[province], province, "CAN", province == "AB")
    lines.append('</cropInsurance>')
    lines.append('')

    out_path = os.path.abspath(out_path)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("wrote %s (%.0f KB, Canada + %d provinces)" % (out_path, os.path.getsize(out_path) / 1024, len(CANADA_NEIGHBOUR)))


def write_poland(out_path):
    """Poland: named-peril yield cover from published rules plus estimated rates. Needs no RMA data."""
    cal = POLAND_CALIBRATION
    target = cal["subsidyPaidPln"] * cal["cropShare"] / POLAND_SUBSIDY_SHARE / (cal["areaHa"] * cal["sumPerHaPln"])
    weighted = sum(POLAND_RATES_ESTIMATE[g]["package"] * w for g, w in cal["areaMix"].items()) / sum(cal["areaMix"].values())
    calibration = target / weighted
    print("  Poland: implied average rate %.2f %%, estimated package average %.2f %% -> calibration x%.3f" % (
        target * 100, weighted * 100, calibration))
    def rate_attrs(rates, group_cap):
        package = rates["package"] * calibration
        return 'package="%s" hail="%s" capped="%s"' % (
            fmt(package), fmt(rates["hail"]), "true" if package > group_cap else "false")

    lines = ['<?xml version="1.0" encoding="utf-8" standalone="no" ?>',
             '<!-- Generated by tools/build_crop_insurance.py - do not edit by hand. -->',
             '<!-- Sources: Ustawa o ubezpieczeniach upraw rolnych i zwierzat gospodarskich (Dz.U. 2025 poz. 251), -->',
             '<!-- gov.pl (Ministerstwo Rolnictwa i Rozwoju Wsi) 2026 subsidy and tariff rules, Dz.U. 2025 poz. 1628, Dz.U. 2024 poz. 1695. -->',
             '<!-- Rates marked isEstimate="true" are our own estimates, not official figures. -->',
             '<cropInsurance version="1" source="Polish law and gov.pl (MRiRW)" years="2024-%d" currency="EUR">'
             % POLAND_MAX_SUM_YEAR,
             '    <program type="namedPeril" subsidyShare="%s" capRule="subsidyUpToCap" eurPerPln="%s" '
             'calibration="%s" averageRate="%s" averageRateIsEstimate="true">' % (
                 fmt(POLAND_SUBSIDY_SHARE, 2), fmt(POLAND_EUR_PER_PLN), fmt(calibration, 3), fmt(target)),
             '        <rateCap group="field" share="%s"/>' % fmt(POLAND_RATE_CAP["field"], 3),
             '        <rateCap group="fruit" share="%s"/>' % fmt(POLAND_RATE_CAP["fruit"], 3),
             '        <rateCap group="animal" share="%s"/>' % fmt(POLAND_RATE_CAP["animal"], 3),
             '        <obligation areaShare="%s" feePerHa="%s" optional="true"/>' % (
                 fmt(POLAND_OBLIGATION["areaShare"], 2), fmt(POLAND_OBLIGATION["feePerHaEur"], 2))]
    for kind in ("mandatory", "optional"):
        for peril in POLAND_PERILS[kind]:
            lines.append('        <peril id="%s" %s="true"/>' % (peril, kind))
    for share, factor in POLAND_DEDUCTIBLES_ESTIMATE:
        lines.append('        <deductible share="%s" rateFactor="%s" isEstimate="true"/>' % (fmt(share, 2), fmt(factor, 2)))
    lines.append('    </program>')

    lines.append('    <region id="POL" name="Poland">')
    for crop, group in POLAND_CROPS.items():
        rates = POLAND_RATES_ESTIMATE[group]
        cap_group = rates["capGroup"]
        lines.append('        <crop fillType=%s group=%s%s maxSumPerHa="%s" maxSumPerHaPln="%s" capGroup="%s">' % (
            quoteattr(crop), quoteattr(group), ' borrowed="true"' if crop in POLAND_BORROWED else "",
            fmt(POLAND_MAX_SUM[group] * POLAND_EUR_PER_PLN, 0), POLAND_MAX_SUM[group], cap_group))
        lines.append('            <rates %s isEstimate="true"/>' % rate_attrs(rates, POLAND_RATE_CAP[cap_group]))
        for peril in ("WINDSTORM", "DROUGHT"):
            lines.append('            <addOn peril="%s" rate="%s" isEstimate="true"/>' % (peril, fmt(rates[peril])))
        lines.append('        </crop>')
    for animal, pln in POLAND_MAX_SUM_ANIMAL.items():
        lines.append('        <animal type=%s maxSumPerHead="%s" maxSumPerHeadPln="%s" rate="%s" isEstimate="true"/>' % (
            quoteattr(animal), fmt(pln * POLAND_EUR_PER_PLN, 0), pln, fmt(POLAND_ANIMAL_RATE_ESTIMATE)))
    lines.append('    </region>')
    lines.append('</cropInsurance>')
    lines.append('')

    out_path = os.path.abspath(out_path)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("wrote %s (%.1f KB, Poland, %d crops, %d animals)" % (
        out_path, os.path.getsize(out_path) / 1024, len(POLAND_CROPS), len(POLAND_MAX_SUM_ANIMAL)))


def write_germany(out_path):
    """Germany: private hail cover + add-ons, state subsidy programmes, estimated rates. Needs no raw data."""
    cal = GERMANY_CALIBRATION
    target = cal["premiumEur"] / cal["areaHa"]
    weighted = sum(GERMANY_GROUPS[g][0] * GERMANY_GROUPS[g][1] * w for g, w in cal["areaMix"].items()) \
        / sum(cal["areaMix"].values())
    calibration = target / weighted
    print("  Germany: market premium %.2f EUR/ha, estimated hail premium %.2f EUR/ha -> calibration x%.3f" % (
        target, weighted, calibration))

    lines = ['<?xml version="1.0" encoding="utf-8" standalone="no" ?>',
             '<!-- Generated by tools/build_crop_insurance.py - do not edit by hand. -->',
             '<!-- Sources: DLG-Merkblatt 434 (insurance tax), state subsidy rules (StMELF Bayern, Baden-Wuerttemberg, -->',
             '<!-- Niedersachsen, Sachsen), Vereinigte Hagel published figures. Values marked isEstimate="true" are our -->',
             '<!-- own estimates, not official figures. -->',
             '<cropInsurance version="1" source="German state programmes, DLG, Vereinigte Hagel" years="2022-2026" currency="EUR">',
             '    <program type="namedPeril" basePeril="HAIL" insuranceTax="%s" insuranceTaxBase="sumInsured" '
             'insuranceTaxPerils="%s" calibration="%s" averagePremiumPerHa="%s" averageIsEstimate="true">' % (
                 fmt(GERMANY_INSURANCE_TAX), " ".join(GERMANY_TAXED_PERILS), fmt(calibration, 3), fmt(target, 2))]
    for kind in ("base", "optional"):
        for peril in GERMANY_PERILS[kind]:
            lines.append('        <peril id="%s" %s="true"/>' % (peril, kind))
    lines.append('        <package perils="%s"/>' % " ".join(GERMANY_PACKAGE))
    for share, factor in GERMANY_DEDUCTIBLES_ESTIMATE:
        lines.append('        <deductible share="%s" rateFactor="%s" isEstimate="true"/>' % (fmt(share, 2), fmt(factor, 2)))
    lines.append('    </program>')

    lines.append('    <region id="DEU" name="Germany">')
    addon_ids = ["WINDSTORM", "HEAVY_RAIN", "SEVERE_FROST", "DROUGHT"]
    for crop, group in GERMANY_CROPS.items():
        sum_per_ha, hail = GERMANY_GROUPS[group][0], GERMANY_GROUPS[group][1] * calibration
        addons = dict(zip(addon_ids, GERMANY_GROUPS[group][2:]))
        package = hail + sum(addons.values())
        lines.append('        <crop fillType=%s group=%s%s sumPerHa="%d" sumPerHaIsEstimate="true">' % (
            quoteattr(crop), quoteattr(group), ' borrowed="true"' if crop in GERMANY_BORROWED else "", sum_per_ha))
        lines.append('            <rates hail="%s" package="%s" isEstimate="true"/>' % (fmt(hail), fmt(package)))
        for peril in addon_ids:
            lines.append('            <addOn peril="%s" rate="%s" isEstimate="true"/>' % (peril, fmt(addons[peril])))
        lines.append('        </crop>')
    lines.append('    </region>')

    for code, st in GERMANY_STATES.items():
        lines.append('    <region id="DEU_%s" name=%s parent="DEU">' % (code, quoteattr(st["name"])))
        attrs = ['share="%s"' % fmt(st["share"], 2)]
        for key in ("minDeductible", "maxPayoutShare"):
            if key in st:
                attrs.append('%s="%s"' % (key, fmt(st[key], 2)))
        for key in ("maxPerFarm", "since"):
            if key in st:
                attrs.append('%s="%d"' % (key, st[key]))
        if "minAreaHa" in st:
            attrs.append('minAreaHa="%s"' % fmt(st["minAreaHa"], 1))
        attrs.append('source=%s' % quoteattr(st["source"]))
        lines.append('        <stateSubsidy %s>' % " ".join(attrs))
        for pid, perils, min_perils, groups in st["packages"]:
            lines.append('            <package id="%s" perils="%s" minPerils="%d" groups="%s"/>' % (
                pid, perils, min_perils, groups))
        for group, value in st.get("maxSumPerHa", {}).items():
            lines.append('            <maxSum group="%s" perHa="%d"/>' % (group, value))
        lines.append('        </stateSubsidy>')
        lines.append('    </region>')
    lines.append('</cropInsurance>')
    lines.append('')

    out_path = os.path.abspath(out_path)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("wrote %s (%.1f KB, Germany + %d states)" % (out_path, os.path.getsize(out_path) / 1024, len(GERMANY_STATES)))


def write_france(out_path):
    """France: three-tier multi-risk system (MRC + ISN), estimated rates. Needs no raw data."""
    cal = FRANCE_CALIBRATION
    shares = FRANCE_INSURED_SHARE[cal["year"]]
    target = cal["subsidyPaidEur"] / FRANCE_SUBSIDY_SHARE

    def per_ha(group):
        return FRANCE_GROUPS[group][0] * FRANCE_GROUPS[group][1]

    estimated = 0.0
    for sector, area in cal["sectorAreaHa"].items():
        insured = area * shares[sector]
        if sector == "fieldCrops":
            mix = cal["fieldCropMix"]
            estimated += insured * sum(per_ha(g) * w for g, w in mix.items()) / sum(mix.values())
        else:
            estimated += insured * per_ha(cal["sectorGroup"][sector])
    calibration = target / estimated
    print("  France: subsidised premium %.0f M EUR, estimated %.0f M EUR -> calibration x%.3f" % (
        target / 1e6, estimated / 1e6, calibration))

    base_shape = coverage_shape(1 - FRANCE_FRANCHISES[0])
    lines = ['<?xml version="1.0" encoding="utf-8" standalone="no" ?>',
             '<!-- Generated by tools/build_crop_insurance.py - do not edit by hand. -->',
             '<!-- Sources: Ministere de l\'Agriculture (agriculture.gouv.fr, assurance recolte FAQ 2026), Assemblee -->',
             '<!-- nationale commission des affaires economiques (January 2026), La France Agricole. Values marked -->',
             '<!-- isEstimate="true" are our own estimates, not official figures. -->',
             '<cropInsurance version="1" source="French Ministry of Agriculture, Assemblee nationale" years="2024-2028" currency="EUR">',
             '    <program type="multiRisk" subsidyShare="%s" minPerils="%d" insuredYieldMin="%s" insuredYieldMax="%s" '
             'referenceYield="olympic5 average3" calibration="%s" isEstimate="true">' % (
                 fmt(FRANCE_SUBSIDY_SHARE, 2), FRANCE_MIN_PERILS, fmt(FRANCE_INSURED_YIELD[0], 2),
                 fmt(FRANCE_INSURED_YIELD[1], 2), fmt(calibration, 3))]
    # Deductible choices; the rate factor follows the same loss model as the coverage curves.
    for franchise in FRANCE_FRANCHISES:
        lines.append('        <franchise share="%s" rateFactor="%s" shape="lossModel"/>' % (
            fmt(franchise, 2), fmt(coverage_shape(1 - franchise) / base_shape, 3)))
    lines.append('        <hailOnly subsidised="false"/>')
    lines.append('    </program>')

    lines.append('    <solidarity id="ISN" stateShareInsured="0.9" insurerShareInsured="0.1">')
    for sector, isn in FRANCE_ISN.items():
        years = " ".join('%d:%s' % (y, fmt(r, 3)) for y, r in sorted(isn["uninsured"].items()))
        insured = "".join(' insuredShare%d="%s"' % (y, fmt(v[sector], 3))
                          for y, v in sorted(FRANCE_INSURED_SHARE.items()) if sector in v)   # none published: left out
        lines.append('        <sector id="%s" threshold="%s" uninsuredRates="%s"%s/>' % (
            sector, fmt(isn["threshold"], 2), years, insured))
    lines.append('    </solidarity>')

    lines.append('    <region id="FRA" name="France">')
    for crop, group in FRANCE_CROPS.items():
        sum_per_ha, multi, hail = FRANCE_GROUPS[group]
        lines.append('        <crop fillType=%s group=%s sector="%s"%s sumPerHa="%d" sumPerHaIsEstimate="true">' % (
            quoteattr(crop), quoteattr(group), FRANCE_SECTOR[group],
            ' borrowed="true"' if crop in FRANCE_BORROWED else "", sum_per_ha))
        lines.append('            <rates multiRisk="%s" hailOnly="%s" isEstimate="true"/>' % (
            fmt(multi * calibration), fmt(hail)))
        lines.append('        </crop>')
    lines.append('    </region>')
    lines.append('</cropInsurance>')
    lines.append('')

    out_path = os.path.abspath(out_path)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("wrote %s (%.1f KB, France, %d crops)" % (out_path, os.path.getsize(out_path) / 1024, len(FRANCE_CROPS)))


def write_netherlands(out_path):
    """Netherlands: subsidised broad weather insurance with a fixed subsidy pool. Needs no raw data."""
    lines = ['<?xml version="1.0" encoding="utf-8" standalone="no" ?>',
             '<!-- Generated by tools/build_crop_insurance.py - do not edit by hand. -->',
             '<!-- Sources: RVO (Rijksdienst voor Ondernemend Nederland) brede weersverzekering 2025 / 2026, Ecorys / WUR -->',
             '<!-- evaluation for the Ministry of LVVN (May 2024), Agriver. Values marked isEstimate="true" are our own -->',
             '<!-- estimates, not official figures. -->',
             '<cropInsurance version="1" source="RVO, Ecorys / WUR evaluation" years="2015-2026" currency="EUR">',
             '    <program type="multiRisk" threshold="%s" perils="%s" insuranceTaxExempt="true" '
             'lossRatioNorm="%s">' % (fmt(NETHERLANDS_THRESHOLD, 2), " ".join(NETHERLANDS_PERILS),
                                       fmt(NETHERLANDS_LOSS_RATIO_NORM, 2)),
             '        <subsidyPool budget="%d" maxShare="%s" rule="proRata"/>' % (
                 NETHERLANDS_BUDGET_EUR, fmt(NETHERLANDS_MAX_SUBSIDY, 3))]
    for year, (budget, paid, premium, share) in sorted(NETHERLANDS_HISTORY.items()):
        lines.append('        <year id="%d" budget="%s" subsidyPaid="%s" premium="%s" share="%s"/>' % (
            year, fmt(budget * 1e6, 0), fmt(paid * 1e6, 0), fmt(premium * 1e6, 0), fmt(share, 4)))
    lines.append('        <hailOnly subsidised="false" insuranceTax="%s"/>' % fmt(NETHERLANDS_INSURANCE_TAX, 2))
    lines.append('        <uptake %s/>' % " ".join('%s="%s"' % (k, fmt(v, 2)) for k, v in NETHERLANDS_UPTAKE.items()))
    lines.append('    </program>')

    lines.append('    <region id="NLD" name="Netherlands">')
    for crop, group in NETHERLANDS_CROPS.items():
        sum_per_ha, multi, hail = NETHERLANDS_GROUPS[group]
        lines.append('        <crop fillType=%s group=%s%s sumPerHa="%d" sumPerHaIsEstimate="true">' % (
            quoteattr(crop), quoteattr(group), ' borrowed="true"' if crop in NETHERLANDS_BORROWED else "", sum_per_ha))
        lines.append('            <rates multiRisk="%s" hailOnly="%s" isEstimate="true"/>' % (fmt(multi), fmt(hail)))
        lines.append('        </crop>')
    lines.append('    </region>')
    lines.append('</cropInsurance>')
    lines.append('')

    out_path = os.path.abspath(out_path)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("wrote %s (%.1f KB, Netherlands, %d crops)" % (out_path, os.path.getsize(out_path) / 1024, len(NETHERLANDS_CROPS)))


def write_spain(out_path):
    """Spain: Agroseguro modules with ENESA subsidies, estimated rates. Needs no raw data."""
    cal = SPAIN_CALIBRATION
    agri_value = cal["insuredValue"] * cal["agriculturalShare"]
    target = cal["premiumAB"] * (1 - cal["livestockShare"]) / agri_value
    weighted = sum(g[1] * g[2] for g in SPAIN_GROUPS.values()) / sum(g[2] for g in SPAIN_GROUPS.values())
    calibration = target / weighted
    print("  Spain: agricultural average rate %.2f %%, estimated %.2f %% -> calibration x%.3f" % (
        target * 100, weighted * 100, calibration))

    lines = ['<?xml version="1.0" encoding="utf-8" standalone="no" ?>',
             '<!-- Generated by tools/build_crop_insurance.py - do not edit by hand. -->',
             '<!-- Sources: 47th Plan de Seguros Agrarios Combinados (BOE-A-2025-27098), Agroseguro annual report 2024 and -->',
             '<!-- "Sistema espanol de Seguros Agrarios Combinados 2024". Values marked isEstimate="true" are our own -->',
             '<!-- estimates, not official figures. -->',
             '<cropInsurance version="1" source="ENESA plan 2026, Agroseguro" years="2014-2026" currency="EUR">',
             '    <program type="modules" maxSubsidy="%s" rateCap="%s" fixedDeduction="%d" canaryBaseUplift="%s" '
             'calibration="%s" averageRate="%s" averageRateIsEstimate="true" insuredAreaHa="%d">' % (
                 fmt(SPAIN_MAX_SUBSIDY, 2), fmt(SPAIN_RATE_CAP, 2), SPAIN_FIXED_DEDUCTION_EUR,
                 fmt(SPAIN_CANARY_BASE_UPLIFT, 2), fmt(calibration, 3), fmt(target), cal["areaHa"]),
             '        <module id="1" cover="whole farm, catastrophic" subsidy="%s" rateFactor="%s" isEstimate="true"/>' % (
                 fmt(SPAIN_MODULE1_SUBSIDY, 2), fmt(SPAIN_MODULE_FACTORS["1"], 2)),
             '        <module id="2" cover="all climatic risks per plot" rateFactor="%s"/>' % fmt(SPAIN_MODULE_FACTORS["2"], 2),
             '        <module id="P" cover="named perils (hail, fire, ...)" rateFactor="%s" isEstimate="true"/>' % (
                 fmt(SPAIN_MODULE_FACTORS["P"], 2))]
    for key, value in SPAIN_ADDITIONAL.items():
        if isinstance(value, dict):
            lines.append('        <additional id="%s" %s/>' % (key, " ".join(
                '%s="%s"' % (k, fmt(v, 3)) for k, v in value.items())))
        else:
            lines.append('        <additional id="%s" share="%s"/>' % (key, fmt(value, 2)))
    for who, floor in SPAIN_FLOORS.items():
        lines.append('        <floor id="%s" totalShare="%s" modules="2 3"/>' % (who, fmt(floor, 2)))
    lines.append('        <modulation exempt=%s>' % quoteattr(SPAIN_MODULATION_EXEMPT))
    for low, high, share in SPAIN_MODULATION:
        lines.append('            <band from="%d"%s withhold="%s"/>' % (
            low, (' to="%d"' % high) if high is not None else "", fmt(share, 2)))
    lines.append('        </modulation>')
    lines.append('    </program>')

    lines.append('    <history unit="MEUR" scope="all lines incl. livestock">')
    for year, (premium, subsidy, value, claims) in sorted(SPAIN_HISTORY.items()):
        lines.append('        <year id="%d" premium="%s" subsidy="%s" insuredValue="%s" claims="%s"/>' % (
            year, fmt(premium, 2), fmt(subsidy, 2), fmt(value, 2), fmt(claims, 2)))
    lines.append('    </history>')
    lines.append('    <claimCauses year="2023" scope="agricultural claims">')
    for peril, share in SPAIN_CLAIM_CAUSES_2023.items():
        lines.append('        <peril id="%s" claimShare="%s"/>' % (peril, fmt(share, 4)))
    lines.append('    </claimCauses>')

    lines.append('    <region id="ESP" name="Spain">')
    for crop, group in SPAIN_CROPS.items():
        sum_per_ha, rate = SPAIN_GROUPS[group][0], SPAIN_GROUPS[group][1] * calibration
        base2, baseP, line = SPAIN_BASE_SUBSIDY[group]
        lines.append('        <crop fillType=%s group=%s line=%s%s sumPerHa="%d" sumPerHaIsEstimate="true">' % (
            quoteattr(crop), quoteattr(group), quoteattr(line), ' borrowed="true"' if crop in SPAIN_BORROWED else "",
            sum_per_ha))
        if base2 is not None:
            lines.append('            <module id="2" rate="%s" baseSubsidy="%s" isEstimate="true"/>' % (
                fmt(min(rate, 1.0)), fmt(base2, 3)))
            lines.append('            <module id="1" rate="%s" baseSubsidy="%s" isEstimate="true"/>' % (
                fmt(rate * SPAIN_MODULE_FACTORS["1"]), fmt(SPAIN_MODULE1_SUBSIDY, 2)))
        # Lines without module 2 (bananas) sell module P as their main, comprehensive cover: full rate.
        p_factor = SPAIN_MODULE_FACTORS["P"] if base2 is not None else 1.0
        lines.append('            <module id="P" rate="%s" baseSubsidy="%s" isEstimate="true"/>' % (
            fmt(rate * p_factor), fmt(baseP, 3)))
        lines.append('        </crop>')
    lines.append('    </region>')
    lines.append('</cropInsurance>')
    lines.append('')

    out_path = os.path.abspath(out_path)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("wrote %s (%.1f KB, Spain, %d crops)" % (out_path, os.path.getsize(out_path) / 1024, len(SPAIN_CROPS)))


def write_italy(out_path):
    """Italy: PGRA peril groups and policy types, AgriCat, estimated rates. Needs no raw data."""
    totals = ITALY_TOTALS_2025
    weighted = sum(g[1] * g[2] for g in ITALY_GROUPS.values()) / sum(g[2] for g in ITALY_GROUPS.values())
    # The ISMEA average covers the policy mix as sold (2/3 package C = frequency perils); scale the mix-weighted
    # rate, not the all-risk rate: average factor of the sold mix (OUR ESTIMATE: 2/3 type c, 1/3 type a / b).
    mix_factor = totals["packageCShare"] * ITALY_TYPE_FACTORS["c"] + (1 - totals["packageCShare"]) * \
        (ITALY_TYPE_FACTORS["a"] + ITALY_TYPE_FACTORS["b"]) / 2
    calibration = totals["averageRate"] / (weighted * mix_factor)
    print("  Italy: average rate %.2f %%, estimated %.2f %% (mix x%.2f) -> calibration x%.3f" % (
        totals["averageRate"] * 100, weighted * mix_factor * 100, mix_factor, calibration))

    lines = ['<?xml version="1.0" encoding="utf-8" standalone="no" ?>',
             '<!-- Generated by tools/build_crop_insurance.py - do not edit by hand. -->',
             '<!-- Sources: Piano di gestione dei rischi in agricoltura 2026 (MASAF, DM 22/12/2025), ISMEA 2025 campaign -->',
             '<!-- figures. Values marked isEstimate="true" are our own estimates, not official figures. -->',
             '<cropInsurance version="1" source="MASAF PGRA 2026, ISMEA" years="2025-2026" currency="EUR">',
             '    <program type="perilGroups" threshold="%s" budget2026="%d" calibration="%s">' % (
                 fmt(ITALY_THRESHOLD, 2), ITALY_BUDGET_2026, fmt(calibration, 3))]
    for group, perils in ITALY_PERILS.items():
        lines.append('        <perilGroup id="%s" perils="%s"/>' % (group, " ".join(perils)))
    for pid, needs, share, label in ITALY_POLICY_TYPES:
        lines.append('        <policyType id="%s" needs="%s" subsidy="%s" rateFactor="%s" rateFactorIsEstimate="true" label=%s/>' % (
            pid, needs, fmt(share, 2), fmt(ITALY_TYPE_FACTORS[pid], 2), quoteattr(label)))
    lines.append('    </program>')
    lines.append('    <solidarity id="AgriCat" perils="%s" %s/>' % (
        " ".join(ITALY_PERILS["catastrophic"]),
        " ".join('%s="%s"' % (k, fmt(v, 2)) for k, v in ITALY_AGRICAT.items())))
    lines.append('    <totals year="2025" %s/>' % " ".join('%s="%s"' % (k, fmt(v, 4)) for k, v in totals.items()))
    lines.append('    <cropValues year="2025" %s/>' % " ".join(
        '%s="%s"' % (k, fmt(v, 0)) for k, v in ITALY_CROP_VALUES_2025.items()))

    lines.append('    <region id="ITA" name="Italy">')
    for crop, group in ITALY_CROPS.items():
        sum_per_ha, rate = ITALY_GROUPS[group][0], ITALY_GROUPS[group][1] * calibration
        lines.append('        <crop fillType=%s group=%s%s sumPerHa="%d" sumPerHaIsEstimate="true">' % (
            quoteattr(crop), quoteattr(group), ' borrowed="true"' if crop in ITALY_BORROWED else "", sum_per_ha))
        lines.append('            <rates allRisk="%s" isEstimate="true"/>' % fmt(rate))
        lines.append('        </crop>')
    lines.append('    </region>')
    lines.append('</cropInsurance>')
    lines.append('')

    out_path = os.path.abspath(out_path)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("wrote %s (%.1f KB, Italy, %d crops)" % (out_path, os.path.getsize(out_path) / 1024, len(ITALY_CROPS)))


def write_australia(out_path):
    """Australia: private named-peril cover, GST + state stamp duty, estimated rates. Needs no raw data."""
    rng = AUSTRALIA_RANGES
    lines = ['<?xml version="1.0" encoding="utf-8" standalone="no" ?>',
             '<!-- Generated by tools/build_crop_insurance.py - do not edit by hand. -->',
             '<!-- Sources: Insurance Council of Australia (state insurance duties), Revenue NSW / SRO Victoria (crop -->',
             '<!-- exemptions), Deloitte (premium ranges), ABARES 2012 (market overview). Values marked isEstimate="true" -->',
             '<!-- are our own estimates, not official figures. No climate data is used in this file. -->',
             '<cropInsurance version="1" source="ICA, state revenue offices, Deloitte, ABARES" years="2017-2026" currency="AUD">',
             '    <program type="namedPeril" subsidy="0" perils="%s" optionalPerils="%s" gst="%s" '
             'multiPeril="limited" %s>' % (" ".join(AUSTRALIA_NAMED_PERILS), " ".join(AUSTRALIA_OPTIONAL_PERILS),
                                          fmt(AUSTRALIA_GST, 2),
                                          " ".join('%s="%s"' % (k, fmt(v, 4)) for k, v in rng.items())),
             '    </program>',
             '    <region id="AUS" name="Australia">']
    for crop, group in AUSTRALIA_CROPS.items():
        sum_per_ha, named, multi = AUSTRALIA_GROUPS[group]
        lines.append('        <crop fillType=%s group=%s%s sumPerHa="%d" sumPerHaIsEstimate="true">' % (
            quoteattr(crop), quoteattr(group), ' borrowed="true"' if crop in AUSTRALIA_BORROWED else "", sum_per_ha))
        lines.append('            <rates namedPeril="%s"%s isEstimate="true"/>' % (
            fmt(named), (' multiPeril="%s"' % fmt(multi)) if multi is not None else ""))
        lines.append('        </crop>')
    lines.append('    </region>')
    for code, st in AUSTRALIA_STATES.items():
        lines.append('    <region id="AUS_%s" name=%s parent="AUS" stampDuty="%s" cropStampDutyExempt="%s"%s/>' % (
            code, quoteattr(st["name"]), fmt(st["stampDuty"], 2), "true" if st["cropExempt"] else "false",
            (' exemptSince="%d"' % st["since"]) if "since" in st else ""))
    lines.append('</cropInsurance>')
    lines.append('')

    out_path = os.path.abspath(out_path)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("wrote %s (%.1f KB, Australia + %d states)" % (out_path, os.path.getsize(out_path) / 1024, len(AUSTRALIA_STATES)))


def write_argentina(out_path):
    """Argentina: private hail market, province factors, estimated rates. Needs no raw data."""
    tot = ARGENTINA_TOTALS_2024
    target = tot["premiumArs"] / tot["capitalArs"]
    shares = ARGENTINA_COVER_SHARES
    mix = (shares["hail"] + shares["hailPlus"] * ARGENTINA_HAILPLUS_FACTOR) / (shares["hail"] + shares["hailPlus"])
    weighted = sum(g[1] * g[2] for g in ARGENTINA_GROUPS.values()) / sum(g[2] for g in ARGENTINA_GROUPS.values())
    calibration = target / (weighted * mix)
    print("  Argentina: SSN average rate %.2f %%, estimated %.2f %% (mix x%.3f) -> calibration x%.3f" % (
        target * 100, weighted * mix * 100, mix, calibration))

    provinces = dict((k, dict(v)) for k, v in ARGENTINA_PROVINCES.items())
    known = sum(p["capitalShare"] for p in provinces.values() if p["capitalShare"] is not None)
    others_premium = 1 - sum(p["premiumShare"] for p in provinces.values())
    provinces["CB"]["capitalShare"] = 1 - known - others_premium
    provinces["CB"]["capitalIsEstimate"] = True

    lines = ['<?xml version="1.0" encoding="utf-8" standalone="no" ?>',
             '<!-- Generated by tools/build_crop_insurance.py - do not edit by hand. -->',
             '<!-- Sources: Superintendencia de Seguros de la Nacion (SSN), Encuesta de Seguros en los Sectores Agropecuario -->',
             '<!-- y Forestal 2024; provincial governments of Mendoza and Cordoba. Values marked isEstimate="true" are our -->',
             '<!-- own estimates, not official figures. -->',
             '<cropInsurance version="1" source="SSN survey 2024, provinces" years="2023-2026" currency="USD">',
             '    <program type="namedPeril" subsidy="0" basePeril="HAIL" calibration="%s" averageRate="%s" '
             'hailPlusFactor="%s" multiPerilRate="%s" isEstimate="true">' % (
                 fmt(calibration, 3), fmt(target), fmt(ARGENTINA_HAILPLUS_FACTOR, 2), fmt(ARGENTINA_MULTIPERIL_RATE, 3)),
             '        <coverShares %s/>' % " ".join('%s="%s"' % (k, fmt(v, 3)) for k, v in shares.items()),
             '        <totals period="2023-07/2024-06" %s/>' % " ".join(
                 '%s="%s"' % (k, fmt(v, 3)) for k, v in tot.items()),
             '    </program>',
             '    <region id="ARG" name="Argentina">']
    for crop, group in ARGENTINA_CROPS.items():
        sum_per_ha, hail = ARGENTINA_GROUPS[group][0], ARGENTINA_GROUPS[group][1] * calibration
        lines.append('        <crop fillType=%s group=%s%s sumPerHa="%d" sumPerHaIsEstimate="true">' % (
            quoteattr(crop), quoteattr(group), ' borrowed="true"' if crop in ARGENTINA_BORROWED else "", sum_per_ha))
        lines.append('            <rates hail="%s" hailPlus="%s" isEstimate="true"/>' % (
            fmt(hail), fmt(hail * ARGENTINA_HAILPLUS_FACTOR)))
        lines.append('        </crop>')
    lines.append('    </region>')
    for code, p in provinces.items():
        scheme = ARGENTINA_SCHEMES.get(code)
        lines.append('    <region id="ARG_%s" name=%s parent="ARG" rateFactor="%s" premiumShare="%s" capitalShare="%s"%s>' % (
            code, quoteattr(p["name"]), fmt(p["premiumShare"] / p["capitalShare"], 3), fmt(p["premiumShare"], 3),
            fmt(p["capitalShare"], 3), ' rateFactorIsEstimate="true"' if p.get("capitalIsEstimate") else ""))
        if scheme:
            lines.append('        <provincialScheme %s/>' % " ".join(
                '%s=%s' % (k, quoteattr(fmt(v, 2) if isinstance(v, float) else str(v))) for k, v in scheme.items() if k != "name"))
        lines.append('    </region>')
    for code, scheme in ARGENTINA_SCHEMES.items():
        if code not in provinces:
            lines.append('    <region id="ARG_%s" name=%s parent="ARG">' % (code, quoteattr(scheme["name"])))
            lines.append('        <provincialScheme %s/>' % " ".join(
                '%s=%s' % (k, quoteattr(fmt(v, 2) if isinstance(v, float) else str(v))) for k, v in scheme.items() if k != "name"))
            lines.append('    </region>')
    lines.append('</cropInsurance>')
    lines.append('')

    out_path = os.path.abspath(out_path)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("wrote %s (%.1f KB, Argentina, %d crops)" % (out_path, os.path.getsize(out_path) / 1024, len(ARGENTINA_CROPS)))


def write_chile(out_path):
    """Chile: Agroseguros subsidy formula, estimated rates in UF. Needs no raw data."""
    sub, bonus = CHILE_SUBSIDY, CHILE_BONUSES
    lines = ['<?xml version="1.0" encoding="utf-8" standalone="no" ?>',
             '<!-- Generated by tools/build_crop_insurance.py - do not edit by hand. -->',
             '<!-- Sources: Agroseguros (Comite de Seguros del Agro) / ChileAtiende, DIPRES evaluation, Ministry of -->',
             '<!-- Agriculture. Values marked isEstimate="true" are our own estimates, not official figures. -->',
             '<cropInsurance version="1" source="Agroseguros, ChileAtiende, DIPRES" years="2014-2026" currency="CLF">',
             '    <program type="namedPeril" perils="%s" droughtOnlyRainfed="true">' % " ".join(CHILE_PERILS),
             '        <subsidy %s/>' % " ".join('%s="%s"' % (k, fmt(v, 2)) for k, v in sub.items()),
             '        <bonuses %s/>' % " ".join('%s="%s"' % (k, fmt(v, 2)) for k, v in bonus.items()),
             '        <smallFarmer %s/>' % " ".join('%s=%s' % (k, quoteattr(str(v))) for k, v in CHILE_INDAP.items()),
             '        <stats %s/>' % " ".join('%s="%s"' % (k, fmt(v, 4)) for k, v in CHILE_STATS.items()),
             '    </program>',
             '    <region id="CHL" name="Chile">']
    for crop, group in CHILE_CROPS.items():
        sum_per_ha, rate = CHILE_GROUPS[group]
        lines.append('        <crop fillType=%s group=%s%s%s sumPerHa="%d" sumPerHaIsEstimate="true">' % (
            quoteattr(crop), quoteattr(group), ' borrowed="true"' if crop in CHILE_BORROWED else "",
            ' cerealBonus="true"' if group in CHILE_CEREAL_GROUPS else "", sum_per_ha))
        lines.append('            <rates namedPeril="%s" isEstimate="true"/>' % fmt(rate))
        lines.append('        </crop>')
    lines.append('    </region>')
    lines.append('</cropInsurance>')
    lines.append('')

    out_path = os.path.abspath(out_path)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("wrote %s (%.1f KB, Chile, %d crops)" % (out_path, os.path.getsize(out_path) / 1024, len(CHILE_CROPS)))


def write_uk(out_path):
    """United Kingdom: private hail / fire cover with IPT, estimated rates. Needs no raw data."""
    lines = ['<?xml version="1.0" encoding="utf-8" standalone="no" ?>',
             '<!-- Generated by tools/build_crop_insurance.py - do not edit by hand. -->',
             '<!-- Sources: Northern Ireland Assembly research paper "Agricultural insurance", Farmers Weekly, HMRC (IPT). -->',
             '<!-- Values marked isEstimate="true" are our own estimates, not official figures. -->',
             '<cropInsurance version="1" source="NI Assembly, Farmers Weekly, HMRC" years="2026" currency="GBP">',
             '    <program type="namedPeril" subsidy="0" perils="%s" optionalPerils="%s" insurancePremiumTax="%s" '
             'averageRate="%s" averageRateIsEstimate="true" multiPeril="rare"/>' % (
                 " ".join(UK_PERILS), " ".join(UK_OPTIONAL_PERILS), fmt(UK_IPT, 2), fmt(UK_REFERENCE["averageRate"], 3)),
             '    <region id="GBR" name="United Kingdom">']
    for crop, group in UK_CROPS.items():
        sum_per_ha, rate = UK_GROUPS[group]
        lines.append('        <crop fillType=%s group=%s%s sumPerHa="%d" sumPerHaIsEstimate="true">' % (
            quoteattr(crop), quoteattr(group), ' borrowed="true"' if crop in UK_BORROWED else "", sum_per_ha))
        lines.append('            <rates namedPeril="%s" isEstimate="true"/>' % fmt(rate))
        lines.append('        </crop>')
    lines.append('    </region>')
    lines.append('</cropInsurance>')
    lines.append('')

    out_path = os.path.abspath(out_path)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("wrote %s (%.1f KB, United Kingdom, %d crops)" % (out_path, os.path.getsize(out_path) / 1024, len(UK_CROPS)))


def write_sea(out_path):
    """South-East Asia (Hutan Pantai): Indonesian and Malaysian state rice schemes. Needs no raw data."""
    lines = ['<?xml version="1.0" encoding="utf-8" standalone="no" ?>',
             '<!-- Generated by tools/build_crop_insurance.py - do not edit by hand. -->',
             '<!-- Sources: Jasindo / Ministry of Agriculture Indonesia (AUTP, via Kontan, IDX Channel), Agrobank / KPKM -->',
             '<!-- Malaysia (via Bernama, New Straits Times). Values marked isEstimate="true" are not confirmed. -->',
             '<cropInsurance version="1" source="AUTP Indonesia, SKTP Malaysia" years="2024-2026" currency="local">',
             '    <region id="SEA" name="South-East Asia" defaultChild="IDN"/>']
    for code, sc in SEA_SCHEMES.items():
        rate = sc["premiumPerHa"] / sc["sumInsuredPerHa"]
        lines.append('    <region id="%s" name=%s parent="SEA" currency="%s">' % (code, quoteattr(sc["name"]), sc["currency"]))
        attrs = ['name=%s' % quoteattr(sc["scheme"]), 'premiumPerHaSeason="%d"' % sc["premiumPerHa"],
                 'sumInsuredPerHaSeason="%d"' % sc["sumInsuredPerHa"], 'rate="%s"' % fmt(rate),
                 'subsidy="%s"' % fmt(sc["subsidy"], 2), 'perils="%s"' % sc["perils"]]
        if "pestSumInsuredPerHa" in sc:
            attrs.append('pestSumInsuredPerHaSeason="%d"' % sc["pestSumInsuredPerHa"])
        if "damageThreshold" in sc:
            attrs.append('damageThreshold="%s"' % fmt(sc["damageThreshold"], 2))
            if sc.get("damageThresholdIsEstimate"):
                attrs.append('damageThresholdIsEstimate="true"')
        if "insuredHa2024" in sc:
            attrs.append('insuredHa2024="%d"' % sc["insuredHa2024"])
        if "subsidyNote" in sc:
            attrs.append('subsidyNote=%s' % quoteattr(sc["subsidyNote"]))
        lines.append('        <scheme %s/>' % " ".join(attrs))
        for crop in sorted(SEA_INSURED_CROPS):
            lines.append('        <crop fillType="%s" scheme="state"/>' % crop)
        for crop in SEA_OTHER_CROPS:
            lines.append('        <crop fillType="%s" borrowedFrom="RICE" noStateScheme="true"/>' % crop)
        lines.append('    </region>')
    lines.append('</cropInsurance>')
    lines.append('')

    out_path = os.path.abspath(out_path)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("wrote %s (%.1f KB, South-East Asia: %s)" % (out_path, os.path.getsize(out_path) / 1024,
                                                     ", ".join(SEA_SCHEMES)))


def write_regions(out_path):
    """Region detection data: profiles, fallbacks, keywords and the known maps from tools/map_countries.csv."""
    known = []
    with open(MAP_COUNTRIES_CSV, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            mod, country, kind, title = (line.split("|") + ["", "", "", ""])[:4]
            known.append((mod, country, kind, title))
    countries = set(REGION_PROFILES) | set(REGION_NEAREST)
    unknown = sorted({c for _, c, _, _ in known if c not in countries})
    if unknown:
        print("  [WARNING] map_countries.csv: countries without profile / nearest rule: %s" % ", ".join(unknown))

    lines = ['<?xml version="1.0" encoding="utf-8" standalone="no" ?>',
             '<!-- Generated by tools/build_crop_insurance.py - do not edit by hand (edit tools/map_countries.csv / the -->',
             '<!-- REGION DETECTION config instead). Order: setting, knownMap, baseMap, keywords, environment, default. -->',
             '<insuranceRegions version="1" default="%s" order="setting knownMap baseMap keywords environment default">'
             % REGION_DEFAULT]
    lines.append('    <profiles>')
    for code, (filename, region, name) in REGION_PROFILES.items():
        lines.append('        <profile country="%s" file="%s" region="%s" name=%s/>' % (code, filename, region, quoteattr(name)))
    lines.append('    </profiles>')
    lines.append('    <nearest>')
    for code, target in REGION_NEAREST.items():
        lines.append('        <country id="%s" useProfile="%s"/>' % (code, target))
    lines.append('    </nearest>')
    lines.append('    <baseMaps>')
    for map_id, code in REGION_BASE_MAPS.items():
        lines.append('        <map id="%s" country="%s"/>' % (map_id, code))
    lines.append('    </baseMaps>')
    lines.append('    <environments>')
    for path, code in REGION_ENVIRONMENTS.items():
        lines.append('        <environment pathContains="%s" country="%s"/>' % (path, code))
    lines.append('    </environments>')
    lines.append('    <keywords match="wholeWord" rule="longestMatch">')
    for code, words in REGION_KEYWORDS.items():
        lines.append('        <country id="%s" words=%s/>' % (code, quoteattr(", ".join(w.strip() for w in words.split(",")))))
    lines.append('    </keywords>')
    lines.append('    <knownMaps source="GIANTS ModHub survey 2026-10-16" count="%d">' % len(known))
    for mod, country, kind, title in known:
        lines.append('        <map mod="%s" country="%s" kind="%s" title=%s/>' % (mod, country, kind, quoteattr(title)))
    lines.append('    </knownMaps>')
    lines.append('</insuranceRegions>')
    lines.append('')

    out_path = os.path.abspath(out_path)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    per = {}
    for _, country, _, _ in known:
        per[country] = per.get(country, 0) + 1
    print("wrote %s (%.0f KB, %d known maps: %s)" % (out_path, os.path.getsize(out_path) / 1024, len(known),
          ", ".join("%s %d" % kv for kv in sorted(per.items(), key=lambda kv: -kv[1]))))


def brazil_num(text):
    """PSR numbers use a decimal comma; "-" = empty."""
    text = text.strip()
    if text in ("", "-"):
        return 0.0
    if "," in text:
        text = text.replace(".", "").replace(",", ".")
    try:
        return float(text)
    except ValueError:
        return 0.0


def load_brazil(path):
    """Totals per (crop, plan, level), per (state, crop, plan, level) and per (crop, peril).
    Only the columns below are read - never the farmer name / tax id columns."""
    name_to_crops = defaultdict(list)
    for crop, names in BRAZIL_CROPS.items():
        for name in names:
            name_to_crops[name].append(crop)
    years = {str(y) for y in BRAZIL_YEARS}
    nat = defaultdict(Totals)
    state = defaultdict(Totals)
    perils = defaultdict(lambda: [0.0, 0.0])     # (crop, peril) -> [claims, indemnity]
    skipped = defaultdict(int)
    t0 = time.time()
    with open(path, encoding="latin-1", newline="") as f:
        head = f.readline().rstrip("\r\n").split(";")
        col = {n: i for i, n in enumerate(head)}
        c_ind = [i for n, i in col.items() if n.startswith("VALOR_INDENIZ")][0]
        c_year, c_plan, c_crop = col["ANO_APOLICE"], col["NM_CLASSIF_PRODUTO"], col["NM_CULTURA_GLOBAL"]
        c_uf, c_area, c_level = col["SG_UF_PROPRIEDADE"], col["NR_AREA_TOTAL"], col["NivelDeCobertura"]
        c_liab, c_prem, c_sub = col["VL_LIMITE_GARANTIA"], col["VL_PREMIO_LIQUIDO"], col["VL_SUBVENCAO_FEDERAL"]
        c_event = col["EVENTO_PREPONDERANTE"]
        for line in f:
            p = line.rstrip("\r\n").split(";")
            if len(p) != len(head):
                skipped["bad column count"] += 1
                continue
            if p[c_year] not in years:
                continue
            plan = BRAZIL_PLANS.get(p[c_plan])
            if plan is None:
                skipped["other product"] += 1
                continue
            level = round(brazil_num(p[c_level]) * 20) / 20
            if level not in BRAZIL_COVERAGE_LEVELS:
                skipped["coverage level missing / outside range"] += 1
                continue
            if level == 1.0:
                # 100 % policies are a different product (mostly fruit / named-peril style cover, few claims):
                # kept apart so they do not flatten the yield / cost curves.
                plan = "FULL"
            name = p[c_crop].strip()
            crops = list(name_to_crops.get(name, []))
            if name in BRAZIL_DEFAULT:
                crops.append("DEFAULT")
            if not crops:
                skipped["crop not used"] += 1
                continue
            area = brazil_num(p[c_area])
            liability = brazil_num(p[c_liab])
            premium = brazil_num(p[c_prem])
            if area <= 0 or liability <= 0 or premium <= 0:
                skipped["no area / value / premium"] += 1
                continue
            subsidy = brazil_num(p[c_sub])
            indemnity = brazil_num(p[c_ind])
            claimed = 1.0 if indemnity > 0 else 0.0
            peril = None
            if claimed:
                event = p[c_event].replace("\xa0", " ").strip().upper()
                peril = BRAZIL_PERILS.get(event, "OTHER")
            uf = p[c_uf].strip().upper()
            for crop in crops:
                nat[(crop, plan, level)].add(area, liability, premium, subsidy, indemnity, 1.0, claimed)
                state[(uf, crop, plan, level)].add(area, liability, premium, subsidy, indemnity, 1.0, claimed)
                if peril is not None:
                    perils[(crop, peril)][0] += 1
                    perils[(crop, peril)][1] += indemnity
    print("  Brazil: PSR %d-%d read (%.1fs); skipped: %s" % (min(BRAZIL_YEARS), max(BRAZIL_YEARS), time.time() - t0,
          ", ".join("%s %d" % kv for kv in sorted(skipped.items()))))
    return nat, state, perils


def brazil_usable(t, min_hectares=BRAZIL_MIN_HECTARES):
    return t.acres >= min_hectares and t.policies >= BRAZIL_MIN_POLICIES and t.liability > 0 and t.premium > 0


def write_brazil(path, out_path):
    nat, state, perils = load_brazil(path)
    smooth = shaped_rates(nat, BRAZIL_COVERAGE_LEVELS, brazil_usable)   # FULL: one level, raw average
    crops = list(BRAZIL_CROPS) + ["DEFAULT"]
    prog = BRAZIL_PROGRAM
    lines = ['<?xml version="1.0" encoding="utf-8" standalone="no" ?>',
             '<!-- Generated by tools/build_crop_insurance.py - do not edit by hand. -->',
             '<!-- Source: Ministério da Agricultura e Pecuária (MAPA), PSR open data (SISSER) %d-%d, -->'
             % (min(BRAZIL_YEARS), max(BRAZIL_YEARS)),
             '<!-- Creative Commons Attribution. Totals only; not an official MAPA product. -->',
             '<cropInsurance version="1" source="MAPA PSR open data (SISSER)" years="%d-%d" currency="BRL" area="ha">'
             % (min(BRAZIL_YEARS), max(BRAZIL_YEARS)),
             '    <program subsidySoy="%s" subsidyOther="%s" subsidySoyNorthNortheast="%s" '
             'subsidyOtherNorthNortheast="%s" maxSubsidyPerModality="%d" maxSubsidyPerFarmer="%d" '
             'source="Plano Trienal do Seguro Rural 2025-2027"/>' % (
                 fmt(prog["subsidySoy"], 2), fmt(prog["subsidyOther"], 2), fmt(prog["subsidySoyNorthNortheast"], 2),
                 fmt(prog["subsidyOtherNorthNortheast"], 2), prog["maxSubsidyPerModality"], prog["maxSubsidyPerFarmer"])]

    # ---- national curves + perils
    nat_rate = {}
    lines.append('    <region id="BRA" name="Brazil">')
    for crop in crops:
        plan_lines = []
        for plan in ("YP", "COST", "FULL"):
            level_lines = []
            for level in BRAZIL_COVERAGE_LEVELS:
                t = nat.get((crop, plan, level))
                if t is not None and brazil_usable(t):
                    nat_rate[(crop, plan, level)] = smooth[(crop, plan, level)][0]
                    level_lines.append('                <level coverage="%s" %s/>' % (
                        fmt(level, 2), level_attrs(t, smooth[(crop, plan, level)], "Ha", "hectares")))
            if level_lines:
                plan_lines.append('            <plan id="%s"%s>' % (plan, (' shape="lossModel" shapeCv="%s"' % fmt(COVERAGE_SHAPE_CV, 2)) if plan != "FULL" else ""))
                plan_lines += level_lines
                plan_lines.append('            </plan>')
        if not plan_lines:
            continue
        names = "all grains" if crop == "DEFAULT" else ", ".join(BRAZIL_CROPS[crop])
        lines.append('        <crop fillType=%s psr=%s>' % (quoteattr(crop), quoteattr(names)))
        lines += plan_lines
        crop_perils = sorted(((pe, v) for (c, pe), v in perils.items() if c == crop), key=lambda x: -x[1][1])
        total_ind = sum(v[1] for _, v in crop_perils)
        total_claims = sum(v[0] for _, v in crop_perils)
        if total_ind > 0:
            lines.append('            <perils claims="%d">' % total_claims)
            for peril, (claims, indemnity) in crop_perils:
                lines.append('                <peril id="%s" payoutShare="%s" claimShare="%s"/>' % (
                    peril, fmt(indemnity / total_ind, 3), fmt(claims / total_claims, 3)))
            lines.append('            </perils>')
        lines.append('        </crop>')
    for crop, source in BRAZIL_PROXY_CROPS.items():
        if any(k[0] == source for k in nat_rate):
            lines.append('        <crop fillType=%s borrowedFrom=%s/>' % (quoteattr(crop), quoteattr(source)))
    lines.append('    </region>')

    # ---- state factors
    acc = defaultdict(lambda: defaultdict(lambda: [0.0, 0.0, 0.0, 0.0, 0.0]))  # area, premium, expected, indemnity, policies
    for (uf, crop, plan, level), t in state.items():
        rate = nat_rate.get((crop, plan, level))
        if rate is None:
            continue
        a = acc[uf][crop]
        a[0] += t.acres
        a[1] += t.premium
        a[2] += t.liability * rate
        a[3] += t.indemnity
        a[4] += t.policies
    num_states = 0
    for uf in sorted(acc):
        crop_lines = []
        for crop in crops:
            a = acc[uf].get(crop)
            if a is None or a[0] < BRAZIL_MIN_HECTARES or a[4] < BRAZIL_MIN_POLICIES or a[2] <= 0 or a[1] <= 0:
                continue
            crop_lines.append('        <crop fillType=%s rateFactor="%s" lossRatio="%s" hectares="%d"/>' % (
                quoteattr(crop), fmt(a[1] / a[2], 3), fmt(a[3] / a[1], 3), round(a[0])))
        if crop_lines:
            num_states += 1
            lines.append('    <region id="BRA_%s" name=%s parent="BRA"%s>' % (
                uf, quoteattr(BRAZIL_STATES.get(uf, uf)), ' northNortheast="true"' if uf in BRAZIL_NORTH_NORTHEAST else ""))
            lines += crop_lines
            lines.append('    </region>')
    lines.append('</cropInsurance>')
    lines.append('')

    out_path = os.path.abspath(out_path)
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print("wrote %s (%.0f KB, Brazil + %d states)" % (out_path, os.path.getsize(out_path) / 1024, num_states))


def main():
    if POLAND_OUTPUT_XML:
        write_poland(POLAND_OUTPUT_XML)
    if GERMANY_OUTPUT_XML:
        write_germany(GERMANY_OUTPUT_XML)
    if FRANCE_OUTPUT_XML:
        write_france(FRANCE_OUTPUT_XML)
    if NETHERLANDS_OUTPUT_XML:
        write_netherlands(NETHERLANDS_OUTPUT_XML)
    if SPAIN_OUTPUT_XML:
        write_spain(SPAIN_OUTPUT_XML)
    if ITALY_OUTPUT_XML:
        write_italy(ITALY_OUTPUT_XML)
    if AUSTRALIA_OUTPUT_XML:
        write_australia(AUSTRALIA_OUTPUT_XML)
    if ARGENTINA_OUTPUT_XML:
        write_argentina(ARGENTINA_OUTPUT_XML)
    if CHILE_OUTPUT_XML:
        write_chile(CHILE_OUTPUT_XML)
    if UK_OUTPUT_XML:
        write_uk(UK_OUTPUT_XML)
    if SEA_OUTPUT_XML:
        write_sea(SEA_OUTPUT_XML)
    if REGIONS_OUTPUT_XML:
        write_regions(REGIONS_OUTPUT_XML)
    print("Reading RMA Summary of Business %d-%d from %s" % (min(YEARS), max(YEARS), os.path.abspath(DATA_DIR)))
    us, state, seen = load()
    missing = [n for names in CROPS.values() for n in names if n not in seen]
    if missing:
        print("  [WARNING] commodities not found in the data: %s" % ", ".join(sorted(set(missing))))
    write(us, state, OUTPUT_XML)
    if CANADA_OUTPUT_XML:
        write_canada(us, state, CANADA_OUTPUT_XML)
    if BRAZIL_OUTPUT_XML:
        if os.path.isfile(BRAZIL_DATA):
            write_brazil(BRAZIL_DATA, BRAZIL_OUTPUT_XML)
        else:
            print("  Brazil: %s not found - skipped" % os.path.abspath(BRAZIL_DATA))


if __name__ == "__main__":
    main()
