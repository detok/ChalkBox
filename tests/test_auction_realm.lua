-- Realm key and Market tab identity. A blank normalized name must not
-- hide GetRealmName, and a saved market must stay readable.
local events={}
local frame={scripts={}}
function frame:RegisterEvent(name) events[name]=true end
function frame:SetScript(name,fn) self.scripts[name]=fn end
_G.CreateFrame=function() return frame end
_G.time=function() return 1800000000 end
_G.DEFAULT_CHAT_FRAME={AddMessage=function() end}
_G.GetNormalizedRealmName=function() return "" end
_G.GetRealmName=function() return "Whitemane" end
_G.UnitFactionGroup=function(unit)
    assert(unit=="player")
    return "Alliance"
end
assert(loadfile("AuctionSense.lua"))("ChalkBox")
local status=ChalkBox_AuctionStatus()
assert(status.realm=="Whitemane" and status.faction=="Alliance"
    and status.marketKey=="whitemane|alliance",
    "a blank normalized realm falls through to GetRealmName")
local shown=status.realm.." / "..status.faction
assert(shown=="Whitemane / Alliance",
    "the Market tab line is the realm and faction")
local ok,reason=ChalkBox_AuctionScan()
assert(not ok and reason~="Realm or faction unavailable",
    "scanning does not report the realm missing when GetRealmName works")
_G.GetNormalizedRealmName=function() return nil end
_G.GetRealmName=function() return nil end
_G.GetCVar=function() return "" end
_G.UnitFactionGroup=function() return nil end
ChalkBoxDB.auctionSense.markets["whitemane|alliance"]={
    realm="Whitemane",faction="Alliance",scannedAt=10,
    itemCount=2,items={},source="browse",
}
status=ChalkBox_AuctionStatus()
assert(status.marketKey=="whitemane|alliance" and status.realm=="Whitemane"
    and status.faction=="Alliance" and status.items==2,
    "the saved market is shown when the live realm API is empty")
shown=status.realm.." / "..status.faction
assert(shown=="Whitemane / Alliance" and shown~="Market unavailable",
    "the Market tab still writes the saved realm")
ok,reason=ChalkBox_AuctionScan()
assert(reason~="Realm or faction unavailable",
    "a saved market is not treated as a missing realm")
_G.GetNormalizedRealmName=function() return "Whitemane" end
_G.UnitFactionGroup=function() return "Alliance" end
status=ChalkBox_AuctionStatus()
assert(status.marketKey=="whitemane|alliance",
    "a normal realm and faction keep the original market key")
print("PASS: realm key falls through a blank normalized name and keeps the saved market on the Market tab")
