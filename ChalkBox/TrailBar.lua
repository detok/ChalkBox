-- ChalkBox TrailBar v1.1.1; reserved UIParent safe area and a physical-edge bar.
-- A single native, low-profile information strip. No pop-up windows.
-- Uses non-secret, ordinary player XP, money and elapsed online time only.

local addonName = ...
local db
local bar
local widgets = {}
local ticker
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
}
local specs={
    level={width=98,group="left"},
    rate={width=104,group="left"},
    bags={width=90,group="left"},
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
    right={"time","latency","gold"},
}
local dropPriority={"latency","time","pet","eta","rate","rested","gear","bags","gold"}
local displayed={}
local latest={}
local lastLayout=""
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

local function CreateBar()
    if bar or not UIParent then return end
    bar=CreateFrame("Frame","ChalkBoxInfoBar",UIParent)
    bar:SetHeight(18)
    bar:SetFrameStrata("LOW")
    local background=bar:CreateTexture(nil,"BACKGROUND")
    background:SetAllPoints(bar)
    background:SetColorTexture(0.06,0.08,0.12,0.70)
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
        Hint(widget,name,details)
    end
    bar:SetScript("OnSizeChanged",function() Reflow() end)
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

local function Refresh()
    if not db or not bar then return end
    CaptureXP()
    CaptureMoney()
    local xpPerHour,eta,goldPerHour,elapsed=GetRates()
    local stats={}
    if type(ChalkBox_BarReadStats)=="function" then
        local ok,value=pcall(ChalkBox_BarReadStats,session.maxXP)
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
    local stat,choice=action:match("^stat%s+(%a+)%s+(%a+)$")
    if stat and specs[stat] and stat~="level"
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
        Note("TrailBar: /chalk bar top|bottom|off | reserve on/off | reset | status")
        Note("Stats: /chalk bar stat bags|gear|rested|latency|pet|rate|eta|time|gold on/off")
        Note("Presets: /chalk bar stats all|balanced|minimal | stats")
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_XP_UPDATE")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:RegisterEvent("PLAYER_MONEY")
for _,event in ipairs({
    "BAG_UPDATE_DELAYED","PLAYER_EQUIPMENT_CHANGED","UPDATE_INVENTORY_DURABILITY",
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
    else
        if not session.started then return end
        Refresh()
    end
end)
