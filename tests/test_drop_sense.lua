-- DropSense 1.11: every readable item, actual zone + instance attribution,
-- source-specific observed windows ONLY; never official/kill drop rates.
_G.ChalkBoxZoneDB={}
local handlers,events={},{}
_G.CreateFrame=function()
    local f={}
    function f:RegisterEvent(e) events[e]=true end
    function f:SetScript(key,callback)
        if key=="OnEvent" then handlers.event=callback end
    end
    return f
end
local now=100
_G.GetTime=function() return now end
local mapID=1436
local maps={
    [1436]={name="Westfall",mapType=3,parentMapID=13},
    [1437]={name="Redridge Mountains",mapType=3,parentMapID=13},
    [13]={name="Eastern Kingdoms",mapType=2,parentMapID=947},
    [105]={name="The Deadmines",mapType=4,parentMapID=1436}
}
_G.C_Map={
    GetBestMapForUnit=function() return mapID end,
    GetMapInfo=function(id) return maps[id] end
}
local instance=false
_G.GetInstanceInfo=function()
    if instance then return "The Deadmines","party",1,"Normal",5,nil,nil,36 end
    return "Westfall","none",0,nil,nil,nil,nil,0
end
local guid="Creature-0-1-22-333-12345-00002A"
local links={"|Hitem:100:0|h[Linen Cloth]|h","|Hitem:200:0|h[Bone]|h"}
_G.GetNumLootItems=function() return #links end
_G.GetLootSlotLink=function(slot) return links[slot] end
_G.GetLootSlotInfo=function(slot)
    return nil,nil,slot==1 and 2 or 1
end
local overrideSources
_G.GetLootSourceInfo=function(slot)
    if overrideSources then return overrideSources[slot],1 end
    return guid,1
end
_G.UnitGUID=function() return guid end
_G.UnitName=function() return "Defias Bandit" end
local sessions,seenZone=0,nil
_G.ChalkBox_JournalNoteLoot=function(total,items,areaKey)
    sessions=sessions+1
    assert(total>=1 and type(items)=="table")
    seenZone=areaKey
end
assert(loadfile("DropSense.lua"))("ChalkBox")
assert(events.LOOT_OPENED and events.LOOT_READY and
    events.LOOT_CLOSED and events.ZONE_CHANGED_NEW_AREA)
local opt=ChalkBox_DropOptions()
assert(opt.enabled and opt.mapButton and opt.tooltip and
    opt.watched==0,"new installs automatically record all visible loot")
handlers.event(nil,"PLAYER_ENTERING_WORLD")
handlers.event(nil,"LOOT_READY")
handlers.event(nil,"LOOT_OPENED")
assert(ChalkBox_DropOptions().windows==1 and
    ChalkBox_DropOptions().watched==2 and sessions==1,
    "no manual watch required; duplicate loot-ready/opened samples once")
assert(seenZone=="z:1436","location uses actual Forever UI zone ID")
local cloth=ChalkBox_DropRead(100)
assert(cloth.quantity==2 and cloth.windows==1 and
    not cloth.rate,"global counts never imply a server drop chance")
local detail=ChalkBox_DropRead(100,"z:1436","c:12345")
assert(detail and detail.attempts==1 and detail.hits==1 and
    detail.rate==100 and detail.low<100,
    "only named unambiguous creature opportunities have observed frequency")
local zone=ChalkBox_DropMapData(1436)
assert(zone.zone.name=="Westfall" and #zone.dungeons==0)
local firstAreaItems=ChalkBox_DropAreaItems("z:1436")
assert(#firstAreaItems==2,
    "zone lists every observed item without a manually selected watchlist")
local clothSummary
for _,item in ipairs(firstAreaItems) do
    if item.id=="100" then clothSummary=item end
end
assert(clothSummary and clothSummary.hits==1 and
    clothSummary.attempts==1 and clothSummary.rate==100 and
    clothSummary.sourceName=="Defias Bandit",
    "with one verified mob source, show drops / loots and rate immediately")
assert(#ChalkBox_DropSources("z:1436")==1)
handlers.event(nil,"LOOT_CLOSED")
now=110;handlers.event(nil,"LOOT_OPENED")
assert(ChalkBox_DropOptions().windows==1,
    "same corpse reopening never double-counts")
handlers.event(nil,"LOOT_CLOSED")
now=300
guid="Creature-0-1-22-333-12345-00002B"
links={"|Hitem:200:0|h[Bone]|h"}
handlers.event(nil,"LOOT_OPENED")
detail=ChalkBox_DropRead(100,"z:1436","c:12345")
assert(detail.attempts==2 and detail.hits==1 and detail.rate==50,
    "only another looted bandit contributes a meaningful miss")
handlers.event(nil,"LOOT_CLOSED")
now=500
guid="Creature-0-1-22-333-99999-00002C"
links={"|Hitem:300:0|h[Uncommon Cloak]|h",
    "|Hitem:100:0|h[Linen Cloth]|h"}
handlers.event(nil,"LOOT_OPENED")
detail=ChalkBox_DropRead(100,"z:1436","c:12345")
assert(detail.attempts==2 and detail.rate==50,
    "another creature type cannot pollute the Defias Bandit denominator")
local ambiguousArea=ChalkBox_DropAreaItems("z:1436")
local ambiguousCloth
for _,item in ipairs(ambiguousArea) do
    if item.id=="100" then ambiguousCloth=item end
end
assert(ambiguousCloth and ambiguousCloth.rate==nil,
    "two identified mob types never produce a fake combined drop rate")
local banditCloth=ChalkBox_DropAreaItems("z:1436","c:12345")
assert(#banditCloth>=1 and banditCloth[1].rate==50 and
    banditCloth[1].hits==1 and banditCloth[1].attempts==2,
    "specific creature filter reports exactly its own tracked 1/2 = 50%")
handlers.event(nil,"LOOT_CLOSED")
now=550
overrideSources={
    "Creature-0-1-22-333-12345-00002D",
    "Creature-0-1-22-333-99999-00002E"}
links={"|Hitem:100:0|h[Linen Cloth]|h",
    "|Hitem:400:0|h[Armor Scraps]|h"}
handlers.event(nil,"LOOT_OPENED")
assert(ChalkBox_DropRead(100,"z:1436","c:12345").attempts==2,
    "mixed-source windows are counted as zone discoveries but not mob rolls")
assert(ChalkBox_DropRead(400).quantity==1)
handlers.event(nil,"LOOT_CLOSED")
overrideSources=nil
now=650
instance=true;mapID=105
handlers.event(nil,"ZONE_CHANGED_NEW_AREA")
guid="Creature-0-1-22-333-12345-00002F"
links={"|Hitem:500:0|h[Dungeon Trinket]|h"}
handlers.event(nil,"LOOT_OPENED")
local discovered=ChalkBox_DropMapData(1436)
assert(#discovered.dungeons==1 and
    discovered.dungeons[1].name=="The Deadmines",
    "instance history links separately to the observed entrance zone")
assert(ChalkBox_DropRead(500).quantity==2,
    "observed dungeon item stacks retain game-provided quantities")
assert(ChalkBox_DropRead(500,"z:1436")==nil or
    ChalkBox_DropRead(500,"z:1436").areaQuantity==nil,
    "dungeon items do not leak into outdoors")
assert(#ChalkBox_DropAreaItems(discovered.dungeons[1].key)==1)
handlers.event(nil,"LOOT_CLOSED")
now=800;instance=false;mapID=1437
handlers.event(nil,"ZONE_CHANGED_NEW_AREA")
assert(ChalkBox_DropMapData(1437).zone==nil,
    "unvisited outdoor zone does not borrow Westfall's loot")
assert(ChalkBox_DropCalculate(5,10)>40 and
    ChalkBox_DropCalculate(5,10)<41 and
    ChalkBox_DropCalculate(0,10)==0 and
    ChalkBox_DropCalculate(100,1)==100)
local captured={}
local button={GetName=function() return "LootButton1" end}
local tooltip={
    GetOwner=function() return button end,
    AddLine=function(_,line) captured[#captured+1]=line end,
    Show=function() end}
-- Last drop was in dungeon; global count remains valid without claiming a
-- percentage for current unrelated loot source.
assert(ChalkBox_DropTooltip(tooltip,"item:500"))
assert(table.concat(captured," "):find("NOT official drop odds",1,true))
tooltip.GetOwner=function()
    return {GetName=function() return "ContainerFrame1Item1" end}
end
assert(not ChalkBox_DropTooltip(tooltip,"item:500"),
    "map discovery annotations cannot invade bag/merchant tooltips")
ChalkBox_DropSetOption("mapButton",false)
assert(not ChalkBox_DropOptions().mapButton)
ChalkBox_DropSetOption("enabled",false)
handlers.event(nil,"LOOT_OPENED")
assert(ChalkBox_DropOptions().windows==5,
    "tracking off genuinely stops new sampling, old history remains")
-- Previous 1.10.0 saved watches are retained as older unsited observations;
-- never backfill invented zone/source data.
ChalkBoxZoneDB.dropSense={version=1,enabled=false,tooltip=true,
    items={["777"]={name="Legacy Loot",windows=30,hits=4,
        quantity=5,reference=1.5}},windows=30}
local migrated=ChalkBox_DropOptions()
assert(not migrated.enabled and migrated.legacyWindows==30)
local legacy=ChalkBox_DropRead(777)
assert(legacy and legacy.quantity==0 and
    legacy.legacy.quantity==5 and legacy.reference==1.5 and
    not legacy.rate,"migration preserves legacy data separately, never inventing new area odds")
print("PASS: automatic all-item loot, zone/dungeon split, same-source windows, mixed-loot safety, dedup and legacy migration")
