-- Personal combat log meter for the player and that player's pets.
-- Used only when Blizzard's C_DamageMeter feed is missing, locked, or empty.
-- Nothing here is written to SavedVariables. A reload starts a fresh session.
local MINE,PLAYER,PET,GUARDIAN=0x1,0x400,0x1000,0x2000
local DAMAGE={
    SWING_DAMAGE=true,RANGE_DAMAGE=true,SPELL_DAMAGE=true,
    SPELL_PERIODIC_DAMAGE=true,DAMAGE_SHIELD=true,DAMAGE_SPLIT=true,
    SPELL_BUILDING_DAMAGE=true,
}
local HEAL={SPELL_HEAL=true,SPELL_PERIODIC_HEAL=true}
local INTERRUPT={SPELL_INTERRUPT=true}
local SPELL_PREFIX={
    RANGE_DAMAGE=true,SPELL_DAMAGE=true,SPELL_PERIODIC_DAMAGE=true,
    DAMAGE_SHIELD=true,DAMAGE_SPLIT=true,SPELL_BUILDING_DAMAGE=true,
    SPELL_HEAL=true,SPELL_PERIODIC_HEAL=true,SPELL_INTERRUPT=true,
}
local current,last,closed
local playerGUID,seenPlayer,seenPet
local pets={}
local function Secret(value)
    return type(issecretvalue)=="function" and issecretvalue(value)==true
end
local function Number(value)
    if Secret(value) or type(value)~="number" then return nil end
    if value~=value or value==math.huge or value==-math.huge then return nil end
    return value
end
local function Now()
    if type(GetTime)~="function" then return nil end
    local ok,value=pcall(GetTime)
    return ok and Number(value) or nil
end
local function Band(a,b)
    a,b=Number(a),Number(b)
    if not a or not b or a<0 or b<0 then return 0 end
    if type(bit)=="table" and type(bit.band)=="function" then
        local ok,value=pcall(bit.band,a,b)
        if ok and Number(value) then return value end
    end
    local result,bitValue=0,1
    local x,y=math.floor(a),math.floor(b)
    while x>0 and y>0 and bitValue<0x80000000 do
        if x%2==1 and y%2==1 then result=result+bitValue end
        x=math.floor(x/2)
        y=math.floor(y/2)
        bitValue=bitValue*2
    end
    return result
end
local function Has(flags,mask)
    return Band(flags,mask)>0
end
local function Blank()
    return {damage=0,healing=0,taken=0,interrupts=0,
        petDamage=0,petHealing=0,petTaken=0,petInterrupts=0,
        started=nil,ended=nil,combat=false,archived=false}
end
local function CopySeg(seg)
    local out=Blank()
    if type(seg)~="table" then return out end
    for key,value in pairs(out) do
        if type(seg[key])=="number" then out[key]=seg[key]
        elseif type(seg[key])=="boolean" then out[key]=seg[key] end
    end
    out.started,out.ended=seg.started,seg.ended
    return out
end
local function Totals()
    closed=closed or {damage=0,healing=0,taken=0,interrupts=0,
        petDamage=0,petHealing=0,petTaken=0,petInterrupts=0,time=0}
    return closed
end
current=Blank()
local function Elapsed(seg,now)
    if type(seg)~="table" or not Number(seg.started) then return 0 end
    local finish=seg.combat and now or seg.ended or now
    if not Number(finish) then return 0 end
    local span=finish-seg.started
    if span~=span or span<0 then return 0 end
    return span
end
local function HasNumbers(seg)
    if type(seg)~="table" then return false end
    return (seg.damage or 0)+(seg.healing or 0)+(seg.taken or 0)
        +(seg.interrupts or 0)+(seg.petDamage or 0)+(seg.petHealing or 0)
        +(seg.petTaken or 0)+(seg.petInterrupts or 0)>0
end
local function Archive(now)
    if type(current)~="table" or current.archived then return end
    if not current.started and not HasNumbers(current) then return end
    current.combat=false
    if not Number(current.ended) then current.ended=now or Now() end
    current.archived=true
    last=CopySeg(current)
    local box=Totals()
    box.damage=box.damage+current.damage
    box.healing=box.healing+current.healing
    box.taken=box.taken+current.taken
    box.interrupts=box.interrupts+current.interrupts
    box.petDamage=box.petDamage+current.petDamage
    box.petHealing=box.petHealing+current.petHealing
    box.petTaken=box.petTaken+current.petTaken
    box.petInterrupts=box.petInterrupts+current.petInterrupts
    box.time=box.time+Elapsed(current,current.ended)
end
local function RememberUnits()
    if type(UnitGUID)~="function" then return end
    local ok,guid=pcall(UnitGUID,"player")
    if ok and not Secret(guid) and type(guid)=="string" and guid~="" then
        playerGUID=guid
    end
    local petOK,pet=pcall(UnitGUID,"pet")
    if petOK and not Secret(pet) and type(pet)=="string" and pet~="" then
        pets[pet]=true
    end
end
local function Role(guid,flags)
    if type(guid)=="string" and playerGUID and guid==playerGUID then
        return "player"
    end
    if type(guid)=="string" and pets[guid] then return "pet" end
    if not Has(flags,MINE) then return nil end
    if Has(flags,PLAYER) then
        if type(guid)=="string" and guid~="" then playerGUID=guid end
        return "player"
    end
    if Has(flags,PET) or Has(flags,GUARDIAN) then
        if type(guid)=="string" and guid~="" then pets[guid]=true end
        return "pet"
    end
end
local function Add(role,field,amount)
    amount=Number(amount)
    if not amount or amount<=0 or type(current)~="table" then return end
    local now=Now()
    if not current.combat then
        if current.started and not current.archived then Archive(now) end
        current=Blank()
        current.combat=true
    end
    if not current.started then current.started=now end
    if role=="player" then
        current[field]=(current[field] or 0)+amount
    elseif role=="pet" then
        local key=field=="damage" and "petDamage" or field=="healing" and "petHealing"
            or field=="taken" and "petTaken" or "petInterrupts"
        current[key]=(current[key] or 0)+amount
    end
end
local function Ingest(timestamp,subevent,hideCaster,sourceGUID,sourceName,
    sourceFlags,sourceRaidFlags,destGUID,destName,destFlags,destRaidFlags,...)
    if Secret(subevent) or type(subevent)~="string" then return end
    local source=Role(sourceGUID,sourceFlags)
    local dest=Role(destGUID,destFlags)
    if not Secret(sourceName) and type(sourceName)=="string" and sourceName~="" then
        if source=="player" then seenPlayer=sourceName
        elseif source=="pet" then seenPet=sourceName end
    end
    local spell=SPELL_PREFIX[subevent]==true
    local amount=spell and Number(select(4,...)) or Number(select(1,...))
    if DAMAGE[subevent] then
        if source then Add(source,"damage",amount) end
        if dest then Add(dest,"taken",amount) end
    elseif HEAL[subevent] then
        local over=Number(select(5,...))
        if amount and over and over>0 and over<amount then amount=amount-over end
        if source then Add(source,"healing",amount) end
    elseif INTERRUPT[subevent] and source then
        Add(source,"interrupts",1)
    end
end
function ChalkBox_PersonalMeterIngest(...)
    local ok,err=pcall(Ingest,...)
    if not ok then return false,err end
    return true
end
function ChalkBox_PersonalMeterReset()
    current=Blank()
    last=nil
    closed=nil
    pets={}
    seenPlayer,seenPet=nil,nil
    RememberUnits()
    return true
end
local function Rate(amount,seconds)
    amount=Number(amount) or 0
    seconds=Number(seconds) or 0
    if seconds<1 then seconds=1 end
    return amount/seconds
end
local function PlayerName()
    if type(UnitName)=="function" then
        local ok,name=pcall(UnitName,"player")
        if ok and not Secret(name) and type(name)=="string" and name~="" then
            return name
        end
    end
    return seenPlayer or "You"
end
local function PlayerClass()
    if type(UnitClass)~="function" then return nil end
    local ok,_,class=pcall(UnitClass,"player")
    if ok and not Secret(class) and type(class)=="string" then return class end
end
local function PetName()
    if type(UnitName)=="function" then
        local ok,name=pcall(UnitName,"pet")
        if ok and not Secret(name) and type(name)=="string" and name~="" then
            return name
        end
    end
    return seenPet or "Pet"
end
local function View(which,now)
    local box=Totals()
    if which=="expired" or which=="last" then return CopySeg(last),0 end
    if which=="overall" then
        local seg=Blank()
        seg.damage=box.damage
        seg.healing=box.healing
        seg.taken=box.taken
        seg.interrupts=box.interrupts
        seg.petDamage=box.petDamage
        seg.petHealing=box.petHealing
        seg.petTaken=box.petTaken
        seg.petInterrupts=box.petInterrupts
        local extra=0
        if current and not current.archived then
            seg.damage=seg.damage+current.damage
            seg.healing=seg.healing+current.healing
            seg.taken=seg.taken+current.taken
            seg.interrupts=seg.interrupts+current.interrupts
            seg.petDamage=seg.petDamage+current.petDamage
            seg.petHealing=seg.petHealing+current.petHealing
            seg.petTaken=seg.petTaken+current.petTaken
            seg.petInterrupts=seg.petInterrupts+current.petInterrupts
            extra=Elapsed(current,now)
        end
        return seg,box.time+extra
    end
    return CopySeg(current),Elapsed(current,now)
end
function ChalkBox_PersonalMeterSnapshot(session,mode)
    local now=Now()
    local seg,seconds=View(session or "current",now)
    if session~="overall" and not HasNumbers(seg) and not (seg and seg.started) then
        return {combatSources={},maxAmount=0,seconds=0,source="personal",idle=true}
    end
    local field="damage"
    if mode=="healing" or mode=="hps" then field="healing"
    elseif mode=="taken" then field="taken"
    elseif mode=="interrupts" then field="interrupts" end
    local petField=field=="damage" and "petDamage" or field=="healing" and "petHealing"
        or field=="taken" and "petTaken" or "petInterrupts"
    local perSecond=mode=="dps" or mode=="hps"
    local function Row(name,class,localPlayer,isPet,total)
        local shown=perSecond and Rate(total,seconds) or total
        return {name=name,classFilename=class,isLocalPlayer=localPlayer,
            isPet=isPet,totalAmount=total,amountPerSecond=shown}
    end
    local playerTotal=seg[field] or 0
    local petTotal=seg[petField] or 0
    local rows={Row(PlayerName(),PlayerClass(),true,false,playerTotal)}
    if petTotal>0 then
        rows[#rows+1]=Row(PetName(),nil,false,true,petTotal)
    end
    local maxValue=0
    for _,row in ipairs(rows) do
        local shown=perSecond and row.amountPerSecond or row.totalAmount
        if shown>maxValue then maxValue=shown end
    end
    if maxValue<=0 then maxValue=1 end
    return {combatSources=rows,maxAmount=maxValue,seconds=seconds,
        source="personal",idle=false,
        combined=playerTotal+petTotal}
end
function ChalkBox_PersonalMeterStatus()
    local now=Now()
    return {logging=type(CombatLogGetCurrentEventInfo)=="function"
            or type(ChalkBox_PersonalMeterIngest)=="function",
        inCombat=current and current.combat==true,
        seconds=Elapsed(current,now),
        damage=(current and current.damage or 0)+(current and current.petDamage or 0),
        healing=(current and current.healing or 0)+(current and current.petHealing or 0),
        fights=last and 1 or 0}
end
local function OnRegen(enabled)
    local now=Now()
    RememberUnits()
    if enabled then
        if current and current.combat then
            current.combat=false
            current.ended=now
        end
        return
    end
    if current and current.started and not current.archived then
        Archive(now)
    end
    current=Blank()
    current.combat=true
    current.started=now
end
local frame=CreateFrame("Frame")
frame:SetScript("OnEvent",function(_,event,unit)
    if event=="COMBAT_LOG_EVENT_UNFILTERED" then
        if type(CombatLogGetCurrentEventInfo)=="function" then
            pcall(function()
                ChalkBox_PersonalMeterIngest(CombatLogGetCurrentEventInfo())
            end)
        end
    elseif event=="PLAYER_REGEN_DISABLED" then
        OnRegen(false)
    elseif event=="PLAYER_REGEN_ENABLED" then
        OnRegen(true)
    elseif event=="UNIT_PET" or event=="PLAYER_LOGIN"
        or event=="PLAYER_ENTERING_WORLD" then
        if event~="UNIT_PET" or unit=="player" or unit==nil then
            RememberUnits()
        end
    end
end)
for _,event in ipairs({"COMBAT_LOG_EVENT_UNFILTERED","PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED","UNIT_PET","PLAYER_LOGIN","PLAYER_ENTERING_WORLD"}) do
    pcall(frame.RegisterEvent,frame,event)
end
RememberUnits()
