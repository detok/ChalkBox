-- Optional read-only item -> quest evidence from QuestieDB (WoW Forever).
-- No bundled DB, no quest-log writes, no inventory changes, no item deletion.
local provider
local ids
local position=1
local index={}
local ready=false
local started=false
local errors=0
local PRIORITY={objective=1,required=2,used=3,starts=4,provided=5,related=6}
local function Public(v)
    return v~=nil and (type(issecretvalue)~="function" or not issecretvalue(v))
end
local function Table(v)
    return Public(v) and type(v)=="table" and
        (type(issecrettable)~="function" or not issecrettable(v))
end
local function ID(v)
    return Public(v) and type(v)=="number" and v>0 and v==math.floor(v)
end
local function Library()
    local lib=LibQuestieDB
    return Table(lib) and Table(lib.Quest) and Table(lib.Item) and
        type(lib.Quest.Get)=="function" and
        type(lib.Quest.GetAllIds)=="function" and
        type(lib.Item.Get)=="function" and lib or nil
end
local function Read(entity,id,field)
    if not ID(id) then return nil end
    local ok,val=pcall(entity.Get,id,field)
    return ok and Public(val) and val or nil
end
local function Link(itemID,questID,role)
    if not ID(itemID) or not ID(questID) then return end
    local entries=index[itemID]
    if not entries then entries={};index[itemID]=entries end
    local previous=entries[questID]
    if not previous or PRIORITY[role]<PRIORITY[previous] then
        entries[questID]=role
    end
end
local function ScanQuest(questID)
    if not ID(questID) then return end
    local quest=provider.Quest
    local objectives=Read(quest,questID,"objectives")
    if Table(objectives) then
        local itemObjectives=objectives[3]
        if Table(itemObjectives) then
            for _,entry in pairs(itemObjectives) do
                if Table(entry) then Link(entry[1],questID,"objective") end
            end
        end
        local spellObjectives=objectives[6]
        if Table(spellObjectives) then
            for _,entry in pairs(spellObjectives) do
                if Table(entry) then Link(entry[3],questID,"used") end
            end
        end
    end
    local required=Read(quest,questID,"requiredSourceItems")
    if Table(required) then
        for _,itemID in pairs(required) do Link(itemID,questID,"required") end
    end
    Link(Read(quest,questID,"sourceItemId"),questID,"provided")
    local startedBy=Read(quest,questID,"startedBy")
    if Table(startedBy) and Table(startedBy[3]) then
        for _,itemID in pairs(startedBy[3]) do
            Link(itemID,questID,"starts")
        end
    end
end
local frame=CreateFrame("Frame")
frame:Hide()
local function Start()
    if started or ready then return end
    provider=Library()
    if not provider then return end
    local ok,list=pcall(provider.Quest.GetAllIds)
    if not ok or not Table(list) or #list==0 then return end
    ids=list -- QuestieDB's read-only sorted ID list. Never mutate it.
    started=true
    position=1
    frame:Show()
end
frame:SetScript("OnUpdate",function()
    if not started or ready then frame:Hide();return end
    if type(InCombatLockdown)=="function" and InCombatLockdown() then return end
    -- Avoid login stutters. Process bounded work, never build the index
    -- synchronously from a hover and never scan the entire DB in one frame.
    local clock=type(debugprofilestop)=="function" and debugprofilestop or nil
    local begin=clock and clock() or nil
    for n=1,48 do
        if position>#ids then
            ready=true
            ids=nil
            frame:Hide()
            return
        end
        local ok=pcall(ScanQuest,ids[position])
        if not ok then errors=errors+1 end
        position=position+1
        if begin and clock()-begin>=2 then return end
    end
end)

local function AddCandidate(found,questID,role)
    if not ID(questID) then return end
    local old=found[questID]
    if not old or PRIORITY[role]<PRIORITY[old] then found[questID]=role end
end
local function Flag(fn,questID)
    if type(fn)~="function" then return nil end
    local ok,value=pcall(fn,questID)
    if ok and Public(value) and type(value)=="boolean" then return value end
end
function ChalkBox_QuestItemDatabaseLinks(itemID)
    if not ID(itemID) then return nil end
    if not provider then Start() end
    if not provider then return nil end
    local found={}
    if index[itemID] then
        for questID,role in pairs(index[itemID]) do
            AddCandidate(found,questID,role)
        end
    end
    -- Item fields are direct lookups, useful even while the index builds.
    AddCandidate(found,Read(provider.Item,itemID,"startQuest"),"starts")
    local related=Read(provider.Item,itemID,"relatedQuests")
    if Table(related) then
        for _,questID in pairs(related) do
            AddCandidate(found,questID,"related")
        end
    end
    local quests={}
    for questID,role in pairs(found) do
        local title=Read(provider.Quest,questID,"name")
        if type(title)~="string" or title=="" then
            local getTitle=C_QuestLog and C_QuestLog.GetTitleForQuestID
            local ok,result=pcall(getTitle or function() end,questID)
            if ok and Public(result) and type(result)=="string" then
                title=result
            end
        end
        if type(title)=="string" and title~="" then
            local active=Flag(C_QuestLog and C_QuestLog.IsOnQuest,questID)
            local complete=Flag(C_QuestLog and
                C_QuestLog.IsQuestFlaggedCompleted,questID)
            quests[#quests+1]={id=questID,title=title,role=role,
                active=active,complete=complete}
        end
    end
    table.sort(quests,function(a,b)
        if (a.active==true)~=(b.active==true) then return a.active==true end
        if PRIORITY[a.role]~=PRIORITY[b.role] then
            return PRIORITY[a.role]<PRIORITY[b.role]
        end
        return a.id<b.id
    end)
    return quests
end
function ChalkBox_QuestItemDatabaseStatus()
    if ready then return "ready",position-1,errors end
    if started then return "indexing",position-1,#ids end
    return Library() and "not started" or "QuestieDB unavailable",0,0
end
local events=CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent",function(_,event,name)
    if event=="PLAYER_LOGIN" or event=="PLAYER_ENTERING_WORLD"
        or (event=="ADDON_LOADED" and name=="QuestieDB") then
        Start()
    end
end)
