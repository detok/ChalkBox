-- Personal combat-log meter: you and your pet, your own fight clock.
local now=500
_G.GetTime=function() return now end
_G.issecretvalue=function() return false end
_G.CreateFrame=function()
    return {RegisterEvent=function() end,SetScript=function() end}
end
assert(loadfile("CombatLogMeter.lua"))("ChalkBox")
local MINE,PLAYER,PET=0x1,0x400,0x1000
local function Hit(guid,name,flags,amount,subevent)
    assert(ChalkBox_PersonalMeterIngest(now,subevent or "SWING_DAMAGE",false,
        guid,name,flags,0,"Creature-1","Boar",0,0,amount))
end
Hit("Player-1","Detok",MINE+PLAYER,1000)
Hit("Pet-1","Wolf",MINE+PET,400)
Hit("Other-1","Stranger",PLAYER,9999)
now=503
local snap=ChalkBox_PersonalMeterSnapshot("current","dps")
assert(snap and snap.idle~=true and #snap.combatSources==2,
    "player and pet are separate rows")
assert(snap.combatSources[1].name=="Detok" and
    snap.combatSources[1].isLocalPlayer==true and
    snap.combatSources[1].totalAmount==1000 and
    snap.combatSources[1].amountPerSecond==1000/3,
    "personal DPS uses this fight's own clock")
assert(snap.combatSources[2].name=="Wolf" and snap.combatSources[2].isPet==true
    and snap.combatSources[2].totalAmount==400,
    "pet damage is counted on its own row")
assert(snap.combined==1400,"you plus your pet is the combined total")
-- Another player's hits never join the personal meter.
assert(snap.combatSources[1].totalAmount==1000)
-- Effective healing subtracts overheal. Spell amount is the 4th extra value.
assert(ChalkBox_PersonalMeterIngest(now,"SPELL_HEAL",false,
    "Player-1","Detok",MINE+PLAYER,0,"Player-1","Detok",MINE+PLAYER,0,
    123, "Heal", 2, 500, 200))
local heal=ChalkBox_PersonalMeterSnapshot("current","healing")
assert(heal.combatSources[1].totalAmount==300,
    "overheal is not counted as healing done")
now=510
local before=ChalkBox_PersonalMeterSnapshot("overall","damage")
assert(before.combatSources[1].totalAmount==1000)
ChalkBox_PersonalMeterReset()
local idle=ChalkBox_PersonalMeterSnapshot("current","dps")
assert(idle.idle==true and #idle.combatSources==0,
    "reset clears the session and does not touch saved variables")
Hit("Player-1","Detok",MINE+PLAYER,50)
now=512
local again=ChalkBox_PersonalMeterSnapshot("current","damage")
assert(again.combatSources[1].totalAmount==50 and
    ChalkBox_PersonalMeterSnapshot("overall","damage").combatSources[1].totalAmount==50)
print("PASS: personal meter counts you and your pet, ignores other players, and keeps its own timer")
