-- ChalkBox's original, deliberately small future-quest item index.
-- Manually researched factual item IDs, quest IDs, and quantities; this is
-- NOT a copied quest database, third-party code, or a current-quest tracker.
-- Sources and review boundaries: docs/FUTURE_QUEST_DATA.md
-- Only verified entries belong here. Absence is unknown, not safe to sell.
local itemUses = {
    [1274] = {{quest=117, amount=5}},   -- Hops
    [729]  = {{quest=38,  amount=3}},   -- Stringy Vulture Meat
    [730]  = {{quest=38,  amount=3},    -- Murloc Eye
              {quest=91920, amount=3}, {quest=92110, amount=3}},
    [731]  = {{quest=38,  amount=3}},   -- Goretusk Snout
    [732]  = {{quest=38,  amount=3}},   -- Okra
    [3172] = {{quest=418, amount=3}},   -- Boar Intestines
    [3173] = {{quest=418, amount=3}},   -- Bear Meat
    [3174] = {{quest=418, amount=3}},   -- Spider Ichor
    [1080] = {{quest=92,  amount=5}},   -- Tough Condor Meat
    [1081] = {{quest=92,  amount=5}},   -- Crisp Spider Meat
    [2296] = {{quest=92,  amount=5}},   -- Great Goretusk Snout
    [3110] = {{quest=416, amount=12}},  -- Tunnel Rat Ear
}
local questDetails = {
    [117] = {title="Thunderbrew", zone="Westfall", faction="Alliance",
             repeatable=true},
    [38]  = {title="Westfall Stew", zone="Westfall", faction="Alliance"},
    [418] = {title="Thelsamar Blood Sausages", zone="Loch Modan",
             faction="Alliance"},
    [92]  = {title="Redridge Goulash", zone="Redridge Mountains",
             faction="Alliance"},
    [416] = {title="Rat Catching", zone="Loch Modan", faction="Alliance"},
    [91920] = {title="Wild Eyes", zone="Silverpine Forest", faction="Horde"},
    [92110] = {title="My First Real Potion", zone="Westfall",
               faction="Alliance"},
}

local function Safe(value)
    return value ~= nil and (type(issecretvalue)~="function"
        or not issecretvalue(value))
end
local function Truth(fn,id)
    if type(fn)~="function" then return nil end
    local ok,yes=pcall(fn,id)
    if ok and Safe(yes) and type(yes)=="boolean" then return yes end
end
local function CurrentFaction()
    if type(UnitFactionGroup)~="function" then return nil end
    local ok,faction=pcall(UnitFactionGroup,"player")
    if ok and Safe(faction) and type(faction)=="string" then
        return faction
    end
end
local function ReadableID(itemID)
    if type(itemID)=="string" then
        itemID=itemID:match("^%d+$") and tonumber(itemID) or nil
    end
    if not Safe(itemID) or type(itemID)~="number"
        or itemID<=0 or itemID~=math.floor(itemID) then return nil end
    return itemID
end

-- Return detached data about quests NOT confirmed in the current quest log.
-- Never mark an item as actively needed; Blizzard and Core.lua own that.
-- An unavailable API returns unknown, never a fabricated completion status.
function ChalkBox_FutureQuestUses(itemID)
    itemID=ReadableID(itemID)
    local uses=itemID and itemUses[itemID]
    if not uses then return nil end
    local faction=CurrentFaction()
    local active=C_QuestLog and C_QuestLog.IsOnQuest
    local done=C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
    local titleForID=C_QuestLog and C_QuestLog.GetTitleForQuestID
    local out={}
    for _,entry in ipairs(uses) do
        local quest=questDetails[entry.quest]
        if quest and (not faction or not quest.faction
            or quest.faction==faction)
            and Truth(active,entry.quest)~=true
            and (quest.repeatable or Truth(done,entry.quest)~=true) then
            local title=quest.title
            if type(titleForID)=="function" then
                local ok,live=pcall(titleForID,entry.quest)
                if ok and Safe(live) and type(live)=="string"
                    and live~="" then title=live end
            end
            out[#out+1]={
                questID=entry.quest,
                questName=title,
                required=entry.amount,
                zone=quest.zone,
                -- This is researched reference data, NOT proof that the
                -- character can currently accept the quest on Forever.
                evidence="Reference",
            }
        end
    end
    return #out>0 and out or nil
end
