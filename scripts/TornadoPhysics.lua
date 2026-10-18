---@class TornadoPhysics
---@version 3.0.0.1 (GOLD MASTER)
---@description Final Physics Tuning: 3-Tier Weight Classes, Fixed Mass Calculation, and optimized Ejection Logic.

TornadoPhysics = {}

TornadoPhysics.foundCandidate = nil
TornadoPhysics.confirmTimer = 0

-- [TUNING CONSTANTS]
TornadoPhysics.settings = {
    base_radius           = 35.0,
    indoor_damage         = false,
    outdoor_damage        = true,
    lift_bales            = true,
    lift_logs             = true,
    lift_props            = true,
    border_safety         = true,
    ejection_power        = 20.0,
    damage_center         = 0.25,
    damage_outer          = 0.08,
    heavy_threshold       = 3.0,
    geo_fence             = 40.0,

    -- SCALING & LOGIC
    min_scale             = 0.5,
    max_scale             = 5.0,
    destruction_ratio     = 0.2,
    purge_duration        = 5000,
    purge_interval        = 45000,

    -- PHYSICS SPEEDS
    suction_speed         = 50.0,
    lift_speed            = 12.0,
    mass_penalty          = 0.8,
    bale_orbit            = 20.0,
    bale_suction          = 15.0,
    bale_lift             = 10.0,
    chaos_factor          = 5.0,
    hover_height          = 35.0,
    max_safe_speed        = 35.0,

    -- FIRE FX
    fire_damage_threshold = 0.85,
    damage_fx_cooldown_ms = 2000
}

local currentOuterRadius = 35.0
local currentOuterRadiusSq = 35.0 * 35.0
local mapScaleFactor = 1.0
local mapBoundary = 8192.0
local mapInitialized = false
local LOG_MASK = 8192 + 32 + 2
local ROOF_MASK = 1 + 2048 + 1048576 + 32
-- Includes Bales/Logs (8192), Vehicles (32), Dynamic Props (16), Breakable Signs (4096), and Physics Actors (2)
-- local OBJECT_MASK = 8192 + 4096 + 32 + 16 + 2 -- Total value: 12338
local PROP_MASK = 4096 + 16 + 2 -- Scans for breakable signs, fences, and loose map props

function TornadoPhysics:loadMap(name)
    self.isActive = true
    self.tornadoNode = nil
    self.lastTornadoPos = nil
    self.debugMode = false
    -- showRing is NOT reset here: TornadoSettings:loadMap() has already applied the saved value.
    if self.showRing == nil then self.showRing = false end
    self.activeNodes = {}
    self.scanTimer = 0
    self.safetyCache = {}

    self.purgeTimer = 0
    self.purgeInterval = self.settings.purge_interval
    self.isPurging = false
    self.tornadoSearchTimer = 0
    self.sizeMultiplier = 1.0

    self.foundCandidate = nil
    self.confirmTimer = 0
    self.CONFIRM_THRESHOLD = 150 -- Frames to wait (approx 2.5s)

    -- if TornadoNFW and TornadoNFW.loadMap then
    --     TornadoNFW:loadMap(name)
    -- end

    mapInitialized = false


    self.respawnPending = false
    self:installSpawnHook()

    if TornadoDebug then TornadoDebug:info("PHYSICS", "V3.0.0.1 Initialized (Gold Master)") end
end

function TornadoPhysics:deleteMap()
    self.isActive = false
    self.activeNodes = {}
    self.safetyCache = {}
end

function TornadoPhysics:update(dt)
    -- TornadoEffects / TornadoDestruction / TornadoCompass are updated by TornadoMain:update().

    -- 1. BASIC SERVER CHECKS (Always required)
    if not self.isActive or g_currentMission == nil then
        return
    end
    -- Multiplayer clients only show what the server sends (TornadoStateEvent); no physics here.
    if not g_currentMission:getIsServer() then
        self:updateClient(dt)
        return
    end

    -- ============================================================================
    -- 2. SEARCH PHASE (Height + Timer Fix)
    -- ============================================================================
    if self.tornadoNode == nil or not entityExists(self.tornadoNode) then
        self.tornadoNode = nil

        local candidate = self:findTornadoSimple()

        if candidate then
            if self.foundCandidate ~= candidate then
                self.foundCandidate = candidate
                self.confirmTimer = 0
            else
                self.confirmTimer = self.confirmTimer + 1

                -- [CONFIRMATION]
                -- 1. Must persist for 150 frames
                -- 2. Must be above ground (Height Check) - Fixes login false alarm
                local pX, pY, pZ = getWorldTranslation(candidate)

                if self.confirmTimer > 150 then
                    -- The "Cache" tornado is usually at Y = -100 or lower.
                    -- Real tornadoes are usually at Y > -50.
                    if pY > -50 then
                        self.tornadoNode = candidate
                        print("TornadoPhysics: Tornado CONFIRMED! (Timer: OK | Height: " .. math.floor(pY) .. "m)")
                        self.foundCandidate = nil
                        self.confirmTimer = 0

                        -- Announce it
                        print("TornadoPhysics: Tornado ACQUIRED!")
                    else
                        -- Reset if we found the underground cache object
                        if self.confirmTimer % 100 == 0 then -- Don't spam log
                            print("TornadoPhysics: Ignoring Cache Tornado at Depth: " .. math.floor(pY) .. "m")
                        end
                    end
                end
            end
        else
            self.foundCandidate = nil
            self.confirmTimer = 0
        end

        if self.tornadoNode == nil then return end

        -- ==========================================================
        -- TORNADO IS ACTIVE BEYOND THIS POINT
        -- ==========================================================

        -- If we passed the watchdog check, the tornado is active and moving.
        -- [HIGH PRIORITY HOOK] Evacuate AI before physics calculations
        -- if TornadoNFW and TornadoNFW.isAvailable then
        --     local tX, tY, tZ = getWorldTranslation(self.tornadoNode)
        --     -- Using 10.0 multiplier for early detection (roughly 350-500m radius depending on scale)
        --     TornadoNFW:evaluateDanger(tX, tY, tZ, self.settings.base_radius)
        -- end

        -- 1. Get the exact current position of the active tornado
        local tX, tY, tZ = getWorldTranslation(self.tornadoNode)

        -- 2. NFW Evacuation Check (Check if AI is in the path)
        -- if TornadoNFW and TornadoNFW.isInitialized then
        --     local radius = (self.settings and self.settings.base_radius) or 50
        --     TornadoNFW:evaluateDanger(tX, tY, tZ, radius)
        -- end
    end

    -- ============================================================================
    --#region
    -- ============================================================================
    -- WATCHDOG: Validate the Tornado Node FIRST
    -- ============================================================================
    local tornadoIsValid = false

    if self.tornadoNode ~= nil then
        if entityExists(self.tornadoNode) and getVisibility(self.tornadoNode) then
            tornadoIsValid = true
        else
            self:clearTornadoState()
            return -- Abort immediately before running ANY physics!
        end
    end

    -- A new spawn on the twister that was already active (see installSpawnHook): treat it as a new touchdown.
    if tornadoIsValid and self.respawnPending then
        self.respawnPending = false
        self:onTornadoRespawn()
    end

    if tornadoIsValid then
        if TornadoSFX then TornadoSFX:playSiren() end
    else
        if TornadoSFX then TornadoSFX.sirenLoopCount = 0 end
        if g_currentMission:getIsServer() then
            self.tornadoSearchTimer = self.tornadoSearchTimer + dt
            if self.tornadoSearchTimer > 2000 then
                self:findTornadoSimple()
                self.tornadoSearchTimer = 0
            end
        end
        return
    end

    -- NOW it is 100% safe to get position and run physics
    local x, y, z = getWorldTranslation(self.tornadoNode)
    self.tornadoY = y
    --#endregion

    -- Log Position (using the separate command t_dev pos)
    if TornadoDebug and TornadoDebug.showPosition then
        TornadoDebug:logPos(string.format("Tornado at %.1f, %.1f, %.1f", x, y, z))
    end

    -- Run the Physics Scan
    self:processNearbyObjects(dt, x, y, z)

    if not mapInitialized then
        self:calculateMapScale()
        mapInitialized = true
    end

    -- 1. DETECT TORNADO (Siren Logic)
    -- Read tornado position for BOTH server + client (for hotspot + distance)
    local tX, tY, tZ = getWorldTranslation(self.tornadoNode)
    if tX == nil then return end
    local _, rotY, _ = getWorldRotation(self.tornadoNode)

    -- UI/Hotspot updates run on BOTH sides (distance requires client)
    if TornadoHotspot then
        TornadoHotspot:updatePosition(tX, tZ, rotY)
    end

    -- From here down: SERVER-ONLY physics/gameplay
    if not self.isActive or not g_currentMission:getIsServer() then return end

    if not mapInitialized then
        self:calculateMapScale()
        mapInitialized = true
    end

    -- 2. PURGE LOGIC (Scaled by Size)
    self.purgeTimer = self.purgeTimer + dt
    if self.isPurging then
        local scaledDuration = self.settings.purge_duration * self.sizeMultiplier
        if self.purgeTimer > scaledDuration then
            self.isPurging = false
            self.purgeTimer = 0
            if TornadoDebug then TornadoDebug:log("PHYSICS", "Purge Complete. Resuming Suction.") end
        end
    else
        if self.purgeTimer > self:getPurgeInterval() then
            self.isPurging = true
            self.purgeTimer = 0
            if TornadoDebug then TornadoDebug:log("PHYSICS", "Purge Started! EJECTING CONTENTS...") end
        end
    end

    local tX, tY, tZ = getWorldTranslation(self.tornadoNode)
    if tX == nil then return end

    local _, rotY, _ = getWorldRotation(self.tornadoNode)

    -- Keep the tornado hotspot updated (map icon + teleport rotation)
    if TornadoHotspot ~= nil and TornadoHotspot.updatePosition ~= nil then
        TornadoHotspot:updatePosition(tX, tZ, rotY)
    end
    self:trackMovement(tX, tZ)

    if self.lastTornadoPos then
        local jumpDist = MathUtil.vector2Length(tX - self.lastTornadoPos.x, tZ - self.lastTornadoPos.z)
        if jumpDist > 200.0 then
            self.activeNodes = {}
            self.safetyCache = {}
        end
    end
    self.lastTornadoPos = { x = tX, y = tY, z = tZ }

    self:runPhysicsLoop(dt, tX, tY, tZ)

    if TornadoADS then TornadoADS:update(dt, self.activeNodes) end
    if TornadoCargo then TornadoCargo:update(dt, self.activeNodes) end

    -- VISUAL DEBUGGER
    if self.showRing or self.debugMode then
        self:drawDebugRing(tX, tY, tZ, currentOuterRadius)
        local debugColor = { 1, 0, 0, 1 }; debugColor.r = 1; debugColor.g = 0; debugColor.b = 0; debugColor.a = 1
        DebugUtil.drawDebugSphere(tX, tY, tZ, 2.0, 16, 16, debugColor, true)
    end

    -- VISUAL SYNC
    -- Check if we have a visual tornado active
    if g_currentMission.environment.weather.twister ~= nil then
        local twister = g_currentMission.environment.weather.twister

        -- Only scale it if we haven't already (optimization)
        if twister.rootNode ~= nil and not twister.isTornadoModScaled then
            -- FIX 1: Use the correct variable name (currentEfNum instead of currentEFRating)
            local efScale = self.currentEfNum

            -- FIX 2: Safety Check. If efScale is nil, the physics haven't calculated the size yet.
            -- We simply do nothing this frame and wait for randomizeTornado() to run.
            if efScale ~= nil then
                local scale = 1.0 + (efScale * 0.8)

                setScale(twister.rootNode, scale, scale, scale)
                twister.isTornadoModScaled = true

                print(string.format("Tornado Visuals Synced: Scale %.2f (EF-%d)", scale, efScale))

                -- Crop damage path = the physics radius, strength by EF (server: the areas only exist there).
                self:applyCropDamageScale(twister, currentOuterRadius, efScale)
            end
        end
    end

    if TornadoHusbandry and TornadoHusbandry.runCycle then TornadoHusbandry:runCycle(dt, tX, tY, tZ, currentOuterRadius) end
    if AutoRepair and self.activeNodes and next(self.activeNodes) and AutoRepair.timer then AutoRepair.timer = 0 end
end

--#region
function TornadoPhysics:processNearbyObjects(dt, tX, tY, tZ)
    --#region
    if g_currentMission.vehicleSystem and g_currentMission.vehicleSystem.vehicles then
        for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
            if vehicle ~= nil and vehicle.rootNode ~= nil then
                local vx, vy, vz = getWorldTranslation(vehicle.rootNode)

                -- 1. Check shop/origin conditions FIRST before doing math
                local isOrigin = (math.abs(vx) < 0.001 and math.abs(vz) < 0.001)
                local isShopItem = (VehiclePropertyState ~= nil and VehiclePropertyState.SHOP_CONFIG ~= nil
                    and vehicle.propertyState == VehiclePropertyState.SHOP_CONFIG)

                if not isOrigin and not isShopItem then
                    -- 2. Only calculate distance for valid, in-world vehicles
                    local dist = MathUtil.vector3Length(vx - tX, vy - tY, vz - tZ)

                    if dist < self.settings.base_radius then
                        -- self:applyTornadoForces(vehicle, dist, dt)

                        -- Trigger Destruction
                        if TornadoDestruction then
                            TornadoDestruction:destroyTarget(vehicle)
                        end
                    end
                end
            end
        end
    end
    --#endregion
    --#region
    -- 2. Scan Placeables (Buildings)
    if g_currentMission.placeableSystem and g_currentMission.placeableSystem.placeables then
        for _, placeable in pairs(g_currentMission.placeableSystem.placeables) do
            if placeable ~= nil and placeable.rootNode ~= nil then
                local px, py, pz = getWorldTranslation(placeable.rootNode)

                -- 1. Ignore uninitialized / preview placeables sitting at origin (0,0)
                if not (math.abs(px) < 0.001 and math.abs(pz) < 0.001) then
                    -- 2. Distance check only runs on valid map placeables
                    local dist = MathUtil.vector3Length(px - tX, py - tY, pz - tZ)

                    if dist < self.settings.base_radius then
                        -- Trigger Destruction
                        if TornadoDestruction then
                            TornadoDestruction:destroyTarget(placeable)
                        end
                    end
                end
            end
        end
    end
    --#endregion
end

function TornadoPhysics:runPhysicsLoop(dt, tX, tY, tZ)
    local dtSec = dt * 0.001
    if dtSec > 0.04 then dtSec = 0.04 end
    self.activeNodes = {}

    local releaseRadiusSq = (currentOuterRadius * 1.2) * (currentOuterRadius * 1.2)

    if g_currentMission.vehicleSystem and g_currentMission.vehicleSystem.vehicles then
        for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
            if vehicle and not vehicle.isDeleted and vehicle.rootNode then
                local vX, vY, vZ = getWorldTranslation(vehicle.rootNode)
                local dx = vX - tX
                local dz = vZ - tZ
                local distSq = dx * dx + dz * dz

                if distSq <= releaseRadiusSq then
                    local isPallet = false
                    if vehicle.isPallet then
                        isPallet = true
                    elseif vehicle.typeName and (string.find(string.lower(vehicle.typeName), "pallet") or string.find(string.lower(vehicle.typeName), "bigbag")) then
                        isPallet = true
                    end

                    if isPallet then
                        if self.settings.lift_bales then
                            self.activeNodes[vehicle.rootNode] = { type = "PALLET", obj = vehicle }
                        end
                    else
                        if not (vehicle.isa and vehicle:isa(Bale)) then
                            local totalMass = self:getVehicleTotalMass(vehicle)
                            local vType = (vehicle == g_currentMission.controlledVehicle) and "PLAYER" or "VEHICLE"
                            self.activeNodes[vehicle.rootNode] = { type = vType, obj = vehicle, massOverride = totalMass }
                        end
                    end
                end
            end
        end
    end

    if self.settings.lift_bales and g_currentMission.itemSystem and g_currentMission.itemSystem.itemsToSave then
        for k, entry in pairs(g_currentMission.itemSystem.itemsToSave) do
            local object = entry.item or k
            if object and type(object) == "table" and object.nodeId and entityExists(object.nodeId) then
                if object.isa and object:isa(Bale) then
                    local bX, bY, bZ = getWorldTranslation(object.nodeId)
                    if bX then
                        local distSq = (tX - bX) ^ 2 + (tZ - bZ) ^ 2
                        if distSq < releaseRadiusSq then
                            if not (object.getIsMounted and object:getIsMounted()) then
                                self.activeNodes[object.nodeId] = { type = "BALE", obj = object }
                            end
                        end
                    end
                end
            end
        end
    end

    --#region
    -- if self.settings.lift_logs then
    --     self.scanTimer = (self.scanTimer or 0) + dt
    --     if self.scanTimer > 100 then
    --         overlapSphere(tX, tY, tZ, currentOuterRadius * 1.2, "objectScanCallback", self, 8192 + 32 + 2, true, true, true, false)
    --         self.scanTimer = 0
    --     end
    -- end
    -- Sweep for Logs & Environmental Props (Stop Signs, Fences, Loose Items)
    -- if self.settings.lift_logs then
    --     self.scanTimer = (self.scanTimer or 0) + dt
    --     if self.scanTimer > 100 then
    --         -- Use LOG_MASK + PROP_MASK so objectScanCallback catches both logs and breakable signs!
    --         local SCAN_MASK = LOG_MASK + PROP_MASK
    --         overlapSphere(tX, tY, tZ, currentOuterRadius * 1.2, "objectScanCallback", self, SCAN_MASK, true, true, true,
    --             false)
    --         self.scanTimer = 0
    --     end
    -- end
    -- ---------------------------------------------------------------------
    -- SWEEP FOR TIMBER / LOGS
    -- ---------------------------------------------------------------------
    if self.settings.lift_logs then
        self.logScanTimer = (self.logScanTimer or 0) + dt
        if self.logScanTimer > 100 then
            overlapSphere(tX, tY, tZ, currentOuterRadius * 1.2, "objectScanCallback", self, LOG_MASK, true, true, true, false)
            self.logScanTimer = 0
        end
    end

    -- ---------------------------------------------------------------------
    -- SWEEP FOR MAP PROPS (Signs, Cones, Fences, Loose Items)
    -- ---------------------------------------------------------------------
    if self.settings.lift_props then
        self.propScanTimer = (self.propScanTimer or 0) + dt
        if self.propScanTimer > 100 then
            overlapSphere(tX, tY, tZ, currentOuterRadius * 1.2, "objectScanCallback", self, PROP_MASK, true, true, true, false)
            self.propScanTimer = 0
        end
    end
    --#endregion
    --#region
    -- for nodeId, data in pairs(self.activeNodes) do
    --     if entityExists(nodeId) then
    --         if self.debugMode then self:drawDebugLabel(nodeId, self.isPurging and "EJECT" or data.type) end
    --         I3DUtil.wakeUpObject(nodeId)

    --         if data.type == "VEHICLE" or data.type == "PLAYER" or data.type == "PALLET" then
    --             self:applyVehiclePhysics(nodeId, tX, tY, tZ, dtSec, data)
    --         elseif data.type == "LOG" then
    --             self:applyLogPhysics(nodeId, tX, tY, tZ, dtSec, data)
    --         else
    --             self:applyBalePhysics(nodeId, tX, tY, tZ, dtSec, data)
    --         end
    --     end
    -- end
    --#endregion
    --#region
    -- UPDATED LOOP WITH PROP DISPATCH & CLEANUP:
    for nodeId, data in pairs(self.activeNodes) do
        if entityExists(nodeId) then
            if self.debugMode then self:drawDebugLabel(nodeId, self.isPurging and "EJECT" or data.type) end
            I3DUtil.wakeUpObject(nodeId)

            if data.type == "VEHICLE" or data.type == "PLAYER" or data.type == "PALLET" then
                self:applyVehiclePhysics(nodeId, tX, tY, tZ, dtSec, data)
            elseif data.type == "LOG" then
                self:applyLogPhysics(nodeId, tX, tY, tZ, dtSec, data)
            elseif data.type == "PROP" then
                self:applyPropPhysics(nodeId, tX, tY, tZ, dtSec, data)
            elseif data.type == "BALE" then
                self:applyBalePhysics(nodeId, tX, tY, tZ, dtSec, data)
            end
        else
            self.activeNodes[nodeId] = nil -- Clean up missing nodes
        end
    end
    --#endregion
end

-- =========================================================================
-- MAIN PHYSICS LOGIC (VEHICLES)
-- =========================================================================
function TornadoPhysics:applyVehiclePhysics(nodeId, tX, tY, tZ, dtSec, data)
    local mass = data.massOverride or getMass(nodeId)
    if mass < 0.001 then return end

    if data ~= nil and data.obj ~= nil and data.obj.rootNode ~= nil and nodeId ~= data.obj.rootNode then
        return
    end

    local vX, vY, vZ = getWorldTranslation(nodeId)
    local lVx, lVy, lVz = getLinearVelocity(nodeId)
    if lVx == nil then return end

    if self.settings.border_safety then
        local safeLimit = mapBoundary - self.settings.geo_fence
        if math.abs(vX) > safeLimit or math.abs(vZ) > safeLimit then
            setLinearVelocity(nodeId, 0, -10.0, 0)
            setAngularVelocity(nodeId, 0, 0, 0)
            return
        end
    end

    local dx = tX - vX
    local dz = tZ - vZ
    local distSq = dx * dx + dz * dz

    if distSq > currentOuterRadiusSq then
        setLinearDamping(nodeId, 0.05)
        setAngularDamping(nodeId, 0.05)
        return
    end

    if self:checkIsIndoorsCached(nodeId, 2.0) then
        if not self.settings.indoor_damage then
            if MathUtil.vector3Length(lVx, lVy, lVz) < 5.0 then
                setLinearDamping(nodeId, 10.0)
                setAngularDamping(nodeId, 10.0)
            end
            return
        end
    end

    -- A header on a header trailer (or anything else on a dynamic mount) is held by a joint that locks its
    -- rotation to the carrier and pulls it back along one axis without ever breaking. In the storm that kept
    -- the header standing on end next to the trailer and dragged it back onto it. Inside the wind field it
    -- is a loose object of its own.
    if data ~= nil and data.obj ~= nil then
        self:releaseDynamicMount(data.obj)
    end

    local massFactor = 1.0
    if mass > self.settings.heavy_threshold then
        massFactor = 1.0 + ((mass - self.settings.heavy_threshold) * self.settings.mass_penalty)
    end
    if massFactor > 15.0 then massFactor = 15.0 end

    -- =========================================================================
    -- PURGE LOGIC (3-TIER SYSTEM)
    -- =========================================================================
    if self.isPurging then
        local dist = math.sqrt(distSq)
        if dist < 1.0 then dist = 1.0 end
        local pushX = -dx / dist
        local pushZ = -dz / dist

        local purgeMult = self.sizeMultiplier
        local verticalKick = 15.0
        local damping = 0.05
        local speedLimit = 999.0

        -- TIER 1: FEATHERWEIGHT (< 0.8t)
        if mass < 0.8 then
            purgeMult = 0.60
            verticalKick = 6.0
            damping = 0.20
            speedLimit = 30.0

            -- TIER 2: MIDDLEWEIGHT (0.8t - 2.5t)
        elseif mass < 2.5 then
            if purgeMult > 1.0 then purgeMult = 1.0 end
            verticalKick = 6.0
            damping = 0.5
        end

        -- APPLY DAMPING
        setLinearDamping(nodeId, damping)
        setAngularDamping(nodeId, damping)

        -- SPEED LIMITER
        local currentSpeed = MathUtil.vector3Length(lVx, lVy, lVz)
        if currentSpeed > speedLimit then
            return
        end

        -- CALCULATE FORCE
        local ejectionResistance = massFactor * 0.6
        if ejectionResistance < 1.0 then ejectionResistance = 1.0 end

        local adjustedPower = (self.settings.ejection_power * purgeMult) / ejectionResistance
        local forceMag = mass * adjustedPower
        local liftKickVal = verticalKick / math.sqrt(massFactor)

        addForce(nodeId, pushX * forceMag, mass * liftKickVal, pushZ * forceMag, 0, 0, 0, true)
        return
    end

    -- =========================================================================
    -- SUCTION LOGIC
    -- =========================================================================
    setAngularDamping(nodeId, 1.0)
    setLinearDamping(nodeId, 0.15)
    local dist = math.sqrt(distSq)
    if dist < 0.1 then dist = 0.1 end
    local dirX = dx / dist
    local dirZ = dz / dist
    local targetVx, targetVz, targetVy = 0, 0, 0
    local edgeDist = currentOuterRadius - dist
    local entryFactor = 1.0
    if edgeDist < 20.0 then entryFactor = edgeDist / 20.0 end
    if entryFactor < 0 then entryFactor = 0 end

    if dist < 20.0 then
        targetVx = -dirX * 5.0 - (dirZ * 15.0)
        targetVz = -dirZ * 5.0 + (dirX * 15.0)
        targetVy = self.settings.lift_speed / math.sqrt(massFactor)
    else
        local speed = self.settings.suction_speed * (dist / currentOuterRadius) * entryFactor
        local rotationSpeed = 10.0
        targetVx = (dirX * speed) - (dirZ * rotationSpeed)
        targetVz = (dirZ * speed) + (dirX * rotationSpeed)
        targetVy = 0.5
    end

    if (vY - tY) > self.settings.hover_height then targetVy = -5.0 end

    local blend = 5.0 * dtSec * entryFactor
    if blend > 0.01 then
        local newVx = lVx + (targetVx - lVx) * blend
        local newVz = lVz + (targetVz - lVz) * blend
        local newVy = lVy + (targetVy - lVy) * blend

        local newSpeed = MathUtil.vector3Length(newVx, newVy, newVz)
        if newSpeed > self.settings.max_safe_speed then
            local scale = self.settings.max_safe_speed / newSpeed
            newVx, newVy, newVz = newVx * scale, newVy * scale, newVz * scale
        end
        setLinearVelocity(nodeId, newVx, newVy, newVz)
    end

    local allowDamage = (self.settings.indoor_damage) or (self.settings.outdoor_damage)
    if allowDamage then
        local destructionZoneSq = (currentOuterRadius * self.settings.destruction_ratio) ^ 2
        local applyDmg = 0
        local shouldEject = false

        if distSq < destructionZoneSq then
            applyDmg = self.settings.damage_center * dtSec
            shouldEject = true
        elseif distSq < currentOuterRadiusSq then
            applyDmg = self.settings.damage_outer * dtSec
            shouldEject = true
        end

        if applyDmg > 0 then
            if shouldEject and data.type == "PLAYER" and data.obj == g_currentMission.controlledVehicle then
                g_currentMission:onLeaveVehicle()
            end
            self:applyDamage(data.obj, applyDmg, currentOuterRadius)
        end
    end
end

-- =========================================================================
-- LOGS & BALES PHYSICS
-- =========================================================================
--#region
function TornadoPhysics:applyLogPhysics(nodeId, tX, tY, tZ, dtSec, data)
    local mass = getMass(nodeId)
    if mass == nil or mass < 0.001 then return end
    local vX, vY, vZ = getWorldTranslation(nodeId)
    if vX == nil then return end

    local dx = tX - vX
    local dz = tZ - vZ
    local distSq = dx * dx + dz * dz

    local massFactor = 1.0
    if mass > self.settings.heavy_threshold then
        massFactor = 1.0 + ((mass - self.settings.heavy_threshold) * self.settings.mass_penalty)
    end
    if massFactor > 4.0 then massFactor = 4.0 end

    if self.settings.border_safety then
        local safeLimit = mapBoundary - self.settings.geo_fence
        if math.abs(vX) > safeLimit or math.abs(vZ) > safeLimit then
            setLinearVelocity(nodeId, 0, -10.0, 0)
            setAngularVelocity(nodeId, 0, 0, 0)
            return
        end
    end

    if self:checkIsIndoorsCached(nodeId, 1.5) then return end

    if self.isPurging then
        setLinearDamping(nodeId, 0.05)
        setAngularDamping(nodeId, 0.05)
        local dist = math.sqrt(distSq)
        if dist < 1.0 then dist = 1.0 end
        local pushX = -dx / dist
        local pushZ = -dz / dist

        local adjustedPower = (self.settings.ejection_power * self.sizeMultiplier) / massFactor
        local forceMag = mass * adjustedPower
        local liftKick = 6.0 / math.sqrt(massFactor)
        addForce(nodeId, pushX * forceMag, mass * liftKick, pushZ * forceMag, 0, 0, 0, true)
        return
    end

    setAngularDamping(nodeId, 1.0)
    local lVx, lVy, lVz = getLinearVelocity(nodeId)
    if lVx == nil then return end

    local dist = math.sqrt(distSq)
    if dist < 0.1 then dist = 0.1 end
    local dirX = dx / dist
    local dirZ = dz / dist

    local targetVx, targetVz, targetVy = 0, 0, 0
    if dist < 20.0 then
        targetVx = -dirX * 5.0 - (dirZ * 15.0)
        targetVz = -dirZ * 5.0 + (dirX * 15.0)
        targetVy = self.settings.lift_speed / math.sqrt(massFactor)
    else
        local speed = self.settings.suction_speed * (dist / currentOuterRadius)
        targetVx = dirX * speed
        targetVz = dirZ * speed
        targetVy = 0.5
    end

    if (vY - tY) > self.settings.hover_height then targetVy = -5.0 end
    local blend = 5.0 * dtSec
    local newVx = lVx + (targetVx - lVx) * blend
    local newVz = lVz + (targetVz - lVz) * blend
    local newVy = lVy + (targetVy - lVy) * blend
    setLinearVelocity(nodeId, newVx, newVy, newVz)
end

--#endregion
--#region
--old section before adding a dedicated function for props.

-- =========================================================================
-- LOGS & BALES PHYSICS
-- =========================================================================
-- function TornadoPhysics:applyLogPhysics(nodeId, tX, tY, tZ, dtSec, data)
--     local mass = getMass(nodeId)
--     if mass == nil or mass < 0.001 then return end
--     local vX, vY, vZ = getWorldTranslation(nodeId)
--     if vX == nil then return end

--     local dx = tX - vX
--     local dz = tZ - vZ
--     local distSq = dx * dx + dz * dz

--     -- Detect light map props (street signs, cones, small debris)
--     local isLightProp = (mass < 0.2)

--     local massFactor = 1.0
--     if mass > self.settings.heavy_threshold then
--         massFactor = 1.0 + ((mass - self.settings.heavy_threshold) * self.settings.mass_penalty)
--     end
--     if massFactor > 4.0 then massFactor = 4.0 end

--     if self.settings.border_safety then
--         local safeLimit = mapBoundary - self.settings.geo_fence
--         if math.abs(vX) > safeLimit or math.abs(vZ) > safeLimit then
--             setLinearVelocity(nodeId, 0, -10.0, 0)
--             setAngularVelocity(nodeId, 0, 0, 0)
--             return
--         end
--     end

--     if self:checkIsIndoorsCached(nodeId, 1.5) then return end

--     if self.isPurging then
--         setLinearDamping(nodeId, 0.05)
--         setAngularDamping(nodeId, 0.05)
--         local dist = math.sqrt(distSq)
--         if dist < 1.0 then dist = 1.0 end
--         local pushX = -dx / dist
--         local pushZ = -dz / dist

--         -- Light props get an extra ejection burst so they sail away
--         local ejectionMult = isLightProp and 2.5 or 1.0
--         local adjustedPower = ((self.settings.ejection_power * self.sizeMultiplier) / massFactor) * ejectionMult
--         local forceMag = mass * adjustedPower
--         local liftKick = (isLightProp and 12.0 or 6.0) / math.sqrt(massFactor)
--         addForce(nodeId, pushX * forceMag, mass * liftKick, pushZ * forceMag, 0, 0, 0, true)
--         return
--     end

--     -- Less angular damping for light props so they tumble naturally in the air
--     setAngularDamping(nodeId, isLightProp and 0.1 or 1.0)
--     local lVx, lVy, lVz = getLinearVelocity(nodeId)
--     if lVx == nil then return end

--     local dist = math.sqrt(distSq)
--     if dist < 0.1 then dist = 0.1 end
--     local dirX = dx / dist
--     local dirZ = dz / dist

--     local targetVx, targetVz, targetVy = 0, 0, 0

--     if dist < 20.0 then
--         -- Light props orbit faster and gain vertical swirl
--         local orbitSpeed = isLightProp and 25.0 or 15.0
--         targetVx = -dirX * 5.0 - (dirZ * orbitSpeed)
--         targetVz = -dirZ * 5.0 + (dirX * orbitSpeed)

--         -- Give light props strong lift inside the core
--         targetVy = isLightProp and (self.settings.lift_speed * 1.8) or (self.settings.lift_speed / math.sqrt(massFactor))
--     else
--         local speed = self.settings.suction_speed * (dist / currentOuterRadius)
--         targetVx = dirX * speed
--         targetVz = dirZ * speed
--         targetVy = isLightProp and 1.5 or 0.5
--     end

--     -- Height management
--     local relY = vY - tY
--     if isLightProp then
--         -- Allow signs to float higher, and use soft damping instead of hard -5.0 downforce
--         if relY > (self.settings.hover_height * 1.5) then
--             targetVy = -1.5
--         end
--     else
--         -- Heavy logs/timber stay locked to low hover ceiling
--         if relY > self.settings.hover_height then
--             targetVy = -5.0
--         end
--     end

--     -- Velocity blending (Light props blend quicker to stay responsive)
--     local blend = (isLightProp and 8.0 or 5.0) * dtSec
--     local newVx = lVx + (targetVx - lVx) * blend
--     local newVz = lVz + (targetVz - lVz) * blend
--     local newVy = lVy + (targetVy - lVy) * blend
--     setLinearVelocity(nodeId, newVx, newVy, newVz)
-- end
--#endregion

function TornadoPhysics:applyBalePhysics(nodeId, tX, tY, tZ, dtSec, data)
    local mass = getMass(nodeId)
    if mass == nil or mass < 0.001 then return end
    local vX, vY, vZ = getWorldTranslation(nodeId)
    if vX == nil then return end

    local dx = tX - vX
    local dz = tZ - vZ
    local distSq = dx * dx + dz * dz
    local massFactor = 1.0

    if self.settings.border_safety then
        local safeLimit = mapBoundary - self.settings.geo_fence
        if math.abs(vX) > safeLimit or math.abs(vZ) > safeLimit then
            setLinearVelocity(nodeId, 0, -10.0, 0)
            setAngularVelocity(nodeId, 0, 0, 0)
            return
        end
    end

    if self:checkIsIndoorsCached(nodeId, 0.5) then return end

    if self.isPurging then
        setLinearDamping(nodeId, 0.05)
        setAngularDamping(nodeId, 0.05)
        local dist = math.sqrt(distSq)
        if dist < 1.0 then dist = 1.0 end
        local pushX = -dx / dist
        local pushZ = -dz / dist

        local baleMult = self.sizeMultiplier
        if mass < 0.5 then
            if baleMult > 0.3 then baleMult = 0.3 end
        else
            if baleMult > 1.0 then baleMult = 1.0 end
        end

        local adjustedPower = (self.settings.ejection_power * baleMult) / massFactor
        local forceMag = mass * adjustedPower
        local liftKick = 3.0 / math.sqrt(massFactor)
        addForce(nodeId, pushX * forceMag, mass * liftKick, pushZ * forceMag, 0, 0, 0, true)
        return
    end

    setAngularDamping(nodeId, 0.1)
    local lVx, lVy, lVz = getLinearVelocity(nodeId)
    if lVx == nil then return end

    local dist = math.sqrt(distSq)
    if dist < 0.1 then dist = 0.1 end
    local dirX = dx / dist
    local dirZ = dz / dist

    local targetVx, targetVz, targetVy = 0, 0, 0
    if dist < 20.0 then
        targetVx = -dirX * 5.0 - (dirZ * self.settings.bale_orbit)
        targetVz = -dirZ * 5.0 + (dirX * self.settings.bale_orbit)
        targetVy = self.settings.bale_lift
    else
        local suction = self.settings.bale_suction * (dist / currentOuterRadius)
        targetVx = dirX * suction
        targetVz = dirZ * suction
        targetVy = 2.0
    end

    -- math.random(m, n) only takes whole numbers; chaos_factor may be fractional, so scale a 0..1 roll instead.
    local chaos = self.settings.chaos_factor
    targetVx = targetVx + (math.random() * 2 - 1) * chaos
    targetVz = targetVz + (math.random() * 2 - 1) * chaos
    targetVy = targetVy + (math.random() * 4 - 2)

    if (vY - tY) > self.settings.hover_height then targetVy = -5.0 end

    local blend = 8.0 * dtSec
    if blend > 1.0 then blend = 1.0 end
    local newVx = lVx + (targetVx - lVx) * blend
    local newVz = lVz + (targetVz - lVz) * blend
    local newVy = lVy + (targetVy - lVy) * blend

    local newSpeed = MathUtil.vector3Length(newVx, newVy, newVz)
    if newSpeed > self.settings.max_safe_speed then
        local scale = self.settings.max_safe_speed / newSpeed
        newVx, newVy, newVz = newVx * scale, newVy * scale, newVz * scale
    end
    setLinearVelocity(nodeId, newVx, newVy, newVz)
end

function TornadoPhysics:applyDamage(vehicle, amount, currentOuterRadius)
    if vehicle == nil then return end

    -- Attempt to trigger visual destruction before applying stat damage
    if TornadoDestruction and TornadoDestruction.destroyTarget then
        TornadoDestruction:destroyTarget(vehicle)
    end

    local newDmg = 0.0
    if vehicle.getDamageAmount then
        newDmg = vehicle:getDamageAmount() or 0.0
    end

    if vehicle.setDamageAmount then
        newDmg = newDmg + amount
        if newDmg > 1.0 then
            newDmg = 1.0
            if vehicle.stopMotor then vehicle:stopMotor() end
            if vehicle.setBroken then vehicle:setBroken(true) end
        end
        vehicle:setDamageAmount(newDmg)
    end

    if vehicle.setDirtAmount then
        vehicle:setDirtAmount(math.min(vehicle:getDirtAmount() + amount * 5, 1))
    end
    if vehicle.setWearTotalAmount then
        vehicle:setWearTotalAmount(math.min(vehicle:getWearTotalAmount() + amount * 2, 1))
    end

    local igniteThreshold = self.settings.fire_damage_threshold or 0.85

    -- [CRITICAL CHECK] Added vehicle.spec_motorized
    if newDmg >= igniteThreshold and not vehicle.tornadoIsOnFire and vehicle.spec_motorized then
        vehicle.tornadoIsOnFire = true
        if TornadoEffects and TornadoEffects.igniteVehicle and vehicle.rootNode and entityExists(vehicle.rootNode) then
            -- This now just MARKS the vehicle. The fire will appear 30s after it leaves the storm.
            TornadoEffects:igniteVehicle(vehicle.rootNode)
        end
    end

    if vehicle.tornadoIsOnFire and TornadoEffects and TornadoEffects.igniteVehicle then
        TornadoEffects:igniteVehicle(vehicle.rootNode)

        -- Multiplayer: the fire roll happens here on the server; tell clients once per effect.
        local effect = TornadoEffects.activeEffects ~= nil and TornadoEffects.activeEffects[vehicle.rootNode] or nil
        if effect ~= nil and effect.willBurn and not effect.burnSent then
            effect.burnSent = true
            if TornadoSync ~= nil then TornadoSync:sendFx(vehicle, TornadoSync.FX_BURN) end
        end
    end

    if TornadoEffects and vehicle.spec_motorized then
        local tNode = self.tornadoNode
        local vNode = vehicle.rootNode
        local now = g_currentMission.time
        vehicle.tornadoNextSmokeTime = vehicle.tornadoNextSmokeTime or 0
        local cd = self.settings.damage_fx_cooldown_ms or 2000

        if now > vehicle.tornadoNextSmokeTime then
            if tNode and entityExists(tNode) and vNode and entityExists(vNode) then
                TornadoEffects:playDamageEffect(vNode, tNode, currentOuterRadius or 0)
                vehicle.tornadoNextSmokeTime = now + cd
                if TornadoSync ~= nil then TornadoSync:sendFx(vehicle, TornadoSync.FX_CONTACT) end
            end
        end
    end
end

--#region
-- =========================================================================
-- PROPS & ENVIRONMENT DEBRIS PHYSICS (Signs, Cones, Fences)
-- =========================================================================
function TornadoPhysics:applyPropPhysics(nodeId, tX, tY, tZ, dtSec, data)
    local mass = getMass(nodeId)
    if mass == nil or mass < 0.001 then return end
    local vX, vY, vZ = getWorldTranslation(nodeId)
    if vX == nil then return end

    -- Only dynamic bodies get here (see objectScanCallback). Kinematic bodies are never converted: in FS25 they
    -- are objects other systems hold in place - mounted bales / pallets, growing trees, AI traffic, animated
    -- doors / gates, and physics objects on multiplayer clients.

    -- Shock stationary props to snap map joints
    local lVx, lVy, lVz = getLinearVelocity(nodeId)
    if lVx ~= nil and (lVx * lVx + lVy * lVy + lVz * lVz) < 0.0001 then
        addImpulse(nodeId, 0, mass * 10.0, 0, 0, 0, 0, true)
    end

    local dx = tX - vX
    local dz = tZ - vZ
    local distSq = dx * dx + dz * dz

    -- Border safety check
    if self.settings.border_safety then
        local safeLimit = mapBoundary - self.settings.geo_fence
        if math.abs(vX) > safeLimit or math.abs(vZ) > safeLimit then
            setLinearVelocity(nodeId, 0, -10.0, 0)
            setAngularVelocity(nodeId, 0, 0, 0)
            return
        end
    end

    if self:checkIsIndoorsCached(nodeId, 1.5) then return end

    -- Purge / Ejection Phase
    if self.isPurging then
        setLinearDamping(nodeId, 0.05)
        setAngularDamping(nodeId, 0.05)
        local dist = math.sqrt(distSq)
        if dist < 1.0 then dist = 1.0 end
        local pushX = -dx / dist
        local pushZ = -dz / dist

        local forceMag = mass * (self.settings.ejection_power * self.sizeMultiplier * 2.5)
        addForce(nodeId, pushX * forceMag, mass * 12.0, pushZ * forceMag, 0, 0, 0, true)
        return
    end

    -- Low angular damping for active airborne tumbling
    setAngularDamping(nodeId, 0.1)

    local dist = math.sqrt(distSq)
    if dist < 0.1 then dist = 0.1 end
    local dirX = dx / dist
    local dirZ = dz / dist

    local targetVx, targetVz, targetVy = 0, 0, 0

    if dist < 20.0 then
        -- Fast, tight orbit in funnel center
        targetVx = -dirX * 5.0 - (dirZ * 25.0)
        targetVz = -dirZ * 5.0 + (dirX * 25.0)
        targetVy = self.settings.lift_speed * 1.8
    else
        -- Suction phase
        local speed = self.settings.suction_speed * (dist / currentOuterRadius)
        targetVx = dirX * speed
        targetVz = dirZ * speed
        targetVy = 1.5
    end

    -- Soft height ceiling so props float gracefully without slamming down
    local relY = vY - tY
    if relY > (self.settings.hover_height * 1.5) then
        targetVy = -1.5
    end

    -- Rapid velocity blending
    local blend = 8.0 * dtSec
    local newVx = lVx + (targetVx - lVx) * blend
    local newVz = lVz + (targetVz - lVz) * blend
    local newVy = lVy + (targetVy - lVy) * blend

    setLinearVelocity(nodeId, newVx, newVy, newVz)
end

--#endregion

-- =========================================================================
-- HELPERS
-- =========================================================================
function TornadoPhysics:checkIsIndoorsCached(nodeId, startHeight)
    local currentTime = g_currentMission.time
    local cache = self.safetyCache[nodeId]
    if cache and currentTime < cache.expireTime then return cache.isSafe end
    local x, y, z = getWorldTranslation(nodeId)
    if x == nil then return false end
    self.raycastResult = false
    raycastClosest(x, y + startHeight, z, 0, 1, 0, 30, "raycastCallback", self, ROOF_MASK)
    if not self.raycastResult then
        raycastClosest(x + 2.0, y + startHeight, z, 0, 1, 0, 30, "raycastCallback", self, ROOF_MASK)
    end
    if not self.raycastResult then
        raycastClosest(x - 2.0, y + startHeight, z, 0, 1, 0, 30, "raycastCallback", self, ROOF_MASK)
    end
    self.safetyCache[nodeId] = { isSafe = self.raycastResult, expireTime = currentTime + 1000 }
    return self.raycastResult
end

function TornadoPhysics:raycastCallback(hitObjectId)
    if hitObjectId ~= 0 then
        self.raycastResult = true
        return false
    end
    return true
end

--#region
-- function TornadoPhysics:objectScanCallback(nodeId)
--     if not entityExists(nodeId) then return true end
--     if self.activeNodes[nodeId] then return true end
--     if ClassIds and getHasClassId(nodeId, ClassIds.MESH_SPLIT_SHAPE) then self.activeNodes[nodeId] = { type = "LOG" } end
--     return true
-- end
-- function TornadoPhysics:objectScanCallback(nodeId)
--     if not entityExists(nodeId) then return true end
--     if self.activeNodes[nodeId] then return true end

--     -- Pick up split logs
--     if ClassIds and getHasClassId(nodeId, ClassIds.MESH_SPLIT_SHAPE) then
--         self.activeNodes[nodeId] = { type = "LOG" }
--     -- Pick up dynamic street signs and map props
--     elseif getRigidBodyType(nodeId) ~= RigidBodyType.STATIC then
--         self.activeNodes[nodeId] = { type = "LOG" } -- Flings them using log/bale physics!
--     end
--     return true
-- end
function TornadoPhysics:objectScanCallback(nodeId)
    if not entityExists(nodeId) then return true end
    if self.activeNodes[nodeId] then return true end

    local mass = getMass(nodeId) or 0.0

    -- 1. Split timber / logs
    if ClassIds and getHasClassId(nodeId, ClassIds.MESH_SPLIT_SHAPE) then
        self.activeNodes[nodeId] = { type = "LOG" }

        -- 2. Dynamic map props (signs, cones, light debris). Only DYNAMIC: kinematic bodies are held by other
        --    systems (mounts, tree growth, traffic, animations, MP clients) and NONE has no physics at all.
    elseif getRigidBodyType(nodeId) == RigidBodyType.DYNAMIC then
        -- If it's light, tag it as PROP, otherwise leave heavy debris as LOG
        if mass > 0 and mass < 0.2 then
            self.activeNodes[nodeId] = { type = "PROP" }
        else
            self.activeNodes[nodeId] = { type = "LOG" }
        end
    end

    return true
end

--#endregion

function TornadoPhysics:drawDebugLabel(nodeId, type)
    local x, y, z = getWorldTranslation(nodeId)
    local vx, vy, vz = getLinearVelocity(nodeId)
    if vx then
        local speed = MathUtil.vector3Length(vx, vy, vz)
        Utils.renderTextAtWorldPosition(x, y + 1.5, z,
            string.format("[%s]\nMass: %.2f\nSpd: %.1f", type, getMass(nodeId) or 0, speed), 0.012, 0)
    end
end

function TornadoPhysics:drawDebugRing(x, y, z, r)
    local steps = 40; local hLow = y + 2.0; local hHigh = y + 40.0; local g = self.isPurging and 1.0 or 0.0; local r_col =
    self.isPurging and 0.0 or 1.0
    for i = 1, steps do
        local a1 = (i - 1) / (steps) * 6.28; local a2 = i / steps * 6.28
        local x1, z1 = x + math.cos(a1) * r, z + math.sin(a1) * r
        local x2, z2 = x + math.cos(a2) * r, z + math.sin(a2) * r
        drawDebugLine(x1, hLow, z1, r_col, g, 0, x2, hLow, z2, r_col, g, 0)
        drawDebugLine(x1, hHigh, z1, r_col, g, 0, x2, hHigh, z2, r_col, g, 0)
        if i % 5 == 0 then drawDebugLine(x1, hLow, z1, r_col, g, 0, x1, hHigh, z1, r_col, g, 0) end
    end
end

--- Live outer radius of the active tornado (map-scaled and EF-scaled), for other modules.
function TornadoPhysics:getOuterRadius()
    return currentOuterRadius
end

--- Ejection interval: the tuned base value plus the extra time large maps get.
--- Read live so t_tune purge_int / t_reset apply immediately.
function TornadoPhysics:getPurgeInterval()
    return self.settings.purge_interval + ((mapScaleFactor - 1.0) * 20000)
end

--- Map size relative to a standard 2 km map (1 = 2 km, 2 = 4 km, 4 = 8 km ...).
function TornadoPhysics:getMapScaleFactor()
    return mapScaleFactor
end

function TornadoPhysics:calculateMapScale()
    if g_currentMission and g_currentMission.terrainSize then
        local size = g_currentMission.terrainSize
        mapScaleFactor = size / 2048.0; if mapScaleFactor < 1.0 then mapScaleFactor = 1.0 end
        mapBoundary = size * 0.5; currentOuterRadius = self.settings.base_radius * mapScaleFactor; currentOuterRadiusSq =
        currentOuterRadius * currentOuterRadius
        self.purgeInterval = self:getPurgeInterval()
        if TornadoDebug then TornadoDebug:info("SETUP",
                string.format("MapSize=%.0f | Base Radius=%.1fm (before EF roll) | Purge=%.1fs", size, currentOuterRadius,
                    self.purgeInterval / 1000)) end
    end

    -- Export for other modules (MapUI, etc.)
    self.mapScaleFactor = mapScaleFactor
    TornadoPhysics.mapScaleFactor = mapScaleFactor
    self.mapBoundary = mapBoundary
    TornadoPhysics.mapBoundary = mapBoundary
end

function TornadoPhysics:randomizeTornado()
    -- The server rolls the tornado; multiplayer clients get the result through TornadoStateEvent.
    if g_currentMission == nil or not g_currentMission:getIsServer() then
        return
    end
    if self.tornadoNode then
        -- The map scale must exist before the radius is rolled. Otherwise the first tornado after
        -- loading uses scale 1.0 and calculateMapScale() then resets the rolled radius to base_radius.
        if not mapInitialized then
            self:calculateMapScale()
            mapInitialized = true
        end

        local scaledBase = self.settings.base_radius * mapScaleFactor
        -- Real-life climate mode (TornadoClimate) rolls EF + size from NOAA data; nil = classic even roll.
        local scale = TornadoClimate ~= nil and TornadoClimate:rollScale() or nil
        if scale == nil then
            scale = self.settings.min_scale + math.random() * (self.settings.max_scale - self.settings.min_scale)
        end
        setScale(self.tornadoNode, scale, scale, scale)

        self.currentScale = scale
        self:multiplyDebris(self.tornadoNode)

        currentOuterRadius = scaledBase * scale
        currentOuterRadiusSq = currentOuterRadius * currentOuterRadius

        self.sizeMultiplier = currentOuterRadius / self.settings.base_radius
        if self.sizeMultiplier < 1.0 then self.sizeMultiplier = 1.0 end

        -- EF scale + NWS 3-second gust ranges (mph)
        local efNum = 0
        local windMin, windMax = 65, 85
        if scale > 1.0 then
            efNum = 1; windMin, windMax = 86, 110
        end
        if scale > 2.0 then
            efNum = 2; windMin, windMax = 111, 135
        end
        if scale > 3.0 then
            efNum = 3; windMin, windMax = 136, 165
        end
        if scale > 4.0 then
            efNum = 4; windMin, windMax = 166, 200
        end
        if scale > 4.8 then
            efNum = 5; windMin, windMax = 201, 250
        end

        local rating = "EF-" .. tostring(efNum)

        -- Export stats for MapUI (and other modules)
        self.currentEfNum = efNum; TornadoPhysics.currentEfNum = efNum
        self.currentWindMin = windMin; TornadoPhysics.currentWindMin = windMin
        self.currentWindMax = windMax; TornadoPhysics.currentWindMax = windMax
        self.currentRadiusM = math.floor(currentOuterRadius + 0.5); TornadoPhysics.currentRadiusM = self.currentRadiusM

        if TornadoHotspot ~= nil and TornadoHotspot.updateStats ~= nil then
            TornadoHotspot:updateStats(efNum, windMin, windMax, self.currentRadiusM)
        end

        if TornadoDebug then
            TornadoDebug:info("EVENT", string.format("Tornado touchdown (%s | Radius: %dm | PwrMult: x%.1f)", rating,
                math.floor(currentOuterRadius), self.sizeMultiplier))
        end
        if g_currentMission and g_dedicatedServer == nil then
            g_currentMission:showBlinkingWarning(TornadoText.format("tp_msg_touchdown", efNum,
                math.floor(currentOuterRadius), self.sizeMultiplier), 20000)
        end
        if TornadoAPI then TornadoAPI:fireTouchdownEvent() end

        -- Multiplayer: clients show the same EF, size, warning and siren.
        if TornadoSync ~= nil then TornadoSync:sendTornadoState(true, true) end
    end
end

-- =========================================================================
-- MULTIPLAYER CLIENT
-- The server runs all tornado gameplay. A client only finds the (network-synced) twister node itself
-- and shows the stats the server sends in TornadoStateEvent: funnel size, siren, warning, hotspot,
-- map overlay, compass marker and the danger ring.
-- =========================================================================

--- The visible twister node in the scene, or nil. No side effects (unlike findTornadoSimple).
function TornadoPhysics:findTwisterNode()
    local root = getRootNode()
    for i = 0, getNumOfChildren(root) - 1 do
        local child = getChildAt(root, i)
        local name = getName(child)
        if name and string.find(string.lower(name), "twister") and getVisibility(child) then
            return child
        end
    end
    return nil
end

--- Client: stats from the server (TornadoStateEvent).
function TornadoPhysics:applyClientState(state)
    if not state.isActive then
        local wasActive = self.clientActive
        self.clientActive = false
        self.clientVisualsPending = false
        self.tornadoNode = nil
        self:resetTrackMovement()
        if TornadoHotspot ~= nil then TornadoHotspot:setActive(false) end
        if TornadoSFX then TornadoSFX.sirenLoopCount = 0 end
        if wasActive and TornadoAPI then TornadoAPI:fireDespawnEvent() end
        return
    end

    if state.isNewTouchdown or not self.clientActive then
        self:resetTrackMovement()
    end
    self.clientActive = true
    currentOuterRadius = state.outerRadius
    currentOuterRadiusSq = currentOuterRadius * currentOuterRadius
    self.currentEfNum = state.efNum
    self.currentWindMin = state.windMin
    self.currentWindMax = state.windMax
    self.currentRadiusM = state.radiusM
    self.sizeMultiplier = state.sizeMultiplier
    self.currentScale = state.scale
    self.clientVisualsPending = true

    if TornadoHotspot ~= nil and TornadoHotspot.updateStats ~= nil then
        TornadoHotspot:updateStats(state.efNum, state.windMin, state.windMax, state.radiusM)
    end
    if TornadoClimate ~= nil and state.hasClimateRoll then
        TornadoClimate.lastRoll = {
            region = state.rollRegion, regionName = state.rollRegionName, ef = state.rollEf,
            width = state.rollWidth >= 0 and state.rollWidth or nil, scale = state.scale,
        }
    end

    if state.isNewTouchdown then
        if TornadoSFX then
            TornadoSFX.sirenLoopCount = 0
            TornadoSFX.sirenTimer = 0
        end
        g_currentMission:showBlinkingWarning(TornadoText.format("tp_msg_touchdown",
            state.efNum, math.floor(state.outerRadius), state.sizeMultiplier), 20000)
        if TornadoAPI then TornadoAPI:fireTouchdownEvent() end
    end
end

--- Client: funnel size and extra debris the way the server set them in randomizeTornado / visual sync.
-- Crop damage strength by EF rating: multiplies the destroyed share of every twister destruction area
-- (game default: inner 85 %, middle ring 70 %, outer ring 40 % = EF-2 here). Capped at 5 - 98 %.
TornadoPhysics.CROP_STRENGTH_BY_EF = { [0] = 0.6, [1] = 0.8, [2] = 1.0, [3] = 1.15, [4] = 1.3, [5] = 1.45 }

--- The game's twister destroys crops along its destruction areas (polygons of child nodes of the twister i3d,
--- $data/sky/twister.xml: outer ring 35 m; maps can bring their own twister, e.g. 70 m). Scaling the twister root by
--- EF (visual sync) scales them too, but not to our physics radius. This sizes the areas' common parent node so
--- the outermost ring sits on targetRadius (measured in world space, so any twister i3d and any parent scale
--- work), and sets each area's perlin value from its original one by CROP_STRENGTH_BY_EF.
--- Nothing is copied from the twister files; the storm damage report measures the scaled areas as they are.
function TornadoPhysics:applyCropDamageScale(twister, targetRadius, efNum)
    local areas = twister ~= nil and twister.destructionAreas or nil
    if areas == nil or #areas == 0 or twister.rootNode == nil or targetRadius == nil or targetRadius <= 0 then
        return
    end

    -- The areas' common parent: walk up from a polygon node to the node directly under the i3d component
    -- (the component itself is linked to twister.rootNode).
    local areasNode = twister.tornadoAreasNode
    if areasNode == nil then
        local first = areas[1].polygon ~= nil and areas[1].polygon.nodes ~= nil and areas[1].polygon.nodes[1] or nil
        local node = first
        while node ~= nil and node ~= 0 and getParent(node) ~= 0 and getParent(getParent(node)) ~= twister.rootNode do
            node = getParent(node)
        end
        if node == nil or node == 0 or getParent(node) == 0 then
            return
        end
        areasNode = node
        twister.tornadoAreasNode = areasNode
    end

    -- Size: outermost polygon point from the twister centre, in world space.
    local cx, _, cz = getWorldTranslation(twister.rootNode)
    local current = 0
    for _, area in ipairs(areas) do
        for _, node in ipairs(area.polygon ~= nil and area.polygon.nodes or {}) do
            local x, _, z = getWorldTranslation(node)
            current = math.max(current, math.sqrt((x - cx) * (x - cx) + (z - cz) * (z - cz)))
        end
    end
    if current > 0.5 then
        local sx, sy, sz = getScale(areasNode)
        local factor = targetRadius / current
        setScale(areasNode, sx * factor, sy, sz * factor)
    end

    -- Strength: destroyed share = 1 - perlin / 10000, scaled from the twister file's own value.
    local strength = self.CROP_STRENGTH_BY_EF[efNum or 2] or 1.0
    for _, area in ipairs(areas) do
        if area.tornadoBasePerlin == nil then
            area.tornadoBasePerlin = area.perlinPercentage or 2500
        end
        local destroyed = 1 - area.tornadoBasePerlin / 10000
        destroyed = math.max(0.05, math.min(0.98, destroyed * strength))
        area.perlinPercentage = math.floor((1 - destroyed) * 10000 + 0.5)
    end

    if TornadoDebug then
        TornadoDebug:info("EVENT", string.format("Crop damage path: outer ring %.0f m -> %.0f m, strength x%.2f (EF-%s)",
            current, targetRadius, strength, tostring(efNum)))
    end
end

function TornadoPhysics:applyClientVisuals()
    self.clientVisualsPending = false
    local scale = self.currentScale or 1
    setScale(self.tornadoNode, scale, scale, scale)
    self:multiplyDebris(self.tornadoNode)

    local weather = g_currentMission.environment ~= nil and g_currentMission.environment.weather or nil
    if weather ~= nil and weather.twister ~= nil and weather.twister.rootNode ~= nil and self.currentEfNum ~= nil then
        local visualScale = 1.0 + (self.currentEfNum * 0.8)
        setScale(weather.twister.rootNode, visualScale, visualScale, visualScale)
        weather.twister.isTornadoModScaled = true
    end
end

--- Client per-frame: siren, hotspot position and the danger ring while the server reports a tornado.
function TornadoPhysics:updateClient(dt)
    if not self.clientActive then
        return
    end
    if self.tornadoNode == nil or not entityExists(self.tornadoNode) then
        self.tornadoNode = self:findTwisterNode()
        if self.tornadoNode == nil then
            return
        end
        self.clientVisualsPending = true
    end
    if not getVisibility(self.tornadoNode) then
        return
    end

    if self.clientVisualsPending then
        self:applyClientVisuals()
    end
    if TornadoSFX then TornadoSFX:playSiren() end

    local tX, tY, tZ = getWorldTranslation(self.tornadoNode)
    local _, rotY, _ = getWorldRotation(self.tornadoNode)
    if TornadoHotspot ~= nil then
        TornadoHotspot:updatePosition(tX, tZ, rotY)
    end
    self:trackMovement(tX, tZ)
    if self.showRing or self.debugMode then
        self:drawDebugRing(tX, tY, tZ, currentOuterRadius)
    end
end

--- Compass direction the tornado is actually moving ("NE"), from its position over time.
--- Works on the server and on clients and for every spawn type; shown on the ESC map overlay.
function TornadoPhysics:trackMovement(tX, tZ)
    if self.trackLastX == nil then
        self.trackLastX, self.trackLastZ = tX, tZ
        return
    end
    local dx, dz = tX - self.trackLastX, tZ - self.trackLastZ
    if dx * dx + dz * dz < 4 then   -- wait for 2 m of movement so the heading is stable
        return
    end
    self.trackLastX, self.trackLastZ = tX, tZ
    if TornadoClimate ~= nil and TornadoClimate.directionToLabel ~= nil then
        self.trackLabel = TornadoClimate.directionToLabel(dx, dz)
    end
end

function TornadoPhysics:resetTrackMovement()
    self.trackLastX, self.trackLastZ, self.trackLabel = nil, nil, nil
end

--- Server, after loading a savegame: puts the saved tornado back as it was (TornadoPersistence) instead of
--- rolling a new one. No touchdown alert, no siren replay, no outbreak roll.
function TornadoPhysics:restoreTornado(saved)
    if not mapInitialized then
        self:calculateMapScale()
        mapInitialized = true
    end

    local scale = saved.scale or 1
    setScale(self.tornadoNode, scale, scale, scale)
    self.currentScale = scale
    self:multiplyDebris(self.tornadoNode)

    currentOuterRadius = saved.outerRadius or (self.settings.base_radius * mapScaleFactor * scale)
    currentOuterRadiusSq = currentOuterRadius * currentOuterRadius
    self.sizeMultiplier = saved.sizeMultiplier or 1
    self.currentEfNum = saved.efNum
    self.currentWindMin = saved.windMin
    self.currentWindMax = saved.windMax
    self.currentRadiusM = saved.radiusM

    if TornadoHotspot ~= nil and TornadoHotspot.updateStats ~= nil then
        TornadoHotspot:updateStats(saved.efNum, saved.windMin, saved.windMax, saved.radiusM)
    end
    if TornadoClimate ~= nil and saved.roll ~= nil then
        TornadoClimate.lastRoll = saved.roll
    end
    -- The siren already warned about this tornado before the save.
    if TornadoSFX then
        TornadoSFX.sirenLoopCount = 3
    end
    -- The game restores twister weather without activating it, so put the saved storm back.
    if saved.weather ~= nil and TornadoWeather ~= nil and TornadoWeather.applyProfile ~= nil then
        TornadoWeather:applyProfile(nil, true, saved.weather)
    end

    if TornadoSync ~= nil then TornadoSync:sendTornadoState(true, false) end
    print(string.format("TornadoPhysics: Restored saved tornado (EF-%d | Radius: %dm) - no new roll.",
        saved.efNum or 0, math.floor(currentOuterRadius)))
end

--- Clones the twister's native debris / dust particle nodes 3x for a denser funnel base.
--- Only once per tornado node: randomizeTornado() also runs on every radius change, and re-running this
--- would clone the clones (4x, 16x, 64x ...). Used by the server and by multiplayer clients.
function TornadoPhysics:multiplyDebris(node)
    if node == nil or self.debrisMultipliedNode == node then
        return
    end
    self.debrisMultipliedNode = node

    -- Snapshot the original children first so clones added below are never scanned.
    local originals = {}
    for i = 0, getNumOfChildren(node) - 1 do
        originals[#originals + 1] = getChildAt(node, i)
    end

    for _, child in ipairs(originals) do
        local childName = string.lower(getName(child) or "")

        -- Look for native GIANTS particle/debris nodes attached to the twister
        if string.find(childName, "debris") or string.find(childName, "dust") or string.find(childName, "particles") then
            -- We found the debris ring! Let's clone it 3 times for 4x density.
            for cloneIdx = 1, 3 do
                local clonedDebris = clone(child, true, false, false)
                link(node, clonedDebris) -- Attach clone to the main tornado

                -- Offset the rotation so the debris fields interlock instead of overlapping
                local rx, ry, rz = getRotation(clonedDebris)
                setRotation(clonedDebris, rx, ry + math.rad(cloneIdx * 45), rz)

                -- Make the outer clones slightly wider to thicken the funnel base
                setScale(clonedDebris, 1.0 + (cloneIdx * 0.2), 1.0, 1.0 + (cloneIdx * 0.2))
            end

            if TornadoDebug then TornadoDebug:log("PHYSICS", "Successfully multiplied native debris/dust nodes.") end
        end
    end
end

function TornadoPhysics:findTornadoSimple()
    local root = getRootNode()
    local count = getNumOfChildren(root)
    for i = 0, count - 1 do
        local child = getChildAt(root, i)
        local name = getName(child)
        if name and string.find(string.lower(name), "twister") then
            if getVisibility(child) then
                self.tornadoNode = child
                -- A tornado that was on the ground when the game was saved keeps its saved stats.
                local saved = TornadoPersistence ~= nil and TornadoPersistence:takeTornadoRestore() or nil
                if saved ~= nil then
                    self:restoreTornado(saved)
                else
                    self:randomizeTornado()
                    if TornadoOutbreak ~= nil then TornadoOutbreak:onTouchdown() end
                end
                return
            end
        end
    end
end

--- Server: frees a vehicle that is dynamically mounted on another one (header trailer, fork mounts).
--- If it lands on its carrier again, the game mounts it again by itself.
function TornadoPhysics:releaseDynamicMount(vehicle)
    if MountableObject == nil or vehicle.unmountDynamic == nil or vehicle.spec_mountable == nil then
        return
    end
    if vehicle.dynamicMountType ~= MountableObject.MOUNT_TYPE_DYNAMIC then
        return
    end
    vehicle:unmountDynamic()
    -- Same clean-up the game does when a mounted object leaves its carrier.
    local spec = vehicle.spec_mountable
    spec.dynamicMountObjectTriggerCount = nil
    spec.dynamicMountJointNodeDynamicRefNode = nil
    spec.dynamicMountJointNodeDynamicMountOffset = nil
    if TornadoDebug then
        TornadoDebug:log("PHYSICS", "Released dynamic mount: " .. tostring(vehicle.getName ~= nil and vehicle:getName() or vehicle.typeName))
    end
end

function TornadoPhysics:getVehicleTotalMass(vehicle)
    local totalMass = 0
    if vehicle.rootNode then totalMass = totalMass + (getMass(vehicle.rootNode) or 0) end
    if vehicle.components then
        for _, comp in pairs(vehicle.components) do
            if comp.node and comp.node ~= vehicle.rootNode then
                totalMass = totalMass + (getMass(comp.node) or 0)
            end
        end
    end

    -- SAFETY ONLY (Prevent divide-by-zero, but DO NOT fake the weight)
    if totalMass < 0.05 then totalMass = 0.05 end

    return totalMass
end

--- The game has a single twister object. Spawning while it is still on the ground (e.g. a second
--- gsWeatherTwisterSpawn) re-uses the same node, so the "node appeared" detection never fires again.
--- Twister:spawn() runs for every spawn, so flag it and let update() redo the touchdown.
function TornadoPhysics:installSpawnHook()
    -- Twister survives savegame reloads; flag the class so the hook is only added once.
    if Twister == nil or Twister.spawn == nil or Twister.tornadoSpawnHooked then
        return
    end
    Twister.tornadoSpawnHooked = true
    Twister.spawn = Utils.appendedFunction(Twister.spawn, function(twister, ...)
        -- Only a re-spawn matters; a first spawn is picked up by the normal node search.
        if TornadoPhysics ~= nil and TornadoPhysics.tornadoNode ~= nil then
            TornadoPhysics.respawnPending = true
        end
    end)
end

--- New touchdown on the already tracked twister: fresh roll, warning, siren and visual rescale.
function TornadoPhysics:onTornadoRespawn()
    print("TornadoPhysics: New tornado spawned on the active twister - rolling a new touchdown.")

    -- The previous tornado is over: report its crop damage before the new one starts.
    if TornadoInsuranceDamage ~= nil and TornadoInsuranceDamage.onTornadoEnded ~= nil then
        TornadoInsuranceDamage:onTornadoEnded()
    end

    self.activeNodes = {}
    self.safetyCache = {}
    self.isPurging = false
    self.purgeTimer = 0
    self:resetTrackMovement()

    if TornadoSFX then
        TornadoSFX.sirenLoopCount = 0
        TornadoSFX.sirenTimer = 0
    end

    -- Let the visual sync scale the funnel to the new EF rating.
    local weather = g_currentMission.environment ~= nil and g_currentMission.environment.weather or nil
    if weather ~= nil and weather.twister ~= nil then
        weather.twister.isTornadoModScaled = nil
    end

    self:randomizeTornado()
    if TornadoOutbreak ~= nil then TornadoOutbreak:onTouchdown() end

    -- No weather change happens on a re-spawn, so roll the storm weather (rain / hail / wind) here.
    if TornadoWeather ~= nil and TornadoWeather.applyProfile ~= nil then
        TornadoWeather:applyProfile(nil, true)
    end
end

function TornadoPhysics:clearTornadoState()
    print("TornadoPhysics: WATCHDOG TRIGGERED! Cleaning up despawned tornado.")

    --#region
    -- Scan every active entity tracked in the current physics sweep
    -- and strip off visual artifacts before clearing the tracking tables.
    if self.activeNodes ~= nil then
        for _, data in pairs(self.activeNodes) do
            -- If it's a vehicle object containing a standard structural root
            if data.obj ~= nil then
                self:purgeVehicleVisualArtifacts(data.obj)
            end
        end
    end
    --#endregion

    -- 1. Clear internal script variables
    self:resetTrackMovement()
    self.tornadoNode = nil
    self.lastTornadoPos = nil
    self.activeNodes = {}
    self.safetyCache = {}
    self.isPurging = false
    self.purgeTimer = 0
    self.foundCandidate = nil
    self.confirmTimer = 0

    -- 2. Clear HUD / Hotspot
    if TornadoHotspot ~= nil and TornadoHotspot.deleteMap ~= nil then
        TornadoHotspot:deleteMap()
    end

    -- 3. Stop Siren
    if TornadoSFX then
        TornadoSFX.sirenLoopCount = 0
        -- If you have a specific stopSiren() function, call it here
    end
    --#region
    -- -- 4. Force Weather Manager Reset (Crucial for the spawn bug)
    -- if g_currentMission and g_currentMission.environment and g_currentMission.environment.weather then
    --     local weather = g_currentMission.environment.weather
    --     if weather.twister ~= nil then
    --         print("TornadoPhysics: Forcing game engine weather cleanup.")
    --         -- We manually trick the engine into thinking the weather event is fully over
    --         weather.twister = nil
    --     end

    --     --#region
    --     -- Force the engine to execute its full, native environment data reload.
    --     -- This re-reads the map configurations and restores the twister definition
    --     -- table that EDC or Screenshot mode broke!
    --     if environment.consoleCommandReloadEnvironment ~= nil then
    --         print("TornadoPhysics: Running consoleCommandReloadEnvironment to restore map definitions...")
    --         environment:consoleCommandReloadEnvironment()
    --     else
    --         print("TornadoPhysics: Warning - consoleCommandReloadEnvironment not found on environment object.")
    --     end

    --     -- Optional: Reload ambient sounds just like EDC does to keep everything in sync
    --     if g_currentMission.ambientSoundSystem ~= nil and g_currentMission.ambientSoundSystem.consoleCommandReload ~= nil then
    --         g_currentMission.ambientSoundSystem:consoleCommandReload()
    --     end
    --     --#endregion
    -- end
    -- 4. Force Weather Manager Reset & Auto-Heal Environment
    if g_currentMission and g_currentMission.environment ~= nil then
        local environment = g_currentMission.environment

        -- Safe cleanup of the old twister reference
        if environment.weather ~= nil then
            if environment.weather.twister ~= nil then
                print("TornadoPhysics: Forcing game engine weather cleanup.")
                environment.weather.twister = nil
            end

            -- EDC Trick: Reset the rain updater to avoid log warnings during reload
            if environment.weather.rainUpdater ~= nil then
                print("TornadoPhysics: Resetting rainUpdater table...")
                environment.weather.rainUpdater:reset()
            end
        end

        -- Force the engine to execute its full, native environment data reload.
        if environment.consoleCommandReloadEnvironment ~= nil then
            print("TornadoPhysics: Running consoleCommandReloadEnvironment to restore map definitions...")
            environment:consoleCommandReloadEnvironment()
        else
            print("TornadoPhysics: Warning - consoleCommandReloadEnvironment not found on environment object.")
        end

        -- Reload ambient sounds just like EDC does to keep everything in sync
        if g_currentMission.ambientSoundSystem ~= nil and g_currentMission.ambientSoundSystem.consoleCommandReload ~= nil then
            g_currentMission.ambientSoundSystem:consoleCommandReload()
        end
    else
        -- If environment is nil, the engine is already rebuilding it!
        print("TornadoPhysics: Environment instance is currently rebuilding (nil). Skipping manual reload invocation.")
    end
    --#endregion

    -- The hotspot was removed in step 2; always re-create it (hidden until the next tornado),
    -- whether or not the environment reload above was available.
    if TornadoHotspot ~= nil and TornadoHotspot.loadMap ~= nil then
        print("TornadoPhysics: Restoring map hotspot...")
        TornadoHotspot:loadMap()
    end

    if TornadoAPI then TornadoAPI:fireDespawnEvent() end
    if TornadoSync ~= nil then TornadoSync:sendTornadoState(false, false) end
    if TornadoOutbreak ~= nil then TornadoOutbreak:onTornadoEnded() end
    if TornadoInsuranceDamage ~= nil and TornadoInsuranceDamage.onTornadoEnded ~= nil then
        TornadoInsuranceDamage:onTornadoEnded()   -- storm damage report now, not after the quiet time
    end

    print("TornadoPhysics: Cleanup complete. Ready for new spawn.")
end

function TornadoPhysics:purgeVehicleVisualArtifacts(vehicle)
    if not vehicle or not vehicle.rootNode or not entityExists(vehicle.rootNode) then
        return
    end

    local root = vehicle.rootNode
    local numChildren = getNumOfChildren(root)

    -- Loop backwards to safely delete child entries from the engine stack
    for i = numChildren - 1, 0, -1 do
        local child = getChildAt(root, i)
        if child and entityExists(child) then
            local name = getName(child) or ""
            local lowerName = string.lower(name)

            -- Targeted precision sweep for your exact asset footprints
            if string.find(lowerName, "smoketrail") or string.find(lowerName, "firetrail") then
                print(string.format("TornadoPhysics: Purging orphaned asset artifact [%s] from vehicle.", name))
                delete(child)
            end
        end
    end
end
