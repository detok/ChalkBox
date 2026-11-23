-- ChalkBox's native Forever combat meter: live protected values go only to C UI
-- setters, not Lua comparisons/math/formatting/persistent SavedVariables.
local frames,queued,chat,callCount,resetCount={}, {}, {}, 0,0
local locked=false
local protected=true
local grouped=true
local raiding=false
local now=1000
local partyMessages,rawPartyMessages={},{}
local function RecordParty(message,channel,legacy)
    assert(not message:find("[|\r\n]"),"plain WoW chat line must not contain pipe or newline")
    rawPartyMessages[#rawPartyMessages+1]={message=message,channel=channel,legacy=legacy}
    if message:match("^CB .+%):$") then
        partyMessages[#partyMessages+1]={message=message,channel=channel,legacy=legacy,lines={message}}
    else
        local report=partyMessages[#partyMessages]
        assert(report and report.channel==channel,"player row must follow same-channel heading")
        report.message=report.message..(#report.lines==1 and " " or ", ")..message
        report.lines[#report.lines+1]=message
    end
end
_G.IsInGroup=function() return grouped end
_G.IsInRaid=function() return raiding end
_G.GetTime=function() return now end
_G.C_ChatInfo={SendChatMessage=function(message,channel)
    RecordParty(message,channel)
end}
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
            {name=secretName,classFilename="HUNTER",specIconID=135774,isLocalPlayer=true,
                amountPerSecond=rawValue,totalAmount=Secret(4400)},
            {name="Other Player",classFilename="WARRIOR",isLocalPlayer=false,
                amountPerSecond=240,totalAmount=2200},
            {name="Unknown Summon",classFilename=nil,isLocalPlayer=false,
                amountPerSecond=75,totalAmount=170}
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
    function w:SetTexture(v) self.texturePath=v end
    function w:SetTexCoord(...) self.texCoords={...} end
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
assert(loadfile("CombatLogMeter.lua"))("ChalkBox")
local personalMeterFrame=frames[#frames]
assert(personalMeterFrame.events and
    not personalMeterFrame.events.COMBAT_LOG_EVENT_UNFILTERED,
    "WoW Forever blocks addon combat-log access; never register the event")
assert(loadfile("CombatMeter.lua"))("ChalkBox")
local event
for _,f in ipairs(frames) do
    if f.kind=="Frame" and f.events and f.events.PLAYER_LOGIN then event=f end
end
assert(event and event.events.DAMAGE_METER_CURRENT_SESSION_UPDATED)
assert(event.events.DAMAGE_METER_COMBAT_SESSION_UPDATED and event.events.DAMAGE_METER_RESET)
event.script.OnEvent(event,"ADDON_LOADED","ChalkBox")
assert(ChalkBoxDB.meter.shown==false and ChalkBoxDB.meter.mode=="dps",
    "optional meter defaults off")
event.script.OnEvent(event,"PLAYER_LOGIN")
local window
for _,f in ipairs(frames) do if f.name=="ChalkBoxCombatMeterFrame" then window=f end end
assert(window and not window.shown and window.w==326 and window.h==191,
    "meter starts hidden at login")
assert(window.resizable==true and window.alpha==1
    and window.background.color[4]==0.70,
    "meter starts with Bar-like independent background opacity and full-strength text")
local function Flush()
    local todo=queued
    queued={}
    for _,fn in ipairs(todo) do fn() end
end
Flush()
assert(callCount==0,"a hidden meter must not fetch combat data at startup")
assert(event.script.OnUpdate,
    "visible-only heartbeat can recover native damage events that are missed")
event.script.OnUpdate(event,2.0)
assert(callCount==0,"hidden heartbeat must not poll native combat data")
ChalkBox_MeterCommand("show")
Flush()
assert(lastMeterType==1 and lastSession==1,"manual show defaults to current DPS")
local shown=ChalkBox_MeterStatus()
assert(shown.feed=="blizzard" and shown.reason=="showing",
    "status names the live feed and why the window looks the way it does")
local bars,labels={},{}
for _,f in ipairs(frames) do
    if f.kind=="StatusBar" then bars[#bars+1]=f end
    if f.kind=="FontString" then labels[#labels+1]=f end
end
assert(#bars==12,"five default rows and seven latent raid row bars")
assert(window.h==191 and bars[1].parent.shown and not bars[4].parent.shown,
    "three recorded combatants fill three rows inside the saved window")
ChalkBox_MeterCommand("rows 8")
Flush()
assert(ChalkBox_MeterStatus().rows==8 and window.h==266,
    "raising the row cap keeps that height instead of collapsing")
ChalkBox_MeterCommand("rows 5")
Flush()
assert(bars[1].value==rawValue and bars[1].max==maxValue,
    "secret DPS & scaling passed unchanged to C statusbar")
local formatted=false;local named=false
for _,f in ipairs(labels) do
    if f.nativeFormat=="%.0f" and f.text==rawValue then formatted=true end
    if f.text==secretName then named=true end
end
assert(formatted and named,"secret DPS and name go directly to native UI setters")
local icons={}
for _,f in ipairs(frames) do
    if f.isChalkBoxClassIcon then icons[#icons+1]=f end
end
local classSheet="Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
assert(#icons==12 and ChalkBox_MeterStatus().iconMode=="class",
    "twelve reusable icon slots and recognizable CLASS defaults")
assert(icons[1].shown and icons[1].texturePath==classSheet
    and icons[1].texCoords[1]==0 and icons[1].texCoords[3]==0.25,
    "hunter emblem uses Blizzard class atlas at correct tile coordinates")
assert(icons[2].shown and icons[2].texturePath==classSheet
    and icons[2].texCoords[1]==0 and icons[2].texCoords[3]==0,
    "warrior class icon has separate correct tile coordinates")
assert(icons[3].shown and icons[3].texturePath==
    "Interface\\Icons\\INV_Misc_QuestionMark",
    "unknown/pet sources never get mislabeled as a player class")
assert(not icons[4].shown,"empty result rows must not retain stale icons")
local firstValueLabel=bars[1].parent.value
local thirdValueLabel=bars[3].parent.value
assert(firstValueLabel and thirdValueLabel,
    "each native combat row owns its own numerical text")
local name1
for _,f in ipairs(labels) do
    if f.text==secretName then name1=f end
end
assert(name1 and name1.anchors and name1.anchors[#name1.anchors][4]==49,
    "player name is aligned after icon, without covering damage amounts")
assert(ChalkBox_MeterStatus().rows==5)
local function Button(caption)
    for _,f in ipairs(frames) do
        if f.kind=="Button" and f.caption==caption then return f end
    end
end
local menuButton=Button("Menu")
local menuOpens=0
_G.ChalkBox_MeterOpenMenu=function(owner)
    assert(owner and owner.parent==window,
        "compact gear popup anchors to the original meter header")
    menuOpens=menuOpens+1
    return true
end
local grip
for _,f in ipairs(frames) do
    if f.isChalkBoxResizeGrip then grip=f end
end
assert(menuButton and grip and not Button("PRINT")
    and not Button("RESET") and not Button("LOCK"),
    "the meter has exactly one compact gear menu, plus the original resize grip")
menuButton.script.OnClick(menuButton)
assert(menuOpens==1,"gear button opens the compact menu")
local meterHeader=menuButton.parent
assert(meterHeader and meterHeader.script.OnMouseUp,
    "the drag header also owns a right-click menu shortcut")
meterHeader.script.OnMouseUp(meterHeader,"RightButton")
assert(menuOpens==2,"right-click opens the same menu without replacing the drag script")
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
assert(slider and slider.value==70 and slider.min==0,
    "meter background slider defaults to 70%, supporting the Bar's 0-100 range")
slider:SetValue(75)
assert(ChalkBoxDB.meter.opacity==0.75 and window.alpha==1
    and window.background.color[4]==0.75,
    "meter background opacity changes without fading text and icons")
ChalkBox_MeterCommand("opacity 60")
assert(window.alpha==1 and window.background.color[4]==0.60,
    "slash opacity setting changes only the background")
ChalkBox_MeterCommand("opacity 0")
assert(window.alpha==1 and window.background.color[4]==0
    and name1:IsShown() and icons[1]:IsShown(),
    "fully transparent meter still shows the player's data and icons")
ChalkBox_MeterCommand("opacity 60")
ChalkBox_MeterCommand("icons spec")
Flush()
assert(ChalkBox_MeterStatus().iconMode=="spec"
    and icons[1].texturePath==135774
    and icons[1].texCoords[1]==0.08,
    "native specialization fileID should render like an existing macro icon")
assert(icons[2].texturePath==classSheet,
    "missing spec icon falls back to the correct class emblem")
ChalkBox_MeterCommand("icons off")
Flush()
assert(not icons[1].shown and not icons[2].shown and not icons[3].shown,
    "icon mode off removes all emblems and reclaims the name space")
assert(name1.anchors[#name1.anchors][4]==27,
    "hiding icons repositions player names to the old layout")
ChalkBox_MeterCommand("icons class")
Flush()
assert(icons[1].shown and icons[1].texturePath==classSheet
    and name1.anchors[#name1.anchors][4]==49,
    "switching back to class mode restores proper emblem and spacing")
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
assert(ChalkBoxDB.meter.locked)
grip.script.OnMouseDown(grip,"LeftButton")
assert(not window.sizing,"lock prevents resizing")
ChalkBox_MeterCommand("unlock")
assert(not ChalkBoxDB.meter.locked,
    "compact gear menu's lock/unlock command uses the original preference")
window:SetSize(422,66+10*25)
grip.script.OnMouseDown(grip,"LeftButton")
assert(window.sizing=="BOTTOMRIGHT","grip starts live window resize")
grip.script.OnMouseUp(grip)
assert(ChalkBoxDB.meter.width==422 and ChalkBoxDB.meter.rows==10,
    "dragged width/height turn into saved width and visible row count")
assert(window.w==422 and window.h==316,"resized meter keeps dimensions")
Flush()
event.script.OnUpdate(event,0.8)
assert(window.h==316 and window.w==422,
    "a later refresh does not shrink a size the player just dragged")
-- No combat-session event was fired: the visible-only heartbeat still
-- repaints one bounded native sample instead of leaving values stale.
Flush()
local beforeHeartbeat=callCount
event.script.OnUpdate(event,0.50)
assert(callCount==beforeHeartbeat,
    "heartbeat does not poll more often than the bounded cadence")
event.script.OnUpdate(event,0.30)
assert(callCount==beforeHeartbeat+1,
    "visible meter recovers without needing a native session event")
ChalkBox_MeterCommand("hide")
Flush()
local old=callCount
event.script.OnUpdate(event,2)
assert(callCount==old,"hidden meter disables all periodic API reads")
event.script.OnEvent(event,"DAMAGE_METER_COMBAT_SESSION_UPDATED")
Flush()
assert(callCount==old,"hidden window should not poll Blizzard data")
ChalkBox_MeterCommand("show")
Flush()
assert(window.shown and callCount>old,"show immediately displays latest data")
ChalkBox_MeterCommand("reset")
assert(lastPopup=="CHALKBOX_METER_RESET" and resetCount==0,
    "menu RESET must invoke existing shared-data confirmation")
locked=true
assert(StaticPopupDialogs.CHALKBOX_METER_RESET.OnAccept()==false and resetCount==0,
    "do not reset combat data in combat")
locked=false
assert(StaticPopupDialogs.CHALKBOX_METER_RESET.OnAccept()==true and resetCount==1,
    "user-confirmed action resets Blizzard's shared sessions")
-- The deprecated print API and every legacy slash command are inert.
local reportChatBefore=#chat
local reportSendBefore=#rawPartyMessages
assert(ChalkBox_MeterPrintFight()==false)
assert(ChalkBox_MeterReportAdapter()==nil)
assert(ChalkBox_MeterReportSelected("PARTY")==false)
ChalkBox_MeterCommand("print")
ChalkBox_MeterCommand("print local")
ChalkBox_MeterCommand("native auto on")
ChalkBox_MeterCommand("native channel party")
ChalkBox_MeterCommand("native status")
assert(#chat==reportChatBefore and #rawPartyMessages==reportSendBefore,
    "old print commands make no chat messages and cannot send anything")
assert(resetCount==1,"report commands do not reset Blizzard sessions")
-- An empty current fight must stay empty. Last is only shown when chosen.
Flush()
local fallbackGetter=C_DamageMeter.GetCombatSessionFromType
local askedExpired=false
C_DamageMeter.GetCombatSessionFromType=function(session,kind)
    _G.lastSession=session
    if session==Enum.DamageMeterSessionType.Expired then askedExpired=true end
    if session==Enum.DamageMeterSessionType.Current then
        return {maxAmount=0,combatSources={}}
    end
    return fallbackGetter(session,kind)
end
ChalkBox_MeterCommand("current")
Flush()
assert(lastSession==Enum.DamageMeterSessionType.Current and
    not askedExpired and bars[1].parent.value.text=="",
    "empty current fight does not silently show the previous pull")
assert(ChalkBox_MeterStatus().reason=="empty")
C_DamageMeter.GetCombatSessionFromType=fallbackGetter
-- An intermittent player entry failure must not prevent other rows from
-- showing, nor retain a stale player number.
local failing=bars[1].SetStatusBarColor
local once=true
bars[1].SetStatusBarColor=function(self,...)
    if once then once=false;error("simulated protected rendering failure") end
    return failing(self,...)
end
ChalkBox_MeterCommand("dps")
Flush()
assert(bars[1].parent.value.text=="" and
    bars[2].parent.value.text~=nil and
    ChalkBox_MeterStatus().displayError:find("simulated protected",1,true),
    "one failed row is isolated and its issue is available to diagnostics")
bars[1].SetStatusBarColor=failing
local fewer=C_DamageMeter.GetCombatSessionFromType
C_DamageMeter.GetCombatSessionFromType=function()
    return {maxAmount=120,combatSources={
        {name="Only Player",classFilename="HUNTER",
            amountPerSecond=120,totalAmount=1000}}}
end
ChalkBox_MeterCommand("damage")
Flush()
assert(thirdValueLabel.text=="",
    "unused combat rows clear stale numerical text as well as names")
C_DamageMeter.GetCombatSessionFromType=fewer
local availableCheck=C_DamageMeter.IsDamageMeterAvailable
C_DamageMeter.IsDamageMeterAvailable=function() return Secret(true) end
ChalkBox_MeterCommand("dps")
Flush()
assert(ChalkBox_MeterStatus().reason=="secret" and
    not ChalkBox_MeterStatus().displayError,
    "a locked availability flag is reported instead of crashing the meter")
C_DamageMeter.IsDamageMeterAvailable=availableCheck
local petGetter=C_DamageMeter.GetCombatSessionFromType
C_DamageMeter.GetCombatSessionFromType=function()
    return {maxAmount=100,combatSources={
        {name="Wolf",isPet=true,isLocalPlayer=false,
            amountPerSecond=40,totalAmount=400},
        {name="",isPet=true,isLocalPlayer=false,
            amountPerSecond=10,totalAmount=80},
    }}
end
ChalkBox_MeterCommand("damage")
Flush()
assert(bars[1].parent.playerName.text=="Wolf" and
    icons[1].texturePath=="Interface\\Icons\\Ability_Hunter_BeastCall",
    "a named pet keeps its name and uses the pet icon")
assert(bars[2].parent.playerName.text=="Pet",
    "an unnamed pet is labeled Pet instead of a player class")
C_DamageMeter.GetCombatSessionFromType=petGetter
local api=C_DamageMeter
C_DamageMeter=nil
ChalkBox_MeterCommand("status")
assert(chat[#chat]:find("unavailable",1,true),"native API absence is explicit")
ChalkBox_MeterCommand("dps")
Flush()
assert(window.shown)
ChalkBox_PersonalMeterIngest(1,"SWING_DAMAGE",false,
    "Player-1","Detok",0x401,0,"Creature-1","Boar",0,0,250)
ChalkBox_PersonalMeterIngest(1,"SWING_DAMAGE",false,
    "Pet-1","Wolf",0x1101,0,"Creature-1","Boar",0,0,50)
ChalkBox_MeterCommand("dps")
Flush()
assert(ChalkBox_MeterStatus().feed=="personal" and
    bars[1].parent.playerName.text=="Detok" and
    tonumber(bars[1].parent.value.text)==250 and
    bars[2].parent.playerName.text=="Wolf",
    "a missing built-in meter shows your damage and your pet from the combat log")
event.script.OnEvent(event,"PLAYER_LOGIN")
assert(not window.shown and ChalkBoxDB.meter.shown==false,
    "previously open meter starts closed on a fresh login")
C_DamageMeter=api
ChalkBox_MeterCommand("last")
assert(ChalkBox_MeterStatus().session=="expired",
    "the local combat display still shows the previous fight")
assert(ChalkBox_MeterPrintFight()==false
    and ChalkBox_MeterReportSelected("SAY")==false,
    "report APIs remain harmless after all session changes")
print("PASS: Combat Meter still displays Blizzard data, resets safely, and has zero chat reporting")
