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
                    Both are smoothed so they never fall as coverage rises (see smoothed_rates).
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


def pav(values, weights):
    """Weighted pool-adjacent-violators: the closest non-decreasing sequence (keeps the weighted average)."""
    blocks = []  # [value, weight, count]
    for v, w in zip(values, weights):
        blocks.append([v, w, 1])
        while len(blocks) > 1 and blocks[-2][0] > blocks[-1][0]:
            v2, w2, n2 = blocks.pop()
            v1, w1, n1 = blocks.pop()
            blocks.append([(v1 * w1 + v2 * w2) / (w1 + w2), w1 + w2, n1 + n2])
    out = []
    for v, _, n in blocks:
        out += [v] * n
    return out


def smoothed_rates(us):
    """(crop, plan, level) -> (premiumRate, farmerRate), both non-decreasing with the coverage level.

    The raw national averages often FALL at high coverage: low-risk farms pick high coverage
    (selection bias), so 80 % looked cheaper per acre than 70 %. Real rates rise with coverage, so
    each curve is smoothed to the closest rising curve with the same liability-weighted average."""
    result = {}
    keys = {(crop, plan) for (crop, plan, _) in us}
    for crop, plan in keys:
        rows = [(level, us[(crop, plan, level)]) for level in COVERAGE_LEVELS
                if (crop, plan, level) in us and usable(us[(crop, plan, level)])]
        if not rows:
            continue
        weights = [t.liability for _, t in rows]
        premium = pav([t.premium / t.liability for _, t in rows], weights)
        farmer = pav([(t.premium - t.subsidy) / t.liability for _, t in rows], weights)
        for (level, _), p_rate, f_rate in zip(rows, premium, farmer):
            result[(crop, plan, level)] = (p_rate, min(f_rate, p_rate))
    return result


def level_attrs(t, rates):
    premium_rate, farmer_rate = rates
    subsidy_share = 1 - farmer_rate / premium_rate if premium_rate > 0 else 0
    farmer = t.premium - t.subsidy
    return ('premiumRate="%s" farmerRate="%s" subsidyShare="%s" lossRatio="%s" claimShare="%s" '
            'farmerPerAcre="%s" acres="%d" policies="%d"' % (
                fmt(premium_rate), fmt(farmer_rate), fmt(subsidy_share, 3),
                fmt(t.indemnity / t.premium, 3), fmt(t.indemnified / t.policies if t.policies > 0 else 0, 3),
                fmt(farmer / t.acres, 2), round(t.acres), round(t.policies)))


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
    smooth = smoothed_rates(us)
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
                plan_lines.append('            <plan id="%s">' % plan)
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
    """(crop, plan, level) -> smoothed total premium rate for usable US entries."""
    return {key: rates[0] for key, rates in smoothed_rates(us).items()}


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
                out.append('            <plan id="YP">')
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


def main():
    if POLAND_OUTPUT_XML:
        write_poland(POLAND_OUTPUT_XML)
    print("Reading RMA Summary of Business %d-%d from %s" % (min(YEARS), max(YEARS), os.path.abspath(DATA_DIR)))
    us, state, seen = load()
    missing = [n for names in CROPS.values() for n in names if n not in seen]
    if missing:
        print("  [WARNING] commodities not found in the data: %s" % ", ".join(sorted(set(missing))))
    write(us, state, OUTPUT_XML)
    if CANADA_OUTPUT_XML:
        write_canada(us, state, CANADA_OUTPUT_XML)


if __name__ == "__main__":
    main()
