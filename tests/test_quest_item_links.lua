-- Optional QuestieDB reverse item-to-quest index. No WoW client required.
local frames={}
_G.CreateFrame=function()
    local f={shown=false,scripts={},events={}}
    function f:Hide() self.shown=false end
    function f:Show() self.shown=true end
    function f:SetScript(name,fn) self.scripts[name]=fn end
    function f:RegisterEvent(event) self.events[event]=true end
    frames[#frames+1]=f
    return f
end
local combat=false
_G.InCombatLockdown=function() return combat end
local quests={
    [1]={name="Relics of the Past",objectives={[3]={{106,1,4}}}},
    [2]={name="Another Relic Quest",requiredSourceItems={106}},
    [3]={name="The Relic Begins",startedBy={[3]={200}}},
    [4]={name="Take This Map",sourceItemId=201},
    [5]={name="Use The Medallion",objectives={[6]={{55,"Use",202}}}},
    [888]={name="A Connected Quest"},
    [909]={name="A Starting Quest"},
}
local itemFields={
    [106]={relatedQuests={888}},
    [200]={startQuest=909},
}
_G.LibQuestieDB={
    Quest={
        GetAllIds=function() return {1,2,3,4,5} end,
        Get=function(id,key)
            return quests[id] and quests[id][key]
        end,
    },
    Item={
        Get=function(id,key)
            return itemFields[id] and itemFields[id][key]
        end,
    },
}
_G.C_QuestLog={
    IsOnQuest=function(id) return id==1 end,
    IsQuestFlaggedCompleted=function(id) return id==2 end,
}
assert(loadfile("QuestItemLinks.lua"))("ChalkBox")
local worker,events=frames[1],frames[2]
local status=ChalkBox_QuestItemDatabaseStatus()
assert(status=="not started")
events.scripts.OnEvent(events,"PLAYER_LOGIN")
assert(worker.shown and ChalkBox_QuestItemDatabaseStatus()=="indexing")
combat=true
worker.scripts.OnUpdate(worker,0.1)
assert(ChalkBox_QuestItemDatabaseStatus()=="indexing",
    "index should pause during combat")
combat=false
for i=1,5 do
    worker.scripts.OnUpdate(worker,0.1)
end
local state,processed=ChalkBox_QuestItemDatabaseStatus()
assert(state=="ready" and processed==5 and not worker.shown,
    "indexed exactly the known quest IDs without a per-hover database scan")
local found=ChalkBox_QuestItemDatabaseLinks(106)
assert(type(found)=="table" and #found==3
    and found[1].title=="Relics of the Past" and
    found[1].role=="objective" and found[1].active==true
    and found[2].title=="Another Relic Quest" and
    found[2].role=="required" and found[2].complete==true
    and found[3].role=="related" and found[3].title=="A Connected Quest",
    "reverse index identifies specific quests and keeps relationships distinct")
assert(ChalkBox_QuestItemDatabaseLinks(200)[1].role=="starts" and
    ChalkBox_QuestItemDatabaseLinks(200)[1].title=="The Relic Begins",
    "quest-starting item relation is not misclassified as required item")
local related=ChalkBox_QuestItemDatabaseLinks(200)
assert(#related==2 and related[2].title=="A Starting Quest",
    "direct Item.startQuest is combined with reverse startedBy evidence")
assert(ChalkBox_QuestItemDatabaseLinks(201)[1].role=="provided",
    "quest-provided items are not wrongly called required")
assert(ChalkBox_QuestItemDatabaseLinks(202)[1].role=="used",
    "spell use item metadata is handled separately from collection")
assert(#ChalkBox_QuestItemDatabaseLinks(999)==0 and
    ChalkBox_QuestItemDatabaseLinks(0)==nil,
    "no random quest is invented for unknown item IDs or invalid zero IDs")
-- Direct item fields should work before the full quest index completes.
local fresh={11}
LibQuestieDB.Quest.GetAllIds=function() return fresh end
-- The initialized index is intentionally stable: never run a new
-- synchronous full-database scan on tooltip hover.
local before=processed
ChalkBox_QuestItemDatabaseLinks(106)
assert(select(2,ChalkBox_QuestItemDatabaseStatus())==before)
print("PASS: optional QuestieDB reverse item-to-quest evidence, active/completed state, role priority, protected combat and safe unknown IDs")
