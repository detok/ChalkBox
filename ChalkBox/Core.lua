-- ChalkBox core: quest & merchant awareness.
-- Vendor-awareness: distinguish items offered for sale from items in your bags.
-- Purely informational; never intercepts clicks, buys, or sells anything.

local questItems = {}
local merchantHighlights = {}
local highlightRefreshPending = false
local merchantUpdateHooked = false

local function Safe(value)
    return value ~= nil and (not issecretvalue or not issecretvalue(value))
end

local function GetQuest(index)
    if C_QuestLog and C_QuestLog.GetInfo then
        local info = C_QuestLog.GetInfo(index)
        if info and not info.isHeader then
            return info.title, info.questID
        end
    elseif GetQuestLogTitle then
        local title, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(index)
        if not isHeader then
            return title, questID
        end
    end
end

local function ParseObjective(text)
    if not Safe(text) or type(text) ~= "string" then return nil end
    -- Use the quest log's own item wording: names must match exactly.
    local name, have, total = text:match("^%s*(.-):%s*(%d+)%s*/%s*(%d+)%s*$")
    if name then return name, tonumber(have), tonumber(total) end
    have, total, name = text:match("^%s*(%d+)%s*/%s*(%d+)%s+(.+)%s*$")
    if name then return name, tonumber(have), tonumber(total) end
    return text:match("^%s*(.-)%s*$")
end

local function RebuildQuestItems()
    local fresh = {}
    local count = (C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetNumQuestLogEntries())
        or (GetNumQuestLogEntries and GetNumQuestLogEntries()) or 0
    if not Safe(count) or type(count) ~= "number" then return end

    for index = 1, count do
        local title, questID = GetQuest(index)
        if Safe(title) and Safe(questID) and C_QuestLog and C_QuestLog.GetQuestObjectives then
            local objectives = C_QuestLog.GetQuestObjectives(questID)
            if type(objectives) == "table" then
                for _, objective in ipairs(objectives) do
                    if objective.type == "item" then
                        local name, parsedHave, parsedTotal = ParseObjective(objective.text)
                        if name and name ~= "" then
                            local entry = fresh[name]
                            if not entry then
                                entry = { protect = nil, purchase = nil }
                                fresh[name] = entry
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
    questItems = fresh
end

-- Read-only quest lookup for optional LootSense advice; original behavior is unchanged.
function ChalkBox_IsTrackedQuestItem(itemName)
    return Safe(itemName) and type(itemName) == "string"
        and questItems[itemName] ~= nil and questItems[itemName].protect ~= nil
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

    local entry = questItems[itemName]
    if not entry then return end

    local slot, vendorBuyTab = TooltipVendorSlot(tooltip)
    if slot and not vendorBuyTab then return end -- buyback is not an inventory sale
    local message, r, g, b
    if slot then
        -- No false buying recommendation when hovering buyback items or
        -- items for already-completed objectives.
        if not entry.purchase or GetVendorName(slot) ~= itemName then return end
        message = "BUY THIS FOR QUEST: " .. entry.purchase.quest
        if entry.purchase.remaining and entry.purchase.remaining > 0 then
            message = message .. " (need " .. entry.purchase.remaining .. " more)"
        end
        r, g, b = 1, 0.28, 0.17
    elseif entry.protect then
        message = "Don't sell: needed for " .. entry.protect
        r, g, b = 1, 0.32, 0.12
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
            local entry = Safe(name) and questItems[name] or nil
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