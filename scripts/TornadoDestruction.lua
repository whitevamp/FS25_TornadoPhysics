---@class TornadoDestruction
---@version 4.1 (PROCEDURAL & OPTIMIZED LINKING)
---@description Procedural destruction engine for vehicles. Eliminates static database files and dynamically classifies mesh nodes at runtime.

TornadoDestruction = {}

-- ============================================================================
-- Configuration
-- ============================================================================
TornadoDestruction.REPAIR_COOLDOWN_HOURS = 24
TornadoDestruction.DESTRUCTION_XML_FILE = "TornadoDestructionState.xml"
TornadoDestruction.SEARCH_BUDGET = 1000

-- SAFETY LIMITS (Limits for destroyed vehicle structural parts)
TornadoDestruction.MIN_STRUCT_TO_DESTROY = 2
TornadoDestruction.MAX_STRUCT_TO_DESTROY = 6

-- KEYWORDS FOR "ALWAYS HIDE" (Trash / Cosmetic Details)
TornadoDestruction.TRASH_KEYWORDS = {
    "decal", "sticker", "logo", "lettering", "sign", "warning", "label",
    "hose", "cable", "wire", "line", "pipe", "tube", "connection", "electric", "chain",
    "licenseplate", "license_plate", "plate", "numberplate", "glow", "visor"
}

-- KEYWORDS FOR "STRUCTURAL LOTTERY" (Bodywork / Panels / Attachments)
TornadoDestruction.STRUCT_KEYWORDS = {
    "window", "glass", "door", "hood", "bonnet", "cabin", "cab", "roof",
    "fender", "panel", "wing", "arm", "boom", "cover", "hatch", "mirror",
    "axis", "lod"
}

-- ============================================================================
-- Internal State
-- ============================================================================
TornadoDestruction._destroyedObjects = {}
TornadoDestruction._pendingLoad = {}
TornadoDestruction.IgnoreListExact = {}
TornadoDestruction.IgnoreListPatterns = {}
TornadoDestruction.isInitialized = false
TornadoDestruction.loggedIgnoredFiles = {}
TornadoDestruction.nextLinkCheckTime = 0 -- Throttle timer for relinking

local function getTableCount(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- ============================================================================
-- Lifecycle
-- ============================================================================
function TornadoDestruction:loadMap(name, baseDir)
    if self.isInitialized then return end
    if not g_currentMission then return end

    self._destroyedObjects = {}
    self._pendingLoad = {}
    self.loggedIgnoredFiles = {}
    self.nextLinkCheckTime = 0

    local dir = baseDir or g_currentModDirectory
    if not dir then
        print("TornadoDestruction: ERROR - No Mod Dir")
        return
    end

    print("TornadoDestruction: V4.1 Initializing (Procedural Vehicle Destruction)...")

    -- Load Optional Ignore List
    local ignorePath = Utils.getFilename("DB/TornadoMod_IgnoreList.lua", dir)
    if fileExists(ignorePath) then
        source(ignorePath)
        local rawIgnoreList = _G.TornadoMod_IgnoreList or {}

        self.IgnoreListExact = {}
        self.IgnoreListPatterns = {}

        for _, entry in ipairs(rawIgnoreList) do
            if type(entry) == "string" then
                local cleanEntry = string.lower(entry)
                if string.find(cleanEntry, "^_") or string.find(cleanEntry, "_$") or #cleanEntry <= 3 then
                    table.insert(self.IgnoreListPatterns, cleanEntry)
                else
                    self.IgnoreListExact[cleanEntry] = true
                end
            end
        end

        print(string.format("TornadoDestruction: Ignore List Loaded. (Exact: %d, Patterns: %d)",
            getTableCount(self.IgnoreListExact), #self.IgnoreListPatterns))
        _G.TornadoMod_IgnoreList = nil
    end

    if g_currentMission.environment then
        self.lastAbsoluteTime = g_currentMission.environment.dayTime
    else
        self.lastAbsoluteTime = 0
    end

    self:_loadFromXML()
    self.isInitialized = true
end

function TornadoDestruction:deleteMap()
    if #self._destroyedObjects > 0 or #self._pendingLoad > 0 then self:_saveToXML() end
    self.isInitialized = false
end

function TornadoDestruction:update(dt)
    if not self.isInitialized or not g_currentMission then return end

    -- Throttle relinking checks to run once every 1000ms instead of every frame
    local currentTime = g_currentMission.time or 0
    if #self._pendingLoad > 0 and currentTime > self.nextLinkCheckTime then
        self.nextLinkCheckTime = currentTime + 1000
        self:_linkPendingObjects()
    end

    local hasDestroyed = false

    -- Calculate scaled time so fast-forward works accurately
    local timeScale = 1
    if g_currentMission.missionInfo then
        timeScale = g_currentMission.missionInfo.timeScale or 1
    end
    local scaledDt = dt * timeScale

    for id, data in pairs(self._destroyedObjects) do
        -- Garbage collection check: wipe if vehicle was sold or deleted
        if not data.obj or not data.obj.rootNode or not entityExists(data.obj.rootNode) then
            self._destroyedObjects[id] = nil
        else
            hasDestroyed = true

            if data.repairTimer then
                data.repairTimer = data.repairTimer - scaledDt
            end

            local x, y, z = getWorldTranslation(data.obj.rootNode)
            if x then
                data.lastX, data.lastY, data.lastZ = x, y, z
            end
        end
    end

    if g_currentMission.environment then
        local currentAbsTime = g_currentMission.environment.dayTime
        local absoluteDelta = currentAbsTime - self.lastAbsoluteTime

        -- Handle midnight clock rollover
        if absoluteDelta < 0 then
            absoluteDelta = absoluteDelta + 86400000 -- Milliseconds in a day
        end

        -- Time-skip delta check
        local expectedMaxDelta = dt * timeScale * 2
        if absoluteDelta > expectedMaxDelta then
            for id, data in pairs(self._destroyedObjects) do
                if data.repairTimer then
                    local skippedUnits = absoluteDelta / 1000
                    data.repairTimer = data.repairTimer - skippedUnits
                end
            end
        end

        self.lastAbsoluteTime = currentAbsTime
    end

    if hasDestroyed then self:_updateRepairs(dt) end
end

-- ============================================================================
-- Main Destruction Logic
-- ============================================================================

function TornadoDestruction:destroyTarget(target)
    if not (TornadoPhysics and TornadoPhysics.settings and TornadoPhysics.settings.destructionEnabled) then return end
    if target == nil or target.rootNode == nil or not entityExists(target.rootNode) then return end

    local objectId = target.rootNode
    if self._destroyedObjects[objectId] ~= nil then return end

    local rawFilename = target.i3dFilename or ""
    local lowerRawFilename = string.lower(rawFilename)

    -- Strict Vehicle Filter: Reject placeables, buildings, trains, and locomotives
    local isVehicleObject = (target.isa ~= nil and target:isa(Vehicle)) or
        (target.spec_motorized ~= nil or target.spec_attachable ~= nil)
    if not isVehicleObject or string.find(lowerRawFilename, "placeables/") then
        return
    end

    if target.isTrain or target.spec_locomotive ~= nil or string.find(lowerRawFilename, "train") then
        return
    end

    if target.rootNode and TornadoAPI and TornadoAPI:isNodeProtected(target.rootNode) then
        return
    end

    -- Smart Scan Cache Cooldown
    if target.tornadoLastDestructionScan and g_currentMission.time < (target.tornadoLastDestructionScan + 10000) then
        return
    end

    -- Indoor / Roof Protection Check
    local x, y, z = getWorldTranslation(target.rootNode)
    if x ~= nil and z ~= nil then
        local isIndoor = false
        if g_currentMission.indoorMask ~= nil then
            isIndoor = g_currentMission.indoorMask:getIsIndoorAtWorldPosition(x, z)
        end

        local indoorDamageEnabled = TornadoPhysics.settings and TornadoPhysics.settings.indoor_damage

        if isIndoor and not indoorDamageEnabled then
            if TornadoDebug and TornadoDebug.verboseIndoorBypass then
                TornadoDebug:log("DESTRUCTION", "SKIPPED -> " .. tostring(rawFilename) .. " (Vehicle is indoors/covered)")
            end
            return
        end
    end

    local filename = self:_cleanFilename(rawFilename)

    -- File-level ignore list check
    local filenameLower = string.lower(filename)
    for pattern, _ in pairs(self.IgnoreListExact) do
        if string.find(filenameLower, pattern, 1, true) then
            if not self.loggedIgnoredFiles[filenameLower] then
                if TornadoDebug then
                    TornadoDebug:log("DESTRUCTION", "IGNORED FILE -> " .. filename .. " (Matches ignore list)")
                end
                self.loggedIgnoredFiles[filenameLower] = true
            end
            return
        end
    end

    if TornadoDebug then
        TornadoDebug:log("DESTRUCTION", "--------------------------------------------------")
        TornadoDebug:log("DESTRUCTION", "Processing Vehicle (Procedural) -> " .. tostring(filename))
    end

    -- 1. PROCEDURAL SCAN & CLASSIFICATION
    local foundTrash = {}
    local foundStructure = {}

    self:_scanProcedural(target.rootNode, foundTrash, foundStructure)

    -- 2. EXECUTE DESTRUCTION
    local finalHiddenNodes = {}

    -- A. Hide ALL Trash Nodes
    for _, nodeData in ipairs(foundTrash) do
        if TornadoDebug and TornadoDebug.verboseDestruction then
            TornadoDebug:log("DESTRUCTION", "   >> HIDING (Trash): " .. nodeData.name)
        end
        setVisibility(nodeData.id, false)
        table.insert(finalHiddenNodes, nodeData)
    end

    -- B. Hide Lottery Structural Nodes
    local structLimit = math.random(self.MIN_STRUCT_TO_DESTROY, self.MAX_STRUCT_TO_DESTROY)
    local structCount = 0

    self:_shuffleTable(foundStructure)

    local function hideSubChildren(parentNode)
        local numChildren = getNumOfChildren(parentNode)
        for i = 0, numChildren - 1 do
            local child = getChildAt(parentNode, i)
            if getVisibility(child) then
                setVisibility(child, false)
                table.insert(finalHiddenNodes, { id = child, name = getName(child) or "sub_child" })
            end
            hideSubChildren(child)
        end
    end

    for _, nodeData in ipairs(foundStructure) do
        if structCount >= structLimit then break end

        if TornadoDebug and TornadoDebug.verboseDestruction then
            TornadoDebug:log("DESTRUCTION", "   >> HIDING (Struct): " .. nodeData.name)
        end
        setVisibility(nodeData.id, false)
        table.insert(finalHiddenNodes, nodeData)
        hideSubChildren(nodeData.id)
        structCount = structCount + 1
    end

    -- 3. RECORD STATE
    if #finalHiddenNodes > 0 then
        if TornadoDebug and TornadoDebug.verboseDestruction then
            TornadoDebug:log("DESTRUCTION",
                string.format("RESULT -> Hid %d Trash, %d/%d Structure.", #foundTrash, structCount, structLimit))
        end

        target.tornadoLastDestructionScan = g_currentMission.time
        local totalTimerMs = self.REPAIR_COOLDOWN_HOURS * 3600 * 1000

        self._destroyedObjects[objectId] = {
            obj = target,
            filename = filename,
            nodes = finalHiddenNodes,
            repairTimer = totalTimerMs,
            lastX = x or 0,
            lastY = y or 0,
            lastZ = z or 0
        }
    else
        if TornadoDebug then TornadoDebug:log("DESTRUCTION", "FAILED. No suitable vehicle parts found.") end
        target.tornadoLastDestructionScan = g_currentMission.time
    end
end

-- ============================================================================
-- Dynamic Procedural Node Collector
-- ============================================================================
function TornadoDestruction:_scanProcedural(rootNode, outTrash, outStructure)
    local nodesToProcess = { rootNode }
    local processedCount = 0

    local function isValidDestructionNode(nodeId, nodeName)
        local lowerName = string.lower(nodeName)

        if string.find(lowerName, "sound") or string.find(lowerName, "audio") or
            string.find(lowerName, "sample") or string.find(lowerName, "gls") or
            string.find(lowerName, "wav") then
            return false
        end

        if lowerName == "lod" or lowerName == "lod0" or lowerName == "lod1" then
            return false
        end

        if ClassIds and ClassIds.SHAPE and getHasClassId then
            return getHasClassId(nodeId, ClassIds.SHAPE)
        end

        return getIsShape and getIsShape(nodeId) or false
    end

    while #nodesToProcess > 0 do
        if processedCount >= self.SEARCH_BUDGET then break end

        local currentNode = table.remove(nodesToProcess, 1)
        processedCount = processedCount + 1

        local nodeName = getName(currentNode) or ""
        local nodeNameLower = string.lower(nodeName)
        local skipChildren = false

        local skipNode = false
        if currentNode == rootNode then
            skipNode = true
        else
            if self.IgnoreListExact[nodeNameLower] then
                skipNode = true
            else
                for _, pattern in ipairs(self.IgnoreListPatterns) do
                    if string.find(nodeNameLower, pattern, 1, true) ~= nil then
                        skipNode = true
                        break
                    end
                end
            end
        end

        if not skipNode and getVisibility(currentNode) and isValidDestructionNode(currentNode, nodeName) then
            local isTrash = false
            local isStruct = false

            for _, trashKey in ipairs(self.TRASH_KEYWORDS) do
                if string.find(nodeNameLower, trashKey, 1, true) then
                    isTrash = true
                    break
                end
            end

            if not isTrash then
                for _, structKey in ipairs(self.STRUCT_KEYWORDS) do
                    if string.find(nodeNameLower, structKey, 1, true) then
                        isStruct = true
                        break
                    end
                end
            end

            local finalNode = currentNode
            local finalName = nodeName
            local parent = getParent(currentNode)
            if parent and parent ~= 0 then
                local parentName = getName(parent) or ""
                local parentLower = string.lower(parentName)
                if parentLower == "lod" or parentLower == "lod0" or parentLower == "lod1" then
                    finalNode = parent
                    finalName = parentName
                end
            end

            if isTrash then
                table.insert(outTrash, { id = finalNode, name = finalName })
                skipChildren = true
            elseif isStruct then
                table.insert(outStructure, { id = finalNode, name = finalName })
                skipChildren = true
            end
        end

        if not skipChildren then
            local numChildren = getNumOfChildren(currentNode)
            if numChildren > 0 then
                for i = 0, numChildren - 1 do
                    table.insert(nodesToProcess, getChildAt(currentNode, i))
                end
            end
        end
    end
end

function TornadoDestruction:_shuffleTable(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

function TornadoDestruction:_updateRepairs(dt)
    local objectsToRepair = {}

    for id, data in pairs(self._destroyedObjects) do
        if data.repairTimer and data.repairTimer <= 0 then
            table.insert(objectsToRepair, id)
        end
    end

    for _, id in ipairs(objectsToRepair) do
        local data = self._destroyedObjects[id]

        if TornadoDebug then
            TornadoDebug:log("DESTRUCTION",
                string.format("REPAIR TRACE: Timer expired for %s. Restoring %d parts.", tostring(data.filename),
                    #data.nodes))
        end

        if data.nodes and data.nodes[1] and entityExists(data.nodes[1].id) then
            local vehicleRoot = getParent(data.nodes[1].id)
            if vehicleRoot and entityExists(vehicleRoot) then
                self:purgeOrphanedFX(vehicleRoot)
            end
        end

        for _, nodeInfo in ipairs(data.nodes) do
            if entityExists(nodeInfo.id) then
                setVisibility(nodeInfo.id, true)
            end
        end

        self._destroyedObjects[id] = nil
    end
end

function TornadoDestruction:_cleanFilename(path)
    if path == nil or path == "" then return "unknown" end
    path = string.gsub(path, "\\", "/")
    local vPos = string.find(path, "vehicles/")
    if vPos then return string.sub(path, vPos) end
    return path
end

-- Optimized fast stack node search
function TornadoDestruction:_findNodeByName(rootNode, targetName)
    if rootNode == nil or rootNode == 0 then return 0 end
    local nodesToProcess = { rootNode }
    local maxSearch = 1000
    local count = 0

    while #nodesToProcess > 0 do
        if count > maxSearch then break end
        local currentNode = table.remove(nodesToProcess) -- Fast stack pop (no table shift overhead)
        count = count + 1

        if getName(currentNode) == targetName then
            return currentNode
        end

        local numChildren = getNumOfChildren(currentNode)
        if numChildren > 0 then
            for i = 0, numChildren - 1 do
                table.insert(nodesToProcess, getChildAt(currentNode, i))
            end
        end
    end
    return 0
end

function TornadoDestruction:_linkPendingObjects()
    if g_currentMission == nil then return end
    local stillPending = {}
    local searchRadiusSq = 1.0
    local searchTargets = {}

    if g_currentMission.vehicleSystem and g_currentMission.vehicleSystem.vehicles then
        for _, v in pairs(g_currentMission.vehicleSystem.vehicles) do table.insert(searchTargets, v) end
    end

    for _, pending in ipairs(self._pendingLoad) do
        local found = false
        -- Track attempts so unresolvable saved items don't stall execution indefinitely
        pending.attempts = (pending.attempts or 0) + 1

        for _, obj in ipairs(searchTargets) do
            local filename = self:_cleanFilename(obj.i3dFilename)
            if filename == pending.filename then
                local x, y, z = getWorldTranslation(obj.rootNode)
                if x ~= nil then
                    local dx, dy, dz = x - pending.x, y - pending.y, z - pending.z
                    if (dx * dx + dy * dy + dz * dz) < searchRadiusSq then
                        if TornadoDebug then TornadoDebug:log("DESTRUCTION", "RELINKING saved vehicle -> " .. filename) end

                        for _, nodeInfo in ipairs(pending.nodes) do
                            local foundNode = self:_findNodeByName(obj.rootNode, nodeInfo.name)
                            if foundNode and foundNode ~= 0 then
                                setVisibility(foundNode, false)
                                nodeInfo.id = foundNode
                            end
                        end

                        self._destroyedObjects[obj.rootNode] = {
                            obj = obj,
                            filename = filename,
                            nodes = pending.nodes,
                            repairTimer = pending.repairTimer,
                            lastX = x,
                            lastY = y,
                            lastZ = z
                        }
                        found = true
                        break
                    end
                end
            end
        end

        -- Keep checking for up to 10 attempts (~10 seconds), then drop to clear memory
        if not found then
            if pending.attempts < 10 then
                table.insert(stillPending, pending)
            else
                if TornadoDebug then
                    TornadoDebug:log("DESTRUCTION", "LINK EXPIRED -> Gave up relinking " .. tostring(pending.filename))
                end
            end
        end
    end
    self._pendingLoad = stillPending
end

function TornadoDestruction:_resolveSavegamePath()
    if not g_currentMission or not g_currentMission.missionInfo then return nil end

    local dir = g_currentMission.missionInfo.savegameDirectory
    if dir == nil then
        if g_currentMission.missionInfo.savegameIndex ~= nil then
            dir = string.format('%ssavegame%d', getUserProfileAppPath(), g_currentMission.missionInfo.savegameIndex)
        end
    end

    if dir ~= nil then
        return dir .. "/"
    end
    return nil
end

function TornadoDestruction:_saveToXML()
    if TornadoDebug then TornadoDebug:log("DESTRUCTION", "TRACE: _saveToXML triggered.") end

    if g_server == nil then return end

    local saveDir = self:_resolveSavegamePath()
    if saveDir == nil then return end

    local filepath = saveDir .. self.DESTRUCTION_XML_FILE
    local xmlId = createXMLFile("TornadoDestruction", filepath, "TornadoDestruction")
    if xmlId == 0 then return end

    local i = 0
    local function writeEntry(data, x, y, z)
        local objKey = string.format("TornadoDestruction.destroyed.object%d", i)
        setXMLString(xmlId, objKey .. ".filename", data.filename)
        setXMLFloat(xmlId, objKey .. ".posX", x)
        setXMLFloat(xmlId, objKey .. ".posY", y)
        setXMLFloat(xmlId, objKey .. ".posZ", z)
        setXMLFloat(xmlId, objKey .. ".repairTimer", data.repairTimer)

        local nodesStr = ""
        if data.nodes then
            for _, nodeInfo in ipairs(data.nodes) do nodesStr = nodesStr .. nodeInfo.name .. ";" end
        end
        setXMLString(xmlId, objKey .. ".nodes", nodesStr)
        i = i + 1
    end

    if self._destroyedObjects then
        for _, data in pairs(self._destroyedObjects) do
            if data and data.filename then
                writeEntry(data, data.lastX or 0, data.lastY or 0, data.lastZ or 0)
            end
        end
    end

    if self._pendingLoad then
        for _, pending in ipairs(self._pendingLoad) do
            if pending then
                writeEntry(pending, pending.x or 0, pending.y or 0, pending.z or 0)
            end
        end
    end

    saveXMLFile(xmlId)
    delete(xmlId)
    if TornadoDebug then TornadoDebug:log("DESTRUCTION", "SUCCESS. Saved " .. i .. " vehicle objects to XML.") end
end

function TornadoDestruction:_loadFromXML()
    if TornadoDebug then TornadoDebug:log("DESTRUCTION", "TRACE: _loadFromXML triggered.") end

    if g_server == nil then return end

    local saveDir = self:_resolveSavegamePath()
    if saveDir == nil then return end

    local filepath = saveDir .. self.DESTRUCTION_XML_FILE
    if not fileExists(filepath) then return end

    local xmlId = loadXMLFile("TornadoDestruction", filepath)
    if xmlId == 0 then return end

    self._pendingLoad = {}
    local i = 0
    while true do
        local objkey = string.format("TornadoDestruction.destroyed.object%d", i)
        local filename = getXMLString(xmlId, objkey .. ".filename")
        if filename == nil then break end

        local nodesStr = getXMLString(xmlId, objkey .. ".nodes") or ""
        local nodes = {}
        for nodeName in string.gmatch(nodesStr, "([^;]+)") do table.insert(nodes, { id = 0, name = nodeName }) end

        local savedTimer = getXMLFloat(xmlId, objkey .. ".repairTimer")
        if savedTimer == nil then
            savedTimer = getXMLFloat(xmlId, objkey .. ".repairTime") or (24 * 3600 * 1000)
        end

        table.insert(self._pendingLoad, {
            filename = filename,
            x = getXMLFloat(xmlId, objkey .. ".posX"),
            y = getXMLFloat(xmlId, objkey .. ".posY"),
            z = getXMLFloat(xmlId, objkey .. ".posZ"),
            repairTimer = savedTimer,
            nodes = nodes,
            attempts = 0
        })

        i = i + 1
    end

    delete(xmlId)
    if TornadoDebug then TornadoDebug:log("DESTRUCTION", "SUCCESS. Loaded " .. i .. " pending vehicle objects.") end
end

function TornadoDestruction:purgeOrphanedFX(vehicleNode)
    if not vehicleNode or not entityExists(vehicleNode) then return end

    local numChildren = getNumOfChildren(vehicleNode)
    for i = numChildren - 1, 0, -1 do
        local child = getChildAt(vehicleNode, i)
        if child and entityExists(child) then
            local name = getName(child) or ""
            local lowerName = string.lower(name)

            if string.find(lowerName, "smoketrail", 1, true) or string.find(lowerName, "firetrail", 1, true) then
                if TornadoDebug then
                    TornadoDebug:log("DESTRUCTION", string.format("Stripping orphaned visual FX node: %s", name))
                end
                delete(child)
            else
                self:purgeOrphanedFX(child)
            end
        end
    end
end

return TornadoDestruction