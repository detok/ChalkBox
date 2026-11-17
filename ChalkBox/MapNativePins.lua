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
-- Forever and DonMap-compatible clients expose world coordinates, which
-- remain meaningful when the displayed zone changes or the map is stitched.
-- Ask the game to convert the saved point; never transpose percentages.
local function WorldProjection(sourceMap,targetMap,x,y)
    local api=C_Map
    if type(api)~="table" or
        type(api.GetWorldPosFromMapPos)~="function" or
        type(api.GetMapPosFromWorldPos)~="function" or
        type(CreateVector2D)~="function" then return nil end
    local vector=Call(CreateVector2D,x,y)
    if not vector then return nil end
    local good,continent,world=pcall(api.GetWorldPosFromMapPos,
        sourceMap,vector)
    if not good or type(continent)~="number" or not world then
        return nil
    end
    local ok,_,point=pcall(api.GetMapPosFromWorldPos,
        continent,world,targetMap)
    if not ok or not point then return nil end
    local read,mx,my=pcall(function()
        if type(point.GetXY)=="function" then
            return point:GetXY()
        end
        return point.x,point.y
    end)
    if read and Number(mx) and Number(my) then return mx,my end
end
-- Prefer the game's world coordinate transform when available; only use
-- map-rectangle projection for clients without that capability.
local function Project(sourceMap,targetMap,x,y)
    if not Number(x) or not Number(y)
        or type(sourceMap)~="number" or type(targetMap)~="number" then
        return nil
    end
    if sourceMap==targetMap then return x,y end
    local px,py=WorldProjection(sourceMap,targetMap,x,y)
    if px then return px,py end
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
local lastView,lastW,lastH,lastScale
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
    local canvas=scroll.Child or Safe(map.GetCanvas,map)
        or Safe(scroll.GetCanvas,scroll)
    if not canvas then return nil end
    local w,h=Safe(canvas.GetWidth,canvas),Safe(canvas.GetHeight,canvas)
    local id=MapID(map) or Safe(scroll.GetMapID,scroll)
    if type(w)~="number" or type(h)~="number"
        or w<=0 or h<=0 or type(id)~="number" or id<=0 then
        return nil
    end
    return map,scroll,canvas,id,w,h
end
local function SetColor(tex,r,g,b,a)
    if type(tex.SetTexture)=="function" and
        type(tex.SetVertexColor)=="function" then
        tex:SetTexture("Interface\\Buttons\\WHITE8x8")
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
-- Forever's existing map addons use the 2010+ map-layer range.
-- A canvas+90 level (often ~220) can sit UNDER newer zone artwork while
-- the mouse target remains active, exactly as seen in the user's screenshot.
local function Raise(world,scroll,canvas)
    if not layer then return end
    local cv=Safe(canvas.GetFrameLevel,canvas)
    local wanted=math.max(2012,type(cv)=="number" and cv+2 or 2012)
    local om=rawget(_G,"OpenMapAPI")
    if type(om)=="table" and type(om.IsStitched)=="function"
        and type(om.ArtTopLevel)=="function" then
        local stitched=Safe(om.IsStitched)
        local top=stitched and Safe(om.ArtTopLevel)
        if type(top)=="number" then wanted=math.max(wanted,top+2) end
    end
    wanted=math.min(9000,wanted)
    if type(layer.SetFrameLevel)=="function" then
        if type(layer.SetFixedFrameLevel)=="function" then
            pcall(layer.SetFixedFrameLevel,layer,false)
        end
        layer:SetFrameLevel(wanted)
        if type(layer.SetFixedFrameLevel)=="function" then
            pcall(layer.SetFixedFrameLevel,layer,true)
        end
    end
    local strata=Safe(world.GetFrameStrata,world)
    if type(strata)=="string" and type(layer.SetFrameStrata)=="function" then
        layer:SetFrameStrata(strata)
    end
end
local function CanvasScale(scroll)
    local scale=scroll and Safe(scroll.GetCanvasScale,scroll)
    return type(scale)=="number" and scale>0 and scale or 1
end
local function Ensure()
    local map,scroll,canvas,id,w,h=State()
    if not map then
        currentProblem="map canvas not displayed"
        return nil
    end
    if not layer or layerCanvas~=canvas or layerParent~=canvas then
        if layer then layer:Hide() end
        -- Parent to the canvas itself: pins inherit panning, clipping and
        -- zoom exactly like tested Forever addons such as DonMap.
        layer=CreateFrame("Frame",nil,canvas)
        layerCanvas,layerParent=canvas,canvas
        layer:SetAllPoints(canvas)
        if type(layer.EnableMouse)=="function" then
            layer:EnableMouse(false)
        end
        flightMarkers,lootMarkers={},{}
        activeFlights,activeLoot=0,0
        lastView,lastW,lastH,lastScale=nil,nil,nil,nil
    end
    Raise(map,scroll,canvas)
    layer:Show()
    currentProblem="overlay attached to active map canvas"
    return id,w,h,CanvasScale(scroll)
end
local function Make(kind,index)
    local list=kind=="flight" and flightMarkers or lootMarkers
    local marker=list[index]
    if marker then return marker end
    marker=CreateFrame("Frame",nil,layer)
    marker.isFlight=kind=="flight"
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
local function Place(pin,x,y,w,h,scale)
    -- Keep marker size in screen pixels at all canvas zoom levels.
    scale=(type(scale)=="number" and scale>0) and scale or 1
    local base=pin.isFlight and 26 or 17
    pin:SetSize(base/scale,base/scale)
    local backSize=pin.isFlight and 19 or 17
    local faceSize=pin.isFlight and 15 or 13
    if pin.back then pin.back:SetSize(backSize/scale,backSize/scale) end
    if pin.face then pin.face:SetSize(faceSize/scale,faceSize/scale) end
    if pin.center then pin.center:SetSize(5/scale,5/scale) end
    local function Pixel(v)
        return math.floor(v*scale+0.5)/scale
    end
    pin:ClearAllPoints()
    pin:SetPoint("CENTER",layer,"TOPLEFT",Pixel(x*w),-Pixel(y*h))
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
local function RedrawFlights(id,w,h,scale)
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
            Place(pin,entry.x,entry.y,w,h,scale)
        end
    end
    HideAfter(flightMarkers,count)
    activeFlights=count
end
local function RedrawLoot(id,w,h,scale)
    local count=0
    for _,spot in ipairs(lootRecords) do
        local x,y=Project(spot.mapID,id,spot.x,spot.y)
        if x and count<20 then
            count=count+1
            local pin=Make("loot",count)
            Place(pin,x,y,w,h,scale)
        end
    end
    HideAfter(lootMarkers,count)
    activeLoot=count
end
function ChalkBox_MapNativeAvailable()
    return Ensure()~=nil
end
function ChalkBox_MapNativeRefresh()
    local id,w,h,scale=Ensure()
    if not id then
        activeFlights=0
        return false
    end
    RedrawFlights(id,w,h,scale)
    lastView,lastW,lastH,lastScale=id,w,h,scale
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
    local id,w,h,scale=Ensure()
    if not id then activeLoot=0;return false end
    RedrawLoot(id,w,h,scale)
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
    local id,w,h,scale=Ensure()
    if not id then
        activeFlights,activeLoot=0,0
        lastView,lastW,lastH,lastScale=nil,nil,nil,nil
        return
    end
    if id~=lastView or w~=lastW or h~=lastH or scale~=lastScale then
        RedrawFlights(id,w,h,scale)
        RedrawLoot(id,w,h,scale)
        lastView,lastW,lastH,lastScale=id,w,h,scale
    end
end)
