-- WoW Forever 1.60 test: legacy profession APIs absent, modern data loads
-- after SHOW, and some recipe schematic endpoints are incomplete.
local seenFrame,timers=nil,{}
_G.ChalkBoxProfessionDB={
    reagents={
        ["id:783"]={Cooking=true},
        ["name:light hide"]={Cooking=true}},
    recipeUses={
        ["id:783"]={["Cooking|Cured Light Hide"]={
            profession="Cooking",recipe="Cured Light Hide",quantity=1}},
        ["name:light hide"]={["Cooking|Cured Light Hide"]={
            profession="Cooking",recipe="Cured Light Hide",quantity=1}},
    }
}
-- The actual bundled Forever database puts spell 3816 in Leatherworking.
-- A stale profession heading must never relabel it as Cooking.
_G.LibStub=setmetatable({},{__call=function(_,name)
    if name~="LibProfessionDB-1.0" then return nil end
    return {GetRecipes=function(_,professionID)
        if professionID==165 then
            return {[3816]={reagents={[783]=1,[4289]=1}}}
        elseif professionID==185 then
            return {[5001]={reagents={[30817]=1}}}
        end
        return {}
    end}
end})
_G.GetProfessions=nil
_G.GetProfessionInfo=nil
_G.GetNumSkillLines=nil
_G.GetNumTradeSkills=nil
_G.GetTradeSkillLine=nil
_G.GetSpellInfo=function(spell)
    if spell==3816 then return "Cured Light Hide" end
    if spell==5001 then return "Roast Test Fish" end
    return spell==2001 and "Camp Tent" or "Alchemy Potion"
end
_G.C_Timer={After=function(delay,callback)
    assert(delay>0)
    timers[#timers+1]=callback
end}
_G.CreateFrame=function()
    local f={events={}}
    function f:RegisterEvent(event) self.events[event]=true end
    function f:SetScript(which,callback) self.callback=callback end
    seenFrame=f
    return f
end
local currentProfession=165
local recipeIDs={}
local schematic=true
_G.C_TradeSkillUI={
    GetBaseProfessionInfo=function()
        return {professionID=currentProfession,
            professionName=currentProfession==165 and "Leatherworking" or
                currentProfession==185 and "Cooking" or "Alchemy"}
    end,
    GetAllRecipeIDs=function() return recipeIDs end,
    GetProfessionInfoByRecipeID=function(recipeID)
        if recipeID==3816 then
            return {professionID=165,professionName="Leatherworking"}
        end
        -- No per-recipe profession identity for older synthetic test recipes.
        return nil
    end,
    GetRecipeInfo=function(id)
        return {name=id==3816 and "Cured Light Hide" or
            id==2001 and "Camp Tent" or nil,learned=id~=2002}
    end,
    GetRecipeSchematic=function(id)
        if schematic then
            if id==3816 then
                return {reagentSlotSchematics={{
                    quantityRequired=1,reagents={{itemID=783}}
                },{
                    quantityRequired=1,reagents={{itemID=4289}}
                }}}
            end
            return {reagentSlotSchematics={{
                quantityRequired=5,reagents={{itemID=2318}}
            }}}
        end
        return nil -- Forever's partial schematic API
    end,
    GetRecipeNumReagents=function() return 1 end,
    GetRecipeReagentInfo=function(id,index)
        return {itemID=id==2005 and 3371 or 2318,quantityRequired=2}
    end,
}
assert(loadfile("ProfessionSense.lua"))("ChalkBox")
local frame=seenFrame
assert(frame.events.TRADE_SKILL_LIST_UPDATE and
    frame.events.TRADE_SKILL_DATA_SOURCE_CHANGED,
    "must respond to modern Forever list/data-source changes")
frame.callback(frame,"ADDON_LOADED","ChalkBox")
assert(ChalkBoxProfessionDB.recipeUses["id:783"]==nil and
    ChalkBoxProfessionDB.recipeUses["name:light hide"]==nil,
    "old saved Cooking / Cured Light Hide association must be repaired")
assert(ChalkBoxProfessionDB.reagents["id:783"].Cooking==nil,
    "wrong cached known-reagent label must not survive migration")
frame.callback(frame,"TRADE_SKILL_SHOW")
assert(#ChalkBox_LearnedRecipeUses("2318","Light Leather")==0,
    "empty early recipe list must not invent learned recipes")
recipeIDs={2001,2002}
frame.callback(frame,"TRADE_SKILL_LIST_UPDATE")
assert(ChalkBox_ProfessionHas("Leatherworking"),
    "active modern profession is legitimate evidence, even without classic APIs")
local items=ChalkBox_LearnedRecipeUses("2318","Light Leather")
assert(#items==1 and items[1].recipe=="Camp Tent" and items[1].quantity==5,
    "modern learned recipe plus reagent quantity must be recorded")
assert(#ChalkBox_LearnedRecipeUses("4470","Simple Wood")==0,
    "unlearned recipes are never marked as known")
local source,window,n,m=ChalkBox_ProfessionDiagnostics()
assert(source=="modern C_TradeSkillUI" and window=="Leatherworking"
    and n==1 and m==1)
for _,cb in ipairs(timers) do cb() end
timers={}
items=ChalkBox_LearnedRecipeUses("2318","Light Leather")
assert(#items==1,"delayed scan after recipe data load must be idempotent")
currentProfession=171
recipeIDs={2005}
schematic=false
frame.callback(frame,"TRADE_SKILL_DATA_SOURCE_CHANGED")
assert(ChalkBox_ProfessionHas("Alchemy"),"data source change detects next profession")
local potion=ChalkBox_LearnedRecipeUses("3371","Empty Vial")
assert(#potion==1 and potion[1].profession=="Alchemy"
    and potion[1].quantity==2,
    "incomplete schematic must fall back to GetRecipeNumReagents")
frame.callback(frame,"PLAYER_ENTERING_WORLD")
assert(ChalkBox_ProfessionHas("Alchemy"),
    "on modern-only client, observed profession survives refresh")
-- Simulate Forever's transient mismatch: profession header says Cooking,
-- but the recipe list still contains a learned Leatherworking recipe.
currentProfession=185
recipeIDs={3816}
schematic=true
frame.callback(frame,"TRADE_SKILL_DATA_SOURCE_CHANGED")
assert(#ChalkBox_LearnedRecipeUses(783,"Light Hide")==0,
    "stale cross-profession list must never become learned Cooking")
assert(ChalkBoxProfessionDB.recipeUses["id:783"]==nil,
    "wrong new recipe must not be written to saved variables")
-- The independent bundled catalog must catch the same contamination
-- even on Forever builds without GetProfessionInfoByRecipeID.
C_TradeSkillUI.GetProfessionInfoByRecipeID=nil
frame.callback(frame,"TRADE_SKILL_DATA_SOURCE_CHANGED")
assert(#ChalkBox_LearnedRecipeUses(783,"Light Hide")==0,
    "offline recipe ID ownership rejects stale Cooking data")
-- Legacy trade-skill APIs can also lag a profession/source switch.
_G.GetTradeSkillLine=function() return "Cooking" end
_G.GetNumTradeSkills=function() return 1 end
_G.GetTradeSkillInfo=function() return "Cured Light Hide","optimal" end
_G.GetTradeSkillNumReagents=function() return 1 end
_G.GetTradeSkillReagentInfo=function() return "Light Hide",nil,1 end
_G.GetTradeSkillReagentItemLink=function() return "item:783" end
frame.callback(frame,"TRADE_SKILL_DATA_SOURCE_CHANGED")
assert(#ChalkBox_LearnedRecipeUses(783,"Light Hide")==0,
    "legacy stale Cooking recipe title cannot contaminate saved data")
-- After the client settles on Leatherworking, the legitimate scan can
-- re-establish the correct learned association.
currentProfession=165
frame.callback(frame,"TRADE_SKILL_DATA_SOURCE_CHANGED")
local hides=ChalkBox_LearnedRecipeUses(783,"Light Hide")
assert(#hides==1 and hides[1].profession=="Leatherworking" and
    hides[1].recipe=="Cured Light Hide" and hides[1].recipeID==3816,
    "actual Leatherworking list restores the correct profession and recipe ID")
print("PASS: Forever live recipe identity, stale modern and legacy headings, saved Cooking corruption migration and proper new recipe ownership")
