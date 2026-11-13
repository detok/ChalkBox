-- All-race/all-class Emota context. Forever starts with Dwarf Hunter,
-- but the same data-driven lookup applies to any playable race and class.
-- Only harmless native emote tokens; no action-bar, targeting or combat logic.
local function Safe(x)
    return x~=nil and (type(issecretvalue)~="function" or not issecretvalue(x))
end
local raceWeights={
    Dwarf={FLEX=4, SALUTE=3, PONDER=3, DANCE=2, DRINK=3},
    Human={SALUTE=3, PONDER=2, DANCE=2},
    NightElf={DANCE=4, PONDER=2, KNEEL=2},
    Gnome={LAUGH=4, PONDER=3, DANCE=2},
    Orc={ROAR=4, FLEX=4, SALUTE=2},
    Troll={DANCE=4, LAUGH=3, CHICKEN=2},
    Tauren={KNEEL=3, PONDER=3, SALUTE=2},
    Scourge={SIGH=3, LAUGH=2, STARE=3},
    BloodElf={DANCE=3, PONDER=3, SALUTE=2},
    Draenei={SALUTE=3, KNEEL=3, PONDER=2},
    Worgen={ROAR=3, PONDER=2},
    Goblin={LAUGH=4, SHRUG=3},
    Pandaren={SIT=3, PONDER=3},
    Earthen={FLEX=3, SALUTE=2},
}
local classWeights={
    HUNTER={PONDER=2, SALUTE=2, CHEER=3, LOOK=2},
    WARRIOR={FLEX=4, ROAR=2, SALUTE=3},
    MAGE={PONDER=4, SHRUG=2, YAWN=2},
    PRIEST={KNEEL=3, PONDER=4, SALUTE=2},
    DRUID={SIT=3, YAWN=3, PONDER=2},
    ROGUE={LOOK=3, STARE=3, SHRUG=2},
    PALADIN={SALUTE=3, KNEEL=3, FLEX=2},
    SHAMAN={PONDER=3, KNEEL=3, ROAR=2},
    WARLOCK={LAUGH=3, STARE=3, PONDER=2},
    DEATHKNIGHT={STARE=3, ROAR=2},
    MONK={KNEEL=3, SIT=3},
    DEMONHUNTER={STARE=3, ROAR=2},
    EVOKER={PONDER=3, SALUTE=2},
}
local function Class()
    if type(UnitClass)~="function" then return end
    local _,token=UnitClass("player")
    return Safe(token) and type(token)=="string" and token or nil
end
local function Race()
    if type(UnitRace)~="function" then return end
    local _,token=UnitRace("player")
    return Safe(token) and type(token)=="string" and token or nil
end
function ChalkBox_PersonalityContext()
    local race,class=Race(),Class()
    local result={race=race or "Unknown",class=class or "Unknown",
        weights={},resting=false,petName=nil}
    for token,w in pairs(raceWeights[race] or {}) do result.weights[token]=(result.weights[token] or 0)+w end
    for token,w in pairs(classWeights[class] or {}) do result.weights[token]=(result.weights[token] or 0)+w end
    if type(IsResting)=="function" then
        local state=IsResting()
        if Safe(state) and state==true then
            result.resting=true
            result.weights.SIT=(result.weights.SIT or 0)+4
            result.weights.SLEEP=(result.weights.SLEEP or 0)+2
            result.weights.DANCE=(result.weights.DANCE or 0)+1
        end
    end
    if class=="HUNTER" and type(UnitExists)=="function" then
        local pet=UnitExists("pet")
        if Safe(pet) and pet then
            local name=type(UnitName)=="function" and UnitName("pet")
            if Safe(name) and type(name)=="string" and name~="" then
                result.petName=name
                result.weights.CHEER=(result.weights.CHEER or 0)+3
            end
        end
    end
    return result
end
