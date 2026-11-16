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
local returnedCount=2
local syntheticLarge=false
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
    GetNumReplicateItems=function() return countReady and returnedCount or 0 end,
    GetReplicateItemInfo=function(index)
        if syntheticLarge then
            assert(index>=0 and index<returnedCount)
            return "Linen Cloth",12,1,1,true,1,"",0,0,5000,
                0,nil,nil,nil,nil,0,2589,true
        end
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
assert(ChalkBox_AuctionStatus().cooldown>0,
    "accepted request starts account-wide cooldown before data is returned")
Tick(60)
Tick(60)
assert(ChalkBox_AuctionStatus().busy and
    ChalkBox_AuctionStatus().state:find("Waiting for full scan response",1,true),
    "Forever's delayed replicate response must NOT time out at 25 or 45s")
Fire("REPLICATE_ITEM_LIST_UPDATE")
assert(ChalkBox_AuctionStatus().busy,
    "early event with zero count must keep waiting instead of discarding")
Tick(1)
assert(ChalkBox_AuctionStatus().busy,"still awaiting the delayed count")
countReady=true
Tick(1)
assert(ChalkBox_AuctionStatus().phase=="settling" and
    ChalkBox_AuctionStatus().reportedListings==2,
    "early signal must wait for replicated count to stabilize")
Tick(1)
Tick(1)
Tick(1)
Tick(1) -- reads the first batch
Tick(1) -- waits for any later auction chunks
Tick(1) -- safely commits after a second quiet window
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
-- The realm can return far more than 150,000 individual auctions. Accept
-- that real count without reading/storing all auctions in a single frame.
now=now+901
returnedCount=200001
assert(ChalkBox_AuctionFullScan())
Fire("REPLICATE_ITEM_LIST_UPDATE")
assert(ChalkBox_AuctionStatus().busy and
    ChalkBox_AuctionStatus().reportedListings==200001,
    "large but valid Forever snapshot is received without rejection")
Tick(1)
returnedCount=200002
Tick(1)
assert(ChalkBox_AuctionStatus().phase=="settling" and
    ChalkBox_AuctionStatus().reportedListings==200002,
    "incoming batches can grow before the scanner starts reading")
Tick(1)
Tick(1)
assert(ChalkBox_AuctionStatus().phase=="reading" and
    ChalkBox_AuctionStatus().totalListings==200002,
    "full scanner starts reading the stabilized initial listing count")
returnedCount=200003
Tick(1)
assert(ChalkBox_AuctionStatus().totalListings==200003
    and ChalkBox_AuctionStatus().busy,
    "later Forever batches extend an active scan rather than losing auctions")
Fire("AUCTION_HOUSE_CLOSED")
assert(not ChalkBox_AuctionStatus().busy
    and ChalkBox_AuctionPrice(2589).low==4300,
    "closing a large scan safely leaves the previous prices intact")
Fire("AUCTION_HOUSE_SHOW")
now=now+901
assert(ChalkBox_AuctionFullScan())
Tick(601)
assert(not ChalkBox_AuctionStatus().busy
    and ChalkBox_AuctionStatus().error:find("10 minutes",1,true)
    and ChalkBox_AuctionPrice(2589).low==4300,
    "silent Forever request stops after 10 minutes without erasing prices")
assert(ChalkBox_AuctionStatus().cooldown>0,
    "even a silent accepted full-scan request has a request cooldown")
-- Exercise an entire full market snapshot spanning multiple frame batches,
-- then append an auction before the final two-second completion check.
now=now+901
syntheticLarge=true
returnedCount=160
assert(ChalkBox_AuctionFullScan())
Fire("REPLICATE_ITEM_LIST_UPDATE")
Tick(1)
Tick(1)
Tick(1) -- switches to reading after 2 quiet seconds
Tick(1) -- first 140 listings
Tick(1) -- remaining 20 listings; begins final quiet period
assert(ChalkBox_AuctionStatus().phase=="finalizing")
returnedCount=161
Tick(1) -- late data invalidates finalization
assert(ChalkBox_AuctionStatus().totalListings==161
    and ChalkBox_AuctionStatus().busy,
    "late full-snapshot chunk invalidates the earlier completion decision")
Tick(1) -- reads last appended listing
Tick(1)
Tick(1) -- final quiet confirmation
local complete=ChalkBox_AuctionPrice(2589)
assert(complete and complete.average==5000 and
    complete.low==5000 and complete.quantity==161 and
    complete.listings==161 and not ChalkBox_AuctionStatus().busy
    and ChalkBox_AuctionStatus().auctions==161,
    "all batches contribute to actual full-market average and listing count")
print("PASS: delayed Forever replicate event, full weighted asks, cooldown, retained browse minima and independently aging listing samples")
