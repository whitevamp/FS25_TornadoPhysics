---@class TornadoTraffic
---@version 1.0
---@description Stops AI road traffic before it drives into the tornado.
--- FS25 traffic is simulated by the engine; Lua cannot steer individual cars or change their
--- routes. What the engine does offer is the same "blocking position" mechanism traffic lights and
--- railroad crossings use: a point on a traffic lane where cars wait until it is released.
---
--- How it works:
---   1. Once per map, every traffic lane (spline) is sampled every SAMPLE_SPACING metres.
---   2. While a tornado is on the ground, a keep-out circle (outer radius + bufferDistance) follows it.
---   3. For each lane that enters the circle, a blocking position is switched on at the last sample
---      before the entry point, so cars queue outside the storm like at a red light.
---   4. Blocks are moved as the tornado moves and all released when it is gone or the feature is off.
--- Cars already inside the circle are not blocked (they drive out of it).
--- Server only: the traffic system is simulated on the server and streamed to clients.

TornadoTraffic = {}

-- Settings (saved by TornadoSettings, changed via t_set traffic / control panel)
TornadoTraffic.isEnabled = true
TornadoTraffic.bufferDistance = 40       -- metres beyond the tornado's outer radius

-- Tuning
TornadoTraffic.SAMPLE_SPACING = 10       -- metres between lane samples
TornadoTraffic.UPDATE_INTERVAL = 1000    -- ms between block recalculations
TornadoTraffic.BLOCK_SEARCH_DISTANCE = 2 -- metres, same tolerance the railroad crossings use

function TornadoTraffic:loadMap()
    self.lanes = nil          -- built lazily once the traffic system exists
    self.activeBlocks = {}    -- key -> { splineId, splineTime, x, y, z }
    self.blockInfoCache = {}  -- key -> { splineId, splineTime } or false when no lane was found
    self.updateTimer = 0

    if TornadoDebug then TornadoDebug:info("TRAFFIC", "V1.0 Initialized (Traffic Roadblocks)") end
end

function TornadoTraffic:deleteMap()
    self:releaseAll()
    self.lanes = nil
    self.blockInfoCache = {}
end

-- =========================================================================
-- HELPERS
-- =========================================================================

--- Returns the traffic system id, or nil when the map has no (or a disabled) traffic system.
function TornadoTraffic:getTrafficSystemId()
    if g_currentMission == nil or g_currentMission.getTrafficSystem == nil then
        return nil
    end
    local trafficSystem = g_currentMission:getTrafficSystem()
    if trafficSystem == nil or trafficSystem.trafficSystemId == nil or trafficSystem.rootNodeId == nil then
        return nil
    end
    return trafficSystem.trafficSystemId, trafficSystem.rootNodeId
end

--- Samples every traffic lane once. Each lane keeps a bounding box so far-away lanes are skipped cheaply.
function TornadoTraffic:buildLaneCache(rootNodeId)
    self.lanes = {}
    local spacing = self.SAMPLE_SPACING
    local numSamples = 0

    I3DUtil.iterateRecursively(rootNodeId, function(node)
        if I3DUtil.getIsSpline(node) then
            local length = getSplineLength(node)
            local steps = math.max(1, math.floor(length / spacing))
            local lane = { spline = node, samples = {} }
            local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge

            for i = 0, steps do
                local t = i / steps
                local x, y, z = getSplinePosition(node, t)
                lane.samples[#lane.samples + 1] = { t = t, x = x, y = y, z = z }
                minX, maxX = math.min(minX, x), math.max(maxX, x)
                minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
            end

            lane.minX, lane.maxX, lane.minZ, lane.maxZ = minX, maxX, minZ, maxZ
            self.lanes[#self.lanes + 1] = lane
            numSamples = numSamples + #lane.samples
        end
    end)

    if TornadoDebug then
        TornadoDebug:info("TRAFFIC", string.format("Lane cache built: %d lanes, %d samples.", #self.lanes, numSamples))
    end
end

--- Engine lane id/time for a sample, looked up once and cached.
function TornadoTraffic:getBlockInfo(trafficSystemId, lane, sampleIndex, key)
    local cached = self.blockInfoCache[key]
    if cached ~= nil then
        return cached
    end

    local sample = lane.samples[sampleIndex]
    local dx, dy, dz = getSplineDirection(lane.spline, sample.t)
    local splineId, splineTime = findTrafficSystemBlockingPositionInformation(trafficSystemId,
        sample.x, sample.y, sample.z, dx, dy, dz, self.BLOCK_SEARCH_DISTANCE)

    local info = false
    if splineId ~= nil and splineId ~= 0 then
        info = { splineId = splineId, splineTime = splineTime }
    end
    self.blockInfoCache[key] = info
    return info
end

function TornadoTraffic:releaseAll()
    local trafficSystemId = self:getTrafficSystemId()
    if trafficSystemId ~= nil and self.activeBlocks ~= nil then
        for _, block in pairs(self.activeBlocks) do
            setTrafficSystemBlockingPositionState(trafficSystemId, block.splineId, block.splineTime, false)
        end
    end
    self.activeBlocks = {}
end

-- =========================================================================
-- MAIN LOOP
-- =========================================================================

function TornadoTraffic:update(dt)
    if g_currentMission == nil or not g_currentMission:getIsServer() then
        return
    end

    local hasBlocks = next(self.activeBlocks) ~= nil
    local tornadoNode = TornadoPhysics ~= nil and TornadoPhysics.tornadoNode or nil
    local tornadoActive = tornadoNode ~= nil and entityExists(tornadoNode)

    if not self.isEnabled or not tornadoActive then
        if hasBlocks then
            self:releaseAll()
            if TornadoDebug then TornadoDebug:log("TRAFFIC", "Roadblocks released.") end
        end
        return
    end

    if hasBlocks and TornadoPhysics.showRing then
        self:drawBlocks()
    end

    self.updateTimer = self.updateTimer + dt
    if self.updateTimer < self.UPDATE_INTERVAL then
        return
    end
    self.updateTimer = 0

    local trafficSystemId, rootNodeId = self:getTrafficSystemId()
    if trafficSystemId == nil then
        return
    end
    if self.lanes == nil then
        self:buildLaneCache(rootNodeId)
    end

    local tX, _, tZ = getWorldTranslation(tornadoNode)
    local outerRadius = TornadoPhysics.getOuterRadius ~= nil and TornadoPhysics:getOuterRadius() or TornadoPhysics.settings.base_radius
    local keepOut = outerRadius + self.bufferDistance
    local keepOutSq = keepOut * keepOut

    -- 1. Work out where every lane first enters the keep-out circle.
    local wanted = {}
    for laneIndex, lane in ipairs(self.lanes) do
        if lane.maxX >= tX - keepOut and lane.minX <= tX + keepOut and lane.maxZ >= tZ - keepOut and lane.minZ <= tZ + keepOut then
            local wasInside = nil
            for i, sample in ipairs(lane.samples) do
                local dx, dz = sample.x - tX, sample.z - tZ
                local isInside = (dx * dx + dz * dz) < keepOutSq

                if isInside and wasInside ~= true then
                    -- Entry: block at the last sample before the circle (or the lane start if it begins inside).
                    local blockIndex = (wasInside == false) and (i - 1) or i
                    local key = laneIndex .. ":" .. blockIndex
                    local info = self:getBlockInfo(trafficSystemId, lane, blockIndex, key)
                    if info then
                        local s = lane.samples[blockIndex]
                        wanted[key] = { splineId = info.splineId, splineTime = info.splineTime, x = s.x, y = s.y, z = s.z }
                    end
                end
                wasInside = isInside
            end
        end
    end

    -- 2. Release blocks the tornado has moved away from, then switch on the new ones.
    local released, added = 0, 0
    for key, block in pairs(self.activeBlocks) do
        if wanted[key] == nil then
            setTrafficSystemBlockingPositionState(trafficSystemId, block.splineId, block.splineTime, false)
            self.activeBlocks[key] = nil
            released = released + 1
        end
    end
    for key, block in pairs(wanted) do
        if self.activeBlocks[key] == nil then
            setTrafficSystemBlockingPositionState(trafficSystemId, block.splineId, block.splineTime, true)
            self.activeBlocks[key] = block
            added = added + 1
        end
    end

    if TornadoDebug and (added > 0 or released > 0) then
        TornadoDebug:log("TRAFFIC", string.format("Roadblocks: +%d / -%d (active %d, keep-out %.0fm)",
            added, released, self:getNumActiveBlocks(), keepOut))
    end
end

function TornadoTraffic:getNumActiveBlocks()
    local count = 0
    for _ in pairs(self.activeBlocks) do count = count + 1 end
    return count
end

--- Red posts at every active roadblock, shown together with the danger ring (t_sfx ring).
function TornadoTraffic:drawBlocks()
    for _, block in pairs(self.activeBlocks) do
        drawDebugLine(block.x, block.y, block.z, 1, 0, 0, block.x, block.y + 6, block.z, 1, 0, 0)
    end
end
