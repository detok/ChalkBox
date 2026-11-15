-- Market intelligence: no item use, auction posting, or inbox mutation.
local events={},{}
local frames={}
_G.CreateFrame=function()
    local f={scripts={}}
    function f:RegisterEvent(event) events[event]=true end
    function f:SetScript(script,callback) self.scripts[script]=callback end
    frames[#frames+1]=f
    return f
end
_G.ChalkBoxDB={keep={["id:5002"]="My green gear"}}
_G.UnitName=function() return "Detok" end
_G.time=function() return 2000000 end
_G.GetServerTime=_G.time
_G.NUM_BAG_SLOTS=4
local marketKey="whitemaine|alliance"
_G.ChalkBox_AuctionStatus=function()
    return {marketKey=marketKey}
end
local prices={
    [2589]={low=2000,stale=false,mixed=false},
    [5002]={low=2500,stale=false,mixed=false},
    [5003]={low=100,stale=true,mixed=false},
    [5004]={low=5000,stale=false,mixed=true},
}
_G.ChalkBox_AuctionPrice=function(id) return prices[id] end
_G.ChalkBox_DisenchantEvaluate=function(id)
    if id==5002 then return {complete=true,estimated=4000} end
end
_G.ChalkBox_IsTrackedQuestItem=function(name)
    return name=="Protected Quest Drop"
end
local bags={
    [0]={
        {hyperlink="item:2589",itemID=2589,stackCount=20,isBound=false},
        {hyperlink="item:5002",itemID=5002,stackCount=1,isBound=false},
        {hyperlink="item:5003",itemID=5003,stackCount=3,isBound=false},
        {hyperlink="item:5004",itemID=5004,stackCount=2,isBound=false},
    },
    [1]={
        {hyperlink="item:2589",itemID=2589,stackCount=15,isBound=false},
        {hyperlink="item:5005",itemID=5005,stackCount=1,isBound=true},
    }
}
_G.C_Container={
    GetContainerNumSlots=function(bag) return #(bags[bag] or {}) end,
    GetContainerItemInfo=function(bag,slot) return (bags[bag] or {})[slot] end,
}
local names={
    [2589]={"Linen Cloth",1,100},
    [5002]={"Green Boots",2,200},
    [5003]={"Old Scan Item",1,75},
    [5004]={"Mixed Gear",2,250},
    [5005]={"Bound Trinket",2,300},
}
_G.C_Item={GetItemInfo=function(link)
    local id=tonumber(tostring(link):match("item:(%d+)"))
    local row=names[id]
    if not row then return nil end
    return row[1],link,row[2],20,15,"Cloth","",1,"INVTYPE_FEET",
        nil,row[3],4,1
end}
local mailVisible=false
local mails={}
local function Mail(invoiceType,itemName,subject,money,daysLeft,price,deposit,cut,count)
    return {sender="Auction House",subject=subject,
        money=money,daysLeft=daysLeft,invoiceType=invoiceType,
        itemName=itemName,bid=price,deposit=deposit,cut=cut,count=count}
end
_G.GetInboxNumItems=function() return #mails,#mails end
_G.GetInboxHeaderInfo=function(i)
    local m=mails[i]
    if not m then return nil end
    return nil,nil,m.sender,m.subject,m.money,0,m.daysLeft
end
_G.GetInboxInvoiceInfo=function(i)
    local m=mails[i]
    if not m then return nil end
    return m.invoiceType,m.itemName,"Buyer",m.bid,m.bid,
        m.deposit,m.cut,0,0,0,m.count
end
local changed=0
_G.ChalkBox_AuctionRefreshUI=function() changed=changed+1 end
assert(loadfile("AuctionInsights.lua"))("ChalkBox")
assert(events.MAIL_SHOW and events.MAIL_INBOX_UPDATE and
    events.MAIL_CLOSED and events.BAG_UPDATE_DELAYED)
local function Fire(event,...)
    for _,f in ipairs(frames) do
        if f.scripts.OnEvent then f.scripts.OnEvent(f,event,...) end
    end
end
Fire("ADDON_LOADED","ChalkBox")
local rows,stats=ChalkBox_MarketBagRows("")
assert(#rows==5 and stats.stacks==5 and stats.units==42
    and stats.priced==2 and stats.unpriced==3,
    "bag appraisal consolidates stacks and doesn't invent missing, old or mixed asks")
assert(stats.marketValue==72500,
    "fresh asking-value estimates are per-unit × owned stack count")
local byID={}
for _,row in ipairs(rows) do byID[row.itemID]=row end
assert(byID[2589].count==35 and byID[2589].marketTotal==70000)
assert(byID[5002].protected and byID[5002].note=="KEEP"
    and byID[5002].de==4000,
    "KEEP protection outranks DE suggestions on owned gear")
assert(byID[5005].bound and byID[5005].note=="BOUND",
    "bound items are never presented as auction candidates")
assert(byID[5003].low==nil and byID[5004].low==nil,
    "stale and mixed prices never become bag appraisals")
local linen=ChalkBox_MarketBagRows("linen")
assert(#linen==1 and linen[1].itemID==2589,
    "search filters bag rows without affecting personal inventory")
assert(ChalkBox_MarketSalesStatus().count==0)
local n,msg=ChalkBox_MarketCaptureSales()
assert(n==0 and msg:find("Open your mailbox",1,true),
    "never access inbox or infer sales while mailbox is closed")
mails={
    Mail("seller","Linen Cloth","Auction successful: Linen Cloth",
        9900,29.9,10000,500,600,5),
    Mail("buyer","Green Boots","Auction won: Green Boots",
        0,29.8,5000,0,0,1),
    Mail("seller_temp_invoice","Future sale","Auction successful: Future sale",
        0,29.8,6000,300,400,1),
}
Fire("MAIL_SHOW")
local report=ChalkBox_MarketSalesStatus()
assert(report.count==1 and report.units==5 and
    report.gross==10000 and report.fees==600 and
    report.proceeds==9900 and report.last30==1,
    "only completed seller invoices count, with Blizzard's net payout formula")
assert(ChalkBoxDB.auctionInsights.characters[marketKey.."|detok"],
    "seller receipts persist only under this realm/faction/character")
Fire("MAIL_INBOX_UPDATE")
assert(ChalkBox_MarketSalesStatus().count==1,
    "polling the same invoice never double-counts the sale")
-- Reordered inbox must not double count the existing sale.
mails={mails[3],mails[1],mails[2]}
Fire("MAIL_INBOX_UPDATE")
assert(ChalkBox_MarketSalesStatus().count==1)
-- Another distinct sale is a separate receipt and stays bounded.
mails[#mails+1]=Mail("seller","Green Boots",
    "Auction successful: Green Boots",18800,29.5,20000,0,1200,1)
Fire("MAIL_INBOX_UPDATE")
report=ChalkBox_MarketSalesStatus()
assert(report.count==2 and report.gross==30000
    and report.proceeds==28700 and report.fees==1800,
    "multiple sale invoices track gross, AH cut and proceeds, not market asks")
local sales=ChalkBox_MarketSaleRows("boots",10)
assert(#sales==1 and sales[1].name=="Green Boots")
Fire("MAIL_CLOSED")
local added=ChalkBox_MarketCaptureSales()
assert(added==0 and ChalkBox_MarketSalesStatus().count==2,
    "closing mailbox disables further invoice reads")
marketKey="another-realm|horde"
assert(ChalkBox_MarketSalesStatus().count==0,
    "no sale data bleed between markets")
marketKey="whitemaine|alliance"
assert(ChalkBox_MarketSalesStatus().count==2,
    "returning to original market preserves history")
Fire("BAG_UPDATE_DELAYED")
assert(changed>0,"bag changes notify existing AH presentation only")
assert(_G.PostAuction==nil and _G.UseContainerItem==nil,
    "insights never require protected item actions")
print("PASS: My Items bag appraisal, scan freshness, KEEP/bound protection, completed seller mail invoices, dedup, stats and character isolation")
