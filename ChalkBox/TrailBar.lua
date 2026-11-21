-- ChalkBox TrailBar: self-owned, combat-safe screen-edge overlay.
-- A single native, low-profile information strip. No pop-up windows.
-- Uses non-secret, ordinary player XP, money and elapsed online time only.

local addonName = ...
local db
local bar
local widgets = {}
local latest = {} -- shared with hover color roles and live stat refresh
local ticker
local Refresh -- forward declaration: mode controls update TrailBar immediately
local session = {
    started = nil, level = nil, xp = nil, maxXP = nil,
    xpGained = 0, goldStart = nil, money = nil
}

local function Public(value)
    return value ~= nil and (type(issecretvalue) ~= "function" or not issecretvalue(value))
end

local function ReadXP()
    if type(UnitLevel) ~= "function" or type(UnitXP) ~= "function"
        or type(UnitXPMax) ~= "function" then return end
    local level, xp, maxXP = UnitLevel("player"), UnitXP("player"), UnitXPMax("player")
    if not Public(level) or not Public(xp) or not Public(maxXP)
        or type(level) ~= "number" or type(xp) ~= "number"
        or type(maxXP) ~= "number" or xp < 0 or maxXP < 0 then return end
    return level, xp, maxXP
end

local function ReadMoney()
    if type(GetMoney) ~= "function" then return end
    local value = GetMoney()
    if Public(value) and type(value) == "number" and value >= 0 then return value end
end

local function ReadElapsed()
    if not session.started then return 0 end
    local now = type(GetTime) == "function" and GetTime() or session.started
    if not Public(now) or type(now) ~= "number" then return 0 end
    return math.max(0, now - session.started)
end

local function CaptureXP()
    local level, xp, maxXP = ReadXP()
    if not level then return end
    if session.level then
        local delta = 0
        if level == session.level and xp >= session.xp then
            delta = xp - session.xp
        elseif level == session.level + 1 and session.maxXP and session.maxXP > 0 then
            delta = math.max(0, session.maxXP - session.xp) + xp
        end
        -- Unexpected level jumps/XP drops reset the baseline, never create fake gains.
        if delta > 0 then session.xpGained = session.xpGained + delta end
    end
    session.level, session.xp, session.maxXP = level, xp, maxXP
end

local function CaptureMoney()
    local value = ReadMoney()
    if value then
        if not session.goldStart then session.goldStart = value end
        session.money = value
    end
end

local function ResetSession()
    session.started = type(GetTime) == "function" and GetTime() or 0
    session.level, session.xp, session.maxXP = nil, nil, nil
    session.xpGained, session.goldStart, session.money = 0, nil, nil
    CaptureXP()
    CaptureMoney()
end

local function Number(value)
    if value >= 1000000 then return ("%.1fm"):format(value / 1000000) end
    if value >= 1000 then return ("%.1fk"):format(value / 1000) end
    return tostring(math.floor(value + 0.5))
end

local function Duration(seconds)
    if seconds == nil then return "--" end
    seconds = math.max(0, math.floor(seconds))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    if hours >= 24 then return ("%dd %dh"):format(math.floor(hours / 24), hours % 24) end
    if hours > 0 then return ("%dh %02dm"):format(hours, minutes) end
    if minutes > 0 then return ("%dm"):format(minutes) end
    return ("%ds"):format(seconds)
end

local function Money(copper, signed)
    if copper == nil then return "--" end
    local sign = ""
    if signed then sign = copper < 0 and "-" or "+" end
    copper = math.floor(math.abs(copper))
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local c = copper % 100
    if gold > 0 then return ("%s%dg %02ds"):format(sign, gold, silver) end
    if silver > 0 then return ("%s%ds %02dc"):format(sign, silver, c) end
    return ("%s%dc"):format(sign, c)
end

local function GetRates()
    local elapsed = ReadElapsed()
    if elapsed <= 0 then return 0, nil, 0, elapsed end
    local xpPerHour = session.xpGained * 3600 / elapsed
    local remaining = session.maxXP and session.xp and math.max(0, session.maxXP - session.xp)
    local eta = remaining and remaining > 0 and xpPerHour > 0 and remaining * 3600 / xpPerHour or nil
    local net = session.money and session.goldStart and (session.money - session.goldStart) or 0
    return xpPerHour, eta, net * 3600 / elapsed, elapsed
end

-- Bar icons are recognizable at a glance; tooltip colors convey meaning.
local function TipRole(key,line)
    if line=="Unavailable" or line=="No quote"
        or line:find("^Unknown") or line:find("unavailable") then
        return "muted"
    end
    if key=="repair" then
        if line:find("^Estimate") then return "warning" end
        if line=="No damage" then return "good" end
        return "value"
    elseif key=="gear" then
        local gear=latest and latest.gear
        if gear and type(gear.percent)=="number" and gear.percent<40 then
            return "danger"
        end
        if line:find("^Lowest") and gear and
            type(gear.worst)=="number" and gear.worst<40 then
            return "danger"
        end
        return "good"
    elseif key=="pet" then
        local pet=latest and latest.pet
        if pet and type(pet.percent)=="number" and pet.percent<40 then
            return "danger"
        end
        return "good"
    elseif key=="bags" then
        local bags=latest and latest.bags
        if bags and type(bags.free)=="number" and bags.free<=4 then
            return "warning"
        end
        return "count"
    elseif key=="gold" then
        if line:find("^Net: %-") or line:find("^Per hour: %-") then
            return "danger"
        end
        return "value"
    elseif key=="bagvalue" or key=="bankvalue" then
        return "value"
    elseif key=="rate" or key=="rested" then
        return "good"
    elseif key=="level" or key=="latency" or key=="eta" then
        return "count"
    end
    return "text"
end
local tipFallback={
    good={0.39,0.94,0.62},value={0.98,0.79,0.39},
    count={0.51,0.76,0.98},warning={0.98,0.66,0.33},
    danger={0.98,0.45,0.40},muted={0.65,0.70,0.73},
    text={0.85,0.87,0.88},
}
local function Hint(widget,label,details,key)
    widget:EnableMouse(true)
    widget:SetScript("OnEnter",function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self,db and db.bar=="bottom" and
            "ANCHOR_TOP" or "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        local tr,tg,tb=1,0.82,0.35
        if type(ChalkBox_TipColor)=="function" then
            tr,tg,tb=ChalkBox_TipColor("title")
        end
        GameTooltip:AddLine(label,tr,tg,tb)
        for _,line in ipairs(details()) do
            local role=TipRole(key,line)
            local c=tipFallback[role] or tipFallback.text
            local r,g,b=c[1],c[2],c[3]
            if type(ChalkBox_TipColor)=="function" then
                r,g,b=ChalkBox_TipColor(role)
            end
            -- Native two-column layout keeps the label quiet and the value
            -- vivid. Fallback preserves original text on older Forever UI.
            local name,value=line:match("^([^:]+):%s*(.+)$")
            if name and type(GameTooltip.AddDoubleLine)=="function" then
                GameTooltip:AddDoubleLine(name,value,0.69,0.76,0.82,r,g,b)
            else
                GameTooltip:AddLine(line,r,g,b,true)
            end
        end
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave",function()
        if GameTooltip then GameTooltip:Hide() end
    end)
end

-- Visible metrics are configurable, and the 18px bar automatically drops
-- lower-priority metrics at narrow widths. It NEVER overlaps or changes height.
local statDefaults={
    rate=true,eta=true,time=true,gold=true,
    bags=true,gear=true,rested=true,latency=true,pet=false,
    bagvalue=true, -- fresh installs match the reference Bar; saved choices win
    bankvalue=true, -- new builds show Bank -- even before the first visit
    repair=true, -- honest quote/estimate, not uncalibrated guesswork
}
local specs={
    level={width=98,group="left"},
    rate={width=104,group="left"},
    bags={width=90,group="left"},
    bagvalue={width=125,group="right"},
    bankvalue={width=132,group="right"},
    repair={width=116,group="right"},
    gear={width=82,group="left"},
    eta={width=128,group="center"},
    rested={width=92,group="center"},
    pet={width=81,group="center"},
    time={width=85,group="right"},
    latency={width=86,group="right"},
    gold={width=182,group="right"},
}
-- Native Blizzard textures, not new asset dependencies. Every module keeps
-- its existing width, spacing and notch-safe position.
local moduleIcons={
    level="Interface\\Icons\\INV_Misc_Book_07",
    rate="Interface\\Icons\\Spell_Holy_ArcaneIntellect",
    bags="Interface\\Icons\\INV_Misc_Bag_08",
    bagvalue="Interface\\Icons\\INV_Misc_Coin_01",
    bankvalue="Interface\\Icons\\INV_Misc_Coin_02",
    repair="Interface\\Icons\\INV_Hammer_09",
    gear="Interface\\Icons\\INV_Chest_Chain_05",
    eta="Interface\\Icons\\INV_Misc_PocketWatch_01",
    rested="Interface\\Icons\\Spell_Nature_Sleep",
    pet="Interface\\Icons\\Ability_Hunter_BeastCall",
    time="Interface\\Icons\\INV_Misc_PocketWatch_02",
    latency="Interface\\Icons\\Spell_Arcane_Blink",
    gold="Interface\\Icons\\INV_Misc_Coin_01",
}
local groups={
    left={"level","rate"},
    center={"time","eta","rested"},
    right={"bags","gear","repair","bagvalue","bankvalue","gold","latency","pet"},
}
local dropPriority={"latency","time","pet","eta","rate","rested","gear","bagvalue","bankvalue","bags","repair","gold"}
local displayed={}
local lastLayout=""
local NotchLayout -- native/manual notch geometry, defined with the bar placement
local editMode=false
local backgroundOpacity=70
local previewWidths={} -- preview only; persisted once a resize finishes
local function RoundedWidth(value)
    if type(value)~="number" or value~=value then return nil end
    return math.floor(math.max(60,math.min(280,value))/4+0.5)*4
end
local function ModuleWidth(key)
    if previewWidths[key] then return previewWidths[key] end
    local saved=type(ChalkBox_BarLayoutWidthGet)=="function"
        and ChalkBox_BarLayoutWidthGet(key) or nil
    return saved or specs[key].width
end
local function IconsShown()
    -- Off unless this character explicitly turned icons on. A missing
    -- saved value is not rewritten, so older layouts keep their widths.
    return db and db.barShowIcons==true
end
local function LayoutModuleIcon(widget)
    if not widget or not widget.text then return end
    local font=widget.text
    -- If a client cannot provide the two text anchors, don't paint an icon
    -- across the existing metric. The text-only presentation still works.
    local anchored=type(font.ClearAllPoints)=="function"
        and type(font.SetPoint)=="function"
    local show=IconsShown() and anchored and widget.icon~=nil
    if widget.icon then
        if show then widget.icon:Show() else widget.icon:Hide() end
    end
    if anchored then
        font:ClearAllPoints()
        font:SetPoint("LEFT",widget,"LEFT",show and 18 or 1,0)
        font:SetPoint("RIGHT",widget,"RIGHT",-2,0)
    elseif type(font.SetAllPoints)=="function" then
        font:SetAllPoints(widget)
    end
end
function ChalkBox_BarIconsGet() return IconsShown() end
function ChalkBox_BarIconsSet(value)
    if not db or type(value)~="boolean" then return false end
    db.barShowIcons=value
    for _,widget in pairs(widgets) do LayoutModuleIcon(widget) end
    return true
end
local function CursorInBar()
    if type(GetCursorPosition)~="function" or not bar then return nil end
    local x=GetCursorPosition()
    local scale=type(bar.GetEffectiveScale)=="function"
        and bar:GetEffectiveScale() or 1
    if not Public(x) or type(x)~="number" or
        not Public(scale) or type(scale)~="number" or scale<=0 then
        return nil
    end
    return x/scale
end
local function ApplyAppearance()
    if not db then return end
    local a=tonumber(db.barBackgroundOpacity)
    if not a then a=70 end
    a=math.max(0,math.min(100,math.floor(a+0.5)))
    db.barBackgroundOpacity=a
    backgroundOpacity=a
    if bar and bar.background and bar.background.SetColorTexture then
        -- Blizzard-style neutral near-black; alpha applies ONLY to the panel.
        local r,g,bg,alpha=0.018,0.018,0.022,a/100
        if type(ChalkBox_ThemeBackground)=="function" then
            r,g,bg,alpha=ChalkBox_ThemeBackground(a/100)
        end
        bar.background:SetColorTexture(r,g,bg,alpha)
        if bar.backgroundRight and bar.backgroundRight.SetColorTexture then
            bar.backgroundRight:SetColorTexture(r,g,bg,alpha)
        end
    end
end
function ChalkBox_BarThemeRefresh() ApplyAppearance() end
function ChalkBox_BarAppearanceGet()
    return db and db.barBackgroundOpacity or 70
end
function ChalkBox_BarAppearanceSet(value)
    if not db or type(value)~="number" or value~=value then return false end
    db.barBackgroundOpacity=math.max(0,math.min(100,math.floor(value+0.5)))
    ApplyAppearance()
    return true
end
local function EditDecorations()
    for _,widget in pairs(widgets) do
        if widget.editBackground then
            widget.editBackground:SetColorTexture(0.45,0.32,0.12,
                editMode and 0.55 or 0)
        end
        if widget.resizeGrip then
            if editMode then widget.resizeGrip:Show()
            else
                widget.resizeGrip.dragging=false
                widget.resizeGrip:Hide()
            end
        end
    end
end
function ChalkBox_BarEditStatus() return editMode end
function ChalkBox_BarEditSet(on)
    if on and type(InCombatLockdown)=="function" and InCombatLockdown() then
        return false
    end
    editMode=(on==true)
    if not editMode then
        for key in pairs(previewWidths) do previewWidths[key]=nil end
        lastLayout=""
    end
    EditDecorations()
    if Refresh then Refresh() end
    return true
end
function ChalkBox_BarBagValueModeGet()
    return db and db.barBagValueMode=="junk" and "junk" or "total"
end
function ChalkBox_BarBagValueModeSet(mode)
    if not db or (mode~="junk" and mode~="total") then return false end
    db.barBagValueMode=mode
    if Refresh then Refresh() end
    return true
end
function ChalkBox_BarBagValueModeToggle()
    return ChalkBox_BarBagValueModeSet(
        ChalkBox_BarBagValueModeGet()=="junk" and "total" or "junk")
end
-- A player-initiated shortcut to Blizzard's existing bag toggle. Never
-- reposition, replace or manipulate protected inventory item buttons here.
-- In edit mode, left-click is reserved for arranging Bar widgets.
function ChalkBox_BarToggleBags()
    if editMode or type(ToggleAllBags)~="function" then return false end
    if type(InCombatLockdown)=="function" then
        local ok,locked=pcall(InCombatLockdown)
        if not ok or not Public(locked) or locked then return false end
    end
    local ok,result=pcall(ToggleAllBags)
    return ok and result~=false
end
local function Coins(copper)
    if type(copper)~="number" then return "--" end
    copper=math.floor(math.max(0,copper))
    return ("%dg %ds %dc"):format(
        math.floor(copper/10000),math.floor(copper%10000/100),copper%100)
end
local function BagValueText(data)
    if not data then return "Value --" end
    local junk=ChalkBox_BarBagValueModeGet()=="junk"
    local value=junk and data.junkCopper or data.totalCopper
    local complete=junk and data.junkComplete or data.totalComplete
    return (junk and "Junk " or "Value ")..
        (complete and "" or ">=")..Money(value)
end

local function ConfigureStats()
    if not db then return end
    if type(db.barStats)~="table" then db.barStats={} end
    for key,enabled in pairs(statDefaults) do
        if type(db.barStats[key])~="boolean" then db.barStats[key]=enabled end
    end
    -- First Bank Value prerelease defaulted OFF, silently saving false for
    -- everyone. One-time onboarding exposes the promised "Bank --" even
    -- when no banker has been visited. Later user OFF remains persistent.
    if db.bankValueOnboardV2~=true then
        db.barStats.bankvalue=true
        db.bankValueOnboardV2=true
    end
end
local function StatEnabled(key)
    if key=="level" then return true end
    if not db then return statDefaults[key]~=false end
    local values=db.barStats
    if type(values)=="table" and type(values[key])=="boolean" then
        return values[key]
    end
    return statDefaults[key]==true
end
function ChalkBox_BarStatEnabled(key)
    return specs[key]~=nil and StatEnabled(key) or false
end

local function Reflow()
    if not bar then return end
    if type(ChalkBox_BarLayoutGet)=="function" then
        local saved=ChalkBox_BarLayoutGet()
        if type(saved)=="table" then groups=saved end
    end
    local width=bar:GetWidth()
    if not Public(width) or type(width)~="number" or width<=0 then return end
    local split=type(NotchLayout)=="function" and
        db and db.bar=="top" and db.barTopInset==nil and
        NotchLayout(width) or nil
    -- A manually selected gap supersedes a previous top-inset selection.
    if db and db.barNotchGap then
        split=type(NotchLayout)=="function" and db.bar=="top" and
            NotchLayout(width) or nil
    end
    local chosen={}
    for key in pairs(specs) do
        chosen[key]=StatEnabled(key) and (key=="level" or
            key=="rate" or key=="eta" or key=="time" or key=="gold" or
            key=="bankvalue" or latest[key]~=nil)
    end
    local function Measure(list)
        local total,count=0,0
        for _,key in ipairs(list) do
            if chosen[key] then
                total=total+ModuleWidth(key)+(count>0 and 7 or 0)
                count=count+1
            end
        end
        return total,count
    end
    local function Need()
        local l,lc=Measure(groups.left)
        local c,cc=Measure(groups.center)
        local r,rc=Measure(groups.right)
        return l+c+r+24+(lc>0 and cc>0 and 10 or 0)
            +(rc>0 and (lc>0 or cc>0) and 10 or 0),l,c,r
    end
    -- A notch divides only the CENTER group. Left/right groups continue to
    -- use their saved order, widths and text alignment unchanged.
    -- Find the most balanced center partition that fits both safe lanes.
    local function ChooseSplit()
        if not split then return nil end
        local leftWidth,leftCount=Measure(groups.left)
        local rightWidth,rightCount=Measure(groups.right)
        local center={}
        for _,key in ipairs(groups.center) do
            if chosen[key] then center[#center+1]=key end
        end
        local best,bestScore=nil,nil
        for pivot=0,#center do
            local first,second={},{}
            for i,key in ipairs(center) do
                local lane=i<=pivot and first or second
                lane[#lane+1]=key
            end
            local lw,lc=Measure(first)
            local rw,rc=Measure(second)
            local leftEnd=12+leftWidth+(leftCount>0 and lc>0 and 10 or 0)+lw
            local rightStart=width-12-rightWidth-
                (rightCount>0 and rc>0 and 10 or 0)-rw
            -- With two or more center modules, require one on EACH
            -- side before accepting the split; otherwise we'd stop
            -- dropping optional right-side stats too early and leave the
            -- entire center group stranded on the left.
            local balanced=#center<2 or (pivot>0 and pivot<#center)
            if balanced and leftEnd<=split.left and
                rightStart>=split.right then
                local leftRoom=math.max(1,split.left-12)
                local rightRoom=math.max(1,width-split.right-12)
                local balance=math.abs((leftEnd/leftRoom)-
                    ((width-rightStart)/rightRoom))
                local score=math.abs(pivot-#center/2)*2+balance
                if not bestScore or score<bestScore then
                    bestScore=score
                    best={first=first,second=second,
                        leftStart=12+leftWidth+
                            (leftCount>0 and lc>0 and 10 or 0),
                        rightStart=rightStart}
                end
            end
        end
        return best
    end
    local chosenSplit=ChooseSplit()
    local needed=Need()
    -- In split mode prioritize the center widgets over lower-priority
    -- right-edge metrics. Otherwise the original drop order could discard
    -- every center widget before leaving room beside the camera notch.
    local splitDropPriority={"latency","pet","bagvalue","repair",
        "bankvalue","gear","bags","rate","gold","time","rested","eta"}
    for _,key in ipairs(split and splitDropPriority or dropPriority) do
        if (split and chosenSplit) or (not split and needed<=width) then
            break
        end
        if chosen[key] then
            chosen[key]=false
            needed=Need()
            chosenSplit=ChooseSplit()
        end
    end
    if split and not chosenSplit then
        -- Only the level indicator is indispensable. If even that cannot
        -- occupy its lane, do not draw anything over the camera cutout.
        for key in pairs(chosen) do chosen[key]=key=="level" end
        chosenSplit=ChooseSplit()
        if not chosenSplit then chosen.level=false end
    elseif not split and needed>width then
        for key in pairs(chosen) do chosen[key]=(key=="level") end
    end
    local signature=math.floor(width+0.5)..":"..
        (split and ("split:"..split.left..":"..split.right) or "normal")..":"
    for _,group in ipairs({"left","center","right"}) do
        for _,key in ipairs(groups[group]) do
            if chosen[key] then
                signature=signature..key.."="..ModuleWidth(key)..","
            end
        end
    end
    if signature==lastLayout then return end
    lastLayout=signature
    displayed={}
    for key,widget in pairs(widgets) do
        if chosen[key] then
            widget:SetSize(ModuleWidth(key),16)
            widget:Show()
            displayed[key]=true
            if widget.resizeGrip and widget.resizeGrip.Place then
                widget.resizeGrip.Place()
            end
        else widget:Hide() end
    end
    local function Arrange(list,group,start)
        local x=start
        for _,key in ipairs(list) do
            if chosen[key] then
                local widget=widgets[key]
                local justification=groups.align and groups.align[key] or group
                if widget.text and widget.text.SetJustifyH then
                    widget.text:SetJustifyH(string.upper(justification))
                end
                widget:ClearAllPoints()
                if group=="left" then
                    widget:SetPoint("LEFT",bar,"LEFT",x,0)
                elseif group=="center" then
                    widget:SetPoint("CENTER",bar,"LEFT",
                        x+ModuleWidth(key)/2,0)
                else
                    widget:SetPoint("RIGHT",bar,"RIGHT",
                        x+ModuleWidth(key)-width,0)
                end
                x=x+ModuleWidth(key)+7
            end
        end
    end
    if split then
        local leftWidth=Measure(groups.left)
        local rightWidth=Measure(groups.right)
        Arrange(groups.left,"left",12)
        if chosenSplit then
            Arrange(chosenSplit.first,"center",chosenSplit.leftStart)
            Arrange(chosenSplit.second,"center",chosenSplit.rightStart)
        end
        Arrange(groups.right,"right",width-12-rightWidth)
        -- The bar remains in one Blizzard-owned frame, but only its two
        -- visible backgrounds cover usable pixels. No added game frames or
        -- invisible notch hit-targets.
        if bar.background and bar.backgroundRight and
            bar.background.ClearAllPoints and
            bar.backgroundRight.ClearAllPoints then
            bar.background:ClearAllPoints()
            bar.background:SetPoint("TOPLEFT",bar,"TOPLEFT",0,0)
            bar.background:SetPoint("BOTTOMRIGHT",bar,"BOTTOMLEFT",
                split.left,0)
            bar.backgroundRight:ClearAllPoints()
            bar.backgroundRight:SetPoint("TOPLEFT",bar,"TOPLEFT",
                split.right,0)
            bar.backgroundRight:SetPoint("BOTTOMRIGHT",bar,"BOTTOMRIGHT",
                0,0)
            bar.backgroundRight:Show()
        end
    else
        local _,leftWidth,centerWidth,rightWidth=Need()
        Arrange(groups.left,"left",12)
        local rightStart=width-12-rightWidth
        local centerStart=math.max(12+leftWidth+(leftWidth>0 and 10 or 0),
            math.min((width-centerWidth)/2,
                rightStart-centerWidth-(rightWidth>0 and 10 or 0)))
        Arrange(groups.center,"center",centerStart)
        Arrange(groups.right,"right",rightStart)
        if bar.background and bar.backgroundRight then
            if bar.background.ClearAllPoints then
                bar.background:ClearAllPoints()
                bar.background:SetAllPoints(bar)
            end
            bar.backgroundRight:Hide()
        end
    end
end
-- Cosmetic widths are per-character and never resize protected game UI.
function ChalkBox_BarWidthGet(key)
    return specs[key] and ModuleWidth(key) or nil
end
function ChalkBox_BarWidthSet(key,value)
    local pixels=RoundedWidth(value)
    if not specs[key] or not pixels then return false end
    if type(InCombatLockdown)=="function" and InCombatLockdown() then
        return false
    end
    if type(ChalkBox_BarLayoutWidthSet)~="function" or
        not ChalkBox_BarLayoutWidthSet(key,pixels) then return false end
    previewWidths[key]=nil
    lastLayout=""
    Reflow()
    return true
end
function ChalkBox_BarWidthReset(key)
    if not specs[key] or type(ChalkBox_BarLayoutWidthReset)~="function"
        then return false end
    if type(InCombatLockdown)=="function" and InCombatLockdown() then
        return false
    end
    if not ChalkBox_BarLayoutWidthReset(key) then return false end
    previewWidths[key]=nil
    lastLayout=""
    Reflow()
    return true
end

-- The stat menu controls only that stat. Right-click empty bar space for
-- global controls. WoW color codes also work with the legacy menu fallback.
local menuNames={
    level="Level / XP",rate="XP/hr",bags="Bags",
    bagvalue="Bag value",bankvalue="Bank value",repair="Repair",gear="Durability",
    eta="Level ETA",rested="Rested XP",pet="Pet",
    time="Session",latency="Latency",gold="Gold",
}
local menuOrder={"rate","bags","bagvalue","bankvalue","repair","gear","eta",
    "rested","pet","time","latency","gold"}
local menuColors={
    title="ffffd36a",    -- gold: headings
    group="ff79d4e9",    -- cyan: navigation
    enabled="ff74d99b",  -- green: enabled
    disabled="ff9ba2ad", -- gray: disabled
    selected="ffffd36a", -- gold: current position
    warning="ffffb76f",  -- amber: hide / reset
    normal="ffe5e8ee",   -- neutral actions
}
local fallbackMenu
local function AddMenuEntry(list,label,callback,children,tone)
    list[#list+1]={text=label,func=callback,children=children,tone=tone or "normal"}
end
local function MenuText(item)
    return "|c"..(menuColors[item.tone] or menuColors.normal)..item.text.."|r"
end
local sectionNames={left="Left",center="Center",right="Right"}
local sections={"left","center","right"}
local function CurrentSection(layout,key)
    for _,section in ipairs(sections) do
        for _,module in ipairs(layout[section] or {}) do
            if module==key then return section end
        end
    end
    return specs[key] and specs[key].group or "left"
end
local function DirectionMenu(key,command,current)
    local items={}
    for _,section in ipairs(sections) do
        local choice=section
        local selected=choice==current
        AddMenuEntry(items,(selected and "* " or "")..sectionNames[choice],
            function() ChalkBox_BarCommand(command.." "..key.." "..choice) end,
            nil,selected and "selected" or "normal")
    end
    return items
end
function ChalkBox_BarContextItems(key)
    if key and not specs[key] then return end
    local result={}
    if key then
        AddMenuEntry(result,menuNames[key],nil,nil,"title")
        if key~="level" then
            local enabled=StatEnabled(key)
            AddMenuEntry(result,enabled and "Hide" or "Show",function()
                ChalkBox_BarCommand("stat "..key.." "..
                    (StatEnabled(key) and "off" or "on"))
            end,nil,enabled and "warning" or "enabled")
        end
        if key=="bagvalue" then
            AddMenuEntry(result,ChalkBox_BarBagValueModeGet()=="junk"
                and "Total value" or "Junk only",
                function() ChalkBox_BarBagValueModeToggle() end)
        elseif key=="repair" then
            AddMenuEntry(result,"Repair stats",function()
                ChalkBox_BarCommand("repair status")
            end)
        end
        local layout=type(ChalkBox_BarLayoutGet)=="function"
            and ChalkBox_BarLayoutGet() or groups
        local section=CurrentSection(layout,key)
        local alignment=layout.align and layout.align[key] or section
        AddMenuEntry(result,"Move",nil,DirectionMenu(key,"move",section),"group")
        AddMenuEntry(result,"Align",nil,DirectionMenu(key,"align",alignment),"group")
        local widths={}
        local current=ChalkBox_BarWidthGet(key) or specs[key].width
        for _,change in ipairs({-16,-8,8,16}) do
            local step=change
            AddMenuEntry(widths,(step>0 and "+" or "")..step.." px",
                function() ChalkBox_BarWidthSet(key,current+step) end)
        end
        AddMenuEntry(widths,"Reset width",function()
            ChalkBox_BarWidthReset(key)
        end,nil,"warning")
        AddMenuEntry(result,("Width (%d px)"):format(current),
            nil,widths,"group")
        AddMenuEntry(result,"Bar settings",function()
            if type(ChalkBox_OpenSettings)=="function" then
                ChalkBox_OpenSettings("barstats")
            end
        end,nil,"group")
        return result
    end

    AddMenuEntry(result,"THE BAR",nil,nil,"title")
    local modules={}
    for _,module in ipairs(menuOrder) do
        local selected=module
        local enabled=StatEnabled(selected)
        AddMenuEntry(modules,(enabled and "ON  " or "OFF ")..
            menuNames[selected],function()
            ChalkBox_BarCommand("stat "..selected.." "..
                (StatEnabled(selected) and "off" or "on"))
        end,nil,enabled and "enabled" or "disabled")
    end
    AddMenuEntry(result,"Modules",nil,modules,"group")
    local positions={}
    for _,position in ipairs({"top","bottom","off"}) do
        local choice=position
        local label=choice=="off" and "Hidden" or
            (choice=="top" and "Top" or "Bottom")
        local current=db and db.bar==choice
        AddMenuEntry(positions,(current and "* " or "")..label,
            function() ChalkBox_BarCommand(choice) end,nil,
            current and "selected" or "normal")
    end
    AddMenuEntry(result,"Position",nil,positions,"group")
    AddMenuEntry(result,IconsShown() and "Hide module icons" or
        "Show module icons",function()
        ChalkBox_BarIconsSet(not IconsShown())
    end,nil,"group")
    local notch=ChalkBox_BarTopInsetStatus()
    AddMenuEntry(result,"Top safe area ("..
        (notch.mode=="auto" and "Auto" or
            notch.mode=="split" and "Split" or
            tostring(notch.inset).."px")..")",function()
        if type(ChalkBox_OpenSettings)=="function" then
            ChalkBox_OpenSettings("barsafe")
        end
    end,nil,"group")
    AddMenuEntry(result,editMode and "Done editing" or "Edit layout",
        function() ChalkBox_BarCommand(editMode and "edit off" or "edit on") end,
        nil,editMode and "enabled" or "normal")
    AddMenuEntry(result,"Reset layout",function()
        ChalkBox_BarCommand("layout reset")
    end,nil,"warning")
    AddMenuEntry(result,"Stat settings",function()
        if type(ChalkBox_OpenSettings)=="function" then
            ChalkBox_OpenSettings("barstats")
        end
    end,nil,"group")
    AddMenuEntry(result,"Appearance",function()
        if type(ChalkBox_OpenSettings)=="function" then
            ChalkBox_OpenSettings("barappearance")
        end
    end,nil,"group")
    return result
end
local function BuildNativeMenu(root,items)
    for _,item in ipairs(items) do
        local label=MenuText(item)
        if item.children then
            local submenu=root:CreateButton(label)
            if submenu and submenu.CreateButton then
                BuildNativeMenu(submenu,item.children)
            end
        elseif item.func then
            root:CreateButton(label,function() item.func() end)
        elseif type(root.CreateTitle)=="function" then
            root:CreateTitle(label)
        end
    end
end
local function BuildLegacyMenu(items)
    local output={}
    for _,item in ipairs(items) do
        local label=MenuText(item)
        if item.children then
            output[#output+1]={text=label,hasArrow=true,
                notCheckable=true,menuList=BuildLegacyMenu(item.children)}
        elseif item.func then
            output[#output+1]={text=label,func=item.func,notCheckable=true}
        else
            output[#output+1]={text=label,isTitle=true,notCheckable=true}
        end
    end
    return output
end
function ChalkBox_BarOpenMenu(key,owner)
    if type(InCombatLockdown)=="function" and InCombatLockdown() then
        return false
    end
    local items=ChalkBox_BarContextItems(key)
    if not items then return false end
    if type(MenuUtil)=="table" and
        type(MenuUtil.CreateContextMenu)=="function" then
        local ok=pcall(MenuUtil.CreateContextMenu,owner or bar,
            function(_,root) BuildNativeMenu(root,items) end)
        if ok then return true end
    end
    if type(EasyMenu)=="function" then
        if not fallbackMenu then
            fallbackMenu=CreateFrame("Frame","ChalkBoxBarContextDropdown",
                UIParent,"UIDropDownMenuTemplate")
        end
        return pcall(EasyMenu,BuildLegacyMenu(items),fallbackMenu,
            "cursor",0,0,"MENU")
    end
    if type(ChalkBox_OpenSettings)=="function" then
        ChalkBox_OpenSettings("barstats")
    end
    return false
end

local function CreateBar()
    if bar or not UIParent then return end
    bar=CreateFrame("Frame","ChalkBoxInfoBar",UIParent)
    bar:SetHeight(18)
    -- Bar is persistent background chrome. Blizzard's LOW/MEDIUM unit
    -- frames (including the resting ZZZ artwork) must draw over it.
    -- Never raise our Bar above native HUD frames.
    bar:SetFrameStrata("BACKGROUND")
    if bar.SetFrameLevel then bar:SetFrameLevel(1) end
    if bar.EnableMouse then bar:EnableMouse(true) end
    bar:SetScript("OnMouseUp",function(self,button)
        -- Empty Bar space remains a context-menu target while editing, so
        -- "Done editing" can always be reached without another settings page.
        -- Individual stat blocks still right-click to cycle text alignment.
        if button=="RightButton" then
            ChalkBox_BarOpenMenu(nil,self)
        end
    end)
    local background=bar:CreateTexture(nil,"BACKGROUND")
    background:SetAllPoints(bar)
    bar.background=background
    local backgroundRight=bar:CreateTexture(nil,"BACKGROUND")
    backgroundRight:SetAllPoints(bar)
    bar.backgroundRight=backgroundRight
    backgroundRight:Hide()
    ApplyAppearance()
    local progress=bar:CreateTexture(nil,"ARTWORK")
    progress:SetPoint("BOTTOMLEFT",bar,"BOTTOMLEFT",0,0)
    progress:SetHeight(1)
    progress:SetColorTexture(0.19,0.64,0.93,0.85)
    bar.xpProgress=progress
    local progressRight=bar:CreateTexture(nil,"ARTWORK")
    progressRight:SetPoint("BOTTOMLEFT",bar,"BOTTOMLEFT",0,0)
    progressRight:SetHeight(1)
    progressRight:SetColorTexture(0.19,0.64,0.93,0.85)
    progressRight:Hide()
    bar.xpProgressRight=progressRight
    -- Hover details are a quick readout, not a help article.
    -- Keep each metric to one or two useful values; guidance belongs in settings.
    local blocks={
        {"level","Level / XP",function()
            return {tostring(session.xp or "--").." / "..
                tostring(session.maxXP or "--").." XP"}
        end},
        {"rate","XP / hour",function()
            return {"Gained: "..Number(session.xpGained).." XP"}
        end},
        {"bagvalue","Bag value",function()
            local v=latest.bagvalue
            if not v then return {"Unavailable"} end
            local junk=(v.junkComplete and "" or ">= ")..Coins(v.junkCopper)
            local total=(v.totalComplete and "" or ">= ")..Coins(v.totalCopper)
            local lines={"Junk: "..junk,"Total: "..total}
            if (v.totalUnknown or 0)>0 then
                lines[#lines+1]="Unknown: "..v.totalUnknown
            end
            return lines
        end},
        {"bankvalue","Bank value",function()
            local v=latest.bankvalue
            if not v then return {"Open your bank to record its value"} end
            local lines={
                "Vendor: "..(v.vendorComplete and "" or "at least ")..
                    Coins(v.vendorCopper),
                "Last seen: "..(v.age or "bank visit")
            }
            lines[#lines+1]="AH asks: "..(v.ahPriced>0 and
                ((v.ahComplete and "" or "at least ")..
                Coins(v.ahCopper)) or "unavailable")
            lines[#lines+1]=(v.ahPriced or 0).."/"..
                (v.stacks or 0).." stacks AH-priced"
            if (v.vendorUnknown or 0)>0 then
                lines[#lines+1]=v.vendorUnknown.." vendor prices unavailable"
            end
            return lines
        end},
        {"repair","Repair",function()
            local r=latest.repair
            if not r then return {"Unavailable"} end
            local lines={}
            if r.state=="exact" then
                lines[1]="Quote: "..Coins(r.copper)
            elseif r.state=="estimate" then
                lines[1]="Estimate: ~"..Coins(r.copper)
            elseif r.state=="no-damage" then
                lines[1]="No damage"
            else
                lines[1]="No quote"
            end
            if r.missing and r.max then
                lines[#lines+1]="Wear: "..r.missing.." / "..r.max
            end
            return lines
        end},
        {"bags","Bag space",function()
            local a=latest.bags
            if not a then return {"Unavailable"} end
            local lines={"Free: "..a.free.." / "..a.total}
            if (a.special or 0)>0 then
                lines[#lines+1]="General: "..a.general.."  Specialty: "..a.special
            end
            if (a.unknown or 0)>0 then
                lines[#lines+1]="Unknown: "..a.unknown
            end
            return lines
        end},
        {"gear","Durability",function()
            local a=latest.gear
            if not a then return {"Unavailable"} end
            return {"Overall: "..a.percent.."%","Lowest: "..a.worst.."%"}
        end},
        {"eta","Level ETA",function()
            local remaining=session.maxXP and session.xp and
                math.max(0,session.maxXP-session.xp)
            return {"XP left: "..(remaining and Number(remaining) or "--")}
        end},
        {"rested","Rested XP",function()
            local a=latest.rested
            if not a then return {"Unavailable"} end
            return {Number(a.xp).." XP ("..a.percent.."%)"}
        end},
        {"pet","Pet",function()
            local a=latest.pet
            if not a then return {"Unavailable"} end
            if a.state=="none" then return {"No pet"} end
            if a.state=="protected" or a.state=="unknown" then
                return {"Health unavailable"}
            end
            return {"Health: "..a.percent.."%"}
        end},
        {"time","Session",function()
            return {"Elapsed: "..Duration(ReadElapsed())}
        end},
        {"latency","Latency",function()
            local a=latest.latency
            if not a then return {"Unavailable"} end
            return {"Home: "..a.home.." ms","World: "..a.world.." ms"}
        end},
        {"gold","Gold",function()
            local _,_,perHour=GetRates()
            local net=session.money and session.goldStart and
                session.money-session.goldStart or nil
            return {"Net: "..Money(net,true),"Per hour: "..Money(perHour,true)}
        end},
    }
    for _,item in ipairs(blocks) do
        local key,name,details=unpack(item)
        local widget=CreateFrame("Frame",nil,bar)
        widget:SetSize(ModuleWidth(key),16)
        if type(widget.SetClipsChildren)=="function" then
            widget:SetClipsChildren(true)
        end
        local font=widget:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        font:SetAllPoints(widget)
        -- Narrow widths must clip to a single Bar line, never spill down
        -- into the game UI or draw over a neighboring module.
        if type(font.SetMaxLines)=="function" then font:SetMaxLines(1) end
        if type(font.SetWordWrap)=="function" then font:SetWordWrap(false) end
        font:SetJustifyH(key=="gold" and "RIGHT" or
            (specs[key].group=="center" and "CENTER" or "LEFT"))
        widget.text=font
        widgets[key]=widget
        local icon=widget:CreateTexture(nil,"ARTWORK")
        if type(icon.SetTexture)=="function" then
            icon:SetTexture(moduleIcons[key] or
                "Interface\\Icons\\INV_Misc_QuestionMark")
        end
        if type(icon.SetWidth)=="function" then icon:SetWidth(13) end
        if type(icon.SetHeight)=="function" then icon:SetHeight(13) end
        if type(icon.SetPoint)=="function" then
            icon:SetPoint("LEFT",widget,"LEFT",2,0)
        end
        if type(icon.SetTexCoord)=="function" then
            icon:SetTexCoord(0.07,0.93,0.07,0.93)
        end
        widget.icon=icon
        LayoutModuleIcon(widget)
        local grab=widget:CreateTexture(nil,"BACKGROUND")
        grab:SetAllPoints(widget)
        grab:SetColorTexture(0.45,0.32,0.12,0)
        widget.editBackground=grab
        -- Only the tiny gold right-edge grip resizes. All other widget area
        -- preserves the existing left-drag move interaction.
        local grip=CreateFrame("Frame",nil,widget)
        grip:SetSize(8,16)
        grip:SetPoint("RIGHT",widget,"RIGHT",0,0)
        if grip.EnableMouse then grip:EnableMouse(true) end
        if grip.RegisterForDrag then grip:RegisterForDrag("LeftButton") end
        local stroke=grip:CreateTexture(nil,"OVERLAY")
        if stroke.SetWidth then stroke:SetWidth(2) end
        if stroke.SetHeight then stroke:SetHeight(11) end
        if stroke.SetPoint then
            stroke:SetPoint("CENTER",grip,"CENTER",0,0)
        end
        if stroke.SetColorTexture then
            stroke:SetColorTexture(.95,.76,.40,.95)
        end
        widget.resizeGrip=grip
        if grip.SetMovable then grip:SetMovable(true) end
        local function EdgeFor()
            local group=specs[key] and specs[key].group or "left"
            for _,name in ipairs({"left","center","right"}) do
                for _,item in ipairs(groups[name] or {}) do
                    if item==key then group=name end
                end
            end
            -- Right-side stats are pinned on the right, so the grip that
            -- actually moves is the left edge. Everywhere else, drag the right.
            return group=="right" and "left" or "right"
        end
        local function PlaceGrip()
            if type(grip.ClearAllPoints)~="function" or
                type(grip.SetPoint)~="function" then return end
            grip.edge=EdgeFor()
            grip:ClearAllPoints()
            if grip.edge=="left" then
                grip:SetPoint("LEFT",widget,"LEFT",0,0)
            else
                grip:SetPoint("RIGHT",widget,"RIGHT",0,0)
            end
        end
        grip.Place=PlaceGrip
        PlaceGrip()
        local function Candidate()
            if not grip.dragStartX or not grip.dragStartWidth then
                return nil
            end
            local cursor=CursorInBar()
            if not cursor then return nil end
            local delta=cursor-grip.dragStartX
            if grip.edge=="left" then delta=-delta end
            return RoundedWidth(grip.dragStartWidth+delta)
        end
        local function BeginDrag(self)
            if not editMode or (type(InCombatLockdown)=="function"
                and InCombatLockdown()) then return end
            local cursor=CursorInBar()
            if not cursor then return end
            PlaceGrip()
            self.dragStartX=cursor
            self.dragStartWidth=ModuleWidth(key)
            self.dragging=true
        end
        local function FinishDrag(self)
            if not self.dragging then return end
            local newWidth=Candidate() or self.dragStartWidth
            self.dragging=false
            previewWidths[key]=nil
            if not ChalkBox_BarWidthSet(key,newWidth) then
                lastLayout=""
                Reflow()
            end
            PlaceGrip()
        end
        grip:SetScript("OnMouseDown",function(self,button)
            if button=="LeftButton" then BeginDrag(self) end
        end)
        grip:SetScript("OnMouseUp",function(self,button)
            if button=="LeftButton" then FinishDrag(self) end
        end)
        grip:SetScript("OnDragStart",function(self)
            BeginDrag(self)
        end)
        grip:SetScript("OnUpdate",function(self)
            if not self.dragging then return end
            if type(InCombatLockdown)=="function" and
                InCombatLockdown() then
                self.dragging=false
                previewWidths[key]=nil
                lastLayout=""
                Reflow()
                return
            end
            local newWidth=Candidate()
            if newWidth and newWidth~=ModuleWidth(key) then
                previewWidths[key]=newWidth
                lastLayout=""
                Reflow()
                PlaceGrip()
            end
        end)
        grip:SetScript("OnDragStop",function(self)
            FinishDrag(self)
        end)
        if widget.SetMovable then widget:SetMovable(true) end
        if widget.RegisterForDrag then widget:RegisterForDrag("LeftButton") end
        widget:SetScript("OnDragStart",function(self)
            if not editMode or (type(InCombatLockdown)=="function"
                and InCombatLockdown()) then return end
            if self.StartMoving then self:StartMoving() end
        end)
        widget:SetScript("OnDragStop",function(self)
            if self.StopMovingOrSizing then self:StopMovingOrSizing() end
            if not editMode or (type(InCombatLockdown)=="function"
                and InCombatLockdown()) then
                -- A drag cancelled by combat/lock must snap back to its last
                -- valid saved anchor, never leave a floating ghost widget.
                lastLayout=""
                Reflow()
                return
            end
            local x
            if type(GetCursorPosition)=="function" and bar.GetEffectiveScale then
                local cursor=GetCursorPosition()
                local scale=bar:GetEffectiveScale()
                if Public(cursor) and type(cursor)=="number" and
                    Public(scale) and type(scale)=="number" and scale>0 then
                    x=cursor/scale
                end
            end
            if not x and self.GetCenter then x=self:GetCenter() end
            local left=bar.GetLeft and bar:GetLeft()
            local width=bar:GetWidth()
            if not Public(left) or type(left)~="number"
                or not Public(width) or type(width)~="number"
                or width<=0 or not Public(x) or type(x)~="number" then
                lastLayout=""
                Reflow()
                return
            end
            -- The three drop zones are real thirds of the bar's live width.
            local relativeX=x-left
            local destination=relativeX<width/3 and "left" or
                (relativeX>width*2/3 and "right" or "center")
            local index=1
            for _,other in ipairs(groups[destination] or {}) do
                if other~=key then
                    local neighbor=widgets[other]
                    local cx=neighbor and neighbor.GetCenter and neighbor:GetCenter()
                    if Public(cx) and type(cx)=="number" and x>cx then
                        index=index+1
                    end
                end
            end
            if type(ChalkBox_BarLayoutMove)=="function" then
                ChalkBox_BarLayoutMove(key,destination,index)
            end
            lastLayout=""
            Reflow()
        end)
        widget:SetScript("OnMouseUp",function(self,button)
            if button=="RightButton" then
                if editMode then
                    local layout=type(ChalkBox_BarLayoutGet)=="function" and
                        ChalkBox_BarLayoutGet() or {}
                    local current=layout.align and layout.align[key] or "left"
                    local nextMode=current=="left" and "center" or
                        (current=="center" and "right" or "left")
                    if type(ChalkBox_BarLayoutAlign)=="function" then
                        ChalkBox_BarLayoutAlign(key,nextMode)
                        lastLayout=""
                        Reflow()
                    end
                else
                    if GameTooltip then GameTooltip:Hide() end
                    ChalkBox_BarOpenMenu(key,self)
                end
            elseif button=="LeftButton" and not editMode then
                if key=="bags" then
                    ChalkBox_BarToggleBags()
                elseif key=="bagvalue" then
                    ChalkBox_BarBagValueModeToggle()
                elseif key=="level" and type(ChalkBox_OpenStorybook)=="function" then
                    ChalkBox_OpenStorybook("overview")
                end
            end
        end)
        Hint(widget,name,details,key)
    end
    bar:SetScript("OnSizeChanged",function() Reflow() end)
    EditDecorations()
end

-- Combat-safe overlay: only move our own unprotected frame.
-- Never reanchor, resize, or reset UIParent, Blizzard action buttons,
-- or another addon's frames. Those mutations can taint protected actions.
local reservation={active=false,pending=false,position=nil,issue=nil}
-- Auto-read Blizzard's notched-display safe region, when Forever exposes
-- it. We deliberately do not move UIParent or alter the macOS game display.
-- Manual override is available for clients without these APIs.
local TOP_INSET_MAX=120
local function ValidInset(value)
    return Public(value) and type(value)=="number" and
        value==value and value>=0 and value<=TOP_INSET_MAX
        and value~=math.huge
end
local function SafeRegion(fn)
    if type(fn)~="function" then return nil end
    local ok,left,right,top,bottom=pcall(fn)
    if not ok or not Public(left) or not Public(right) or
        not Public(top) or not Public(bottom) or
        type(left)~="number" or type(right)~="number" or
        type(top)~="number" or type(bottom)~="number" or
        left~=left or right~=right or top~=top or bottom~=bottom or
        right<=left or top<=bottom then return nil end
    return {left=left,right=right,top=top,bottom=bottom}
end
NotchLayout=function(width)
    if not db or not Public(width) or type(width)~="number"
        or width<160 then return nil end
    -- Use the owner's live-tested MacBook geometry only when the active
    -- display reports a real notch. Keep manual saved choices authoritative.
    -- Never apply these values on a normal/external display.
    local manual=db.barNotchGap
    local calibrated=false
    if manual==nil and db.barTopInset==nil then
        local api=type(C_UI)=="table" and C_UI or nil
        if api and type(api.DoesAnyDisplayHaveNotch)=="function" then
            local ok,has=pcall(api.DoesAnyDisplayHaveNotch)
            if ok and Public(has) and has==true then
                local l=SafeRegion(api.GetTopLeftNotchSafeRegion)
                local r=SafeRegion(api.GetTopRightNotchSafeRegion)
                if l and r and r.left>l.right then
                    local height=math.min(l.top-l.bottom,r.top-r.bottom)
                    local span=r.right-l.left
                    local notchWidth=r.left-l.right
                    if height>0 and height<=TOP_INSET_MAX and span>0
                        and notchWidth/span>=0.02
                        and notchWidth/span<=0.45 then
                        manual=152
                        calibrated=true
                    end
                end
            end
        end
    end
    if type(manual)=="number" and Public(manual) and manual==manual
        and manual>=40 and manual<=400 and manual<width*0.50 then
        local mid=width/2
        local left=math.floor(mid-manual/2-8)
        local right=math.ceil(mid+manual/2+8)
        if left>24 and right<width-24 then
            return {left=left,right=right,source=calibrated and
                "Mac notch calibrated default" or "manual split"}
        end
    end
    if manual~=nil or db.barTopInset~=nil then return nil end
    local api=type(C_UI)=="table" and C_UI or nil
    if not api then return nil end
    -- ShouldUIParentAvoidNotch() means BLIZZARD HAS MOVED UIParent DOWN:
    -- it is precisely when our split needs to reach WorldFrame's top.
    -- Never suppress valid notch geometry because that returns true.
    if type(api.DoesAnyDisplayHaveNotch)=="function" then
        local ok,has=pcall(api.DoesAnyDisplayHaveNotch)
        if ok and Public(has) and has==false then return nil end
    end
    local left=SafeRegion(api.GetTopLeftNotchSafeRegion)
    local right=SafeRegion(api.GetTopRightNotchSafeRegion)
    if not left or not right or right.left<=left.right then return nil end
    local span=right.right-left.left
    local notchWidth=right.left-left.right
    local height=math.min(left.top-left.bottom,
        right.top-right.bottom)
    if span<=0 or notchWidth/span<0.02 or notchWidth/span>0.45
        or height<=0 or height>TOP_INSET_MAX then return nil end
    local x1=(left.right-left.left)/span*width
    local x2=(right.left-left.left)/span*width
    if x1<width*0.15 or x2>width*0.85 then return nil end
    -- An 8 UI-pixel guard on each side keeps grips and glyphs clear.
    local a=math.floor(x1-8)
    local b=math.ceil(x2+8)
    if a<=24 or b>=width-24 then return nil end
    return {left=a,right=b,source="native notch split"}
end
local function NativeTopInset()
    local api=type(C_UI)=="table" and C_UI or nil
    if not api then return 0,"no notch API" end
    if type(api.ShouldUIParentAvoidNotch)=="function" then
        local ok,already=pcall(api.ShouldUIParentAvoidNotch)
        if ok and Public(already) and already==true then
            return 0,"Blizzard already avoids notch"
        end
    end
    if type(api.DoesAnyDisplayHaveNotch)=="function" then
        local ok,present=pcall(api.DoesAnyDisplayHaveNotch)
        if ok and Public(present) and present==false then
            return 0,"no notched display"
        end
    end
    local depth=0
    for _,fn in ipairs({"GetTopLeftNotchSafeRegion",
        "GetTopRightNotchSafeRegion"}) do
        if type(api[fn])=="function" then
            local ok,left,right,top,bottom=pcall(api[fn])
            if ok and Public(left) and Public(right) and
                Public(top) and Public(bottom) and
                type(left)=="number" and type(right)=="number" and
                type(top)=="number" and type(bottom)=="number" and
                right>left then
                local height=top-bottom
                if ValidInset(height) and height>0 then
                    depth=math.max(depth,height)
                end
            end
        end
    end
    -- The region describes the band left/right of the camera cutout.
    -- Add a tiny cushion so text and interactive grips sit below it.
    if depth>0 then
        return math.min(TOP_INSET_MAX,math.ceil(depth+4)),
            "native notch safe region"
    end
    return 0,"notch region unavailable"
end
function ChalkBox_BarTopInsetStatus()
    local choice=db and db.barTopInset or nil
    if not ValidInset(choice) then choice=nil end
    local width=bar and bar.GetWidth and bar:GetWidth()
        or (UIParent and UIParent.GetWidth and UIParent:GetWidth()) or 0
    local split=type(NotchLayout)=="function" and NotchLayout(width)
    local inset,source,mode
    if split then
        inset,source=0,split.source
        mode=db and db.barNotchGap and "split" or "auto"
    elseif choice~=nil then
        inset,source,mode=choice,"manual top inset","manual"
    elseif db and db.barNotchGap~=nil then
        -- A very narrow window cannot fit the requested manual camera
        -- gap. Keep all remaining widgets visible below the camera
        -- instead of incorrectly drawing over the cutout.
        local native=NativeTopInset()
        inset,source,mode=math.max(32,native),
            "manual split too wide for display; lowered","split"
    else
        inset,source=NativeTopInset()
        mode="auto"
    end
    return {mode=mode,inset=choice,effective=inset,source=source,
        manualGap=db and db.barNotchGap or nil,
        rise=db and db.barNotchRise or nil,
        split=split~=nil,gapStart=split and split.left,
        gapEnd=split and split.right,pending=reservation.pending,
        anchor=reservation.position or "UIParent"}
end
-- Top chrome spacing is managed independently by ScreenLayout.lua.
-- This Bar stays full-width, and never changes Blizzard's UIParent anchors.
local function InCombat()
    return type(InCombatLockdown)=="function" and InCombatLockdown()
end
-- WorldFrame covers the actual rendered display, whereas Blizzard may
-- shift UIParent below the Mac camera housing. Only anchor OUR bar to
-- WorldFrame; never resize or move either Blizzard-owned frame.
local function FullscreenReference()
    local world=WorldFrame
    if not Public(world) then world=nil end
    if not world and type(C_UI)=="table" and
        type(C_UI.GetWorldFrame)=="function" then
        local ok,frame=pcall(C_UI.GetWorldFrame)
        if ok and Public(frame) then world=frame end
    end
    if world and type(world.GetWidth)=="function" then
        local ok,width=pcall(world.GetWidth,world)
        if ok and Public(width) and type(width)=="number" and width>0 then
            return world
        end
    end
    return nil
end
local function NativeLiftFallback()
    local api=type(C_UI)=="table" and C_UI or nil
    local depth=0
    if api then
        for _,name in ipairs({"GetTopLeftNotchSafeRegion",
            "GetTopRightNotchSafeRegion"}) do
            local region=SafeRegion(api[name])
            if region then
                local h=region.top-region.bottom
                if ValidInset(h) then depth=math.max(depth,h) end
            end
        end
    end
    -- Without WorldFrame metrics, still let a manual split claim the
    -- usual camera-height band; its position can be tuned by the user.
    return depth>0 and math.ceil(depth) or 32
end
local function PlaceBar()
    if not bar or not db then return end
    if InCombat() then
        reservation.pending=true
        return
    end
    reservation.pending=false
    reservation.issue=nil
    -- In overlay mode Blizzard owns its root layout at all times.
    -- This remains anchored to the requested edge after UI scale changes.
    local state=ChalkBox_BarTopInsetStatus()
    local reference=UIParent
    local y=-(state.effective or 0)
    reservation.position="UIParent"
    if db.bar=="top" and state.split then
        local manualRise=db.barNotchRise
        if manualRise==nil and state.source=="Mac notch calibrated default" then
            manualRise=36
        end
        if ValidInset(manualRise) then
            -- Slider moves UP into the camera-height band (positive Y).
            y=manualRise
            reservation.position="manual lift"
        else
            local full=FullscreenReference()
            if full and type(full.IsProtected)=="function" then
                local ok,prot=pcall(full.IsProtected,full)
                if not ok or prot~=false then full=nil end
            end
            if full then
                reference=full
                y=0
                reservation.position="WorldFrame"
            else
                y=NativeLiftFallback()
                reservation.position="native notch height"
            end
        end
    end
    bar:ClearAllPoints()
    if db.bar=="bottom" then
        bar:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",0,0)
        bar:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",0,0)
    else
        bar:SetPoint("TOPLEFT",reference,"TOPLEFT",0,y)
        bar:SetPoint("TOPRIGHT",reference,"TOPRIGHT",0,y)
    end
    if db.bar=="off" then bar:Hide() else bar:Show() end
    -- ScreenLayout moves only safe, native top chrome once out of combat;
    -- the Bar itself remains a full-width 18px strip.
    if type(ChalkBox_ScreenLayoutAdjust)=="function" then
        ChalkBox_ScreenLayoutAdjust()
    end
    lastLayout=""
    Reflow()
end
function ChalkBox_BarNotchGapSet(value)
    if not db then return false end
    if value=="auto" then
        db.barNotchGap=nil
        db.barNotchRise=nil
    elseif type(value)=="number" and Public(value) and
        value==value and value>=40 and value<=400 then
        db.barNotchGap=math.floor(value+0.5)
        db.barTopInset=nil
    else
        return false
    end
    PlaceBar()
    return true
end
function ChalkBox_BarTopInsetSet(value)
    if not db then return false end
    if value=="auto" then
        db.barTopInset=nil
        db.barNotchGap=nil
        db.barNotchRise=nil
    elseif ValidInset(value) then
        -- Explicit BELOW-notch fallback, retained for older installations.
        db.barTopInset=math.floor(value+0.5)
        db.barNotchGap=nil
        db.barNotchRise=nil
    else
        return false
    end
    PlaceBar()
    return true
end
function ChalkBox_BarNotchRaiseSet(value)
    if not db then return false end
    if value=="auto" then
        db.barNotchRise=nil
    elseif ValidInset(value) then
        db.barNotchRise=math.floor(value+0.5)
        db.barTopInset=nil
        -- On Forever builds that lack the safe-rectangle API, a manual
        -- upward correction must keep a camera gap to avoid obstruction.
        if not NotchLayout(bar and bar.GetWidth and bar:GetWidth() or 0) then
            db.barNotchGap=db.barNotchGap or 120
        end
    else
        return false
    end
    PlaceBar()
    return true
end

Refresh=function()
    if not db or not bar then return end
    CaptureXP()
    CaptureMoney()
    local xpPerHour,eta,goldPerHour,elapsed=GetRates()
    local stats={}
    if type(ChalkBox_BarReadStats)=="function" then
        local ok,value=pcall(ChalkBox_BarReadStats,session.maxXP,
            StatEnabled("bagvalue"),StatEnabled("repair"))
        if ok and type(value)=="table" then stats=value end
    end
    if type(ChalkBox_BankValueStatus)=="function" then
        local ok,value=pcall(ChalkBox_BankValueStatus)
        if ok and type(value)=="table" then
            stats.bankvalue=value
        end
    end
    latest=stats
    if session.level then
        if session.maxXP and session.maxXP>0 then
            widgets.level.text:SetText(("Lv %d  %.1f%%"):format(
                session.level,100*session.xp/session.maxXP))
        else
            widgets.level.text:SetText(("Lv %d  MAX"):format(session.level))
        end
    else
        widgets.level.text:SetText("Level --")
    end
    widgets.rate.text:SetText("XP/h "..Number(xpPerHour))
    widgets.eta.text:SetText("To level "..
        (session.maxXP and session.maxXP>0 and Duration(eta) or "--"))
    widgets.gold.text:SetText("Gold "..Money(session.money).." (net "..
        Money(session.money and session.goldStart and session.money-session.goldStart
            or nil,true)..")")
    widgets.time.text:SetText("Time "..Duration(elapsed))
    widgets.bagvalue.text:SetText(BagValueText(stats.bagvalue))
    local bank=stats.bankvalue
    widgets.bankvalue.text:SetText(bank and
        ("Bank "..(bank.vendorComplete and "" or ">=")..
        Money(bank.vendorCopper)) or "Bank --")
    local cost=stats.repair
    local repairText="Repair --"
    if cost and type(cost.copper)=="number" then
        repairText="Repair "..(cost.state=="estimate" and "~" or "")..
            Money(cost.copper)
    end
    widgets.repair.text:SetText(repairText)
    widgets.bags.text:SetText(stats.bags and
        ("Bags "..stats.bags.free.." free") or "Bags --")
    widgets.gear.text:SetText(stats.gear and
        ("Gear "..stats.gear.percent.."%") or "Gear --")
    widgets.rested.text:SetText(stats.rested and
        ("Rest "..stats.rested.percent.."%") or "Rest --")
    widgets.latency.text:SetText(stats.latency and
        ("World "..stats.latency.world.."ms") or "World --")
    local pet=stats.pet
    widgets.pet.text:SetText(pet and (pet.state=="ready" and
        ("Pet "..pet.percent.."%") or (pet.state=="none" and "Pet none" or "Pet --"))
        or "Pet --")
    local highlights={
        gear=stats.gear and stats.gear.worst and stats.gear.worst<=25,
        repair=cost and cost.missing and cost.max and cost.max>0 and
            cost.missing/cost.max>=0.65,
        bags=stats.bags and stats.bags.general and stats.bags.general<=2,
        pet=pet and pet.state=="ready" and pet.percent<=30,
        latency=stats.latency and stats.latency.world>=250,
    }
    for key,warning in pairs(highlights) do
        local font=widgets[key] and widgets[key].text
        if font and type(font.SetTextColor)=="function" then
            if warning then font:SetTextColor(1,0.47,0.34)
            else font:SetTextColor(0.95,0.91,0.80) end
        end
    end
    Reflow()
    if session.maxXP and session.maxXP>0 and bar.xpProgress then
        local width=bar:GetWidth()
        if Public(width) and type(width)=="number" then
            local fill=width*math.min(1,session.xp/session.maxXP)
            local notch=type(NotchLayout)=="function" and
                db.bar=="top" and NotchLayout(width) or nil
            if notch then
                if fill>0 then
                    bar.xpProgress:SetWidth(math.max(0.1,
                        math.min(fill,notch.left)))
                    bar.xpProgress:Show()
                else bar.xpProgress:Hide() end
                local remaining=fill-notch.right
                if bar.xpProgressRight and remaining>0 then
                    if bar.xpProgressRight.ClearAllPoints then
                        bar.xpProgressRight:ClearAllPoints()
                    end
                    bar.xpProgressRight:SetPoint("BOTTOMLEFT",bar,
                        "BOTTOMLEFT",notch.right,0)
                    bar.xpProgressRight:SetWidth(remaining)
                    bar.xpProgressRight:Show()
                elseif bar.xpProgressRight then
                    bar.xpProgressRight:Hide()
                end
            else
                bar.xpProgress:SetWidth(math.max(0.1,fill))
                bar.xpProgress:Show()
                if bar.xpProgressRight then bar.xpProgressRight:Hide() end
            end
        end
    elseif bar.xpProgress then
        bar.xpProgress:Hide()
        if bar.xpProgressRight then bar.xpProgressRight:Hide() end
    end
end

-- The bank reader triggers this after a user actually opens a banker.
-- It must never cause another bank scan or touch bank item buttons.
function ChalkBox_BarBankValueRefresh()
    if Refresh then Refresh() end
end
function ChalkBox_BarStatus()
    local chosen={}
    for _,group in ipairs({"left","center","right"}) do
        for _,key in ipairs(groups[group]) do
            if StatEnabled(key) then chosen[#chosen+1]=key end
        end
    end
    local visible={}
    for key in pairs(displayed) do visible[#visible+1]=key end
    table.sort(visible)
    return {enabled=chosen,visible=visible,options=db and db.barStats}
end

local function Note(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff55ccaaChalkBox|r " .. message)
    end
end

function ChalkBox_BarCommand(message)
    if not db then return end
    local action = string.lower((message or ""):match("^%s*(.-)%s*$") or "")
    local alpha=action:match("^opacity%s+(%d+)$")
    local module,section,index=action:match("^move%s+(%a+)%s+(%a+)%s*(%d*)$")
    local aligned,mode=action:match("^align%s+(%a+)%s+(%a+)$")
    if alpha then
        ChalkBox_BarAppearanceSet(tonumber(alpha))
        Note("TrailBar charcoal background opacity: "..ChalkBox_BarAppearanceGet().."%.")
    elseif action=="icons on" or action=="icons off" then
        local on=action=="icons on"
        ChalkBox_BarIconsSet(on)
        Note("Bar module icons: "..(on and "ON." or "OFF."))
    elseif action=="edit" or action=="edit toggle" or action=="edit on"
        or action=="edit off" then
        local on=action=="edit on" or
            ((action=="edit" or action=="edit toggle") and not editMode)
        if ChalkBox_BarEditSet(on) then
            Note("Bar editing: "..(on and "ON." or "OFF."))
        else Note("Cannot edit TrailBar while in combat.") end
    elseif action=="layout reset" then
        if type(ChalkBox_BarLayoutReset)=="function" then
            ChalkBox_BarLayoutReset()
            lastLayout=""
            Reflow()
        end
        Note("Bar layout reset.")
    elseif action:match("^width%s+(%a+)%s+reset$") then
        local key=action:match("^width%s+(%a+)%s+reset$")
        Note(ChalkBox_BarWidthReset(key)
            and ((menuNames[key] or key).." width reset.")
            or "Unknown module or cannot resize during combat.")
    elseif action:match("^width%s+(%a+)%s+(%d+)$") then
        local key,px=action:match("^width%s+(%a+)%s+(%d+)$")
        Note(ChalkBox_BarWidthSet(key,tonumber(px))
            and ((menuNames[key] or key).." width: "..
                tostring(ChalkBox_BarWidthGet(key)).."px.")
            or "Invalid module width or cannot resize during combat.")
    elseif action=="layout" or action=="layout status" then
        Note(type(ChalkBox_BarLayoutDescription)=="function"
            and ChalkBox_BarLayoutDescription() or "Layout module unavailable.")
    elseif module and (section=="left" or section=="center" or section=="right") then
        if type(ChalkBox_BarLayoutMove)=="function" and
            ChalkBox_BarLayoutMove(module,section,tonumber(index)) then
            lastLayout=""
            Reflow()
            Note((menuNames[module] or module).." moved to "..section..".")
        else Note("Unknown TrailBar module or section.") end
    elseif aligned and (mode=="left" or mode=="center" or mode=="right") then
        if type(ChalkBox_BarLayoutAlign)=="function" and
            ChalkBox_BarLayoutAlign(aligned,mode) then
            lastLayout=""
            Reflow()
            Note((menuNames[aligned] or aligned).." aligned "..mode..".")
        else Note("Unknown TrailBar module.") end
    else
        local stat,choice=action:match("^stat%s+(%a+)%s+(%a+)$")
    if action=="bank status" or action=="bankvalue status" then
        local diagnostic=type(ChalkBox_BankValueDebug)=="function"
            and ChalkBox_BankValueDebug() or nil
        local on=StatEnabled("bankvalue")
        local shown=displayed.bankvalue==true
        Note(("Bank Bar: %s, %s; first visit %s."):format(
            on and "enabled" or "disabled",
            shown and "visible" or "not visible at current width",
            type(ChalkBox_BankValueStatus)=="function" and
                ChalkBox_BankValueStatus() and "recorded" or "not recorded"))
        if diagnostic then
            Note(("Bank reader: %s, frame %s, panel %s; %d tabs from %s."):format(
                diagnostic.open and "OPEN" or "closed",
                tostring(diagnostic.bankFrame),
                diagnostic.panel and "shown" or "not shown",
                diagnostic.tabs or 0,tostring(diagnostic.tabSource)))
            Note(("%d readable tabs, %d missing; %s."):format(
                diagnostic.readable or 0,diagnostic.missing or 0,
                tostring(diagnostic.reason)))
        else
            Note("Bank reader unavailable: confirm new build is installed.")
        end
    elseif action=="repair status" then
        local status=type(ChalkBox_RepairLearningStatus)=="function"
            and ChalkBox_RepairLearningStatus() or nil
        if status then
            Note("Repair learning: "..status.samples.." saved distinct quote(s), "..
                "limit "..status.limit..
                (status.lastError and
                    (", last estimate error "..status.lastError.."%") or
                    ", no accuracy comparison yet")..".")
        else Note("Repair learning module unavailable.") end
    elseif action=="repair reset" then
        if type(ChalkBox_RepairLearningReset)=="function" then
            ChalkBox_RepairLearningReset()
            Refresh()
            Note("Cleared this character's repair-learning history.")
        else Note("Repair learning module unavailable.") end
    elseif action=="bagvalue junk" or action=="bagvalue total"
        or action=="bagvalue toggle" then
        local mode=action:match("bagvalue%s+(%a+)")
        if mode=="toggle" then ChalkBox_BarBagValueModeToggle()
        else ChalkBox_BarBagValueModeSet(mode) end
        Note("Bag resale mode: "..ChalkBox_BarBagValueModeGet()..
            ". Click the value in TrailBar to switch.")
    elseif stat and specs[stat] and stat~="level"
        and (choice=="on" or choice=="off") then
        ConfigureStats()
        db.barStats[stat]=(choice=="on")
        Refresh()
        Note((menuNames[stat] or stat)..": "..string.upper(choice)..".")
    elseif action=="stats balanced" or action=="stats all"
        or action=="stats minimal" then
        ConfigureStats()
        local profile=action:match("stats%s+(%a+)")
        for key,default in pairs(statDefaults) do
            if profile=="all" then db.barStats[key]=true
            elseif profile=="minimal" then
                db.barStats[key]=(key=="gold" or key=="bags")
            else db.barStats[key]=default end
        end
        Refresh()
        Note("TrailBar preset: "..profile..".")
    elseif action=="stats" then
        local state=ChalkBox_BarStatus()
        Note("TrailBar enabled: "..table.concat(state.enabled,", ")..
            ". Visible at current width: "..table.concat(state.visible,", ")..".")
    elseif action == "reserve on" or action == "reserve off"
        or action == "dock on" or action == "dock off" then
        -- Preserve the old command syntax, but redirect to safe, selective
        -- Blizzard chrome shifting. Never modify UIParent or action buttons.
        db.barReserve=false
        if type(ChalkBox_ScreenLayoutSet)=="function" then
            ChalkBox_ScreenLayoutSet(action=="reserve on"
                or action=="dock on")
        end
        PlaceBar()
        Note("Safe top UI adjustment: " ..
            ((db.barShiftChrome~=false) and "ON." or "OFF."))
    elseif action=="safe" or action=="safe status" then
        local st=ChalkBox_BarTopInsetStatus()
        Note("Top safe area: "..st.mode.." / "..
            (st.split and ("split "..tostring(st.gapStart).."–"..
                tostring(st.gapEnd)) or
                tostring(st.effective).." UI px").." ("..st.source..
                "; anchor "..st.anchor.."; lift "..
                tostring(st.rise or "auto")..").")
    elseif action=="safe auto" then
        ChalkBox_BarTopInsetSet("auto")
        local st=ChalkBox_BarTopInsetStatus()
        Note("Top safe area: automatic "..(st.split and
            "split around notch" or st.effective.." UI px inset")..".")
    elseif action:match("^safe up %d+$") then
        local rise=tonumber(action:match("^safe up (%d+)$"))
        if ChalkBox_BarNotchRaiseSet(rise) then
            Note("Notch bar raised "..rise.." UI px above the game UI edge.")
        else
            Note("Upward notch position must be 0–120 UI px.")
        end
    elseif action:match("^safe split %d+$") then
        local gap=tonumber(action:match("^safe split (%d+)$"))
        if ChalkBox_BarNotchGapSet(gap) then
            Note("Manual notch gap: "..gap.." UI px (split at top).")
        else
            Note("Manual notch gap must be 40–400 UI px.")
        end
    elseif action:match("^safe %d+$") then
        local inset=tonumber(action:match("^safe (%d+)$"))
        if ChalkBox_BarTopInsetSet(inset) then
            Note("Top safe area: "..inset.." UI px (manual).")
        else
            Note("Top safe area must be 0–120 UI px.")
        end
    elseif action == "top" or action == "bottom" or action == "off" then
        db.bar = action
        PlaceBar()
        Note("Info bar: " .. action)
    elseif action == "reset" then
        ResetSession()
        Refresh()
        Note("XP/hour and net-gold session reset.")
    elseif action == "status" then
        local xpPerHour, eta, goldPerHour = GetRates()
        local chrome=type(ChalkBox_ScreenLayoutStatus)=="function"
            and ChalkBox_ScreenLayoutStatus() or {}
        Note("Bar=" .. db.bar .. ", layout=full-width / safe chrome shift" ..
            ", top inset=" .. tostring(ChalkBox_BarTopInsetStatus().effective) ..
            ", shifted=" .. tostring(chrome.moved or 0) ..
            ", protected=" .. tostring(chrome.skippedProtected or 0) ..
            ", pending=" .. tostring(reservation.pending or chrome.pending) ..
            ", XP/hr=" .. Number(xpPerHour) .. ", ETA=" .. Duration(eta) ..
            ", net gold/hr=" .. Money(goldPerHour, true))
    else
        Note("The Bar: /chalk bar top|bottom|off | reserve on/off | reset | status")
        Note("Stats: /chalk bar stat <module> on/off | stats all|balanced|minimal")
        Note("Layout: /chalk bar edit on/off | drag right-edge gold grips | layout reset")
        Note("Mac notch: /chalk bar safe auto | safe split 40-400 | safe up 0-120 | safe 0-120 (below)")
        Note("Icons: /chalk bar icons on|off.")
        Note("Widths: /chalk bar width <module> 60-280 | width <module> reset | move <module> <left|center|right>")
        Note("Text alignment: /chalk bar align <module> <left|center|right> | opacity 0-100")
        Note("Vendor value: /chalk bar stat bagvalue on | bagvalue junk|total|toggle")
        Note("Bank snapshot: /chalk bar stat bankvalue on/off | bank status for live diagnostics")
        Note("Repairs: /chalk bar stat repair on|off | repair status|reset. Right-click a module for a menu.")
    end
    end
end

local inventoryQueued=false
local function QueueInventoryRefresh()
    if inventoryQueued or not session.started then return end
    if C_Timer and type(C_Timer.After)=="function" then
        inventoryQueued=true
        C_Timer.After(0.25,function()
            inventoryQueued=false
            Refresh()
        end)
    else
        Refresh()
    end
end
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_XP_UPDATE")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:RegisterEvent("PLAYER_MONEY")
for _,event in ipairs({
    "BAG_UPDATE_DELAYED","GET_ITEM_INFO_RECEIVED","ITEM_DATA_LOAD_RESULT",
    "PLAYER_EQUIPMENT_CHANGED","UPDATE_INVENTORY_DURABILITY",
    "MERCHANT_SHOW","MERCHANT_UPDATE","MERCHANT_CLOSED",
    "UPDATE_EXHAUSTION","PLAYER_UPDATE_RESTING","UNIT_PET","UNIT_HEALTH",
    "UNIT_MAXHEALTH",
}) do events:RegisterEvent(event) end
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("UI_SCALE_CHANGED")
events:RegisterEvent("DISPLAY_SIZE_CHANGED")
events:RegisterEvent("NOTCHED_DISPLAY_MODE_CHANGED")
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name ~= addonName then return end
        if type(ChalkBoxDB) ~= "table" then ChalkBoxDB = {} end
        if ChalkBoxDB.bar ~= "top" and ChalkBoxDB.bar ~= "bottom"
            and ChalkBoxDB.bar ~= "off" then ChalkBoxDB.bar = "top" end
        db = ChalkBoxDB
        -- A saved legacy reservation is not safe: never re-enable it.
        -- Keep the Bar itself; leave Blizzard-owned UIParent unmodified.
        db.barReserve=false
        -- Previous beta's slider moved DOWN by mistake. Clear that one
        -- obsolete offset once so the corrected world-edge split is not
        -- silently held below the notch by a stale SavedVariable.
        if db.barNotchPositionV2~=true then
            db.barTopInset=nil
            db.barNotchRise=nil
            db.barNotchPositionV2=true
        end
        -- Older characters had a default of Total. Keep it if their Bar
        -- preferences already exist; only genuinely new Bars start on Junk.
        local freshBar=type(db.barStats)~="table"
        ConfigureStats()
        if db.barBagValueMode~="junk" and db.barBagValueMode~="total" then
            db.barBagValueMode=freshBar and "junk" or "total"
        end
        ApplyAppearance()
    elseif event == "PLAYER_ENTERING_WORLD" then
        if not session.started then ResetSession() end
        CreateBar()
        PlaceBar()
        Refresh()
        -- Character switches can finish restoring Blizzard's notch/UIParent
        -- geometry AFTER PLAYER_ENTERING_WORLD. A slider click fixes it
        -- because it calls PlaceBar again; repeat that same safe reanchor
        -- once the display layout settles, without changing any preferences.
        if C_Timer and type(C_Timer.After)=="function" then
            C_Timer.After(0.25,function() if bar then PlaceBar() end end)
            C_Timer.After(1.5,function() if bar then PlaceBar() end end)
        end
        if not ticker and C_Timer and C_Timer.NewTicker then
            ticker = C_Timer.NewTicker(5, Refresh)
        end
    elseif event=="PLAYER_REGEN_ENABLED" then
        if reservation.pending then PlaceBar() end
    elseif (event=="UNIT_HEALTH" or event=="UNIT_MAXHEALTH")
        and name~="pet" then
        -- Ignore the many party/target health events; only our Hunter pet matters.
        return
    elseif event=="UNIT_PET" and name~="player" then
        return
    elseif event=="UI_SCALE_CHANGED" or event=="DISPLAY_SIZE_CHANGED"
        or event=="NOTCHED_DISPLAY_MODE_CHANGED" then
        if bar then PlaceBar() end
    elseif event=="BAG_UPDATE_DELAYED" or event=="GET_ITEM_INFO_RECEIVED"
        or event=="ITEM_DATA_LOAD_RESULT" then
        -- These events arrive in bursts while Blizzard builds container frames.
        -- Refresh the bar once per burst instead of repeating bag valuation.
        QueueInventoryRefresh()
    else
        if not session.started then return end
        Refresh()
    end
end)
