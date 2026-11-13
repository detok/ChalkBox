-- ChalkBox TrailBar v1.1.1; reserved UIParent safe area and a physical-edge bar.
-- A single native, low-profile information strip. No pop-up windows.
-- Uses non-secret, ordinary player XP, money and elapsed online time only.

local addonName = ...
local db
local bar
local widgets = {}
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

local function Hint(widget, label, details)
    widget:EnableMouse(true)
    widget:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, db and db.bar == "bottom" and "ANCHOR_TOP" or "ANCHOR_BOTTOM")
        GameTooltip:ClearLines()
        GameTooltip:AddLine(label, 1, 0.82, 0.35)
        for _, line in ipairs(details()) do GameTooltip:AddLine(line, 0.9, 0.9, 0.9, true) end
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
end

-- Visible metrics are configurable, and the 18px bar automatically drops
-- lower-priority metrics at narrow widths. It NEVER overlaps or changes height.
local statDefaults={
    rate=true,eta=true,time=true,gold=true,
    bags=true,gear=true,rested=true,latency=false,pet=true,
    bagvalue=false, -- opt-in: preserves existing users' TrailBar layout
    repair=true, -- honest quote/estimate, not uncalibrated guesswork
}
local specs={
    level={width=98,group="left"},
    rate={width=104,group="left"},
    bags={width=90,group="left"},
    bagvalue={width=125,group="right"},
    repair={width=116,group="right"},
    gear={width=82,group="left"},
    eta={width=128,group="center"},
    rested={width=92,group="center"},
    pet={width=81,group="center"},
    time={width=85,group="right"},
    latency={width=86,group="right"},
    gold={width=182,group="right"},
}
local groups={
    left={"level","rate","bags","gear"},
    center={"eta","rested","pet"},
    right={"time","latency","bagvalue","repair","gold"},
}
local dropPriority={"latency","time","pet","eta","rate","rested","gear","bagvalue","bags","repair","gold"}
local displayed={}
local latest={}
local lastLayout=""
local editMode=false
local backgroundOpacity=70
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
    end
end
function ChalkBox_BarEditStatus() return editMode end
function ChalkBox_BarEditSet(on)
    if on and type(InCombatLockdown)=="function" and InCombatLockdown() then
        return false
    end
    editMode=(on==true)
    EditDecorations()
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
    local chosen={}
    for key in pairs(specs) do
        chosen[key]=StatEnabled(key) and (key=="level" or
            key=="rate" or key=="eta" or key=="time" or key=="gold" or latest[key]~=nil)
    end
    local function Measure(group)
        local total,count=0,0
        for _,key in ipairs(groups[group]) do
            if chosen[key] then total=total+specs[key].width+ (count>0 and 7 or 0);count=count+1 end
        end
        return total,count
    end
    local function Need()
        local l,lc=Measure("left")
        local c,cc=Measure("center")
        local r,rc=Measure("right")
        return l+c+r+24+(lc>0 and cc>0 and 10 or 0)
            +(rc>0 and (lc>0 or cc>0) and 10 or 0),l,c,r
    end
    local needed=Need()
    for _,key in ipairs(dropPriority) do
        if needed<=width then break end
        if chosen[key] then chosen[key]=false;needed=Need() end
    end
    -- At very low resolutions keep level first rather than overlap elements.
    if needed>width then
        for key in pairs(chosen) do chosen[key]=(key=="level") end
    end
    local signature=math.floor(width+0.5)..":"
    for _,group in ipairs({"left","center","right"}) do
        for _,key in ipairs(groups[group]) do
            if chosen[key] then signature=signature..key.."," end
        end
    end
    if signature==lastLayout then return end
    lastLayout=signature
    displayed={}
    for key,widget in pairs(widgets) do
        if chosen[key] then widget:Show();displayed[key]=true
        else widget:Hide() end
    end
    local _,leftWidth,centerWidth,rightWidth=Need()
    local function Arrange(group,start)
        local x=start
        for _,key in ipairs(groups[group]) do
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
                    widget:SetPoint("CENTER",bar,"LEFT",x+specs[key].width/2,0)
                else
                    widget:SetPoint("RIGHT",bar,"RIGHT",
                        x+specs[key].width-width,0)
                end
                x=x+specs[key].width+7
            end
        end
    end
    Arrange("left",12)
    local rightStart=width-12-rightWidth
    local centerStart=math.max(12+leftWidth+(leftWidth>0 and 10 or 0),
        math.min((width-centerWidth)/2,
            rightStart-centerWidth-(rightWidth>0 and 10 or 0)))
    Arrange("center",centerStart)
    Arrange("right",rightStart)
end

-- Right-click menus belong to The Bar. Prefer Blizzard_Menu, fall back to
-- the legacy dropdown on compatible clients. Edit Mode retains its old
-- right-click alignment gesture for existing users.
local menuNames={
    level="Level & XP",rate="XP per hour",bags="Bag slots",
    bagvalue="Bag resale",repair="Repair cost",gear="Durability",
    eta="Time to level",rested="Rested XP",pet="Hunter pet",
    time="Session timer",latency="Latency",gold="Gold",
}
local menuOrder={"rate","bags","bagvalue","repair","gear","eta",
    "rested","pet","time","latency","gold"}
local fallbackMenu
local function AddMenuEntry(list,label,callback,children)
    list[#list+1]={text=label,func=callback,children=children}
end
function ChalkBox_BarContextItems(key)
    if key and not specs[key] then return end
    local result={}
    if key then
        AddMenuEntry(result,menuNames[key] or key)
        if key~="level" then
            AddMenuEntry(result,(StatEnabled(key) and "Hide " or "Show ")..
                (menuNames[key] or key),function()
                ChalkBox_BarCommand("stat "..key.." "..
                    (StatEnabled(key) and "off" or "on"))
            end)
        end
        if key=="repair" then
            AddMenuEntry(result,"Repair learning status",function()
                ChalkBox_BarCommand("repair status")
            end)
        end
        if key=="bagvalue" then
            AddMenuEntry(result,"Switch to "..
                (ChalkBox_BarBagValueModeGet()=="junk" and "Total" or "Junk")..
                " value",function() ChalkBox_BarBagValueModeToggle() end)
        end
        local move={}
        for _,section in ipairs({"left","center","right"}) do
            local zone=section
            AddMenuEntry(move,string.upper(section:sub(1,1))..section:sub(2),
                function() ChalkBox_BarCommand("move "..key.." "..zone) end)
        end
        AddMenuEntry(result,"Move to",nil,move)
        local align={}
        for _,mode in ipairs({"left","center","right"}) do
            local target=mode
            AddMenuEntry(align,string.upper(mode:sub(1,1))..mode:sub(2),
                function() ChalkBox_BarCommand("align "..key.." "..target) end)
        end
        AddMenuEntry(result,"Text alignment",nil,align)
    else
        AddMenuEntry(result,"The Bar")
    end
    local modules={}
    for _,module in ipairs(menuOrder) do
        local selected=module
        AddMenuEntry(modules,(StatEnabled(selected) and "[x] " or "[ ] ")..
            menuNames[selected],function()
            ChalkBox_BarCommand("stat "..selected.." "..
                (StatEnabled(selected) and "off" or "on"))
        end)
    end
    AddMenuEntry(result,"Show / hide modules",nil,modules)
    AddMenuEntry(result,editMode and "Finish editing" or "Edit The Bar",
        function() ChalkBox_BarCommand(editMode and "edit off" or "edit on") end)
    AddMenuEntry(result,"Reset module positions",
        function() ChalkBox_BarCommand("layout reset") end)
    local positions={}
    AddMenuEntry(positions,"Top",function() ChalkBox_BarCommand("top") end)
    AddMenuEntry(positions,"Bottom",function() ChalkBox_BarCommand("bottom") end)
    AddMenuEntry(positions,"Hide The Bar",function() ChalkBox_BarCommand("off") end)
    AddMenuEntry(result,"Bar position",nil,positions)
    AddMenuEntry(result,"Module settings...",function()
        if type(ChalkBox_OpenSettings)=="function" then
            ChalkBox_OpenSettings("barstats")
        end
    end)
    AddMenuEntry(result,"Appearance & layout...",function()
        if type(ChalkBox_OpenSettings)=="function" then
            ChalkBox_OpenSettings("barappearance")
        end
    end)
    return result
end
local function BuildNativeMenu(root,items)
    for _,item in ipairs(items) do
        if item.children then
            local submenu=root:CreateButton(item.text)
            if submenu and submenu.CreateButton then
                BuildNativeMenu(submenu,item.children)
            end
        elseif item.func then
            root:CreateButton(item.text,function() item.func() end)
        elseif type(root.CreateTitle)=="function" then
            root:CreateTitle(item.text)
        end
    end
end
local function BuildLegacyMenu(items)
    local output={}
    for _,item in ipairs(items) do
        if item.children then
            output[#output+1]={text=item.text,hasArrow=true,
                notCheckable=true,menuList=BuildLegacyMenu(item.children)}
        elseif item.func then
            output[#output+1]={text=item.text,func=item.func,notCheckable=true}
        else
            output[#output+1]={text=item.text,isTitle=true,notCheckable=true}
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
    bar:SetFrameStrata("LOW")
    if bar.EnableMouse then bar:EnableMouse(true) end
    bar:SetScript("OnMouseUp",function(self,button)
        if button=="RightButton" and not editMode then
            ChalkBox_BarOpenMenu(nil,self)
        end
    end)
    local background=bar:CreateTexture(nil,"BACKGROUND")
    background:SetAllPoints(bar)
    bar.background=background
    ApplyAppearance()
    local progress=bar:CreateTexture(nil,"ARTWORK")
    progress:SetPoint("BOTTOMLEFT",bar,"BOTTOMLEFT",0,0)
    progress:SetHeight(1)
    progress:SetColorTexture(0.19,0.64,0.93,0.85)
    bar.xpProgress=progress
    local blocks={
        {"level","Level & XP",function()
            return {"XP: "..tostring(session.xp or "--").." / "..tostring(session.maxXP or "--"),
                "Level: "..tostring(session.level or "--")}
        end},
        {"rate","Session XP per hour",function()
            return {"XP gained this session: "..Number(session.xpGained),
                "Average XP/hour includes idle time since login or reset."}
        end},
        {"bagvalue","Bag vendor resale value",function()
            local v=latest.bagvalue
            if not v then return {"Bag valuation unavailable in this client."} end
            local junk=(v.junkComplete and "" or "At least ")..Coins(v.junkCopper)
            local total=(v.totalComplete and "" or "At least ")..Coins(v.totalCopper)
            local detail={}
            detail[#detail+1]="Junk (gray/poor-quality items): "..junk
            detail[#detail+1]="All equipped bag contents: "..total
            if v.totalUnknown>0 or v.junkUnknown>0 then
                detail[#detail+1]=("Unresolved slots: %d total, %d junk."):format(
                    v.totalUnknown,v.junkUnknown)
            end
            detail[#detail+1]="Stacks counted at actual vendor sell price, not auction price."
            detail[#detail+1]="Excludes bank, worn equipment and your current gold."
            detail[#detail+1]="Left-click to flip Junk / Total; no items are sold."
            return detail
        end},
        {"repair","Repair cost",function()
            local r=latest.repair
            if not r then return {"Current repair information unavailable."} end
            local lines={}
            if r.state=="exact" then
                lines[#lines+1]="Exact repair-all quote at this merchant: "..
                    Coins(r.copper)
            elseif r.state=="estimate" then
                lines[#lines+1]="Learned estimate: about "..Coins(r.copper)
                if r.source=="same-gear" then
                    lines[#lines+1]="Based on actual quotes for this equipment."
                elseif r.source=="similar-gear" then
                    lines[#lines+1]="Based on quotes from similar equipment."
                else
                    lines[#lines+1]="Using your previous 1.9.2 calibration."
                end
                lines[#lines+1]="Confidence: "..(r.confidence or "early")..
                    ". Still approximate."
            elseif r.state=="no-damage" then
                lines[#lines+1]="No damage detected on equipped repairable gear."
            else
                lines[#lines+1]="No reliable estimate yet. Visit a repair merchant"
                lines[#lines+1]="with damaged equipment to teach the estimator."
            end
            lines[#lines+1]="Learned from "..tostring(r.samples or 0)..
                " distinct merchant quote(s)."
            if type(r.lastError)=="number" then
                lines[#lines+1]="Last estimate vs actual vendor quote: "..
                    tostring(r.lastError).."% difference."
            end
            lines[#lines+1]="Equipped durability lost: "..
                (r.missing or "--").." / "..(r.max or "--").."."
            lines[#lines+1]="Estimates use equipped wear; vendor bills also"
            lines[#lines+1]="include damaged items in bags and may vary by discounts."
            lines[#lines+1]="No auto repair or payment is performed."
            lines[#lines+1]="/chalk bar repair status | repair reset"
            return lines
        end},
        {"bags","Free bag slots",function()
            local a=latest.bags
            if not a then return {"Inventory slot data unavailable."} end
            return {a.free.." free of "..a.total.." equipped bag slots.",
                a.general.." general free, "..a.special.." profession-specialized free."..
                ((a.unknown or 0)>0 and (" "..a.unknown.." unclassified free.") or ""),
                "Specialty slots may only accept their matching items."}
        end},
        {"gear","Equipped item durability",function()
            local a=latest.gear
            if not a then return {"Durability unavailable."} end
            return {"Weighted condition: "..a.percent.."% across "..a.items.." repairable items.",
                "Lowest equipped item: "..a.worst.."%.",
                "Only equipment with durability contributes."}
        end},
        {"eta","Time to next level",function()
            return {"Estimated from XP/hour; requires earned session XP.",
                "Use /chalk bar reset to start a fresh session."}
        end},
        {"rested","Rested experience",function()
            local a=latest.rested
            if not a then return {"Rested XP data unavailable."} end
            return {Number(a.xp).." bonus XP, "..a.percent.."% of one level.",
                "Rested XP is separate from the Camp Benefits aura."}
        end},
        {"pet","Hunter pet status",function()
            local a=latest.pet
            if not a then return {"Hunter pet data unavailable."} end
            if a.state=="none" then return {"No active pet."} end
            if a.state=="protected" or a.state=="unknown" then
                return {"Pet health protected or unavailable in this client."}
            end
            return {"Active pet health: "..a.percent.."%."}
        end},
        {"time","Session time",function()
            return {"Online time since login or last session reset."}
        end},
        {"latency","Home / world latency",function()
            local a=latest.latency
            if not a then return {"Latency API unavailable."} end
            return {"Home: "..a.home.." ms", "World: "..a.world.." ms",
                "Current network latency is not your frame rate."}
        end},
        {"gold","Gold & net earnings",function()
            local _,_,perHour=GetRates()
            return {"Net gold/hour: "..Money(perHour,true),
                "Current gold and net change since login or reset.",
                "Spending can make net gold negative; not gross loot value."}
        end},
    }
    for _,item in ipairs(blocks) do
        local key,name,details=unpack(item)
        local widget=CreateFrame("Frame",nil,bar)
        widget:SetSize(specs[key].width,16)
        local font=widget:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        font:SetAllPoints(widget)
        font:SetJustifyH(key=="gold" and "RIGHT" or
            (specs[key].group=="center" and "CENTER" or "LEFT"))
        widget.text=font
        widgets[key]=widget
        local grab=widget:CreateTexture(nil,"BACKGROUND")
        grab:SetAllPoints(widget)
        grab:SetColorTexture(0.45,0.32,0.12,0)
        widget.editBackground=grab
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
            elseif button=="LeftButton" and not editMode and key=="bagvalue" then
                ChalkBox_BarBagValueModeToggle()
            end
        end)
        Hint(widget,name,details)
    end
    bar:SetScript("OnSizeChanged",function() Reflow() end)
    EditDecorations()
end

-- A Titan-style screen reservation, not a whitelist of named UI frames.
-- UIParent is the root for normal Blizzard UI anchors. Insets leave a genuine
-- 18px top/bottom strip, while WorldFrame continues drawing behind the UI.
-- This cannot promise to move manually placed or WorldFrame-anchored addons.
local BAR_HEIGHT = 18
local reservation = {
    active=false, original=nil, position=nil, pending=false, issue=nil
}

local function InCombat()
    return type(InCombatLockdown)=="function" and InCombatLockdown()
end

local function InsetStillPresent(position)
    if not UIParent or not UIParent.GetNumPoints or not UIParent.GetPoint then
        return false
    end
    local top,bottom
    local count=UIParent:GetNumPoints()
    if not Public(count) or type(count)~="number" then return false end
    for i=1,count do
        local point,_,_,x,y=UIParent:GetPoint(i)
        if point=="TOPLEFT" then top=y end
        if point=="BOTTOMRIGHT" then bottom=y end
    end
    local expectedTop=position=="top" and -BAR_HEIGHT or 0
    local expectedBottom=position=="bottom" and BAR_HEIGHT or 0
    return top==expectedTop and bottom==expectedBottom
end

local function CaptureRoot()
    if not UIParent or type(UIParent.GetNumPoints)~="function"
        or type(UIParent.GetPoint)~="function" then return end
    local count=UIParent:GetNumPoints()
    if not Public(count) or type(count)~="number" or count<0 or count>8 then return end
    local saved={anchors={}, width=UIParent.GetWidth and UIParent:GetWidth(),
        height=UIParent.GetHeight and UIParent:GetHeight()}
    for i=1,count do
        local point,relative,relativePoint,x,y=UIParent:GetPoint(i)
        if not Public(point) or type(point)~="string" then return end
        -- Named fields preserve a nil relative frame: array/unpack can drop nil.
        saved.anchors[#saved.anchors+1]={
            point=point,relative=relative,relativePoint=relativePoint,
            x=x or 0,y=y or 0
        }
    end
    return saved
end

local function RestoreRoot()
    if not reservation.active then return true end
    if InCombat() then reservation.pending=true;return false end
    local original=reservation.original
    if not original or not UIParent or not UIParent.ClearAllPoints then return false end
    local ok=pcall(function()
        UIParent:ClearAllPoints()
        if #original.anchors>0 then
            for _,a in ipairs(original.anchors) do
                UIParent:SetPoint(a.point,a.relative,a.relativePoint,a.x,a.y)
            end
        elseif UIParent.SetAllPoints then
            -- UIParent without explicit points was the full-screen root.
            UIParent:SetAllPoints()
        end
        if #original.anchors<=1 and UIParent.SetSize
            and Public(original.width) and Public(original.height) then
            UIParent:SetSize(original.width,original.height)
        end
    end)
    if ok then
        reservation.active=false
        reservation.position=nil
        reservation.original=nil
        reservation.issue=nil
        return true
    end
    reservation.issue="Could not restore the original screen anchors."
    return false
end

local function ReserveRoot()
    if InCombat() then reservation.pending=true;return false end
    local want=(db and db.barReserve and db.bar~="off") and db.bar or nil
    if reservation.active and reservation.position==want then
        if InsetStillPresent(want) then
            reservation.pending=false
            return true
        end
        -- Blizzard or another addon rebuilt UIParent after a display/UI scale
        -- change. The new anchors are the new baseline; don't restore stale ones.
        reservation.active=false
        reservation.position=nil
        reservation.original=nil
    end
    if not RestoreRoot() then return false end
    if not want then reservation.pending=false;reservation.issue=nil;return true end
    if not UIParent or not UIParent.ClearAllPoints
        or not UIParent.SetPoint then
        reservation.issue="This client does not allow UIParent screen resizing."
        return false
    end
    local original=CaptureRoot()
    if not original then
        reservation.issue="Unable to read this client's original UI layout."
        return false
    end
    local ok=pcall(function()
        UIParent:ClearAllPoints()
        -- Explicit nil means the physical screen, not the resized UIParent.
        UIParent:SetPoint("TOPLEFT",nil,"TOPLEFT",0,
            want=="top" and -BAR_HEIGHT or 0)
        UIParent:SetPoint("BOTTOMRIGHT",nil,"BOTTOMRIGHT",0,
            want=="bottom" and BAR_HEIGHT or 0)
    end)
    if not ok then
        reservation.original=original
        reservation.active=true
        RestoreRoot()
        reservation.issue="Screen inset was rejected; TrailBar remains in overlay mode."
        return false
    end
    reservation.original=original
    reservation.active=true
    reservation.position=want
    reservation.pending=false
    reservation.issue=nil
    return true
end

local function PlaceBar()
    if not bar or not db then return end
    -- If the user changes bar position in combat, leave the existing geometry
    -- in place until Blizzard permits editing the root frame again.
    local inCombat=InCombat()
    local pendingChange=inCombat and reservation.active
        and (db.bar~=reservation.position or not db.barReserve)
    if not pendingChange then ReserveRoot() else reservation.pending=true end
    if pendingChange and db.bar~="off" then return end

    bar:ClearAllPoints()
    if reservation.active and reservation.position==db.bar and db.barReserve then
        if db.bar=="top" then
            bar:SetPoint("BOTTOMLEFT",UIParent,"TOPLEFT",0,0)
            bar:SetPoint("BOTTOMRIGHT",UIParent,"TOPRIGHT",0,0)
        else
            bar:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",0,0)
            bar:SetPoint("TOPRIGHT",UIParent,"BOTTOMRIGHT",0,0)
        end
    elseif db.bar=="bottom" then
        bar:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",0,0)
        bar:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",0,0)
    else
        bar:SetPoint("TOPLEFT",UIParent,"TOPLEFT",0,0)
        bar:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",0,0)
    end
    if db.bar=="off" then bar:Hide() else bar:Show() end
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
            bar.xpProgress:SetWidth(math.max(0.1,width*math.min(
                1,session.xp/session.maxXP)))
            bar.xpProgress:Show()
        end
    elseif bar.xpProgress then bar.xpProgress:Hide() end
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
    elseif action=="edit" or action=="edit toggle" or action=="edit on"
        or action=="edit off" then
        local on=action=="edit on" or
            ((action=="edit" or action=="edit toggle") and not editMode)
        if ChalkBox_BarEditSet(on) then
            Note("TrailBar edit "..(on and "ON: drag stats between thirds and reorder; right-click to cycle text alignment." or "OFF: layout saved per character."))
        else Note("Cannot edit TrailBar while in combat.") end
    elseif action=="layout reset" then
        if type(ChalkBox_BarLayoutReset)=="function" then
            ChalkBox_BarLayoutReset()
            lastLayout=""
            Reflow()
        end
        Note("TrailBar positions and text alignment reset for this character.")
    elseif action=="layout" or action=="layout status" then
        Note(type(ChalkBox_BarLayoutDescription)=="function"
            and ChalkBox_BarLayoutDescription() or "Layout module unavailable.")
    elseif module and (section=="left" or section=="center" or section=="right") then
        if type(ChalkBox_BarLayoutMove)=="function" and
            ChalkBox_BarLayoutMove(module,section,tonumber(index)) then
            lastLayout=""
            Reflow()
            Note(module.." moved to "..section.." and saved per character.")
        else Note("Unknown TrailBar module or section.") end
    elseif aligned and (mode=="left" or mode=="center" or mode=="right") then
        if type(ChalkBox_BarLayoutAlign)=="function" and
            ChalkBox_BarLayoutAlign(aligned,mode) then
            lastLayout=""
            Reflow()
            Note(aligned.." text aligned "..mode..".")
        else Note("Unknown TrailBar module.") end
    else
        local stat,choice=action:match("^stat%s+(%a+)%s+(%a+)$")
    if action=="repair status" then
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
        Note("TrailBar "..stat.." "..string.upper(choice)..
            ". Narrow displays may hide low-priority modules.")
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
        db.barReserve=(action=="reserve on" or action=="dock on")
        PlaceBar()
        Note("Reserve 18px for TrailBar: " .. (db.barReserve and "ON" or "OFF") ..
            (reservation.pending and " (applies after combat)" or "") ..
            (reservation.issue and " - " .. reservation.issue or ""))
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
        local rootHeight=UIParent and UIParent.GetHeight and UIParent:GetHeight()
        local baselineHeight=reservation.original and reservation.original.height
        local delta=(type(baselineHeight)=="number" and type(rootHeight)=="number")
            and (baselineHeight-rootHeight) or nil
        Note("Bar=" .. db.bar .. ", reserve=" .. tostring(db.barReserve) ..
            ", active=" .. tostring(reservation.active) ..
            ", applied=" .. tostring(reservation.position) ..
            ", pending=" .. tostring(reservation.pending) ..
            ", screen space=" .. (delta and ("%.0f"):format(delta) or "unavailable") .. "px" ..
            (reservation.issue and ", issue=" .. reservation.issue or "") ..
            ", XP/hr=" .. Number(xpPerHour) .. ", ETA=" .. Duration(eta) ..
            ", net gold/hr=" .. Money(goldPerHour, true))
    else
        Note("The Bar: /chalk bar top|bottom|off | reserve on/off | reset | status")
        Note("Stats: /chalk bar stat <module> on/off | stats all|balanced|minimal")
        Note("Layout: /chalk bar edit on/off | layout reset | move <module> <left|center|right> [index]")
        Note("Text alignment: /chalk bar align <module> <left|center|right> | opacity 0-100")
        Note("Vendor value: /chalk bar stat bagvalue on | bagvalue junk|total|toggle")
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
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name ~= addonName then return end
        if type(ChalkBoxDB) ~= "table" then ChalkBoxDB = {} end
        if ChalkBoxDB.bar ~= "top" and ChalkBoxDB.bar ~= "bottom"
            and ChalkBoxDB.bar ~= "off" then ChalkBoxDB.bar = "top" end
        db = ChalkBoxDB
        -- The previous frame-whitelist docking was ineffective. This setting
        -- uses a real UIParent safe-area inset and defaults ON for all users.
        if db.barReserve==nil then db.barReserve=true end
        ConfigureStats()
        if db.barBagValueMode~="junk" then db.barBagValueMode="total" end
        ApplyAppearance()
    elseif event == "PLAYER_ENTERING_WORLD" then
        if not session.started then ResetSession() end
        CreateBar()
        PlaceBar()
        Refresh()
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
    elseif event=="UI_SCALE_CHANGED" or event=="DISPLAY_SIZE_CHANGED" then
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
