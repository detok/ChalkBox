-- ChalkBox Map Discoveries: optional button on Blizzard's existing world map.
-- No replacement map, pins, external database or quest tracker alterations.
local mapButton,panel
local currentMap,mode,dungeonIndex,sourceIndex,page=nil,"outdoor",1,1,1
local rows={}
local title,subtitle,summary,footer
local elapsed=0
local function Public(v)
    return v~=nil and (type(issecretvalue)~="function" or not issecretvalue(v))
end
local function Call(fn,...)
    if type(fn)~="function" then return end
    local ok,result=pcall(fn,...)
    if ok and Public(result) then return result end
end
local function Color()
    if not panel then return end
    local r,g,b,a=0.018,0.018,0.022,0.97
    if type(ChalkBox_ThemeBackground)=="function" then
        r,g,b,a=ChalkBox_ThemeBackground(0.97)
    end
    if panel.back and panel.back.SetColorTexture then
        panel.back:SetColorTexture(r,g,b,a)
    end
    if panel.stripe and panel.stripe.SetColorTexture then
        if type(ChalkBox_ThemeAccent)=="function" then
            panel.stripe:SetColorTexture(ChalkBox_ThemeAccent())
        else panel.stripe:SetColorTexture(0.86,0.66,0.38,1) end
    end
end
function ChalkBox_MapDiscoveriesThemeRefresh() Color() end
local function MapID()
    local world=WorldMapFrame
    local id
    if world and type(world.GetMapID)=="function" then
        id=Call(world.GetMapID,world)
    end
    if (not id or type(id)~="number") and world and
        type(world.ScrollContainer)=="table" and
        type(world.ScrollContainer.GetMapID)=="function" then
        id=Call(world.ScrollContainer.GetMapID,world.ScrollContainer)
    end
    if (not id or type(id)~="number") and C_Map then
        id=Call(C_Map.GetBestMapForUnit,"player")
    end
    if type(id)=="number" and id>0 then return id end
end
local function Name(mapID)
    local info=Call(C_Map and C_Map.GetMapInfo,mapID)
    if type(info)=="table" and type(info.name)=="string" then
        return info.name
    end
    return "Map "..tostring(mapID or "?")
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
    f:SetJustifyH("LEFT")
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
local function Data()
    if type(ChalkBox_DropMapData)~="function" then
        return {zone=nil,dungeons={}}
    end
    return ChalkBox_DropMapData(currentMap)
end
local function Selected()
    local data=Data()
    if mode=="outdoor" then
        return data.zone and ("z:"..tostring(currentMap)),
            data.zone,nil,data
    end
    local dungeons=data.dungeons
    if #dungeons==0 then return nil,nil,nil,data end
    if dungeonIndex>#dungeons then dungeonIndex=1 end
    if dungeonIndex<1 then dungeonIndex=1 end
    local selected=dungeons[dungeonIndex]
    return selected.key,selected.area,selected,data
end
local function Refresh()
    if not panel then return end
    local key,area,dungeon,data=Selected()
    title:SetText("DISCOVERIES  /  "..Name(currentMap))
    local opts=ChalkBox_DropOptions and ChalkBox_DropOptions() or {}
    if not area then
        summary:SetText(mode=="outdoor" and
            "No outdoor loot observed here yet." or
            "No recorded dungeon is linked to this map.")
        subtitle:SetText(mode=="outdoor" and
            "Loot this zone to start a personal field guide." or
            "Dungeons link here only after observed entry/exit.")
        footer:SetText("Only personally observed loot is displayed.")
        for _,row in ipairs(rows) do
            row.title:SetText("")
            row.detail:SetText("")
        end
        if panel.dungeonButton then panel.dungeonButton:SetText("Next dungeon") end
        if panel.sourceButton then panel.sourceButton:SetText("Next source") end
        return
    end
    local sources=type(ChalkBox_DropSources)=="function" and
        ChalkBox_DropSources(key) or {}
    local sourceKey=nil
    if sourceIndex>1 and #sources>0 then
        local selected=sources[sourceIndex-1]
        if selected then sourceKey=selected.key
        else sourceIndex=1 end
    end
    local items=ChalkBox_DropAreaItems and
        ChalkBox_DropAreaItems(key,sourceKey) or {}
    local maxPages=math.max(1,math.ceil(#items/#rows))
    if page>maxPages then page=maxPages end
    subtitle:SetText(area.kind=="dungeon" and
        ((dungeon and dungeon.name or area.name)..
            " · separate instance history") or
        ("Outdoor zone · "..tostring(area.windows or 0)..
            " sampled loot windows"))
    local label=sourceKey and sources[sourceIndex-1].name or "All sources"
    summary:SetText(("%d discovered items  ·  %s"):format(#items,label))
    local start=(page-1)*#rows
    for i,row in ipairs(rows) do
        local item=items[start+i]
        if item then
            row.title:SetText(item.name.."  x"..item.quantity)
            if item.rate then
                row.detail:SetText(("%d / %d observed windows · %.1f%%, not official"):format(
                    item.windows,item.attempts,item.rate))
            else
                row.detail:SetText(("%d observed loot windows · no reliable source odds"):format(
                    item.windows))
            end
        else row.title:SetText("");row.detail:SetText("") end
    end
    footer:SetText(("Page %d/%d · %d recorded dungeon(s)%s"):format(
        page,maxPages,#data.dungeons,
        opts.limitReached and " · journal storage limit reached" or ""))
    if panel.dungeonButton then
        panel.dungeonButton:SetText("Next dungeon ("..#data.dungeons..")")
    end
    if panel.sourceButton then
        panel.sourceButton:SetText("Source ("..#sources..")")
    end
end
local function EnsurePanel()
    if panel or not UIParent then return end
    local f=CreateFrame("Frame","ChalkBoxMapDiscoveries",UIParent)
    f:SetSize(466,477)
    f:SetPoint("CENTER",UIParent,"CENTER",0,0)
    if f.SetFrameStrata then f:SetFrameStrata("DIALOG") end
    if f.SetMovable then f:SetMovable(true) end
    if f.SetClampedToScreen then f:SetClampedToScreen(true) end
    if f.EnableMouse then f:EnableMouse(true) end
    if f.RegisterForDrag then f:RegisterForDrag("LeftButton") end
    f:SetScript("OnDragStart",function(self)
        if self.StartMoving and (type(InCombatLockdown)~="function" or
            not InCombatLockdown()) then self:StartMoving() end
    end)
    f:SetScript("OnDragStop",function(self)
        if self.StopMovingOrSizing then self:StopMovingOrSizing() end
    end)
    local back=f:CreateTexture(nil,"BACKGROUND")
    back:SetAllPoints(f)
    f.back=back
    local stripe=f:CreateTexture(nil,"ARTWORK")
    stripe:SetPoint("TOPLEFT",f,"TOPLEFT",0,0)
    stripe:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0)
    stripe:SetHeight(3)
    f.stripe=stripe
    title=Font(f,"GameFontNormalLarge",20,-20,420)
    subtitle=Font(f,"GameFontHighlightSmall",20,-53,423)
    Button(f,"Outdoor",112,20,-82,function()
        mode="outdoor";page=1;sourceIndex=1;Refresh()
    end)
    Button(f,"Dungeons",112,142,-82,function()
        mode="dungeon";page=1;sourceIndex=1;Refresh()
    end)
    Button(f,"Close",90,356,-82,function() f:Hide() end)
    summary=Font(f,"GameFontNormal",21,-124,424)
    for i=1,7 do
        local top=-159-(i-1)*37
        local a=Font(f,"GameFontHighlight",27,top,407)
        local b=Font(f,"GameFontHighlightSmall",27,top-17,407)
        rows[#rows+1]={title=a,detail=b}
    end
    f.sourceButton=Button(f,"Source (0)",131,20,-430,function()
        local key=Selected()
        local sources=key and ChalkBox_DropSources and
            ChalkBox_DropSources(key) or {}
        sourceIndex=sourceIndex+1
        if sourceIndex>#sources+1 then sourceIndex=1 end
        page=1;Refresh()
    end)
    f.dungeonButton=Button(f,"Next dungeon",132,159,-430,function()
        local dungeons=Data().dungeons
        if #dungeons>0 then
            mode="dungeon"
            dungeonIndex=dungeonIndex%#dungeons+1
            sourceIndex=1;page=1;Refresh()
        end
    end)
    Button(f,"<",41,304,-430,function()
        page=math.max(1,page-1);Refresh()
    end)
    Button(f,">",41,351,-430,function() page=page+1;Refresh() end)
    footer=Font(f,"GameFontHighlightSmall",21,-466,426)
    panel=f
    f:Hide()
    Color()
    local lastMap=MapID()
    f:SetScript("OnUpdate",function(self,dt)
        if not self.IsShown or not self:IsShown() then return end
        elapsed=elapsed+(type(dt)=="number" and dt or 0)
        if elapsed<0.6 then return end
        elapsed=0
        local id=MapID()
        if id and id~=lastMap then
            lastMap=id
            currentMap=id;dungeonIndex=1;sourceIndex=1;page=1
            Refresh()
        end
    end)
end
function ChalkBox_OpenMapDiscoveries()
    -- A slash command/settings click can be the first access before the
    -- map's load-on-demand frame exists; the journal still opens standalone.
    if type(ChalkBox_MapDiscoveriesEnsure)=="function" then
        ChalkBox_MapDiscoveriesEnsure()
    end
    EnsurePanel()
    if not panel then return false end
    local id=MapID()
    if id and id~=currentMap then
        currentMap=id;dungeonIndex=1;sourceIndex=1;page=1
    end
    if not currentMap then return false end
    Color()
    Refresh()
    panel:Show()
    return true
end
-- Forever's WorldMapFrame can be loaded AFTER ChalkBox finishes loading.
-- Additionally Forever uses the modern map canvas, with its pin button
-- at the top LEFT; a static top-right coordinate can be obscured.
-- Discoveries remains independently accessible via /chalk drops map.
local attachedTo
local retries=0
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
    if not mapButton then return end
    local world=WorldMapFrame
    if not world then return end
    local container,kind=MapContainer(world)
    if not container then return end
    if type(mapButton.ClearAllPoints)=="function" then
        mapButton:ClearAllPoints()
    end
    -- Anchor inside the visible canvas, away from the nav bar and map pin.
    -- When the canvas API is unavailable, use the outer map as fallback.
    mapButton:SetPoint("TOPLEFT",container,"TOPLEFT",
        kind=="frame" and 18 or 8,kind=="frame" and -114 or -98)
    attachedTo=kind
end
local function InstallButton()
    if mapButton then return true end
    local world=WorldMapFrame
    if not world then return false end
    local b=CreateFrame("Button","ChalkBoxMapDiscoveriesButton",world,
        "UIPanelButtonTemplate")
    if not b then return false end
    b:SetSize(116,25)
    if type(b.SetFrameStrata)=="function" then
        b:SetFrameStrata("HIGH")
    end
    if type(b.SetFrameLevel)=="function" and
        type(world.GetFrameLevel)=="function" then
        local level=Call(world.GetFrameLevel,world)
        if type(level)=="number" then b:SetFrameLevel(level+40) end
    end
    b:SetText("Discoveries")
    b:SetScript("OnClick",function()
        ChalkBox_OpenMapDiscoveries()
    end)
    if type(b.SetScript)=="function" then
        b:SetScript("OnEnter",function(self)
            if GameTooltip then
                GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
                GameTooltip:SetText("ChalkBox Discoveries")
                GameTooltip:AddLine("Browse your own outdoor and dungeon loot.",
                    0.85,0.85,0.85,true)
                GameTooltip:Show()
            end
        end)
        b:SetScript("OnLeave",function()
            if GameTooltip then GameTooltip:Hide() end
        end)
    end
    mapButton=b
    PositionButton()
    if type(world.HookScript)=="function" then
        -- OnShow is more reliable than the map update event on a
        -- load-on-demand WorldMapFrame, including the very first open.
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
    local opts=type(ChalkBox_DropOptions)=="function"
        and ChalkBox_DropOptions() or {}
    return {
        frame=WorldMapFrame~=nil,
        button=mapButton~=nil,
        shown=mapButton and type(mapButton.IsShown)=="function"
            and mapButton:IsShown() or false,
        allowed=opts.mapButton~=false,
        tracking=opts.enabled~=false,
        areas=opts.areas or 0,
        anchor=attachedTo or "not attached",
        mapID=MapID(),
        retries=retries,
    }
end
function ChalkBox_MapDiscoveriesRefresh()
    if not mapButton then
        if not InstallButton() then return false end
    end
    if Watch() then mapButton:Show()
    else
        mapButton:Hide()
        if panel then panel:Hide() end
    end
    return true
end
local loader=CreateFrame("Frame")
-- Do not rely on WORLD_MAP_UPDATE existing in this Forever build.
-- ADDON_LOADED also fires when Blizzard's map loads on demand.
for _,e in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD",
    "ADDON_LOADED"}) do
    loader:RegisterEvent(e)
end
loader:SetScript("OnEvent",function()
    ChalkBox_MapDiscoveriesEnsure()
end)
-- A lightweight temporary retry handles clients with an already available
-- world frame that isn't initialized until the first time the map opens.
-- Stops entirely once the button attaches; no permanent map polling.
local elapsedRetry=0
loader:SetScript("OnUpdate",function(self,elapsed)
    if mapButton then
        self:SetScript("OnUpdate",nil)
        return
    end
    if type(elapsed)~="number" then return end
    elapsedRetry=elapsedRetry+elapsed
    if elapsedRetry<0.75 then return end
    elapsedRetry=0
    retries=retries+1
    if InstallButton() then self:SetScript("OnUpdate",nil) end
end)
ChalkBox_MapDiscoveriesEnsure()
