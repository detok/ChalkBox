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

local function CreateBar()
    if bar or not UIParent then return end
    bar = CreateFrame("Frame", "ChalkBoxInfoBar", UIParent)
    bar:SetHeight(18)
    bar:SetFrameStrata("LOW")
    local background = bar:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(bar)
    background:SetColorTexture(0.06, 0.08, 0.12, 0.70)
    local progress = bar:CreateTexture(nil, "ARTWORK")
    progress:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
    progress:SetHeight(1)
    progress:SetColorTexture(0.19, 0.64, 0.93, 0.85)
    bar.xpProgress = progress

    -- Layout is anchored in three independent groups, not absolute pixels.
    -- The measured width determines which optional elements disappear.
    local blocks = {
        {"level", "LEFT", "LEFT", 12, 120, "LEFT", "Level & XP", function()
            return {"XP: " .. tostring(session.xp or "--") .. " / " .. tostring(session.maxXP or "--"),
                "Level: " .. tostring(session.level or "--")}
        end},
        {"rate", "LEFT", "LEFT", 140, 120, "LEFT", "Session XP per hour", function()
            return {"XP gained this session: " .. Number(session.xpGained),
                "Average since login or last reset (including idle time)."}
        end},
        {"eta", "CENTER", "CENTER", -85, 165, "CENTER", "Time to next level", function()
            return {"Estimated from XP/hour; requires earned session XP.",
                "Use /chalk bar reset to start a fresh session."}
        end},
        {"time", "CENTER", "CENTER", 105, 110, "CENTER", "Session time", function()
            return {"Online time since login or reset."}
        end},
        {"gold", "RIGHT", "RIGHT", -12, 235, "RIGHT", "Gold & net earnings", function()
            local _,_,perHour=GetRates()
            return {"Net gold/hour: " .. Money(perHour,true),
                "Current gold and net change since login or reset.",
                "Spending can make net gold negative; not gross loot value."}
        end},
    }
    for _,spec in ipairs(blocks) do
        local key,point,relative,offset,width,justify,name,details = unpack(spec)
        local widget=CreateFrame("Frame",nil,bar)
        widget:SetPoint(point,bar,relative,offset,0)
        widget:SetSize(width,16)
        local font=widget:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        font:SetAllPoints(widget)
        font:SetJustifyH(justify)
        widget.text=font
        widgets[key]=widget
        Hint(widget,name,details)
    end
    bar:SetScript("OnSizeChanged", function(self)
        local width=self:GetWidth()
        if not Public(width) or type(width)~="number" then return end
        if widgets.time then
            if width>=1070 then widgets.time:Show() else widgets.time:Hide() end
        end
        if widgets.eta then
            if width>=780 then widgets.eta:Show() else widgets.eta:Hide() end
        end
        if widgets.rate then
            if width>=640 then widgets.rate:Show() else widgets.rate:Hide() end
        end
        if widgets.gold then
            if width>=410 then widgets.gold:Show() else widgets.gold:Hide() end
        end
    end)

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
    local xpPerHour, eta, goldPerHour, elapsed = GetRates()
    local xpText = "Level --"
    if session.level then
        if session.maxXP and session.maxXP > 0 then
            xpText = ("Lv %d  %.1f%%"):format(session.level, 100 * session.xp / session.maxXP)
        else
            xpText = ("Lv %d  MAX"):format(session.level)
        end
    end
    widgets.level.text:SetText(xpText)
    widgets.rate.text:SetText("XP/h " .. Number(xpPerHour))
    widgets.eta.text:SetText("To level " .. (session.maxXP and session.maxXP > 0 and Duration(eta) or "--"))
    widgets.gold.text:SetText("Gold " .. Money(session.money) .. " (net " ..
        Money(session.money and session.goldStart and session.money - session.goldStart or nil, true) .. ")")
    widgets.time.text:SetText("Time " .. Duration(elapsed))
    if session.maxXP and session.maxXP > 0 and bar.xpProgress then
        local width = bar:GetWidth()
        if Public(width) and type(width) == "number" then
            bar.xpProgress:SetWidth(math.max(0.1, width * math.min(1, session.xp / session.maxXP)))
            bar.xpProgress:Show()
        end
    elseif bar.xpProgress then
        bar.xpProgress:Hide()
    end
    -- The tooltip is the detail layer, while the bar stays uncluttered.
    -- Keep detailed net gold/hour in the tooltip instead of widening the bar.
end

local function Note(message)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff55ccaaChalkBox|r " .. message)
    end
end

function ChalkBox_BarCommand(message)
    if not db then return end
    local action = string.lower((message or ""):match("^%s*(.-)%s*$") or "")
    if action == "reserve on" or action == "reserve off"
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
        Note("TrailBar: /chalk bar top | bottom | off | reserve on/off | reset | status")
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_XP_UPDATE")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:RegisterEvent("PLAYER_MONEY")
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
    elseif event=="UI_SCALE_CHANGED" or event=="DISPLAY_SIZE_CHANGED" then
        if bar then PlaceBar() end
    else
        if not session.started then return end
        Refresh()
    end
end)
