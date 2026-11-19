-- ChalkBox Data Transfer: explicit file export/import (no settings or trading).
-- ChalkBoxTransfer companion's SavedVariables writes ChalkBoxTransfer.lua on
-- logout or /reload. File imports merge known evidence; no UI or transactions.
local MAX_COUNT=100000000
local MAX_MARKETS,MAX_HISTORY,MAX_SALES=6,7,400
local function Int(n)
    return type(n)=="number" and n==n and n>=0 and n<=1e12 and n%1==0
end
local function Amount(n) return Int(n) and math.min(n,MAX_COUNT) or 0 end
local function Add(a,b) return math.min(MAX_COUNT,Amount(a)+Amount(b)) end
local function Str(s,max)
    return type(s)=="string" and #s>0 and #s<=(max or 160)
end
local function Copy(x,depth,budget,seen)
    local t=type(x)
    if t=="number" then return Int(x) and x or nil end
    if t=="string" then return #x<=512 and x or x:sub(1,512) end
    if t=="boolean" then return x end
    if t~="table" or depth>12 or budget.n>250000 then return nil end
    if seen[x] then return nil end
    seen[x]=true
    local out={}
    for k,v in pairs(x) do
        if budget.n>=250000 then break end
        if (type(k)=="number" and Int(k) or
            type(k)=="string" and #k<=160) then
            budget.n=budget.n+1
            local item=Copy(v,depth+1,budget,seen)
            if item~=nil then out[k]=item end
        end
    end
    seen[x]=nil
    return out
end
local function Snapshot(t)
    return Copy(t,0,{n=0},{})
end
local function Count(t)
    local n=0
    for _ in pairs(type(t)=="table" and t or {}) do n=n+1 end
    return n
end
local function IsLoaded()
    if C_AddOns and type(C_AddOns.IsAddOnLoaded)=="function" then
        local ok,v=pcall(C_AddOns.IsAddOnLoaded,"ChalkBoxTransfer")
        if ok then return v==true end
    end
    if type(IsAddOnLoaded)=="function" then
        local ok,v=pcall(IsAddOnLoaded,"ChalkBoxTransfer")
        if ok then return v==true end
    end
    return false
end
local function Character()
    local name=type(UnitName)=="function" and UnitName("player")
    local realm=type(GetNormalizedRealmName)=="function" and
        GetNormalizedRealmName() or nil
    if not Str(realm) and type(GetRealmName)=="function" then
        realm=GetRealmName()
    end
    if not Str(name) or not Str(realm) then return nil end
    return realm:lower():gsub("%s+","").."|"..name:lower()
end
local function Node(s,key)
    if type(s[key])~="table" then s[key]={} end
    return s[key]
end
local function NewSourceID()
    local now=type(time)=="function" and time() or 0
    local clock=type(GetTime)=="function" and GetTime() or 0
    local rand=math.random(1,1000000000)
    return tostring(now)..":"..tostring(math.floor(clock*1000))..
        ":"..tostring(rand)
end
-- Count-only event components. Provenance prevents importing the same
-- cumulative data twice or counting a previous machine's baseline again.
local function PartFromDrops(d)
    local part={windows=Amount(d.windows),observedItems=Amount(d.observedItems),
        items={},areas={}}
    for id,row in pairs(type(d.items)=="table" and d.items or {}) do
        if Str(tostring(id),32) and type(row)=="table" then
            part.items[id]={quantity=Amount(row.quantity),
                windows=Amount(row.windows)}
        end
    end
    for key,area in pairs(type(d.areas)=="table" and d.areas or {}) do
        if Str(key,100) and type(area)=="table" then
            local a={windows=Amount(area.windows),items={},sources={}}
            for id,row in pairs(type(area.items)=="table" and area.items or {}) do
                if type(row)=="table" then
                    a.items[id]={quantity=Amount(row.quantity),
                        windows=Amount(row.windows)}
                end
            end
            for source,row in pairs(type(area.sources)=="table" and area.sources or {}) do
                if Str(source,80) and type(row)=="table" then
                    local r={windows=Amount(row.windows),items={}}
                    for id,item in pairs(type(row.items)=="table" and row.items or {}) do
                        if type(item)=="table" then
                            r.items[id]={quantity=Amount(item.quantity),
                                windows=Amount(item.windows)}
                        end
                    end
                    a.sources[source]=r
                end
            end
            part.areas[key]=a
        end
    end
    return part
end
local function MaxPair(dst,src)
    dst.quantity=math.max(Amount(dst.quantity),Amount(src.quantity))
    dst.windows=math.max(Amount(dst.windows),Amount(src.windows))
end
local function MaxPart(dst,src)
    dst.windows=math.max(Amount(dst.windows),Amount(src.windows))
    dst.observedItems=math.max(Amount(dst.observedItems),Amount(src.observedItems))
    for id,row in pairs(type(src.items)=="table" and src.items or {}) do
        if type(row)=="table" and Count(dst.items)<5100 then
            MaxPair(Node(dst.items,id),row)
        end
    end
    for key,area in pairs(type(src.areas)=="table" and src.areas or {}) do
        if type(area)=="table" and Count(dst.areas)<250 then
            local target=Node(dst.areas,key)
            target.windows=math.max(Amount(target.windows),Amount(area.windows))
            local items=Node(target,"items")
            for id,row in pairs(type(area.items)=="table" and area.items or {}) do
                if type(row)=="table" and Count(items)<760 then
                    MaxPair(Node(items,id),row)
                end
            end
            local sources=Node(target,"sources")
            for source,sourceRow in pairs(type(area.sources)=="table" and area.sources or {}) do
                if type(sourceRow)=="table" and Count(sources)<155 then
                    local r=Node(sources,source)
                    r.windows=math.max(Amount(r.windows),Amount(sourceRow.windows))
                    local hits=Node(r,"items")
                    for id,item in pairs(type(sourceRow.items)=="table" and sourceRow.items or {}) do
                        if type(item)=="table" and Count(hits)<760 then
                            MaxPair(Node(hits,id),item)
                        end
                    end
                end
            end
        end
    end
end
local function Tracking()
    if type(ChalkBoxZoneDB)~="table" then ChalkBoxZoneDB={} end
    local t=ChalkBoxZoneDB.transferDrops
    if type(t)~="table" or t.version~=1 then
        t={version=1,localID=NewSourceID(),parts={}}
        ChalkBoxZoneDB.transferDrops=t
        t.parts[t.localID]=PartFromDrops(ChalkBoxZoneDB.dropSense or {})
    end
    if type(t.parts)~="table" then t.parts={} end
    if not Str(t.localID,80) then t.localID=NewSourceID() end
    if type(t.parts[t.localID])~="table" then
        t.parts[t.localID]={windows=0,observedItems=0,
            items={},areas={}}
    end
    return t
end
function ChalkBox_TransferPrepareDrop()
    Tracking()
end
function ChalkBox_TransferRecordDrop(counts,total,areaKey,sourceKey)
    local t=Tracking()
    local part=t.parts[t.localID]
    part.windows=Add(part.windows,1)
    part.observedItems=Add(part.observedItems,total)
    local area
    if Str(areaKey,100) then
        area=Node(Node(part,"areas"),areaKey)
        area.windows=Add(area.windows,1)
    end
    local source
    if area and Str(sourceKey,80) then
        source=Node(Node(area,"sources"),sourceKey)
        source.windows=Add(source.windows,1)
    end
    for id,quantity in pairs(type(counts)=="table" and counts or {}) do
        if Str(tostring(id),32) then
            local g=Node(Node(part,"items"),id)
            g.windows=Add(g.windows,1);g.quantity=Add(g.quantity,quantity)
            if area then
                local a=Node(Node(area,"items"),id)
                a.windows=Add(a.windows,1);a.quantity=Add(a.quantity,quantity)
            end
            if source then
                local r=Node(Node(source,"items"),id)
                r.windows=Add(r.windows,1);r.quantity=Add(r.quantity,quantity)
            end
        end
    end
end
local function MergeLocations(dst,src)
    if type(src)~="table" then return end
    if type(dst.locations)~="table" then dst.locations={} end
    for _,point in ipairs(src) do
        if type(point)=="table" and Int(point.x) and Int(point.y) and
            point.x<=1000 and point.y<=1000 then
            local match
            for _,p in ipairs(dst.locations) do
                if p.x==point.x and p.y==point.y then match=p;break end
            end
            if match then
                match.count=math.max(Amount(match.count),Amount(point.count))
            else
                dst.locations[#dst.locations+1]={x=point.x,y=point.y,
                    count=Amount(point.count)}
            end
        end
    end
    while #dst.locations>6 do table.remove(dst.locations,1) end
end
local function MergeDropMetadata(target,foreign)
    for id,row in pairs(type(foreign.items)=="table" and foreign.items or {}) do
        if type(row)=="table" and Count(target.items)<5100 then
            local localRow=Node(target.items,id)
            if not Str(localRow.name) and Str(row.name,120) then localRow.name=row.name end
            if not localRow.reference and row.reference then
                localRow.reference=Snapshot(row.reference)
            end
        end
    end
    for key,area in pairs(type(foreign.areas)=="table" and foreign.areas or {}) do
        if type(area)=="table" and Count(target.areas)<250 then
            local a=Node(target.areas,key)
            for _,field in ipairs({"kind","name","mapID","instanceID",
                "difficulty","entranceZoneID","entranceZoneName"}) do
                if a[field]==nil and (type(area[field])=="string" or
                    Int(area[field])) then a[field]=area[field] end
            end
            for id,row in pairs(type(area.items)=="table" and area.items or {}) do
                if type(row)=="table" and Count(Node(a,"items"))<760 then
                    MergeLocations(Node(a.items,id),row.locations)
                end
            end
            for src,source in pairs(type(area.sources)=="table" and area.sources or {}) do
                if type(source)=="table" and Count(Node(a,"sources"))<155 then
                    local s=Node(a.sources,src)
                    if not Str(s.name) and Str(source.name) then s.name=source.name end
                    for id,row in pairs(type(source.items)=="table" and source.items or {}) do
                        if type(row)=="table" and Count(Node(s,"items"))<760 then
                            MergeLocations(Node(s.items,id),row.locations)
                        end
                    end
                end
            end
        end
    end
end
local function ApplyTotals(d,parts)
    d.windows,d.observedItems=0,0
    for _,r in pairs(d.items) do
        if type(r)=="table" then r.windows=0;r.quantity=0 end
    end
    for _,a in pairs(d.areas) do
        if type(a)=="table" then
            a.windows=0
            for _,r in pairs(type(a.items)=="table" and a.items or {}) do
                if type(r)=="table" then r.windows=0;r.quantity=0 end
            end
            for _,s in pairs(type(a.sources)=="table" and a.sources or {}) do
                if type(s)=="table" then
                    s.windows=0
                    for _,r in pairs(type(s.items)=="table" and s.items or {}) do
                        if type(r)=="table" then r.windows=0;r.quantity=0 end
                    end
                end
            end
        end
    end
    for _,part in pairs(parts) do
        d.windows=Add(d.windows,part.windows)
        d.observedItems=Add(d.observedItems,part.observedItems)
        for id,row in pairs(type(part.items)=="table" and part.items or {}) do
            local r=Node(d.items,id)
            r.quantity=Add(r.quantity,row.quantity);r.windows=Add(r.windows,row.windows)
            if not Str(r.name) then r.name="Item #"..tostring(id) end
        end
        for key,area in pairs(type(part.areas)=="table" and part.areas or {}) do
            local a=Node(d.areas,key)
            a.windows=Add(a.windows,area.windows)
            for id,row in pairs(type(area.items)=="table" and area.items or {}) do
                local r=Node(Node(a,"items"),id)
                r.quantity=Add(r.quantity,row.quantity)
                r.windows=Add(r.windows,row.windows)
            end
            for src,source in pairs(type(area.sources)=="table" and area.sources or {}) do
                local s=Node(Node(a,"sources"),src)
                s.windows=Add(s.windows,source.windows)
                for id,row in pairs(type(source.items)=="table" and source.items or {}) do
                    local r=Node(Node(s,"items"),id)
                    r.quantity=Add(r.quantity,row.quantity)
                    r.windows=Add(r.windows,row.windows)
                end
            end
        end
    end
end
local function MergeDrops(foreign,foreignParts)
    local t=Tracking()
    local d=ChalkBoxZoneDB.dropSense
    if type(d)~="table" or d.version~=2 then
        d={version=2,items={},areas={},windows=0,observedItems=0}
        ChalkBoxZoneDB.dropSense=d
    end
    d.items=type(d.items)=="table" and d.items or {}
    d.areas=type(d.areas)=="table" and d.areas or {}
    MergeDropMetadata(d,foreign)
    for id,part in pairs(type(foreignParts)=="table" and foreignParts or {}) do
        if Str(id,80) and type(part)=="table" and Count(t.parts)<16 then
            if not t.parts[id] then
                t.parts[id]={windows=0,observedItems=0,items={},areas={}}
            end
            MaxPart(t.parts[id],part)
        end
    end
    -- A later import from a copied installation starts a NEW local branch.
    -- Historical contributions keep their original IDs and are not doubled.
    ApplyTotals(d,t.parts)
    t.localID=NewSourceID()
    while t.parts[t.localID] do t.localID=NewSourceID() end
    t.parts[t.localID]={windows=0,observedItems=0,items={},areas={}}
end
local function MergeHistory(a,b)
    local found,items={},{}
    for _,history in ipairs({a,b}) do
        for _,sample in ipairs(type(history)=="table" and history or {}) do
            if type(sample)=="table" and Int(sample.t) and Int(sample.low) then
                local key=tostring(sample.t)..":"..tostring(sample.low)
                if not found[key] then
                    items[#items+1]={t=sample.t,low=sample.low}
                    found[key]=true
                end
            end
        end
    end
    table.sort(items,function(x,y)
        if x.t==y.t then return x.low<y.low end
        return x.t<y.t
    end)
    while #items>MAX_HISTORY do table.remove(items,1) end
    return items
end
local function MergeMarkets(src)
    if type(src)~="table" or src.version~=1 then return 0 end
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    local db=ChalkBoxDB.auctionSense
    if type(db)~="table" or db.version~=1 then
        db={version=1,markets={},order={},tooltip=true,nextAllowed=0}
        ChalkBoxDB.auctionSense=db
    end
    db.markets=type(db.markets)=="table" and db.markets or {}
    local merged=0
    for key,incoming in pairs(type(src.markets)=="table" and src.markets or {}) do
        if Str(key,128) and type(incoming)=="table" and
            Int(incoming.scannedAt) then
            local current=db.markets[key]
            local newer=type(current)~="table" or
                Amount(incoming.scannedAt)>Amount(current.scannedAt) or
                (incoming.scannedAt==current.scannedAt and
                 incoming.source=="full" and current.source~="full")
            local winning=newer and Snapshot(incoming) or Snapshot(current)
            local older=newer and current or incoming
            if type(winning)=="table" then
                winning.items=type(winning.items)=="table" and winning.items or {}
                for itemID,item in pairs(winning.items) do
                    if type(item)=="table" then
                        local old=type(older)=="table" and
                            type(older.items)=="table" and older.items[itemID]
                        if type(old)=="table" then
                            item.history=MergeHistory(item.history,old.history)
                            if not item.mixed and not old.mixed and
                                not item.detailAverage and old.detailAverage and
                                Int(old.detailAt) then
                                item.detailAverage=old.detailAverage
                                item.detailListings=old.detailListings
                                item.detailAt=old.detailAt
                            end
                        end
                    end
                end
                db.markets[key]=winning
                merged=merged+1
            end
        end
    end
    local keys={}
    for key,market in pairs(db.markets) do
        keys[#keys+1]={key=key,t=Amount(market.scannedAt)}
    end
    table.sort(keys,function(a,b)
        if a.t==b.t then return a.key<b.key end
        return a.t<b.t
    end)
    while #keys>MAX_MARKETS do
        local victim=table.remove(keys,1)
        db.markets[victim.key]=nil
    end
    db.order={}
    for _,r in ipairs(keys) do db.order[#db.order+1]=r.key end
    return merged
end
local function SameSale(a,b)
    return type(a)=="table" and type(b)=="table" and
        a.sig==b.sig and a.ordinal==b.ordinal and
        Int(a.expiryBucket) and Int(b.expiryBucket) and
        math.abs(a.expiryBucket-b.expiryBucket)<=1
end
local function MergeSales(src)
    if type(src)~="table" or src.version~=1 then return 0 end
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    local root=ChalkBoxDB.auctionInsights
    if type(root)~="table" or root.version~=1 then
        root={version=1,characters={}}
        ChalkBoxDB.auctionInsights=root
    end
    root.characters=type(root.characters)=="table" and root.characters or {}
    local added=0
    for key,ledger in pairs(type(src.characters)=="table" and src.characters or {}) do
        if Str(key,180) and type(ledger)=="table" then
            local dst=Node(root.characters,key)
            local sales=Node(dst,"sales")
            for _,sale in ipairs(type(ledger.sales)=="table" and ledger.sales or {}) do
                if type(sale)=="table" and Str(sale.sig,512) and
                    Int(sale.ordinal) and Int(sale.expiryBucket) and
                    Int(sale.gross) and Int(sale.cut) and
                    Int(sale.deposit) and Int(sale.at) then
                    local found=false
                    for _,existing in ipairs(sales) do
                        if SameSale(existing,sale) then found=true;break end
                    end
                    if not found then
                        sales[#sales+1]=Snapshot(sale)
                        added=added+1
                    end
                end
            end
            table.sort(sales,function(a,b)
                if a.at==b.at then return tostring(a.name)<tostring(b.name) end
                return a.at>b.at
            end)
            while #sales>MAX_SALES do table.remove(sales) end
        end
    end
    return added
end
local function MergeFlights(src)
    if type(src)~="table" or src.version~=1 then return 0 end
    local d=ChalkBoxZoneDB.discoveriesKnownFlights
    if type(d)~="table" or d.version~=1 then
        d={version=1,enabled=true,nodes={},revision=0}
        ChalkBoxZoneDB.discoveriesKnownFlights=d
    end
    d.nodes=type(d.nodes)=="table" and d.nodes or {}
    local added=0
    for key,node in pairs(type(src.nodes)=="table" and src.nodes or {}) do
        if Str(tostring(key),60) and d.nodes[key]==nil and
            type(node)=="table" then
            d.nodes[key]=Snapshot(node);added=added+1
        end
    end
    if added>0 then d.revision=Amount(d.revision)+1 end
    return added
end
local lastMessage="No transfer created yet."
local function StatusCount(d)
    return Count(type(d)=="table" and d or {})
end
function ChalkBox_TransferStatus()
    local transfer=type(ChalkBoxTransferDB)=="table" and ChalkBoxTransferDB or nil
    return {companion=IsLoaded(),file=transfer and transfer.kind=="ChalkBoxData",
        exportedAt=transfer and transfer.exportedAt,
        marketCount=transfer and transfer.auction and
            StatusCount(transfer.auction.markets) or 0,
        saleCharacters=transfer and transfer.sales and
            StatusCount(transfer.sales.characters) or 0,
        discoveryAreas=transfer and transfer.drops and
            StatusCount(transfer.drops.areas) or 0,
        character=transfer and transfer.character,
        message=lastMessage}
end
function ChalkBox_TransferExport()
    if not IsLoaded() then
        return false,"ChalkBoxTransfer companion addon isn't enabled."
    end
    local character=Character()
    if not character then return false,"Character/realm isn't ready." end
    local parts=Tracking()
    local now=type(time)=="function" and time() or 0
    _G.ChalkBoxTransferDB={
        kind="ChalkBoxData",version=1,exportedAt=Int(now) and now or 0,
        character=character,
        auction=Snapshot(ChalkBoxDB and ChalkBoxDB.auctionSense),
        sales=Snapshot(ChalkBoxDB and ChalkBoxDB.auctionInsights),
        drops=Snapshot(ChalkBoxZoneDB and ChalkBoxZoneDB.dropSense),
        dropParts=Snapshot(parts.parts),
        flights=Snapshot(ChalkBoxZoneDB and ChalkBoxZoneDB.discoveriesKnownFlights),
    }
    lastMessage="Export prepared. /reload or log out to write ChalkBoxTransfer.lua."
    return true,lastMessage
end
function ChalkBox_TransferImport()
    if not IsLoaded() then return false,
        "ChalkBoxTransfer companion addon isn't enabled." end
    local data=ChalkBoxTransferDB
    if type(data)~="table" or data.kind~="ChalkBoxData" or
        data.version~=1 then return false,
        "No valid transfer file. Exit WoW, copy the file, then log in." end
    if type(data.auction)~="table" or type(data.sales)~="table" or
        type(data.drops)~="table" or type(data.dropParts)~="table" then
        return false,"Incomplete transfer; no changes made." end
    -- Deep-copy first: imports never mutate the file or share table aliases.
    local copied=Snapshot(data)
    if type(copied)~="table" or
        type(copied.dropParts)~="table" then
        return false,"Transfer exceeds safe limits or is malformed." end
    local markets=MergeMarkets(copied.auction)
    local sales=MergeSales(copied.sales)
    local dropStatus="discovery data skipped (different character)"
    if Character() and copied.character==Character() then
        MergeDrops(copied.drops,copied.dropParts)
        local flights=MergeFlights(copied.flights)
        dropStatus="discoveries merged; "..flights.." new flight nodes"
    end
    if type(ChalkBox_IntelInvalidate)=="function" then
        pcall(ChalkBox_IntelInvalidate)
    end
    if type(ChalkBox_AuctionRefreshUI)=="function" then
        pcall(ChalkBox_AuctionRefreshUI)
    end
    lastMessage=("Merged %d market snapshots, %d sale receipts; %s."):format(
        markets,sales,dropStatus)
    return true,lastMessage
end
