-- Forever QuestSense 2: accepted quest watches work without map pins.
-- Preserves manual watches; defers risky changes while map/quest log/combat is open.
local currentMap=3
local inCombat=false
local mapShown=false
local logShown=false
local pending,tickers,changes={},{},{}
local watches={[301]=true}
local activeDungeon=nil
local logs={
    {isHeader=true,title="Duskwood"},
    {questID=101,title="Night Watch"},
    {questID=102,title="Worgen in the Woods"},
    {isHeader=true,title="Redridge Mountains"},
    {questID=201,title="A Threat Within"},
    {isHeader=true,title="Other"},
    {questID=301,title="Personal Dungeon Quest"},
    {questID=401,title="Objective in Duskwood"},
}
local mapInfo={
    [1]={name="Duskwood",mapType=3,parentMapID=0},
    [2]={name="Redridge Mountains",mapType=3,parentMapID=0},
    [3]={name="Darkshire",mapType=5,parentMapID=1},
}
_G.ChalkBoxZoneDB=nil
_G.C_Map={
    GetBestMapForUnit=function(unit) assert(unit=="player");return currentMap end,
    GetMapInfo=function(id) return mapInfo[id] end,
}
local frame
_G.WorldMapFrame={
    IsShown=function() return mapShown end,
    HookScript=function(_,event,callback) assert(event=="OnHide");_G.closeMap=callback end,
}
_G.QuestLogFrame={
    IsShown=function() return logShown end,
    HookScript=function(_,event,callback) assert(event=="OnHide");_G.closeLog=callback end,
}
_G.C_QuestLog={
    GetNumQuestLogEntries=function() return #logs end,
    GetInfo=function(i) return logs[i] end,
    GetQuestsOnMap=function(id)
        if id==1 then return {{questID=101},{questID=401},{questID=999}} end
        if id==2 then return {{questID=201}} end
        return {}
    end,
    GetNumQuestWatches=function()
        local n=0;for _ in pairs(watches) do n=n+1 end
        return n
    end,
    GetQuestIDForQuestWatchIndex=function(index)
        local a={};for id in pairs(watches) do a[#a+1]=id end
        table.sort(a)
        return a[index]
    end,
    AddQuestWatch=function(id)
        assert(id~=999,"never watch a quest not accepted")
        watches[id]=true
        changes[#changes+1]="+"..id
        if frame then frame.fire(frame,"QUEST_WATCH_LIST_CHANGED") end
        return false -- false is not proof that AddQuestWatch failed
    end,
    RemoveQuestWatch=function(id)
        if id==301 then
            assert(ChalkBoxZoneDB.mode=="zone" or
                (ChalkBoxZoneDB.mode=="smart" and activeDungeon),
                "manual watch is hidden only in Nearby or confirmed dungeon Smart mode")
        end
        watches[id]=nil
        changes[#changes+1]="-"..id
        if frame then frame.fire(frame,"QUEST_WATCH_LIST_CHANGED") end
        return true
    end,
}
_G.GetZoneText=function() return currentMap==2 and "Redridge Mountains" or "Darkshire" end
_G.InCombatLockdown=function() return inCombat end
_G.IsInInstance=function()
    return activeDungeon~=nil,activeDungeon and "party" or "none"
end
_G.GetInstanceInfo=function()
    if activeDungeon then
        return activeDungeon.name,"party",1,"Normal",5,nil,nil,
            activeDungeon.id
    end
    return "Duskwood","none",0,nil,nil,nil,nil,0
end
_G.Constants={QuestWatchConsts={MAX_QUEST_WATCHES=10}}
local messages={}
_G.DEFAULT_CHAT_FRAME={AddMessage=function(_,msg) messages[#messages+1]=msg end}
_G.C_Timer={
    After=function(delay,fn)
        assert(delay>=0.3)
        pending[#pending+1]=fn
    end,
    NewTicker=function(_,fn) tickers[#tickers+1]=fn end,
}
local function Flush()
    for i=1,40 do
        if #pending==0 then return end
        local fn=table.remove(pending,1);fn()
    end
    error("runaway scheduled quest update")
end
_G.CreateFrame=function()
    local f={events={}}
    function f:RegisterEvent(e) self.events[e]=true end
    function f:SetScript(which,handler) self.fire=handler end
    frame=f
    return f
end
-- Isolate the selection budget to two managed watches and one manual watch.
Constants.QuestWatchConsts.MAX_QUEST_WATCHES=3
for _,q in ipairs(logs) do
    if q.questID==101 then q.level=34 end
    if q.questID==102 then q.level=30 end
    if q.questID==201 then q.level=25 end
    if q.questID==401 then q.level=28 end
end
C_QuestLog.GetDistanceSqToQuest=function(id)
    if id==102 then return 1600,true end
    if id==101 then return 90000,true end
    if id==201 then return 100,true end -- remote Redridge quest
    if id==401 then return nil end -- unknown distance
    return nil
end
local completeID=nil
C_QuestLog.IsComplete=function(id) return id==completeID end
-- Explicitly simulate the native Forever tracker list and verify that visual
-- sorting does NOT rewrite the watch list to reorder its rows.
local nativeBuilder=function()
    local ids={}
    for id in pairs(watches) do ids[#ids+1]=id end
    table.sort(ids)
    local result={}
    for i,id in ipairs(ids) do
        result[#result+1]={index=i,quest={GetID=function() return id end}}
    end
    return result
end
_G.QuestObjectiveTrackerMixin={BuildQuestWatchInfos=nativeBuilder}
-- Simulate an XML-built frame that has COPIED the method at construction.
_G.QuestObjectiveTracker={BuildQuestWatchInfos=nativeBuilder,
    Update=function(self) self.updated=true end}
assert(loadfile("QuestSense.lua"))("ChalkBox")
local function Fire(event,a,b)
    assert(frame.events[event],"missing event: "..event)
    frame.fire(frame,event,a,b)
end
Fire("ADDON_LOADED","ChalkBox")
assert(ChalkBoxZoneDB.smartSort=="nearest" and
    ChalkBoxZoneDB.smartNearbyFirst==true and
    ChalkBoxZoneDB.smartCompleteFirst==false,
    "Smart defaults to unfinished quests first, with completed turn-ins last")
Fire("PLAYER_LOGIN")
Flush()
assert(watches[101] and watches[102] and watches[301] and
    not watches[201] and not watches[401],
    "Smart keeps current-zone quests ahead of remote closer ones")
local rank=ChalkBox_QuestDisplayOrder()
assert(rank[102]<rank[101],
    "nearest native objective sorts before farther local objective")
ChalkBox_QuestCommand("sort level")
Flush()
assert(ChalkBox_QuestDisplayOrder()[102]<ChalkBox_QuestDisplayOrder()[101],
    "level-order Smart can choose a lower-level local quest")
ChalkBox_QuestCommand("sort nearest")
Flush()
ChalkBox_QuestCommand("completefirst on") -- deliberate opt-in to legacy priority
Flush()
-- Quest objective finishes during gameplay: Smart must keep the actual
-- completed quest watched so Blizzard can show its native Complete state.
completeID=401
Fire("QUEST_LOG_UPDATE")
Flush()
assert(watches[401] and watches[102] and watches[301]
    and not watches[101],
    "newly complete accepted quest replaces lower-priority uncompleted watch")
assert(ChalkBox_QuestDisplayOrder()[401] <
    ChalkBox_QuestDisplayOrder()[102],
    "newly complete quest ranks before nearby unfinished objectives")
ChalkBox_QuestCommand("completefirst off")
Flush()
assert(watches[101] and watches[102] and not watches[401],
    "explicit completed-first opt-out is preserved")
ChalkBox_QuestCommand("completefirst on")
Flush()
assert(watches[401] and not watches[101],
    "explicit completed-first toggle restores completed quest")
completeID=nil
Fire("QUEST_LOG_UPDATE")
Flush()
assert(watches[101] and watches[102] and not watches[401],
    "when quest is no longer reported complete, Smart returns to proximity")
ChalkBox_QuestCommand("sort nearest")
ChalkBox_QuestCommand("nearbyfirst off")
Flush()
assert(watches[201] and watches[102] and not watches[101]
    and not watches[401],
    "nearest-first mode without zone priority can select remote objectives")
ChalkBox_QuestCommand("nearbyfirst on")
Flush()
assert(watches[101] and watches[102] and watches[301] and not watches[201],
    "zone-first setting restores current-area choices")
assert(loadfile("QuestTrackerMenu.lua"))("ChalkBox")
local before=QuestObjectiveTracker:BuildQuestWatchInfos()
assert(before[1].quest:GetID()==101,"native order unchanged by default")
local originalMethod=QuestObjectiveTracker.BuildQuestWatchInfos
local writes=#changes
ChalkBox_QuestCommand("nativeorder on")
Flush()
assert(ChalkBoxZoneDB.nativeOrder==false
    and QuestObjectiveTracker.BuildQuestWatchInfos==originalMethod
    and QuestObjectiveTrackerMixin.BuildQuestWatchInfos==nativeBuilder,
    "taint protection never patches native tracker frame or prototype")
assert(#changes==writes,
    "blocked display-order toggle never rewrites watched quest list")
-- Nearby can pick up objective map data attached to a current subzone
-- rather than only inspecting the parent zone's map.
local getQuestsOnMap=C_QuestLog.GetQuestsOnMap
C_QuestLog.GetQuestsOnMap=function(id)
    if id==3 then return {{questID=201}} end
    return getQuestsOnMap(id)
end
ChalkBox_QuestCommand("zone")
Flush()
assert(watches[201],
    "Nearby recognizes verified quest objective POIs on local micro-map")
C_QuestLog.GetQuestsOnMap=getQuestsOnMap
C_QuestLog.GetNextWaypointForMap=function(id,map)
    if id==201 and map==1 then return .3,.4 end
end
Flush()
assert(watches[201],
    "Nearby accepts the client's actual map-scoped waypoint coordinates")
C_QuestLog.GetNextWaypointForMap=nil
ChalkBox_QuestCommand("range 0")
Flush()
assert(not watches[201],
    "default Nearby does not infer remote quest relevance from distance alone")
ChalkBox_QuestCommand("range 500")
Flush()
assert(watches[201] and ChalkBox_QuestStatus().nearbyRange==500,
    "optional Nearby native 500-yard radius includes legitimately close quest")
ChalkBox_QuestCommand("range 0")
Flush()
-- Simulate the full 40-quest Forever log. Unknown locations remain lower
-- priority, and only native available watch slots may be filled.
logs[#logs+1]={isHeader=true,title="Other"}
for i=1,35 do
    logs[#logs+1]={questID=1000+i,title="Later quest "..i,level=40}
end
ChalkBox_QuestCommand("smart")
Flush()
local st=ChalkBox_QuestStatus()
assert(st.accepted==40 and st.tracked<=3,
    "forty accepted quests remain bounded by Blizzard's real watch cap")
assert(watches[101] and watches[102],
    "known nearby objectives stay prioritized over 35 unlocated quests")
-- Check that a real movement-driven distance change refreshes the top rank
-- without requiring the player to re-open or modify the objective tracker.
C_QuestLog.GetDistanceSqToQuest=function(id)
    if id==101 then return 100,true end
    if id==102 then return 50000,true end
    if id==201 then return 90000,true end
    return nil
end
for i=1,4 do tickers[1]() end
Flush()
assert(ChalkBox_QuestDisplayOrder()[101]<
    ChalkBox_QuestDisplayOrder()[102],
    "Smart reevaluates nearest objectives on its twelve-second update")
ChalkBox_QuestCommand("sort lowest")
Flush()
assert(ChalkBox_QuestStatus().sort=="level",
    "Smart exposes Lowest level first without an alphabetical mode")
-- Nearby must consider sibling micro-maps and quest-specific waypoint maps,
-- rather than accepting only the one quest visible on the current micro-map.
mapInfo[4]={name="Worgen Grove",mapType=5,parentMapID=1}
C_Map.GetMapChildrenInfo=function(id,mapType,allDescendants)
    assert(mapType==5 and allDescendants==true)
    if id==1 then return {{mapID=4}} end
    return {}
end
local getOriginal=C_QuestLog.GetQuestsOnMap
C_QuestLog.GetQuestsOnMap=function(id)
    if id==4 then
        local result={}
        for questID=1501,1506 do
            result[#result+1]={questID=questID}
        end
        return result
    end
    return getOriginal(id)
end
for questID=1501,1507 do
    logs[#logs+1]={questID=questID,title="Local task "..questID,level=33}
end
C_QuestLog.GetNextWaypoint=function(id)
    if id==1507 then return 4,.35,.65 end
    if id==201 then return 2,.35,.65 end -- remote objective, never Nearby
end
Constants.QuestWatchConsts.MAX_QUEST_WATCHES=25
ChalkBox_QuestCommand("limit 5")
ChalkBox_QuestCommand("zone")
Flush()
assert(C_QuestLog.GetNumQuestWatches()==5,
    "Nearby fills all five slots when five local quests have native evidence")
assert(not watches[201] and not watches[301],
    "Nearby does not invent locality for other zones or manual dungeon quests")
ChalkBox_QuestCommand("limit 10")
Flush()
assert(C_QuestLog.GetNumQuestWatches()==10 and watches[1507] and
    not watches[201] and not watches[301],
    "Nearby fills ten verified objectives, including sibling micro-map waypoints")
local near=ChalkBox_QuestStatus()
assert(near.localCandidates==10 and near.eligibleCandidates==10
    and near.tracked==10 and near.shortfall==0,
    "Nearby diagnostics match the selected budget and verified candidate count")
ChalkBox_QuestCommand("sort closest")
Flush()
assert(ChalkBox_QuestStatus().sort=="nearest",
    "Closest first remains an available setting next to Lowest level first")
print("PASS: 5/10 Nearby filling from sibling maps and waypoints; closest/level priorities; protected Blizzard tracker")
