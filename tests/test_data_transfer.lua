-- Source-aware, repeatable file transfer between two WoW computers.
local nextRand=0
math.random=function(low,high)
    nextRand=nextRand+1
    return 100000+nextRand
end
_G.GetTime=function() return 12 end
_G.time=function() return 1770000000 end
_G.UnitName=function() return "Hunter" end
_G.GetNormalizedRealmName=function() return "Whitemaine" end
_G.C_AddOns={IsAddOnLoaded=function(name)
    assert(name=="ChalkBoxTransfer");return true
end}
local function Sale(sig,at)
    return {sig=sig,ordinal=1,expiryBucket=2700,at=at,
        name="Linen Cloth",count=1,gross=500,deposit=10,
        cut=25,proceeds=485}
end
local function Market(at,low)
    return {realm="Whitemaine",faction="Alliance",scannedAt=at,
        source="browse",itemCount=1,items={
            [2589]={name="Linen Cloth",low=low,
                history={{t=at,low=low}}}}}
end
local function Drops(windows)
    return {version=2,enabled=true,tooltip=true,mapButton=true,
        windows=windows,observedItems=windows*2,legacyWindows=0,
        items={["2589"]={id="2589",name="Linen Cloth",
            windows=windows,quantity=windows*2}},
        areas={["z:1"]={
            kind="outdoor",name="Duskwood",mapID=1,
            windows=windows,items={["2589"]={
                windows=windows,quantity=windows*2,
                locations={{x=432,y=555,count=windows}}}},
            sources={["c:10"]={
                name="Worgen",windows=windows,items={["2589"]={
                    windows=windows,quantity=windows*2}}}}}}}
end
local function Account(at,low,receipts)
    return {auctionSense={version=1,markets={
        ["whitemaine|alliance"]=Market(at,low)},
        order={"whitemaine|alliance"},nextAllowed=999},
        auctionInsights={version=1,characters={
            ["whitemaine|alliance|hunter"]={sales=receipts}}}}
end
local function Char(windows,node)
    return {dropSense=Drops(windows),
        discoveriesKnownFlights={version=1,enabled=true,revision=1,
            nodes={[node]={name="Flight",x=500,y=500}}}}
end
assert(loadfile("DataTransfer.lua"))("ChalkBox")
-- Machine A: two observed loot windows and two verified sales.
_G.ChalkBoxDB=Account(1770000100,80,{Sale("a",10),Sale("b",20)})
_G.ChalkBoxZoneDB=Char(2,12)
assert(ChalkBox_TransferExport())
local a=ChalkBoxTransferDB
assert(a.kind=="ChalkBoxData" and a.version==1 and
    a.drops.windows==2 and type(a.dropParts)=="table" and
    a.auction.markets["whitemaine|alliance"].scannedAt==1770000100)
local aChar=ChalkBoxZoneDB
local aAccount=ChalkBoxDB
-- Machine B already observed three other windows independently. It has a
-- newer asking price and a seller invoice already present on machine A.
_G.ChalkBoxDB=Account(1770000200,75,{Sale("b",20),Sale("c",30)})
_G.ChalkBoxZoneDB=Char(3,13)
_G.ChalkBoxTransferDB=a
local ok,summary=ChalkBox_TransferImport()
assert(ok and summary:find("discoveries merged",1,true))
local d=ChalkBoxZoneDB.dropSense
assert(d.windows==5 and d.observedItems==10 and
    d.items["2589"].quantity==10 and
    d.areas["z:1"].sources["c:10"].windows==5,
    "independent computers must sum genuinely distinct loot windows")
assert(ChalkBoxDB.auctionSense.markets["whitemaine|alliance"].scannedAt==1770000200,
    "newer market snapshot wins")
local history=ChalkBoxDB.auctionSense.markets[
    "whitemaine|alliance"].items[2589].history
assert(#history==2 and history[1].t==1770000100 and history[2].t==1770000200,
    "distinct price scans retained in chronological order")
assert(#ChalkBoxDB.auctionInsights.characters[
    "whitemaine|alliance|hunter"].sales==3,
    "seller invoice merge deduplicates by invoice identity")
assert(ChalkBoxZoneDB.discoveriesKnownFlights.nodes[12] and
    ChalkBoxZoneDB.discoveriesKnownFlights.nodes[13],
    "flight discoveries merged rather than replaced")
assert(ChalkBox_TransferImport())
assert(ChalkBoxZoneDB.dropSense.windows==5 and
    #ChalkBoxDB.auctionInsights.characters[
        "whitemaine|alliance|hunter"].sales==3,
    "importing same file twice must NOT double count")
-- Simulate a real new DropSense capture on B. The main module updates its
-- visible aggregate and the transfer engine records the independent delta.
ChalkBox_TransferPrepareDrop()
d.windows=d.windows+1;d.observedItems=d.observedItems+2
d.items["2589"].windows=d.items["2589"].windows+1
d.items["2589"].quantity=d.items["2589"].quantity+2
d.areas["z:1"].windows=d.areas["z:1"].windows+1
d.areas["z:1"].items["2589"].windows=
    d.areas["z:1"].items["2589"].windows+1
d.areas["z:1"].items["2589"].quantity=
    d.areas["z:1"].items["2589"].quantity+2
d.areas["z:1"].sources["c:10"].windows=
    d.areas["z:1"].sources["c:10"].windows+1
d.areas["z:1"].sources["c:10"].items["2589"].windows=
    d.areas["z:1"].sources["c:10"].items["2589"].windows+1
d.areas["z:1"].sources["c:10"].items["2589"].quantity=
    d.areas["z:1"].sources["c:10"].items["2589"].quantity+2
ChalkBox_TransferRecordDrop({["2589"]=2},2,"z:1","c:10")
assert(ChalkBox_TransferExport())
local b=ChalkBoxTransferDB
assert(b.drops.windows==6)
-- Return to original machine A. Its original baseline should not be
-- recounted: only B's three historic windows plus one fresh window are added.
_G.ChalkBoxDB=aAccount
_G.ChalkBoxZoneDB=aChar
_G.ChalkBoxTransferDB=b
assert(ChalkBox_TransferImport())
assert(ChalkBoxZoneDB.dropSense.windows==6 and
    ChalkBoxZoneDB.dropSense.items["2589"].quantity==12,
    "roundtrip preserves original baseline and adds only B's independent events")
assert(ChalkBox_TransferImport())
assert(ChalkBoxZoneDB.dropSense.windows==6,
    "roundtrip file remains idempotent")
assert(#ChalkBoxDB.auctionInsights.characters[
    "whitemaine|alliance|hunter"].sales==3)
-- Another character may import shared market and seller history, but must
-- not merge this hunter's character-local drops or flight discoveries.
_G.ChalkBoxZoneDB=Char(1,99)
_G.UnitName=function() return "Different" end
assert(ChalkBox_TransferImport())
assert(ChalkBoxZoneDB.dropSense.windows==1 and
    not ChalkBoxZoneDB.discoveriesKnownFlights.nodes[12],
    "per-character discoveries never silently combine different characters")
_G.ChalkBoxTransferDB={kind="ChalkBoxData",version=1}
local before=ChalkBoxZoneDB.dropSense.windows
assert(not ChalkBox_TransferImport() and
    ChalkBoxZoneDB.dropSense.windows==before,
    "invalid export cannot overwrite the receiver")
print("PASS: file-only scoped export, newer market scans, exact invoice dedupe, "
    .."independent DropSense counts, replay-safe two-PC roundtrip, flight union, character isolation")
