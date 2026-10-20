---@class TornadoInsuranceStateEvent
---@description server -> the players of one farm (or one joining player): that farm's insurance state, so the
--- control panel can show it. The server owns the state; clients only display it.
---   farm id, premiums paid, payouts received, crop policy (plan, coverage, status, open claims),
---   equipment policy (deductible, status), vehicle titles, total losses waiting for the farm's choice,
---   monthly history (premiums / payouts, per policy type) for the Payments section,
---   claim list for the Insurance tab (the newest MAX_CLAIM_LIST, TornadoInsurance:getClaimList),
---   inbox (key + parameters, day, read) - the newest MAX_INBOX

-- Events may only be registered while no mission exists (when the mod's scripts load). If this file is
-- loaded again for another savegame in the same game session, keep using the class registered the first time.
TornadoInsuranceStateEvent = EventIds.getEventClassByName("TornadoInsuranceStateEvent") or {}
local TornadoInsuranceStateEvent_mt = Class(TornadoInsuranceStateEvent, Event)

if EventIds.getEventClassByName("TornadoInsuranceStateEvent") == nil then
    InitEventClass(TornadoInsuranceStateEvent, "TornadoInsuranceStateEvent")
end

TornadoInsuranceStateEvent.MAX_INBOX = 50   -- 6 bits
TornadoInsuranceStateEvent.MAX_PARAMS = 15  -- 4 bits
TornadoInsuranceStateEvent.MAX_TITLES = 255 -- 8 bits
TornadoInsuranceStateEvent.MAX_TOTALS = 15  -- 4 bits
TornadoInsuranceStateEvent.MAX_CLAIM_LIST = 50  -- 6 bits
TornadoInsuranceStateEvent.MAX_HISTORY = 31     -- 5 bits (the farm keeps 24 months)
TornadoInsuranceStateEvent.CLAIM_VALUES = 6     -- numbers per claim summary
TornadoInsuranceStateEvent.CLAIM_KINDS = { "CROP", "EQUIP", "LIVESTOCK" }   -- 2 bits (index - 1)

function TornadoInsuranceStateEvent.emptyNew()
    return Event.new(TornadoInsuranceStateEvent_mt)
end

function TornadoInsuranceStateEvent.new(farmId, farm)
    local self = TornadoInsuranceStateEvent.emptyNew()
    self.farmId = farmId or 0
    self.state = farm
    return self
end

local function isNumberParam(paramType)
    return paramType == TornadoText.PARAM_NUMBER or paramType == TornadoText.PARAM_MONEY
end

function TornadoInsuranceStateEvent:writeStream(streamId, connection)
    local state = self.state or {}
    streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
    streamWriteFloat32(streamId, state.premiumsTotal or 0)
    streamWriteFloat32(streamId, state.payoutsTotal or 0)

    local crop = state.crop
    streamWriteString(streamId, crop ~= nil and crop.plan or "")
    streamWriteFloat32(streamId, crop ~= nil and crop.coverage or 0)
    streamWriteString(streamId, crop ~= nil and crop.status or "")
    local openClaims = TornadoInsuranceCrop ~= nil and TornadoInsuranceCrop:getOpenClaimCount(state) or 0
    if TornadoInsuranceEquipment ~= nil then
        openClaims = openClaims + TornadoInsuranceEquipment:getOpenClaimCount(state)
    end
    if TornadoInsuranceLivestock ~= nil then
        openClaims = openClaims + TornadoInsuranceLivestock:getOpenClaimCount(state)
    end
    streamWriteUIntN(streamId, math.min(openClaims, 255), 8)

    local equipment = state.equipment
    streamWriteInt32(streamId, equipment ~= nil and equipment.deductible or 0)
    streamWriteString(streamId, equipment ~= nil and equipment.status or "")
    local titles = {}
    for uniqueId, title in pairs(state.titles or {}) do
        if #titles < TornadoInsuranceStateEvent.MAX_TITLES then
            table.insert(titles, { uniqueId = uniqueId, title = title })
        end
    end
    streamWriteUIntN(streamId, #titles, 8)
    for _, entry in ipairs(titles) do
        streamWriteString(streamId, tostring(entry.uniqueId))
        streamWriteString(streamId, entry.title or "")
    end
    local totals = TornadoInsuranceEquipment ~= nil and TornadoInsuranceEquipment:getPendingTotals(state) or {}
    local numTotals = math.min(#totals, TornadoInsuranceStateEvent.MAX_TOTALS)
    streamWriteUIntN(streamId, numTotals, 4)
    for i = 1, numTotals do
        local claim = totals[i]
        streamWriteInt32(streamId, claim.id)
        streamWriteString(streamId, claim.name or "")
        streamWriteFloat32(streamId, claim.lossPayout or 0)
        streamWriteFloat32(streamId, claim.buyBackPayout or 0)
    end

    streamWriteString(streamId, state.livestock ~= nil and state.livestock.status or "")

    local claims = TornadoInsurance ~= nil and TornadoInsurance.getClaimList ~= nil and TornadoInsurance:getClaimList(self.farmId) or {}
    local numClaims = math.min(#claims, TornadoInsuranceStateEvent.MAX_CLAIM_LIST)
    streamWriteUIntN(streamId, numClaims, 6)
    for i = 1, numClaims do
        local claim = claims[i]
        local kindIndex = 1
        for k, kind in ipairs(TornadoInsuranceStateEvent.CLAIM_KINDS) do
            if kind == claim.kind then
                kindIndex = k
            end
        end
        streamWriteUIntN(streamId, kindIndex - 1, 2)
        streamWriteInt32(streamId, claim.id or 0)
        streamWriteInt32(streamId, claim.day or 0)
        streamWriteString(streamId, claim.status or "")
        streamWriteString(streamId, claim.subject or "")
        streamWriteString(streamId, claim.info or "")
        streamWriteString(streamId, claim.cause or "")
        for v = 1, TornadoInsuranceStateEvent.CLAIM_VALUES do
            streamWriteFloat32(streamId, claim.values ~= nil and claim.values[v] or 0)
        end
        streamWriteBool(streamId, claim.flag == true)
        streamWriteFloat32(streamId, claim.remaining or -1)
    end

    local history = state.history or {}
    local firstMonth = math.max(1, #history - TornadoInsuranceStateEvent.MAX_HISTORY + 1)
    streamWriteUIntN(streamId, #history - firstMonth + 1, 5)
    for i = firstMonth, #history do
        local month = history[i]
        streamWriteInt32(streamId, month.month or 0)
        streamWriteFloat32(streamId, month.premiums or 0)
        streamWriteFloat32(streamId, month.payouts or 0)
        streamWriteString(streamId, TornadoInsurance.encodeParts(month.premiumBy))
        streamWriteString(streamId, TornadoInsurance.encodeParts(month.payoutBy))
    end

    local inbox = state.inbox or {}
    local first = math.max(1, #inbox - TornadoInsuranceStateEvent.MAX_INBOX + 1)
    streamWriteUIntN(streamId, #inbox - first + 1, 6)
    for i = first, #inbox do
        local message = inbox[i]
        streamWriteString(streamId, message.key or "")
        streamWriteInt32(streamId, message.day or 0)
        streamWriteBool(streamId, message.read == true)
        local params = message.params or {}
        local count = math.min(#params, TornadoInsuranceStateEvent.MAX_PARAMS)
        streamWriteUIntN(streamId, count, 4)
        for p = 1, count do
            local param = params[p]
            streamWriteUIntN(streamId, param.type or 0, 2)
            if isNumberParam(param.type) then
                streamWriteFloat32(streamId, tonumber(param.value) or 0)
            else
                streamWriteString(streamId, tostring(param.value or ""))
            end
        end
    end
end

function TornadoInsuranceStateEvent:readStream(streamId, connection)
    self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
    local state = { inbox = {} }
    state.premiumsTotal = streamReadFloat32(streamId)
    state.payoutsTotal = streamReadFloat32(streamId)
    state.cropPlan = streamReadString(streamId)
    state.cropCoverage = streamReadFloat32(streamId)
    state.cropStatus = streamReadString(streamId)
    state.openClaims = streamReadUIntN(streamId, 8)
    state.equipDeductible = streamReadInt32(streamId)
    state.equipStatus = streamReadString(streamId)
    state.titles = {}
    local numTitles = streamReadUIntN(streamId, 8)
    for _ = 1, numTitles do
        local uniqueId = streamReadString(streamId)
        state.titles[uniqueId] = streamReadString(streamId)
    end
    state.equipTotals = {}
    local numTotals = streamReadUIntN(streamId, 4)
    for _ = 1, numTotals do
        table.insert(state.equipTotals, { id = streamReadInt32(streamId), name = streamReadString(streamId),
            lossPayout = streamReadFloat32(streamId), buyBackPayout = streamReadFloat32(streamId), status = "TOTAL" })
    end
    state.livestockStatus = streamReadString(streamId)
    state.claimList = {}
    local numClaims = streamReadUIntN(streamId, 6)
    for _ = 1, numClaims do
        local claim = { values = {} }
        claim.kind = TornadoInsuranceStateEvent.CLAIM_KINDS[streamReadUIntN(streamId, 2) + 1] or "CROP"
        claim.id = streamReadInt32(streamId)
        claim.day = streamReadInt32(streamId)
        claim.status = streamReadString(streamId)
        claim.subject = streamReadString(streamId)
        claim.info = streamReadString(streamId)
        claim.cause = streamReadString(streamId)
        for v = 1, TornadoInsuranceStateEvent.CLAIM_VALUES do
            claim.values[v] = streamReadFloat32(streamId)
        end
        claim.flag = streamReadBool(streamId)
        claim.remaining = streamReadFloat32(streamId)
        table.insert(state.claimList, claim)
    end
    state.history = {}
    local numMonths = streamReadUIntN(streamId, 5)
    for _ = 1, numMonths do
        table.insert(state.history, { month = streamReadInt32(streamId), premiums = streamReadFloat32(streamId),
            payouts = streamReadFloat32(streamId), premiumBy = TornadoInsurance.decodeParts(streamReadString(streamId)),
            payoutBy = TornadoInsurance.decodeParts(streamReadString(streamId)) })
    end
    local count = streamReadUIntN(streamId, 6)
    for _ = 1, count do
        local message = { params = {} }
        message.key = streamReadString(streamId)
        message.day = streamReadInt32(streamId)
        message.read = streamReadBool(streamId)
        local numParams = streamReadUIntN(streamId, 4)
        for p = 1, numParams do
            local paramType = streamReadUIntN(streamId, 2)
            local value
            if isNumberParam(paramType) then
                value = streamReadFloat32(streamId)
            else
                value = streamReadString(streamId)
            end
            message.params[p] = { type = paramType, value = value }
        end
        table.insert(state.inbox, message)
    end
    self.state = state
    self:run(connection)
end

function TornadoInsuranceStateEvent:run(connection)
    if not connection:getIsServer() or TornadoInsurance == nil then
        return
    end
    TornadoInsurance:applyFarmState(self.farmId, self.state)
end
