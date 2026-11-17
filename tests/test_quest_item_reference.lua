-- Standalone bundled MIT Classic item/quest reference (no WoW client).
-- Exact relationships and titles are preserved with the license.
local dataFile=assert(loadfile("Libs/ClassicQuestReference/Data.lua"))
dataFile()
assert(type(ChalkBoxClassicQuestReference)=="table")
local countItems,countQuests=0,0
for _ in pairs(ChalkBoxClassicQuestReference.items) do countItems=countItems+1 end
for _ in pairs(ChalkBoxClassicQuestReference.titles) do countQuests=countQuests+1 end
assert(countItems>2000 and countQuests>2000,
    "bundled standalone reference contains thousands of real IDs, not a stub")
local inLog,completed=false,false
_G.C_QuestLog={
    IsOnQuest=function() return inLog end,
    IsQuestFlaggedCompleted=function() return completed end,
    GetTitleForQuestID=function() return nil end,
}
assert(loadfile("QuestItemReference.lua"))()
local results,n=ChalkBox_QuestReferenceCandidates(182)
assert(n==1 and #results==1 and
    results[1].id==6 and results[1].relation=="required"
    and results[1].title=="Bounty on Garrick Padfoot"
    and results[1].provenance=="Classic reference",
    "item 182 resolves to the real quest title and exact item objective")
local gnoll=ChalkBox_QuestReferenceCandidates(782)
assert(gnoll and gnoll[1].title=="Riverpaw Gnoll Bounty")
assert(ChalkBox_QuestReferenceCandidates(6497)==nil,
    "obsolete source test quests must never become tooltip advice")
local starter=ChalkBox_QuestReferenceCandidates(1307)
assert(starter and starter[1].relation=="starts"
    and starter[1].id==123,
    "quest starter items must not be mistaken for collected objective items")
-- Current client quest text wins over older Classic reference text.
C_QuestLog.GetTitleForQuestID=function(id)
    if id==6 then return "Forever Updated Quest Title" end
end
inLog=true
local live=ChalkBox_QuestReferenceCandidates(182)
assert(live and live[1].title=="Forever Updated Quest Title"
    and live[1].onQuest==true,
    "live Forever quest title and accepted state supersede reference names")
inLog=false
completed=true
local done=ChalkBox_QuestReferenceCandidates(182)
assert(done and done[1].completed==true and done[1].onQuest==false,
    "completed status remains separate from current quest log membership")
assert(ChalkBox_QuestReferenceCandidates(0)==nil and
    ChalkBox_QuestReferenceCandidates(-15)==nil and
    ChalkBox_QuestReferenceCandidates("182")==nil,
    "invalid item IDs cannot resolve or create fabricated quest links")
local tooMany=ChalkBox_QuestReferenceCandidates(15407,3)
assert(tooMany and #tooMany<=3,
    "large shared-material reference sets are bounded on hover")
assert(type(CreateFrame)=="nil" and type(C_Timer)=="nil",
    "no frames, timers, Questie dependency or login-time indexing needed")
print("PASS: licensed embedded Classic quest reference, live-title priority, quest roles, completion state and bounded lookup")
