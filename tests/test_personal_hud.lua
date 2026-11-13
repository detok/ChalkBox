-- Lua 5.1 integration regression: custom information bar and Emota module.
local now, playerXP, xpMax, playerLevel, money = 1000, 200, 1000, 25, 150000
local standalone, moving, combat = false, true, false
local frames, timers, emotes, notes = {}, {}, {}, {}
-- Simulate a screen-sized UIParent. The bar must shorten this root by
-- exactly 18 UI units instead of offsetting selected named UI frames.
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
_G.ChalkBoxDB = {}
_G.DEFAULT_CHAT_FRAME = {AddMessage=function(_, line) notes[#notes + 1]=line end}
_G.GetTime = function() return now end
_G.UnitXP = function(unit) assert(unit=="player"); return playerXP end
_G.UnitXPMax = function(unit) assert(unit=="player"); return xpMax end
_G.UnitLevel = function(unit) assert(unit=="player"); return playerLevel end
_G.GetMoney = function() return money end
_G.ChalkBox_BarReadStats=function()
    return {
        bags={free=12,total=96,general=7,special=5},
        gear={percent=87,worst=76,items=9},
        rested={percent=42,xp=420},
        latency={home=21,world=63},
        pet={state="ready",percent=95},
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
    return {SetAllPoints=function() end, SetColorTexture=function() end,
        SetPoint=function() end, SetHeight=function() end, SetWidth=function() end,
        Show=function(self) self.visible=true end, Hide=function(self) self.visible=false end}
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
    function frame:Show() self.visible=true end
    function frame:Hide() self.visible=false end
    frames[#frames+1]=frame
    return frame
end
_G.GameTooltip = {SetOwner=function() end,ClearLines=function() end,
    AddLine=function() end,Show=function() end,Hide=function() end}

local function Fire(event,...)
    for _,frame in ipairs(frames) do
        if frame.events[event] and frame.scripts.OnEvent then
            frame.scripts.OnEvent(frame,event,...)
        end
    end
end
assert(loadfile("Emota.lua"))("ChalkBox")
assert(loadfile("TrailBar.lua"))("ChalkBox")
Fire("ADDON_LOADED","ChalkBox")
assert(ChalkBoxDB.emota.auto==false,"integrated auto-emotes must default off")
assert(ChalkBoxDB.bar=="top","default info bar is at top")
Fire("PLAYER_ENTERING_WORLD")
local bar
for _,frame in ipairs(frames) do if frame.name=="ChalkBoxInfoBar" then bar=frame end end
assert(bar and bar.visible and bar.anchor=="BOTTOMRIGHT",
    "top bar should occupy the new reserved strip above UIParent")
assert(ChalkBoxDB.barReserve==true,"screen reservation should be on by default")
assert(UIParent:GetHeight()==750,"top reservation must reduce usable root height by 18")
assert(select(5,UIParent:GetPoint(1))==-18,"UIParent top must move down 18")
local function RootIsBaseline()
    return UIParent:GetHeight()==768 and select(5,UIParent:GetPoint(1))==0
       and select(5,UIParent:GetPoint(2))==0
end
assert(bar.height==18,"bar should remain slim")
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
assert(FindText("Gear 87%"),"durability appears in the actual TrailBar widgets")
assert(FindText("Rest 42%"),"rested XP appears as a level percent")
assert(FindText("Pet 95%"),"Hunter pet status is available when readable")
assert(FindMetric("Bags ").visible and FindMetric("Gear ").visible
    and FindMetric("Rest ").visible,
    "new priority widgets appear on a normal screen")
assert(ChalkBoxDB.barStats.bags and ChalkBoxDB.barStats.gear
    and ChalkBoxDB.barStats.rested and not ChalkBoxDB.barStats.latency,
    "balanced defaults feature bags/gear/rest while opt-in latency saves space")
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
bar.width=1440
bar.scripts.OnSizeChanged(bar)
assert(FindMetric("World ").visible and FindMetric("Pet ").visible,
    "wider UI restores all configured latency and Hunter status metrics")
bar.width=1024
bar.scripts.OnSizeChanged(bar)
ChalkBox_BarCommand("stats balanced")
assert(not ChalkBoxDB.barStats.latency,"balanced preset restores intentional defaults")
assert(FindMetric("Gear ").visible,"preset restores previously hidden durability widget")
local state=ChalkBox_BarStatus()
assert(type(state.enabled)=="table" and type(state.visible)=="table",
    "native status gives enabled vs currently fitting modules")
-- A normal UIParent-anchored widget keeps its own offset; by shrinking the
-- root, every such widget follows the inset without being named by the addon.
local anchoredChild=CreateFrame("Frame","NeverWhitelisted",UIParent)
anchoredChild:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-10,-8)
assert(anchoredChild.points[1][2]==UIParent)
ChalkBox_BarCommand("reserve off")
assert(RootIsBaseline(),"reserve off must restore the exact full-screen root")
assert(bar.anchor=="TOPRIGHT","overlay fallback anchors to UIParent edge")
ChalkBox_BarCommand("reserve on")
assert(UIParent:GetHeight()==750 and bar.anchor=="BOTTOMRIGHT",
    "reserve on must reactivate physical top gap")
ChalkBox_BarCommand("bottom")
assert(UIParent:GetHeight()==750 and select(5,UIParent:GetPoint(2))==18,
    "bottom reservation reduces root height from below")
assert(bar.anchor=="TOPRIGHT" and bar.visible,
    "bar must live below the shortened UIParent")
ChalkBox_BarCommand("off")
assert(RootIsBaseline(),"hiding bar must restore original root")
assert(bar.visible==false,"bar can be hidden without losing session statistics")
ChalkBox_BarCommand("top")
assert(bar.visible and bar.anchor=="BOTTOMRIGHT")
assert(UIParent:GetHeight()==750)
combat=true
ChalkBox_BarCommand("bottom")
assert(select(5,UIParent:GetPoint(1))==-18,
    "in combat the existing top inset remains unchanged")
combat=false
Fire("PLAYER_REGEN_ENABLED")
assert(select(5,UIParent:GetPoint(2))==18 and bar.anchor=="TOPRIGHT",
    "pending bottom inset applies after combat")
ChalkBox_BarCommand("top")
assert(select(5,UIParent:GetPoint(1))==-18)
ChalkBox_BarCommand("reserve off")
assert(RootIsBaseline())
ChalkBox_BarCommand("reserve on")
assert(UIParent:GetHeight()==750)
-- Blizzard can reset UIParent anchors during display/UI scale changes.
UIParent:SetAllPoints()
assert(RootIsBaseline())
Fire("UI_SCALE_CHANGED")
assert(UIParent:GetHeight()==750,
    "TrailBar re-applies a lost screen inset after a UI scale reset")
ChalkBox_BarCommand("reserve off")
assert(RootIsBaseline(),"UI scale changes still preserve reversible layout")
ChalkBox_BarCommand("reserve on")
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

print("PASS: HUD stats, 18px root safe area, Emota randomized idle rotation, disables and frequency extremes")
