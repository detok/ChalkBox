-- ChalkBox: Smart Zone Tracking (Forever native quest watches).
-- Uses the Blizzard objective tracker, never creates a new UI.
-- Only removes watches the module originally added; preserves existing user watches.

local addonName = ...
local settings
local busy = false
local queued = false
local pending = false
local lastZoneID

local function Public(value)
    return value ~= nil and (type(issecretvalue) ~= "function" or not issecretvalue(value))
end

local function Number(value)
    return Public(value) and type(value) == "number" and value > 0
end

local function Note(message)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff55ccaaChalkBox|r " .. message)
    end
end

local function QuestAPI()
    return C_QuestLog
        and type(C_QuestLog.AddQuestWatch) == "function"
        and type(C_QuestLog.RemoveQuestWatch) == "function"
        and type(C_QuestLog.GetNumQuestWatches) == "function"
        and type(C_QuestLog.GetQuestIDForQuestWatchIndex) == "function"
        and type(C_QuestLog.GetNumQuestLogEntries) == "function"
        and type(C_QuestLog.GetInfo) == "function"
end

local function CurrentZone()
    if not C_Map or type(C_Map.GetBestMapForUnit) ~= "function"
        or type(C_Map.GetMapInfo) ~= "function" then return end
    local id = C_Map.GetBestMapForUnit("player")
    if not Number(id) then return end
    -- The best map may be a micro-zone. Prefer its zone parent (mapType=3).
    local visited = {}
    for _ = 1, 8 do
        if visited[id] then return end
        visited[id] = true
        local info = C_Map.GetMapInfo(id)
        if type(info) ~= "table" or not Public(info.name)
            or type(info.name) ~= "string" or not Public(info.mapType) then return end
        if info.mapType == 3 or info.mapType == 4 then
            return id, info.name
        end
        local parent = info.parentMapID
        if not Number(parent) then return end
        id = parent
    end
end

local function ActiveQuests()
    local active, underHeader = {}, nil
    local count = C_QuestLog.GetNumQuestLogEntries()
    if not Public(count) or type(count) ~= "number" or count < 0 then return end
    for i = 1, count do
        local info = C_QuestLog.GetInfo(i)
        if type(info) == "table" then
            if info.isHeader then
                if Public(info.title) and type(info.title) == "string" then
                    underHeader = info.title
                else
                    underHeader = nil
                end
            elseif Number(info.questID) and not info.isHidden then
                active[info.questID] = underHeader or false
            end
        end
    end
    return active
end

local function EligibleForZone(zoneID, zoneName)
    local active = ActiveQuests()
    if not active then return end
    local eligible = {}
    -- A quest with an objective/POI on the current zone map is directly relevant,
    -- even if its log category refers to another region.
    if type(C_QuestLog.GetQuestsOnMap) == "function" then
        local listed = C_QuestLog.GetQuestsOnMap(zoneID)
        if type(listed) == "table" then
            for _, quest in ipairs(listed) do
                if type(quest) == "table" and Number(quest.questID) then
                    local id = quest.questID
                    local isAccepted = active[id] ~= nil
                    if not isAccepted and type(C_QuestLog.GetLogIndexForQuestID) == "function" then
                        local index = C_QuestLog.GetLogIndexForQuestID(id)
                        if Number(index) then
                            local info = C_QuestLog.GetInfo(index)
                            isAccepted = type(info) == "table" and not info.isHeader
                                and not info.isHidden and info.questID == id
                        end
                    end
                    if isAccepted then eligible[id] = true end
                end
            end
        end
    end
    -- Some accepted quests have no map POI at all. An exact quest-log zone
    -- header is a useful secondary signal, without guessing distant objectives.
    for id, header in pairs(active) do
        if type(header) == "string" and string.lower(header) == string.lower(zoneName) then
            eligible[id] = true
        end
    end
    return eligible
end

local function Watches()
    local result = {}
    local count = C_QuestLog.GetNumQuestWatches()
    if not Public(count) or type(count) ~= "number" or count < 0 then return end
    for index = 1, count do
        local id = C_QuestLog.GetQuestIDForQuestWatchIndex(index)
        if Number(id) then result[id] = true end
    end
    return result
end

local function ForgetUnavailable(watches)
    for id in pairs(settings.managed) do
        if not watches[id] then
            -- The player may have manually unchecked one of our watches.
            settings.managed[id] = nil
            settings.muted[id] = true
        end
    end
end

local function Reconcile()
    queued = false
    if not settings or not settings.enabled or not QuestAPI() then return end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        pending = true
        return
    end
    local zoneID, zoneName = CurrentZone()
    if not zoneID then return end
    local desired = EligibleForZone(zoneID, zoneName)
    local watches = Watches()
    if not desired or not watches then return end

    local changed = zoneID ~= lastZoneID
    if changed then
        settings.muted = {}
        lastZoneID = zoneID
    else
        ForgetUnavailable(watches)
    end

    busy = true
    -- Remove only the watches we added. Never wipe a user's pre-existing watches.
    for questID in pairs(settings.managed) do
        if not desired[questID] then
            if watches[questID] then
                C_QuestLog.RemoveQuestWatch(questID)
                watches[questID] = nil
            end
            settings.managed[questID] = nil
        end
    end

    local ids = {}
    for id in pairs(desired) do ids[#ids + 1] = id end
    table.sort(ids)
    for _, id in ipairs(ids) do
        if not watches[id] and not settings.muted[id] then
            -- The API calls its return 'wasWatched', not 'wasAdded'.
            -- Query the actual watch list rather than interpreting that boolean.
            C_QuestLog.AddQuestWatch(id)
            local after = Watches()
            if after and after[id] then
                settings.managed[id] = true
                watches[id] = true
            end
        end
    end
    busy = false
    pending = false
end

local function QueueUpdate()
    if not settings or not settings.enabled or queued then return end
    queued = true
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(0.25, Reconcile)
    else
        Reconcile()
    end
end

function ChalkBox_QuestCommand(input)
    if not settings then return end
    local cmd = string.lower((input or ""):match("^%s*(.-)%s*$") or "")
    if cmd == "on" then
        settings.enabled = true
        lastZoneID = nil
        QueueUpdate()
        Note("Zone quest tracking enabled.")
    elseif cmd == "off" then
        settings.enabled = false
        queued = false
        if QuestAPI() then
            local watches = Watches()
            if watches then
                for id in pairs(settings.managed) do
                    if watches[id] then C_QuestLog.RemoveQuestWatch(id) end
                end
            end
        end
        settings.managed, settings.muted = {}, {}
        Note("Zone quest tracking disabled. Your manual quest watches remain.")
    elseif cmd == "refresh" then
        lastZoneID = nil
        QueueUpdate()
        Note("Refreshing zone quest watches.")
    elseif cmd == "status" then
        local id, name = CurrentZone()
        local own = 0
        for _ in pairs(settings.managed) do own = own + 1 end
        Note("Zone quests " .. (settings.enabled and "ON" or "OFF") ..
            "; zone: " .. (name or "unknown") .. "; auto-watched: " .. own ..
            "; map ID: " .. tostring(id or "-"))
    else
        Note("Quest tracking: /chalk quests on | off | refresh | status")
    end
end

local events = CreateFrame("Frame")
for _, event in ipairs({
    "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED", "ZONE_CHANGED_NEW_AREA",
    "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN",
    "QUEST_WATCH_LIST_CHANGED", "PLAYER_REGEN_ENABLED",
}) do
    events:RegisterEvent(event)
end
events:SetScript("OnEvent", function(_, event, arg)
    if event == "ADDON_LOADED" then
        if arg ~= addonName then return end
        if type(ChalkBoxZoneDB) ~= "table" then ChalkBoxZoneDB = {} end
        settings = ChalkBoxZoneDB
        settings.enabled = settings.enabled ~= false
        if type(settings.managed) ~= "table" then settings.managed = {} end
        if type(settings.muted) ~= "table" then settings.muted = {} end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pending then QueueUpdate() end
    elseif event == "QUEST_WATCH_LIST_CHANGED" then
        if not busy then QueueUpdate() end
    else
        QueueUpdate()
    end
end)
