-- RecipeAdvisor: never confuse offline possibilities with known recipes.
local frames={}
local known={}
local hasLW=true
local itemQty=3
local dbEnabled=true
_G.GetItemCount=function() return itemQty end
_G.ChalkBox_LearnedRecipeUses=function(id,name)
    return known[tostring(id)] or {}
end
_G.ChalkBox_ProfessionHas=function(name)
    return hasLW and name=="Leatherworking"
end
local db={
    IsReady=function() return true end,
    GetGameVersion=function() return "Forever" end,
    GetRecipes=function(self,profession)
        if profession==165 then
            return {
                [5001]={name="Camp Tent",reagents={[2318]=5,[4470]=2}},
                [5002]={name="Camp Chair",reagents={{itemID=2318,count=3}}},
                [5003]={name="Does not use Light Leather",reagents={[4471]=1}},
            }
        end
        if profession==197 then
            return {[6001]={name="Cloth Vest",reagents={[2589]=3}}}
        end
        return {}
    end
}
_G.LibStub=function(_,silent)
    assert(silent==true)
    if dbEnabled then return db end
    return nil
end
_G.CreateFrame=function()
    local f={events={}}
    function f:RegisterEvent(name) self.events[name]=true end
    function f:SetScript(name,fn) self[name]=fn end
    frames[#frames+1]=f
    return f
end
assert(loadfile("RecipeAdvisor.lua"))("ChalkBox")
local events=frames[#frames]
events.OnEvent(events,"PLAYER_ENTERING_WORLD")
local state,total,count=ChalkBox_RecipeAdvisorStatus()
assert(state=="ready" and total==4 and count==5,
    "read all relevant offline recipes once and construct item-to-recipes index")
local advice=ChalkBox_RecipeAdvice("2318","Light Leather")
assert(advice:find("POTENTIAL USE: Camp Tent",1,true) or
    advice:find("POTENTIAL USE: Camp Chair",1,true),
    "no learned recipes means possible, not known")
assert(not advice:find("KNOWN",1,true),
    "offline recipe list must never be treated as learned")
known["2318"]={
    {recipe="Camp Tent",profession="Leatherworking",quantity=5},
    {recipe="Camp Chair",profession="Leatherworking",quantity=3},
}
advice=ChalkBox_RecipeAdvice("2318","Light Leather")
assert(advice:find("KNOWN RECIPE: Camp Tent",1,true))
assert(advice:find("3/5 in bags",1,true),"show player's actual current stack count")
assert(ChalkBox_RecipeDetails("2318","Light Leather"):find("Camp Chair",1,true),
    "allow extra learned recipes only in expanded details")
itemQty=nil
advice=ChalkBox_RecipeAdvice("2318","Light Leather")
assert(advice:find("requires 5",1,true),
    "show material requirement without inventing inaccessible bag count")
known["2318"]=nil
hasLW=false
advice=ChalkBox_RecipeAdvice("2318","Light Leather")
assert(advice:find("OTHER PROFESSION:",1,true),
    "not owning the profession should not suggest hoarding for your own craft")
assert(ChalkBox_RecipeAdvice("999999","Unrelated")==nil,
    "do not invent relevance for unrelated items")
dbEnabled=false
ChalkBox_RecipeAdvisorRescan()
assert(select(1,ChalkBox_RecipeAdvisorStatus())=="not available",
    "missing third-party database is a supported fallback, not a crash")
assert(ChalkBox_RecipeAdvice("999","Untracked")==nil,
    "absence of external data must be quiet")
print("PASS: optional library indexing, confirmed vs possible, bag quantity, expanded details, third-party fallback and unrelated item silence")
