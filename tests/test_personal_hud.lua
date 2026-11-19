-- Lua 5.1 integration regression: custom information bar and Emota module.
local now, playerXP, xpMax, playerLevel, money = 1000, 200, 1000, 25, 150000
local standalone, moving, combat = false, true, false
local frames, timers, emotes, notes = {}, {}, {}, {}
-- Model Blizzard-owned UIParent. The addon must never alter its anchors or size.
_G.UIParent = {points={},width=1024,height=768}
local function ScreenPoint(point,relative,relativePoint,x,y)
    return {point=point,relative=relative,relativePoint=relativePoint,x=x,y=y}
end
function UIParent:ClearAllPoints() self.points={} end
function UIParent:SetPoint(point,relative,relativePoint,x,y)
    self.points[#self.points+1]=ScreenPoint(point,relative,relativePoint,x,y)
end
function UIParent:GetNumPoints() return #self.points end
function UIParent:GetPoint(i)
    local p=self.points[i]
    if p then return p.point,p.relative,p.relativePoint,p.x,p.y end
end
function UIParent:GetWidth() return self.width end
function UIParent:GetHeight()
    local top,bottom
    for _,p in ipairs(self.points) do
        if p.point=="TOPLEFT" then top=p.y end
        if p.point=="BOTTOMRIGHT" then bottom=p.y end
    end
    if top and bottom then return self.height+top-bottom end
    return self.height
end
function UIParent:SetSize(w,h) self.width=w;self.height=h end
function UIParent:SetAllPoints()
    self:ClearAllPoints()
    self:SetPoint("TOPLEFT",nil,"TOPLEFT",0,0)
    self:SetPoint("BOTTOMRIGHT",nil,"BOTTOMRIGHT",0,0)
end
UIParent:SetAllPoints()
-- A strict regression trap: tampering with the Blizzard root must fail.
-- The Bar can only reanchor its own non-protected frame.
UIParent.ClearAllPoints=function() error("unsafe UIParent:ClearAllPoints") end
UIParent.SetPoint=function() error("unsafe UIParent:SetPoint") end
UIParent.SetAllPoints=function() error("unsafe UIParent:SetAllPoints") end
UIParent.SetSize=function() error("unsafe UIParent:SetSize") end
_G.ChalkBoxDB = {barReserve=true,barTopInset=120}
-- Simulate a saved preference from the previous backward-sliding beta.
-- Upgrading must release that obsolete down-offset automatically.
_G.ChalkBoxZoneDB = {}
local cursorX=0
_G.GetCursorPosition=function() return cursorX,0 end
_G.DEFAULT_CHAT_FRAME = {AddMessage=function(_, line) notes[#notes + 1]=line end}
_G.GetTime = function() return now end
_G.UnitXP = function(unit) assert(unit=="player"); return playerXP end
_G.UnitXPMax = function(unit) assert(unit=="player"); return xpMax end
_G.UnitLevel = function(unit) assert(unit=="player"); return playerLevel end
_G.GetMoney = function() return money end
_G.ChalkBox_BarReadStats=function(_,includeBagValue,includeRepair)
    return {
        bags={free=12,total=96,general=7,special=5},
        gear={percent=87,worst=76,items=9},
        rested={percent=42,xp=420},
        latency={home=21,world=63},
        pet={state="ready",percent=95},
        repair=includeRepair and {state="estimate",copper=7400,missing=31,max=500} or nil,
        bagvalue=includeBagValue and {totalCopper=182250,junkCopper=12525,
            totalUnknown=0,junkUnknown=0,totalComplete=true,junkComplete=true} or nil,
    }
end
_G.IsInGroup = function() return false end
_G.IsInRaid = function() return false end
_G.UnitGUID = function() return nil end
_G.IsPlayerMoving = function() return moving end
_G.InCombatLockdown = function() return combat end
_G.UnitIsDeadOrGhost = function() return false end
_G.UnitIsAFK = function() return false end
_G.IsMounted = function() return false end
_G.UnitOnTaxi = function() return false end
_G.GetInstanceInfo = function() return "Test zone", "none" end
_G.wipe = function(t) for k in pairs(t) do t[k] = nil end end
_G.strsplit = function(_, input)
    local a,b = input:match("^(%S+)%s*(.*)$")
    return a or "", b or ""
end
_G.C_ChatInfo = {
    PerformEmote = function(token) emotes[#emotes+1]=token; return false end
}
_G.C_AddOns = {IsAddOnLoaded=function(name) assert(name=="EmotaSpeak"); return standalone end}
_G.C_Timer = {NewTicker=function(_,callback)
    timers[#timers+1]=callback
    return {Cancel=function() end}
end}

local function NewTexture()
    return {points={},
        ClearAllPoints=function(self) self.points={} end,
        SetAllPoints=function(self,owner) self.allPoints=owner end,
        SetColorTexture=function(self,r,g,b,a) self.rgba={r,g,b,a} end,
        SetPoint=function(self,...)
            self.points[#self.points+1]={...}
        end,
        SetHeight=function(self,v) self.height=v end,
        SetWidth=function(self,v) self.width=v end,
        Show=function(self) self.visible=true end,
        Hide=function(self) self.visible=false end}
end
local function NewFont()
    return {SetAllPoints=function() end,SetJustifyH=function() end,
        SetText=function(self,value) self.value=value end}
end
_G.CreateFrame = function(_, name, parent)
    local frame={name=name,parent=parent,events={},scripts={},anchor=nil,points={},visible=true,width=1024}
    function frame:RegisterEvent(event) self.events[event]=true end
    function frame:UnregisterEvent(event) self.events[event]=nil end
    function frame:SetScript(which,callback) self.scripts[which]=callback end
    function frame:SetHeight(height) self.height=height end
    function frame:SetSize(w,h) self.width=w;self.height=h end
    function frame:SetFrameStrata(strata) self.strata=strata end
    function frame:SetFrameLevel(level) self.level=level end
    function frame:CreateTexture() return NewTexture() end
    function frame:CreateFontString()
        local font=NewFont()
        self.font=font
        return font
    end
    function frame:SetPoint(point,...) self.anchor=point;self.points[#self.points+1]={point,...} end
    function frame:ClearAllPoints() self.anchor=nil;self.points={} end
    function frame:GetNumPoints() return #self.points end
    function frame:GetPoint(i) return unpack(self.points[i] or {}) end
    function frame:EnableMouse() end
    function frame:GetWidth() return self.width end
    function frame:GetLeft() return 0 end
    function frame:GetEffectiveScale() return 1 end
    function frame:GetCenter()
        local p=self.points[1]
        if not p then return nil end
        local point,relative,relPoint,offset=p[1],p[2],p[3],p[4]
        if point=="LEFT" then return offset+self.width/2 end
        if point=="CENTER" then return offset end
        if point=="RIGHT" then return relative.width+offset-self.width/2 end
    end
    function frame:SetMovable(v) self.movable=v end
    function frame:RegisterForDrag(v) self.dragButton=v end
    function frame:StartMoving() self.moving=true end
    function frame:StopMovingOrSizing() self.moving=false end
    function frame:Show() self.visible=true end
    function frame:Hide() self.visible=false end
    frames[#frames+1]=frame
    return frame
end
-- Mock the modern native menu framework, recording actual nested callbacks.
local lastNativeMenu
local function MockMenu()
    return {
        entries={},
        CreateTitle=function(self,label)
            self.entries[#self.entries+1]={text=label,isTitle=true}
        end,
        CreateButton=function(self,label,fn)
            local e={text=label,func=fn}
            self.entries[#self.entries+1]=e
            local submenu=MockMenu()
            e.children=submenu.entries
            e.submenu=submenu
            return submenu
        end,
    }
end
_G.MenuUtil={
    CreateContextMenu=function(owner,generator)
        local root=MockMenu()
        generator(owner,root)
        lastNativeMenu=root.entries
    end,
}
local function MenuPlain(text)
    return (text or ""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
end
local function FindMenu(items,label)
    for _,entry in ipairs(items or {}) do
        if MenuPlain(entry.text)==label then return entry end
        if entry.children then
            local result=FindMenu(entry.children,label)
            if result then return result end
        end
    end
end
local openedPage
_G.ChalkBox_OpenSettings=function(page) openedPage=page end
_G.GameTooltip = {
    lines={},shown=false,
    SetOwner=function() end,
    ClearLines=function(self) self.lines={} end,
    AddLine=function(self,txt,r,g,b)
        assert(type(txt)=="string" and #txt>0,"empty hover text")
        self.lines[#self.lines+1]={text=txt,color={r,g,b}}
    end,
    Show=function(self) self.shown=true end,
    Hide=function(self) self.shown=false end,
}

local function Fire(event,...)
    for _,frame in ipairs(frames) do
        if frame.events[event] and frame.scripts.OnEvent then
            frame.scripts.OnEvent(frame,event,...)
        end
    end
end
assert(loadfile("Emota.lua"))("ChalkBox")
assert(loadfile("TrailBarLayout.lua"))("ChalkBox")
assert(loadfile("ScreenLayout.lua"))("ChalkBox")
assert(loadfile("TrailBar.lua"))("ChalkBox")
Fire("ADDON_LOADED","ChalkBox")
assert(ChalkBoxDB.emota.auto==false,"integrated auto-emotes must default off")
assert(ChalkBoxDB.bar=="top","default info bar is at top")
assert(ChalkBoxDB.barTopInset==nil and
    ChalkBoxDB.barNotchPositionV2==true,
    "old backward notch slider is reset once and does not hold bar down")
Fire("PLAYER_ENTERING_WORLD")
local bar
for _,frame in ipairs(frames) do if frame.name=="ChalkBoxInfoBar" then bar=frame end end
-- Validate the approved wide-screen screenshot layout before testing
-- narrower widths and automatic metric suppression below.
bar.width=2048
if bar.scripts.OnSizeChanged then bar.scripts.OnSizeChanged(bar) end
assert(bar and bar.visible and bar.anchor=="TOPRIGHT",
    "top bar must stay visible as its own combat-safe overlay")
assert(bar.points[2] and bar.points[2][4]==0,
    "the full-width Bar reaches both screen edges")
-- Split the bar around real native notch coordinates. Do not lower the
-- entire bar or move UIParent, and never overlap the physical camera cutout.
assert(ChalkBox_BarTopInsetStatus().mode=="auto" and
    ChalkBox_BarTopInsetStatus().effective==0,
    "non-notched default keeps the entire original bar position")
_G.WorldFrame={width=2048,GetWidth=function(self) return self.width end}
_G.C_UI={
    DoesAnyDisplayHaveNotch=function() return true end,
    ShouldUIParentAvoidNotch=function() return true end,
    GetTopLeftNotchSafeRegion=function() return 0,450,768,740 end,
    GetTopRightNotchSafeRegion=function() return 570,1024,768,740 end,
}
Fire("NOTCHED_DISPLAY_MODE_CHANGED")
local notch=ChalkBox_BarTopInsetStatus()
assert(bar.points[1][5]==0 and bar.points[2][5]==0 and
    bar.points[1][2]==WorldFrame and bar.points[2][2]==WorldFrame
    and notch.split and notch.source=="native notch split"
    and notch.gapStart==892 and notch.gapEnd==1148,
    "shifted UIParent must not trap the split bar below the camera notch")
assert(bar.backgroundRight.visible and
    bar.background.points[2][4]==notch.gapStart and
    bar.backgroundRight.points[1][4]==notch.gapEnd,
    "two background strips have a genuine transparent camera gap")
local firstSide,secondSide=0,0
for _,frame in ipairs(frames) do
    if frame.parent==bar and frame.font and frame.visible and
        frame.anchor=="CENTER" then
        local x=frame.points[1][4]
        local from=x-frame.width/2
        local to=from+frame.width
        assert(to<=notch.gapStart or from>=notch.gapEnd,
            "center widgets must never cross behind the camera notch")
        if to<=notch.gapStart then firstSide=firstSide+1
        else secondSide=secondSide+1 end
    end
end
assert(firstSide>0 and secondSide>0,
    "center group is intentionally split across both usable top lanes")
assert(UIParent:GetHeight()==768,
    "notch handling never changes native UIParent height")
-- WoW intentionally shifts UIParent below the notch; we must KEEP
-- splitting and anchor to WorldFrame instead of suppressing the mode.
C_UI.ShouldUIParentAvoidNotch=function() return true end
Fire("NOTCHED_DISPLAY_MODE_CHANGED")
assert(bar.points[1][2]==WorldFrame and
    ChalkBox_BarTopInsetStatus().split,
    "ShouldUIParentAvoidNotch true must never disable a valid split")
C_UI.ShouldUIParentAvoidNotch=function() return false end
Fire("NOTCHED_DISPLAY_MODE_CHANGED")
assert(bar.points[1][2]==WorldFrame and
    ChalkBox_BarTopInsetStatus().split,
    "the split also works when Blizzard does not shift UIParent")
-- A Forever build without WorldFrame can still lift by native notch depth.
_G.WorldFrame=nil
Fire("NOTCHED_DISPLAY_MODE_CHANGED")
assert(bar.points[1][2]==UIParent and bar.points[1][5]==28,
    "when WorldFrame is unavailable, native safe height lifts the bar UP")
_G.WorldFrame={width=2048,GetWidth=function(self) return self.width end}
C_UI.DoesAnyDisplayHaveNotch=function() return false end
Fire("DISPLAY_SIZE_CHANGED")
assert(bar.points[1][5]==0 and bar.points[1][2]==UIParent and
    not ChalkBox_BarTopInsetStatus().split and
    not bar.backgroundRight.visible,
    "external display returns to native UIParent with a single full bar")
C_UI.DoesAnyDisplayHaveNotch=function() return true end
C_UI.GetTopLeftNotchSafeRegion=function() return 0,450,768,100 end
C_UI.GetTopRightNotchSafeRegion=function() return 570,1024,768,100 end
Fire("UI_SCALE_CHANGED")
assert(bar.points[1][5]==0 and
    not ChalkBox_BarTopInsetStatus().split,
    "invalid oversized notch rectangles never create an unsafe split")
_G.C_UI=nil
assert(ChalkBox_BarNotchGapSet(160)
    and ChalkBox_BarTopInsetStatus().split
    and ChalkBox_BarTopInsetStatus().mode=="split"
    and bar.points[1][2]==WorldFrame and bar.points[1][5]==0,
    "manual split uses WorldFrame even when client notch API is unavailable")
bar.width=280
Fire("DISPLAY_SIZE_CHANGED")
assert(not ChalkBox_BarTopInsetStatus().split and
    ChalkBox_BarTopInsetStatus().effective==32 and
    bar.points[1][5]==-32,
    "manual split becomes a safe below-notch strip in very narrow windows")
bar.width=2048
Fire("DISPLAY_SIZE_CHANGED")
assert(ChalkBox_BarTopInsetStatus().split and
    bar.points[1][5]==0,
    "normal window size restores user-selected manual split")
ChalkBox_BarCommand("safe split 144")
assert(ChalkBox_BarTopInsetStatus().manualGap==144 and
    ChalkBox_BarTopInsetStatus().split,
    "manual split-width command is wired to real layout preference")
-- Height slider now moves UP, independently of the manual split gap.
assert(ChalkBox_BarNotchRaiseSet(40)
    and bar.points[1][2]==UIParent and bar.points[1][5]==40
    and ChalkBox_BarTopInsetStatus().rise==40,
    "positive raise slider offsets into the notch, never DOWN")
assert(ChalkBox_BarNotchRaiseSet(80)
    and bar.points[1][5]==80,
    "increasing the height slider moves the bar further UP")
combat=true
assert(ChalkBox_BarNotchRaiseSet(48)
    and bar.points[1][5]==80 and
    ChalkBox_BarTopInsetStatus().pending,
    "height slider postpones repositioning while in combat")
combat=false
Fire("PLAYER_REGEN_ENABLED")
assert(bar.points[1][5]==48,
    "deferred upward adjustment applies when combat ends")
assert(ChalkBox_BarNotchRaiseSet("auto")
    and bar.points[1][2]==WorldFrame and bar.points[1][5]==0,
    "reselecting auto returns split to the world top")
assert(ChalkBox_BarNotchGapSet("auto")
    and not ChalkBox_BarTopInsetStatus().split,
    "manual split is reversible without restarting or changing UIParent")
assert(ChalkBox_BarTopInsetSet(50) and
    ChalkBox_BarTopInsetStatus().mode=="manual" and
    bar.points[1][5]==-50 and bar.points[2][5]==-50,
    "unsupported client can use a saved explicit notch-safe inset")
assert(not ChalkBox_BarTopInsetSet(200) and bar.points[1][5]==-50,
    "out-of-range manual insets are rejected without mutating layout")
combat=true
assert(ChalkBox_BarTopInsetSet(60) and bar.points[1][5]==-50
    and ChalkBox_BarTopInsetStatus().pending,
    "safe inset changes do not reposition frames while in combat")
combat=false
Fire("PLAYER_REGEN_ENABLED")
assert(bar.points[1][5]==-60 and not ChalkBox_BarTopInsetStatus().pending,
    "inset queued in combat applies after combat ends")
assert(ChalkBox_BarTopInsetSet("auto")
    and bar.points[1][5]==0 and ChalkBoxDB.barTopInset==nil,
    "automatic mode restores baseline when notch APIs are unavailable")
assert(ChalkBoxDB.barReserve==false,
    "legacy UIParent reservation setting must be migrated to safe overlay")
assert(UIParent:GetHeight()==768,"Blizzard root height must never change")
assert(select(5,UIParent:GetPoint(1))==0,
    "no addon-driven changes to Blizzard root anchors")
local function RootIsBaseline()
    return UIParent:GetHeight()==768 and select(5,UIParent:GetPoint(1))==0
       and select(5,UIParent:GetPoint(2))==0
end
assert(bar.height==18,"bar should remain slim")
assert(bar.strata=="BACKGROUND" and bar.level==1,
    "Bar chrome must be behind LOW/MEDIUM Blizzard unit frames and resting ZZZ")
assert(RootIsBaseline(),
    "lowering Bar draw order never modifies protected UIParent")
local aligned={}
for _,w in ipairs(frames) do
    if w.parent==bar and w.text and w.text.value then
        if w.text.value:find("Lv ",1,true)==1 then aligned.level=w.anchor end
        if w.text.value:find("To level ",1,true)==1 then aligned.eta=w.anchor end
        if w.text.value:find("Gold ",1,true)==1 then aligned.gold=w.anchor end
    end
end
assert(aligned.level=="LEFT" and aligned.eta=="CENTER" and aligned.gold=="RIGHT",
    "bar must actually anchor contents to left, center and right")
assert(#timers==2,"integrated emotes and info bar should each have one 5-second ticker")
local function FindText(prefix)
    for _,frame in ipairs(frames) do
        if frame.font and frame.font.value and frame.font.value:find(prefix,1,true)==1 then
            return frame.font.value
        end
    end
end
assert(FindText("Lv 25"),"bar should show level")
assert(FindText("XP/h 0"),"rate starts at zero")
now=1100
playerXP=300
money=172000
Fire("PLAYER_XP_UPDATE")
Fire("PLAYER_MONEY")
assert(FindText("XP/h 3.6k"),"XP gained over elapsed seconds becomes XP/hour")
assert(FindText("To level 11m"),"time-to-level estimate uses session average")
assert(FindText("Gold 17g"),"current gold is visible")
assert(FindText("Time 1m"),"session runtime is visible")
local function FindMetric(prefix)
    for _,frame in ipairs(frames) do
        if frame.parent==bar and frame.font and frame.font.value
            and frame.font.value:find(prefix,1,true)==1 then
            return frame
        end
    end
end
assert(FindText("Bags 12 free"),"free slots appear in the actual TrailBar widgets")
assert(ChalkBoxDB.barStats.bankvalue and
    FindMetric("Bank --") and FindMetric("Bank --").visible,
    "Bank Value visibly shows Bank -- on first login before any bank snapshot")
ChalkBox_BarCommand("stat bankvalue off")
assert(ChalkBoxDB.barStats.bankvalue==false and
    not FindMetric("Bank --").visible,
    "explicit Bank Value OFF persists without breaking other modules")
ChalkBox_BarCommand("stat bankvalue on")
assert(FindMetric("Bank --").visible,
    "Bank Value can be restored immediately without opening the bank")
ChalkBox_BarCommand("bank status")
assert(notes[#notes] and notes[#notes]:find("reader unavailable",1,true),
    "bank diagnostics clearly distinguish a missing bank reader from no snapshot")
assert(ChalkBoxDB.barStats.bagvalue and ChalkBoxDB.barStats.latency
    and not ChalkBoxDB.barStats.pet,
    "reference Bar shows Junk and World ping, with pet status opt-in")
assert(ChalkBox_BarBagValueModeGet()=="junk",
    "a fresh Bar starts on grey-only Junk value")
assert(FindText("Junk 1g"),"fresh Bar displays vendor junk value")
ChalkBox_BarBagValueModeSet("total")
assert(FindText("Value 18g"),"users can still select total resale value")
ChalkBox_BarCommand("stat pet on")
assert(ChalkBoxDB.barStats.pet,"Hunter pet can be enabled manually")

assert(FindText("Gear 87%"),"durability appears in the actual TrailBar widgets")
assert(FindText("Rest 42%"),"rested XP appears as a level percent")
assert(FindText("Pet 95%"),"Hunter pet status is available when readable")
assert(ChalkBoxDB.barStats.repair==true,
    "repair module is enabled on Balanced by default")
assert(FindText("Repair ~74s"),"Bar labels calibrated costs as estimates")
-- Hover details should be short status readouts, not documentation.
local function HoverStat(prefix,expectedLines,expectedValue)
    local frame=FindMetric(prefix)
    assert(frame and frame.scripts.OnEnter and frame.scripts.OnLeave,
        "missing hover handler for "..prefix)
    frame.scripts.OnEnter(frame)
    assert(GameTooltip.shown,"hover must open for "..prefix)
    local lines=GameTooltip.lines
    assert(#lines==expectedLines,"verbose or missing hover lines for "..prefix..
        ": "..#lines)
    assert(lines[1].color[1]==1 and lines[1].color[2]==0.82,
        "hover title keeps the gold header")
    for index,line in ipairs(lines) do
        assert(#line.text<=48,"hover text must be short: "..line.text)
        if index>1 then assert(not line.text:find("ChalkBox") and
            not line.text:find("Click") and
            not line.text:find("Estimate vs") and
            not line.text:find("equipped items"),
            "hover must not include help documentation")
        end
    end
    assert(lines[2] and lines[2].text:find(expectedValue,1,true),
        "hover must retain relevant data for "..prefix)
    frame.scripts.OnLeave(frame)
    assert(not GameTooltip.shown,"tooltip closes on leave")
end
HoverStat("Lv ",2,"300 / 1000 XP")
HoverStat("XP/h ",2,"Gained: 100 XP")
HoverStat("To level ",2,"XP left: 700")
HoverStat("Repair ",3,"Estimate: ~0g 74s 0c")
local repairHover=FindMetric("Repair ")
repairHover.scripts.OnEnter(repairHover)
assert(GameTooltip.lines[2].color[1]>GameTooltip.lines[2].color[3],
    "estimated repairs are highlighted as caution, not an exact quote")
repairHover.scripts.OnLeave(repairHover)
HoverStat("Bags ",3,"Free: 12 / 96")
local nativeBagToggles=0
_G.ToggleAllBags=function() nativeBagToggles=nativeBagToggles+1 end
local bagStat=FindMetric("Bags ")
assert(bagStat and bagStat.scripts.OnMouseUp,
    "bag stat preserves ordinary Bar click handling")
bagStat.scripts.OnMouseUp(bagStat,"LeftButton")
assert(nativeBagToggles==1,
    "a real bag-stat left click invokes Blizzard's all-bags toggle")
bagStat.scripts.OnMouseUp(bagStat,"LeftButton")
assert(nativeBagToggles==2,
    "second bag click toggles bags again without opening new frames")
_G.ToggleAllBags=nil
HoverStat("Gear ",3,"Overall: 87%")
HoverStat("Rest ",2,"420 XP (42%)")
HoverStat("Pet ",2,"Health: 95%")
HoverStat("Time ",2,"Elapsed: 1m")
HoverStat("World ",3,"Home: 21 ms")
HoverStat("Gold ",3,"Net: +2g 20s")
HoverStat("Value ",3,"Junk: 1g 25s 25c")
local repairMenuData=ChalkBox_BarContextItems("repair")
assert(type(repairMenuData)=="table",
    "repair cost is a real customizable stat, not a hardcoded label")
local gearContext=FindMetric("Gear ")
assert(gearContext and gearContext.scripts.OnMouseUp)
gearContext.scripts.OnMouseUp(gearContext,"RightButton")
assert(FindMenu(lastNativeMenu,"Hide"),
    "right-click outside Edit Mode shows compact per-stat controls")
assert(#lastNativeMenu==6 and not FindMenu(lastNativeMenu,"Modules")
    and FindMenu(lastNativeMenu,"Width (82 px)"),
    "stat menu adds per-module width while keeping compact native controls")
assert(lastNativeMenu[1].isTitle and
    lastNativeMenu[1].text:find("|cffffd36a",1,true),
    "stat heading is clearly gold, not another white action")
FindMenu(lastNativeMenu,"Hide").func()
assert(not ChalkBoxDB.barStats.gear,"menu action hides clicked module")
bar.scripts.OnMouseUp(bar,"RightButton")
local allModules=FindMenu(lastNativeMenu,"Modules")
assert(#lastNativeMenu==8 and allModules and
    FindMenu(lastNativeMenu,"Top safe area (Auto)") and
    FindMenu(allModules.children,"OFF Durability"),
    "background menu has compact, categorized controls including notch safety")
assert(FindMenu(allModules.children,"OFF Durability").text:
    find("|cff9ba2ad",1,true),
    "disabled stats are muted gray instead of a sea of white")
FindMenu(allModules.children,"OFF Durability").func()
assert(ChalkBoxDB.barStats.gear,"module restored through bar background menu")
local gearMove=ChalkBox_BarContextItems("gear")
FindMenu(gearMove,"Left").func()
local moved=false
for _,key in ipairs(ChalkBox_BarLayoutGet().left) do
    if key=="gear" then moved=true end
end
assert(moved,"context menu moves gear from its new right-side default")
FindMenu(FindMenu(gearMove,"Align").children,"Center").func()
assert(ChalkBox_BarLayoutGet().align.gear=="center",
    "context menu applies per-module text alignment")
ChalkBox_BarCommand("layout reset")
FindMenu(lastNativeMenu,"Stat settings").func()
assert(openedPage=="barstats","context menu navigates into native Settings")
local valueWidget=FindMetric("Value ")
assert(valueWidget and valueWidget.scripts.OnMouseUp,
    "Bag Value widget is directly clickable outside Edit Mode")
valueWidget.scripts.OnMouseUp(valueWidget,"LeftButton")
assert(ChalkBox_BarBagValueModeGet()=="junk" and
    FindText("Junk 1g"),"click flips to grey-only resale price")
valueWidget.scripts.OnMouseUp(valueWidget,"LeftButton")
assert(ChalkBox_BarBagValueModeGet()=="total" and
    FindText("Value 18g"),"second click restores total bag resale")
ChalkBox_BarCommand("bagvalue junk")
assert(ChalkBox_BarBagValueModeGet()=="junk",
    "mode can also be configured by slash command")
ChalkBox_BarCommand("bagvalue total")
ChalkBox_BarCommand("stat bagvalue off")
assert(not ChalkBoxDB.barStats.bagvalue,
    "disabling the optional module doesn't change its mode preference")
-- Crucial regression: Bag Value left click still flips modes; its right
-- click now opens the native menu without killing Edit Mode alignment.
valueWidget.scripts.OnMouseUp(valueWidget,"RightButton")
assert(FindMenu(lastNativeMenu,"Junk only"),
    "bag value context menu keeps a short value-mode switch")
FindMenu(lastNativeMenu,"Junk only").func()
assert(ChalkBox_BarBagValueModeGet()=="junk")
ChalkBox_BarBagValueModeSet("total")
-- Legacy dropdown fallback must be equally legible, and actions must remain
-- wired even when the modern MenuUtil API is absent.
local modernMenu=MenuUtil
local capturedLegacy
_G.MenuUtil=nil
_G.EasyMenu=function(items)
    capturedLegacy=items
    return true
end
assert(ChalkBox_BarOpenMenu("gear",gearContext),
    "legacy right-click menu opens without MenuUtil")
assert(capturedLegacy and #capturedLegacy==6 and
    capturedLegacy[1].isTitle and
    capturedLegacy[1].text:find("|cffffd36a",1,true),
    "legacy menu keeps gold headings and a compact stat-only layout")
assert(capturedLegacy[3].hasArrow and
    capturedLegacy[3].text:find("|cff79d4e9",1,true),
    "legacy submenu headings keep the cyan navigation color")
_G.MenuUtil=modernMenu
_G.EasyMenu=nil
assert(FindMetric("Bags ").visible and FindMetric("Gear ").visible
    and FindMetric("Rest ").visible,
    "new priority widgets appear on a normal screen")
assert(ChalkBoxDB.barStats.bags and ChalkBoxDB.barStats.gear
    and ChalkBoxDB.barStats.rested and ChalkBoxDB.barStats.latency,
    "reference defaults feature bags, gear, rested XP and World latency")
ChalkBox_BarCommand("stat latency on")
assert(ChalkBoxDB.barStats.latency==true,"optional latency switch persists")
ChalkBox_BarCommand("stat gear off")
assert(not ChalkBoxDB.barStats.gear and not FindMetric("Gear ").visible,
    "turning a stat off must hide it immediately without clearing data")
ChalkBox_BarCommand("stats minimal")
assert(not ChalkBoxDB.barStats.rate and ChalkBoxDB.barStats.bags
    and not ChalkBoxDB.barStats.rested and ChalkBoxDB.barStats.gold,
    "minimal preset keeps only level, bag space and gold")
ChalkBox_BarCommand("stats all")
assert(ChalkBoxDB.barStats.latency and ChalkBoxDB.barStats.pet,
    "all preset enables the full supported inventory and status data")
bar.width=520
bar.scripts.OnSizeChanged(bar)
local n=0
for _,frame in ipairs(frames) do
    if frame.parent==bar and frame.font and frame.visible then n=n+1 end
end
assert(n>=2 and n<=5,"narrow bar must hide lower-priority metrics")
assert(FindMetric("Lv ").visible,"level metric must survive narrow widths")
assert(FindMetric("Gold ").visible,"gold metric survives normal narrow layouts")
local segments={}
for _,frame in ipairs(frames) do
    if frame.parent==bar and frame.font and frame.visible then
        local p=frame.points[1]
        assert(p and (p[1]=="LEFT" or p[1]=="CENTER" or p[1]=="RIGHT"),
            "visible metrics must have one of the allowed native group anchors")
        local x=p[4]
        if p[1]=="CENTER" then x=x-frame.width/2
        elseif p[1]=="RIGHT" then x=bar.width+x-frame.width end
        segments[#segments+1]={from=x,to=x+frame.width}
    end
end
table.sort(segments,function(a,b) return a.from<b.from end)
for i,segment in ipairs(segments) do
    assert(segment.from>=0 and segment.to<=bar.width,
        "no visible TrailBar text widget may extend off-screen")
    if i>1 then assert(segments[i-1].to<=segment.from,
        "adaptive modules must never overlap at narrow widths") end
end
bar.width=1680
bar.scripts.OnSizeChanged(bar)
assert(FindMetric("World ").visible and FindMetric("Pet ").visible and
    FindMetric("Bank --").visible,
    "truly wide UI displays Bank --, latency, and Hunter status with no overlap")
bar.width=1024
bar.scripts.OnSizeChanged(bar)
ChalkBox_BarCommand("stats balanced")
assert(ChalkBoxDB.barStats.latency and not ChalkBoxDB.barStats.pet,
    "balanced preset restores the new reference stats")
assert(FindMetric("Gear ").visible,"preset restores previously hidden durability widget")
local state=ChalkBox_BarStatus()
assert(type(state.enabled)=="table" and type(state.visible)=="table",
    "native status gives enabled vs currently fitting modules")
-- Polished 1.9: edit-mode direct mouse drag, per-character layout, text align.
ChalkBox_BarCommand("edit on")
assert(ChalkBox_BarEditStatus(),"in-game editor is enabled")
local bagWidget=FindMetric("Bags ")
assert(bagWidget and bagWidget.movable and bagWidget.dragButton=="LeftButton",
    "user can physically drag stat modules within the 18px bar")
local grip=bagWidget.resizeGrip
assert(grip and grip.parent==bagWidget and grip.visible and
    grip.dragButton=="LeftButton" and ChalkBox_BarWidthGet("bags")==90,
    "Edit Mode adds a gold right-edge grip while preserving the module body drag")
cursorX=300
grip.scripts.OnDragStart(grip)
cursorX=347
grip.scripts.OnUpdate(grip,.1)
assert(bagWidget.width==136 and ChalkBox_BarWidthGet("bags")==136 and
    ChalkBox_BarLayoutWidthGet("bags")==nil,
    "resizing previews a 46px wider stat without saving until release")
grip.scripts.OnDragStop(grip)
assert(not grip.dragging and ChalkBox_BarLayoutWidthGet("bags")==136
    and bagWidget.width==136 and ChalkBox_BarWidthGet("gold")==182,
    "release persists only the chosen stat width; other widths remain unchanged")
cursorX=945
bagWidget.scripts.OnDragStart(bagWidget)
assert(bagWidget.moving,"left drag must start moving only in edit mode")
bagWidget.scripts.OnDragStop(bagWidget)
local custom=ChalkBox_BarLayoutGet()
local placed=false
for _,entry in ipairs(custom.right) do if entry=="bags" then placed=true end end
assert(placed and not bagWidget.moving,
    "drop on right third saves bag stat in right group")
bagWidget.scripts.OnMouseUp(bagWidget,"RightButton")
assert(ChalkBox_BarLayoutGet().align.bags=="center",
    "right-click in Edit Mode cycles in-module text alignment")
bar.scripts.OnMouseUp(bar,"RightButton")
local done=FindMenu(lastNativeMenu,"Done editing")
assert(done and done.func,
    "empty-Bar right-click offers Done editing without opening settings")
done.func()
assert(not ChalkBox_BarEditStatus() and not grip.visible and
    ChalkBox_BarWidthGet("bags")==136,
    "Done editing hides the resize grip and preserves its saved width")
ChalkBox_BarCommand("layout reset")
assert(ChalkBox_BarLayoutGet().right[1]=="bags"
    and ChalkBox_BarLayoutGet().center[1]=="time"
    and not ChalkBox_BarLayoutGet().align.bags
    and ChalkBox_BarWidthGet("bags")==90 and
    ChalkBox_BarLayoutWidthGet("bags")==nil,
    "reset layout restores screenshot order, text alignment and metric widths")
assert(ChalkBox_BarWidthSet("gold",248)
    and ChalkBox_BarWidthGet("gold")==248,
    "precise stat width control can be adjusted outside Edit Mode")
ChalkBox_BarCommand("width gold 116")
assert(ChalkBox_BarWidthGet("gold")==116 and
    ChalkBox_BarLayoutWidthGet("gold")==116,
    "slash width command persists independently of other modules")
ChalkBox_BarCommand("width gold reset")
assert(ChalkBox_BarWidthGet("gold")==182,
    "slash width reset restores the original module footprint")
assert(ChalkBox_BarAppearanceSet(0))
assert(ChalkBox_BarAppearanceGet()==0 and bar.background.rgba[4]==0,
    "zero opacity removes only the charcoal panel background")
assert(ChalkBox_BarAppearanceSet(100))
assert(bar.background.rgba[4]==1 and bar.background.rgba[1]<0.03,
    "fully opaque bar is neutral Blizzard-like charcoal, not blue")
combat=true
assert(not ChalkBox_BarOpenMenu("gear",gearContext) and
    not ChalkBox_BarEditSet(true),
    "combat forbids layout editor and unsafe customization menus")
combat=false
assert(ChalkBox_BarEditSet(true),
    "Edit Mode can resume after combat")
ChalkBox_BarEditSet(false)
combat=true
assert(not ChalkBox_BarEditSet(true),"combat may not enter layout editor")
combat=false
ChalkBox_BarAppearanceSet(70)
-- Combat-taint regression: every display and positioning command leaves
-- UIParent untouched. Even a legacy "reserve on" cannot enable root writes.
local anchoredChild=CreateFrame("Frame","NeverWhitelisted",UIParent)
anchoredChild:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-10,-8)
assert(anchoredChild.points[1][2]==UIParent)
ChalkBox_BarCommand("reserve off")
assert(RootIsBaseline() and bar.anchor=="TOPRIGHT")
ChalkBox_BarCommand("reserve on")
assert(RootIsBaseline() and ChalkBoxDB.barReserve==false,
    "legacy reserve command must never reenable root mutation")
ChalkBox_BarCommand("bottom")
assert(RootIsBaseline() and bar.anchor=="BOTTOMRIGHT" and bar.visible,
    "bottom bar anchors only its own frame")
ChalkBox_BarCommand("off")
assert(RootIsBaseline() and not bar.visible,
    "hidden bar must leave Blizzard root alone")
ChalkBox_BarCommand("top")
assert(RootIsBaseline() and bar.visible and bar.anchor=="TOPRIGHT")
combat=true
ChalkBox_BarCommand("bottom")
assert(RootIsBaseline() and bar.anchor=="TOPRIGHT",
    "combat must defer even self-owned frame repositioning")
combat=false
Fire("PLAYER_REGEN_ENABLED")
assert(RootIsBaseline() and bar.anchor=="BOTTOMRIGHT",
    "deferred safe placement resumes after combat")
ChalkBox_BarCommand("top")
Fire("UI_SCALE_CHANGED")
Fire("DISPLAY_SIZE_CHANGED")
assert(RootIsBaseline() and bar.anchor=="TOPRIGHT",
    "scale changes must never rewrite protected UIParent")
assert(bar.points[2] and bar.points[2][4]==0,
    "full-width Bar keeps its original edge-to-edge design")
UIParent.width=2048
Fire("DISPLAY_SIZE_CHANGED")
assert(RootIsBaseline() and bar.points[2][4]==0,
    "wider view keeps Bar full width without modifying UIParent")
UIParent.width=1024
Fire("DISPLAY_SIZE_CHANGED")
assert(bar.points[2][4]==0,
    "small views keep Bar full width; other Blizzard top frames shift")
ChalkBox_BarCommand("reset")
assert(FindText("XP/h 0"),"reset must restart XP baseline")
playerLevel=26
playerXP=100
now=1200
Fire("PLAYER_LEVEL_UP")
assert(FindText("Lv 26"),"level-ups should be handled")
ChalkBox_EmotaCommand("auto on")
ChalkBox_EmotaCommand("test")
assert(#emotes==1 and emotes[1]=="WAVE","manual native wave should be attempted")
assert(not table.concat(notes):find("API returned false",1,true),
    "false API return must never be reported as an animation failure")
standalone=true
ChalkBox_EmotaCommand("test")
assert(#emotes==1,"standalone EmotaSpeak should suppress integrated emotes")
standalone=false
moving=false
-- Deterministic RNG for the old HUD/Emota integration regression. Separate
-- tests exercise broader random selection, poses and safely skipped events.
local originalRandom=math.random
math.random=function(a,b)
    if a and b then return a end
    if a then return 1 end
    return 0.5
end
Fire("PLAYER_STOPPED_MOVING")
now=1261
for _,tick in ipairs(timers) do tick() end
assert(emotes[#emotes]=="JOKE","default idle pool still includes racial jokes")
ChalkBox_EmotaSetEnabled("JOKE",false)
ChalkBox_EmotaCommand("idle reset")
local before=#emotes
now=1322
for _,tick in ipairs(timers) do tick() end
assert(#emotes==before+1 and emotes[#emotes]~="JOKE",
    "blocking JOKE should rotate to another enabled idle behavior")
ChalkBox_EmotaSetEnabled("JOKE",true)
ChalkBox_EmotaSetJokeFrequency(100)
assert(ChalkBoxDB.emota.jokeFrequency==100)
now=1342
for _,tick in ipairs(timers) do tick() end
assert(#emotes==before+2,
    "rightmost slider increases idle opportunities when enabled")
ChalkBox_EmotaSetJokeFrequency(0)
assert(ChalkBoxDB.emota.jokeFrequency==0)
before=#emotes
now=1400
for _,tick in ipairs(timers) do tick() end
assert(#emotes==before,"leftmost slider is much slower than normal")
assert(#ChalkBox_EmotaCatalog()>=20,"catalog exposes multiple native emotes")
assert(ChalkBox_EmotaGetEnabled("SIT")==true and
    ChalkBox_EmotaGetEnabled("SLEEP")==true and
    ChalkBox_EmotaGetEnabled("DANCE")==true,"new idle actions are available")
math.random=originalRandom

-- Blizzard sends clusters of item-cache events when several bags open.
-- One HUD update should serve a burst without dropping the next update.
local scheduled={}
C_Timer.After=function(delay,fn)
    scheduled[#scheduled+1]={delay=delay,callback=fn}
end
Fire("BAG_UPDATE_DELAYED")
Fire("GET_ITEM_INFO_RECEIVED",123)
Fire("ITEM_DATA_LOAD_RESULT",123)
assert(#scheduled==1 and scheduled[1].delay>=0.2,
    "inventory and item-cache bursts are coalesced")
scheduled[1].callback()
Fire("BAG_UPDATE_DELAYED")
assert(#scheduled==2,"later inventory changes are still displayed")
scheduled[2].callback()

print("PASS: full-width HUD, protected root untouched, safe screen layout integration, Emota idle rotation and frequency extremes")
