-- WoW Forever 1.60 test: legacy profession APIs absent, modern data loads
-- after SHOW, and some recipe schematic endpoints are incomplete.
local seenFrame,timers={}
_G.ChalkBoxProfessionDB=nil
_G.GetProfessions=nil
_G.GetProfessionInfo=nil
_G.GetNumSkillLines=nil
_G.GetNumTradeSkills=nil
_G.GetTradeSkillLine=nil
_G.GetSpellInfo=function(spell) return spell==2001 and "Camp Tent" or "Alchemy Potion" end
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
            professionName=currentProfession==165 and "Leatherworking" or "Alchemy"}
    end,
    GetAllRecipeIDs=function() return recipeIDs end,
    GetRecipeInfo=function(id)
        return {name=id==2001 and "Camp Tent" or nil,learned=id~=2002}
    end,
    GetRecipeSchematic=function(id)
        if schematic then
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
print("PASS: Forever-only modern profession scanning, late list update, learned/unlearned, schema fallback, source switch and diagnostics")
