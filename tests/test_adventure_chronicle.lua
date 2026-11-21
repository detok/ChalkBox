-- Chronicle records new milestones only and never rewrites session summaries.
local now=1700000000
_G.time=function() return now end
_G.date=function(fmt) return "01-01 12:00" end
_G.issecretvalue=function() return false end
_G.GetZoneText=function() return "Elwynn Forest" end
_G.UnitLevel=function() return 10 end
_G.ChalkBoxZoneDB={sessionJournal={version=1,history={{label="old",seconds=5}},
    current={label="now",seconds=1}}}
local events={}
local frame={scripts={}}
function frame:RegisterEvent(name) events[name]=true end
function frame:SetScript(name,fn) self.scripts[name]=fn end
_G.CreateFrame=function() return frame end
assert(loadfile("AdventureChronicle.lua"))("ChalkBox")
assert(events.PLAYER_LEVEL_UP and events.QUEST_TURNED_IN and events.PLAYER_DEAD)
local function Fire(name,arg)
    frame.scripts.OnEvent(frame,name,arg)
end
Fire("PLAYER_LEVEL_UP",12)
Fire("PLAYER_LEVEL_UP",12)
Fire("QUEST_TURNED_IN",100)
Fire("QUEST_TURNED_IN",100)
now=now+120
Fire("QUEST_TURNED_IN",100)
Fire("PLAYER_DEAD")
local snap=ChalkBox_ChronicleEvents("timeline",20)
assert(snap.count==4,"level once, quest twice across time, and one death")
assert(ChalkBoxZoneDB.sessionJournal.history[1].label=="old" and
    ChalkBoxZoneDB.sessionJournal.current.seconds==1,
    "old session journal records are not rewritten")
assert(ChalkBox_ChronicleSetEnabled(false))
Fire("PLAYER_LEVEL_UP",13)
assert(ChalkBox_ChronicleEvents().count==4,"recording off adds nothing and deletes nothing")
assert(ChalkBox_ChronicleSetEnabled(true))
local rare=false
_G.GetItemInfo=function(id)
    if id==12345 then return "Boar",nil,3 end
end
assert(ChalkBox_ChronicleNoteLoot({["12345"]=2,["5"]=99})==true)
assert(not ChalkBox_ChronicleNoteLoot({["5"]=99}),
    "common or unknown rarity is not called a notable drop")
assert(ChalkBox_ChronicleClear())
assert(ChalkBox_ChronicleEvents().count==0)
ChalkBoxZoneDB.adventureChronicle={version=4,events={{kind="level",label="keep"}},note="keep"}
Fire("PLAYER_LEVEL_UP",20)
assert(ChalkBoxZoneDB.adventureChronicle.note=="keep" and
    #ChalkBoxZoneDB.adventureChronicle.events==1,
    "an unfamiliar chronicle save is left alone")
print("PASS: chronicle records new milestones, dedupes, and preserves old history")
