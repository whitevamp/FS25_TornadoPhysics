-- ==============================================================================
-- Tornado Physics Mod - Cross-Mod Compatibility Layer
-- Author: whitevamp
--
-- Integrates with:
--   - "Moisture System" (FS25_MoistureSystem) by Ozz - https://github.com/sprkem/FS25_MoistureSystem
-- ==============================================================================

---@class TornadoMoisture
---@version 1.0
---@description Moisture System simulates field moisture, withers crops in drought (its WitheringSystem paints
--- withered patches straight into the crop density map - not through the game's disaster function, so the storm
--- damage report would not see them) and changes yield / quality by moisture. When it is installed:
---   * our own drought switches off (TornadoHazards) - both would hit the same crops;
---   * field fires only start on fields Moisture System has dried below the crop's wither threshold;
---   * floods keep running on our own water balance (Moisture System has no floods);
---   * its withered patches are recorded as DROUGHT damage (TornadoInsuranceDamage) for the crop insurance.
--- Reading only: getMoistureAtPosition, CropValueMap.getCropDef(fillTypeIndex).witherThreshold and the
--- witheringEnabled setting. The withering hook wraps WitheringSystem:witherPatchAtField on the instance
--- (re-created every mission) and reads the three math.random() draws it makes (patch x, z, radius) to rebuild
--- where the patch went (same field bounds, same disc shape: a centre square + 4 corner squares). If the draws
--- do not match that pattern (Moisture System changed), the patch is not recorded and a warning is logged once.
--- No code from Moisture System is copied. All calls are guarded by nil checks (no pcall - ModHub rule).

TornadoMoisture = {}
TornadoMoisture.MOD_NAME = "FS25_MoistureSystem"
TornadoMoisture.DEFAULT_WITHER_THRESHOLD = 0.03
-- Field fire: dry enough when the field is below the crop's yieldCurveFloor (where Moisture System's dry-side yield
-- loss is at its maximum - 3 to 5 %). The wither threshold (2 - 3 %) is below most months' moisture clamp, so fires
-- would almost never start (in-game test 2026-10-17: msSetMoisture 1 is clamped back to the month minimum ~9 %).
TornadoMoisture.DEFAULT_FIRE_THRESHOLD = 0.05
TornadoMoisture.RADIUS_MIN = 4       -- Moisture System 2.0.0.8: radius = 4 + random() * 6
TornadoMoisture.RADIUS_RANGE = 6
TornadoMoisture.HOOK_RETRY_MS = 1000

TornadoMoisture.isAvailable = false

function TornadoMoisture:loadMap()
    self.isAvailable = g_modIsLoaded ~= nil and g_modIsLoaded[self.MOD_NAME] == true
    self.hookedSystem = nil
    self.hookTimer = 0
    self.warnedPattern = false
    self.patchesRecorded = 0
    if TornadoDebug then
        TornadoDebug:info("MOISTURE", self.isAvailable and "Moisture System found - own drought off, its withering feeds the damage report."
            or "Moisture System not found.")
    end
    if self.isAvailable then
        self:tryHook()
    end
end

function TornadoMoisture:deleteMap()
    self.hookedSystem = nil
end

local function isServer()
    return g_currentMission ~= nil and g_currentMission:getIsServer()
end

function TornadoMoisture:getSystem()
    return g_currentMission ~= nil and g_currentMission.MoistureSystem or nil
end

--- Moisture System is installed and running.
function TornadoMoisture:isActive()
    return self.isAvailable and self:getSystem() ~= nil
end

--- The mod's CropValueMap (its own mod environment), nil when not reachable.
function TornadoMoisture:getCropValueMap()
    local env = _G[self.MOD_NAME]
    if type(env) == "table" and type(env.CropValueMap) == "table" then
        return env.CropValueMap
    end
    return nil
end

--- Field moisture (0 - 1) at the field centre, nil without Moisture System.
function TornadoMoisture:getFieldMoisture(field)
    local system = self.isAvailable and self:getSystem() or nil
    if system == nil or system.getMoistureAtPosition == nil or field == nil or field.getCenterOfFieldWorldPosition == nil then
        return nil
    end
    local x, z = field:getCenterOfFieldWorldPosition()
    if x == nil then
        return nil
    end
    return system:getMoistureAtPosition(x, z)
end

--- The moisture below which Moisture System withers this crop (fill type index).
function TornadoMoisture:getWitherThreshold(fillTypeIndex)
    local map = self:getCropValueMap()
    if map ~= nil and map.getCropDef ~= nil and fillTypeIndex ~= nil then
        local def = map.getCropDef(fillTypeIndex)
        if def ~= nil and def.witherThreshold ~= nil then
            return def.witherThreshold
        end
    end
    return self.DEFAULT_WITHER_THRESHOLD
end

--- The field moisture below which a ripe crop counts as dry enough to burn: its yieldCurveFloor, never below
--- the wither threshold.
function TornadoMoisture:getFireThreshold(fillTypeIndex)
    local threshold = self.DEFAULT_FIRE_THRESHOLD
    local map = self:getCropValueMap()
    if map ~= nil and map.getCropDef ~= nil and fillTypeIndex ~= nil then
        local def = map.getCropDef(fillTypeIndex)
        if def ~= nil and def.yieldCurveFloor ~= nil then
            threshold = def.yieldCurveFloor
        end
    end
    return math.max(threshold, self:getWitherThreshold(fillTypeIndex))
end

local function getFieldFillTypeIndex(field)
    local state = field.getFieldState ~= nil and field:getFieldState() or nil
    if state ~= nil and state.fruitTypeIndex ~= nil and g_fruitTypeManager ~= nil then
        return g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(state.fruitTypeIndex)
    end
    return nil
end

--- Is the crop on this field drier than its wither threshold (Moisture System withers it)?
function TornadoMoisture:isFieldTooDry(field)
    local moisture = self:getFieldMoisture(field)
    if moisture == nil then
        return false
    end
    return moisture < self:getWitherThreshold(getFieldFillTypeIndex(field))
end

--- Is the crop on this field dry enough to catch fire (below its fire threshold)?
function TornadoMoisture:isFieldFireDry(field)
    local moisture = self:getFieldMoisture(field)
    if moisture == nil then
        return false
    end
    return moisture < self:getFireThreshold(getFieldFillTypeIndex(field))
end

-- =========================================================================
-- WITHERING -> STORM DAMAGE REPORT (server)
-- =========================================================================

--- The WitheringSystem exists after Moisture System's own loadMap; retried from update until found.
function TornadoMoisture:update(dt)
    if not self.isAvailable or not isServer() then
        return
    end
    local system = g_currentMission.witheringSystem
    if system ~= nil and system == self.hookedSystem then
        return
    end
    self.hookTimer = (self.hookTimer or 0) + dt
    if self.hookTimer >= self.HOOK_RETRY_MS then
        self.hookTimer = 0
        self:tryHook()
    end
end

--- Field bounds the way Moisture System computes them (axis-aligned box of the polygon points).
local function getFieldBounds(field)
    local points = field.getPolygonPoints ~= nil and field:getPolygonPoints() or nil
    if points == nil or #points == 0 then
        return nil
    end
    local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
    for _, node in ipairs(points) do
        local x, _, z = getWorldTranslation(node)
        minX, maxX = math.min(minX, x), math.max(maxX, x)
        minZ, maxZ = math.min(minZ, z), math.max(maxZ, z)
    end
    return minX, maxX, minZ, maxZ
end

--- A square as an area for the damage tracker (getVerticesAs3DCoordinates like the game's density map areas).
local function squareArea(x0, z0, size)
    return {
        getVerticesAs3DCoordinates = function()
            return { x0, 0, z0, x0 + size, 0, z0, x0 + size, 0, z0 + size, x0, 0, z0 + size }
        end,
    }
end

function TornadoMoisture:tryHook()
    local system = g_currentMission ~= nil and g_currentMission.witheringSystem or nil
    if system == nil or system.witherPatchAtField == nil or system == self.hookedSystem then
        return
    end
    if system.tornadoMoistureHooked then
        self.hookedSystem = system   -- already wrapped (same mission): never wrap twice
        return
    end
    system.tornadoMoistureHooked = true
    local original = system.witherPatchAtField
    local moisture = self
    -- Instance field: shadows the class method for this mission's WitheringSystem only.
    system.witherPatchAtField = function(witheringSystem, field, fruitTypeIndex, witherThreshold, ...)
        local draws = {}
        local realRandom = math.random
        math.random = function(...)
            local value = realRandom(...)
            if select("#", ...) == 0 then
                draws[#draws + 1] = value
            end
            return value
        end
        local result = original(witheringSystem, field, fruitTypeIndex, witherThreshold, ...)
        math.random = realRandom
        moisture:onWitherPatch(field, draws)
        return result
    end
    self.hookedSystem = system
    if TornadoDebug then
        TornadoDebug:info("MOISTURE", "Withering hooked - withered patches go to the storm damage report.")
    end
end

--- 3 draws = a patch was painted (x, z, radius); 2 = skipped (wetter at the patch spot); 0 = no modifier / bounds.
function TornadoMoisture:onWitherPatch(field, draws)
    if #draws == 0 or #draws == 2 then
        return
    end
    if #draws ~= 3 then
        if not self.warnedPattern then
            self.warnedPattern = true
            print(string.format("TORNADO MOISTURE: Moisture System withering made %d random draws (expected 3) - " ..
                "its withered patches are not recorded for the insurance. Please report your Moisture System version.", #draws))
        end
        return
    end
    if TornadoInsuranceDamage == nil or TornadoInsuranceDamage.recordArea == nil or field == nil then
        return
    end
    local minX, maxX, minZ, maxZ = getFieldBounds(field)
    if minX == nil then
        return
    end
    local cx = minX + draws[1] * (maxX - minX)
    local cz = minZ + draws[2] * (maxZ - minZ)
    local radius = self.RADIUS_MIN + draws[3] * self.RADIUS_RANGE
    -- Same disc as Moisture System: a centre square (side = radius) and 4 corner squares (side = radius / 2).
    local half = radius * 0.5
    TornadoInsuranceDamage:recordArea(squareArea(cx - half, cz - half, radius), 1, TornadoInsuranceDamage.CAUSE_DROUGHT)
    for _, offset in ipairs({ { half, half }, { -half, half }, { half, -half }, { -half, -half } }) do
        local sx = cx + offset[1] - half * 0.5
        local sz = cz + offset[2] - half * 0.5
        TornadoInsuranceDamage:recordArea(squareArea(sx, sz, half), 1, TornadoInsuranceDamage.CAUSE_DROUGHT)
    end
    self.patchesRecorded = (self.patchesRecorded or 0) + 1
end

-- =========================================================================
-- DEV CONSOLE: t_dev moisture <status | field <n> | wither <n> [count]>
-- =========================================================================

function TornadoMoisture:consoleCommand(sub, value, extra)
    if not self:isActive() then
        return "Moisture: FS25_MoistureSystem is not installed / not running."
    end
    local field = g_fieldManager ~= nil and tonumber(value) ~= nil and g_fieldManager:getFieldById(tonumber(value)) or nil
    if sub == "field" then
        if field == nil then return "Usage: t_dev moisture field <field number>" end
        local fillTypeIndex = getFieldFillTypeIndex(field)
        local moisture = self:getFieldMoisture(field) or 0
        return string.format("Moisture: field %d - moisture %.1f %% | wither below %.1f %% (%s) | fire below %.1f %% (%s)",
            field:getId(), moisture * 100, self:getWitherThreshold(fillTypeIndex) * 100, self:isFieldTooDry(field) and "WITHERING" or "no",
            self:getFireThreshold(fillTypeIndex) * 100, self:isFieldFireDry(field) and "DRY ENOUGH" or "no")
    elseif sub == "wither" then
        if not isServer() then return "Moisture: run on the host / server." end
        local system = g_currentMission.witheringSystem
        if field == nil or system == nil or system.witherPatchAtField == nil then
            return "Usage: t_dev moisture wither <field number> [patches, default 5]  (DESTROYS crop - Moisture System's own withering)"
        end
        local state = field:getFieldState()
        if state == nil or state.fruitTypeIndex == nil or state.fruitTypeIndex == FruitType.UNKNOWN then
            return "Moisture: nothing grows on field " .. tostring(field:getId()) .. "."
        end
        local before = self.patchesRecorded or 0
        local count = math.max(1, math.min(50, tonumber(extra) or 5))
        for _ = 1, count do
            -- threshold 1.0: Moisture System's own "is the spot wet enough to skip" check never skips
            system:witherPatchAtField(field, state.fruitTypeIndex, 1.0)
        end
        return string.format("Moisture: %d withered patches painted on field %d by Moisture System, %d recorded for the damage report (t_dev insurance damage).",
            count, field:getId(), (self.patchesRecorded or 0) - before)
    end
    return self:getStatusText()
end

function TornadoMoisture:getStatusText()
    if not self.isAvailable then
        return "Moisture System: not installed."
    end
    local system = self:getSystem()
    local withering = system ~= nil and system.settings ~= nil and system.settings.witheringEnabled
    return string.format("Moisture System: installed | map moisture %s | withering %s | hook %s | crop table %s | patches recorded %d",
        system ~= nil and system.currentMoisturePercent ~= nil and string.format("%.1f %%", system.currentMoisturePercent * 100) or "?",
        withering == false and "off" or "on", self.hookedSystem ~= nil and "ok" or "waiting",
        self:getCropValueMap() ~= nil and "found" or "NOT found (default thresholds)", self.patchesRecorded or 0)
end
