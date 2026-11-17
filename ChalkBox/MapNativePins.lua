-- ChalkBox World Map drawing: let Blizzard's native MapCanvas position pins.
-- This module owns *rendering only*. DropSense owns recorded loot coordinates;
-- DiscoveriesFlights owns which flight paths were personally confirmed.
-- No external library, copied pin code, saved-variable migration or map writes.
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

local pinMixin
local function BuildPinMixin()
    if pinMixin or type(MapCanvasPinMixin)~="table" or
        type(CreateFromMixins)~="function" then return pinMixin end
    pinMixin=CreateFromMixins(MapCanvasPinMixin)
    function pinMixin:OnLoad()
        self:SetSize(24,24)
        if type(self.UseFrameLevelType)=="function" then
            self:UseFrameLevelType("PIN_FRAME_LEVEL_TOPMOST")
        end
        if type(self.SetScalingLimits)=="function" then
            self:SetScalingLimits(1,1,1.2)
        end
        if type(self.SetMouseClickEnabled)=="function" then
            self:SetMouseClickEnabled(false)
        end
        if type(self.SetMouseMotionEnabled)=="function" then
            self:SetMouseMotionEnabled(true)
        end
        self.glyph=self:CreateTexture(nil,"OVERLAY")
        self.glyph:SetAllPoints(self)
        self.ring=self:CreateTexture(nil,"OVERLAY")
        self.ring:SetSize(17,17)
        self.ring:SetPoint("CENTER",self,"CENTER",0,0)
        self.center=self:CreateTexture(nil,"OVERLAY")
        self.center:SetSize(6,6)
        self.center:SetPoint("CENTER",self,"CENTER",0,0)
    end
    function pinMixin:OnAcquired(kind,x,y,name,atlas)
        self.kind,self.flightName=kind,name
        self.clock=0
        -- Native SetPosition routes through the map's zoom-aware canvas.
        self:SetPosition(x,y)
        if type(self.SetMouseMotionEnabled)=="function" then
            self:SetMouseMotionEnabled(kind=="flight")
        end
        if kind=="flight" then
            self:SetSize(24,24)
            self.glyph:Show()
            self.ring:Hide()
            self.center:Hide()
            local chosen=atlas or "TaxiNode_Neutral"
            local atlasOK=false
            if type(self.glyph.SetAtlas)=="function" then
                local ok,result=pcall(self.glyph.SetAtlas,self.glyph,chosen,false)
                atlasOK=ok and result~=false
            end
            if not atlasOK and type(self.glyph.SetTexture)=="function" then
                self.glyph:SetTexture("Interface\\Minimap\\Tracking\\FlightMaster")
            end
            self:SetScript("OnUpdate",nil)
        else
            self:SetSize(20,20)
            self.glyph:Hide()
            self.ring:Show()
            self.center:Show()
            self.ring:SetColorTexture(1,0.70,0.27,0.66)
            self.center:SetColorTexture(1,0.96,0.74,1)
            self:SetScript("OnUpdate",function(pin,dt)
                if type(dt)~="number" or dt<0 then return end
                pin.clock=(pin.clock+dt)%1.3
                if pin.ring and type(pin.ring.SetAlpha)=="function" then
                    pin.ring:SetAlpha(0.24+0.64*math.abs(
                        math.sin(pin.clock/1.3*math.pi)))
                end
            end)
        end
    end
    function pinMixin:OnMouseEnter()
        if self.kind~="flight" or not GameTooltip then return end
        if type(GameTooltip.SetOwner)=="function" and
            type(GameTooltip.AddLine)=="function" then
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:AddLine(self.flightName or "Flight master",1,0.81,0.45)
            GameTooltip:AddLine("Known flight path",0.50,0.90,0.67)
            GameTooltip:Show()
        end
    end
    function pinMixin:OnMouseLeave()
        if self.kind=="flight" and GameTooltip then GameTooltip:Hide() end
    end
    function pinMixin:OnReleased()
        self.kind,self.flightName=nil,nil
        self:SetScript("OnUpdate",nil)
    end
    return pinMixin
end
local function InitProvider(map)
    if provider then return true end
    if type(CreateFromMixins)~="function" or
        type(MapCanvasDataProviderMixin)~="table" or
        not BuildPinMixin() or type(Mixin)~="function" or
        type(CreateFramePool)~="function" or type(map.GetCanvas)~="function"
        or type(map.AddDataProvider)~="function" or
        type(map.AcquirePin)~="function" or
        type(map.RemoveAllPinsByTemplate)~="function" or
        type(map.pinPools)~="table" then
        lastProblem="native MapCanvas pin API unavailable"
        return false
    end
    local canvas=Call(map.GetCanvas,map)
    if not canvas then
        lastProblem="native map canvas not ready"
        return false
    end
    -- Separate native pools prevent rapid loot-row hover from rebuilding
    -- the flight markers or making their artwork flicker.
    local function NewPool()
        local ok,newPool=pcall(CreateFramePool,"FRAME")
        if not ok or type(newPool)~="table" then return nil end
        newPool.parent=canvas
        newPool.createFunc=function()
            local frame=CreateFrame("Frame",nil,canvas)
            frame:SetSize(24,24)
            return Mixin(frame,pinMixin)
        end
        newPool.creationFunc=newPool.createFunc
        newPool.resetFunc=function(_,pin)
            pin:Hide()
            pin:ClearAllPoints()
            pin:OnReleased()
            pin.pinTemplate=nil
            if type(pin.SetOwningMap)=="function" then
                pin:SetOwningMap(nil)
            end
        end
        newPool.resetterFunc=newPool.resetFunc
        return newPool
    end
    local fp,lp=NewPool(),NewPool()
    if not fp or not lp then
        lastProblem="native frame pools unavailable"
        return false
    end
    local p=CreateFromMixins(MapCanvasDataProviderMixin)
    function p:RemoveAllData()
        local owning=self:GetMap()
        if owning then
            owning:RemoveAllPinsByTemplate(FLIGHT_TEMPLATE)
            owning:RemoveAllPinsByTemplate(LOOT_TEMPLATE)
        end
        markerCount,flightCount,lootCount=0,0,0
    end
    function p:RefreshFlights()
        local owning=self:GetMap()
        if not owning then return end
        owning:RemoveAllPinsByTemplate(FLIGHT_TEMPLATE)
        flightCount=0
        local viewed=MapID(owning)
        local discovered=viewed and
            type(ChalkBox_DiscoveriesFlightCandidates)=="function"
            and ChalkBox_DiscoveriesFlightCandidates(viewed) or {}
        for i=1,math.min(#discovered,80) do
            local entry=discovered[i]
            if entry and Number(entry.x) and Number(entry.y) then
                if nativeBroken then break end
                local good,pin=pcall(owning.AcquirePin,owning,FLIGHT_TEMPLATE,
                    "flight",entry.x,entry.y,entry.name,entry.atlas)
                if good and pin then
                    flightCount=flightCount+1
                else
                    nativeBroken=true
                    lastProblem="native flight pin acquisition unsupported"
                    owning:RemoveAllPinsByTemplate(FLIGHT_TEMPLATE)
                    flightCount=0
                end
            end
        end
        markerCount=flightCount+lootCount
    end
    function p:RefreshLoot()
        local owning=self:GetMap()
        if not owning then return end
        owning:RemoveAllPinsByTemplate(LOOT_TEMPLATE)
        lootCount=0
        local viewed=MapID(owning)
        if viewed and transientLoot then
            local x,y=Project(transientLoot.mapID,viewed,
                transientLoot.x,transientLoot.y)
            if x then
                local good,pin=pcall(owning.AcquirePin,owning,LOOT_TEMPLATE,
                    "loot",x,y)
                if good and pin then
                    lootCount=1
                else
                    nativeBroken=true
                    lastProblem="native loot pin acquisition unsupported"
                    owning:RemoveAllPinsByTemplate(LOOT_TEMPLATE)
                end
            end
        end
        markerCount=flightCount+lootCount
    end
    function p:RefreshAllData()
        self:RefreshFlights()
        self:RefreshLoot()
    end
    map.pinPools[FLIGHT_TEMPLATE],map.pinPools[LOOT_TEMPLATE]=fp,lp
    local registered=pcall(map.AddDataProvider,map,p)
    if not registered then
        map.pinPools[FLIGHT_TEMPLATE],map.pinPools[LOOT_TEMPLATE]=nil,nil
        lastProblem="native data provider registration failed"
        return false
    end
    flightPool,lootPool,provider=fp,lp,p
    lastProblem="native MapCanvas provider installed"
    return true
end
local function Ensure()
    if nativeBroken then return false end
    if provider then return true end
    local map=WorldMapFrame
    if not map then return false end
    return InitProvider(map)
end
function ChalkBox_MapNativeAvailable()
    return Ensure()
end
function ChalkBox_MapNativeRefresh()
    if refreshBusy or not Ensure() then return false end
    refreshBusy=true
    local ok=pcall(provider.RefreshFlights,provider)
    refreshBusy=false
    if not ok then
        lastProblem="native map marker refresh failed"
    end
    return ok and not nativeBroken
end
function ChalkBox_MapNativeLootSet(mapID,x,y)
    if type(mapID)~="number" or not Number(x) or not Number(y) then
        return false
    end
    if not Ensure() then return false end
    transientLoot={mapID=mapID,x=x,y=y}
    local ok=pcall(provider.RefreshLoot,provider)
    if not ok then lastProblem="native loot marker refresh failed" end
    return ok and not nativeBroken
end
function ChalkBox_MapNativeLootClear()
    if not transientLoot then return end
    transientLoot=nil
    if provider then pcall(provider.RefreshLoot,provider) end
end
function ChalkBox_MapNativeStatus()
    return {available=provider~=nil and not nativeBroken,
        mapID=MapID(WorldMapFrame),pinCount=markerCount,
        flightPins=flightCount,lootPins=lootCount,
        problem=lastProblem,loot=transientLoot~=nil}
end
-- The MapCanvas provider handles map changes, panning and zoom natively.
-- Retry installation only while Blizzard's lazily loaded map is missing.
local loader=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","ADDON_LOADED","PLAYER_ENTERING_WORLD"}) do
    pcall(loader.RegisterEvent,loader,event)
end
loader:SetScript("OnEvent",function() Ensure() end)
loader:SetScript("OnUpdate",function(_,elapsed)
    if provider then
        loader:SetScript("OnUpdate",nil)
        return
    end
    mapRetry=mapRetry+(type(elapsed)=="number" and elapsed or 0)
    if mapRetry>=1 then mapRetry=0;Ensure() end
end)
Ensure()
