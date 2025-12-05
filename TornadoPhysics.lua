---@class TornadoPhysics
---@author whitevamp
---@version 29.0
---@description Adds physics interactions to the Farming Simulator 25 Tornado (Twister).
---Handles suction, lift, rotation, and vehicle destruction based on distance and mass.

TornadoPhysics = {}

-- =============================================================
-- CONFIGURATION & TUNING
-- =============================================================

---Distance in meters where suction (drag) begins.
local OUTER_RADIUS = 150.0

---Distance in meters where lift (flight) begins.
local INNER_RADIUS = 30.0

---Horizontal pull strength multiplier.
local SUCTION_POWER = 0.8

---Vertical lift strength multiplier.
---Reduced to 2.5 to prevent "Moon Launches" for heavy equipment.
local LIFT_POWER = 2.5

---Height in meters where lift force fades to zero to create a hover effect.
local MAX_HEIGHT = 25.0

-- =============================================================
-- MOD LIFECYCLE
-- =============================================================

---Called when the map finishes loading.
---Initializes mod state and registers console commands.
---@param name string Map name
function TornadoPhysics:loadMap(name)
self.isActive = true
self.tornadoNode = nil
self.searchTimer = 0

print("--------------------------------------------------")
print("TORNADO PHYSICS V29.0: PRODUCTION READY")
print("Includes: Heavy Mass Tuning, Lag Fixes, LuaDoc.")
print("--------------------------------------------------")

addConsoleCommand("t_status", "Check Physics Status", "consoleStatus", self)
end

---Called when the map is unloaded or game exits.
function TornadoPhysics:deleteMap()
self.isActive = false
removeConsoleCommand("t_status")
end

---Console command to print debug information to the log.
function TornadoPhysics:consoleStatus()
if self.tornadoNode and entityExists(self.tornadoNode) then
    print(string.format("TORNADO: LOCKED (ID %d)", self.tornadoNode))
    else
        print("TORNADO: SEARCHING... (Tornado object not found in scene)")
        end
        end

        -- =============================================================
        -- GAME LOOP
        -- =============================================================

        ---Called every frame (update tick).
        ---@param dt number Delta time in milliseconds
        function TornadoPhysics:update(dt)
        if not self.isActive then return end

            -- Safety check: Ensure vehicle system is loaded
            if g_currentMission == nil or g_currentMission.vehicleSystem == nil then return end

                -- Physics should only run on the Server to prevent network desync
                if not g_currentMission:getIsServer() then return end

                    -- 1. FIND TORNADO
                    -- If we haven't found the tornado yet, scan for it every 2 seconds
                    if self.tornadoNode == nil or not entityExists(self.tornadoNode) then
                        self.searchTimer = self.searchTimer + dt
                        if self.searchTimer > 1000 then
                            self:scanForTwister()
                            self.searchTimer = 0
                            end
                            return
                            end

                            -- 2. PHYSICS LOOP
                            -- Apply wind forces to all active vehicles in the game
                            local tX, tY, tZ = getWorldTranslation(self.tornadoNode)
                            local dtSec = dt * 0.001 -- Convert ms to seconds for physics math

                            for _, vehicle in pairs(g_currentMission.vehicleSystem.vehicles) do
                                if vehicle.components ~= nil then
                                    self:applyPhysicsToVehicle(vehicle, tX, tY, tZ, dtSec)
                                    end
                                    end
                                    end

                                    ---Scans the Engine Root Node for the visual tornado object.
                                    ---Looks for "twister" in the node name (Loose match).
                                    function TornadoPhysics:scanForTwister()
                                    local root = getRootNode()
                                    local count = getNumOfChildren(root)

                                    for i = 0, count - 1 do
                                        local child = getChildAt(root, i)
                                        local name = getName(child)

                                        -- Loose string matching to find "twisterRootNode" or similar variations
                                        if name and string.find(string.lower(name), "twister") then
                                            print("TORNADO PHYSICS: Locked to '" .. name .. "' (ID: " .. tostring(child) .. ")")
                                            self.tornadoNode = child
                                            return
                                            end
                                            end
                                            end

                                            -- =============================================================
                                            -- PHYSICS LOGIC
                                            -- =============================================================

                                            ---Applies wind forces (Impulse) to a specific vehicle.
                                            ---Handles suction, lift, rotation, and damage application.
                                            ---@param vehicle table The vehicle object
                                            ---@param tX number Tornado X position
                                            ---@param tY number Tornado Y position
                                            ---@param tZ number Tornado Z position
                                            ---@param dtSec number Delta time in seconds
                                            function TornadoPhysics:applyPhysicsToVehicle(vehicle, tX, tY, tZ, dtSec)
                                            -- SAFETY: Do not touch vehicles currently in the Shop Config screen
                                            if vehicle.getIsInShowroom and vehicle:getIsInShowroom() then return end

                                                -- OPTIMIZATION: Check distance to root component first to avoid looping parts unnecessarily
                                                if vehicle.components[1] then
                                                    local rX, rY, rZ = getWorldTranslation(vehicle.components[1].node)
                                                    if MathUtil.vector2Length(tX - rX, tZ - rZ) > OUTER_RADIUS then return end
                                                        end

                                                        -- Wake up vehicle physics if it was parked/sleeping
                                                        if vehicle.isSleeping then vehicle:wakeUp() end

                                                            local triggerDamage = false

                                                            -- Loop through all physical components (Body, Wheels, Axles, Tools)
                                                            for _, component in pairs(vehicle.components) do
                                                                local node = component.node

                                                                if node and entityExists(node) then
                                                                    local mass = 1
                                                                    if getMass then mass = getMass(node) end

                                                                        local vX, vY, vZ = getWorldTranslation(node)
                                                                        local dist = MathUtil.vector2Length(tX - vX, tZ - vZ)

                                                                        -- Avoid divide by zero errors
                                                                        if dist < 0.1 then dist = 0.1 end

                                                                            if dist < OUTER_RADIUS then
                                                                                -- Calculate direction vectors
                                                                                local dx = tX - vX
                                                                                local dz = tZ - vZ
                                                                                local dirX = dx / dist
                                                                                local dirZ = dz / dist
                                                                                local tanX = -dirZ -- Perpendicular vector for rotation
                                                                                local tanZ = dirX

                                                                                local impX = 0
                                                                                local impY = 0
                                                                                local impZ = 0

                                                                                local heightDiff = vY - tY

                                                                                -- ZONE 1: LIFT (The Funnel)
                                                                                if dist < INNER_RADIUS then
                                                                                    triggerDamage = true

                                                                                    -- HEIGHT LOGIC (Feathering)
                                                                                    -- Reduces lift as object approaches MAX_HEIGHT to prevent space launches
                                                                                    local heightFactor = 1.0 - (heightDiff / MAX_HEIGHT)
                                                                                    if heightFactor < 0 then heightFactor = 0 end

                                                                                        -- MASS LOGIC (Heavy Weight Tuning)
                                                                                        -- mass^0.7 ensures heavy objects feel heavier than light objects
                                                                                        local adjustedMass = math.pow(mass, 0.7) * 1.5

                                                                                        -- Apply Vertical Lift
                                                                                        -- Formula: Base gravity compensation + (Adjusted Mass * Power * Fade)
                                                                                        impY = (mass * 9.81 * 0.5) + (adjustedMass * 9.81 * LIFT_POWER * heightFactor)
                                                                                        impY = impY * dtSec

                                                                                        -- Apply Chaos Spin (Torque)
                                                                                        if addTorqueImpulse then
                                                                                            local spin = mass * 2.0 * dtSec
                                                                                            addTorqueImpulse(node, math.random(-1,1)*spin, math.random(-1,1)*spin, math.random(-1,1)*spin)
                                                                                            end
                                                                                            else
                                                                                                -- ZONE 2: SUCTION (The Drag)
                                                                                                -- Stronger as you get closer to the center
                                                                                                local strength = 1 + (1 - (dist / OUTER_RADIUS)) * 2
                                                                                                impX = (dirX * SUCTION_POWER * mass * strength * dtSec)
                                                                                                impZ = (dirZ * SUCTION_POWER * mass * strength * dtSec)

                                                                                                -- Tiny lift to reduce tire friction (Hovercraft effect)
                                                                                                if heightDiff < 2.0 then
                                                                                                    impY = (mass * 0.3 * dtSec)
                                                                                                    end
                                                                                                    end

                                                                                                    -- Execute Physics
                                                                                                    addImpulse(node, impX, impY, impZ, 0, 0, 0, true)
                                                                                                    end
                                                                                                    end
                                                                                                    end

                                                                                                    -- DAMAGE APPLICATION
                                                                                                    -- Runs exactly once per vehicle to prevent lag
                                                                                                    if triggerDamage and vehicle.tornadoDamaged == nil then
                                                                                                        -- 1. Visual Dirt
                                                                                                        if vehicle.setDirtAmount then vehicle:setDirtAmount(1) end
                                                                                                            -- 2. Visual Wear (Paint scratches)
                                                                                                            if vehicle.setWearTotalAmount then vehicle:setWearTotalAmount(1) end
                                                                                                                -- 3. HUD Damage Stat (100%)
                                                                                                                if vehicle.setDamageAmount then vehicle:setDamageAmount(1) end
                                                                                                                    -- 4. Mechanical Failure (Engine Stop)
                                                                                                                    if vehicle.setBroken and not vehicle.isBroken then vehicle:setBroken() end

                                                                                                                        -- Flag as damaged so we don't re-run this block
                                                                                                                        vehicle.tornadoDamaged = true
                                                                                                                        end
                                                                                                                        end

                                                                                                                        -- Register the mod listener class
                                                                                                                        addModEventListener(TornadoPhysics)
