-- QuestSense Navigator: source-only quest points, map math, opt-in UI,
-- manual and tracked priority, coordinate safety, no game state mutations.
_G.ChalkBoxZoneDB={}
_G.BackdropTemplateMixin={}
local currentMap=1
local inInstance=false
local logLoading=false
local facing=0
local super=222
local destinations={
    [111]={1,0.5,0.2},
    [222]={1,0.8,0.5},
    [333]={2,0.3,0.3},
    [444]={3,0.5,0.5},
}
local entries={
    {isHeader=true,title="Westfall"},
    {questID=111,title="North Road"},
    {questID=222,title="The Far Farm"},
    {questID=333,title="Across Elwynn"},
    {questID=444,title="Across the Sea"},
    {questID=555,title="No Waypoint Yet"},
}
local created={}
local frames={}
_G.UIParent={
    GetCenter=function() return 800,500 end,
    GetTop=function() return 1000 end
}
_G.GetPlayerFacing=function() return facing end
_G.IsInInstance=function() return inInstance,inInstance and "party" or "none" end
_G.C_QuestLog={
    GetNumQuestLogEntries=function()
        return not logLoading and #entries or nil
    end,
    GetInfo=function(i) return entries[i] end,
    GetNextWaypoint=function(id)
        local d=destinations[id]
        if d then return d[1],d[2],d[3] end
    end,
    GetQuestsOnMap=function(mapID)
        if mapID==1 then return {{questID=555,mapID=1,x=0,y=0}} end
        return {}
    end,
}
_G.C_SuperTrack={GetSuperTrackedQuestID=function() return super end}
_G.C_Map={
    GetBestMapForUnit=function(unit)
        assert(unit=="player")
        return currentMap
    end,
    GetMapInfo=function(id)
        return {name="Zone "..id,mapType=3,parentMapID=0}
    end,
    GetPlayerMapPosition=function(id,unit)
        assert(unit=="player")
        if inInstance then return nil end
        return {x=0.5,y=0.5}
    end,
    GetWorldPosFromMapPos=function(id,pos)
        local continent=(id==3) and 1 or 0
        local offset=id==2 and 2000 or 0
        return continent,{x=1000-pos.x*1000+offset,
            y=1000-pos.y*1000+offset}
    end
}
_G.DEFAULT_CHAT_FRAME={AddMessage=function() end}
_G.InCombatLockdown=function() return false end
_G.CreateFrame=function(kind,name,parent,template)
    local f={kind=kind,name=name,parent=parent,template=template,
        children={},scripts={},shown=false}
    created[#created+1]=f
    if name then frames[name]=f end
    function f:RegisterEvent(event) self.events=self.events or {};
        self.events[event]=true end
    function f:SetScript(event,fn) self.scripts[event]=fn end
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:IsShown() return self.shown end
    function f:SetSize(w,h) self.w=w;self.h=h end
    function f:SetHeight(h) self.h=h end
    function f:GetHeight() return self.h end
    function f:SetPoint(...) self.point={...} end
    function f:ClearAllPoints() self.cleared=true end
    function f:SetFrameStrata(value) self.strata=value end
    function f:SetClampedToScreen(value) self.clamped=value end
    function f:SetMovable(value) self.movable=value end
    function f:EnableMouse(value) self.mouse=value end
    function f:RegisterForDrag(...) self.drag={...} end
    function f:SetText(value) self.caption=value end
    function f:StartMoving() self.started=true end
    function f:StopMovingOrSizing() self.stopped=true end
    function f:GetCenter() return 800,700 end
    function f:SetBackdrop(v) self.backdrop=v end
    function f:SetBackdropColor(...) self.color={...} end
    function f:SetBackdropBorderColor(...) self.border={...} end
    function f:CreateTexture()
        local t={shown=true}
        function t:SetTexture(v) self.texture=v end
        function t:SetAllPoints() self.all=true end
        function t:SetColorTexture(...) self.color={...} end
        function t:SetPoint(...) self.point={...} end
        function t:SetSize(w,h) self.w=w;self.h=h end
        function t:SetRotation(v) self.angle=v end
        function t:SetVertexColor(...) self.color={...} end
        function t:Hide() self.shown=false end
        function t:Show() self.shown=true end
        return t
    end
    function f:CreateFontString()
        local t={}
        function t:SetPoint(...) self.point={...} end
        function t:SetWidth(w) self.w=w end
        function t:SetJustifyH(h) self.align=h end
        function t:SetWordWrap(v) self.wrap=v end
        function t:SetText(v) self.text=v end
        return t
    end
    return f
end
assert(loadfile("QuestNavigator.lua"))("ChalkBox")
local st=ChalkBox_NavStatus()
assert(not st.enabled and not frames.ChalkBoxQuestNavigator,
    "navigation starts off and never creates an unwanted window")
assert(ChalkBox_NavCommand("on"))
local nav=frames.ChalkBoxQuestNavigator
assert(nav and nav:IsShown() and nav.movable and nav.clamped,
    "navigation has a movable, clamped single frame when enabled")
assert(nav.backdrop and nav.backdrop.edgeFile==
    "Interface\\DialogFrame\\UI-DialogBox-Border",
    "native ChalkBox border surrounds the compact arrow")
st=ChalkBox_NavStatus()
assert(st.questID==222 and st.mode=="Tracked" and st.candidates==4,
    "Blizzard supertracked quest takes priority when it has a waypoint")
assert(nav.arrow.shown and math.abs(nav.arrow.angle+math.pi/2)<0.01,
    "world coordinate X, continent 0 and north-facing rotation work")
assert(nav.distance.text:find("yd",1,true),
    "distance is displayed in yards when world positions are known")
assert(ChalkBox_NavCommand("follow 111"))
assert(ChalkBox_NavStatus().mode=="Manual" and
    ChalkBox_NavStatus().questID==111 and
    math.abs(nav.arrow.angle)<0.01,
    "manual chosen quest wins over Blizzard super-tracking")
assert(not ChalkBox_NavCommand("follow 999"),
    "cannot navigate to a quest not accepted in the log")
assert(not ChalkBox_NavCommand("follow 555"),
    "cannot manually follow a quest without validated coordinates")
assert(ChalkBox_NavCommand("next") and
    ChalkBox_NavStatus().questID==222,
    "next steps through verified accepted quest waypoints")
assert(ChalkBox_NavCommand("prev") and
    ChalkBox_NavStatus().questID==111,
    "previous steps backwards through verified quest waypoints")
assert(ChalkBox_NavCommand("lock") and
    ChalkBox_NavStatus().locked)
nav.scripts.OnDragStart(nav)
assert(not nav.started,"locked arrow is not draggable")
assert(ChalkBox_NavCommand("unlock"))
nav.scripts.OnDragStart(nav)
assert(nav.started,"unlocked arrow can be dragged")
nav.scripts.OnDragStop(nav)
assert(ChalkBoxZoneDB.questNavigator.offsetY==-242,
    "release position persists a bounded user offset")
assert(ChalkBox_NavCommand("reset") and
    ChalkBoxZoneDB.questNavigator.offsetX==nil,
    "user can reset arrow positioning without altering quest data")
assert(ChalkBox_NavCommand("auto"))
super=nil
st=ChalkBox_NavStatus()
assert(st.questID==111 and st.mode=="Smart",
    "Auto picks the closest known world waypoint when none is supertracked")
inInstance=true
ChalkBox_NavCommand("status")
assert(nav.arrow.shown==false and
    nav.distance.text=="No GPS inside instances",
    "instanced maps never produce a fake direction or distance")
inInstance=false
destinations[111]=nil
ChalkBox_NavCommand("follow 222")
destinations[222]=nil
ChalkBox_NavCommand("status")
st=ChalkBox_NavStatus()
assert(st.manualID==222 and st.title=="The Far Farm" and
    not nav.arrow.shown and
    nav.distance.text=="No waypoint for selected quest",
    "temporarily missing quest coordinates do not erase a saved selection")
destinations[222]={1,0.8,0.5}
ChalkBox_NavCommand("status")
assert(nav.arrow.shown and ChalkBox_NavStatus().questID==222,
    "selected destination resumes automatically when waypoint returns")
-- A quest removed from the log relinquishes its saved manual selection.
for i=#entries,1,-1 do
    if entries[i].questID==222 then table.remove(entries,i) end
end
ChalkBox_NavCommand("status")
assert(ChalkBox_NavStatus().manualID==nil,
    "deleted quest does not remain locked as a permanent manual target")
-- A different-continent waypoint must not point in the wrong direction.
ChalkBox_NavCommand("follow 444")
assert(not nav.arrow.shown and
    nav.distance.text=="Quest is in another region",
    "world instance IDs protect against cross-continent false headings")
-- The client returning an incomplete quest list never erases the selection.
logLoading=true
ChalkBox_NavCommand("status")
assert(ChalkBox_NavStatus().manualID==444 and not nav.arrow.shown
    and nav.distance.text=="Quest log loading",
    "incomplete quest log never erases manual selection or shows stale arrows")
logLoading=false
ChalkBox_NavCommand("status")
assert(ChalkBox_NavStatus().manualID==444)
assert(ChalkBox_NavCommand("off") and not nav:IsShown()
    and not ChalkBox_NavStatus().enabled,
    "navigation hides cleanly without changing QuestSense tracker")
local named=0
for _,obj in ipairs(created) do
    if obj.name=="ChalkBoxQuestNavigator" then named=named+1 end
end
assert(named==1,"one compass only; repeated toggles must reuse its frame")
print("PASS: isolated optional navigation, trusted quest waypoints, continent-0 compass, supertrack/manual/nearest priority, instance/cross-map guards, drag lock, persistence and quest-log recovery")
