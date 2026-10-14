#!/usr/bin/env python3
"""
build_eu_weather_climate.py  -  Tornado Physics EU climate data builder
==========================================================================

Queries Open-Meteo's Historical Weather API (ERA5 reanalysis) across major
European countries and regions, aggregating them into a structured XML file
(EUWeatherClimate.xml) consumable by the FS25 Tornado Physics mod.

Requirements: Python 3.8+ and requests library (`pip install requests`)
Usage:        edit the CONFIG section below, then run
                  python build_eu_weather_climate.py

Data source:  Open-Meteo Historical Weather API (CC-BY 4.0)
              Powered by Copernicus ECMWF ERA5 reanalysis.
"""

import math
import os
import sys
import time
from collections import Counter, defaultdict
from datetime import datetime
from xml.sax.saxutils import quoteattr

try:
    import requests
except ImportError:
    sys.exit("ERROR: The 'requests' module is required. Install it via: pip install requests")

# ============================================================================
# CONFIG  -  edit these paths / values
# ============================================================================

# Where to write the output XML (e.g., next to your US database)
OUTPUT_XML = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "DB", "EUWeatherClimate.xml")

# Historical analysis date range (Open-Meteo ERA5 goes back to 1940, but 10-20 years provides robust climatology)
START_DATE = "2010-01-01"
END_DATE = "2025-12-31"

# Percentile blocks with fewer valid aggregated hours than this are omitted
MIN_SAMPLES = 50

# Decimal places for shares / weights in the XML
SHARE_DECIMALS = 4

# ============================================================================
# European Regions & Representative Coordinate Grid
# (Tailored for popular FS25 map locations across Europe)
# ============================================================================

EU_REGIONS = {
    "DE": {
        "name": "Germany",
        "parent": "EU",
        "coords": [
            (52.52, 13.41, "Berlin"), (53.55, 9.99, "Hamburg"),
            (48.13, 11.58, "Munich"), (50.93, 6.96, "Cologne"),
            (50.11, 8.68, "Frankfurt"), (51.22, 6.77, "Dusseldorf")
        ]
    },
    "FR": {
        "name": "France",
        "parent": "EU",
        "coords": [
            (48.85, 2.35, "Paris"), (43.60, 1.44, "Toulouse"),
            (45.76, 4.83, "Lyon"), (43.29, 5.36, "Marseille"),
            (47.21, -1.55, "Nantes"), (50.62, 3.05, "Lille")
        ]
    },
    "PL": {
        "name": "Poland",
        "parent": "EU",
        "coords": [
            (52.23, 21.01, "Warsaw"), (50.06, 19.94, "Krakow"),
            (51.10, 17.03, "Wroclaw"), (52.40, 16.92, "Poznan"),
            (54.35, 18.65, "Gdansk")
        ]
    },
    "GB": {
        "name": "United Kingdom",
        "parent": "EU",
        "coords": [
            (51.50, -0.12, "London"), (53.48, -2.24, "Manchester"),
            (55.95, -3.18, "Edinburgh"), (52.48, -1.89, "Birmingham"),
            (53.80, -1.54, "Leeds")
        ]
    },
    "RO": {
        "name": "Romania",
        "parent": "EU",
        "coords": [
            (44.42, 26.10, "Bucharest"), (46.77, 23.62, "Cluj"),
            (47.15, 27.60, "Iasi"), (44.33, 23.79, "Craiova")
        ]
    },
    "CZ": {
        "name": "Czech Republic",
        "parent": "EU",
        "coords": [
            (50.07, 14.43, "Prague"), (49.19, 16.60, "Brno"),
            (49.82, 18.26, "Ostrava")
        ]
    }
}

SECTORS = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]

# ============================================================================
# Helpers
# ============================================================================

def fmt(value, decimals=1):
    return ("%." + str(decimals) + "f") % value

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
    return {
        "count": len(values),
        "p10": percentile(values, 10),
        "p50": percentile(values, 50),
        "p90": percentile(values, 90),
        "max": values[-1],
    }

def shares(counter, keys):
    total = sum(counter.get(k, 0) for k in keys)
    return {k: (counter.get(k, 0) / total if total else 0.0) for k in keys}

# ============================================================================
# Open-Meteo Fetcher
# ============================================================================

def fetch_country_data(coords):
    """Fetches hourly historical wind gusts and precipitation for a list of coordinates."""
    lats = [c[0] for c in coords]
    lons = [c[1] for c in coords]

    url = "https://archive-api.open-meteo.com/v1/archive"
    params = {
        "latitude": ",".join(map(str, lats)),
        "longitude": ",".join(map(str, lons)),
        "start_date": START_DATE,
        "end_date": END_DATE,
        "hourly": "wind_gusts_10m,precipitation",
        "timezone": "UTC"
    }

    try:
        response = requests.get(url, params=params, timeout=60)
        response.raise_for_status()
        data = response.json()
        # Open-Meteo returns a list of dicts if multiple coordinates are queried
        return data if isinstance(data, list) else [data]
    except Exception as e:
        print(f"  [ERROR] Failed to fetch data from Open-Meteo: {e}")
        return None

# ============================================================================
# Statistics Aggregator
# ============================================================================

def process_station_timeseries(station_json_list):
    """Aggregates multi-station hourly arrays into unified regional metrics."""
    all_gusts = []
    month_counter = Counter()
    hour_counter = Counter()
    
    total_hours = 0
    severe_gust_count = 0  # Gusts exceeding standard severe threshold (~75 km/h)

    for stn in station_json_list:
        if not stn or "hourly" not in stn:
            continue
        times = stn["hourly"].get("time", [])
        gusts = stn["hourly"].get("wind_gusts_10m", [])

        for t_str, g_val in zip(times, gusts):
            if g_val is None:
                continue
            try:
                dt = datetime.fromisoformat(t_str)
            except ValueError:
                continue

            total_hours += 1
            all_gusts.append(g_val)
            month_counter[dt.month] += 1
            hour_counter[dt.hour] += 1

            if g_val >= 75.0:  # Severe convective wind gust benchmark
                severe_gust_count += 1

    return {
        "total_hours": total_hours,
        "severe_gust_count": severe_gust_count,
        "gusts_block": percentile_block(all_gusts),
        "months": shares(month_counter, range(1, 13)),
        "hours": shares(hour_counter, range(24))
    }

# ============================================================================
# XML Writer
# ============================================================================

def xml_region(out, region_id, name, parent, stats):
    w = out.append
    parent_attr = (" parent=%s" % quoteattr(parent)) if parent else ""
    w(f"    <region id={quoteattr(region_id)} name={quoteattr(name)} country=\"EU\"{parent_attr}>")
    w(f"        <stats totalHours=\"{stats['total_hours']}\" severeEvents=\"{stats['severe_gust_count']}\"/>")

    w("        <months>")
    for m in range(1, 13):
        w(f"            <month m=\"{m}\" weight=\"{fmt(stats['months'][m], SHARE_DECIMALS)}\"/>")
    w("        </months>")

    w("        <hours timeZone=\"UTC\">")
    for h in range(24):
        w(f"            <hour h=\"{h}\" weight=\"{fmt(stats['hours'][h], SHARE_DECIMALS)}\"/>")
    w("        </hours>")

    gb = stats["gusts_block"]
    if gb:
        w(f"        <windGusts unit=\"km/h\" count=\"{gb['count']}\" p10=\"{fmt(gb['p10'], 0)}\" p50=\"{fmt(gb['p50'], 0)}\" p90=\"{fmt(gb['p90'], 0)}\" max=\"{fmt(gb['max'], 0)}\"/>")

    w("    </region>")

# ============================================================================
# Main
# ============================================================================

def main():
    started = time.time()
    print("Tornado Physics EU Climate Builder (Open-Meteo API)")
    print("--------------------------------------------------")
    print(window_msg := f"Date Range: {START_DATE} to {END_DATE}")

    out = [
        '<?xml version="1.0" encoding="utf-8" standalone="no" ?>',
        '<!-- Generated by tools/build_eu_weather_climate.py from Open-Meteo ERA5 API. Do not edit by hand. -->',
        f'<EUWeatherClimate source="Open-Meteo ERA5 Reanalysis" generated="{datetime.now().strftime("%Y-%m-%d")}">',
        '    <region id="EU" name="Europe (Aggregate)" country="EU">'
    ]

    continental_stations = []

    for reg_key, reg_info in EU_REGIONS.items():
        print(f"Fetching climate metrics for {reg_info['name']} ({reg_key})...")
        station_data = fetch_country_data(reg_info["coords"])
        if not station_data:
            print(f"  [WARNING] Skipping {reg_info['name']} due to fetch error.")
            continue

        continental_stations.extend(station_data)
        stats = process_station_timeseries(station_data)
        
        # Write individual country block
        xml_region(out, f"EU_{reg_key}", reg_info['name'], "EU", stats)
        print(f"  Successfully processed {reg_info['name']} ({stats['total_hours']} hourly data points).")
        time.sleep(0.5)  

    # Build overarching EU continent-wide summary node
    print("Aggregating continent-wide European metrics...")
    eu_stats = process_station_timeseries(continental_stations)
    
    # Insert continent aggregate right after the root header
    out.insert(3, f"        <stats totalHours=\"{eu_stats['total_hours']}\" severeEvents=\"{eu_stats['severe_gust_count']}\"/>")
    
    # Months / Hours for aggregate
    out.insert(4, "        <months>")
    for m in range(1, 13):
        out.insert(5 + m - 1, f"            <month m=\"{m}\" weight=\"{fmt(eu_stats['months'][m], SHARE_DECIMALS)}\"/>")
    out.insert(17, "        </months>")
    
    out.insert(18, "        <hours timeZone=\"UTC\">")
    for h in range(24):
        out.insert(19 + h, f"            <hour h=\"{h}\" weight=\"{fmt(eu_stats['hours'][h], SHARE_DECIMALS)}\"/>")
    out.insert(43, "        </hours>")
    
    gb_eu = eu_stats["gusts_block"]
    if gb_eu:
        out.insert(44, f"        <windGusts unit=\"km/h\" count=\"{gb_eu['count']}\" p10=\"{fmt(gb_eu['p10'], 0)}\" p50=\"{fmt(gb_eu['p50'], 0)}\" p90=\"{fmt(gb_eu['p90'], 0)}\" max=\"{fmt(gb_eu['max'], 0)}\"/>")
    out.insert(45, "    </region>")

    out.append("</EUWeatherClimate>")

    output_path = os.path.abspath(OUTPUT_XML)
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    text = "\n".join(out) + "\n"
    
    with open(output_path, "w", encoding="ascii", errors="replace", newline="\n") as f:
        f.write(text)

    print("--------------------------------------------------")
    print(f"Wrote EU Weather Database -> {output_path} (%.1f KB) in %.0f s" % (len(text) / 1024.0, time.time() - started))

if __name__ == "__main__":
    main()