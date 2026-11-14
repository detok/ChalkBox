-- ChalkBox 1.9: understated, noninteractive green insets on actual learned
-- profession reagents in Blizzard's original bag buttons. Never alters clicks,
-- rarity borders, bag sorting or the game's icon textures.
local addonName=...
local db
local last={marked=0,visible=0,reason="not initialized"}
local queued=false
local bankOpen=false
local learnedForRefresh
local hooked={all=false,items=false}
local stripColor={0.24,0.94,0.57}

local function Public(v)
    return v~=nil and (type(issecretvalue)~="function" or not issecretvalue(v))
end
-- Never decorate or inspect bank item buttons while Blizzard initializes
-- its bank panel. BANKFRAME_OPENED can arrive before every bank frame is ready.
local function BankVisible()
    if bankOpen then return true end
    local frame=BankFrame
    if frame and type(frame.IsShown)=="function" then
        local ok,shown=pcall(frame.IsShown,frame)
        if ok and Public(shown) and shown then return true end
    end
    return false
end
local function PlayerBag(bag)
    if not Public(bag) or type(bag)~="number" then return false end
    local backpack=type(BACKPACK_CONTAINER)=="number" and
        BACKPACK_CONTAINER or 0
    local lastBag=type(NUM_BAG_SLOTS)=="number" and
        NUM_BAG_SLOTS or 4
    return bag>=backpack and bag<=lastBag
end
local function Enabled()
    return db and db.lootHighlightKnown~=false
end
local function Alpha()
    if not db then return 0.8 end
    local value=tonumber(db.lootHighlightOpacity)
    if not value or value~=value then value=75 end
    value=math.max(15,math.min(100,value))
    return value/100
end
local function CreateMarker(button)
    if button.ChalkBoxReagentBorder then return button.ChalkBoxReagentBorder end
    if type(button.CreateTexture)~="function" then return end
    local marker={}
    local function Strip(a,b,c,d,height,width)
        local tex=button:CreateTexture(nil,"OVERLAY")
        if not tex then return end
        tex:SetPoint(a,button,b,c,d)
        if height then tex:SetHeight(height) end
        if width then tex:SetWidth(width) end
        tex:SetColorTexture(stripColor[1],stripColor[2],stripColor[3],Alpha())
        tex:Hide()
        marker[#marker+1]=tex
    end
    Strip("TOPLEFT","TOPLEFT",2,-2,2,nil)
    if marker[1] and marker[1].SetPoint then
        marker[1]:SetPoint("TOPRIGHT",button,"TOPRIGHT",-2,-2)
    end
    Strip("BOTTOMLEFT","BOTTOMLEFT",2,2,2,nil)
    if marker[2] and marker[2].SetPoint then
        marker[2]:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-2,2)
    end
    Strip("TOPLEFT","TOPLEFT",2,-2,nil,2)
    if marker[3] and marker[3].SetPoint then
        marker[3]:SetPoint("BOTTOMLEFT",button,"BOTTOMLEFT",2,2)
    end
    Strip("TOPRIGHT","TOPRIGHT",-2,-2,nil,2)
    if marker[4] and marker[4].SetPoint then
        marker[4]:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-2,2)
    end
    button.ChalkBoxReagentBorder=marker
    return marker
end
local function ShowMarker(button,show)
    if not button then return end
    -- Never create visual decoration for items that aren't verified ingredients.
    local marker=show and CreateMarker(button) or button.ChalkBoxReagentBorder
    if not marker then return end
    for _,tex in ipairs(marker) do
        if tex.SetColorTexture then
            tex:SetColorTexture(stripColor[1],stripColor[2],stripColor[3],Alpha())
        end
        if show then tex:Show() else tex:Hide() end
    end
end
local function ItemID(button)
    if not button or not button.GetBagID or not button.GetID then return end
    local ok,bag,slot=pcall(function() return button:GetBagID(),button:GetID() end)
    if not ok or not PlayerBag(bag) or not Public(slot)
        or type(slot)~="number" then return end
    local api=C_Container and C_Container.GetContainerItemID or GetContainerItemID
    if type(api)~="function" then return end
    local status,value=pcall(api,bag,slot)
    if status and Public(value) and type(value)=="number" and value>0 then
        return value
    end
end
local function Learned(itemID)
    if type(ChalkBox_LearnedRecipeUses)~="function" then return false end
    local ok,recipes=pcall(ChalkBox_LearnedRecipeUses,itemID,nil)
    if ok and type(recipes)=="table" and #recipes>0 then return true end
    -- Legacy profession scans can record a reagent by localized item name
    -- only. Match the same evidence the tooltip uses when the item cache
    -- supplies a safe name; never use an offline catalog as proof.
    local getName=C_Item and C_Item.GetItemInfo or GetItemInfo
    if type(getName)~="function" then return false end
    local success,name=pcall(getName,itemID)
    if not success or not Public(name) or type(name)~="string" then return false end
    ok,recipes=pcall(ChalkBox_LearnedRecipeUses,itemID,name)
    return ok and type(recipes)=="table" and #recipes>0
end
local function UpdateButton(button)
    if not button or BankVisible() then return end
    -- The native container iterator can include character-bank, reagent-bank
    -- and account-bank item buttons. Do not attach our overlay textures to
    -- those protected Blizzard controls, even after the bank closes.
    if type(button.GetBagID)~="function" then return end
    local ok,bag=pcall(button.GetBagID,button)
    if not ok or not PlayerBag(bag) then return end
    local shown=not button.IsShown or button:IsShown()
    if not Public(shown) or not shown then ShowMarker(button,false);return end
    last.visible=last.visible+1
    local itemID=Enabled() and ItemID(button)
    local mark=false
    if itemID then
        -- A bag often contains several stacks of the same ingredient.
        -- Read its learned-recipe evidence only once per batched pass.
        if learnedForRefresh[itemID]==nil then
            learnedForRefresh[itemID]=Learned(itemID)
        end
        mark=learnedForRefresh[itemID]
    end
    ShowMarker(button,mark)
    if mark then last.marked=last.marked+1 end
end
local function UpdateFrame(frame)
    if not frame or type(frame.EnumerateValidItems)~="function" then return end
    local shown=not frame.IsShown or frame:IsShown()
    if not Public(shown) or not shown then return end
    local ok=pcall(function()
        for _,button in frame:EnumerateValidItems() do
            UpdateButton(button)
        end
    end)
    if not ok then last.reason="A client bag frame could not be scanned." end
end
local function Refresh()
    if BankVisible() then
        last.reason="bank UI active; inventory scan deferred"
        return
    end
    last={visible=0,marked=0,reason="ready"}
    learnedForRefresh={}
    if type(ContainerFrameUtil_EnumerateContainerFrames)=="function" then
        local ok=pcall(function()
            for _,frame in ContainerFrameUtil_EnumerateContainerFrames() do
                UpdateFrame(frame)
            end
        end)
        if ok then return end
    end
    for i=1,20 do UpdateFrame(_G["ContainerFrame"..i]) end
    if type(ContainerFrameCombinedBags)=="table" then
        UpdateFrame(ContainerFrameCombinedBags)
    end
end
function ChalkBox_BagHighlightsRefresh()
    Refresh()
    return last
end
function ChalkBox_BagHighlightSet(enabled)
    if not db then return false end
    db.lootHighlightKnown=enabled==true
    Refresh()
    return true
end
function ChalkBox_BagHighlightOpacity(value)
    if not db or type(value)~="number" or value~=value then return false end
    db.lootHighlightOpacity=math.max(15,math.min(100,math.floor(value+0.5)))
    Refresh()
    return true
end
function ChalkBox_BagHighlightStatus()
    return {enabled=Enabled() or false,opacity=math.floor(Alpha()*100+0.5),
        marked=last.marked,visible=last.visible,reason=last.reason}
end
local function QueueRefresh()
    if queued or not db or BankVisible() then return end
    if type(C_Timer)=="table" and type(C_Timer.After)=="function" then
        queued=true
        -- Blizzard can update individual bag slots many times per opening.
        -- Coalesce them into one scan after the burst settles.
        C_Timer.After(0.20,function()
            queued=false
            Refresh()
        end)
    else Refresh() end
end
local function HookBagUpdates()
    if BankVisible() or type(hooksecurefunc)~="function" then return end
    -- A bag can update individually without ContainerFrame_UpdateAll firing.
    -- Hook both safe native extension points as they become available.
    if not hooked.all and type(ContainerFrame_UpdateAll)=="function" then
        hooked.all=pcall(hooksecurefunc,"ContainerFrame_UpdateAll",QueueRefresh)
    end
    if not hooked.items and type(ContainerFrameMixin)=="table"
        and type(ContainerFrameMixin.UpdateItems)=="function" then
        hooked.items=pcall(hooksecurefunc,ContainerFrameMixin,"UpdateItems",
            QueueRefresh)
    end
end
local events=CreateFrame("Frame")
for _,event in ipairs({"ADDON_LOADED","PLAYER_ENTERING_WORLD","BAG_UPDATE_DELAYED",
    "TRADE_SKILL_LIST_UPDATE","TRADE_SKILL_DATA_SOURCE_CHANGED",
    "NEW_RECIPE_LEARNED","PLAYER_REGEN_ENABLED","BAG_OPEN",
    "BANKFRAME_OPENED","BANKFRAME_CLOSED"}) do
    pcall(events.RegisterEvent,events,event)
end
events:SetScript("OnEvent",function(_,event,name)
    if event=="BANKFRAME_OPENED" then
        bankOpen=true
        return -- Do not touch first-use bank frames during Blizzard initialization.
    elseif event=="BANKFRAME_CLOSED" then
        bankOpen=false
        HookBagUpdates()
        QueueRefresh()
        return
    end
    if event=="ADDON_LOADED" then
        if name==addonName then
            if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
            db=ChalkBoxDB
            if db.lootHighlightKnown==nil then db.lootHighlightKnown=true end
            if type(db.lootHighlightOpacity)~="number" then
                db.lootHighlightOpacity=75
            end
        end
        HookBagUpdates()
        return
    end
    HookBagUpdates()
    QueueRefresh()
end)
