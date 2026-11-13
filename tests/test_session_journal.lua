-- Persistent per-character session history plus an actual openable window.
_G.ChalkBoxZoneDB={}
local now,xp,money=1000,100,100000
_G.GetTime=function() return now end
_G.UnitXP=function() return xp end
_G.UnitXPMax=function() return 1000 end
_G.GetMoney=function() return money end
_G.UIParent={}
local event
_G.CreateFrame=function(kind,name,parent)
    local f={shown=false,children={},name=name}
    function f:RegisterEvent() end
    function f:SetScript(what,fn)
        self[what]=fn
        if what=="OnEvent" then event=fn end
    end
    function f:SetSize() end
    function f:SetPoint() end
    function f:SetFrameStrata() end
    function f:SetMovable() end
    function f:EnableMouse() end
    function f:RegisterForDrag() end
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:IsShown() return self.shown end
    function f:CreateTexture()
        return {SetAllPoints=function() end,SetColorTexture=function() end,
            SetPoint=function() end,SetHeight=function() end}
    end
    function f:CreateFontString()
        return {SetPoint=function() end,SetWidth=function() end,
            SetJustifyH=function() end,SetText=function(self,t) self.value=t end}
    end
    function f:SetText(t) self.caption=t end
    return f
end
assert(loadfile("SessionJournal.lua"))("ChalkBox")
event(nil,"PLAYER_LOGIN")
assert(ChalkBox_JournalStatus().current and
    ChalkBox_JournalStatus().history==0)
now=1060;xp=175;money=117250
event(nil,"PLAYER_XP_UPDATE")
event(nil,"PLAYER_MONEY")
event(nil,"QUEST_TURNED_IN")
ChalkBox_JournalNoteLoot(4,{["100"]=2,["300"]=2},"z:1436","Westfall")
ChalkBox_JournalNoteCamp()
ChalkBox_JournalNoteRepair(1700)
local cur=ChalkBox_JournalGet(0)
assert(cur.xp==75 and cur.goldNet==17250 and cur.quests==1 and
    cur.lootWindows==1 and cur.lootItems==4 and
    cur.campPrompts==1 and cur.repairQuotes==1,
    "only directly observed session facts enter the record")
assert(cur.areas["z:1436"] and cur.areas["z:1436"].windows==1,
    "zone observation is retained as a compact per-session location")
assert(ChalkBox_OpenSessionJournal("current"),
    "a native-styled standalone session window can be opened")
now=1150;event(nil,"PLAYER_LOGOUT")
assert(ChalkBox_JournalStatus().history==1 and
    ChalkBox_JournalGet(1).xp==75 and
    ChalkBox_JournalGet(1).seconds>=60)
event(nil,"PLAYER_LOGIN")
assert(ChalkBox_JournalStatus().history==1 and
    ChalkBox_JournalGet(1).lootItems==4 and
    ChalkBox_JournalGet(0).xp==0,
    "new login preserves previous session and starts a fresh summary")
assert(ChalkBox_JournalGet(1).areas["z:1436"].windows==1,
    "saved session retains observed outdoor loot regions")
assert(ChalkBox_OpenSessionJournal("last"),
    "past sessions can be opened without the game combat log")
print("PASS: persistent adventure sessions, XP/money/quests/loot/camp/repair facts and openable native recap")
