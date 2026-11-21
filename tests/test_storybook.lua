-- The storybook only reads module summaries and only while it is open.
local frames={}
local function Widget()
    local w={points={},shown=true,text=""}
    function w:SetSize(a,b) self.w,self.h=a,b end
    function w:GetWidth() return self.w or 640 end
    function w:GetHeight() return self.h or 440 end
    function w:SetPoint(...) self.points[#self.points+1]={...} end
    function w:SetAllPoints() end
    function w:SetFrameStrata() end
    function w:SetMovable() end
    function w:SetResizable() end
    function w:SetResizeBounds() end
    function w:EnableMouse() end
    function w:RegisterForDrag() end
    function w:SetText(v) self.text=v end
    function w:SetJustifyH() end
    function w:SetWordWrap() end
    function w:SetWidth() end
    function w:Show() self.shown=true end
    function w:Hide() self.shown=false end
    function w:IsShown() return self.shown end
    function w:StartMoving() self.moving=true end
    function w:StartSizing() self.sizing=true end
    function w:StopMovingOrSizing() self.moving=false;self.sizing=false end
    function w:GetCenter() return 500,400 end
    function w:SetScript(name,fn) self[name]=fn end
    function w:CreateFontString()
        local f=Widget()
        self.fonts=self.fonts or {}
        self.fonts[#self.fonts+1]=f
        return f
    end
    function w:CreateTexture()
        return {SetAllPoints=function() end,SetColorTexture=function() end}
    end
    frames[#frames+1]=w
    return w
end
_G.CreateFrame=function(kind,name,parent,template)
    local w=Widget()
    w.kind,w.name,w.parent,w.template=kind,name,parent,template
    if template=="UIPanelButtonTemplate" then w.button=true end
    return w
end
_G.UIParent={GetCenter=function() return 400,300 end}
_G.UnitLevel=function() return 25 end
_G.InCombatLockdown=function() return false end
_G.ChalkBoxDB={}
_G.ChalkBoxZoneDB={sessionJournal={version=1,marker="untouched",history={}}}
_G.ChalkBox_JournalStatus=function() return {history=1,current=true} end
_G.ChalkBox_JournalGet=function(index)
    if index==0 then return {seconds=120,xp=40,goldNet=5000,quests=1,lootWindows=2} end
    return {label="Yesterday",xp=90,goldNet=-200,seconds=400,lootItems=3}
end
_G.ChalkBox_ChronicleEvents=function()
    return {events={{kind="level",label="Reached level 25",zone="Elwynn"}}}
end
_G.ChalkBox_DropOptions=function() return {windows=4,items=7,areas=2} end
_G.ChalkBox_QuestStatus=function()
    return {enabled=true,mode="smart",tracked=3,zone="Elwynn Forest"}
end
_G.ChalkBox_ProfessionSummary=function() return "Leatherworking",2 end
_G.ChalkBox_AuctionStatus=function() return {items=12,realm="Whitemane"} end
_G.ChalkBox_BankValueStatus=function() return {vendorCopper=250000} end
_G.ChalkBox_PersonalMeterStatus=function() return {damage=1000} end
_G.ChalkBox_CampStatus=function() return {summary="Rested and fed"} end
assert(loadfile("Storybook.lua"))("ChalkBox")
assert(ChalkBox_OpenStorybook())
local book
for _,f in ipairs(frames) do if f.name=="ChalkBoxStorybook" then book=f end end
assert(book and book.shown,"the storybook opens its own window")
local blob=""
for _,font in ipairs(book.fonts) do blob=blob..(font.text or "").."\n" end
assert(blob:find("level 25",1,true) and blob:find("Discoveries",1,true)
    and blob:find("Leatherworking",1,true) and blob:find("25g",1,true),
    "the overview reads every module without requiring all of them")
assert(ChalkBoxZoneDB.sessionJournal.marker=="untouched",
    "opening the storybook does not rewrite saved module data")
book:Hide()
_G.InCombatLockdown=function() return true end
_G.UnitLevel=function() return 99 end
book:Show()
book.OnUpdate(book,3)
blob=""
for _,font in ipairs(book.fonts) do blob=blob..(font.text or "").."\n" end
assert(blob:find("Combat is under way",1,true) and not blob:find("level 99",1,true),
    "an open storybook does not rebuild during combat")
_G.InCombatLockdown=function() return false end
ChalkBox_OpenStorybook("records")
blob=""
for _,font in ipairs(book.fonts) do blob=blob..(font.text or "").."\n" end
assert(blob:find("Most experience",1,true),
    "records are personal bests from session summaries")
book.OnDragStop(book)
assert(type(ChalkBoxDB.storybook.x)=="number" and type(ChalkBoxDB.storybook.w)=="number",
    "the window remembers where the player put it")
print("PASS: storybook is read-only, skips work in combat, and keeps its place")
