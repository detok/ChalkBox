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
assert(watches[201] and not watches[301] and not watches[101] and not watches[102],
    "nearby-only remote cleanup: 201="..tostring(watches[201])..
    " 301="..tostring(watches[301]).." 101="..tostring(watches[101])..
    " 102="..tostring(watches[102]).." reason="..ChalkBox_QuestStatus().reason)
assert(ChalkBoxZoneDB.mode=="zone" and
    ChalkBoxZoneDB.suspendedManual[301] and ChalkBox_QuestStatus().hidden==1,
    "suspended manual watches are remembered, not forgotten")
-- The explicit Nearby setting includes previously manual, out-of-zone quests.
-- They must return only when relevant again, not require re-checking by hand.
watches[401]=true
Fire("QUEST_WATCH_LIST_CHANGED")
Flush()
assert(not watches[401] and ChalkBoxZoneDB.suspendedManual[401],
    "manual remote watch is hidden but remembered automatically")
-- No tracker edits with the map open: wait for OnHide and then reconcile.
mapShown=true
currentMap=3
Fire("ZONE_CHANGED_NEW_AREA")
Flush()
assert(watches[201] and not watches[101] and ChalkBox_QuestStatus().pending)
mapShown=false
closeMap()
Flush()
assert(not watches[201] and watches[101] and watches[102] and watches[401]
    and not watches[301],
    "map closing applies only currently matching zone watches")
assert(not ChalkBoxZoneDB.suspendedManual[401] and
    not ChalkBoxZoneDB.managed[401],
    "when a manual watch becomes nearby again it is restored as manual")
-- Manually unchecking a returned watch must stick until the zone changes.
watches[401]=nil
Fire("QUEST_WATCH_LIST_CHANGED")
Flush()
assert(not watches[401] and ChalkBoxZoneDB.muted[401],
    "QuestSense respects manual unwatch even after restoring a saved choice")
for i=1,4 do tickers[1]() end
Flush()
assert(not watches[401],
    "periodic Nearby refresh never overrides an intentional manual unwatch")
-- Recently accepted quests must not evade the active-zone filter.
logs[#logs+1]={isHeader=true,title="Redridge Mountains"}
logs[#logs+1]={questID=402,title="Fresh distant quest",
    hasLocalPOI=true,isOnMap=true}
Fire("QUEST_ACCEPTED",#logs,402)
Flush()
assert(not watches[402],
    "new or local-POI-marked remote quests cannot bypass Nearby-only")
-- A missed watch-change event is reconciled on the periodic safety scan.
watches[201]=true
for i=1,4 do tickers[1]() end
Flush()
assert(not watches[201] and ChalkBoxZoneDB.suspendedManual[201],
    "Nearby mode repairs tracker drift without pressing Refresh")
-- Likewise, defer updates while the separate quest log is open.
logShown=true
currentMap=2
Fire("ZONE_CHANGED_NEW_AREA")
Flush()
assert(watches[101] and not watches[201])
logShown=false
closeLog()
Flush()
assert(watches[201] and not watches[101] and
    not ChalkBoxZoneDB.suspendedManual[201],
    "returning to the area restores its manual watch automatically")
-- No map or POI support: smart mode must still do something useful.
C_Map=nil
C_QuestLog.GetQuestsOnMap=nil
ChalkBox_QuestCommand("smart")
Flush()
assert(watches[101] and watches[102] and watches[201] and watches[401],
    "smart mode uses accepted quest log even on clients missing all map-pin APIs")
assert(watches[301] and not ChalkBoxZoneDB.suspendedManual[301],
    "leaving Nearby restores manually selected watches even without map data")
-- Combat gating.
inCombat=true
ChalkBox_QuestCommand("zone")
Flush()
assert(ChalkBox_QuestStatus().pending)
inCombat=false
local zoneTextBefore=GetZoneText
GetZoneText=function() return "" end
Fire("PLAYER_REGEN_ENABLED")
Flush()
assert(ChalkBox_QuestStatus().pending and
    ChalkBox_QuestStatus().reason:find("zone data",1,true),
    "no zone evidence keeps existing watches instead of clearing them")
GetZoneText=zoneTextBefore
C_Map={
    GetBestMapForUnit=function() return currentMap end,
    GetMapInfo=function(id) return mapInfo[id] end,
}
C_QuestLog.GetQuestsOnMap=function(id)
    if id==1 then return {{questID=101},{questID=401}} end
    if id==2 then return {{questID=201}} end
    return {}
end
Fire("ZONE_CHANGED_NEW_AREA")
Flush()
assert(ChalkBox_QuestStatus().reason=="ready",
    "nearby tracking automatically resumes when map data returns")
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
assert(not watches[101] and not watches[102] and
    not watches[401] and not watches[402] and watches[201],
    "disabling removes only auto watches and keeps restored manual watches")
assert(watches[301],"turning off never deletes manual watches")
ChalkBox_QuestCommand("on")
Flush()
assert(watches[101] and watches[301],"re-enabling works on the same session")
-- Smart should shift to a verified dungeon-only tracker when the player
-- enters a *specific* instance. Other dungeon quests and all outdoor
-- quests, including manual watches, must be hidden until exit.
mapInfo[10]={name="The Deadmines",mapType=4,parentMapID=1}
mapInfo[12]={name="Deadmines Lower Level",mapType=5,parentMapID=10}
mapInfo[11]={name="The Stockade",mapType=4,parentMapID=1}
mapInfo[13]={name="Unmapped Dungeon",mapType=4,parentMapID=1}
logs[#logs+1]={isHeader=true,title="The Deadmines"}
logs[#logs+1]={questID=601,title="Kill Edwin VanCleef"}
logs[#logs+1]={isHeader=true,title="Duskwood"}
logs[#logs+1]={questID=602,title="Dungeon loot on the map"}
logs[#logs+1]={isHeader=true,title="Other"}
logs[#logs+1]={questID=603,title="A quest tagged as dungeon",
    hasLocalPOI=true,isOnMap=true}
logs[#logs+1]={isHeader=true,title="The Stockade"}
logs[#logs+1]={questID=604,title="Stockade quest"}
C_QuestLog.GetQuestsOnMap=function(id)
    if id==10 then
        return {{questID=602},{questID=999}}
    elseif id==11 then return {{questID=604}} end
    return {}
end
ChalkBox_QuestCommand("smart")
currentMap=12
activeDungeon={name="The Deadmines",id=36}
mapShown=true
Fire("ZONE_CHANGED_NEW_AREA")
Flush()
assert(watches[301] and not watches[601] and
    ChalkBox_QuestStatus().pending,
    "opening the map still defers dungeon tracking edits")
mapShown=false
closeMap()
Flush()
assert(watches[601] and watches[602] and not watches[603]
    and not watches[604] and not watches[101] and not watches[301],
    "only quests verified for The Deadmines remain visible")
assert(ChalkBoxZoneDB.suspendedManual[301]
    and ChalkBox_QuestStatus().dungeon=="The Deadmines"
    and ChalkBox_QuestStatus().dungeonMatches==2,
    "manual watches remain saved and dungeon diagnostics list matched quests")
assert(not watches[999],"unaccepted dungeon map quest is never tracked")
-- A player unchecking a dungeon watch should not have their choice undone.
watches[601]=nil
Fire("QUEST_WATCH_LIST_CHANGED")
Flush()
assert(not watches[601] and ChalkBoxZoneDB.muted[601],
    "smart dungeon mode respects a manually unchecked dungeon quest")
for i=1,4 do tickers[1]() end
Flush()
assert(not watches[601],
    "periodic dungeon refresh does not override a manual unwatch")
-- Switching between two dungeons must change the filter, even when a
-- player remains in an instance and no outdoor-zone transition occurs.
currentMap=11
activeDungeon={name="The Stockade",id=34}
Fire("ZONE_CHANGED_NEW_AREA")
Flush()
assert(watches[604] and not watches[602] and not watches[601],
    "Stockade quests replace Deadmines quests instead of mixing them")
assert(ChalkBox_QuestStatus().dungeon=="The Stockade"
    and ChalkBox_QuestStatus().dungeonMatches==1,
    "Smart identifies the actual current instance rather than any dungeon")
-- If the client has neither relevant map pins nor matching quest
-- headers, preserve watches rather than silently wiping everything.
currentMap=13
activeDungeon={name="Unmapped Dungeon",id=999}
Fire("ZONE_CHANGED_NEW_AREA")
Flush()
assert(watches[604] and ChalkBox_QuestStatus().reason:
    find("no verified quests",1,true),
    "missing instance quest evidence preserves current watch state")
-- Normal Smart behavior returns immediately on leaving the instance.
activeDungeon=nil
currentMap=3
Fire("ZONE_CHANGED_NEW_AREA")
Flush()
assert(watches[301] and not ChalkBoxZoneDB.suspendedManual[301]
    and watches[101] and watches[102],
    "leaving a dungeon restores manual watches and regular Smart tracking")
assert(not ChalkBox_QuestStatus().dungeon,
    "dungeon diagnostics clear after returning outdoors")
-- When the arrow points at a quest, add it to Blizzard's existing
-- watch list even if automatic QuestSense management was disabled.
ChalkBox_QuestCommand("off")
Flush()
assert(type(ChalkBox_QuestNavFocus)=="function")
ChalkBox_QuestNavFocus(201)
Flush()
assert(watches[201] and not ChalkBoxZoneDB.managed[201]
    and ChalkBox_QuestStatus().navigationWatch==201,
    "navigation-selected quest becomes a native, manually owned watch")
-- Target changes never clear other player's manual watch selections.
ChalkBox_QuestNavFocus(401)
Flush()
assert(watches[201] and watches[401] and
    not ChalkBoxZoneDB.managed[401],
    "changing arrow target adds selected quest without removing other watches")
ChalkBox_QuestNavFocus(nil)
-- Native watch writes defer safely while in combat.
watches[201]=nil
inCombat=true
ChalkBox_QuestNavFocus(201)
Flush()
assert(not watches[201] and ChalkBox_QuestStatus().pending,
    "selected quest watch defers through combat lockdown")
inCombat=false
Fire("PLAYER_REGEN_ENABLED")
Flush()
assert(watches[201] and watches[401],
    "selected quest appears when combat ends, while prior watches remain")
-- Nearby filtering must not hide the very quest the arrow points at.
ChalkBox_QuestCommand("on")
ChalkBox_QuestCommand("zone")
currentMap=3
Flush()
assert(watches[201] and not ChalkBoxZoneDB.suspendedManual[201],
    "selected quest stays visible in Blizzard's tracker across zone filtering")
ChalkBox_QuestNavFocus(nil)
print("PASS: Forever Smart dungeon-only tracking, safe instance identity, manual watch restoration, unknown-data fallback, Nearby sync, and watch ownership")
