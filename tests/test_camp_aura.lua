-- CampAura: real Forever buff names and spell IDs, without false assumptions.
local now=1000
_G.GetTime=function() return now end
local auras={}
_G.C_UnitAuras={GetAuraDataByIndex=function(unit,index,filter)
    assert(unit=="player" and filter=="HELPFUL")
    return auras[index]
end}
_G.UnitBuff=nil
assert(loadfile("CampAura.lua"))("ChalkBox")
local function Status()
    return ChalkBox_CampBuffStatus()
end
assert(Status().state=="missing","client available + no aura = missing")
auras={{name="Camp Benefits",spellId=1229741,expirationTime=4600}}
assert(Status().state=="active" and Status().seconds==3600,
    "Camp Benefits active with 60 min remaining means do not camp again")
now=4101
assert(Status().state=="expiring" and Status().seconds==499,
    "only alert when less than 10 minutes left")
auras={{name="Welcoming Campfire",spellId=1229739,expirationTime=4160},
    {name="Camp Benefits",spellId=1229741,expirationTime=4120}}
assert(Status().state=="gathering",
    "player already resting at camp: suppress missing/expiring reminders")
auras={{name="A localized camp buff",spellId=1229741,expirationTime=0}}
assert(Status().state=="active",
    "spell IDs work when localized buff name differs and no expiry visible")
auras={{name="Well Rested",spellId=999,expirationTime=6000}}
assert(Status().state=="missing",
    "sleeping-bag Well Rested alone does not replace actual Camp Benefits")
C_UnitAuras.GetAuraDataByIndex=function() error("restricted player aura") end
assert(Status().state=="unknown","restricted scan must never guess missing")
C_UnitAuras=nil
local oldAuras={
    {"Camp Benefits",nil,nil,nil,3600,now+400},
}
_G.UnitBuff=function(unit,index,filter)
    local value=oldAuras[index]
    if value then
        return value[1],nil,nil,nil,value[5],value[6],nil,nil,nil,1229741
    end
end
assert(Status().state=="expiring" and Status().seconds==400,
    "legacy UnitBuff fallback reads 10th spell ID and expiration")
oldAuras={}
assert(Status().state=="missing")
UnitBuff=nil
assert(Status().state=="unknown","unavailable APIs cannot prove missing buffs")
-- Camp Tent is a separate HARMFUL Boosted Rest lockout, not Camp Benefits.
local harmful={}
local rested=0
_G.UnitXPMax=function() return 1000 end
_G.GetXPExhaustion=function() return rested end
_G.C_UnitAuras={GetAuraDataByIndex=function(unit,index,filter)
    assert(unit=="player")
    if filter=="HARMFUL" then return harmful[index] end
    return nil
end}
assert(ChalkBox_CampTentStatus().state=="ready",
    "with low rested XP and no Boosted Rest debuff, another tent may help")
harmful={{name="Boosted Rest",spellId=1229451,expirationTime=now+1800}}
local tent=ChalkBox_CampTentStatus()
assert(tent.state=="cooldown" and tent.seconds==1800,
    "Boosted Rest proves the tent awarded its rested XP refill")
harmful={{name="Localized debuff",spellId=1229451,expirationTime=now+250}}
assert(ChalkBox_CampTentStatus().state=="cooldown",
    "Boosted Rest must also be detected by spell ID in localized clients")
harmful={}
rested=60
assert(ChalkBox_CampTentStatus().state=="sufficient",
    "existing 6% rested XP means the tent cannot refill more than 5%")
rested=10
assert(ChalkBox_CampTentStatus().state=="ready",
    "low rested XP and no lockout makes a tent useful")
rested=nil -- GetXPExhaustion nil represents no rested XP, not an error
assert(ChalkBox_CampTentStatus().state=="ready")
C_UnitAuras.GetAuraDataByIndex=function() error("restricted harmful aura") end
rested=60
assert(ChalkBox_CampTentStatus().state=="sufficient",
    "known sufficient rested XP remains useful evidence if debuff API is blocked")
rested=10
assert(ChalkBox_CampTentStatus().state=="unknown",
    "cannot assert tent ready if debuff API is blocked")
C_UnitAuras=nil
_G.UnitDebuff=function(unit,index)
    if index==1 then return "Boosted Rest",nil,nil,nil,nil,now+600,nil,nil,nil,1229451 end
end
assert(ChalkBox_CampTentStatus().state=="cooldown",
    "legacy UnitDebuff harmful scan detects one-hour tent lockout")
_G.UnitDebuff=nil
assert(ChalkBox_CampTentStatus().state=="unknown",
    "no harmful aura API must not invent tent completion state")
print("PASS: stat auras, harmful Boosted Rest ID 1229451, rested XP thresholds, localized debuffs and safe unknown")
