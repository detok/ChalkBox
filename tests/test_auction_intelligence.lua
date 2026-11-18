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
    [7770]={low=1000,age=100,stale=false,mixed=false,source="full",
        quantity=20,listings=7},
    [7771]={low=10000,age=100,stale=false,mixed=false,source="full",
        quantity=20,listings=7},
    [7772]={low=7200,age=100,stale=false,mixed=false,source="full",
        quantity=20,listings=7},
}
_G.ChalkBox_AuctionPrice=function(id) return prices[id] end
_G.ChalkBox_MarketSalesStatus=function()
    return {gross=100000,fees=5000,count=8}
end
local saleRows={}
_G.time=function() return 1000000 end
_G.ChalkBox_MarketSaleRows=function() return saleRows end
local lib={GetRecipe=function(_,prof,id)
    if prof~=165 then return nil end
    if id==20001 then return {difficulty={180,225,245,270},requiredSkill=180,craftedItemId=4234}
    elseif id==20002 then return {difficulty={orange=190,yellow=235,
        green=260,grey=275},requiredSkill=190,craftedItemId=9001}
    elseif id==20003 then return {difficulty={orange=200,yellow=225,
        green=250,grey=275},requiredSkill=200,craftedItemId=9002,
        reagents={[2319]=5}}
    elseif id==20005 then return {difficulty={200,225,250,275},
        requiredSkill=200,craftedItemId=7771}
    elseif id==20006 then return {difficulty={200,225,250,275},
        requiredSkill=200,craftedItemId=7772}
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
assert(ChalkBox_IntelStatus().enabled==false and
    ChalkBox_IntelEnabled()==false)
assert(ChalkBox_IntelBankStatus(2319)==nil and
    not ChalkBox_IntelObserveBankInventory({[2319]=30},{
        at=1000000,missingTabs=0,unknown=0,containers=2}),
    "bank recording must be impossible while Intelligence is off")
assert(ChalkBoxProfessionDB.intelligence==nil,
    "disabled by default does not create saved data")
local off=Stock()
assert(ChalkBox_IntelAnnotate(off,{freeSlots=2})==nil and
    off[1].note=="Auction candidate",
    "off is a strict no-op for existing bag note behavior")
assert(not ChalkBox_IntelObserveRecipe("Leatherworking",20001,
    {learned=true},{}),"off skips recipe capture")

assert(ChalkBox_IntelSet("enabled",true) and refresh==1)
assert(ChalkBox_IntelStatus().enabled and ChalkBox_IntelEnabled())
assert(ChalkBox_IntelObserveBankInventory({[2319]=21},
    {at=999900,missingTabs=0,unknown=0,containers=2}))
assert(ChalkBox_IntelBankStatus(2319).count==21)
assert(ChalkBox_IntelObserveSkill("Leatherworking",225,225))
assert(ChalkBox_IntelStatus().profession=="Leatherworking")
assert(ChalkBox_IntelStatus().protectGoal==true,
    "profession protection must default on while Intelligence remains opt-in")
assert(ChalkBox_IntelObserveSkill("Cooking",150,225))
assert(ChalkBox_IntelStatus().profession=="Leatherworking",
    "opening Cooking does not steal the primary Leatherworking goal")
assert(ChalkBox_IntelSet("profession","Cooking"))
assert(ChalkBox_IntelStatus().goalPinned and
    ChalkBox_IntelStatus().profession=="Cooking")
assert(ChalkBox_IntelObserveSkill("Leatherworking",225,225))
assert(ChalkBox_IntelStatus().profession=="Cooking",
    "passive skill scans never replace a user-pinned profession")
assert(ChalkBox_IntelSet("profession",nil))
assert(not ChalkBox_IntelStatus().goalPinned and
    ChalkBox_IntelStatus().profession=="Leatherworking",
    "unpin restores automatic primary profession choice")
local info={learned=true,name="Convert Medium Leather",canSkillUp=true}
local schem={outputItemID=4234,quantityMin=1,quantityMax=1,
    reagentSlotSchematics={{required=true,quantityRequired=5,
        reagents={{itemID=2319}}}}}
assert(ChalkBox_IntelObserveRecipe("Leatherworking",20001,info,schem))
-- Historical beta data may contain cross-profession learned snapshots.
-- Discard only records where the real Forever catalog proves ownership.
ChalkBoxProfessionDB.intelligence.recipes["20001"].profession="Cooking"
ChalkBox_IntelAnnotate(Stock(),{freeSlots=1})
assert(ChalkBoxProfessionDB.intelligence.recipes["20001"]==nil,
    "wrong saved Cooking-owned Leatherworking recipe is pruned")
assert(not ChalkBox_IntelObserveRecipe("Cooking",20001,info,schem),
    "stale modern profession heading cannot repopulate false Cooking evidence")
assert(ChalkBox_IntelObserveRecipe("Leatherworking",20001,info,schem),
    "correct client observation can restore a previously corrupted recipe")
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
-- The game can supply exact reagent details through the older reader while
-- output ID and fixed yield come from GetRecipeInfo. No offline DB needed.
assert(ChalkBox_IntelObserveRecipe("Leatherworking",20010,
    {learned=true,name="Live Only Craft",outputItemID=9001,
     quantityMin=1,quantityMax=1},
    {chalkBoxReagentFallback=true,reagentSlotSchematics={{
        required=true,quantityRequired=2,reagents={{itemID=2319}}}}}))
local live=ChalkBoxProfessionDB.intelligence.recipes["20010"]
assert(live and live.output==9001 and live.yield==1 and
    live.inputs[2319]==2 and live.source=="client reagent fallback",
    "live fallback materials and live recipe info must form a complete recipe")
assert(ChalkBox_IntelStatus().recipesComplete>=3 and
    ChalkBox_IntelStatus().recipesIncomplete>=1,
    "coverage diagnostics distinguish usable from incomplete knowledge")
assert(ChalkBox_IntelForgetRecipe("Leatherworking",20010) and
    ChalkBoxProfessionDB.intelligence.recipes["20010"]==nil,
    "explicit unlearned signal invalidates only the stale recipe")
-- LibStub can be a normal function rather than a callable table. Its
-- catalog is still permitted to fill genuinely missing ingredient metadata,
-- but never to grant learned status by itself.
local originalLibStub=LibStub
LibStub=function(key)
    if key=="LibProfessionDB-1.0" then return {
        GetRecipe=function(_,prof,id)
            if prof==165 and id==20011 then return {
                reagents={[2319]=2},craftedItemId=9001,
                difficulty={200,225,250,275},requiredSkill=200
            } end
        end
    } end
end
assert(ChalkBox_IntelObserveRecipe("Leatherworking",20011,
    {learned=true,name="Catalog Assisted Craft",
     quantityMin=1,quantityMax=1},nil))
local assisted=ChalkBoxProfessionDB.intelligence.recipes["20011"]
assert(assisted and assisted.inputs[2319]==2 and
    assisted.output==9001 and assisted.source=="database fallback",
    "function-valued bundled library can enrich a learned recipe safely")
assert(ChalkBox_IntelForgetRecipe("Leatherworking",20011),
    "synthetic library compatibility recipe must not leak into profit tests")
LibStub=originalLibStub

local skillRows=Stock()
local skill=ChalkBox_IntelAnnotate(skillRows,{freeSlots=2,totalSlots=56})
local same=Stock()
local cached=ChalkBox_IntelAnnotate(same,{freeSlots=2,totalSlots=56})
assert(cached==skill and same[1].intel==skillRows[1].intel,
    "unchanged bag snapshots reuse a single planned result and tooltip advice")
ChalkBox_IntelInvalidate()
local rechecked=ChalkBox_IntelAnnotate(Stock(),{freeSlots=2,totalSlots=56})
assert(rechecked~=skill,"explicit observation invalidation forces a new forecast")
assert(skill and skill.mode=="skill" and skill.uncertain,
    "currently capped profession is not promised immediate gains")
assert(skill.reserved[2319] and skill.reserved[2319]>0,
    "skill route reserves learned recipe reagents")
assert(skill.forecastSteps>0 and #skill.route>0 and
    skill.route[1].crafts>0,
    "four-number Forever difficulty tiers produce a named, quantified recipe route")
assert(skillRows[1].intel.goalRecipe and
    skillRows[1].intel.goalRecipeCrafts and
    skillRows[1].intel.goalDetail and
    skillRows[1].intel.trainingDetail,
    "skill tooltip explains craft recipe, required material and capped profession")
assert(skillRows[1].intel.headline and
    skillRows[1].intel.headline:find("Keep",1,true),
    "rows use plain-English actions rather than opaque planner codes")
assert(skillRows[1].intel.bankLastSeen==21 and
    skillRows[1].intel.bankDetail and
    skillRows[1].intel.bankDetail:find("not craftable",1,true),
    "bank observation is last-seen evidence, never silently credited to bags")
-- The profession forecast is about known recipes and inventory. AH prices
-- can rank viable choices but must NEVER gate whether a recipe is planned.
local previousAsk=prices[2319]
prices[2319]=nil
ChalkBox_IntelInvalidate() -- model completed a new/changed AH scan
local offlineRows=Stock()
local offline=ChalkBox_IntelAnnotate(offlineRows,{freeSlots=1})
assert(offline.forecastSteps>0 and offline.reserved[2319]>0,
    "known skill materials are forecast even without ANY AH quote")
assert(offlineRows[1].intel.kind~="SCAN AH",
    "a missing AH scan cannot override known skill material protection")
prices[2319]=previousAsk
ChalkBox_IntelInvalidate()
assert(skillRows[6].intel.kind=="KEEP" and
    skillRows[7].intel.kind=="KEEP",
    "quest-protected and bound items never auctioned")
assert(skillRows[4].intel.kind~="AUCTION" and
    skillRows[5].intel.kind~="AUCTION",
    "stale and mixed-variant auction prices excluded")
assert(ChalkBox_IntelSet("mode","gold"))
local protectedGoldRows=Stock()
local protectedGold=ChalkBox_IntelAnnotate(protectedGoldRows,{freeSlots=2})
assert(protectedGold.reserved[2319]>=skill.reserved[2319] and
    protectedGoldRows[1].intel.keep==50,
    "Make Gold also protects forecast materials by default")
assert(ChalkBox_IntelSet("protectGoal",false))
local goldRows=Stock()
local gold=ChalkBox_IntelAnnotate(goldRows,{freeSlots=2})
assert(gold.mode=="gold" and #gold.actions>0 and
    gold.reserved[2319]==nil,
    "turning off progression protection permits explicit profit-mode exploration")
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
assert(goldRows[8].intel.kind=="VENDOR" and
    goldRows[8].intel.clearsSlots==1 and
    goldRows[8].intel.bagDetail,
    "known grey junk should suggest vendoring and conditional bag-slot recovery")
assert(goldRows[1].intel.comparisonDetail or
    goldRows[2].intel.comparisonDetail,
    "valuation must explain modeled AH net against vendor value")
local priceMissing=prices[2319]
prices[2319]=nil
ChalkBox_IntelInvalidate()
local missingRows=Stock()
ChalkBox_IntelAnnotate(missingRows,{freeSlots=1})
assert(missingRows[1].intel.kind=="SCAN AH",
    "missing gold-market price requests the precise missing evidence")
-- Real, exact-name seller invoices provide evidence even when today's scan
-- is missing. One old sale alone must never imply present demand.
saleRows={
    {name="Medium Leather",count=10,gross=15000,cut=750,at=999000},
    {name="Medium Leather",count=10,gross=15000,cut=750,at=999500},
}
ChalkBox_IntelInvalidate() -- model received new confirmed seller invoices
local historic=Stock()
ChalkBox_IntelAnnotate(historic,{freeSlots=1})
assert(historic[1].intel.kind=="AUCTION" and
    historic[1].intel.reason:find("seller invoices",1,true),
    "repeated recent real sales justify a qualified decision without a fresh scan")
saleRows[2]=nil
ChalkBox_IntelInvalidate()
local onlyOne=Stock()
ChalkBox_IntelAnnotate(onlyOne,{freeSlots=1})
assert(onlyOne[1].intel.kind=="SCAN AH",
    "one past sale is insufficient evidence to infer repeat demand")
saleRows={
    {name="Medium Leather",count=10,gross=15000,cut=750,
        at=1000000-41*86400},
    {name="Medium Leather",count=10,gross=15000,cut=750,
        at=999500},
}
ChalkBox_IntelInvalidate()
local mixedAges=Stock()
ChalkBox_IntelAnnotate(mixedAges,{freeSlots=1})
assert(mixedAges[1].intel.kind=="SCAN AH",
    "a single recent sale plus an ancient invoice cannot count as repeated demand")
saleRows={}
prices[2319]=priceMissing
ChalkBox_IntelInvalidate()
local unknown=Stock()
unknown[1].boundKnown=false
ChalkBox_IntelAnnotate(unknown,{freeSlots=1})
assert(unknown[1].intel.kind=="HOLD",
    "missing game bind state produces a clear safe holding action, not AH advice")
assert(ChalkBox_IntelReserve(2319,45))
local hold=Stock()
local protectedPlan=ChalkBox_IntelAnnotate(hold,{freeSlots=1})
assert(protectedPlan.reserved[2319]==45 and
    hold[1].intel.keep==45 and hold[1].intel.surplus==5 and
    (hold[1].intel.qty or 0)<=5,
    "explicit reserve splits stock into kept versus available, without double spend")
local displayed={}
local mockTip={
    GetName=function() return "MockInventoryTip" end,
    NumLines=function() return 0 end,
    AddLine=function(_,line) displayed[#displayed+1]=line end,
    Show=function() end
}
assert(ChalkBox_IntelTooltip(mockTip,"item:2319"))
assert(displayed[1]:find("ChalkBox",1,true) and
    table.concat(displayed," | "):find("Personal reserve: 45",1,true),
    "normal item tooltip shows one understandable advice block and its evidence")
assert(ChalkBox_IntelIgnore(2319,true))
local ignored=Stock()
ChalkBox_IntelAnnotate(ignored,{freeSlots=1})
assert(ignored[1].intel.kind=="IGNORE")
assert(ChalkBox_IntelIgnore(2319,false))
-- A malformed optional planning snapshot must never leave a partially
-- rewritten AuctionSense table if one row fails during processing.
local invalid=Stock()
invalid[#invalid+1]={itemID=nil,name="Malformed optional item",
    count=1,note="Native note must survive"}
ChalkBox_IntelInvalidate()
assert(ChalkBox_IntelAnnotate(invalid,{freeSlots=2})==nil,
    "planner failures must be isolated from AuctionSense")
for _,row in ipairs(invalid) do
    assert(row.intel==nil,
        "planner error restores every prior item annotation")
end
assert(invalid[1].note=="Auction candidate" and
    invalid[#invalid].note=="Native note must survive",
    "planner error preserves original notes after partial processing")
-- Competing profitable recipes share the same six materials.
-- The higher-margin craft A consumes four and strands two; making B
-- twice yields more TOTAL extra value. A first-fit greedy sorter fails.
assert(ChalkBox_IntelSet("protectGoal",false))
assert(ChalkBox_IntelObserveRecipe("Leatherworking",20005,
    {learned=true,name="Premium Craft A",canSkillUp=true},
    {outputItemID=7771,quantityMin=1,quantityMax=1,
     reagentSlotSchematics={{required=true,quantityRequired=4,
         reagents={{itemID=7770}}}}}))
assert(ChalkBox_IntelObserveRecipe("Leatherworking",20006,
    {learned=true,name="Efficient Craft B",canSkillUp=true},
    {outputItemID=7772,quantityMin=1,quantityMax=1,
     reagentSlotSchematics={{required=true,quantityRequired=3,
         reagents={{itemID=7770}}}}}))
local contested={{itemID=7770,name="Sample Raw Material",count=6,
    vendor=10,classID=7,stacks=1,boundKnown=true}}
local combined=ChalkBox_IntelAnnotate(contested,{freeSlots=1})
assert(combined and combined.optimization=="bounded combination search")
assert(ChalkBox_IntelCommand("plan"),
    "explicit diagnostic should show computed actionable plan without auctioning")
local selectedB=false
for _,action in ipairs(combined.actions) do
    if action.kind=="CRAFT" and action.itemID==20006 and
        action.count==2 then selectedB=true end
end
assert(selectedB and contested[1].intel.kind=="CRAFT" and
    contested[1].intel.qty==6,
    "bounded inventory search beats ratio-greedy when two smaller crafts pay more")
_G.ChalkBox_ProfessionHas=function(profession)
    return profession~="Leatherworking"
end
ChalkBox_IntelInvalidate()
local stale=ChalkBox_IntelAnnotate({{
    itemID=7770,name="Sample Raw Material",count=6,vendor=10,
    classID=7,stacks=1,boundKnown=true}},{freeSlots=1})
for _,action in ipairs(stale.actions) do
    assert(action.kind~="CRAFT",
        "a no-longer-owned profession must not offer cached crafting routes")
end
_G.ChalkBox_ProfessionHas=nil
ChalkBox_IntelInvalidate()
assert(ChalkBox_IntelSet("learn",false))
assert(ChalkBox_IntelSet("protectGoal",true))
assert(ChalkBox_IntelSet("target",50))
assert(ChalkBox_IntelSet("margin",50))
assert(ChalkBox_IntelStatus().target==50 and
    ChalkBox_IntelStatus().margin==50 and
    ChalkBox_IntelStatus().learn==false)

assert(ChalkBox_IntelSet("enabled",false))
assert(ChalkBox_IntelEnabled()==false and
    ChalkBox_IntelCommand("plan")==false and
    ChalkBox_IntelBankStatus(2319)==nil and
    not ChalkBox_IntelObserveBankInventory({[2319]=9000},
        {at=1000001,missingTabs=0,unknown=0,containers=2}),
    "after disabling, even explicit bank callback cannot record changes")
local fallback=Stock()
assert(ChalkBox_IntelAnnotate(fallback,{freeSlots=2})==nil)
assert(fallback[1].intel==nil and
    fallback[1].note=="Auction candidate",
    "toggle off restores legacy notes without user-facing changes")
assert(_G.PostAuction==nil and _G.UseContainerItem==nil,
    "no direct auction or inventory actions were introduced")
print("PASS: opt-in intelligence, learning bounds, actual recipes, capped skill, two-step crafting, shared-stock budget, reserves, mixed/stale/protected safety and off no-op")
