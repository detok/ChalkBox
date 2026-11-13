-- ChalkBox RepairLearning 1.9.3: empirical, local-only repair estimates.
-- Learns from merchant-confirmed copper quotes; never repairs, pays or
-- sends data anywhere. Bounded, validated SavedVariables per character.
local VERSION=1
local LIMIT=32
local ERROR_LIMIT=12

local function SafeNumber(n)
    return n~=nil and (type(issecretvalue)~="function" or
        not issecretvalue(n)) and type(n)=="number" and n==n and
        n>=0 and n<1e12
end
local function Fields(gear)
    if type(gear)~="table" or not SafeNumber(gear.max) or
        not SafeNumber(gear.current) or not SafeNumber(gear.items) or
        gear.max<=0 or gear.current>gear.max or gear.items<1 or
        gear.items>19 then return end
    local fingerprint=gear.fingerprint
    if type(fingerprint)~="string" or #fingerprint>600 then
        fingerprint=nil
    end
    return {missing=gear.max-gear.current,max=gear.max,
        items=gear.items,fingerprint=fingerprint}
end
local function Store()
    if type(ChalkBoxZoneDB)~="table" then ChalkBoxZoneDB={} end
    local store=ChalkBoxZoneDB.repairLearning
    if type(store)~="table" or store.version~=VERSION then
        store={version=VERSION,samples={},errors={}}
        ChalkBoxZoneDB.repairLearning=store
    end
    if type(store.samples)~="table" then store.samples={} end
    if type(store.errors)~="table" then store.errors={} end
    return store
end
local function ValidSample(s)
    return type(s)=="table" and SafeNumber(s.cost) and
        s.cost>0 and s.cost<=1e11 and SafeNumber(s.missing) and
        s.missing>0 and SafeNumber(s.max) and s.max>0 and
        SafeNumber(s.items) and s.items>=1 and s.items<=19 and
        (s.fingerprint==nil or (type(s.fingerprint)=="string" and
            #s.fingerprint<=600))
end
local function Similar(s,f)
    local maxDiff=math.abs(s.max-f.max)/s.max
    local countDiff=math.abs(s.items-f.items)
    if maxDiff>0.15 or countDiff>2 then return end
    if f.fingerprint and s.fingerprint and
        s.fingerprint==f.fingerprint then return 3.5,true end
    return 1/(1+maxDiff*5+countDiff*0.8),false
end
local function Median(values)
    if #values==0 then return end
    table.sort(values)
    local center=math.floor((#values+1)/2)
    if #values%2==1 then return values[center] end
    return (values[center]+values[center+1])/2
end
function ChalkBox_RepairLearningPredict(gear)
    local f=Fields(gear)
    if not f then return {state="unavailable",samples=0} end
    local store=Store()
    local samples={}
    local matched={}
    for i=1,math.min(#store.samples,LIMIT) do
        local s=store.samples[i]
        if ValidSample(s) then
            local weight,same=Similar(s,f)
            if weight then
                local item={rate=s.cost/s.missing,weight=weight,
                    same=same,index=i}
                samples[#samples+1]=item
                if same then matched[#matched+1]=item end
            end
        end
    end
    local relevant=#matched>0 and matched or samples
    local used=#relevant
    local validTotal=0
    for i=1,math.min(#store.samples,LIMIT) do
        if ValidSample(store.samples[i]) then validTotal=validTotal+1 end
    end
    local lastError
    if #store.errors>0 then
        local e=store.errors[#store.errors]
        if SafeNumber(e) and e<=10 then
            lastError=math.floor(e*100+0.5)
        end
    end
    local function Result(state,extra)
        extra=extra or {}
        extra.state=state
        extra.samples=validTotal
        extra.matched=used
        extra.lastError=lastError
        return extra
    end
    if f.missing==0 then
        return Result("no-damage",{copper=0,confidence="equipped only"})
    end
    if used==0 then
        -- A valid 1.9.2 calibration remains usable until a real new sample.
        -- No legacy reference is silently promoted to an observed sample.
        local old=type(ChalkBoxZoneDB)=="table" and
            ChalkBoxZoneDB.repairReference or nil
        if validTotal==0 and type(old)=="table" and
            SafeNumber(old.rate) and old.rate>0 and old.rate<1e10 and
            SafeNumber(old.max) and old.max>0 and
            math.abs(f.max-old.max)<=old.max*0.15 then
            return Result("estimate",{copper=math.floor(
                f.missing*old.rate+0.5),confidence="initial",
                source="legacy"})
        end
        return Result(validTotal>0 and "needs-calibration" or "unavailable")
    end
    local rates={}
    for _,s in ipairs(relevant) do
        rates[#rates+1]=s.rate
    end
    local median=Median(rates)
    if not median or not SafeNumber(median) or median<=0 then
        return Result("unavailable")
    end
    -- Outlier-resistant weighted average. Each additional distinct merchant
    -- observation can improve our cost-per-durability estimate. Recent
    -- samples carry slightly more weight. Neither one-off prices nor an
    -- assumed item-level price table are treated as exact.
    local weighted,totalWeight=0,0
    local retained=0
    for _,s in ipairs(relevant) do
        if #relevant<3 or
            (s.rate>=median*0.5 and s.rate<=median*1.5) then
            local age=math.min(s.index or LIMIT,LIMIT)
            local weight=s.weight*(0.65+0.35*(age/LIMIT))
            weighted=weighted+s.rate*weight
            totalWeight=totalWeight+weight
            retained=retained+1
        end
    end
    local rate=totalWeight>0 and weighted/totalWeight or median
    local estimate=f.missing*rate
    if not SafeNumber(estimate) or estimate>1e11 then
        return Result("unavailable")
    end
    local same=#matched>0
    local confidence=retained>=5 and same and "improving" or
        (retained>=2 and same and "developing" or "early")
    return Result("estimate",{copper=math.floor(estimate+0.5),
        confidence=confidence,source=same and "same-gear" or
            "similar-gear",used=retained})
end
function ChalkBox_RepairLearningObserve(gear,exactCost)
    local f=Fields(gear)
    if not f or not SafeNumber(exactCost) or exactCost<=0 or
        exactCost>1e11 or f.missing<=0 then return false end
    local store=Store()
    for _,s in ipairs(store.samples) do
        if ValidSample(s) and s.cost==exactCost and
            s.missing==f.missing and s.max==f.max and
            s.items==f.items and s.fingerprint==f.fingerprint then
            return false -- ticker/event repeats are never training examples
        end
    end
    local prediction=ChalkBox_RepairLearningPredict(gear)
    if prediction.state=="estimate" and SafeNumber(prediction.copper)
        and exactCost>0 then
        local err=math.abs(prediction.copper-exactCost)/exactCost
        if SafeNumber(err) and err<=10 then
            store.errors[#store.errors+1]=err
            while #store.errors>ERROR_LIMIT do table.remove(store.errors,1) end
        end
    end
    store.samples[#store.samples+1]={
        cost=math.floor(exactCost+0.5),missing=f.missing,
        max=f.max,items=f.items,fingerprint=f.fingerprint}
    while #store.samples>LIMIT do table.remove(store.samples,1) end
    if type(ChalkBox_JournalNoteRepair)=="function" then
        pcall(ChalkBox_JournalNoteRepair,exactCost)
    end
    return true
end
function ChalkBox_RepairLearningStatus()
    local store=Store()
    local n=0
    for i=1,math.min(#store.samples,LIMIT) do
        if ValidSample(store.samples[i]) then n=n+1 end
    end
    local last
    if #store.errors>0 and SafeNumber(store.errors[#store.errors]) then
        last=math.floor(store.errors[#store.errors]*100+0.5)
    end
    return {samples=n,lastError=last,limit=LIMIT}
end
function ChalkBox_RepairLearningReset()
    if type(ChalkBoxZoneDB)~="table" then ChalkBoxZoneDB={} end
    ChalkBoxZoneDB.repairLearning={version=VERSION,samples={},errors={}}
    ChalkBoxZoneDB.repairReference=nil
    return true
end
