-- QuestSense Navigator: source-only quest points, map math, opt-in UI,
-- manual and tracked priority, coordinate safety, no game state mutations.
_G.ChalkBoxZoneDB={}
_G.BackdropTemplateMixin={}
local currentMap=1
local inInstance=false
local logLoading=false
local facing=0
local super=222
local selected=nil
local ghost=false
local corpseVisible=true
local localQuestWaypoint=nil
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
_G.UnitIsGhost=function(unit)
    assert(unit=="player")
    return ghost
end
_G.UnitIsDeadOrGhost=function(unit)
    assert(unit=="player")
    return ghost
end
_G.C_DeathInfo={GetCorpseMapPosition=function(mapID)
    if corpseVisible and mapID==1 then
        return {x=0.2,y=0.5}
    end
end}
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
    GetNextWaypointForMap=function(id,mapID)
        if localQuestWaypoint==id and mapID==1 then
            return 0.7,0.5
        end
    end,
    GetSelectedQuest=function() return selected end,
    GetQuestsOnMap=function(mapID)
        if mapID==1 then return {{questID=555,mapID=1,x=0,y=0}} end
        return {}
    end,
}
_G.C_SuperTrack={
    GetSuperTrackedQuestID=function() return super end,
    IsSuperTrackingCorpse=function() return ghost end,
}
_G.C_Map={
    GetBestMapForUnit=function(unit)
        assert(unit=="player")
        return currentMap
    end,
    GetMapInfo=function(id)
        return {name="Zone "..id,mapType=3,parentMapID=(id==5 and 1 or 0)}
    end,
    GetPlayerMapPosition=function(id,unit)
        assert(unit=="player")
        if inInstance then return nil end
        return {x=0.5,y=0.5}
    end,
    GetWorldPosFromMapPos=function(id,pos)
        local continent=(id==3) and 1 or 0
        local offset=id==2 and 2000 or 0
        -- Actual WoW world axes: X points north/south, Y west/east.
        -- Increasing map X goes east (world Y decreases); increasing
        -- map Y goes south (world X decreases).
        return continent,{x=1000-pos.y*1000+offset,
            y=1000-pos.x*1000+offset}
    end
}
_G.DEFAULT_CHAT_FRAME={AddMessage=function() end}
_G.InCombatLockdown=function() return false end
local menuEntries,menusOpened={},0
_G.MenuUtil={
    CreateContextMenu=function(owner,build)
        assert(owner==frames.ChalkBoxQuestNavigator,
            "right-click opens menu on the arrow hit area")
        menuEntries={};menusOpened=menusOpened+1
        local root={}
        function root:CreateButton(label,fn)
            menuEntries[#menuEntries+1]={label=label,action=fn}
        end
        build(owner,root)
    end
}
_G.GameTooltip={
    SetOwner=function(self,owner,anchor)
        self.owner=owner;self.anchor=anchor;self.lines={}
    end,
    AddLine=function(self,value) self.lines[#self.lines+1]=value end,
    Show=function(self) self.shown=true end,
    Hide=function(self) self.shown=false end,
}
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
        function t:SetAtlas(v) self.atlas=v end
        function t:GetAtlas() return self.atlas end
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
assert(nav and nav:IsShown() and nav.movable and nav.clamped
    and nav.w==64 and nav.h==64,
    "navigation is a movable, uncluttered 64px arrow hit area")
assert(nav.arrow.atlas=="Navigation-Tracked-Arrow",
    "native north-up arrow atlas avoids the minimap glyph orientation")
assert(nav.backdrop==nil and nav.back==nil and not nav.title
    and not nav.distance and not nav.mode and not nav.children[1],
    "floating compass has no box, labels, border or visible action buttons")
nav.scripts.OnEnter(nav)
assert(GameTooltip.shown and GameTooltip.owner==nav
    and GameTooltip.lines[1]=="The Far Farm"
    and GameTooltip.lines[3]:find("Right%-click"),
    "quest name, distance state and menu hint live only in mouseover tooltip")
nav.scripts.OnLeave(nav)
assert(GameTooltip.shown==false,"arrow tooltip closes cleanly")
nav.scripts.OnMouseUp(nav,"RightButton")
assert(menusOpened==1 and #menuEntries==3 and
    menuEntries[1].label=="Auto (follow tracked)" and
    menuEntries[2].label=="Next quest" and
    menuEntries[3].label=="Hide arrow",
    "right-click contains only Auto, Next and Hide")
menuEntries[2].action()
assert(ChalkBox_NavStatus().questID==333
    and ChalkBox_NavStatus().mode=="Manual",
    "right-click Next picks another validated quest")
menuEntries[1].action()
assert(ChalkBox_NavStatus().questID==222
    and ChalkBox_NavStatus().mode=="Tracked",
    "right-click Auto restores native super-tracked priority")
menuEntries[3].action()
assert(not nav:IsShown() and not ChalkBox_NavStatus().enabled,
    "right-click Hide disables the compass without changing quest watches")
assert(ChalkBox_NavCommand("on"),"reopening arrow reuses the same frame")
st=ChalkBox_NavStatus()
assert(st.questID==222 and st.mode=="Tracked" and st.candidates==4,
    "Blizzard supertracked quest takes priority when it has a waypoint")
assert(nav.arrow.shown and math.abs(nav.arrow.angle+math.pi/2)<0.01,
    "world coordinate X, continent 0 and north-facing rotation work")
assert(nav.readout:find("yd",1,true),
    "tooltip retains useful straight-line yards without a text box")
-- All cardinals on the actual WoW axis convention, plus turning the
-- character in place. These would fail with the old reversed atan2.
local function RefreshArrow()
    ChalkBox_NavCommand("status")
    return nav.arrow.angle
end
local function CloseAngle(actual,expected)
    local diff=math.atan2(math.sin(actual-expected),
        math.cos(actual-expected))
    return math.abs(diff)<0.01
end
assert(ChalkBox_NavCommand("follow 111"))
assert(CloseAngle(RefreshArrow(),0),
    "north target must point straight forward facing north")
destinations[111]={1,0.8,0.5}
assert(CloseAngle(RefreshArrow(),-math.pi/2),
    "east target must turn right, not south")
destinations[111]={1,0.5,0.8}
assert(CloseAngle(math.abs(RefreshArrow()),math.pi),
    "south target must point backward")
destinations[111]={1,0.2,0.5}
assert(CloseAngle(RefreshArrow(),math.pi/2),
    "west target must turn left")
facing=math.pi/2
assert(CloseAngle(RefreshArrow(),0),
    "turning west makes the west-facing destination point forward")
facing=0
destinations[111]={1,0.5,0.5}
assert(CloseAngle(RefreshArrow(),0) and
    nav.arrow.color[2]>0.8,
    "arriving within 7yd freezes unstable zero-distance heading")
destinations[111]={1,0.5,0.2}
assert(CloseAngle(RefreshArrow(),0))
-- Current-map next waypoint takes priority over a remote or stale
-- overall objective when the client provides it.
localQuestWaypoint=111
assert(CloseAngle(RefreshArrow(),-math.pi/2),
    "prefer explicit next step for selected quest on current map")
localQuestWaypoint=nil
assert(CloseAngle(RefreshArrow(),0))
-- Clicking a different quest in Blizzard's quest log must override an
-- old manual Next/Follow target even if the supertracked ID is unchanged.
selected=222
assert(ChalkBox_NavCommand("status"))
assert(ChalkBox_NavStatus().questID==222 and
    ChalkBox_NavStatus().mode=="Selected",
    "live quest log selection takes priority over stale manual choice")
selected=111
ChalkBox_NavCommand("status")
assert(ChalkBox_NavStatus().questID==111,
    "a second quest selection updates without closing the arrow")
selected=nil
ChalkBox_NavCommand("status")
assert(ChalkBox_NavStatus().questID==222,
    "clearing log selection restores the supertracked quest")
super=333
ChalkBox_NavCommand("status")
assert(ChalkBox_NavStatus().questID==333,
    "changing the game supertracked quest overrides stale navigator choice")
super=222
ChalkBox_NavCommand("status")
assert(ChalkBox_NavStatus().questID==222,
    "tracked quest changes remain authoritative")
-- Corpse overrides even an explicitly manually followed quest, and
-- previous quest choice returns automatically after resurrection.
assert(ChalkBox_NavCommand("follow 111"))
ghost=true
ChalkBox_NavCommand("status")
assert(ChalkBox_NavStatus().targetType=="corpse" and
    ChalkBox_NavStatus().title=="Your corpse" and
    CloseAngle(nav.arrow.angle,math.pi/2),
    "while ghosted, corpse west of the player overrides all quests")
assert(nav.readout:find("yd",1,true),
    "corpse arrow uses genuine position and distance when available")
-- Parent-map fallback finds the same corpse while ghosted on a
-- local minimap/subzone that does not itself expose the death marker.
currentMap=5
ChalkBox_NavCommand("status")
assert(ChalkBox_NavStatus().targetType=="corpse" and
    CloseAngle(nav.arrow.angle,math.pi/2),
    "corpse marker is retrieved from a parent map when necessary")
currentMap=1
corpseVisible=false
ChalkBox_NavCommand("status")
assert(nav.readout=="Corpse position unavailable" and
    nav.arrow.color[4]==0.4 and
    ChalkBox_NavStatus().targetType=="corpse",
    "unknown corpse location never sends a ghost toward a quest")
corpseVisible=true
ghost=false
ChalkBox_NavCommand("status")
assert(ChalkBox_NavStatus().targetType=="quest" and
    ChalkBox_NavStatus().questID==111 and
    ChalkBox_NavStatus().mode=="Manual",
    "resurrection restores the manual quest without losing settings")

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
assert(ChalkBoxZoneDB.questNavigator.offsetY==-268,
    "release position persists a bounded user offset")
assert(ChalkBox_NavCommand("reset") and
    ChalkBoxZoneDB.questNavigator.offsetX==nil,
    "user can reset arrow positioning without altering quest data")
super=nil
assert(ChalkBox_NavCommand("auto"))
st=ChalkBox_NavStatus()
assert(st.questID==111 and st.mode=="Auto",
    "Auto retains the previously chosen valid quest rather than jumping when no quest is supertracked")
inInstance=true
ChalkBox_NavCommand("status")
assert(nav.arrow.shown and nav.arrow.color[4]==0.40 and
    nav.readout=="No GPS inside instances",
    "instanced maps never produce a fake direction or distance")
inInstance=false
destinations[111]=nil
ChalkBox_NavCommand("follow 222")
destinations[222]=nil
ChalkBox_NavCommand("status")
st=ChalkBox_NavStatus()
assert(st.manualID==222 and st.title=="The Far Farm" and
    nav.arrow.shown and nav.arrow.color[4]==0.40 and
    nav.readout=="No waypoint for selected quest",
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
assert(nav.arrow.shown and nav.arrow.color[4]==0.40 and
    nav.readout=="Quest is in another region",
    "world instance IDs protect against cross-continent false headings")
-- The client returning an incomplete quest list never erases the selection.
logLoading=true
ChalkBox_NavCommand("status")
assert(ChalkBox_NavStatus().manualID==444 and
    nav.arrow.shown and nav.arrow.color[4]==0.40
    and nav.readout=="Quest log loading",
    "incomplete quest log never erases manual selection or shows stale arrows")
logLoading=false
ChalkBox_NavCommand("status")
assert(ChalkBox_NavStatus().manualID==444)
assert(ChalkBox_NavCommand("off") and not nav:IsShown()
    and not ChalkBox_NavStatus().enabled,
    "navigation hides cleanly without changing QuestSense tracker")
-- Older Forever builds may expose EasyMenu rather than the modern
-- MenuUtil. Verify the exact same three actions and native placement.
MenuUtil=nil
local legacyItems,legacyAnchor
_G.EasyMenu=function(items,menu,anchor,x,y,kind)
    assert(menu and menu.name=="ChalkBoxNavigationDropdown")
    legacyItems=items;legacyAnchor=anchor
    assert(x==0 and y==0 and kind=="MENU")
end
assert(ChalkBox_NavCommand("on"))
nav.scripts.OnMouseUp(nav,"RightButton")
assert(legacyAnchor=="cursor" and #legacyItems==3 and
    legacyItems[1].text=="Auto (follow tracked)" and
    legacyItems[2].text=="Next quest" and
    legacyItems[3].text=="Hide arrow",
    "older clients get the same three-item right-click popup")
legacyItems[3].func()
assert(not nav:IsShown() and not ChalkBox_NavStatus().enabled,
    "legacy menu Hide has the same effect without altering quest tracking")
local named=0
for _,obj in ipairs(created) do
    if obj.name=="ChalkBoxQuestNavigator" then named=named+1 end
end
assert(named==1,"one compass only; repeated toggles must reuse its frame")
print("PASS: isolated optional navigation, trusted quest waypoints, continent-0 compass, supertrack/manual/nearest priority, instance/cross-map guards, drag lock, persistence and quest-log recovery")
