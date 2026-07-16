---@class TornadoEffects
---@version 33.1 (OPTIMIZED CINEMATIC)
---@description Manages delayed fire, smoke longevity, and smooth fading transitions.
---Restored initialization separation for better performance.

TornadoEffects = {}
TornadoEffects.i3dFilename = nil
TornadoEffects.fireI3dFilename = nil
TornadoEffects.activeEffects = {}

-- =========================
-- CINEMATIC CONFIGURATION
-- =========================
TornadoEffects.CONFIG = {
    -- TIMING (Milliseconds)
    SMOKE_LIFE_NORMAL   = 60000,  -- Smoke lasts 60s after leaving tornado
    SMOKE_LIFE_FIRE     = 120000, -- Smoke lasts 120s if vehicle catches fire
    
    FIRE_DELAY_START    = 30000,  -- Fire starts 30s AFTER leaving tornado
    FIRE_DURATION       = 60000,  -- Fire burns for 60s

    FADE_TIME           = 5000,   -- Takes 5s to fade in/out smoothly

    -- LOGIC
    RANDOM_FIRE_MODE    = true,   -- true = 50/50 chance; false = ALL engines burn if damaged
    FIRE_CHANCE         = 0.50,   -- 50% chance if RANDOM_MODE is true

    -- VISUALS (Smoke)
    rotateSpeed = 0.005,
    smokeScale  = {3.0, 8.0, 3.0},
    smokeColor  = {0.1, 0.1, 0.1},
    smokeParams = {3.0, 8.0, 1.0, 0.0}, -- Width/Noise
    smokeAtlas  = {15.0, 20.0, 16.0, 4.0}, -- Play Speed / Atlas Size

    -- VISUALS (Fire)
    fireScale   = {0.6, 0.6, 0.6},
    fireOffset  = {0.0, 0.3, 0.0},
    fireColor   = {1.0, 0.55, 0.15},
    fireParams  = {1.2, 2.0, 1.0, 0.0},
    fireAtlas   = {25.0, 35.0, 8.0, 8.0}
}

function TornadoEffects:loadMap(name, baseDir)
    local dir = baseDir or g_currentModDirectory
    self.i3dFilename = Utils.getFilename("FX/smokeTrailSubUV.i3d", dir)
    self.fireI3dFilename = Utils.getFilename("FX/FireTrailSubUV.i3d", dir)
    self.activeEffects = {}

    -- Baseline the tracking anchors so they are numbers, not nil on frame 1
    if g_currentMission and g_currentMission.environment then
        self.lastAbsoluteTime = g_currentMission.environment.dayTime or 0
        self.lastTrackedDay = g_currentMission.environment.currentDay or 1
    else
        self.lastAbsoluteTime = 0
        self.lastTrackedDay = 1
    end

    if TornadoDebug then TornadoDebug:info("FX", "V33.1 Initialized (Optimized Cinematic)") end
end

function TornadoEffects:deleteMap()
    for _, effect in pairs(self.activeEffects) do
        self:cleanupEffectNodes(effect)
    end
    self.activeEffects = {}
end

function TornadoEffects:cleanupEffectNodes(effect)
    if effect.smokeNode and entityExists(effect.smokeNode) then delete(effect.smokeNode) end
    if effect.fireNode and entityExists(effect.fireNode) then delete(effect.fireNode) end
    effect.smokeNode = nil
    effect.fireNode = nil
end

-- =========================
-- MAIN LOOP
-- =========================
function TornadoEffects:update(dt)
    local currentTime = g_currentMission.time
    
    -- Safety check: Ensure the environment is ready
    if not g_currentMission or not g_currentMission.environment then
        return
    end

    local currentAbsTime = g_currentMission.environment.dayTime
    local currentDay = g_currentMission.environment.currentDay
    local timeSkipDetected = false

    -- Detect Day/Month/Season jumps
    if currentDay ~= self.lastTrackedDay then
        local daysSkipped = currentDay - self.lastTrackedDay
        if daysSkipped > 1 or daysSkipped < 0 then
            timeSkipDetected = true
        end
    end

    -- Detect intra-day fast-forward jumps (e.g., changing hour via EDC)
    local absoluteDelta = currentAbsTime - self.lastAbsoluteTime
    if absoluteDelta < 0 then
        absoluteDelta = absoluteDelta + 86400000 -- Account for midnight wrap
    end

    local expectedMaxDelta = dt * g_currentMission.missionInfo.timeScale * 2
    if absoluteDelta > expectedMaxDelta then
        timeSkipDetected = true
    end

    -- ==========================================================
    -- THE FLUSH FIX
    -- ==========================================================
    if timeSkipDetected then
        -- Loop through your active tracking tables and kill/fade lingering FX
        for id, fxInstance in pairs(self.activeEffects or {}) do 
            -- Option A: Hard cut (Instant delete from scene graph)
            if fxInstance.node and entityExists(fxInstance.node) then
                delete(fxInstance.node)
            end
            
            -- Option B: Force immediate fade/dissipation status
            -- fxInstance.alpha = 0
            -- fxInstance.lifetime = 0
            
            -- Clear the reference tracker
            self.activeEffects[id] = nil
        end
        
        -- Sync anchors immediately so the rest of the frame processes normally
        self.lastAbsoluteTime = currentAbsTime
        self.lastTrackedDay = currentDay
        return -- Exit early for this frame since everything was flushed
    end

    -- Update your anchors for normal frame-by-frame progression
    self.lastAbsoluteTime = currentAbsTime
    self.lastTrackedDay = currentDay

    for vehicleId, effect in pairs(self.activeEffects) do
        -- 1. VEHICLE CHECK
        if not entityExists(vehicleId) then
            self:cleanupEffectNodes(effect)
            self.activeEffects[vehicleId] = nil
        else
            -- 2. UPDATE POSITIONS
            local vx, vy, vz = getWorldTranslation(vehicleId)
            self:updateNodeTransform(effect.smokeNode, vx, vy, vz, 0, 0, 0, dt)
            self:updateNodeTransform(effect.fireNode, vx, vy, vz, 
                self.CONFIG.fireOffset[1], self.CONFIG.fireOffset[2], self.CONFIG.fireOffset[3], dt)

            -- 3. TIMELINE LOGIC
            local timeSinceContact = currentTime - effect.lastContactTime
            
            -- A. SMOKE FADING
            local targetSmokeAlpha = 0.0
            local smokeLife = effect.willBurn and self.CONFIG.SMOKE_LIFE_FIRE or self.CONFIG.SMOKE_LIFE_NORMAL
            
            -- If we are IN the tornado (timeSince < 100ms) or within the smoke life window
            if timeSinceContact < smokeLife then
                targetSmokeAlpha = 1.0
            end

            -- B. FIRE FADING (Delayed Ignition)
            local targetFireAlpha = 0.0
            if effect.willBurn then
                -- Check if we are in the "Burn Window"
                -- Window: Starts at DELAY, Ends at DELAY + DURATION
                local fireStart = self.CONFIG.FIRE_DELAY_START
                local fireEnd = fireStart + self.CONFIG.FIRE_DURATION

                if timeSinceContact > fireStart and timeSinceContact < fireEnd then
                    targetFireAlpha = 1.0
                end
            end

            -- 4. APPLY FADING (Smooth Transition)
            local fadeStep = dt / self.CONFIG.FADE_TIME -- Calculate step to fade over 5 seconds
            effect.smokeAlpha = self:approach(effect.smokeAlpha, targetSmokeAlpha, fadeStep)
            effect.fireAlpha = self:approach(effect.fireAlpha, targetFireAlpha, fadeStep)

            -- 5. VISUAL UPDATES
            -- Only spawn/delete based on need to save performance
            if effect.smokeAlpha > 0.01 then
                if not effect.smokeNode then effect.smokeNode = self:spawnSmoke(vx, vy, vz) end
                self:applyOpacity(effect.smokeNode, effect.smokeAlpha, "smoke")
            elseif effect.smokeNode and timeSinceContact > smokeLife then
                -- Delete only if alpha is zero AND time is up
                delete(effect.smokeNode)
                effect.smokeNode = nil
            end

            if effect.fireAlpha > 0.01 then
                if not effect.fireNode then effect.fireNode = self:spawnFire(vx, vy, vz) end
                self:applyOpacity(effect.fireNode, effect.fireAlpha, "fire")
            elseif effect.fireNode then
                 delete(effect.fireNode)
                 effect.fireNode = nil
            end

            -- 6. GARBAGE COLLECTION
            -- If both nodes are gone and we are past the max duration, remove from list
            local maxDuration = self.CONFIG.SMOKE_LIFE_FIRE + self.CONFIG.FADE_TIME
            if not effect.smokeNode and not effect.fireNode and timeSinceContact > maxDuration then
                self.activeEffects[vehicleId] = nil
            end
        end
    end
end

-- =========================
-- API
-- =========================

-- Called continuously while inside the tornado
function TornadoEffects:playDamageEffect(vehicleId, tornadoId, radius)
    if not entityExists(vehicleId) then return end

    local effect = self.activeEffects[vehicleId]
    if not effect then
        effect = {
            lastContactTime = 0,
            smokeAlpha = 0.0,
            fireAlpha = 0.0,
            willBurn = false,
            smokeNode = nil,
            fireNode = nil
        }
        self.activeEffects[vehicleId] = effect
    end

    -- Keep resetting the contact time while inside the storm
    effect.lastContactTime = g_currentMission.time
end

-- Called ONCE when damage threshold is met
function TornadoEffects:igniteVehicle(vehicleId)
    if not entityExists(vehicleId) then return end

    local effect = self.activeEffects[vehicleId]
    if not effect then
        -- Create effect if it doesn't exist yet (rare, but possible)
        self:playDamageEffect(vehicleId)
        effect = self.activeEffects[vehicleId]
    end

    -- DECIDE FATE: Random or Guaranteed?
    if not effect.willBurn then
        local ignite = true
        if self.CONFIG.RANDOM_FIRE_MODE then
            ignite = math.random() < self.CONFIG.FIRE_CHANCE
        end
        
        if ignite then
            effect.willBurn = true
            if TornadoDebug then TornadoDebug:log("FX", "Vehicle marked for Delayed Ignition: " .. getName(vehicleId)) end
        end
    end
end

-- =========================
-- HELPERS
-- =========================
function TornadoEffects:approach(current, target, step)
    if current < target then
        return math.min(current + step, target)
    elseif current > target then
        return math.max(current - step, target)
    end
    return target
end

function TornadoEffects:updateNodeTransform(node, x, y, z, ox, oy, oz, dt)
    if node and entityExists(node) then
        setTranslation(node, x + ox, y + oy, z + oz)
        rotate(node, 0, self.CONFIG.rotateSpeed * dt, 0)
    end
end

function TornadoEffects:spawnSmoke(x, y, z)
    return self:spawnFX(self.i3dFilename, x, y, z, self.CONFIG.smokeScale, "smoke")
end

function TornadoEffects:spawnFire(x, y, z)
    return self:spawnFX(self.fireI3dFilename, x, y, z, self.CONFIG.fireScale, "fire")
end

function TornadoEffects:spawnFX(filename, x, y, z, scale, type)
    if not filename then return nil end
    local root = loadI3DFile(filename, false, true, false)
    if root ~= 0 then
        link(getRootNode(), root)
        setTranslation(root, x, y, z)
        setScale(root, scale[1], scale[2], scale[3])
        
        -- [RESTORED] Init Static Params ONCE
        self:initShaderParams(root, type)
        
        -- Start invisible
        self:applyOpacity(root, 0.0, type)
        return root
    end
    return nil
end

-- SEPARATE INIT FUNCTION (Optimized)
function TornadoEffects:initShaderParams(node, type)
    if not node or not entityExists(node) then return end
    
    local c = (type == "smoke") and self.CONFIG.smokeColor or self.CONFIG.fireColor
    local p = (type == "smoke") and self.CONFIG.smokeParams or self.CONFIG.fireParams
    local a = (type == "smoke") and self.CONFIG.smokeAtlas or self.CONFIG.fireAtlas

    if getHasClassId(node, ClassIds.SHAPE) then
        -- Set Static Values (Color, Width, PlaySpeed)
        setShaderParameter(node, "colorAlpha", c[1], c[2], c[3], 0.0, false)
        setShaderParameter(node, "widthScale", p[1], p[2], p[3], p[4], false)
        setShaderParameter(node, "playScale", a[1], a[2], a[3], a[4], false)
    end

    for i = 0, getNumOfChildren(node) - 1 do
        self:initShaderParams(getChildAt(node, i), type)
    end
end

-- [OPTIMIZED] Only updates Alpha
function TornadoEffects:applyOpacity(node, alpha, type)
    if not node or not entityExists(node) then return end
    
    local c = (type == "smoke") and self.CONFIG.smokeColor or self.CONFIG.fireColor

    if getHasClassId(node, ClassIds.SHAPE) then
        -- Only update the Alpha channel
        setShaderParameter(node, "colorAlpha", c[1], c[2], c[3], alpha, false)
    end

    for i = 0, getNumOfChildren(node) - 1 do
        self:applyOpacity(getChildAt(node, i), alpha, type)
    end
end