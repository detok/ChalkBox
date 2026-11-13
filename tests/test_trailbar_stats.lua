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
assert(loadfile("TrailBarStats.lua"))("ChalkBox")

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
_G.C_Container=nil
_G.GetInventoryItemDurability=nil
_G.GetXPExhaustion=nil
_G.GetNetStats=nil
_G.UnitClass=nil
s=ChalkBox_BarReadStats(playerMax)
assert(s.bags==nil and s.gear==nil and s.rested==nil
    and s.latency==nil and s.pet==nil,
    "missing Forever APIs must fail quietly and never claim 0")
print("PASS: TrailBar Forever bag/free/special slots, weighted gear, rested XP, latency and safe Hunter state")
