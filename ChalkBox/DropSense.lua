-- ChalkBox DropSense 1.11: automatic, local-only discovery journal.
-- Counts only visible loot windows and item quantities, not unseen kills.
-- An observed frequency is reported ONLY for a known single creature source.
local addonName=...
local MAX_ITEMS,MAX_AREAS,MAX_SOURCES,MAX_AREA_ITEMS=5000,240,150,750
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
                end
                if sourceRow then
                    local hit=sourceRow.items[id]
                    if not hit then hit={windows=0,quantity=0};
                        sourceRow.items[id]=hit end
                    hit.windows=Add(hit.windows,1)
                    hit.quantity=Add(hit.quantity,amount)
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
        if sourceKey and type(area.sources[sourceKey])=="table" then
            local source=area.sources[sourceKey]
            local observed=source.items[id]
            local hits=observed and observed.windows or 0
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
    local from=sourceKey and area.sources[sourceKey]
    local rows=from and from.items or area.items
    search=type(search)=="string" and search:lower() or ""
    for id,counts in pairs(rows or {}) do
        local item=ChalkBox_DropRead(id,key,sourceKey)
        if item and (search=="" or item.name:lower():find(
                search,1,true) or id:find(search,1,true)) then
            result[#result+1]={
                id=id,name=item.name,
                quantity=counts.quantity or 0,
                windows=counts.windows or 0,
                rate=item.rate,attempts=item.attempts,low=item.low,
                high=item.high,sourceName=item.sourceName}
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
                    row:GetText()=="CHALKBOX | DROP JOURNAL" then
                    return false
                end
            end
        end
    end
    tooltip:AddLine("CHALKBOX | DROP JOURNAL",0.86,0.66,0.38)
    tooltip:AddLine(("%d collected in %d observed loot windows"):format(
        item.quantity,item.windows),0.43,0.83,0.73,true)
    if item.rate then
        tooltip:AddLine(("%s: %d/%d readable windows (%.1f%%)"):format(
            item.sourceName or "Creature",item.hits,item.attempts,item.rate),
            0.72,0.82,0.74,true)
        tooltip:AddLine(("95%% interval: %.1f–%.1f%%"):format(item.low,item.high),
            0.72,0.76,0.79,true)
    end
    if item.legacy and item.legacy.quantity>0 then
        tooltip:AddLine(("Earlier unsited observations: %d items"):format(
            item.legacy.quantity),0.72,0.76,0.79,true)
    end
    if item.reference then
        tooltip:AddLine(("Your reference: %.2f%% (unverified)"):format(
            item.reference),0.90,0.74,0.42,true)
    end
    tooltip:AddLine("Observed loot-window data; NOT official drop odds.",
        0.72,0.76,0.79,true)
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
            ChalkBox_OpenMapDiscoveries()
        else Note("Map Discoveries unavailable.") end
    elseif cmd=="status" or cmd=="" then
        local opt=ChalkBox_DropOptions()
        Note(("%s: %d unique items, %d loot windows, %d mapped areas."):format(
            opt.enabled and "ON" or "OFF",opt.watched,opt.windows,opt.areas))
        if opt.legacyWindows>0 then
            Note(opt.legacyWindows.." older windows kept separately; no retroactive zones.")
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
