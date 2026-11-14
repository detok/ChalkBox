-- Original AuctionSense regression: no actual transactions or third-party code.
local events={}
local frame={scripts={}}
function frame:RegisterEvent(name) events[name]=true end
function frame:SetScript(name,fn) self.scripts[name]=fn end
_G.CreateFrame=function(kind)
    assert(kind=="Frame")
    return frame
end
local clock=1700000000
_G.time=function() return clock end
_G.GetNormalizedRealmName=function() return "Whitemane" end
local faction="Alliance"
_G.UnitFactionGroup=function(unit) assert(unit=="player");return faction end
local msgs={}
_G.DEFAULT_CHAT_FRAME={AddMessage=function(_,value) msgs[#msgs+1]=value end}
local requested=0
local auctions={}
local function Listing(name,id,count,buyout,link,ready)
    return {name=name,id=id,count=count,buyout=buyout,
        link=link or ("|Hitem:"..id..":0|h["..name.."]|h"),
        ready=ready~=false}
end
_G.C_AuctionHouse={
    ReplicateItems=function() requested=requested+1 end,
    GetNumReplicateItems=function() return #auctions end,
    GetReplicateItemLink=function(index) return auctions[index+1].link end,
    GetReplicateItemInfo=function(index)
        local a=auctions[index+1]
        assert(a,"must use zero-based replicate indices")
        -- name, texture, stack count, quality, usable, level, levelType,
        -- minBid, minIncrement, buyout, bidAmount, highBidder, bidderName,
        -- owner, ownerName, saleStatus, itemID, hasAllInfo
        return a.name,12,a.count,1,true,1,"",0,0,a.buyout,0,
            nil,nil,nil,nil,0,a.id,a.ready
    end,
}
local function Fire(event,...)
    assert(events[event],"event not registered: "..event)
    frame.scripts.OnEvent(frame,event,...)
end
local function Tick(count,elapsed)
    for _=1,(count or 1) do
        if frame.scripts.OnUpdate then
            frame.scripts.OnUpdate(frame,elapsed or 1)
        end
    end
end
assert(loadfile("AuctionSense.lua"))("ChalkBox")
Fire("ADDON_LOADED","ChalkBox")
assert(type(ChalkBoxDB.auctionSense)=="table")
assert(events.AUCTION_HOUSE_SHOW and events.AUCTION_HOUSE_CLOSED
    and events.REPLICATE_ITEM_LIST_UPDATE)
assert(ChalkBox_AuctionPrice(2589)==nil)
assert(not ChalkBox_AuctionFullScan(),"can't scan away from the auctioneer")
Fire("AUCTION_HOUSE_SHOW")
assert(requested==0,"opening the auctioneer never silently starts full scans")
auctions={
    Listing("Linen Cloth",2589,2,10000),
    Listing("Linen Cloth",2589,5,37500),
    Listing("Strange Blade",100,1,70000,"|Hitem:100:0:0:0:1|h[Blade]|h"),
    Listing("Strange Blade",100,1,50000,"|Hitem:100:0:0:0:2|h[Blade]|h"),
    Listing("Bid Only",999,1,0),
    Listing("Copper Ore",2770,4,8000),
}
assert(ChalkBox_AuctionFullScan())
assert(requested==1 and ChalkBox_AuctionStatus().busy)
assert(not ChalkBox_AuctionFullScan(),"busy request cannot send another scan")
Fire("REPLICATE_ITEM_LIST_UPDATE")
Fire("REPLICATE_ITEM_LIST_UPDATE") -- repeated metadata event, ignore
Tick(4)
local status=ChalkBox_AuctionStatus()
assert(not status.busy and status.scannedAt==clock and
    status.auctions==6 and status.items==3,
    "advanced full replicate scan commits once after all listings are read")
local linen=ChalkBox_AuctionPrice("|Hitem:2589:0|h[Linen Cloth]|h")
assert(linen and linen.low==5000 and linen.average==6786 and
    linen.quantity==7 and linen.listings==2 and not linen.mixed,
    "buyout divided by stack count; weighted average is per unit")
assert(linen.kind=="asking" and not linen.stale and linen.age==0)
assert(select(1,ChalkBox_AuctionValue(2589,3))==15000,
    "other ChalkBox modules can value item stacks through the shared API")
assert(ChalkBox_AuctionPrice(999)==nil,
    "bid-only auctions are never treated as buyout prices")
assert(ChalkBox_AuctionPrice(100).mixed and
    ChalkBox_AuctionValue(100,1)==nil,
    "mixed equipment variants have observations, but no safe valuation")
local tip={lines={}}
function tip:AddLine(text)
    self.lines[#self.lines+1]=text
    _G["AuctionSenseTestTextLeft"..#self.lines]={
        GetText=function() return text end}
end
function tip:GetName() return "AuctionSenseTest" end
function tip:NumLines() return #self.lines end
function tip:Show() end
assert(ChalkBox_AuctionTooltip(tip,"item:2589"))
assert(table.concat(tip.lines," "):find("Low ask: 50s",1,true)
    and table.concat(tip.lines," "):find("Avg ask: 67s 86c",1,true),
    "item tooltip clearly labels stack-normalized asking prices")
assert(not ChalkBox_AuctionTooltip(tip,"item:2589"),
    "repeat OnTooltipSetItem calls never duplicate the price block")
assert(not ChalkBox_AuctionTooltip(tip,"item:999"),
    "unpriced items never show guessed auction numbers")
assert(ChalkBox_AuctionRows("linen",100)[1].name=="Linen Cloth")
assert(#ChalkBox_AuctionRows("",100)==3)
assert(not ChalkBox_AuctionFullScan() and requested==1,
    "full-scan cooldown prevents a second server request")
faction="Horde"
assert(not ChalkBox_AuctionPrice(2589),
    "different faction markets remain isolated on the same realm")
faction="Alliance"
clock=clock+86401
assert(ChalkBox_AuctionPrice(2589).stale and
    ChalkBox_AuctionValue(2589,2)==nil,
    "stale data can be displayed with age, not promoted as current valuation")
tip.lines={}
assert(ChalkBox_AuctionTooltip(tip,"item:2589") and
    table.concat(tip.lines," "):find("Old scan",1,true),
    "stale tooltip explicitly warns prices may have changed")
assert(ChalkBox_AuctionFullScan())
auctions={Listing("Linen Cloth",2589,1,9000)}
Fire("REPLICATE_ITEM_LIST_UPDATE")
Tick(2)
assert(ChalkBox_AuctionPrice(2589).low==9000 and
    ChalkBoxDB.auctionSense.markets["whitemane|alliance"].items["2589"].history[2].low==9000,
    "successful scans atomically replace the market and keep bounded price history")
clock=clock+901
auctions={Listing("Linen Cloth",2589,1,4000)}
assert(ChalkBox_AuctionFullScan())
Fire("REPLICATE_ITEM_LIST_UPDATE")
Fire("AUCTION_HOUSE_CLOSED")
Tick(3)
assert(ChalkBox_AuctionPrice(2589).low==9000,
    "closing the AH in the middle of a scan preserves prior complete prices")
Fire("AUCTION_HOUSE_SHOW")
clock=clock+901
assert(ChalkBox_AuctionFullScan())
auctions={Listing("Unknown",2589,1,9000,nil,false)}
Fire("REPLICATE_ITEM_LIST_UPDATE")
Tick(1)
assert(ChalkBox_AuctionStatus().busy)
Tick(1)
Tick(1,3)
Tick(1)
Tick(1,3)
Tick(2)
assert(ChalkBox_AuctionPrice(2589).low==9000,
    "incomplete item metadata cannot replace a complete saved snapshot")
assert(not ChalkBox_AuctionStatus().busy,
    "scanner eventually reports incomplete data without hanging")
clock=clock+901
assert(ChalkBox_AuctionFullScan())
Tick(1,26)
assert(not ChalkBox_AuctionStatus().busy,
    "throttled or ignored server requests time out rather than hanging forever")
assert(ChalkBox_AuctionPrice(2589).low==9000)
ChalkBox_AuctionSetTooltips(false)
assert(not ChalkBox_AuctionStatus().tooltip)
ChalkBox_AuctionCommand("tooltip on")
assert(ChalkBox_AuctionStatus().tooltip)
ChalkBox_AuctionCommand("status")
assert(msgs[#msgs]:find("market whitemane|alliance",1,true),
    "market status includes current realm and faction, never fabricated prices")
-- The old module registered its job AFTER ReplicateItems, losing a synchronous
-- response forever. This must now complete even if the event fires inside it.
clock=clock+901
auctions={Listing("Linen Cloth",2589,3,15000)}
C_AuctionHouse.ReplicateItems=function()
    requested=requested+1
    Fire("REPLICATE_ITEM_LIST_UPDATE")
end
assert(ChalkBox_AuctionFullScan())
Tick(2)
assert(not ChalkBox_AuctionStatus().busy and
    ChalkBox_AuctionPrice(2589).low==5000,
    "synchronous replicate events are handled before the request returns")
print("PASS: AuctionSense manual requests, zero-based replicates, stack prices, weighted asks, variants, stale age, faction isolation, history, cooldown, metadata retries, atomic rollback and timeouts")
