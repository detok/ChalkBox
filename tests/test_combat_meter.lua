-- ChalkBox's native Forever combat meter: live protected values go only to C UI
-- setters, not Lua comparisons/math/formatting/persistent SavedVariables.
local frames,queued,chat,callCount,resetCount={}, {}, {}, 0,0
local locked=false
local protected=true
local grouped=true
local raiding=false
local now=1000
local partyMessages={}
_G.IsInGroup=function() return grouped end
_G.IsInRaid=function() return raiding end
_G.GetTime=function() return now end
_G.C_ChatInfo={SendChatMessage=function(message,channel)
    partyMessages[#partyMessages+1]={message=message,channel=channel}
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
ChalkBox_MeterCommand("show")
Flush()
assert(lastMeterType==1 and lastSession==1,"manual show defaults to current DPS")
local bars,labels={},{}
for _,f in ipairs(frames) do
    if f.kind=="StatusBar" then bars[#bars+1]=f end
    if f.kind=="FontString" then labels[#labels+1]=f end
end
assert(#bars==12,"five default rows and seven latent raid row bars")
assert(window.h==141 and bars[1].parent.shown and not bars[4].parent.shown,
    "three recorded combatants produce only three populated rows, no blank slots")
ChalkBox_MeterCommand("rows 8")
Flush()
assert(ChalkBox_MeterStatus().rows==8 and window.h==141,
    "raid row cap may expand but height still follows actual combatants")
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
    "menu RESET must invoke existing shared-data confirmation")
locked=true
assert(StaticPopupDialogs.CHALKBOX_METER_RESET.OnAccept()==false and resetCount==0,
    "do not reset combat data in combat")
locked=false
assert(StaticPopupDialogs.CHALKBOX_METER_RESET.OnAccept()==true and resetCount==1,
    "user-confirmed action resets Blizzard's shared sessions")
-- Printing is ONE explicit party chat line, never a multi-line chat flood.
locked=true
local oldChat=#chat
ChalkBox_MeterPrintFight()
assert(#chat==oldChat+1 and chat[#chat]:find("Finish combat",1,true)
    and #partyMessages==0,
    "legacy print never uses in-combat secret totals or sends to party")
locked=false
oldChat=#chat
ChalkBox_MeterPrintFight()
assert(#chat==oldChat+1 and chat[#chat]:find("protected",1,true)
    and #partyMessages==0,
    "protected values after combat are never sent or formatted")
protected=false
grouped=false
ChalkBox_MeterPrintFight()
assert(#partyMessages==0 and chat[#chat]:find("Join a party",1,true),
    "solo players do not get a SAY or local-chat fallback")
grouped=true
raiding=true
ChalkBox_MeterPrintFight()
assert(#partyMessages==0,"strict party request must never broadcast to raid")
raiding=false
ChalkBox_MeterPrintFight()
assert(#partyMessages==1 and partyMessages[1].channel=="PARTY",
    "one click must submit EXACTLY one standard PARTY chat message")
assert(partyMessages[1].message:find("CB HEAL (Overall):",1,true)
    and partyMessages[1].message:find("1 Detok 4400",1,true)
    and partyMessages[1].message:find("2 Other Player 2200",1,true)
    and #partyMessages[1].message<=255,
    "party report includes selected stat, selected session and ranking")
oldChat=#chat
ChalkBox_MeterPrintFight()
assert(#partyMessages==1 and #chat==oldChat+1
    and chat[#chat]:find("already requested",1,true),
    "double-clicking within three seconds does not spam group chat")
now=1004
local copies={}
_G.ChalkBox_MeterShowCopy=function(message,reason)
    copies[#copies+1]={text=message,reason=reason}
    return true
end
C_ChatInfo.SendChatMessage=function()
    error("Forever party chat restriction")
end
oldChat=#chat
ChalkBox_MeterPrintFight()
assert(#partyMessages==1 and #copies==1
    and copies[1].text:find("CB HEAL (Overall):",1,true)
    and copies[1].reason:find("rejected",1,true),
    "rejected report preserves a copyable summary without another chat send")
C_ChatInfo.SendChatMessage=function()
    error("Should not call chat while restricted")
end
C_ChatInfo.InChatMessagingLockdown=function() return true end
ChalkBox_MeterPrintFight()
assert(#copies==2 and #partyMessages==1,
    "chat lockdown prepares local text without calling protected API")
C_ChatInfo.InChatMessagingLockdown=nil
C_ChatInfo.SendChatMessage=nil
_G.SendChatMessage=function(message,channel)
    partyMessages[#partyMessages+1]={message=message,channel=channel,legacy=true}
end
ChalkBox_MeterPrintFight()
assert(#partyMessages==2 and partyMessages[2].legacy
    and partyMessages[2].channel=="PARTY",
    "old Classic API is a supported fallback when modern chat API is absent")
C_ChatInfo.SendChatMessage=function(message,channel)
    partyMessages[#partyMessages+1]={message=message,channel=channel}
end
now=1010
local saved=C_DamageMeter.GetCombatSessionFromType
C_DamageMeter.GetCombatSessionFromType=function(session,typeId)
    if session==Enum.DamageMeterSessionType.Current then
        return {combatSources={}}
    end
    return saved(session,typeId)
end
ChalkBox_MeterCommand("current")
Flush()
ChalkBox_MeterPrintFight()
assert(#partyMessages==3
    and partyMessages[3].message:find("CB HEAL (Last):",1,true),
    "when the current session is empty, report the last recorded fight")
C_DamageMeter.GetCombatSessionFromType=saved
assert(resetCount==1,"PRINT never resets Blizzard's shared sessions")
local api=C_DamageMeter
C_DamageMeter=nil
ChalkBox_MeterCommand("status")
assert(chat[#chat]:find("unavailable",1,true),"native API absence is explicit")
ChalkBox_MeterCommand("dps")
Flush()
assert(window.shown)
event.script.OnEvent(event,"PLAYER_LOGIN")
assert(not window.shown and ChalkBoxDB.meter.shown==false,
    "previously open meter starts closed on a fresh login")
C_DamageMeter=api
ChalkBox_MeterCommand("last")
local adapter=ChalkBox_MeterReportAdapter()
assert(adapter and adapter:GetSessionType()==Enum.DamageMeterSessionType.Expired
    and adapter:GetDamageMeterType()==Enum.DamageMeterType.Dps
    and adapter:GetCombatSession().combatSources[1].name=="Detok",
    "compact menu reads its selected last fight and DPS from the shared native API")
local delegated
_G.ChalkBox_NativeMeterPrint=function(selected,channel)
    delegated={selected=selected,channel=channel}
    return true
end
assert(ChalkBox_MeterReportSelected("SAY")
    and delegated and delegated.channel=="SAY"
    and delegated.selected:GetSessionType()==Enum.DamageMeterSessionType.Expired,
    "compact reporting always delegates to native sender, never a second chat path")
print("PASS: compact native report adapter, five-row auto-fit, secret/solo/raid guards, confirmed RESET, icons, gear header and all sessions")
