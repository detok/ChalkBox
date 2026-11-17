-- ChalkBox unified map marker renderer: exercise actual marker frames, not
-- an invented MapCanvas AcquirePin stub that can pass without painting art.
_G.ChalkBoxZoneDB={}
local frames={}
local function Frame(parent)
    local f={parent=parent,visible=true,scripts={},strata="FULLSCREEN_DIALOG",
        level=20}
    function f:SetScript(n,fn) self.scripts[n]=fn end
    function f:SetSize(w,h) self.w,self.h=w,h end
    function f:GetWidth() return self.w end
    function f:GetHeight() return self.h end
    function f:SetAllPoints(target) self.all=target end
    function f:SetPoint(...) self.point={...} end
    function f:ClearAllPoints() self.point=nil end
    function f:SetFrameLevel(v) self.level=v end
    function f:SetFixedFrameLevel(v) self.fixed=v end
    function f:GetFrameLevel() return self.level end
    function f:GetFrameStrata() return self.strata end
    function f:SetFrameStrata(v) self.strata=v end
    function f:EnableMouse(v) self.mouse=v end
    function f:Show() self.visible=true end
    function f:Hide() self.visible=false end
    function f:IsShown() return self.visible end
    function f:CreateTexture(_,layer)
        local t={layer=layer}
        function t:SetDrawLayer(l,o) self.layer,self.order=l,o end
        function t:SetSize(w,h) self.w,self.h=w,h end
        function t:SetPoint(...) self.point={...} end
        function t:SetAllPoints(v) self.all=v end
        function t:SetTexture(v) self.texture=v end
        function t:SetVertexColor(...) self.color={...} end
        function t:SetColorTexture(...) self.color={...} end
        function t:SetAtlas(v) self.atlas=v;return true end
        return t
    end
    frames[#frames+1]=f
    return f
end
_G.CreateFrame=function(_,__,parent) return Frame(parent) end
local world=Frame()
local scroll=Frame(world)
local canvas=Frame(scroll)
canvas:SetSize(800,600)
scroll.Child=canvas
local scale=1
function scroll:GetCanvasScale() return scale end
world.ScrollContainer=scroll
local viewed=1434
function world:GetMapID() return viewed end
function world:GetCanvas() return canvas end
function world:AcquirePin() error("native pin factory must not be used") end
_G.WorldMapFrame=world
_G.C_Map={
    GetMapInfo=function(id)
        if id==1434 then return {mapType=3,parentMapID=13} end
        if id==999 then return {mapType=5,parentMapID=1434} end
        if id==13 then return {mapType=2,parentMapID=947} end
    end,
    GetMapRectOnMap=function(child,parent)
        if child==999 and parent==1434 then return .2,.6,.2,.6 end
    end,
}
_G.C_Texture={GetAtlasInfo=function() return {valid=true} end}
local flightCalls=0
_G.ChalkBox_DiscoveriesFlightCandidates=function(id)
    flightCalls=flightCalls+1
    if id==1434 then return {
        {x=.3,y=.4,name="Booty Bay",atlas="TaxiNode_Alliance"},
    } end
    if id==999 then return {
        {x=.25,y=.5,name="Booty Bay",atlas="TaxiNode_Alliance"},
    } end
    return {}
end
local hover={}
_G.GameTooltip={
    SetOwner=function() end,
    AddLine=function(_,s) hover[#hover+1]=s end,
    Show=function() end,
    Hide=function() end,
}
assert(loadfile("MapNativePins.lua"))("ChalkBox")
assert(ChalkBox_MapNativeAvailable(),"map overlay attaches to visible map")
assert(ChalkBox_MapNativeRefresh(),"visible local flight markers refresh")
local status=ChalkBox_MapNativeStatus()
assert(status.available and status.renderer=="map-owned overlay" and
    status.mapID==1434 and status.flightPins==1,
    "one learned flight on the current zone, not every worldwide path")
local overlay,flight
for _,f in ipairs(frames) do
    if f.parent==canvas and f.all==canvas then overlay=f end
end
assert(overlay and overlay.level>=2012 and overlay.mouse==false
    and overlay.fixed==true,
    "pins use Forever-proven map canvas parent and a fixed 2012+ level")
for _,f in ipairs(frames) do
    if f.parent==overlay and f.flightName=="Booty Bay" and f.visible then
        flight=f
    end
end
assert(flight and flight.point[2]==overlay and flight.point[4]==240
    and flight.point[5]==-240,
    "the actual displayed boot frame follows normalized map coordinates")
assert(flight.back.texture=="Interface\\Buttons\\WHITE8x8"
    and flight.face.texture=="Interface\\Buttons\\WHITE8x8"
    and flight.face.color[4]==1 and flight.icon.atlas=="TaxiNode_Alliance",
    "flight marker has visible colored pixels even if Taxi atlas paints blank")
flight.scripts.OnEnter(flight)
assert(hover[1]=="Booty Bay" and hover[2]=="Known flight path",
    "the flight tooltip belongs to the same visible frame")
assert(ChalkBox_MapNativeLootSetMany(1434,{
    {x=.30,y=.40},{x=.35,y=.45},
}),"multiple recorded positions appear on the local zone map")
status=ChalkBox_MapNativeStatus()
assert(status.flightPins==1 and status.lootPins==2 and status.pinCount==3,
    "loot overlays coexist with flights and display every item location")
local count=0
for _,f in ipairs(frames) do
    if f.parent==overlay and f.mouse==false and f.visible and f.center then
        count=count+1
        assert(f.face.texture=="Interface\\Buttons\\WHITE8x8"
            and f.center.texture=="Interface\\Buttons\\WHITE8x8",
            "loot markers paint real, opaque pixel-backed textures")
    end
end
assert(count==2,"two separate marker frames displayed")
-- Pan/resize/zone-switch: real map canvas owns the markers.
canvas:SetSize(1000,750)
scale=2
for _,f in ipairs(frames) do
    if f.scripts.OnUpdate then f.scripts.OnUpdate(f,0.3) end
end
assert(flight.point[4]==300 and flight.point[5]==-300
    and flight.w==13 and flight.face.w==7.5,
    "canvas zoom resizes the marker to constant screen pixels without moving its map position")
viewed=999
for _,f in ipairs(frames) do
    if f.scripts.OnUpdate then f.scripts.OnUpdate(f,0.3) end
end
status=ChalkBox_MapNativeStatus()
assert(status.flightPins==1 and status.lootPins==2,
    "saved parent-zone positions project into viewed child map")
assert(flight.point[4]==250 and flight.point[5]==-375,
    "zoomed-in local flight coordinate is placed at child map position")
assert(math.abs(ChalkBox_MapNativeProject(1434,999,.3,.4)-.25)<.000001)
assert(ChalkBox_MapNativeProject(1434,999,.9,.4)==nil,
    "out-of-child locations are not invented")
ChalkBox_MapNativeLootClear()
assert(ChalkBox_MapNativeStatus().lootPins==0 and
    ChalkBox_MapNativeStatus().flightPins==1,
    "leaving a Discoveries item hides only its temporary pins")
viewed=13
for _,f in ipairs(frames) do
    if f.scripts.OnUpdate then f.scripts.OnUpdate(f,0.3) end
end
assert(ChalkBox_MapNativeStatus().flightPins==0,
    "unrelated maps never retain stale flight pins")
-- The client's world-coordinate API converts positions between maps even
-- when no parent/child rectangle exists (same pattern used by Forever DonMap).
_G.CreateVector2D=function(x,y) return {GetXY=function() return x,y end} end
C_Map.GetWorldPosFromMapPos=function(map,pos)
    if map~=1434 then return nil end
    local x,y=pos:GetXY()
    return 13,{GetXY=function() return x*1000,y*1000 end}
end
C_Map.GetMapPosFromWorldPos=function(cont,world,target)
    if cont~=13 or target~=1437 then return nil end
    local x,y=world:GetXY()
    return target,{GetXY=function() return x/2000,y/2000 end}
end
local wx,wy=ChalkBox_MapNativeProject(1434,1437,.3,.4)
assert(wx and math.abs(wx-.15)<.000001 and math.abs(wy-.2)<.000001,
    "world conversion finds location on a different valid local zone map")
assert(flightCalls>=3,"map changes refresh the candidate directory")
print("PASS: shared raised overlay, visible flight art, all loot locations, child projection, canvas resizing, independent hover cleanup and map changes")
