========================================================================
                    TORNADO PHYSICS - CREDITS AND DATA SOURCES
========================================================================

Tornado Physics is a free, non-commercial mod for Farming Simulator 25.
This file lists everyone and every data source the mod builds on, so the
modDesc.xml can stay short. Please keep it in the mod folder when sharing.

------------------------------------------------------------------------
[1] MOD
------------------------------------------------------------------------
Scripting, physics engine and data tools: whitevamp
Testing and feedback:                     Community

Compatibility support (built into Tornado Physics):
- "Advanced Damage System" (ADS) by id577 and Squallqt
- "CompassHeading" by RocklandUSA Gaming
- "Moisture System" (FS25_MoistureSystem) by Ozz
  (https://github.com/Ozz-Modding/FS25_MoistureSystem): its drought and
  withering are used instead of ours, withered crops count for the
  insurance.
- "Red Tape" (FS25_RedTape) by Ozz: insurance premiums and payouts appear
  on its tax statement.
  https://github.com/Ozz-Modding/FS25_RedTape
- "Realistic Weather" (FS25_RealisticWeather) by Arrow-kb: our natural
  hazards switch off when it is installed.
These mods are not included in Tornado Physics and are not required; the
integration only reads from them while they are installed. No code from
them is copied into this mod.

Translations (German, French, Polish, Spanish, Italian, Dutch):
- AI-assisted translations. Corrections from native speakers are welcome.

AI assistance:
- Claude (an AI assistant by Anthropic) helped with the design, the
  implementation and the research / data gathering for the crop insurance
  system, and with the translations.
- All code and data were reviewed and tested by whitevamp, who is
  responsible for the mod.

Sound and effects (FX/):
- Tornado siren (tornado_siren.ogg): royalty-free recording of a real
  Kansas tornado warning siren, edited for this mod.
- Fire texture (fire1_64_8x8_512.dds, FireTrailSubUV, fieldFireFlames):
  royalty-free fire texture, modified for this mod. The field fire
  flames use a copy with a soft alpha (fieldFireFlames_diffuse.dds)
  with the GIANTS particle shader and emitter mesh.
- Smoke effect (smokeTrailSubUV): uses the GIANTS Software factory
  chimney smoke texture and smoke shader from Farming Simulator 25
  (loaded from the game, not included in the mod). The fire effect uses
  the same GIANTS shader.
- Field fire smoke plume (fieldFireSmoke.i3d): a particle system made
  from the GIANTS Software base-game smoke effects of Farming Simulator 25
  (train / chimney smoke emitter mesh, destroy-smoke texture and shader;
  textures and shader are loaded from the game).
- If you are the original author of the siren recording or the fire
  texture, please get in touch so you can be credited by name.

------------------------------------------------------------------------
[2] TORNADO CLIMATE DATA (Real-Life Tornado Climate mode)
------------------------------------------------------------------------
United States (DB/TornadoClimate.xml)
- Tornado, hail and wind statistics derived from the NOAA / National
  Weather Service Storm Prediction Center Severe Weather Database.
  US government work, public domain.

Canada (DB/TornadoClimate_CA.xml)
- Tornado statistics derived from Northern Tornadoes Project event data,
  Western University, licensed under CC BY-NC 4.0
  (https://creativecommons.org/licenses/by-nc/4.0/).
  The data was aggregated and modified for this mod.
- Canadian hail values are borrowed from neighbouring US states (NOAA SPC).

------------------------------------------------------------------------
[3] CROP INSURANCE DATA (DB/CropInsurance_*.xml)
------------------------------------------------------------------------
Only summary figures are included (rates, shares and totals), calculated
by the mod's own data tools. No original documents are redistributed.
Some values are the mod's own estimates; they are marked
isEstimate="true" in the XML files and are not official figures.

United States (CropInsurance_US.xml)
- USDA Risk Management Agency (RMA), Summary of Business,
  State/County/Crop/Coverage Level, crop years 2020-2024.
  US government work, public domain.

Canada (CropInsurance_CA.xml)
- Alberta hail insurance rates from Agriculture Financial Services
  Corporation (AFSC), 2026 Full Cover Hail Insurance premium rates.
- Saskatchewan crop insurance figures from the Saskatchewan Crop
  Insurance Corporation (SCIC) 2024-25 annual report.
  SCIC figures (c) 2026, Government of Saskatchewan.
- Used for a free, non-commercial mod; not an official version and not
  affiliated with or endorsed by AFSC or SCIC.
- Curve shapes from the USDA RMA data above.

Poland (CropInsurance_PL.xml)
- Polish crop insurance rules from the Act on crop and livestock
  insurance (Ustawa o ubezpieczeniach upraw rolnych i zwierzat
  gospodarskich, Dz.U. 2025 poz. 251), the Ministry of Agriculture and
  Rural Development (gov.pl) subsidy and tariff rules, and the maximum
  sums insured regulations (Dz.U. 2025 poz. 1628, Dz.U. 2024 poz. 1695).
- Premium rates are estimates, not official figures.

France (CropInsurance_FR.xml)
- French crop insurance rules from the Ministere de l'Agriculture et de
  la Souverainete alimentaire (agriculture.gouv.fr).
- Figures from the Assemblee nationale (commission des affaires
  economiques, January 2026) and La France Agricole.
- Rates are estimates, not official figures. Not affiliated with or
  endorsed by any of them.

Netherlands (CropInsurance_NL.xml)
- Dutch crop insurance rules and subsidy figures from RVO (Rijksdienst
  voor Ondernemend Nederland) and the 2024 Ecorys / WUR evaluation of the
  Subsidieregeling Brede Weersverzekering; premium range from Agriver.
- Rates are estimates, not official figures. Not affiliated with or
  endorsed by any of them.

Spain (CropInsurance_ES.xml)
- Spanish crop insurance rules from the 47th Plan de Seguros Agrarios
  Combinados (Boletin Oficial del Estado) and ENESA; figures from
  Agroseguro's annual report 2024 and "Sistema espanol de Seguros
  Agrarios Combinados".
- Rates are estimates, not official figures. Not affiliated with or
  endorsed by ENESA or Agroseguro.

Italy (CropInsurance_IT.xml)
- Italian crop insurance rules from the Piano di gestione dei rischi in
  agricoltura 2026 (Ministero dell'agricoltura, della sovranita
  alimentare e delle foreste, MASAF); figures from ISMEA.
- Rates are estimates, not official figures. Not affiliated with or
  endorsed by MASAF or ISMEA.

South-East Asia (CropInsurance_SEA.xml, for Hutan Pantai)
- Indonesian rice insurance (AUTP) figures from the Ministry of
  Agriculture and PT Asuransi Jasa Indonesia (Jasindo); Malaysian padi
  crop takaful figures from Agrobank and the Ministry of Agriculture and
  Food Security (KPKM), as reported by the press.
- Not affiliated with or endorsed by any of them.

United Kingdom (CropInsurance_GB.xml)
- UK crop insurance figures from the Northern Ireland Assembly research
  paper "Agricultural insurance" and Farmers Weekly; Insurance Premium Tax
  from HMRC.
- Rates are estimates, not official figures. Not affiliated with or
  endorsed by any of them.

Chile (CropInsurance_CL.xml)
- Chilean crop insurance rules from Agroseguros (Comite de Seguros del
  Agro) and ChileAtiende; figures from DIPRES and the Ministerio de
  Agricultura.
- Rates are estimates, not official figures. Not affiliated with or
  endorsed by any of them.

Argentina (CropInsurance_AR.xml)
- Argentine crop insurance figures from the Superintendencia de Seguros
  de la Nacion (SSN), Encuesta de Seguros en los Sectores Agropecuario y
  Forestal 2024; provincial schemes from the governments of Mendoza and
  Cordoba.
- Rates are estimates, not official figures. Not affiliated with or
  endorsed by any of them.

Australia (CropInsurance_AU.xml)
- Insurance duty rates from the Insurance Council of Australia; crop
  insurance exemptions from Revenue NSW and the State Revenue Office
  Victoria; premium ranges from Deloitte; market overview from ABARES.
- Rates are estimates, not official figures. Not affiliated with or
  endorsed by any of them. No Bureau of Meteorology data is used.

Germany (CropInsurance_DE.xml)
- German crop insurance rules from the Bavarian State Ministry for
  Food, Agriculture, Forestry and Tourism (StMELF) and the state
  programmes of Baden-Wuerttemberg, Lower Saxony and Saxony.
- Market figures from published Vereinigte Hagelversicherung VVaG
  reports; insurance tax from DLG-Merkblatt 434.
- Rates are estimates, not official figures. Not affiliated with or
  endorsed by any of them.

Brazil (CropInsurance_BR.xml)
- Brazilian crop insurance figures from the Ministerio da Agricultura e
  Pecuaria (MAPA), PSR open data (SISSER), crop years 2020-2024,
  licensed under Creative Commons Attribution
  (https://dados.agricultura.gov.br/dataset/sisser3).
  Not an official MAPA product.
- Subsidy rules from the Plano Trienal do Seguro Rural 2025-2027 (CGSR).

------------------------------------------------------------------------
[4] TERMS OF USE
------------------------------------------------------------------------
- This mod is free and non-commercial. The included climate and
  insurance data may not be used commercially.
- You are free to use this mod in videos and streams.
- Please do not re-upload this mod to other sites without permission.
