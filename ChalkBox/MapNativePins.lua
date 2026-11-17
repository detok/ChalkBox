-- ChalkBox shared, map-owned flight and Discoveries markers.
-- UI positions come only from saved player observations and taxi proof.
local FLIGHT_TEMPLATE="ChalkBoxNativeFlightMarker"
local LOOT_TEMPLATE="ChalkBoxNativeLootMarker"
local provider,flightPool,lootPool
local transientLoot
local markerCount,flightCount,lootCount=0,0,0
local mapRetry=0
local refreshBusy=false
local nativeBroken=false
local lastProblem="native map canvas not loaded"

local function Public(v)
    return v~=nil and (type(issecretvalue)~="function"
        or not issecretvalue(v))
end
local function Number(v)
    return Public(v) and type(v)=="number" and v==v
        and v>=0 and v<=1
end
local function Call(fn,...)
    if type(fn)~="function" then return nil end
    local ok,value=pcall(fn,...)
    if ok and Public(value) then return value end
end
local function MapID(map)
    local id=map and Call(map.GetMapID,map)
    return type(id)=="number" and id>0 and id or nil
end
-- The source coordinates must belong to a *known* map. Projection into a
-- smaller local map uses Blizzard's own map rectangle, never a guess.
local function Project(sourceMap,targetMap,x,y)
    if not Number(x) or not Number(y)
        or type(sourceMap)~="number" or type(targetMap)~="number" then
        return nil
    end
    if sourceMap==targetMap then return x,y end
    local info=Call(C_Map and C_Map.GetMapInfo,targetMap)
    if type(info)~="table" or not Public(info.parentMapID) then return nil end
    -- Walk only downward from source to child. No unrelated or sibling maps.
    local current,seen=targetMap,{}
    local descendant=false
    for _=1,10 do
        if seen[current] then break end
        seen[current]=true
        if current==sourceMap then descendant=true;break end
        local detail=Call(C_Map and C_Map.GetMapInfo,current)
        if type(detail)~="table" or
            type(detail.parentMapID)~="number" then break end
        current=detail.parentMapID
    end
    if not descendant then return nil end
    local minX,maxX,minY,maxY
    local fn=C_Map and C_Map.GetMapRectOnMap
    if type(fn)=="function" then
        local ok,a,b,c,d=pcall(fn,targetMap,sourceMap)
        if ok and Public(a) and Public(b) and Public(c) and Public(d) then
            minX,maxX,minY,maxY=a,b,c,d
        end
    end
    if not Number(minX) or not Number(maxX) or not Number(minY)
        or not Number(maxY) or maxX<=minX or maxY<=minY then
        return nil
    end
    if x<minX or x>maxX or y<minY or y>maxY then return nil end
    local px,py=(x-minX)/(maxX-minX),(y-minY)/(maxY-minY)
    if Number(px) and Number(py) then return px,py end
end
function ChalkBox_MapNativeProject(sourceMap,targetMap,x,y)
    return Project(sourceMap,targetMap,x,y)
end


-- Previously two independent renderers competed with Forever's map tiles:
-- an XML-less MapCanvas pin pool (which fails acquisition on this client),
-- and canvas-child textures which could be hovered while hidden by art.
-- Both features now use one stable sibling of the map canvas, anchored to
-- its coordinates and explicitly raised above the map detail artwork.
local layer, layerCanvas, layerParent
local flightMarkers, lootMarkers={},{}
local lootRecords={}
local activeFlights,activeLoot=0,0
local lastView,lastW,lastH
local tick=0
local currentProblem="waiting for World Map"

local function Safe(method,...)
    if type(method)~="function" then return nil end
    local ok,value=pcall(method,...)
    if ok and Public(value) then return value end
end
local function State()
    local map=WorldMapFrame
    if not map or type(map.IsShown)~="function" or not map:IsShown()
        then return nil end
    local scroll=map.ScrollContainer
    if not scroll then return nil end
    local canvas=Safe(map.GetCanvas,map) or scroll.Child
        or Safe(scroll.GetCanvas,scroll)
    if not canvas then return nil end
    local w,h=Safe(canvas.GetWidth,canvas),Safe(canvas.GetHeight,canvas)
    local id=MapID(map) or Safe(scroll.GetMapID,scroll)
    if not Number(0) or type(w)~="number" or type(h)~="number"
        or w<=0 or h<=0 or type(id)~="number" or id<=0 then
        return nil
    end
    return map,scroll,canvas,id,w,h
end
local function SetColor(tex,r,g,b,a)
    if type(tex.SetTexture)=="function" and
        type(tex.SetVertexColor)=="function" then
        tex:SetTexture("Interface\\Buttons\\WHITE8X8")
        tex:SetVertexColor(r,g,b,a)
    elseif type(tex.SetColorTexture)=="function" then
        tex:SetColorTexture(r,g,b,a)
    end
end
local function Texture(frame,w,h,layerNo,r,g,b,a)
    local tex=frame:CreateTexture(nil,"OVERLAY")
    if type(tex.SetDrawLayer)=="function" then
        tex:SetDrawLayer("OVERLAY",layerNo)
    end
    tex:SetSize(w,h)
    tex:SetPoint("CENTER",frame,"CENTER",0,0)
    SetColor(tex,r,g,b,a)
    return tex
end
local function Raise(world,scroll,canvas)
    if not layer then return end
    local wanted=220
    for _,f in ipairs({world,scroll,canvas}) do
        local v=Safe(f.GetFrameLevel,f)
        if type(v)=="number" then wanted=math.max(wanted,v+90) end
    end
    wanted=math.min(9000,wanted)
    if type(layer.SetFrameLevel)=="function" then
        layer:SetFrameLevel(wanted)
    end
    -- The scroll container can draw different zone tiles at a later stage.
    -- This overlay is its sibling, not a child of an individual tile/canvas.
    local strata=Safe(world.GetFrameStrata,world)
    if type(strata)=="string" and type(layer.SetFrameStrata)=="function" then
        layer:SetFrameStrata(strata)
    end
end
local function Ensure()
    local map,scroll,canvas,id,w,h=State()
    if not map then
        currentProblem="map canvas not displayed"
        return nil
    end
    if not layer or layerCanvas~=canvas or layerParent~=scroll then
        if layer then layer:Hide() end
        layer=CreateFrame("Frame",nil,scroll)
        layerCanvas,layerParent=canvas,scroll
        layer:SetAllPoints(canvas)
        if type(layer.EnableMouse)=="function" then
            layer:EnableMouse(false)
        end
        flightMarkers,lootMarkers={},{}
        activeFlights,activeLoot=0,0
        lastView,lastW,lastH=nil,nil,nil
    end
    Raise(map,scroll,canvas)
    layer:Show()
    currentProblem="overlay attached to active map canvas"
    return id,w,h
end
local function Make(kind,index)
    local list=kind=="flight" and flightMarkers or lootMarkers
    local marker=list[index]
    if marker then return marker end
    marker=CreateFrame("Frame",nil,layer)
    marker:SetSize(kind=="flight" and 26 or 17,
        kind=="flight" and 26 or 17)
    if type(marker.EnableMouse)=="function" then
        marker:EnableMouse(kind=="flight")
    end
    if kind=="flight" then
        -- Real, opaque pixels even if Forever accepts a missing Taxi atlas.
        marker.back=Texture(marker,19,19,5,0.14,0.08,0.02,0.94)
        marker.face=Texture(marker,15,15,6,1,0.74,0.20,1)
        local art=marker:CreateTexture(nil,"OVERLAY")
        art:SetAllPoints(marker)
        if type(art.SetDrawLayer)=="function" then
            art:SetDrawLayer("OVERLAY",7)
        end
        marker.icon=art
        marker:SetScript("OnEnter",function(self)
            if GameTooltip and type(GameTooltip.SetOwner)=="function"
                and type(GameTooltip.AddLine)=="function" then
                GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
                GameTooltip:AddLine(self.flightName or "Flight master",
                    1,0.81,0.45)
                GameTooltip:AddLine("Known flight path",0.50,0.90,0.67)
                GameTooltip:Show()
            end
        end)
        marker:SetScript("OnLeave",function()
            if GameTooltip then GameTooltip:Hide() end
        end)
    else
        marker.back=Texture(marker,17,17,5,0.12,0.08,0.02,0.9)
        marker.face=Texture(marker,13,13,6,1,0.72,0.24,0.95)
        marker.center=Texture(marker,5,5,7,1,0.96,0.73,1)
    end
    list[index]=marker
    return marker
end
local function Place(pin,x,y,w,h)
    pin:ClearAllPoints()
    pin:SetPoint("CENTER",layer,"TOPLEFT",x*w,-y*h)
    pin:Show()
end
local function HideAfter(list,count)
    for i=count+1,#list do list[i]:Hide() end
end
local function SetFlightArtwork(pin,atlas)
    if not pin.icon then return end
    local name=type(atlas)=="string" and atlas or "TaxiNode_Neutral"
    local usable=false
    local info=C_Texture and C_Texture.GetAtlasInfo
    if type(info)=="function" then
        usable=Safe(info,name)~=nil
    end
    if usable and type(pin.icon.SetAtlas)=="function" then
        local ok,result=pcall(pin.icon.SetAtlas,pin.icon,name,false)
        usable=ok and result~=false
    else
        usable=false
    end
    if not usable and type(pin.icon.SetTexture)=="function" then
        pin.icon:SetTexture("Interface\\Minimap\\Tracking\\FlightMaster")
    end
end
local function RedrawFlights(id,w,h)
    local get=ChalkBox_DiscoveriesFlightCandidates
    local entries=type(get)=="function" and get(id) or {}
    if type(entries)~="table" then entries={} end
    local count=0
    for _,entry in ipairs(entries) do
        if type(entry)=="table" and Number(entry.x) and
            Number(entry.y) and count<80 then
            count=count+1
            local pin=Make("flight",count)
            pin.flightName=entry.name
            SetFlightArtwork(pin,entry.atlas)
            Place(pin,entry.x,entry.y,w,h)
        end
    end
    HideAfter(flightMarkers,count)
    activeFlights=count
end
local function RedrawLoot(id,w,h)
    local count=0
    for _,spot in ipairs(lootRecords) do
        local x,y=Project(spot.mapID,id,spot.x,spot.y)
        if x and count<20 then
            count=count+1
            local pin=Make("loot",count)
            Place(pin,x,y,w,h)
        end
    end
    HideAfter(lootMarkers,count)
    activeLoot=count
end
function ChalkBox_MapNativeAvailable()
    return Ensure()~=nil
end
function ChalkBox_MapNativeRefresh()
    local id,w,h=Ensure()
    if not id then
        activeFlights=0
        return false
    end
    RedrawFlights(id,w,h)
    lastView,lastW,lastH=id,w,h
    return true
end
-- Existing single-spot API remains supported. Multi-spot is preferred
-- so hovering a Discoveries item reveals every saved nearby loot position.
function ChalkBox_MapNativeLootSetMany(sourceMap,locations)
    if type(sourceMap)~="number" or type(locations)~="table" then
        return false
    end
    local accepted={}
    for _,spot in ipairs(locations) do
        if type(spot)=="table" and Number(spot.x) and
            Number(spot.y) and #accepted<20 then
            accepted[#accepted+1]={
                mapID=sourceMap,x=spot.x,y=spot.y
            }
        end
    end
    lootRecords=accepted
    local id,w,h=Ensure()
    if not id then activeLoot=0;return false end
    RedrawLoot(id,w,h)
    return activeLoot>0
end
function ChalkBox_MapNativeLootSet(sourceMap,x,y)
    return ChalkBox_MapNativeLootSetMany(sourceMap,{{x=x,y=y}})
end
function ChalkBox_MapNativeLootClear()
    lootRecords={}
    activeLoot=0
    HideAfter(lootMarkers,0)
end
function ChalkBox_MapNativeStatus()
    return {available=layer~=nil and State()~=nil,
        renderer="map-owned overlay",
        mapID=MapID(WorldMapFrame),
        flightPins=activeFlights,lootPins=activeLoot,
        pinCount=activeFlights+activeLoot,
        problem=currentProblem,loot=#lootRecords>0}
end
-- Follow zoom changes, late-created map artwork and map reopening.
-- Reuse the same markers; do not repeatedly destroy/acquire frames.
local driver=CreateFrame("Frame")
driver:SetScript("OnUpdate",function(_,elapsed)
    tick=tick+(type(elapsed)=="number" and elapsed or 0)
    if tick<0.25 then return end
    tick=0
    local id,w,h=Ensure()
    if not id then
        activeFlights,activeLoot=0,0
        lastView,lastW,lastH=nil,nil,nil
        return
    end
    if id~=lastView or w~=lastW or h~=lastH then
        RedrawFlights(id,w,h)
        RedrawLoot(id,w,h)
        lastView,lastW,lastH=id,w,h
    end
end)
