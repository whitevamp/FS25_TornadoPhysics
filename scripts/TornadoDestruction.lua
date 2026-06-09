---@class TornadoDestruction
---@version 3.1 (VERBOSE + LOGIC FIX)
---@description Restored detailed print logs and increased destruction limits.

TornadoDestruction = {}

-- ============================================================================ 
-- Configuration
-- ============================================================================ 
TornadoDestruction.REPAIR_COOLDOWN_HOURS = 24
TornadoDestruction.DESTRUCTION_XML_FILE = "TornadoDestructionState.xml"
TornadoDestruction.SEARCH_BUDGET = 1000 

-- SAFETY LIMITS (Increased Max to 6 to handle larger buildings/vehicles)
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
    
    --self._savegameDir = g_currentMission.missionInfo.savegameDirectory .. "/"
    self._destroyedObjects = {}
    self._pendingLoad = {}

    local dir = baseDir or g_currentModDirectory
    if not dir then print("TornadoDestruction: ERROR - No Mod Dir") return end

    print("TornadoDestruction: V3.1 Initializing (Verbose Logging)...")

    local dbPath = Utils.getFilename("DB/TornadoMod_GlobalDatabase.lua", dir)
    if fileExists(dbPath) then
        source(dbPath) 
        if _G.TornadoMod_GlobalDatabase then
            self.GlobalDatabase = _G.TornadoMod_GlobalDatabase
            print("TornadoDestruction: GlobalDB Loaded: " .. getTableCount(self.GlobalDatabase))
            _G.TornadoMod_GlobalDatabase = nil 
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
        self.IgnoreList = _G.TornadoMod_IgnoreList or {}
        print("TornadoDestruction: Ignore List Loaded: " .. #self.IgnoreList)
        _G.TornadoMod_IgnoreList = nil
    end

    if g_currentMission.missionInfo ~= nil and g_currentMission.missionInfo.savegameDirectory ~= nil then
        self._savegameDir = g_currentMission.missionInfo.savegameDirectory .. "/"
    end
    
    self:_loadFromXML()
    self.isInitialized = true
end

function TornadoDestruction:deleteMap()
    if #self._destroyedObjects > 0 or #self._pendingLoad > 0 then self:_saveToXML() end
    self.isInitialized = false
end

function TornadoDestruction:update(dt)
    if #self._pendingLoad > 0 then self:_linkPendingObjects() end
    if #self._destroyedObjects > 0 then self:_updateRepairs(dt) end
end

-- ============================================================================ 
-- Main Destruction Logic
-- ============================================================================ 

function TornadoDestruction:destroyTarget(target)
    if not (TornadoPhysics and TornadoPhysics.settings and TornadoPhysics.settings.destructionEnabled) then return end
    if target == nil or target.rootNode == nil or not entityExists(target.rootNode) then return end

    local objectId = target.rootNode
    if self._destroyedObjects[objectId] ~= nil then return end 

    local filename = self:_cleanFilename(target.i3dFilename)
    
    -- [CHECK] File-level Ignore with DEBUG LOGGING
    local filenameLower = string.lower(filename)
    for _, keyword in ipairs(self.IgnoreList) do
        if string.find(filenameLower, keyword, 1, true) then 
            if TornadoDebug and TornadoDebug.verboseMode then
                print("TornadoDestruction: IGNORED FILE -> " .. filename .. " (Matches: '" .. keyword .. "')")
            end
            return 
        end
    end
    
    if TornadoDebug and TornadoDebug.verboseMode then
        print("--------------------------------------------------")
        print("TornadoDestruction: Processing -> " .. tostring(filename))
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
        if TornadoDebug and TornadoDebug.verboseMode then
             print("   >> HIDING (Trash): " .. nodeData.name)
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
        
        if TornadoDebug and TornadoDebug.verboseMode then
             print("   >> HIDING (Struct): " .. nodeData.name)
        end
        setVisibility(nodeData.id, false)
        table.insert(finalHiddenNodes, nodeData)
        structCount = structCount + 1
    end

    -- 4. SAVE RESULT
    if #finalHiddenNodes > 0 then
        if TornadoDebug and TornadoDebug.verboseMode then
            print(string.format("TornadoDestruction: RESULT -> Hid %d Trash, %d/%d Structure.", 
                #foundTrash, structCount, structLimit))
        end
        
        local repairTime = g_currentMission.time + (self.REPAIR_COOLDOWN_HOURS * 3600 * 1000)
        self._destroyedObjects[objectId] = {
            obj = target,
            filename = filename,
            nodes = finalHiddenNodes,
            repairTime = repairTime
        }
    else
        if TornadoDebug and TornadoDebug.verboseMode then print("TornadoDestruction: FAILED. No suitable parts found.") end
    end
end

function TornadoDestruction:_scanForCandidates(rootNode, namesToHide, budget, isSpecificDB, outTrash, outStructure)
    local nodesToProcess = {rootNode}
    local processedCount = 0

    while #nodesToProcess > 0 do
        if processedCount >= budget then break end

        local currentNode = table.remove(nodesToProcess, 1)
        processedCount = processedCount + 1
        
        local nodeName = getName(currentNode) or ""
        local nodeNameLower = string.lower(nodeName)
        
        -- [CHECK] Ignore List
        local skipNode = false
        for _, ignoreWord in ipairs(self.IgnoreList) do
            if string.find(nodeNameLower, ignoreWord, 1, true) then
                skipNode = true
                break
            end
        end
        if currentNode == rootNode then skipNode = true end

        if not skipNode then
            local matched = false
            
            -- CHECK AGAINST DB
            for _, entry in ipairs(namesToHide) do
                local targetName = (type(entry) == "table") and entry.name or entry
                
                if isSpecificDB then 
                    matched = (nodeName == targetName)
                else 
                    matched = string.find(nodeNameLower, string.lower(targetName), 1, true) ~= nil 
                end

                if matched then
                    -- CLASSIFY
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

                    if isTrash then
                        table.insert(outTrash, {id = finalNode, name = finalName})
                    else
                        table.insert(outStructure, {id = finalNode, name = finalName})
                    end
                    
                    break 
                end
            end
            
            -- Recurse children
            local numChildren = getNumOfChildren(currentNode)
            if numChildren > 0 then
                for i = 0, numChildren - 1 do
                    table.insert(nodesToProcess, getChildAt(currentNode, i))
                end
            end
        else
            -- Recurse children even if skipped
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
    local currentTime = g_currentMission.time
    local objectsToRepair = {}
    for id, data in pairs(self._destroyedObjects) do if currentTime >= data.repairTime then table.insert(objectsToRepair, id) end end
    for _, id in ipairs(objectsToRepair) do
        local data = self._destroyedObjects[id]
        if TornadoDebug and TornadoDebug.verboseMode then print("TornadoDestruction: REPAIRING -> " .. data.filename) end
        for _, nodeInfo in ipairs(data.nodes) do if entityExists(nodeInfo.id) then setVisibility(nodeInfo.id, true) end end
        self._destroyedObjects[id] = nil
    end
end
function TornadoDestruction:_cleanFilename(path)
    if path == nil or path == "" then return "unknown" end
    path = string.gsub(path, "\\", "/")
    local vPos = string.find(path, "vehicles/")
    local pPos = string.find(path, "placeables/")
    local startPos = vPos or pPos
    if startPos then return string.sub(path, startPos) end
    return path
end
function TornadoDestruction:_linkPendingObjects()
    if g_currentMission == nil then return end
    local stillPending = {}
    local searchRadiusSq = 1.0
    local searchTargets = {}
    if g_currentMission.vehicles then for _, v in pairs(g_currentMission.vehicles) do table.insert(searchTargets, v) end end
    if g_currentMission.placeableSystem and g_currentMission.placeableSystem.placeables then for _, p in pairs(g_currentMission.placeableSystem.placeables) do table.insert(searchTargets, p) end end
    for _, pending in ipairs(self._pendingLoad) do
        local found = false
        for _, obj in ipairs(searchTargets) do
            local filename = self:_cleanFilename(obj.i3dFilename)
            if filename == pending.filename then
                local x, y, z = getWorldTranslation(obj.rootNode)
                local dx, dy, dz = x - pending.x, y - pending.y, z - pending.z
                if (dx*dx + dy*dy + dz*dz) < searchRadiusSq then
                    if TornadoDebug and TornadoDebug.verboseMode then print("TornadoDestruction: RELINKING saved -> " .. filename) end
                    for _, nodeInfo in ipairs(pending.nodes) do
                        local foundNode = I3DUtil.findNode(obj.rootNode, nodeInfo.name, true)
                        if foundNode and foundNode ~= 0 then setVisibility(foundNode, false) nodeInfo.id = foundNode end
                    end
                    self._destroyedObjects[obj.rootNode] = { obj = obj, filename = filename, nodes = pending.nodes, repairTime = pending.repairTime }
                    found = true
                    break
                end
            end
        end
        if not found then table.insert(stillPending, pending) end
    end
    self._pendingLoad = stillPending
end
function TornadoDestruction:_saveToXML()
    if self._savegameDir == nil then return end
    local filepath = self._savegameDir .. self.DESTRUCTION_XML_FILE
    local xmlId = createXMLFile("TornadoDestruction", filepath)
    local key = "TornadoDestruction.destroyed.object"
    local i = 0
    local function writeEntry(data, x, y, z)
        local objKey = string.format("%s(%d)", key, i)
        setXMLString(xmlId, objKey .. ".filename", data.filename)
        setXMLFloat(xmlId, objKey .. ".posX", x)
        setXMLFloat(xmlId, objKey .. ".posY", y)
        setXMLFloat(xmlId, objKey .. ".posZ", z)
        setXMLFloat(xmlId, objKey .. ".repairTime", data.repairTime)
        local nodesStr = ""
        for _, nodeInfo in ipairs(data.nodes) do nodesStr = nodesStr .. nodeInfo.name .. ";" end
        setXMLString(xmlId, objKey .. ".nodes", nodesStr)
        i = i + 1
    end
    for _, data in pairs(self._destroyedObjects) do local x, y, z = getWorldTranslation(data.obj.rootNode) if x then writeEntry(data, x, y, z) end end
    for _, pending in ipairs(self._pendingLoad) do writeEntry(pending, pending.x, pending.y, pending.z) end
    saveXMLFile(xmlId)
    delete(xmlId)
    print("TornadoDestruction: Saved " .. i .. " objects.")
end
function TornadoDestruction:_loadFromXML()
    if self._savegameDir == nil then return end
    local filepath = self._savegameDir .. self.DESTRUCTION_XML_FILE
    if not fileExists(filepath) then return end
    local xmlId = loadXMLFile("TornadoDestruction", filepath)
    if xmlId == 0 then return end
    self._pendingLoad = {}
    local i = 0
    while true do
        local key = string.format("TornadoDestruction.destroyed.object(%d)", i)
        local filename = getXMLString(xmlId, key .. ".filename")
        if filename == nil then break end
        local nodesStr = getXMLString(xmlId, key .. ".nodes") or ""
        local nodes = {}
        for nodeName in string.gmatch(nodesStr, "([^;]+)") do table.insert(nodes, {id = 0, name = nodeName}) end
        table.insert(self._pendingLoad, { filename = filename, x = getXMLFloat(xmlId, key .. ".posX"), y = getXMLFloat(xmlId, key .. ".posY"), z = getXMLFloat(xmlId, key .. ".posZ"), repairTime = getXMLFloat(xmlId, key .. ".repairTime"), nodes = nodes })
        i = i + 1
    end
    delete(xmlId)
    print("TornadoDestruction: Loaded " .. i .. " pending objects.")
end

-- function TornadoDestruction.getXmlFilePath()
-- 	if g_currentMission.missionInfo then
-- 		local savegameDirectory = g_currentMission.missionInfo.savegameDirectory
-- 		if savegameDirectory ~= nil then
-- 			return ("%s/%s.xml"):format(savegameDirectory, self.DESTRUCTION_XML_FILE) --MOD_NAME)
-- 		-- else: Save game directory is nil if this is a brand new save
-- 		end
-- 	else
-- 		Logging.warning(MOD_NAME .. ": Could not get path to TornadoDestruction.xml settings file since g_currentMission.missionInfo is nil.")
-- 	end
-- 	return nil
-- end

return TornadoDestruction