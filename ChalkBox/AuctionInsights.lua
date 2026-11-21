-- AuctionInsights: read-only bag appraisal and observed seller-mail receipts.
-- Uses ChalkBox AuctionSense ask snapshots, never posts/buys/disenchants.
-- Sale records are from native "seller" invoices ONLY, not vanished auctions.
-- No native frame mutations, no mail collection or automatic trading.
local addonName=...
local MAX_RECEIPTS=400
local MAX_ROWS=250
local frame=CreateFrame("Frame")
local function Safe(v)
    return v~=nil and (type(issecretvalue)~="function" or not issecretvalue(v))
end
local function Number(n)
    return Safe(n) and type(n)=="number" and n==n and
        n>=0 and n<1000000000000000 and n~=math.huge
end
local function Int(n)
    return Number(n) and n%1==0
end
local function Call(f,...)
    if type(f)~="function" then return nil end
    local ok,a,b,c,d,e,f2,g,h,i,j,k=pcall(f,...)
    if ok then return a,b,c,d,e,f2,g,h,i,j,k end
end
local function Time()
    local v=Call(time)
    if not Int(v) then v=Call(GetServerTime) end
    return Int(v) and v or 0
end
local function CharacterKey()
    local status=type(ChalkBox_AuctionStatus)=="function"
        and ChalkBox_AuctionStatus() or nil
    local market=status and status.marketKey
    local character=Call(UnitName,"player")
    if not Safe(market) or type(market)~="string" or
        not Safe(character) or type(character)~="string" or
        character=="" then return nil end
    return market.."|"..character:lower()
end
local function DB()
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    if type(ChalkBoxDB.auctionInsights)~="table" or
        ChalkBoxDB.auctionInsights.version~=1 then
        ChalkBoxDB.auctionInsights={version=1,characters={}}
    end
    local root=ChalkBoxDB.auctionInsights
    if type(root.characters)~="table" then root.characters={} end
    return root
end
local function Ledger()
    local key=CharacterKey()
    if not key then return nil end
    local root=DB()
    local d=root.characters[key]
    if type(d)~="table" then
        d={sales={}}
        root.characters[key]=d
    end
    if type(d.sales)~="table" then d.sales={} end
    return d
end
local function ItemInfo(link)
    local getter=C_Item and C_Item.GetItemInfo or GetItemInfo
    if type(getter)~="function" then return nil end
    local name,_,quality,level,required,class,sub,stack,slot,icon,vendor,
        classID,subclassID=Call(getter,link)
    if not Safe(name) or type(name)~="string" then return nil end
    return {name=name,quality=quality,vendor=Number(vendor) and vendor or nil,
        classID=classID}
end
local function ItemID(link)
    if Int(link) then return link end
    if not Safe(link) or type(link)~="string" then return nil end
    local id=tonumber(link:match("item:(%d+)"))
    return Int(id) and id or nil
end
local function Protect(name,id)
    local db=type(ChalkBoxDB)=="table" and ChalkBoxDB
    local keep=db and db.keep
    if type(keep)=="table" and
        (keep["id:"..tostring(id)] or
         keep["name:"..name:lower()]) then return true end
    if type(ChalkBox_IsTrackedQuestItem)=="function" then
        local q=Call(ChalkBox_IsTrackedQuestItem,name)
        if q==true then return true end
    end
    return false
end
local function ContainerItem(bag,slot)
    local container=C_Container
    if container and type(container.GetContainerItemInfo)=="function" then
        local info=Call(container.GetContainerItemInfo,bag,slot)
        if type(info)=="table" then
            local link=Safe(info.hyperlink) and info.hyperlink or
                Call(container.GetContainerItemLink,bag,slot)
            return link,info.stackCount or 1,info.isBound==true
        end
    end
    local getter=container and container.GetContainerItemLink or GetContainerItemLink
    local link=Call(getter,bag,slot)
    local count=1
    local legacy=Call(GetContainerItemInfo,bag,slot)
    -- Legacy tuple: texture, stackCount, locked, quality, ..., hyperlink.
    if legacy then
        local _,n=Call(GetContainerItemInfo,bag,slot)
        if Int(n) then count=n end
    end
    return link,count,false
end
local function ValidAsk(id)
    if type(ChalkBox_AuctionPrice)~="function" then return nil end
    local price=Call(ChalkBox_AuctionPrice,id)
    if type(price)=="table" and price.stale~=true and
        price.mixed~=true and Number(price.low) and price.low>0 then
        return price.low,price
    end
end
local function BagItems(search)
    local results={}
    local counters={stacks=0,units=0,priced=0,marketValue=0,
        vendorValue=0,unpriced=0,protected=0}
    local container=C_Container
    local slotsFn=container and container.GetContainerNumSlots or
        GetContainerNumSlots
    if type(slotsFn)~="function" then return results,counters end
    local last=Number(NUM_BAG_SLOTS) and math.min(5,NUM_BAG_SLOTS) or 4
    search=type(search)=="string" and search:lower():sub(1,70) or ""
    local byID={}
    for bag=0,last do
        local slots=Call(slotsFn,bag)
        if Int(slots) and slots>=0 and slots<=200 then
            for slot=1,slots do
                local link,count,bound=ContainerItem(bag,slot)
                local id=ItemID(link)
                if id and Int(count) and count>0 and count<=100000 then
                    local data=ItemInfo(link)
                    local name=data and data.name or ("Item #"..id)
                    local row=byID[id]
                    if not row then
                        row={itemID=id,name=name,count=0,bound=false,
                            quality=data and data.quality or nil,
                            vendor=data and data.vendor or nil}
                        byID[id]=row
                    end
                    row.count=row.count+count
                    row.bound=row.bound or bound
                end
            end
        end
    end
    for _,item in pairs(byID) do
        if search=="" or item.name:lower():find(search,1,true)
            or tostring(item.itemID):find(search,1,true) then
            local low,market=ValidAsk(item.itemID)
            local protected=Protect(item.name,item.itemID)
            local vendor=item.vendor
            local vendorTotal=vendor and vendor*item.count or nil
            local marketTotal=low and low*item.count or nil
            local de,denum
            if type(ChalkBox_DisenchantEvaluate)=="function" and
                item.count>0 and item.count<100000 then
                de=Call(ChalkBox_DisenchantEvaluate,item.itemID)
                if type(de)=="table" and de.complete and
                    Number(de.estimated) then denum=de.estimated end
            end
            item.low=low
            item.marketTotal=marketTotal
            item.vendorTotal=vendorTotal
            item.de=denum
            item.protected=protected
            item.note=protected and "KEEP" or
                item.bound and "BOUND" or
                (not low and "NO FRESH ASK" or
                (denum and denum>low*1.15 and "DE candidate" or
                (vendor and vendor>low*1.15 and "Vendor candidate" or
                "Auction candidate")))
            counters.stacks=counters.stacks+1
            counters.units=counters.units+item.count
            counters.vendorValue=counters.vendorValue+(vendorTotal or 0)
            if protected then counters.protected=counters.protected+1 end
            if marketTotal then
                counters.marketValue=counters.marketValue+marketTotal
                counters.priced=counters.priced+1
            else counters.unpriced=counters.unpriced+1 end
            results[#results+1]=item
        end
    end
    table.sort(results,function(a,b)
        if a.name:lower()==b.name:lower() then return a.itemID<b.itemID end
        return a.name:lower()<b.name:lower()
    end)
    return results,counters
end
function ChalkBox_MarketBagRows(search,limit)
    local rows,stats=BagItems(search)
    limit=Int(limit) and math.min(MAX_ROWS,limit) or MAX_ROWS
    while #rows>limit do rows[#rows]=nil end
    return rows,stats
end
local mailboxActive=false
local lastCapture=0
local function MailboxVisible()
    return mailboxActive and type(GetInboxNumItems)=="function" and
        type(GetInboxHeaderInfo)=="function" and
        type(GetInboxInvoiceInfo)=="function"
end
-- Unique mail IDs are not exposed by the supported mailbox APIs.
-- De-duplicate using invoice content and the approximate original expiry,
-- plus an occurrence number for otherwise identical simultaneous invoices.
-- Not a guaranteed exhaustive accounting ledger.
function ChalkBox_MarketCaptureSales()
    if not MailboxVisible() then return 0,"Open your mailbox to capture sales" end
    local ledger=Ledger()
    if not ledger then return 0,"Character or market unavailable" end
    local n=Call(GetInboxNumItems)
    if not Int(n) or n>500 then return 0,"Inbox unavailable" end
    local now=Time()
    if now==0 then return 0,"Clock unavailable" end
    local added=0
    local duplicates={}
    for index=1,n do
        local _,_,sender,subject,money,_,daysLeft=Call(GetInboxHeaderInfo,index)
        local invoiceType,itemName,buyer,bid,_,deposit,cut,_,_,_,
            quantity=Call(GetInboxInvoiceInfo,index)
        if invoiceType=="seller" and Safe(itemName) and
            type(itemName)=="string" and itemName~="" and
            Safe(sender) and type(sender)=="string" and
            Safe(subject) and type(subject)=="string" and
            Int(bid) and bid>0 and Int(deposit) and Int(cut)
            and Number(daysLeft) and daysLeft>0 and daysLeft<=40
            and Int(money) and money>=0 then
            -- The invoice's bid is gross sale price; net is after AH cut
            -- plus returned deposit, matching Blizzard's mail invoice UI.
            local count=Int(quantity) and quantity>=1 and quantity<=100000
                and quantity or 1
            local expiry=now+math.floor(daysLeft*86400)
            local bucket=math.floor((expiry+450)/900)
            local sig=table.concat({sender,subject,itemName,bid,
                deposit,cut,count},"|")
            duplicates[sig]=(duplicates[sig] or 0)+1
            local ordinal=duplicates[sig]
            local known=false
            for _,old in ipairs(ledger.sales) do
                if old.sig==sig and old.ordinal==ordinal and
                    math.abs((old.expiryBucket or -100)-bucket)<=1 then
                    known=true;break
                end
            end
            if not known then
                ledger.sales[#ledger.sales+1]={sig=sig,
                    ordinal=ordinal,expiryBucket=bucket,
                    at=now,name=itemName,count=count,
                    gross=bid,deposit=deposit,cut=cut,
                    proceeds=bid+deposit-cut}
                added=added+1
            end
        end
    end
    table.sort(ledger.sales,function(a,b)
        if a.at==b.at then return a.name<b.name end
        return a.at>b.at
    end)
    while #ledger.sales>MAX_RECEIPTS do table.remove(ledger.sales) end
    lastCapture=now
    if added>0 and type(ChalkBox_AuctionRefreshUI)=="function" then
        Call(ChalkBox_AuctionRefreshUI)
    end
    return added,("Captured %d new seller invoices"):format(added)
end
function ChalkBox_MarketSalesStatus()
    local ledger=Ledger()
    local rows=ledger and ledger.sales or {}
    local result={count=#rows,units=0,gross=0,proceeds=0,fees=0,
        last30=0,last30proceeds=0,lastCapture=lastCapture,
        supported=type(GetInboxInvoiceInfo)=="function"}
    local now=Time()
    for _,sale in ipairs(rows) do
        result.units=result.units+(sale.count or 0)
        result.gross=result.gross+(sale.gross or 0)
        result.proceeds=result.proceeds+(sale.proceeds or 0)
        result.fees=result.fees+(sale.cut or 0)
        if now>=sale.at and now-sale.at<=30*86400 then
            result.last30=result.last30+1
            result.last30proceeds=result.last30proceeds+sale.proceeds
        end
    end
    return result
end
function ChalkBox_MarketSaleRows(search,limit)
    local rows={}
    local ledger=Ledger()
    local items=ledger and ledger.sales or {}
    search=type(search)=="string" and search:lower():sub(1,70) or ""
    limit=Int(limit) and math.min(MAX_ROWS,limit) or 50
    for _,v in ipairs(items) do
        if search=="" or v.name:lower():find(search,1,true) then
            rows[#rows+1]={name=v.name,count=v.count,at=v.at,
                gross=v.gross,proceeds=v.proceeds,cut=v.cut,
                deposit=v.deposit}
            if #rows>=limit then break end
        end
    end
    return rows
end
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("MAIL_SHOW")
frame:RegisterEvent("MAIL_INBOX_UPDATE")
frame:RegisterEvent("MAIL_CLOSED")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:SetScript("OnEvent",function(_,event,name)
    if event=="ADDON_LOADED" then
        if name==addonName then DB() end
    elseif event=="MAIL_SHOW" then
        mailboxActive=true
        ChalkBox_MarketCaptureSales()
    elseif event=="MAIL_CLOSED" then
        mailboxActive=false
    elseif event=="MAIL_INBOX_UPDATE" then
        if mailboxActive then ChalkBox_MarketCaptureSales() end
    elseif event=="BAG_UPDATE_DELAYED" then
        if type(ChalkBox_AuctionRefreshUI)=="function" then
            Call(ChalkBox_AuctionRefreshUI)
        end
    end
end)
