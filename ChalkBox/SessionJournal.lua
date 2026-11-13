-- ChalkBox Session Journal: compact, personal, persistent run history.
-- Event-derived facts only. No combat log analysis, estimated kills, syncing
-- or extra installations. Saved per character, last 20 finished sessions.
local addonName=...
local MAX_HISTORY=20
local window,view= nil,0 -- 0=current; 1=most recent finished
local textRows={}
local current
local lastClock
local function Safe(v)
    return v~=nil and (type(issecretvalue)~="function" or
        not issecretvalue(v))
end
local function Num(v)
    return Safe(v) and type(v)=="number" and v==v and v>=0 and v<1e12
end
local function Clock()
    local t=type(GetTime)=="function" and GetTime() or nil
    return Num(t) and t or nil
end
local function NowLabel()
    if type(date)=="function" then
        local ok,value=pcall(date,"%Y-%m-%d %H:%M")
        if ok and type(value)=="string" then return value end
    end
    return "Game session"
end
local function DB()
    if type(ChalkBoxZoneDB)~="table" then ChalkBoxZoneDB={} end
    local s=ChalkBoxZoneDB.sessionJournal
    if type(s)~="table" or s.version~=1 then
        s={version=1,history={}}
        ChalkBoxZoneDB.sessionJournal=s
    end
    if type(s.history)~="table" then s.history={} end
    return s
end
local function NewSession()
    return {label=NowLabel(),seconds=0,xp=0,goldNet=0,levels=0,
        quests=0,lootWindows=0,lootItems=0,campPrompts=0,
        repairQuotes=0,repairLast=nil,startedMoney=nil,
        lastMoney=nil,lastXP=nil,lastMaxXP=nil,topDrops={}}
end
local function Advance()
    if not current then return end
    local now=Clock()
    if lastClock and now and now>=lastClock and now-lastClock<600 then
        current.seconds=(current.seconds or 0)+(now-lastClock)
    end
    lastClock=now
end
local function ReadXP()
    if not current or type(UnitXP)~="function" or
        type(UnitXPMax)~="function" then return end
    local ok,value=pcall(UnitXP,"player")
    local okm,maximum=pcall(UnitXPMax,"player")
    if not ok or not okm or not Num(value) or not Num(maximum) or
        maximum<=0 then return end
    if Num(current.lastXP) and Num(current.lastMaxXP) then
        local change
        if value>=current.lastXP and maximum==current.lastMaxXP then
            change=value-current.lastXP
        elseif value<current.lastXP and current.lastMaxXP>0 then
            -- Level rollover is counted conservatively, once.
            change=current.lastMaxXP-current.lastXP+value
        end
        if change and change>=0 and change<1e7 then
            current.xp=(current.xp or 0)+change
        end
    end
    current.lastXP=value;current.lastMaxXP=maximum
end
local function ReadGold()
    if not current or type(GetMoney)~="function" then return end
    local ok,amount=pcall(GetMoney)
    if not ok or not Num(amount) then return end
    if current.startedMoney==nil then current.startedMoney=amount end
    current.lastMoney=amount
    current.goldNet=amount-current.startedMoney
end
local function Finish()
    if not current then return end
    Advance()
    local s=DB()
    current.lastXP=nil;current.lastMaxXP=nil
    current.finished=NowLabel()
    s.history[#s.history+1]=current
    while #s.history>MAX_HISTORY do table.remove(s.history,1) end
    s.current=nil
    current=nil
    lastClock=nil
end
local function Begin()
    local s=DB()
    if current then return end
    if type(s.current)=="table" then
        -- A prior session survived a forced quit without PLAYER_LOGOUT.
        s.current.finished="Recovered from last login"
        s.history[#s.history+1]=s.current
        while #s.history>MAX_HISTORY do table.remove(s.history,1) end
    end
    current=NewSession()
    s.current=current
    lastClock=Clock()
    ReadXP();ReadGold()
end
function ChalkBox_JournalNoteLoot(quantity,items)
    if not current then return end
    if Num(quantity) then current.lootItems=(current.lootItems or 0)+quantity end
    current.lootWindows=(current.lootWindows or 0)+1
    if type(items)=="table" then
        for id,count in pairs(items) do
            if type(id)=="string" and id:match("^%d+$") and
                Num(count) and count>0 then
                local key=id:sub(1,10)
                current.topDrops[key]=(current.topDrops[key] or 0)+count
                -- Hard cap on unique item labels to avoid bloating SavedVariables.
                local keys=0
                for _ in pairs(current.topDrops) do keys=keys+1 end
                if keys>16 then current.topDrops[key]=nil end
            end
        end
    end
end
function ChalkBox_JournalNoteCamp()
    if current then current.campPrompts=(current.campPrompts or 0)+1 end
end
function ChalkBox_JournalNoteRepair(amount)
    if current and Num(amount) then
        current.repairQuotes=(current.repairQuotes or 0)+1
        current.repairLast=amount
    end
end
function ChalkBox_JournalGet(index)
    local s=DB()
    if index==nil or index==0 then return current or s.current end
    index=tonumber(index)
    if not Num(index) or index<1 or index%1~=0 then return end
    return s.history[#s.history-index+1]
end
function ChalkBox_JournalStatus()
    local s=DB()
    return {history=#s.history,current=current~=nil}
end
local function Money(copper)
    if not Num(math.abs(copper or 0)) then return "--" end
    local sign=copper<0 and "-" or "+"
    local v=math.floor(math.abs(copper))
    return ("%s%dg %02ds %02dc"):format(sign,math.floor(v/10000),
        math.floor((v%10000)/100),v%100)
end
local function Duration(seconds)
    seconds=Num(seconds) and math.floor(seconds) or 0
    return ("%dh %02dm"):format(math.floor(seconds/3600),
        math.floor(seconds%3600/60))
end
local function TopDrops(s)
    local entries={}
    for id,count in pairs(s.topDrops or {}) do
        if Num(count) then entries[#entries+1]={id=id,count=count} end
    end
    table.sort(entries,function(a,b)
        if a.count==b.count then return a.id<b.id end
        return a.count>b.count
    end)
    local result={}
    for i=1,math.min(#entries,4) do
        result[#result+1]="#"..entries[i].id.." x"..entries[i].count
    end
    return #result>0 and table.concat(result,"    ") or "No item drops recorded"
end
local function Background()
    if not window then return end
    local r,g,b,a=0.018,0.018,0.022,0.96
    if type(ChalkBox_ThemeBackground)=="function" then
        r,g,b,a=ChalkBox_ThemeBackground(0.96)
    end
    if window.bg then window.bg:SetColorTexture(r,g,b,a) end
    if window.stripe then
        if type(ChalkBox_ThemeAccent)=="function" then
            local x,y,z=ChalkBox_ThemeAccent()
            window.stripe:SetColorTexture(x,y,z,1)
        else window.stripe:SetColorTexture(0.86,0.66,0.38,1) end
    end
end
function ChalkBox_JournalThemeRefresh() Background() end
local function Render()
    if not window then return end
    Advance()
    local entry=ChalkBox_JournalGet(view)
    if not entry then
        view=0
        entry=ChalkBox_JournalGet(0)
    end
    if not entry then return end
    window.head:SetText(view==0 and "CURRENT SESSION" or
        ("SAVED SESSION  "..view.." / "..ChalkBox_JournalStatus().history))
    local details={
        "Started     "..(entry.label or "Unknown"),
        "Adventuring     "..Duration(entry.seconds),
        "XP gained     "..tostring(entry.xp or 0)..
            "    |    Levels gained "..tostring(entry.levels or 0),
        "Net gold     "..Money(entry.goldNet or 0),
        "Quests completed     "..tostring(entry.quests or 0),
        "Loot windows sampled     "..tostring(entry.lootWindows or 0)..
            "    |    Items observed "..tostring(entry.lootItems or 0),
        "Camping reminders     "..tostring(entry.campPrompts or 0),
        "Repair merchant quotes observed     "..tostring(entry.repairQuotes or 0),
        "Last repair quote     "..(entry.repairLast and
            Money(entry.repairLast) or "Not observed"),
        "Most observed items: "..TopDrops(entry),
        "Only information ChalkBox actually observed is listed.",
    }
    for i,font in ipairs(textRows) do font:SetText(details[i] or "") end
end
function ChalkBox_OpenSessionJournal(which)
    if not window then
        if not UIParent or type(CreateFrame)~="function" then return false end
        local f=CreateFrame("Frame","ChalkBoxSessionJournal",UIParent)
        f:SetSize(590,430)
        f:SetPoint("CENTER",UIParent,"CENTER",0,0)
        if f.SetFrameStrata then f:SetFrameStrata("DIALOG") end
        if f.SetMovable then f:SetMovable(true) end
        if f.EnableMouse then f:EnableMouse(true) end
        if f.RegisterForDrag then f:RegisterForDrag("LeftButton") end
        f:SetScript("OnDragStart",function(self)
            if self.StartMoving and (type(InCombatLockdown)~="function"
                or not InCombatLockdown()) then self:StartMoving() end
        end)
        f:SetScript("OnDragStop",function(self)
            if self.StopMovingOrSizing then self:StopMovingOrSizing() end
        end)
        local bg=f:CreateTexture(nil,"BACKGROUND")
        bg:SetAllPoints(f);f.bg=bg
        local stripe=f:CreateTexture(nil,"ARTWORK")
        stripe:SetPoint("TOPLEFT",f,"TOPLEFT",0,0)
        stripe:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0)
        stripe:SetHeight(3);f.stripe=stripe
        local function Font(size,x,y,width)
            local t=f:CreateFontString(nil,"OVERLAY",size)
            t:SetPoint("TOPLEFT",f,"TOPLEFT",x,y)
            t:SetWidth(width);t:SetJustifyH("LEFT")
            return t
        end
        Font("GameFontNormalHuge",22,-17,500):SetText("CHALKBOX  /  ADVENTURE JOURNAL")
        f.head=Font("GameFontNormal",22,-61,500)
        for i=1,11 do
            textRows[i]=Font("GameFontHighlight",26,-91-(i-1)*26,540)
        end
        local function Button(label,x,fn)
            local button=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
            button:SetSize(122,26)
            button:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",x,15)
            button:SetText(label)
            button:SetScript("OnClick",fn)
        end
        Button("Current",22,function() view=0;Render() end)
        Button("Older",155,function()
            view=math.min(view+1,ChalkBox_JournalStatus().history);Render()
        end)
        Button("Newer",288,function()
            view=math.max(0,view-1);Render()
        end)
        Button("Close",444,function() f:Hide() end)
        window=f
    end
    if not current then Begin() end
    if which=="last" then
        view=ChalkBox_JournalStatus().history>0 and 1 or 0
    elseif which=="current" then view=0 end
    Background()
    Render()
    window:Show()
    return true
end
local event=CreateFrame("Frame")
for _,name in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD",
    "PLAYER_XP_UPDATE","PLAYER_MONEY","PLAYER_LEVEL_UP",
    "QUEST_TURNED_IN","PLAYER_LOGOUT"}) do event:RegisterEvent(name) end
event:SetScript("OnEvent",function(_,name)
    if name=="PLAYER_LOGIN" then
        Begin()
    elseif name=="PLAYER_LOGOUT" then
        Finish()
    else
        if not current then Begin() end
        Advance()
        if name=="PLAYER_LEVEL_UP" then
            current.levels=(current.levels or 0)+1
        elseif name=="QUEST_TURNED_IN" then
            current.quests=(current.quests or 0)+1 end
        if name=="PLAYER_XP_UPDATE" or name=="PLAYER_LEVEL_UP" then
            ReadXP()
        elseif name=="PLAYER_MONEY" then ReadGold() end
        if window and window.IsShown and window:IsShown() then Render() end
    end
end)
