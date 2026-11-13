-- ChalkBox RecipeAdvisor: our own safety-first item relevance logic.
-- Bundled LibProfessionDB-1.0 by Pimptasty (MIT), Forever-only core data.
-- All rules below are ChalkBox's independent item-advice logic.
local index,ready,lastCheck={},false,-1e8
local stats={recipes=0,reagents=0,state="not installed"}
local professions={
    [171]="Alchemy",[164]="Blacksmithing",[165]="Leatherworking",
    [197]="Tailoring",[202]="Engineering",[333]="Enchanting",
    [185]="Cooking",[129]="First Aid",[755]="Jewelcrafting",
    [773]="Inscription",[182]="Herbalism",[186]="Mining",
    [393]="Skinning",[356]="Fishing",
}
local function Safe(v)
    return v~=nil and (type(issecretvalue)~="function" or not issecretvalue(v))
end
local function Library()
    -- WoW LibStub is commonly a callable table, not a Lua function.
    if type(LibStub)~="function" and
        not (type(LibStub)=="table" and type(LibStub.GetLibrary)=="function") then
        return nil
    end
    local ok,db=pcall(LibStub,"LibProfessionDB-1.0",true)
    if not ok or type(db)~="table" or type(db.IsReady)~="function" then return nil end
    local readyOk,available=pcall(db.IsReady,db)
    if not readyOk or available~=true then return nil end
    if type(db.GetGameVersion)=="function" then
        local versionOk,version=pcall(db.GetGameVersion,db)
        if not versionOk or version~="Forever" then return nil end
    end
    return db
end
-- The library stores reagents as item-ID keyed values in its own data model.
-- Accept numeric maps and common {itemID, count} records, but refuse any
-- ambiguous shape; never guess that an unrecognized material belongs to a recipe.
local function ReadReagent(reagents,consumer)
    if type(reagents)~="table" then return end
    for key,value in pairs(reagents) do
        local id,count
        if type(value)=="number" and tonumber(key) then
            id,count=tonumber(key),value
        elseif type(value)=="table" then
            id=tonumber(value.itemID or value.itemId or value.id or value[1])
            count=tonumber(value.count or value.quantity or value[2])
            -- { [itemID] = { count = N } } is also supported.
            if not id and tonumber(key) then id=tonumber(key) end
        end
        if id and id>0 and count and count>0 then consumer(id,math.floor(count)) end
    end
end
local function DisplayName(record)
    if Safe(record.recipe) and type(record.recipe)=="string" and record.recipe~="" then
        return record.recipe
    end
    local spell=record.spellID
    if type(GetSpellInfo)=="function" then
        local ok,name=pcall(GetSpellInfo,spell)
        if ok and Safe(name) and type(name)=="string" and name~="" then
            record.recipe=name
            return name
        end
    end
    if C_Spell and type(C_Spell.GetSpellName)=="function" then
        local ok,name=pcall(C_Spell.GetSpellName,spell)
        if ok and Safe(name) and type(name)=="string" and name~="" then
            record.recipe=name
            return name
        end
    end
    -- A valid recipe record without a localized name is still evidence of a
    -- possible use. Mark the missing text honestly instead of hiding it.
    return "recipe #"..tostring(spell).." (name unavailable)"
end

local function Register(profession,spellID,recipe)
    if type(recipe)~="table" then return end
    local name=Safe(recipe.name) and type(recipe.name)=="string" and recipe.name or nil
    if type(recipe.reagents)~="table" then return end
    local found=false
    ReadReagent(recipe.reagents,function(id,qty)
        index[id]=index[id] or {}
        index[id][#index[id]+1]={
            recipe=name,profession=profession,quantity=qty,spellID=spellID
        }
        stats.reagents=stats.reagents+1
        found=true
    end)
    if found then stats.recipes=stats.recipes+1 end
end
local function Load()
    if ready then return true end
    local now=type(GetTime)=="function" and GetTime() or nil
    if type(now)=="number" and Safe(now) then
        if now-lastCheck<15 then return false end
        lastCheck=now
    end
    local db=Library()
    if not db then stats.state="not loaded";return false end
    if type(db.GetRecipes)~="function" then
        stats.state="unsupported API"
        return false
    end
    local pending={}
    local counted=0
    local ok=pcall(function()
        for profId,profession in pairs(professions) do
            local recipes=db:GetRecipes(profId)
            if type(recipes)=="table" then
                for key,record in pairs(recipes) do
                    counted=counted+1
                    if counted>20000 then error("too many recipe rows") end
                    local spellID=tonumber(key)
                    if type(record)=="number" then spellID=record end
                    if type(record)=="table" then
                        spellID=tonumber(record.spellID or record.spellId or record.id) or spellID
                    end
                    local recipe=type(record)=="table" and record or nil
                    if not recipe and spellID and type(db.GetRecipe)=="function" then
                        recipe=db:GetRecipe(profId,spellID)
                    end
                    if recipe and spellID then
                        pending[#pending+1]={profession,spellID,recipe}
                    end
                end
            end
        end
    end)
    if not ok then
        stats.state="API incompatible"
        return false
    end
    index={}
    stats.recipes=0;stats.reagents=0
    for _,record in ipairs(pending) do
        Register(record[1],record[2],record[3])
    end
    ready=stats.recipes>0
    stats.state=ready and "bundled" or "empty data"
    return ready
end
local function BagCount(itemID)
    local fn=type(GetItemCount)=="function" and GetItemCount
        or C_Item and C_Item.GetItemCount
    if type(fn)~="function" then return nil end
    local ok,count=pcall(fn,itemID,false,false)
    if ok and Safe(count) and type(count)=="number" and count>=0 then
        return math.floor(count)
    end
end
local function Known(itemID,itemName)
    if type(ChalkBox_LearnedRecipeUses)~="function" then return {} end
    return ChalkBox_LearnedRecipeUses(itemID,itemName)
end
local function ChooseCandidate(itemID,known)
    if not ready then Load() end
    local list=index[tonumber(itemID)] or {}
    local seen={}
    for _,r in ipairs(known) do seen[r.profession.."|"..r.recipe]=true end
    -- Stable ordering keeps a tooltip from changing between hovers.
    table.sort(list,function(a,b)
        if a.profession~=b.profession then return a.profession<b.profession end
        return a.spellID<b.spellID
    end)
    local selected,also= nil,nil
    for _,r in ipairs(list) do
        if not seen[r.profession.."|"..r.recipe] then
            if type(ChalkBox_ProfessionHas)=="function" and
                ChalkBox_ProfessionHas(r.profession) then
                if not selected then selected=r end
            elseif not also then also=r end
        end
    end
    return selected,also,#list
end
local function FormatKnown(entry,itemID,count)
    local line="KNOWN RECIPE: "..entry.recipe.." ("..entry.profession..")"
    if entry.quantity and count then
        line=line.." - "..count.."/"..entry.quantity.." in bags"
    elseif entry.quantity then
        line=line.." - requires "..entry.quantity
    end
    return line
end
function ChalkBox_RecipeAdvice(itemID,itemName)
    local known=Known(itemID,itemName)
    local count=BagCount(tonumber(itemID))
    if #known>0 then
        -- An actual recipe scan is proof; a public database alone never is.
        return FormatKnown(known[1],itemID,count),0.30,0.97,0.51,
            {kind="known",known=known}
    end
    local prospective,other,total=ChooseCandidate(itemID,known)
    if prospective then
        return "POTENTIAL USE: "..DisplayName(prospective).." ("..
            prospective.profession..", not confirmed learned)",0.84,0.88,0.48,
            {kind="future",total=total}
    end
    if other then
        return "OTHER PROFESSION: "..DisplayName(other).." ("..
            other.profession.."; not your current craft)",0.69,0.77,0.83,
            {kind="other",total=total}
    end
end
function ChalkBox_RecipeDetails(itemID,itemName)
    local known=Known(itemID,itemName)
    if #known<=1 then return nil end
    local parts={}
    for i=2,math.min(#known,4) do
        parts[#parts+1]=known[i].recipe.." ("..known[i].profession..")"
    end
    return "Other learned recipes: "..table.concat(parts,", ")
end
function ChalkBox_RecipeAdvisorStatus()
    Load()
    return stats.state,stats.recipes,stats.reagents
end
function ChalkBox_RecipeAdvisorRescan()
    ready=false;index={}
    lastCheck=-1e8
    stats.recipes=0;stats.reagents=0
    return Load()
end
local events=CreateFrame("Frame")
for _,name in ipairs({"PLAYER_ENTERING_WORLD","ADDON_LOADED"}) do
    events:RegisterEvent(name)
end
events:SetScript("OnEvent",function(_,event,name)
    if event=="PLAYER_ENTERING_WORLD" then Load() end
    if event=="ADDON_LOADED" and (name=="ProfessionDB" or name=="ChalkBox") then
        if ready==false then Load() end
    end
end)
