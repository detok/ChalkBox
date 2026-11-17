-- A separate purple border for CURATED future-quest references only.
-- Never parent, reanchor, paint, hook, or write fields onto Blizzard bag items.
-- This overlays world-space rectangles via ChalkBox-owned UIParent frames.
-- Active quest items and the existing Core/Blizzard highlights are untouched.
local addonName=...
local root=CreateFrame("Frame")
local pool={}
local visible=0
local lastReason="waiting for bags"
local enabled=true
local elapsed=0

local function Safe(v)
    return v~=nil and (type(issecretvalue)~="function"
        or not issecretvalue(v))
end
local function Read(fn,self)
    if type(fn)~="function" then return nil end
    local ok,v=pcall(fn,self)
    if ok and Safe(v) then return v end
end
local function InCombat()
    if type(InCombatLockdown)~="function" then return false end
    local ok,v=pcall(InCombatLockdown)
    return not ok or not Safe(v) or v==true
end
local function Settings()
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    if ChalkBoxDB.futureQuestGlow==nil then
        ChalkBoxDB.futureQuestGlow=true
    end
    enabled=ChalkBoxDB.futureQuestGlow~=false
    return enabled
end
local function HideAll()
    for _,marker in ipairs(pool) do marker:Hide() end
    visible=0
end
local function MakeMarker()
    if not UIParent or type(CreateFrame)~="function" then return nil end
    -- A detached frame anchored in UIParent coordinates. Never a child of
    -- a secure bag button; mouse disabled and no click scripts.
    local f=CreateFrame("Frame",nil,UIParent)
    if type(f.EnableMouse)=="function" then f:EnableMouse(false) end
    if type(f.SetFrameStrata)=="function" then f:SetFrameStrata("DIALOG") end
    local edges={}
    for i=1,4 do
        local t=f:CreateTexture(nil,"OVERLAY")
        t:SetColorTexture(0.71,0.46,0.97,0.95)
        edges[i]=t
    end
    edges[1]:SetPoint("TOPLEFT",f,"TOPLEFT",-2,2)
    edges[1]:SetPoint("TOPRIGHT",f,"TOPRIGHT",2,2)
    edges[1]:SetHeight(3)
    edges[2]:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",-2,-2)
    edges[2]:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",2,-2)
    edges[2]:SetHeight(3)
    edges[3]:SetPoint("TOPLEFT",f,"TOPLEFT",-2,2)
    edges[3]:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",-2,-2)
    edges[3]:SetWidth(3)
    edges[4]:SetPoint("TOPRIGHT",f,"TOPRIGHT",2,2)
    edges[4]:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",2,-2)
    edges[4]:SetWidth(3)
    f:Hide()
    pool[#pool+1]=f
    return f
end
local function Position(marker,button)
    -- Read visible geometry only; never anchor to a protected item.
    if not button or not UIParent then return false end
    local shown=Read(button.IsVisible,button)
    if shown==false or (shown==nil and
        Read(button.IsShown,button)~=true) then return false end
    local cx,cy
    if type(button.GetCenter)=="function" then
        local ok,x,y=pcall(button.GetCenter,button)
        if ok and Safe(x) and Safe(y) then cx,cy=x,y end
    end
    local w,h=Read(button.GetWidth,button),Read(button.GetHeight,button)
    local scale=Read(button.GetEffectiveScale,button) or 1
    local parentScale=Read(UIParent.GetEffectiveScale,UIParent) or 1
    if type(cx)~="number" or type(cy)~="number"
        or type(w)~="number" or type(h)~="number"
        or type(scale)~="number" or type(parentScale)~="number"
        or w<=0 or h<=0 or parentScale<=0 or scale<=0 then
        return false
    end
    local ratio=scale/parentScale
    if ratio>8 or ratio<0.125 then return false end
    marker:ClearAllPoints()
    marker:SetSize(w*ratio,h*ratio)
    marker:SetPoint("CENTER",UIParent,"BOTTOMLEFT",cx*ratio,cy*ratio)
    marker:Show()
    return true
end
local function IsActiveBagQuestItem(bag,slot,id)
    local getQuestInfo=C_Container and C_Container.GetContainerItemQuestInfo
        or GetContainerItemQuestInfo
    if type(getQuestInfo)=="function" then
        local ok,a,_,active=pcall(getQuestInfo,bag,slot)
        if ok and Safe(a) then
            if type(a)=="table" then
                local valid,state=pcall(function() return a.isActive end)
                if valid and Safe(state) and state==true then return true end
            elseif Safe(active) and active==true then return true end
        end
    end
    local getName=C_Item and C_Item.GetItemInfo or GetItemInfo
    if type(getName)=="function" and
        type(ChalkBox_IsTrackedQuestItem)=="function" then
        local ok,name=pcall(getName,id)
        if ok and Safe(name) and type(name)=="string" then
            local checked,tracked=pcall(ChalkBox_IsTrackedQuestItem,name)
            if checked and tracked then return true end
        end
    end
    return false
end
local function ItemAt(bag,slot)
    local api=C_Container
    local fn=api and api.GetContainerItemID or GetContainerItemID
    if type(fn)~="function" then return nil end
    local ok,id=pcall(fn,bag,slot)
    if ok and Safe(id) and type(id)=="number" and id>0 then
        return id
    end
end
local function Candidate(button,bag,slot)
    if visible>=80 or type(ChalkBox_FutureQuestUses)~="function"
        or type(bag)~="number" or bag<0 or bag>4
        or type(slot)~="number" or slot<1 then return end
    local id=ItemAt(bag,slot)
    if not id or IsActiveBagQuestItem(bag,slot,id) then return end
    local ok,uses=pcall(ChalkBox_FutureQuestUses,id)
    if not ok or type(uses)~="table" or #uses==0 then return end
    local marker=pool[visible+1] or MakeMarker()
    if marker and Position(marker,button) then visible=visible+1 end
end

local function Scan()
    HideAll()
    if not Settings() then lastReason="future markers disabled";return end
    if InCombat() then lastReason="suppressed during combat";return end
    if not UIParent then lastReason="UIParent unavailable";return end
    if type(ChalkBox_FutureQuestUses)~="function" then
        lastReason="future-quest data unavailable";return
    end
    -- Default separate bags. Avoid hooks and writes to secure bag frames.
    local frames=type(NUM_CONTAINER_FRAMES)=="number"
        and math.min(NUM_CONTAINER_FRAMES,20) or 13
    local scanned=0
    for index=1,frames do
        local frame=_G["ContainerFrame"..index]
        if frame and Read(frame.IsShown,frame)==true then
            local bag=Read(frame.GetBagID,frame)
            if bag==nil then bag=Read(frame.GetID,frame) end
            if type(bag)=="number" and bag>=0 and bag<=4 then
                local frameName=Read(frame.GetName,frame)
                frameName=type(frameName)=="string" and frameName
                    or ("ContainerFrame"..index)
                for i=1,64 do
                    local button=_G[frameName.."Item"..i]
                    if button and Read(button.IsShown,button)==true then
                        local slot=Read(button.GetID,button)
                        if type(slot)=="number" then
                            scanned=scanned+1
                            Candidate(button,bag,slot)
                        end
                    end
                end
            end
        end
    end
    lastReason=scanned>0 and "default bags scanned" or
        "no supported separate bag items visible"
end
function ChalkBox_FutureQuestGlowRefresh()
    Scan()
end
function ChalkBox_FutureQuestGlowSet(on)
    Settings()
    ChalkBoxDB.futureQuestGlow=on==true
    Scan()
    return enabled
end
function ChalkBox_FutureQuestGlowStatus()
    Settings()
    return {enabled=enabled,visible=visible,reason=lastReason,
        mode="detached markers, separate Blizzard bags"}
end
for _,event in ipairs({"ADDON_LOADED","PLAYER_ENTERING_WORLD",
    "BAG_UPDATE_DELAYED","QUEST_LOG_UPDATE","QUEST_ACCEPTED",
    "QUEST_REMOVED","QUEST_TURNED_IN","PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED"}) do
    pcall(root.RegisterEvent,root,event)
end
root:SetScript("OnEvent",function(_,event,name)
    if event=="ADDON_LOADED" and name~=addonName then return end
    Scan()
end)
-- Read-only polling tracks bag moves, open/close and default bag sorting.
-- The independent markers never interact with Blizzard's secure slots.
root:SetScript("OnUpdate",function(_,dt)
    if not Safe(dt) or type(dt)~="number" then return end
    elapsed=elapsed+dt
    if elapsed>=0.35 then
        elapsed=0
        Scan()
    end
end)
