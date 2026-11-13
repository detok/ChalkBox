-- TrailBarStats fixture against Blizzard-compatible Forever data and secret values.
local private={}
local supplies={{16,4,0},{10,1,0},{12,2,8},{8,0,0},{6,3,0}}
local items={[1]={80,100},[5]={50,100},[16]={100,100},[17]={20,100}}
local rest=400
local playerMax=1000
local latencyHome,latencyWorld=21,70
local health,maxHealth=475,500
local hasPet=true
local hunter=true
local function Secret() return private end
_G.issecretvalue=function(v) return v==private end
_G.BACKPACK_CONTAINER=0
_G.NUM_BAG_SLOTS=4
_G.C_Container={
    GetContainerNumSlots=function(bag) return supplies[bag+1][1] end,
    GetContainerNumFreeSlots=function(bag)
        return supplies[bag+1][2],supplies[bag+1][3]
    end,
}
_G.GetInventoryItemDurability=function(slot)
    local value=items[slot]
    if value then return value[1],value[2] end
end
_G.GetXPExhaustion=function() return rest end
_G.GetNetStats=function() return 0,0,latencyHome,latencyWorld end
_G.UnitClass=function() return "Hunter",hunter and "HUNTER" or "MAGE" end
_G.UnitExists=function(u) assert(u=="pet");return hasPet end
_G.UnitHealth=function(u) assert(u=="pet");return health end
_G.UnitHealthMax=function(u) assert(u=="pet");return maxHealth end
-- Vendor resale fixtures: grey junk, colored loot, zero-value items,
-- an uncached reagent and an item with an unknown quality.
local vendorItems={
    [0]={[1]={stackCount=4,quality=0,itemID=100,hasNoValue=false},
         [2]={stackCount=2,quality=3,itemID=200,hasNoValue=false}},
    [1]={[1]={stackCount=3,quality=0,itemID=300,hasNoValue=false}},
    [2]={[1]={stackCount=1,quality=1,itemID=400,hasNoValue=true}},
    [3]={[1]={stackCount=1,itemID=500,hasNoValue=false}},
}
local prices={[100]={quality=0,price=251},
    [200]={quality=3,price=4500},
    [400]={quality=1,price=0},
    [500]={quality=nil,price=75}}
_G.C_Container.GetContainerItemInfo=function(bag,slot)
    return vendorItems[bag] and vendorItems[bag][slot]
end
_G.C_Container.GetContainerItemID=function(bag,slot)
    local item=vendorItems[bag] and vendorItems[bag][slot]
    return item and item.itemID
end
_G.C_Item={GetItemInfo=function(id)
    local value=prices[id]
    if not value then return end -- uncached
    return "Item "..id,"item:"..id,value.quality,nil,nil,nil,nil,nil,nil,nil,
        value.price
end}
assert(loadfile("TrailBarStats.lua"))("ChalkBox")

assert(ChalkBox_BarReadStats(playerMax).bagvalue==nil,
    "default read must not scan bags for expensive vendor values")
local valuation=ChalkBox_BarReadStats(playerMax,true).bagvalue
assert(valuation and valuation.totalCopper==10079 and
    valuation.junkCopper==1004,
    "vendor value multiplies quantities and junk counts only grey-quality items")
assert(valuation.totalUnknown==1 and valuation.junkUnknown==2 and
    not valuation.totalComplete and not valuation.junkComplete,
    "uncached vendor price and unknown quality cannot count as proven zero")
prices[300]={quality=0,price=100}
prices[500]={quality=2,price=75}
valuation=ChalkBox_BarReadStats(playerMax,true).bagvalue
assert(valuation.totalCopper==10379 and valuation.junkCopper==1304 and
    valuation.totalComplete and valuation.junkComplete,
    "newly cached item prices reconcile both complete valuation modes")
prices[300]=nil
prices[500]={quality=nil,price=75}
-- Exact repair-all cost is available only with a repair merchant open;
-- outside the merchant we use a prior quote or explicitly return unknown.
_G.ChalkBoxZoneDB={}
local merchantOpen=false
local quotedCost=30000
_G.MerchantFrame={IsShown=function() return merchantOpen end}
_G.CanMerchantRepair=function() return true end
_G.GetRepairAllCost=function()
    assert(merchantOpen,"repair API must NEVER be called without merchant")
    return quotedCost,true
end
assert(ChalkBox_BarReadStats(playerMax).repair==nil,
    "repair price scanning is disabled when the Bar module is off")
local repair=ChalkBox_BarReadStats(playerMax,false,true).repair
assert(repair.state=="unavailable" and not repair.copper,
    "before a vendor quote an exact-looking repair estimate must not be invented")
merchantOpen=true
repair=ChalkBox_BarReadStats(playerMax,false,true).repair
assert(repair.state=="exact" and repair.copper==30000 and
    repair.missing==150,
    "real repair-all quote is shown only at a real repair vendor")
assert(ChalkBoxZoneDB.repairReference.rate==200,
    "per-character calibration is derived from observed bill and worn durability")
merchantOpen=false
items[1][1]=70
repair=ChalkBox_BarReadStats(playerMax,false,true).repair
assert(repair.state=="estimate" and repair.copper==32000,
    "missing wear scales the last real vendor quote and is marked approximate")
items[17][2]=200
repair=ChalkBox_BarReadStats(playerMax,false,true).repair
assert(repair.state=="needs-calibration" and not repair.copper,
    "changing the durability pool drastically invalidates stale estimates")
items[17][2]=100
items[1][1]=80
merchantOpen=true
quotedCost=0
repair=ChalkBox_BarReadStats(playerMax,false,true).repair
assert(repair.state=="exact" and repair.copper==0,
    "real merchant zero is valid and different from unavailable")
merchantOpen=false
quotedCost=30000
local s=ChalkBox_BarReadStats(playerMax)
assert(s.bags.free==10 and s.bags.total==52 and s.bags.general==8
    and s.bags.special==2 and s.bags.bags==5,
    "equipped bag slot 0-4 must include profession bags without counting bank bags")
assert(s.gear.percent==63 and s.gear.worst==20 and s.gear.items==4,
    "aggregate durability is weighted by max durability and reports worst item")
assert(s.rested.percent==40 and s.rested.xp==400,
    "rested XP must be a percent of the current level, not percent of health")
assert(s.latency.home==21 and s.latency.world==70,
    "latency should distinguish home vs world")
assert(s.pet.state=="ready" and s.pet.percent==95,
    "hunter pet health should be a safe percentage")

rest=private
s=ChalkBox_BarReadStats(1000)
assert(s.rested==nil,"secret rested XP must be unknown instead of guessed")
rest=400
playerMax=private
s=ChalkBox_BarReadStats(playerMax)
assert(s.rested==nil,"secret max XP must not be compared or divided")
playerMax=1000
health=private
s=ChalkBox_BarReadStats(playerMax)
assert(s.pet.state=="protected" and not s.pet.percent,
    "secret pet health must not be read, compared or formatted")
health=475
hasPet=false
s=ChalkBox_BarReadStats(playerMax)
assert(s.pet.state=="none","Hunter without an active pet must report none")
hasPet=true
hunter=false
s=ChalkBox_BarReadStats(playerMax)
assert(s.pet==nil,"non-Hunters should not show meaningless pet module")
hunter=true
latencyWorld=private
s=ChalkBox_BarReadStats(playerMax)
assert(s.latency==nil,"secret network values must stay unavailable")
latencyWorld=70
supplies[2][2]=private
s=ChalkBox_BarReadStats(playerMax)
assert(s.bags.free==9 and s.bags.total==42,
    "a protected bag count must be skipped rather than changing the total to zero")
supplies[2][2]=1
supplies[3][3]=private
s=ChalkBox_BarReadStats(playerMax)
assert(s.bags.free==10 and s.bags.special==0 and s.bags.unknown==2,
    "protected bag family must not be falsely identified as general space")
supplies[3][3]=8
_G.C_Container=nil
_G.GetInventoryItemDurability=nil
_G.GetXPExhaustion=nil
_G.GetNetStats=nil
_G.UnitClass=nil
s=ChalkBox_BarReadStats(playerMax)
assert(s.bags==nil and s.gear==nil and s.rested==nil
    and s.latency==nil and s.pet==nil,
    "missing Forever APIs must fail quietly and never claim 0")
print("PASS: TrailBar vendor junk/total stacks and unknown cache, bag slots, weighted gear, rested XP and safe Hunter state")
