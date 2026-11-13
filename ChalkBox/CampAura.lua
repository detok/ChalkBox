-- ChalkBox CampAura: exact Forever camping buff detection (spell IDs, not guesses).
-- No protected aura manipulation. Supports both Forever modern and legacy APIs.
local CAMP_BENEFITS=1229741
local WELCOMING=1229739
local function Visible(v)
    return (type(issecretvalue)~="function" or not issecretvalue(v)) and v~=nil
end
local function Clock()
    if type(GetTime)=="function" then
        local now=GetTime()
        if Visible(now) and type(now)=="number" then return now end
    end
end
local function Recognize(id,name)
    if Visible(id) and type(id)=="number" then
        if id==CAMP_BENEFITS then return "benefits" end
        if id==WELCOMING or id==1289723 then return "welcoming" end
    end
    -- Fallback for servers that leave spell IDs unavailable to the client.
    if Visible(name) and type(name)=="string" then
        if name=="Camp Benefits" then return "benefits" end
        if name=="Welcoming Campfire" then return "welcoming" end
    end
end
local function Scan()
    local getModern=C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    local modern=type(getModern)=="function"
    local legacy=type(UnitBuff)=="function"
    if not modern and not legacy then return nil,"unavailable" end
    local result={}
    for index=1,80 do
        local ok,aura,name,id,expires
        if modern then
            ok,aura=pcall(getModern,"player",index,"HELPFUL")
            if ok and aura==nil then break end
            if not ok or not Visible(aura) or type(aura)~="table" then
                return nil,"restricted"
            end
            name,id,expires=aura.name,aura.spellId,aura.expirationTime
        else
            local icon,count,kind,duration,source,stealable,plate
            ok,name,icon,count,kind,duration,expires,source,stealable,plate,id=
                pcall(UnitBuff,"player",index,"HELPFUL")
            if ok and name==nil then break end
            if not ok then return nil,"restricted" end
        end
        if not Visible(name) and not Visible(id) then return nil,"restricted" end
        local recognized=Recognize(id,name)
        if recognized then
            result[recognized]={name=Visible(name) and name or recognized,
                expiration=Visible(expires) and type(expires)=="number" and expires or nil}
        end
    end
    return result,nil
end
function ChalkBox_CampBuffStatus()
    local buffs,err=Scan()
    if not buffs then return {state="unknown",reason=err or "aura API unavailable"} end
    local now=Clock()
    if buffs.welcoming then
        return {state="gathering",name="Welcoming Campfire",
            seconds=now and buffs.welcoming.expiration and
                math.max(0,math.floor(buffs.welcoming.expiration-now)) or nil}
    end
    if buffs.benefits then
        local expires=buffs.benefits.expiration
        if now and expires and expires>0 then
            local remaining=math.max(0,math.floor(expires-now))
            if remaining<=600 then return {state="expiring",seconds=remaining,name="Camp Benefits"} end
            return {state="active",seconds=remaining,name="Camp Benefits"}
        end
        return {state="active",seconds=nil,name="Camp Benefits"}
    end
    return {state="missing",name="Camp Benefits"}
end

-- Camp Tent is a Rested XP refill, not a Camp Benefits stat aura. Successful
-- use applies the one-hour HARMFUL Boosted Rest lockout, spell 1229451.
local BOOSTED_REST=1229451
local function TentDebuff()
    local modern=C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    local legacy=UnitDebuff
    if type(modern)~="function" and type(legacy)~="function" then
        return nil,"unavailable"
    end
    for i=1,80 do
        local ok,name,spellID,expires
        if type(modern)=="function" then
            local aura
            ok,aura=pcall(modern,"player",i,"HARMFUL")
            if not ok then return nil,"restricted" end
            if type(issecretvalue)=="function" and issecretvalue(aura) then
                return nil,"restricted"
            end
            if aura==nil then return false end
            if not Visible(aura) or type(aura)~="table" then return nil,"restricted" end
            name,spellID,expires=aura.name,aura.spellId,aura.expirationTime
        else
            local icon,count,kind,duration,source,stealable,plate
            ok,name,icon,count,kind,duration,expires,source,stealable,plate,spellID=
                pcall(legacy,"player",i,"HARMFUL")
            if not ok then return nil,"restricted" end
            if type(issecretvalue)=="function" and issecretvalue(name) then
                return nil,"restricted"
            end
            if name==nil then return false end
        end
        if not Visible(name) and not Visible(spellID) then return nil,"restricted" end
        if (Visible(spellID) and spellID==BOOSTED_REST)
            or (Visible(name) and name=="Boosted Rest") then
            local now=Clock()
            return {seconds=Visible(expires) and type(expires)=="number"
                and now and expires>0 and math.max(0,math.floor(expires-now))
                or nil}
        end
    end
    return false
end

local function RestedPercent()
    if type(UnitXPMax)~="function" or type(GetXPExhaustion)~="function" then
        return nil
    end
    local okMax,maxXP=pcall(UnitXPMax,"player")
    local okRest,restXP=pcall(GetXPExhaustion)
    if not okMax or not okRest or not Visible(maxXP) or type(maxXP)~="number"
        or maxXP<=0 then return nil end
    -- GetXPExhaustion() returns nil when no rested XP is stored.
    if type(issecretvalue)=="function" and issecretvalue(restXP) then return nil end
    if restXP==nil then restXP=0 end
    if not Visible(restXP) or type(restXP)~="number" or restXP<0 then return nil end
    return restXP/maxXP
end
function ChalkBox_CampTentStatus()
    local debuff,reason=TentDebuff()
    if type(debuff)=="table" then
        return {state="cooldown",seconds=debuff.seconds,
            detail="Boosted Rest: tent refill already used"}
    end
    local percent=RestedPercent()
    if percent and percent>=0.05 then
        return {state="sufficient",rested=percent,
            detail="Already have at least 5% of a level in rested XP"}
    end
    if debuff==false and percent then
        return {state="ready",rested=percent,
            detail="Tent could refill rested XP to 5% of a level"}
    end
    return {state="unknown",reason=reason or "XP or debuff API unavailable"}
end
