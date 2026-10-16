# FS25 map survey (2026-10-15)

Purpose: decide which countries get crop-insurance (and climate) data first – by how many maps players
can actually play there.

## Sources

| Source | Total | Europe | North America | South America | Asia | Other |
|---|---|---|---|---|---|---|
| GIANTS ModHub (PC + console), unique maps | 294 (317 listings) | 166 | 83 | 19 | – | 49 |
| KingMods (third-party, many re-uploads / duplicates) | 858 | 461 | 179 | 63 | 6 | 149 |

The regional split is almost the same on both sites (Europe ~52 – 54 %, North America ~21 – 26 %,
South America ~6 – 7 %). ModHub listings in several categories were counted once; KingMods was only counted
per category (its pages time out for a per-map breakdown).

## ModHub maps by country (from map names / descriptions in the titles)

Variants of the same map (4x, crossplay, "25") counted once; their number in brackets.

| Country | Maps | Insurance data |
|---|---|---|
| **Germany** | **62** (+2) | estimates (§13.6) |
| **United States** | **39** named + ~31 US-style fictional (North America only) | **real RMA data** |
| **Poland** | 16 (+4) | rules + estimates (§13.4) |
| **Brazil** | 16 | **real PSR data** |
| **France** | 13 | rules + estimates (§13.7) |
| **United Kingdom** | 11 (+1) – incl. Northern Ireland, Scotland | estimates (§13.14) |
| Canada | 5 | SCIC / AFSC |
| Estonia | 4 (+1) | none |
| Netherlands | 4 | estimates (§13.8) |
| Italy | 4 | estimates (§13.10) |
| Spain | 4 | rules + estimates (§13.9) |
| Argentina | 2 | estimates (§13.12) |
| Hungary | 2 (+1) | none |
| Romania | 2 | none |
| Australia, South Africa, Austria, Switzerland, Luxembourg, Norway, Portugal, Russia | 1 each | Australia only |
| **Chile** | **0** | estimates (§13.13) |
| Fictional / no country: Europe-only ~22, all regions ~4, "Others" ~21 | ~82 | fall back to the parent region (see below) |
| Not maps (packs, signs, test map) | 7 | – |

## Base game and DLC (everyone has these)

- **Riverbend Springs** (USA) – US data.
- **Zielonka** (Poland) – Polish data.
- **Hutan Pantai** (South-East Asia) – Indonesia / Malaysia rice schemes (§13.15).
- **Highlands Fishing Expansion** (Scotland) – UK data would cover it.
- **South America DLC** (coffee, bananas; announced) – Brazil data, plus Argentina / Chile if set there.

## Conclusions

1. **Germany** has by far the most maps (62) but only estimated rates – improving its data is worth more
   than any new country.
2. **United Kingdom** (11 maps + the Highlands Fishing DLC) is the biggest gap.
3. **South-East Asia** (Hutan Pantai, a base map) needs at least a simple profile.
4. Small countries (Estonia, Hungary, Romania …) can wait or share a generic EU profile.
5. Chile (0 maps) and Argentina (2) were low priority in hindsight; keep them for the South America DLC.
6. **Fictional maps:** done – `tools/map_countries.csv` (284 maps incl. their mod names, checked against the
   descriptions) and the detection chain in `INSURANCE_DESIGN.md` §13.16 / `DB/InsuranceRegions.xml`. With the
   descriptions the split is: US 73 (incl. US-style), Germany 65, no region 27, France 17, Poland 17, Brazil 16,
   UK 14, fictional European 13, Estonia 5, Netherlands 5, Canada 5, others ≤ 3.
