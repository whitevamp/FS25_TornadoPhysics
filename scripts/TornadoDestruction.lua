---@class TornadoDestruction
---@version 3.2 (VEHICLES ONLY)
---@description Restored detailed print logs and limited destruction strictly to vehicles.

TornadoDestruction = {}

-- ============================================================================
-- Configuration
-- ============================================================================
TornadoDestruction.REPAIR_COOLDOWN_HOURS = 24
TornadoDestruction.DESTRUCTION_XML_FILE = "TornadoDestructionState.xml"
TornadoDestruction.SEARCH_BUDGET = 1000

-- SAFETY LIMITS (Limits for vehicle parts)
TornadoDestruction.MIN_STRUCT_TO_DESTROY = 2
TornadoDestruction.MAX_STRUCT_TO_DESTROY = 6

-- KEYWORDS FOR "ALWAYS HIDE" (Trash)
TornadoDestruction.TRASH_KEYWORDS = {
    "decal", "sticker", "logo", "lettering", "sign", "warning", "label",
    "hose", "cable", "wire", "line", "pipe", "tube", "connection", "electric", "chain"
}

-- ============================================================================
-- Internal State
-- ============================================================================
TornadoDestruction._destroyedObjects = {}
TornadoDestruction._pendingLoad = {}
TornadoDestruction._savegameDir = nil
TornadoDestruction.GlobalDatabase = {}
TornadoDestruction.FlatDefaults = {}
TornadoDestruction.IgnoreList = {}
TornadoDestruction.isInitialized = false
TornadoDestruction.loggedIgnoredFiles = {}

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

    local dir = baseDir or g_currentModDirectory
    if not dir then
        print("TornadoDestruction: ERROR - No Mod Dir")
        return
    end

    print("TornadoDestruction: V3.2 Initializing (Vehicles Only)...")

    local dbPath = Utils.getFilename("DB/TornadoMod_GlobalDatabase.lua", dir)
    if fileExists(dbPath) then
        source(dbPath)
        
        if _G.TornadoMod_GlobalDatabase then
            self.GlobalDatabase = {}
            for filename, nodeNames in pairs(_G.TornadoMod_GlobalDatabase) do
                self.GlobalDatabase[filename] = {}
                for _, entry in ipairs(nodeNames) do
                    -- SAFE EXTRACT: Handle table objects if entry properties are packed
                    local rawString = (type(entry) == "table") and (entry.name or entry[1]) or entry
                    
                    if type(rawString) == "string" then
                        self.GlobalDatabase[filename][rawString] = true
                        self.GlobalDatabase[filename][string.lower(rawString)] = true
                    end
                end
            end
            print("TornadoDestruction: GlobalDB Loaded and Double-Hashed.")
        end
    end

    local defPath = Utils.getFilename("DB/TornadoMod_Defaults.lua", dir)
    if fileExists(defPath) then
        source(defPath)
        local rawDefaults = _G.TornadoMod_Defaults or {}
        if rawDefaults then
            self.FlatDefaults = {}
            for _, names in pairs(rawDefaults) do
                for _, name in ipairs(names) do table.insert(self.FlatDefaults, name) end
            end
            print("TornadoDestruction: Defaults Loaded: " .. #self.FlatDefaults)
            _G.TornadoMod_Defaults = nil
        end
    end

    local ignorePath = Utils.getFilename("DB/TornadoMod_IgnoreList.lua", dir)
    if fileExists(ignorePath) then
        source(ignorePath)
        local rawIgnoreList = _G.TornadoMod_IgnoreList or {}

        self.IgnoreListExact = {}
        self.IgnoreListPatterns = {}

        for _, entry in ipairs(rawIgnoreList) do
            if type(entry) == "string" then
                local cleanEntry = string.lower(entry)
                -- If it starts or ends with a wildcard style, or is very short, treat it as a pattern match.
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

    self.lastAbsoluteTime = g_currentMission.environment.dayTime

    self:_loadFromXML()
    self.isInitialized = true
end

function TornadoDestruction:deleteMap()
    if #self._destroyedObjects > 0 or #self._pendingLoad > 0 then self:_saveToXML() end
    self.isInitialized = false
end

function TornadoDestruction:update(dt)
    if #self._pendingLoad > 0 then self:_linkPendingObjects() end

    local hasDestroyed = false

    -- Calculate scaled time so 120x fast-forward actually works!
    local timeScale = 1
    if g_currentMission and g_currentMission.missionInfo then
        timeScale = g_currentMission.missionInfo.timeScale or 1
    end
    local scaledDt = dt * timeScale

    for id, data in pairs(self._destroyedObjects) do
        -- ==========================================================
        -- [GARBAGE COLLECTION FIX]
        -- If the vehicle was sold or deleted, wipe it immediately!
        -- ==========================================================
        if not data.obj or not data.obj.rootNode or not entityExists(data.obj.rootNode) then
            self._destroyedObjects[id] = nil
        else
            hasDestroyed = true

            -- [THE COUNTDOWN] Subtract the scaled time from the timer
            if data.repairTimer then
                data.repairTimer = data.repairTimer - scaledDt
            end

            -- [CACHE] Continuously cache the position
            local x, y, z = getWorldTranslation(data.obj.rootNode)
            if x then
                data.lastX, data.lastY, data.lastZ = x, y, z
            end
        end
    end

    local currentAbsTime = g_currentMission.environment.dayTime
    local absoluteDelta = currentAbsTime - self.lastAbsoluteTime

    -- Handle day wrap-around safety (e.g., clock rolls past midnight)
    if absoluteDelta < 0 then
        absoluteDelta = absoluteDelta + 86400000 -- Milliseconds in a day
    end

    -- Threshold check: If the jump is larger than a normal frame delta * timeScale
    local expectedMaxDelta = dt * g_currentMission.missionInfo.timeScale * 2 -- buffer multiplier
    if absoluteDelta > expectedMaxDelta then
        -- A time skip occurred! Force-update all active repair timers instantly
        for id, data in pairs(self._destroyedObjects) do
            if data.repairTimer then
                -- Convert absoluteDelta to the unit your repairTimer uses (e.g., seconds or minutes)
                local skippedUnits = absoluteDelta / 1000
                data.repairTimer = data.repairTimer - skippedUnits
            end
        end
    end

    -- Always update the tracking anchor at the very end of the frame
    self.lastAbsoluteTime = currentAbsTime

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

    -- Get filename to check if it's a vehicle or placeable
    local rawFilename = target.i3dFilename or ""
    local lowerRawFilename = string.lower(rawFilename)

    -- ONLY allow vehicles to be destroyed. Reject placeables/buildings entirely.
    if string.find(lowerRawFilename, "placeables/") or not string.find(lowerRawFilename, "vehicles/") then
        return
    end

    if target.rootNode and TornadoAPI and TornadoAPI:isNodeProtected(target.rootNode) then
        return -- The node was protected by another mod, abort destruction!
    end

    -- ==========================================================
    -- CACHE CHECK: Did we already scan this target previously?
    -- SMART CACHE: Prevents the 120ms lag loop while allowing
    -- the vehicle to be re-scanned if the player buys new parts later.
    -- ==========================================================
    if target.tornadoLastDestructionScan and g_currentMission.time < (target.tornadoLastDestructionScan + 10000) then
        return
    end
    -- =================================================================================================================

    -- ==========================================================
    -- INDOOR / COVER PROTECTION CHECK
    -- ==========================================================
    local x, y, z = getWorldTranslation(target.rootNode)
    if x ~= nil and z ~= nil then
        local isIndoor = false
        if g_currentMission.indoorMask ~= nil then
            isIndoor = g_currentMission.indoorMask:getIsIndoorAtWorldPosition(x, z)
        end

        local indoorDamageEnabled = TornadoPhysics.settings and TornadoPhysics.settings.indoor_damage

        -- If the vehicle is under a roof AND indoor damage is disabled, abort destruction!
        if isIndoor and not indoorDamageEnabled then
            if TornadoDebug and TornadoDebug.verboseIndoorBypass then
                TornadoDebug:log("DESTRUCTION", "SKIPPED -> " .. tostring(rawFilename) .. " (Vehicle is indoors/covered)")
            end

            return
        end
    end
    -- ==========================================================

    local filename = self:_cleanFilename(rawFilename)

    -- [CHECK] File-level Ignore with DEBUG LOGGING
    local filenameLower = string.lower(filename)
    for _, keyword in ipairs(self.IgnoreList) do
        if string.find(filenameLower, keyword, 1, true) then
            -- log this specific file path once per storm cycle
            if not self.loggedIgnoredFiles[filenameLower] then
                if TornadoDebug then
                    TornadoDebug:log("DESTRUCTION", "IGNORED FILE -> " .. filename .. " (Matches: '" .. keyword .. "')")
                end
                self.loggedIgnoredFiles[filenameLower] = true
            end
            return
        end
    end

    if TornadoDebug then
        TornadoDebug:log("DESTRUCTION", "--------------------------------------------------")
        TornadoDebug:log("DESTRUCTION", "Processing Vehicle -> " .. tostring(filename))
    end

    -- 1. IDENTIFY TARGETS
    local targetList = {}
    local isGlobal = false

    if self.GlobalDatabase[filename] then
        targetList = self.GlobalDatabase[filename]
        isGlobal = true
    else
        targetList = self.FlatDefaults
    end

    -- 2. SORT CANDIDATES
    local foundTrash = {}
    local foundStructure = {}

    self:_scanForCandidates(target.rootNode, targetList, self.SEARCH_BUDGET, isGlobal, foundTrash, foundStructure)

    -- 3. EXECUTE DESTRUCTION
    local finalHiddenNodes = {}

    -- A. Hide ALL Trash
    for _, nodeData in ipairs(foundTrash) do
        if TornadoDebug and TornadoDebug.verboseDestruction then
            TornadoDebug:log("DESTRUCTION", "   >> HIDING (Trash): " .. nodeData.name)
        end
        setVisibility(nodeData.id, false)
        table.insert(finalHiddenNodes, nodeData)
    end

    -- B. Hide Lottery Structure
    local structLimit = math.random(self.MIN_STRUCT_TO_DESTROY, self.MAX_STRUCT_TO_DESTROY)
    local structCount = 0

    self:_shuffleTable(foundStructure)

    for _, nodeData in ipairs(foundStructure) do
        if structCount >= structLimit then break end

        if TornadoDebug and TornadoDebug.verboseDestruction then
            TornadoDebug:log("DESTRUCTION", "   >> HIDING (Struct): " .. nodeData.name)
        end
        setVisibility(nodeData.id, false)
        table.insert(finalHiddenNodes, nodeData)
        structCount = structCount + 1
    end

    -- 4. SAVE RESULT
    if #finalHiddenNodes > 0 then
        if TornadoDebug and TornadoDebug.verboseDestruction then
            TornadoDebug:log("DESTRUCTION",
                string.format("RESULT -> Hid %d Trash, %d/%d Structure.", #foundTrash, structCount, structLimit))
        end

        -- [SMART CACHE TAG]
        target.tornadoLastDestructionScan = g_currentMission.time

        -- Just set the countdown total (24 hours in milliseconds)
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

        -- ==========================================================
        -- TRIGGER EMERGENCY DLC
        -- Vehicle has been confirmed destroyed. Dispatch rescue!
        -- ==========================================================
        -- if TornadoSettings.enableEmergencyDLC then
        --     if self.handleVehicleEmergencyTrigger then
        --         self:handleVehicleEmergencyTrigger(target)
        --     end
        -- end
        -- ==========================================================
    else
        if TornadoDebug then TornadoDebug:log("DESTRUCTION", "FAILED. No suitable vehicle parts found.") end

        -- [SMART CACHE TAG]
        target.tornadoLastDestructionScan = g_currentMission.time
    end
end

function TornadoDestruction:_scanForCandidates(rootNode, namesToHide, budget, isSpecificDB, outTrash, outStructure)
    local nodesToProcess = { rootNode }
    local processedCount = 0

    while #nodesToProcess > 0 do
        if processedCount >= budget then break end

        local currentNode = table.remove(nodesToProcess, 1)
        processedCount = processedCount + 1

        local nodeName = getName(currentNode) or ""
        local nodeNameLower = string.lower(nodeName)

        -- 1. [CHECK] Ignore List (Upgraded Optimized Engine)
        local skipNode = false
        if currentNode == rootNode then
            skipNode = true
        else
            -- Check the high-speed O(1) exact hash map first
            if self.IgnoreListExact[nodeNameLower] then
                skipNode = true
            else
                -- Fall back to wildcards/patterns only if exact match misses
                for _, pattern in ipairs(self.IgnoreListPatterns) do
                    if string.find(nodeNameLower, pattern, 1, true) ~= nil then
                        skipNode = true
                        break
                    end
                end
            end
        end

        -- 2. [PROCESS] Run matching engine ONLY if this specific node isn't ignored
        local skipChildren = false
        if not skipNode then
            local matched = false

            if isSpecificDB then
                -- Match against both case-sensitive and lower-case variants for safety
                if namesToHide[nodeName] ~= nil or namesToHide[nodeNameLower] ~= nil then
                    matched = true
                else
                    -- Fallback substring parsing for custom mod variables
                    for targetName, _ in pairs(namesToHide) do
                        if string.find(nodeNameLower, string.lower(targetName), 1, true) ~= nil then
                            matched = true
                            break
                        end
                    end
                end
            else
                -- Fallback to flat default array processing
                for _, entry in ipairs(namesToHide) do
                    local targetName = (type(entry) == "table") and entry.name or entry
                    if string.find(nodeNameLower, string.lower(targetName), 1, true) ~= nil then
                        matched = true
                        break
                    end
                end
            end

            if matched then
                -- CLASSIFY TRASH VS STRUCTURE
                local isTrash = false
                for _, trashKey in ipairs(self.TRASH_KEYWORDS) do
                    if string.find(nodeNameLower, trashKey, 1, true) then
                        isTrash = true
                        break
                    end
                end

                -- Check LOD parent
                local finalNode = currentNode
                local finalName = nodeName
                local parent = getParent(currentNode)
                if parent and parent ~= 0 then
                    local parentName = getName(parent) or ""
                    if string.find(string.lower(parentName), "lod", 1, true) then
                        finalNode = parent
                        finalName = parentName
                    end
                end

                -- Verify component visibility status
                if getVisibility(finalNode) then
                    if isTrash then
                        table.insert(outTrash, { id = finalNode, name = finalName })
                    else
                        table.insert(outStructure, { id = finalNode, name = finalName })
                    end
                else
                    if TornadoDebug and TornadoDebug.verboseDestruction then
                        TornadoDebug:log("DESTRUCTION", "   >> IGNORING (Unbought Config): " .. finalName)
                    end
                end

                -- Found a valid component mapping, flag to skip expanding this branch
                skipChildren = true
            end
        end

        -- 3. [RECURSE] Pull child elements forward unless explicit mapping matched
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
        -- Check if the countdown has hit zero!
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

        -- Grab the parent vehicle transform node from the first part in the data array
        if data.nodes and data.nodes[1] and entityExists(data.nodes[1].id) then
            local vehicleRoot = getParent(data.nodes[1].id)
            if vehicleRoot and entityExists(vehicleRoot) then
                -- Scrub any persistent/orphaned smoke or fire nodes off the vehicle
                self:purgeOrphanedFX(vehicleRoot)
            end
        end

        -- Loop through and turn visibility back on for broken components
        for _, nodeInfo in ipairs(data.nodes) do
            if entityExists(nodeInfo.id) then
                setVisibility(nodeInfo.id, true)
            end
        end

        -- Clear the object out of the tracking array
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

function TornadoDestruction:_findNodeByName(rootNode, targetName)
    if rootNode == nil or rootNode == 0 then return 0 end
    local nodesToProcess = { rootNode }
    local maxSearch = 2000
    local count = 0

    while #nodesToProcess > 0 do
        if count > maxSearch then break end
        local currentNode = table.remove(nodesToProcess, 1)
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
        for _, obj in ipairs(searchTargets) do
            local filename = self:_cleanFilename(obj.i3dFilename)
            if filename == pending.filename then
                local x, y, z = getWorldTranslation(obj.rootNode)
                if x ~= nil then
                    local dx, dy, dz = x - pending.x, y - pending.y, z - pending.z
                    if (dx * dx + dy * dy + dz * dz) < searchRadiusSq then
                        if TornadoDebug then TornadoDebug:log("DESTRUCTION", "RELINKING saved vehicle -> " .. filename) end

                        -- [THE FIX] Use our custom scanner instead of the broken I3DUtil command
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
                            repairTimer = pending.repairTimer, -- [FIXED]
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
        if not found then table.insert(stillPending, pending) end
    end
    self._pendingLoad = stillPending
end

---@param vehicle table The GIANTS engine vehicle object that was just destroyed
function TornadoDestruction:handleVehicleEmergencyTrigger(vehicle)
    if TornadoDebug then
        TornadoDebug:log("DESTRUCTION",
            "[EMERGENCY_HOOK] Vehicle destroyed! Checking emergency criteria...")
    end

    -- 1. Check if the feature is enabled via settings and the manager exists
    if not TornadoSettings.enableEmergencyDLC or TornadoEmergencyManager == nil then
        if TornadoDebug then
            TornadoDebug:log("DESTRUCTION",
                "[EMERGENCY_HOOK] ABORT: Integration disabled in settings or manager missing.")
        end
        return
    end

    -- 2. Prevent spam: Ensure this vehicle isn't already tied to an active emergency scene
    if vehicle.hasActiveEmergencyScenario then
        if TornadoDebug then
            TornadoDebug:log("DESTRUCTION",
                "[EMERGENCY_HOOK] ABORT: Vehicle already has an active disaster scene.")
        end
        return
    end

    -- 3. Flag it so it doesn't execute multiple times concurrently
    vehicle.hasActiveEmergencyScenario = true

    -- 4. Get the exact coordinates of the destroyed vehicle
    local x, y, z = getWorldTranslation(vehicle.rootNode)

    if TornadoDebug then
        TornadoDebug:log("DESTRUCTION",
            string.format("[EMERGENCY_HOOK] PASSED! Handoff to Manager -> Type: carCrash | X:%.2f, Z:%.2f", x, z))
    end

    -- 5. Hand over coordination to the emergency manager
    -- TornadoEmergencyManager:triggerDisasterScenario("carCrash", x, z, "tornadoVehicleCrash.xml")
    -- Randomly decide if the vehicle crash resulted in a fire or trapped passengers
    if math.random() > 0.5 then
        if TornadoDebug then TornadoDebug:log("DESTRUCTION", "Vehicle destroyed! Dispatching Car Crash Scenario.") end
        TornadoEmergencyManager:triggerDisasterScenario("carCrash", x, z, "tornadoVehicleCrash.xml")
    else
        if TornadoDebug then TornadoDebug:log("DESTRUCTION", "Vehicle destroyed! Dispatching Car Fire Scenario.") end
        TornadoEmergencyManager:triggerDisasterScenario("fire", x, z, "tornadoCarFire.xml")
    end
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

    -- 1. Check Server
    if g_server == nil then
        if TornadoDebug then TornadoDebug:log("DESTRUCTION", "TRACE: FAILED g_server check. Aborting save.") end
        return
    end
    if TornadoDebug then TornadoDebug:log("DESTRUCTION", "TRACE: g_server check passed.") end

    -- 2. Resolve Path
    local saveDir = self:_resolveSavegamePath()
    if saveDir == nil then
        if TornadoDebug then TornadoDebug:log("DESTRUCTION", "TRACE: FAILED to resolve savegame path. Aborting save.") end
        return
    end
    if TornadoDebug then TornadoDebug:log("DESTRUCTION", "TRACE: Save path resolved to -> " .. tostring(saveDir)) end

    -- 3. Create XML
    local filepath = saveDir .. self.DESTRUCTION_XML_FILE
    if TornadoDebug then TornadoDebug:log("DESTRUCTION", "TRACE: Attempting to create XML at -> " .. tostring(filepath)) end

    local xmlId = createXMLFile("TornadoDestruction", filepath, "TornadoDestruction")
    if xmlId == 0 then
        if TornadoDebug then TornadoDebug:log("DESTRUCTION", "TRACE: FAILED to create XML file. xmlId is 0. Aborting.") end
        return
    end
    if TornadoDebug then TornadoDebug:log("DESTRUCTION", "TRACE: XML file created successfully. ID: " .. tostring(xmlId)) end

    local objKey = "TornadoDestruction.destroyed.object"
    local i = 0

    local function writeEntry(data, x, y, z)
        --#region
        --local objKey = string.format("%s(%d)", key, i)
        local objKey = string.format("TornadoDestruction.destroyed.object%d", i)
        --#endregion
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
    -- 4. Process Destroyed Objects
    if self._destroyedObjects then
        local count = 0
        for _, data in pairs(self._destroyedObjects) do count = count + 1 end
        if TornadoDebug then
            TornadoDebug:log("DESTRUCTION",
                "TRACE: Found " .. count .. " items in _destroyedObjects table.")
        end

        for id, data in pairs(self._destroyedObjects) do
            -- We no longer check for rootNode. We just use our cached data!
            if data and data.filename then
                local x = data.lastX or 0
                local y = data.lastY or 0
                local z = data.lastZ or 0

                writeEntry(data, x, y, z)
                if TornadoDebug then
                    TornadoDebug:log("DESTRUCTION",
                        "TRACE: Wrote entry for -> " .. tostring(data.filename))
                end
            else
                if TornadoDebug then
                    TornadoDebug:log("DESTRUCTION",
                        "TRACE: Warning - Invalid data structure for ID: " .. tostring(id))
                end
            end
        end
    else
        if TornadoDebug then TornadoDebug:log("DESTRUCTION", "TRACE: _destroyedObjects table is nil.") end
    end

    -- 5. Process Pending Loads
    if self._pendingLoad then
        for _, pending in ipairs(self._pendingLoad) do
            if pending then
                writeEntry(pending, pending.x or 0, pending.y or 0, pending.z or 0)
                if TornadoDebug then
                    TornadoDebug:log("DESTRUCTION",
                        "TRACE: Wrote pending entry for -> " .. tostring(pending.filename))
                end
            end
        end
    end

    saveXMLFile(xmlId)
    delete(xmlId)
    if TornadoDebug then TornadoDebug:log("DESTRUCTION", "SUCCESS. Saved " .. i .. " vehicle objects to XML.") end
end

function TornadoDestruction:_loadFromXML()
    if TornadoDebug then TornadoDebug:log("DESTRUCTION", "TRACE: _loadFromXML triggered.") end

    if g_server == nil then
        if TornadoDebug then TornadoDebug:log("DESTRUCTION", "TRACE: FAILED g_server check. Aborting load.") end
        return
    end

    local saveDir = self:_resolveSavegamePath()
    if saveDir == nil then
        if TornadoDebug then TornadoDebug:log("DESTRUCTION", "TRACE: FAILED to resolve savegame path. Aborting load.") end
        return
    end

    local filepath = saveDir .. self.DESTRUCTION_XML_FILE
    if TornadoDebug then TornadoDebug:log("DESTRUCTION", "TRACE: Looking for XML at -> " .. tostring(filepath)) end

    if not fileExists(filepath) then
        if TornadoDebug then TornadoDebug:log("DESTRUCTION", "TRACE: No save XML found. This is normal for a fresh save.") end
        return
    end

    local xmlId = loadXMLFile("TornadoDestruction", filepath)
    if xmlId == 0 then
        if TornadoDebug then TornadoDebug:log("DESTRUCTION", "TRACE: FAILED to load XML file. xmlId is 0.") end
        return
    end
    if TornadoDebug then TornadoDebug:log("DESTRUCTION", "TRACE: XML loaded successfully.") end

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
            nodes = nodes
        })

        i = i + 1
    end

    delete(xmlId)
    if TornadoDebug then TornadoDebug:log("DESTRUCTION", "SUCCESS. Loaded " .. i .. " pending vehicle objects.") end
end

function TornadoDestruction:purgeOrphanedFX(vehicleNode)
    if not vehicleNode or not entityExists(vehicleNode) then return end

    local nodesToProcess = { vehicleNode }
    while #nodesToProcess > 0 do
        local currentNode = table.remove(nodesToProcess, 1)

        -- Loop backwards to safely delete child items without breaking indexing
        local numChildren = getNumOfChildren(currentNode)
        for i = numChildren - 1, 0, -1 do
            local child = getChildAt(currentNode, i)
            if child and entityExists(child) then
                local name = getName(child) or ""
                local lowerName = string.lower(name)

                if string.find(lowerName, "smoketrail", 1, true) or string.find(lowerName, "firetrail", 1, true) then
                    if TornadoDebug then
                        TornadoDebug:log("DESTRUCTION", string.format("Stripping orphaned visual FX node: %s", name))
                    end
                    delete(child)
                else
                    table.insert(nodesToProcess, child)
                end
            end
        end
    end
end

return TornadoDestruction
