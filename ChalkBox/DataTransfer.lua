-- Move AuctionSense and Discoveries between computers.
-- One explicit export, one explicit import. The companion addon only gives
-- WoW a file to write. This module does not keep a second copy of loot
-- counts, and it never lowers a number you already have.
local MAX_COUNT=100000000
local MAX_MARKETS,MAX_HISTORY,MAX_SALES=6,7,400
local function Int(n)
    return type(n)=="number" and n==n and n>=0 and n<=1e12 and n%1==0
end
local function Amount(n) return Int(n) and math.min(n,MAX_COUNT) or 0 end
local function Stamp(n) return Int(n) and n or 0 end
local function Str(s,max)
    return type(s)=="string" and #s>0 and #s<=(max or 160)
end
local function Copy(x,depth,budget,seen)
    local t=type(x)
    if t=="number" then return Int(x) and x or nil end
    if t=="string" then return #x<=512 and x or x:sub(1,512) end
    if t=="boolean" then return x end
    if t~="table" then return nil end
    if depth>12 or budget.n>2000000 then
        budget.tooLarge=true
        return nil
    end
    if seen[x] then return nil end
    seen[x]=true
    local out={}
    for k,v in pairs(x) do
        if budget.n>=2000000 then budget.tooLarge=true;break end
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
    if t==nil then return nil end
    local budget={n=0,tooLarge=false}
    local result=Copy(t,0,budget,{})
    return not budget.tooLarge and result or nil
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
-- Kept so DropSense can call them. They no longer rewrite discoveries.
function ChalkBox_TransferPrepareDrop() return true end
function ChalkBox_TransferRecordDrop() return true end
local function MaxPair(dst,src)
    if type(src)~="table" then return end
    dst.quantity=math.max(Amount(dst.quantity),Amount(src.quantity))
    dst.windows=math.max(Amount(dst.windows),Amount(src.windows))
    if not Str(dst.name) and Str(src.name,120) then dst.name=src.name end
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
            elseif #dst.locations<6 then
                dst.locations[#dst.locations+1]={x=point.x,y=point.y,
                    count=Amount(point.count)}
            end
        end
    end
end
local function MaxTree(dst,src)
    if type(src)~="table" then return end
    dst.windows=math.max(Amount(dst.windows),Amount(src.windows))
    dst.observedItems=math.max(Amount(dst.observedItems),Amount(src.observedItems))
    dst.legacyWindows=math.max(Amount(dst.legacyWindows),Amount(src.legacyWindows))
    dst.items=type(dst.items)=="table" and dst.items or {}
    dst.areas=type(dst.areas)=="table" and dst.areas or {}
    for id,row in pairs(type(src.items)=="table" and src.items or {}) do
        if type(row)=="table" and Count(dst.items)<5100 then
            MaxPair(Node(dst.items,id),row)
            MergeLocations(Node(dst.items,id),row.locations)
        end
    end
    for key,area in pairs(type(src.areas)=="table" and src.areas or {}) do
        if type(area)=="table" and Count(dst.areas)<250 then
            local target=Node(dst.areas,key)
            target.windows=math.max(Amount(target.windows),Amount(area.windows))
            for _,field in ipairs({"kind","name","mapID","instanceID",
                "difficulty","entranceZoneID","entranceZoneName"}) do
                if target[field]==nil and (type(area[field])=="string" or
                    Int(area[field])) then target[field]=area[field] end
            end
            for id,row in pairs(type(area.items)=="table" and area.items or {}) do
                if type(row)=="table" and Count(Node(target,"items"))<760 then
                    local item=Node(target.items,id)
                    MaxPair(item,row)
                    MergeLocations(item,row.locations)
                end
            end
            for source,row in pairs(type(area.sources)=="table" and area.sources or {}) do
                if type(row)=="table" and Count(Node(target,"sources"))<155 then
                    local saved=Node(target.sources,source)
                    saved.windows=math.max(Amount(saved.windows),Amount(row.windows))
                    if not Str(saved.name) and Str(row.name,80) then
                        saved.name=row.name
                    end
                    for id,item in pairs(type(row.items)=="table" and row.items or {}) do
                        if type(item)=="table" and Count(Node(saved,"items"))<760 then
                            local hit=Node(saved.items,id)
                            MaxPair(hit,item)
                            MergeLocations(hit,item.locations)
                        end
                    end
                end
            end
        end
    end
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
        if Str(key,128) and type(incoming)=="table" and Int(incoming.scannedAt) then
            local current=db.markets[key]
            local newer=type(current)~="table" or
                Stamp(incoming.scannedAt)>Stamp(current.scannedAt) or
                (incoming.scannedAt==current.scannedAt and
                 incoming.source=="full" and current.source~="full")
            local winning=newer and Snapshot(incoming) or Snapshot(current)
            local older=newer and current or incoming
            if type(winning)=="table" then
                winning.items=type(winning.items)=="table" and winning.items or {}
                for itemID,item in pairs(winning.items) do
                    if type(item)=="table" then
                        local old=type(older)=="table" and type(older.items)=="table"
                            and older.items[itemID]
                        if type(old)=="table" then
                            item.history=MergeHistory(item.history,old.history)
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
        keys[#keys+1]={key=key,t=Stamp(market.scannedAt)}
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
        if Str(tostring(key),60) and d.nodes[key]==nil and type(node)=="table" then
            d.nodes[key]=Snapshot(node)
            added=added+1
        end
    end
    if added>0 then d.revision=Amount(d.revision)+1 end
    return added
end
local function MergeDrops(src)
    if type(ChalkBoxZoneDB)~="table" then ChalkBoxZoneDB={} end
    local d=ChalkBoxZoneDB.dropSense
    if type(d)~="table" then
        d={version=2,items={},areas={},windows=0,observedItems=0}
        ChalkBoxZoneDB.dropSense=d
    end
    if d.version~=2 then return false end
    MaxTree(d,src)
    if type(src)=="table" and type(src.parts)=="table" then
        for _,part in pairs(src.parts) do MaxTree(d,part) end
    end
    return true
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
        backup=type(ChalkBoxDB)=="table" and ChalkBoxDB.transferBackup~=nil,
        message=lastMessage}
end
local function Evidence(root,key)
    local value=root and root[key]
    return type(value)=="table" and value or {}
end
function ChalkBox_TransferExport()
    if not IsLoaded() then
        return false,"ChalkBoxTransfer companion addon isn't enabled."
    end
    local character=Character()
    if not character then return false,"Character/realm isn't ready." end
    local now=type(time)=="function" and time() or 0
    local a=Evidence(ChalkBoxDB,"auctionSense")
    local s=Evidence(ChalkBoxDB,"auctionInsights")
    local d=Evidence(ChalkBoxZoneDB,"dropSense")
    local f=Evidence(ChalkBoxZoneDB,"discoveriesKnownFlights")
    local auction=Snapshot({version=1,markets=a.markets or {}})
    local sales=Snapshot({version=1,characters=s.characters or {}})
    local drops=Snapshot({version=2,items=d.items or {},areas=d.areas or {},
        windows=d.windows or 0,observedItems=d.observedItems or 0,
        legacyWindows=d.legacyWindows or 0})
    local flights=Snapshot({version=1,nodes=f.nodes or {}})
    if not auction or not sales or not drops or not flights then
        return false,"Too much or invalid transfer data; old file unchanged."
    end
    _G.ChalkBoxTransferDB={
        kind="ChalkBoxData",version=1,exportedAt=Int(now) and now or 0,
        character=character,auction=auction,sales=sales,
        drops=drops,flights=flights,
    }
    lastMessage="Export prepared. /reload or log out to write ChalkBoxTransfer.lua."
    return true,lastMessage
end
local function Backup()
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    if type(ChalkBoxZoneDB)~="table" then ChalkBoxZoneDB={} end
    local now=type(time)=="function" and time() or 0
    local account={at=now,
        auctionSense=Snapshot(ChalkBoxDB.auctionSense),
        auctionInsights=Snapshot(ChalkBoxDB.auctionInsights)}
    local character={at=now,
        dropSense=Snapshot(ChalkBoxZoneDB.dropSense),
        discoveriesKnownFlights=Snapshot(ChalkBoxZoneDB.discoveriesKnownFlights)}
    if type(ChalkBoxDB.auctionSense)=="table" and not account.auctionSense then
        return nil
    end
    if type(ChalkBoxZoneDB.dropSense)=="table" and not character.dropSense then
        return nil
    end
    if type(ChalkBoxDB.transferBackup)=="table" then
        ChalkBoxDB.transferBackupPrevious=ChalkBoxDB.transferBackup
    end
    ChalkBoxDB.transferBackup=account
    if type(ChalkBoxZoneDB.transferBackup)=="table" then
        ChalkBoxZoneDB.transferBackupPrevious=ChalkBoxZoneDB.transferBackup
    end
    ChalkBoxZoneDB.transferBackup=character
    return account,character
end
local function Restore(account,character)
    if type(account)=="table" then
        ChalkBoxDB.auctionSense=account.auctionSense
        ChalkBoxDB.auctionInsights=account.auctionInsights
    end
    if type(character)=="table" then
        ChalkBoxZoneDB.dropSense=character.dropSense
        ChalkBoxZoneDB.discoveriesKnownFlights=character.discoveriesKnownFlights
    end
end
function ChalkBox_TransferImport()
    if not IsLoaded() then return false,
        "ChalkBoxTransfer companion addon isn't enabled." end
    local data=ChalkBoxTransferDB
    if type(data)~="table" or data.kind~="ChalkBoxData" or data.version~=1 then
        return false,"No valid transfer file. Exit WoW, copy the file, then log in."
    end
    if type(data.auction)~="table" or type(data.sales)~="table" or
        type(data.drops)~="table" or data.auction.version~=1 or
        data.sales.version~=1 or data.drops.version~=2 or
        (data.flights and data.flights.version~=1) then
        return false,"Incomplete or incompatible transfer; no changes made."
    end
    if type(ChalkBoxDB)=="table" and
        ((type(ChalkBoxDB.auctionSense)=="table" and
            ChalkBoxDB.auctionSense.version~=1) or
         (type(ChalkBoxDB.auctionInsights)=="table" and
            ChalkBoxDB.auctionInsights.version~=1)) then
        return false,"Newer local auction schema; import blocked safely."
    end
    if type(ChalkBoxZoneDB)=="table" and
        ((type(ChalkBoxZoneDB.dropSense)=="table" and
            ChalkBoxZoneDB.dropSense.version~=2) or
         (type(ChalkBoxZoneDB.discoveriesKnownFlights)=="table" and
            ChalkBoxZoneDB.discoveriesKnownFlights.version~=1)) then
        return false,"Different local Discoveries schema; import blocked safely."
    end
    local copied=Snapshot(data)
    if type(copied)~="table" then
        return false,"Transfer exceeds safe limits or is malformed."
    end
    -- Old transfer files carried a second loot ledger. Fold it with max
    -- so those files still import, without ever adding the same counts twice.
    if type(copied.dropParts)=="table" then
        copied.drops.parts=copied.dropParts
    end
    local account,character=Backup()
    if not account then
        return false,"Could not back up local data. Nothing was changed."
    end
    local ok,markets,sales,dropStatus=pcall(function()
        local marketCount=MergeMarkets(copied.auction)
        local saleCount=MergeSales(copied.sales)
        local note="discovery data skipped (different character)"
        if Character() and copied.character==Character() then
            if not MergeDrops(copied.drops) then error("drops") end
            local flights=MergeFlights(copied.flights)
            note="discoveries merged; "..flights.." new flight nodes"
        end
        return marketCount,saleCount,note
    end)
    if not ok then
        Restore(account,character)
        lastMessage="Import failed. Local data was restored from the backup."
        return false,lastMessage
    end
    if type(ChalkBox_IntelInvalidate)=="function" then
        pcall(ChalkBox_IntelInvalidate)
    end
    if type(ChalkBox_AuctionRefreshUI)=="function" then
        pcall(ChalkBox_AuctionRefreshUI)
    end
    if type(ChalkBox_MapDiscoveriesRefresh)=="function" then
        pcall(ChalkBox_MapDiscoveriesRefresh)
    end
    lastMessage=("Merged %d market snapshots, %d sale receipts; %s."):format(
        markets,sales,dropStatus)
    return true,lastMessage
end
