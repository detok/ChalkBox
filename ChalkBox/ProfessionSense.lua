-- ChalkBox ProfessionSense: what the CURRENT character can actually use.
-- Prefer known recipe reagents gathered from the profession UI; use a clearly
-- qualified family hint only when no known recipe has been observed.
-- Never assumes gathering profession = consuming craft profession.
local addonName = ...
local learned = {}
local recipeUses = {}
local available = {}
local seenWindow = {}
local loaded = false
local scan = {source="not scanned", recipes=0, reagents=0, lastWindow="none", retries=0}
local scanScheduled = false

local ids = {
    [171]="Alchemy", [164]="Blacksmithing", [165]="Leatherworking",
    [197]="Tailoring", [202]="Engineering", [333]="Enchanting",
    [185]="Cooking", [129]="First Aid", [755]="Jewelcrafting",
    [773]="Inscription", [182]="Herbalism", [186]="Mining",
    [393]="Skinning", [356]="Fishing",
}
local craft = {
    ["alchemy"]="Alchemy", ["blacksmithing"]="Blacksmithing",
    ["leatherworking"]="Leatherworking", ["tailoring"]="Tailoring",
    ["engineering"]="Engineering", ["enchanting"]="Enchanting",
    ["cooking"]="Cooking", ["first aid"]="First Aid",
    ["jewelcrafting"]="Jewelcrafting", ["inscription"]="Inscription",
    ["herbalism"]="Herbalism", ["mining"]="Mining",
    ["skinning"]="Skinning", ["fishing"]="Fishing",
}
local function Safe(value)
    return value ~= nil and (type(issecretvalue) ~= "function" or not issecretvalue(value))
end
local function Normalize(name, skill)
    if Safe(skill) and ids[skill] then return ids[skill] end
    if not Safe(name) or type(name) ~= "string" then return nil end
    local low = string.lower(name)
    for needle,pretty in pairs(craft) do
        if low:find(needle, 1, true) then return pretty end
    end
    return nil
end

-- Professions in Forever can be visible through the modern trade UI even
-- when Classic's GetProfessions / skill-list endpoints do not expose them.
-- Treat a real opened profession as positive evidence; do not require an
-- unrelated legacy API to grant permission to scan its recipes.
local function ReadProfessions()
    local found = {}
    if type(GetProfessions)=="function" and type(GetProfessionInfo)=="function" then
        local ok,p1,p2,arch,fish,cook=pcall(GetProfessions)
        if ok then
            for _,idx in ipairs({p1 or false,p2 or false,arch or false,
                fish or false,cook or false}) do
                if idx and Safe(idx) then
                    local infoOK,name,icon,rank,maxRank,_,_,skillID=
                        pcall(GetProfessionInfo,idx)
                    if infoOK then
                        local normalized=Normalize(name,skillID)
                        if normalized then found[normalized]=true end
                    end
                end
            end
        end
    end
    if type(GetNumSkillLines)=="function" and type(GetSkillLineInfo)=="function" then
        local ok,n=pcall(GetNumSkillLines)
        if ok and Safe(n) and type(n)=="number" then
            for i=1,math.min(n,400) do
                local lineOK,name,isHeader,_,_,_,_,_,_,_,_,_,_,skillID=
                    pcall(GetSkillLineInfo,i)
                if lineOK then
                    -- Classic puts professions under headers, and some builds
                    -- report the profession itself as a header. Check both.
                    local normalized=Normalize(name,skillID)
                    if normalized then found[normalized]=true end
                end
            end
        end
    end
    local sawAny=next(found)~=nil
    if not sawAny then
        for name in pairs(seenWindow) do found[name]=true end
    else
        -- An actual profession API enumerating currently owned skills wins.
        -- It also avoids showing a removed profession indefinitely.
        for name in pairs(seenWindow) do
            if not found[name] then seenWindow[name]=nil end
        end
    end
    available=found
end

local function AddReagent(profession, link, name, recipeName, quantity)
    if not profession then return end
    available[profession]=true
    seenWindow[profession]=true
    if type(link)=="number" then link="item:"..tostring(link) end
    scan.reagents=scan.reagents+1
    local keys={}
    if Safe(link) and type(link)=="string" then
        local id=link:match("item:(%d+)")
        if id then keys[#keys+1]="id:"..id end
    end
    if Safe(name) and type(name)=="string" and name~="" then
        keys[#keys+1]="name:"..string.lower(name)
    end
    if Safe(recipeName) and type(recipeName)=="string" and recipeName~=""
        and #keys>0 and type(ChalkBoxProfessionDB)=="table" then
        local key=profession.."|"..recipeName
        for _,itemKey in ipairs(keys) do
            recipeUses[itemKey]=recipeUses[itemKey] or {}
            recipeUses[itemKey][key]={
                profession=profession,recipe=recipeName,
                quantity=Safe(quantity) and type(quantity)=="number" and
                    quantity>0 and math.floor(quantity) or nil
            }
        end
    end
    if Safe(link) and type(link) == "string" then
        local itemID = link:match("item:(%d+)")
        if itemID then
            learned["id:" .. itemID] = learned["id:" .. itemID] or {}
            learned["id:" .. itemID][profession] = true
        end
    end
    if Safe(name) and type(name) == "string" and name ~= "" then
        local key = "name:" .. string.lower(name)
        learned[key] = learned[key] or {}
        learned[key][profession] = true
    end
end

local function ReadLegacyTrade()
    if type(GetTradeSkillLine) ~= "function" or type(GetNumTradeSkills) ~= "function"
        or type(GetTradeSkillInfo) ~= "function" then return end
    local name = GetTradeSkillLine()
    local profession = Normalize(name)
    if not profession or not available[profession] then return end
    local count = GetNumTradeSkills()
    if not Safe(count) or type(count) ~= "number" then return end
    for i=1,math.min(count,1200) do
        local recipeName,kind = GetTradeSkillInfo(i)
        if kind ~= "header" and kind ~= "subheader" and kind ~= "unavailable" then
            local n = type(GetTradeSkillNumReagents) == "function" and GetTradeSkillNumReagents(i) or 0
            if Safe(n) and type(n) == "number" then
                for j=1,math.min(n,25) do
                    local reagent,link
                    local required
                    if type(GetTradeSkillReagentInfo)=="function" then
                        local _; reagent,_,required=GetTradeSkillReagentInfo(i,j)
                    end
                    if type(GetTradeSkillReagentItemLink)=="function" then link=GetTradeSkillReagentItemLink(i,j) end
                    AddReagent(profession,link,reagent,recipeName,required)
                end
            end
        end
    end
end

local function ReadLegacyCraft()
    if type(GetCraftDisplaySkillLine) ~= "function" or type(GetNumCrafts) ~= "function" then return end
    local profession = Normalize(GetCraftDisplaySkillLine())
    if not profession or not available[profession] then return end
    local count = GetNumCrafts()
    if not Safe(count) or type(count) ~= "number" then return end
    for i=1,math.min(count,1200) do
        local kind,recipeName
        if type(GetCraftInfo)=="function" then
            local subtype
            recipeName,subtype,kind=GetCraftInfo(i)
        end
        if kind ~= "header" and kind ~= "subheader" then
            local n = type(GetCraftNumReagents) == "function" and GetCraftNumReagents(i) or 0
            if Safe(n) and type(n) == "number" then
                for j=1,math.min(n,25) do
                    local reagent,link
                    local required
                    if type(GetCraftReagentInfo)=="function" then
                        local _; reagent,_,required=GetCraftReagentInfo(i,j)
                    end
                    if type(GetCraftReagentItemLink)=="function" then link=GetCraftReagentItemLink(i,j) end
                    AddReagent(profession,link,reagent,recipeName,required)
                end
            end
        end
    end
end

local function ReadModernTrade()
    local api = C_TradeSkillUI
    if not api or type(api.GetAllRecipeIDs) ~= "function"
        or type(api.GetRecipeInfo) ~= "function" then return end
    local base = type(api.GetBaseProfessionInfo) == "function" and api.GetBaseProfessionInfo()
    local profession = base and Normalize(base.professionName,base.professionID)
    if not profession or not available[profession] then return end
    local recipes = api.GetAllRecipeIDs()
    if type(recipes) ~= "table" then return end
    for i=1,math.min(#recipes,1600) do
        local id = recipes[i]
        if Safe(id) and type(id) == "number" then
            local info = api.GetRecipeInfo(id)
            if type(info) == "table" and info.learned == true then
                if type(api.GetRecipeSchematic) == "function" then
                    local schematic = api.GetRecipeSchematic(id,false)
                    if type(schematic) == "table" and type(schematic.reagentSlotSchematics) == "table" then
                        for _,slot in ipairs(schematic.reagentSlotSchematics) do
                            if type(slot) == "table" and type(slot.reagents) == "table" then
                                for _,reagent in ipairs(slot.reagents) do
                                    if type(reagent) == "table" and Safe(reagent.itemID)
                                        and type(reagent.itemID) == "number" then
                                        AddReagent(profession,"item:"..reagent.itemID,nil,info.name,
                                            slot.quantityRequired or reagent.quantityRequired)
                                    end
                                end
                            end
                        end
                    end
                elseif type(api.GetRecipeNumReagents) == "function"
                    and type(api.GetRecipeReagentInfo) == "function" then
                    local n = api.GetRecipeNumReagents(id)
                    if Safe(n) and type(n) == "number" then
                        for j=1,math.min(n,25) do
                            local reagent = api.GetRecipeReagentInfo(id,j)
                            if type(reagent) == "table" then
                                AddReagent(profession,reagent.itemLink,reagent.name,info.name,
                                    reagent.quantityRequired or reagent.quantity)
                            end
                        end
                    end
                end
            end
        end
    end
end

local function Refresh()
    ReadProfessions()
    if type(ChalkBoxProfessionDB) ~= "table" then ChalkBoxProfessionDB = {} end
    if type(ChalkBoxProfessionDB.reagents) ~= "table" then ChalkBoxProfessionDB.reagents = {} end
    learned = ChalkBoxProfessionDB.reagents
    if type(ChalkBoxProfessionDB.recipeUses)~="table" then
        ChalkBoxProfessionDB.recipeUses={}
    end
    recipeUses=ChalkBoxProfessionDB.recipeUses
    loaded = true
end

local families = {
    {match={"leather","hide","scale"}, professions={"Leatherworking"}},
    {match={"cloth"},professions={"Tailoring","First Aid"}},
    {match={"herb"},professions={"Alchemy","Inscription"}},
    {match={"metal","stone","ore","bar"},professions={"Blacksmithing","Engineering","Jewelcrafting"}},
    {match={"enchant"},professions={"Enchanting"}},
    {match={"meat","fish","food"},professions={"Cooking"}},
    {match={"gem"},professions={"Jewelcrafting"}},
    {match={"parts","device"},professions={"Engineering"}},
}
local function Known(id,name)
    local result = {}
    local function Collect(key)
        if learned[key] then
            for prof in pairs(learned[key]) do
                if available[prof] then result[prof]=true end
            end
        end
    end
    if id then Collect("id:"..id) end
    if Safe(name) and type(name) == "string" then Collect("name:"..string.lower(name)) end
    local keys={}
    for prof in pairs(result) do keys[#keys+1]=prof end
    table.sort(keys)
    return keys[1]
end

function ChalkBox_ProfessionMatch(itemID,itemName,itemSubType,classID)
    if not loaded then return end
    local id = Safe(itemID) and itemID and tostring(itemID):match("^(%d+)$")
    local known = Known(id,itemName)
    if known then return known,"known" end
    if classID ~= 7 or not Safe(itemSubType) or type(itemSubType) ~= "string" then return end
    local low=string.lower(itemSubType)
    for _,family in ipairs(families) do
        for _,pattern in ipairs(family.match) do
            if low:find(pattern,1,true) then
                for _,prof in ipairs(family.professions) do
                    if available[prof] then return prof,"possible" end
                end
            end
        end
    end
end

-- Saved per-character recipe names only come from the character's actual
-- learned trade/craft windows. Never infer a recipe is known from an offline DB.
function ChalkBox_LearnedRecipeUses(itemID,itemName)
    local entries,seen={},{}
    local function Include(key)
        local set=recipeUses[key]
        if type(set)~="table" then return end
        for id,entry in pairs(set) do
            if type(entry)=="table" and type(entry.profession)=="string"
                and available[entry.profession] and type(entry.recipe)=="string"
                and not seen[id] then
                entries[#entries+1]=entry
                seen[id]=true
            end
        end
    end
    if Safe(itemID) and tonumber(itemID) then Include("id:"..tostring(tonumber(itemID))) end
    if Safe(itemName) and type(itemName)=="string" then
        Include("name:"..string.lower(itemName))
    end
    table.sort(entries,function(a,b)
        if a.profession~=b.profession then return a.profession<b.profession end
        return a.recipe<b.recipe
    end)
    return entries
end
function ChalkBox_ProfessionHas(name)
    return type(name)=="string" and available[name]==true
end

function ChalkBox_ProfessionSummary()
    local names={}
    for name in pairs(available) do names[#names+1]=name end
    table.sort(names)
    local recipes=0
    for _ in pairs(learned) do recipes=recipes+1 end
    return #names>0 and table.concat(names,", ") or "None detected",recipes
end

function ChalkBox_ProfessionRefresh()
    Refresh()
    ReadLegacyTrade()
    ReadLegacyCraft()
    ReadModernTrade()
end

local events=CreateFrame("Frame")
for _,event in ipairs({"ADDON_LOADED","PLAYER_ENTERING_WORLD","SKILL_LINES_CHANGED",
    "TRADE_SKILL_SHOW","TRADE_SKILL_UPDATE","CRAFT_SHOW","CRAFT_UPDATE",
    "NEW_RECIPE_LEARNED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function(_,event,name)
    if event=="ADDON_LOADED" then
        if name~=addonName then return end
        Refresh()
    elseif event=="SKILL_LINES_CHANGED" or event=="PLAYER_ENTERING_WORLD" then
        ReadProfessions()
    elseif loaded then
        ChalkBox_ProfessionRefresh()
    end
end)
