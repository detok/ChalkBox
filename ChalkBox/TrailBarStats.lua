-- ChalkBox TrailBarStats: native Forever data readers, no UI frame mutations.
-- All comparisons/arithmetic happen only after checking for secret values.
-- Unavailable information is nil, never guessed, cached or displayed as zero.
local function PublicNumber(value)
    return value~=nil and (type(issecretvalue)~="function" or
        not issecretvalue(value)) and type(value)=="number"
        and value==value and value>=0 and value<1e12
end
local function Call(method,...)
    if type(method)~="function" then return end
    local ok,a,b,c,d=pcall(method,...)
    if ok then return a,b,c,d end
end
local function Bags()
    local api=C_Container
    local slots=api and api.GetContainerNumSlots or GetContainerNumSlots
    local freeSlots=api and api.GetContainerNumFreeSlots or GetContainerNumFreeSlots
    if type(slots)~="function" or type(freeSlots)~="function" then return end
    local backpack=PublicNumber(BACKPACK_CONTAINER) and BACKPACK_CONTAINER or 0
    local last=PublicNumber(NUM_BAG_SLOTS) and NUM_BAG_SLOTS or 4
    -- Don't touch bank bags or reagent bank; this is the player's equipped bags.
    if last<backpack or last>8 then last=4 end
    local free,total,general,special,unknown=0,0,0,0,0
    local seen=0
    for bag=backpack,last do
        local count=Call(slots,bag)
        local empty,family=Call(freeSlots,bag)
        if PublicNumber(count) and PublicNumber(empty) and
            count<=500 and empty<=count then
            total=total+count
            free=free+empty
            seen=seen+1
            if not PublicNumber(family) then
                unknown=unknown+empty
            elseif family~=0 then
                special=special+empty
            else
                general=general+empty
            end
        end
    end
    if seen==0 then return end
    return {free=free,total=total,general=general,special=special,
        unknown=unknown,bags=seen}
end
local function Gear()
    if type(GetInventoryItemDurability)~="function" then return end
    local current,max,totalItems,worst=0,0,0,nil
    -- The 1..19 paper-doll inventory slots. Only slots with durability count.
    for slot=1,19 do
        local durability,maximum=Call(GetInventoryItemDurability,slot)
        if PublicNumber(durability) and PublicNumber(maximum)
            and maximum>0 and durability<=maximum then
            current=current+durability
            max=max+maximum
            totalItems=totalItems+1
            local percent=100*durability/maximum
            if not worst or percent<worst then worst=percent end
        end
    end
    if totalItems==0 or max<=0 then return end
    return {percent=math.floor(current*100/max+0.5),
        worst=math.floor(worst+0.5),items=totalItems,
        current=current,max=max}
end
local function Rested(maxXP)
    if not PublicNumber(maxXP) or maxXP<=0 then return end
    local rested=Call(GetXPExhaustion)
    if not PublicNumber(rested) then return end
    return {xp=math.floor(rested),percent=math.floor(100*rested/maxXP+0.5)}
end
local function Latency()
    local _,_,home,world=Call(GetNetStats)
    if not PublicNumber(home) or not PublicNumber(world) then return end
    return {home=math.floor(home+0.5),world=math.floor(world+0.5)}
end
local function Pet()
    if type(UnitClass)~="function" then return end
    local _,class=Call(UnitClass,"player")
    if class~="HUNTER" then return end
    if type(UnitExists)~="function" then return end
    local exists=Call(UnitExists,"pet")
    if exists==nil or (type(issecretvalue)=="function" and issecretvalue(exists)) then
        return {state="unknown"}
    end
    if not exists then return {state="none"} end
    local health=Call(UnitHealth,"pet")
    local max=Call(UnitHealthMax,"pet")
    if not PublicNumber(health) or not PublicNumber(max) or max<=0 then
        return {state="protected"}
    end
    return {state="ready",percent=math.floor(100*math.min(health,max)/max+0.5)}
end

function ChalkBox_BarReadStats(maxXP)
    return {
        bags=Bags(),gear=Gear(),rested=Rested(maxXP),
        latency=Latency(),pet=Pet(),
    }
end
