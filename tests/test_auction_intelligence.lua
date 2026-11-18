-- Regression suite for optional AuctionSense Intelligence.
-- Lua 5.1 compatible, no game writes, no protected UI, no server calls.
_G.ChalkBoxProfessionDB={}
local refresh=0
_G.ChalkBox_ProfessionRefresh=function() refresh=refresh+1 end
_G.ChalkBox_AuctionRefreshUI=function() end
_G.DEFAULT_CHAT_FRAME={AddMessage=function() end}
local prices={
    [2319]={low=1000,age=100,stale=false,mixed=false,source="full",
        quantity=50,listings=10},
    [4234]={low=12000,age=100,stale=false,mixed=false,source="full",
        quantity=15,listings=5},
    [2320]={low=500,age=100,stale=false,mixed=false,source="full",
        quantity=40,listings=6},
    [9001]={low=30000,age=100,stale=false,mixed=false,source="full",
        quantity=12,listings=5},
    [9002]={low=40000,age=2*86400,stale=true,mixed=false,
        source="full",quantity=20,listings=5},
    [9003]={low=50000,age=100,stale=false,mixed=true,
        source="full",quantity=20,listings=5},
}
_G.ChalkBox_AuctionPrice=function(id) return prices[id] end
_G.ChalkBox_MarketSalesStatus=function()
    return {gross=100000,fees=5000,count=8}
end
_G.ChalkBox_MarketSaleRows=function() return {} end
local lib={GetRecipe=function(_,prof,id)
    if prof~=165 then return nil end
    if id==20001 then return {difficulty={orange=180,yellow=225,
        green=245,grey=270},requiredSkill=180,craftedItemId=4234}
    elseif id==20002 then return {difficulty={orange=190,yellow=235,
        green=260,grey=275},requiredSkill=190,craftedItemId=9001}
    elseif id==20003 then return {difficulty={orange=200,yellow=225,
        green=250,grey=275},requiredSkill=200,craftedItemId=9002,
        reagents={[2319]=5}}
    end
end,IsBorrowed=function() return nil end}
_G.LibStub=setmetatable({},{__call=function(_,key)
    if key=="LibProfessionDB-1.0" then return lib end
end})
local function Stock()
    local rows={
        {itemID=2319,name="Medium Leather",count=50,stacks=3,
            vendor=50,classID=7,note="Auction candidate"},
        {itemID=4234,name="Heavy Leather",count=3,stacks=1,
            vendor=200,classID=7,note="Auction candidate"},
        {itemID=2320,name="Thread",count=10,stacks=1,
            vendor=100,classID=7,note="Auction candidate"},
        {itemID=9002,name="Old Gear",count=1,stacks=1,vendor=1000,
            note="No fresh ask"},
        {itemID=9003,name="Mixed Item",count=1,stacks=1,vendor=1000,
            note="No fresh ask"},
        {itemID=9997,name="Quest Material",count=4,stacks=1,vendor=50,
            protected=true,note="KEEP"},
        {itemID=9998,name="Bound Material",count=3,stacks=1,vendor=10,
            bound=true,note="BOUND"},
        {itemID=9999,name="Broken Claw",count=3,stacks=1,vendor=22,
            quality=0,note="No fresh ask"}
    }
    for _,row in ipairs(rows) do row.boundKnown=true end
    return rows
end
assert(loadfile("AuctionIntelligence.lua"))("ChalkBox")
assert(ChalkBox_IntelStatus().enabled==false)
assert(ChalkBoxProfessionDB.intelligence==nil,
    "disabled by default does not create saved data")
local off=Stock()
assert(ChalkBox_IntelAnnotate(off,{freeSlots=2})==nil and
    off[1].note=="Auction candidate",
    "off is a strict no-op for existing bag note behavior")
assert(not ChalkBox_IntelObserveRecipe("Leatherworking",20001,
    {learned=true},{}),"off skips recipe capture")

assert(ChalkBox_IntelSet("enabled",true) and refresh==1)
assert(ChalkBox_IntelStatus().enabled)
assert(ChalkBox_IntelObserveSkill("Leatherworking",225,225))
local info={learned=true,name="Convert Medium Leather",canSkillUp=true}
local schem={outputItemID=4234,quantityMin=1,quantityMax=1,
    reagentSlotSchematics={{required=true,quantityRequired=5,
        reagents={{itemID=2319}}}}}
assert(ChalkBox_IntelObserveRecipe("Leatherworking",20001,info,schem))
assert(ChalkBox_IntelObserveRecipe("Leatherworking",20002,
    {learned=true,name="Leather Gloves",canSkillUp=true},
    {outputItemID=9001,quantityMin=1,quantityMax=1,
     reagentSlotSchematics={
        {required=true,quantityRequired=1,reagents={{itemID=4234}}},
        {required=true,quantityRequired=1,reagents={{itemID=2320}}}}}))
-- Alternatives must never be falsely summed as multiple requirements.
ChalkBox_IntelObserveRecipe("Leatherworking",20003,
    {learned=true,name="Variable Recipe",canSkillUp=true},
    {outputItemID=9002,quantityMin=1,quantityMax=1,
     reagentSlotSchematics={{required=true,quantityRequired=5,
       reagents={{itemID=2319},{itemID=4234}}}}})
assert(ChalkBoxProfessionDB.intelligence.recipes["20003"].inputs==nil,
    "ambiguous client recipe must not be revived by bundled database")
ChalkBox_IntelObserveRecipe("Leatherworking",20004,
    {learned=true,name="Uncertain Yield",canSkillUp=true},
    {outputItemID=9001,quantityMin=1,quantityMax=3,
     reagentSlotSchematics={{required=true,quantityRequired=2,
       reagents={{itemID=2319}}}}})
assert(ChalkBoxProfessionDB.intelligence.recipes["20004"].inputs==nil,
    "variable-yield recipe must not acquire a fabricated one-item output")

local skillRows=Stock()
local skill=ChalkBox_IntelAnnotate(skillRows,{freeSlots=2,totalSlots=56})
assert(skill and skill.mode=="skill" and skill.uncertain,
    "currently capped profession is not promised immediate gains")
assert(skill.reserved[2319] and skill.reserved[2319]>0,
    "skill route reserves learned recipe reagents")
-- The profession forecast is about known recipes and inventory. AH prices
-- can rank viable choices but must NEVER gate whether a recipe is planned.
local previousAsk=prices[2319]
prices[2319]=nil
local offlineRows=Stock()
local offline=ChalkBox_IntelAnnotate(offlineRows,{freeSlots=1})
assert(offline.forecastSteps>0 and offline.reserved[2319]>0,
    "known skill materials are forecast even without ANY AH quote")
assert(offlineRows[1].intel.kind~="SCAN AH",
    "a missing AH scan cannot override known skill material protection")
prices[2319]=previousAsk
assert(skillRows[6].intel.kind=="KEEP" and
    skillRows[7].intel.kind=="KEEP",
    "quest-protected and bound items never auctioned")
assert(skillRows[4].intel.kind~="AUCTION" and
    skillRows[5].intel.kind~="AUCTION",
    "stale and mixed-variant auction prices excluded")
assert(ChalkBox_IntelSet("mode","gold"))
local goldRows=Stock()
local gold=ChalkBox_IntelAnnotate(goldRows,{freeSlots=2})
assert(gold.mode=="gold" and #gold.actions>0)
local hasConnectedChain=false
for _,action in ipairs(gold.actions) do
    if action.kind=="CRAFT" and
        action.reason:find(" > ",1,true) then
        hasConnectedChain=true
    end
end
assert(hasConnectedChain,
    "two-step ingredient-to-product paths should be compared when supported")
local allocated={}
for _,action in ipairs(gold.actions) do
    if action.kind=="CRAFT" then
        assert(action.advantage>=2000)
    end
end
for _,item in ipairs(goldRows) do
    if item.intel.kind=="CRAFT" then
        assert(item.intel.qty<=item.count,
            "shared crafting inputs may never be spent twice")
    end
end
assert(goldRows[6].intel.kind=="KEEP" and
    goldRows[7].intel.kind=="KEEP")
assert(goldRows[4].intel.kind~="AUCTION" and
    goldRows[5].intel.kind~="AUCTION")
assert(goldRows[8].intel.kind=="VENDOR",
    "verified unprotected grey junk is vendored without a market scan")
local priceMissing=prices[2319]
prices[2319]=nil
local missingRows=Stock()
ChalkBox_IntelAnnotate(missingRows,{freeSlots=1})
assert(missingRows[1].intel.kind=="SCAN AH",
    "missing gold-market price requests the precise missing evidence")
prices[2319]=priceMissing
local unknown=Stock()
unknown[1].boundKnown=false
ChalkBox_IntelAnnotate(unknown,{freeSlots=1})
assert(unknown[1].intel.kind=="HOLD",
    "missing game bind state produces a clear safe holding action, not AH advice")
assert(ChalkBox_IntelReserve(2319,45))
local hold=Stock()
local protectedPlan=ChalkBox_IntelAnnotate(hold,{freeSlots=1})
assert(protectedPlan.reserved[2319]==45 and
    (hold[1].intel.qty or 0)<=5,
    "explicit reserve reduces craft/sale availability")
assert(ChalkBox_IntelIgnore(2319,true))
local ignored=Stock()
ChalkBox_IntelAnnotate(ignored,{freeSlots=1})
assert(ignored[1].intel.kind=="IGNORE")
assert(ChalkBox_IntelIgnore(2319,false))
assert(ChalkBox_IntelSet("learn",false))
assert(ChalkBox_IntelSet("target",50))
assert(ChalkBox_IntelSet("margin",50))
assert(ChalkBox_IntelStatus().target==50 and
    ChalkBox_IntelStatus().margin==50 and
    ChalkBox_IntelStatus().learn==false)

assert(ChalkBox_IntelSet("enabled",false))
local fallback=Stock()
assert(ChalkBox_IntelAnnotate(fallback,{freeSlots=2})==nil)
assert(fallback[1].intel==nil and
    fallback[1].note=="Auction candidate",
    "toggle off restores legacy notes without user-facing changes")
assert(_G.PostAuction==nil and _G.UseContainerItem==nil,
    "no direct auction or inventory actions were introduced")
print("PASS: opt-in intelligence, learning bounds, actual recipes, capped skill, two-step crafting, shared-stock budget, reserves, mixed/stale/protected safety and off no-op")
