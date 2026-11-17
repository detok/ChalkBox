-- Curated item IDs + explicitly documented quest facts; no external DB.
_G.UnitFactionGroup=function() return "Alliance" end
local active={}
local completed={}
local titles={}
_G.C_QuestLog={
    IsOnQuest=function(id) return active[id]==true end,
    IsQuestFlaggedCompleted=function(id) return completed[id]==true end,
    GetTitleForQuestID=function(id) return titles[id] end,
}
assert(loadfile("FutureQuestItems.lua"))()
local hops=ChalkBox_FutureQuestUses("1274")
assert(hops and #hops==1 and hops[1].questID==117
    and hops[1].required==5 and hops[1].questName=="Thunderbrew"
    and hops[1].evidence=="Reference",
    "Hops item 1274 -> five for Thunderbrew, as a reference not live evidence")
assert(ChalkBox_FutureQuestUses(729)[1].questID==38,
    "ordinary trade goods can be flagged for a future quest")
local eye=ChalkBox_FutureQuestUses(730)
assert(eye and #eye==2 and eye[1].questID==38
    and eye[2].questID==92110,
    "Alliance Murloc Eye retains both the Classic and Forever custom uses")
UnitFactionGroup=function() return "Horde" end
eye=ChalkBox_FutureQuestUses(730)
assert(eye and #eye==1 and eye[1].questID==91920,
    "faction-incompatible quest references must not be shown")
UnitFactionGroup=function() return "Alliance" end
active[38]=true
assert(ChalkBox_FutureQuestUses(729)==nil,
    "an accepted quest's items are never future-quest items")
eye=ChalkBox_FutureQuestUses(730)
assert(eye and #eye==1 and eye[1].questID==92110,
    "other future uses remain even when one known quest is accepted")
active[38]=nil
completed[38]=true
assert(ChalkBox_FutureQuestUses(729)==nil,
    "finished nonrepeatable quests must not produce endless future warning")
completed[117]=true
assert(ChalkBox_FutureQuestUses(1274)~=nil,
    "repeatable Thunderbrew remains useful after completion")
completed[38]=nil
titles[38]="Westfall Stew (Forever)"
assert(ChalkBox_FutureQuestUses(729)[1].questName=="Westfall Stew (Forever)",
    "live quest title wins over reference data where available")
assert(ChalkBox_FutureQuestUses(12345678)==nil and
    ChalkBox_FutureQuestUses(0)==nil and
    ChalkBox_FutureQuestUses(-729)==nil and
    ChalkBox_FutureQuestUses("729abc")==nil,
    "no guessed uses, malformed links, or unrelated items")
assert(type(ChalkBox_FutureQuestUses(729)[1].required)=="number")
local first=ChalkBox_FutureQuestUses(729);first[1].questName="tamper"
assert(ChalkBox_FutureQuestUses(729)[1].questName=="Westfall Stew (Forever)",
    "reference result is detached; caller cannot mutate catalog")
print("PASS: curated original FutureQuestItems, Hops, multi-use, factions, completion, repeatability, live title, no guessed matches")
