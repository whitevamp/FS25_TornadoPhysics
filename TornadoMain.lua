---@class TornadoMain
---@description The Central Manager. Loads and updates all sub-modules in the correct order.

TornadoMain = {}
local modDir = g_currentModDirectory

function TornadoMain:loadMap(name)
    print("--------------------------------------------------")
    print("TORNADO MOD SYSTEM: INITIALIZING MAIN CONTROLLER")

    -- 1. LOAD SCRIPTS
    source(Utils.getFilename("scripts/TornadoDebug.lua", modDir))
    source(Utils.getFilename("scripts/TornadoSettings.lua", modDir))
    source(Utils.getFilename("scripts/TornadoSFX.lua", modDir))
    source(Utils.getFilename("scripts/TornadoEffects.lua", modDir))
    source(Utils.getFilename("scripts/TornadoHusbandry.lua", modDir))
    source(Utils.getFilename("scripts/TornadoCargo.lua", modDir))
    source(Utils.getFilename("scripts/TornadoADS.lua", modDir))
    source(Utils.getFilename("scripts/TornadoPhysics.lua", modDir))
    source(Utils.getFilename("scripts/TornadoConsole.lua", modDir))
    
    -- [NEW] Load Destruction Module
    source(Utils.getFilename("scripts/TornadoDestruction.lua", modDir))

    source(Utils.getFilename("scripts/TornadoHotspot.lua", modDir))
    source(Utils.getFilename("scripts/TornadoMapUI.lua", modDir))

    -- 2. INITIALIZE MODULES (non-UI stuff is safe here)
    if TornadoDebug then TornadoDebug:loadMap() end
    if TornadoSettings then TornadoSettings:loadMap(name) end
    if TornadoSFX then TornadoSFX:loadMap(name, modDir) end
    if TornadoEffects then TornadoEffects:loadMap(name, modDir) end
    if TornadoHusbandry then TornadoHusbandry:loadMap(name) end

    if TornadoCargo then TornadoCargo:loadMap() end
    if TornadoADS then TornadoADS:loadMap() end
    
    -- [NEW] Initialize Destruction (Before Physics uses it)
    if TornadoDestruction then TornadoDestruction:loadMap(name, modDir) end

    if TornadoPhysics then TornadoPhysics:loadMap(name, modDir) end
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
    if TornadoDestruction then TornadoDestruction:deleteMap() end -- [NEW] Save data on exit
    if TornadoHusbandry then TornadoHusbandry:deleteMap() end
    if TornadoEffects then TornadoEffects:deleteMap() end
    if TornadoDebug then TornadoDebug:deleteMap() end
    if TornadoMapUI ~= nil and TornadoMapUI.deleteMap ~= nil then TornadoMapUI:deleteMap() end
    if TornadoHotspot ~= nil and TornadoHotspot.deleteMap ~= nil then TornadoHotspot:deleteMap() end
end

function TornadoMain:update(dt)
    if TornadoPhysics then TornadoPhysics:update(dt) end
    if TornadoDestruction then TornadoDestruction:update(dt) end -- [NEW] Update repair timers
    if TornadoEffects then TornadoEffects:update(dt) end
    if TornadoSFX then TornadoSFX:update(dt) end

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

-- function TornadoMain:getSavePath()
--     local info = g_currentMission.missionInfo
--     if info == nil then return nil end
--     local path = info.savegameDirectory
--     if path == nil then
--         path = ('%ssavegame%d'):format(getUserProfileAppPath(), info.savegameIndex)
--     end
--     return path .. "/"
-- end

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