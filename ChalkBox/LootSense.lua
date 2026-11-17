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
-- The category carries the meaning; the second line is only evidence.
-- Avoid repeating "Item Insight", the module name, or the category itself.
local function Insight(label,details,role,red,green,blue)
    if type(ChalkBox_TipColor)=="function" then
        red,green,blue=ChalkBox_TipColor(role)
    end
    if type(details)=="string" then
        details=details:gsub(" %- ","  ·  ")
            :gsub("^protected by you$","Personal protection")
            :gsub("^accepted quest needs this$","Needed for active quest")
            :gsub("^possible ","Possible ")
            :gsub("not confirmed learned","learned status unknown")
    end
    return label,details,red,green,blue
end
function ChalkBox_LootPresentation(message)
    if type(message)~="string" then return end
    local prefix,body=message:match("^([^:]+):%s*(.*)$")
    if prefix=="KEEP" then
        local quest=body=="quest item" or body=="accepted quest needs this"
        return Insight("KEEP",body,quest and "warning" or "good",
            0.39,0.94,0.62)
    elseif prefix=="KNOWN RECIPE" then
        return Insight("LEARNED RECIPE",body,"good",0.39,0.94,0.62)
    elseif prefix=="POTENTIAL USE" then
        return Insight("POSSIBLE RECIPE",body,"warning",0.98,0.66,0.33)
    elseif prefix=="OTHER PROFESSION" then
        return Insight("OTHER PROFESSION",body,"count",0.51,0.76,0.98)
    elseif prefix=="PROFESSION" then
        local confirmed=body and body:find("used in a learned",1,true)
        if confirmed then
            body=body:gsub("^used in a learned ","")
        end
        if not confirmed then
            body=body:gsub("^possible (.-) material %(check recipes%)$",
                "%1  ·  Check recipes")
        end
        return Insight(confirmed and "LEARNED USE" or "POSSIBLE MATERIAL",
            body,confirmed and "good" or "warning",
            confirmed and 0.39 or 0.98,
            confirmed and 0.94 or 0.66,
            confirmed and 0.62 or 0.33)
    elseif prefix=="CAMP SUPPLY" then
        return Insight("CAMP SUPPLY",body,"info",0.40,0.83,0.78)
    elseif prefix=="CAMP TOOL" then
        return Insight("CAMP TOOL",body,"info",0.40,0.83,0.78)
    elseif prefix=="CAMP" or prefix=="CAMP REAGENT" then
        return Insight("CAMP USE",body,"info",0.40,0.83,0.78)
    elseif prefix=="XP UTILITY" then
        return Insight("BONUS XP",body,"good",0.39,0.94,0.62)
    end
    return Insight("ITEM NOTE",message,"text",0.85,0.87,0.88)
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
    -- Read-only DE economics: never auto-cast, alter bag buttons, or suggest
    -- destroying protected/quest items. The item tooltip owns the display.
    if type(ChalkBox_DisenchantTooltip)=="function" then
        local protected=IsProtected(name,link) or
            (type(ChalkBox_IsTrackedQuestItem)=="function" and
                ChalkBox_IsTrackedQuestItem(name))
        pcall(ChalkBox_DisenchantTooltip,tooltip,link,protected)
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
    -- The meaningful classification IS the heading. Do not repeat
    -- brand/module names inside Blizzard's item tooltip.
    local label,details,cr,cg,cb=ChalkBox_LootPresentation(message)
    -- Core.lua already cached the exact accepted-quest titles and
    -- item objective progress. Reuse it; never guess a quest from the
    -- item class or require a second quest-log scan on tooltip hover.
    local quests
    if label=="KEEP" and type(ChalkBox_QuestItemDetails)=="function" then
        local ok,found=pcall(ChalkBox_QuestItemDetails,name)
        if ok and type(found)=="table" then quests=found end
    end
    -- Quest-class metadata by itself only says the item is a Quest item,
    -- not WHICH quest uses it. QuestieDB supplies reverse item-ID links
    -- (including quests not in the player's log), when installed.
    local dbLinks
    local questLinkState
    if label=="KEEP" and (not quests or #quests==0)
        and type(ChalkBox_QuestItemDatabaseLinks)=="function" then
        local itemID=Public(link) and type(link)=="string" and
            tonumber(link:match("item:(%d+)")) or nil
        if itemID then
            local ok,found=pcall(ChalkBox_QuestItemDatabaseLinks,itemID)
            if ok and type(found)=="table" then dbLinks=found end
        end
        if type(ChalkBox_QuestItemDatabaseStatus)=="function" then
            local ok,state=pcall(ChalkBox_QuestItemDatabaseStatus)
            if ok and type(state)=="string" then questLinkState=state end
        end
    end
    if label and not HasLine(tooltip,label) then
        tooltip:AddLine(" ",1,1,1)
        tooltip:AddLine(label,cr or r,cg or g,cb or b,true)
        if quests and #quests>0 and
            message=="KEEP: accepted quest needs this" then
            if #quests==1 and type(quests[1].title)=="string" then
                details="Needed for: "..quests[1].title
            else
                details="Needed for "..#quests.." accepted quests"
            end
        end
        if message=="KEEP: quest item" and (not quests or #quests==0) then
            if dbLinks and #dbLinks>0 then
                details="Known quest connections"
            elseif questLinkState=="indexing" or questLinkState=="not started" then
                details="Quest lookup loading; re-hover in a moment"
            elseif questLinkState=="QuestieDB unavailable" then
                details="Quest item (QuestieDB not installed)"
            else
                details="Quest item (no verified quest link yet)"
            end
        end
        if details and details~="" then
            -- Evidence stays quieter than the action/category heading.
            local dr,dg,db=0.85,0.87,0.88
            if type(ChalkBox_TipColor)=="function" then
                dr,dg,db=ChalkBox_TipColor("text")
            end
            tooltip:AddLine(details,dr,dg,db,true)
        end
        if quests and #quests>0 then
            if #quests==1 then
                local q=quests[1]
                if message~="KEEP: accepted quest needs this" and
                    type(q.title)=="string" then
                    tooltip:AddLine("Needed for: "..q.title,
                        0.88,0.84,0.70,true)
                end
                if type(q.have)=="number" and
                    type(q.required)=="number" and q.required>0 then
                    local progress=("%d / %d collected"):format(
                        q.have,q.required)
                    if q.complete then
                        progress=progress.."  ·  Objective complete"
                    end
                    local pr,pg,pb=0.51,0.76,0.98
                    if type(ChalkBox_TipColor)=="function" then
                        pr,pg,pb=ChalkBox_TipColor("count")
                    end
                    tooltip:AddLine(progress,pr,pg,pb,true)
                end
            else
                -- Accepted-quest list length is bounded by the quest log.
                -- Display each matching quest, including completed
                -- objectives that should remain protected until turn-in.
                for _,q in ipairs(quests) do
                    if type(q.title)=="string" and q.title~="" then
                        local line=q.title
                        if type(q.have)=="number" and
                            type(q.required)=="number" and q.required>0 then
                            line=line..("  ·  %d/%d"):format(
                                q.have,q.required)
                        end
                        if q.complete then line=line.."  ·  Complete" end
                        tooltip:AddLine(line,0.83,0.85,0.78,true)
                    end
                end
            end
        end
        -- Database relations are specific to item ID. A reward, starter
        -- and required collection item are different claims, so label them
        -- separately instead of calling every link "needed".
        if dbLinks and #dbLinks>0 then
            local roleNames={
                objective="Needed for",required="Needed for",
                used="Used for",starts="Starts quest",
                provided="Provided by",related="Related to",
            }
            local maxLines=math.min(#dbLinks,5)
            for i=1,maxLines do
                local q=dbLinks[i]
                if type(q)=="table" and type(q.title)=="string"
                    and q.title~="" then
                    local prefix=roleNames[q.role] or "Related to"
                    local line=prefix..": "..q.title
                    if q.active==true then
                        line=line.."  ·  In quest log"
                    elseif q.complete==true then
                        line=line.."  ·  Completed"
                    elseif q.active==false then
                        line=line.."  ·  Not in quest log"
                    end
                    tooltip:AddLine(line,0.88,0.84,0.70,true)
                end
            end
            if #dbLinks>maxLines then
                tooltip:AddLine("+"..(#dbLinks-maxLines)..
                    " more quest connections",0.72,0.76,0.78,true)
            end
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
        if type(ChalkBox_QuestItemDatabaseStatus)=="function" then
            local ok,phase,done,total=pcall(ChalkBox_QuestItemDatabaseStatus)
            if ok then
                Note("Quest item links (QuestieDB): "..tostring(phase)..
                    (type(done)=="number" and done>0 and
                        ("; indexed "..done.." quests") or "")..
                    (phase=="indexing" and type(total)=="number" and
                        ("/"..total) or "")..".")
            end
        end
        if tonumber(learnedCount)==0 then
            Note("Open a crafting window, let its recipe list load, and /chalk loot scan. Then re-hover the item.")
        end
    elseif command=="de" or command=="disenchant" then
        if type(ChalkBox_DisenchantCommand)=="function" then
            ChalkBox_DisenchantCommand(argument)
        else Note("DE estimates unavailable in this client.") end
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
    elseif command == "nav" or command == "navigate" then
        if type(ChalkBox_NavCommand)=="function" then
            ChalkBox_NavCommand(argument)
        else
            Note("Quest navigation unavailable on this client.")
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
        Note("Open settings: /chalk | /chalk settings. Commands: keep [item] | forget [item] | list | loot on/off|status|scan | bags | meter | quests | nav | bar | emota | prep | guard | help")
        Note("LootSense shows quest protections and your character's possible/known profession uses. No automatic selling.")
        Note("Explore: /chalk drops map | map status | map on|off | /chalk drops status | chance 5 20")
        Note("Build: /chalk macro opens MacroForge | /chalk forge rescan refreshes your spellbook.")
        Note("Auctions: at an auctioneer, open the AuctionSense tab. /chalk auction scan = browse prices; /chalk auction full = full listing request (15m cooldown).")
        Note("Disenchant: hover green/blue gear for modeled outcomes or /chalk de [item link]. /chalk de on|off toggles tooltip estimates.")
        Note("Quest navigation: /chalk nav on|off|auto|next|prev|follow ID|lock|unlock|reset|status")
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
