-- Smart Zone Tracking: Lua 5.1 unit regression, no live WoW client needed.
local currentMap = 3
local inCombat = false
local events, pending = {}, {}
local watches, changes = {[301]=true}, {}
local logs = {
    {isHeader=true,title="Duskwood"},
    {questID=101,title="Night Watch"},
    {questID=102,title="Worgen in the Woods"},
    {isHeader=true,title="Redridge Mountains"},
    {questID=201,title="A Threat Within"},
    {isHeader=true,title="Other"},
    {questID=301,title="Personal Dungeon Quest"},
    {questID=401,title="Objective in Duskwood"},
}
local mapInfo = {
    [1]={name="Duskwood",mapType=3,parentMapID=0},
    [2]={name="Redridge Mountains",mapType=3,parentMapID=0},
    [3]={name="Darkshire",mapType=5,parentMapID=1},
}
_G.ChalkBoxZoneDB = nil
_G.C_Map = {
    GetBestMapForUnit=function(unit) assert(unit=="player"); return currentMap end,
    GetMapInfo=function(id) return mapInfo[id] end
}
_G.C_QuestLog = {
    GetNumQuestLogEntries=function() return #logs end,
    GetInfo=function(i) return logs[i] end,
    GetLogIndexForQuestID=function(id)
        for i,row in ipairs(logs) do if row.questID==id then return i end end
    end,
    GetQuestsOnMap=function(id)
        if id==1 then return {{questID=101},{questID=401},{questID=999}} end
        if id==2 then return {{questID=201}} end
        return {}
    end,
    GetNumQuestWatches=function()
        local n=0
        for _ in pairs(watches) do n=n+1 end
        return n
    end,
    GetQuestIDForQuestWatchIndex=function(index)
        local a={}
        for id in pairs(watches) do a[#a+1]=id end
        table.sort(a)
        return a[index]
    end,
    AddQuestWatch=function(id)
        assert(id~=999,"never track an unaccepted quest")
        watches[id]=true
        changes[#changes+1]="+"..id
        return false -- 'wasWatched' is deliberately NOT a success flag
    end,
    RemoveQuestWatch=function(id)
        assert(id~=301,"do not remove a pre-existing manual watch")
        watches[id]=nil
        changes[#changes+1]="-"..id
        return true
    end,
}
_G.InCombatLockdown=function() return inCombat end
_G.DEFAULT_CHAT_FRAME={AddMessage=function() end}
_G.C_Timer={After=function(_,fn) pending[#pending+1]=fn end}
local function Flush()
    for _=1,30 do
        if #pending==0 then return end
        local nextStep=table.remove(pending,1)
        nextStep()
    end
    error("Runaway quest update scheduling")
end
local frame
-- Capture the addon frame for event delivery.
_G.CreateFrame=function()
    local f={}
    function f:RegisterEvent(event) f[event]=true end
    function f:SetScript(_,handler) f.fire=handler end
    frame=f
    return f
end
assert(loadfile("QuestSense.lua"))("ChalkBox")
local function Fire(event,arg) assert(frame[event],event);frame.fire(frame,event,arg) end
Fire("ADDON_LOADED","ChalkBox")
assert(ChalkBoxZoneDB.enabled==true,"user-requested automatic zone mode is on by default")
Fire("PLAYER_ENTERING_WORLD")
Flush()
assert(watches[101] and watches[102] and watches[401],
    "accepted zone/header and map POI quests should be tracked")
assert(not watches[201] and not watches[999],"foreign and unaccepted quests remain untracked")
assert(watches[301],"manual watches remain untouched")
assert(ChalkBoxZoneDB.managed[101],"record ownership of actual watch even if API returned false")
currentMap=2
Fire("ZONE_CHANGED_NEW_AREA")
Flush()
assert(not watches[101] and not watches[102] and not watches[401],
    "addon-managed out-of-zone watches must be removed")
assert(watches[201] and watches[301],"new-zone quest watched; manual choice retained")
-- Untrack one of our automatic watches by hand: it should stay muted in this zone.
watches[201]=nil
Fire("QUEST_WATCH_LIST_CHANGED")
Flush()
assert(not watches[201],"manual untrack must not immediately be reversed")
currentMap=3
Fire("ZONE_CHANGED_NEW_AREA")
Flush()
currentMap=2
Fire("ZONE_CHANGED_NEW_AREA")
Flush()
assert(watches[201],"a new zone visit should reset temporary suppression")
ChalkBox_QuestCommand("off")
assert(ChalkBoxZoneDB.enabled==false and not watches[201] and watches[301],
    "turning off restores manual-only watches")
ChalkBox_QuestCommand("on")
Flush()
assert(watches[201] and watches[301],"turning on resumes auto tracking")
currentMap=3
inCombat=true
Fire("ZONE_CHANGED_NEW_AREA")
Flush()
assert(watches[201],"defer tracker changes during combat")
inCombat=false
Fire("PLAYER_REGEN_ENABLED")
Flush()
assert(watches[101] and not watches[201],"pending zone update executes when safe")
ChalkBox_QuestCommand("status")
print("PASS: map-only objective quests, quest-header fallback, zone switching, manual-watch preservation, manual removal, toggle, deferred combat update")
