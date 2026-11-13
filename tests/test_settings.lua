-- Native Blizzard AddOns options regression (Lua 5.1, no client).
local frames, widgets, printed = {}, {}, {}
local registered, opened, categories = {}, {}, {}
_G.UIParent={}
_G.DEFAULT_CHAT_FRAME={AddMessage=function(_,str) printed[#printed+1]=str end}
_G.ChalkBoxDB={lootAdvice=true,bar="top",barReserve=true,emota={auto=false,idleAuto=true,debug=false,idleVariety=false,contextual=true,jokeFrequency=50},guard={guild=true,duel=true,party=false,trade=false,channel=false},camp={enabled=true,toast=true,supplies=true,buffs=true,classCare=true,interval=45,
    toastOptions={locked=true,opacity=0.92}},meter={shown=true,locked=false,mode="dps",session="current",rows=8,scale=1,opacity=0.94,iconMode="class"},keep={["id:11"]="Test Trinket"}}
_G.ChalkBoxZoneDB={enabled=true,mode="smart",limit=10,managed={},muted={}}
_G.SlashCmdList={CHALKBOX=function(command)
    if command:find("^keep ") then ChalkBoxDB.keep["name:new"] = "New Item" end
    if command:find("^forget ") then ChalkBoxDB.keep["name:new"] = nil end
end}
_G.ChalkBox_GetKeepList=function()
    local result={}
    for key,label in pairs(ChalkBoxDB.keep) do result[#result+1]={key=key,label=label} end
    table.sort(result,function(a,b) return a.key < b.key end)
    return result
end
_G.ChalkBox_RemoveKeepKey=function(key) ChalkBoxDB.keep[key]=nil end
_G.ChalkBox_QuestCommand=function(value)
    if value=="on" then ChalkBoxZoneDB.enabled=true end
    if value=="off" then ChalkBoxZoneDB.enabled=false end
    if value=="smart" or value=="zone" or value=="all" then
        ChalkBoxZoneDB.mode=value
    end
    if value:match("^limit %d+$") then
        ChalkBoxZoneDB.limit=tonumber(value:match("%d+"))
    end
    printed[#printed+1]="quests "..value
end
_G.ChalkBox_QuestStatus=function()
    return {enabled=ChalkBoxZoneDB.enabled,mode=ChalkBoxZoneDB.mode,
        limit=ChalkBoxZoneDB.limit,api=true,accepted=8,tracked=5,reason="ready"}
end
local defaults={rate=true,eta=true,time=true,gold=true,bags=true,
    gear=true,rested=true,latency=false,pet=true}
_G.ChalkBoxDB.barStats={}
for k,v in pairs(defaults) do ChalkBoxDB.barStats[k]=v end
_G.ChalkBox_BarStatEnabled=function(key)
    return ChalkBoxDB.barStats[key]==true
end
_G.ChalkBox_BarCommand=function(value)
    if value=="top" or value=="bottom" or value=="off" then ChalkBoxDB.bar=value end
    if value=="reserve on" then ChalkBoxDB.barReserve=true end
    if value=="reserve off" then ChalkBoxDB.barReserve=false end
    local stat,on=value:match("^stat (%a+) (%a+)$")
    if stat and (on=="on" or on=="off") then
        ChalkBoxDB.barStats[stat]=on=="on"
    end
    local profile=value:match("^stats (%a+)$")
    if profile then
        for key,default in pairs(defaults) do
            ChalkBoxDB.barStats[key]=profile=="all" or
                (profile=="minimal" and (key=="bags" or key=="gold")) or
                (profile=="balanced" and default)
        end
    end
    printed[#printed+1]="bar "..value
end
local editor=false
_G.ChalkBox_BarAppearanceGet=function() return ChalkBoxDB.barBackgroundOpacity or 70 end
_G.ChalkBox_BarAppearanceSet=function(value)
    ChalkBoxDB.barBackgroundOpacity=math.max(0,math.min(100,value))
end
_G.ChalkBox_BarEditStatus=function() return editor end
_G.ChalkBox_BarHighlightNotPresent=function() return nil end
local originalBarCommand=ChalkBox_BarCommand
_G.ChalkBox_BarCommand=function(command)
    if command=="edit on" then editor=true end
    if command=="edit off" then editor=false end
    if command=="layout reset" then ChalkBoxZoneDB.trailLayout=nil end
    originalBarCommand(command)
end
_G.ChalkBox_BagHighlightStatus=function()
    return {enabled=ChalkBoxDB.lootHighlightKnown~=false,
        opacity=ChalkBoxDB.lootHighlightOpacity or 75}
end
_G.ChalkBox_BagHighlightSet=function(on) ChalkBoxDB.lootHighlightKnown=on end
_G.ChalkBox_BagHighlightOpacity=function(value)
    ChalkBoxDB.lootHighlightOpacity=math.floor(value+0.5)
end
_G.ChalkBox_BagHighlightsRefresh=function() printed[#printed+1]="bag markers refresh" end
_G.ChalkBox_RaceCatalog=function()
    return {
        {token="Dwarf",label="Dwarf",implemented=true},
        {token="VoidElf",label="Void Elf",implemented=false}
    }
end
_G.UnitRace=function() return "Dwarf","Dwarf" end
_G.ChalkBox_RaceBehaviorStatus=function(token)
    local modes=ChalkBoxDB.emota.raceModes or {}
    return {token=token,examples="FLEX, SALUTE",mode=modes[token] or "default"}
end
_G.ChalkBox_RaceBehaviorSet=function(token,mode)
    if token~="Dwarf" then return false end
    ChalkBoxDB.emota.raceModes=ChalkBoxDB.emota.raceModes or {}
    ChalkBoxDB.emota.raceModes[token]=mode
    return true
end
_G.ChalkBox_BagOffsetSet=function(value)
    ChalkBoxDB.bagOffsetY=math.max(-120,math.min(120,math.floor(value+0.5)))
end
_G.ChalkBox_BagStatus=function()
    return {offset=ChalkBoxDB.bagOffsetY or 0}
end
_G.ChalkBox_EmotaCommand=function(value)
    if value=="auto on" then ChalkBoxDB.emota.auto=true end
    if value=="auto off" then ChalkBoxDB.emota.auto=false end
    if value=="idle on" then ChalkBoxDB.emota.idleAuto=true end
    if value=="idle off" then ChalkBoxDB.emota.idleAuto=false end
    if value=="debug on" then ChalkBoxDB.emota.debug=true end
    if value=="debug off" then ChalkBoxDB.emota.debug=false end
    if value=="variety on" then ChalkBoxDB.emota.idleVariety=true end
    if value=="variety off" then ChalkBoxDB.emota.idleVariety=false end
    if value=="context on" then ChalkBoxDB.emota.contextual=true end
    if value=="context off" then ChalkBoxDB.emota.contextual=false end
    printed[#printed+1]="emota "..value
end
_G.ChalkBox_EmotaTestJoke=function() printed[#printed+1]="joke" end
_G.ChalkBox_EmotaPreviewIdle=function() printed[#printed+1]="random idle" end
_G.ChalkBox_GuardSet=function(key,on)
    ChalkBoxDB.guard[key]=on
    printed[#printed+1]="guard "..key.." "..tostring(on)
end
_G.ChalkBox_GuardCommand=function() printed[#printed+1]="guard status" end
_G.ChalkBox_CampCommand=function(command)
    if command=="on" or command=="off" then
        ChalkBoxDB.camp.enabled=command=="on"
    else
        local key,arg=command:match("^(%S+) (%S+)$")
        if key and (arg=="on" or arg=="off") then
            if key=="classcare" then key="classCare" end
            ChalkBoxDB.camp[key]=arg=="on"
        elseif key=="interval" then ChalkBoxDB.camp.interval=tonumber(arg) end
    end
    printed[#printed+1]="camp "..command
end
_G.ChalkBox_CampStatus=function()
    return {interval=ChalkBoxDB.camp.interval,class="HUNTER"}
end
_G.ChalkBox_CampChecklist=function() printed[#printed+1]="checklist" end
_G.ChalkBox_CampTestToast=function() printed[#printed+1]="test toast";return true end
_G.ChalkBox_ToastStatus=function()
    local d=ChalkBoxDB.camp.toastOptions
    return {locked=d.locked,opacity=d.opacity,position=d.position or "top"}
end
_G.ChalkBox_ToastCommand=function(command)
    local d=ChalkBoxDB.camp.toastOptions
    if command=="lock" then d.locked=true end
    if command=="unlock" then d.locked=false end
    if command=="reset" then d.position=nil;d.x=nil;d.y=nil end
    local opacity=command:match("^opacity (%d+)$")
    if opacity then d.opacity=tonumber(opacity)/100 end
    printed[#printed+1]="toast "..command
end
_G.ChalkBox_MeterCommand=function(command)
    local meter=ChalkBoxDB.meter
    if command=="show" then meter.shown=true end
    if command=="hide" then meter.shown=false end
    if command=="lock" then meter.locked=true end
    if command=="unlock" then meter.locked=false end
    local rows=command:match("^rows (%d+)$")
    local scale=command:match("^scale (%d+)$")
    if rows then meter.rows=tonumber(rows) end
    if scale then meter.scale=tonumber(scale)/100 end
    local opacity=command:match("^opacity (%d+)$")
    if opacity then meter.opacity=tonumber(opacity)/100 end
    local mode=command:match("^icons (%a+)$")
    if mode then meter.iconMode=mode end
    printed[#printed+1]="meter "..command
end
_G.ChalkBox_MeterStatus=function() return ChalkBoxDB.meter end
_G.ChalkBox_ProfessionSummary=function() return "Leatherworking",17 end
_G.ChalkBox_ProfessionRefresh=function() printed[#printed+1]="profession refresh" end
_G.ChalkBox_EmotaSetJokeFrequency=function(v) ChalkBoxDB.emota.jokeFrequency=math.floor(v+0.5) end
_G.ChalkBox_EmotaCatalog=function() return {
  {token="JOKE",automatic=true},{token="WAVE",automatic=true},
  {token="DANCE",automatic=false},{token="SALUTE",automatic=false}
} end
_G.ChalkBox_EmotaGetEnabled=function(token)
    local t=ChalkBoxDB.emota.allowed or {}
    return t[token]~=nil and t[token] or token=="JOKE" or token=="WAVE"
end
_G.ChalkBox_EmotaSetEnabled=function(token,v)
    ChalkBoxDB.emota.allowed=ChalkBoxDB.emota.allowed or {}
    ChalkBoxDB.emota.allowed[token]=v
end
_G.ChalkBox_EmotaTest=function(token) printed[#printed+1]="try "..token end

_G.CreateFrame=function(kind,name,parent)
    local f={kind=kind,name=name,parent=parent,shown=true,script={}}
    function f:SetSize(w,h) self.w=w;self.h=h end
    function f:SetPoint(...) self.anchor={...} end
    function f:SetWidth(w) self.w=w end
    function f:SetJustifyH(value) self.justify=value end
    function f:CreateFontString()
        local ff={}
        function ff:SetPoint(...) end
        function ff:SetWidth(w) self.width=w end
        function ff:SetJustifyH(value) end
        function ff:SetText(value) self.value=value end
        return ff
    end
    function f:CreateTexture()
        return {SetPoint=function() end,SetSize=function() end,
            SetColorTexture=function() end}
    end
    function f:Hide() self.shown=false end
    function f:Show() self.shown=true;if self.script.OnShow then self.script.OnShow(self) end end
    function f:SetScript(event,callback) self.script[event]=callback end
    function f:RegisterEvent(event) self.event=event end
    function f:UnregisterEvent(event) self.event=nil end
    function f:SetText(text) self.text=text end
    function f:SetMinMaxValues(a,b) self.min,self.max=a,b end
    function f:SetValueStep(v) self.step=v end
    function f:SetValue(value)
        self.value=value
        if self.script.OnValueChanged then self.script.OnValueChanged(self,value) end
    end
    function f:GetText() return self.text end
    function f:SetChecked(value) self.checked=value end
    function f:GetChecked() return self.checked end
    function f:SetAutoFocus() end
    function f:SetMaxLetters() end
    function f:ClearFocus() end
    function f:Click(checked)
        if checked ~= nil then self.checked=checked end
        assert(self.script.OnClick,"no click script for "..(self.text or tostring(self.kind)))
        self.script.OnClick(self)
    end
    frames[#frames+1]=f
    if kind=="Button" or kind=="CheckButton" then widgets[#widgets+1]=f end
    return f
end
_G.Settings={
    RegisterCanvasLayoutCategory=function(panel,name)
        assert(name=="ChalkBox")
        local cat={panel=panel,name=name,ID=(#registered+101)}
        function cat:GetID() return self.ID end
        registered[#registered+1]=cat
        categories.home=cat
        return cat
    end,
    RegisterAddOnCategory=function(category)
        assert(category==categories.home)
    end,
    RegisterCanvasLayoutSubcategory=function(parent,panel,name)
        assert(parent==categories.home)
        local cat={panel=panel,name=name,ID=(#registered+101)}
        function cat:GetID() return self.ID end
        registered[#registered+1]=cat
        categories[name]=cat
        return cat
    end,
    OpenToCategory=function(id) opened[#opened+1]=id end,
}
assert(loadfile("ChalkBox_Settings.lua"))("ChalkBox")
local loader=frames[#frames]
assert(loader.event=="PLAYER_LOGIN","must register settings when the client is ready")
loader.script.OnEvent(loader,"PLAYER_LOGIN")
assert(#registered==14,"native pages include LootSense Appearance, TrailBar Appearance and Emota Race Behavior")
assert(categories.home.name=="ChalkBox")
ChalkBox_OpenSettings()
assert(opened[#opened]==101,"default /chalk must open native settings")
ChalkBox_OpenSettings("loot")
assert(opened[#opened]==102)
ChalkBox_OnAddonCompartmentClick()
assert(opened[#opened]==101)
local function Control(caption)
    for _,f in ipairs(widgets) do if f.text==caption then return f end end
    error("Missing native option button: "..caption)
end
local function FindCheckByParentTitle(title)
    local category = categories[title]
    assert(category,title)
    local checks={}
    for _,f in ipairs(frames) do if f.kind=="CheckButton" and f.parent==category.panel then
        checks[#checks+1]=f
    end end
    return checks
end
local checks=FindCheckByParentTitle("LootSense")
assert(#checks==1,"loot page needs an actual toggle")
categories["LootSense"].panel:Show()
assert(checks[1].checked==true)
checks[1]:Click(false)
assert(ChalkBoxDB.lootAdvice==false,"native checkbox must control item advice")
local edit
for _,f in ipairs(frames) do if f.kind=="EditBox" then edit=f end end
assert(edit,"personal protection input must be on the options page")
edit:SetText("New Item")
Control("Keep Item"):Click()
assert(ChalkBoxDB.keep["name:new"],"Keep Item must call original protection logic")
categories["LootSense"].panel:Show()
Control("Remove"):Click() -- sorts by key; first is id:11
assert(ChalkBoxDB.keep["id:11"]==nil,"Remove must use the exact protected key")
Control("LootSense Appearance"):Click()
assert(opened[#opened]==categories["LootSense Appearance"].ID)
categories["LootSense Appearance"].panel:Show()
local lootCheck=FindCheckByParentTitle("LootSense Appearance")
assert(#lootCheck==1 and lootCheck[1].checked,
    "ingredient highlighting defaults ON for verified recipes only")
lootCheck[1]:Click(false)
assert(ChalkBoxDB.lootHighlightKnown==false,
    "new bag highlight toggle is stored independently from tooltip hints")
lootCheck[1]:Click(true)
Control("Refresh Bag Markers"):Click()
assert(printed[#printed]=="bag markers refresh")
local questCheck=FindCheckByParentTitle("QuestSense")[1]
categories["QuestSense"].panel:Show()
questCheck:Click(false)
assert(ChalkBoxZoneDB.enabled==false,"quest menu must toggle existing tracking code")
Control("Refresh Quests"):Click()
assert(printed[#printed]=="quests refresh","refresh calls the reworked scan")
Control("Nearby only"):Click()
assert(ChalkBoxZoneDB.mode=="zone","nearby-only is a selectable strict mode")
Control("All accepted"):Click()
assert(ChalkBoxZoneDB.mode=="all")
Control("Smart (recommended)"):Click()
assert(ChalkBoxZoneDB.mode=="smart")
Control("15"):Click()
assert(ChalkBoxZoneDB.limit==15,"autowatch limit can be selected from native options")
Control("Tracking Diagnostics"):Click()
assert(printed[#printed]=="quests status")
local barChecks=FindCheckByParentTitle("TrailBar")
assert(#barChecks==4)
categories["TrailBar"].panel:Show()
barChecks[2]:Click(true)
assert(ChalkBoxDB.bar=="bottom","placement selection must update saved bar")
assert(barChecks[4].checked==true,"screen reservation should be enabled by default")
barChecks[4]:Click(false)
assert(ChalkBoxDB.barReserve==false,"user can disable screen reservation")
barChecks[4]:Click(true)
assert(ChalkBoxDB.barReserve==true,"screen reservation can be re-enabled")
Control("Reset Session"):Click()
assert(printed[#printed]=="bar reset")
Control("Appearance"):Click()
assert(opened[#opened]==categories["TrailBar Appearance"].ID,
    "TrailBar links into its own appearance and drag-layout page")
Control("Stats & Presets"):Click()
assert(opened[#opened]==categories["TrailBar Stats"].ID,
    "TrailBar should navigate directly to the new stats page")
categories["TrailBar Appearance"].panel:Show()
Control("Edit Bar"):Click()
assert(editor,"native drag-layout edit toggle starts edit mode")
Control("Done Editing"):Click()
assert(not editor,"done exits editor without losing saved layout")
Control("Reset Layout"):Click()
assert(printed[#printed]=="bar layout reset","reset layout button reaches controller")
categories["TrailBar Stats"].panel:Show()
local statsChecks=FindCheckByParentTitle("TrailBar Stats")
assert(#statsChecks==9,"9 independent stats are accessible")
assert(statsChecks[1].checked==true and statsChecks[4].checked==false,
    "bag space is on by default and optional latency starts off")
statsChecks[4]:Click(true)
assert(ChalkBoxDB.barStats.latency==true,
    "latency checkbox persists the new module preference")
statsChecks[2]:Click(false)
assert(ChalkBoxDB.barStats.gear==false,"gear checkbox disables the module")
Control("Minimal"):Click()
assert(ChalkBoxDB.barStats.bags and ChalkBoxDB.barStats.gold
    and not ChalkBoxDB.barStats.gear and not ChalkBoxDB.barStats.rate,
    "Minimal preset is functional")
Control("All"):Click()
assert(ChalkBoxDB.barStats.gear and ChalkBoxDB.barStats.latency,
    "All preset enables optional modules")
Control("Balanced"):Click()
assert(ChalkBoxDB.barStats.gear and not ChalkBoxDB.barStats.latency,
    "Balanced preset restores tested defaults")
local emotaChecks=FindCheckByParentTitle("Emota")
categories["Emota"].panel:Show()
assert(#emotaChecks==5)
emotaChecks[1]:Click(true)
assert(ChalkBoxDB.emota.auto==true,"emota auto must be reachable in native settings")
emotaChecks[3]:Click(true)
assert(ChalkBoxDB.emota.debug==true)
Control("Test Joke"):Click()
assert(printed[#printed]=="joke")
emotaChecks[4]:Click(true)
assert(ChalkBoxDB.emota.idleVariety==true)
emotaChecks[5]:Click(false)
assert(ChalkBoxDB.emota.contextual==false,"race/class personality toggle works")
local slider
for _,frame in ipairs(frames) do
    if frame.kind=="Slider" and frame.parent==categories["Emota"].panel then slider=frame end
end
assert(slider and slider.value==50,"slider must default to original joke cadence")
slider:SetValue(100)
assert(ChalkBoxDB.emota.jokeFrequency==100,"joke frequency slider updates settings")
Control("Surprise Me"):Click()
assert(printed[#printed]=="random idle","idle preview must be reachable in normal settings")
Control("Races"):Click()
assert(opened[#opened]==categories["Emota Race Behavior"].ID,
    "Emota links directly to new race behavior editor")
categories["Emota Race Behavior"].panel:Show()
Control("Expressive"):Click()
assert(ChalkBoxDB.emota.raceModes.Dwarf=="expressive",
    "live racial intensity selection saves the chosen race")
Control("Next race"):Click()
Control("Off"):Click()
assert(ChalkBoxDB.emota.raceModes.VoidElf==nil,
    "placeholder race does not gain fabricated emote behavior")
Control("My race"):Click()
Control("Default"):Click()
assert(ChalkBoxDB.emota.raceModes.Dwarf=="default")
Control("Catalog"):Click()
assert(opened[#opened]==categories["Emote Catalog"].ID,
    "catalog must have its own native settings page")
local catalogChecks=FindCheckByParentTitle("Emote Catalog")
assert(#catalogChecks==6,"catalog supports up to six paged emotes")
categories["Emote Catalog"].panel:Show()
catalogChecks[1]:Click(false)
assert(ChalkBoxDB.emota.allowed.JOKE==false,"per-emote checkbox updates allowlist")
local catalogTry
for _,frame in ipairs(frames) do
    if frame.kind=="Button" and frame.text=="Try" then catalogTry=frame;break end
end
assert(catalogTry)
catalogTry:Click()
assert(printed[#printed]=="try JOKE","preview button tests selected catalog entry")
local guardChecks=FindCheckByParentTitle("QuietGuard")
assert(#guardChecks==5,"QuietGuard page should have five real social toggles")
categories["QuietGuard"].panel:Show()
assert(guardChecks[1].checked==true and guardChecks[2].checked==true)
assert(guardChecks[3].checked==false)
guardChecks[3]:Click(true)
assert(ChalkBoxDB.guard.party==true)
guardChecks[2]:Click(false)
assert(ChalkBoxDB.guard.duel==false)
Control("Show Protection Status"):Click()
assert(printed[#printed]=="guard status")
local prepChecks=FindCheckByParentTitle("Adventure Prep")
assert(#prepChecks==5,"Adventure Prep has a toast option and four reminder preferences")
categories["Adventure Prep"].panel:Show()
assert(prepChecks[2].checked==true,"on-screen reminders enabled by default")
prepChecks[2]:Click(false)
assert(ChalkBoxDB.camp.toast==false,"onscreen reminders can be turned off")
prepChecks[2]:Click(true)
assert(ChalkBoxDB.camp.toast==true)
prepChecks[4]:Click(false)
assert(ChalkBoxDB.camp.supplies==false)
Control("20m"):Click()
assert(ChalkBoxDB.camp.interval==20)
Control("Test"):Click()
assert(printed[#printed]=="test toast","native options preview must show reminder")
Control("Print Checklist"):Click()
assert(printed[#printed]=="checklist")
Control("Tent Used"):Click()
assert(printed[#printed]=="camp tent done","manual tent acknowledgment is accessible from options")
assert(categories["QuietGuard"].name=="QuietGuard" and categories["Adventure Prep"].name=="Adventure Prep")
Control("Toast Appearance"):Click()
assert(opened[#opened]==categories["Toast Appearance"].ID,
    "Adventure Prep directly navigates to Toast Appearance native submenu")
categories["Toast Appearance"].panel:Show()
local toastChecks=FindCheckByParentTitle("Toast Appearance")
assert(#toastChecks==1 and toastChecks[1].checked,
    "toast lock default is on")
toastChecks[1]:Click(false)
assert(not ChalkBoxDB.camp.toastOptions.locked)
Control("Preview / Move (25s)"):Click()
assert(printed[#printed]=="toast preview")
Control("Reset to Top"):Click()
assert(printed[#printed]=="toast reset")
local meterChecks=FindCheckByParentTitle("Combat Meter")
assert(#meterChecks==2,"meter has show and lock controls")
categories["Combat Meter"].panel:Show()
assert(meterChecks[1].checked and not meterChecks[2].checked)
meterChecks[1]:Click(false)
assert(not ChalkBoxDB.meter.shown,"show/hide toggle controls window")
meterChecks[1]:Click(true)
meterChecks[2]:Click(true)
assert(ChalkBoxDB.meter.locked,"lock switch is active")
assert(ChalkBoxDB.meter.iconMode=="class","WoW class badges are shown by default")
Control("Spec"):Click()
assert(ChalkBoxDB.meter.iconMode=="spec","users can prefer WoW specialization art")
Control("Off"):Click()
assert(ChalkBoxDB.meter.iconMode=="off","icons can be hidden to save space")
Control("Class"):Click()
assert(ChalkBoxDB.meter.iconMode=="class","easy one-click return to class icons")
Control("5 rows"):Click()
assert(ChalkBoxDB.meter.rows==5)
Control("115%"):Click()
assert(ChalkBoxDB.meter.scale==1.15)
local sliders={}
for _,frame in ipairs(frames) do
    if frame.kind=="Slider" then sliders[#sliders+1]=frame end
end
assert(#sliders==6,"four existing sliders plus bag highlight and TrailBar appearance opacity")
local appearanceSlider,highlightSlider
for _,frame in ipairs(sliders) do
    if frame.parent==categories["TrailBar Appearance"].panel then
        appearanceSlider=frame
    end
    if frame.parent==categories["LootSense Appearance"].panel then
        highlightSlider=frame
    end
end
assert(appearanceSlider and appearanceSlider.value==70,
    "native bar opacity slider defaults to original 70%")
appearanceSlider:SetValue(0)
assert(ChalkBoxDB.barBackgroundOpacity==0,
    "slider makes only bar background disappear")
appearanceSlider:SetValue(100)
assert(ChalkBoxDB.barBackgroundOpacity==100,
    "slider can produce an opaque Blizzard-charcoal background")
assert(highlightSlider and highlightSlider.value==75,
    "bag recipe insets have a separate 75% opacity default")
highlightSlider:SetValue(40)
assert(ChalkBoxDB.lootHighlightOpacity==40,
    "reagent highlight strength is configurable in native settings")
local meterSlider
for _,frame in ipairs(sliders) do
    if frame.parent==categories["Combat Meter"].panel then meterSlider=frame end
end
local bagSlider
for _,frame in ipairs(sliders) do
    if frame.parent==categories["TrailBar"].panel then bagSlider=frame end
end
assert(bagSlider and bagSlider.value==0,"bag offset starts at Blizzard default")
bagSlider:SetValue(-30)
assert(ChalkBoxDB.bagOffsetY==30,
    "vertical slider downward moves separate bags down from the stock center")
bagSlider:SetValue(35)
assert(ChalkBoxDB.bagOffsetY==-35,
    "vertical slider upward raises separate bags above Blizzard's stock anchor")
bagSlider:SetValue(0)
assert(ChalkBoxDB.bagOffsetY==0,
    "vertical slider midpoint restores exactly Blizzard's original position")
assert(meterSlider,"native meter opacity slider belongs to Combat Meter page")
meterSlider:SetValue(65)
assert(ChalkBoxDB.meter.opacity==0.65,
    "native transparency slider updates persisted meter opacity")
local toastSlider
for _,frame in ipairs(sliders) do
    if frame.parent==categories["Toast Appearance"].panel then toastSlider=frame end
end
assert(toastSlider and toastSlider.value==92)
toastSlider:SetValue(70)
assert(ChalkBoxDB.camp.toastOptions.opacity==0.7,
    "Toast Appearance slider saves its own opacity, independently from the meter")
Control("Reset Data..."):Click()
assert(printed[#printed]=="meter reset","reset must request confirmation in the real module")
Control("Show Window"):Click()
assert(printed[#printed]=="meter show")
print("PASS: native settings, QuestSense, Toast Appearance, Combat Meter class/spec/off icon controls, CampSense and Emota")
