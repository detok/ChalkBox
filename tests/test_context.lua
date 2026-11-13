-- All-race/all-class context can be exercised without native animations.
local race,class,rest,pet="Dwarf","HUNTER",false,true
_G.UnitRace=function() return race,race end
_G.UnitClass=function() return class,class end
_G.IsResting=function() return rest end
_G.UnitExists=function(unit) return unit=="pet" and pet end
_G.UnitName=function(unit) return unit=="pet" and "Biscuit" end
assert(loadfile("PersonalityContext.lua"))("ChalkBox")
local a=ChalkBox_PersonalityContext()
assert(a.race=="Dwarf" and a.class=="HUNTER" and a.petName=="Biscuit")
assert(a.weights.FLEX>0 and a.weights.CHEER>0,
    "Dwarf Hunter gets both racial and pet-friendly idle weighting")
rest=true
local b=ChalkBox_PersonalityContext()
assert(b.resting==true and b.weights.SIT>=4,
    "an inn/rest area adds peaceful idle animation bias")
rest=false;pet=false;race="Orc";class="WARRIOR"
local c=ChalkBox_PersonalityContext()
assert(c.weights.ROAR>=2 and c.weights.FLEX>=4 and c.petName==nil)
local classes={
    "HUNTER","WARRIOR","MAGE","PRIEST","DRUID","ROGUE","PALADIN","SHAMAN",
    "WARLOCK","DEATHKNIGHT","MONK","DEMONHUNTER","EVOKER"
}
for _,cls in ipairs(classes) do
    class=cls
    assert(next(ChalkBox_PersonalityContext().weights)~=nil,
        "must have usable context for class "..cls)
end
for _,r in ipairs({"Human","Dwarf","NightElf","Gnome","Orc","Troll",
    "Tauren","Scourge","BloodElf","Draenei","Worgen","Goblin",
    "Pandaren","Earthen"}) do
    race=r
    assert(next(ChalkBox_PersonalityContext().weights)~=nil,r)
end
race="BrandNewRace";class="BrandNewClass"
local fresh=ChalkBox_PersonalityContext()
assert(type(fresh.weights)=="table" and next(fresh.weights)==nil,
    "unknown future classes/races must fail open without errors")
print("PASS: all supported races/classes, Dwarf Hunter pet, inn/rest area, and safe future-race fallback")
