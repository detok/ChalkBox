-- ChalkBox Discoveries browser. WoW Forever's native WorldMapFrame is
-- preserved. Discoveries is a map-owned side panel; its optional map
-- button retains its existing user-selected position. Never move the map.
-- No HTTP requests, map texture replacements or fabricated drop probabilities.
local mapButton,panel,loader
local currentMap=nil
local mode="outdoor"
local selectedArea=nil
local followMap=true
local browseArea,browseMode=nil,"outdoor"
local browserStateLoaded=false
local selectedSource=nil
local sortKey="quantity"
local searchText=""
local page=1
local rows={}
local controls={}
local lastMap,elapsed=nil,0
local attachedTo,retries=nil,0
local PANEL_W,PANEL_H=488,616
local dockSide="unpositioned"
local PER_PAGE=7
-- The very same backdrop atlas Blizzard uses in Forever's World Map
-- (Blizzard_WorldMap.xml). Artwork stays confined to this side panel.
local MAP_TILE_ATLAS="gamepad-mapquestlog-bgtile-2k"

local function Public(v)
    return v~=nil and (type(issecretvalue)~="function" or not issecretvalue(v))
end
local function Call(fn,...)
    if type(fn)~="function" then return end
    local ok,value=pcall(fn,...)
    if ok and Public(value) then return value end
end
local function Store()
    if type(ChalkBoxZoneDB)~="table" then ChalkBoxZoneDB={} end
    local saved=ChalkBoxZoneDB.mapDiscoveryUI
    if type(saved)~="table" then
        saved={};ChalkBoxZoneDB.mapDiscoveryUI=saved
    end
    return saved
end
-- Browser preferences are per character, separate from button positioning.
-- Older saves have no browser fields and keep the original follow-map default.
local function RestoreBrowser()
    if browserStateLoaded then return end
    browserStateLoaded=true
    local saved=Store()
    followMap=saved.followMap~=false
    if saved.viewMode=="dungeon" then mode="dungeon" end
    if saved.browseMode=="dungeon" then browseMode="dungeon" end
    if type(saved.browseArea)=="string" and #saved.browseArea<128 then
        browseArea=saved.browseArea
    end
    if not followMap then
        mode=browseMode
        selectedArea=browseArea
    end
end
local function SaveBrowser()
    local saved=Store()
    saved.followMap=followMap
    saved.viewMode=mode
    if not followMap then
        browseArea=selectedArea
        browseMode=mode
        saved.browseArea=browseArea
        saved.browseMode=browseMode
    end
end
local function ValidOffset(v)
    return type(v)=="number" and v==v and v>-5000 and v<5000 and
        (type(issecretvalue)~="function" or not issecretvalue(v))
end
local function ValidColor(value)
    return Public(value) and type(value)=="number" and value==value
        and value>=0 and value<=1
end
local function Colors()
    local r,g,b,a=0.018,0.018,0.022,0.97
    if type(ChalkBox_ThemeBackground)=="function" then
        local ok,red,green,blue,alpha=pcall(ChalkBox_ThemeBackground,0.97)
        if ok and ValidColor(red) and ValidColor(green)
            and ValidColor(blue) and ValidColor(alpha) then
            r,g,b,a=red,green,blue,alpha
        end
    end
    -- Discoveries is a reading surface, not an overlay. A global theme
    -- opacity of zero must not erase the window behind its controls.
    return r,g,b,math.max(0.92,a)
end
local function Accent()
    if type(ChalkBox_ThemeAccent)=="function" then
        local ok,r,g,b=pcall(ChalkBox_ThemeAccent)
        if ok and ValidColor(r) and ValidColor(g) and ValidColor(b) then
            return r,g,b
        end
    end
    return 0.86,0.66,0.38
end
-- Use a real texture as well as a backdrop. On some Forever builds
-- SetColorTexture-only regions can fail to paint behind native map panes.
local function Paint(texture,r,g,b,a)
    if not texture then return end
    if type(texture.SetTexture)=="function" and
        type(texture.SetVertexColor)=="function" then
        texture:SetTexture("Interface\\Buttons\\WHITE8X8")
        texture:SetVertexColor(r,g,b,a)
    elseif type(texture.SetColorTexture)=="function" then
        texture:SetColorTexture(r,g,b,a)
    end
end
local function Tint()
    if not panel then return end
    local r,g,b,a=Colors()
    local ar,ag,ab=Accent()
    -- Keep the map's parchment/tiled background visible beneath a dark
    -- glaze so the existing light-on-dark controls stay easy to read.
    -- If a Forever build lacks the atlas, retain the original opaque body.
    -- Parchment should be clearly visible, not buried under a near-opaque
    -- charcoal texture. Row strips still provide local text contrast.
    -- Warm the existing dark-wood atlas to complement the native map's
    -- parchment. Keep item rows neutral blue-gray for scan readability.
    local woodR=0.16+r*0.20
    local woodG=0.092+g*0.12
    local woodB=0.048+b*0.06
    Paint(panel.back,panel.hasMapArt and woodR or r,
        panel.hasMapArt and woodG or g,
        panel.hasMapArt and woodB or b,
        panel.hasMapArt and 0.30 or a)
    Paint(panel.edge,ar,ag,ab,0.82)
    Paint(panel.stripe,ar,ag,ab,1)
    if type(panel.SetBackdropColor)=="function" then
        -- This undercoat is below the map tile; the visible inner glaze
        -- is handled separately by panel.back.
        panel:SetBackdropColor(panel.hasMapArt and woodR or r,
            panel.hasMapArt and woodG or g,
            panel.hasMapArt and woodB or b,
            panel.hasMapArt and 0.12 or a)
    end
    if type(panel.SetBackdropBorderColor)=="function" then
        panel:SetBackdropBorderColor(ar,ag,ab,1)
    end
    for i,row in ipairs(rows) do
        if row.back then
            row.back:SetColorTexture(
                math.min(1,r*2+0.040),
                math.min(1,g*2+0.044),
                math.min(1,b*2+0.046),
                i%2==0 and 0.54 or 0.74)
        end
    end
end
function ChalkBox_MapDiscoveriesThemeRefresh() Tint() end
local function MapID()
    local world=WorldMapFrame
    local id
    if world and type(world.GetMapID)=="function" then
        id=Call(world.GetMapID,world)
    end
    if (not id or type(id)~="number") and world and
        world.ScrollContainer and
        type(world.ScrollContainer.GetMapID)=="function" then
        id=Call(world.ScrollContainer.GetMapID,world.ScrollContainer)
    end
    if (not id or type(id)~="number") and C_Map then
        id=Call(C_Map.GetBestMapForUnit,"player")
    end
    if type(id)=="number" and id>0 then return id end
end
-- DropSense stores outdoor loot under the first parent UI zone (type 3).
-- Follow the same zone when the visible map is a smaller subzone/micro view.
-- Drawing on a different map still requires an actual client coordinate
-- transformation; never reinterpret saved zone coordinates directly.
local function ZoneMapID(id)
    local origin,seen=id,{}
    for _=1,12 do
        if type(id)~="number" or id<=0 or id%1~=0 or seen[id] then
            break
        end
        seen[id]=true
        local info=Call(C_Map and C_Map.GetMapInfo,id)
        if type(info)~="table" then break end
        if Public(info.mapType) and info.mapType==3 then return id end
        if Public(info.mapType) and type(info.mapType)=="number"
            and info.mapType<3 then break end
        local parent=Public(info.parentMapID) and info.parentMapID or nil
        if type(parent)~="number" or parent<=0 then break end
        id=parent
    end
    return origin
end
-- One transient loot-position pulse on Blizzard's *existing* map canvas.
-- Never move the map, call AddPin, store an extra map marker, or infer a
-- corpse/creature spawn from where a loot window happened to open.
local lootPulse,hoverSpot
local function PulseClear()
    hoverSpot=nil
    if type(ChalkBox_MapNativeLootClear)=="function" then
        ChalkBox_MapNativeLootClear()
    end
    if lootPulse and type(lootPulse.Hide)=="function" then
        lootPulse:Hide()
    end
end
local function PulseCanvas()
    local scroll=WorldMapFrame and WorldMapFrame.ScrollContainer
    if not scroll then return end
    local canvas=scroll.Child
    if not canvas and type(scroll.GetCanvas)=="function" then
        canvas=Call(scroll.GetCanvas,scroll)
    end
    if canvas and type(canvas.GetWidth)=="function" and
        type(canvas.GetHeight)=="function" and
        type(canvas.CreateTexture)=="function" then return canvas end
end
local function PulsePosition()
    if not lootPulse or not hoverSpot or
        not panel or (type(panel.IsShown)=="function" and
        not panel:IsShown()) or mode~="outdoor" then return false end
    local viewed=MapID()
    if selectedArea~="z:"..tostring(ZoneMapID(viewed) or "") then
        return false
    end
    local source=tonumber(selectedArea:match("^z:(%d+)$"))
    local x,y=hoverSpot.x/1000,hoverSpot.y/1000
    if source~=viewed then
        -- Fallback must apply the same parent-zone -> subzone coordinate
        -- conversion as the native renderer. Never paint parent coordinates
        -- directly on a different child map.
        if type(ChalkBox_MapNativeProject)~="function" then return false end
        x,y=ChalkBox_MapNativeProject(source,viewed,x,y)
        if not x then return false end
    end
    local canvas=PulseCanvas()
    if canvas~=lootPulse.canvas then return false end
    local w,h=Call(canvas.GetWidth,canvas),Call(canvas.GetHeight,canvas)
    if not ValidOffset(w) or not ValidOffset(h) or w<=0 or h<=0 then
        return false
    end
    lootPulse:ClearAllPoints()
    lootPulse:SetPoint("CENTER",canvas,"TOPLEFT",x*w,-y*h)
    return true
end
local function PulseHover(item)
    PulseClear()
    if mode~="outdoor" or type(item)~="table"
        or type(item.locations)~="table" or #item.locations<1
        or selectedArea~="z:"..tostring(ZoneMapID(MapID()) or "") then return end
    -- Recent observation only. Does not imply this is the mob's spawn.
    local spot=item.locations[#item.locations]
    if type(spot)~="table" or not ValidOffset(spot.x)
        or not ValidOffset(spot.y) or spot.x<0 or spot.x>1000
        or spot.y<0 or spot.y>1000 then return end
    -- Preferred path: the built-in MapCanvas pin system positions and
    -- draws the dot during local zoom, panning and map changes. It also
    -- projects a parent-zone sample onto a subzone only when Forever
    -- supplies a valid rectangle and the sample lies inside it.
    local sourceMap=tonumber(selectedArea:match("^z:(%d+)$"))
    if sourceMap and type(ChalkBox_MapNativeAvailable)=="function"
        and ChalkBox_MapNativeAvailable() and
        type(ChalkBox_MapNativeLootSet)=="function" then
        if ChalkBox_MapNativeLootSet(sourceMap,
            spot.x/1000,spot.y/1000) then return end
    end
    local canvas=PulseCanvas()
    if not canvas then return end
    if not lootPulse or lootPulse.canvas~=canvas then
        local dot=CreateFrame("Frame",nil,canvas)
        dot.canvas=canvas
        dot:SetSize(18,18)
        if type(dot.EnableMouse)=="function" then dot:EnableMouse(false) end
        if type(dot.SetFrameLevel)=="function" and
            type(canvas.GetFrameLevel)=="function" then
            dot:SetFrameLevel(math.max(200,canvas:GetFrameLevel()+60))
        end
        local ring=dot:CreateTexture(nil,"OVERLAY")
        ring:SetAllPoints(dot)
        Paint(ring,1,0.70,0.27,0.70)
        local center=dot:CreateTexture(nil,"OVERLAY")
        center:SetSize(6,6)
        center:SetPoint("CENTER",dot,"CENTER",0,0)
        Paint(center,1,0.96,0.74,1)
        dot.ring=ring;dot.clock=0
        dot:SetScript("OnUpdate",function(self,dt)
            if type(dt)~="number" or dt<0 then return end
            self.clock=(self.clock+dt)%1.3
            if self.ring and type(self.ring.SetAlpha)=="function" then
                self.ring:SetAlpha(0.24+0.64*math.abs(
                    math.sin(self.clock/1.3*math.pi)))
            end
            if not PulsePosition() then PulseClear() end
        end)
        lootPulse=dot
    end
    hoverSpot={x=spot.x,y=spot.y}
    if PulsePosition() then lootPulse:Show()
    else PulseClear() end
end
local function MapName(id)
    local info=Call(C_Map and C_Map.GetMapInfo,id)
    if type(info)=="table" and Public(info.name) and
        type(info.name)=="string" then
        return info.name
    end
    return id and ("Map "..tostring(id)) or "Unknown map"
end
local function Watch()
    local opts=type(ChalkBox_DropOptions)=="function" and
        ChalkBox_DropOptions() or nil
    return opts and opts.mapButton~=false
end
local function Font(parent,style,x,y,width)
    local f=parent:CreateFontString(nil,"OVERLAY",style)
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    f:SetWidth(width)
    if type(f.SetJustifyH)=="function" then f:SetJustifyH("LEFT") end
    -- Explicit contrast is required across Forever UI themes.
    if type(f.SetTextColor)=="function" then
        if style=="GameFontNormalHuge" or style=="GameFontNormal" then
            f:SetTextColor(1.0,0.87,0.55,1)
        elseif style=="GameFontHighlightSmall" then
            f:SetTextColor(0.87,0.90,0.94,1)
        else
            f:SetTextColor(0.97,0.97,0.97,1)
        end
    end
    if type(f.SetShadowColor)=="function" then
        f:SetShadowColor(0,0,0,0.9)
    end
    if type(f.SetShadowOffset)=="function" then
        f:SetShadowOffset(1,-1)
    end
    return f
end
-- A heading includes text; Font() only accepts a style and coordinates.
-- Passing text into Font() as the style used to abort panel construction
-- halfway through, leaving Close/Outdoor/Dungeons floating on screen.
local function Heading(parent,label,style,x,y,width)
    local f=Font(parent,style,x,y,width)
    f:SetText(label)
    return f
end
local function Button(parent,label,width,x,y,fn)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(width,24)
    b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    b:SetText(label)
    b:SetScript("OnClick",fn)
    return b
end
local function Areas(kind)
    if type(ChalkBox_DropVisitedAreas)=="function" then
        return ChalkBox_DropVisitedAreas(kind) or {}
    end
    -- Older clients running mixed files should still open the journal.
    local fallback={}
    local id=MapID()
    if kind=="outdoor" and id and
        type(ChalkBox_DropArea)=="function" and ChalkBox_DropArea(id) then
        fallback[1]={key="z:"..id,name=MapName(id),mapID=id}
    elseif kind=="dungeon" and id and
        type(ChalkBox_DropMapData)=="function" then
        local data=ChalkBox_DropMapData(id)
        for _,v in ipairs(data and data.dungeons or {}) do
            fallback[#fallback+1]={key=v.key,name=v.name}
        end
    end
    return fallback
end
local function DefaultArea()
    if mode=="outdoor" then
        local zone=currentMap and ZoneMapID(currentMap)
        local key=zone and ("z:"..zone) or nil
        -- Following the viewed map must NEVER show the first unrelated zone.
        if followMap and key then return key end
        if key and type(ChalkBox_DropAreaInfo)=="function" and
            ChalkBox_DropAreaInfo(key) then return key end
        local items=Areas("outdoor")
        return items[1] and items[1].key or nil
    end
    local list=Areas("dungeon")
    for _,entry in ipairs(list) do
        if currentMap and
            (entry.entranceZoneID==currentMap or entry.mapID==currentMap) then
            return entry.key
        end
    end
    if followMap then return nil end
    return list[1] and list[1].key or nil
end
local function EnsureSelection()
    local list=Areas(mode)
    local found=false
    for _,v in ipairs(list) do
        if v.key==selectedArea then found=true;break end
    end
    if not found then
        if not (followMap and mode=="outdoor" and currentMap and
            selectedArea=="z:"..ZoneMapID(currentMap)) then
            selectedArea=DefaultArea();selectedSource=nil;page=1
        end
    end
    return list
end
local function Sources()
    if not selectedArea or type(ChalkBox_DropSources)~="function" then
        return {}
    end
    return ChalkBox_DropSources(selectedArea) or {}
end
local function Items()
    if not selectedArea or type(ChalkBox_DropAreaItems)~="function" then
        return {}
    end
    local items=ChalkBox_DropAreaItems(selectedArea,selectedSource,searchText)
        or {}
    table.sort(items,function(a,b)
        if sortKey=="name" then
            if a.name==b.name then return a.id<b.id end
            return a.name<b.name
        elseif sortKey=="appearances" then
            if a.windows==b.windows then return a.name<b.name end
            return a.windows>b.windows
        elseif sortKey=="rate" then
            local ar,br=a.rate or -1,b.rate or -1
            if ar==br then return a.name<b.name end
            return ar>br
        end
        if a.quantity==b.quantity then return a.name<b.name end
        return a.quantity>b.quantity
    end)
    return items
end
-- Source and sort use Blizzard menus. Areas use a dedicated, scrollable
-- dropdown because Forever can silently fail to open nested menus.
local menuFrame
local menuColors={
    title="ffffd36a",group="ff79d4e9",selected="ff79df9c",
    normal="ffe4e9ef",muted="ff9ca7b5",
}
local function MenuLabel(entry)
    return "|c"..(menuColors[entry.tone] or menuColors.normal)..
        entry.text.."|r"
end
local function NativeChoices(root,choices)
    for _,entry in ipairs(choices) do
        local text=MenuLabel(entry)
        if entry.children then
            if type(root.CreateButton)=="function" then
                local submenu=root:CreateButton(text)
                if submenu and type(submenu.CreateButton)=="function" then
                    NativeChoices(submenu,entry.children)
                end
            end
        elseif entry.title then
            if type(root.CreateTitle)=="function" then
                root:CreateTitle(text)
            end
        elseif entry.action and type(root.CreateButton)=="function" then
            root:CreateButton(text,function() entry.action() end)
        end
    end
end
local function LegacyChoices(choices)
    local list={}
    for _,entry in ipairs(choices) do
        local item={text=MenuLabel(entry),notCheckable=true}
        if entry.children then
            item.hasArrow=true
            item.menuList=LegacyChoices(entry.children)
        elseif entry.title then
            item.isTitle=true
        else
            item.func=entry.action
        end
        list[#list+1]=item
    end
    return list
end
local function ShowMenu(owner,choices)
    if type(InCombatLockdown)=="function" and InCombatLockdown() then
        return false
    end
    if type(MenuUtil)=="table" and
        type(MenuUtil.CreateContextMenu)=="function" then
        local ok=pcall(MenuUtil.CreateContextMenu,owner,
            function(_,root) NativeChoices(root,choices) end)
        if ok then return true end
    end
    if type(EasyMenu)=="function" then
        if not menuFrame then
            menuFrame=CreateFrame("Frame",
                "ChalkBoxDiscoveriesDropdown",UIParent,"UIDropDownMenuTemplate")
        end
        local ok=pcall(EasyMenu,LegacyChoices(choices),menuFrame,
            owner,0,-4,"MENU")
        if ok then return true end
    end
    return false
end
local function Pick(index,options)
    if #options==0 then return end
    local candidate=options[index]
    if candidate and candidate.action then candidate.action() end
end
local refresh
local function FollowWorldMap()
    followMap=true
    mode="outdoor"
    currentMap=MapID() or currentMap
    selectedArea=DefaultArea()
    selectedSource=nil
    page=1
    SaveBrowser()
    refresh()
end
local function BrowseLocation(entry)
    if type(entry)~="table" or type(entry.key)~="string" then return end
    followMap=false
    mode=entry.kind=="dungeon" and "dungeon" or "outdoor"
    selectedArea=entry.key
    selectedSource=nil
    page=1
    SaveBrowser()
    refresh()
end
local function AreaOptions()
    local list={{
        text=(followMap and "✓ " or "").."Follow world map",
        tone=followMap and "selected" or "normal",action=FollowWorldMap
    }}
    local total=0
    for _,category in ipairs({
        {kind="outdoor",name="OUTDOOR ZONES"},
        {kind="dungeon",name="DUNGEONS"},
    }) do
        local entries=Areas(category.kind)
        table.sort(entries,function(a,b)
            local an=string.lower(tostring(a.name or a.key))
            local bn=string.lower(tostring(b.name or b.key))
            if an==bn then return tostring(a.key)<tostring(b.key) end
            return an<bn
        end)
        if #entries>0 then
            list[#list+1]={text=category.name.." ("..#entries..")",
                title=true,tone="title"}
            for _,entry in ipairs(entries) do
                local item=entry
                local selected=not followMap and selectedArea==entry.key
                list[#list+1]={
                    text=(selected and "✓ " or "")..
                        tostring(entry.name or entry.key)..
                        "  ·  "..tostring(entry.items or 0).." items",
                    tone=selected and "selected" or "normal",
                    action=function() BrowseLocation(item) end,
                    areaKey=entry.key,
                }
                total=total+1
            end
        end
    end
    if total==0 then
        list[#list+1]={text="No recorded zones yet",
            title=true,tone="muted"}
    end
    return list
end
local function SourceOptions()
    local list={
        {text="CREATURE",title=true,tone="title"},
        {text=(not selectedSource and "✓ " or "").."All creatures",
            action=function() selectedSource=nil;page=1;refresh() end}
    }
    local sources=Sources()
    for _,entry in ipairs(sources) do
        local item=entry
        list[#list+1]={text=(selectedSource==item.key and "✓ " or "")..
            item.name.." · "..tostring(item.windows).." loots",
            action=function()
                selectedSource=item.key;page=1;refresh()
            end}
    end
    if #sources==0 then
        list[#list+1]={text="No identified creatures in this area",
            title=true,tone="muted"}
    end
    return list
end
local sorting={
    {key="quantity",name="Quantity"},
    {key="appearances",name="Appearances"},
    {key="name",name="Item name"},
    {key="rate",name="Drop rate"},
}
local function SortOptions()
    local list={{text="SORT ITEMS",title=true}}
    for _,entry in ipairs(sorting) do
        local item=entry
        list[#list+1]={text=(sortKey==item.key and "✓ " or "")..
            item.name,action=function() sortKey=item.key;page=1;refresh() end}
    end
    return list
end
function ChalkBox_DiscoveriesDropdownItems(kind)
    if kind=="area" then return AreaOptions()
    elseif kind=="source" then return SourceOptions()
    elseif kind=="sort" then return SortOptions() end
    return {}
end
-- Unlike Forever's transient context menus, this picker is a full frame.
-- It is visible immediately beneath the Area button, supports mouse wheel
-- and paging, and puts every recorded zone one click away.
local areaPopup
local AREA_VISIBLE_ROWS=9
local AREA_ROW_HEIGHT=26
local function CloseAreaPopup()
    if areaPopup and areaPopup.Hide then areaPopup:Hide() end
end
local function AreaPopupPage(delta)
    if not areaPopup then return end
    local options=AreaOptions()
    local totalPages=math.max(1,math.ceil(#options/AREA_VISIBLE_ROWS))
    areaPopup.page=math.max(1,math.min(totalPages,(areaPopup.page or 1)+delta))
    -- Repaint just the visible row controls; no saved state changes.
    local startIndex=((areaPopup.page or 1)-1)*AREA_VISIBLE_ROWS
    for i,button in ipairs(areaPopup.rows) do
        local entry=options[startIndex+i]
        button.areaEntry=entry
        if entry then
            local text=tostring(entry.text or "")
            if #text>47 then text=text:sub(1,44).."..." end
            button.label:SetText(text)
            local r,g,b=0.88,0.91,0.95
            if entry.tone=="selected" then r,g,b=0.43,0.93,0.61
            elseif entry.title then r,g,b=1,0.83,0.40
            elseif entry.tone=="muted" then r,g,b=0.59,0.64,0.72 end
            button.label:SetTextColor(r,g,b,1)
            if button.back and button.back.SetColorTexture then
                button.back:SetColorTexture(
                    entry.title and 0.12 or 0.08,
                    entry.title and 0.16 or 0.10,
                    entry.title and 0.19 or 0.13,0.95)
            end
            button:SetScript("OnClick",entry.action and function()
                entry.action()
                CloseAreaPopup()
            end or nil)
            button:Show()
        else
            button:SetScript("OnClick",nil)
            button:Hide()
        end
    end
    areaPopup.pageLabel:SetText(
        ("Page %d / %d"):format(areaPopup.page,totalPages))
    areaPopup.previous:SetText(areaPopup.page>1 and "◀ Previous" or "◀")
    areaPopup.next:SetText(areaPopup.page<totalPages and "Next ▶" or "▶")
end
local function EnsureAreaPopup()
    if areaPopup or not panel then return end
    -- A child of the journal can be layered *under* later controls on
    -- Forever, including the native menu or item list. Give the picker an
    -- independent top-level stratum but anchor it to the original Area field.
    -- As a UIParent child, its buttons are clickable above the whole journal.
    local f=CreateFrame("Frame","ChalkBoxDiscoveriesAreaPicker",UIParent)
    f:SetSize(310,314)
    f:SetPoint("TOPLEFT",controls.area,"BOTTOMLEFT",0,-2)
    if type(f.SetFrameStrata)=="function" then
        f:SetFrameStrata("TOOLTIP")
    end
    if type(f.SetFrameLevel)=="function" then
        f:SetFrameLevel(1000)
    end
    if type(f.SetToplevel)=="function" then f:SetToplevel(true) end
    if type(f.EnableMouse)=="function" then f:EnableMouse(true) end
    if type(f.EnableMouseWheel)=="function" then f:EnableMouseWheel(true) end
    local bg=f:CreateTexture(nil,"BACKGROUND")
    bg:SetAllPoints(f)
    Paint(bg,0.025,0.034,0.042,0.98)
    f.back=bg
    local edge=f:CreateTexture(nil,"BORDER")
    edge:SetPoint("TOPLEFT",f,"TOPLEFT",0,0)
    edge:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0)
    edge:SetHeight(2)
    local er,eg,eb=Accent()
    Paint(edge,er,eg,eb,1)
    f.rows={}
    for i=1,AREA_VISIBLE_ROWS do
        local b=CreateFrame("Button",nil,f)
        b:SetSize(294,AREA_ROW_HEIGHT-1)
        b:SetPoint("TOPLEFT",f,"TOPLEFT",8,-8-(i-1)*AREA_ROW_HEIGHT)
        local back=b:CreateTexture(nil,"BACKGROUND")
        back:SetAllPoints(b)
        b.back=back
        b.label=Font(b,"GameFontHighlight",7,-3,275)
        b:SetScript("OnMouseWheel",function(_,delta)
            AreaPopupPage(delta>0 and -1 or 1)
        end)
        f.rows[i]=b
    end
    f.previous=Button(f,"◀ Previous",98,8,-251,function()
        AreaPopupPage(-1)
    end)
    f.pageLabel=Font(f,"GameFontHighlightSmall",119,-256,85)
    f.next=Button(f,"Next ▶",98,207,-251,function()
        AreaPopupPage(1)
    end)
    f:SetScript("OnMouseWheel",function(_,delta)
        AreaPopupPage(delta>0 and -1 or 1)
    end)
    areaPopup=f
    f:Hide()
end
local quickPicker
local QUICK_VISIBLE_ROWS=9
local QUICK_ROW_HEIGHT=26
local function CloseQuickPopup()
    if quickPicker and quickPicker.Hide then quickPicker:Hide() end
end
local function QuickPopupPage(delta)
    if not quickPicker then return end
    local kind=quickPicker.kind
    if kind~="source" and kind~="sort" then return end
    local options=ChalkBox_DiscoveriesDropdownItems(kind)
    local totalPages=math.max(1,math.ceil(#options/QUICK_VISIBLE_ROWS))
    quickPicker.page=math.max(1,math.min(totalPages,
        (quickPicker.page or 1)+delta))
    local startIndex=(quickPicker.page-1)*QUICK_VISIBLE_ROWS
    for i,button in ipairs(quickPicker.rows) do
        local entry=options[startIndex+i]
        button.choice=entry
        if entry then
            local value=tostring(entry.text or "")
            if #value>38 then value=value:sub(1,35).."..." end
            button.label:SetText(value)
            local r,g,b=0.88,0.91,0.95
            if entry.title then r,g,b=1,0.83,0.40
            elseif value:find("✓",1,true) then r,g,b=0.43,0.93,0.61 end
            button.label:SetTextColor(r,g,b,1)
            if button.back and button.back.SetColorTexture then
                button.back:SetColorTexture(entry.title and 0.12 or 0.08,
                    entry.title and 0.16 or 0.10,
                    entry.title and 0.19 or 0.13,0.95)
            end
            button:SetScript("OnClick",entry.action and function()
                entry.action()
                CloseQuickPopup()
            end or nil)
            button:Show()
        else
            button:SetScript("OnClick",nil)
            button:Hide()
        end
    end
    quickPicker.pageLabel:SetText(
        ("Page %d / %d"):format(quickPicker.page,totalPages))
    quickPicker.previous:SetText(quickPicker.page>1 and "◀ Previous" or "◀")
    quickPicker.next:SetText(quickPicker.page<totalPages and "Next ▶" or "▶")
end
local function EnsureQuickPopup()
    if quickPicker or not panel then return end
    local f=CreateFrame("Frame","ChalkBoxDiscoveriesQuickPicker",UIParent)
    f:SetSize(252,314)
    if type(f.SetFrameStrata)=="function" then f:SetFrameStrata("TOOLTIP") end
    if type(f.SetFrameLevel)=="function" then f:SetFrameLevel(1001) end
    if type(f.SetToplevel)=="function" then f:SetToplevel(true) end
    if type(f.EnableMouse)=="function" then f:EnableMouse(true) end
    if type(f.EnableMouseWheel)=="function" then f:EnableMouseWheel(true) end
    local bg=f:CreateTexture(nil,"BACKGROUND")
    bg:SetAllPoints(f)
    Paint(bg,0.025,0.034,0.042,0.98)
    f.back=bg
    local edge=f:CreateTexture(nil,"BORDER")
    edge:SetPoint("TOPLEFT",f,"TOPLEFT",0,0)
    edge:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0)
    edge:SetHeight(2)
    local er,eg,eb=Accent()
    Paint(edge,er,eg,eb,1)
    f.rows={}
    for i=1,QUICK_VISIBLE_ROWS do
        local b=CreateFrame("Button",nil,f)
        b:SetSize(236,QUICK_ROW_HEIGHT-1)
        b:SetPoint("TOPLEFT",f,"TOPLEFT",8,-8-(i-1)*QUICK_ROW_HEIGHT)
        local back=b:CreateTexture(nil,"BACKGROUND")
        back:SetAllPoints(b)
        b.back=back
        b.label=Font(b,"GameFontHighlight",7,-3,220)
        b:SetScript("OnMouseWheel",function(_,wheel)
            QuickPopupPage(wheel>0 and -1 or 1)
        end)
        f.rows[i]=b
    end
    f.previous=Button(f,"◀ Previous",98,8,-251,function()
        QuickPopupPage(-1)
    end)
    f.pageLabel=Font(f,"GameFontHighlightSmall",107,-256,66)
    f.next=Button(f,"Next ▶",98,147,-251,function()
        QuickPopupPage(1)
    end)
    f:SetScript("OnMouseWheel",function(_,wheel)
        QuickPopupPage(wheel>0 and -1 or 1)
    end)
    quickPicker=f
    f:Hide()
end
local function ToggleQuickPopup(kind)
    EnsureQuickPopup()
    if not quickPicker then return end
    if quickPicker:IsShown() and quickPicker.kind==kind then
        CloseQuickPopup()
        return
    end
    CloseAreaPopup()
    quickPicker.kind=kind
    quickPicker.page=1
    quickPicker:ClearAllPoints()
    if kind=="source" then
        -- The source button sits on the right of the compact sidecar.
        -- Right-align the popup to keep it inside the map-side panel.
        quickPicker:SetPoint("TOPRIGHT",controls[kind],"BOTTOMRIGHT",0,-2)
    else
        quickPicker:SetPoint("TOPLEFT",controls[kind],"BOTTOMLEFT",0,-2)
    end
    QuickPopupPage(0)
    quickPicker:Show()
    if type(quickPicker.Raise)=="function" then quickPicker:Raise() end
end
local function ClosePickers()
    CloseAreaPopup()
    CloseQuickPopup()
end
local function Dropdown(parent,label,width,x,y,kind)
    local b=Button(parent,label,width,x,y,function(self)
        if kind=="area" then
            CloseQuickPopup()
            EnsureAreaPopup()
            if not areaPopup then return end
            if areaPopup:IsShown() then CloseAreaPopup()
            else
                areaPopup.page=1
                AreaPopupPage(0)
                areaPopup:Show()
                if type(areaPopup.Raise)=="function" then
                    areaPopup:Raise()
                end
            end
            return
        end
        -- Actual clickable Blizzard-style frames, not a context menu that
        -- may silently fail to appear on Forever. No auto-cycling fallback.
        ToggleQuickPopup(kind)
    end)
    controls[kind]=b
    return b
end
local function Row(parent,index)
    local y=-291-(index-1)*36
    local frame=CreateFrame("Frame",nil,parent)
    frame:SetSize(PANEL_W-36,34)
    frame:SetPoint("TOPLEFT",parent,"TOPLEFT",18,y)
    local back=frame:CreateTexture(nil,"BACKGROUND")
    back:SetAllPoints(frame)
    local icon=frame:CreateTexture(nil,"ARTWORK")
    icon:SetSize(28,28)
    icon:SetPoint("LEFT",frame,"LEFT",7,0)
    local name=Font(frame,"GameFontHighlight",46,-5,198)
    local quantity=Font(frame,"GameFontNormal",243,-5,52)
    local sampled=Font(frame,"GameFontHighlightSmall",304,-5,55)
    local rate=Font(frame,"GameFontHighlight",375,-5,64)
    local hint=Font(frame,"GameFontHighlightSmall",46,-21,397)
    local r={frame=frame,back=back,icon=icon,name=name,qty=quantity,
        samples=sampled,rate=rate,hint=hint}
    if type(frame.EnableMouse)=="function" then frame:EnableMouse(true) end
    frame:SetScript("OnEnter",function()
        local item=r.item
        PulseHover(item)
        if not item or not GameTooltip or
            type(GameTooltip.SetHyperlink)~="function" then return end
        GameTooltip:SetOwner(frame,"ANCHOR_RIGHT")
        local ok=pcall(GameTooltip.SetHyperlink,GameTooltip,"item:"..item.id)
        if ok then
            if item.rate and item.attempts then
                GameTooltip:AddLine(item.sourceName or "Creature",
                    0.86,0.66,0.38)
                GameTooltip:AddLine(
                    ("%d drops / %d loots  ·  %.1f%%"):format(
                    item.hits or item.windows,item.attempts,item.rate),
                    0.7,0.9,0.8)
            else
                GameTooltip:AddLine("Select a creature for drop rate.",
                    0.75,0.75,0.8)
            end
            -- A loot location is where the player opened that outdoor
            -- loot window, not a claim about the exact creature death spot.
            local spots=item.locations
            if mode=="outdoor" and type(spots)=="table" and #spots>0 then
                local info=type(ChalkBox_DropAreaInfo)=="function"
                    and ChalkBox_DropAreaInfo(selectedArea) or nil
                local zone=info and info.name or "this zone"
                GameTooltip:AddLine("Looted near "..zone..":",
                    0.86,0.66,0.38)
                for i=#spots,math.max(1,#spots-2),-1 do
                    local spot=spots[i]
                    if type(spot)=="table" and type(spot.x)=="number"
                        and type(spot.y)=="number" then
                        GameTooltip:AddLine(
                            ("%.1f, %.1f  (%d loot%s)"):format(
                                spot.x/10,spot.y/10,spot.count or 1,
                                (spot.count or 1)==1 and "" or "s"),
                            0.70,0.90,0.80)
                    end
                end
                if #spots>3 then
                    GameTooltip:AddLine(("%d more recorded locations"):format(
                        #spots-3),0.65,0.70,0.74)
                end
            end
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave",function()
        PulseClear()
        if GameTooltip then GameTooltip:Hide() end
    end)
    return r
end
local function SetItemIcon(row,id)
    local iconID
    if type(C_Item)=="table" then
        iconID=Call(C_Item.GetItemIconByID,tonumber(id))
    end
    if not iconID then iconID=Call(GetItemIcon,tonumber(id)) end
    if row.icon and type(row.icon.SetTexture)=="function" then
        row.icon:SetTexture(iconID or 134400)
    end
end
local function ClearRow(row)
    row.item=nil
    row.name:SetText("")
    row.qty:SetText("")
    row.samples:SetText("")
    row.rate:SetText("")
    row.hint:SetText("")
    if row.icon and type(row.icon.SetTexture)=="function" then
        row.icon:SetTexture(nil)
    end
    if type(row.frame.Hide)=="function" then row.frame:Hide() end
end
refresh=function()
    PulseClear()
    if not panel then return end
    EnsureSelection()
    local info=type(ChalkBox_DropAreaInfo)=="function" and
        selectedArea and ChalkBox_DropAreaInfo(selectedArea) or nil
    local all=Items()
    local sources=Sources()
    local maxPage=math.max(1,math.ceil(#all/PER_PAGE))
    if page>maxPage then page=maxPage end
    if page<1 then page=1 end
    local zoneName=selectedArea and info and info.name or
        (currentMap and MapName(currentMap)) or "Unexplored"
    controls.title:SetText("DISCOVERIES")
    controls.subtitle:SetText(
        "YOUR PERSONAL LOOT ATLAS  ·  "..(mode=="outdoor" and
            "OUTDOOR" or "DUNGEON"))
    controls.area:SetText(
        (zoneName:len()>25 and zoneName:sub(1,22).."..." or zoneName).."  ▾")
    local sourceName="All creatures"
    for _,s in ipairs(sources) do
        if s.key==selectedSource then sourceName=s.name;break end
    end
    if sourceName:len()>18 then sourceName=sourceName:sub(1,15).."..." end
    if #sources==0 then sourceName="No creatures recorded" end
    controls.source:SetText(sourceName.."  ▾")
    local sortName="Quantity"
    for _,s in ipairs(sorting) do
        if s.key==sortKey then sortName=s.name;break end
    end
    controls.sort:SetText(sortName.."  ▾")
    controls.outdoor:SetText(mode=="outdoor" and "● Outdoor" or "Outdoor")
    controls.dungeon:SetText(mode=="dungeon" and "● Dungeons" or "Dungeons")
    controls.map:SetText(followMap and "● Map sync: ON" or "○ Map sync: OFF")
    controls.count:SetText(("%d items  ·  %d loots tracked  ·  %d creatures"):format(
        #all,info and info.windows or 0,#sources))
    for i,row in ipairs(rows) do
        local item=all[(page-1)*PER_PAGE+i]
        if not item then ClearRow(row)
        else
            row.item=item
            SetItemIcon(row,item.id)
            row.name:SetText(item.name or ("Item #"..item.id))
            row.qty:SetText("x"..tostring(item.quantity or 0))
            row.samples:SetText(tostring(item.windows or 0))
            row.rate:SetText(item.rate and
                ("%.1f%%"):format(item.rate) or "—")
            row.hint:SetText(item.rate and item.attempts and
                ("%s  ·  %d drops / %d loots"):format(
                    item.sourceName or "Creature",item.hits or 0,item.attempts)
                or "Choose a creature for its drop rate")
            if type(row.frame.Show)=="function" then row.frame:Show() end
        end
    end
    controls.page:SetText(("Page %d of %d"):format(page,maxPage))
    local opts=type(ChalkBox_DropOptions)=="function" and
        ChalkBox_DropOptions() or {}
    if not info then
        controls.empty:SetText("No drops recorded here yet.")
    elseif #all==0 then
        controls.empty:SetText("No items match your search or source filter.")
    else controls.empty:SetText("") end
    controls.footer:SetText(
        "* Personal loot rates only  ·  Unlooted kills not counted."..
        (opts.limitReached and "  ·  Storage limit reached." or ""))
end
-- Attach to Blizzard's map without mutating its points/scale/size.
-- Prefer a sidecar outside the right edge, use left if needed, and keep
-- a deliberate in-map side attachment for maximized map layouts.
local dockGeometry
local function DockPanel()
    if not panel or not WorldMapFrame then return false end
    local world=WorldMapFrame
    local worldLeft=Call(world.GetLeft,world)
    local worldRight=Call(world.GetRight,world)
    local worldTop=Call(world.GetTop,world)
    local rootLeft=UIParent and Call(UIParent.GetLeft,UIParent)
    local rootRight=UIParent and Call(UIParent.GetRight,UIParent)
    local rootTop=UIParent and Call(UIParent.GetTop,UIParent)
    local rootBottom=UIParent and Call(UIParent.GetBottom,UIParent)
    local gap=8
    local side="right"
    if type(worldRight)=="number" and type(rootRight)=="number"
        and rootRight-worldRight<PANEL_W+gap then
        side="inside"
        if type(worldLeft)=="number" and type(rootLeft)=="number"
            and worldLeft-rootLeft>=PANEL_W+gap then
            side="left"
        end
    end
    local y=0
    if type(worldTop)=="number" and type(rootTop)=="number"
        and type(rootBottom)=="number" then
        local minY=rootBottom+PANEL_H-worldTop+10
        local maxY=rootTop-worldTop-10
        if minY<=maxY then y=math.max(minY,math.min(0,maxY)) end
    end
    local key=tostring(side)..":"..tostring(y)..":"..
        tostring(worldLeft)..":"..tostring(worldRight)..":"..
        tostring(worldTop)..":"..tostring(rootRight)
    if key==dockGeometry then return true end
    dockGeometry=key
    dockSide=side
    panel:ClearAllPoints()
    if side=="right" then
        panel:SetPoint("TOPLEFT",world,"TOPRIGHT",gap,y)
    elseif side=="left" then
        panel:SetPoint("TOPRIGHT",world,"TOPLEFT",-gap,y)
    else
        panel:SetPoint("TOPRIGHT",world,"TOPRIGHT",-10,y)
    end
    return true
end
local function EnsurePanel()
    if panel or not UIParent then return end
    local template=type(BackdropTemplateMixin)=="table" and
        "BackdropTemplate" or nil
    local world=WorldMapFrame
    if not world then return end
    -- Parenting to the map makes the side panel disappear with it, even
    -- if another addon closes the map without notifying ChalkBox.
    local f=CreateFrame("Frame","ChalkBoxMapDiscoveries",world,template)
    f:SetSize(PANEL_W,PANEL_H)
    f:SetPoint("TOPLEFT",world,"TOPRIGHT",8,0)
    -- The native Map & Quest Log uses higher strata than ordinary DIALOG.
    -- Put the *whole* journal (body + child controls) above it.
    if type(f.SetFrameStrata)=="function" then
        f:SetFrameStrata("FULLSCREEN_DIALOG")
    end
    if type(f.SetFrameLevel)=="function" then
        local level=Call(world.GetFrameLevel,world) or 0
        if type(level)~="number" then level=0 end
        f:SetFrameLevel(math.max(200,level+20))
    end
    if type(f.SetToplevel)=="function" then f:SetToplevel(true) end
    if type(f.SetBackdrop)=="function" then
        f:SetBackdrop({
            bgFile="Interface\\Buttons\\WHITE8X8",
            edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
            tile=true,tileSize=32,edgeSize=24,
            insets={left=8,right=8,top=8,bottom=8},
        })
    end
    -- Sidecars are docked, not draggable independent dialogs.
    if type(f.EnableMouse)=="function" then f:EnableMouse(true) end
    f:SetScript("OnHide",function()
        PulseClear()
        ClosePickers()
    end)
    -- A dedicated visible border and inset body keep the journal legible
    -- even when the shared theme requests a fully transparent background.
    local edge=f:CreateTexture(nil,"BACKGROUND",nil,-1)
    edge:SetAllPoints(f);f.edge=edge
    -- Purely cosmetic map-style body, not a copy of the map canvas or a
    -- replacement for its tiles. Reuse native Forever art and leave
    -- WorldMapFrame's geometry, scroll container and map IDs untouched.
    local art=f:CreateTexture(nil,"BACKGROUND",nil,0)
    art:SetPoint("TOPLEFT",f,"TOPLEFT",2,-2)
    art:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-2,2)
    f.mapArt=art
    local function LoadNativeArt()
        if type(art.SetAtlas)~="function" then return false end
        -- SetAtlas may be available even when this particular atlas is not.
        local exists=C_Texture and C_Texture.GetAtlasExists
        if type(exists)=="function" then
            local ok,available=pcall(exists,MAP_TILE_ATLAS)
            if ok and available==false then return false end
        end
        local ok,result=pcall(art.SetAtlas,art,MAP_TILE_ATLAS,false)
        if not ok or result==false then return false end
        if type(art.GetAtlas)=="function" then
            local got,atlas=pcall(art.GetAtlas,art)
            if got and atlas~=nil and atlas~=MAP_TILE_ATLAS then return false end
        end
        if type(art.SetHorizTile)=="function" then art:SetHorizTile(true) end
        if type(art.SetVertTile)=="function" then art:SetVertTile(true) end
        if type(art.SetVertexColor)=="function" then
            art:SetVertexColor(1,1,1,1)
        end
        if type(art.Show)=="function" then art:Show() end
        return true
    end
    f.hasMapArt=LoadNativeArt()
    if not f.hasMapArt and type(art.Hide)=="function" then art:Hide() end
    f.RefreshMapArt=function()
        if not f.hasMapArt then
            f.hasMapArt=LoadNativeArt()
            if not f.hasMapArt and type(art.Hide)=="function" then art:Hide() end
        end
    end
    local bg=f:CreateTexture(nil,"BACKGROUND",nil,1)
    bg:SetPoint("TOPLEFT",f,"TOPLEFT",2,-2)
    bg:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-2,2)
    f.back=bg
    local stripe=f:CreateTexture(nil,"ARTWORK")
    stripe:SetPoint("TOPLEFT",f,"TOPLEFT",0,0)
    stripe:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0)
    stripe:SetHeight(3);f.stripe=stripe
    controls.title=Font(f,"GameFontNormalHuge",20,-20,310)
    controls.subtitle=Font(f,"GameFontHighlightSmall",20,-51,446)
    Button(f,"Close",72,392,-20,function() f:Hide() end)
    controls.outdoor=Button(f,"Outdoor",102,18,-83,function()
        CloseAreaPopup()
        mode="outdoor";selectedArea=DefaultArea()
        selectedSource=nil;page=1;SaveBrowser();refresh()
    end)
    controls.dungeon=Button(f,"Dungeons",108,130,-83,function()
        CloseAreaPopup()
        mode="dungeon";selectedArea=DefaultArea()
        selectedSource=nil;page=1;SaveBrowser();refresh()
    end)
    controls.map=Button(f,"Map sync: ON",136,332,-83,function()
        CloseAreaPopup()
        if followMap then
            followMap=false
            -- Return to the last location deliberately selected by the player.
            if browseArea then
                mode=browseMode
                selectedArea=browseArea
            elseif not selectedArea then
                selectedArea=DefaultArea()
            end
            SaveBrowser()
            selectedSource=nil;page=1;refresh()
        else
            FollowWorldMap()
        end
    end)
    Heading(f,"AREA / DUNGEON","GameFontNormal",18,-124,218)
    Heading(f,"CREATURE","GameFontNormal",247,-124,218)
    Dropdown(f,"Choose area",218,18,-144,"area")
    Dropdown(f,"All creatures",218,247,-144,"source")
    Heading(f,"SORT","GameFontNormal",18,-192,135)
    Heading(f,"SEARCH ITEMS","GameFontNormal",164,-192,210)
    Dropdown(f,"Quantity",135,18,-212,"sort")
    local input=CreateFrame("EditBox",nil,f,"InputBoxTemplate")
    input:SetSize(211,24)
    input:SetPoint("TOPLEFT",f,"TOPLEFT",164,-212)
    if input.SetAutoFocus then input:SetAutoFocus(false) end
    if input.SetScript then
        input:SetScript("OnTextChanged",function(self)
            local value=type(self.GetText)=="function" and
                self:GetText() or ""
            if type(value)~="string" then value="" end
            searchText=value:sub(1,80)
            page=1;refresh()
        end)
        input:SetScript("OnEscapePressed",function(self)
            if self.ClearFocus then self:ClearFocus() end
        end)
    end
    controls.search=input
    Button(f,"Clear",81,387,-212,function()
        if input.SetText then input:SetText("") end
        searchText="";page=1;refresh()
    end)
    controls.count=Font(f,"GameFontHighlightSmall",18,-249,450)
    Heading(f,"ITEM","GameFontNormal",65,-271,190)
    Heading(f,"FOUND","GameFontNormal",261,-271,70)
    Heading(f,"LOOTS","GameFontNormal",320,-271,70)
    Heading(f,"RATE*","GameFontNormal",393,-271,68)
    for i=1,PER_PAGE do rows[i]=Row(f,i) end
    controls.empty=Font(f,"GameFontHighlight",30,-315,428)
    Button(f,"◀ Previous",105,18,-558,function()
        page=math.max(1,page-1);refresh()
    end)
    controls.page=Font(f,"GameFontNormal",204,-564,110)
    Button(f,"Next ▶",105,365,-558,function()
        page=page+1;refresh()
    end)
    controls.footer=Font(f,"GameFontHighlightSmall",18,-593,452)
    panel=f
    f:Hide()
    Tint()
    f:SetScript("OnUpdate",function(self,dt)
        if type(self.IsShown)=="function" and not self:IsShown() then
            return
        end
        elapsed=elapsed+(type(dt)=="number" and dt or 0)
        if elapsed<0.7 then return end
        elapsed=0
        -- Recheck only ~once per second; no per-frame pcall/geometry work.
        DockPanel()
        local id=MapID()
        if id and id~=lastMap then
            lastMap=id;currentMap=id
            if followMap then
                selectedArea=DefaultArea()
                selectedSource=nil;page=1;refresh()
            end
        end
    end)
end
-- The settings button and /chalk drops map may be used while the World
-- Map is closed. Use Blizzard's normal map toggle exactly once on that
-- deliberate user action; do not open another standalone Discoveries window.
-- Retry only briefly while Forever lazily constructs its native map.
local mapOpenPending=false
function ChalkBox_OpenMapDiscoveries()
    if not WorldMapFrame or
        (type(WorldMapFrame.IsShown)=="function" and
        not WorldMapFrame:IsShown()) then
        if mapOpenPending or type(ToggleWorldMap)~="function"
            or Call(InCombatLockdown)==true then return false end
        mapOpenPending=true
        local ok=pcall(ToggleWorldMap)
        if not ok then mapOpenPending=false;return false end
        local function Resume(attempt)
            local world=WorldMapFrame
            if world and type(world.IsShown)=="function" and
                Call(world.IsShown,world)==true then
                mapOpenPending=false
                ChalkBox_OpenMapDiscoveries()
            elseif attempt<5 and C_Timer and
                type(C_Timer.After)=="function" then
                C_Timer.After(0.15,function() Resume(attempt+1) end)
            else
                mapOpenPending=false
            end
        end
        if C_Timer and type(C_Timer.After)=="function" then
            C_Timer.After(0,function() Resume(0) end)
        else
            Resume(5)
        end
        return true -- requested; native map may still be loading
    end
    RestoreBrowser()
    if type(ChalkBox_MapDiscoveriesEnsure)=="function" then
        ChalkBox_MapDiscoveriesEnsure()
    end
    EnsurePanel()
    if not panel then return false end
    DockPanel()
    local id=MapID()
    if id then currentMap=id;lastMap=id end
    if not selectedArea or followMap then
        selectedArea=DefaultArea()
    end
    refresh()
    if panel.RefreshMapArt then panel:RefreshMapArt() end
    Tint()
    panel:Show()
    if type(panel.Raise)=="function" then panel:Raise() end
    -- A map can be reopened after this frame was constructed.
    if type(panel.SetFrameLevel)=="function" then
        local level=WorldMapFrame and
            Call(WorldMapFrame.GetFrameLevel,WorldMapFrame) or 0
        if type(level)~="number" then level=0 end
        panel:SetFrameLevel(math.max(200,level+20))
    end
    return true
end
-- The new visibility fix in 2.0 is retained: Forever may load the map
-- after ChalkBox's initial events. Attach once and stop temporary retries.
local function MapContainer(world)
    if not world then return end
    if type(world.GetCanvasContainer)=="function" then
        local candidate=Call(world.GetCanvasContainer,world)
        if candidate and type(candidate.SetPoint)=="function" then
            return candidate,"canvas"
        end
    end
    if world.ScrollContainer and
        type(world.ScrollContainer.SetPoint)=="function" then
        return world.ScrollContainer,"scroll"
    end
    return world,"frame"
end
local function PositionButton()
    if not mapButton or not WorldMapFrame then return end
    local container,kind=MapContainer(WorldMapFrame)
    if not container then return end
    if type(mapButton.ClearAllPoints)=="function" then
        mapButton:ClearAllPoints()
    end
    local saved=Store()
    local x,y=kind=="frame" and 18 or 8,kind=="frame" and -114 or -98
    if ValidOffset(saved.buttonX) and ValidOffset(saved.buttonY) then
        x,y=saved.buttonX,saved.buttonY
    end
    -- Saved positions stay within the visible map at smaller UI scales.
    local w=Call(container.GetWidth,container)
    local h=Call(container.GetHeight,container)
    if type(w)=="number" and w>140 then
        x=math.max(0,math.min(x,w-116))
    end
    if type(h)=="number" and h>90 then
        y=math.max(-h+35,math.min(-10,y))
    end
    mapButton:SetPoint("TOPLEFT",container,"TOPLEFT",x,y)
    attachedTo=kind
end
local function SavePosition()
    if not mapButton or not WorldMapFrame then return false end
    local container=MapContainer(WorldMapFrame)
    if not container or type(mapButton.GetLeft)~="function" or
        type(mapButton.GetTop)~="function" or
        type(container.GetLeft)~="function" or
        type(container.GetTop)~="function" then return false end
    local left,top=Call(mapButton.GetLeft,mapButton),
        Call(mapButton.GetTop,mapButton)
    local baseLeft,baseTop=Call(container.GetLeft,container),
        Call(container.GetTop,container)
    if not (ValidOffset(left) and ValidOffset(top) and
        ValidOffset(baseLeft) and ValidOffset(baseTop)) then
        return false
    end
    local saved=Store()
    saved.buttonX=math.floor(left-baseLeft+0.5)
    saved.buttonY=math.floor(top-baseTop+0.5)
    PositionButton()
    return true
end
function ChalkBox_MapDiscoveriesResetButton()
    local saved=Store()
    saved.buttonX=nil;saved.buttonY=nil
    if mapButton then PositionButton() end
    return true
end
function ChalkBox_MapDiscoveriesButtonPosition()
    local saved=Store()
    return {x=saved.buttonX,y=saved.buttonY,
        custom=ValidOffset(saved.buttonX) and ValidOffset(saved.buttonY)}
end
local function OnButtonMenu(self)
    local options={
        {text="Discoveries",title=true},
        {text="Open loot journal",action=function()
            ChalkBox_OpenMapDiscoveries() end},
        {text="Reset button position",action=function()
            ChalkBox_MapDiscoveriesResetButton() end},
    }
    if not ShowMenu(self,options) then
        ChalkBox_MapDiscoveriesResetButton()
    end
end
local function InstallButton()
    if mapButton then return true end
    local world=WorldMapFrame
    if not world then return false end
    local b=CreateFrame("Button","ChalkBoxMapDiscoveriesButton",world,
        "UIPanelButtonTemplate")
    if not b then return false end
    b:SetSize(116,25)
    if type(b.SetFrameStrata)=="function" then b:SetFrameStrata("HIGH") end
    if type(b.SetFrameLevel)=="function" and
        type(world.GetFrameLevel)=="function" then
        local level=Call(world.GetFrameLevel,world)
        if type(level)=="number" then b:SetFrameLevel(level+40) end
    end
    if type(b.SetMovable)=="function" then b:SetMovable(true) end
    if type(b.SetClampedToScreen)=="function" then
        b:SetClampedToScreen(true)
    end
    if type(b.RegisterForDrag)=="function" then
        b:RegisterForDrag("LeftButton")
    end
    b:SetText("Discoveries")
    b:SetScript("OnClick",function(self,button)
        if button=="RightButton" then OnButtonMenu(self)
        else ChalkBox_OpenMapDiscoveries() end
    end)
    if type(b.RegisterForClicks)=="function" then
        b:RegisterForClicks("LeftButtonUp","RightButtonUp")
    end
    b:SetScript("OnDragStart",function(self)
        if type(InCombatLockdown)=="function" and InCombatLockdown() then
            return
        end
        self._chalkDragging=true
        if type(self.StartMoving)=="function" then self:StartMoving() end
    end)
    b:SetScript("OnDragStop",function(self)
        if type(self.StopMovingOrSizing)=="function" then
            self:StopMovingOrSizing()
        end
        if self._chalkDragging then SavePosition() end
        self._chalkDragging=false
    end)
    b:SetScript("OnEnter",function(self)
        if GameTooltip then
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:SetText("Discoveries")
            GameTooltip:AddLine("Left click  ·  Open journal",
                0.8,0.82,0.85,true)
            GameTooltip:AddLine("Drag  ·  Move button",
                0.7,0.85,0.75,true)
            GameTooltip:AddLine("Right click  ·  Reset position",
                0.75,0.75,0.8,true)
            GameTooltip:Show()
        end
    end)
    b:SetScript("OnLeave",function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    mapButton=b
    PositionButton()
    if type(world.HookScript)=="function" then
        world:HookScript("OnShow",function()
            PositionButton()
            dockGeometry=nil
            if panel and type(panel.IsShown)=="function"
                and panel:IsShown() then DockPanel() end
            ChalkBox_MapDiscoveriesRefresh()
        end)
        world:HookScript("OnHide",function()
            ClosePickers()
            if panel and panel.Hide then panel:Hide() end
        end)
    end
    if type(hooksecurefunc)=="function" and
        type(world.OnMapChanged)=="function" then
        pcall(hooksecurefunc,world,"OnMapChanged",function()
            PositionButton()
            ChalkBox_MapDiscoveriesRefresh()
        end)
    end
    ChalkBox_MapDiscoveriesRefresh()
    return true
end
function ChalkBox_MapDiscoveriesEnsure()
    if not mapButton then InstallButton() end
    if mapButton then PositionButton() end
    return mapButton~=nil
end
-- Read-only browser state for diagnostics and regression tests.
function ChalkBox_DiscoveriesBrowserStatus()
    RestoreBrowser()
    return {followMap=followMap,mode=mode,selectedArea=selectedArea,
        browseArea=browseArea,mapID=currentMap,dock=dockSide,
        selectedSource=selectedSource}
end
function ChalkBox_MapDiscoveriesStatus()
    local opt=type(ChalkBox_DropOptions)=="function" and
        ChalkBox_DropOptions() or {}
    return {
        frame=WorldMapFrame~=nil,
        button=mapButton~=nil,
        shown=mapButton and type(mapButton.IsShown)=="function"
            and mapButton:IsShown() or false,
        allowed=opt.mapButton~=false,
        tracking=opt.enabled~=false,
        areas=opt.areas or 0,
        anchor=attachedTo or "not attached",
        mapID=MapID(),
        retries=retries,
        moved=ChalkBox_MapDiscoveriesButtonPosition().custom,
    }
end
function ChalkBox_MapDiscoveriesRefresh()
    if not mapButton and not InstallButton() then return false end
    if Watch() then mapButton:Show()
    else
        mapButton:Hide()
        if panel then panel:Hide() end
    end
    return true
end
loader=CreateFrame("Frame")
for _,name in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD",
    "ADDON_LOADED"}) do
    loader:RegisterEvent(name)
end
loader:SetScript("OnEvent",function()
    ChalkBox_MapDiscoveriesEnsure()
end)
local elapsedRetry=0
loader:SetScript("OnUpdate",function(self,dt)
    if mapButton then
        self:SetScript("OnUpdate",nil)
        return
    end
    if type(dt)~="number" then return end
    elapsedRetry=elapsedRetry+dt
    if elapsedRetry<0.75 then return end
    elapsedRetry=0
    retries=retries+1
    if InstallButton() then self:SetScript("OnUpdate",nil) end
end)
ChalkBox_MapDiscoveriesEnsure()
