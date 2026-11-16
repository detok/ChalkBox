-- Discoveries / Known Flight Paths
-- Only nodes the character has actually confirmed at a flight master.
-- Never infer unlocked nodes from GetTaxiNodesForMap/isUndiscovered,
-- a published coordinate database, other characters or a faction.
-- All markers are cosmetic and map-owned; native taxi/map UI is unchanged.
local MAX_NODES,MAX_MARKERS=160,80
local pins={}
local drawnKey,menuInstalled=nil,false
local capturePending=0
local lastCanvas=nil
local tick=0
local lastCount=0

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
local function MakePin(canvas,index)
    local pin=pins[index]
    if not pin then
        pin=CreateFrame("Frame",nil,canvas)
        pin:SetSize(15,15)
        if type(pin.EnableMouse)=="function" then pin:EnableMouse(true) end
        local ring=pin:CreateTexture(nil,"ARTWORK")
        ring:SetAllPoints(pin)
        ring:SetTexture("Interface\\Buttons\\WHITE8X8")
        ring:SetVertexColor(0.10,0.11,0.12,0.90)
        local center=pin:CreateTexture(nil,"OVERLAY")
        center:SetSize(9,9)
        center:SetPoint("CENTER",pin,"CENTER",0,0)
        center:SetTexture("Interface\\Buttons\\WHITE8X8")
        center:SetVertexColor(0.97,0.76,0.34,1)
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
    if type(pin.SetFrameLevel)=="function" and
        type(canvas.GetFrameLevel)=="function" then
        pin:SetFrameLevel(canvas:GetFrameLevel()+8)
    end
    return pin
end
local function GetProjected(node,mapID)
    local x=node.x and node.x/10000 or nil
    local y=node.y and node.y/10000 or nil
    if not ValidXY(x,y) or not Integer(node.taxiMapID) then return end
    if node.taxiMapID==mapID then return x,y end
    local minX,maxX,minY,maxY=Call(
        C_Map and C_Map.GetMapRectOnMap,mapID,node.taxiMapID)
    if not Number(minX) or not Number(maxX) or
        not Number(minY) or not Number(maxY) or
        maxX<=minX or maxY<=minY or maxX>1 or maxY>1 then return end
    -- Only draw a node when a real client-supplied rectangle connects the
    -- stored taxi-map coordinate to the exact visible zone map.
    if x<minX or x>maxX or y<minY or y>maxY then return end
    local zoneX=(x-minX)/(maxX-minX)
    local zoneY=(y-minY)/(maxY-minY)
    if ValidXY(zoneX,zoneY) then return zoneX,zoneY end
end
local function CurrentCandidates(mapID)
    local list={}
    local taxi=C_TaxiMap
    if type(taxi)~="table" or
        type(taxi.GetTaxiNodesForMap)~="function" or
        type(taxi.ShouldMapShowTaxiNodes)~="function" then
        return list
    end
    local mapInfo=Call(C_Map and C_Map.GetMapInfo,mapID)
    if type(mapInfo)~="table" or
        not Number(mapInfo.mapType) or mapInfo.mapType>2 then
        return list
    end
    if Call(taxi.ShouldMapShowTaxiNodes,mapID)~=true then return list end
    local all=Call(taxi.GetTaxiNodesForMap,mapID)
    if type(all)~="table" then return list end
    for _,node in ipairs(all) do
        if type(node)=="table" and Integer(node.nodeID) then
            local x,y=Point(node.position)
            if x then list[tostring(node.nodeID)]={x=x,y=y} end
        end
    end
    return list
end
local function Refresh()
    if not WorldMapFrame or type(WorldMapFrame.IsShown)~="function" or
        not WorldMapFrame:IsShown() or not Enabled() then
        HidePins();drawnKey=nil;return
    end
    local mapID,canvas=ViewedMap(),Canvas()
    if not mapID or not canvas then
        HidePins();drawnKey=nil;return
    end
    local w,h=Call(canvas.GetWidth,canvas),Call(canvas.GetHeight,canvas)
    if not Number(w) or not Number(h) or w<=0 or h<=0 then
        HidePins();drawnKey=nil;return
    end
    local db=DB()
    if not db then return end
    local key=tostring(mapID)..":"..db.revision..":"..w..":"..h
    if key==drawnKey and lastCanvas==canvas then return end
    HidePins()
    drawnKey,lastCanvas=key,canvas
    local indexed=CurrentCandidates(mapID)
    local ids={}
    for id in pairs(db.nodes) do ids[#ids+1]=id end
    table.sort(ids) -- deterministic ordering without altering learned data
    for _,id in ipairs(ids) do
        local node=db.nodes[id]
        if type(node)=="table" then
            local x,y
            if node.zoneMapID==mapID then
                x,y=node.zoneX and node.zoneX/10000,
                    node.zoneY and node.zoneY/10000
                if not ValidXY(x,y) then x,y=nil,nil end
            end
            if not x then x,y=GetProjected(node,mapID) end
            if not x and indexed[id] then
                x,y=indexed[id].x,indexed[id].y
            end
            if ValidXY(x,y) then
                local pin=MakePin(canvas,lastCount+1)
                pin.flightName=type(node.name)=="string" and node.name or
                    "Flight master"
                pin:ClearAllPoints()
                pin:SetPoint("CENTER",canvas,"TOPLEFT",x*w,-y*h)
                pin:Show()
                lastCount=lastCount+1
                if lastCount>=MAX_MARKERS then break end
            end
        end
    end
    for i=lastCount+1,#pins do pins[i]:Hide() end
end
local function Capture()
    local getID=GetTaxiMapID
    local taxiMap=Call(getID)
    local taxi=C_TaxiMap
    if not Integer(taxiMap) or taxiMap<=0 or type(taxi)~="table" or
        type(taxi.GetAllTaxiNodes)~="function" then return false end
    local all=Call(taxi.GetAllTaxiNodes,taxiMap)
    if type(all)~="table" then return false end
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
                    for _=1,10 do
                        if not Integer(zone) or seen[zone] then break end
                        seen[zone]=true
                        local info=Call(C_Map and C_Map.GetMapInfo,zone)
                        if type(info)~="table" then break end
                        if info.mapType==3 then break end
                        zone=info.parentMapID
                    end
                    local p=zone and Call(
                        C_Map and C_Map.GetPlayerMapPosition,zone,"player")
                    local zx,zy=Point(p)
                    if zx and Integer(zone) then
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
    return true
end
function ChalkBox_DiscoveriesKnownFlightsStatus()
    local db=DB()
    return {enabled=db and db.enabled~=false or false,
        verified=db and Count(db.nodes) or 0,
        mapPins=lastCount,menuHook=menuInstalled,
        mapID=ViewedMap(),captureRetry=capturePending>0}
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
