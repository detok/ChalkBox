-- Integration test against the real, legally bundled Forever-only 1.9.1 data.
_G.GetBuildInfo=function() return "1.60.1","release","",16001 end
_G.GetLocale=function() return "enUS" end
_G.GetSpellInfo=function(id) return "Spell recipe "..tostring(id) end
_G.GetItemCount=function() return 3 end
local frames={}
_G.CreateFrame=function()
    local f={}
    function f:RegisterEvent() end
    function f:SetScript(which,fn) self[which]=fn end
    frames[#frames+1]=f
    return f
end
dofile("Libs/LibStub/LibStub.lua")
dofile("Libs/LibProfessionDB-1.0/LibProfessionDB-1.0.lua")
local names={"Alchemy","Blacksmithing","Cooking","Enchanting","Engineering",
    "Firstaid","Fishing","Leatherworking","Mining","Tailoring",
    "RecipeItems","HiddenRecipes","AcquireMethods","Sources","SourceNames"}
for _,name in ipairs(names) do
    dofile("Libs/LibProfessionDB-1.0/Data/"..name..".lua")
end
local db=LibStub("LibProfessionDB-1.0",true)
assert(db and db:IsReady() and db:GetGameVersion()=="Forever")
assert(db:Count()==2511, "must load all 2511 Forever recipes, not Classic or Retail")
assert(type(db:GetRecipes(165))=="table", "Leatherworking must exist")
local light=db:GetRecipe(165,2149)
assert(light and light.reagents[2318]==2,
    "actual Forever Light Leather recipe data must survive packaging")
_G.ChalkBox_ProfessionHas=function(prof) return prof=="Leatherworking" end
local known={}
_G.ChalkBox_LearnedRecipeUses=function(id)
    return known[tostring(id)] or {}
end
assert(loadfile("RecipeAdvisor.lua"))("ChalkBox")
local state,rec,materials=ChalkBox_RecipeAdvisorStatus()
assert(state=="bundled" and rec>2400 and materials>2400,
    "ChalkBox should index complete Forever recipes, even without locale-name files")
local advice=ChalkBox_RecipeAdvice("2318","Light Leather")
assert(advice and advice:find("POTENTIAL USE:",1,true)
    and advice:find("Spell recipe ",1,true),
    "live GetSpellInfo supplies localized recipe names only on hover")
assert(not advice:find("KNOWN RECIPE:",1,true),
    "offline recipe data is never proof the character has learned a recipe")
known["2318"]={{profession="Leatherworking",recipe="Camp Tent",quantity=5}}
advice=ChalkBox_RecipeAdvice("2318","Light Leather")
assert(advice:find("KNOWN RECIPE: Camp Tent",1,true)
    and advice:find("3/5 in bags",1,true),
    "observed learned recipe and actual bag quantity override broad candidates")
known["2318"]=nil
_G.GetSpellInfo=nil
ChalkBox_RecipeAdvisorRescan()
advice=ChalkBox_RecipeAdvice("2318","Light Leather")
assert(advice:find("recipe #",1,true)
    and advice:find("name unavailable",1,true),
    "when the client hides a recipe name, never invent one")
print("PASS: 2,511 bundled MIT Forever recipes, Light Leather truth, localized spell names, known-first advice and honest fallback")
