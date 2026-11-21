-- Posting help fills a price only when asked, and never posts or switches tabs.
_G.ChalkBoxDB={}
_G.ChalkBox_AuctionPrice=function(id)
    if id==2589 then return {low=1500,stale=false,mixed=false} end
end
local writes,modeWrites,posts=0,0,0
_G.AuctionHouseFrame={
    SetDisplayMode=function() modeWrites=modeWrites+1 end,
    CommoditiesSellFrame={PriceInput={
        gold={SetText=function(_,v) writes=writes+1;assert(v=="0") end},
        silver={SetText=function(_,v) writes=writes+1;assert(v=="15") end},
        copper={SetText=function(_,v) writes=writes+1;assert(v=="0") end},
    }},
}
_G.PostButton={Click=function() posts=posts+1 end}
assert(loadfile("AuctionPost.lua"))("ChalkBox")
local suggestion=ChalkBox_AuctionPostSuggestion(2589)
assert(suggestion and suggestion.copper==1500 and
    suggestion.reason:find("Post",1,true),
    "the suggestion names the saved ask and says the player still clicks Post")
local ok,message=ChalkBox_AuctionPostFill(2589)
assert(ok and writes==3 and modeWrites==0 and posts==0,
    "a requested fill writes the price boxes and does not post or change auction mode")
assert(message:find("Click Post",1,true))
AuctionHouseFrame.CommoditiesSellFrame.PriceInput.IsProtected=function() return true end
writes=0
local denied=ChalkBox_AuctionPostFill(2589)
assert(denied==false and writes==0 and modeWrites==0,
    "a protected sell box is left alone")
assert(ChalkBox_AuctionPostSet(false)==true)
assert(ChalkBox_AuctionPostSuggestion(2589)==nil,
    "turning the help off stops suggestions without deleting saved prices")
print("PASS: auction posting help suggests and fills only, with no Post click and no display-mode write")
