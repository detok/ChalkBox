-- ChalkBox DropSense 1.11: automatic, local-only discovery journal.
-- Counts only visible loot windows and item quantities, not unseen kills.
-- An observed frequency is reported ONLY for a known single creature source.
local addonName=...
local MAX_ITEMS,MAX_AREAS,MAX_SOURCES,MAX_AREA_ITEMS=5000,240,150,750
-- Preserve only a few distinct last-seen loot positions per area/item.
-- Samples are rounded to 0.1%, deduped spatially and never extrapolated.
local MAX_SPOTS=6
local SPOT_RADIUS2=25*25 -- 2.5 map percentage points in tenths
local MAX_COUNT=100000000
local frame=CreateFrame("Frame")
local opened=false
local lastSourceGUID,lastSourceAt=nil,-1e9
local lastAreaKey,lastSourceKey
local lastOutdoor,lastOutdoorAt,lastInstance=nil,nil,nil
local function Public(v)
    return v~=nil and (type(issecretvalue)~="function" or not issecretvalue(v))
end
local function Number(v)
    return Public(v) and type(v)=="number" and v==v and v>=0 and v<1e12
end
local function Integer(v)
    return Number(v) and v%1==0
end
local function SafeCall(fn,...)
    if type(fn)~="function" then return end
    local ok,value=pcall(fn,...)
    if ok and Public(value) then return value end
end
local function Clock()
    return SafeCall(GetTime)
end
local function Count(t)
    local n=0
    for _ in pairs(t) do n=n+1 end
    return n
end
local function Add(a,b)
    return math.min(MAX_COUNT,(Number(a) and a or 0)+(Number(b) and b or 0))
end
local function ItemID(link)
    if Integer(link) and link>0 then return tostring(link) end
    if not Public(link) or type(link)~="string" then return end
    return link:match("item:(%d+)") or link:match("^%s*(%d+)%s*$")
end
local function ItemName(link,id)
    local name=Public(link) and type(link)=="string" and
        link:match("%[([^%]]+)%]") or nil
    if not name then
        local fn=C_Item and C_Item.GetItemInfo or GetItemInfo
        name=SafeCall(fn,tonumber(id))
    end
    if type(name)=="string" and #name>0 and #name<=120 then return name end
    return "Item #"..id
end
local function Note(msg)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff67c6b7ChalkBox Drops|r "..msg)
    end
end
local function Migrate(old)
    local s={version=2,enabled=true,tooltip=true,mapButton=true,items={},
        areas={},windows=0,observedItems=0,legacyWindows=0}
    if type(old)=="table" then
        if old.enabled==false then s.enabled=false end
        if old.tooltip==false then s.tooltip=false end
        if old.mapButton==false then s.mapButton=false end
        s.legacyWindows=Number(old.windows) and old.windows or 0
        if type(old.items)=="table" then
            for key,value in pairs(old.items) do
                local id=ItemID(key)
                if id and type(value)=="table" and
                    Count(s.items)<MAX_ITEMS then
                    s.items[id]={id=id,name=type(value.name)=="string" and
                        value.name:sub(1,96) or "Item #"..id,
                        quantity=0,windows=0,legacy={
                            windows=Number(value.windows) and value.windows or 0,
                            hits=Number(value.hits) and value.hits or 0,
                            quantity=Number(value.quantity) and value.quantity or 0
                        },reference=value.reference}
                end
            end
        end
    end
    return s
end
local function State()
    if type(ChalkBoxZoneDB)~="table" then ChalkBoxZoneDB={} end
    local s=ChalkBoxZoneDB.dropSense
    if type(s)~="table" or s.version~=2 then
        s=Migrate(s);ChalkBoxZoneDB.dropSense=s
    end
    if type(s.items)~="table" then s.items={} end
    if type(s.areas)~="table" then s.areas={} end
    return s
end
local function MapInfo(mapID)
    if not Integer(mapID) or mapID<=0 then return end
    local info=SafeCall(C_Map and C_Map.GetMapInfo,mapID)
    if type(info)~="table" then return end
    local name=info.name
    local parent=info.parentMapID
    local mapType=info.mapType
    if not Public(name) or type(name)~="string" then name="Map "..mapID end
    if not Integer(parent) then parent=nil end
    if not Integer(mapType) then mapType=nil end
    return {name=name,parent=parent,mapType=mapType,id=mapID}
end
local function ZoneMap(rawID)
    local current=rawID
    local seen={}
    for _=1,12 do
        if not Integer(current) or current<=0 or seen[current] then break end
        seen[current]=true
        local info=MapInfo(current)
        if not info then break end
        -- UIMapType.Zone==3; Dungeon==4, Micro==5. Keep zone when found.
        if info.mapType==3 then return info end
        if info.mapType and info.mapType<3 then break end
        if not info.parent or info.parent<=0 then break end
        current=info.parent
    end
    return MapInfo(rawID)
end
local function Location()
    local map=SafeCall(C_Map and C_Map.GetBestMapForUnit,"player")
    local iName,iType,difficulty,_,_,_,_,instanceID
    if type(GetInstanceInfo)=="function" then
        local ok,a,b,c,dd,e,f,g,h=pcall(GetInstanceInfo)
        if ok then
            iName,iType,difficulty,instanceID=a,b,c,h
        end
    end
    local dungeon=Public(iType) and
        (iType=="party" or iType=="raid" or iType=="scenario")
    local now=Clock()
    if dungeon then
        local key
        if Integer(instanceID) and instanceID>0 then
            key="d:"..instanceID..":"..tostring(Integer(difficulty) and
                difficulty or 0)
        elseif Integer(map) and map>0 then
            key="dmap:"..map
        else key="d:unknown" end
        local info=MapInfo(map)
        local name=Public(iName) and type(iName)=="string" and
            iName or (info and info.name) or "Unidentified instance"
        local entry={key=key,kind="dungeon",name=name,
            mapID=map,instanceID=instanceID,difficulty=difficulty}
        if lastOutdoor and Number(now) and Number(lastOutdoorAt) and
            now-lastOutdoorAt>=0 and now-lastOutdoorAt<900 then
            entry.entranceZoneID=lastOutdoor.id
            entry.entranceZoneName=lastOutdoor.name
        end
        lastInstance=entry
        return entry
    end
    local info=ZoneMap(map)
    local zone=info or {id=nil,name=SafeCall(GetRealZoneText) or
        "Unknown outdoor location"}
    local entry={key=zone.id and ("z:"..zone.id) or "z:unknown",
        kind="outdoor",name=zone.name,mapID=zone.id}
    if lastInstance and zone.id and
        (not lastInstance.entranceZoneID) then
        -- Inferred from immediate exit, never presented as an official
        -- dungeon-to-zone mapping.
        local s=State()
        local old=s.areas[lastInstance.key]
        if old and old.kind=="dungeon" then
            old.entranceZoneID=zone.id
            old.entranceZoneName=zone.name
        end
    end
    lastInstance=nil
    if zone.id then lastOutdoor=zone;lastOutdoorAt=now end
    return entry
end
local function Area(entry)
    local s=State()
    if not entry or entry.key=="z:unknown" or entry.key=="d:unknown" then
        return -- no map attribution for unknown locations
    end
    local area=s.areas[entry.key]
    if not area then
        if Count(s.areas)>=MAX_AREAS then
            s.limitReached=true;return
        end
        area={kind=entry.kind,name=entry.name,mapID=entry.mapID,
            entranceZoneID=entry.entranceZoneID,
            entranceZoneName=entry.entranceZoneName,
            instanceID=entry.instanceID,difficulty=entry.difficulty,
            items={},sources={},windows=0}
        s.areas[entry.key]=area
    end
    if entry.kind=="dungeon" and entry.entranceZoneID and
        not area.entranceZoneID then
        area.entranceZoneID=entry.entranceZoneID
        area.entranceZoneName=entry.entranceZoneName
    end
    return area
end
local function Item(s,id,link)
    local row=s.items[id]
    if not row then
        if Count(s.items)>=MAX_ITEMS then
            s.limitReached=true;return
        end
        row={id=id,name=ItemName(link,id),quantity=0,windows=0}
        s.items[id]=row
    elseif row.name=="Item #"..id then
        row.name=ItemName(link,id)
    end
    return row
end
-- This is the player's position at LOOT_OPENED, not the corpse's
-- guaranteed death position. No coordinates are attributed inside instances.
local function LootPoint(entry)
    if not entry or entry.kind~="outdoor" or not Integer(entry.mapID) then return end
    local fn=C_Map and C_Map.GetPlayerMapPosition
    if type(fn)~="function" then return end
    local ok,point=pcall(fn,entry.mapID,"player")
    if not ok or not Public(point) or point==nil then return end
    local read,x,y=pcall(function()
        if type(point.GetXY)=="function" then return point:GetXY() end
        return point.x,point.y
    end)
    if not read or not Number(x) or not Number(y)
        or x>1 or y>1 or (x==0 and y==0) then return end
    return {x=math.floor(x*1000+0.5),y=math.floor(y*1000+0.5)}
end
local function RememberSpot(row,point)
    if not point or type(row)~="table" then return end
    if type(row.locations)~="table" then row.locations={} end
    local spots=row.locations
    local selected
    for i=#spots,1,-1 do
        local old=spots[i]
        if type(old)=="table" and Integer(old.x) and Integer(old.y) then
            local dx,dy=old.x-point.x,old.y-point.y
            if dx*dx+dy*dy<=SPOT_RADIUS2 then
                selected=table.remove(spots,i)
                break
            end
        end
    end
    selected=selected or {x=point.x,y=point.y,count=0}
    selected.x,selected.y=point.x,point.y
    selected.count=Add(selected.count,1)
    spots[#spots+1]=selected
    while #spots>MAX_SPOTS do table.remove(spots,1) end
end
local function ReadSpots(row)
    if type(row)~="table" or type(row.locations)~="table" then return end
    local result={}
    -- A bounded read-only snapshot; never expose the mutable saved table.
    for i=math.max(1,#row.locations-MAX_SPOTS+1),#row.locations do
        local p=row.locations[i]
        if type(p)=="table" and Integer(p.x) and Integer(p.y)
            and p.x<=1000 and p.y<=1000 then
            result[#result+1]={x=p.x,y=p.y,
                count=Integer(p.count) and p.count or 1}
        end
    end
    return #result>0 and result or nil
end
local function Source(guid)
    if type(guid)~="string" or #guid>120 then return end
    local kind=guid:match("^(%a+)%-")
    local numeric=guid:match("%-(%d+)%-%x+$")
    if not numeric or (kind~="Creature" and kind~="Vehicle" and
        kind~="GameObject") then return end
    local label="Source #"..numeric
    for _,unit in ipairs({"target","mouseover"}) do
        if type(UnitGUID)=="function" and
            SafeCall(UnitGUID,unit)==guid then
            local n=SafeCall(UnitName,unit)
            if type(n)=="string" and #n>0 then label=n end
        end
    end
    local isCreature=kind=="Creature" or kind=="Vehicle"
    return (isCreature and "c:" or "o:")..numeric,label,isCreature
end
local function SourceGUID(slot)
    if type(GetLootSourceInfo)~="function" then return end
    local ok,guid,_,second=pcall(GetLootSourceInfo,slot)
    if not ok or not Public(guid) or type(guid)~="string" then return end
    if second~=nil and Public(second) and type(second)=="string"
        and second~=guid then return nil,true end
    return guid,false
end
local function CapturedItems()
    if type(GetNumLootItems)~="function" or
        type(GetLootSlotLink)~="function" then return end
    local count=SafeCall(GetNumLootItems)
    if not Integer(count) or count<1 or count>60 then return end
    local counts,links={},{}
    local total=0
    local guid,mixed=nil,false
    for slot=1,count do
        local ok,link=pcall(GetLootSlotLink,slot)
        if not ok or (type(issecretvalue)=="function" and
            issecretvalue(link)) then return end
        if link then
            local id=ItemID(link)
            if id then
                local quantity=1
                if type(GetLootSlotInfo)=="function" then
                    local okInfo,_,_,n=pcall(GetLootSlotInfo,slot)
                    if okInfo and Integer(n) and n>0 and n<100000 then
                        quantity=n
                    end
                end
                counts[id]=(counts[id] or 0)+quantity
                links[id]=link
                total=total+quantity
                local source,bad=SourceGUID(slot)
                if bad then mixed=true end
                if guid and source~=guid then mixed=true end
                if not source then mixed=true else guid=source end
            end
        end
    end
    if total==0 then return end
    if mixed then guid=nil end
    return counts,links,total,guid
end
local function Capture()
    local s=State()
    if not s.enabled or opened then return end
    local counts,links,total,guid=CapturedItems()
    if not counts then return end
    local now=Clock()
    -- Re-opening the same physical corpse within 2 minutes is not another
    -- loot opportunity. Missing GUID cannot be de-duplicated across opens.
    if guid and lastSourceGUID==guid and
        Number(now) and Number(lastSourceAt) and
        now-lastSourceAt>=0 and now-lastSourceAt<120 then
        opened=true;return
    end
    opened=true
    lastSourceGUID=guid;lastSourceAt=now or 0
    local location=Location()
    local area=Area(location)
    -- Only sample a real map coordinate from an outdoor loot event.
    local point=area and LootPoint(location) or nil
    local sourceKey,sourceName,creature=Source(guid)
    local sourceRow
    if area then
        area.windows=Add(area.windows,1)
        if sourceKey and creature then
            sourceRow=area.sources[sourceKey]
            if not sourceRow and Count(area.sources)<MAX_SOURCES then
                sourceRow={name=sourceName,windows=0,items={}}
                area.sources[sourceKey]=sourceRow
            elseif not sourceRow then s.limitReached=true end
            if sourceRow then
                sourceRow.windows=Add(sourceRow.windows,1)
                if sourceRow.name:match("^Source #") and
                    not sourceName:match("^Source #") then
                    sourceRow.name=sourceName
                end
            end
        end
    end
    s.windows=Add(s.windows,1)
    s.observedItems=Add(s.observedItems,total)
    for id,amount in pairs(counts) do
        local item=Item(s,id,links[id])
        if item then
            item.quantity=Add(item.quantity,amount)
            item.windows=Add(item.windows,1)
            if area then
                local entry=area.items[id]
                if not entry and Count(area.items)<MAX_AREA_ITEMS then
                    entry={quantity=0,windows=0}
                    area.items[id]=entry
                elseif not entry then s.limitReached=true end
                if entry then
                    entry.quantity=Add(entry.quantity,amount)
                    entry.windows=Add(entry.windows,1)
                    RememberSpot(entry,point)
                end
                if sourceRow then
                    local hit=sourceRow.items[id]
                    if not hit then hit={windows=0,quantity=0};
                        sourceRow.items[id]=hit end
                    hit.windows=Add(hit.windows,1)
                    hit.quantity=Add(hit.quantity,amount)
                    RememberSpot(hit,point)
                end
            end
        end
    end
    lastAreaKey=area and location.key or nil
    lastSourceKey=sourceRow and sourceKey or nil
    if type(ChalkBox_JournalNoteLoot)=="function" then
        pcall(ChalkBox_JournalNoteLoot,total,counts,
            area and location.key or nil,
            area and location.name or nil)
    end
end
local function Interval(hits,n)
    if not Number(n) or n<=0 then return end
    local p=hits/n
    local z=1.96
    local d=1+z*z/n
    local center=(p+z*z/(2*n))/d
    local half=z*math.sqrt(p*(1-p)/n+z*z/(4*n*n))/d
    return 100*p,100*math.max(0,center-half),
        100*math.min(1,center+half)
end
function ChalkBox_DropOptions()
    local s=State()
    return {enabled=s.enabled~=false,tooltip=s.tooltip~=false,
        mapButton=s.mapButton~=false,watched=Count(s.items),
        windows=s.windows,items=s.observedItems,areas=Count(s.areas),
        limitReached=s.limitReached==true,legacyWindows=s.legacyWindows or 0}
end
function ChalkBox_DropSetOption(key,on)
    if key~="enabled" and key~="tooltip" and
        key~="mapButton" then return false end
    State()[key]=on==true
    if key=="mapButton" and type(ChalkBox_MapDiscoveriesRefresh)=="function" then
        pcall(ChalkBox_MapDiscoveriesRefresh)
    end
    return true
end
-- Legacy commands remain as optional labels/reference entries; every item
-- is now tracked automatically, with no 32-item watchlist requirement.
function ChalkBox_DropWatch(item,name)
    local id=ItemID(item)
    if not id then return false,"Provide an item ID or link" end
    local s=State()
    local row=Item(s,id,item)
    if not row then return false,"Journal capacity reached" end
    if type(name)=="string" and name~="" then row.name=name:sub(1,96) end
    return true,"Item #"..id.." indexed; all loot is recorded automatically"
end
function ChalkBox_DropUnwatch(item)
    -- No removal: dropping a watch should never silently delete history.
    return false,"Automatic journal keeps all observed items. Clear via settings."
end
function ChalkBox_DropReference(item,rate)
    local id=ItemID(item)
    if not id then return false end
    local s=State()
    local row=s.items[id]
    if not row then return false end
    if rate==nil then row.reference=nil;return true end
    local n=tonumber(rate)
    if not Number(n) or n>100 then return false end
    row.reference=n;return true
end
function ChalkBox_DropCalculate(rate,attempts)
    rate=tonumber(rate);attempts=tonumber(attempts)
    if not Number(rate) or rate>100 or not Integer(attempts) or
        attempts>100000 then return end
    return 100*(1-math.pow(1-rate/100,attempts))
end
function ChalkBox_DropRead(item,areaKey,sourceKey)
    local id=ItemID(item)
    local s=State()
    local row=id and s.items[id]
    if not row then return end
    local result={id=id,name=row.name,quantity=row.quantity or 0,
        windows=row.windows or 0,reference=row.reference,
        legacy=row.legacy}
    if areaKey and type(s.areas[areaKey])=="table" then
        local area=s.areas[areaKey]
        local hit=area.items[id]
        if not hit then return result end
        result.areaQuantity=hit.quantity
        result.areaWindows=hit.windows
        result.locations=ReadSpots(hit)
        if sourceKey and type(area.sources[sourceKey])=="table" then
            local source=area.sources[sourceKey]
            local observed=source.items[id]
            local hits=observed and observed.windows or 0
            result.locations=ReadSpots(observed)
            if source.windows>0 then
                result.sourceName=source.name
                result.hits=hits
                result.attempts=source.windows
                result.rate,result.low,result.high=Interval(
                    hits,source.windows)
            end
        end
    end
    return result
end
function ChalkBox_DropArea(mapID)
    local s=State()
    if not Integer(mapID) then return end
    return s.areas["z:"..mapID]
end
function ChalkBox_DropMapData(mapID)
    local s=State()
    local result={zone=ChalkBox_DropArea(mapID),dungeons={}}
    if not Integer(mapID) then return result end
    for key,area in pairs(s.areas) do
        if area.kind=="dungeon" and
            (area.entranceZoneID==mapID or area.mapID==mapID) then
            result.dungeons[#result.dungeons+1]={key=key,
                name=area.name,items=Count(area.items),area=area}
        end
    end
    table.sort(result.dungeons,function(a,b)
        if a.name==b.name then return a.key<b.key end
        return a.name<b.name
    end)
    return result
end
-- A read-only location index for the discoveries browser. Data comes
-- entirely from this character's existing observation history.
function ChalkBox_DropVisitedAreas(kind)
    local areas=State().areas
    local result={}
    for key,area in pairs(areas) do
        if type(area)=="table" and (not kind or area.kind==kind) then
            result[#result+1]={
                key=key,kind=area.kind,name=area.name or key,
                mapID=area.mapID,entranceZoneID=area.entranceZoneID,
                windows=area.windows or 0,items=Count(area.items or {})
            }
        end
    end
    table.sort(result,function(a,b)
        if a.name==b.name then return a.key<b.key end
        return a.name<b.name
    end)
    return result
end
function ChalkBox_DropAreaInfo(key)
    local area=State().areas[key]
    if type(area)~="table" then return end
    return {key=key,kind=area.kind,name=area.name or key,
        windows=area.windows or 0,items=Count(area.items or {}),
        mapID=area.mapID,entranceZoneID=area.entranceZoneID}
end
function ChalkBox_DropAreaItems(key,sourceKey,search)
    local area=State().areas[key]
    if not area then return {} end
    local result={}
    local chosen=sourceKey and area.sources[sourceKey] or nil
    local rows=chosen and chosen.items or area.items
    search=type(search)=="string" and search:lower() or ""
    for id,counts in pairs(rows or {}) do
        local item=ChalkBox_DropRead(id,key,sourceKey)
        if item and (search=="" or item.name:lower():find(
                search,1,true) or id:find(search,1,true)) then
            local sourceName,hits,attempts,rate=item.sourceName,
                item.hits,item.attempts,item.rate
            if not sourceKey then
                -- A single identified mob provides a useful rate while
                -- browsing the whole zone. With several mob types, NEVER
                -- conflate their separate loot pools into one percentage.
                local onlyKey,ambiguous
                for mobKey,source in pairs(area.sources or {}) do
                    if type(source)=="table" and source.items and
                        source.items[id] then
                        if onlyKey then ambiguous=true;break end
                        onlyKey=mobKey
                    end
                end
                if onlyKey and not ambiguous then
                    local detail=ChalkBox_DropRead(id,key,onlyKey)
                    if detail and detail.attempts then
                        sourceName=detail.sourceName
                        hits,attempts,rate=
                            detail.hits,detail.attempts,detail.rate
                    end
                end
            end
            -- Optional read-only AuctionSense bridge. Never infer sale values
            -- from old scans or from equipment with mixed variants.
            local auctionTotal,auctionDetail
            if type(ChalkBox_AuctionValue)=="function" then
                local ok,value,detail=pcall(ChalkBox_AuctionValue,id,
                    counts.quantity or 0)
                if ok and Number(value) and type(detail)=="table" then
                    auctionTotal,auctionDetail=value,detail
                end
            end
            result[#result+1]={
                id=id,name=item.name,
                marketEstimateCopper=auctionTotal,
                marketScanAge=auctionDetail and auctionDetail.age or nil,
                quantity=counts.quantity or 0,
                windows=counts.windows or 0,
                hits=hits,rate=rate,attempts=attempts,
                low=item.low,high=item.high,
                sourceName=sourceName,
                multipleSources=not sourceName,
                locations=item.locations,
            }
        end
    end
    table.sort(result,function(a,b)
        if a.quantity==b.quantity then return a.name<b.name end
        return a.quantity>b.quantity
    end)
    return result
end
function ChalkBox_DropSources(key)
    local area=State().areas[key]
    if not area then return {} end
    local result={}
    for id,source in pairs(area.sources) do
        result[#result+1]={key=id,name=source.name,
            windows=source.windows}
    end
    table.sort(result,function(a,b)
        if a.windows==b.windows then return a.name<b.name end
        return a.windows>b.windows
    end)
    return result
end
function ChalkBox_DropTooltip(tooltip,link)
    local s=State()
    if not s.enabled or s.tooltip==false or not tooltip or
        type(tooltip.AddLine)~="function" then return false end
    local owner=type(tooltip.GetOwner)=="function" and tooltip:GetOwner()
    local frameName=owner and type(owner.GetName)=="function" and
        owner:GetName()
    if type(frameName)~="string" or
        not frameName:match("^LootButton") then return false end
    local item=ChalkBox_DropRead(link,lastAreaKey,lastSourceKey)
    if not item then return false end
    if type(tooltip.GetName)=="function" and
        type(tooltip.NumLines)=="function" then
        local name=tooltip:GetName()
        if type(name)=="string" then
            for i=1,tooltip:NumLines() do
                local row=_G[name.."TextLeft"..i]
                if row and row.GetText and
                    row:GetText()=="Drop Journal" then
                    return false
                end
            end
        end
    end
    local function Line(text,role,r,g,b)
        if type(ChalkBox_TipColor)=="function" then
            r,g,b=ChalkBox_TipColor(role)
        end
        tooltip:AddLine(text,r,g,b,true)
    end
    -- Separate the journal from Blizzard's item details. Counts are blue;
    -- observed frequencies are informational, never a "good drop chance".
    Line(" ","muted",0.65,0.70,0.73)
    Line("Drop Journal","title",0.94,0.76,0.42)
    Line(("%d found  ·  %d loots"):format(
        item.quantity,item.windows),"count",0.51,0.76,0.98)
    if item.rate then
        Line(("%s  ·  %d/%d  ·  %.1f%% observed"):format(
            item.sourceName or "Creature",item.hits,item.attempts,item.rate),
            "info",0.40,0.83,0.78)
    end
    if item.legacy and item.legacy.quantity>0 then
        Line(("Earlier: %d"):format(item.legacy.quantity),
            "muted",0.65,0.70,0.73)
    end
    if item.reference then
        Line(("Manual reference: %.2f%%"):format(item.reference),
            "warning",0.98,0.66,0.33)
    end
    Line("Personal sample  ·  not official odds",
        "muted",0.65,0.70,0.73)
    if type(tooltip.Show)=="function" then tooltip:Show() end
    return true
end
function ChalkBox_DropCommand(input)
    local cmd,args=(input or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd=string.lower(cmd or "")
    if cmd=="on" or cmd=="off" then
        ChalkBox_DropSetOption("enabled",cmd=="on")
        Note("Automatic drop sampling "..cmd..".")
    elseif cmd=="map" and (args=="on" or args=="off") then
        ChalkBox_DropSetOption("mapButton",args=="on")
        Note("Map Discoveries button "..args..".")
    elseif cmd=="tooltip" and (args=="on" or args=="off") then
        ChalkBox_DropSetOption("tooltip",args=="on")
        Note("Loot tooltip observations "..args..".")
    elseif cmd=="watch" then
        local ok,msg=ChalkBox_DropWatch(args,args:match("%[([^%]]+)%]"))
        Note(msg or (ok and "Indexed" or "Invalid item"))
    elseif cmd=="unwatch" then
        Note("No manual watchlist now. Disable tracking or keep your full journal.")
    elseif cmd=="reference" then
        local id,rate=args:match("^(%d+)%s+([%d%.]+)$")
        Note(ChalkBox_DropReference(id,rate) and "Reference saved (unverified)."
            or "Item must be in your journal first.")
    elseif cmd=="chance" then
        local rate,tries=args:match("^([%d%.]+)%s+(%d+)$")
        local chance=ChalkBox_DropCalculate(rate,tries)
        Note(chance and (("%.2f%% chance in %s independent attempts"):format(
            chance,tries)) or "Usage: /chalk drops chance <percent> <attempts>")
    elseif cmd=="map" and
        (args=="flights on" or args=="flights off") then
        local on=args=="flights on"
        local ok=type(ChalkBox_DiscoveriesKnownFlightsSet)=="function" and
            ChalkBox_DiscoveriesKnownFlightsSet(on)
        Note(ok and ("Known flight paths "..(on and "shown." or "hidden."))
            or "Known flight path filter is unavailable.")
    elseif cmd=="map" and args=="flights status" then
        local fn=ChalkBox_DiscoveriesKnownFlightsStatus
        local info=type(fn)=="function" and fn() or nil
        if info then
            Note(("%d verified learned flight paths. %d visible pins."):format(
                info.verified,info.mapPins))
            Note(("Map Filter checkbox %s; overlay %s; map %s."):format(
                info.menuHook and "installed" or "unavailable",
                info.enabled and "ON" or "OFF",
                tostring(info.mapID or "not shown")))
            Note(("Positions: %d observed, %d zone nodes, %d projected; %d missing."):format(
                info.observedPositions or 0,info.directPositions or 0,
                info.projectedPositions or 0,info.unplacedNodes or 0))
            Note("Renderer: "..tostring(info.renderer or "unknown")..
                (info.rendererProblem and
                " ("..tostring(info.rendererProblem)..")." or "."))
            Note(("Last taxi read: %s (map %s, learned there %d)."):format(
                tostring(info.captureStatus or "unknown"),
                tostring(info.taxiMapID or "none"),info.taxiKnown or 0))
            if info.verified==0 then
                Note("No learned paths confirmed yet. Open a flight master's taxi map once.")
            elseif info.mapPins==0 then
                Note("Known paths saved but none located on this displayed map.")
            end
        else Note("Known flight path diagnostics unavailable.") end
    elseif cmd=="map" and args=="reset" then
        local ok=type(ChalkBox_MapDiscoveriesResetButton)=="function"
            and ChalkBox_MapDiscoveriesResetButton()
        Note(ok and "Discoveries map button restored to its default position."
            or "Open the world map and try again.")
    elseif cmd=="map" and args=="status" then
        local state=type(ChalkBox_MapDiscoveriesStatus)=="function"
            and ChalkBox_MapDiscoveriesStatus() or nil
        if state then
            Note(("Map button: frame %s, attached %s, visible %s, toggle %s, anchor %s."):format(
                tostring(state.frame),tostring(state.button),
                tostring(state.shown),tostring(state.allowed),
                tostring(state.anchor)))
            Note(("Tracking %s; %d mapped area(s); selected map %s."):format(
                state.tracking and "ON" or "OFF",state.areas,
                tostring(state.mapID or "unavailable")))
            if not state.button then
                Note("Open the world map once, then use /chalk drops map.")
            end
        else Note("Map diagnostics are unavailable in this client.") end
    elseif cmd=="open" or cmd=="map" then
        if type(ChalkBox_OpenMapDiscoveries)=="function" then
            if not ChalkBox_OpenMapDiscoveries() then
                Note("Open the World Map, then select Discoveries.")
            end
        else Note("Map Discoveries unavailable.") end
    elseif cmd=="status" or cmd=="" then
        local opt=ChalkBox_DropOptions()
        Note(("%s: %d items, %d loots, %d zones."):format(
            opt.enabled and "ON" or "OFF",opt.watched,opt.windows,opt.areas))
        if opt.legacyWindows>0 then
            Note(opt.legacyWindows.." earlier loots (zone unknown).")
        end
        if opt.limitReached then Note("Journal capacity reached for some new entries.") end
    else
        Note("/chalk drops on|off | map | map on|off | map status | status")
        Note("/chalk drops chance <percent> <tries>")
    end
end
for _,name in ipairs({"LOOT_READY","LOOT_OPENED","LOOT_CLOSED",
    "PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA"}) do
    frame:RegisterEvent(name)
end
frame:SetScript("OnEvent",function(_,event)
    if event=="LOOT_CLOSED" then
        opened=false;lastAreaKey=nil;lastSourceKey=nil
    elseif event=="LOOT_OPENED" or event=="LOOT_READY" then
        Capture()
    elseif event=="PLAYER_ENTERING_WORLD" or
        event=="ZONE_CHANGED_NEW_AREA" then
        Location()
    end
end)
