-- ChalkBox TrailBarStats: native Forever data readers, no UI frame mutations.
-- All comparisons/arithmetic happen only after checking for secret values.
-- Unavailable information is nil, never guessed, cached or displayed as zero.
local function PublicNumber(value)
    return value~=nil and (type(issecretvalue)~="function" or
        not issecretvalue(value)) and type(value)=="number"
        and value==value and value>=0 and value<1e12
end
local function Public(value)
    return value~=nil and (type(issecretvalue)~="function" or
        not issecretvalue(value))
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

-- Reusable resale valuation for equipped bags only (0 through 4).
-- Grey/poor quality (quality=0) is "junk"; "total" counts every item.
-- Unknown cache entries lower confidence instead of silently becoming zero.
local function BagVendorValue()
    local api=C_Container
    local slots=api and api.GetContainerNumSlots or GetContainerNumSlots
    local slotInfo=api and api.GetContainerItemInfo or GetContainerItemInfo
    local slotID=api and api.GetContainerItemID or GetContainerItemID
    local itemInfo=(C_Item and C_Item.GetItemInfo) or GetItemInfo
    if type(slots)~="function" or type(slotInfo)~="function"
        or type(itemInfo)~="function" then return end
    local backpack=PublicNumber(BACKPACK_CONTAINER) and BACKPACK_CONTAINER or 0
    local last=PublicNumber(NUM_BAG_SLOTS) and NUM_BAG_SLOTS or 4
    if last<backpack or last>8 then last=4 end
    local total,junk=0,0
    local unknown,unknownJunk=0,0
    local priced,junkStacks,zeroStacks,observed=0,0,0,0
    local function Unknown()
        unknown=unknown+1
        unknownJunk=unknownJunk+1
    end
    for bag=backpack,last do
        local count=Call(slots,bag)
        -- A missing empty equipped bag can be nil on some clients.
        -- Secret or invalid bag sizes are unknown, not a presumed zero.
        if count~=nil and not PublicNumber(count) then
            Unknown()
        elseif PublicNumber(count) and (count>500 or count%1~=0) then
            Unknown()
        elseif PublicNumber(count) then
            observed=observed+1
            for slot=1,count do
                local success,raw,oldCount,_,oldQuality,_,_,oldLink,_,
                    oldNoValue,oldID=pcall(slotInfo,bag,slot)
                local item,quantity,quality,noValue,identity
                if not success or (type(issecretvalue)=="function"
                    and issecretvalue(raw)) then
                    Unknown()
                elseif raw==nil then
                    -- Empty slots are not "unknown"; an actual pending item
                    -- ID is unresolved until its full container data arrives.
                    if type(slotID)=="function" then
                        local ok,id=pcall(slotID,bag,slot)
                        if not ok or (type(issecretvalue)=="function"
                            and issecretvalue(id)) then Unknown()
                        elseif id~=nil then Unknown() end
                    end
                else
                    item=raw
                    local fieldsOK=true
                    if type(item)=="table" then
                        local link,id
                        fieldsOK,quantity,quality,noValue,link,id=
                            pcall(function()
                                return item.stackCount,item.quality,
                                    item.hasNoValue,item.hyperlink,item.itemID
                            end)
                        identity=Public(link) and link or (Public(id) and id or nil)
                    else
                        quantity,quality,noValue=oldCount,oldQuality,oldNoValue
                        identity=Public(oldLink) and oldLink or
                            (Public(oldID) and oldID or nil)
                    end
                    if not fieldsOK or not PublicNumber(quantity) or
                        quantity<1 or quantity>100000 or quantity%1~=0 or
                        (type(issecretvalue)=="function" and
                            issecretvalue(noValue)) then
                        Unknown()
                    else
                        if not Public(identity) or
                            (type(identity)~="string" and
                                type(identity)~="number") then
                            identity=nil
                        end
                        if identity==nil then
                            Unknown()
                        else
                            local ok,q,price=pcall(function()
                                local _,_,qValue,_,_,_,_,_,_,_,sell=itemInfo(identity)
                                return qValue,sell
                            end)
                            if not ok then q,price=nil,nil end
                            if not PublicNumber(quality) then quality=q end
                            -- noValue is verified by Blizzard as 0 copper;
                            -- don't mistake an absent item cache for zero.
                            if noValue==true then price=0 end
                            if not PublicNumber(price) or price>1000000000 or
                                total+price*quantity>=1e12 then
                                Unknown()
                            else
                                total=total+price*quantity
                                if price==0 then zeroStacks=zeroStacks+1
                                else priced=priced+1 end
                                if PublicNumber(quality) and quality==0 then
                                    junk=junk+price*quantity
                                    junkStacks=junkStacks+1
                                elseif not PublicNumber(quality) then
                                    unknownJunk=unknownJunk+1
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if observed==0 then return end
    return {totalCopper=total,junkCopper=junk,
        totalUnknown=unknown,junkUnknown=unknownJunk,
        totalComplete=unknown==0,junkComplete=unknownJunk==0,
        priced=priced,junkStacks=junkStacks,zeroStacks=zeroStacks}
end

function ChalkBox_BarReadStats(maxXP, includeBagValue)
    return {
        bags=Bags(),gear=Gear(),rested=Rested(maxXP),
        latency=Latency(),pet=Pet(),
        bagvalue=includeBagValue==true and BagVendorValue() or nil,
    }
end
