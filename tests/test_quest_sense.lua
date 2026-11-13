-- Forever QuestSense 2: accepted quest watches work without map pins.
-- Preserves manual watches; defers risky changes while map/quest log/combat is open.
local currentMap=3
local inCombat=false
local mapShown=false
local logShown=false
local pending,tickers,changes={},{},{}
local watches={[301]=true}
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
        assert(id~=301,"never remove user's manual watch")
        watches[id]=nil
        changes[#changes+1]="-"..id
        if frame then frame.fire(frame,"QUEST_WATCH_LIST_CHANGED") end
        return true
    end,
}
_G.GetZoneText=function() return currentMap==2 and "Redridge Mountains" or "Darkshire" end
_G.InCombatLockdown=function() return inCombat end
_G.IsInInstance=function() return false,"none" end
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
assert(loadfile("QuestSense.lua"))("ChalkBox")
local function Fire(event,a,b)
    assert(frame.events[event],"must register "..event)
    frame.fire(frame,event,a,b)
end
Fire("ADDON_LOADED","ChalkBox")
assert(ChalkBoxZoneDB.enabled and ChalkBoxZoneDB.mode=="smart")
Fire("PLAYER_LOGIN")
Fire("PLAYER_ENTERING_WORLD")
Flush()
assert(watches[101] and watches[102] and watches[201] and watches[401] and watches[301],
    "smart mode must track accepted quests whether or not they have on-map POIs")
assert(not watches[999],"a POI for an unaccepted quest must NEVER be tracked")
assert(ChalkBoxZoneDB.managed[101] and not ChalkBoxZoneDB.managed[301],
    "only automatic watches are owned by ChalkBox")
local st=ChalkBox_QuestStatus()
assert(st.api and st.accepted==5 and st.auto==4 and st.reason=="ready")
assert(#tickers==1,"deferred watch edits can retry after map closes")
-- Manual unwatch must be respected, even though the quest remains accepted.
watches[201]=nil
Fire("QUEST_WATCH_LIST_CHANGED")
Flush()
assert(not watches[201] and ChalkBoxZoneDB.muted[201],
    "manual unwatch must not instantly be undone")
-- Zone change allows previously muted quests to be reconsidered.
currentMap=2
Fire("ZONE_CHANGED_NEW_AREA")
Flush()
assert(watches[201],"new zone visit resets muted auto watch")
-- A strict zone mode remains available to avoid clutter for players who want it.
ChalkBox_QuestCommand("zone")
Flush()
assert(watches[201] and watches[301] and not watches[101] and not watches[102],
    "nearby-only drops previous auto watches but preserves manual")
assert(ChalkBoxZoneDB.mode=="zone")
-- No tracker edits with the map open: wait for OnHide and then reconcile.
mapShown=true
currentMap=3
Fire("ZONE_CHANGED_NEW_AREA")
Flush()
assert(watches[201] and not watches[101] and ChalkBox_QuestStatus().pending)
mapShown=false
closeMap()
Flush()
assert(not watches[201] and watches[101] and watches[102] and watches[401],
    "map closing unlocks queued current-zone watch changes")
-- Likewise, defer updates while the separate quest log is open.
logShown=true
currentMap=2
Fire("ZONE_CHANGED_NEW_AREA")
Flush()
assert(watches[101] and not watches[201])
logShown=false
closeLog()
Flush()
assert(watches[201] and not watches[101])
-- No map or POI support: smart mode must still do something useful.
C_Map=nil
C_QuestLog.GetQuestsOnMap=nil
ChalkBox_QuestCommand("smart")
Flush()
assert(watches[101] and watches[102] and watches[201] and watches[401],
    "smart mode uses accepted quest log even on clients missing all map-pin APIs")
assert(watches[301],"manual remains untouched without map info")
-- Combat gating.
inCombat=true
ChalkBox_QuestCommand("zone")
Flush()
assert(ChalkBox_QuestStatus().pending)
inCombat=false
Fire("PLAYER_REGEN_ENABLED")
Flush()
assert(ChalkBox_QuestStatus().reason=="ready")
-- No API: state reports the reason instead of silently appearing functional.
local old=C_QuestLog.GetNumQuestWatches
C_QuestLog.GetNumQuestWatches=nil
ChalkBox_QuestCommand("status")
assert(messages[#messages]:find("MISSING",1,true),
    "diagnostics show missing Forever watch methods")
C_QuestLog.GetNumQuestWatches=old
ChalkBox_QuestCommand("all")
Flush()
ChalkBox_QuestCommand("limit 5")
Flush()
assert(ChalkBox_QuestStatus().limit==5)
ChalkBox_QuestCommand("off")
Flush()
assert(not watches[101] and not watches[102] and not watches[201] and not watches[401],
    "disabling removes only our auto watches")
assert(watches[301],"turning off never deletes manual watches")
ChalkBox_QuestCommand("on")
Flush()
assert(watches[101] and watches[301],"re-enabling works on the same session")
print("PASS: Forever C_QuestLog accepted-quest fallback, strict-zone mode, watch diff, event gating, manual unwatch, API diagnostics, limit and reset")
