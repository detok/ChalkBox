-- Discoveries "Known Flight Paths": never reveal an unlearned location.
-- Verify taxi proof, per-character persistence, Blizzard Map Filter injection,
-- exact canvas positioning, zone projection and no native map mutations.
local allFrames={}
local function Frame(kind,name,parent)
    local f={kind=kind,name=name,parent=parent,shown=true,scripts={},hooks={}}
    function f:RegisterEvent(event) self.events=self.events or {};self.events[event]=true end
    function f:SetScript(name,func) self.scripts[name]=func end
    function f:HookScript(name,func) self.hooks[name]=func end
    function f:SetSize(w,h) self.w,self.h=w,h end
    function f:GetWidth() return self.w end
    function f:GetHeight() return self.h end
    function f:GetFrameLevel() return self.level or 20 end
    function f:SetFrameLevel(n) self.level=n end
    function f:GetFrameStrata() return self.strata or "MEDIUM" end
    function f:SetFrameStrata(name) self.strata=name end
    function f:SetPoint(...) self.point={...} end
    function f:ClearAllPoints() self.point=nil end
    function f:SetParent(p) self.parent=p end
    function f:EnableMouse() end
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:IsShown() return self.shown end
    function f:CreateTexture()
        local tex={parent=self,layer=select(2,...)}
        function tex:SetDrawLayer(layer,order)
            self.layer,self.order=layer,order
        end
        function tex:SetTexture(s) self.texture=s end
        function tex:SetAtlas(s,resize)
            self.atlas=s;self.resize=resize
        end
        function tex:SetVertexColor(...) self.color={...} end
        function tex:SetSize(w,h) self.w,self.h=w,h end
        function tex:SetPoint(...) self.point={...} end
        function tex:SetAllPoints() end
        return tex
    end
    allFrames[#allFrames+1]=f
    return f
end
_G.CreateFrame=Frame
_G.UIParent=Frame("Root","UIParent")
_G.ChalkBoxZoneDB={}
local taxiMap=1463
_G.GetTaxiMapID=function() return taxiMap end
local mapID=1436
local browseCalls=0
local calls=0
_G.C_Map={
    GetBestMapForUnit=function(unit) assert(unit=="player");return 1436 end,
    GetMapInfo=function(id)
        if id==1436 or id==1437 or id==1413 then
            return {mapType=3,id=id,name="Zone",
                parentMapID=id==1413 and 1414 or nil}
        end
        if id==1415 or id==1414 then
            return {mapType=2,id=id,name="Continent"}
        end
        return {mapType=2,id=id,name="Taxi"}
    end,
    GetPlayerMapPosition=function(id,unit)
        assert(id==1436 and unit=="player")
        return {GetXY=function() return .50,.50 end}
    end,
    GetMapRectOnMap=function(zone,top)
        if zone==1436 and top==1463 then
            return .20,.60,.20,.60
        end
    end,
}
_G.C_Texture={GetAtlasInfo=function(atlas)
    if atlas=="TaxiNode_Alliance" or atlas=="TaxiNode_Horde" or
        atlas=="TaxiNode_Neutral" then return {atlas=atlas} end
end}
local points={
    {nodeID=7,name="Visited Hub",state=0,
        position={GetXY=function() return .30,.30 end},
        isUndiscovered=true},
    {nodeID=8,name="Known Destination",state=1,
        position={GetXY=function() return .45,.50 end}},
    {nodeID=9,name="Not Learned",state=2,
        position={GetXY=function() return .49,.49 end},
        isUndiscovered=false},
}
_G.C_TaxiMap={
    GetAllTaxiNodes=function(id)
        calls=calls+1
        assert(id==1463)
        return points
    end,
    ShouldMapShowTaxiNodes=function(id) return id==1415 end,
    GetTaxiNodesForMap=function(id)
        browseCalls=browseCalls+1
        if id==1413 then
            -- Screenshot regression: zone Barrens shows Ratchet known FP
            -- even though Blizzard does NOT show taxi nodes via map filter.
            return {
                {nodeID=8,position={GetXY=function() return .72,.31 end},
                    atlasName="TaxiNode_Neutral",faction=0},
                {nodeID=9,position={GetXY=function() return .69,.34 end},
                    atlasName="TaxiNode_Horde",faction=1},
            }
        elseif id==1436 then
            return {
                {nodeID=8,position={GetXY=function() return .70,.60 end},
                    atlasName="TaxiNode_Alliance",faction=2},
                {nodeID=9,position={GetXY=function() return .55,.45 end},
                    atlasName="TaxiNode_Horde",faction=1},
            }
        elseif id==1437 then return {}
        elseif id==1414 then return {} end
        assert(id==1415)
        return {
            {nodeID=7,position={GetXY=function() return .1,.2 end}},
            {nodeID=8,position={GetXY=function() return .4,.5 end}},
            {nodeID=9,position={GetXY=function() return .6,.7 end}},
        }
    end,
}
local menuAdded,checkbox,menuHook=0
_G.Menu={
    ModifyMenu=function(tag,callback)
        menuAdded=menuAdded+1
        assert(tag=="MENU_WORLD_MAP_TRACKING",
            "only modify Blizzard's World Map Filter dropdown")
        menuHook=callback
    end
}
local tooltipLines={}
_G.GameTooltip={
    SetOwner=function() end,
    AddLine=function(_,s) tooltipLines[#tooltipLines+1]=s end,
    Show=function() end,
    Hide=function() end,
}
assert(loadfile("DiscoveriesFlights.lua"))("ChalkBox")
assert(menuAdded==1 and type(menuHook)=="function",
    "standard Blizzard menu extension registers once")
local function OpenFilter()
    checkbox=nil
    local root={
        CreateDivider=function(self) self.dividers=(self.dividers or 0)+1 end,
        CreateCheckbox=function(_,label,checked,toggle)
            checkbox={label=label,checked=checked,toggle=toggle,
                SetSelectionIgnored=function(self) self.ignored=true end}
            return checkbox
        end,
    }
    menuHook({},root,{})
    assert(root.dividers==1 and checkbox and checkbox.ignored
        and checkbox.label=="Known Flight Paths (ChalkBox)",
        "only append one native style checkbox")
end
OpenFilter()
assert(checkbox.checked() and ChalkBox_DiscoveriesKnownFlightsStatus().verified==0,
    "new character has zero verified paths, not all possible locations")
local loader
for _,f in ipairs(allFrames) do
    if f.scripts.OnEvent and f.scripts.OnUpdate then loader=f end
end
assert(loader and loader.events.TAXIMAP_OPENED)
local before=ChalkBoxZoneDB.discoveriesKnownFlights
loader.scripts.OnEvent(loader,"TAXIMAP_OPENED")
assert(calls>=1 and ChalkBox_DiscoveriesKnownFlightsStatus().verified==2
    and before.nodes["7"] and before.nodes["8"] and not before.nodes["9"],
    "CURRENT + REACHABLE only; isUndiscovered=false does not unlock unknown")
assert(before.nodes["7"].zoneMapID==1436
    and before.nodes["7"].zoneX==5000
    and before.nodes["7"].zoneY==5000,
    "player's exact CURRENT flight-master zone position is saved")
local revision=before.revision
loader.scripts.OnUpdate(loader,1)
loader.scripts.OnUpdate(loader,1)
loader.scripts.OnUpdate(loader,1)
assert(before.revision==revision,
    "repeated taxi event delivery does not churn saved records")
local world=Frame("Frame","WorldMapFrame",UIParent)
_G.WorldMapFrame=world
function world:GetMapID() return mapID end
local scroll=Frame("Frame","Scroll",world)
local canvas=Frame("Frame","MapCanvas",scroll)
canvas:SetSize(900,600)
scroll.Child=canvas
world.ScrollContainer=scroll
loader.scripts.OnUpdate(loader,1)
local status=ChalkBox_DiscoveriesKnownFlightsStatus()
assert(status.mapID==1436 and status.mapPins==2 and
    status.directPositions==1 and status.observedPositions==1,
    "zone maps render learned nodes from zone-local positions even when taxi map filters are false")
local drawn={}
for _,f in ipairs(allFrames) do
    if f.parent==canvas and f.flightName and f.shown then
        drawn[f.flightName]=f
    end
end
assert(drawn["Visited Hub"] and drawn["Known Destination"] and
    not drawn["Not Learned"],"no unlearned marker appears on the map")
assert(drawn["Known Destination"].icon and
    drawn["Known Destination"].icon.atlas=="TaxiNode_Alliance" and
    drawn["Known Destination"].icon.texture~=
        "Interface\\Buttons\\WHITE8X8",
    "a known Alliance flight master uses Blizzard's winged-boot atlas, not squares")
assert(drawn["Visited Hub"].icon and
    drawn["Visited Hub"].icon.atlas=="TaxiNode_Neutral",
    "a known node without a reported faction uses native neutral flight master art")
local pin=drawn["Visited Hub"]
assert(pin.point and pin.point[1]=="CENTER" and
    pin.point[2]==canvas and pin.point[4]==450 and pin.point[5]==-300,
    "observed CURRENT flight master is placed on exact zone coordinates")
assert(drawn["Visited Hub"].icon.layer=="OVERLAY" and
    drawn["Visited Hub"].icon.order==7 and
    drawn["Visited Hub"].level>=80 and
    drawn["Visited Hub"].w==24 and drawn["Visited Hub"].h==24,
    "local flight boot renders above zone map art instead of hidden ARTWORK")
-- Forever can dynamically raise the local tile layer after the pin is
-- built, while leaving mapID/width/height unchanged.
canvas.level=170
loader.scripts.OnUpdate(loader,1)
assert(drawn["Visited Hub"].level>=230,
    "existing visible zone pin relayers after local tile levels change")
drawn["Visited Hub"].scripts.OnEnter(drawn["Visited Hub"])
assert(tooltipLines[1]=="Visited Hub" and tooltipLines[2]=="Known flight path",
    "pin tooltip confirms only verified nodes")
drawn["Visited Hub"].scripts.OnLeave()
checkbox.toggle()
loader.scripts.OnUpdate(loader,1)
assert(not checkbox.checked() and
    ChalkBox_DiscoveriesKnownFlightsStatus().mapPins==0 and
    Count==nil, "native checkbox immediately hides only addon markers")
assert(before.nodes["7"] and before.nodes["8"],
    "visibility toggle never removes known history")
checkbox.toggle()
loader.scripts.OnUpdate(loader,1)
assert(ChalkBox_DiscoveriesKnownFlightsStatus().mapPins==2,
    "checkbox restores the two known pins")
-- Actual failing reported view: Ratchet in The Barrens, known node 8
-- stored through a previous taxi visit but no stored current-zone XY.
-- It must draw with GetTaxiNodesForMap(zone) without trusting the unknown 9.
mapID=1413
loader.scripts.OnUpdate(loader,1)
local ratchet=ChalkBox_DiscoveriesKnownFlightsStatus()
assert(ratchet.mapPins==1 and ratchet.directPositions==1 and
    ratchet.verified==2 and ratchet.unplacedNodes==1,
    "Barrens displays known Ratchet-style node without exposing unknown node")
local ratchetPin
for _,f in ipairs(allFrames) do
    if f.parent==canvas and f.shown and
        f.flightName=="Known Destination" then ratchetPin=f end
end
assert(ratchetPin and ratchetPin.point[4]==648 and
    ratchetPin.point[5]==-186,
    "known Ratchet-style map-local position uses exact zone canvas geometry")
assert(ratchetPin.icon.atlas=="TaxiNode_Neutral" and
    ratchetPin.icon.layer=="OVERLAY" and
    ratchetPin.level>=230 and not drawn["Not Learned"],
    "Ratchet uses the raised winged-boot overlay and still excludes unknown FP")
mapID=1437
loader.scripts.OnUpdate(loader,1)
assert(ChalkBox_DiscoveriesKnownFlightsStatus().mapPins==0,
    "zone with no verified coordinates is empty, not mapped with false positions")
mapID=1415
loader.scripts.OnUpdate(loader,1)
assert(ChalkBox_DiscoveriesKnownFlightsStatus().mapPins==2 and
    browseCalls>0, "continent can use map node coordinates only for learned IDs")
mapID=1436
loader.scripts.OnUpdate(loader,1)
world:Hide()
loader.scripts.OnUpdate(loader,1)
assert(ChalkBox_DiscoveriesKnownFlightsStatus().mapPins==0,
    "closed map hides markers and never touches native map navigation")
world:Show()
local first=ChalkBoxZoneDB
_G.ChalkBoxZoneDB={}
loader.scripts.OnUpdate(loader,1)
assert(ChalkBox_DiscoveriesKnownFlightsStatus().verified==0 and
    ChalkBox_DiscoveriesKnownFlightsStatus().mapPins==0,
    "other character cannot inherit this character's flight discoveries")
_G.ChalkBoxZoneDB=first
loader.scripts.OnUpdate(loader,1)
assert(ChalkBox_DiscoveriesKnownFlightsStatus().verified==2,
    "reloading the correct character's DB restores confirmed discoveries")
local old=ChalkBoxZoneDB.discoveriesKnownFlights
ChalkBoxZoneDB.discoveriesKnownFlights={version=100,nodes={protected=true}}
loader.scripts.OnUpdate(loader,1)
assert(not ChalkBox_DiscoveriesKnownFlightsStatus().enabled and
    ChalkBoxZoneDB.discoveriesKnownFlights.version==100,
    "unknown newer data schema is retained intact rather than reset")
ChalkBoxZoneDB.discoveriesKnownFlights=old
assert(menuAdded==1,"menu hooks must never be registered twice")
print("PASS: Discoveries flight proof-only nodes, Blizzard Map Filter checkbox, exact/projection map positions, unknown exclusion, character isolation, version protection")
