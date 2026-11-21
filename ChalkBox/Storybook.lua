-- Read-only storybook. Pulls short summaries from the other modules
-- only while the window is open. It never writes their saved data.
local PAGES={
    {key="overview",label="Overview",icon="Interface\\Icons\\INV_Misc_Book_09"},
    {key="timeline",label="Timeline",icon="Interface\\Icons\\INV_Misc_PocketWatch_01"},
    {key="milestones",label="Milestones",icon="Interface\\Icons\\Spell_Holy_MindVision"},
    {key="records",label="Records",icon="Interface\\Icons\\INV_Misc_Gem_Pearl_01"},
}
local window,lines,page,cache,elapsed
local function Secret(v)
    return type(issecretvalue)=="function" and issecretvalue(v)
end
local function Call(fn,...)
    if type(fn)~="function" then return end
    local ok,a,b=pcall(fn,...)
    if ok and not Secret(a) then return a,b end
end
local function Text(v)
    if Secret(v) or type(v)~="string" or v=="" then return nil end
    return v:gsub("[%c|]",""):sub(1,96)
end
local function Num(v)
    if Secret(v) or type(v)~="number" or v~=v then return nil end
    return v
end
local function Combat()
    if type(InCombatLockdown)~="function" then return false end
    local ok,locked=pcall(InCombatLockdown)
    return ok and locked==true
end
local function Place()
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    if type(ChalkBoxDB.storybook)~="table" then ChalkBoxDB.storybook={} end
    return ChalkBoxDB.storybook
end
local function Money(copper)
    copper=Num(copper)
    if not copper then return "not recorded" end
    copper=math.floor(copper)
    local sign=copper<0 and "-" or ""
    copper=math.abs(copper)
    return ("%s%dg %ds %dc"):format(sign,math.floor(copper/10000),
        math.floor(copper%10000/100),copper%100)
end
local function Hours(seconds)
    seconds=Num(seconds) or 0
    return ("%dh %02dm"):format(math.floor(seconds/3600),math.floor(seconds%3600/60))
end
local function Sessions()
    local status=Call(ChalkBox_JournalStatus) or {}
    local list={}
    local n=Num(status.history) or 0
    for i=1,math.min(n,20) do
        local row=Call(ChalkBox_JournalGet,i)
        if type(row)=="table" then list[#list+1]=row end
    end
    local current=Call(ChalkBox_JournalGet,0)
    return current,list
end
local function Overview()
    local lines={"A look back at what ChalkBox has actually seen."}
    local level=Call(UnitLevel,"player")
    if Num(level) then lines[#lines+1]="You are level "..math.floor(level).."." end
    local current=Sessions()
    if type(current)=="table" then
        lines[#lines+1]="This login: "..Hours(current.seconds)
            ..", "..tostring(Num(current.xp) or 0).." XP, gold "
            ..Money(current.goldNet).."."
        lines[#lines+1]="Quests turned in "..tostring(Num(current.quests) or 0)
            ..". Loot windows "..tostring(Num(current.lootWindows) or 0).."."
    else
        lines[#lines+1]="No session summary yet."
    end
    local quests=Call(ChalkBox_QuestStatus)
    if type(quests)=="table" then
        lines[#lines+1]="QuestSense is "..(quests.enabled==false and "off" or
            (quests.mode or "on"))..", watching "
            ..tostring(Num(quests.tracked) or 0).." in "
            ..(Text(quests.zone) or "an unknown place").."."
    end
    local drops=Call(ChalkBox_DropOptions)
    if type(drops)=="table" then
        lines[#lines+1]="Discoveries remember "..tostring(Num(drops.windows) or 0)
            .." loot windows, "..tostring(Num(drops.items) or 0)
            .." items, "..tostring(Num(drops.areas) or 0).." places."
    end
    local prof,recipes=Call(ChalkBox_ProfessionSummary)
    if Text(prof) then
        lines[#lines+1]="Professions: "..prof
            ..(Num(recipes) and (" ("..math.floor(recipes).." learned recipes).") or ".")
    end
    local auction=Call(ChalkBox_AuctionStatus)
    if type(auction)=="table" then
        lines[#lines+1]="Auction asks on file: "..tostring(Num(auction.items) or 0)
            .." items"..(Text(auction.realm) and (" on "..auction.realm) or "").."."
    end
    local bank=Call(ChalkBox_BankValueStatus)
    if type(bank)=="table" and Num(bank.vendorCopper) then
        lines[#lines+1]="Bank last seen at vendor value "..Money(bank.vendorCopper).."."
    else
        lines[#lines+1]="The bank has not been opened on this character yet."
    end
    local meter=Call(ChalkBox_PersonalMeterStatus)
    if type(meter)=="table" and Num(meter.damage) and meter.damage>0 then
        lines[#lines+1]="This login's own damage, including your pet: "
            ..math.floor(meter.damage).."."
    else
        lines[#lines+1]="No personal combat total yet this login."
    end
    local camp=Call(ChalkBox_CampStatus)
    if type(camp)=="table" and Text(camp.summary) then
        lines[#lines+1]="Camp: "..camp.summary
    end
    return lines
end
local function Timeline()
    local out={"Newest moments first. Nothing here was invented for old sessions."}
    local snap=Call(ChalkBox_ChronicleEvents,"timeline",12)
    local events=type(snap)=="table" and snap.events or {}
    if #events==0 then
        out[#out+1]="The chronicle has no events yet. Recording starts from this update."
    end
    for _,event in ipairs(events) do
        if type(event)=="table" then
            out[#out+1]=(Text(event.label) or Text(event.kind) or "Moment")
                ..(Text(event.zone) and (" · "..event.zone) or "")
        end
    end
    local _,history=Sessions()
    if #history>0 then
        out[#out+1]="Earlier session summaries, without a made-up timeline:"
        for i=1,math.min(3,#history) do
            local row=history[i]
            out[#out+1]=(Text(row.label) or "Session").." · "
                ..tostring(Num(row.xp) or 0).." XP · "..Money(row.goldNet)
        end
    end
    return out
end
local function Milestones()
    local out={"Levels, quests, and rare drops the chronicle actually stored."}
    local snap=Call(ChalkBox_ChronicleEvents,"timeline",40)
    local events=type(snap)=="table" and snap.events or {}
    local shown=0
    for _,event in ipairs(events) do
        if type(event)=="table" and (event.kind=="level" or event.kind=="quest"
            or event.kind=="loot" or event.kind=="dungeon") then
            out[#out+1]=Text(event.label) or event.kind
            shown=shown+1
        end
    end
    if shown==0 then
        out[#out+1]="No milestones yet. Turn in a quest or gain a level to begin."
    end
    return out
end
local function Records()
    local current,history=Sessions()
    local bestXP,bestLoot,bestTime=0,0,0
    local function Consider(row)
        if type(row)~="table" then return end
        bestXP=math.max(bestXP,Num(row.xp) or 0)
        bestLoot=math.max(bestLoot,Num(row.lootItems) or 0)
        bestTime=math.max(bestTime,Num(row.seconds) or 0)
    end
    Consider(current)
    for _,row in ipairs(history) do Consider(row) end
    return {
        "Personal bests from saved session summaries.",
        "Most experience in one session: "..math.floor(bestXP).." XP.",
        "Most items seen in one session: "..math.floor(bestLoot)..".",
        "Longest session on record: "..Hours(bestTime)..".",
        "These are your own records. They are not server rankings.",
    }
end
local function Gather(which)
    if Combat() and cache then
        local copy={}
        for i,line in ipairs(cache) do copy[i]=line end
        copy[#copy+1]="Combat is under way. This page will refresh after."
        return copy
    end
    local built
    if which=="timeline" then built=Timeline()
    elseif which=="milestones" then built=Milestones()
    elseif which=="records" then built=Records()
    else built=Overview() end
    cache=built
    return built
end
local function Paint()
    if not window then return end
    local body=Gather(page or "overview")
    for i,row in ipairs(lines) do
        row:SetText(body[i] or "")
    end
end
local function SavePlace()
    if not window or Combat() then return end
    local box=Place()
    local w,h=window:GetWidth(),window:GetHeight()
    if Num(w) and Num(h) then
        box.w=math.max(480,math.min(900,math.floor(w+0.5)))
        box.h=math.max(320,math.min(700,math.floor(h+0.5)))
    end
    if window.GetCenter and UIParent and UIParent.GetCenter then
        local x,y=window:GetCenter()
        local ux,uy=UIParent:GetCenter()
        if Num(x) and Num(y) and Num(ux) and Num(uy) then
            box.x,box.y=math.floor(x-ux),math.floor(y-uy)
        end
    end
end
function ChalkBox_OpenStorybook(which)
    if which=="timeline" or which=="milestones" or which=="records"
        or which=="overview" then
        page=which
    end
    page=page or "overview"
    if not UIParent or type(CreateFrame)~="function" then return false end
    if not window then
        local template=type(BackdropTemplateMixin)=="table" and "BackdropTemplate" or nil
        window=CreateFrame("Frame","ChalkBoxStorybook",UIParent,template)
        if not window or type(window.SetSize)~="function" then
            window=nil
            return false
        end
        local box=Place()
        window:SetSize(Num(box.w) or 640,Num(box.h) or 440)
        window:SetPoint("CENTER",UIParent,"CENTER",Num(box.x) or 0,Num(box.y) or 20)
        window:SetFrameStrata("MEDIUM")
        if window.SetMovable then window:SetMovable(true) end
        if window.SetResizable then window:SetResizable(true) end
        if window.SetResizeBounds then
            window:SetResizeBounds(480,320,900,700)
        elseif window.SetMinResize then
            window:SetMinResize(480,320)
            window:SetMaxResize(900,700)
        end
        if window.EnableMouse then window:EnableMouse(true) end
        if window.RegisterForDrag then window:RegisterForDrag("LeftButton") end
        if type(window.SetBackdrop)=="function" then
            window:SetBackdrop({
                bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
                tile=true,tileSize=32,edgeSize=32,
                insets={left=11,right=12,top=12,bottom=11},
            })
            if window.SetBackdropColor then window:SetBackdropColor(0.12,0.09,0.06,1) end
        else
            local bg=window:CreateTexture(nil,"BACKGROUND")
            bg:SetAllPoints(window)
            if bg.SetColorTexture then bg:SetColorTexture(0.12,0.09,0.06,0.96) end
        end
        local title=window:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
        title:SetPoint("TOP",window,"TOP",0,-16)
        title:SetText("ChalkBox")
        local subtitle=window:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        subtitle:SetPoint("TOP",title,"BOTTOM",0,-2)
        subtitle:SetText("A record of your adventure")
        window:SetScript("OnDragStart",function(self)
            if not Combat() and self.StartMoving then self:StartMoving() end
        end)
        window:SetScript("OnDragStop",function(self)
            if self.StopMovingOrSizing then self:StopMovingOrSizing() end
            SavePlace()
        end)
        for i,tab in ipairs(PAGES) do
            local button=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
            button:SetSize(110,22)
            button:SetPoint("TOPLEFT",window,"TOPLEFT",18+(i-1)*118,-48)
            button:SetText(tab.label)
            if button.SetNormalTexture then
                pcall(button.SetNormalTexture,button,tab.icon)
            end
            button:SetScript("OnClick",function()
                page=tab.key
                Paint()
            end)
        end
        lines={}
        for i=1,14 do
            local row=window:CreateFontString(nil,"OVERLAY","GameFontHighlight")
            row:SetPoint("TOPLEFT",window,"TOPLEFT",24,-84-(i-1)*20)
            row:SetPoint("RIGHT",window,"RIGHT",-24,0)
            row:SetJustifyH("LEFT")
            if row.SetWordWrap then row:SetWordWrap(true) end
            lines[i]=row
        end
        local grip=CreateFrame("Button",nil,window)
        grip:SetSize(18,18)
        grip:SetPoint("BOTTOMRIGHT",window,"BOTTOMRIGHT",-8,8)
        grip:SetScript("OnMouseDown",function(_,button)
            if button=="LeftButton" and not Combat() and window.StartSizing then
                window:StartSizing("BOTTOMRIGHT")
            end
        end)
        grip:SetScript("OnMouseUp",function()
            if window.StopMovingOrSizing then window:StopMovingOrSizing() end
            SavePlace()
            if window.SetSize and Num(Place().w) and Num(Place().h) then
                window:SetSize(Place().w,Place().h)
            end
        end)
        window:SetScript("OnUpdate",function(_,delta)
            if not window:IsShown() then elapsed=0 return end
            elapsed=(elapsed or 0)+(type(delta)=="number" and delta or 0)
            if elapsed<2 then return end
            elapsed=0
            Paint()
        end)
    end
    Paint()
    window:Show()
    return true
end
function ChalkBox_StorybookStatus()
    local box=type(ChalkBoxDB)=="table" and ChalkBoxDB.storybook or nil
    return {open=window and window.IsShown and window:IsShown() or false,
        page=page or "overview",
        width=box and box.w,height=box and box.h}
end
