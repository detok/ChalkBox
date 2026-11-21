-- Black Market listings stay out of the normal auction price tables.
_G.ChalkBoxDB={markets={["Whitemane|Alliance"]={items={["2589"]=true}}}}
_G.time=function() return 1800000000 end
local notes={}
_G.DEFAULT_CHAT_FRAME={AddMessage=function(_,text) notes[#notes+1]=text end}
local events={}
local frame
_G.CreateFrame=function()
    frame={events={}}
    function frame:RegisterEvent(name) self.events[name]=true;events[name]=true end
    function frame:SetScript(_,fn) self.fire=fn end
    return frame
end
assert(loadfile("BlackMarket.lua"))("ChalkBox")
assert(events.BLACK_MARKET_OPEN and events.BLACK_MARKET_ITEM_UPDATE
    and events.BLACK_MARKET_CLOSED)
assert(not ChalkBox_BlackMarketStatus().available)
assert(ChalkBox_BlackMarketCommand()==false)
assert(table.concat(notes," "):find("not on this client",1,true),
    "a missing Black Market API is explained and does not error")
assert(ChalkBoxDB.markets["Whitemane|Alliance"].items["2589"],
    "the unavailable client does not rewrite auction prices")
local bids,requests=0,0
_G.C_BlackMarket={
    GetNumItems=function() return 2 end,
    GetItemInfoByIndex=function(index)
        if index==1 then
            return "Orb of Mystery","tex",1,"Armor",true,60,1,"Seller",
                10000,500,25000,false,3,2,"item:12345",9,4
        end
        return "Old Relic","tex",2,"Misc",true,1,1,"Nobody",
            50,5,50,false,1,4,"item:99",8,1
    end,
    RequestItems=function() requests=requests+1 end,
    Bid=function() bids=bids+1 end,
}
-- Reload so the new API is visible to the already-loaded functions.
-- The functions close over C_BlackMarket lookups at call time, not load time.
frame.fire(frame,"BLACK_MARKET_OPEN")
frame.fire(frame,"BLACK_MARKET_ITEM_UPDATE")
local st=ChalkBox_BlackMarketStatus()
assert(st.available and st.open and st.listings==2 and st.history==2
    and bids==0 and requests==0,
    "an open list is read without bidding or requesting a scan")
local price=ChalkBoxDB.markets["Whitemane|Alliance"]
assert(price.items["2589"] and not price.items["12345"],
    "black market rows never enter the auction price table")
assert(ChalkBoxDB.blackMarket.history["item:12345"].samples[1].currBid==25000)
frame.fire(frame,"BLACK_MARKET_ITEM_UPDATE")
assert(#ChalkBoxDB.blackMarket.history["item:12345"].samples==1,
    "the same bid is not stored twice")
_G.C_BlackMarket.GetItemInfoByIndex=function(index)
    if index==1 then
        return "Orb of Mystery","tex",1,"Armor",true,60,1,"Seller",
            10000,500,40000,false,4,1,"item:12345",9,4
    end
    return nil
end
_G.C_BlackMarket.GetNumItems=function() return 1 end
frame.fire(frame,"BLACK_MARKET_ITEM_UPDATE")
local past=ChalkBoxDB.blackMarket.history["item:12345"]
assert(#past.samples==2 and past.samples[2].currBid==40000
    and past.firstSeen==1800000000,
    "a changed bid is kept in that item's own history")
local rows=ChalkBox_BlackMarketRows("relic")
assert(#rows==1 and rows[1].name=="Old Relic" and rows[1].listed==false,
    "items that left the board stay in history and out of the current list")
frame.fire(frame,"BLACK_MARKET_CLOSED")
assert(not ChalkBox_BlackMarketStatus().open)
notes={}
assert(ChalkBox_BlackMarketCommand())
assert(table.concat(notes," "):find("remembered",1,true))
print("PASS: black market listings and bid history stay separate from auction prices")
