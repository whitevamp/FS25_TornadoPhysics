---@class TornadoSettings
---@version 2.2 (MASTER RESET + RECOVERY)
---@description Handles Saving/Loading and Resetting of preferences.

TornadoSettings = {}
TornadoSettings.MOD_NAME = g_currentModName
TornadoSettings.DIR = getUserProfileAppPath() .. "modSettings/"
TornadoSettings.FILE = TornadoSettings.DIR .. "TornadoPhysics_Config.xml"

-- [NEW] Master Gatekeeper for Recovery Bill
TornadoSettings.recoveryEnabled = false 

function TornadoSettings:loadMap(name)
    if TornadoDebug then TornadoDebug:info("SETTINGS", "V2.2 Initialized") end
    createFolder(self.DIR)

    if fileExists(self.FILE) then
        self:loadFromXML()
    else
        self:createDefaultXML()
    end
end

function TornadoSettings:deleteMap()
    -- Managed by Console
end

-- Master Reset Function
function TornadoSettings:resetToDefaults(category)
    if TornadoPhysics and TornadoPhysics.settings then
        local s = TornadoPhysics.settings
        
        -- RESET PHYSICS (Standard)
        if category == "all" or category == "physics" then
            s.base_radius = 35.0
            s.ejection_power = 20.0
            s.heavy_threshold = 3.0
            s.geo_fence = 40.0
            s.damage_center = 0.25
            s.damage_outer = 0.08
            s.lift_bales = true
            s.lift_logs = true
            s.border_safety = true
            s.indoor_damage = false
            s.outdoor_damage = true
            s.destructionEnabled = false 
            
            self.recoveryEnabled = false -- [NEW] RESET RECOVERY
            
            print("TORNADO RESET: Physics defaults restored.")
        end

        -- RESET TUNING (Hardcore)
        if category == "all" or category == "tuning" then
            s.suction_speed = 50.0
            s.lift_speed = 12.0
            s.chaos_factor = 5.0
            s.bale_orbit = 20.0
            s.bale_suction = 15.0
            s.bale_lift = 10.0
            s.hover_height = 35.0
            s.max_safe_speed = 35.0
            s.destruction_ratio = 0.2
            s.mass_penalty = 0.8
            s.purge_duration = 5000
            s.purge_interval = 45000
            print("TORNADO RESET: Tuning defaults restored.")
        end
    end

    -- RESET CARGO
    if TornadoCargo and TornadoCargo.settings then
        if category == "all" or category == "cargo" then
            local cs = TornadoCargo.settings
            cs.spillHeight = 1.5
            cs.spillAngle = 0.7
            cs.drainRate = 0.10
            cs.spreadRadius = 4.0
            cs.coverLeakChance = 0.25
            TornadoCargo.isEnabled = false
            TornadoCargo.isVerbose = false
            print("TORNADO RESET: Cargo defaults restored.")
        end
    end

    -- RESET HUSBANDRY
    if TornadoHusbandry then
        if category == "all" or category == "husbandry" then
            TornadoHusbandry.isActive = false
            TornadoHusbandry.IMMUNITY_DURATION = 120000 -- 2 minutes
            print("TORNADO RESET: Husbandry defaults restored.")
        end
    end

    -- AUTO-SAVE immediately so the reset sticks
    self:saveToXML()
end

function TornadoSettings:createDefaultXML()
    local xmlId = createXMLFile("TornadoConfig", self.FILE, "TornadoPhysics")
    
    -- 1. GENERAL
    setXMLFloat(xmlId, "TornadoPhysics.general.radius", 35.0)
    setXMLBool(xmlId, "TornadoPhysics.general.destruction", false) 
    setXMLBool(xmlId, "TornadoPhysics.general.recovery", false) -- [NEW] ADD RECOVERY

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

    -- 7. HARDCORE TUNING
    setXMLFloat(xmlId, "TornadoPhysics.tuning.suctionSpeed", 50.0)
    setXMLFloat(xmlId, "TornadoPhysics.tuning.liftSpeed", 12.0)
    setXMLFloat(xmlId, "TornadoPhysics.tuning.chaosFactor", 5.0)
    setXMLFloat(xmlId, "TornadoPhysics.tuning.baleOrbit", 20.0)
    setXMLFloat(xmlId, "TornadoPhysics.tuning.baleSuction", 15.0)
    setXMLFloat(xmlId, "TornadoPhysics.tuning.baleLift", 10.0)
    setXMLFloat(xmlId, "TornadoPhysics.tuning.hoverHeight", 35.0)
    setXMLFloat(xmlId, "TornadoPhysics.tuning.maxSafeSpeed", 35.0)
    setXMLFloat(xmlId, "TornadoPhysics.tuning.destructionRatio", 0.2)
    setXMLFloat(xmlId, "TornadoPhysics.tuning.massPenalty", 0.8)
    setXMLFloat(xmlId, "TornadoPhysics.tuning.purgeDuration", 5000.0)
    setXMLFloat(xmlId, "TornadoPhysics.tuning.purgeInterval", 45000.0)

    -- 8. DEBUG
    setXMLBool(xmlId, "TornadoPhysics.debug.showRing", false)

    -- 9. AUDIO
    setXMLBool(xmlId, "TornadoPhysics.audio.enabled", true)

    -- 10. CARGO
    setXMLBool(xmlId, "TornadoPhysics.cargo.enabled", false)
    setXMLFloat(xmlId, "TornadoPhysics.cargo.spillHeight", 1.5)
    setXMLFloat(xmlId, "TornadoPhysics.cargo.spillAngle", 0.7)
    setXMLFloat(xmlId, "TornadoPhysics.cargo.drainRate", 0.10)
    setXMLFloat(xmlId, "TornadoPhysics.cargo.spreadRadius", 4.0)
    setXMLFloat(xmlId, "TornadoPhysics.cargo.coverLeakChance", 0.25)

    -- 11. MAPUI
    setXMLBool(xmlId, "TornadoPhysics.mapui.enabled", true)
    setXMLBool(xmlId, "TornadoPhysics.mapui.onlyWhenSelected", true)
    
    -- 12. EFFECTS
    setXMLBool(xmlId, "TornadoPhysics.effects.fireRandom", false)

    saveXMLFile(xmlId)
    delete(xmlId)
end

function TornadoSettings:loadFromXML()
    print("TORNADO SETTINGS: Loading preferences...")
    local xmlId = loadXMLFile("TornadoConfig", self.FILE)

    if xmlId == 0 then return end

    if TornadoPhysics and TornadoPhysics.settings then
        local s = TornadoPhysics.settings
        s.base_radius = getXMLFloat(xmlId, "TornadoPhysics.general.radius") or s.base_radius
        s.destructionEnabled = Utils.getNoNil(getXMLBool(xmlId, "TornadoPhysics.general.destruction"), false) 
        
        -- [NEW] LOAD RECOVERY
        self.recoveryEnabled = Utils.getNoNil(getXMLBool(xmlId, "TornadoPhysics.general.recovery"), false) 
        
        local lb = getXMLBool(xmlId, "TornadoPhysics.objects.liftBales")
        if lb ~= nil then s.lift_bales = lb end
        local ll = getXMLBool(xmlId, "TornadoPhysics.objects.liftLogs")
        if ll ~= nil then s.lift_logs = ll end

        local bp = getXMLBool(xmlId, "TornadoPhysics.safety.borderProtection")
        if bp ~= nil then s.border_safety = bp end
        s.geo_fence = getXMLFloat(xmlId, "TornadoPhysics.safety.geoFenceBuffer") or s.geo_fence

        local di = getXMLBool(xmlId, "TornadoPhysics.damage.indoor")
        if di ~= nil then s.indoor_damage = di end
        local dout = getXMLBool(xmlId, "TornadoPhysics.damage.outdoor")
        if dout ~= nil then s.outdoor_damage = dout end

        s.ejection_power = getXMLFloat(xmlId, "TornadoPhysics.advanced.ejectionPower") or s.ejection_power
        s.heavy_threshold = getXMLFloat(xmlId, "TornadoPhysics.advanced.heavyThreshold") or s.heavy_threshold
        s.damage_center = getXMLFloat(xmlId, "TornadoPhysics.advanced.damageCenter") or s.damage_center
        s.damage_outer = getXMLFloat(xmlId, "TornadoPhysics.advanced.damageOuter") or s.damage_outer

        s.suction_speed = getXMLFloat(xmlId, "TornadoPhysics.tuning.suctionSpeed") or s.suction_speed
        s.lift_speed = getXMLFloat(xmlId, "TornadoPhysics.tuning.liftSpeed") or s.lift_speed
        s.chaos_factor = getXMLFloat(xmlId, "TornadoPhysics.tuning.chaosFactor") or s.chaos_factor
        s.bale_orbit = getXMLFloat(xmlId, "TornadoPhysics.tuning.baleOrbit") or s.bale_orbit
        s.bale_suction = getXMLFloat(xmlId, "TornadoPhysics.tuning.baleSuction") or s.bale_suction
        s.bale_lift = getXMLFloat(xmlId, "TornadoPhysics.tuning.baleLift") or s.bale_lift
        s.hover_height = getXMLFloat(xmlId, "TornadoPhysics.tuning.hoverHeight") or s.hover_height
        s.max_safe_speed = getXMLFloat(xmlId, "TornadoPhysics.tuning.maxSafeSpeed") or s.max_safe_speed
        s.destruction_ratio = getXMLFloat(xmlId, "TornadoPhysics.tuning.destructionRatio") or s.destruction_ratio
        s.mass_penalty = getXMLFloat(xmlId, "TornadoPhysics.tuning.massPenalty") or s.mass_penalty
        s.purge_duration = getXMLFloat(xmlId, "TornadoPhysics.tuning.purgeDuration") or s.purge_duration
        s.purge_interval = getXMLFloat(xmlId, "TornadoPhysics.tuning.purgeInterval") or s.purge_interval

        local ring = getXMLBool(xmlId, "TornadoPhysics.debug.showRing")
        if ring ~= nil then TornadoPhysics.showRing = ring end
    end

    if TornadoHusbandry then
        local hEnabled = getXMLBool(xmlId, "TornadoPhysics.husbandry.enabled")
        if hEnabled ~= nil then TornadoHusbandry.isActive = hEnabled end

        local hTime = getXMLFloat(xmlId, "TornadoPhysics.husbandry.immunitySeconds")
        if hTime then 
            TornadoHusbandry.IMMUNITY_DURATION = hTime * 1000 
            TornadoHusbandry.customImmunitySet = true
        end
    end

    if TornadoSFX then
        local aud = getXMLBool(xmlId, "TornadoPhysics.audio.enabled")
        if aud ~= nil then TornadoSFX.isEnabled = aud end
    end

    if TornadoCargo and TornadoCargo.settings then
        local cEnabled = getXMLBool(xmlId, "TornadoPhysics.cargo.enabled")
        if cEnabled ~= nil then TornadoCargo.isEnabled = cEnabled end

        local cs = TornadoCargo.settings
        cs.spillHeight = getXMLFloat(xmlId, "TornadoPhysics.cargo.spillHeight") or cs.spillHeight
        cs.spillAngle = getXMLFloat(xmlId, "TornadoPhysics.cargo.spillAngle") or cs.spillAngle
        cs.drainRate = getXMLFloat(xmlId, "TornadoPhysics.cargo.drainRate") or cs.drainRate
        cs.spreadRadius = getXMLFloat(xmlId, "TornadoPhysics.cargo.spreadRadius") or cs.spreadRadius
        cs.coverLeakChance = getXMLFloat(xmlId, "TornadoPhysics.cargo.coverLeakChance") or cs.coverLeakChance
    end

    if TornadoMapUI then
        local muiEnabled = getXMLBool(xmlId, "TornadoPhysics.mapui.enabled")
        if muiEnabled ~= nil then TornadoMapUI.enabled = muiEnabled end

        local muiSelected = getXMLBool(xmlId, "TornadoPhysics.mapui.onlyWhenSelected")
        if muiSelected ~= nil then TornadoMapUI.onlyWhenSelected = muiSelected end
    end

    if TornadoEffects and TornadoEffects.CONFIG then
        local fireRandom = getXMLBool(xmlId, "TornadoPhysics.effects.fireRandom")
        if fireRandom ~= nil then TornadoEffects.CONFIG.RANDOM_FIRE_MODE = fireRandom end
    end

    delete(xmlId)
    if TornadoDebug then TornadoDebug:log("SETTINGS", "Preferences Loaded Successfully.") end
end

function TornadoSettings:saveToXML()
    if TornadoDebug then TornadoDebug:info("SETTINGS", "Saving current state...") end
    local xmlId = createXMLFile("TornadoConfig", self.FILE, "TornadoPhysics")

    if TornadoPhysics and TornadoPhysics.settings then
        local s = TornadoPhysics.settings
        setXMLFloat(xmlId, "TornadoPhysics.general.radius", s.base_radius)
        setXMLBool(xmlId, "TornadoPhysics.general.destruction", s.destructionEnabled) 
        
        -- [NEW] SAVE RECOVERY
        setXMLBool(xmlId, "TornadoPhysics.general.recovery", self.recoveryEnabled) 
        
        setXMLBool(xmlId, "TornadoPhysics.objects.liftBales", s.lift_bales)
        setXMLBool(xmlId, "TornadoPhysics.objects.liftLogs", s.lift_logs)
        setXMLBool(xmlId, "TornadoPhysics.safety.borderProtection", s.border_safety)
        setXMLFloat(xmlId, "TornadoPhysics.safety.geoFenceBuffer", s.geo_fence)
        setXMLBool(xmlId, "TornadoPhysics.damage.indoor", s.indoor_damage)
        setXMLBool(xmlId, "TornadoPhysics.damage.outdoor", s.outdoor_damage)
        setXMLFloat(xmlId, "TornadoPhysics.advanced.ejectionPower", s.ejection_power)
        setXMLFloat(xmlId, "TornadoPhysics.advanced.heavyThreshold", s.heavy_threshold)
        setXMLFloat(xmlId, "TornadoPhysics.advanced.damageCenter", s.damage_center)
        setXMLFloat(xmlId, "TornadoPhysics.advanced.damageOuter", s.damage_outer)
        setXMLFloat(xmlId, "TornadoPhysics.tuning.suctionSpeed", s.suction_speed)
        setXMLFloat(xmlId, "TornadoPhysics.tuning.liftSpeed", s.lift_speed)
        setXMLFloat(xmlId, "TornadoPhysics.tuning.chaosFactor", s.chaos_factor)
        setXMLFloat(xmlId, "TornadoPhysics.tuning.baleOrbit", s.bale_orbit)
        setXMLFloat(xmlId, "TornadoPhysics.tuning.baleSuction", s.bale_suction)
        setXMLFloat(xmlId, "TornadoPhysics.tuning.baleLift", s.bale_lift)
        setXMLFloat(xmlId, "TornadoPhysics.tuning.hoverHeight", s.hover_height)
        setXMLFloat(xmlId, "TornadoPhysics.tuning.maxSafeSpeed", s.max_safe_speed)
        setXMLFloat(xmlId, "TornadoPhysics.tuning.destructionRatio", s.destruction_ratio)
        setXMLFloat(xmlId, "TornadoPhysics.tuning.massPenalty", s.mass_penalty)
        setXMLFloat(xmlId, "TornadoPhysics.tuning.purgeDuration", s.purge_duration)
        setXMLFloat(xmlId, "TornadoPhysics.tuning.purgeInterval", s.purge_interval)
        setXMLBool(xmlId, "TornadoPhysics.debug.showRing", TornadoPhysics.showRing)
    end

    if TornadoHusbandry then
        setXMLBool(xmlId, "TornadoPhysics.husbandry.enabled", TornadoHusbandry.isActive)
        setXMLFloat(xmlId, "TornadoPhysics.husbandry.immunitySeconds", TornadoHusbandry.IMMUNITY_DURATION / 1000)
    end

    if TornadoSFX then
        setXMLBool(xmlId, "TornadoPhysics.audio.enabled", TornadoSFX.isEnabled)
    end

    if TornadoCargo and TornadoCargo.settings then
        setXMLBool(xmlId, "TornadoPhysics.cargo.enabled", TornadoCargo.isEnabled)
        local cs = TornadoCargo.settings
        setXMLFloat(xmlId, "TornadoPhysics.cargo.spillHeight", cs.spillHeight)
        setXMLFloat(xmlId, "TornadoPhysics.cargo.spillAngle", cs.spillAngle)
        setXMLFloat(xmlId, "TornadoPhysics.cargo.drainRate", cs.drainRate)
        setXMLFloat(xmlId, "TornadoPhysics.cargo.spreadRadius", cs.spreadRadius)
        setXMLFloat(xmlId, "TornadoPhysics.cargo.coverLeakChance", cs.coverLeakChance)
    end

    if TornadoMapUI then
        setXMLBool(xmlId, "TornadoPhysics.mapui.enabled", TornadoMapUI.enabled)
        setXMLBool(xmlId, "TornadoPhysics.mapui.onlyWhenSelected", TornadoMapUI.onlyWhenSelected)
    end

    if TornadoEffects and TornadoEffects.CONFIG then
        setXMLBool(xmlId, "TornadoPhysics.effects.fireRandom", TornadoEffects.CONFIG.RANDOM_FIRE_MODE)
    end

    saveXMLFile(xmlId)
    delete(xmlId)
    if TornadoDebug then TornadoDebug:info("SETTINGS", "Configuration Saved!") end
end