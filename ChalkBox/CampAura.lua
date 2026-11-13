-- ChalkBox CampAura: exact Forever camping buff detection (spell IDs, not guesses).
-- No protected aura manipulation. Supports both Forever modern and legacy APIs.
local CAMP_BENEFITS=1229741
local WELCOMING=1229739
local function Visible(v)
    return v~=nil and (type(issecretvalue)~="function" or not issecretvalue(v))
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
