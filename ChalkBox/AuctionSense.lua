-- AuctionSense: first-party, read-only market data for WoW Forever.
-- No third-party addon code; no bids, purchases, posts or automatic searches.
-- A scan is a snapshot of asking prices, never evidence of completed sales.
local addonName=...
-- Full replication can legitimately contain hundreds of thousands of auctions.
-- Stream per-listing reads in frame-bounded batches; only per-item aggregates
-- are stored. This guard is for implausible/corrupt counts, not ordinary volume.
local MAX_LISTINGS=5000000
local MAX_ITEMS=12000
local MAX_MARKETS=6
local BATCH=140
local COOLDOWN=15*60
local FULL_RESPONSE_WAIT=10*60 -- Forever can exceed five minutes to first reply
local FULL_SETTLE_SECONDS=2 -- allow replicated listing count to stop growing
local MAX_PENDING_ROWS=20000 -- never retain millions of unreadable indices
local MAX_HISTORY=7
local DETAIL_MAX_AGE=7*24*3600 -- retain actual full-listing evidence for up to 7 days
local frame=CreateFrame("Frame")
local auctionOpen=false
local job
local state="Open the auction house to scan"
local progress=0
local lastError=nil
local lastMode="browse"

local function Safe(value)
    return value~=nil and
        (type(issecretvalue)~="function" or not issecretvalue(value))
end
local function ValidNumber(n)
    return Safe(n) and type(n)=="number" and n==n and
        n~=math.huge and n~=-math.huge and n>=0 and n<1e15
end
local function Integer(n)
    return ValidNumber(n) and n%1==0
end
local function Call(fn,...)
    if type(fn)~="function" then return end
    local ok,a,b,c=pcall(fn,...)
    if ok then return a,b,c end
end
local function Now()
    local now=Call(time)
    if not Integer(now) then now=Call(GetServerTime) end
    return Integer(now) and now or 0
end
local function Note(text)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff67c6b7ChalkBox AuctionSense|r "..text)
    end
end
local function State()
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    local db=ChalkBoxDB.auctionSense
    if type(db)~="table" or db.version~=1 then
        db={version=1,markets={},order={},tooltip=true,nextAllowed=0}
        ChalkBoxDB.auctionSense=db
    end
    if type(db.markets)~="table" then db.markets={} end
    if type(db.order)~="table" then db.order={} end
    if not Integer(db.nextAllowed) then db.nextAllowed=0 end
    return db
end
local function MarketID()
    local realm=Call(GetNormalizedRealmName) or Call(GetRealmName)
    local faction=Call(UnitFactionGroup,"player")
    if not Safe(realm) or type(realm)~="string" or #realm==0 or
        not Safe(faction) or type(faction)~="string" or #faction==0 then
        return nil
    end
    local normalized=realm:lower():gsub("%s+","")
    return normalized.."|"..faction:lower(),realm,faction
end
local function ItemID(item)
    if Integer(item) and item>0 then return item end
    if not Safe(item) or type(item)~="string" then return end
    local id=item:match("item:(%d+)") or item:match("^%s*(%d+)%s*$")
    id=tonumber(id)
    return Integer(id) and id>0 and id or nil
end
local function AH()
    return type(C_AuctionHouse)=="table" and C_AuctionHouse or nil
end
local function FullAH()
    local ah=AH()
    return ah and type(ah.ReplicateItems)=="function" and
        type(ah.GetNumReplicateItems)=="function" and
        type(ah.GetReplicateItemInfo)=="function" and ah or nil
end
local function BrowseAH()
    local ah=AH()
    -- Paging helpers are optional. One page of results is still a scan.
    return ah and type(ah.SendBrowseQuery)=="function" and
        type(ah.GetBrowseResults)=="function" and ah or nil
end
local function Shown(widget)
    return widget and type(widget.IsShown)=="function"
        and Call(widget.IsShown,widget)==true
end
local function AtAuctioneer()
    if auctionOpen then return true end
    return Shown(AuctionHouseFrame) or Shown(AuctionFrame)
end
local function ClassicReady()
    return type(QueryAuctionItems)=="function"
        and type(GetNumAuctionItems)=="function"
        and type(GetAuctionItemInfo)=="function"
end
local function UIRefresh()
    if type(ChalkBox_AuctionRefreshUI)=="function" then
        pcall(ChalkBox_AuctionRefreshUI)
    end
end
function ChalkBox_AuctionStatus()
    local db=State()
    local key,realm,faction=MarketID()
    local market=key and db.markets[key] or nil
    local age=market and Integer(market.scannedAt) and
        math.max(0,Now()-market.scannedAt) or nil
    local detailAt=market and market.detailAt
    if not Integer(detailAt) and market and market.source=="full" then
        detailAt=market.scannedAt -- older valid full-scan SavedVariables
    end
    return {available=BrowseAH()~=nil,fullAvailable=FullAH()~=nil,
        open=AtAuctioneer(),busy=job~=nil,mode=job and job.mode or lastMode,
        state=state,progress=progress,error=lastError,
        phase=job and job.phase or nil,
        waitSeconds=job and job.waited or nil,
        received=job and job.eventSeen or false,
        totalListings=job and job.total or nil,
        reportedListings=job and job.reportedCount or nil,
        processedListings=job and job.index or nil,
        pendingListings=job and job.missing and #job.missing or nil,
        scannedItems=job and job.itemCount or nil,
        realm=realm,faction=faction,marketKey=key,
        auctions=market and market.auctions or 0,
        source=market and market.source or nil,
        items=market and market.itemCount or 0,
        scannedAt=market and market.scannedAt or nil,age=age,
        detailAge=Integer(detailAt) and math.max(0,Now()-detailAt) or nil,
        cooldown=math.max(0,db.nextAllowed-Now()),
        tooltip=db.tooltip~=false}
end
function ChalkBox_AuctionSetTooltips(enabled)
    State().tooltip=enabled==true
end
local function Money(copper)
    copper=math.max(0,math.floor(copper or 0))
    local g=math.floor(copper/10000)
    local s=math.floor(copper%10000/100)
    local c=copper%100
    if g>0 then return ("%dg %ds %dc"):format(g,s,c) end
    if s>0 then return ("%ds %dc"):format(s,c) end
    return c.."c"
end
-- Browse summaries cannot produce an average. Carry forward a real full
-- snapshot only with its own timestamp; never pretend it was just scanned.
local function Detail(entry,market)
    if type(entry)~="table" or type(market)~="table" then return end
    local average,listings,detailAt
    if market.source=="full" then
        average,listings,detailAt=entry.average,entry.listings,market.scannedAt
    else
        average,listings,detailAt=entry.detailAverage,entry.detailListings,entry.detailAt
    end
    if not Integer(average) or not Integer(listings) or listings<1 or
        not Integer(detailAt) then return end
    local age=math.max(0,Now()-detailAt)
    if age>DETAIL_MAX_AGE then return end
    return average,listings,age,detailAt
end
function ChalkBox_AuctionPrice(item)
    local id=ItemID(item)
    local key=MarketID()
    local market=key and State().markets[key]
    local entry=id and market and market.items and market.items[tostring(id)]
    if type(entry)~="table" or not Integer(entry.low) then return nil end
    local age=math.max(0,Now()-(market.scannedAt or 0))
    local average,listings,detailAge,detailAt=Detail(entry,market)
    return {itemID=id,name=entry.name,low=entry.low,average=average,
        quantity=entry.quantity,listings=listings,
        detailAge=detailAge,detailAt=detailAt,
        market=key,age=age,scannedAt=market.scannedAt,
        stale=age>24*3600,mixed=entry.mixed==true,
        source=market.source or "replicate",kind="asking"}
end
-- Item tooltip extension, used by LootSense after an item has a real ID.
-- Always identify the market and scan age; hide extra data until scanned.
function ChalkBox_AuctionTooltip(tooltip,link)
    if State().tooltip==false or not tooltip or
        type(tooltip.AddLine)~="function" then return false end
    local price=ChalkBox_AuctionPrice(link)
    if not price then return false end
    local marker="Market  |  "
    local name=type(tooltip.GetName)=="function" and
        Call(tooltip.GetName,tooltip) or nil
    if type(name)=="string" and type(tooltip.NumLines)=="function" then
        local count=Call(tooltip.NumLines,tooltip) or 0
        for i=1,math.min(35,count) do
            local line=_G[name.."TextLeft"..i]
            local text=line and Call(line.GetText,line)
            if type(text)=="string" and text:find(marker,1,true) then
                return false
            end
        end
    end
    local age=price.age or 0
    local when=age<60 and "now" or (age<3600 and
        (math.floor(age/60).."m ago") or
        (age<86400 and math.floor(age/3600).."h ago" or
        math.floor(age/86400).."d ago"))
    local market=(price.market or "Unknown"):gsub("|"," / ")
    local source=price.source=="browse" and "Browse" or "Full listings"
    local function Line(text,role,r,g,b)
        if type(ChalkBox_TipColor)=="function" then
            r,g,b=ChalkBox_TipColor(role)
        end
        tooltip:AddLine(text,r,g,b)
    end
    local function Metric(label,value,role,r,g,b)
        if type(ChalkBox_TipMetric)=="function" then
            ChalkBox_TipMetric(tooltip,label,value,role)
        else
            if type(tooltip.AddDoubleLine)=="function" then
                tooltip:AddDoubleLine(label,value,0.81,0.84,0.85,r,g,b)
            else
                tooltip:AddLine(label..": "..value,r,g,b)
            end
        end
    end
    -- Separate historical market evidence from Blizzard's item properties.
    -- Asking prices are monetary values, not a guaranteed good deal.
    Line(" ","muted",0.65,0.70,0.73)
    Line(marker..market,"info",0.40,0.83,0.78)
    Metric("Low / unit",Money(price.low),"value",0.98,0.79,0.39)
    Metric("Avg / unit",price.average and Money(price.average) or "—",
        "value",0.98,0.79,0.39)
    Metric("Listings",price.listings and tostring(price.listings) or "—",
        "count",0.51,0.76,0.98)
    Metric("Units",price.quantity and tostring(price.quantity) or "—",
        "text",0.85,0.87,0.88)
    Line(source.." low price  ·  "..when,"muted",0.65,0.70,0.73)
    if price.detailAge and price.source=="browse" then
        local d=price.detailAge
        local detailWhen=d<3600 and "under 1h" or
            (d<86400 and math.floor(d/3600).."h" or
            math.floor(d/86400).."d")
        Line("Avg / listings: last full scan ("..detailWhen.." old)",
            "muted",0.65,0.70,0.73)
    elseif not price.average then
        Line("Avg / listings need a successful full scan",
            "muted",0.65,0.70,0.73)
    end
    if price.mixed then
        Line("MIXED VARIANTS  ·  Check exact gear","warning",
            0.98,0.66,0.33)
    end
    if price.stale then
        Line("OLD SCAN  ·  Refresh prices","danger",0.98,0.45,0.40)
    end
    Line("Asking prices, not sales","muted",0.65,0.70,0.73)
    if type(tooltip.Show)=="function" then tooltip:Show() end
    return true
end

-- Shared read-only estimate for LootSense, DropSense, ProfessionSense and
-- future bag valuation. Reject old or mixed-variant data rather than guessing.
function ChalkBox_AuctionValue(item,quantity)
    local price=ChalkBox_AuctionPrice(item)
    if not price or price.stale or price.mixed then return nil end
    if not Integer(quantity) or quantity<1 or quantity>100000 then
        return nil
    end
    return price.low*quantity,price
end
function ChalkBox_AuctionRows(search,limit)
    local key=MarketID()
    local market=key and State().markets[key]
    local results={}
    if not market or type(market.items)~="table" then return results end
    search=type(search)=="string" and search:lower():sub(1,70) or ""
    limit=Integer(limit) and math.min(limit,MAX_ITEMS) or 50
    for id,entry in pairs(market.items) do
        if search=="" or id:find(search,1,true) or
            (type(entry.name)=="string" and
                entry.name:lower():find(search,1,true)) then
            local avg,lots,detailAge=Detail(entry,market)
            results[#results+1]={itemID=tonumber(id),
                name=entry.name or ("Item #"..id),low=entry.low,
                average=avg,quantity=entry.quantity,
                listings=lots,detailAge=detailAge,
                mixed=entry.mixed==true}
        end
    end
    table.sort(results,function(a,b)
        if a.name==b.name then return a.itemID<b.itemID end
        return a.name:lower()<b.name:lower()
    end)
    while #results>limit do results[#results]=nil end
    return results
end
-- Experimental charts consume EXISTING saved low-price scan observations.
-- Return a validated copy, never a live reference to SavedVariables.
-- No new AH requests or extra per-item history are created by graphing.
function ChalkBox_AuctionChartHistory(item)
    local id=ItemID(item)
    local key,realm,faction=MarketID()
    local market=key and State().markets[key]
    local entry=id and market and type(market.items)=="table"
        and market.items[tostring(id)] or nil
    if type(entry)~="table" then return nil end
    local history=type(entry.history)=="table" and entry.history or {}
    local points={}
    for i=math.max(1,#history-MAX_HISTORY+1),#history do
        local row=history[i]
        if type(row)=="table" and Integer(row.t) and row.t>0
            and Integer(row.low) and row.low>0 then
            points[#points+1]={t=row.t,low=row.low}
        end
    end
    table.sort(points,function(a,b) return a.t<b.t end)
    return {itemID=id,name=type(entry.name)=="string" and entry.name
            or ("Item #"..tostring(id)),
        marketKey=key,realm=realm,faction=faction,
        source=market.source,scannedAt=market.scannedAt,
        mixed=entry.mixed==true,points=points}
end
local function Finish(message)
    job=nil
    frame:SetScript("OnUpdate",nil)
    state=message
    UIRefresh()
end
local function Abort(message)
    lastError=message
    Finish(message)
end
local function Commit(scan)
    local id,realm,faction=MarketID()
    if id~=scan.key then
        Abort("Market changed. Previous prices kept.")
        return
    end
    local items,found={},0
    for itemID,row in pairs(scan.rows) do
        found=found+1
        local average=row.totalCopper and row.quantity>0 and
            math.ceil(row.totalCopper/row.quantity) or nil
        items[itemID]={name=row.name,low=row.low,
            average=average,quantity=row.quantity,variant=row.variant,
            listings=row.listings,mixed=row.mixed}
    end
    if found==0 then
        Abort("No usable buyout listings. Previous prices kept.")
        return
    end
    local db=State()
    local old=db.markets[id]
    if scan.mode=="browse" and old and type(old.items)=="table" then
        -- Keep the last known *full* auction evidence when the player
        -- refreshes browse minima. Its age remains independently visible.
        for itemID,item in pairs(items) do
            local prev=old.items[itemID]
            -- Full replicate links and browse ItemKeys use different
            -- signature formats; their raw strings are not comparable.
            -- Reject known mixed-variant aggregates without false matches.
            local compatible=type(prev)=="table" and
                not item.mixed and not prev.mixed
            if compatible then
                local avg,lots,_,at=Detail(prev,old)
                if avg and lots and at then
                    item.detailAverage=avg
                    item.detailListings=lots
                    item.detailAt=at
                end
            end
        end
    end
    if old and type(old.items)=="table" then
        for itemID,item in pairs(items) do
            local previous=old.items[itemID]
            local history=type(previous)=="table" and previous.history or nil
            item.history={}
            if type(history)=="table" then
                for i=math.max(1,#history-MAX_HISTORY+2),#history do
                    local h=history[i]
                    if type(h)=="table" and Integer(h.t) and Integer(h.low) then
                        item.history[#item.history+1]={t=h.t,low=h.low}
                    end
                end
            end
            item.history[#item.history+1]={t=Now(),low=item.low}
        end
    else
        for _,item in pairs(items) do
            item.history={{t=Now(),low=item.low}}
        end
    end
    db.markets[id]={realm=realm,faction=faction,scannedAt=Now(),
        detailAt=scan.mode=="full" and Now() or
            (old and (old.detailAt or
                (old.source=="full" and old.scannedAt))) or nil,
        auctions=scan.mode=="full" and scan.total or nil,
        itemCount=found,items=items,source=scan.mode,
        bidOnly=scan.bidOnly}
    for i=#db.order,1,-1 do
        if db.order[i]==id then table.remove(db.order,i) end
    end
    db.order[#db.order+1]=id
    while #db.order>MAX_MARKETS do
        local obsolete=table.remove(db.order,1)
        db.markets[obsolete]=nil
    end
    progress=100
    lastError=nil
    if scan.mode=="browse" then
        Finish(("Saved %d browse prices (low + units). Avg/listings require full data"):format(found))
    else
        local partial=(scan.partial or 0)>0 and
            (" (%d listings with uncached names)"):format(scan.partial) or ""
        Finish(("Saved %d items from %d auctions%s"):format(
            found,scan.total,partial))
    end
    Note("Saved "..found.." items. Asking prices only, not sales.")
end
local function ReadRow(scan,index)
    local ah=AH()
    if not ah then return false end
    local ok,name,_,count,_,_,_,_,_,_,buyout,_,_,_,_,_,_,itemID,allInfo=
        pcall(ah.GetReplicateItemInfo,index)
    if not ok or not Safe(count) or not Safe(itemID) or
        not Integer(itemID) or itemID<=0 or
        not Integer(count) or count<1 or not Safe(buyout) then
        return false
    end
    -- Valid ID, quantity and buyout arrive before the item name cache.
    -- A pending name must not discard a real auction asking price.
    if allInfo==false then scan.partial=(scan.partial or 0)+1 end
    if not Integer(buyout) or buyout<=0 then
        scan.bidOnly=scan.bidOnly+1
        return true
    end
    local id=tostring(itemID)
    local row=scan.rows[id]
    if not row then
        scan.itemCount=scan.itemCount+1
        if scan.itemCount>MAX_ITEMS then
            scan.tooMany=true
            return true
        end
        row={name=Safe(name) and type(name)=="string"
                and name~="" and name:sub(1,76) or ("Item #"..id),
            low=math.ceil(buyout/count),listings=0,
            quantity=0,totalCopper=0}
        scan.rows[id]=row
    end
    local price=math.ceil(buyout/count)
    if price<row.low then row.low=price end
    -- Prevent corrupt/overflowing API results from poisoning statistics.
    if row.quantity+count>=1e15 or
        row.totalCopper+buyout>=1e15 then
        scan.tooMany=true
        return true
    end
    row.listings=row.listings+1
    row.quantity=row.quantity+count
    row.totalCopper=row.totalCopper+buyout
    -- An itemID is not necessarily a distinct equipment variant.
    if type(ah.GetReplicateItemLink)=="function" then
        local link=Call(ah.GetReplicateItemLink,index)
        if type(link)=="string" then
            local signature=link:match("item:([%d:%-]+)")
            if signature then
                if row.variant and row.variant~=signature then row.mixed=true end
                row.variant=signature
            end
        end
    end
    return true
end
-- The Forever browse API is the supported primary scan path. It returns
-- summary prices, not individual transactions, so AVG and listing counts are
-- intentionally unknown. Queries are user-triggered and page in throttle order.
local function BrowseRead(scan)
    local ah=BrowseAH()
    if not ah then return false,"Browse API unavailable" end
    local results=Call(ah.GetBrowseResults)
    if type(results)~="table" then return false,"Waiting for browse results" end
    local rows,count={},0
    for _,info in ipairs(results) do
        if type(info)=="table" and type(info.itemKey)=="table" then
            local id=info.itemKey.itemID or info.itemKey.itemId or info.itemID
            local price=info.minPrice or info.buyoutAmount or info.unitPrice
            local qty=info.totalQuantity
            if not Integer(qty) then qty=info.quantity end
            if Integer(id) and id>0 and Integer(price) and price>0
                and Integer(qty) and qty>=0 then
                local key=tostring(id)
                local item=rows[key]
                local itemKey=info.itemKey
                if not item then
                    count=count+1
                    if count>MAX_ITEMS then
                        return false,"Too many items for safe storage"
                    end
                    local name
                    local keyInfo=Call(ah.GetItemKeyInfo,itemKey)
                    if type(keyInfo)=="table" and Safe(keyInfo.itemName)
                        and type(keyInfo.itemName)=="string" then
                        name=keyInfo.itemName
                    elseif type(keyInfo)=="table" and Safe(keyInfo.name)
                        and type(keyInfo.name)=="string" then
                        name=keyInfo.name
                    end
                    if not name and Safe(info.name) and
                        type(info.name)=="string" then
                        name=info.name
                    end
                    item={name=name or ("Item #"..key),
                        low=price,quantity=0}
                    rows[key]=item
                end
                item.low=math.min(item.low,price)
                item.quantity=item.quantity+qty
                -- A summary might include multiple versions of one item.
                local variant=tostring(itemKey.itemSuffix or 0)..":"..
                    tostring(itemKey.itemLevel or 0)..":"..
                    tostring(itemKey.battlePetSpeciesID or 0)
                if item.variant and item.variant~=variant then
                    item.mixed=true
                end
                item.variant=variant
            end
        end
    end
    scan.rows=rows
    scan.itemCount=count
    scan.seen=#results
    return true
end
local function StepBrowse(_,elapsed)
    local scan=job
    if not scan or scan.mode~="browse" then return end
    elapsed=type(elapsed)=="number" and elapsed or 0
    scan.elapsed=scan.elapsed+elapsed
    scan.poll=(scan.poll or 0)+elapsed
    -- Some Forever builds fill GetBrowseResults without the browse event.
    if not scan.received and scan.elapsed>=0.5 then
        local ah=BrowseAH()
        local results=ah and Call(ah.GetBrowseResults)
        if type(results)=="table" and #results>0 then
            scan.received=true
            scan.updated=true
        end
    end
    -- The server can fire a browse event with no actual rows. Empty
    -- callbacks are not progress; fail quickly and preserve the old market.
    if (not scan.received or scan.seen==0) and scan.elapsed>=12 then
        Abort("No browse data in 12s. The AH may be busy; try again.")
        return
    end
    if not scan.received then return end
    if scan.elapsed>=65 then
        Abort("Browse timed out while loading pages. Previous prices kept.")
        return
    end
    -- Never hammer the browse system every render frame.
    if not scan.updated and scan.poll<1 then return end
    scan.poll=0
    scan.updated=false
    local ready,why=BrowseRead(scan)
    if ready then
        state=("Reading market: %d items"):format(scan.itemCount)
        local ah=BrowseAH()
        local function FinishPage()
            if scan.itemCount>0 then Commit(scan)
            else Abort("No auction results. Previous prices kept.") end
        end
        local knownFull=ah and type(ah.HasFullBrowseResults)=="function"
        local complete=scan.pagingStopped or not knownFull
            or Call(ah.HasFullBrowseResults)==true
        if complete then
            FinishPage()
            return
        end
        -- Request another page only after current results arrive and the
        -- server throttle is free. Never bypass AH request rate limits.
        local canSend=true
        if ah and type(ah.IsThrottledMessageSystemReady)=="function" then
            canSend=Call(ah.IsThrottledMessageSystemReady)==true
        end
        if canSend and scan.seen>0 and scan.elapsed>=scan.nextPageAt
            and not scan.awaitingPage
            and type(ah.RequestMoreBrowseResults)=="function" then
            scan.awaitingPage=true
            scan.pageSeen=scan.seen
            scan.nextPageAt=scan.elapsed+1
            local ok,accepted=pcall(ah.RequestMoreBrowseResults)
            if not ok or accepted==false then
                -- Keep the page we already have instead of discarding it.
                scan.awaitingPage=false
                scan.pagingStopped=true
                FinishPage()
                return
            end
        elseif scan.awaitingPage and scan.elapsed>=(scan.nextPageAt or 0)+3
            and scan.seen==scan.pageSeen then
            scan.awaitingPage=false
            scan.pagingStopped=true
            FinishPage()
            return
        end
        UIRefresh()
    elseif why~="Waiting for browse results" then
        Abort(why)
    end
end

local function Step(_,elapsed)
    local scan=job
    if scan and scan.mode=="browse" then
        StepBrowse(nil,elapsed)
        return
    end
    if not scan or scan.mode~="full" or
        (scan.phase~="reading" and scan.phase~="finalizing") then return end
    local dt=type(elapsed)=="number" and elapsed or 0
    -- Forever can append results after the first replicate event. A stable
    -- initial count is not a license to ignore later chunks.
    local current=Call(AH() and AH().GetNumReplicateItems)
    if Integer(current) and current>MAX_LISTINGS then
        Abort("Full snapshot grew beyond the safe listing bound. Old prices kept.")
        return
    end
    if Integer(current) and current>scan.total then
        scan.total=current
        scan.phase="reading"
        scan.finalQuiet=0
        state=("Additional auctions received: %d listings..."):format(current)
        UIRefresh()
    elseif Integer(current) and current<scan.total then
        -- Decreasing counts are inconsistent with the snapshot being read.
        Abort("Replicated auction count changed unexpectedly. Previous prices kept.")
        return
    end
    if scan.phase=="finalizing" then
        scan.finalQuiet=(scan.finalQuiet or 0)+dt
        if scan.finalQuiet>=FULL_SETTLE_SECONDS then Commit(scan) end
        return
    end
    if scan.pause and scan.pause>0 then
        scan.pause=scan.pause-(type(elapsed)=="number" and elapsed or 0)
        if scan.pause>0 then return end
    end
    local work=0
    if scan.index<scan.total then
        while scan.index<scan.total and work<BATCH do
            local index=scan.index
            scan.index=index+1
            if not ReadRow(scan,index) then
                scan.missing[#scan.missing+1]=index
                if #scan.missing>MAX_PENDING_ROWS then
                    Abort("Too many unreadable auction rows; old prices kept.")
                    return
                end
            end
            work=work+1
            if scan.tooMany then
                Abort("Market too large for safe storage. Previous prices kept.")
                return
            end
        end
    else
        local retry={}
        for i=scan.retryIndex,math.min(#scan.missing,
            scan.retryIndex+BATCH-1) do
            if not ReadRow(scan,scan.missing[i]) then
                retry[#retry+1]=scan.missing[i]
            end
            work=work+1
        end
        scan.retryIndex=scan.retryIndex+work
        for _,index in ipairs(retry) do
            scan.nextMissing[#scan.nextMissing+1]=index
        end
        if scan.retryIndex>#scan.missing then
            if #scan.nextMissing==0 then
                scan.missing={}
            elseif scan.passes>=3 then
                Abort(#scan.nextMissing..
                    " listings lacked complete item data. Old prices kept.")
                return
            else
                scan.passes=scan.passes+1
                scan.missing=scan.nextMissing
                scan.nextMissing={}
                scan.retryIndex=1
                scan.pause=2
            end
        end
    end
    progress=math.min(99,math.floor(scan.index/math.max(1,scan.total)*100))
    if scan.index>=scan.total and #scan.missing==0 then
        -- Last data may arrive after an early event. Verify two quiet
        -- seconds before replacing the last good snapshot.
        scan.phase="finalizing"
        scan.finalQuiet=0
        state=("Confirming complete snapshot: %d auctions..."):format(scan.total)
    elseif scan.index>=scan.total then
        state="Finishing item details..."
    end
    if work>0 and scan.index%(BATCH*8)<BATCH then UIRefresh() end
end
-- Forever may signal replication before the item count is populated.
-- Only read results after the actual request's modern update event; an old
-- cached count by itself is NOT evidence that this request succeeded.
local function BeginFullReading(scan,count)
    scan.phase="reading"
    scan.total=count
    scan.finalQuiet=0
    scan.index=0
    scan.rows={}
    scan.itemCount=0
    scan.bidOnly=0
    scan.missing={}
    scan.nextMissing={}
    scan.retryIndex=1
    scan.passes=1
    state="Processing "..count.." auction listings..."
    frame:SetScript("OnUpdate",Step)
    UIRefresh()
end
local function AcceptFullResults(elapsed)
    local scan=job
    if not scan or scan.mode~="full" or
        (scan.phase~="waiting" and scan.phase~="settling") or
        not scan.eventSeen or not AtAuctioneer() then return false end
    local ah=AH()
    local count=Call(ah and ah.GetNumReplicateItems)
    if not Integer(count) or count<1 then return false end
    if count>MAX_LISTINGS then
        Abort(("Full snapshot reported %d auctions beyond the %d safety bound. Previous prices kept."):format(
            count,MAX_LISTINGS))
        return true
    end
    if scan.reportedCount~=count then
        scan.reportedCount=count
        scan.settledFor=0
        scan.phase="settling"
        state=("Receiving full snapshot: %d listings reported..."):format(count)
        UIRefresh()
        return false
    end
    scan.settledFor=(scan.settledFor or 0)+
        (type(elapsed)=="number" and elapsed or 0)
    if scan.settledFor>=FULL_SETTLE_SECONDS then
        BeginFullReading(scan,count)
        return true
    end
    return false
end
local function ReadClassicRow(scan,index)
    local values={pcall(GetAuctionItemInfo,"list",index)}
    if values[1]~=true then return false end
    local name,count,buyout=values[2],values[4],values[11]
    local itemID=values[18]
    if type(GetAuctionItemLink)=="function" then
        local link=Call(GetAuctionItemLink,"list",index)
        if type(link)=="string" then
            local parsed=tonumber(link:match("item:(%d+)"))
            if Integer(parsed) then itemID=parsed end
        end
    end
    if not Integer(count) or count<1 then count=1 end
    if not Integer(buyout) or buyout<=0 then
        scan.bidOnly=(scan.bidOnly or 0)+1
        return true
    end
    if not Integer(itemID) or itemID<=0 then return false end
    local id=tostring(itemID)
    local row=scan.rows[id]
    if not row then
        scan.itemCount=(scan.itemCount or 0)+1
        if scan.itemCount>MAX_ITEMS then scan.tooMany=true;return true end
        row={name=Safe(name) and type(name)=="string" and name~=""
                and name:sub(1,76) or ("Item #"..id),
            low=math.ceil(buyout/count),listings=0,quantity=0,totalCopper=0}
        scan.rows[id]=row
    end
    local price=math.ceil(buyout/count)
    if price<row.low then row.low=price end
    if row.quantity+count>=1e15 or row.totalCopper+buyout>=1e15 then
        scan.tooMany=true
        return true
    end
    row.listings=row.listings+1
    row.quantity=row.quantity+count
    row.totalCopper=row.totalCopper+buyout
    return true
end
local function SendClassicQuery(scan)
    if type(CanSendAuctionQuery)=="function" then
        local ok,ready=pcall(CanSendAuctionQuery)
        if ok and ready==false then return false end
    end
    local ok,accepted=pcall(QueryAuctionItems,"",nil,nil,nil,nil,nil,
        scan.page or 0,false,nil,scan.getAll==true)
    return ok and accepted~=false
end
local function ReadClassicList(scan)
    local ok,batch,total=pcall(GetNumAuctionItems,"list")
    if not ok or not Integer(batch) or batch<0 then return false end
    scan.gotList=true
    for index=1,batch do
        if not ReadClassicRow(scan,index) then return false end
        if scan.tooMany then
            Abort("Market too large for safe storage. Previous prices kept.")
            return true
        end
    end
    local pageSize=type(NUM_AUCTION_ITEMS_PER_PAGE)=="number"
        and NUM_AUCTION_ITEMS_PER_PAGE or 50
    local covered=((scan.page or 0)*pageSize)+batch
    if scan.getAll or not Integer(total) or total<=0 or covered>=total
        or batch==0 then
        Commit(scan)
        return true
    end
    scan.page=(scan.page or 0)+1
    if not SendClassicQuery(scan) then
        if scan.itemCount>0 then Commit(scan)
        else Abort("Auction list query was refused. Previous prices kept.") end
    end
    return true
end
local function StartClassic(mode,key)
    job={mode=mode,key=key,rows={},itemCount=0,bidOnly=0,page=0,
        getAll=mode=="full",elapsed=0,classic=true,total=0}
    progress=0
    lastMode=mode
    lastError=nil
    state=mode=="full" and "Requesting the classic full auction list..."
        or "Requesting the classic auction list..."
    frame:SetScript("OnUpdate",function(_,elapsed)
        if not job or not job.classic then return end
        job.elapsed=job.elapsed+(type(elapsed)=="number" and elapsed or 0)
        if not job.gotList and job.elapsed>=20 then
            Abort("No auction list arrived in 20s. Previous prices kept.")
        end
    end)
    UIRefresh()
    if not SendClassicQuery(job) then
        Abort("Auction query was refused. Previous prices kept.")
        return false,state
    end
    return true
end
local function StartScan(mode)
    if job then return false,"Scan already in progress" end
    if not AtAuctioneer() then
        return false,"Open the Auction House to scan"
    end
    local key=MarketID()
    if not key then return false,"Realm or faction unavailable" end
    if mode=="browse" then
        local ah=BrowseAH()
        if not ah then
            if ClassicReady() then return StartClassic("browse",key) end
            lastError="Browse API unavailable on this client"
            state=lastError
            return false,lastError
        end
        -- Set the state BEFORE sending. Some Forever auction events are
        -- synchronous; the old scanner missed responses for this reason.
        job={mode="browse",phase="reading",key=key,
            elapsed=0,poll=0,received=false,updated=false,
            seen=0,itemCount=0,
            nextPageAt=1,awaitingPage=false,rows={}}
        progress=0
        lastMode=mode
        lastError=nil
        state="Requesting market browse..."
        frame:SetScript("OnUpdate",Step)
        UIRefresh()
        local query={searchString="",sorts={},filters={},itemClassFilters={}}
        local ok,accepted=pcall(ah.SendBrowseQuery,query)
        if not ok or accepted==false then
            if ClassicReady() and StartClassic("browse",key) then
                return true
            end
            Abort("Browse request refused. Check the AH and try again.")
            return false,state
        end
        if job and job.mode=="browse" then
            state="Loading market results..."
            UIRefresh()
        end
        return true
    end
    local ah=FullAH()
    if not ah then
        if ClassicReady() then return StartClassic("full",key) end
        lastError="Full listing API unavailable"
        state=lastError
        return false,lastError
    end
    local remaining=State().nextAllowed-Now()
    if remaining>0 then
        local msg=("Full scan available in %d min"):format(
            math.ceil(remaining/60))
        state=msg
        return false,msg
    end
    -- A full replicate can be very expensive and server-throttled.
    -- Wait state must exist before the client can fire a synchronous event.
    job={mode="full",phase="waiting",key=key,waited=0,
        eventSeen=false,partial=0,reportedCount=nil,settledFor=0}
    progress=0
    lastMode=mode
    lastError=nil
    state="Requesting full auction snapshot; waiting for server response..."
    frame:SetScript("OnUpdate",function(_,elapsed)
        if not job then return end
        if job.phase=="reading" then
            Step(nil,elapsed)
        elseif job.phase=="waiting" or job.phase=="settling" then
            local dt=type(elapsed)=="number" and elapsed or 0
            job.waited=job.waited+dt
            -- The initial event can precede readable data, and large
            -- snapshots arrive in chunks. Only scan after two quiet seconds.
            if AcceptFullResults(dt) then return end
            if not job then return end
            if job.waited>=FULL_RESPONSE_WAIT and
                (job.phase=="waiting" or not job.reportedCount) then
                Abort("No complete full-scan response after 10 minutes. "..
                    "Previous prices kept; the 15-minute request cooldown "..
                    "still applies.")
                return
            end
            local waiting=math.floor(job.waited)
            if waiting~=job.lastShownSecond then
                job.lastShownSecond=waiting
                if job.phase=="waiting" then
                    state=("Waiting for full scan response: %ds / 600s"):format(waiting)
                end
                UIRefresh()
            end
        end
    end)
    UIRefresh()
    local ok,accepted=pcall(ah.ReplicateItems)
    if not ok or accepted==false then
        Abort("Full Scan refused by the client/server. "..
            "The 15-minute account-wide replicate cooldown may be active; "..
            "use Browse Scan until it is available.")
        return false,state
    end
    -- Full requests can consume the 15-minute throttle even if the addon
    -- later rejects a malformed/oversized result or the player closes AH.
    -- Record the attempt on acceptance, not after processing succeeds.
    State().nextAllowed=math.max(State().nextAllowed,Now()+COOLDOWN)
    UIRefresh()
    return true
end
function ChalkBox_AuctionScan()
    return StartScan("browse")
end
function ChalkBox_AuctionFullScan()
    return StartScan("full")
end
function ChalkBox_AuctionCommand(cmd)
    cmd=(cmd or ""):lower():match("^%s*(.-)%s*$")
    if cmd=="scan" or cmd=="browse" then
        local ok,why=ChalkBox_AuctionScan()
        Note(ok and "Browse scan requested." or why)
    elseif cmd=="full" then
        local ok,why=ChalkBox_AuctionFullScan()
        Note(ok and "Full listing scan requested." or why)
    elseif cmd=="status" then
        local status=ChalkBox_AuctionStatus()
        Note(status.state.." | market "..tostring(status.marketKey or "unknown")..
            " | "..status.items.." items | cooldown "..status.cooldown.."s")
    elseif cmd=="tooltip on" or cmd=="tooltip off" then
        ChalkBox_AuctionSetTooltips(cmd=="tooltip on")
        Note("Market tooltips "..(cmd=="tooltip on" and "ON" or "OFF"))
    elseif type(ChalkBox_AuctionOpen)=="function" then
        ChalkBox_AuctionOpen()
    else
        Note("AuctionSense: open an auctioneer, then /chalk auction scan.")
    end
end
local function OnEvent(_,event,name)
    if event=="ADDON_LOADED" then
        if name==addonName then State() end
    elseif event=="AUCTION_HOUSE_SHOW" then
        auctionOpen=true
        if not job then state="Ready to browse market" end
        if type(ChalkBox_AuctionAttach)=="function" then
            pcall(ChalkBox_AuctionAttach)
        end
        UIRefresh()
    elseif event=="PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
        if Enum and Enum.PlayerInteractionType and
            name==Enum.PlayerInteractionType.Auctioneer then
            auctionOpen=true
            if type(ChalkBox_AuctionAttach)=="function" then
                pcall(ChalkBox_AuctionAttach)
            end
            UIRefresh()
        end
    elseif event=="AUCTION_HOUSE_CLOSED" or
        event=="PLAYER_INTERACTION_MANAGER_FRAME_HIDE" and
        Enum and Enum.PlayerInteractionType and
        name==Enum.PlayerInteractionType.Auctioneer then
        auctionOpen=false
        if type(ChalkBox_AuctionHide)=="function" then
            pcall(ChalkBox_AuctionHide)
        end
        if job then Abort("Auction House closed. Previous scan preserved.")
        else state="Open the auction house to scan";UIRefresh() end
    elseif (event=="AUCTION_HOUSE_BROWSE_RESULTS_UPDATED" or
        event=="AUCTION_HOUSE_BROWSE_RESULTS_ADDED") and job and
        job.mode=="browse" then
        job.received=true
        job.updated=true
        job.awaitingPage=false
    elseif event=="AUCTION_HOUSE_BROWSE_FAILURE" and job and
        job.mode=="browse" then
        Abort("Browse scan failed. Your last snapshot was kept.")
    elseif event=="AUCTION_ITEM_LIST_UPDATE" and job and job.classic then
        ReadClassicList(job)
    elseif event=="AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED"
        and job and job.mode=="full" and job.phase=="waiting" then
        Abort("Full auction request was dropped by the server. "..
            "Previous market prices kept.")
    elseif event=="REPLICATE_ITEM_LIST_UPDATE" and job
        and job.mode=="full" and
        (job.phase=="waiting" or job.phase=="settling") and
        AtAuctioneer() then
        job.eventSeen=true
        if not AcceptFullResults(0) and job and
            job.phase=="waiting" then
            state="Server answered; waiting for listing count..."
            UIRefresh()
        end
    end
end
for _,event in ipairs({"ADDON_LOADED","AUCTION_HOUSE_SHOW",
    "AUCTION_HOUSE_CLOSED","REPLICATE_ITEM_LIST_UPDATE",
    "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
    "PLAYER_INTERACTION_MANAGER_FRAME_HIDE",
    "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED",
    "AUCTION_HOUSE_BROWSE_RESULTS_ADDED",
    "AUCTION_HOUSE_BROWSE_FAILURE",
    "AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED",
    "AUCTION_ITEM_LIST_UPDATE"}) do
    pcall(frame.RegisterEvent,frame,event)
end
frame:SetScript("OnEvent",OnEvent)
