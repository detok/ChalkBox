-- ChalkBox Discoveries browser. WoW Forever's native WorldMapFrame is
-- preserved; only a movable optional button and a standalone browser are added.
-- No HTTP requests, map texture replacements or fabricated drop probabilities.
local mapButton,panel,loader
local currentMap=nil
local mode="outdoor"
local selectedArea=nil
local followMap=true
local selectedSource=nil
local sortKey="quantity"
local searchText=""
local page=1
local rows={}
local controls={}
local lastMap,elapsed=nil,0
local attachedTo,retries=nil,0
local menuFrame
local PANEL_W,PANEL_H=660,616
local PER_PAGE=7

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
    Paint(panel.back,r,g,b,a)
    Paint(panel.edge,ar,ag,ab,0.82)
    Paint(panel.stripe,ar,ag,ab,1)
    if type(panel.SetBackdropColor)=="function" then
        panel:SetBackdropColor(r,g,b,a)
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
        local key=currentMap and ("z:"..currentMap) or nil
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
            selectedArea=="z:"..currentMap) then
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
-- MenuUtil is the modern client API. EasyMenu is a fallback. If neither is
-- present, clicking cycles through options instead of breaking navigation.
local function ShowMenu(owner,choices)
    if type(InCombatLockdown)=="function" and InCombatLockdown() then
        return false
    end
    if type(MenuUtil)=="table" and
        type(MenuUtil.CreateContextMenu)=="function" then
        local ok=pcall(MenuUtil.CreateContextMenu,owner,
            function(_,root)
                for _,entry in ipairs(choices) do
                    if entry.title and type(root.CreateTitle)=="function" then
                        root:CreateTitle(entry.text)
                    elseif type(root.CreateButton)=="function" then
                        root:CreateButton(entry.text,function() entry.action() end)
                    end
                end
            end)
        if ok then return true end
    end
    if type(EasyMenu)=="function" then
        if not menuFrame then
            menuFrame=CreateFrame("Frame",
                "ChalkBoxDiscoveriesDropdown",UIParent,"UIDropDownMenuTemplate")
        end
        local list={}
        for _,entry in ipairs(choices) do
            list[#list+1]={text=entry.text,func=entry.action,
                isTitle=entry.title==true,notCheckable=true}
        end
        local ok=pcall(EasyMenu,list,menuFrame,owner,0,-4,"MENU")
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
local function AreaOptions()
    local list={{text="CHOOSE "..(mode=="outdoor" and "OUTDOOR ZONE"
        or "DUNGEON"),title=true}}
    for _,entry in ipairs(Areas(mode)) do
        local item=entry
        local name=(entry.key==selectedArea and "✓ " or "")..
            entry.name.." · "..tostring(entry.items or 0).." items"
        list[#list+1]={text=name,action=function()
            selectedArea=item.key
            followMap=false;selectedSource=nil;page=1
            refresh()
        end}
    end
    if #list==1 then
        list[2]={text="No observed locations yet",action=function() end}
    end
    return list
end
local function SourceOptions()
    local list={
        {text="CREATURE / SOURCE FILTER",title=true},
        {text=(not selectedSource and "✓ " or "").."All observed sources",
            action=function() selectedSource=nil;page=1;refresh() end}
    }
    for _,entry in ipairs(Sources()) do
        local item=entry
        list[#list+1]={text=(selectedSource==item.key and "✓ " or "")..
            item.name.." · "..tostring(item.windows).." windows",
            action=function()
                selectedSource=item.key;page=1;refresh()
            end}
    end
    return list
end
local sorting={
    {key="quantity",name="Quantity"},
    {key="appearances",name="Appearances"},
    {key="name",name="Item name"},
    {key="rate",name="Observed rate"},
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
local function Dropdown(parent,label,width,x,y,kind)
    local b=Button(parent,label,width,x,y,function(self)
        local options=ChalkBox_DiscoveriesDropdownItems(kind)
        if not ShowMenu(self,options) then
            local actionable={}
            for _,entry in ipairs(options) do
                if not entry.title then actionable[#actionable+1]=entry end
            end
            if #actionable>0 then
                local pointer=controls[kind.."Cycle"] or 0
                pointer=pointer%#actionable+1
                controls[kind.."Cycle"]=pointer
                Pick(pointer,actionable)
            end
        end
    end)
    controls[kind]=b
    return b
end
local function Row(parent,index)
    local y=-276-(index-1)*39
    local frame=CreateFrame("Frame",nil,parent)
    frame:SetSize(PANEL_W-40,37)
    frame:SetPoint("TOPLEFT",parent,"TOPLEFT",20,y)
    local back=frame:CreateTexture(nil,"BACKGROUND")
    back:SetAllPoints(frame)
    local icon=frame:CreateTexture(nil,"ARTWORK")
    icon:SetSize(28,28)
    icon:SetPoint("LEFT",frame,"LEFT",7,0)
    local name=Font(frame,"GameFontHighlight",46,-5,276)
    local quantity=Font(frame,"GameFontNormal",328,-5,62)
    local sampled=Font(frame,"GameFontHighlightSmall",401,-5,92)
    local rate=Font(frame,"GameFontHighlight",511,-5,103)
    local hint=Font(frame,"GameFontHighlightSmall",46,-22,495)
    local r={frame=frame,back=back,icon=icon,name=name,qty=quantity,
        samples=sampled,rate=rate,hint=hint}
    if type(frame.EnableMouse)=="function" then frame:EnableMouse(true) end
    frame:SetScript("OnEnter",function()
        local item=r.item
        if not item or not GameTooltip or
            type(GameTooltip.SetHyperlink)~="function" then return end
        GameTooltip:SetOwner(frame,"ANCHOR_RIGHT")
        local ok=pcall(GameTooltip.SetHyperlink,GameTooltip,"item:"..item.id)
        if ok then
            GameTooltip:AddLine("ChalkBox · personal observation",
                0.86,0.66,0.38)
            if item.rate then
                GameTooltip:AddLine(("%d in %d known-source windows (%.1f%%)"):format(
                    item.windows,item.attempts,item.rate),0.7,0.9,0.8)
            else
                GameTooltip:AddLine("No comparable creature-specific odds.",
                    0.75,0.75,0.8)
            end
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave",function()
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
    local sourceName="All sources"
    for _,s in ipairs(sources) do
        if s.key==selectedSource then sourceName=s.name;break end
    end
    if sourceName:len()>18 then sourceName=sourceName:sub(1,15).."..." end
    controls.source:SetText(sourceName.."  ▾")
    local sortName="Quantity"
    for _,s in ipairs(sorting) do
        if s.key==sortKey then sortName=s.name;break end
    end
    controls.sort:SetText(sortName.."  ▾")
    controls.outdoor:SetText(mode=="outdoor" and "● Outdoor" or "Outdoor")
    controls.dungeon:SetText(mode=="dungeon" and "● Dungeons" or "Dungeons")
    controls.map:SetText(followMap and "Following map" or "Use map zone")
    controls.count:SetText(("%d items  ·  %d loot windows  ·  %d sources"):format(
        #all,info and info.windows or 0,#sources))
    for i,row in ipairs(rows) do
        local item=all[(page-1)*PER_PAGE+i]
        if not item then ClearRow(row)
        else
            row.item=item
            SetItemIcon(row,item.id)
            row.name:SetText(item.name or ("Item #"..item.id))
            row.qty:SetText("x"..tostring(item.quantity or 0))
            row.samples:SetText(tostring(item.windows or 0).." windows")
            row.rate:SetText(item.rate and
                ("%.1f%%"):format(item.rate) or "—")
            row.hint:SetText(item.rate and
                ("Observed in %d of %d readable %s windows"):format(
                    item.windows,item.attempts,sourceName) or
                "Collected here · rate requires one known creature source")
            if type(row.frame.Show)=="function" then row.frame:Show() end
        end
    end
    controls.page:SetText(("Page %d of %d"):format(page,maxPage))
    local opts=type(ChalkBox_DropOptions)=="function" and
        ChalkBox_DropOptions() or {}
    if not info then
        controls.empty:SetText("Nothing recorded for this location yet.\n"..
            "Loot here with DropSense tracking enabled to build your journal.")
    elseif #all==0 then
        controls.empty:SetText("No items match your search or source filter.")
    else controls.empty:SetText("") end
    controls.footer:SetText(
        "Rates are YOUR observed known-source loot windows, not official drop odds."..
        (opts.limitReached and "  ·  Storage limit reached." or ""))
end
local function EnsurePanel()
    if panel or not UIParent then return end
    local template=type(BackdropTemplateMixin)=="table" and
        "BackdropTemplate" or nil
    local f=CreateFrame("Frame","ChalkBoxMapDiscoveries",UIParent,template)
    f:SetSize(PANEL_W,PANEL_H)
    f:SetPoint("CENTER",UIParent,"CENTER",0,0)
    -- The native Map & Quest Log uses higher strata than ordinary DIALOG.
    -- Put the *whole* journal (body + child controls) above it.
    if type(f.SetFrameStrata)=="function" then
        f:SetFrameStrata("FULLSCREEN_DIALOG")
    end
    if type(f.SetFrameLevel)=="function" then
        local level=type(WorldMapFrame)=="table" and
            Call(WorldMapFrame.GetFrameLevel,WorldMapFrame) or 0
        if type(level)~="number" then level=0 end
        f:SetFrameLevel(math.max(200,level+100))
    end
    if type(f.SetToplevel)=="function" then f:SetToplevel(true) end
    if type(f.SetBackdrop)=="function" then
        f:SetBackdrop({
            bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
            tile=true,tileSize=32,edgeSize=24,
            insets={left=8,right=8,top=8,bottom=8},
        })
    end
    if type(f.SetMovable)=="function" then f:SetMovable(true) end
    if type(f.SetClampedToScreen)=="function" then
        f:SetClampedToScreen(true)
    end
    if type(f.EnableMouse)=="function" then f:EnableMouse(true) end
    if type(f.RegisterForDrag)=="function" then
        f:RegisterForDrag("LeftButton")
    end
    f:SetScript("OnDragStart",function(self)
        if type(InCombatLockdown)~="function" or not InCombatLockdown() then
            if self.StartMoving then self:StartMoving() end
        end
    end)
    f:SetScript("OnDragStop",function(self)
        if self.StopMovingOrSizing then self:StopMovingOrSizing() end
    end)
    -- A dedicated visible border and inset body keep the journal legible
    -- even when the shared theme requests a fully transparent background.
    local edge=f:CreateTexture(nil,"BACKGROUND",nil,-1)
    edge:SetAllPoints(f);f.edge=edge
    local bg=f:CreateTexture(nil,"BACKGROUND",nil,0)
    bg:SetPoint("TOPLEFT",f,"TOPLEFT",2,-2)
    bg:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-2,2)
    f.back=bg
    local stripe=f:CreateTexture(nil,"ARTWORK")
    stripe:SetPoint("TOPLEFT",f,"TOPLEFT",0,0)
    stripe:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0)
    stripe:SetHeight(3);f.stripe=stripe
    controls.title=Font(f,"GameFontNormalHuge",22,-20,400)
    controls.subtitle=Font(f,"GameFontHighlightSmall",22,-51,594)
    Button(f,"Close",86,552,-20,function() f:Hide() end)
    controls.outdoor=Button(f,"Outdoor",128,22,-83,function()
        mode="outdoor";selectedArea=DefaultArea()
        selectedSource=nil;page=1;refresh()
    end)
    controls.dungeon=Button(f,"Dungeons",128,160,-83,function()
        mode="dungeon";selectedArea=DefaultArea()
        selectedSource=nil;page=1;refresh()
    end)
    controls.map=Button(f,"Following map",153,485,-83,function()
        followMap=true;currentMap=MapID()
        selectedArea=DefaultArea();selectedSource=nil;page=1;refresh()
    end)
    Heading(f,"AREA / DUNGEON","GameFontNormal",22,-124,265)
    Heading(f,"CREATURE SOURCE","GameFontNormal",301,-124,212)
    Heading(f,"SORT BY","GameFontNormal",515,-124,116)
    Dropdown(f,"Choose area",265,22,-144,"area")
    Dropdown(f,"All sources",205,301,-144,"source")
    Dropdown(f,"Quantity",123,515,-144,"sort")
    Heading(f,"SEARCH ITEMS","GameFontNormal",22,-195,137)
    local input=CreateFrame("EditBox",nil,f,"InputBoxTemplate")
    input:SetSize(382,24)
    input:SetPoint("TOPLEFT",f,"TOPLEFT",151,-189)
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
    Button(f,"Clear",91,545,-189,function()
        if input.SetText then input:SetText("") end
        searchText="";page=1;refresh()
    end)
    controls.count=Font(f,"GameFontHighlightSmall",22,-230,610)
    Heading(f,"ITEM", "GameFontNormal",70,-257,260)
    Heading(f,"COLLECTED", "GameFontNormal",348,-257,90)
    Heading(f,"APPEARED", "GameFontNormal",425,-257,88)
    Heading(f,"RATE*", "GameFontNormal",542,-257,70)
    for i=1,PER_PAGE do rows[i]=Row(f,i) end
    controls.empty=Font(f,"GameFontHighlight",37,-311,575)
    Button(f,"◀ Previous",112,22,-558,function()
        page=math.max(1,page-1);refresh()
    end)
    controls.page=Font(f,"GameFontNormal",279,-564,137)
    Button(f,"Next ▶",109,529,-558,function()
        page=page+1;refresh()
    end)
    controls.footer=Font(f,"GameFontHighlightSmall",22,-593,612)
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
function ChalkBox_OpenMapDiscoveries()
    if type(ChalkBox_MapDiscoveriesEnsure)=="function" then
        ChalkBox_MapDiscoveriesEnsure()
    end
    EnsurePanel()
    if not panel then return false end
    local id=MapID()
    if id then currentMap=id;lastMap=id end
    if not selectedArea or followMap then
        selectedArea=DefaultArea()
    end
    refresh()
    Tint()
    panel:Show()
    if type(panel.Raise)=="function" then panel:Raise() end
    -- A map can be reopened after this frame was constructed.
    if type(panel.SetFrameLevel)=="function" then
        local level=WorldMapFrame and
            Call(WorldMapFrame.GetFrameLevel,WorldMapFrame) or 0
        if type(level)~="number" then level=0 end
        panel:SetFrameLevel(math.max(200,level+100))
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
        {text="ChalkBox Discoveries",title=true},
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
            GameTooltip:SetText("ChalkBox · Discoveries")
            GameTooltip:AddLine("Click: browse observed loot and dungeons.",
                0.8,0.82,0.85,true)
            GameTooltip:AddLine("Drag: reposition this button on the map.",
                0.7,0.85,0.75,true)
            GameTooltip:AddLine("Right-click: reset button position.",
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
            ChalkBox_MapDiscoveriesRefresh()
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
