-- Discoveries / Known Flight Paths
-- Only nodes the character has actually confirmed at a flight master.
-- Never infer unlocked nodes from GetTaxiNodesForMap/isUndiscovered,
-- a published coordinate database, other characters or a faction.
-- All markers are cosmetic and map-owned; native taxi/map UI is unchanged.
local MAX_NODES,MAX_MARKERS=160,80
local pins={}
local drawnKey,menuInstalled=nil,false
local lastCandidateSignature,refreshCycles=nil,0
local capturePending=0
local lastCanvas=nil
local tick=0
local lastCount=0
local positionSources={observed=0,direct=0,projected=0,unplaced=0}
local lastCapture={status="not seen",taxiMapID=nil,reachable=0}

local function Public(value)
    return type(issecretvalue)~="function" or not issecretvalue(value)
end
local function Number(value)
    return Public(value) and type(value)=="number" and value==value and
        value>=0 and value<1e8 and value~=math.huge
end
local function Integer(value)
    return Number(value) and value%1==0
end
local function ValidXY(x,y)
    return Number(x) and Number(y) and x<=1 and y<=1 and
        not (x==0 and y==0)
end
local function Call(fn,...)
    if type(fn)~="function" then return end
    local ok,a,b,c,d=pcall(fn,...)
    if ok and Public(a) then return a,b,c,d end
end
local function Point(value)
    if not Public(value) or value==nil then return end
    local ok,x,y=pcall(function()
        if type(value.GetXY)=="function" then return value:GetXY() end
        return value.x,value.y
    end)
    if ok and ValidXY(x,y) then return x,y end
end
local function DB()
    if type(ChalkBoxZoneDB)~="table" then ChalkBoxZoneDB={} end
    local db=ChalkBoxZoneDB.discoveriesKnownFlights
    if db==nil then
        db={version=1,enabled=true,nodes={},revision=0}
        ChalkBoxZoneDB.discoveriesKnownFlights=db
    end
    -- Unknown newer versions remain untouched. Fail closed.
    if type(db)~="table" or db.version~=1 then return nil end
    if type(db.nodes)~="table" then db.nodes={} end
    if not Integer(db.revision) then db.revision=0 end
    return db
end
local function Count(nodes)
    local count=0
    for _ in pairs(nodes or {}) do count=count+1 end
    return count
end
local function Enabled()
    local db=DB()
    return db and db.enabled~=false or false
end
local function Canvas()
    local scroll=WorldMapFrame and WorldMapFrame.ScrollContainer
    if not scroll then return end
    local canvas=scroll.Child
    if not canvas and type(scroll.GetCanvas)=="function" then
        canvas=Call(scroll.GetCanvas,scroll)
    end
    if canvas and type(canvas.GetWidth)=="function" and
        type(canvas.GetHeight)=="function" and
        type(canvas.CreateTexture)=="function" then
        return canvas
    end
end
local function ViewedMap()
    local map=WorldMapFrame
    local id=map and Call(map.GetMapID,map)
    if not Integer(id) and map and map.ScrollContainer then
        id=Call(map.ScrollContainer.GetMapID,map.ScrollContainer)
    end
    return Integer(id) and id>0 and id or nil
end
local function HidePins()
    for _,pin in ipairs(pins) do pin:Hide() end
    lastCount=0
end
-- Use Blizzard's actual flight-master map artwork. The returned atlas
-- can vary by map and faction; never rely on it for learned-state checks.
local function TaxiAtlas(node,located)
    local from=located or node
    local own=from and from.atlasName
    if Public(own) and type(own)=="string" and
        own:match("^TaxiNode_[%w_]+$") then
        if not (C_Texture and type(C_Texture.GetAtlasInfo)=="function") or
            Call(C_Texture.GetAtlasInfo,own) then
            return own
        end
    end
    local faction=from and from.faction
    if not Integer(faction) then faction=node and node.faction end
    local atlas=faction==2 and "TaxiNode_Alliance" or
        (faction==1 and "TaxiNode_Horde" or "TaxiNode_Neutral")
    -- Gracefully fall back to the neutral winged-boot on client forks
    -- where a faction-specific atlas is not present.
    if C_Texture and type(C_Texture.GetAtlasInfo)=="function" and
        not Call(C_Texture.GetAtlasInfo,atlas) then
        return "TaxiNode_Neutral"
    end
    return atlas
end
local function SetPinArt(pin,atlas)
    local icon=pin.icon
    if not icon then return end
    if type(icon.SetAtlas)=="function" then
        local ok,result=pcall(icon.SetAtlas,icon,atlas,false)
        if ok and result~=false then return end
        if atlas~="TaxiNode_Neutral" then
            ok,result=pcall(icon.SetAtlas,icon,"TaxiNode_Neutral",false)
            if ok and result~=false then return end
        end
    end
    -- Older texture-only clients: use Blizzard's minimap flight-master
    -- tracking art instead of painting another square over the map.
    if type(icon.SetTexture)=="function" then
        icon:SetTexture("Interface\\Minimap\\Tracking\\FlightMaster")
    end
end
-- Forever's zone map adds artwork above the base canvas after map changes.
-- On continents canvas+8 worked, but on zones it left the native taxi atlas
-- underneath local map layers even though the pin could still be hovered.
-- Keep map ownership/coordinates, only lift this small cosmetic pin.
local function RaisePin(pin,canvas)
    if not pin then return end
    local world=WorldMapFrame
    local scroll=world and world.ScrollContainer
    local top=0
    for _,frame in ipairs({canvas,scroll,world}) do
        local level=frame and Call(frame.GetFrameLevel,frame)
        if Number(level) then top=math.max(top,level) end
    end
    if type(pin.SetFrameStrata)=="function" then
        local strata=world and Call(world.GetFrameStrata,world)
        if type(strata)=="string" and
            Call(pin.GetFrameStrata,pin)~=strata then
            pcall(pin.SetFrameStrata,pin,strata)
        end
    end
    -- Discoveries' own working map sidecar uses level >=200. Apply the
    -- same conservative floor to cosmetic pins (within the map canvas).
    local wanted=math.min(9900,math.max(200,top+60))
    if type(pin.SetFrameLevel)=="function" and
        Call(pin.GetFrameLevel,pin)~=wanted then
        pcall(pin.SetFrameLevel,pin,wanted)
    end
end
local function MakePin(canvas,index)
    local pin=pins[index]
    if not pin then
        pin=CreateFrame("Frame",nil,canvas)
        pin:SetSize(24,24)
        if type(pin.EnableMouse)=="function" then pin:EnableMouse(true) end
        -- In Forever the zone-specific map tiles may be drawn above
        -- ARTWORK textures; OVERLAY keeps the flight-master boot visible.
        -- The frame can be hoverable while its taxi atlas is invisible.
        -- A small color texture guarantees a visible marker on Forever
        -- builds whose atlas registration differs from Blizzard retail.
        local backing=pin:CreateTexture(nil,"OVERLAY")
        backing:SetSize(11,11)
        backing:SetPoint("CENTER",pin,"CENTER",0,0)
        if type(backing.SetDrawLayer)=="function" then
            pcall(backing.SetDrawLayer,backing,"OVERLAY",5)
        end
        if type(backing.SetColorTexture)=="function" then
            backing:SetColorTexture(1,0.70,0.16,0.95)
        else
            backing:SetTexture("Interface\\Buttons\\WHITE8X8")
            if type(backing.SetVertexColor)=="function" then
                backing:SetVertexColor(1,0.70,0.16,0.95)
            end
        end
        pin.backing=backing
        local icon=pin:CreateTexture(nil,"OVERLAY")
        icon:SetAllPoints(pin)
        if type(icon.SetDrawLayer)=="function" then
            pcall(icon.SetDrawLayer,icon,"OVERLAY",7)
        end
        pin.icon=icon
        pin:SetScript("OnEnter",function(self)
            if GameTooltip and type(GameTooltip.SetOwner)=="function" and
                type(GameTooltip.AddLine)=="function" then
                GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
                GameTooltip:AddLine(self.flightName or "Flight master",
                    1,0.81,0.45)
                GameTooltip:AddLine("Known flight path",0.50,0.90,0.67)
                GameTooltip:Show()
            end
        end)
        pin:SetScript("OnLeave",function()
            if GameTooltip then GameTooltip:Hide() end
        end)
        pins[index]=pin
    elseif type(pin.SetParent)=="function" then
        pin:SetParent(canvas)
    end
    RaisePin(pin,canvas)
    return pin
end
-- Convert points from an explicitly reported parent map into its zone.
-- All coordinates are returned by Forever, never taken from a flight master
-- database. Inverting a rectangle is safe only if the node is inside it.
local function ProjectOnZone(x,y,zoneID,sourceMapID)
    if not ValidXY(x,y) or not Integer(sourceMapID) then return end
    if zoneID==sourceMapID then return x,y end
    local minX,maxX,minY,maxY=Call(
        C_Map and C_Map.GetMapRectOnMap,zoneID,sourceMapID)
    if not Number(minX) or not Number(maxX) or
        not Number(minY) or not Number(maxY) or
        maxX<=minX or maxY<=minY or maxX>1 or maxY>1 then return end
    if x<minX or x>maxX or y<minY or y>maxY then return end
    local zoneX=(x-minX)/(maxX-minX)
    local zoneY=(y-minY)/(maxY-minY)
    if ValidXY(zoneX,zoneY) then return zoneX,zoneY end
end
local function GetProjected(node,mapID)
    local x=node.x and node.x/10000 or nil
    local y=node.y and node.y/10000 or nil
    if not ValidXY(x,y) or not Integer(node.taxiMapID) then return end
    return ProjectOnZone(x,y,mapID,node.taxiMapID)
end
-- MapTaxiNodeInfo includes BOTH learned and unknown nodes. It is strictly a
-- coordinate directory here: only IDs already proved learned by a taxi visit
-- in the current character's SavedVariables may ever be displayed.
-- Forever sometimes supplies per-zone coordinates even when
-- ShouldMapShowTaxiNodes() is false for the standard map filter. Do not
-- discard those coordinates merely because the zone's mapType == 3.
local function IndexedPositions(mapID,known)
    local list={}
    local taxi=C_TaxiMap
    if type(taxi)~="table" or
        type(taxi.GetTaxiNodesForMap)~="function" then return list end
    local visited={}
    local current=mapID
    for depth=1,8 do
        if not Integer(current) or current<=0 or visited[current] then
            break
        end
        visited[current]=true
        local ok,all=pcall(taxi.GetTaxiNodesForMap,current)
        if ok and Public(all) and type(all)=="table" then
            for _,candidate in ipairs(all) do
                if type(candidate)=="table" and Integer(candidate.nodeID) and
                    known[tostring(candidate.nodeID)] then
                    local id=tostring(candidate.nodeID)
                    if not list[id] then
                        local x,y=Point(candidate.position)
                        if x then
                            local px,py=ProjectOnZone(x,y,mapID,current)
                            if px then
                                list[id]={x=px,y=py,
                                    atlasName=Public(candidate.atlasName) and
                                        candidate.atlasName or nil,
                                    faction=Public(candidate.faction) and
                                        candidate.faction or nil,
                                    from=(current==mapID and "direct" or
                                        "projected")}
                            end
                        end
                    end
                end
            end
        end
        local info=Call(C_Map and C_Map.GetMapInfo,current)
        if type(info)~="table" or not Integer(info.parentMapID) or
            info.parentMapID<=0 or info.parentMapID==current then break end
        current=info.parentMapID
    end
    return list
end
-- This is the single source of flight-marker positions for both renderers.
-- Only learned taxi node IDs in this character's DB may generate candidates.
-- The native MapCanvas data provider consumes normalized map coordinates;
-- legacy cosmetic frames are used only if this client's provider is absent.
function ChalkBox_DiscoveriesFlightCandidates(mapID)
    local result={}
    local db=DB()
    if not db or not Enabled() or not Integer(mapID) then
        positionSources={observed=0,direct=0,projected=0,unplaced=0}
        lastCount=0
        return result
    end
    local indexed=IndexedPositions(mapID,db.nodes)
    positionSources={observed=0,direct=0,projected=0,unplaced=0}
    local ids={}
    for id in pairs(db.nodes) do ids[#ids+1]=id end
    table.sort(ids)
    for _,id in ipairs(ids) do
        local node=db.nodes[id]
        if type(node)=="table" then
            local x,y,from
            if node.zoneMapID==mapID then
                x,y=node.zoneX and node.zoneX/10000,
                    node.zoneY and node.zoneY/10000
                if not ValidXY(x,y) then x,y=nil,nil
                else from="observed" end
            end
            if not x and indexed[id] then
                x,y=indexed[id].x,indexed[id].y
                from=indexed[id].from
            end
            if not x then
                x,y=GetProjected(node,mapID)
                if x then from="projected" end
            end
            if ValidXY(x,y) then
                result[#result+1]={x=x,y=y,
                    name=type(node.name)=="string" and node.name
                        or "Flight master",
                    atlas=TaxiAtlas(node,indexed[id]),
                    from=from or "projected"}
                positionSources[from or "projected"]=
                    positionSources[from or "projected"]+1
                if #result>=MAX_MARKERS then break end
            else
                positionSources.unplaced=positionSources.unplaced+1
            end
        end
    end
    lastCount=#result
    return result
end

-- Coordinate lookups may become available after a zone map loads.
-- Recheck periodically, but only reconstruct visible pins when the actual
-- candidate set changes. Off-map learned nodes are not a reason to flicker.
local function CandidateSignature(candidates)
    local parts={}
    for i,entry in ipairs(candidates) do
        parts[i]=("%.5f:%.5f:%s:%s"):format(
            entry.x,entry.y,entry.name,entry.atlas or "")
    end
    return table.concat(parts,"|")
end
local function Refresh()
    if not WorldMapFrame or type(WorldMapFrame.IsShown)~="function" or
        not WorldMapFrame:IsShown() or not Enabled() then
        local wasDrawn=drawnKey~=nil
        HidePins();drawnKey=nil;lastCandidateSignature=nil
        refreshCycles=0
        if wasDrawn and type(ChalkBox_MapNativeRefresh)=="function" then
            ChalkBox_MapNativeRefresh()
        end
        return
    end
    local mapID,canvas=ViewedMap(),Canvas()
    if not mapID or not canvas then
        HidePins();drawnKey=nil;lastCandidateSignature=nil;return
    end
    local w,h=Call(canvas.GetWidth,canvas),Call(canvas.GetHeight,canvas)
    if not Number(w) or not Number(h) or w<=0 or h<=0 then
        HidePins();drawnKey=nil;lastCandidateSignature=nil;return
    end
    local db=DB()
    if not db then return end
    local native=type(ChalkBox_MapNativeAvailable)=="function" and
        ChalkBox_MapNativeAvailable()
    local key=tostring(mapID)..":"..db.revision..":"..w..":"..h..":"..
        (native and "native" or "fallback")
    local unchanged=key==drawnKey and lastCanvas==canvas
    if unchanged then
        if not native then
            -- Native zone artwork can change frame levels after first show.
            for i=1,lastCount do RaisePin(pins[i],canvas) end
        end
        refreshCycles=refreshCycles+1
        if refreshCycles<4 then return end
    end
    refreshCycles=0
    local candidates=ChalkBox_DiscoveriesFlightCandidates(mapID)
    local signature=CandidateSignature(candidates)
    if unchanged and signature==lastCandidateSignature then
        return -- Late lookup still gave the same answer: no repaint
    end
    lastCandidateSignature=signature
    drawnKey,lastCanvas=key,canvas
    if native then
        HidePins() -- clear any previous legacy-only frames
        if type(ChalkBox_MapNativeRefresh)=="function" then
            ChalkBox_MapNativeRefresh()
        end
        return
    end
    -- Conservative compatibility path for clients without native pins.
    HidePins()
    for i,entry in ipairs(candidates) do
        local pin=MakePin(canvas,i)
        pin.flightName=entry.name
        SetPinArt(pin,entry.atlas)
        pin:ClearAllPoints()
        pin:SetPoint("CENTER",canvas,"TOPLEFT",entry.x*w,-entry.y*h)
        pin:Show()
    end
    lastCount=#candidates
    for i=lastCount+1,#pins do pins[i]:Hide() end
end
local function Capture()
    local getID=GetTaxiMapID
    local taxiMap=Call(getID)
    local taxi=C_TaxiMap
    if not Integer(taxiMap) or taxiMap<=0 or type(taxi)~="table" or
        type(taxi.GetAllTaxiNodes)~="function" then
        lastCapture.status="taxi map unavailable"
        return false
    end
    lastCapture.taxiMapID=taxiMap
    local all=Call(taxi.GetAllTaxiNodes,taxiMap)
    if type(all)~="table" then
        lastCapture.status="taxi nodes unavailable"
        return false
    end
    lastCapture.status="read"
    lastCapture.reachable=0
    local db=DB()
    if not db then return false end
    local count=Count(db.nodes)
    local changed=false
    for _,node in ipairs(all) do
        if type(node)=="table" and Integer(node.nodeID) and
            node.nodeID>0 and Public(node.state) and
            -- 0 CURRENT and 1 REACHABLE are authoritative. All other
            -- states remain unlearned; isUndiscovered is NOT consulted.
            (node.state==0 or node.state==1) then
            lastCapture.reachable=lastCapture.reachable+1
            local id=tostring(node.nodeID)
            local old=db.nodes[id]
            if old or count<MAX_NODES then
                local name=Public(node.name) and type(node.name)=="string"
                    and node.name:sub(1,90) or ("Flight path "..id)
                local x,y=Point(node.position)
                local record=old or {}
                local changedNode=(not old) or record.name~=name
                if record.name~=name then record.name=name end
                if record.taxiMapID~=taxiMap then
                    record.taxiMapID=taxiMap;changedNode=true
                end
                if x then
                    local nx,ny=math.floor(x*10000+0.5),
                        math.floor(y*10000+0.5)
                    if record.x~=nx or record.y~=ny then
                        record.x,record.y=nx,ny
                        changedNode=true
                    end
                end
                if node.state==0 then
                    -- The active flight master's own zone position can be
                    -- independently confirmed from the player's location.
                    local raw=Call(C_Map and C_Map.GetBestMapForUnit,"player")
                    local seen={}
                    local zone=raw
                    local verifiedZone=false
                    for _=1,10 do
                        if not Integer(zone) or seen[zone] then break end
                        seen[zone]=true
                        local info=Call(C_Map and C_Map.GetMapInfo,zone)
                        if type(info)~="table" then break end
                        if info.mapType==3 then
                            verifiedZone=true;break
                        end
                        zone=info.parentMapID
                    end
                    local p=verifiedZone and Call(
                        C_Map and C_Map.GetPlayerMapPosition,zone,"player")
                    local zx,zy=Point(p)
                    if verifiedZone and zx and Integer(zone) then
                        local ix,iy=math.floor(zx*10000+0.5),
                            math.floor(zy*10000+0.5)
                        if record.zoneMapID~=zone or
                            record.zoneX~=ix or record.zoneY~=iy then
                            record.zoneMapID,record.zoneX,record.zoneY=
                                zone,ix,iy
                            changedNode=true
                        end
                    end
                end
                if not old then db.nodes[id]=record;count=count+1 end
                if changedNode then changed=true end
            end
        end
    end
    if changed then
        db.revision=db.revision+1
        drawnKey=nil
        Refresh()
    end
    return true
end
function ChalkBox_DiscoveriesKnownFlightsSet(value)
    local db=DB()
    if not db then return false end
    db.enabled=value==true
    drawnKey=nil
    Refresh()
    -- Disabling a native data-provider pin requires an explicit refresh:
    -- Refresh() rightly skips drawing while the checkbox is off.
    if not db.enabled and
        type(ChalkBox_MapNativeRefresh)=="function" then
        ChalkBox_MapNativeRefresh()
    end
    return true
end
function ChalkBox_DiscoveriesKnownFlightsStatus()
    local db=DB()
    local native=type(ChalkBox_MapNativeStatus)=="function" and
        ChalkBox_MapNativeStatus() or nil
    return {enabled=db and db.enabled~=false or false,
        verified=db and Count(db.nodes) or 0,
        mapPins=native and native.available and native.flightPins
            or lastCount,menuHook=menuInstalled,
        renderer=native and native.available and "native MapCanvas"
            or "compatibility canvas",
        rendererProblem=native and native.problem or nil,
        mapID=ViewedMap(),captureRetry=capturePending>0,
        captureStatus=lastCapture.status,taxiMapID=lastCapture.taxiMapID,
        taxiKnown=lastCapture.reachable,
        observedPositions=positionSources.observed,
        directPositions=positionSources.direct,
        projectedPositions=positionSources.projected,
        unplacedNodes=positionSources.unplaced}
end
local function InstallMenu()
    if menuInstalled then return end
    if type(Menu)~="table" or type(Menu.ModifyMenu)~="function" then
        return
    end
    local ok=pcall(Menu.ModifyMenu,"MENU_WORLD_MAP_TRACKING",
        function(owner,root)
            if not root or type(root.CreateCheckbox)~="function" then return end
            if type(root.CreateDivider)=="function" then
                root:CreateDivider()
            end
            local checkbox=root:CreateCheckbox("Known Flight Paths (ChalkBox)",
                Enabled,function() ChalkBox_DiscoveriesKnownFlightsSet(
                    not Enabled()) end)
            if checkbox and type(checkbox.SetSelectionIgnored)=="function" then
                checkbox:SetSelectionIgnored()
            end
        end)
    if ok then menuInstalled=true end
end
local loader=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD",
    "ADDON_LOADED","TAXIMAP_OPENED","TAXI_NODE_STATUS_CHANGED"}) do
    loader:RegisterEvent(event)
end
loader:SetScript("OnEvent",function(_,event)
    if event=="TAXIMAP_OPENED" or
        event=="TAXI_NODE_STATUS_CHANGED" then
        capturePending=3 -- retry as taxi map data arrives asynchronously
        Capture()
    else
        InstallMenu()
    end
end)
loader:SetScript("OnUpdate",function(_,elapsed)
    tick=tick+(type(elapsed)=="number" and elapsed or 0)
    if tick<0.8 then return end
    tick=0
    InstallMenu()
    if capturePending>0 then
        capturePending=capturePending-1
        Capture()
    end
    Refresh()
end)
InstallMenu()
