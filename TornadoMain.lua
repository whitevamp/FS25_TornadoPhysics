---@class TornadoMain
---@description The Central Manager. Loads and updates all sub-modules in the correct order.

TornadoMain = {}
local modDir = g_currentModDirectory
local modName = g_currentModName

-- Player-visible texts in the player's language (used by the events below and every module).
source(Utils.getFilename("scripts/TornadoText.lua", modDir))

-- Player-visible texts in the player's language (used by the events below and every module).
source(Utils.getFilename("scripts/TornadoText.lua", modDir))

-- Multiplayer network events. These MUST be loaded here, while the mod's scripts load: the game only
-- allows registering event classes before a mission exists (InitEventClass), so not from loadMap().
source(Utils.getFilename("scripts/events/TornadoSettingsEvent.lua", modDir))
source(Utils.getFilename("scripts/events/TornadoActionEvent.lua", modDir))
source(Utils.getFilename("scripts/events/TornadoStateEvent.lua", modDir))
source(Utils.getFilename("scripts/events/TornadoWeatherEvent.lua", modDir))
source(Utils.getFilename("scripts/events/TornadoDestructionEvent.lua", modDir))
source(Utils.getFilename("scripts/events/TornadoFxEvent.lua", modDir))
source(Utils.getFilename("scripts/events/TornadoMessageEvent.lua", modDir))
source(Utils.getFilename("scripts/events/TornadoFieldFireEvent.lua", modDir))
source(Utils.getFilename("scripts/events/TornadoInsuranceActionEvent.lua", modDir))
source(Utils.getFilename("scripts/events/TornadoInsuranceStateEvent.lua", modDir))
source(Utils.getFilename("scripts/events/TornadoMessageLogEvent.lua", modDir))

-- Insurance rows on the Finances page: must exist before the savegame builds the farms' finance tables.
source(Utils.getFilename("scripts/insurance/TornadoInsuranceFinance.lua", modDir))

function TornadoMain:loadMap(name)
    print("--------------------------------------------------")
    print("TORNADO MOD SYSTEM: INITIALIZING MAIN CONTROLLER")

    -- 1. LOAD SCRIPTS
    -- Load the Public API First
    source(Utils.getFilename("API/TornadoAPI.lua", modDir))

    -- Load the Debug script.
    source(Utils.getFilename("scripts/TornadoDebug.lua", modDir))

    -- Load the Settings script.
    source(Utils.getFilename("scripts/TornadoSettings.lua", modDir))

    -- Load SFX scripts.
    source(Utils.getFilename("scripts/TornadoSFX.lua", modDir))
    source(Utils.getFilename("scripts/TornadoEffects.lua", modDir))

    -- Load Husbandries script.
    source(Utils.getFilename("scripts/TornadoHusbandry.lua", modDir))

    -- Load Cargo spillage system.
    source(Utils.getFilename("scripts/TornadoCargo.lua", modDir))

    -- Load Advanced Damage System, mod intergration script.
    source(Utils.getFilename("scripts/TornadoADS.lua", modDir))

    -- Moisture System (Ozz) integration: its drought / withering instead of ours, withering -> damage report.
    source(Utils.getFilename("scripts/TornadoMoisture.lua", modDir))

    -- Load the physics system.
    source(Utils.getFilename("scripts/TornadoPhysics.lua", modDir))

    -- Weather system.
    source(Utils.getFilename("scripts/TornadoWeather.lua", modDir))

    -- AI road traffic roadblocks around the tornado.
    source(Utils.getFilename("scripts/TornadoTraffic.lua", modDir))

    -- Wildlife flees the tornado, the farm dog runs home.
    source(Utils.getFilename("scripts/TornadoWildlife.lua", modDir))

    -- Optional natural hazards (drought ...) - the perils the crop insurance will pay for.
    source(Utils.getFilename("scripts/TornadoHazards.lua", modDir))
    source(Utils.getFilename("scripts/TornadoFieldFireFX.lua", modDir))

    -- Optional real-life climate mode (EF / size rolled from NOAA statistics).
    source(Utils.getFilename("scripts/TornadoRegion.lua", modDir))
    source(Utils.getFilename("scripts/TornadoClimate.lua", modDir))
    source(Utils.getFilename("scripts/TornadoOutbreak.lua", modDir))

    -- Optional per-farm insurance (OFF by default; docs/INSURANCE_DESIGN.md).
    source(Utils.getFilename("scripts/insurance/TornadoInsuranceData.lua", modDir))
    source(Utils.getFilename("scripts/insurance/TornadoInsuranceCrops.lua", modDir))
    source(Utils.getFilename("scripts/insurance/TornadoInsuranceDamage.lua", modDir))
    source(Utils.getFilename("scripts/insurance/TornadoInsurancePrograms.lua", modDir))
    source(Utils.getFilename("scripts/insurance/TornadoInsuranceCrop.lua", modDir))
    source(Utils.getFilename("scripts/insurance/TornadoInsuranceEquipment.lua", modDir))
    source(Utils.getFilename("scripts/insurance/TornadoInsuranceLivestock.lua", modDir))
    source(Utils.getFilename("scripts/insurance/TornadoInsurance.lua", modDir))

    -- Saves the active tornado / outbreak with the savegame so a reload carries on.
    source(Utils.getFilename("scripts/TornadoPersistence.lua", modDir))

    -- Message history for the control panel's Messages tab.
    source(Utils.getFilename("scripts/TornadoMessageLog.lua", modDir))

    -- Multiplayer sync (settings, tornado state, weather, destruction, effects, messages).
    source(Utils.getFilename("scripts/TornadoSync.lua", modDir))

    -- Load the console commands.
    source(Utils.getFilename("scripts/TornadoConsole.lua", modDir))

    -- Load the control panel UI (base page first, then one script per tab, then the screen).
    source(Utils.getFilename("scripts/gui/TornadoMenuPage.lua", modDir))
    source(Utils.getFilename("scripts/gui/TornadoTable.lua", modDir))
    source(Utils.getFilename("scripts/gui/pages/TornadoPageSettings.lua", modDir))
    source(Utils.getFilename("scripts/gui/pages/TornadoPagePhysics.lua", modDir))
    source(Utils.getFilename("scripts/gui/pages/TornadoPageTuning.lua", modDir))
    source(Utils.getFilename("scripts/gui/pages/TornadoPageEffects.lua", modDir))
    source(Utils.getFilename("scripts/gui/pages/TornadoPageModules.lua", modDir))
    source(Utils.getFilename("scripts/gui/pages/TornadoPageInsurance.lua", modDir))
    source(Utils.getFilename("scripts/gui/pages/TornadoPageMessages.lua", modDir))
    source(Utils.getFilename("scripts/gui/pages/TornadoPageDeveloper.lua", modDir))
    source(Utils.getFilename("scripts/gui/TornadoMenu.lua", modDir))

    -- Load CompassHeading mod intergration by RocklandUSA Gaming
    source(Utils.getFilename("scripts/TornadoCompass.lua", modDir))

    -- Load the NFW mod intergration script
    --source(Utils.getFilename("scripts/TornadoNFW.lua", modDir))

    -- Load the vehicle reset/recovery script.
    source(Utils.getFilename("scripts/TornadoRecovery.lua", modDir))

    -- Load Destruction Module
    source(Utils.getFilename("scripts/TornadoDestruction.lua", modDir))

    -- Load the mapui
    source(Utils.getFilename("scripts/TornadoHotspot.lua", modDir))
    source(Utils.getFilename("scripts/TornadoMapUI.lua", modDir))

    -- Source the Emergency Manager using exact pattern
    -- source(Utils.getFilename("scripts/TornadoEmergencyManager.lua", modDir))

    -- 2. INITIALIZE MODULES (non-UI stuff is safe here)
    if TornadoDebug then TornadoDebug:loadMap() end
    if TornadoSettings then TornadoSettings:loadMap(name) end
    if TornadoSFX then TornadoSFX:loadMap(name, modDir) end
    if TornadoEffects then TornadoEffects:loadMap(name, modDir) end
    if TornadoHusbandry then TornadoHusbandry:loadMap(name) end

    if TornadoCargo then TornadoCargo:loadMap() end
    if TornadoADS then TornadoADS:loadMap() end
    if TornadoMoisture then TornadoMoisture:loadMap() end
    if TornadoCompass then TornadoCompass:loadMap(name) end
    --if TornadoNFW then TornadoNFW:loadMap() end

    -- Initialize Destruction (Before Physics uses it)
    if TornadoDestruction then TornadoDestruction:loadMap(name, modDir) end

    -- Run map initialization for the emergency system
    -- if TornadoEmergencyManager and TornadoEmergencyManager.loadMap then
    --     TornadoEmergencyManager:loadMap(name, modDir)
    -- end

    -- Install Recovery/Insurance Hooks ONCE during startup
    if TornadoRecovery then TornadoRecovery:installHooks() end

    if TornadoPhysics then TornadoPhysics:loadMap(name, modDir) end
    if TornadoWeather then TornadoWeather:loadMap(name) end
    if TornadoTraffic then TornadoTraffic:loadMap() end
    if TornadoWildlife then TornadoWildlife:loadMap() end
    if TornadoHazards then TornadoHazards:loadMap() end
    if TornadoFieldFireFX then TornadoFieldFireFX:loadMap(modDir) end
    if TornadoRegion then TornadoRegion:loadMap(modDir) end
    if TornadoClimate then TornadoClimate:loadMap(modDir) end
    if TornadoOutbreak then TornadoOutbreak:loadMap() end
    if TornadoMessageLog then TornadoMessageLog:loadMap() end
    if TornadoInsuranceCrops then TornadoInsuranceCrops:loadMap(modDir) end
    if TornadoInsuranceDamage then TornadoInsuranceDamage:loadMap() end   -- storm damage report (also with insurance OFF)
    if TornadoInsurance then TornadoInsurance:loadMap(modDir, modName) end   -- after Region / Climate (region detection)
    if TornadoPersistence then TornadoPersistence:loadMap() end   -- after Outbreak: restores its state
    -- Multiplayer: wrap the console handlers BEFORE they are registered, and send state to joining players.
    if TornadoSync then
        TornadoSync:wrapConsole()
        TornadoSync:installHooks()
    end
    if TornadoConsole then TornadoConsole:loadMap() end
    if TornadoMenu then TornadoMenu.register(modDir) end

    -- Defer UI until mission + GUI + HUD exist
    self._pendingGuiRegister = true
    self._pendingMapUiInit = true
end

-- Called after map load completes (safer than loadMap)
function TornadoMain:loadMapFinished()
    self._pendingGuiRegister = true
    self._pendingMapUiInit = true
end

function TornadoMain:deleteMap()
    if TornadoMenu then TornadoMenu.unregister() end
    if TornadoPhysics then TornadoPhysics:deleteMap() end
    if TornadoDestruction then TornadoDestruction:deleteMap() end
    if TornadoRecovery and TornadoRecovery.deleteMap then TornadoRecovery:deleteMap() end
    if TornadoHusbandry then TornadoHusbandry:deleteMap() end
    if TornadoTraffic then TornadoTraffic:deleteMap() end
    if TornadoWildlife then TornadoWildlife:deleteMap() end
    if TornadoHazards then TornadoHazards:deleteMap() end
    if TornadoMoisture then TornadoMoisture:deleteMap() end
    if TornadoFieldFireFX then TornadoFieldFireFX:deleteMap() end
    if TornadoClimate then TornadoClimate:deleteMap() end
    if TornadoRegion then TornadoRegion:deleteMap() end
    if TornadoOutbreak then TornadoOutbreak:deleteMap() end
    if TornadoInsurance then TornadoInsurance:deleteMap() end
    if TornadoInsuranceCrops then TornadoInsuranceCrops:deleteMap() end
    if TornadoMessageLog then TornadoMessageLog:deleteMap() end
    if TornadoInsuranceDamage then TornadoInsuranceDamage:deleteMap() end
    if TornadoEffects then TornadoEffects:deleteMap() end
    if TornadoDebug then TornadoDebug:deleteMap() end
    if TornadoCompass then TornadoCompass:deleteMap() end
    if TornadoMapUI ~= nil and TornadoMapUI.deleteMap ~= nil then TornadoMapUI:deleteMap() end
    if TornadoHotspot ~= nil and TornadoHotspot.deleteMap ~= nil then TornadoHotspot:deleteMap() end
end

function TornadoMain:update(dt)
    if TornadoPhysics then TornadoPhysics:update(dt) end
    if TornadoDestruction then TornadoDestruction:update(dt) end
    if TornadoEffects then TornadoEffects:update(dt) end
    if TornadoSFX then TornadoSFX:update(dt) end
    if TornadoTraffic then TornadoTraffic:update(dt) end
    if TornadoWildlife then TornadoWildlife:update(dt) end
    if TornadoHazards then TornadoHazards:update(dt) end
    if TornadoMoisture then TornadoMoisture:update(dt) end
    if TornadoFieldFireFX then TornadoFieldFireFX:update(dt) end
    if TornadoOutbreak then TornadoOutbreak:update(dt) end
    if TornadoCompass then TornadoCompass:update(dt) end

    -- ---- Map/HUD UI init (needs HUD/map) ----
    if self._pendingMapUiInit then
        local hudReady = (g_currentMission ~= nil and g_currentMission.hud ~= nil and g_currentMission.hud.ingameMap ~= nil)

        if hudReady then
            if TornadoHotspot ~= nil and TornadoHotspot.loadMap ~= nil then
                TornadoHotspot:loadMap(modDir)
            end

            if TornadoMapUI ~= nil and TornadoMapUI.loadMap ~= nil then
                TornadoMapUI:loadMap(modDir)
            end

            self._pendingMapUiInit = false
        end
    end
end

function TornadoMain:draw()
    if TornadoPhysics and TornadoPhysics.draw then TornadoPhysics:draw() end
end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

-- FSBaseMission survives savegame reloads; flag it so the save hook is only appended once.
if not FSBaseMission.tornadoSaveHooked then
    FSBaseMission.tornadoSaveHooked = true
    FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, function(...)
        if TornadoDestruction and TornadoDestruction._saveToXML then
            TornadoDestruction:_saveToXML()
        end
        if TornadoPersistence and TornadoPersistence.save then
            TornadoPersistence:save()
        end
        if TornadoHazards and TornadoHazards.save then
            TornadoHazards:save()
        end
        if TornadoInsuranceDamage and TornadoInsuranceDamage.save then
            TornadoInsuranceDamage:save()
        end
        if TornadoMessageLog and TornadoMessageLog.save then
            TornadoMessageLog:save()
        end
        if TornadoInsurance and TornadoInsurance.save then
            TornadoInsurance:save()
        end
    end)
end



addModEventListener(TornadoMain)
