-- AuctionSense browse-scan regression for Forever modern AH. No trade actions.
local events={}
local f={scripts={}}
function f:RegisterEvent(e) events[e]=true end
function f:SetScript(e,cb) self.scripts[e]=cb end
_G.CreateFrame=function() return f end
local clock=1763130000
_G.time=function() return clock end
_G.GetNormalizedRealmName=function() return "Whitemane" end
_G.UnitFactionGroup=function() return "Alliance" end
local notes={}
_G.DEFAULT_CHAT_FRAME={AddMessage=function(_,s) notes[#notes+1]=s end}
local posted,more=0,0
local full=false
local results={}
local function Fire(name,...)
    assert(events[name],"event not registered: "..name)
    f.scripts.OnEvent(f,name,...)
end
local function Tick(seconds)
    if f.scripts.OnUpdate then f.scripts.OnUpdate(f,seconds or 1) end
end
_G.C_AuctionHouse={
    SendBrowseQuery=function(query)
        assert(query.searchString=="" and type(query.sorts)=="table" and
            type(query.filters)=="table" and type(query.itemClassFilters)=="table",
            "explicit full browse query must use documented arguments")
        posted=posted+1
        -- Forever may deliver responses synchronously.
        Fire("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
    end,
    GetBrowseResults=function() return results end,
    GetItemKeyInfo=function(key)
        return {itemName=key.itemID==2589 and "Linen Cloth" or "Copper Ore"}
    end,
    HasFullBrowseResults=function() return full end,
    RequestMoreBrowseResults=function()
        more=more+1
        full=true
        results={
            {itemKey={itemID=2589},minPrice=1250,totalQuantity=14},
            {itemKey={itemID=2770},minPrice=880,totalQuantity=7},
        }
        Fire("AUCTION_HOUSE_BROWSE_RESULTS_ADDED")
        return true
    end,
    IsThrottledMessageSystemReady=function() return true end,
}
assert(loadfile("AuctionSense.lua"))("ChalkBox")
Fire("ADDON_LOADED","ChalkBox")
assert(not ChalkBox_AuctionScan(),"no auctioneer means no scan")
Fire("AUCTION_HOUSE_SHOW")
results={{itemKey={itemID=2589},minPrice=1500,totalQuantity=10}}
assert(ChalkBox_AuctionScan())
assert(posted==1 and ChalkBox_AuctionStatus().busy)
assert(not ChalkBox_AuctionScan(),"busy scan prevents collisions")
Tick(1.2)
assert(more==1 and ChalkBox_AuctionStatus().busy,
    "browse scan requests one additional page after initial results")
Tick(1.2)
local st=ChalkBox_AuctionStatus()
assert(not st.busy and st.source=="browse" and st.items==2 and
    st.auctions==0 and not st.error,
    "full browse list commits without fabricating listing counts")
local cloth=ChalkBox_AuctionPrice(2589)
assert(cloth and cloth.low==1250 and cloth.average==nil and
    cloth.listings==nil and cloth.quantity==14 and
    cloth.source=="browse" and not cloth.stale,
    "summary gives lowest unit ask and quantity, not invented average")
assert(ChalkBox_AuctionValue(2589,4)==5000,
    "other modules can use a fresh unambiguous browse unit ask")
assert(ChalkBox_AuctionRows("copper",20)[1].low==880)
assert(ChalkBoxDB.auctionSense.nextAllowed==0,
    "browse results do not consume the 15-minute full-listing cooldown")
-- No progress after a request is a visible timeout, never 'waiting' forever.
full=false
results={}
clock=clock+1
assert(ChalkBox_AuctionScan())
Tick(66)
assert(not ChalkBox_AuctionStatus().busy and
    ChalkBox_AuctionStatus().error:find("timed out",1,true),
    "unanswered browse scan returns a clear timeout")
assert(ChalkBox_AuctionPrice(2589).low==1250,
    "failed browse never deletes the last good market")
-- The server may reject a browse query without throwing Lua errors.
local query=C_AuctionHouse.SendBrowseQuery
C_AuctionHouse.SendBrowseQuery=function() return false end
assert(not ChalkBox_AuctionScan() and not ChalkBox_AuctionStatus().busy)
assert(ChalkBox_AuctionStatus().error:find("refused",1,true))
C_AuctionHouse.SendBrowseQuery=query
-- No auctioneer, no scan, even with a cached saved market.
Fire("AUCTION_HOUSE_CLOSED")
assert(not ChalkBox_AuctionScan())
assert(ChalkBox_AuctionPrice(2589).low==1250)
print("PASS: AuctionSense synchronous browse response, native page events, real lowest/quantity, no fabricated average/listings, timeout, throttle isolation and snapshot rollback")
