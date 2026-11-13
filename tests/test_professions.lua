-- ChalkBox ProfessionSense: actual character professions and learned recipe cache.
local observed={}
local owned={"Leatherworking","Alchemy"}
local legReagents={"|Hitem:501:0|h[Soft Leather]|h"}
_G.ChalkBoxProfessionDB=nil
_G.GetProfessions=function() return owned[1] and 1 or nil, owned[2] and 2 or nil end
_G.GetProfessionInfo=function(i)
    local name=owned[i]
    local skill=name=="Leatherworking" and 165 or name=="Alchemy" and 171
    return name,nil,75,150,nil,nil,skill
end
_G.GetTradeSkillLine=function() return "Leatherworking" end
_G.GetNumTradeSkills=function() return 1 end
_G.GetTradeSkillInfo=function() return "Leather Jerkin","optimal" end
_G.GetTradeSkillNumReagents=function() return #legReagents end
_G.GetTradeSkillReagentInfo=function() return "Soft Leather",nil,3 end
_G.GetTradeSkillReagentItemLink=function(_,j) return legReagents[j] end
_G.C_TradeSkillUI={
    GetBaseProfessionInfo=function() return {professionName="Alchemy",professionID=171} end,
    GetAllRecipeIDs=function() return {99,100} end,
    GetRecipeInfo=function(id) return {learned=id==99,name=id==99 and "Mystic Draught" or "Unknown Potion"} end,
    GetRecipeSchematic=function(id)
        return {reagentSlotSchematics={{quantityRequired=2,reagents={{itemID=801}}}}}
    end
}
_G.CreateFrame=function()
    local f={events={}}
    function f:RegisterEvent(event) self.events[event]=true end
    function f:SetScript(_,callback) self.callback=callback end
    observed.frame=f
    return f
end
assert(loadfile("ProfessionSense.lua"))("ChalkBox")
local f=observed.frame
f.callback(f,"ADDON_LOADED","ChalkBox")
local a,b=ChalkBox_ProfessionSummary()
assert(a:find("Leatherworking",1,true) and a:find("Alchemy",1,true))
local prof,confidence=ChalkBox_ProfessionMatch("555","Untested Hide","Leather",7)
assert(prof=="Leatherworking" and confidence=="possible","leather family is only possible use")
assert(ChalkBox_ProfessionMatch("777","Soft Cloth","Cloth",7)==nil,
    "do not suggest Tailoring if character lacks it")
assert(ChalkBox_ProfessionMatch("103","Some Sword","",2)==nil,
    "do not label unrelated equipment")
ChalkBox_ProfessionRefresh()
prof,confidence=ChalkBox_ProfessionMatch("501","Soft Leather","",0)
assert(prof=="Leatherworking" and confidence=="known","legacy learned recipe reagent")
prof,confidence=ChalkBox_ProfessionMatch("801","Mystic Catalyst","",0)
assert(prof=="Alchemy" and confidence=="known","modern learned schematic reagent")
assert(ChalkBox_ProfessionMatch("999","Unlearned Catalyst","",0)==nil,
    "unlearned recipes are not sources of confirmed relevance")
local p,n=ChalkBox_ProfessionSummary()
assert(n>=2,"recipe index should persist in saved per-character table")
assert(ChalkBoxProfessionDB.reagents["id:501"].Leatherworking==true)
local known=ChalkBox_LearnedRecipeUses("501","Soft Leather")
assert(#known==1 and known[1].recipe=="Leather Jerkin" and
    known[1].profession=="Leatherworking" and known[1].quantity==3,
    "learned legacy reagent must retain exact recipe name and required amount")
local modern=ChalkBox_LearnedRecipeUses("801","Mystic Catalyst")
assert(#modern==1 and modern[1].recipe=="Mystic Draught" and modern[1].quantity==2,
    "modern learned schematic ingredient must retain name and amount")
assert(#ChalkBox_LearnedRecipeUses("999","Unlearned Catalyst")==0,
    "unknown recipes never become known via offline data")
assert(ChalkBox_ProfessionHas("Leatherworking") and ChalkBox_ProfessionHas("Alchemy"))

owned[1]=nil
f.callback(f,"SKILL_LINES_CHANGED")
assert(ChalkBox_ProfessionMatch("501","Soft Leather","",0)==nil,
    "learned recipes stop appearing when profession is unlearned")
assert(ChalkBox_ProfessionMatch("555","Untested Hide","Leather",7)==nil)
assert(#ChalkBox_LearnedRecipeUses("501","Soft Leather")==0,
    "removed profession must not report stale learned recipe uses")
print("PASS: current character professions, cautious family hints, learned legacy and modern reagents, unlearned filtering and per-character recipe names, quantities and persistence")
