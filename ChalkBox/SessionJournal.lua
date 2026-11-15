-- ChalkBox Session Journal: compact, personal, persistent run history.
-- Event-derived facts only. No combat log analysis, estimated kills, syncing
-- or extra installations. Saved per character, last 20 finished sessions.
local addonName=...
local MAX_HISTORY=20
-- Same native World Map art and dialog frame used by Discoveries.
local MAP_ATLAS="gamepad-mapquestlog-bgtile-2k"
local PANEL_FILL={0.112,0.086,0.062,0.91}
local function Color(value)
    return (type(issecretvalue)~="function" or
        not issecretvalue(value)) and type(value)=="number" and
        value==value and value>=0 and value<=1
end
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
        areas={},
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
function ChalkBox_JournalNoteLoot(quantity,items,areaKey,areaName)
    if not current then return end
    if Num(quantity) then current.lootItems=(current.lootItems or 0)+quantity end
    current.lootWindows=(current.lootWindows or 0)+1
    if type(areaKey)=="string" and #areaKey<=75 and
        type(areaName)=="string" and #areaName<=96 then
        current.areas=current.areas or {}
        if current.areas[areaKey] or
            (function() local n=0;for _ in pairs(current.areas) do n=n+1 end
                return n<24 end)() then
            local entry=current.areas[areaKey]
            if not entry then entry={name=areaName,windows=0};
                current.areas[areaKey]=entry end
            entry.windows=math.min(1e7,(entry.windows or 0)+1)
        end
    end
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
local function AreasLine(entry)
    local order={}
    for _,v in pairs(entry.areas or {}) do
        if type(v)=="table" and type(v.name)=="string" then
            order[#order+1]={name=v.name,n=v.windows or 0}
        end
    end
    table.sort(order,function(a,b)
        if a.n==b.n then return a.name<b.name end
        return a.n>b.n
    end)
    local parts={}
    for i=1,math.min(3,#order) do
        parts[#parts+1]=order[i].name.." ("..order[i].n..")"
    end
    return #parts>0 and table.concat(parts," · ") or "No mapped loot observed"
end
local function ReadPalette()
    local r,g,b,a=0.018,0.018,0.022,0.96
    if type(ChalkBox_ThemeBackground)=="function" then
        local ok,red,green,blue,alpha=pcall(
            ChalkBox_ThemeBackground,0.96)
        if ok and Color(red) and Color(green) and
            Color(blue) and Color(alpha) then
            r,g,b,a=red,green,blue,alpha
        end
    end
    local ar,ag,ab=0.86,0.66,0.38
    if type(ChalkBox_ThemeAccent)=="function" then
        local ok,red,green,blue=pcall(ChalkBox_ThemeAccent)
        if ok and Color(red) and Color(green) and Color(blue) then
            ar,ag,ab=red,green,blue
        end
    end
    return r,g,b,math.max(0.92,a),ar,ag,ab
end
-- Some Forever builds fail to display SetColorTexture alone on the map
-- windows. A native white texture with vertex tint is more reliable.
local function Paint(texture,r,g,b,a)
    if not texture then return end
    if type(texture.SetTexture)=="function" and
        type(texture.SetVertexColor)=="function" then
        texture:SetTexture("Interface\\Buttons\\WHITE8X8")
        texture:SetVertexColor(r,g,b,a)
    elseif type(texture.SetColorTexture)=="function" then
        texture:SetColorTexture(r,g,b,a)
    end
end
local function Background()
    if not window then return end
    local r,g,b,a,ar,ag,ab=ReadPalette()
    local woodR,woodG,woodB=0.16+r*0.20,0.092+g*0.12,
        0.048+b*0.06
    Paint(window.bg,window.hasMapArt and woodR or r,
        window.hasMapArt and woodG or g,
        window.hasMapArt and woodB or b,
        window.hasMapArt and 0.30 or a)
    if type(window.SetBackdropColor)=="function" then
        window:SetBackdropColor(window.hasMapArt and woodR or r,
            window.hasMapArt and woodG or g,
            window.hasMapArt and woodB or b,
            window.hasMapArt and 0.12 or a)
    end
    if type(window.SetBackdropBorderColor)=="function" then
        window:SetBackdropBorderColor(ar,ag,ab,1)
    end
    Paint(window.stripe,ar,ag,ab,1)
    if window.panels then
        for _,p in ipairs(window.panels) do
            Paint(p.fill,PANEL_FILL[1],PANEL_FILL[2],PANEL_FILL[3],
                PANEL_FILL[4])
        end
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
        "Loot regions: "..AreasLine(entry),
        "Only information ChalkBox actually observed is listed.",
    }
    for i,font in ipairs(textRows) do font:SetText(details[i] or "") end
end
function ChalkBox_OpenSessionJournal(which)
    if not window then
        if not UIParent or type(CreateFrame)~="function" then return false end
        local template=type(BackdropTemplateMixin)=="table" and
            "BackdropTemplate" or nil
        local f=CreateFrame("Frame","ChalkBoxSessionJournal",UIParent,template)
        f:SetSize(590,460)
        -- The session window is independent and movable, but should have
        -- the same polished native dialog frame as Discoveries.
        if type(f.SetBackdrop)=="function" then
            f:SetBackdrop({
                bgFile="Interface\\Buttons\\WHITE8X8",
                edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
                tile=true,tileSize=32,edgeSize=24,
                insets={left=8,right=8,top=8,bottom=8},
            })
        else
            f.outerBorderFallback=true
            -- Four restrained bronze edges for older Forever builds.
            local function OuterLine(x,y,w,h)
                local t=f:CreateTexture(nil,"OVERLAY")
                t:SetPoint("TOPLEFT",f,"TOPLEFT",x,y)
                t:SetSize(w,h)
                Paint(t,0.63,0.44,0.22,0.95)
            end
            OuterLine(1,-1,588,2)
            OuterLine(1,-457,588,2)
            OuterLine(1,-2,2,456)
            OuterLine(587,-2,2,456)
        end
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
        -- Decorative native map-derived wood. No modifications to
        -- WorldMapFrame, protected game controls, or Blizzard Settings.
        local art=f:CreateTexture(nil,"BACKGROUND",nil,0)
        art:SetPoint("TOPLEFT",f,"TOPLEFT",4,-4)
        art:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-4,4)
        f.mapArt=art
        local function LoadArt()
            if type(art.SetAtlas)~="function" then return false end
            local exists=C_Texture and C_Texture.GetAtlasExists
            if type(exists)=="function" then
                local ok,yes=pcall(exists,MAP_ATLAS)
                if ok and yes==false then return false end
            end
            local ok,result=pcall(art.SetAtlas,art,MAP_ATLAS,false)
            if not ok or result==false then return false end
            if type(art.GetAtlas)=="function" then
                local got,name=pcall(art.GetAtlas,art)
                if got and name~=nil and name~=MAP_ATLAS then
                    return false
                end
            end
            if type(art.SetHorizTile)=="function" then
                art:SetHorizTile(true)
            end
            if type(art.SetVertTile)=="function" then
                art:SetVertTile(true)
            end
            if type(art.SetVertexColor)=="function" then
                art:SetVertexColor(1,1,1,1)
            end
            if type(art.Show)=="function" then art:Show() end
            return true
        end
        f.hasMapArt=LoadArt()
        if not f.hasMapArt and type(art.Hide)=="function" then
            art:Hide()
        end
        f.RefreshMapArt=function()
            if not f.hasMapArt then
                f.hasMapArt=LoadArt()
                if not f.hasMapArt and
                    type(art.Hide)=="function" then art:Hide() end
            end
        end
        local bg=f:CreateTexture(nil,"BACKGROUND",nil,1)
        bg:SetPoint("TOPLEFT",f,"TOPLEFT",4,-4)
        bg:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-4,4)
        f.bg=bg
        local stripe=f:CreateTexture(nil,"ARTWORK")
        stripe:SetPoint("TOPLEFT",f,"TOPLEFT",13,-13)
        stripe:SetSize(563,2)
        f.stripe=stripe
        -- Two clearly separated reading sections, not a flat stats list.
        f.panels={}
        local function Inset(x,y,width,height)
            local shadow=f:CreateTexture(nil,"BORDER",nil,-3)
            shadow:SetPoint("TOPLEFT",f,"TOPLEFT",x+2,y-2)
            shadow:SetSize(width,height)
            Paint(shadow,0.008,0.006,0.005,0.70)
            local rim=f:CreateTexture(nil,"BORDER",nil,-2)
            rim:SetPoint("TOPLEFT",f,"TOPLEFT",x,y)
            rim:SetSize(width,height)
            Paint(rim,0.37,0.27,0.14,0.94)
            local fill=f:CreateTexture(nil,"BORDER",nil,-1)
            fill:SetPoint("TOPLEFT",f,"TOPLEFT",x+1,y-1)
            fill:SetSize(width-2,height-2)
            local bevel=f:CreateTexture(nil,"BORDER",nil,0)
            bevel:SetPoint("TOPLEFT",f,"TOPLEFT",x+2,y-2)
            bevel:SetSize(width-4,1)
            Paint(bevel,0.69,0.49,0.23,0.33)
            f.panels[#f.panels+1]={fill=fill,rim=rim,
                shadow=shadow,bevel=bevel}
        end
        Inset(14,-79,562,151)
        Inset(14,-235,562,175)
        local function Font(size,x,y,width)
            local t=f:CreateFontString(nil,"OVERLAY",size)
            t:SetPoint("TOPLEFT",f,"TOPLEFT",x,y)
            t:SetWidth(width);t:SetJustifyH("LEFT")
            return t
        end
        Font("GameFontNormalHuge",22,-20,535):SetText(
            "CHALKBOX  /  ADVENTURE JOURNAL")
        f.head=Font("GameFontHighlight",22,-56,530)
        Font("GameFontNormal",27,-87,520):SetText("SESSION SUMMARY")
        Font("GameFontNormal",27,-242,520):SetText("FIELD NOTES")
        -- Fixed rows fit inside their own inset borders; the historical
        -- session data and navigation behavior are intentionally unchanged.
        for i=1,12 do
            local y=i<=6 and (-109-(i-1)*20) or
                (-264-(i-7)*21)
            textRows[i]=Font("GameFontHighlight",27,y,533)
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
    if window.RefreshMapArt then window:RefreshMapArt() end
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
