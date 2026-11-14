-- ChalkBox LootSense: profession recipes, item utility and quest safety.
-- No transactions, automation, protected combat data, or market-price guesses.
-- Loaded after ChalkBox.lua so original quest/vendor guidance has priority.

local addonName = ...
local db

local function Public(value)
    return value ~= nil and (type(issecretvalue) ~= "function" or not issecretvalue(value))
end

local function Trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function ItemKey(name, link)
    if Public(link) and type(link) == "string" then
        local id = link:match("item:(%d+)")
        if id then return "id:" .. id end
    end
    if Public(name) and type(name) == "string" and name ~= "" then
        return "name:" .. string.lower(name)
    end
end

local function UserItemKey(input)
    if not input or input == "" then return nil end
    local id = input:match("item:(%d+)")
    if id then
        local name = input:match("%[([^%]]+)%]") or ("Item #" .. id)
        return "id:" .. id, name
    end
    local name = Trim(input)
    if name == "" then return nil end
    return "name:" .. string.lower(name), name
end

local function IsProtected(name, link)
    if not db or not db.keep then return false end
    local byID = ItemKey(name, link)
    local byName = ItemKey(name, nil)
    return (byID and db.keep[byID] ~= nil)
        or (byName and db.keep[byName] ~= nil)
end

local function IsVendorOffer(tooltip)
    if not MerchantFrame or not MerchantFrame.IsShown or not MerchantFrame:IsShown()
        or not tooltip.GetOwner then return false end
    local owner = tooltip:GetOwner()
    if not owner then return false end
    for slot = 1, (MERCHANT_ITEMS_PER_PAGE or 10) do
        local button = _G["MerchantItem" .. slot .. "ItemButton"]
        if button and (owner == button or (button.GetParent and owner == button:GetParent())) then
            return true -- both purchase and buyback; never label vendor stock as personal loot
        end
    end
    return false
end

local function HasLine(tooltip, message)
    if not tooltip.GetName or not tooltip.NumLines then return false end
    local tooltipName = tooltip:GetName()
    if not tooltipName then return false end
    for index = 1, tooltip:NumLines() do
        local row = _G[tooltipName .. "TextLeft" .. index]
        if row and row.GetText and row:GetText() == message then return true end
    end
    return false
end

-- Quest/personal protection always has priority. Otherwise ONLY annotate items
-- related to the current character's professions. No market-price guesses and no
-- useless REVIEW line on every green or white item.
local function Classify(name,link,quality,itemType,itemSubType,equipLoc,
    sellPrice,classID,bindType,isCraftingReagent)
    if not Public(name) or type(name)~="string" then return end
    if IsProtected(name,link) then
        return "KEEP: protected by you",0.40,0.95,0.45
    end
    if type(ChalkBox_IsTrackedQuestItem)=="function"
        and ChalkBox_IsTrackedQuestItem(name) then
        return "KEEP: accepted quest needs this",1,0.36,0.20
    end
    if Public(classID) and classID==12 then
        return "KEEP: quest item",1,0.36,0.20
    end
    local id=Public(link) and type(link)=="string" and link:match("item:(%d+)") or nil
    -- Verified recipes learned by this character are more relevant than broad
    -- camping and profession-family rules. An external library never invents
    -- "known" status: only the character's profession scan can prove that.
    if type(ChalkBox_RecipeAdvice)=="function" and
        (not db.lootCategories or db.lootCategories.crafting~=false) then
        local note,r,g,b=ChalkBox_RecipeAdvice(id,name)
        if note and (not note:find("^POTENTIAL USE") or
            not db.lootCategories or db.lootCategories.potential~=false) then
            return note,r,g,b
        end
    end
    if type(ChalkBox_CampUtility)=="function" and
        (not db.lootCategories or db.lootCategories.camp~=false) then
        local utility=ChalkBox_CampUtility(id,name)
        if utility then return utility,0.52,0.91,0.70 end
    end
    if type(ChalkBox_ProfessionMatch)~="function" or
        (db.lootCategories and db.lootCategories.crafting==false) then return end
    local profession,confidence=ChalkBox_ProfessionMatch(id,name,itemSubType,classID)
    if profession then
        if confidence=="known" then
            return "PROFESSION: used in a learned "..profession.." recipe",0.35,0.98,0.57
        end
        if not db.lootCategories or db.lootCategories.potential~=false then
            return "PROFESSION: possible "..profession.." material (check recipes)",0.83,0.91,0.48
        end
    end
end

-- Presentation is its own layer: reason/classification still comes from
-- unchanged LootSense and learned-profession evidence, not string guesswork.
local TIP_HEADER="CHALKBOX  |  ITEM INSIGHT"
function ChalkBox_LootPresentation(message)
    if type(message)~="string" then return end
    local prefix,body=message:match("^([^:]+):%s*(.*)$")
    if prefix=="KEEP" then
        return "Keep this item",body,0.43,0.93,0.56
    elseif prefix=="KNOWN RECIPE" then
        return "Used in a learned recipe",body,0.43,0.93,0.56
    elseif prefix=="POTENTIAL USE" then
        return "Possible crafting use",body,0.91,0.75,0.39
    elseif prefix=="OTHER PROFESSION" then
        return "Other profession recipe",body,0.68,0.76,0.89
    elseif prefix=="PROFESSION" then
        local confirmed=body and body:find("used in a learned",1,true)
        return confirmed and "Learned profession use" or "Possible profession material",
            body,confirmed and 0.43 or 0.91,
            confirmed and 0.93 or 0.75,
            confirmed and 0.56 or 0.39
    elseif prefix=="CAMP SUPPLY" then
        return "Camp supply",body,0.48,0.86,0.72
    elseif prefix=="CAMP TOOL" then
        return "Reusable camp tool",body,0.48,0.86,0.72
    elseif prefix=="CAMP" or prefix=="CAMP REAGENT" then
        return "Camping utility",body,0.48,0.86,0.72
    end
    return "Item insight",message,0.78,0.84,0.88
end

local function OnItemTooltip(tooltip)
    if not db or not tooltip or not tooltip.GetItem or IsVendorOffer(tooltip) then return end
    local name, link = tooltip:GetItem()
    if not Public(name) or type(name) ~= "string" then return end
    if not Public(link) then link = nil end
    -- DropSense is an independent, opt-in note available only on native
    -- loot-window item tooltips, even when ordinary LootSense advice is off.
    if type(ChalkBox_DropTooltip)=="function" then
        pcall(ChalkBox_DropTooltip,tooltip,link)
    end
    -- AuctionSense offers a separate, read-only market insight even when
    -- general LootSense classification advice has been disabled.
    if type(ChalkBox_AuctionTooltip)=="function" then
        pcall(ChalkBox_AuctionTooltip,tooltip,link)
    end
    if db.lootAdvice==false then return end

    -- A cached item link and tooltip name are already enough to identify
    -- learned-recipe reagents. Never reject all advice just because Forever's
    -- async GetItemInfo cache hasn't populated rarity/subtype yet.
    local infoName,quality,itemType,itemSubType,equipLoc,sellPrice,classID
    local bindType,isCraftingReagent
    local itemInfo=C_Item and C_Item.GetItemInfo or GetItemInfo
    if type(itemInfo)=="function" then
        local ok,n,_,q,_,_,typ,sub,_,loc,_,price,cls,_,bind,_,_,reagent=
            pcall(itemInfo,link or name)
        if ok and Public(n) then
            infoName,quality,itemType,itemSubType,equipLoc,sellPrice,classID=
                n,q,typ,sub,loc,price,cls
            bindType,isCraftingReagent=bind,reagent
        end
    end
    local message, r, g, b = Classify(name, link, quality, itemType, itemSubType,
        equipLoc, sellPrice, classID, bindType, isCraftingReagent)
    if not message then return end

    -- The existing addon already prints its more specific quest warning at merchants.
    if MerchantFrame and MerchantFrame.IsShown and MerchantFrame:IsShown()
        and type(ChalkBox_IsTrackedQuestItem) == "function"
        and ChalkBox_IsTrackedQuestItem(name) then
        return
    end
    -- Match the game's tooltip hierarchy: a muted gold section header,
    -- a short colored status, then the exact evidence on a separate line.
    -- No debug-style "LootSense: blah" prefix and no full item reskin.
    if not HasLine(tooltip,TIP_HEADER) then
        local label,details,cr,cg,cb=ChalkBox_LootPresentation(message)
        tooltip:AddLine(" ",1,1,1)
        tooltip:AddLine(TIP_HEADER,0.85,0.69,0.39)
        tooltip:AddLine(label,cr or r,cg or g,cb or b,true)
        if details and details~="" then
            tooltip:AddLine(details,0.92,0.91,0.84,true)
        end
        if type(IsShiftKeyDown)=="function" and IsShiftKeyDown()
            and type(ChalkBox_RecipeDetails)=="function" then
            local id=Public(link) and type(link)=="string" and link:match("item:(%d+)") or nil
            local detail=ChalkBox_RecipeDetails(id,name)
            if detail then tooltip:AddLine(detail,0.65,0.78,0.93,true) end
        end
        tooltip:Show()
    end
end

local function Note(message)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff55ccaaChalkBox|r " .. message)
    end
end

SLASH_CHALKBOX1 = "/chalk"
SLASH_CHALKBOX2 = "/cb"
SlashCmdList.CHALKBOX = function(input)
    if not db then return end
    local command, argument = (input or ""):match("^%s*(%S*)%s*(.-)%s*$")
    command = string.lower(command or "")
    if command == "" or command == "settings" or command == "config" or command == "options" then
        if type(ChalkBox_OpenSettings) == "function" then
            ChalkBox_OpenSettings()
        else
            Note("Open Options > AddOns > ChalkBox (or use /chalk help).")
        end
    elseif command == "keep" or command == "forget" then
        local key, label = UserItemKey(argument)
        if not key then
            Note("Shift-click an item into /chalk " .. command .. " [item], or type its exact name.")
            return
        end
        if command == "keep" then
            db.keep[key] = label
            Note("Protected " .. label .. ".")
        else
            db.keep[key] = nil
            Note("Removed your protection for " .. label .. ".")
        end
    elseif command=="loot" and argument=="scan" then
        if type(ChalkBox_ProfessionRefresh)=="function" then ChalkBox_ProfessionRefresh() end
        if type(ChalkBox_RecipeAdvisorRescan)=="function" then ChalkBox_RecipeAdvisorRescan() end
        if type(ChalkBox_BagHighlightsRefresh)=="function" then
            ChalkBox_BagHighlightsRefresh()
        end
        local source,window,knownCount="unavailable","none",0
        if type(ChalkBox_ProfessionDiagnostics)=="function" then
            source,window,knownCount=ChalkBox_ProfessionDiagnostics()
        end
        Note("Scan: "..tostring(source)..", profession "..tostring(window)..
            ", "..tostring(knownCount).." learned recipes seen. Re-hover items to refresh their tooltips.")
    elseif command=="loot" and argument=="status" then
        local prof,materials="unavailable",0
        if type(ChalkBox_ProfessionSummary)=="function" then
            prof,materials=ChalkBox_ProfessionSummary()
        end
        local state,recipes,reagents="not installed",0,0
        if type(ChalkBox_RecipeAdvisorStatus)=="function" then
            state,recipes,reagents=ChalkBox_RecipeAdvisorStatus()
        end
        local scanSource,window,learnedCount,reagentCount="unavailable","none",0,0
        if type(ChalkBox_ProfessionDiagnostics)=="function" then
            scanSource,window,learnedCount,reagentCount=ChalkBox_ProfessionDiagnostics()
        end
        Note("LootSense advice: "..(db.lootAdvice~=false and "ON" or "OFF")..
            ". If OFF, use /chalk loot on.")
        Note("Professions: "..tostring(prof).."; saved reagent keys: "..tostring(materials)..
            "; learned this scan: "..tostring(learnedCount)..
            "; active profession: "..tostring(window)..".")
        Note("Scanner: "..tostring(scanSource).."; bundled recipe catalog: "..
            tostring(state).." ("..tostring(recipes).." indexed recipes).")
        if tonumber(learnedCount)==0 then
            Note("Open a crafting window, let its recipe list load, and /chalk loot scan. Then re-hover the item.")
        end
    elseif command=="auction" or command=="auctions" or command=="ah" then
        if type(ChalkBox_AuctionCommand)=="function" then
            ChalkBox_AuctionCommand(argument)
        else Note("AuctionSense isn't available on this client.") end
    elseif command=="update" or command=="updates" then
        if type(ChalkBox_UpdateCommand)=="function" then
            ChalkBox_UpdateCommand()
        else Note("Update information unavailable.") end
    elseif command=="macro" or command=="macros" or command=="forge" then
        if type(ChalkBox_ForgeCommand)=="function" then
            ChalkBox_ForgeCommand(argument)
        else Note("MacroForge unavailable in this client.") end
    elseif command=="drops" or command=="drop" then
        if type(ChalkBox_DropCommand)=="function" then
            ChalkBox_DropCommand(argument)
        else Note("DropSense is unavailable in this client.") end
    elseif command=="session" or command=="journal" then
        if type(ChalkBox_OpenSessionJournal)=="function" then
            ChalkBox_OpenSessionJournal(argument=="last" and "last" or "current")
        else Note("Session Journal is unavailable.") end
    elseif command=="appearance" or command=="theme" then
        if type(ChalkBox_OpenSettings)=="function" then
            ChalkBox_OpenSettings("theme")
        end
    elseif command == "loot" and (argument == "on" or argument == "off") then
        db.lootAdvice = (argument == "on")
        Note("Extra item advice: " .. (db.lootAdvice and "ON" or "OFF") ..
            ". Original quest warnings remain active.")
    elseif command=="bags" or command=="bag" then
        if type(ChalkBox_BagCommand)=="function" then
            ChalkBox_BagCommand(argument)
        else
            Note("Bag positioning is unavailable on this client.")
        end
    elseif command=="meter" or command=="dps" then
        if type(ChalkBox_MeterCommand)=="function" then
            ChalkBox_MeterCommand(argument)
        else
            Note("Combat Meter unavailable on this client.")
        end
    elseif command == "quests" then
        if type(ChalkBox_QuestCommand) == "function" then
            ChalkBox_QuestCommand(argument)
        else
            Note("Zone quest tracking module unavailable.")
        end
    elseif command == "bar" then
        if type(ChalkBox_BarCommand) == "function" then
            ChalkBox_BarCommand(argument)
        else
            Note("Info bar module unavailable.")
        end
    elseif command == "prep" or command == "camp" then
        if type(ChalkBox_CampCommand)=="function" then
            ChalkBox_CampCommand(argument)
        else
            Note("CampSense module unavailable.")
        end
    elseif command == "guard" then
        if type(ChalkBox_GuardCommand)=="function" then
            ChalkBox_GuardCommand(argument)
        else
            Note("QuietGuard module unavailable.")
        end
    elseif command == "emota" then
        if type(ChalkBox_EmotaCommand) == "function" then
            ChalkBox_EmotaCommand(argument)
        else
            Note("Emota module unavailable.")
        end
    elseif command == "list" then
        local names = {}
        for _, label in pairs(db.keep) do names[#names + 1] = label end
        table.sort(names)
        if #names == 0 then
            Note("No personal protections yet.")
        else
            Note("Personal protections (" .. #names .. "): " .. table.concat(names, ", "))
        end
    else
        Note("Open settings: /chalk | /chalk settings. Commands: keep [item] | forget [item] | list | loot on/off|status|scan | bags | meter | quests | bar | emota | prep | guard | help")
        Note("LootSense shows quest protections and your character's possible/known profession uses. No automatic selling.")
        Note("Explore: /chalk drops map | map status | map on|off | /chalk drops status | chance 5 20")
        Note("Build: /chalk macro opens MacroForge | /chalk forge rescan refreshes your spellbook.")
        Note("Auctions: /chalk auction opens AuctionSense | /chalk auction scan requests a market snapshot at an auctioneer.")
        Note("Updates: /chalk update shows your installed version and GitHub Releases link.")
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, event, loadedAddon)
    if loadedAddon ~= addonName then return end
    if type(ChalkBoxDB) ~= "table" then ChalkBoxDB = {} end
    if type(ChalkBoxDB.keep) ~= "table" then ChalkBoxDB.keep = {} end
    db = ChalkBoxDB
    if db.lootAdvice == nil then db.lootAdvice = true end
    if type(db.lootCategories)~="table" then db.lootCategories={} end
    loader:UnregisterEvent("ADDON_LOADED")
end)

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall
    and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItemTooltip)
else
    GameTooltip:HookScript("OnTooltipSetItem", OnItemTooltip)
end

-- Shared read-only list used by the native options page. Item keys are never
-- inferred from displayed labels when removing a protection.
function ChalkBox_GetKeepList()
    local result = {}
    if db and type(db.keep) == "table" then
        for key, label in pairs(db.keep) do
            result[#result+1] = { key = key, label = label }
        end
    end
    table.sort(result, function(a,b)
        local an, bn = string.lower(tostring(a.label)), string.lower(tostring(b.label))
        if an ~= bn then return an < bn end
        return a.key < b.key
    end)
    return result
end

function ChalkBox_RemoveKeepKey(key)
    if db and db.keep and type(key) == "string" then
        db.keep[key] = nil
    end
end
