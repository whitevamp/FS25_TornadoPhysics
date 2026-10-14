---@class TornadoCargo
---@version 5.3 (RESTING-HEIGHT LIFT CHECK, NO LEFTOVERS)
---@description Forces dumping by overriding Lua checks. Now features independent verbose logging.

TornadoCargo            = {}
TornadoCargo.isEnabled  = false         --true
TornadoCargo.isVerbose  = false         -- Separate logging toggle

-- TUNING
TornadoCargo.settings   = {
    spillHeight = 1.5,
    spillAngle = 0.7,
    drainRate = 0.10,
    spreadRadius = 4.0,
    coverPopChance = 0.0020,
    coverLeakChance = 0.25,
    coverLeakMult = 0.10
}

-- Most cargo one trailer can lose per second, and the remainder that is poured out in one go.
TornadoCargo.MAX_DUMP_PER_SECOND = 30000
TornadoCargo.REMAINDER_LITERS = 150
TornadoCargo.MAX_DUMP_PER_LEAK = 2000

local IGNORED_FILLTYPES = {
    ["DIESEL"] = true,
    ["DEF"] = true,
    ["ELECTRICCHARGE"] = true,
    ["METHANE"] = true,
    ["AIR"] = true,
    ["UNKNOWN"] = true
}

function TornadoCargo:loadMap()
    if TornadoDebug then TornadoDebug:info("CARGO", "V5.2 Initialized (Selective Logging)") end
end

function TornadoCargo:update(dt, activeNodes)
    if not self.isEnabled then return end
    if not g_currentMission:getIsServer() then return end

    local processed = {}
    for nodeId, data in pairs(activeNodes) do
        if data.type == "VEHICLE" and data.obj then
            local vehicle = data.obj
            if not processed[vehicle] then
                self:processVehicle(vehicle, dt)
                processed[vehicle] = true
            end
        end
    end
end

function TornadoCargo:rollChancePerSec(chancePerSec, dt)
    if chancePerSec == nil or chancePerSec <= 0 then return false end
    local seconds = (dt or 0) / 1000
    if seconds <= 0 then return false end
    local pTick = 1 - (1 - chancePerSec) ^ seconds
    return math.random() < pTick
end

function TornadoCargo:processVehicle(vehicle, dt)
    -- Use local verbose flag
    local isVerbose = self.isVerbose

    if vehicle == nil or vehicle.rootNode == nil or vehicle.getFillUnits == nil then return end

    local x, y, z = getWorldTranslation(vehicle.rootNode)
    local terrainH = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
    local clearance = y - terrainH
    local _, dy, _ = localDirectionToWorld(vehicle.rootNode, 0, 1, 0)

    -- Lift is measured from the vehicle's own resting height, not from the terrain: the root node of many
    -- trailers sits well above the ground, and on a farmyard / concrete / bridge the surface is above the
    -- terrain, so "root - terrain" alone made upright trailers on their wheels spill everything.
    local grounded = self:getHasWheelGroundContact(vehicle)
    if (grounded == true or vehicle.tornadoCargoRestHeight == nil) and dy > 0.9 then
        vehicle.tornadoCargoRestHeight = clearance
    end
    local lift = clearance - (vehicle.tornadoCargoRestHeight or 0)

    local isSpilling = false
    if dy < self.settings.spillAngle then
        isSpilling = true -- tipped over / upside down
    elseif grounded ~= true and lift > self.settings.spillHeight then
        isSpilling = true -- in the air
    end

    if not isSpilling then
        vehicle.tornadoCoverMsgTimer = 0
        return
    end

    local cover = vehicle.spec_cover
    local hasCover = (cover ~= nil and cover.covers ~= nil and #cover.covers > 0)
    local coverClosed = (hasCover and cover.state == 0)

    if coverClosed then
        if self:maybePopCoverOpen(vehicle, dt) then
            if isVerbose then
                TornadoDebug:log("CARGO", "COVER POP: " .. vehicle:getName() .. " cover popped open!")
            end
            self:drainCargo(vehicle, dt, x, z, 1.0)
            return
        end

        local doLeak = self:rollChancePerSec(self.settings.coverLeakChance, dt)
        if doLeak then
            if isVerbose then
                vehicle.tornadoCoverMsgTimer = (vehicle.tornadoCoverMsgTimer or 0) + dt
                if vehicle.tornadoCoverMsgTimer >= 1000 then
                    vehicle.tornadoCoverMsgTimer = 0
                    TornadoDebug:log("CARGO", string.format(
                        "COVER SEALED: leaking (x%.2f rate)", self.settings.coverLeakMult
                    ))
                end
            end
            self:drainCargo(vehicle, dt, x, z, self.settings.coverLeakMult, true)
        end
        return
    end

    self:drainCargo(vehicle, dt, x, z, 1.0)
end

--- true = a wheel touches the ground, false = no wheel does, nil = the vehicle has no wheels to ask.
function TornadoCargo:getHasWheelGroundContact(vehicle)
    local spec = vehicle.spec_wheels
    if spec == nil or spec.wheels == nil or #spec.wheels == 0 then
        return nil
    end
    for _, wheel in ipairs(spec.wheels) do
        if wheel.physics ~= nil and wheel.physics.hasGroundContact then
            return true
        end
    end
    return false
end

function TornadoCargo:maybePopCoverOpen(vehicle, dt)
    if vehicle == nil or vehicle.spec_cover == nil then return false end
    local cover = vehicle.spec_cover
    if cover.state ~= 0 then return false end

    if not self:rollChancePerSec(self.settings.coverPopChance, dt) then
        return false
    end

    if vehicle.setCoverState ~= nil then
        vehicle:setCoverState(1, false)
    else
        cover.state = 1
    end

    return cover.state ~= 0
end

--- isBurst: one leak through a closed cover (a single share of drainRate), not a per-second flow.
function TornadoCargo:drainCargo(vehicle, dt, worldX, worldZ, drainScale, isBurst)
    drainScale = drainScale or 1.0
    if drainScale <= 0 then return end

    local units = vehicle:getFillUnits()
    if not units then return end

    -- drainRate is the share of the load lost per 0.1 s (frame-rate independent).
    local seconds = (dt or 0) / 1000
    if seconds <= 0 then return end
    local share = 1 - (1 - math.min(self.settings.drainRate or 0.1, 1)) ^ (seconds * 10)
    local maxDump = self.MAX_DUMP_PER_SECOND * seconds
    if isBurst then
        share = math.min(self.settings.drainRate or 0.1, 1)
        maxDump = self.MAX_DUMP_PER_LEAK
    end

    for i, _ in pairs(units) do
        local currentLevel = vehicle:getFillUnitFillLevel(i)
        if currentLevel > 0 then
            local fillTypeIndex = vehicle:getFillUnitFillType(i)
            local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
            local fillName = (fillType and fillType.name) or "UNKNOWN"

            if not IGNORED_FILLTYPES[fillName] then
                local drainAmount = math.min(currentLevel * share, maxDump) * drainScale

                -- The ground only takes heaps above a minimum size; smaller amounts were refunded forever, which
                -- left the last litres in the trailer (even upside down). Spill at least that much, and pour
                -- out the rest in one go once only a small remainder is left.
                local minValid = 0
                if g_densityMapHeightManager ~= nil and g_densityMapHeightManager.getMinValidLiterValue ~= nil then
                    minValid = g_densityMapHeightManager:getMinValidLiterValue(fillTypeIndex) or 0
                end
                local isRemainder = drainScale >= 1 and currentLevel <= math.max(minValid * 4, self.REMAINDER_LITERS)
                if isRemainder then
                    drainAmount = currentLevel
                else
                    drainAmount = math.max(drainAmount, minValid * 2)
                end
                drainAmount = math.min(drainAmount, currentLevel)

                if drainAmount > 0 then
                    vehicle:addFillUnitFillLevel(vehicle:getOwnerFarmId(), i, -drainAmount, fillTypeIndex, ToolType
                    .UNDEFINED, nil)

                    if fillType and not fillType.isLiquid then
                        local dropped = self:forceTipToGround(fillTypeIndex, drainAmount, worldX, worldZ, vehicle)

                        if isRemainder then
                            -- The last few litres are blown away even if no heap could be placed.
                            if self.isVerbose then
                                TornadoDebug:log("CARGO", string.format("REMAINDER: %.1fL of %s spilled (%.1fL as heap).",
                                    drainAmount, fillName, dropped))
                            end
                        elseif dropped <= 0 then
                            vehicle:addFillUnitFillLevel(vehicle:getOwnerFarmId(), i, drainAmount, fillTypeIndex,
                                ToolType.UNDEFINED, nil)

                            -- Use local verbose flag
                            if self.isVerbose then
                                vehicle.tornadoNoDropTimer = (vehicle.tornadoNoDropTimer or 0) + dt
                                if vehicle.tornadoNoDropTimer >= 1000 then
                                    vehicle.tornadoNoDropTimer = 0
                                    TornadoDebug:log("CARGO", string.format(
                                        "NO DROP: couldn't place %s this tick; refunded %.1fL",
                                        fillName, drainAmount
                                    ))
                                end
                            end
                        elseif dropped < drainAmount then
                            local refund = drainAmount - dropped
                            vehicle:addFillUnitFillLevel(vehicle:getOwnerFarmId(), i, refund, fillTypeIndex,
                                ToolType.UNDEFINED, nil)

                            -- Use local verbose flag
                            if self.isVerbose then
                                TornadoDebug:log("CARGO", string.format(
                                    "PARTIAL: Dropped %.1fL of %s, refunded %.1fL", dropped, fillName, refund
                                ))
                            end
                        else
                            vehicle.tornadoNoDropTimer = 0
                        end
                    else
                        -- Use local verbose flag
                        if self.isVerbose then
                            TornadoDebug:log("CARGO", string.format("LEAK: %.1fL of %s drained.", drainAmount, fillName))
                        end
                    end
                end
            end
        end
    end
end

function TornadoCargo:forceTipToGround(fillTypeIndex, amount, x, z, vehicle)
    if amount == nil or amount <= 0 then return 0 end
    if DensityMapHeightUtil == nil or DensityMapHeightUtil.tipToGroundAroundLine == nil then return 0 end

    local terrainNode = g_terrainNode or (g_currentMission and g_currentMission.terrainRootNode)
    if terrainNode == nil then return 0 end

    local oldIsTipAllowed = DensityMapHeightUtil.getIsTipAllowed
    DensityMapHeightUtil.getIsTipAllowed = function() return true end

    local oldTipMask = g_densityMapHeightManager.tipCollisionMask
    g_densityMapHeightManager.tipCollisionMask = CollisionFlag.PLAYER

    local sx, sy, sz, ex, ey, ez
    local length = self.settings.spreadRadius
    local lineOffset = 0

    if vehicle ~= nil and vehicle.spec_dischargeable ~= nil and vehicle.spec_dischargeable.currentDischargeNode ~= nil then
        local dischargeNode = vehicle.spec_dischargeable.currentDischargeNode
        local info = dischargeNode.info
        if info ~= nil and info.node ~= nil then
            local width = info.width or 1.5
            local zOffset = info.zOffset or 0
            local yOffset = info.yOffset or 0

            sx, sy, sz = localToWorld(info.node, -width, 0, zOffset)
            ex, ey, ez = localToWorld(info.node, width, 0, zOffset)
            sy = sy + yOffset
            ey = ey + yOffset

            local thS = getTerrainHeightAtWorldPos(terrainNode, sx, 0, sz)
            local thE = getTerrainHeightAtWorldPos(terrainNode, ex, 0, ez)
            sy = math.max(thS + 0.1, sy)
            ey = math.max(thE + 0.1, ey)

            length = info.length or length
            vehicle.tornadoLineOffset = vehicle.tornadoLineOffset or 0
            lineOffset = vehicle.tornadoLineOffset
        end
    end

    if sx == nil then
        local y = getTerrainHeightAtWorldPos(terrainNode, x, 0, z) + 0.1
        local rx, rz = 1, 0
        if vehicle ~= nil and vehicle.rootNode ~= nil then
            local dx, _, dz = localDirectionToWorld(vehicle.rootNode, 1, 0, 0)
            local len = math.max(0.0001, math.sqrt(dx * dx + dz * dz))
            rx, rz = dx / len, dz / len
        end
        local halfW = 1.5
        sx, sy, sz = x - rx * halfW, y, z - rz * halfW
        ex, ey, ez = x + rx * halfW, y, z + rz * halfW
    end

    local pad = (length or self.settings.spreadRadius) + 2
    local minX = math.min(sx, ex) - pad
    local maxX = math.max(sx, ex) + pad
    local minZ = math.min(sz, ez) - pad
    local maxZ = math.max(sz, ez) + pad
    g_densityMapHeightManager:updateCollisionMap(minX, minZ, maxX, maxZ)

    -- No tip occlusion areas: they keep heaps from forming under a vehicle, and a trailer standing on end or
    -- upside down covered its own spill line, so every drop failed and was put back (leak "stopped").
    -- No line-height limit either: the fallback line lies 0.1 m above the ground and capped heaps to that.
    local dropped, newLineOffset = DensityMapHeightUtil.tipToGroundAroundLine(
        vehicle, amount, fillTypeIndex, sx, sy, sz, ex, ey, ez, length, nil, lineOffset, false, nil, false
    )

    if vehicle ~= nil and newLineOffset ~= nil then
        vehicle.tornadoLineOffset = newLineOffset
    end

    g_densityMapHeightManager.tipCollisionMask = oldTipMask
    DensityMapHeightUtil.getIsTipAllowed = oldIsTipAllowed
    g_densityMapHeightManager:updateCollisionMap(minX, minZ, maxX, maxZ)

    return dropped or 0
end

function TornadoCargo:toggle()
    self.isEnabled = not self.isEnabled
    if TornadoDebug then TornadoDebug:log("CARGO", "System: " .. tostring(self.isEnabled)) end
end
