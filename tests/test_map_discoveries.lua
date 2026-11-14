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
    function f:Hide()
        self.shown=false
        if self.OnHide then self.OnHide(self) end
    end
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
local manyZones=false
_G.ChalkBox_DropVisitedAreas=function(kind)
    if kind=="outdoor" then
        local list={{key="z:1436",kind="outdoor",mapID=1436,name="Westfall",
            items=2,windows=12},
            {key="z:1437",kind="outdoor",mapID=1437,
                name="Redridge Mountains",items=1,windows=2}}
        if manyZones then
            for i=1,14 do
                list[#list+1]={key="z:"..(2000+i),kind="outdoor",
                    mapID=2000+i,name=("Sample Zone %02d"):format(i),
                    items=i,windows=i*2}
            end
        end
        return list
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
            windows=4,hits=4,attempts=12,rate=33.333,
            sourceName="Defias Bandit"}}
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
local function MenuRoot(entries)
    return {
        CreateTitle=function(_,label)
            entries[#entries+1]={label=label,title=true}
        end,
        CreateButton=function(_,label,fn)
            local item={label=label,action=fn,children={}}
            entries[#entries+1]=item
            return MenuRoot(item.children)
        end,
    }
end
_G.MenuUtil={
    CreateContextMenu=function(owner,callback)
        menuEntries={}
        callback(owner,MenuRoot(menuEntries))
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
local function FindMenu(entries,pattern)
    for _,v in ipairs(entries) do
        if v.label:find(pattern,1,true) then return v end
        if v.children then
            local found=FindMenu(v.children,pattern)
            if found then return found end
        end
    end
end
local function ChooseMenu(pattern)
    local entry=FindMenu(menuEntries,pattern)
    if entry and entry.action then entry.action();return true end
    error("Missing menu choice "..pattern)
end
local function OpenArea()
    local button=ClickButton("▾")
    local popup=Find("ChalkBoxDiscoveriesAreaPicker")
    assert(popup and popup:IsShown(),"area field must open a visible dropdown")
    assert(popup.parent==UIParent and popup.strata=="TOOLTIP" and
        popup.level>=1000 and popup.toplevel,
        "zone picker must be an independent top-level clickable overlay")
    assert(popup.point and popup.point[1]=="TOPLEFT" and
        popup.point[3]=="BOTTOMLEFT",
        "overlay remains anchored beneath the existing Area field")
    return popup
end
local function SelectArea(text)
    local popup=Find("ChalkBoxDiscoveriesAreaPicker")
    assert(popup and popup:IsShown(),"open area dropdown before selecting")
    local pages=tonumber((popup.pageLabel.text or ""):match("/ (%d+)")) or 1
    for pageIndex=1,pages do
        for _,row in ipairs(popup.rows) do
            if row.shown and row.label.text and
                row.label.text:find(text,1,true) and row.OnClick then
                row.OnClick(row,"LeftButton")
                assert(not popup:IsShown(),"zone selection closes the dropdown")
                return true
            end
        end
        popup.next.OnClick(popup.next,"LeftButton")
    end
    error("Missing direct area option: "..text)
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
    FOUND=true,DROPS=true,["RATE*"]=true,
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
local areaMenu=ChalkBox_DiscoveriesDropdownItems("area")
assert(#areaMenu==6 and areaMenu[1].text:find("Follow world map",1,true),
    "area dropdown includes map sync and every recorded location directly")
assert(areaMenu[2].text:find("OUTDOOR ZONES (2)",1,true) and
    areaMenu[5].text:find("DUNGEONS (1)",1,true),
    "zones and dungeons have readable section headings")
assert(areaMenu[3].text:find("Redridge",1,true) and
    areaMenu[4].text:find("Westfall",1,true) and
    areaMenu[6].text:find("Deadmines",1,true),
    "all recorded locations can be selected without nested submenus")
assert(ChalkBox_DiscoveriesBrowserStatus().followMap,
    "fresh characters continue following the current world map")
assert(ChalkBoxZoneDB.mapDiscoveryUI.followMap==nil,
    "opening the journal does not mutate original follow-map defaults")
assert(#ChalkBox_DiscoveriesDropdownItems("source")>=3)
assert(#ChalkBox_DiscoveriesDropdownItems("sort")==5)
OpenArea()
SelectArea("Redridge Mountains")
local browser=ChalkBox_DiscoveriesBrowserStatus()
assert(not browser.followMap and browser.mode=="outdoor"
    and browser.selectedArea=="z:1437",
    "choosing a recorded zone turns map following off without moving Blizzard's map")
assert(viewed==1436 and ChalkBoxZoneDB.mapDiscoveryUI.browseArea=="z:1437"
    and ChalkBoxZoneDB.mapDiscoveryUI.followMap==false,
    "manual location is saved per character while the native world map stays put")
assert(#ChalkBox_DiscoveriesDropdownItems("source")==2,
    "area switching works and clears unrelated creature filters")
viewed=1436
journal.OnUpdate(journal,0.8)
assert(ChalkBox_DiscoveriesBrowserStatus().selectedArea=="z:1437",
    "browsing a remote zone survives map movement and updates")
OpenArea()
assert(Find("ChalkBoxDiscoveriesAreaPicker").shown,
    "list stays clickable while the journal is open")
journal:Hide()
assert(not Find("ChalkBoxDiscoveriesAreaPicker").shown,
    "hiding the journal closes its separate top-level popup")
assert(ChalkBox_OpenMapDiscoveries())
assert(ChalkBox_DiscoveriesBrowserStatus().selectedArea=="z:1437",
    "manual browse choice survives closing and reopening")
OpenArea()
SelectArea("Westfall")
ClickButton("All creatures")
ChooseMenu("Defias Bandit")
local selected=ChalkBox_DiscoveriesDropdownItems("source")
assert(selected[3].text:find("Defias Bandit",1,true),
    "known-creature source can be selected in a genuine menu")
local sawDropRate,sawDrops,sawSourceStats=false,false,false
for _,font in ipairs(fonts) do
    if font.text=="DROPS" then sawDrops=true end
    if font.text=="33.3%" then sawDropRate=true end
    if font.text and font.text:find("4 drops / 12 loots",1,true) then
        sawSourceStats=true
    end
end
assert(sawDrops and sawDropRate and sawSourceStats,
    "source-filtered items show drops, looted attempts and an observed percentage")
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
-- Choose a dungeon directly from the same area dropdown without switching tabs.
OpenArea()
SelectArea("The Deadmines")
browser=ChalkBox_DiscoveriesBrowserStatus()
assert(browser.mode=="dungeon" and browser.selectedArea=="d:36:1"
    and not browser.followMap,
    "cross-category selection automatically selects Dungeons")
assert(ChalkBoxZoneDB.mapDiscoveryUI.browseArea=="d:36:1" and
    ChalkBoxZoneDB.mapDiscoveryUI.browseMode=="dungeon",
    "dungeon selection is persisted independently from map following")
viewed=1437
journal.OnUpdate(journal,0.8)
assert(journal:IsShown() and
    ChalkBox_DiscoveriesBrowserStatus().selectedArea=="d:36:1",
    "manual dungeon browsing is independent of map changes")
-- Both existing top-right button and dropdown control the same sync state.
ClickButton("Map sync: OFF")
browser=ChalkBox_DiscoveriesBrowserStatus()
assert(browser.followMap and browser.mode=="outdoor" and
    browser.selectedArea=="z:1437",
    "map sync immediately returns to the zone on Blizzard's map")
assert(ChalkBoxZoneDB.mapDiscoveryUI.browseArea=="d:36:1",
    "syncing does not destroy last deliberately browsed location")
OpenArea()
SelectArea("Follow world map")
assert(ChalkBox_DiscoveriesBrowserStatus().followMap,
    "the area dropdown can explicitly enable following the world map")
viewed=1436
journal.OnUpdate(journal,0.8)
assert(ChalkBox_DiscoveriesBrowserStatus().selectedArea=="z:1436",
    "following updates the selected zone when the map changes")
ClickButton("Map sync: ON")
browser=ChalkBox_DiscoveriesBrowserStatus()
assert(not browser.followMap and browser.mode=="dungeon" and
    browser.selectedArea=="d:36:1",
    "switching sync off restores the last manually browsed location")
-- Switching to the Outdoor tab still works without replacing the main layout.
ClickButton("Dungeons")
ClickButton("Outdoor")
-- The area list is a real dropdown and must not depend on whether
-- Forever ships either of its native transient menu APIs.
local modernMenu=MenuUtil
_G.MenuUtil=nil
_G.EasyMenu=nil
local direct=OpenArea()
assert(direct.rows[1].label.text:find("Follow world map",1,true) and
    direct.rows[3].label.text:find("Redridge",1,true) and
    direct.rows[4].label.text:find("Westfall",1,true),
    "actual visible rows expose zone names immediately")
SelectArea("Westfall")
_G.MenuUtil=modernMenu
-- Many known zones need more than nine visible rows. A paginated
-- picker still lets the player choose any saved zone directly.
manyZones=true
local popup=OpenArea()
assert(popup.pageLabel.text=="Page 1 / 3",
    "large observed zone libraries have a visible page indicator")
popup.OnMouseWheel(popup,-1)
assert(popup.pageLabel.text=="Page 2 / 3",
    "mouse wheel scrolls the zone selection")
popup.OnMouseWheel(popup,1)
assert(popup.pageLabel.text=="Page 1 / 3",
    "mouse wheel can move backward")
popup.next.OnClick(popup.next,"LeftButton")
SelectArea("Sample Zone 14")
assert(ChalkBox_DiscoveriesBrowserStatus().selectedArea=="z:2014",
    "a later-page location is actually selectable")
manyZones=false
OpenArea()
SelectArea("Westfall")
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
-- Player's manual selection survives not only reopening but a new addon
-- instance (the same persisted per-character SavedVariables after relog).
OpenArea()
SelectArea("Redridge Mountains")
local savedBrowse=ChalkBoxZoneDB.mapDiscoveryUI
assert(savedBrowse.followMap==false and savedBrowse.browseArea=="z:1437")
assert(loadfile("MapDiscoveries.lua"))("ChalkBox")
assert(ChalkBox_OpenMapDiscoveries())
local restored=ChalkBox_DiscoveriesBrowserStatus()
assert(not restored.followMap and restored.mode=="outdoor" and
    restored.selectedArea=="z:1437",
    "fresh browser instance restores the per-character manual zone")
print("PASS: Discoveries direct zone picker, real visible rows without native menu APIs, source filter, paging, sync, saved selection and map button")
