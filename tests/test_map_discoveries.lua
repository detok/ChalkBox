-- Discoveries 2.0.1: native dropdown selection, item search, sorting,
-- source-specific statistics, empty map behavior and movable map control.
_G.ChalkBoxZoneDB={}
-- A transparent global theme must never make the journal body disappear.
_G.ChalkBox_ThemeBackground=function() return 0.12,0.15,0.18,0 end
_G.ChalkBox_ThemeAccent=function() return 0.2,0.8,0.7 end
local frames={}
local fonts={}
local function Frame(kind,name,parent)
    local f={kind=kind,name=name,parent=parent,shown=false,text=""}
    function f:SetSize(w,h) self.w=w;self.h=h end
    function f:SetPoint(...) self.point={...} end
    function f:ClearAllPoints() self.point=nil end
    function f:SetFrameStrata(n) self.strata=n end
    function f:SetFrameLevel(n) self.level=n end
    function f:GetFrameLevel() return self.level or 12 end
    function f:SetToplevel(value) self.toplevel=value end
    function f:SetBackdrop(spec) self.backdrop=spec end
    function f:SetBackdropColor(...) self.backdropColor={...} end
    function f:SetBackdropBorderColor(...) self.backdropEdgeColor={...} end
    function f:SetMovable() self.movable=true end
    function f:SetClampedToScreen() end
    function f:EnableMouse() end
    function f:RegisterForDrag() end
    function f:RegisterForClicks() end
    function f:SetScript(key,fn) self[key]=fn end
    function f:HookScript(key,fn) self["Hook"..key]=fn end
    function f:RegisterEvent() end
    function f:SetText(value)
        self.text=value
        if self.kind=="EditBox" and self.OnTextChanged then
            self.OnTextChanged(self)
        end
    end
    function f:GetText() return self.text end
    function f:SetAutoFocus() end
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:IsShown() return self.shown end
    function f:GetLeft() return self.left or 100 end
    function f:GetTop() return self.top or 400 end
    function f:StartMoving()
        self.left=250;self.top=240
    end
    function f:StopMovingOrSizing() end
    function f:CreateTexture()
        local t={}
        function t:SetAllPoints() end
        function t:SetPoint() end
        function t:SetHeight() end
        function t:SetSize() end
        function t:SetColorTexture(...) self.color={...} end
        function t:SetVertexColor(...) self.color={...} end
        function t:SetTexture(value) self.texture=value end
        return t
    end
    function f:CreateFontString(_,layer,style)
        assert(layer=="OVERLAY" and type(style)=="string"
            and style:find("^GameFont"),
            "font templates must be actual Blizzard font styles, never label text")
        local fs={style=style,parent=self}
        function fs:SetPoint(_,_,_,x,y)
            assert(type(x)=="number" and type(y)=="number",
                "font x/y coordinates must be numeric")
            self.x,self.y=x,y
        end
        function fs:SetWidth(width)
            assert(type(width)=="number" and width>0,
                "font widths must be positive numbers")
            self.width=width
        end
        function fs:SetJustifyH() end
        function fs:SetText(value)
            assert(type(value)=="string")
            self.text=value
        end
        function fs:SetTextColor(r,g,b,a) self.color={r,g,b,a} end
        function fs:SetShadowColor() end
        function fs:SetShadowOffset() end
        fonts[#fonts+1]=fs
        return fs
    end
    frames[#frames+1]=f
    return f
end
_G.UIParent={}
_G.BackdropTemplateMixin={}
local viewed=1436
_G.WorldMapFrame=Frame("Frame","WorldMapFrame",UIParent)
WorldMapFrame:SetFrameLevel(45)
WorldMapFrame:SetFrameStrata("FULLSCREEN_DIALOG")
WorldMapFrame.GetMapID=function() return viewed end
_G.CreateFrame=Frame
_G.C_Map={
    GetBestMapForUnit=function() return 1436 end,
    GetMapInfo=function(id)
        return {name=({[1436]="Westfall",[1437]="Redridge Mountains"})[id]}
    end
}
_G.ChalkBox_DropOptions=function()
    return {mapButton=true,enabled=true,areas=3}
end
_G.ChalkBox_DropVisitedAreas=function(kind)
    if kind=="outdoor" then
        return {{key="z:1436",kind="outdoor",mapID=1436,name="Westfall",
            items=2,windows=12},
            {key="z:1437",kind="outdoor",mapID=1437,
                name="Redridge Mountains",items=1,windows=2}}
    end
    return {{key="d:36:1",kind="dungeon",name="The Deadmines",
        entranceZoneID=1436,items=1,windows=5}}
end
_G.ChalkBox_DropAreaInfo=function(key)
    local all={}
    for _,kind in ipairs({"outdoor","dungeon"}) do
        for _,v in ipairs(ChalkBox_DropVisitedAreas(kind)) do
            all[v.key]=v
        end
    end
    return all[key]
end
_G.ChalkBox_DropSources=function(key)
    if key=="z:1436" then
        return {{key="c:12345",name="Defias Bandit",windows=12}}
    end
    return {}
end
_G.ChalkBox_DropAreaItems=function(key,source,search)
    local list
    if key=="z:1436" then
        list=source and {{id="100",name="Linen Cloth",quantity=8,
            windows=4,attempts=12,rate=33.333}}
        or {{id="100",name="Linen Cloth",quantity=8,windows=4},
            {id="200",name="Bone",quantity=2,windows=2}}
    elseif key=="d:36:1" then list={{id="500",name="Dungeon Trinket",
        quantity=1,windows=1}}
    elseif key=="z:1437" then list={{id="300",name="Redridge Loot",
        quantity=3,windows=2}}
    else list={} end
    local result={}
    for _,item in ipairs(list) do
        if not search or search=="" or
            item.name:lower():find(search:lower(),1,true) or
            item.id:find(search,1,true) then
            result[#result+1]=item
        end
    end
    return result
end
_G.C_Item={GetItemIconByID=function(id) return 100000+id end}
local menuEntries={}
_G.MenuUtil={
    CreateContextMenu=function(owner,callback)
        menuEntries={}
        local root={
            CreateTitle=function(_,label)
                menuEntries[#menuEntries+1]={label=label,title=true}
            end,
            CreateButton=function(_,label,fn)
                menuEntries[#menuEntries+1]={label=label,action=fn}
            end
        }
        callback(owner,root)
    end
}
local function Find(name)
    for _,f in ipairs(frames) do if f.name==name then return f end end
end
local function ClickButton(pattern)
    for _,f in ipairs(frames) do
        if f.kind=="Button" and type(f.text)=="string" and
            f.text:find(pattern,1,true) and f.OnClick then
            f.OnClick(f,"LeftButton")
            return f
        end
    end
    error("Missing button containing "..pattern)
end
local function ChooseMenu(pattern)
    for _,v in ipairs(menuEntries) do
        if v.action and v.label:find(pattern,1,true) then
            v.action()
            return true
        end
    end
    error("Missing menu choice "..pattern)
end
assert(loadfile("MapDiscoveries.lua"))("ChalkBox")
local button=Find("ChalkBoxMapDiscoveriesButton")
assert(button and button.parent==WorldMapFrame and button.shown,
    "2.0 live-client map attach remains intact")
button.OnClick(button,"LeftButton")
local journal=Find("ChalkBoxMapDiscoveries")
assert(journal and journal:IsShown() and journal.w==660 and journal.h==616,
    "Discoveries journal opens at the expected size")
-- Previously this passed despite the real client aborting halfway through
-- construction: static heading text was incorrectly passed as a font style.
local headings={
    ["AREA / DUNGEON"]=true,["CREATURE SOURCE"]=true,
    ["SORT BY"]=true,["SEARCH ITEMS"]=true,ITEM=true,
    COLLECTED=true,APPEARED=true,["RATE*"]=true,
}
local foundHeadings={}
for _,fs in ipairs(fonts) do
    if headings[fs.text] then
        assert(fs.style=="GameFontNormal" and fs.color and
            fs.color[4]==1 and fs.width>0, "header must render readably")
        foundHeadings[fs.text]=true
    end
end
for label in pairs(headings) do
    assert(foundHeadings[label],"missing Discoveries heading: "..label)
end
assert(#fonts>=30,"full journal and its rows must finish constructing")
assert(journal.OnUpdate,"full journal must finish initialization")
assert(journal.strata=="FULLSCREEN_DIALOG" and journal.level>=200
    and journal.toplevel==true,
    "journal frame and all children must sit above the native map")
assert(journal.backdrop and journal.backdrop.bgFile and
    journal.backdrop.bgFile:find("DialogBox",1,true),
    "panel has a real Blizzard-native backdrop")
assert(journal.back and journal.back.texture==
    "Interface\\Buttons\\WHITE8X8",
    "panel paints a real texture, not only a color-only region")
assert(journal.back and journal.back.color and journal.back.color[4]>=0.92,
    "transparent global theme must not hide the Discoveries panel")
assert(journal.edge and journal.edge.color and journal.edge.color[4]>=0.8,
    "journal has a visible accent border")
assert(journal.back.color[1]==0.12 and journal.stripe.color[2]==0.8,
    "global theme colors still apply")
_G.ChalkBox_ThemeBackground=function() error("theme unavailable") end
ChalkBox_MapDiscoveriesThemeRefresh()
assert(journal.back.color[4]>=0.92,
    "a theme failure must not erase the existing journal background")
local filterCount=0
for _,f in ipairs(frames) do
    if f.kind=="Button" and f.parent==journal and f.text and
        f.text:find("▾",1,true) then filterCount=filterCount+1 end
end
assert(filterCount==3,"visible Area/Source/Sort dropdown selectors")
assert(#ChalkBox_DiscoveriesDropdownItems("area")>=3)
assert(#ChalkBox_DiscoveriesDropdownItems("source")>=3)
assert(#ChalkBox_DiscoveriesDropdownItems("sort")==5)
ClickButton("Westfall")
ChooseMenu("Redridge Mountains")
assert(#ChalkBox_DiscoveriesDropdownItems("source")==2,
    "area switching works and clears unrelated creature filters")
ClickButton("Redridge Mountains")
ChooseMenu("Westfall")
ClickButton("All sources")
ChooseMenu("Defias Bandit")
local selected=ChalkBox_DiscoveriesDropdownItems("source")
assert(selected[3].text:find("Defias Bandit",1,true),
    "known-creature source can be selected in a genuine menu")
ClickButton("Quantity")
ChooseMenu("Item name")
local inputs={}
for _,f in ipairs(frames) do
    if f.kind=="EditBox" and f.parent==journal then
        inputs[#inputs+1]=f
    end
end
assert(#inputs==1)
inputs[1]:SetText("Linen")
ClickButton("Clear")
ClickButton("Dungeons")
assert(#ChalkBox_DiscoveriesDropdownItems("area")>=2)
ClickButton("The Deadmines")
ChooseMenu("The Deadmines")
viewed=1437
journal.OnUpdate(journal,0.8)
assert(journal:IsShown(),
    "map changing does not close the standalone browser")
ClickButton("Use map zone")
ClickButton("Outdoor")
-- Position persistence per character.
assert(button.OnDragStart and button.OnDragStop)
button.OnDragStart(button)
button.OnDragStop(button)
local saved=ChalkBox_MapDiscoveriesButtonPosition()
assert(saved.custom and saved.x==150 and saved.y==-160,
    "button drag is saved relative to map container")
ChalkBox_MapDiscoveriesEnsure()
assert(button.point[4]==150 and button.point[5]==-160,
    "map reopening keeps the user's chosen position")
assert(ChalkBox_MapDiscoveriesResetButton())
assert(not ChalkBox_MapDiscoveriesButtonPosition().custom and
    button.point[4]==18 and button.point[5]==-114,
    "reset puts button back on default map position")
print("PASS: Discoveries readable layout, native dropdowns, source/zone/dungeon filtering, live search, sort, persisted button drag and reset")
