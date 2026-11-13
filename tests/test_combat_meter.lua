-- ChalkBox's native Forever combat meter: live protected values go only to C UI
-- setters, not Lua comparisons/math/formatting/persistent SavedVariables.
local frames,queued,chat,callCount,resetCount={}, {}, {}, 0,0
local locked=false
local protected=true
local function Secret(v)
    return setmetatable({secret=true,raw=v},{
        __lt=function() error("secret value compared by Lua!") end,
        __le=function() error("secret value compared by Lua!") end,
        __add=function() error("secret value added by Lua!") end,
        __div=function() error("secret value divided by Lua!") end,
        __tostring=function() error("secret value converted by Lua!") end,
    })
end
_G.issecretvalue=function(value) return type(value)=="table" and value.secret==true end
_G.UIParent={GetCenter=function() return 600,410 end}
_G.DEFAULT_CHAT_FRAME={AddMessage=function(_,msg) chat[#chat+1]=msg end}
_G.C_Timer={After=function(delay,fn)
    assert(delay>=0.10,"combat refresh is throttled")
    queued[#queued+1]=fn
end}
_G.InCombatLockdown=function() return locked end
_G.YES="Yes";_G.NO="No"
_G.StaticPopupDialogs={}
_G.StaticPopup_Show=function(which) _G.lastPopup=which end
_G.RAID_CLASS_COLORS={HUNTER={r=0.35,g=0.7,b=0.46}}
_G.Enum={
    DamageMeterType={DamageDone=0,Dps=1,HealingDone=2,Hps=3,
        Interrupts=5,DamageTaken=7},
    DamageMeterSessionType={Overall=0,Current=1,Expired=2}
}
local rawValue=Secret(555)
local maxValue=Secret(900)
local secretName=Secret("Detok")
_G.C_DamageMeter={
    IsDamageMeterAvailable=function() return true end,
    GetCombatSessionFromType=function(session,typeId)
        callCount=callCount+1
        _G.lastSession=session;_G.lastMeterType=typeId
        if not protected then
            return {maxAmount=900,combatSources={
                {name="Detok",classFilename="HUNTER",isLocalPlayer=true,
                    amountPerSecond=555,totalAmount=4400},
                {name="Other Player",classFilename="WARRIOR",isLocalPlayer=false,
                    amountPerSecond=240,totalAmount=2200}
            }}
        end
        return {maxAmount=maxValue,combatSources={
            {name=secretName,classFilename="HUNTER",isLocalPlayer=true,
                amountPerSecond=rawValue,totalAmount=Secret(4400)},
            {name="Other Player",classFilename="WARRIOR",isLocalPlayer=false,
                amountPerSecond=240,totalAmount=2200}
        }}
    end,
    ResetAllCombatSessions=function() resetCount=resetCount+1 end
}
local function Widget(kind,name,parent)
    local w={kind=kind,name=name,parent=parent,shown=true,script={}}
    function w:RegisterEvent(name) self.events=self.events or {};self.events[name]=true end
    function w:SetScript(name,fn) self.script[name]=fn end
    function w:SetSize(x,y) self.w,self.h=x,y end
    function w:SetWidth(x) self.w=x end
    function w:SetHeight(y) self.h=y end
    function w:SetScale(x) self.scale=x end
    function w:SetAlpha(x) self.alpha=x end
    function w:SetResizable(x) self.resizable=x end
    function w:SetResizeBounds(...) self.bounds={...} end
    function w:GetWidth() return self.w end
    function w:GetHeight() return self.h end
    function w:StartSizing(which) self.sizing=which end
    function w:ClearAllPoints() self.anchors={} end
    function w:SetPoint(...) self.anchors=self.anchors or {};self.anchors[#self.anchors+1]={...} end
    function w:SetAllPoints() end
    function w:SetFrameStrata(s) self.strata=s end
    function w:SetMovable(x) self.movable=x end
    function w:SetClampedToScreen(x) self.clamped=x end
    function w:EnableMouse(x) self.mouse=x end
    function w:RegisterForDrag() end
    function w:StartMoving() self.moving=true end
    function w:StopMovingOrSizing() self.moving=false end
    function w:GetCenter() return 800,500 end
    function w:Show() self.shown=true end
    function w:Hide() self.shown=false end
    function w:IsShown() return self.shown end
    function w:CreateTexture() return Widget("Texture",nil,self) end
    function w:CreateFontString() return Widget("FontString",nil,self) end
    function w:SetColorTexture(...) self.color={...} end
    function w:SetTextColor(...) self.fontColor={...} end
    function w:SetStatusBarColor(...) self.barColor={...} end
    function w:SetStatusBarTexture(...) self.texture={...} end
    function w:SetMinMaxValues(a,b) self.min,self.max=a,b end
    function w:SetValue(v)
        self.value=v
        if self.kind=="Slider" and self.script.OnValueChanged then
            self.script.OnValueChanged(self,v)
        end
    end
    function w:SetText(v) self.text=v end
    function w:SetFormattedText(fmt,v)
        self.nativeFormat=fmt
        self.text=v -- do NOT attempt Lua formatting
    end
    function w:SetJustifyH() end
    frames[#frames+1]=w
    return w
end
_G.CreateFrame=Widget
assert(loadfile("CombatMeter.lua"))("ChalkBox")
local event
for _,f in ipairs(frames) do
    if f.kind=="Frame" and f.events and f.events.PLAYER_LOGIN then event=f end
end
assert(event and event.events.DAMAGE_METER_CURRENT_SESSION_UPDATED)
assert(event.events.DAMAGE_METER_COMBAT_SESSION_UPDATED and event.events.DAMAGE_METER_RESET)
event.script.OnEvent(event,"ADDON_LOADED","ChalkBox")
assert(ChalkBoxDB.meter.shown==true and ChalkBoxDB.meter.mode=="dps")
event.script.OnEvent(event,"PLAYER_LOGIN")
local window
for _,f in ipairs(frames) do if f.name=="ChalkBoxCombatMeterFrame" then window=f end end
assert(window and window.shown and window.w==326 and window.h==266)
assert(window.resizable==true and window.alpha==0.94,
    "window resizable by default, with saved opacity")
local function Flush()
    local todo=queued
    queued={}
    for _,fn in ipairs(todo) do fn() end
end
Flush()
assert(lastMeterType==1 and lastSession==1,"defaults to current DPS")
local bars,labels={},{}
for _,f in ipairs(frames) do
    if f.kind=="StatusBar" then bars[#bars+1]=f end
    if f.kind=="FontString" then labels[#labels+1]=f end
end
assert(#bars==12,"eight shown and four latent row bars")
assert(bars[1].value==rawValue and bars[1].max==maxValue,
    "secret DPS & scaling passed unchanged to C statusbar")
local formatted=false;local named=false
for _,f in ipairs(labels) do
    if f.nativeFormat=="%.0f" and f.text==rawValue then formatted=true end
    if f.text==secretName then named=true end
end
assert(formatted and named,"secret DPS and name go directly to native UI setters")
assert(ChalkBox_MeterStatus().rows==8)
local function Button(caption)
    for _,f in ipairs(frames) do
        if f.kind=="Button" and f.caption==caption then return f end
    end
end
local printButton=Button("PRINT")
local lockButton=Button("LOCK")
local grip
for _,f in ipairs(frames) do
    if f.isChalkBoxResizeGrip then grip=f end
end
assert(printButton and lockButton and grip,
    "visible PRINT/LOCK buttons and resize grip must be directly accessible")
assert(not Button("X"),"the unwanted meter close button must be gone")
local sawBranding=false
for _,f in ipairs(labels) do
    if f.text=="CHALKBOX" or f.text=="Gold stripe = you  |  Native Blizzard data" then
        sawBranding=true
    end
end
assert(not sawBranding,"no branding or noisy footer inside compact meter")
local slider
for _,f in ipairs(frames) do
    if f.kind=="Slider" then slider=f end
end
assert(slider and slider.value==94,"opacity slider shown on the meter window")
slider:SetValue(75)
assert(ChalkBoxDB.meter.opacity==0.75 and window.alpha==0.75,
    "on-window transparency slider changes visibility and saves preference")
ChalkBox_MeterCommand("opacity 60")
assert(window.alpha==0.60,"slash opacity setting uses same state")
ChalkBox_MeterCommand("healing")
Flush()
assert(lastMeterType==2,"can switch damage/healing modes")
ChalkBox_MeterCommand("last")
Flush()
assert(lastSession==2,"can review last fight")
ChalkBox_MeterCommand("overall")
Flush()
assert(lastSession==0,"can review overall group session")
ChalkBox_MeterCommand("rows 5")
assert(window.h==191,"user can shrink meter to five rows")
ChalkBox_MeterCommand("scale 115")
assert(window.scale==1.15,"user can enlarge readable UI")
ChalkBox_MeterCommand("lock")
assert(ChalkBoxDB.meter.locked and lockButton.caption=="UNLOCK")
grip.script.OnMouseDown(grip,"LeftButton")
assert(not window.sizing,"lock prevents resizing")
lockButton.script.OnClick(lockButton)
assert(not ChalkBoxDB.meter.locked and lockButton.caption=="LOCK",
    "on-window lock button toggles back without visiting options")
window:SetSize(422,66+10*25)
grip.script.OnMouseDown(grip,"LeftButton")
assert(window.sizing=="BOTTOMRIGHT","grip starts live window resize")
grip.script.OnMouseUp(grip)
assert(ChalkBoxDB.meter.width==422 and ChalkBoxDB.meter.rows==10,
    "dragged width/height turn into saved width and visible row count")
assert(window.w==422 and window.h==316,"resized meter keeps dimensions")
ChalkBox_MeterCommand("hide")
Flush()
local old=callCount
event.script.OnEvent(event,"DAMAGE_METER_COMBAT_SESSION_UPDATED")
Flush()
assert(callCount==old,"hidden window should not poll Blizzard data")
ChalkBox_MeterCommand("show")
Flush()
assert(window.shown and callCount>old,"show immediately displays latest data")
ChalkBox_MeterCommand("reset")
assert(lastPopup=="CHALKBOX_METER_RESET" and resetCount==0,
    "reset must require clear confirmation")
locked=true
assert(StaticPopupDialogs.CHALKBOX_METER_RESET.OnAccept()==false and resetCount==0,
    "do not reset combat data in combat")
locked=false
assert(StaticPopupDialogs.CHALKBOX_METER_RESET.OnAccept()==true and resetCount==1,
    "user-confirmed action resets Blizzard's shared sessions")
-- Printing is intentionally local only, never party chat and never secret.
locked=true
local oldChat=#chat
printButton.script.OnClick(printButton)
assert(#chat==oldChat+1 and chat[#chat]:find("Finish combat",1,true),
    "print button refuses protected in-combat totals")
locked=false
oldChat=#chat
printButton.script.OnClick(printButton)
assert(#chat==oldChat+1 and chat[#chat]:find("protected",1,true),
    "protected data also refused when client still masks results after combat")
protected=false
oldChat=#chat
printButton.script.OnClick(printButton)
assert(#chat==oldChat+3 and chat[oldChat+1]:find("HEAL",1,true)
    and chat[oldChat+2]:find("Detok",1,true),
    "one-click print writes a header and both ranked results to LOCAL chat")
assert(resetCount==1,"printing must never reset shared combat sessions")
local api=C_DamageMeter
C_DamageMeter=nil
ChalkBox_MeterCommand("status")
assert(chat[#chat]:find("unavailable",1,true),"native API absence is explicit")
ChalkBox_MeterCommand("dps")
Flush()
assert(window.shown)
C_DamageMeter=api
print("PASS: meter print guarded, no branding, draggable resize/lock/opacity, protected-value UI setters, modes, settings and shared reset confirmation")
