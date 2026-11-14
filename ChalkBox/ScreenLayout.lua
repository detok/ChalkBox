-- ChalkBox screen chrome spacing.
-- A small top-frame adjuster inspired by the *behavior* of Titan-style panels.
-- Never resize/reanchor UIParent, the world frame, action buttons, bags,
-- or protected / user-placed frames.
local addonName=...
local db
local BAR_HEIGHT=18
local tracked={}
local pending=false
local skippedProtected=0
local skippedCustom=0
local lastReason="not initialized"
local targets={"MinimapCluster","BuffFrame","PlayerFrame",
    "TargetFrame","TicketStatusFrame","WorldStateAlwaysUpFrame"}

local function Safe(v)
    return v~=nil and (type(issecretvalue)~="function"
        or not issecretvalue(v))
end
local function Combat()
    return type(InCombatLockdown)=="function" and InCombatLockdown()
end
local function Valid(anchor)
    return anchor and type(anchor.point)=="string" and
        type(anchor.x)=="number" and type(anchor.y)=="number"
end
local function Same(a,b)
    return Valid(a) and Valid(b) and a.point==b.point
        and a.relative==b.relative and a.relativePoint==b.relativePoint
        and a.x==b.x and a.y==b.y
end
local function ReadAnchor(frame)
    if not frame or type(frame.GetNumPoints)~="function"
        or type(frame.GetPoint)~="function" then return nil end
    local ok,count=pcall(frame.GetNumPoints,frame)
    if not ok or not Safe(count) or count~=1 then return nil end
    local success,point,relative,relativePoint,x,y=
        pcall(frame.GetPoint,frame,1)
    if not success or not Safe(point) or
        (relative~=nil and not Safe(relative)) or
        (relativePoint~=nil and not Safe(relativePoint))
        or not Safe(x) or not Safe(y) then return nil end
    if relative~=UIParent and relative~="UIParent" and relative~=nil then
        return nil -- preserve addon-relative and Blizzard-managed anchors
    end
    if point~="TOP" and point~="TOPLEFT" and point~="TOPRIGHT" then
        return nil
    end
    local result={point=point,relative=relative,
        relativePoint=relativePoint,x=x,y=y}
    return Valid(result) and result or nil
end
local function IsSafeFrame(frame)
    if not frame or type(frame.ClearAllPoints)~="function"
        or type(frame.SetPoint)~="function" then return false,"unsupported" end
    if type(frame.IsProtected)~="function" then
        return false,"unknown protection"
    end
    local ok,protected=pcall(frame.IsProtected,frame)
    if not ok or not Safe(protected) or protected then
        return false,"protected"
    end
    if type(frame.IsUserPlaced)=="function" then
        local status,userPlaced=pcall(frame.IsUserPlaced,frame)
        if not status or not Safe(userPlaced) or userPlaced then
            return false,"custom"
        end
    end
    return true
end
local function Position(frame,anchor)
    if not Valid(anchor) then return false end
    local original=ReadAnchor(frame)
    local success=pcall(function()
        frame:ClearAllPoints()
        frame:SetPoint(anchor.point,anchor.relative,anchor.relativePoint,
            anchor.x,anchor.y)
    end)
    if not success and original then
        -- A partial frame move must never leave an unanchored Blizzard widget.
        pcall(function()
            frame:ClearAllPoints()
            frame:SetPoint(original.point,original.relative,
                original.relativePoint,original.x,original.y)
        end)
    end
    return success
end
local function Offset(anchor)
    return {point=anchor.point,relative=anchor.relative,
        relativePoint=anchor.relativePoint,x=anchor.x,y=anchor.y-BAR_HEIGHT}
end
local function Restore(name)
    local old=tracked[name]
    if not old then return end
    local frame=_G[name]
    local safe=IsSafeFrame(frame)
    local current=safe and ReadAnchor(frame) or nil
    if current and Same(current,old.applied) then
        Position(frame,old.original)
    end
    tracked[name]=nil
end
local function Apply(name)
    local frame=_G[name]
    if not frame then return end
    local safe,reason=IsSafeFrame(frame)
    if not safe then
        if reason=="protected" or reason=="unknown protection" then
            skippedProtected=skippedProtected+1
        else
            skippedCustom=skippedCustom+1
        end
        return
    end
    local current=ReadAnchor(frame)
    if not current then
        skippedCustom=skippedCustom+1
        return
    end
    local old=tracked[name]
    if old then
        if Same(current,old.applied) then return end
        if not Same(current,old.original) then
            tracked[name]=nil
            skippedCustom=skippedCustom+1
            return -- another addon or Edit Mode owns the new position
        end
    end
    local target=Offset(current)
    if Position(frame,target) then
        tracked[name]={original=current,applied=target}
    end
end
function ChalkBox_ScreenLayoutAdjust()
    if not db then return false end
    if Combat() then pending=true;return false end
    pending=false
    skippedProtected=0
    skippedCustom=0
    local enabled=db.bar~="off" and db.bar=="top"
        and db.barShiftChrome~=false
    if not enabled then
        for _,name in ipairs(targets) do Restore(name) end
        lastReason="off"
        return true
    end
    for _,name in ipairs(targets) do Apply(name) end
    lastReason="top offset applied where safe"
    return true
end
function ChalkBox_ScreenLayoutSet(enabled)
    if not db then return false end
    db.barShiftChrome=enabled==true
    ChalkBox_ScreenLayoutAdjust()
    return true
end
function ChalkBox_ScreenLayoutStatus()
    local moved=0
    for _ in pairs(tracked) do moved=moved+1 end
    return {enabled=db and db.barShiftChrome~=false,
        moved=moved,pending=pending,
        skippedProtected=skippedProtected,
        skippedCustom=skippedCustom,reason=lastReason}
end
local events=CreateFrame("Frame")
for _,event in ipairs({"ADDON_LOADED","PLAYER_ENTERING_WORLD",
    "PLAYER_REGEN_ENABLED","DISPLAY_SIZE_CHANGED","UI_SCALE_CHANGED"}) do
    events:RegisterEvent(event)
end
events:SetScript("OnEvent",function(_,event,name)
    if event=="ADDON_LOADED" then
        if name~=addonName then return end
        if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
        db=ChalkBoxDB
        if type(db.barShiftChrome)~="boolean" then
            db.barShiftChrome=true
        end
        return
    end
    if not db then return end
    if event=="PLAYER_ENTERING_WORLD" or event=="PLAYER_REGEN_ENABLED"
        or event=="DISPLAY_SIZE_CHANGED" or event=="UI_SCALE_CHANGED" then
        ChalkBox_ScreenLayoutAdjust()
    end
end)
