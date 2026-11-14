-- AuctionSense: first-party, read-only market data for WoW Forever.
-- No third-party addon code; no bids, purchases, posts or automatic searches.
-- A scan is a snapshot of asking prices, never evidence of completed sales.
local addonName=...
local MAX_LISTINGS=150000
local MAX_ITEMS=12000
local MAX_MARKETS=6
local BATCH=140
local COOLDOWN=15*60
local MAX_HISTORY=7
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
    return ah and type(ah.SendBrowseQuery)=="function" and
        type(ah.GetBrowseResults)=="function" and
        type(ah.HasFullBrowseResults)=="function" and
        type(ah.RequestMoreBrowseResults)=="function" and ah or nil
end
local function AtAuctioneer()
    if auctionOpen then return true end
    local ahFrame=AuctionHouseFrame
    if ahFrame and type(ahFrame.IsShown)=="function" then
        return Call(ahFrame.IsShown,ahFrame)==true
    end
    return false
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
    return {available=BrowseAH()~=nil,fullAvailable=FullAH()~=nil,
        open=AtAuctioneer(),busy=job~=nil,mode=job and job.mode or lastMode,
        state=state,progress=progress,error=lastError,
        scannedItems=job and job.itemCount or nil,
        realm=realm,faction=faction,marketKey=key,
        auctions=market and market.auctions or 0,
        source=market and market.source or nil,
        items=market and market.itemCount or 0,
        scannedAt=market and market.scannedAt or nil,age=age,
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
function ChalkBox_AuctionPrice(item)
    local id=ItemID(item)
    local key=MarketID()
    local market=key and State().markets[key]
    local entry=id and market and market.items and market.items[tostring(id)]
    if type(entry)~="table" or not Integer(entry.low) then return nil end
    local age=math.max(0,Now()-(market.scannedAt or 0))
    return {itemID=id,name=entry.name,low=entry.low,average=entry.average,
        quantity=entry.quantity,listings=entry.listings,
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
    local marker="AUCTIONSENSE"
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
    tooltip:AddLine("AUCTIONSENSE  |  "..price.market,0.90,0.75,0.43)
    tooltip:AddLine("Low ask: "..Money(price.low)..
        (price.average and ("  |  Avg ask: "..Money(price.average))
            or "  |  Average unavailable"),0.48,0.89,0.77)
    tooltip:AddLine((price.listings and
        (tostring(price.listings).." listings  |  ") or "")..
        "scanned "..when,
        0.70,0.77,0.80)
    if price.stale or price.mixed then
        tooltip:AddLine(price.stale and "Old scan — prices may have changed" or
            "Multiple item variants — check exact gear",0.97,0.70,0.42)
    end
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
            results[#results+1]={itemID=tonumber(id),
                name=entry.name or ("Item #"..id),low=entry.low,
                average=entry.average,quantity=entry.quantity,
                listings=entry.listings,mixed=entry.mixed==true}
        end
    end
    table.sort(results,function(a,b)
        if a.name==b.name then return a.itemID<b.itemID end
        return a.name:lower()<b.name:lower()
    end)
    while #results>limit do results[#results]=nil end
    return results
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
            average=average,quantity=row.quantity,
            listings=row.listings,mixed=row.mixed}
    end
    if found==0 then
        Abort("No usable buyout listings. Previous prices kept.")
        return
    end
    local db=State()
    local old=db.markets[id]
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
        Finish(("Saved %d items from market browse"):format(found))
    else
        Finish(("Saved %d items from %d auctions"):format(found,scan.total))
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
    if allInfo==false then return false end
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
        row={name=type(name)=="string" and name:sub(1,76)
                or ("Item #"..id),
            low=math.ceil(buyout/count),listings=0,
            quantity=0,totalCopper=0}
        scan.rows[id]=row
    end
    local price=math.ceil(buyout/count)
    if price<row.low then row.low=price end
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
            local id=info.itemKey.itemID
            local price=info.minPrice
            local qty=info.totalQuantity
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
    if scan.elapsed>=65 then
        Abort("Browse timed out. Try again at the auctioneer.")
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
        if ah and Call(ah.HasFullBrowseResults)==true then
            if scan.itemCount>0 then Commit(scan)
            else Abort("No auction results. Previous prices kept.") end
            return
        end
        -- Request another page only after current results arrive and the
        -- server throttle is free. Never bypass AH request rate limits.
        local canSend=true
        if ah and type(ah.IsThrottledMessageSystemReady)=="function" then
            canSend=Call(ah.IsThrottledMessageSystemReady)==true
        end
        if canSend and scan.seen>0 and scan.elapsed>=scan.nextPageAt
            and not scan.awaitingPage then
            scan.awaitingPage=true
            scan.nextPageAt=scan.elapsed+1
            local ok,accepted=pcall(ah.RequestMoreBrowseResults)
            if not ok or accepted==false then
                scan.awaitingPage=false
                scan.nextPageAt=scan.elapsed+2
            end
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
    if not scan or scan.phase~="reading" then return end
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
        Commit(scan)
    elseif scan.index>=scan.total then
        state="Finishing item details..."
    end
    if work>0 and scan.index%(BATCH*8)<BATCH then UIRefresh() end
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
            lastError="Browse API unavailable on this client"
            state=lastError
            return false,lastError
        end
        -- Set the state BEFORE sending. Some Forever auction events are
        -- synchronous; the old scanner missed responses for this reason.
        job={mode="browse",phase="reading",key=key,
            elapsed=0,poll=0,updated=false,seen=0,itemCount=0,
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
    job={mode="full",phase="waiting",key=key,waited=0}
    progress=0
    lastMode=mode
    lastError=nil
    state="Requesting full listing snapshot..."
    frame:SetScript("OnUpdate",function(_,elapsed)
        if not job then return end
        if job.phase=="reading" then
            Step(nil,elapsed)
        elseif job.phase=="waiting" then
            job.waited=job.waited+
                (type(elapsed)=="number" and elapsed or 0)
            if job.waited>=25 then
                Abort("Full scan got no response. Possible server cooldown.")
            end
        end
    end)
    UIRefresh()
    local ok,accepted=pcall(ah.ReplicateItems)
    if not ok or accepted==false then
        Abort("Full scan refused. It may be on server cooldown.")
        return false,state
    end
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
        job.updated=true
        job.awaitingPage=false
    elseif event=="AUCTION_HOUSE_BROWSE_FAILURE" and job and
        job.mode=="browse" then
        Abort("Browse scan failed. Your last snapshot was kept.")
    elseif event=="REPLICATE_ITEM_LIST_UPDATE" and job
        and job.mode=="full" and job.phase=="waiting" and
        AtAuctioneer() then
        local count=Call(AH() and AH().GetNumReplicateItems)
        if not Integer(count) or count<1 or count>MAX_LISTINGS then
            Abort("No valid full-scan data. Old prices kept.")
            return
        end
        -- A successful response consumes the server's account-wide throttle.
        local now=Now()
        State().nextAllowed=math.max(State().nextAllowed,now+COOLDOWN)
        job.phase="reading"
        job.total=count
        job.index=0
        job.rows={}
        job.itemCount=0
        job.bidOnly=0
        job.missing={}
        job.nextMissing={}
        job.retryIndex=1
        job.passes=1
        state="Reading auction listings..."
        frame:SetScript("OnUpdate",Step)
        UIRefresh()
    end
end
for _,event in ipairs({"ADDON_LOADED","AUCTION_HOUSE_SHOW",
    "AUCTION_HOUSE_CLOSED","REPLICATE_ITEM_LIST_UPDATE",
    "PLAYER_INTERACTION_MANAGER_FRAME_SHOW",
    "PLAYER_INTERACTION_MANAGER_FRAME_HIDE",
    "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED",
    "AUCTION_HOUSE_BROWSE_RESULTS_ADDED",
    "AUCTION_HOUSE_BROWSE_FAILURE"}) do
    pcall(frame.RegisterEvent,frame,event)
end
frame:SetScript("OnEvent",OnEvent)
