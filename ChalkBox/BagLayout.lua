-- ChalkBox Bag Layout: signed vertical correction for Blizzard's separate bags.
-- Changes only Blizzard's first column anchor, never item buttons or sorting.
-- The stock layout is re-run before each adjustment so offsets do not stack.
local addonName = ...
local db
local hooked = false
local bankOpen = false
local pending = false
local lastApplied = 0

local function Safe(value)
    return value ~= nil and (type(issecretvalue) ~= "function" or not issecretvalue(value))
end

local function InCombat()
    return type(InCombatLockdown) == "function" and InCombatLockdown()
end

local function BankVisible()
    if bankOpen then return true end
    local frame=BankFrame
    if frame and type(frame.IsShown)=="function" then
        local ok,shown=pcall(frame.IsShown,frame)
        if ok and Safe(shown) and shown then return true end
    end
    return false
end

local function PlayerBag(frame)
    if not frame or type(frame.GetBagID)~="function" then return true end
    local ok,id=pcall(frame.GetBagID,frame)
    if not ok or not Safe(id) or type(id)~="number" then return false end
    local backpack=type(BACKPACK_CONTAINER)=="number" and
        BACKPACK_CONTAINER or 0
    local max=type(NUM_BAG_SLOTS)=="number" and NUM_BAG_SLOTS or 4
    return id>=backpack and id<=max
end

local function Offset()
    local value = db and tonumber(db.bagOffsetY) or 0
    if not value or not Safe(value) or value~=value then return 0 end
    return math.max(-120,math.min(120,math.floor(value+0.5)))
end

local function ShownFirstBag()
    local manager = ContainerFrameSettingsManager
    if type(manager) == "table" and type(manager.GetBagsShown) == "function" then
        if type(manager.IsUsingCombinedBags) == "function" then
            local ok,combined=pcall(manager.IsUsingCombinedBags,manager)
            if not ok or combined then return end
        end
        local ok,bags = pcall(manager.GetBagsShown,manager)
        if ok and type(bags) == "table" then return bags[1] end
        return
    end
    -- Older Blizzard bag layout: first of the open frame names.
    local root = ContainerFrame1
    if root and type(root.bags) == "table" then
        return _G[root.bags[1]]
    end
end

local function ApplyOffset()
    if not db then return end
    -- First-time bank opening can initialize protected container anchors.
    -- Never move bag frames as a side effect of that bank UI setup.
    if InCombat() or BankVisible() then
        if Offset()~=0 then pending=true end
        return
    end
    local shift = Offset()
    lastApplied = 0
    pending = false
    if shift == 0 then return end
    local frame = ShownFirstBag()
    if not PlayerBag(frame) or type(frame.GetPoint)~="function"
        or type(frame.GetParent)~="function"
        or type(frame.ClearAllPoints)~="function"
        or type(frame.SetPoint)~="function" then return end
    if type(frame.IsShown)=="function" and not frame:IsShown() then return end
    local ok,point,relative,relativePoint,x,y = pcall(frame.GetPoint,frame,1)
    if not ok or not Safe(point) or not Safe(x) or not Safe(y)
        or point~="BOTTOMRIGHT" or relative~=frame:GetParent()
        or relativePoint~="BOTTOMRIGHT" or type(x)~="number"
        or type(y)~="number" then
        return -- Another bag mover or a changed Blizzard layout owns this anchor.
    end
    if pcall(function()
        frame:ClearAllPoints()
        frame:SetPoint("BOTTOMRIGHT",relative,"BOTTOMRIGHT",x,y-shift)
    end) then
        lastApplied=shift
    end
end

local function InstallHook()
    if hooked or BankVisible() or type(hooksecurefunc)~="function"
        or type(UpdateContainerFrameAnchors)~="function" then return end
    hooked = pcall(hooksecurefunc,"UpdateContainerFrameAnchors",ApplyOffset)
end

local function RefreshLayout()
    InstallHook()
    if InCombat() or BankVisible() then pending=true;return end
    if type(UpdateContainerFrameAnchors)=="function" then
        local ok = pcall(UpdateContainerFrameAnchors)
        if ok then
            if not hooked then ApplyOffset() end
            return
        end
    end
    pending = true -- No Blizzard layout API: leave the original bags untouched.
end

function ChalkBox_BagOffsetSet(value)
    if not db or not Safe(value) or type(value)~="number" then return end
    db.bagOffsetY=math.max(-120,math.min(120,math.floor(value+0.5)))
    RefreshLayout()
end

function ChalkBox_BagStatus()
    return {offset=Offset(),hooked=hooked,pending=pending,applied=lastApplied}
end

local function Note(message)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff55ccaaChalkBox|r "..message)
    end
end

function ChalkBox_BagCommand(command)
    local input=(command or ""):match("^%s*(.-)%s*$")
    local raw=input:match("^offset%s+([%+%-]?%d+)$") or
        input:match("^([%+%-]?%d+)$")
    local value=tonumber(raw)
    if value then
        ChalkBox_BagOffsetSet(value)
        local offset=Offset()
        Note("Separate bags: "..math.abs(offset).."px "..
            (offset>0 and "downward" or (offset<0 and "upward" or "(Blizzard default)"))..
            (pending and " (will update after combat/layout availability)" or "")..".")
    elseif input=="reset" then
        ChalkBox_BagOffsetSet(0)
        Note("Separate bags: Blizzard default position restored.")
    elseif input=="status" then
        Note("Separate bag offset: "..Offset().."px, layout hook="..tostring(hooked)..
            ", applied="..tostring(lastApplied).."px, pending="..tostring(pending)..".")
    else
        Note("Separate bag layout: /chalk bags offset -120..120 (negative = up, positive = down) | reset | status.")
    end
end

local events=CreateFrame("Frame")
for _,event in ipairs({"ADDON_LOADED","PLAYER_LOGIN","PLAYER_ENTERING_WORLD",
    "PLAYER_REGEN_ENABLED","BANKFRAME_OPENED","BANKFRAME_CLOSED"}) do
    pcall(events.RegisterEvent,events,event)
end
events:SetScript("OnEvent",function(_,event,name)
    if event=="BANKFRAME_OPENED" then
        bankOpen=true
        return
    elseif event=="BANKFRAME_CLOSED" then
        bankOpen=false
        if db and Offset()~=0 then
            -- BankFrame may still be visible at the exact close-event edge.
            -- A deferred pass runs after Blizzard finishes its panel changes.
            if C_Timer and type(C_Timer.After)=="function" then
                C_Timer.After(0.2,function()
                    if not BankVisible() then RefreshLayout() end
                end)
            elseif not BankVisible() then
                RefreshLayout()
            end
        end
        return
    end
    if event=="ADDON_LOADED" then
        if name==addonName then
            if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
            db=ChalkBoxDB
            if type(db.bagOffsetY)~="number" or not Safe(db.bagOffsetY) then
                db.bagOffsetY=0
            end
        end
        InstallHook() -- Blizzard bag UI may load after ChalkBox.
    elseif event=="PLAYER_LOGIN" or event=="PLAYER_ENTERING_WORLD" then
        InstallHook()
        if db and Offset()>0 then RefreshLayout() end
    elseif event=="PLAYER_REGEN_ENABLED" and pending then
        RefreshLayout()
    end
end)
