-- Classic auction list fallback used when the modern browse API is absent.
local events={}
local frame={scripts={}}
function frame:RegisterEvent(name) events[name]=true end
function frame:SetScript(name,fn) self.scripts[name]=fn end
_G.CreateFrame=function() return frame end
local now=1800000000
_G.time=function() return now end
_G.GetNormalizedRealmName=function() return "Whitemane" end
_G.UnitFactionGroup=function() return "Alliance" end
_G.DEFAULT_CHAT_FRAME={AddMessage=function() end}
_G.CanSendAuctionQuery=function() return true end
local queries=0
_G.QueryAuctionItems=function(name,_,_,_,_,_,page,_,_,getAll)
    assert(name=="" and page==0 and getAll==false)
    queries=queries+1
end
_G.GetNumAuctionItems=function(kind)
    assert(kind=="list")
    return 2,2
end
_G.GetAuctionItemInfo=function(_,index)
    local count=index==1 and 5 or 2
    local buyout=index==1 and 5000 or 800
    return "Linen Cloth",nil,count,1,true,1,"",0,0,buyout
end
_G.GetAuctionItemLink=function(_,index)
    return index==1 and "item:2589" or "item:2770"
end
local function Fire(event)
    assert(events[event],event)
    frame.scripts.OnEvent(frame,event)
end
assert(loadfile("AuctionSense.lua"))("ChalkBox")
Fire("ADDON_LOADED")
Fire("AUCTION_HOUSE_SHOW")
assert(ChalkBox_AuctionScan() and queries==1 and ChalkBox_AuctionStatus().busy)
Fire("AUCTION_ITEM_LIST_UPDATE")
local price=ChalkBox_AuctionPrice(2589)
assert(price and price.low==1000 and price.quantity==5 and
    not ChalkBox_AuctionStatus().busy and
    ChalkBox_AuctionStatus().source=="browse",
    "classic list rows become saved asking prices")
assert(ChalkBox_AuctionPrice(2770).low==400)
assert(ChalkBoxDB.auctionSense.nextAllowed==0,
    "a page scan does not start the full-replicate cooldown")
-- A second scan of the same list must replace prices, not stack them.
queries=0
_G.GetAuctionItemInfo=function()
    return "Linen Cloth",nil,1,1,true,1,"",0,0,3000
end
_G.GetAuctionItemLink=function() return "item:2589" end
_G.GetNumAuctionItems=function() return 1,1 end
assert(ChalkBox_AuctionScan())
Fire("AUCTION_ITEM_LIST_UPDATE")
assert(ChalkBox_AuctionPrice(2589).low==3000 and
    ChalkBox_AuctionPrice(2589).quantity==1,
    "a later classic scan replaces the saved ask instead of adding to it")
assert(ChalkBox_AuctionStatus().available==true,
    "the scan button stays available when only the classic list API exists")
local notes={}
_G.DEFAULT_CHAT_FRAME.AddMessage=function(_,msg) notes[#notes+1]=msg end
local short=0
_G.AuctionFrame={IsShown=function() return true end}
_G.QueryAuctionItems=function(name,_,_,page,_,_,getAll)
    assert(name=="" and page==0 and getAll==false,"short classic query")
    short=short+1
end
assert(ChalkBox_AuctionScan() and short==1,
    "AuctionFrame uses the classic query whose page is the fourth argument")
local joined=table.concat(notes," ")
assert(joined:find("Scan requested",1,true) or joined:find("Waiting",1,true),
    "starting a classic scan says so in chat")
ChalkBox_AuctionCommand("debug")
joined=table.concat(notes," ")
assert(joined:find("classic list",1,true) and joined:find("CanSendAuctionQuery",1,true),
    "debug reports the API path and the throttle")
print("PASS: classic auction list scan saves buyouts when the modern browse API is missing")
