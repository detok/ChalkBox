-- ChalkBox core: quest & merchant awareness.
-- Vendor-awareness: distinguish items offered for sale from items in your bags.
-- Purely informational; never intercepts clicks, buys, or sells anything.

local questItems = {}
local questDataPending = false
local lastQuestRetry = -1000000000
local merchantHighlights = {}
local highlightRefreshPending = false
local merchantUpdateHooked = false

local function Safe(value)
    return value ~= nil and (not issecretvalue or not issecretvalue(value))
end

-- Quest objectives and tooltip item names can differ in case and whitespace,
-- especially on Forever's localized progress-first objective format.
-- Keep the association exact after normalization; never infer a quest from
-- item category, partial text, a plural guess or an external database.
local function ItemNameKey(name)
    if not Safe(name) or type(name) ~= "string" then return nil end
    local key = name:gsub("^%s+", ""):gsub("%s+$", "")
        :gsub("%s+", " "):lower()
    return key ~= "" and key or nil
end

local function GetQuest(index)
    if C_QuestLog and type(C_QuestLog.GetInfo)=="function" then
        local ok,info=pcall(C_QuestLog.GetInfo,index)
        if not ok or not Safe(info) or type(info)~="table" then
            return nil,nil,"pending"
        end
        if info.isHeader~=nil and not Safe(info.isHeader) then
            return nil,nil,"pending"
        end
        if info.isHeader==true then return nil,nil,"header" end
        if Safe(info.title) and type(info.title)=="string" and
            Safe(info.questID) and type(info.questID)=="number" then
            return info.title,info.questID,"quest"
        end
        return nil,nil,"pending"
    elseif type(GetQuestLogTitle)=="function" then
        local ok,title,_,_,isHeader,_,_,_,questID=
            pcall(GetQuestLogTitle,index)
        if not ok or (isHeader~=nil and not Safe(isHeader)) then
            return nil,nil,"pending"
        end
        if isHeader==true then return nil,nil,"header" end
        if Safe(title) and type(title)=="string" and Safe(questID)
            and type(questID)=="number" then
            return title,questID,"quest"
        end
        return nil,nil,"pending"
    end
    return nil,nil,"pending"
end

local function ParseObjective(text)
    if not Safe(text) or type(text) ~= "string" then return nil end
    -- Use the quest log's own item wording: names must match exactly.
    local name, have, total = text:match("^%s*(.-):%s*(%d+)%s*/%s*(%d+)%s*$")
    if name then return name, tonumber(have), tonumber(total) end
    have, total, name = text:match("^%s*(%d+)%s*/%s*(%d+)%s+(.+)%s*$")
    if name then return name, tonumber(have), tonumber(total) end
    name, have, total = text:match("^%s*(.-)%s*%(%s*(%d+)%s*/%s*(%d+)%s*%)%s*$")
    if name then return name, tonumber(have), tonumber(total) end
    return text:match("^%s*(.-)%s*$")
end

local function RebuildQuestItems()
    local fresh = {}
    local pending = false
    local getCount=C_QuestLog and C_QuestLog.GetNumQuestLogEntries
    if type(getCount)~="function" then getCount=GetNumQuestLogEntries end
    local ok,count=pcall(getCount or function() return nil end)
    if not ok or not Safe(count) or type(count)~="number"
        or count<0 then
        questDataPending = true
        return -- Do not erase the last known quest names on an unreadable log.
    end
    local missing={}
    if not (C_QuestLog and type(C_QuestLog.GetQuestObjectives)=="function") then
        questDataPending=true
        return -- Can't confirm objective changes yet: preserve verified data.
    end
    for index = 1, count do
        local title, questID, state = GetQuest(index)
        if state=="pending" then
            questDataPending=true
            return -- Incomplete log snapshot: preserve all previous evidence.
        end
        if Safe(title) and type(title) == "string" and title ~= ""
            and Safe(questID) and type(questID) == "number" and questID > 0
            and C_QuestLog and type(C_QuestLog.GetQuestObjectives) == "function" then
            local ok, objectives = pcall(C_QuestLog.GetQuestObjectives, questID)
            if not ok or not Safe(objectives) or objectives == nil then
                -- Forever may return nil until quest details finish caching.
                pending = true
                missing[questID]=true
            elseif type(objectives) == "table" then
                for _, objective in ipairs(objectives) do
                    if Safe(objective) and type(objective)=="table"
                        and Safe(objective.type) and objective.type=="item" then
                        local name, parsedHave, parsedTotal = ParseObjective(objective.text)
                        local key = ItemNameKey(name)
                        if key then
                            local entry = fresh[key]
                            if not entry then
                                entry = { protect = nil, purchase = nil, quests = {} }
                                fresh[key] = entry
                            end
                            -- Keep the original behavior: warn about accepted-quest items,
                            -- including completed objectives until the quest is turned in.
                            if not entry.protect then entry.protect = title end

                            local have = Safe(objective.numFulfilled) and objective.numFulfilled or parsedHave
                            local required = Safe(objective.numRequired) and objective.numRequired or parsedTotal
                            local unfinished = objective.finished ~= true
                            if Safe(required) and type(required) == "number" and required > 0
                                and Safe(have) and type(have) == "number" then
                                unfinished = have < required and unfinished
                            end
                            -- Cache the actual active quest title and item
                            -- objective progress for LootSense. No new quest
                            -- queries are required when tooltips appear.
                            -- Multiple accepted quests can need the same item.
                            local found=false
                            for _,q in ipairs(entry.quests) do
                                if q.id==questID then found=true;break end
                            end
                            if not found then
                                entry.quests[#entry.quests+1]={
                                    title=title,id=questID,
                                    have=type(have)=="number" and have or nil,
                                    required=type(required)=="number" and required or nil,
                                    complete=not unfinished,
                                }
                            end
                            if unfinished then
                                local remaining
                                if type(required) == "number" and type(have) == "number" then
                                    remaining = math.max(0, required - have)
                                end
                                if not entry.purchase then
                                    entry.purchase = { quest = title, remaining = remaining }
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    -- Missing objectives should not make a previously verified active quest
    -- disappear from KEEP, but its old collection progress is not current.
    -- Never preserve entries after the quest leaves the readable log.
    for key,previous in pairs(questItems) do
        if type(previous)=="table" and type(previous.quests)=="table" then
            for _,q in ipairs(previous.quests) do
                if missing[q.id] then
                    local entry=fresh[key]
                    if not entry then
                        entry={protect=q.title,purchase=nil,quests={}}
                        fresh[key]=entry
                    end
                    local found=false
                    for _,existing in ipairs(entry.quests) do
                        if existing.id==q.id then found=true;break end
                    end
                    if not found then
                        entry.quests[#entry.quests+1]={
                            title=q.title,id=q.id,have=q.have,
                            required=q.required,complete=q.complete,stale=true,
                        }
                    end
                end
            end
        end
    end
    questItems = fresh
    questDataPending = pending
end

-- Re-query only while Forever explicitly has unresolved quest data, and
-- throttle retries across item hovers. No second scan on every tooltip.
local function RetryPendingQuestData()
    if not questDataPending then return end
    local ok,now=pcall(type(GetTime)=="function" and GetTime or
        function() return nil end)
    if not ok then return end
    if Safe(now) and type(now) == "number" then
        if now - lastQuestRetry < 2 then return end
        lastQuestRetry = now
    else
        -- Without a monotonic clock, only quest-log events trigger refresh.
        return
    end
    RebuildQuestItems()
end

-- Read-only quest lookup for optional LootSense advice; original behavior is unchanged.
function ChalkBox_IsTrackedQuestItem(itemName)
    local key = ItemNameKey(itemName)
    if not key then return false end
    if questDataPending then RetryPendingQuestData() end
    return questItems[key] ~= nil and questItems[key].protect ~= nil
end

-- Read-only evidence for LootSense; only use objectives the accepted quest
-- log itself identifies as item collections. Do not invent a matching quest
-- from item rarity, quest-class flags, or an external name database.
function ChalkBox_QuestItemDetails(itemName)
    local key=ItemNameKey(itemName)
    if not key then return nil end
    if questDataPending then RetryPendingQuestData() end
    local entry=questItems[key]
    if not entry or type(entry.quests)~="table" or #entry.quests==0 then
        return nil
    end
    -- Return a detached copy so callers cannot mutate the live quest cache.
    local found={}
    for _,quest in ipairs(entry.quests) do
        found[#found+1]={title=quest.title,id=quest.id,
            have=quest.have,required=quest.required,
            complete=quest.complete,stale=quest.stale}
    end
    return found
end

local function GetVendorName(index)
    if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
        local info = C_MerchantFrame.GetItemInfo(index)
        if info then return info.name end
    elseif GetMerchantItemInfo then
        return GetMerchantItemInfo(index)
    end
end

local function IsMerchantSelling()
    return MerchantFrame and MerchantFrame:IsShown() and MerchantFrame.selectedTab == 1
end

local function TooltipVendorSlot(tooltip)
    if not MerchantFrame or not MerchantFrame:IsShown() or not tooltip.GetOwner then return nil end
    local owner = tooltip:GetOwner()
    if not owner then return nil end

    -- Blizzard uses MerchantItem1ItemButton through MerchantItem10ItemButton.
    -- Only a tooltip actually owned by a vendor's offered item gets BUY text.
    for slot = 1, (MERCHANT_ITEMS_PER_PAGE or 10) do
        local button = _G["MerchantItem" .. slot .. "ItemButton"]
        if button and (owner == button or owner == button:GetParent()) then
            local index = button:GetID()
            if index and index > 0 then return index, MerchantFrame.selectedTab == 1 end
        end
    end
end

local function HasTooltipLine(tooltip, text)
    local name = tooltip:GetName()
    if not name then return false end
    for i = 1, tooltip:NumLines() do
        local fontString = _G[name .. "TextLeft" .. i]
        if fontString and fontString:GetText() == text then return true end
    end
    return false
end

local function OnItemTooltip(tooltip)
    if not MerchantFrame or not MerchantFrame:IsShown() then return end
    if not tooltip or not tooltip.GetItem then return end
    local itemName = tooltip:GetItem()
    if not Safe(itemName) or type(itemName) ~= "string" then return end

    local key = ItemNameKey(itemName)
    local entry = key and questItems[key] or nil
    if not entry then return end

    local slot, vendorBuyTab = TooltipVendorSlot(tooltip)
    if slot and not vendorBuyTab then return end -- buyback is not an inventory sale
    local message, r, g, b
    if slot then
        -- No false buying recommendation when hovering buyback items or
        -- items for already-completed objectives.
        if not entry.purchase or GetVendorName(slot) ~= itemName then return end
        message = "BUY FOR QUEST  ·  " .. entry.purchase.quest
        if entry.purchase.remaining and entry.purchase.remaining > 0 then
            message = message .. " (" .. entry.purchase.remaining .. " more)"
        end
        r, g, b = 0.98, 0.45, 0.40
    elseif entry.protect then
        message = "DO NOT SELL  ·  " .. entry.protect
        r, g, b = 0.98, 0.45, 0.40
    else
        return
    end

    if not HasTooltipLine(tooltip, message) then
        tooltip:AddLine(message, r, g, b, true)
        tooltip:Show()
    end
end

local function MakeVendorGlow(button)
    if merchantHighlights[button] then return merchantHighlights[button] end

    -- Merchant items render inside their own UI frames. A texture drawn
    -- directly on the item button can sit behind Blizzard's other overlays.
    -- Use a child frame raised above its parent, with real visible border
    -- edges, rather than depending on a specific action-button art texture.
    local frame = CreateFrame("Frame", nil, button)
    frame:SetAllPoints(button)
    frame:SetFrameLevel(button:GetFrameLevel() + 8)
    frame:EnableMouse(false)

    local function Edge(anchor1, anchor2, horizontal)
        local tex = frame:CreateTexture(nil, "OVERLAY")
        tex:SetColorTexture(1.0, 0.62, 0.12, 1.0)
        tex:SetPoint(anchor1, frame, anchor1, 0, 0)
        tex:SetPoint(anchor2, frame, anchor2, 0, 0)
        if horizontal then
            tex:SetHeight(3)
        else
            tex:SetWidth(3)
        end
        return tex
    end

    Edge("TOPLEFT", "TOPRIGHT", true)
    Edge("BOTTOMLEFT", "BOTTOMRIGHT", true)
    Edge("TOPLEFT", "BOTTOMLEFT", false)
    Edge("TOPRIGHT", "BOTTOMRIGHT", false)

    -- A small quest marker makes the purpose clear without modifying the
    -- item texture or interfering with the vendor's click/hover behavior.
    local marker = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    marker:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 3, 5)
    marker:SetText("!")
    marker:SetTextColor(1, 0.25, 0.15)

    local pulse = frame:CreateAnimationGroup()
    pulse:SetLooping("BOUNCE")
    local fade = pulse:CreateAnimation("Alpha")
    fade:SetFromAlpha(0.40)
    fade:SetToAlpha(1.0)
    fade:SetDuration(1.1)
    frame:Hide()

    local result = { glow = frame, pulse = pulse }
    merchantHighlights[button] = result
    return result
end

local function ClearVendorGlows()
    for _, highlight in pairs(merchantHighlights) do
        highlight.pulse:Stop()
        highlight.glow:Hide()
    end
end

local function RefreshVendorGlows()
    if not IsMerchantSelling() then
        ClearVendorGlows()
        return
    end
    for slot = 1, (MERCHANT_ITEMS_PER_PAGE or 10) do
        local button = _G["MerchantItem" .. slot .. "ItemButton"]
        if button then
            local highlight = MakeVendorGlow(button)
            local index = button:GetID()
            local name = index and GetVendorName(index)
            local key = ItemNameKey(name)
            local entry = key and questItems[key] or nil
            local shouldGlow = button:IsShown() and entry and entry.purchase
            if shouldGlow then
                highlight.glow:Show()
                if not highlight.pulse:IsPlaying() then highlight.pulse:Play() end
            else
                highlight.pulse:Stop()
                highlight.glow:Hide()
            end
        end
    end
end

local function ScheduleVendorRefresh()
    if highlightRefreshPending then return end
    highlightRefreshPending = true
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            highlightRefreshPending = false
            RefreshVendorGlows()
        end)
    else
        highlightRefreshPending = false
        RefreshVendorGlows()
    end
end

local function InstallMerchantUpdateHook()
    if merchantUpdateHooked then return end
    if type(MerchantFrame_Update) == "function" and type(hooksecurefunc) == "function" then
        hooksecurefunc("MerchantFrame_Update", ScheduleVendorRefresh)
        merchantUpdateHooked = true
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("QUEST_LOG_UPDATE")
events:RegisterEvent("QUEST_ACCEPTED")
events:RegisterEvent("QUEST_REMOVED")
events:RegisterEvent("QUEST_TURNED_IN")
events:RegisterEvent("MERCHANT_SHOW")
events:RegisterEvent("MERCHANT_UPDATE")
events:RegisterEvent("MERCHANT_CLOSED")
events:SetScript("OnEvent", function(_, event)
    if event == "MERCHANT_CLOSED" then
        ClearVendorGlows()
    elseif event == "MERCHANT_SHOW" or event == "MERCHANT_UPDATE" then
        InstallMerchantUpdateHook()
        ScheduleVendorRefresh()
    else
        RebuildQuestItems()
        ScheduleVendorRefresh()
    end
end)

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
    and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItemTooltip)
else
    GameTooltip:HookScript("OnTooltipSetItem", OnItemTooltip)
end