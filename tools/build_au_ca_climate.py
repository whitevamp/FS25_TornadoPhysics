#!/usr/bin/env python3
"""
build_au_ca_climate.py  -  Tornado Physics climate data builder for Australia and Canada
=======================================================================================

Turns the Australian and Canadian severe-weather CSV files into the same climate XML format the
mod already reads for the US (see build_tornado_climate.py):

    DB/TornadoClimate_AU.xml   (Australia + one region per state)
    DB/TornadoClimate_CA.xml   (Canada + one region per province)

Each region gets: stats, efMix, months, hours (local time), pathLength, pathWidth, direction,
outbreak, hail, wind - blocks with too few samples are left out and the mod falls back to the
country-wide region.

Requirements: Python 3.8+, standard library only.
Usage:        edit the CONFIG section below, then run
                  python build_au_ca_climate.py

----------------------------------------------------------------------------
Sources
----------------------------------------------------------------------------
  Australia : Bureau of Meteorology - Severe Storms Archive (tornado.csv, hail.csv, wind.csv)
  Canada    : Northern Tornadoes Project (NTP), Western University - event summaries export
  Check each source's licence / attribution wording before release and credit them in the mod.

----------------------------------------------------------------------------
How the files are read
----------------------------------------------------------------------------
Australia
  * Date/Time is UTC (the comments confirm it, e.g. 06:00 = "around 4pm AEST"); converted to each
    state's local standard time (no daylight saving) for the hour-of-day shares.
  * Rating   : "Fujita scale" (0..5).
  * Path     : "Path length" / "Path width" in metres, 0 = not recorded.
  * Direction: "Path direction" in degrees, 0 = not recorded. Whether the archive means the direction
    the storm came FROM or moved TOWARD is set by AU_PATH_DIRECTION_IS_FROM below.
  * Funnel clouds that never reached the ground are dropped (EXCLUDE_FUNNEL_ONLY).
  * hail.csv: "Hail size" in cm, 0 = unknown. wind.csv: "Max Gust speed" in knots, 0 = unknown.
Canada (NTP)
  * Only "tornado_over_land" events (waterspouts optional: INCLUDE_WATERSPOUTS).
  * There is no rating column. The EF rating is derived from "Maximum Wind Speed (km/h)" with the
    Canadian EF-scale wind bands; if that is empty, a single "EF<n>" in the description is used,
    otherwise the event counts as unrated (left out of the EF mix only).
  * Time from Year / Month / Day + "Time (Local)" (hhmm), local clock time.
  * Track Length in km, Maximum Path Width in m, "Mean Motion (from)" in degrees -> moving toward +180.
  * No hail data in the NTP export: each province borrows the hail block of a neighbouring US state
    from the US climate file (CA_HAIL_FROM_US); Canada-wide gets their tornado-weighted average.
    Borrowed blocks carry borrowedFrom="US_xx" in the XML.
  * Severe wind: NTP "downburst" events with a wind speed.
Both
  * A convective day runs 06:00 to 06:00 local time, so an overnight storm counts as one day.
  * Outbreak day = at least OUTBREAK_MIN_TORNADOES[country] tornadoes in the whole country that day.
"""

import csv
import glob
import math
import os
import re
import sys
import time
from collections import Counter, defaultdict
from datetime import datetime, timedelta
from xml.sax.saxutils import quoteattr

# ============================================================================
# CONFIG  -  edit these paths / values
# ============================================================================

# Folder that holds the "Australia" and "canada" sub-folders.
DATA_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "weather_csv_files_for_tornadophysics")

AU_DIR = os.path.join(DATA_DIR, "Australia")
AU_TORNADO_CSV = os.path.join(AU_DIR, "tornado.csv")
AU_HAIL_CSV = os.path.join(AU_DIR, "hail.csv")        # None to skip
AU_WIND_CSV = os.path.join(AU_DIR, "wind.csv")        # None to skip

CA_DIR = os.path.join(DATA_DIR, "canada")
CA_EVENTS_CSV = None                                   # None = first *.csv found in CA_DIR

# Output files (next to the US TornadoClimate.xml).
DB_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "DB")
AU_OUTPUT_XML = os.path.join(DB_DIR, "TornadoClimate_AU.xml")
CA_OUTPUT_XML = os.path.join(DB_DIR, "TornadoClimate_CA.xml")

# True: Australian "Path direction" is the direction the tornado came FROM (meteorological convention),
# so the direction of travel is +180. False: it is already the direction of travel.
AU_PATH_DIRECTION_IS_FROM = True

# Drop Australian reports of funnel clouds that never reached the ground.
EXCLUDE_FUNNEL_ONLY = True

# Canada: also count tornadoes over water (waterspouts).
INCLUDE_WATERSPOUTS = False

# Canada has no hail data: borrow the hail block of a neighbouring US state with a similar storm climate.
# Needs the US file built by build_tornado_climate.py. Set CA_HAIL_FROM_US = {} to leave Canada without hail.
US_CLIMATE_XML = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "DB", "TornadoClimate.xml")
CA_HAIL_FROM_US = {
    "AB": "US_MT",   # Alberta      <- Montana (shared border, high-plains storms)
    "SK": "US_ND",   # Saskatchewan <- North Dakota
    "MB": "US_MN",   # Manitoba     <- Minnesota
    "ON": "US_MI",   # Ontario      <- Michigan (Great Lakes)
    "QC": "US_NY",   # Quebec       <- New York (St. Lawrence / north-east)
}

# Hail / wind reports count as "with this tornado" on the same convective day within this distance.
LINK_RADIUS_KM = 80.0

# Outbreak day threshold per country (tornadoes in the whole country on one convective day).
OUTBREAK_MIN_TORNADOES = {"AU": 3, "CA": 6}

# Blocks with fewer values than this are left out (the mod uses the country-wide region instead).
MIN_SAMPLES = 15

SHARE_DECIMALS = 4

# ============================================================================
# Constants
# ============================================================================

KNOT_KMH = 1.852
SECTORS = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]

AU_STATES = {
    "NSW": "New South Wales", "VIC": "Victoria", "QLD": "Queensland", "WA": "Western Australia",
    "SA": "South Australia", "TAS": "Tasmania", "NT": "Northern Territory", "ACT": "Australian Capital Territory",
}
# Local standard time offsets from UTC in hours (no daylight saving).
AU_UTC_OFFSET = {"NSW": 10, "VIC": 10, "QLD": 10, "TAS": 10, "ACT": 10, "SA": 9.5, "NT": 9.5, "WA": 8}

CA_PROVINCES = {
    "Ontario": "ON", "Quebec": "QC", "Alberta": "AB", "Saskatchewan": "SK", "Manitoba": "MB",
    "British Columbia": "BC", "New Brunswick": "NB", "Nova Scotia": "NS", "Newfoundland and Labrador": "NL",
    "Prince Edward Island": "PE", "Northwest Territories": "NT", "Yukon": "YT", "Nunavut": "NU",
}

# Canadian EF scale (Environment and Climate Change Canada): lower wind bound in km/h per rating.
CA_EF_WIND_MIN = [(5, 315), (4, 270), (3, 225), (2, 180), (1, 135), (0, 90)]

FUNNEL_ONLY = re.compile(
    r"(did ?n.?t|did not|does not|doesn.?t|not appear to|never|no evidence (it|of it)) .{0,25}(touch|reach)(ed)? (the )?ground"
    r"|remained .{0,30}above (the )?ground|funnel cloud aloft|not (confirmed|positive)",
    re.IGNORECASE)

# ============================================================================
# Helpers
# ============================================================================


def num(value, default=None):
    try:
        return float(str(value).strip())
    except (TypeError, ValueError):
        return default


def open_csv(path):
    if path is None:
        return None
    if not os.path.isfile(path):
        sys.exit("ERROR: file not found: %s\n       Check the CONFIG section at the top of this script." % path)
    return open(path, "r", encoding="utf-8-sig", errors="replace", newline="")


def valid_point(lat, lon):
    return lat is not None and lon is not None and lat != 0 and lon != 0 and abs(lat) <= 90 and abs(lon) <= 180


def distance_km(lat1, lon1, lat2, lon2):
    x = math.radians(lon2 - lon1) * math.cos(math.radians((lat1 + lat2) * 0.5))
    y = math.radians(lat2 - lat1)
    return 6371.0 * math.hypot(x, y)


def convective_day(dt_local):
    return (dt_local - timedelta(hours=6)).date()


def percentile(sorted_values, p):
    if not sorted_values:
        return None
    if len(sorted_values) == 1:
        return sorted_values[0]
    k = (len(sorted_values) - 1) * p / 100.0
    lo = int(math.floor(k))
    hi = min(lo + 1, len(sorted_values) - 1)
    return sorted_values[lo] + (sorted_values[hi] - sorted_values[lo]) * (k - lo)


def percentile_block(values):
    values = sorted(v for v in values if v is not None)
    if len(values) < MIN_SAMPLES:
        return None
    return {"count": len(values), "p10": percentile(values, 10), "p50": percentile(values, 50),
            "p90": percentile(values, 90), "max": values[-1]}


def shares(counter, keys):
    total = sum(counter.get(k, 0) for k in keys)
    return {k: (counter.get(k, 0) / total if total else 0.0) for k in keys}


def fmt(value, decimals=1):
    return ("%." + str(decimals) + "f") % value


class Tornado:
    __slots__ = ("year", "region", "ef", "dt", "cday", "lat", "lon", "len_m", "wid_m", "heading", "hour_known")


class ReportIndex:
    """Hail / wind reports bucketed by convective day and 1-degree cell; magnitude already in cm or km/h."""

    def __init__(self, label):
        self.label = label
        self.cells = defaultdict(list)
        self.count = 0

    def add(self, cday, lat, lon, mag):
        self.cells[(cday, int(math.floor(lat)), int(math.floor(lon)))].append((lat, lon, mag))
        self.count += 1

    def max_nearby(self, cday, lat, lon, radius_km):
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


# ============================================================================
# Australia
# ============================================================================


def au_local_time(row, state):
    try:
        dt_utc = datetime.strptime((row.get("Date/Time") or "").strip(), "%Y-%m-%d %H:%M:%S")
    except ValueError:
        return None
    return dt_utc + timedelta(hours=AU_UTC_OFFSET.get(state, 10))


def load_au():
    tornadoes, dropped = [], 0
    with open_csv(AU_TORNADO_CSV) as f:
        for row in csv.DictReader(f):
            state = (row.get("State") or "").strip().upper()
            dt = au_local_time(row, state)
            if dt is None or state not in AU_STATES:
                continue
            if EXCLUDE_FUNNEL_ONLY and FUNNEL_ONLY.search(row.get("Comments") or ""):
                dropped += 1
                continue
            t = Tornado()
            t.year, t.region, t.dt, t.cday = dt.year, state, dt, convective_day(dt)
            t.hour_known = True
            f_scale = num(row.get("Fujita scale"))
            t.ef = int(f_scale) if f_scale is not None and 0 <= f_scale <= 5 else -9
            t.lat, t.lon = num(row.get("Latitude")), num(row.get("Longitude"))
            length, width = num(row.get("Path length"), 0), num(row.get("Path width"), 0)
            t.len_m = length if length > 0 else None
            t.wid_m = width if width > 0 else None
            direction = num(row.get("Path direction"), 0)
            t.heading = None
            if direction > 0:
                t.heading = ((direction + 180) if AU_PATH_DIRECTION_IS_FROM else direction) % 360
            tornadoes.append(t)
    print("  Australia: %d tornadoes (%d funnel-cloud-only reports dropped)" % (len(tornadoes), dropped))

    def load_reports(path, label, mag_column, to_unit):
        if path is None:
            return None
        index = ReportIndex(label)
        with open_csv(path) as f:
            for row in csv.DictReader(f):
                state = (row.get("State") or "").strip().upper()
                dt = au_local_time(row, state)
                lat, lon = num(row.get("Latitude")), num(row.get("Longitude"))
                if dt is None or not valid_point(lat, lon):
                    continue
                index.add(convective_day(dt), lat, lon, max(0.0, num(row.get(mag_column), 0.0)) * to_unit)
        print("  Australia %s reports: %d" % (label, index.count))
        return index

    hail = load_reports(AU_HAIL_CSV, "hail", "Hail size", 1.0)                 # cm
    wind = load_reports(AU_WIND_CSV, "wind", "Max Gust speed", KNOT_KMH)       # knots -> km/h
    return tornadoes, hail, wind


# ============================================================================
# Canada
# ============================================================================


def ca_rating(row):
    wind = num(row.get("Maximum Wind Speed (km/h)"))
    if wind is not None and wind > 0:
        for ef, minimum in CA_EF_WIND_MIN:
            if wind >= minimum:
                return ef
        return 0
    found = set(re.findall(r"\bEF-?([0-5])\b", row.get("Event Description") or ""))
    return int(found.pop()) if len(found) == 1 else -9


def ca_local_time(row):
    year, month, day = num(row.get("Year")), num(row.get("Month")), num(row.get("Day"))
    if year is None or month is None or day is None:
        return None
    clock = re.sub(r"\D", "", row.get("Time (Local)") or "")
    known = len(clock) >= 3
    hour, minute = (int(clock[:-2] or 0), int(clock[-2:])) if known else (12, 0)
    try:
        return datetime(int(year), int(month), int(day), min(hour, 23), min(minute, 59)), known
    except ValueError:
        return None


def load_ca():
    path = CA_EVENTS_CSV or (sorted(glob.glob(os.path.join(CA_DIR, "*.csv"))) or [None])[0]
    if path is None:
        sys.exit("ERROR: no Canadian CSV found in %s" % CA_DIR)
    event_types = {"tornado_over_land"} | ({"tornado_over_water"} if INCLUDE_WATERSPOUTS else set())

    tornadoes, wind, unrated = [], ReportIndex("wind"), 0
    with open_csv(path) as f:
        for row in csv.DictReader(f):
            event_type = (row.get("Event Type") or "").strip()
            province = CA_PROVINCES.get((row.get("Province") or "").strip())
            local = ca_local_time(row)
            lat, lon = num(row.get("y")), num(row.get("x"))
            if province is None or local is None:
                continue
            dt, hour_known = local

            if event_type == "downburst":
                speed = num(row.get("Maximum Wind Speed (km/h)"), 0.0)
                if valid_point(lat, lon):
                    wind.add(convective_day(dt), lat, lon, max(0.0, speed))
                continue
            if event_type not in event_types:
                continue

            t = Tornado()
            t.year, t.region, t.dt, t.cday = dt.year, province, dt, convective_day(dt)
            t.hour_known = hour_known
            t.ef = ca_rating(row)
            unrated += 1 if t.ef < 0 else 0
            t.lat, t.lon = lat, lon
            length_km, width = num(row.get("Track Length (km)"), 0), num(row.get("Maximum Path Width (m)"), 0)
            t.len_m = length_km * 1000 if length_km > 0 else None
            t.wid_m = width if width > 0 else None
            motion_from = num(row.get("Mean Motion (from)"))
            t.heading = (motion_from + 180) % 360 if motion_from is not None and motion_from > 0 else None
            tornadoes.append(t)

    print("  Canada: %d tornadoes (%d unrated), %d downburst wind reports" % (len(tornadoes), unrated, wind.count))
    return tornadoes, None, wind


# ============================================================================
# Statistics
# ============================================================================


def region_stats(tornadoes, outbreak_days, hail, wind):
    years = [t.year for t in tornadoes]
    first, last = min(years), max(years)
    stats = {"count": len(tornadoes), "first": first, "last": last, "perYear": len(tornadoes) / (last - first + 1)}

    ef_counter = Counter(t.ef for t in tornadoes if 0 <= t.ef <= 5)
    stats["efCounts"] = ef_counter
    stats["efMix"] = shares(ef_counter, range(6))
    stats["months"] = shares(Counter(t.dt.month for t in tornadoes), range(1, 13))
    stats["hours"] = shares(Counter(t.dt.hour for t in tornadoes if t.hour_known), range(24))

    stats["length"], stats["width"] = {}, {}
    for ef in range(6):
        rated = [t for t in tornadoes if t.ef == ef]
        stats["length"][ef] = percentile_block(t.len_m for t in rated)
        stats["width"][ef] = percentile_block(t.wid_m for t in rated)

    headings = [t.heading for t in tornadoes if t.heading is not None]
    stats["direction"] = None
    if len(headings) >= MIN_SAMPLES:
        sector_counter = Counter(SECTORS[int(((h + 22.5) % 360) // 45)] for h in headings)
        sx = sum(math.sin(math.radians(h)) for h in headings)
        sy = sum(math.cos(math.radians(h)) for h in headings)
        stats["direction"] = {"count": len(headings), "meanDeg": (math.degrees(math.atan2(sx, sy)) + 360) % 360,
                              "consistency": math.hypot(sx, sy) / len(headings),
                              "sectors": shares(sector_counter, SECTORS)}

    per_day = Counter(t.cday for t in tornadoes)
    stats["tornadoDays"] = len(per_day)
    counts = sorted(per_day.values())
    stats["outbreak"] = {"dayShare": sum(1 for d in per_day if d in outbreak_days) / len(per_day),
                         "perDayP50": percentile(counts, 50), "perDayP90": percentile(counts, 90),
                         "perDayMax": counts[-1]} if per_day else None

    for key, index in (("hail", hail), ("wind", wind)):
        stats[key] = None
        if index is None:
            continue
        candidates = [t for t in tornadoes if valid_point(t.lat, t.lon)]
        linked, sizes = 0, []
        for t in candidates:
            best = index.max_nearby(t.cday, t.lat, t.lon, LINK_RADIUS_KM)
            if best is not None:
                linked += 1
                if best > 0:
                    sizes.append(best)
        if len(candidates) >= MIN_SAMPLES:
            stats[key] = {"count": len(candidates), "chance": linked / len(candidates), "sizes": percentile_block(sizes)}
    return stats


# ============================================================================
# XML (same layout as build_tornado_climate.py; hail in cm and wind in km/h already)
# ============================================================================


def xml_region(out, region_id, name, country, parent, stats, outbreak_min):
    w = out.append
    parent_attr = (" parent=%s" % quoteattr(parent)) if parent else ""
    w("    <region id=%s name=%s country=%s%s>" % (quoteattr(region_id), quoteattr(name), quoteattr(country), parent_attr))
    w("        <stats tornadoes=\"%d\" perYear=\"%s\" tornadoDays=\"%d\" firstYear=\"%d\" lastYear=\"%d\"/>"
      % (stats["count"], fmt(stats["perYear"], 2), stats["tornadoDays"], stats["first"], stats["last"]))

    efc = stats["efCounts"]
    w("        <efMix fromYear=\"%d\" count=\"%d\">" % (stats["first"], sum(efc.values())))
    for ef in range(6):
        w("            <ef rating=\"%d\" share=\"%s\" count=\"%d\"/>" % (ef, fmt(stats["efMix"][ef], SHARE_DECIMALS), efc.get(ef, 0)))
    w("        </efMix>")

    w("        <months>")
    for m in range(1, 13):
        w("            <month m=\"%d\" weight=\"%s\"/>" % (m, fmt(stats["months"][m], SHARE_DECIMALS)))
    w("        </months>")
    w("        <hours timeZone=\"local\">")
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
        w("        <direction count=\"%d\" meanDeg=\"%s\" consistency=\"%s\">" % (d["count"], fmt(d["meanDeg"], 0), fmt(d["consistency"], 3)))
        for s in SECTORS:
            w("            <toward sector=\"%s\" share=\"%s\"/>" % (s, fmt(d["sectors"][s], SHARE_DECIMALS)))
        w("        </direction>")

    o = stats["outbreak"]
    if o:
        w("        <outbreak minTornadoesNational=\"%d\" dayShare=\"%s\" perDayP50=\"%s\" perDayP90=\"%s\" perDayMax=\"%d\"/>"
          % (outbreak_min, fmt(o["dayShare"], SHARE_DECIMALS), fmt(o["perDayP50"], 1), fmt(o["perDayP90"], 1), o["perDayMax"]))

    h = stats["hail"]
    if h:
        attrs = "count=\"%d\" chance=\"%s\" radiusKm=\"%s\"" % (h["count"], fmt(h["chance"], SHARE_DECIMALS), fmt(LINK_RADIUS_KM, 0))
        if h.get("borrowedFrom"):
            attrs += " borrowedFrom=%s" % quoteattr(h["borrowedFrom"])
        if h["sizes"]:
            s = h["sizes"]
            attrs += " sizeP50Cm=\"%s\" sizeP90Cm=\"%s\" sizeMaxCm=\"%s\"" % (fmt(s["p50"], 1), fmt(s["p90"], 1), fmt(s["max"], 1))
        w("        <hail %s/>" % attrs)

    wd = stats["wind"]
    if wd:
        attrs = "count=\"%d\" chance=\"%s\" radiusKm=\"%s\"" % (wd["count"], fmt(wd["chance"], SHARE_DECIMALS), fmt(LINK_RADIUS_KM, 0))
        if wd["sizes"]:
            s = wd["sizes"]
            attrs += " gustP50Kmh=\"%s\" gustP90Kmh=\"%s\" gustMaxKmh=\"%s\"" % (fmt(s["p50"], 0), fmt(s["p90"], 0), fmt(s["max"], 0))
        w("        <wind %s/>" % attrs)
    w("    </region>")


def load_us_hail_blocks():
    """US region id -> hail block (chance, sizes in cm) from the US climate XML, or {} if unavailable."""
    if not CA_HAIL_FROM_US:
        return {}
    if not os.path.isfile(US_CLIMATE_XML):
        print("  [WARNING] %s not found - Canada gets no hail. Run build_tornado_climate.py first." % US_CLIMATE_XML)
        return {}
    import xml.etree.ElementTree as ET
    blocks = {}
    for region in ET.parse(US_CLIMATE_XML).getroot().findall("region"):
        hail = region.find("hail")
        if hail is None or hail.get("chance") is None:
            continue
        sizes = None
        if hail.get("sizeP50Cm") is not None:
            sizes = {"p50": float(hail.get("sizeP50Cm")), "p90": float(hail.get("sizeP90Cm")),
                     "max": float(hail.get("sizeMaxCm"))}
        blocks[region.get("id")] = {"count": int(hail.get("count", 0)), "chance": float(hail.get("chance")),
                                    "sizes": sizes, "borrowedFrom": region.get("id")}
    return blocks


def weighted_hail(blocks_and_weights):
    """Tornado-weighted average of several hail blocks (for the country-wide region)."""
    total = sum(w for _, w in blocks_and_weights)
    if total <= 0:
        return None
    sized = [(b, w) for b, w in blocks_and_weights if b["sizes"] is not None]
    sized_total = sum(w for _, w in sized)
    sizes = None
    if sized_total > 0:
        sizes = {k: sum(b["sizes"][k] * w for b, w in sized) / sized_total for k in ("p50", "p90", "max")}
        sizes["max"] = max(b["sizes"]["max"] for b, _ in sized)
    return {"count": sum(b["count"] for b, _ in blocks_and_weights),
            "chance": sum(b["chance"] * w for b, w in blocks_and_weights) / total,
            "sizes": sizes, "borrowedFrom": ",".join(sorted(b["borrowedFrom"] for b, _ in blocks_and_weights))}


def build_country(country, country_id, country_name, sub_names, tornadoes, hail, wind, output, source,
                  borrowed_hail=None):
    outbreak_min = OUTBREAK_MIN_TORNADOES[country]
    per_day = Counter(t.cday for t in tornadoes)
    outbreak_days = {d for d, n in per_day.items() if n >= outbreak_min}
    print("  %s outbreak days (>= %d tornadoes nationally): %d" % (country_name, outbreak_min, len(outbreak_days)))

    out = ['<?xml version="1.0" encoding="utf-8" standalone="no" ?>',
           "<!-- Generated by tools/build_au_ca_climate.py. Do not edit by hand; re-run the script. -->",
           '<TornadoClimate source=%s generated="%s">' % (quoteattr(source), datetime.now().strftime("%Y-%m-%d"))]

    by_region = defaultdict(list)
    for t in tornadoes:
        by_region[t.region].append(t)

    country_stats = region_stats(tornadoes, outbreak_days, hail, wind)
    if country_stats["hail"] is None and borrowed_hail:
        parts = [(borrowed_hail[code], len(by_region[code])) for code in borrowed_hail if by_region.get(code)]
        country_stats["hail"] = weighted_hail(parts)
    xml_region(out, country_id, country_name, country, None, country_stats, outbreak_min)
    skipped = []
    for code in sorted(by_region, key=lambda c: sub_names[c]):
        if len(by_region[code]) < MIN_SAMPLES:
            skipped.append(code)
            continue
        stats = region_stats(by_region[code], outbreak_days, hail, wind)
        if stats["hail"] is None and borrowed_hail and code in borrowed_hail:
            stats["hail"] = borrowed_hail[code]
        xml_region(out, "%s_%s" % (country_id, code), sub_names[code], country, country_id, stats, outbreak_min)
        print("    %-4s %-28s %5d tornadoes" % (code, sub_names[code], len(by_region[code])))
    if skipped:
        print("    skipped (fewer than %d tornadoes, use %s-wide data): %s" % (MIN_SAMPLES, country_name, ", ".join(skipped)))
    out.append("</TornadoClimate>")

    output = os.path.abspath(output)
    os.makedirs(os.path.dirname(output), exist_ok=True)
    text = "\n".join(out) + "\n"
    with open(output, "w", encoding="ascii", errors="replace", newline="\n") as f:
        f.write(text)
    print("  Wrote %s (%.1f KB)" % (output, len(text) / 1024.0))


def main():
    started = time.time()
    print("Tornado Physics climate builder - Australia / Canada")
    print("-----------------------------------------------------")

    print("Australia ...")
    tornadoes, hail, wind = load_au()
    build_country("AU", "AUS", "Australia", AU_STATES, tornadoes, hail, wind, AU_OUTPUT_XML,
                  "Bureau of Meteorology Severe Storms Archive")

    print("Canada ...")
    tornadoes, hail, wind = load_ca()
    province_names = {code: name for name, code in CA_PROVINCES.items()}
    us_hail = load_us_hail_blocks()
    borrowed = {code: us_hail[us_id] for code, us_id in CA_HAIL_FROM_US.items() if us_id in us_hail}
    for code, us_id in CA_HAIL_FROM_US.items():
        if us_id in us_hail:
            print("  hail for %s borrowed from %s" % (code, us_id))
    build_country("CA", "CAN", "Canada", province_names, tornadoes, hail, wind, CA_OUTPUT_XML,
                  "Northern Tornadoes Project, Western University (hail: NOAA SPC, neighbouring US states)",
                  borrowed_hail=borrowed)

    print("-----------------------------------------------------")
    print("Done in %.0f s" % (time.time() - started))


if __name__ == "__main__":
    main()
