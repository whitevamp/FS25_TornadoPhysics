---@class TornadoSettings
---@version 1.3 (Ring Toggle Added)
---@description Handles Saving/Loading of preferences, including the new Debug Ring toggle.

TornadoSettings = {}
TornadoSettings.MOD_NAME = g_currentModName
TornadoSettings.DIR = getUserProfileAppPath() .. "modSettings/"
TornadoSettings.FILE = TornadoSettings.DIR .. "TornadoPhysics_Config.xml"

function TornadoSettings:loadMap(name)
    print("--------------------------------------------------")
    print("TORNADO SETTINGS: INITIALIZING...")
    
    createFolder(self.DIR)
    
    if fileExists(self.FILE) then
        self:loadFromXML()
    else
        self:createDefaultXML()
    end
    
    addConsoleCommand("t_save", "Save Current Settings to XML", "saveToXML", self)
end

function TornadoSettings:deleteMap()
    removeConsoleCommand("t_save")
end

function TornadoSettings:createDefaultXML()
    print("TORNADO SETTINGS: Creating new config file...")
    local xmlId = createXMLFile("TornadoConfig", self.FILE, "TornadoPhysics")
    
    -- 1. GENERAL
    setXMLFloat(xmlId, "TornadoPhysics.general.radius", 35.0)
    
    -- 2. OBJECTS
    setXMLBool(xmlId, "TornadoPhysics.objects.liftBales", true)
    setXMLBool(xmlId, "TornadoPhysics.objects.liftLogs", true)

    -- 3. SAFETY
    setXMLBool(xmlId, "TornadoPhysics.safety.borderProtection", true)
    setXMLFloat(xmlId, "TornadoPhysics.safety.geoFenceBuffer", 40.0)
    
    -- 4. DAMAGE
    setXMLBool(xmlId, "TornadoPhysics.damage.indoor", false)
    setXMLBool(xmlId, "TornadoPhysics.damage.outdoor", true)
    
    -- 5. HUSBANDRY
    setXMLBool(xmlId, "TornadoPhysics.husbandry.enabled", false)
    setXMLFloat(xmlId, "TornadoPhysics.husbandry.immunitySeconds", 120.0)

    -- 6. ADVANCED PHYSICS
    setXMLFloat(xmlId, "TornadoPhysics.advanced.ejectionPower", 20.0)
    setXMLFloat(xmlId, "TornadoPhysics.advanced.heavyThreshold", 3.0)
    setXMLFloat(xmlId, "TornadoPhysics.advanced.damageCenter", 0.25)
    setXMLFloat(xmlId, "TornadoPhysics.advanced.damageOuter", 0.08)

    -- 7. DEBUG
    setXMLBool(xmlId, "TornadoPhysics.debug.showRing", false)
    
    saveXMLFile(xmlId)
    delete(xmlId)
    
    -- Apply defaults immediately
    self:applySettings(35.0, true, true, true, 40.0, false, true, false, 120.0, 20.0, 3.0, 0.25, 0.08, false)
end

function TornadoSettings:loadFromXML()
    print("TORNADO SETTINGS: Loading preferences...")
    local xmlId = loadXMLFile("TornadoConfig", self.FILE)
    
    if xmlId ~= 0 then
        -- 1. GENERAL
        local radius = getXMLFloat(xmlId, "TornadoPhysics.general.radius") or 35.0
        
        -- 2. OBJECTS
        local liftBales = getXMLBool(xmlId, "TornadoPhysics.objects.liftBales")
        if liftBales == nil then liftBales = true end
        
        local liftLogs = getXMLBool(xmlId, "TornadoPhysics.objects.liftLogs")
        if liftLogs == nil then liftLogs = true end

        -- 3. SAFETY
        local border = getXMLBool(xmlId, "TornadoPhysics.safety.borderProtection")
        if border == nil then border = true end
        
        local geoBuffer = getXMLFloat(xmlId, "TornadoPhysics.safety.geoFenceBuffer") or 40.0
        
        -- 4. DAMAGE
        local dmgIn = getXMLBool(xmlId, "TornadoPhysics.damage.indoor") or false
        local dmgOut = getXMLBool(xmlId, "TornadoPhysics.damage.outdoor") 
        if dmgOut == nil then dmgOut = true end
        
        -- 5. HUSBANDRY
        local husbActive = getXMLBool(xmlId, "TornadoPhysics.husbandry.enabled") or false
        local husbTime = getXMLFloat(xmlId, "TornadoPhysics.husbandry.immunitySeconds") or 120.0

        -- 6. ADVANCED PHYSICS
        local eject = getXMLFloat(xmlId, "TornadoPhysics.advanced.ejectionPower") or 20.0
        local heavy = getXMLFloat(xmlId, "TornadoPhysics.advanced.heavyThreshold") or 3.0
        local dmgC = getXMLFloat(xmlId, "TornadoPhysics.advanced.damageCenter") or 0.25
        local dmgO = getXMLFloat(xmlId, "TornadoPhysics.advanced.damageOuter") or 0.08

        -- 7. DEBUG
        local showRing = getXMLBool(xmlId, "TornadoPhysics.debug.showRing") or false
        
        delete(xmlId)
        
        -- APPLY EVERYTHING
        self:applySettings(radius, liftBales, liftLogs, border, geoBuffer, dmgIn, dmgOut, husbActive, husbTime, eject, heavy, dmgC, dmgO, showRing)
    end
end

function TornadoSettings:applySettings(radius, liftBales, liftLogs, border, geoBuffer, dmgIn, dmgOut, husbActive, husbTime, eject, heavy, dmgC, dmgO, showRing)
    -- 1. Apply to Physics Module
    if TornadoPhysics then
        -- Direct Properties
        TornadoPhysics.showRing = showRing

        if TornadoPhysics.consoleSet then
            TornadoPhysics:consoleSet("radius", tostring(radius))
        end

        if TornadoPhysics.settings then
            -- Toggles
            TornadoPhysics.settings.lift_bales = liftBales
            TornadoPhysics.settings.lift_logs = liftLogs
            TornadoPhysics.settings.border_safety = border
            TornadoPhysics.settings.indoor_damage = dmgIn
            TornadoPhysics.settings.outdoor_damage = dmgOut
            
            -- Advanced & Safety Values
            TornadoPhysics.settings.geo_fence = geoBuffer
            TornadoPhysics.settings.ejection_power = eject
            TornadoPhysics.settings.heavy_threshold = heavy
            TornadoPhysics.settings.damage_center = dmgC
            TornadoPhysics.settings.damage_outer = dmgO
        end
        print(string.format(" > Physics Settings Applied (EjectPower: %.1f | ShowRing: %s)", eject, tostring(showRing)))
    end

    -- 2. Apply to Husbandry Module
    if TornadoHusbandry then
        TornadoHusbandry.isActive = husbActive
        if TornadoHusbandry.consoleImmunity then
            TornadoHusbandry:consoleImmunity("set", tostring(husbTime))
        end
        print(string.format(" > Husbandry Settings Applied (Active: %s)", tostring(husbActive)))
    end
end

function TornadoSettings:saveToXML()
    print("TORNADO SETTINGS: Saving current state...")
    local xmlId = createXMLFile("TornadoConfig", self.FILE, "TornadoPhysics")
    
    local pSettings = TornadoPhysics and TornadoPhysics.settings or {}
    local hActive = TornadoHusbandry and TornadoHusbandry.isActive or false
    local hTime = TornadoHusbandry and (TornadoHusbandry.IMMUNITY_DURATION / 1000) or 120.0
    
    -- 1. GENERAL
    setXMLFloat(xmlId, "TornadoPhysics.general.radius", 35.0) 
    
    -- 2. OBJECTS
    setXMLBool(xmlId, "TornadoPhysics.objects.liftBales", pSettings.lift_bales ~= false) 
    setXMLBool(xmlId, "TornadoPhysics.objects.liftLogs", pSettings.lift_logs ~= false)

    -- 3. SAFETY
    setXMLBool(xmlId, "TornadoPhysics.safety.borderProtection", pSettings.border_safety ~= false)
    setXMLFloat(xmlId, "TornadoPhysics.safety.geoFenceBuffer", pSettings.geo_fence or 40.0)
    
    -- 4. DAMAGE
    setXMLBool(xmlId, "TornadoPhysics.damage.indoor", pSettings.indoor_damage or false)
    setXMLBool(xmlId, "TornadoPhysics.damage.outdoor", pSettings.outdoor_damage ~= false)
    
    -- 5. HUSBANDRY
    setXMLBool(xmlId, "TornadoPhysics.husbandry.enabled", hActive)
    setXMLFloat(xmlId, "TornadoPhysics.husbandry.immunitySeconds", hTime)

    -- 6. ADVANCED PHYSICS
    setXMLFloat(xmlId, "TornadoPhysics.advanced.ejectionPower", pSettings.ejection_power or 20.0)
    setXMLFloat(xmlId, "TornadoPhysics.advanced.heavyThreshold", pSettings.heavy_threshold or 3.0)
    setXMLFloat(xmlId, "TornadoPhysics.advanced.damageCenter", pSettings.damage_center or 0.25)
    setXMLFloat(xmlId, "TornadoPhysics.advanced.damageOuter", pSettings.damage_outer or 0.08)

    -- 7. DEBUG
    -- Note: showRing is a direct property of TornadoPhysics, not inside .settings
    local ringState = TornadoPhysics and TornadoPhysics.showRing or false
    setXMLBool(xmlId, "TornadoPhysics.debug.showRing", ringState)
    
    saveXMLFile(xmlId)
    delete(xmlId)
    print(" > Configuration Saved!")
end

addModEventListener(TornadoSettings)