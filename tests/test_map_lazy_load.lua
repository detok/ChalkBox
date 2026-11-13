-- WorldMapFrame is load-on-demand on WoW Forever. ChalkBox must still
-- install its button after login, even when the map wasn't loaded yet.
_G.ChalkBoxZoneDB={}
_G.UIParent={}
local frames={}
local allowed={PLAYER_LOGIN=true,PLAYER_ENTERING_WORLD=true,
    ADDON_LOADED=true}
local function Frame(kind,name,parent)
    local f={kind=kind,name=name,parent=parent,scripts={},
        shown=false}
    function f:SetSize(w,h) self.w,self.h=w,h end
    function f:SetPoint(...) self.point={...} end
    function f:ClearAllPoints() self.point=nil end
    function f:SetFrameLevel(n) self.level=n end
    function f:GetFrameLevel() return 10 end
    function f:SetFrameStrata(level) self.strata=level end
    function f:SetMovable() end
    function f:SetClampedToScreen() end
    function f:EnableMouse() end
    function f:RegisterForDrag() end
    function f:SetText(value) self.text=value end
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:IsShown() return self.shown end
    function f:RegisterEvent(event)
        assert(allowed[event],"unknown map event must never abort addon init")
    end
    function f:SetScript(event,callback) self.scripts[event]=callback end
    function f:HookScript(event,callback) self.scripts["Hook"..event]=callback end
    function f:CreateTexture()
        return {SetAllPoints=function() end,SetPoint=function() end,
            SetHeight=function() end,SetColorTexture=function() end}
    end
    function f:CreateFontString()
        return {SetPoint=function() end,SetWidth=function() end,
            SetJustifyH=function() end,SetText=function(self,t) self.text=t end}
    end
    frames[#frames+1]=f
    return f
end
_G.CreateFrame=Frame
_G.C_Map={
    GetBestMapForUnit=function() return 1436 end,
    GetMapInfo=function(id) return {name="Westfall",mapType=3,id=id} end,
}
local enabled=true
_G.ChalkBox_DropOptions=function()
    return {mapButton=enabled,enabled=true,areas=0}
end
_G.ChalkBox_DropMapData=function()
    return {zone=nil,dungeons={}}
end
local function Find(name)
    for _,f in ipairs(frames) do if f.name==name then return f end end
end
-- WorldMapFrame is nil when ChalkBox first loads.
assert(_G.WorldMapFrame==nil)
assert(loadfile("MapDiscoveries.lua"))("ChalkBox")
local state=ChalkBox_MapDiscoveriesStatus()
assert(not state.frame and not state.button and state.allowed,
    "first login doesn't fabricate a loaded world map or a button")
-- Direct command must work while map is still load-on-demand: player map
-- provides a valid location via C_Map.
assert(ChalkBox_OpenMapDiscoveries(),
    "standalone journal is accessible even if Blizzard map hasn't loaded")
assert(Find("ChalkBoxMapDiscoveries"):IsShown(),
    "direct access never depends on the map button being visible")
local loader
for _,f in ipairs(frames) do
    if f.scripts.OnEvent and f.scripts.OnUpdate then loader=f end
end
assert(loader and loader.scripts.OnEvent,
    "map initialization has a retry until the load-on-demand frame exists")
local map=Frame("Frame","WorldMapFrame",UIParent)
local canvas=Frame("Frame","Canvas",map)
function map:GetCanvasContainer() return canvas end
function map:GetMapID() return 1436 end
map:Show()
-- Fire actual load-on-demand event plus one self-healing update.
loader.scripts.OnEvent(loader,"ADDON_LOADED","Blizzard_WorldMap")
loader.scripts.OnUpdate(loader,0.8)
local button=Find("ChalkBoxMapDiscoveriesButton")
assert(button and button.parent==map,
    "button is installed as a child of the real Blizzard map")
assert(button.point and button.point[1]=="TOPLEFT" and
    button.point[2]==canvas and button.point[4]==8 and
    button.point[5]==-98,
    "Forever button anchors inside top-left map canvas, below map pin")
assert(button.strata=="HIGH" and button.level==50 and button:IsShown(),
    "button is raised above the map canvas, avoiding occluded controls")
assert(loader.scripts.OnUpdate==nil,
    "temporary retry stops completely once button has attached")
local before=#frames
ChalkBox_MapDiscoveriesEnsure()
assert(#frames==before,"repeated map events don't create duplicate buttons")
assert(ChalkBox_MapDiscoveriesStatus().anchor=="canvas")
button.scripts.OnClick(button)
assert(Find("ChalkBoxMapDiscoveries"):IsShown(),
    "new map button opens journal on the selected map")
enabled=false
ChalkBox_MapDiscoveriesRefresh()
assert(not button:IsShown() and
    not Find("ChalkBoxMapDiscoveries"):IsShown(),
    "map button opt-out works without touching the base map")
enabled=true
ChalkBox_MapDiscoveriesRefresh()
assert(button:IsShown(),"reenabling displays the same attached button")
if map.scripts.HookOnShow then map.scripts.HookOnShow(map) end
assert(button:IsShown(),"map reopen refresh preserves button")
print("PASS: Forever lazy-load map recovery, canvas-safe visible button, fallback slash, no duplicate frames, opt-out")
