-- Offline test for scripts/TornadoMessageLog.lua (Messages tab history) - Lua 5.1.
-- Run from the mod root:
--     lua-5.1.5_Win64_bin/lua5.1.exe tools/test/test_messagelog.lua
-- Exit code 0 = all checks passed.

local files, handles, nextHandle = {}, {}, 1
function createXMLFile(_, path) local h = nextHandle nextHandle = nextHandle + 1 handles[h] = { path = path, data = {} } return h end
function loadXMLFile(_, path)
    if files[path] == nil then return 0 end
    local h = nextHandle nextHandle = nextHandle + 1
    handles[h] = { path = path, data = files[path] }
    return h
end
local function setter(h, key, value) handles[h].data[key] = value end
setXMLFloat, setXMLInt, setXMLBool, setXMLString = setter, setter, setter, setter
local function getter(h, key) return handles[h].data[key] end
getXMLFloat, getXMLInt, getXMLBool, getXMLString = getter, getter, getter, getter
function saveXMLFile(h) files[handles[h].path] = handles[h].data end
function delete(h) handles[h] = nil end
function fileExists(path) return files[path] ~= nil end

MessageType = { HOUR_CHANGED = 1 }
local subscriptions = {}
g_messageCenter = { subscribe = function(_, kind, fn, target) subscriptions[kind] = { fn = fn, target = target } end,
    unsubscribeAll = function() subscriptions = {} end }
FarmManager = { SPECTATOR_FARM_ID = 0 }
local playerFarm = 1
local users = {}
g_farmManager = {
    getFarms = function() return { { farmId = 0 }, { farmId = 1 }, { farmId = 2 } } end,
    getFarmByUserId = function(_, userId) return { farmId = userId == 11 and 1 or 2 } end,
}
local environment = { currentMonotonicDay = 3, dayTime = 8 * 3600000 + 12 * 60000 }
g_currentMission = { getIsServer = function() return true end, getFarmId = function() return playerFarm end,
    environment = environment, userManager = { getUserByConnection = function(_, c) return users[c] end } }
TornadoSync = { isMultiplayer = function() return false end }
TornadoText = { PARAM_STRING = 0, PARAM_NUMBER = 1, PARAM_KEY = 2, PARAM_MONEY = 3,
    num = function(v) return { type = 1, value = v } end, get = function(k) return k == "tp_msg_day" and "Day" or k end,
    formatMessage = function(key, params) return key .. ":" .. tostring(params[1] and params[1].value or "") end }
TornadoDestruction = { _resolveSavegamePath = function() return "savegame1/" end }
TornadoMessageLogEvent = { ACTION_SAVE = 1, ACTION_REMOVE = 2 }

dofile("scripts/TornadoMessageLog.lua")
local L = TornadoMessageLog

local failures, total = 0, 0
local function check(label, got, want)
    total = total + 1
    if got ~= want then
        failures = failures + 1
        print(string.format("FAIL  %-60s got %s", label, tostring(got)))
    else
        print(string.format("ok    %-60s %s", label, tostring(got)))
    end
end
local function hours(n)
    environment.dayTime = environment.dayTime + n * 3600000
    while environment.dayTime >= 24 * 3600000 do
        environment.dayTime = environment.dayTime - 24 * 3600000
        environment.currentMonotonicDay = environment.currentMonotonicDay + 1
    end
    subscriptions[MessageType.HOUR_CHANGED].fn(subscriptions[MessageType.HOUR_CHANGED].target)
end

L:loadMap()
L:record("tp_msg_damage_report", { TornadoText.num(5) }, 3, 1)
L:record("tp_msg_touchdown", { TornadoText.num(2) }, 1, nil)
check("farm 1: own + everybody's message", #L:getFarm(1).recent, 2)
check("farm 2: only everybody's message", #L:getFarm(2).recent, 1)
check("spectator farm gets nothing", L.farms[0], nil)
local newest = L:getPlayerMessages("recent")
check("newest first", newest[1].key, "tp_msg_touchdown")
check("text in the player's language", L.getText(newest[2]), "tp_msg_damage_report:5")
check("time text", L.getTimeText(newest[1]), "Day 3, 08:12")

-- Save one, the other expires after 24 in-game hours.
local reportId = newest[2].id
check("save a recent message", L:saveMessage(1, reportId), true)
check("moved to saved", #L:getFarm(1).saved == 1 and #L:getFarm(1).recent == 1, true)
check("saving twice does nothing", L:saveMessage(1, reportId), false)
hours(23)
check("23 h later: recent still there", #L:getFarm(1).recent, 1)
hours(2)
check("25 h later: recent message gone", #L:getFarm(1).recent, 0)
check("saved message stays", #L:getFarm(1).saved, 1)

-- Permissions: only the farm's own players (or the admin) save / remove.
local own, other, admin = {}, {}, {}
users[own] = { getIsMasterUser = function() return false end, getId = function() return 11 end }
users[other] = { getIsMasterUser = function() return false end, getId = function() return 21 end }
users[admin] = { getIsMasterUser = function() return true end, getId = function() return 1 end }
check("player of farm 1 may edit farm 1", L:canEdit(own, 1), true)
check("player of farm 2 may not", L:canEdit(other, 1), false)
check("admin may", L:canEdit(admin, 1), true)
L:handleAction(other, 1, TornadoMessageLogEvent.ACTION_REMOVE, reportId)
check("remove refused for another farm", #L:getFarm(1).saved, 1)

-- Save / load
L:record("tp_msg_flood", { TornadoText.num(3) }, 3, 1)
L:save()
L:deleteMap()
L:loadMap()
check("saved restored", #L:getFarm(1).saved, 1)
check("recent restored", #L:getFarm(1).recent, 1)
check("number param restored as number", L:getFarm(1).saved[1].params[1].value, 5)
check("ids continue", L.nextId > reportId, true)

-- Remove through the player's request
L:request(TornadoMessageLogEvent.ACTION_REMOVE, reportId)
check("removed", #L:getFarm(1).saved, 0)

-- Cap
for i = 1, L.MAX_RECENT + 10 do L:record("tp_msg_x", { TornadoText.num(i) }, 3, 2) end
check("recent list capped", #L:getFarm(2).recent, L.MAX_RECENT)

print(string.format("\n%d / %d checks passed", total - failures, total))
os.exit(failures == 0 and 0 or 1)
