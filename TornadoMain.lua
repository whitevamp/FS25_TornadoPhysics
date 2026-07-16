---@class TornadoMain
---@description The Central Manager. Loads and updates all sub-modules in the correct order.

TornadoMain = {}
local modDir = g_currentModDirectory

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

    -- Load the physics system.
    source(Utils.getFilename("scripts/TornadoPhysics.lua", modDir))

    -- Weather system.
    source(Utils.getFilename("scripts/TornadoWeather.lua", modDir))
    
    -- Load the console commands.
    source(Utils.getFilename("scripts/TornadoConsole.lua", modDir))

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
    if TornadoConsole then TornadoConsole:loadMap() end

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
    if TornadoPhysics then TornadoPhysics:deleteMap() end
    if TornadoDestruction then TornadoDestruction:deleteMap() end
    if TornadoRecovery and TornadoRecovery.deleteMap then TornadoRecovery:deleteMap() end
    if TornadoHusbandry then TornadoHusbandry:deleteMap() end
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

FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, function(...)
    if TornadoDestruction and TornadoDestruction._saveToXML then
        -- Keep our pcall firewall so we never corrupt the weather files
        local success, err = pcall(function()
            TornadoDestruction:_saveToXML()
        end)
        
        if not success then
            print("TORNADO DESTRUCTION SAVE ERROR: " .. tostring(err))
        end
    end
end)



addModEventListener(TornadoMain)