-- MapCanvas native marker integration. No actual WoW client required.
_G.ChalkBoxZoneDB={}
_G.C_Map={
    GetMapInfo=function(id)
        if id==1436 then return {id=id,mapType=3,parentMapID=13} end
        if id==999 then return {id=id,mapType=5,parentMapID=1436} end
        if id==13 then return {id=id,mapType=2,parentMapID=947} end
        if id==1413 then return {id=id,mapType=3,parentMapID=13} end
    end,
    GetMapRectOnMap=function(child,parent)
        if child==999 and parent==1436 then return .20,.60,.20,.60 end
    end,
}
local world,allFrames,pools={}, {},{}
local function Texture()
    return {
        SetAllPoints=function() end,SetSize=function() end,
        SetPoint=function() end,
        SetAtlas=function(self,atlas) self.atlas=atlas end,
        SetTexture=function(self,v) self.texture=v end,
        SetColorTexture=function(self,...) self.color={...} end,
        SetAlpha=function(self,v) self.alpha=v end,
        Show=function(self) self.shown=true end,
        Hide=function(self) self.shown=false end,
    }
end
local function Frame(parent)
    local f={parent=parent,scripts={},visible=true}
    function f:RegisterEvent() end
    function f:SetScript(name,callback) self.scripts[name]=callback end
    function f:SetSize(w,h) self.width,self.height=w,h end
    function f:CreateTexture() return Texture() end
    function f:Hide() self.visible=false end
    function f:Show() self.visible=true end
    function f:ClearAllPoints() self.anchor=nil end
    function f:SetPoint(...) self.anchor={...} end
    function f:SetOwningMap(map) self.owningMap=map end
    function f:SetFrameLevel(level) self.level=level end
    function f:UseFrameLevelType(t) self.levelType=t end
    function f:SetScalingLimits(...) self.limits={...} end
    function f:SetMouseClickEnabled(value) self.click=value end
    function f:SetMouseMotionEnabled(value) self.motion=value end
    function f:GetMap() return self.owningMap end
    allFrames[#allFrames+1]=f
    return f
end
_G.CreateFrame=function(_,__,parent) return Frame(parent) end
_G.MapCanvasPinMixin={
    SetPosition=function(self,x,y)
        assert(x>=0 and x<=1 and y>=0 and y<=1)
        self.position={x,y}
    end
}
_G.MapCanvasDataProviderMixin={
    OnAdded=function(self,map) self.map=map end,
    GetMap=function(self) return self.map end,
    OnMapChanged=function(self) self:RefreshAllData() end,
}
_G.CreateFromMixins=function(base)
    local t={}
    for key,value in pairs(base) do t[key]=value end
    return t
end
_G.Mixin=function(obj,mixin)
    for key,value in pairs(mixin) do obj[key]=value end
    return obj
end
_G.CreateFramePool=function(kind)
    assert(kind=="FRAME")
    local pool={used={},available={}}
    function pool:Acquire()
        local frame=table.remove(self.available)
        local isNew=frame==nil
        frame=frame or self.createFunc()
        self.used[#self.used+1]=frame
        return frame,isNew
    end
    function pool:ReleaseAll()
        while #self.used>0 do
            local frame=table.remove(self.used)
            self.resetFunc(self,frame)
            self.available[#self.available+1]=frame
        end
    end
    pools[#pools+1]=pool
    return pool
end
local mapID=1436
local canvas=Frame()
world.pinPools={}
function world:GetMapID() return mapID end
function world:GetCanvas() return canvas end
function world:AddDataProvider(provider)
    self.provider=provider
    provider:OnAdded(self)
end
function world:AcquirePin(template,...)
    assert(template=="ChalkBoxNativeFlightMarker" or
        template=="ChalkBoxNativeLootMarker")
    local pool=self.pinPools[template]
    local pin,isNew=pool:Acquire()
    pin.pinTemplate=template
    pin:SetOwningMap(self)
    if isNew then pin:OnLoad() end
    pin:Show()
    pin:OnAcquired(...)
    return pin
end
function world:RemoveAllPinsByTemplate(template)
    self.pinPools[template]:ReleaseAll()
end
_G.WorldMapFrame=world
local captured=0
local flights={
    {x=.3,y=.6,atlas="TaxiNode_Alliance",name="Known Flight"},
    {x=.7,y=.8,atlas="TaxiNode_Neutral",name="Visited Flight"},
}
_G.ChalkBox_DiscoveriesFlightCandidates=function(mapID)
    captured=captured+1
    return mapID==1436 and flights or {}
end
assert(loadfile("MapNativePins.lua"))("ChalkBox")
assert(ChalkBox_MapNativeAvailable(),"native provider installs on available modern map")
assert(world.provider and #pools==2 and
    ChalkBox_MapNativeStatus().available)
assert(ChalkBox_MapNativeRefresh())
assert(#pools[1].used==2 and #pools[2].used==0 and
    ChalkBox_MapNativeStatus().pinCount==2,
    "two native flight pins acquired, not independent canvas frames")
local byName={}
for _,pin in ipairs(pools[1].used) do byName[pin.flightName]=pin end
assert(byName["Known Flight"] and byName["Known Flight"].position[1]==.3
    and byName["Known Flight"].glyph.atlas=="TaxiNode_Alliance"
    and byName["Known Flight"].levelType=="PIN_FRAME_LEVEL_TOPMOST",
    "native SetPosition and native map pin level used")
assert(byName["Visited Flight"] and
    byName["Visited Flight"].glyph.atlas=="TaxiNode_Neutral",
    "preserve Blizzard's flight icon")
assert(ChalkBox_MapNativeProject(1436,1436,.5,.6)==.5)
local x,y=ChalkBox_MapNativeProject(1436,999,.30,.30)
assert(math.abs(x-.25)<0.000001 and math.abs(y-.25)<0.000001,
    "child/micro map projection uses client-supplied rectangle")
assert(ChalkBox_MapNativeProject(1436,999,.90,.30)==nil,
    "no marker when actual loot position is outside displayed micro map")
assert(ChalkBox_MapNativeProject(1436,1413,.30,.30)==nil,
    "never transpose unrelated zone coordinates")
assert(ChalkBox_MapNativeProject(1436,13,.30,.30)==nil,
    "no invented parent/continent position for loot")
assert(ChalkBox_MapNativeLootSet(1436,.3,.3))
assert(pools[1].used[1]==byName["Known Flight"] or
    pools[1].used[2]==byName["Known Flight"],
    "hovering a loot row must not rebuild or flicker the flight pins")
assert(#pools[1].used==2 and #pools[2].used==1 and
    ChalkBox_MapNativeStatus().loot and
    ChalkBox_MapNativeStatus().pinCount==3,
    "one temporary native loot pin coexists with verified flights")
local loot
for _,pin in ipairs(pools[2].used) do
    if pin.kind=="loot" then loot=pin end
end
assert(loot and loot.position[1]==.3
    and loot.position[2]==.3
    and loot.glyph.shown==false and loot.ring.shown==true
    and not loot.motion,
    "loot dot drawn natively and does not eat map mouse input")
mapID=999
world.provider:OnMapChanged()
assert(#pools[1].used==0 and #pools[2].used==1
    and pools[2].used[1].kind=="loot",
    "native map changes remove flight pins that are not on this map")
assert(math.abs(pools[2].used[1].position[1]-.25)<.000001,
    "native map changes project the loot dot without reanchoring map frames")
mapID=1413
world.provider:OnMapChanged()
assert(#pools[1].used==0 and #pools[2].used==0,
    "unrelated zone gets no marker")
mapID=1436
world.provider:OnMapChanged()
assert(#pools[1].used==2 and #pools[2].used==1,
    "returning to the zone restores native pins without resetting saved data")
ChalkBox_MapNativeLootClear()
assert(#pools[1].used==2 and #pools[2].used==0
    and not ChalkBox_MapNativeStatus().loot,
    "mouse leave removes only the temporary loot data")
table.remove(flights,2)
assert(ChalkBox_MapNativeRefresh())
assert(#pools[1].used==1,
    "new flight discovery state can rerender without stale cache")
assert(ChalkBox_MapNativeStatus().problem=="native MapCanvas provider installed")
world.AcquirePin=function() error("native pin is not supported on this fork") end
assert(not ChalkBox_MapNativeRefresh() and
    not ChalkBox_MapNativeAvailable() and
    not ChalkBox_MapNativeStatus().available,
    "unsupported native pin acquisition fails closed so flight fallback may draw")
assert(ChalkBox_MapNativeStatus().problem:find("unsupported",1,true),
    "native fallback reason remains available to diagnostics")
print("PASS: native MapCanvas flight/loot pins, zoom-aware positioning, child projection, no false coordinates, independent pools and safe fallback")
