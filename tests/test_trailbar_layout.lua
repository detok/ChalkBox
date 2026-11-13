-- Standalone model tests for per-character left/center/right ordering and text alignment.
_G.ChalkBoxZoneDB={}
assert(loadfile("TrailBarLayout.lua"))("ChalkBox")
local function IsListed(layout,key)
    local count=0
    for _,section in ipairs({"left","center","right"}) do
        for _,item in ipairs(layout[section]) do
            if item==key then count=count+1 end
        end
    end
    return count
end
local first=ChalkBox_BarLayoutGet()
assert(first.left[1]=="level" and first.center[1]=="eta" and
    first.right[#first.right]=="gold","original order preserved for existing users")
assert(ChalkBox_BarLayoutMove("gold","left",2),
    "users can move any module between groups")
local result=ChalkBox_BarLayoutGet()
assert(result.left[2]=="gold" and IsListed(result,"gold")==1,
    "moving gold into left must preserve one instance, at chosen index")
assert(#result.right==2,"removed from original section")
assert(ChalkBox_BarLayoutMove("level","right",1),
    "even mandatory level can be placed in the right group")
result=ChalkBox_BarLayoutGet()
assert(result.right[1]=="level" and IsListed(result,"level")==1,
    "required level placement must persist exactly once")
assert(ChalkBox_BarLayoutAlign("gold","center"),
    "text within each module can be independently centered")
assert(result.align.gold==nil,"returned layout is a copy, not mutable preference")
result=ChalkBox_BarLayoutGet()
assert(result.align.gold=="center" and
    ChalkBoxZoneDB.trailLayout.align.gold=="center",
    "text alignment preferences are stored per character")
assert(not ChalkBox_BarLayoutMove("typo","left") and
    not ChalkBox_BarLayoutMove("gold","invalid"),
    "invalid module ids/zones cannot poison saved layouts")
assert(not ChalkBox_BarLayoutAlign("gold","diagonal"),
    "invalid alignments rejected")
-- Rebuild corrupt/duplicate preference data while preserving valid choices.
ChalkBoxZoneDB.trailLayout={
    left={"bags","bags","not-a-module"},center={"rested","gold"},
    right={"level"},align={bags="right",gold="rotated"}
}
result=ChalkBox_BarLayoutGet()
assert(IsListed(result,"bags")==1 and IsListed(result,"gold")==1
    and IsListed(result,"level")==1 and IsListed(result,"pet")==1,
    "malformed SavedVariables must normalize all modules exactly once")
assert(result.align.bags=="right" and result.align.gold==nil,
    "invalid text alignment is ignored")
local saved=ChalkBoxZoneDB
_G.ChalkBoxZoneDB={}
local newChar=ChalkBox_BarLayoutGet()
assert(newChar.left[1]=="level" and newChar.right[#newChar.right]=="gold"
    and not newChar.align.bags,
    "new character starts with the default layout independently")
_G.ChalkBoxZoneDB=saved
ChalkBox_BarLayoutReset()
result=ChalkBox_BarLayoutGet()
assert(result.left[1]=="level" and result.center[1]=="eta"
    and result.right[#result.right]=="gold" and next(result.align)==nil,
    "Reset Layout restores original positions and alignments")
print("PASS: TrailBar drag/drop ordering model, personal storage, alignment, corruption and resets")
