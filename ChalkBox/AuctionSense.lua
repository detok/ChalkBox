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
    local ah=C_AuctionHouse
    if type(ah)~="table" then return end
    if type(ah.ReplicateItems)~="function" or
        type(ah.GetNumReplicateItems)~="function" or
        type(ah.GetReplicateItemInfo)~="function" then return end
    return ah
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
    return {available=AH()~=nil,open=auctionOpen,busy=job~=nil,
        state=state,progress=progress,error=lastError,
        realm=realm,faction=faction,marketKey=key,
        auctions=market and market.auctions or 0,
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
        source="AuctionSense scan",kind="asking"}
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
        "  |  Avg ask: "..Money(price.average),0.48,0.89,0.77)
    tooltip:AddLine(tostring(price.listings).." listings  |  scanned "..when,
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
    limit=Integer(limit) and math.min(limit,100) or 50
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
        local average=math.floor(row.totalCopper/row.quantity+0.5)
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
        auctions=scan.total,itemCount=found,items=items,
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
    Finish(("Saved %d items from %d auctions"):format(found,scan.total))
    Note("Scan saved: "..found.." items, "..scan.total..
        " auctions. Prices are asking prices, not sales.")
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
            low=math.floor(buyout/count),listings=0,
            quantity=0,totalCopper=0}
        scan.rows[id]=row
    end
    local price=math.floor(buyout/count)
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
local function Step(_,elapsed)
    local scan=job
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
function ChalkBox_AuctionScan()
    if job then return false,"Scan already in progress" end
    if not auctionOpen then return false,"Open an auctioneer first" end
    local ah=AH()
    if not ah then return false,"Forever full-scan API unavailable" end
    local key=MarketID()
    if not key then return false,"Realm or faction unavailable" end
    local db=State()
    local remaining=db.nextAllowed-Now()
    if remaining>0 then
        return false,("Full scan available in %d min"):format(
            math.ceil(remaining/60))
    end
    -- Server's 15-minute account-wide rate limit is authoritative.
    -- Never retry automatically after a rejected or throttled request.
    local ok,err=pcall(ah.ReplicateItems)
    if not ok then
        state="Scan request failed"
        lastError=tostring(err):sub(1,100)
        return false,state
    end
    job={phase="waiting",key=key,waited=0}
    frame:SetScript("OnUpdate",function(_,elapsed)
        if not job or job.phase~="waiting" then return end
        job.waited=job.waited+(type(elapsed)=="number" and elapsed or 0)
        if job.waited>=25 then
            Abort("No scan response. Check the server cooldown.")
        end
    end)
    progress=0
    lastError=nil
    state="Waiting for auction data..."
    UIRefresh()
    return true
end
function ChalkBox_AuctionCommand(cmd)
    cmd=(cmd or ""):lower():match("^%s*(.-)%s*$")
    if cmd=="scan" then
        local ok,why=ChalkBox_AuctionScan()
        Note(ok and "Scan requested." or why)
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
        state="Ready to scan"
        UIRefresh()
    elseif event=="AUCTION_HOUSE_CLOSED" then
        auctionOpen=false
        if job then Abort("Auction house closed. Old prices kept.")
        else state="Open the auction house to scan";UIRefresh() end
    elseif event=="REPLICATE_ITEM_LIST_UPDATE" and job
        and job.phase=="waiting" and auctionOpen then
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
    "AUCTION_HOUSE_CLOSED","REPLICATE_ITEM_LIST_UPDATE"}) do
    pcall(frame.RegisterEvent,frame,event)
end
frame:SetScript("OnEvent",OnEvent)
