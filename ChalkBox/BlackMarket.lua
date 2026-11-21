-- Black Market listings, stored apart from AuctionSense asking prices.
-- Read only. Never bids, never clicks a protected button, never requests a scan.
local MAX_ITEMS=250
local MAX_SAMPLES=16
local open=false
local lastError
local function Secret(v)
    return type(issecretvalue)=="function" and issecretvalue(v)
end
local function Num(v)
    if Secret(v) or type(v)~="number" or v~=v or v<0 or v>1e12 then return nil end
    return v
end
local function Text(v,max)
    if Secret(v) or type(v)~="string" then return nil end
    v=v:gsub("[%c|]",""):sub(1,max or 80)
    if v=="" then return nil end
    return v
end
local function Now()
    if type(time)~="function" then return nil end
    local ok,t=pcall(time)
    return ok and Num(t) or nil
end
local function API()
    return type(C_BlackMarket)=="table" and C_BlackMarket or nil
end
local function DB()
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    local box=ChalkBoxDB.blackMarket
    if type(box)~="table" then
        box={version=1,listings={},history={}}
        ChalkBoxDB.blackMarket=box
    end
    if type(box.listings)~="table" then box.listings={} end
    if type(box.history)~="table" then box.history={} end
    return box
end
local function ItemID(link)
    local text=Text(link,200)
    local id=text and text:match("item:(%d+)")
    return id and tonumber(id) or nil
end
local function TimeLeft(value)
    if type(value)=="string" then return Text(value,24) end
    local n=Num(value)
    if not n then return nil end
    if n<=1 then return "Short" end
    if n==2 then return "Medium" end
    if n==3 then return "Long" end
    if n>=4 then return "Very long" end
end
local function FromTable(row)
    if type(row)~="table" then return nil end
    return {
        name=Text(row.name or row.itemName),
        quantity=Num(row.quantity),
        seller=Text(row.sellerName or row.seller),
        minBid=Num(row.minBid),
        minIncrement=Num(row.minIncrement),
        currBid=Num(row.currBid or row.currentBid),
        numBids=Num(row.numBids),
        timeLeft=TimeLeft(row.timeLeft),
        link=Text(row.itemLink or row.link,200),
        marketID=Num(row.marketID),
        itemID=Num(row.itemID) or ItemID(row.itemLink or row.link),
    }
end
local function FromReturns(a,b,c,h,i,j,k,m,n,o,p)
    -- Blizzard order: name, texture, quantity, itemType, usable, level,
    -- levelType, sellerName, minBid, minIncrement, currBid, youHaveHighBid,
    -- numBids, timeLeft, link, marketID, quality.
    if type(a)=="table" then return FromTable(a) end
    local name=Text(a)
    if not name then return nil end
    return {
        name=name,quantity=Num(c),seller=Text(h),
        minBid=Num(i),minIncrement=Num(j),currBid=Num(k),
        numBids=Num(m),timeLeft=TimeLeft(n),link=Text(o,200),
        marketID=Num(p),itemID=ItemID(o),
    }
end
local function Key(item)
    if item.itemID then return "item:"..item.itemID end
    if item.marketID then return "market:"..item.marketID end
    if item.name then return "name:"..item.name:lower() end
end
local function ReadIndex(index)
    local api=API()
    if not api or type(api.GetItemInfoByIndex)~="function" then return nil end
    local ok,a,b,c,_,_,_,_,h,i,j,k,_,m,n,o,p=pcall(api.GetItemInfoByIndex,index)
    if not ok then return nil end
    local _texture=b
    return FromReturns(a,_texture,c,h,i,j,k,m,n,o,p)
end
local function Remember(box,item,now)
    local key=Key(item)
    if not key then return end
    local past=box.history[key]
    if type(past)~="table" then
        past={key=key,name=item.name,itemID=item.itemID,link=item.link,
            firstSeen=now,lastSeen=now,samples={}}
        box.history[key]=past
    end
    past.name=item.name or past.name
    past.itemID=item.itemID or past.itemID
    past.link=item.link or past.link
    past.lastSeen=now or past.lastSeen
    past.seller=item.seller or past.seller
    past.quantity=item.quantity or past.quantity
    past.timeLeft=item.timeLeft or past.timeLeft
    past.currBid=item.currBid
    past.minBid=item.minBid
    past.minIncrement=item.minIncrement
    past.numBids=item.numBids
    local samples=past.samples
    local last=samples[#samples]
    local same=type(last)=="table" and last.currBid==item.currBid
        and last.minBid==item.minBid and last.numBids==item.numBids
    if not same then
        samples[#samples+1]={
            time=now,currBid=item.currBid,minBid=item.minBid,
            minIncrement=item.minIncrement,numBids=item.numBids,
            timeLeft=item.timeLeft,seller=item.seller,quantity=item.quantity,
        }
        while #samples>MAX_SAMPLES do table.remove(samples,1) end
    end
    local count=0
    for _ in pairs(box.history) do count=count+1 end
    if count>MAX_ITEMS then
        local oldest,oldestKey
        for id,row in pairs(box.history) do
            local seen=type(row)=="table" and row.lastSeen or 0
            if not oldest or seen<oldest then oldest,oldestKey=seen,id end
        end
        if oldestKey then box.history[oldestKey]=nil end
    end
    item.key=key
    item.seen=type(past.samples)=="table" and #past.samples or 1
    item.firstSeen=past.firstSeen
end
local function Capture()
    local api=API()
    if not api or type(api.GetNumItems)~="function" then
        lastError="Black Market is not on this client."
        return false
    end
    local ok,count=pcall(api.GetNumItems)
    count=ok and Num(count) or nil
    if not count then
        lastError="Black Market list could not be read."
        return false
    end
    local box=DB()
    local now=Now()
    local listings={}
    for index=1,math.min(count,200) do
        local item=ReadIndex(index)
        if item and item.name then
            Remember(box,item,now)
            listings[#listings+1]=item
        end
    end
    box.listings=listings
    box.updatedAt=now
    box.open=open
    lastError=nil
    return true
end
function ChalkBox_BlackMarketStatus()
    local api=API()~=nil
    local box=type(ChalkBoxDB)=="table" and ChalkBoxDB.blackMarket or nil
    local history=0
    if type(box)=="table" and type(box.history)=="table" then
        for _ in pairs(box.history) do history=history+1 end
    end
    return {
        available=api,open=open,
        listings=box and type(box.listings)=="table" and #box.listings or 0,
        history=history,
        updatedAt=box and box.updatedAt or nil,
        message=api and (open and "Black Market is open." or
            "Open the Black Market to read the current list.")
            or "Black Market is not on this client.",
        error=lastError,
    }
end
function ChalkBox_BlackMarketRows(search)
    local box=type(ChalkBoxDB)=="table" and ChalkBoxDB.blackMarket or nil
    if type(box)~="table" then return {} end
    local needle=type(search)=="string" and search:lower() or ""
    local rows,seen={},{}
    local function Add(item,listed)
        if type(item)~="table" or not item.name then return end
        if needle~="" and not item.name:lower():find(needle,1,true) then return end
        local key=item.key or Key(item) or item.name
        if seen[key] then return end
        seen[key]=true
        local bids=item.numBids
        rows[#rows+1]={
            name=item.name,itemID=item.itemID,
            low=item.currBid,average=item.minBid,listings=bids,
            quantity=item.quantity,seller=item.seller,
            timeLeft=item.timeLeft,listed=listed,
            seen=item.seen,firstSeen=item.firstSeen,
            note=(listed and "Listed now" or "Seen before")
                ..(item.timeLeft and (" · "..item.timeLeft) or "")
                ..(item.seller and (" · "..item.seller) or "")
                ..(item.quantity and (" · x"..item.quantity) or ""),
        }
    end
    for _,item in ipairs(box.listings or {}) do Add(item,true) end
    for _,item in pairs(box.history or {}) do
        if type(item)=="table" then
            item.seen=type(item.samples)=="table" and #item.samples or item.seen
            Add(item,false)
        end
    end
    return rows
end
function ChalkBox_BlackMarketCommand()
    local st=ChalkBox_BlackMarketStatus()
    local function Note(text)
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
            DEFAULT_CHAT_FRAME:AddMessage("|cff67c6b7ChalkBox|r "..text)
        end
    end
    if not st.available then
        Note(st.message)
        return false
    end
    Note(st.message.." "..st.listings.." listed, "..st.history.." remembered.")
    if st.error then Note(st.error) end
    return true
end
local frame=CreateFrame("Frame")
frame:SetScript("OnEvent",function(_,event)
    if event=="BLACK_MARKET_OPEN" then
        open=true
        if not API() then
            lastError="Black Market is not on this client."
        end
    elseif event=="BLACK_MARKET_CLOSED" then
        open=false
    elseif event=="BLACK_MARKET_ITEM_UPDATE" then
        Capture()
        if type(ChalkBox_AuctionRefreshUI)=="function" then
            pcall(ChalkBox_AuctionRefreshUI)
        end
    end
end)
for _,event in ipairs({"BLACK_MARKET_OPEN","BLACK_MARKET_CLOSED",
    "BLACK_MARKET_ITEM_UPDATE"}) do
    pcall(frame.RegisterEvent,frame,event)
end
