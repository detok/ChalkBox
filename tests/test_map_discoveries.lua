-- The existing Blizzard map gets one optional Discoveries button;
-- its separate window follows selected map, keeps dungeon/outdoor separate.
_G.ChalkBoxZoneDB={}
local frames={}
local function Frame(kind,name,parent)
    local f={kind=kind,name=name,parent=parent,shown=false}
    function f:SetSize(w,h) self.w=w;self.h=h end
    function f:SetPoint(...) self.point={...} end
    function f:SetFrameStrata() end
    function f:SetMovable() end
    function f:SetClampedToScreen() end
    function f:EnableMouse() end
    function f:RegisterForDrag() end
    function f:SetScript(event,callback) self[event]=callback end
    function f:HookScript(event,callback) self["hook"..event]=callback end
    function f:RegisterEvent() end
    function f:SetText(value) self.text=value end
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:IsShown() return self.shown end
    function f:CreateTexture()
        local t={}
        function t:SetAllPoints() end
        function t:SetPoint() end
        function t:SetHeight() end
        function t:SetColorTexture(...) self.color={...} end
        return t
    end
    function f:CreateFontString()
        local font={}
        function font:SetPoint() end
        function font:SetWidth() end
        function font:SetJustifyH() end
        function font:SetText(x) self.text=x end
        return font
    end
    frames[#frames+1]=f
    return f
end
_G.UIParent={}
local viewed=1436
_G.WorldMapFrame=Frame("Frame","WorldMapFrame",UIParent)
WorldMapFrame.GetMapID=function() return viewed end
_G.CreateFrame=Frame
_G.C_Map={
    GetBestMapForUnit=function() return 1436 end,
    GetMapInfo=function(id)
        return {name=id==1436 and "Westfall" or "Redridge Mountains"}
    end
}
local visible=true
_G.ChalkBox_DropOptions=function()
    return {mapButton=visible,enabled=true,areas=2}
end
_G.ChalkBox_DropMapData=function(id)
    if id~=1436 then return {zone=nil,dungeons={}} end
    return {
        zone={kind="outdoor",name="Westfall",windows=12,items={}},
        dungeons={{key="d:36:1",name="The Deadmines",items=2,
            area={kind="dungeon",name="The Deadmines",windows=5}}}
    }
end
_G.ChalkBox_DropSources=function(key)
    if key=="z:1436" then return {
        {key="c:12345",name="Defias Bandit",windows=12}}
    end
    return {}
end
_G.ChalkBox_DropAreaItems=function(key,source)
    if key=="z:1436" then
        if source then return {{name="Linen Cloth",quantity=8,
            windows=4,attempts=12,rate=33.333}} end
        return {{name="Linen Cloth",quantity=8,windows=4},
            {name="Bone",quantity=2,windows=2}}
    end
    if key=="d:36:1" then return {
        {name="Dungeon Trinket",quantity=1,windows=1}}
    end
    return {}
end
assert(loadfile("MapDiscoveries.lua"))("ChalkBox")
local button
for _,f in ipairs(frames) do
    if f.name=="ChalkBoxMapDiscoveriesButton" then button=f end
end
assert(button and button.parent==WorldMapFrame and
    button.text=="Discoveries" and button.shown,
    "map gets one native button attached to existing Blizzard world map")
button.OnClick(button)
local journal
for _,f in ipairs(frames) do
    if f.name=="ChalkBoxMapDiscoveries" then journal=f end
end
assert(journal and journal.shown and journal.w==466,
    "button opens separate discovery panel without replacing quest map")
local all,source,dungeons,close
for _,f in ipairs(frames) do
    if f.parent==journal then
        if f.text=="Outdoor" then all=f end
        if f.text=="Dungeons" then dungeons=f end
        if f.text=="Source (1)" then source=f end
        if f.text=="Close" then close=f end
    end
end
assert(all and dungeons and close)
local buttons={}
for _,f in ipairs(frames) do
    if f.parent==journal and f.text then
        buttons[#buttons+1]=f
    end
end
local sourceButton
for _,b in ipairs(buttons) do
    if b.text=="Source (1)" then sourceButton=b end
end
assert(sourceButton,"source filtering exposed on map browser")
sourceButton.OnClick(sourceButton)
dungeons.OnClick(dungeons)
local dungeonNext
for _,b in ipairs(buttons) do
    if b.text and b.text:match("^Next dungeon") then dungeonNext=b end
end
assert(dungeonNext,"a discovered dungeon is a separate map category")
viewed=1437
journal.OnUpdate(journal,0.7)
assert(journal.shown,"changing viewed map updates the existing panel")
visible=false
ChalkBox_MapDiscoveriesRefresh()
assert(not button.shown and not journal.shown,
    "map toggle hides only ChalkBox controls, preserving native map")
visible=true
ChalkBox_MapDiscoveriesRefresh()
assert(button.shown)
print("PASS: native world map discover button, zone/dungeon/source navigation, viewed-map synchronization, off toggle")
