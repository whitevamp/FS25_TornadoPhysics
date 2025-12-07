---@class TornadoPhysics
---@version 51.0
---@description Advanced Tornado Physics Mod for Farming Simulator 25.
--- Adds realistic suction, lift, and damage mechanics to the in-game "twister" visual effect.
--- Includes safety checks for buildings, player ejection for motion sickness prevention, and distance-based damage.

TornadoPhysics = {}

-- =============================================================
-- SETTINGS & DEFAULTS
-- =============================================================

---@type number Base radius of the tornado effect in meters.
local BASE_OUTER_RADIUS = 150.0

---@type number Radius within which objects are captured by the "Tractor Beam" logic (Logs).
local GRAB_RADIUS = 30.0

-- PHYSICS TUNING
---@type number Speed at which captured logs rotate around the vortex.
local ROTATION_SPEED = 2.5
---@type number Vertical speed for lifting objects.
local LIFT_SPEED = 3.5
---@type number Height at which logs are released from the vortex.
local RELEASE_HEIGHT = 30.0
---@type number Horizontal suction force multiplier.
local SUCTION_POWER = 0.5
---@type number Vertical lift force multiplier.
local LIFT_POWER = 1.5
---@type number Maximum vertical velocity cap to prevent objects flying into space.
local MAX_UP_SPEED = 12.0

---@class TornadoSettings
---@field indoor_damage boolean If true, vehicles inside buildings will take damage (though physics are disabled).
---@field outdoor_damage boolean If true, vehicles outside will take damage and physics forces.
---@field random_size boolean If true, the tornado scale is randomized upon spawning.
---@field lift_bales boolean If true, bales and pallets are affected by physics.
---@field lift_logs boolean If true, logs are affected by the special "Tractor Beam" physics.
TornadoPhysics.settings = {
    indoor_damage = false, -- Default false
    outdoor_damage = true, -- Default true
    random_size = true, -- Default true
    lift_bales = true, -- Default true
    lift_logs = false -- Default false
}

local MIN_SCALE = 0.5
local MAX_SCALE = 5.0

---@type number Current effective radius (Radius * Scale).
local currentOuterRadius = BASE_OUTER_RADIUS
---@type number Squared radius for optimized distance checks.
local currentOuterRadiusSq = BASE_OUTER_RADIUS * BASE_OUTER_RADIUS

---@type number Collision mask for scanning Dynamic objects (Vehicles, Bales, Logs).
local SCAN_MASK = 63
---@type number Collision mask for scanning Static objects (Roofs, Walls, Terrain).
local ROOF_MASK = 2147483647

---Load the map mod and initialize variables.
---@param name string The name of the map/mission being loaded.
function TornadoPhysics:loadMap(name)
self.isActive = true
self.tornadoNode = nil

self.searchTimer = 0
self.scanTimer = 0
self.rootNodeIndex = 0

---@type table<number, table> List of currently tracked entities (Vehicles/Bales) and their metadata.
self.trackedEntities = {}

---@type table<number, table> Cache for indoor/outdoor status to reduce raycast frequency.
self.safetyCache = {}

---@type table<number, table> List of logs currently caught in the tractor beam animation.
self.capturedLogs = {}

print("--------------------------------------------------")
print("TORNADO PHYSICS V51.0: FINAL RELEASE")
print("--------------------------------------------------")

addConsoleCommand("t_status", "Check Status", "consoleStatus", self)
addConsoleCommand("t_set", "Set Radius", "consoleSet", self)
addConsoleCommand("t_toggle", "Toggle Features", "consoleToggle", self)
addConsoleCommand("t_randomize", "Force Random Size", "consoleRandomize", self)
end

---Clean up resources when the map is unloaded.
function TornadoPhysics:deleteMap()
self.isActive = false
-- Drop all captured logs
for nodeId, _ in pairs(self.capturedLogs) do
    if entityExists(nodeId) then
        link(getRootNode(), nodeId)
        addToPhysics(nodeId)
        setRigidBodyType(nodeId, RigidBodyType.DYNAMIC)
        end
        end
        self.trackedEntities = {}
        self.safetyCache = {}

        removeConsoleCommand("t_status")
        removeConsoleCommand("t_set")
        removeConsoleCommand("t_toggle")
        removeConsoleCommand("t_randomize")
        end

        -- =============================================================
        -- MAIN LOOP
        -- =============================================================

        ---Main update loop called every frame.
        ---@param dt number Delta time in milliseconds.
        function TornadoPhysics:update(dt)
        if not self.isActive or g_currentMission == nil or not g_currentMission:getIsServer() then return end

            -- 1. LOCATE TORNADO
            if self.tornadoNode == nil or not entityExists(self.tornadoNode) then
                self:findTornadoChunked()
                return
                end

                local tX, tY, tZ = getWorldTranslation(self.tornadoNode)
                if tX == nil then return end
                    local dtSec = dt * 0.001

                    -- 2. SCANNER (Runs every 200ms)
                    self.scanTimer = self.scanTimer + dt
                    if self.scanTimer > 200 then
                        overlapSphere(tX, tY, tZ, currentOuterRadius, "objectScanCallback", self, SCAN_MASK, true, true, true, false)
                        self.scanTimer = 0
                        end

                        -- 3. PHYSICS LOOP
                        for nodeId, data in pairs(self.trackedEntities) do
                            if entityExists(nodeId) then
                                data.lifeTime = data.lifeTime - dt

                                -- Countdown Safety Buffer (prevents instant lift on spawn)
                                if data.safetyBuffer > 0 then
                                    data.safetyBuffer = data.safetyBuffer - dtSec
                                    end

                                    -- Remove object if it hasn't been scanned recently (lost tracking)
                                    if data.lifeTime < 0 then
                                        self.trackedEntities[nodeId] = nil
                                        self.safetyCache[nodeId] = nil
                                        else
                                            self:applyPhysicsLogic(nodeId, data, tX, tY, tZ, dtSec)
                                            end
                                            else
                                                self.trackedEntities[nodeId] = nil
                                                end
                                                end

                                                -- 4. LOGS (Tractor Beam Animation)
                                                if self.settings.lift_logs then
                                                    for nodeId, data in pairs(self.capturedLogs) do
                                                        if entityExists(nodeId) then
                                                            self:animateCapturedLog(nodeId, data, dtSec)
                                                            else
                                                                self.capturedLogs[nodeId] = nil
                                                                end
                                                                end
                                                                end
                                                                end

                                                                -- =============================================================
                                                                -- PHYSICS LOGIC
                                                                -- =============================================================

                                                                ---Applies physics forces, damage logic, and player ejection.
                                                                ---@param nodeId number The I3D node ID of the object.
                                                                ---@param data table The metadata table for this object.
                                                                ---@param tX number Tornado X position.
                                                                ---@param tY number Tornado Y position.
                                                                ---@param tZ number Tornado Z position.
                                                                ---@param dtSec number Delta time in seconds.
                                                                function TornadoPhysics:applyPhysicsLogic(nodeId, data, tX, tY, tZ, dtSec)
                                                                local vX, vY, vZ = getWorldTranslation(nodeId)
                                                                local dx = tX - vX
                                                                local dz = tZ - vZ
                                                                local distSq = (dx*dx) + (dz*dz)

                                                                -- Drop if out of range
                                                                if distSq > currentOuterRadiusSq then
                                                                    self.trackedEntities[nodeId] = nil
                                                                    return
                                                                    end

                                                                    local dist = math.sqrt(distSq)
                                                                    if dist < 0.1 then dist = 0.1 end

                                                                        -- == 1. SAFETY BUFFER (2.0s) ==
                                                                        -- Waits for roof check to stabilize before lifting
                                                                        if data.safetyBuffer > 0 then return end

                                                                            -- == 2. UNIVERSAL INDOOR CHECK ==
                                                                            local isIndoors = self:checkIsIndoors(nodeId, data)

                                                                            -- If inside a barn/shed, stop here (unless indoor damage is enabled).
                                                                            if isIndoors and not self.settings.indoor_damage then
                                                                                return
                                                                                end

                                                                                -- == VEHICLE KILL ==
                                                                                -- Kill engine if damage > 90% and outdoors
                                                                                if data.isVehicle and self.settings.outdoor_damage and not isIndoors then
                                                                                    if data.vehicleObj and data.vehicleObj.getDamageAmount and data.vehicleObj:getDamageAmount() > 0.9 then
                                                                                        if data.vehicleObj.stopMotor then
                                                                                            data.vehicleObj:stopMotor()
                                                                                            end
                                                                                            end
                                                                                            end

                                                                                            -- == PHYSICS FORCES ==
                                                                                            local dirX = dx / dist
                                                                                            local dirZ = dz / dist
                                                                                            local strength = 1 + (1 - (dist / currentOuterRadius)) * 2.5

                                                                                            local mass = getMass(nodeId)
                                                                                            local physicsMass = mass
                                                                                            -- Cap mass calculation so heavy tractors still fly
                                                                                            if physicsMass > 10.0 then physicsMass = 10.0 + (mass * 0.1) end

                                                                                                local impX = (dirX * SUCTION_POWER * physicsMass * strength * dtSec)
                                                                                                local impZ = (dirZ * SUCTION_POWER * physicsMass * strength * dtSec)
                                                                                                local impY = 0
                                                                                                local curVx, curVy, curVz = getLinearVelocity(nodeId)

                                                                                                -- LIFT & EJECTION ZONE (< 35m)
                                                                                                if dist < 35.0 then
                                                                                                    -- EJECT PLAYER (Motion Sickness Prevention)
                                                                                                    if data.isVehicle and data.vehicleObj == g_currentMission.controlledVehicle then
                                                                                                        g_currentMission:onLeaveVehicle()
                                                                                                        end

                                                                                                        -- Lift Logic (Anti-Gravity)
                                                                                                        if curVy < MAX_UP_SPEED then
                                                                                                            local gravityComp = physicsMass * 9.81 * dtSec
                                                                                                            local liftForce = physicsMass * 8.0 * LIFT_POWER * dtSec
                                                                                                            impY = gravityComp + liftForce
                                                                                                            end
                                                                                                            -- Random Rotation
                                                                                                            addTorqueImpulse(nodeId, math.random(-2,2)*mass*dtSec, math.random(-2,2)*mass*dtSec, math.random(-2,2)*mass*dtSec)
                                                                                                            else
                                                                                                                -- Outer Edge Hover
                                                                                                                if (vY - tY) < 5.0 then
                                                                                                                    impY = (physicsMass * 4.0 * dtSec)
                                                                                                                    end
                                                                                                                    end

                                                                                                                    addImpulse(nodeId, impX, impY, impZ, 0, 0, 0, true)

                                                                                                                    -- == DISTANCE-BASED DAMAGE ==
                                                                                                                    if data.isVehicle then
                                                                                                                        if (not isIndoors and self.settings.outdoor_damage) or (isIndoors and self.settings.indoor_damage) then
                                                                                                                            data.damageTimer = data.damageTimer + dtSec
                                                                                                                            if data.damageTimer > 1.0 then

                                                                                                                                local percent = dist / currentOuterRadius
                                                                                                                                local dmgAmount = 0.0

                                                                                                                                -- Damage scaling based on proximity
                                                                                                                                if percent < 0.5 then
                                                                                                                                    dmgAmount = 0.05 -- Heavy Damage
                                                                                                                                    elseif percent < 0.8 then
                                                                                                                                        dmgAmount = 0.01 -- Light Damage
                                                                                                                                        else
                                                                                                                                            dmgAmount = 0.0  -- Wind Only
                                                                                                                                            end

                                                                                                                                            if isIndoors then dmgAmount = 0.0005 end

                                                                                                                                                if dmgAmount > 0 then
                                                                                                                                                    self:applyDamage(data.vehicleObj, dmgAmount, false)
                                                                                                                                                    end
                                                                                                                                                    data.damageTimer = 0
                                                                                                                                                    end
                                                                                                                                                    end
                                                                                                                                                    end
                                                                                                                                                    end

                                                                                                                                                    -- =============================================================
                                                                                                                                                    -- UTILS & HELPERS
                                                                                                                                                    -- =============================================================

                                                                                                                                                    ---Checks if an object is underneath a roof using a multi-point raycast.
                                                                                                                                                    ---@param nodeId number The node to check.
                                                                                                                                                    ---@param data table The object metadata (optional, used for vehicle root node optimization).
                                                                                                                                                    ---@return boolean isIndoors True if a roof was detected.
                                                                                                                                                    function TornadoPhysics:checkIsIndoors(nodeId, data)
                                                                                                                                                    local currentTime = g_currentMission.time
                                                                                                                                                    local cache = self.safetyCache[nodeId]

                                                                                                                                                    -- Return cached result if valid
                                                                                                                                                    if cache and currentTime < cache.nextCheck then
                                                                                                                                                        return cache.isIndoors
                                                                                                                                                        end

                                                                                                                                                        local startNode = nodeId
                                                                                                                                                        -- Optimize: Use vehicle root node (center of tractor) if available
                                                                                                                                                        if data and data.isVehicle and data.vehicleObj and data.vehicleObj.rootNode then
                                                                                                                                                            startNode = data.vehicleObj.rootNode
                                                                                                                                                            end

                                                                                                                                                            local vX, vY, vZ = getWorldTranslation(startNode)

                                                                                                                                                            -- Start 2.5m up to clear large Combine headers/axles
                                                                                                                                                            local startHeight = vY + 2.5

                                                                                                                                                            -- 1. Center Check
                                                                                                                                                            if self:fireRay(vX, startHeight, vZ) then
                                                                                                                                                                self:cacheResult(nodeId, true)
                                                                                                                                                                return true
                                                                                                                                                                end

                                                                                                                                                                -- 2. Wide Star Pattern (4.0m offset)
                                                                                                                                                                local offset = 4.0
                                                                                                                                                                if self:fireRay(vX + offset, startHeight, vZ) or
                                                                                                                                                                    self:fireRay(vX - offset, startHeight, vZ) or
                                                                                                                                                                    self:fireRay(vX, startHeight, vZ + offset) or
                                                                                                                                                                    self:fireRay(vX, startHeight, vZ - offset) then

                                                                                                                                                                    self:cacheResult(nodeId, true)
                                                                                                                                                                    return true
                                                                                                                                                                    end

                                                                                                                                                                    self:cacheResult(nodeId, false)
                                                                                                                                                                    return false
                                                                                                                                                                    end

                                                                                                                                                                    ---Fires a single raycast upwards to check for a roof.
                                                                                                                                                                    ---@param x number X world position.
                                                                                                                                                                    ---@param y number Y world position.
                                                                                                                                                                    ---@param z number Z world position.
                                                                                                                                                                    ---@return boolean hit True if a STATIC object (roof) was hit.
                                                                                                                                                                    function TornadoPhysics:fireRay(x, y, z)
                                                                                                                                                                    self.raycastHit = false
                                                                                                                                                                    -- Shoot 50m up to find high barn roofs
                                                                                                                                                                    raycastClosest(x, y, z, 0, 1, 0, 50, "raycastCallback", self, ROOF_MASK)
                                                                                                                                                                    return self.raycastHit
                                                                                                                                                                    end

                                                                                                                                                                    ---Caches the indoor/outdoor result for 1 second.
                                                                                                                                                                    ---@param nodeId number Object ID.
                                                                                                                                                                    ---@param isSafe boolean Is the object indoors?
                                                                                                                                                                    function TornadoPhysics:cacheResult(nodeId, isSafe)
                                                                                                                                                                    self.safetyCache[nodeId] = {
                                                                                                                                                                        isIndoors = isSafe,
                                                                                                                                                                        nextCheck = g_currentMission.time + 1000 + math.random(0, 200)
                                                                                                                                                                    }
                                                                                                                                                                    end

                                                                                                                                                                    ---Raycast listener callback.
                                                                                                                                                                    ---@param hitObjectId number The object hit by the ray.
                                                                                                                                                                    function TornadoPhysics:raycastCallback(hitObjectId)
                                                                                                                                                                    if hitObjectId ~= 0 then
                                                                                                                                                                        -- Only accept STATIC objects (Buildings) as roofs.
                                                                                                                                                                        if getRigidBodyType(hitObjectId) == RigidBodyType.STATIC then
                                                                                                                                                                            self.raycastHit = true
                                                                                                                                                                            return false -- Stop raycast
                                                                                                                                                                            end
                                                                                                                                                                            end
                                                                                                                                                                            return true -- Continue raycast through dynamic objects
                                                                                                                                                                            end

                                                                                                                                                                            ---Applies damage to a vehicle.
                                                                                                                                                                            ---@param vehicle table The vehicle object.
                                                                                                                                                                            ---@param amount number Damage amount (0.0 to 1.0).
                                                                                                                                                                            ---@param safeMode boolean If true, prevents critical failure.
                                                                                                                                                                            function TornadoPhysics:applyDamage(vehicle, amount, safeMode)
                                                                                                                                                                            if vehicle.setDirtAmount then vehicle:setDirtAmount(1) end
                                                                                                                                                                                if vehicle.setDamageAmount and vehicle.getDamageAmount then
                                                                                                                                                                                    local newDmg = vehicle:getDamageAmount() + amount
                                                                                                                                                                                    if newDmg > 1 then newDmg = 1 end
                                                                                                                                                                                        vehicle:setDamageAmount(newDmg)
                                                                                                                                                                                        end
                                                                                                                                                                                        end

                                                                                                                                                                                        ---Scans the scenegraph in chunks to find the tornado visual effect.
                                                                                                                                                                                        ---Optimized to prevent FPS lag.
                                                                                                                                                                                        function TornadoPhysics:findTornadoChunked()
                                                                                                                                                                                        local root = getRootNode()
                                                                                                                                                                                        local numChildren = getNumOfChildren(root)
                                                                                                                                                                                        if self.rootNodeIndex >= numChildren then self.rootNodeIndex = 0 end
                                                                                                                                                                                            local endIndex = math.min(self.rootNodeIndex + 200, numChildren - 1)

                                                                                                                                                                                            for i = self.rootNodeIndex, endIndex do
                                                                                                                                                                                                local child = getChildAt(root, i)
                                                                                                                                                                                                local name = getName(child)
                                                                                                                                                                                                if name and string.find(string.lower(name), "twister") then
                                                                                                                                                                                                    print("TORNADO PHYSICS: Locked to '" .. name .. "'")
                                                                                                                                                                                                    self.tornadoNode = child
                                                                                                                                                                                                    if self.settings.random_size then self:randomizeTornado() end
                                                                                                                                                                                                        return
                                                                                                                                                                                                        end
                                                                                                                                                                                                        end
                                                                                                                                                                                                        self.rootNodeIndex = endIndex + 1
                                                                                                                                                                                                        end

                                                                                                                                                                                                        ---Callback for the overlapSphere scanner.
                                                                                                                                                                                                        ---@param nodeId number Object detected by scanner.
                                                                                                                                                                                                        function TornadoPhysics:objectScanCallback(nodeId)
                                                                                                                                                                                                        if not entityExists(nodeId) then return true end

                                                                                                                                                                                                            -- LOGS
                                                                                                                                                                                                            if self.settings.lift_logs and ClassIds and getHasClassId(nodeId, ClassIds.MESH_SPLIT_SHAPE) then
                                                                                                                                                                                                                local objectId = getSplitType(nodeId)
                                                                                                                                                                                                                local bodyType = getRigidBodyType(nodeId)
                                                                                                                                                                                                                if objectId ~= 0 and bodyType ~= RigidBodyType.STATIC then
                                                                                                                                                                                                                    if self.capturedLogs[nodeId] == nil then
                                                                                                                                                                                                                        local tX, tY, tZ = getWorldTranslation(self.tornadoNode)
                                                                                                                                                                                                                        local vX, vY, vZ = getWorldTranslation(nodeId)
                                                                                                                                                                                                                        local dist = MathUtil.vector2Length(tX - vX, tZ - vZ)
                                                                                                                                                                                                                        if dist < GRAB_RADIUS then
                                                                                                                                                                                                                            if not self.settings.indoor_damage then
                                                                                                                                                                                                                                -- Quick check for logs (start 2.0m up)
                                                                                                                                                                                                                                if self:fireRay(vX, vY + 2.0, vZ) then return true end
                                                                                                                                                                                                                                    end
                                                                                                                                                                                                                                    self:captureLog(nodeId, dist)
                                                                                                                                                                                                                                    self.trackedEntities[nodeId] = nil
                                                                                                                                                                                                                                    end
                                                                                                                                                                                                                                    end
                                                                                                                                                                                                                                    end
                                                                                                                                                                                                                                    return true
                                                                                                                                                                                                                                    end

                                                                                                                                                                                                                                    -- VEHICLES / BALES
                                                                                                                                                                                                                                    if getRigidBodyType(nodeId) == RigidBodyType.DYNAMIC then
                                                                                                                                                                                                                                        local mass = getMass(nodeId)
                                                                                                                                                                                                                                        if mass < 0.05 then return true end

                                                                                                                                                                                                                                            local isVehicle = false
                                                                                                                                                                                                                                            local object = g_currentMission:getNodeObject(nodeId)
                                                                                                                                                                                                                                            if object ~= nil and object.isa and object:isa(Vehicle) then
                                                                                                                                                                                                                                                isVehicle = true
                                                                                                                                                                                                                                                if object.getIsInShowroom and object:getIsInShowroom() then return true end
                                                                                                                                                                                                                                                    end

                                                                                                                                                                                                                                                    if not isVehicle and not self.settings.lift_bales then return true end

                                                                                                                                                                                                                                                        local tX, tY, tZ = getWorldTranslation(self.tornadoNode)
                                                                                                                                                                                                                                                        local vX, vY, vZ = getWorldTranslation(nodeId)
                                                                                                                                                                                                                                                        local dist = MathUtil.vector2Length(tX - vX, tZ - vZ)

                                                                                                                                                                                                                                                        if dist > currentOuterRadius then return true end

                                                                                                                                                                                                                                                            if self.trackedEntities[nodeId] == nil then
                                                                                                                                                                                                                                                                self.trackedEntities[nodeId] = {
                                                                                                                                                                                                                                                                isVehicle = isVehicle,
                                                                                                                                                                                                                                                                vehicleObj = isVehicle and object or nil,
                                                                                                                                                                                                                                                                lifeTime = 1000,
                                                                                                                                                                                                                                                                damageTimer = 0,
                                                                                                                                                                                                                                                                safetyBuffer = 2.0 -- 2.0s Safety Buffer on detection
                                                                                                                                                                                                                                                                }
                                                                                                                                                                                                                                                                I3DUtil.wakeUpObject(nodeId)
                                                                                                                                                                                                                                                                else
                                                                                                                                                                                                                                                                self.trackedEntities[nodeId].lifeTime = 1000
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                return true
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                ---Animates captured logs in a circular pattern.
                                                                                                                                                                                                                                                                function TornadoPhysics:animateCapturedLog(nodeId, data, dtSec)
                                                                                                                                                                                                                                                                data.angle = data.angle + (ROTATION_SPEED * dtSec)
                                                                                                                                                                                                                                                                data.height = data.height + (LIFT_SPEED * dtSec)
                                                                                                                                                                                                                                                                data.radius = math.max(3.0, data.radius - (2.0 * dtSec))
                                                                                                                                                                                                                                                                local lx = math.cos(data.angle) * data.radius
                                                                                                                                                                                                                                                                local lz = math.sin(data.angle) * data.radius
                                                                                                                                                                                                                                                                setTranslation(nodeId, lx, data.height, lz)
                                                                                                                                                                                                                                                                if data.height > RELEASE_HEIGHT then self:releaseLog(nodeId) end
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                ---Captures a log into the tractor beam.
                                                                                                                                                                                                                                                                function TornadoPhysics:captureLog(nodeId, dist)
                                                                                                                                                                                                                                                                removeFromPhysics(nodeId)
                                                                                                                                                                                                                                                                link(self.tornadoNode, nodeId)
                                                                                                                                                                                                                                                                self.capturedLogs[nodeId] = { angle = math.random()*6.28, radius = dist, height = 1.0 }
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                ---Releases a log back to physics.
                                                                                                                                                                                                                                                                function TornadoPhysics:releaseLog(nodeId)
                                                                                                                                                                                                                                                                link(getRootNode(), nodeId)
                                                                                                                                                                                                                                                                addToPhysics(nodeId)
                                                                                                                                                                                                                                                                setRigidBodyType(nodeId, RigidBodyType.DYNAMIC)
                                                                                                                                                                                                                                                                local mass = getMass(nodeId)
                                                                                                                                                                                                                                                                addImpulse(nodeId, math.random(-2,2)*mass, 2*mass, math.random(-2,2)*mass, 0, 0, 0, true)
                                                                                                                                                                                                                                                                self.capturedLogs[nodeId] = nil
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                ---Console command: Prints active tracking stats.
                                                                                                                                                                                                                                                                function TornadoPhysics:consoleStatus()
                                                                                                                                                                                                                                                                local count = 0
                                                                                                                                                                                                                                                                for _ in pairs(self.trackedEntities) do count = count + 1 end
                                                                                                                                                                                                                                                                print(string.format("Active: %s | Radius: %.1f | Tracked: %d | Index: %d", tostring(self.isActive), currentOuterRadius, count, self.rootNodeIndex))
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                ---Console command: Sets physics parameters.
                                                                                                                                                                                                                                                                function TornadoPhysics:consoleSet(action, value)
                                                                                                                                                                                                                                                                local val = tonumber(value)
                                                                                                                                                                                                                                                                if not val then return end
                                                                                                                                                                                                                                                                if action == "radius" then
                                                                                                                                                                                                                                                                BASE_OUTER_RADIUS = val
                                                                                                                                                                                                                                                                self:randomizeTornado()
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                ---Console command: Toggles boolean settings.
                                                                                                                                                                                                                                                                function TornadoPhysics:consoleToggle(setting)
                                                                                                                                                                                                                                                                if self.settings[setting] ~= nil then
                                                                                                                                                                                                                                                                self.settings[setting] = not self.settings[setting]
                                                                                                                                                                                                                                                                print(string.format(">> Toggled '%s' to: %s", setting, tostring(self.settings[setting])))
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                ---Console command: Forces a new random size.
                                                                                                                                                                                                                                                                function TornadoPhysics:consoleRandomize()
                                                                                                                                                                                                                                                                self:randomizeTornado()
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                ---Randomizes tornado scale and effective radius.
                                                                                                                                                                                                                                                                function TornadoPhysics:randomizeTornado()
                                                                                                                                                                                                                                                                if self.tornadoNode then
                                                                                                                                                                                                                                                                local scale = MIN_SCALE + math.random() * (MAX_SCALE - MIN_SCALE)
                                                                                                                                                                                                                                                                setScale(self.tornadoNode, scale, scale, scale)
                                                                                                                                                                                                                                                                currentOuterRadius = BASE_OUTER_RADIUS * scale
                                                                                                                                                                                                                                                                currentOuterRadiusSq = currentOuterRadius * currentOuterRadius
                                                                                                                                                                                                                                                                print(string.format(">>> TORNADO RANDOMIZED: Scale %.2fx | Radius %.1f", scale, currentOuterRadius))
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                                end

                                                                                                                                                                                                                                                                addModEventListener(TornadoPhysics)
