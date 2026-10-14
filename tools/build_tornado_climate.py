#!/usr/bin/env python3
"""
build_tornado_climate.py  -  Tornado Physics climate data builder
====================================================================

Reads the NOAA Storm Prediction Center (SPC) severe-weather CSV files
("Actual Tornadoes", hail and wind reports, 1950/1955 - present) and condenses
them into one small XML file (TornadoClimate.xml) that the FS25 Tornado
Physics mod can ship and read with the game's normal XML functions.

  ~150 MB of raw CSV  ->  roughly 50-150 KB of XML (one entry per US state + US-wide)

The raw CSV files are never shipped with the mod; re-run this script whenever
NOAA publishes a new year and ship the regenerated XML.

Requirements: Python 3.8+ and nothing else (standard library only).
Usage:        edit the CONFIG section below, then run
                  python build_tornado_climate.py

Data source:  https://www.spc.noaa.gov/wcm/#data   (US government work, public domain)

----------------------------------------------------------------------------
What ends up in the XML (per region)
----------------------------------------------------------------------------
  stats      total tornadoes, tornadoes per year, number of tornado days
  efMix      share of EF0..EF5 (from EF_MIX_START_YEAR on; early years miss most weak tornadoes)
  months     share of tornadoes per calendar month (all years)
  hours      share of tornadoes per hour of day, US Central Standard Time (all years)
  pathLength p10 / p50 / p90 / max track length per EF rating, metres
  pathWidth  p10 / p50 / p90 / max track width per EF rating, metres
  direction  share of tracks moving toward each of 8 compass sectors + mean heading
  outbreak   share of the region's tornado days that were national outbreak days,
             tornadoes per tornado day in the region (p50 / p90 / max)
  hail       share of tornadoes with a hail report nearby on the same convective day,
             typical / large / max hail size of those reports (cm)
  wind       same for severe-wind reports, gust speeds (km/h)

Every percentile block carries a "count" attribute. Blocks with fewer than
MIN_SAMPLES values are left out, so the mod can fall back to the parent region.

----------------------------------------------------------------------------
NOAA data quirks handled here
----------------------------------------------------------------------------
  * "mag" differs per file: tornado = F/EF rating (-9 = unknown),
    hail = stone size in inches, wind = gust in knots.
  * Tornadoes that cross state lines appear several times:
    one row for the whole track (sn = 1) plus one row per state segment (sn = 0).
    National statistics use one row per tornado (keyed by year + om, preferring
    the whole-track row); state statistics use one row per tornado per state
    (preferring the state-segment row).
  * F-scale (before Feb 2007) and EF-scale ratings are treated as the same 0..5 bins.
  * len is in miles, wid in yards -> converted to metres.
  * tz 3 = CST, tz 9 = GMT (converted to CST); anything else is treated as CST.
  * A "convective day" runs 12 UTC to 12 UTC (06:00 to 06:00 CST), the SPC convention,
    so an overnight outbreak counts as one day.
"""

import csv
import math
import os
import sys
import time
from collections import Counter, defaultdict
from datetime import datetime, timedelta
from xml.sax.saxutils import quoteattr

# ============================================================================
# CONFIG  -  edit these paths / values
# ============================================================================

# Folder that holds the three NOAA CSV files (keep it OUTSIDE the mods folder).
DATA_DIR = r"C:\Users\whitevamp\Downloads\weather_csv_files_for_tornadophysics"

TORNADO_CSV = os.path.join(DATA_DIR, "1950-2025_torn.csv")
HAIL_CSV    = os.path.join(DATA_DIR, "1955-2025_hail.csv")   # set to None to skip hail linking
WIND_CSV    = os.path.join(DATA_DIR, "1955-2025_wind.csv")   # set to None to skip wind linking

# Where to write the result. Default: <mod>/DB/TornadoClimate.xml (next to this tools folder).
OUTPUT_XML = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "DB", "TornadoClimate.xml")

# EF mix is taken from this year on: before radar / spotter networks most EF0s went unreported.
EF_MIX_START_YEAR = 1995

# Hail / wind linking uses reports from this year on (report density changed a lot over time).
LINK_START_YEAR = 1995

# A hail / wind report counts as "with this tornado" if it is on the same convective day
# and within this distance of the tornado's start point.
LINK_RADIUS_KM = 80.0

# A convective day with at least this many tornadoes nationwide is an "outbreak day".
OUTBREAK_MIN_TORNADOES = 10

# Percentile blocks with fewer samples than this are omitted (mod falls back to the parent region).
MIN_SAMPLES = 15

# Decimal places for shares / weights in the XML.
SHARE_DECIMALS = 4

# ============================================================================
# Constants
# ============================================================================

MILE_M = 1609.344
YARD_M = 0.9144
INCH_CM = 2.54
KNOT_KMH = 1.852

SECTORS = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]

STATE_NAMES = {
    "AL": "Alabama", "AK": "Alaska", "AZ": "Arizona", "AR": "Arkansas", "CA": "California",
    "CO": "Colorado", "CT": "Connecticut", "DE": "Delaware", "DC": "District of Columbia",
    "FL": "Florida", "GA": "Georgia", "HI": "Hawaii", "ID": "Idaho", "IL": "Illinois",
    "IN": "Indiana", "IA": "Iowa", "KS": "Kansas", "KY": "Kentucky", "LA": "Louisiana",
    "ME": "Maine", "MD": "Maryland", "MA": "Massachusetts", "MI": "Michigan", "MN": "Minnesota",
    "MS": "Mississippi", "MO": "Missouri", "MT": "Montana", "NE": "Nebraska", "NV": "Nevada",
    "NH": "New Hampshire", "NJ": "New Jersey", "NM": "New Mexico", "NY": "New York",
    "NC": "North Carolina", "ND": "North Dakota", "OH": "Ohio", "OK": "Oklahoma", "OR": "Oregon",
    "PA": "Pennsylvania", "RI": "Rhode Island", "SC": "South Carolina", "SD": "South Dakota",
    "TN": "Tennessee", "TX": "Texas", "UT": "Utah", "VT": "Vermont", "VA": "Virginia",
    "WA": "Washington", "WV": "West Virginia", "WI": "Wisconsin", "WY": "Wyoming",
    "PR": "Puerto Rico", "VI": "US Virgin Islands",
}

# ============================================================================
# Helpers
# ============================================================================


def num(value, default=None):
    """float() that tolerates blanks and junk."""
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def to_int(value, default=None):
    v = num(value)
    return default if v is None else int(v)


def parse_cst(row):
    """Report time as a naive datetime in US Central Standard Time, or None."""
    try:
        dt = datetime.strptime(row["date"].strip() + " " + row["time"].strip(), "%Y-%m-%d %H:%M:%S")
    except (KeyError, ValueError):
        try:
            dt = datetime(int(row["yr"]), int(row["mo"]), int(row["dy"]))
        except (KeyError, ValueError):
            return None
    if to_int(row.get("tz"), 3) == 9:  # GMT -> CST
        dt -= timedelta(hours=6)
    return dt


def convective_day(dt_cst):
    """SPC convective day: 12 UTC to 12 UTC = 06:00 to 06:00 CST."""
    return (dt_cst - timedelta(hours=6)).date()


def valid_point(lat, lon):
    return lat is not None and lon is not None and lat != 0 and lon != 0 and abs(lat) <= 90 and abs(lon) <= 180


def distance_km(lat1, lon1, lat2, lon2):
    """Equirectangular approximation, plenty for <100 km."""
    x = math.radians(lon2 - lon1) * math.cos(math.radians((lat1 + lat2) * 0.5))
    y = math.radians(lat2 - lat1)
    return 6371.0 * math.hypot(x, y)


def bearing_deg(lat1, lon1, lat2, lon2):
    """Initial compass bearing from point 1 to point 2 (0 = N, 90 = E)."""
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dl = math.radians(lon2 - lon1)
    x = math.sin(dl) * math.cos(p2)
    y = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dl)
    return (math.degrees(math.atan2(x, y)) + 360.0) % 360.0


def percentile(sorted_values, p):
    """Linear-interpolated percentile of an already sorted list (p in 0..100)."""
    if not sorted_values:
        return None
    if len(sorted_values) == 1:
        return sorted_values[0]
    k = (len(sorted_values) - 1) * p / 100.0
    lo = int(math.floor(k))
    hi = min(lo + 1, len(sorted_values) - 1)
    return sorted_values[lo] + (sorted_values[hi] - sorted_values[lo]) * (k - lo)


def shares(counter, keys):
    total = sum(counter.get(k, 0) for k in keys)
    return {k: (counter.get(k, 0) / total if total else 0.0) for k in keys}


def fmt(value, decimals=1):
    return ("%." + str(decimals) + "f") % value


def open_csv(path):
    if path is None:
        return None
    if not os.path.isfile(path):
        sys.exit("ERROR: file not found: %s\n       Check the CONFIG section at the top of this script." % path)
    return open(path, "r", encoding="utf-8", errors="replace", newline="")


# ============================================================================
# Loading
# ============================================================================


class Tornado:
    __slots__ = ("year", "state", "ef", "dt", "cday", "slat", "slon", "elat", "elon", "len_m", "wid_m")


def make_tornado(row):
    t = Tornado()
    t.year = to_int(row.get("yr"))
    t.state = (row.get("st") or "").strip().upper()
    t.ef = to_int(row.get("mag"), -9)
    t.dt = parse_cst(row)
    t.cday = convective_day(t.dt) if t.dt else None
    t.slat, t.slon = num(row.get("slat")), num(row.get("slon"))
    t.elat, t.elon = num(row.get("elat")), num(row.get("elon"))
    length, width = num(row.get("len"), 0.0), num(row.get("wid"), 0.0)
    t.len_m = length * MILE_M if length and length > 0 else None
    t.wid_m = width * YARD_M if width and width > 0 else None
    return t


def load_tornadoes(path):
    """Returns (national, by_state): one Tornado per tornado, and one per tornado per state."""
    national = {}   # (yr, om) -> (priority, Tornado)
    by_state = {}   # (yr, om, st) -> (priority, Tornado)
    rows = 0
    with open_csv(path) as f:
        for row in csv.DictReader(f):
            rows += 1
            yr, om = row.get("yr"), row.get("om")
            if yr is None or om is None:
                continue
            sn, sg = to_int(row.get("sn"), 1), to_int(row.get("sg"), 1)
            t = make_tornado(row)
            if t.year is None or not t.state:
                continue

            # National: prefer the whole-track row (sn = 1, sg = 1).
            prio_nat = 2 if (sn == 1 and sg == 1) else (1 if sn == 1 else 0)
            key = (yr, om)
            if key not in national or prio_nat > national[key][0]:
                national[key] = (prio_nat, t)

            # State: prefer the state-segment row (sn = 0); single-state tornadoes only have sn = 1.
            prio_st = 2 if sn == 0 else (1 if sg == 1 else 0)
            skey = (yr, om, t.state)
            if skey not in by_state or prio_st > by_state[skey][0]:
                by_state[skey] = (prio_st, t)

    print("  tornado rows read: %d  ->  %d tornadoes, %d state records" % (rows, len(national), len(by_state)))
    return [v[1] for v in national.values()], [v[1] for v in by_state.values()]


class ReportIndex:
    """Hail / wind reports bucketed by convective day and 1-degree grid cell."""

    def __init__(self, label):
        self.label = label
        self.cells = defaultdict(list)   # (cday, ilat, ilon) -> [(lat, lon, mag)]
        self.count = 0

    def add(self, cday, lat, lon, mag):
        self.cells[(cday, int(math.floor(lat)), int(math.floor(lon)))].append((lat, lon, mag))
        self.count += 1

    def max_nearby(self, cday, lat, lon, radius_km):
        """Largest magnitude within radius on that day; 0 if only unknown sizes; None if no report."""
        lat_span = int(math.ceil(radius_km / 111.0))
        lon_span = int(math.ceil(radius_km / max(1.0, 111.0 * math.cos(math.radians(lat)))))
        ilat, ilon = int(math.floor(lat)), int(math.floor(lon))
        best = None
        for dy in range(-lat_span, lat_span + 1):
            for dx in range(-lon_span, lon_span + 1):
                for rlat, rlon, mag in self.cells.get((cday, ilat + dy, ilon + dx), ()):
                    if distance_km(lat, lon, rlat, rlon) <= radius_km:
                        best = mag if best is None else max(best, mag)
        return best


def load_reports(path, label):
    if path is None:
        return None
    index = ReportIndex(label)
    rows = 0
    with open_csv(path) as f:
        for row in csv.DictReader(f):
            rows += 1
            year = to_int(row.get("yr"))
            if year is None or year < LINK_START_YEAR:
                continue
            lat, lon = num(row.get("slat")), num(row.get("slon"))
            if not valid_point(lat, lon):
                continue
            dt = parse_cst(row)
            if dt is None:
                continue
            index.add(convective_day(dt), lat, lon, max(0.0, num(row.get("mag"), 0.0)))
    print("  %s rows read: %d  ->  %d indexed (from %d)" % (label, rows, index.count, LINK_START_YEAR))
    return index


# ============================================================================
# Statistics
# ============================================================================


def percentile_block(values):
    values = sorted(v for v in values if v is not None)
    if len(values) < MIN_SAMPLES:
        return None
    return {
        "count": len(values),
        "p10": percentile(values, 10),
        "p50": percentile(values, 50),
        "p90": percentile(values, 90),
        "max": values[-1],
    }


def region_stats(tornadoes, outbreak_days, hail, wind):
    years = [t.year for t in tornadoes]
    first, last = min(years), max(years)
    span = last - first + 1

    stats = {"count": len(tornadoes), "first": first, "last": last, "perYear": len(tornadoes) / span}

    # EF mix (recent years only)
    ef_counter = Counter(t.ef for t in tornadoes if t.year >= EF_MIX_START_YEAR and 0 <= t.ef <= 5)
    stats["efCounts"] = ef_counter
    stats["efMix"] = shares(ef_counter, range(6))

    # Seasonality / time of day (all years)
    stats["months"] = shares(Counter(t.dt.month for t in tornadoes if t.dt), range(1, 13))
    stats["hours"] = shares(Counter(t.dt.hour for t in tornadoes if t.dt), range(24))

    # Path length / width per EF
    stats["length"], stats["width"] = {}, {}
    for ef in range(6):
        rated = [t for t in tornadoes if t.ef == ef]
        stats["length"][ef] = percentile_block(t.len_m for t in rated)
        stats["width"][ef] = percentile_block(t.wid_m for t in rated)

    # Direction of travel
    sector_counter = Counter()
    sx = sy = 0.0
    for t in tornadoes:
        if valid_point(t.slat, t.slon) and valid_point(t.elat, t.elon) and (t.len_m or 0) >= 800:
            b = bearing_deg(t.slat, t.slon, t.elat, t.elon)
            sector_counter[SECTORS[int(((b + 22.5) % 360) // 45)]] += 1
            sx += math.sin(math.radians(b))
            sy += math.cos(math.radians(b))
    n_dir = sum(sector_counter.values())
    stats["direction"] = None
    if n_dir >= MIN_SAMPLES:
        stats["direction"] = {
            "count": n_dir,
            "meanDeg": (math.degrees(math.atan2(sx, sy)) + 360.0) % 360.0,
            # 0 = directions all over the place, 1 = every track points the same way
            "consistency": math.hypot(sx, sy) / n_dir,
            "sectors": shares(sector_counter, SECTORS),
        }

    # Tornado days / outbreaks
    per_day = Counter(t.cday for t in tornadoes if t.cday)
    stats["tornadoDays"] = len(per_day)
    stats["outbreak"] = None
    if per_day:
        counts = sorted(per_day.values())
        stats["outbreak"] = {
            "dayShare": sum(1 for d in per_day if d in outbreak_days) / len(per_day),
            "perDayP50": percentile(counts, 50),
            "perDayP90": percentile(counts, 90),
            "perDayMax": counts[-1],
        }

    # Hail / wind on the same convective day near the tornado's start point
    for key, index in (("hail", hail), ("wind", wind)):
        stats[key] = None
        if index is None:
            continue
        linked, sizes = 0, []
        candidates = [t for t in tornadoes
                      if t.year >= LINK_START_YEAR and t.cday and valid_point(t.slat, t.slon)]
        for t in candidates:
            best = index.max_nearby(t.cday, t.slat, t.slon, LINK_RADIUS_KM)
            if best is not None:
                linked += 1
                if best > 0:
                    sizes.append(best)
        if len(candidates) >= MIN_SAMPLES:
            stats[key] = {"count": len(candidates), "chance": linked / len(candidates),
                          "sizes": percentile_block(sizes)}

    return stats


# ============================================================================
# XML output
# ============================================================================


def xml_region(out, region_id, name, parent, stats):
    w = out.append
    parent_attr = (" parent=%s" % quoteattr(parent)) if parent else ""
    w("    <region id=%s name=%s country=\"US\"%s>" % (quoteattr(region_id), quoteattr(name), parent_attr))
    w("        <stats tornadoes=\"%d\" perYear=\"%s\" tornadoDays=\"%d\" firstYear=\"%d\" lastYear=\"%d\"/>"
      % (stats["count"], fmt(stats["perYear"], 2), stats["tornadoDays"], stats["first"], stats["last"]))

    efc = stats["efCounts"]
    w("        <efMix fromYear=\"%d\" count=\"%d\">" % (EF_MIX_START_YEAR, sum(efc.values())))
    for ef in range(6):
        w("            <ef rating=\"%d\" share=\"%s\" count=\"%d\"/>" % (ef, fmt(stats["efMix"][ef], SHARE_DECIMALS), efc.get(ef, 0)))
    w("        </efMix>")

    w("        <months>")
    for m in range(1, 13):
        w("            <month m=\"%d\" weight=\"%s\"/>" % (m, fmt(stats["months"][m], SHARE_DECIMALS)))
    w("        </months>")

    w("        <hours timeZone=\"CST\">")
    for h in range(24):
        w("            <hour h=\"%d\" weight=\"%s\"/>" % (h, fmt(stats["hours"][h], SHARE_DECIMALS)))
    w("        </hours>")

    for tag, key in (("pathLength", "length"), ("pathWidth", "width")):
        blocks = [(ef, b) for ef, b in stats[key].items() if b]
        if blocks:
            w("        <%s unit=\"m\">" % tag)
            for ef, b in blocks:
                w("            <ef rating=\"%d\" count=\"%d\" p10=\"%s\" p50=\"%s\" p90=\"%s\" max=\"%s\"/>"
                  % (ef, b["count"], fmt(b["p10"], 0), fmt(b["p50"], 0), fmt(b["p90"], 0), fmt(b["max"], 0)))
            w("        </%s>" % tag)

    d = stats["direction"]
    if d:
        w("        <direction count=\"%d\" meanDeg=\"%s\" consistency=\"%s\">"
          % (d["count"], fmt(d["meanDeg"], 0), fmt(d["consistency"], 3)))
        for s in SECTORS:
            w("            <toward sector=\"%s\" share=\"%s\"/>" % (s, fmt(d["sectors"][s], SHARE_DECIMALS)))
        w("        </direction>")

    o = stats["outbreak"]
    if o:
        w("        <outbreak minTornadoesNational=\"%d\" dayShare=\"%s\" perDayP50=\"%s\" perDayP90=\"%s\" perDayMax=\"%d\"/>"
          % (OUTBREAK_MIN_TORNADOES, fmt(o["dayShare"], SHARE_DECIMALS), fmt(o["perDayP50"], 1), fmt(o["perDayP90"], 1), o["perDayMax"]))

    h = stats["hail"]
    if h:
        attrs = "count=\"%d\" chance=\"%s\" radiusKm=\"%s\"" % (h["count"], fmt(h["chance"], SHARE_DECIMALS), fmt(LINK_RADIUS_KM, 0))
        s = h["sizes"]
        if s:
            attrs += " sizeP50Cm=\"%s\" sizeP90Cm=\"%s\" sizeMaxCm=\"%s\"" % (
                fmt(s["p50"] * INCH_CM, 1), fmt(s["p90"] * INCH_CM, 1), fmt(s["max"] * INCH_CM, 1))
        w("        <hail %s/>" % attrs)

    wd = stats["wind"]
    if wd:
        attrs = "count=\"%d\" chance=\"%s\" radiusKm=\"%s\"" % (wd["count"], fmt(wd["chance"], SHARE_DECIMALS), fmt(LINK_RADIUS_KM, 0))
        s = wd["sizes"]
        if s:
            attrs += " gustP50Kmh=\"%s\" gustP90Kmh=\"%s\" gustMaxKmh=\"%s\"" % (
                fmt(s["p50"] * KNOT_KMH, 0), fmt(s["p90"] * KNOT_KMH, 0), fmt(s["max"] * KNOT_KMH, 0))
        w("        <wind %s/>" % attrs)

    w("    </region>")


# ============================================================================
# Main
# ============================================================================


def main():
    started = time.time()
    print("Tornado Physics climate builder")
    print("-------------------------------")

    print("Loading tornadoes ...")
    national, by_state = load_tornadoes(TORNADO_CSV)
    print("Loading hail reports ...")
    hail = load_reports(HAIL_CSV, "hail")
    print("Loading wind reports ...")
    wind = load_reports(WIND_CSV, "wind")

    # Outbreak days are defined nationally (one row per tornado).
    national_per_day = Counter(t.cday for t in national if t.cday)
    outbreak_days = {d for d, n in national_per_day.items() if n >= OUTBREAK_MIN_TORNADOES}
    print("  outbreak days (>= %d tornadoes nationally): %d" % (OUTBREAK_MIN_TORNADOES, len(outbreak_days)))

    states = defaultdict(list)
    for t in by_state:
        states[t.state].append(t)

    out = ['<?xml version="1.0" encoding="utf-8" standalone="no" ?>',
           "<!-- Generated by tools/build_tornado_climate.py from NOAA SPC data. Do not edit by hand; re-run the script. -->",
           '<TornadoClimate source="NOAA Storm Prediction Center" generated="%s" efMixFromYear="%d" linkFromYear="%d">'
           % (datetime.now().strftime("%Y-%m-%d"), EF_MIX_START_YEAR, LINK_START_YEAR)]

    print("Building region statistics ...")
    xml_region(out, "US", "United States", None, region_stats(national, outbreak_days, hail, wind))
    skipped = []
    for st in sorted(states):
        if len(states[st]) < MIN_SAMPLES:
            skipped.append(st)
            continue
        name = STATE_NAMES.get(st, st)
        xml_region(out, "US_" + st, name, "US", region_stats(states[st], outbreak_days, hail, wind))
        print("  %-3s %-22s %6d tornadoes" % (st, name, len(states[st])))
    out.append("</TornadoClimate>")

    output = os.path.abspath(OUTPUT_XML)
    os.makedirs(os.path.dirname(output), exist_ok=True)
    text = "\n".join(out) + "\n"
    with open(output, "w", encoding="ascii", errors="replace", newline="\n") as f:
        f.write(text)

    if skipped:
        print("  skipped (fewer than %d tornadoes): %s" % (MIN_SAMPLES, ", ".join(skipped)))
    print("-------------------------------")
    print("Wrote %s (%.1f KB) in %.0f s" % (output, len(text) / 1024.0, time.time() - started))


if __name__ == "__main__":
    main()
