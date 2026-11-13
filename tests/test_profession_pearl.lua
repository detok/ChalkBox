-- Regression: Small Lustrous Pearl (5498) must not become a First Aid
-- reagent due to stale saved scans or broad subclass-based guessing.
local frame
_G.GetProfessions=function() return 1,2 end
_G.GetProfessionInfo=function(i)
    local name=i==1 and "First Aid" or "Leatherworking"
    return name,nil,75,150,nil,nil,i==1 and 129 or 165
end
_G.GetNumSkillLines=nil
_G.C_TradeSkillUI=nil
_G.ChalkBoxProfessionDB={
    reagents={
        ["id:5498"]={["First Aid"]=true,Leatherworking=true},
        ["name:small lustrous pearl"]={["First Aid"]=true},
        ["id:2589"]={["First Aid"]=true},
    },
    recipeUses={
        ["id:5498"]={
            ["First Aid|Incorrect cached use"]={
                profession="First Aid",recipe="Incorrect cached use",quantity=1,
            },
            ["Leatherworking|Moonglow Vest"]={
                profession="Leatherworking",recipe="Moonglow Vest",quantity=1,
            },
        },
        ["name:small lustrous pearl"]={
            ["First Aid|Incorrect cached use"]={
                profession="First Aid",recipe="Incorrect cached use",quantity=1,
            },
        },
        ["id:2589"]={
            ["First Aid|Linen Bandage"]={
                profession="First Aid",recipe="Linen Bandage",quantity=1,
            },
        },
    },
}
local bundled={
    GetRecipes=function(_,skillID)
        if skillID==129 then
            return {[3275]={reagents={[2589]=1}}}
        end
    end,
}
_G.LibStub=function(name,silent)
    if name=="LibProfessionDB-1.0" and silent then return bundled end
end
_G.CreateFrame=function()
    frame={
        RegisterEvent=function() end,
        SetScript=function(self,_,fn) self.callback=fn end,
    }
    return frame
end
assert(loadfile("ProfessionSense.lua"))("ChalkBox")
frame.callback(frame,"ADDON_LOADED","ChalkBox")
assert(ChalkBox_ProfessionHas("First Aid") and ChalkBox_ProfessionHas("Leatherworking"))
local prof,confidence=ChalkBox_ProfessionMatch("5498","Small Lustrous Pearl","Cloth",7)
assert(prof=="Leatherworking" and confidence=="known",
    "legitimate learned Leatherworking use must survive a false First Aid record")
local uses=ChalkBox_LearnedRecipeUses("5498","Small Lustrous Pearl")
assert(#uses==1 and uses[1].profession=="Leatherworking" and
    uses[1].recipe=="Moonglow Vest",
    "saved false First Aid recipe must not be displayed for a pearl")
prof,confidence=ChalkBox_ProfessionMatch("2589","Linen Cloth","Cloth",7)
assert(prof=="First Aid" and confidence=="known",
    "real bandage material remains recognized for First Aid")
uses=ChalkBox_LearnedRecipeUses("2589","Linen Cloth")
assert(#uses==1 and uses[1].recipe=="Linen Bandage",
    "genuine First Aid recipe must still be displayed")
ChalkBoxProfessionDB.reagents["id:5498"].Leatherworking=nil
ChalkBoxProfessionDB.recipeUses["id:5498"]["Leatherworking|Moonglow Vest"]=nil
assert(ChalkBox_ProfessionMatch("5498","Small Lustrous Pearl","Cloth",7)==nil,
    "stale First Aid-only pearl record must not cause a tooltip suggestion")
assert(#ChalkBox_LearnedRecipeUses("5498","Small Lustrous Pearl")==0,
    "stale First Aid-only pearl recipe must not be claimed as learned")
assert(ChalkBox_ProfessionMatch(nil,"Small Lustrous Pearl","Cloth",7)==nil,
    "item-name/subclass alone must not guess First Aid")
print("PASS: pearl rejects stale First Aid hints, learned Leatherworking stays valid, and linen bandage still matches")
