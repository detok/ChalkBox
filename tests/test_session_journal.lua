-- Persistent per-character session history plus an actual openable window.
_G.ChalkBoxZoneDB={}
local now,xp,money=1000,100,100000
_G.GetTime=function() return now end
_G.UnitXP=function() return xp end
_G.UnitXPMax=function() return 1000 end
_G.GetMoney=function() return money end
_G.UIParent={}
_G.ChalkBox_ThemeBackground=function() return 0.018,0.018,0.022,0 end
_G.ChalkBox_ThemeAccent=function() return 0.86,0.66,0.38 end
local windows={}
local event
_G.CreateFrame=function(kind,name,parent)
    local f={shown=false,children={},name=name,fonts={},textures={}}
    if name then windows[name]=f end
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
        local t={}
        function t:SetAllPoints() end
        function t:SetColorTexture(...) self.color={...} end
        function t:SetPoint(...) self.anchor={...} end
        function t:SetHeight(h) self.height=h end
        function t:SetSize(w,h) self.width=w;self.height=h end
        f.textures[#f.textures+1]=t
        return t
    end
    function f:CreateFontString()
        local t={}
        function t:SetPoint(...) self.anchor={...} end
        function t:SetWidth(w) self.width=w end
        function t:SetJustifyH(v) self.align=v end
        function t:SetText(value) self.value=value end
        f.fonts[#f.fonts+1]=t
        return t
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
local journal=windows["ChalkBoxSessionJournal"]
assert(journal and journal.outerBorderFallback and
    journal.bg.color[4]>=0.92,
    "older clients still get a framed, opaque journal at theme opacity zero")
assert(journal.panels and #journal.panels==2 and
    journal.panels[1].fill.color[4]>=0.9,
    "session totals and field notes have separate readable bronze insets")
assert(journal.panels[1].shadow.color[4]>0.6,
    "inset panels have depth behind existing text")
local titles={}
for _,font in ipairs(journal.fonts) do
    if font.value then titles[font.value]=true end
end
assert(titles["SESSION SUMMARY"] and titles["FIELD NOTES"] and
    titles["Only information ChalkBox actually observed is listed."],
    "journal display preserves every existing summary row and adds headings")
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
now=now+601
event(nil,"PLAYER_MONEY")
assert(ChalkBox_JournalGet(0).seconds>=601,
    "a quiet gap longer than 10 minutes still counts as session time")
local many={}
for i=1,16 do many[tostring(i)]=1 end
ChalkBox_JournalNoteLoot(16,many,"z:1","Elwynn")
ChalkBox_JournalNoteLoot(500,{["999"]=500},"z:1","Elwynn")
local drops=ChalkBox_JournalGet(0).topDrops
assert(drops["999"]==500 and drops["1"]==nil,
    "the sixteenth-highest drop is kept and a later larger drop replaces the smallest")
local kept={version=9,history={{label="keep",seconds=3}},note="keep"}
ChalkBoxZoneDB.sessionJournal=kept
event(nil,"PLAYER_LOGIN")
assert(ChalkBoxZoneDB.sessionJournal==kept and
    ChalkBoxZoneDB.sessionJournal.note=="keep",
    "an unfamiliar journal save is not replaced")
print("PASS: preserved session counters and history, readable framed Adventure Journal, inset sections and opacity-zero fallback")
