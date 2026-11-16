-- Forever AuctionSense integration: delayed replication plus browse refresh.
-- Only modern Auction House APIs are simulated. No transactions or real scans.
local events={}
local frame={scripts={}}
function frame:RegisterEvent(name) events[name]=true end
function frame:SetScript(name,cb) self.scripts[name]=cb end
_G.CreateFrame=function(kind) assert(kind=="Frame");return frame end
local now=1700000000
_G.time=function() return now end
_G.GetNormalizedRealmName=function() return "Whitemane" end
_G.UnitFactionGroup=function() return "Alliance" end
_G.DEFAULT_CHAT_FRAME={AddMessage=function() end}
local countReady=false
local browseResults={{itemKey={itemID=2589},minPrice=4300,
    totalQuantity=23}}
local function Fire(event,...)
    assert(events[event],"Missing "..event)
    frame.scripts.OnEvent(frame,event,...)
end
local function Tick(seconds)
    if frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame,seconds or 1) end
end
local requests=0
_G.C_AuctionHouse={
    ReplicateItems=function() requests=requests+1 end,
    GetNumReplicateItems=function() return countReady and 2 or 0 end,
    GetReplicateItemInfo=function(index)
        assert(index==0 or index==1)
        local quantity=index==0 and 2 or 4
        local buyout=index==0 and 10000 or 28000
        return "Linen Cloth",12,quantity,1,true,1,"",0,0,buyout,
            0,nil,nil,nil,nil,0,2589,true
    end,
    SendBrowseQuery=function()
        Fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
        return true
    end,
    GetBrowseResults=function() return browseResults end,
    GetItemKeyInfo=function() return {itemName="Linen Cloth"} end,
    HasFullBrowseResults=function() return true end,
    RequestMoreBrowseResults=function() return true end,
    IsThrottledMessageSystemReady=function() return true end,
}
assert(loadfile("AuctionSense.lua"))("ChalkBox")
Fire("ADDON_LOADED","ChalkBox")
Fire("AUCTION_HOUSE_SHOW")
assert(ChalkBox_AuctionFullScan() and requests==1)
Tick(60)
Tick(60)
assert(ChalkBox_AuctionStatus().busy and
    ChalkBox_AuctionStatus().state:find("awaiting",1,true),
    "Forever's delayed replicate response must NOT time out at 25 or 45s")
Fire("REPLICATE_ITEM_LIST_UPDATE")
assert(ChalkBox_AuctionStatus().busy,
    "early event with zero count must keep waiting instead of discarding")
Tick(1)
assert(ChalkBox_AuctionStatus().busy,"still awaiting the delayed count")
countReady=true
Tick(1)
Tick(1)
local full=ChalkBox_AuctionPrice(2589)
assert(full and full.low==5000 and full.average==6334 and
    full.listings==2 and full.quantity==6 and
    not ChalkBox_AuctionStatus().busy,
    "delayed full scan must compute real unit-weighted average and lots")
assert(ChalkBox_AuctionStatus().cooldown>0,
    "only successful replication consumes the full-scan cooldown")
now=now+30
assert(ChalkBox_AuctionScan())
Tick(1)
local combined=ChalkBox_AuctionPrice(2589)
assert(combined and combined.low==4300 and combined.quantity==23
    and combined.average==6334 and combined.listings==2
    and combined.source=="browse" and combined.detailAge==30,
    "browse updates low/units but retains aged full-listing evidence")
local first=ChalkBox_AuctionRows("linen",10)[1]
assert(first and first.average==6334 and first.listings==2,
    "market table displays actual retained full-scan sample")
-- Missing in a newer browse never fabricates data for other items.
assert(ChalkBox_AuctionPrice(999)==nil)
now=now+8*24*3600
assert(ChalkBox_AuctionPrice(2589).average==nil and
    ChalkBox_AuctionPrice(2589).listings==nil,
    "old full samples expire instead of masquerading as fresh data")
assert(ChalkBox_AuctionFullScan())
Fire("AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED")
assert(not ChalkBox_AuctionStatus().busy and
    ChalkBox_AuctionStatus().error:find("dropped",1,true)
    and ChalkBox_AuctionPrice(2589).low==4300,
    "explicit server throttle-drop aborts cleanly but preserves data")
print("PASS: delayed Forever replicate event, full weighted asks, cooldown, retained browse minima and independently aging listing samples")
