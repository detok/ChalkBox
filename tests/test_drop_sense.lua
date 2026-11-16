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
local px,py=0.426,0.714
local maps={
    [1436]={name="Westfall",mapType=3,parentMapID=13},
    [1437]={name="Redridge Mountains",mapType=3,parentMapID=13},
    [13]={name="Eastern Kingdoms",mapType=2,parentMapID=947},
    [105]={name="The Deadmines",mapType=4,parentMapID=1436}
}
_G.C_Map={
    GetBestMapForUnit=function() return mapID end,
    GetMapInfo=function(id) return maps[id] end,
    GetPlayerMapPosition=function(id,unit)
        assert(unit=="player" and id==mapID)
        return {GetXY=function() return px,py end}
    end
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
assert(detail.locations and #detail.locations==1 and
    detail.locations[1].x==426 and detail.locations[1].y==714 and
    detail.locations[1].count==1,
    "first outdoor loot records the player's observed zone position")
detail.locations[1].x=0
assert(ChalkBox_DropRead(100,"z:1436","c:12345").locations[1].x==426,
    "position readers receive a copy, not mutable SavedVariables")
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
now=110;px,py=0.9,0.9;handlers.event(nil,"LOOT_OPENED")
assert(ChalkBox_DropOptions().windows==1 and
    #ChalkBox_DropRead(100,"z:1436").locations==1,
    "same corpse reopening never double-counts or records a second point")
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
px,py=0.720,0.200
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
assert(ambiguousCloth.locations and #ambiguousCloth.locations==2 and
    ambiguousCloth.locations[2].x==720,
    "zone-wide browsing retains locations from both creature types")
local areaAudit=ChalkBox_DropAreaAudit("z:1436")
assert(areaAudit and areaAudit.items==3 and
    areaAudit.positionedItems==3 and areaAudit.positions>=3 and
    areaAudit.invalidPositions==0 and areaAudit.countProblems==0 and
    areaAudit.sourceProblems==0,
    "cross-checking saved item windows and coordinates detects no false errors")
assert(ChalkBox_DropAreaAudit("z:1437")==nil,
    "a zone with no observations returns no fabricated audit")
local banditItems=ChalkBox_DropAreaItems("z:1436","c:12345")
local banditCloth
for _,item in ipairs(banditItems) do
    if item.id=="100" then banditCloth=item end
end
assert(banditCloth and banditCloth.rate==50 and
    banditCloth.hits==1 and banditCloth.attempts==2,
    "specific creature filter reports exactly its own tracked 1/2 = 50%")
handlers.event(nil,"LOOT_CLOSED")
now=550
px,py=0.730,0.210
overrideSources={
    "Creature-0-1-22-333-12345-00002D",
    "Creature-0-1-22-333-99999-00002E"}
links={"|Hitem:100:0|h[Linen Cloth]|h",
    "|Hitem:400:0|h[Armor Scraps]|h"}
handlers.event(nil,"LOOT_OPENED")
assert(ChalkBox_DropRead(100,"z:1436","c:12345").attempts==2,
    "mixed-source windows are counted as zone discoveries but not mob rolls")
assert(ChalkBox_DropRead(400).quantity==1)
local mixedSpot=ChalkBox_DropRead(100,"z:1436").locations
assert(#mixedSpot==2 and mixedSpot[2].count==2 and
    #ChalkBox_DropRead(100,"z:1436","c:12345").locations==1,
    "nearby mixed-source loot clusters on the zone but cannot pollute a mob")
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
assert(not ChalkBox_DropRead(500,discovered.dungeons[1].key).locations,
    "dungeons keep their area history but never invent outdoor coordinates")
handlers.event(nil,"LOOT_CLOSED")
now=800;instance=false;mapID=1437
handlers.event(nil,"ZONE_CHANGED_NEW_AREA")
assert(ChalkBox_DropMapData(1437).zone==nil,
    "unvisited outdoor zone does not borrow Westfall's loot")
assert(ChalkBox_DropCalculate(5,10)>40 and
    ChalkBox_DropCalculate(5,10)<41 and
    ChalkBox_DropCalculate(0,10)==0 and
    ChalkBox_DropCalculate(100,1)==100)
local captured,colors={},{}
local button={GetName=function() return "LootButton1" end}
local tooltip={
    GetOwner=function() return button end,
    AddLine=function(_,line,r,g,b)
        captured[#captured+1]=line
        colors[#colors+1]={r,g,b}
    end,
    Show=function() end}
-- Last drop was in dungeon; global count remains valid without claiming a
-- percentage for current unrelated loot source.
assert(ChalkBox_DropTooltip(tooltip,"item:500"))
assert(captured[1]==" " and captured[2]=="Drop Journal"
    and captured[3] and captured[3]:find("found",1,true)
    and colors[3] and colors[3][3]>colors[3][1]
    and colors[3][3]>colors[3][2],
    "personal loot quantity is visibly blue, separated from item text")
assert(table.concat(captured," "):find("not official odds",1,true),
    "short loot tooltip labels still identify personal rather than official data")
-- The native tooltip must not receive the same journal twice on refresh.
tooltip.GetName=function() return "DropSenseTestTooltip" end
tooltip.NumLines=function() return #captured end
for index,line in ipairs(captured) do
    _G["DropSenseTestTooltipTextLeft"..index]={
        GetText=function() return line end}
end
local originalCount=#captured
assert(not ChalkBox_DropTooltip(tooltip,"item:500")
    and #captured==originalCount,
    "same loot-window tooltip is annotated only once")
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
-- Bounded retention: 8 distant new sightings retain only the latest 6.
ChalkBox_DropSetOption("enabled",true)
mapID=1436
handlers.event(nil,"ZONE_CHANGED_NEW_AREA")
for i=1,8 do
    handlers.event(nil,"LOOT_CLOSED")
    now=1000+i*130
    px,py=i*0.09,0.10
    guid=("Creature-0-1-22-333-12345-%06X"):format(300+i)
    links={"|Hitem:100:0|h[Linen Cloth]|h"}
    handlers.event(nil,"LOOT_OPENED")
end
local mostRecent=ChalkBox_DropRead(100,"z:1436").locations
assert(#mostRecent==6 and mostRecent[1].x==270 and
    mostRecent[6].x==720,
    "positions stay rounded and bounded to six distinct recent sites")
assert(#ChalkBox_DropRead(100,"z:1436","c:12345").locations==6,
    "verified creature-specific samples are bounded independently")
-- API unavailable: a new real loot window still counts, but gets no point.
handlers.event(nil,"LOOT_CLOSED")
C_Map.GetPlayerMapPosition=nil
now=2200
guid="Creature-0-1-22-333-12345-000DDD"
links={"|Hitem:999:0|h[Unknown Spot]|h"}
handlers.event(nil,"LOOT_OPENED")
assert(ChalkBox_DropRead(999,"z:1436").areaWindows==1 and
    not ChalkBox_DropRead(999,"z:1436").locations,
    "missing coordinate API never invents or blocks ordinary discovery")
areaAudit=ChalkBox_DropAreaAudit("z:1436")
assert(areaAudit and areaAudit.missingPositions>=1 and
    areaAudit.invalidPositions==0,
    "recorded loot can correctly lack locations without being corrupt")
-- Some client builds return the invalid zero/zero map sentinel.
handlers.event(nil,"LOOT_CLOSED")
C_Map.GetPlayerMapPosition=function()
    return {GetXY=function() return 0,0 end}
end
now=2360
guid="Creature-0-1-22-333-12345-000EEE"
links={"|Hitem:998:0|h[Unknown Map Origin]|h"}
handlers.event(nil,"LOOT_OPENED")
assert(ChalkBox_DropRead(998,"z:1436").areaWindows==1 and
    not ChalkBox_DropRead(998,"z:1436").locations,
    "zero-zero client placeholder cannot become a claimed loot location")
local badArea=ChalkBoxZoneDB.dropSense.areas["z:1436"]
local source=badArea.sources["c:12345"]
local oldWindows=source.items["100"].windows
source.items["100"].windows=source.windows+1
local corrupted=ChalkBox_DropAreaAudit("z:1436")
assert(corrupted.sourceProblems>0 and
    ChalkBox_DropRead(100,"z:1436","c:12345").rate==nil,
    "impossible hits greater than sample windows never produce NaN rates")
source.items["100"].windows=oldWindows
local oldLocations=badArea.items["100"].locations
badArea.items["100"].locations={{x=1500,y=500,count=1}}
corrupted=ChalkBox_DropAreaAudit("z:1436")
assert(corrupted.invalidPositions==1,
    "out-of-bounds positions are counted as malformed, never projected")
badArea.items["100"].locations=oldLocations
ChalkBox_DropSetOption("enabled",false)
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
print("PASS: automatic all-item loot, bounded outdoor coordinates, safe source attribution, dungeons/API fallback, zone/dungeon split, mixed-loot safety, dedup and legacy migration")
