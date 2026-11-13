-- Optional loot-window observations are NOT official per-creature drop rates.
_G.ChalkBoxZoneDB={}
local events={}
_G.CreateFrame=function()
    local frame={}
    function frame:RegisterEvent(k) events[k]=true end
    function frame:SetScript(_,callback) _G.onDropEvent=callback end
    return frame
end
_G.GetTime=function() return _G.dropTime end
_G.dropTime=100
local guid="Creature-0-000-000-001-3145"
local sourceLinks={"|Hitem:100:0|h[Trinket]|h","|Hitem:200:0|h[Bone]|h"}
_G.GetNumLootItems=function() return #sourceLinks end
_G.GetLootSlotLink=function(i) return sourceLinks[i] end
_G.GetLootSlotInfo=function(i) return nil,nil,i==1 and 2 or 1 end
_G.GetLootSourceInfo=function() return guid,1 end
local sessions=0
_G.ChalkBox_JournalNoteLoot=function(total,items)
    sessions=sessions+1
    assert(total>=1 and type(items)=="table")
end
assert(loadfile("DropSense.lua"))("ChalkBox")
assert(events.LOOT_READY and events.LOOT_OPENED and events.LOOT_CLOSED)
local s=ChalkBox_DropOptions()
assert(not s.enabled and s.watched==0)
assert(ChalkBox_DropWatch("item:100","Test Trinket"))
assert(ChalkBox_DropWatch("item:300","Rare Trinket"))
onDropEvent(nil,"LOOT_OPENED")
assert(ChalkBox_DropOptions().windows==0,
    "no loot data is captured until the player opts in")
assert(ChalkBox_DropSetOption("enabled",true))
onDropEvent(nil,"LOOT_READY")
onDropEvent(nil,"LOOT_OPENED")
local a=ChalkBox_DropRead("item:100")
assert(a.windows==1 and a.hits==1 and a.quantity==2 and
    a.rate==100 and a.low<100,
    "one loot window yields one observation, not two due to multiple events")
assert(ChalkBox_DropRead(300).hits==0 and sessions==1)
onDropEvent(nil,"LOOT_CLOSED")
_G.dropTime=105
onDropEvent(nil,"LOOT_OPENED")
assert(ChalkBox_DropRead(100).windows==1,
    "reopening the same source soon cannot inflate its sample")
onDropEvent(nil,"LOOT_CLOSED")
_G.dropTime=200
guid="Creature-0-000-000-001-3146"
sourceLinks={"|Hitem:200:0|h[Bone]|h"}
onDropEvent(nil,"LOOT_OPENED")
a=ChalkBox_DropRead(100)
assert(a.windows==2 and a.hits==1 and a.rate==50 and sessions==2,
    "both successes and observed misses count in sampled loot windows")
assert(ChalkBox_DropCalculate(5,10)>40 and
    ChalkBox_DropCalculate(5,10)<41,
    "5 percent independent chance over ten tries gives about 40.1 percent")
assert(ChalkBox_DropCalculate(100,1)==100 and
    ChalkBox_DropCalculate(0,100)==0 and
    not ChalkBox_DropCalculate(500,3))
assert(ChalkBox_DropReference(100,2.5))
assert(ChalkBox_DropRead(100).reference==2.5,
    "user-provided external rates are labeled references, never official data")
local captured={}
local button={GetName=function() return "LootButton1" end}
local tooltip={
    GetOwner=function() return button end,
    AddLine=function(_,line) captured[#captured+1]=line end,
    Show=function() end,
}
assert(ChalkBox_DropTooltip(tooltip,"item:100"))
assert(table.concat(captured," "):find("NOT an official drop chance",1,true),
    "tooltip must explicitly disavow unverified Forever probabilities")
tooltip.GetOwner=function() return {GetName=function() return "ContainerFrame1Item1" end} end
assert(not ChalkBox_DropTooltip(tooltip,"item:100"),
    "no drop-rate clutter in ordinary bag or merchant item tooltips")
assert(ChalkBox_DropSetOption("tooltip",false))
tooltip.GetOwner=function() return button end
assert(not ChalkBox_DropTooltip(tooltip,"item:100"),
    "loot window annotations are a separate opt-in switch")
assert(ChalkBox_DropUnwatch(300))
assert(ChalkBox_DropOptions().watched==1)
print("PASS: optional drop window sampling, bounded watched items, correct event dedupe, observed confidence ranges and calculator")
