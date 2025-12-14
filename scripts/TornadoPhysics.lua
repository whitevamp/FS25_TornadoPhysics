---@class TornadoPhysics
---@version 107.0 (The Final Polish)
---@description Includes Geo-Fence, Barber Pole Fix, and AutoRepair Patch.

TornadoPhysics = {}

-- =============================================================
-- 1. PHYSICS TUNING
-- =============================================================

local BASE_OUTER_RADIUS = 35.0 
local MIN_SCALE = 0.5
local MAX_SCALE = 5.0
local DESTRUCTION_ZONE_RATIO = 0.2 

-- PURGE SETTINGS
local PURGE_DURATION = 5000 
local BASE_PURGE_INTERVAL = 45000 

-- VEHICLE TUNING
local SUCTION_SPEED_VEHICLE = 50.0 
local LIFT_SPEED_VEHICLE = 12.0
local MASS_PENALTY_FACTOR = 0.8 

-- BALE TUNING
local BALE_ORBIT_SPEED = 20.0 
local BALE_SUCTION_SPEED = 15.0
local BALE_LIFT_SPEED = 10.0 
local CHAOS_FACTOR = 5.0 

-- SAFETY
local HOVER_HEIGHT = 35.0
local MAX_SAFE_SPEED = 35.0 

TornadoPhysics.settings = {
    -- Toggles
    indoor_damage = false,
    outdoor_damage = true,
    lift_bales = true,
    lift_logs = true,
    border_safety = true,
    
    -- Advanced Tuning
    ejection_power = 20.0,
    damage_center = 0.25,
    damage_outer = 0.08,
    heavy_threshold = 3.0,
    geo_fence = 40.0
}

local currentOuterRadius = BASE_OUTER_RADIUS
local currentOuterRadiusSq = BASE_OUTER_RADIUS * BASE_OUTER_RADIUS
local mapScaleFactor = 1.0
local mapBoundary = 8192.0 
local mapInitialized = false

-- MASKS
local LOG_MASK = 8192 + 32 + 2 
local ROOF_MASK = 1 + 2048 + 1048576 + 32 

function TornadoPhysics:loadMap(name)
    self.isActive = true
    self.tornadoNode = nil
    self.lastTornadoPos = nil
    self.debugMode = false
    self.showRing = false
    self.activeNodes = {} 
    self.scanTimer = 0
    self.safetyCache = {} 
    
    self.purgeTimer = 0
    self.purgeInterval = BASE_PURGE_INTERVAL 
    self.isPurging = false

    mapInitialized = false 

    print("--------------------------------------------------")
    print("TORNADO PHYSICS V107.0: GOLD MASTER")
    print("--------------------------------------------------")

    addConsoleCommand("t_status", "Check Status", "consoleStatus", self)
    addConsoleCommand("t_set", "Set Radius", "consoleSet", self)
    addConsoleCommand("t_toggle", "Toggle Features", "consoleToggle", self)
    addConsoleCommand("t_debug", "Toggle Telemetry HUD", "consoleDebug", self)
    addConsoleCommand("t_ring", "Toggle Danger Ring", "consoleRing", self)
    addConsoleCommand("t_randomize", "Force New Scale", "randomizeTornado", self)
    addConsoleCommand("t_border", "Toggle Border Safety", "consoleBorder", self)
end

function TornadoPhysics:deleteMap()
    self.isActive = false
    self.activeNodes = {}
    self.safetyCache = {}
    removeConsoleCommand("t_status")
    removeConsoleCommand("t_set")
    removeConsoleCommand("t_toggle")
    removeConsoleCommand("t_debug")
    removeConsoleCommand("t_ring")
    removeConsoleCommand("t_randomize")
    removeConsoleCommand("t_border")
end

-- =============================================================
-- 2. MAIN LOOP
-- =============================================================

function TornadoPhysics:update(dt)
    if not self.isActive or g_currentMission == nil or not g_currentMission:getIsServer() then return end

    if not mapInitialized then
        self:calculateMapScale()
        mapInitialized = true
    end

    -- PURGE LOGIC
    self.purgeTimer = self.purgeTimer + dt
    if self.isPurging then
        if self.purgeTimer > PURGE_DURATION then
            self.isPurging = false
            self.purgeTimer = 0
            if self.debugMode then print("TORNADO: Purge Complete. Resuming Suction.") end
        end
    else
        if self.purgeTimer > self.purgeInterval then
            self.isPurging = true
            self.purgeTimer = 0
            if self.debugMode then print("TORNADO: Purge Started! EJECTING CONTENTS...") end
        end
    end

    if self.tornadoNode and entityExists(self.tornadoNode) then
        -- valid
    else
        self:findTornadoSimple()
        if not self.tornadoNode then return end
    end

    local tX, tY, tZ = getWorldTranslation(self.tornadoNode)
    if tX == nil then return end 

    if self.lastTornadoPos then
        local jumpDist = MathUtil.vector2Length(tX - self.lastTornadoPos.x, tZ - self.lastTornadoPos.z)
        if jumpDist > 200.0 then
            self.activeNodes = {} 
            self.safetyCache = {}
        end
    end
    self.lastTornadoPos = {x=tX, y=tY, z=tZ}

    self:runPhysicsLoop(dt, tX, tY, tZ)

    if self.showRing then
        self:drawDebugRing(tX, tY, tZ, currentOuterRadius)
    end
    
    -- LINK TO HUSBANDRY (If Installed)
    if TornadoHusbandry and TornadoHusbandry.runCycle then
        TornadoHusbandry:runCycle(dt, tX, tY, tZ, currentOuterRadius)
    end

    -- AUTO-REPAIR SUPPRESSION (The Mod Patch)
    if AutoRepair and self.activeNodes and next(self.activeNodes) then
        -- Reset their timer so they don't repair while we destroy
        if AutoRepair.timer then
            AutoRepair.timer = 0
        end
    end
end

function TornadoPhysics:runPhysicsLoop(dt, tX, tY, tZ)
    local dtSec = dt * 0.001
    if dtSec > 0.04 then dtSec = 0.04 end

    self.activeNodes = {}

    -- VEHICLE SCANNER
    if g_currentMission.vehicleSystem and g_currentMission.vehicleSystem.vehicles then
        for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
            if vehicle and not vehicle.isDeleted and vehicle.rootNode then
                if vehicle ~= g_currentMission.controlledVehicle or vehicle == g_currentMission.controlledVehicle then
                    
                    local isPallet = false
                    if vehicle.isPallet then isPallet = true
                    elseif vehicle.typeName and (string.find(string.lower(vehicle.typeName), "pallet") or string.find(string.lower(vehicle.typeName), "bigbag")) then isPallet = true end

                    if isPallet then
                        if self.settings.lift_bales then
                            self.activeNodes[vehicle.rootNode] = { type = "PALLET", obj = vehicle }
                        end
                    else
                        if not (vehicle.isa and vehicle:isa(Bale)) then 
                            local totalMass = self:getVehicleTotalMass(vehicle)
                            local vType = (vehicle == g_currentMission.controlledVehicle) and "PLAYER" or "VEHICLE"
                            
                            self.activeNodes[vehicle.rootNode] = { type = vType, obj = vehicle, massOverride = totalMass }
                            if vehicle.components then
                                for _, comp in pairs(vehicle.components) do
                                    if comp.node then 
                                        self.activeNodes[comp.node] = { type = vType, obj = vehicle, massOverride = totalMass } 
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- BALE SCANNER
    if self.settings.lift_bales and g_currentMission.itemSystem and g_currentMission.itemSystem.itemsToSave then
        for k, entry in pairs(g_currentMission.itemSystem.itemsToSave) do
            local object = entry.item or k
            if object and type(object) == "table" and object.nodeId and entityExists(object.nodeId) then
                if object.isa and object:isa(Bale) then
                    local bX, bY, bZ = getWorldTranslation(object.nodeId)
                    if bX then
                        local distSq = (tX - bX)^2 + (tZ - bZ)^2
                        if distSq < currentOuterRadiusSq then
                            if not (object.getIsMounted and object:getIsMounted()) then
                                self.activeNodes[object.nodeId] = { type = "BALE", obj = object }
                            end
                        end
                    end
                end
            end
        end
    end

    -- LOG SCANNER
    if self.settings.lift_logs then
        self.scanTimer = (self.scanTimer or 0) + dt
        if self.scanTimer > 100 then
            overlapSphere(tX, tY, tZ, currentOuterRadius, "objectScanCallback", self, 8192 + 32 + 2, true, true, true, false)
            self.scanTimer = 0
        end
    end

    -- APPLY PHYSICS
    for nodeId, data in pairs(self.activeNodes) do
        if entityExists(nodeId) then
            if self.debugMode then 
                local status = self.isPurging and "EJECT" or data.type
                self:drawDebugLabel(nodeId, status) 
            end
            
            I3DUtil.wakeUpObject(nodeId)

            if data.type == "VEHICLE" or data.type == "PLAYER" or data.type == "PALLET" then
                self:applyVehiclePhysics(nodeId, tX, tY, tZ, dtSec, data)
            elseif data.type == "LOG" then
                self:applyLogPhysics(nodeId, tX, tY, tZ, dtSec, data) 
            else
                self:applyBalePhysics(nodeId, tX, tY, tZ, dtSec, data)
            end
        end
    end
end

-- =============================================================
-- 3. PHYSICS ENGINES (GEO-FENCE + CCW FIX)
-- =============================================================

function TornadoPhysics:applyVehiclePhysics(nodeId, tX, tY, tZ, dtSec, data)
    local mass = data.massOverride or getMass(nodeId)
    if mass < 0.001 then return end

    local vX, vY, vZ = getWorldTranslation(nodeId)
    local lVx, lVy, lVz = getLinearVelocity(nodeId)
    if lVx == nil then return end

    -- 0. GEO-FENCE (ABSOLUTE PRIORITY)
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
    local distSq = dx*dx + dz*dz

    -- 1. DISTANCE CHECK 
    if distSq > currentOuterRadiusSq then 
        setLinearDamping(nodeId, 0.05) 
        setAngularDamping(nodeId, 0.05)
        return 
    end

    -- 2. INDOOR CHECK
    if self:checkIsIndoorsCached(nodeId, 2.0) then 
        if MathUtil.vector3Length(lVx, lVy, lVz) < 5.0 then
             setLinearDamping(nodeId, 10.0) 
             setAngularDamping(nodeId, 10.0)
        end
        return 
    end

    local massFactor = 1.0
    if mass > self.settings.heavy_threshold then
        massFactor = 1.0 + ((mass - self.settings.heavy_threshold) * MASS_PENALTY_FACTOR)
    end
    if massFactor > 15.0 then massFactor = 15.0 end

    -- 3. PURGE (EJECTION) LOGIC
    if self.isPurging then
        setLinearDamping(nodeId, 0.05)
        setAngularDamping(nodeId, 0.05)
        
        local dist = math.sqrt(distSq)
        if dist < 1.0 then dist = 1.0 end
        
        local pushX = -dx / dist 
        local pushZ = -dz / dist 
        
        local adjustedPower = self.settings.ejection_power / massFactor
        local forceMag = mass * adjustedPower
        local liftKick = 6.0 / math.sqrt(massFactor)
        
        addForce(nodeId, pushX * forceMag, mass * liftKick, pushZ * forceMag, 0, 0, 0, true)
        return
    end

    -- 4. NORMAL TORNADO PHYSICS (CCW FIX APPLIED)
    setAngularDamping(nodeId, 1.0) 

    local dist = math.sqrt(distSq)
    if dist < 0.1 then dist = 0.1 end
    local dirX = dx / dist
    local dirZ = dz / dist

    local targetVx, targetVz, targetVy = 0, 0, 0
    
    local edgeDist = currentOuterRadius - dist
    local entryFactor = 1.0
    if edgeDist < 20.0 then
        entryFactor = edgeDist / 20.0 
    end
    if entryFactor < 0 then entryFactor = 0 end

    if dist < 20.0 then
        -- COUNTER-CLOCKWISE CENTER
        targetVx = -dirX * 5.0 - (dirZ * 15.0)  
        targetVz = -dirZ * 5.0 + (dirX * 15.0)
        targetVy = LIFT_SPEED_VEHICLE / massFactor
    else
        -- COUNTER-CLOCKWISE SUCTION SPIRAL
        local speed = SUCTION_SPEED_VEHICLE * (dist / currentOuterRadius) * entryFactor
        local rotationSpeed = 10.0 

        targetVx = (dirX * speed) - (dirZ * rotationSpeed)
        targetVz = (dirZ * speed) + (dirX * rotationSpeed)
        targetVy = 0.5 
    end

    if (vY - tY) > HOVER_HEIGHT then targetVy = -5.0 end

    local blend = 5.0 * dtSec * entryFactor
    
    if blend > 0.01 then 
        local newVx = lVx + (targetVx - lVx) * blend
        local newVz = lVz + (targetVz - lVz) * blend
        local newVy = lVy + (targetVy - lVy) * blend
        
        local newSpeed = MathUtil.vector3Length(newVx, newVy, newVz)
        if newSpeed > MAX_SAFE_SPEED then
            local scale = MAX_SAFE_SPEED / newSpeed
            newVx, newVy, newVz = newVx * scale, newVy * scale, newVz * scale
        end
        setLinearVelocity(nodeId, newVx, newVy, newVz)
    end

    -- 5. DAMAGE LOGIC
    local allowDamage = (self.settings.indoor_damage) or (self.settings.outdoor_damage)
    if allowDamage then
        local destructionZoneSq = (currentOuterRadius * DESTRUCTION_ZONE_RATIO)^2
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
            self:applyDamage(data.obj, applyDmg)
        end
    end
end

function TornadoPhysics:applyLogPhysics(nodeId, tX, tY, tZ, dtSec, data)
    local mass = getMass(nodeId)
    if mass == nil or mass < 0.001 then return end
    
    local vX, vY, vZ = getWorldTranslation(nodeId)
    if vX == nil then return end

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
        local dx = tX - vX
        local dz = tZ - vZ
        local dist = MathUtil.vector2Length(dx, dz)
        if dist > 0.1 then
            local pushX = -dx / dist
            local pushZ = -dz / dist
            local adjustedPower = self.settings.ejection_power * 0.8
            local forceMag = mass * adjustedPower
            addForce(nodeId, pushX * forceMag, mass * 4.0, pushZ * forceMag, 0, 0, 0, true)
        end
        return 
    end
    
    setAngularDamping(nodeId, 1.0) 

    local lVx, lVy, lVz = getLinearVelocity(nodeId)
    if lVx == nil then return end

    local dx = tX - vX
    local dz = tZ - vZ
    local dist = MathUtil.vector2Length(dx, dz)
    if dist < 0.1 then dist = 0.1 end
    local dirX = dx / dist
    local dirZ = dz / dist

    local massFactor = 1.0
    if mass > self.settings.heavy_threshold then
        massFactor = 1.0 + ((mass - self.settings.heavy_threshold) * MASS_PENALTY_FACTOR)
    end
    if massFactor > 4.0 then massFactor = 4.0 end

    local targetVx, targetVz, targetVy = 0, 0, 0
    
    if dist < 20.0 then
        -- CCW
        targetVx = -dirX * 5.0 - (dirZ * 15.0)
        targetVz = -dirZ * 5.0 + (dirX * 15.0)
        targetVy = LIFT_SPEED_VEHICLE / massFactor 
    else
        local speed = SUCTION_SPEED_VEHICLE * (dist / currentOuterRadius)
        targetVx = dirX * speed
        targetVz = dirZ * speed
        targetVy = 0.5 
    end

    if (vY - tY) > HOVER_HEIGHT then targetVy = -5.0 end

    local blend = 5.0 * dtSec
    local newVx = lVx + (targetVx - lVx) * blend
    local newVz = lVz + (targetVz - lVz) * blend
    local newVy = lVy + (targetVy - lVy) * blend

    setLinearVelocity(nodeId, newVx, newVy, newVz)
end

function TornadoPhysics:applyBalePhysics(nodeId, tX, tY, tZ, dtSec, data)
    local mass = getMass(nodeId)
    if mass == nil or mass < 0.001 then return end

    local vX, vY, vZ = getWorldTranslation(nodeId)
    if vX == nil then return end

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
        local dx = tX - vX
        local dz = tZ - vZ
        local dist = MathUtil.vector2Length(dx, dz)
        if dist > 0.1 then
            local pushX = -dx / dist
            local pushZ = -dz / dist
            local forceMag = mass * self.settings.ejection_power
            addForce(nodeId, pushX * forceMag, mass * 4.0, pushZ * forceMag, 0, 0, 0, true)
        end
        return 
    end
    
    setAngularDamping(nodeId, 0.1) 

    local lVx, lVy, lVz = getLinearVelocity(nodeId)
    if lVx == nil then return end

    local dx = tX - vX
    local dz = tZ - vZ
    local dist = MathUtil.vector2Length(dx, dz)
    if dist < 0.1 then dist = 0.1 end
    local dirX = dx / dist
    local dirZ = dz / dist

    local targetVx, targetVz, targetVy = 0, 0, 0
    
    if dist < 20.0 then
        -- CCW
        targetVx = -dirX * 5.0 - (dirZ * BALE_ORBIT_SPEED)
        targetVz = -dirZ * 5.0 + (dirX * BALE_ORBIT_SPEED)
        targetVy = BALE_LIFT_SPEED
    else
        local suction = BALE_SUCTION_SPEED * (dist / currentOuterRadius)
        targetVx = dirX * suction
        targetVz = dirZ * suction
        targetVy = 2.0 
    end

    targetVx = targetVx + math.random(-CHAOS_FACTOR, CHAOS_FACTOR)
    targetVz = targetVz + math.random(-CHAOS_FACTOR, CHAOS_FACTOR)
    targetVy = targetVy + math.random(-2.0, 2.0)

    if (vY - tY) > HOVER_HEIGHT then targetVy = -5.0 end

    local blend = 8.0 * dtSec 
    if blend > 1.0 then blend = 1.0 end
    
    local newVx = lVx + (targetVx - lVx) * blend
    local newVz = lVz + (targetVz - lVz) * blend
    local newVy = lVy + (targetVy - lVy) * blend

    local newSpeed = MathUtil.vector3Length(newVx, newVy, newVz)
    if newSpeed > MAX_SAFE_SPEED then
        local scale = MAX_SAFE_SPEED / newSpeed
        newVx, newVy, newVz = newVx * scale, newVy * scale, newVz * scale
    end

    setLinearVelocity(nodeId, newVx, newVy, newVz)
end

-- =============================================================
-- 5. HELPERS & SCALING
-- =============================================================

function TornadoPhysics:checkIsIndoorsCached(nodeId, startHeight)
    local currentTime = g_currentMission.time
    local cache = self.safetyCache[nodeId]

    if cache and currentTime < cache.expireTime then
        return cache.isSafe
    end

    local x, y, z = getWorldTranslation(nodeId)
    if x == nil then return false end
    
    self.raycastResult = false
    
    raycastClosest(x, y+startHeight, z, 0, 1, 0, 30, "raycastCallback", self, ROOF_MASK)
    if not self.raycastResult then
        raycastClosest(x+2.0, y+startHeight, z, 0, 1, 0, 30, "raycastCallback", self, ROOF_MASK)
    end
    if not self.raycastResult then
        raycastClosest(x-2.0, y+startHeight, z, 0, 1, 0, 30, "raycastCallback", self, ROOF_MASK)
    end

    self.safetyCache[nodeId] = {
        isSafe = self.raycastResult,
        expireTime = currentTime + 1000 
    }

    return self.raycastResult
end

-- function TornadoPhysics:calculateMapScale()
--     if g_currentMission and g_currentMission.terrainSize then
--         local size = g_currentMission.terrainSize
--         mapScaleFactor = size / 2048.0
--         if mapScaleFactor < 1.0 then mapScaleFactor = 1.0 end
        
--         mapBoundary = size * 0.5
--         currentOuterRadius = BASE_OUTER_RADIUS * mapScaleFactor
--         currentOuterRadiusSq = currentOuterRadius * currentOuterRadius

--         local extraTime = (mapScaleFactor - 1.0) * 20000
--         self.purgeInterval = BASE_PURGE_INTERVAL + extraTime
        
--         print(string.format("TORNADO SETUP: MapSize=%.0f | Radius=%.1fm | PurgeTime=%.1fs", size, currentOuterRadius, self.purgeInterval/1000))
--     end
-- end
function TornadoPhysics:calculateMapScale()
    if g_currentMission and g_currentMission.terrainSize then
        local size = g_currentMission.terrainSize
        mapScaleFactor = size / 2048.0
        if mapScaleFactor < 1.0 then mapScaleFactor = 1.0 end
        
        mapBoundary = size * 0.5
        currentOuterRadius = BASE_OUTER_RADIUS * mapScaleFactor
        currentOuterRadiusSq = currentOuterRadius * currentOuterRadius

        local extraTime = (mapScaleFactor - 1.0) * 20000 -- Original Purge Time Calculation
        self.purgeInterval = BASE_PURGE_INTERVAL + extraTime
        
        -- NEW: Dynamic Husbandry Immunity Calculation (in milliseconds)
        local baseImmunitySec = 240.0 -- 4 minutes minimum
        local scaleBonusSec = (mapScaleFactor - 1.0) * 300.0
        self.dynamicImmunityMS = (baseImmunitySec + scaleBonusSec) * 1000 
        
        print(string.format("TORNADO SETUP: MapSize=%.0f | Radius=%.1fm | PurgeTime=%.1fs", size, currentOuterRadius, self.purgeInterval/1000))
        print(string.format("TORNADO SETUP: Husbandry Immunity calculated at %.1fs", self.dynamicImmunityMS/1000))
    end
end

function TornadoPhysics:randomizeTornado()
    if self.tornadoNode then
        local scaledBase = BASE_OUTER_RADIUS * mapScaleFactor
        local scale = MIN_SCALE + math.random() * (MAX_SCALE - MIN_SCALE)
        
        setScale(self.tornadoNode, scale, scale, scale)
        currentOuterRadius = scaledBase * scale
        currentOuterRadiusSq = currentOuterRadius * currentOuterRadius
        
        local rating = "EF-0"
        if scale > 1.0 then rating = "EF-1" end
        if scale > 2.0 then rating = "EF-2" end
        if scale > 3.0 then rating = "EF-3" end
        if scale > 4.0 then rating = "EF-4" end
        if scale > 4.8 then rating = "EF-5" end
        
        local msg = string.format("ALERT: TORNADO TOUCHDOWN! (%s | Radius: %dm)", rating, math.floor(currentOuterRadius))
        print(">>> " .. msg)
        
        if g_currentMission then
            g_currentMission:showBlinkingWarning(msg, 5000)
        end
    end
end

function TornadoPhysics:objectScanCallback(nodeId)
    if not entityExists(nodeId) then return true end
    if self.activeNodes[nodeId] then return true end
    if ClassIds and getHasClassId(nodeId, ClassIds.MESH_SPLIT_SHAPE) then
         self.activeNodes[nodeId] = { type = "LOG" }
    end
    return true
end

function TornadoPhysics:drawDebugLabel(nodeId, type)
    local x, y, z = getWorldTranslation(nodeId)
    local vx, vy, vz = getLinearVelocity(nodeId)
    if vx and vy and vz then
        local speed = MathUtil.vector3Length(vx, vy, vz)
        local mass = getMass(nodeId)
        local text = string.format("[%s]\nMass: %.2f\nSpd: %.1f", type, mass or 0, speed)
        Utils.renderTextAtWorldPosition(x, y + 1.5, z, text, 0.012, 0)
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
    if totalMass < 1.0 then totalMass = 5.0 end
    return totalMass
end

function TornadoPhysics:raycastCallback(hitObjectId)
    if hitObjectId ~= 0 then
        self.raycastResult = true
        return false 
    end
    return true
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
                self:randomizeTornado()
                return
            end
        end
    end
end

function TornadoPhysics:applyDamage(vehicle, amount)
    if vehicle == nil then return end

    if vehicle.setDamageAmount and vehicle.getDamageAmount then
        local newDmg = vehicle:getDamageAmount() + amount
        if newDmg > 1.0 then 
            newDmg = 1.0 
            if vehicle.stopMotor then vehicle:stopMotor() end
            if vehicle.setBroken then vehicle:setBroken(true) end
        end
        vehicle:setDamageAmount(newDmg)
    end
    
    if vehicle.setDirtAmount and vehicle.getDirtAmount then
         local newDirt = vehicle:getDirtAmount() + (amount * 5.0)
         if newDirt > 1.0 then newDirt = 1.0 end
         vehicle:setDirtAmount(newDirt)
    end
    
    if vehicle.setWearTotalAmount and vehicle.getWearTotalAmount then
         local newWear = vehicle:getWearTotalAmount() + (amount * 2.0)
         if newWear > 1.0 then newWear = 1.0 end
         vehicle:setWearTotalAmount(newWear)
    end
end

function TornadoPhysics:drawDebugRing(x, y, z, r)
    local steps = 32 
    local h1 = y + 5.0 
    local h2 = y + 60.0 
    
    for i=1, steps do
        local a1 = (i-1)/(steps)*6.28
        local a2 = i/steps*6.28
        local g = self.isPurging and 1.0 or 0.0 
        local r_col = self.isPurging and 0.0 or 1.0
        drawDebugLine(x+math.cos(a1)*r, h1, z+math.sin(a1)*r, r_col,g,0, x+math.cos(a2)*r, h1, z+math.sin(a2)*r, r_col,g,0, x+math.cos(a1)*r, h2, z+math.sin(a1)*r, r_col,g,0, x+math.cos(a2)*r, h2, z+math.sin(a2)*r, r_col,g,0)
    end
end

function TornadoPhysics:consoleStatus()
    local c = 0
    for _ in pairs(self.activeNodes) do c = c + 1 end
    print(string.format("Status: %s | Active: %d | PurgeTimer: %.1f/%.1f", tostring(self.isActive), c, self.purgeTimer/1000, self.purgeInterval/1000))
end

function TornadoPhysics:consoleToggle(k)
    if self.settings[k] ~= nil then 
        self.settings[k] = not self.settings[k] 
        print("Toggled " .. k .. " to " .. tostring(self.settings[k]))
    end
end

function TornadoPhysics:consoleSet(action, value)
    local val = tonumber(value)
    if not val then 
        print("Usage: t_set [radius|power|heavy|fence|dmg_in|dmg_out] [value]")
        return 
    end

    if action == "radius" then
        BASE_OUTER_RADIUS = val
        if self.tornadoNode then
             self:randomizeTornado()
        end
        print(string.format("TornadoPhysics: Base Radius set to %.1f", val))
    elseif action == "power" then
        self.settings.ejection_power = val
        print(string.format("TornadoPhysics: Ejection Power set to %.1f", val))
    elseif action == "heavy" then
        self.settings.heavy_threshold = val
        print(string.format("TornadoPhysics: Heavy Mass Threshold set to %.1ft", val))
    elseif action == "fence" then
        self.settings.geo_fence = val
        print(string.format("TornadoPhysics: Geo-Fence Buffer set to %.1fm", val))
    elseif action == "dmg_in" then
        self.settings.damage_center = val
        print(string.format("TornadoPhysics: Inner Damage Rate set to %.3f", val))
    elseif action == "dmg_out" then
        self.settings.damage_outer = val
        print(string.format("TornadoPhysics: Outer Damage Rate set to %.3f", val))
    else
        print("Unknown setting. Available: radius, power, heavy, fence, dmg_in, dmg_out")
    end
end

function TornadoPhysics:consoleRing()
    self.showRing = not self.showRing
    print("TORNADO PHYSICS: Ring Visible = " .. tostring(self.showRing))
end

function TornadoPhysics:consoleBorder()
    self.settings.border_safety = not self.settings.border_safety
    print("TORNADO PHYSICS: Border Safety = " .. tostring(self.settings.border_safety))
end

function TornadoPhysics:consoleDebug()
    self.debugMode = not self.debugMode
    print("TORNADO PHYSICS: Telemetry Mode = " .. tostring(self.debugMode))
end

addModEventListener(TornadoPhysics)