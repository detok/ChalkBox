-- Native Blizzard AddOns options regression (Lua 5.1, no client).
local frames, widgets, printed = {}, {}, {}
local registered, opened, categories = {}, {}, {}
_G.UIParent={}
_G.DEFAULT_CHAT_FRAME={AddMessage=function(_,str) printed[#printed+1]=str end}
_G.ChalkBoxDB={lootAdvice=true,bar="top",barReserve=true,emota={auto=false,idleAuto=true,debug=false,idleVariety=false,contextual=true,jokeFrequency=50},guard={guild=true,duel=true,party=false,trade=false,channel=false},camp={enabled=true,toast=true,supplies=true,buffs=true,classCare=true,interval=45},meter={shown=true,locked=false,mode="dps",session="current",rows=8,scale=1,opacity=0.94},keep={["id:11"]="Test Trinket"}}
_G.ChalkBoxZoneDB={enabled=true,managed={},muted={}}
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
    printed[#printed+1]="quests "..value
end
_G.ChalkBox_BarCommand=function(value)
    if value=="top" or value=="bottom" or value=="off" then ChalkBoxDB.bar=value end
    if value=="reserve on" then ChalkBoxDB.barReserve=true end
    if value=="reserve off" then ChalkBoxDB.barReserve=false end
    printed[#printed+1]="bar "..value
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
assert(#registered==9,"one main options category and eight native subcategories")
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
local questCheck=FindCheckByParentTitle("QuestSense")[1]
categories["QuestSense"].panel:Show()
questCheck:Click(false)
assert(ChalkBoxZoneDB.enabled==false,"quest menu must toggle existing tracking code")
Control("Refresh Zone Quests"):Click()
assert(printed[#printed]=="quests refresh","refresh should call existing function")
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
Control("Reset Session Stats"):Click()
assert(printed[#printed]=="bar reset")
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
    if frame.kind=="Slider" then slider=frame end
end
assert(slider and slider.value==50,"slider must default to original joke cadence")
slider:SetValue(100)
assert(ChalkBoxDB.emota.jokeFrequency==100,"joke frequency slider updates settings")
Control("Surprise Me"):Click()
assert(printed[#printed]=="random idle","idle preview must be reachable in normal settings")
Control("Catalog"):Click()
assert(opened[#opened]==106,"catalog must be its own native settings page")
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
Control("Test Reminder"):Click()
assert(printed[#printed]=="test toast","native options preview must show reminder")
Control("Print Checklist"):Click()
assert(printed[#printed]=="checklist")
Control("Tent Used"):Click()
assert(printed[#printed]=="camp tent done","manual tent acknowledgment is accessible from options")
assert(categories["QuietGuard"].name=="QuietGuard" and categories["Adventure Prep"].name=="Adventure Prep")
local meterChecks=FindCheckByParentTitle("Combat Meter")
assert(#meterChecks==2,"meter has show and lock controls")
categories["Combat Meter"].panel:Show()
assert(meterChecks[1].checked and not meterChecks[2].checked)
meterChecks[1]:Click(false)
assert(not ChalkBoxDB.meter.shown,"show/hide toggle controls window")
meterChecks[1]:Click(true)
meterChecks[2]:Click(true)
assert(ChalkBoxDB.meter.locked,"lock switch is active")
Control("5 rows"):Click()
assert(ChalkBoxDB.meter.rows==5)
Control("115%"):Click()
assert(ChalkBoxDB.meter.scale==1.15)
local sliders={}
for _,frame in ipairs(frames) do
    if frame.kind=="Slider" then sliders[#sliders+1]=frame end
end
assert(#sliders==2,"native Emota and Combat Meter sliders present")
sliders[2]:SetValue(65)
assert(ChalkBoxDB.meter.opacity==0.65,
    "native transparency slider updates persisted meter opacity")
Control("Reset Data..."):Click()
assert(printed[#printed]=="meter reset","reset must request confirmation in the real module")
Control("Show Window"):Click()
assert(printed[#printed]=="meter show")
print("PASS: native settings with eight subpages, combat meter controls, social protection, camp prep, TrailBar and Emota")
