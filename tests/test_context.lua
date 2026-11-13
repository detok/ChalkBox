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
-- Race Behavior editor provides honest live vs. planned profiles.
_G.ChalkBoxDB={emota={}}
local catalog=ChalkBox_RaceCatalog()
assert(#catalog>=20,"race selector lists implemented and planned profiles")
local dwarf=ChalkBox_RaceBehaviorStatus("Dwarf")
local future=ChalkBox_RaceBehaviorStatus("VoidElf")
assert(dwarf.implemented and dwarf.examples:find("FLEX",1,true),
    "Dwarf racial behavior shows the actual weighted emote list")
assert(future and not future.implemented and future.examples=="",
    "future race is explicitly labeled planned, with no fabricated behavior")
assert(not ChalkBox_RaceBehaviorSet("VoidElf","expressive"),
    "planned races do not pretend to have live custom weights")
assert(ChalkBox_RaceBehaviorSet("Dwarf","off"))
race="Dwarf";class="HUNTER";rest=false;pet=false
local off=ChalkBox_PersonalityContext()
assert(off.weights.FLEX==nil or off.weights.FLEX==0,
    "Off removes dwarf racial weights without suppressing hunter class weights")
assert(ChalkBox_RaceBehaviorSet("Dwarf","expressive"))
local expressive=ChalkBox_PersonalityContext()
assert(expressive.weights.FLEX==8,
    "Expressive increases this character's actual racial emote weight")
assert(ChalkBox_RaceBehaviorSet("Dwarf","subtle"))
local subtle=ChalkBox_PersonalityContext()
assert(subtle.weights.FLEX==2,
    "Subtle reduces racial-emote bias but keeps working idle logic")
assert(ChalkBox_RaceBehaviorSet("Dwarf","default"))
assert(ChalkBox_PersonalityContext().weights.FLEX==4,
    "Default restores original dwarf behavior")
assert(not ChalkBox_RaceBehaviorSet("Dwarf","ultra"),
    "invalid race intensity modes are rejected")
print("PASS: racial flavor intensities, honest placeholders and saved user preferences")
print("PASS: all supported races/classes, Dwarf Hunter pet, inn/rest area, and safe future-race fallback")
