-- AuctionSense Intelligence: optional, per-character, read-only inventory planner.
-- Never changes bags, posts auctions, modifies protected frames or invokes trades.
-- All prices are observed ASKING prices, never guaranteed sales.
local addonName=...
local MAX_RECIPES=1000
local MAX_ACTIONS=10
local PROF_IDS={Alchemy=171,Blacksmithing=164,Leatherworking=165,
    Tailoring=197,Engineering=202,Enchanting=333,Cooking=185,
    ["First Aid"]=129,Jewelcrafting=755,Inscription=773}
local lastPlan=nil
function ChalkBox_IntelInvalidate()
    lastPlan=nil
end

local function Safe(v)
    return v~=nil and (type(issecretvalue)~="function" or not issecretvalue(v))
end
local function Num(n)
    return Safe(n) and type(n)=="number" and n==n and n>=0 and
        n<1e12 and n~=math.huge
end
local function Int(n) return Num(n) and n%1==0 end
local function Call(fn,...)
    if type(fn)~="function" then return nil end
    local ok,a,b,c=pcall(fn,...)
    if ok and Safe(a) then return a,b,c end
end
local function DB(create)
    if type(ChalkBoxProfessionDB)~="table" then
        if not create then return nil end
        ChalkBoxProfessionDB={}
    end
    local db=ChalkBoxProfessionDB.intelligence
    if type(db)~="table" then
        if not create then return nil end
        db={enabled=false,mode="skill",learn=true,target=25,
            margin=25,protectGoal=true,reserves={},ignored={},recipes={},skills={},
            progress={}}
        ChalkBoxProfessionDB.intelligence=db
    end
    if create then
        if type(db.reserves)~="table" then db.reserves={} end
        if type(db.ignored)~="table" then db.ignored={} end
        if type(db.recipes)~="table" then db.recipes={} end
        if type(db.skills)~="table" then db.skills={} end
        if type(db.progress)~="table" then db.progress={} end
    end
    return db
end
local function Enabled()
    local db=DB(false)
    return db~=nil and db.enabled==true
end
local function Settings()
    local db=DB(false)
    return {enabled=Enabled(),mode=db and db.mode=="gold" and "gold" or "skill",
        learn=not db or db.learn~=false,
        target=db and (db.target==10 or db.target==25 or db.target==50)
            and db.target or 25,
        margin=db and (db.margin==15 or db.margin==25 or db.margin==50)
            and db.margin or 25,
        profession=db and (db.goalProfession or db.primaryProfession or db.profession) or nil,
        goalPinned=db and db.goalProfession~=nil or false,
        lastObserved=db and db.profession or nil,
        protectGoal=not db or db.protectGoal~=false,
        reserveCount=db and db.reserves and db.reserves or {},
        ignored=db and db.ignored and db.ignored or {}}
end
function ChalkBox_IntelStatus()
    local s=Settings()
    local db=DB(false)
    local n=0
    if db and type(db.recipes)=="table" then
        for _ in pairs(db.recipes) do n=n+1 end
    end
    s.recipes=n
    s.skill=db and db.skills and s.profession and db.skills[s.profession]
        or nil
    s.summary=lastPlan and lastPlan.summary or
        (s.enabled and "Open a profession window and AuctionSense > My Items"
            or "Disabled: existing AuctionSense unchanged")
    s.actions=lastPlan and #lastPlan.actions or 0
    return s
end
function ChalkBox_IntelSet(key,value)
    if key~="enabled" and key~="mode" and key~="learn" and
        key~="target" and key~="margin" and key~="profession" and
        key~="protectGoal" then return false end
    if key=="enabled" and value~=true and value~=false then return false end
    if key=="mode" and value~="skill" and value~="gold" then return false end
    if key=="learn" and value~=true and value~=false then return false end
    if key=="target" and value~=10 and value~=25 and value~=50 then return false end
    if key=="margin" and value~=15 and value~=25 and value~=50 then return false end
    if key=="profession" and value~=nil and not PROF_IDS[value] then return false end
    if key=="protectGoal" and value~=true and value~=false then return false end
    local db=DB(true)
    -- Explicit profession selection is a durable goal. Passive scans
    -- still record every skill but never silently replace a pinned goal.
    if key=="profession" then
        db.goalProfession=value
    else
        db[key]=value
    end
    lastPlan=nil
    if key=="enabled" and value and
        type(ChalkBox_ProfessionRefresh)=="function" then
        pcall(ChalkBox_ProfessionRefresh)
    end
    if type(ChalkBox_AuctionRefreshUI)=="function" then
        pcall(ChalkBox_AuctionRefreshUI)
    end
    return true
end
function ChalkBox_IntelReserve(id,amount)
    if not Int(id) or id<1 or not Int(amount) or amount>100000 then return false end
    local db=DB(true)
    db.reserves[tostring(id)]=amount>0 and amount or nil
    lastPlan=nil
    return true
end
-- Read-only preference inspection for our own My Items row. Blizzard's
-- item context menus and bags are never modified.
function ChalkBox_IntelPreference(id)
    if not Int(id) then return 0,false end
    local db=DB(false)
    if not db then return 0,false end
    local reserve=type(db.reserves)=="table" and
        db.reserves[tostring(id)] or nil
    local ignored=type(db.ignored)=="table" and
        db.ignored[tostring(id)] or nil
    return Int(reserve) and reserve or 0,ignored==true
end
function ChalkBox_IntelIgnore(id,ignored)
    if not Int(id) or id<1 then return false end
    local db=DB(true)
    db.ignored[tostring(id)]=ignored==true or nil
    lastPlan=nil
    return true
end
-- Called from ProfessionSense only after real, successfully read skill data.
-- A rank change is proof of progression, NOT proof of which craft caused it.
function ChalkBox_IntelObserveSkill(profession,rank,cap)
    if not Enabled() or not PROF_IDS[profession] or
        not Int(rank) or rank>1000 or not Int(cap) or cap<rank or
        cap>1000 then return false end
    local db=DB(true)
    local old=db.skills[profession]
    if old and db.learn~=false and Int(old.rank) and rank>old.rank then
        local history=db.progress[profession] or {}
        history[#history+1]={from=old.rank,to=rank}
        while #history>24 do table.remove(history,1) end
        db.progress[profession]=history
    end
    db.skills[profession]={rank=rank,cap=cap}
    db.profession=profession
    -- Favor the first observed primary trade over cooking/first aid.
    -- A deliberate user goal in goalProfession always wins.
    if not db.primaryProfession and
        profession~="Cooking" and profession~="First Aid" then
        db.primaryProfession=profession
    end
    lastPlan=nil
    return true
end
local function Reagents(schematic)
    if type(schematic)~="table" or
        type(schematic.reagentSlotSchematics)~="table" then
        return nil,"unavailable"
    end
    local inputs,slots={},0
    for _,slot in ipairs(schematic.reagentSlotSchematics) do
        if type(slot)~="table" then return nil,"ambiguous" end
        if slot.required~=false then
            slots=slots+1
            -- Alternatives / optional or quality-choice slots are NOT additive.
            -- If we cannot prove one exact required reagent, omit the recipe.
            if type(slot.reagents)~="table" or #slot.reagents~=1 or
                (type(slot.variableQuantities)=="table" and
                 next(slot.variableQuantities)) then
                return nil,"ambiguous"
            end
            local reagent=slot.reagents[1]
            local id=type(reagent)=="table" and
                (reagent.itemID or reagent.itemId) or nil
            local qty=slot.quantityRequired or
                (type(reagent)=="table" and reagent.quantityRequired)
            if not Int(id) or id<1 or not Int(qty) or qty<1 or
                qty>1000 then return nil,"ambiguous" end
            inputs[id]=(inputs[id] or 0)+qty
        end
    end
    if slots==0 then return nil,"unavailable" end
    return inputs
end
-- Input comes ONLY from C_TradeSkillUI for a genuinely learned recipe.
-- Offline database may enrich difficulty, never grant learned status.
function ChalkBox_IntelObserveRecipe(profession,id,info,schematic)
    if not Enabled() or not PROF_IDS[profession] or not Int(id)
        or id<1 or type(info)~="table" or
        not (info.learned==true or info.isLearned==true) then return false end
    local db=DB(true)
    local inputs,inputState=Reagents(schematic)
    local lib=nil
    -- LibStub is frequently a callable table, so handle it without
    -- depending on the client exposing a different library API shape.
    if not lib and type(LibStub)=="table" then
        local ok,value=pcall(function()
            return LibStub("LibProfessionDB-1.0",true)
        end)
        if ok then lib=value end
    end
    local record=lib and type(lib.GetRecipe)=="function" and
        Call(lib.GetRecipe,lib,PROF_IDS[profession],id) or nil
    local source="client"
    if not inputs and inputState=="unavailable" and
        type(record)=="table" and type(record.reagents)=="table" then
        local valid,count={},0
        for rawID,rawQty in pairs(record.reagents) do
            local rid=tonumber(rawID)
            if not Int(rid) or rid<1 or not Int(rawQty) or
                rawQty<1 or rawQty>1000 then valid=nil;break end
            valid[rid]=rawQty
            count=count+1
        end
        if valid and count>0 then inputs=valid;source="database fallback" end
    end
    local output=nil
    if type(schematic)=="table" then
        output=schematic.outputItemID
    end
    if not Int(output) and type(record)=="table" then
        output=record.craftedItemId
    end
    local yield=type(schematic)=="table" and schematic.quantityMin or nil
    local maxYield=type(schematic)=="table" and schematic.quantityMax or nil
    if not Int(yield) or yield<1 or not Int(maxYield) or
        maxYield~=yield then
        -- Unknown/variable outputs are never assumed to be one item.
        -- A bad output count can reverse the economic comparison.
        yield=nil
    end
    local tiers=type(record)=="table" and record.difficulty or nil
    local borrowed=lib and type(lib.IsBorrowed)=="function" and
        Call(lib.IsBorrowed,lib,id,"difficulty")
    if borrowed then tiers=nil end
    local r={id=id,profession=profession,name=
        type(info.name)=="string" and info.name or
        type(record)=="table" and record.name or ("Recipe #"..id),
        inputs=inputs,output=Int(output) and output or nil,
        yield=yield,source=source,known=true,
        requiredSkill=type(record)=="table" and record.requiredSkill or nil,
        tiers=type(tiers)=="table" and tiers or nil,
        canSkillUp=info.canSkillUp==true,
        observedRank=db.skills[profession] and db.skills[profession].rank,
        relativeDifficulty=info.relativeDifficulty}
    if r.inputs and next(r.inputs) and r.output and
        Int(r.yield) and r.yield>0 then
        db.recipes[tostring(id)]=r
    else
        -- Never keep previously complete assumptions when newer live
        -- schematic data reports ambiguity or an unknown output.
        db.recipes[tostring(id)]={id=id,profession=profession,
            name=r.name,known=true,source=inputState or "incomplete"}
    end
    db.profession=profession
    if not db.primaryProfession and
        profession~="Cooking" and profession~="First Aid" then
        db.primaryProfession=profession
    end
    lastPlan=nil
    return true
end

local function Price(id)
    local p=Call(ChalkBox_AuctionPrice,id)
    if type(p)~="table" or p.stale or p.mixed or
        not Int(p.low) or p.low<1 or not Num(p.age) or
        p.age>86400 then return nil end
    return p
end
local function Cut()
    local s=Call(ChalkBox_MarketSalesStatus)
    if type(s)=="table" and Int(s.gross) and s.gross>0 and
        Int(s.fees) and s.count and s.count>=5 then
        local rate=s.fees/s.gross
        if rate>=0 and rate<=0.25 then return rate end
    end
    return 0.05 -- explicit estimate, not a verified server rule
end
local function Sold(name)
    if not Safe(name) or type(name)~="string" or #name<3 or
        type(ChalkBox_MarketSaleRows)~="function" then return 0,nil end
    local sales=Call(ChalkBox_MarketSaleRows,name,200)
    if type(sales)~="table" then return 0,nil end
    local n,units,net,last=0,0,0,nil
    for _,row in ipairs(sales) do
        if type(row)=="table" and row.name==name and
            Int(row.count) and row.count>0 and
            Int(row.gross) and Int(row.cut) and row.gross>=row.cut then
            n=n+1;units=units+row.count;net=net+row.gross-row.cut
            if Int(row.at) and (not last or row.at>last) then
                last=row.at
            end
        end
    end
    return n,units>0 and math.floor(net/units) or nil,last
end
local function UnitValue(id,row,cut)
    local p=Price(id)
    local vendor=row and Int(row.vendor) and row.vendor or 0
    local sample,netSale,last=0,nil,nil
    local db=DB(false)
    if row and row.classID==7 and row.name and
        (not db or db.learn~=false) then
        sample,netSale,last=Sold(row.name)
    end
    local now=Call(time)
    if not Int(now) then now=Call(GetServerTime) end
    local provenRecent=sample>=2 and Int(last) and Int(now) and
        now>=last and now-last<=30*86400 and
        Num(netSale) and netSale>0
    if not p then
        if provenRecent then
            -- Actual seller invoices can answer a missing market quote.
            -- The 30% haircut is caution, not a measured sell chance.
            local estimated=math.floor(netSale*0.70)
            return math.max(vendor,estimated),estimated,
                {age=now-last,sales=sample,source="personal sales",
                 sample="confirmed",risk=0.70}
        end
        return vendor,vendor,nil
    end
    local net=math.floor(p.low*(1-cut))
    -- 15-35% appraisal haircuts are risk buffers, NOT sale probabilities.
    local risk= p.listings and p.listings>=3 and
        p.quantity and p.quantity>=5 and 0.85 or 0.65
    if provenRecent then
        net=math.min(net,netSale)
        risk=0.95
    end
    return math.max(vendor,math.floor(net*risk)),net,
        {ask=p.low,age=p.age,sales=sample,source=p.source,
         sample=p.listings and p.listings>=3 and p.quantity and
            p.quantity>=5 and "sampled" or "thin",
         risk=risk}
end
local function AddAction(plan,kind,id,qty,detail,advantage)
    if #plan.actions>=MAX_ACTIONS then return end
    plan.actions[#plan.actions+1]={kind=kind,itemID=id,
        count=qty,reason=detail,advantage=advantage}
end
local function Weights(recipe,rank)
    if not Int(rank) then return nil end
    if Int(recipe.requiredSkill) and rank<recipe.requiredSkill then return nil end
    local t=recipe.tiers
    if type(t)=="table" then
        -- Forever LibProfessionDB difficulty is {orange,yellow,green,grey};
        -- keep named-field support for other clients/tests. Validate order
        -- to avoid presenting malformed data as a reliable skill plan.
        local orange=t.orange or t[1]
        local yellow=t.yellow or t[2]
        local green=t.green or t[3]
        local grey=t.grey or t[4]
        if Int(orange) and Int(yellow) and Int(green) and Int(grey)
            and orange<=yellow and yellow<=green and green<=grey then
            if rank>=grey then return nil end
            if rank>=green then return 0.25 end
            if rank>=yellow then return 0.65 end
            return 1
        end
    end
    -- Only the currently observed client result can support an otherwise
    -- undocumented skill-up. Do not extrapolate across future ranks.
    if recipe.canSkillUp and rank==recipe.observedRank then return 0.5 end
end
local function RecipeList(db)
    local list={}
    if not db or type(db.recipes)~="table" then return list end
    for _,r in pairs(db.recipes) do
        if type(r)=="table" and type(r.inputs)=="table" and
            next(r.inputs) and Int(r.output) and Int(r.yield)
            and r.yield>=1 and r.yield<=100 then
            list[#list+1]=r
            if #list>=MAX_RECIPES then break end
        end
    end
    table.sort(list,function(a,b) return a.id<b.id end)
    return list
end
local function Forecast(plan,db,list,stock,valueFn)
    local s=Settings()
    local prof=s.profession
    local skill=db.skills and db.skills[prof]
    if not skill or not Int(skill.rank) or not Int(skill.cap) then
        plan.summary="Open "..tostring(prof or
            "your profession").." to record your skill and cap"
        plan.incomplete=true
        plan.uncertain=true
        return
    end
    local rank,cap=skill.rank,skill.cap
    local capped=rank>=cap
    plan.skillRank,plan.skillCap,plan.skillGoal=rank,cap,prof
    plan.capped=capped
    local steps=s.target
    if not capped then steps=math.min(steps,cap-rank) end
    if capped then
        plan.summary="Skill capped at "..rank.."; planning after rank training"
        plan.uncertain=true
    else
        plan.summary="Forecasting "..steps.." skill points for "..prof
    end
    local counts,selected,uses,routeDetails={},{},{},{}
    local planned=0
    for delta=0,steps-1 do
        local at=rank+delta
        local best,bestWeight,bestCost,bestUnknown
        for _,r in ipairs(list) do
            if r.profession==prof then
                local w=Weights(r,at)
                if w then
                    local cost,missing,unknown=0,0,false
                    local crafts=math.ceil(1/w)
                    for id,qty in pairs(r.inputs) do
                        local value=valueFn(id)
                        -- Price influences WHICH eligible recipe is cheaper,
                        -- never WHETHER its known reagents can be forecast.
                        -- Stock on hand is known even without an AH scan.
                        if not Num(value) or value<=0 then
                            unknown=true
                            value=1000 -- scoring penalty, NOT a market value
                        end
                        cost=cost+value*qty
                        local held=math.max(0,(stock[id] or 0)-
                            (counts[id] or 0))
                        missing=missing+math.max(0,qty*crafts-held)
                    end
                    local output=valueFn(r.output)
                    cost=math.max(0,cost-
                        (Num(output) and output or 0)*r.yield)
                    -- Prefer routes using items actually carried, without
                    -- treating absent price information as a free reagent.
                    local rate=cost/w+missing*100000+
                        (unknown and 10000 or 0)
                    if not bestCost or rate<bestCost then
                        best,bestWeight,bestCost,bestUnknown=
                            r,w,rate,unknown or missing>0
                    end
                end
            end
        end
        if not best then break end
        if bestUnknown then plan.uncertain=true end
        local crafts=math.ceil(1/bestWeight)
        for id,qty in pairs(best.inputs) do
            counts[id]=(counts[id] or 0)+qty*crafts
        end
        selected[best.id]=(selected[best.id] or 0)+crafts
        local detail=routeDetails[best.id]
        if not detail then
            detail={recipeID=best.id,name=best.name,crafts=0,
                predictedSteps=0,source=best.source}
            routeDetails[best.id]=detail
        end
        detail.crafts=detail.crafts+crafts
        detail.predictedSteps=detail.predictedSteps+1
        for id,qty in pairs(best.inputs) do
            local byRecipe=uses[id] or {}
            byRecipe[best.id]=(byRecipe[best.id] or 0)+qty*crafts
            uses[id]=byRecipe
        end
        planned=planned+1
    end
    plan.forecastSteps=planned
    plan.forecastRecipes=selected
    plan.goalReserve=counts
    plan.goalUses=uses
    local route={}
    for _,r in pairs(routeDetails) do route[#route+1]=r end
    table.sort(route,function(a,b)
        if a.crafts==b.crafts then return a.recipeID<b.recipeID end
        return a.crafts>b.crafts
    end)
    plan.route=route
    for id,qty in pairs(counts) do
        plan.reserved[id]=math.max(plan.reserved[id] or 0,qty)
    end
    if planned<steps then
        plan.incomplete=true
        plan.uncertain=true
        plan.summary=plan.summary..
            " | incomplete recipe/difficulty coverage"
    end
    if capped then
        plan.summary=plan.summary.." | no skill gains until trained"
    end
end
local function InputsReady(inputs,budget)
    local maxCraft=100
    for id,qty in pairs(inputs) do
        if not Int(qty) or qty<1 then return 0 end
        maxCraft=math.min(maxCraft,math.floor((budget[id] or 0)/qty))
    end
    return maxCraft
end
local function ProfitCandidates(list,byID,valueFn,s)
    local candidates={}
    local function Add(inputs,output,yield,name,sourceID,steps)
        if not Int(output) or not Int(yield) or yield<1 then return end
        local outputValue,_,outputEvidence=valueFn(output)
        if not outputEvidence or not outputEvidence.ask then return end
        local revenue=outputValue*yield
        local cost=0
        for id,qty in pairs(inputs) do
            if not byID[id] or byID[id].protected or byID[id].bound or
                byID[id].boundKnown~=true or s.ignored[tostring(id)] then
                -- Never mistake an unpriced reagent's vendor value for its
                -- market opportunity cost.
                return
            end
            local v,_,evidence=valueFn(id)
            -- Never call a missing quote a free material. Confirmed
            -- personal sales alone remain insufficient to value a craft.
            if not v or not evidence or not evidence.ask then return end
            cost=cost+v*qty
        end
        if cost<=0 then return end
        local gain=revenue-cost
        if gain<2000 or gain*100<cost*s.margin then return end
        candidates[#candidates+1]={inputs=inputs,output=output,
            yield=yield,name=name,sourceID=sourceID,steps=steps,
            gain=gain,rate=gain/cost}
    end
    for _,a in ipairs(list) do
        Add(a.inputs,a.output,a.yield,a.name,a.id,1)
    end
    -- Index by intermediate ingredient to avoid quadratic all-recipe scans.
    -- Bounded search: evaluate only actual connected recipe pairs.
    local consumers={}
    for _,b in ipairs(list) do
        for id in pairs(b.inputs) do
            consumers[id]=consumers[id] or {}
            consumers[id][#consumers[id]+1]=b
        end
    end
    -- Two-step transformations; require one exact intermediate input.
    -- No free outputs, alternative reagents, loops, or double-counting.
    for _,a in ipairs(list) do
        for _,b in ipairs(consumers[a.output] or {}) do
            if a.id~=b.id and a.output~=b.output and
                b.inputs[a.output] and Int(b.inputs[a.output]) then
                local multiplier=math.ceil(b.inputs[a.output]/a.yield)
                local combined={}
                for id,qty in pairs(a.inputs) do
                    combined[id]=(combined[id] or 0)+qty*multiplier
                end
                for id,qty in pairs(b.inputs) do
                    if id~=a.output then
                        combined[id]=(combined[id] or 0)+qty
                    end
                end
                if combined[b.output]==nil and combined[a.output]==nil then
                    Add(combined,b.output,b.yield,
                        a.name.." > "..b.name,a.id,2)
                end
            end
        end
    end
    table.sort(candidates,function(a,b)
        if a.rate==b.rate then return a.gain>b.gain end
        return a.rate>b.rate
    end)
    return candidates
end
local function UsedByGoal(id,name,profession)
    if not profession or
        type(ChalkBox_LearnedRecipeUses)~="function" then return false end
    local uses=Call(ChalkBox_LearnedRecipeUses,id,name)
    if type(uses)~="table" then return false end
    for _,entry in ipairs(uses) do
        if type(entry)=="table" and entry.profession==profession then
            return true
        end
    end
    return false
end
local function Analyze(rows,stats)
    if not Enabled() then return nil end
    local s=Settings()
    local db=DB(true)
    local byID,stock={},{}
    for _,row in ipairs(rows) do
        if Int(row.itemID) and Int(row.count) then
            byID[row.itemID]=row
            stock[row.itemID]=row.count
        end
    end
    local plan={mode=s.mode,actions={},reserved={},rows={},
        forecastRecipes={},forecastSteps=0,
        pressure=stats and stats.freeSlots or nil,
        summary="",uncertain=false}
    for id,n in pairs(s.reserveCount) do
        local key=tonumber(id)
        if Int(key) and Int(n) then plan.reserved[key]=n end
    end
    local cut=Cut()
    local cachedValues={}
    local function Value(itemID)
        local cached=cachedValues[itemID]
        if not cached then
            local v,net,evidence=UnitValue(itemID,byID[itemID],cut)
            cached={v,net,evidence}
            cachedValues[itemID]=cached
        end
        return cached[1],cached[2],cached[3]
    end
    local recipes=RecipeList(db)
    if s.mode=="skill" or s.protectGoal then
        Forecast(plan,db,recipes,stock,Value)
    end
    if s.mode=="gold" then
        plan.summary=s.protectGoal and
            ("Gold opportunities; reserving for "..
            tostring(s.profession or "profession")..
            (plan.incomplete and " (incomplete forecast)" or "")) or
            "Gold opportunities; profession reserves disabled"
    end
    local budget={}
    for id,count in pairs(stock) do
        budget[id]=math.max(0,count-(plan.reserved[id] or 0))
        local row=byID[id]
        if row.protected or row.bound or s.ignored[tostring(id)] then
            budget[id]=0
        end
    end
    if s.mode=="gold" then
        local proposals=ProfitCandidates(recipes,byID,Value,s)
        local used=0
        for _,candidate in ipairs(proposals) do
            if used>=6 then break end
            local qty=math.min(InputsReady(candidate.inputs,budget),20)
            if qty>0 then
                local benefit=math.floor(candidate.gain*qty)
                if benefit>=2000 then
                    for id,n in pairs(candidate.inputs) do
                        budget[id]=budget[id]-n*qty
                        local row=plan.rows[id] or {}
                        row.kind="CRAFT"
                        row.reason="Use as ingredients for "..candidate.name..
                            "; projected advantage is not guaranteed profit"
                        row.qty=(row.qty or 0)+n*qty
                        row.crafts=row.crafts or {}
                        if #row.crafts<4 then
                            row.crafts[#row.crafts+1]={name=candidate.name,
                                count=qty}
                        end
                        row.advantage=(row.advantage or 0)+benefit
                        plan.rows[id]=row
                    end
                    AddAction(plan,"CRAFT",candidate.sourceID,qty,
                        candidate.name.." | risk-discounted extra value",benefit)
                    used=used+1
                end
            end
        end
    end
    for _,item in ipairs(rows) do
        local id=item.itemID
        local reserve=plan.reserved[id] or 0
        local remaining=budget[id] or 0
        local suggestion=plan.rows[id]
        local note,reason,kind,qty
        if s.ignored[tostring(id)] then
            kind,qty,reason="IGNORE",0,"Ignored by your preference"
        elseif item.protected then
            kind,qty,reason="KEEP",item.count,"Personal or quest protection"
        elseif item.bound then
            kind,qty,reason="KEEP",item.count,"Bound item; never recommend auction"
        elseif item.boundKnown~=true then
            kind,qty,reason="HOLD",item.count,
                "Tradeability unverified; do not auction or vendor yet"
        elseif suggestion then
            kind,qty,reason=suggestion.kind,suggestion.qty,suggestion.reason
        elseif (s.mode=="skill" or s.protectGoal) and
            plan.incomplete and reserve==0 and
            UsedByGoal(id,item.name,s.profession) then
            kind,qty,reason="HOLD",item.count,
                "Used by known "..tostring(s.profession)..
                " recipes; progression forecast is incomplete"
        elseif reserve>=item.count and item.count>0 then
            kind,qty,reason="KEEP",item.count,
                "Reserved for "..(s.mode=="skill" and "skill progression" or "your preference")
        elseif remaining>0 then
            local value,net,evidence=Value(id)
            local vendor=Int(item.vendor) and item.vendor or 0
            local netGain=value and (value-vendor)*remaining or 0
            if evidence and netGain>=2000 and
                value>=vendor*(1+s.margin/100) then
                kind,qty="AUCTION",remaining
                if evidence.source=="personal sales" then
                    reason="Surplus; repeated recent seller invoices "..
                        "support value, but current asks are unknown"
                else
                    reason="Surplus; "..tostring(evidence.source)..
                        " asking prices "..
                        (evidence.sample=="thin" and
                            "have limited depth" or "have listing samples")..
                        "; outcome not guaranteed"
                end
            elseif item.de and Num(item.de) and
                item.de>(value or 0)*1.25 and reserve==0 then
                kind,qty,reason="CHECK DE",remaining,
                    "Modeled disenchant return may exceed sale alternatives"
            elseif vendor>0 and item.quality==0 then
                kind,qty,reason="VENDOR",remaining,
                    "Junk quality; instant vendor value beats unknown AH effort"
            elseif vendor>0 and evidence and value<=vendor then
                kind,qty,reason="VENDOR",remaining,
                    "Risk-adjusted auction return does not beat vendor value"
            elseif evidence and vendor>0 and netGain<2000 then
                kind,qty,reason="VENDOR",remaining,
                    "Estimated auction premium too small for listing effort"
            elseif not evidence and
                s.mode=="skill" and reserve>0 then
                kind,qty,reason="HOLD",remaining,
                    "Keep unpriced surplus until progression needs are settled"
            elseif not evidence then
                kind,qty,reason="SCAN AH",remaining,
                    "Price evidence missing; scan before choosing AH or vendor"
            else
                kind,qty,reason="HOLD",remaining,
                    "Small or uncertain auction advantage; retain for now"
            end
        else
            kind,qty,reason="KEEP",item.count,"Reserved or allocated to crafts"
        end
        local p=plan.rows[id] or {}
        p.kind,p.qty,p.reason=kind,qty,reason
        p.reserve=reserve
        p.stock=item.count
        p.keep=math.min(item.count,reserve)
        p.shortfall=math.max(0,reserve-item.count)
        p.surplus=math.max(0,item.count-reserve)
        p.goalReserve=plan.goalReserve and (plan.goalReserve[id] or 0) or 0
        p.mode=s.mode
        p.profession=s.profession
        p.capped=plan.capped
        p.skillRank,p.skillCap=plan.skillRank,plan.skillCap
        p.incomplete=plan.incomplete==true
        p.confidence=(item.protected or item.bound or kind=="IGNORE" or
                (kind=="VENDOR" and item.quality==0)) and "verified" or
            (kind=="AUCTION" or kind=="CRAFT" or reserve>0)
                and "estimated" or "limited"
        local neededBy=plan.goalUses and plan.goalUses[id]
        if type(neededBy)=="table" then
            local recipeID,most=0,0
            for candidateID,amount in pairs(neededBy) do
                if amount>most then recipeID,most=candidateID,amount end
            end
            local recipe=db.recipes[tostring(recipeID)]
            if recipe and type(recipe.name)=="string" then
                p.goalRecipe=recipe.name
                p.goalRecipeCrafts=plan.forecastRecipes[recipeID]
            end
        end
        local unit=tostring(qty or 0)
        if kind=="AUCTION" then
            p.headline="Auction "..unit..
                (p.keep>0 and " | Keep "..p.keep or "")
        elseif kind=="CRAFT" then
            p.headline="Use "..unit.." in crafts"..
                (p.keep>0 and " | Keep "..p.keep or "")
        elseif kind=="VENDOR" then
            p.headline="Vendor "..unit
        elseif kind=="CHECK DE" then
            p.headline="Compare disenchant | "..unit
        elseif kind=="SCAN AH" then
            p.headline="Check AH price | "..unit
        elseif kind=="IGNORE" then
            p.headline="Advice hidden by you"
        elseif kind=="KEEP" then
            p.headline="Keep "..tostring(item.count)
        else
            p.headline="Hold "..tostring(item.count)
        end
        if p.goalReserve>0 and p.goalRecipe then
            p.goalDetail="Plan: "..tostring(p.goalRecipeCrafts or "?")..
                " crafts of "..p.goalRecipe.."; needs "..
                p.goalReserve.." of this material"
        elseif p.goalReserve>0 then
            p.goalDetail=tostring(s.profession or "Profession")..
                " progression plan uses "..p.goalReserve.." units"
        elseif reserve>0 then
            p.goalDetail="Personal reserve: "..reserve.." units"
        end
        if p.capped and p.goalReserve>0 then
            p.trainingDetail="Skill capped at "..tostring(p.skillRank)..
                "; training required before further skill gains"
        end
        p.evidenceDetail=p.confidence=="verified" and
            "Evidence: verified protection / item property" or
            p.confidence=="estimated" and
            "Evidence: provisional recipe or market calculation" or
            "Evidence: incomplete; no guaranteed sale or skill gain"
        plan.rows[id]=p
        item.intel=p
        item.note=p.headline
        if kind=="AUCTION" or kind=="SCAN AH" then
            AddAction(plan,kind,id,qty,reason)
        elseif kind=="VENDOR" and stats and
            Num(stats.freeSlots) and stats.freeSlots<=4 then
            AddAction(plan,kind,id,qty,reason)
        end
    end
    lastPlan=plan
    return plan
end
function ChalkBox_IntelAnnotate(rows,stats)
    if not Enabled() or type(rows)~="table" then return nil end
    local ok,result=pcall(Analyze,rows,stats)
    if ok then return result end
    -- A failed optional planner must not break the existing My Items table.
    lastPlan=nil
    return nil
end
function ChalkBox_IntelActions(limit)
    local result={}
    if not Enabled() or not lastPlan then return result end
    limit=Int(limit) and math.min(10,limit) or 5
    for i=1,math.min(limit,#lastPlan.actions) do
        local a=lastPlan.actions[i]
        result[#result+1]={kind=a.kind,itemID=a.itemID,
            count=a.count,reason=a.reason,advantage=a.advantage}
    end
    return result
end
function ChalkBox_IntelTooltip(tooltip,link)
    if not Enabled() or not tooltip or type(tooltip.AddLine)~="function"
        or type(link)~="string" then return false end
    local id=tonumber(link:match("item:(%d+)"))
    if not Int(id) or type(ChalkBox_MarketBagRows)~="function" then
        return false
    end
    local name=Call(tooltip.GetName,tooltip)
    if type(name)=="string" and type(tooltip.NumLines)=="function" then
        local n=Call(tooltip.NumLines,tooltip) or 0
        for i=1,math.min(40,n) do
            local f=_G[name.."TextLeft"..i]
            local line=f and Call(f.GetText,f)
            if type(line)=="string" and
                line:find("Intelligence  |  ",1,true) then return false end
        end
    end
    -- Reuse the most recent bag appraisal. Rebuild only after a bag, recipe,
    -- preference or auction-snapshot change; never re-plan every hover.
    if not lastPlan or not lastPlan.rows[id] then
        local rows=Call(ChalkBox_MarketBagRows,"",250)
        if type(rows)~="table" then return false end
    end
    local p=lastPlan and lastPlan.rows[id]
    if p then
        tooltip:AddLine("ChalkBox  |  "..(p.mode=="gold" and
            "Make Gold" or "Skill Up"),0.42,0.89,0.73)
        tooltip:AddLine(p.headline or "Hold for now",0.91,0.89,0.70,true)
        tooltip:AddLine(p.reason or "Additional evidence needed",
            0.78,0.82,0.84,true)
        if p.goalDetail then
            tooltip:AddLine(p.goalDetail,0.81,0.78,0.52,true)
        end
        if p.shortfall and p.shortfall>0 then
            tooltip:AddLine("Missing from bags: "..p.shortfall..
                " to meet the reserve",0.91,0.65,0.38,true)
        end
        if p.trainingDetail then
            tooltip:AddLine(p.trainingDetail,0.91,0.65,0.38,true)
        end
        tooltip:AddLine(p.evidenceDetail or "Decision is an estimate",
            0.58,0.70,0.74,true)
        if type(tooltip.Show)=="function" then tooltip:Show() end
        return true
    end
    return false
end
function ChalkBox_IntelCommand(message)
    message=type(message)=="string" and message:lower() or ""
    local cmd,arg=message:match("^(%S+)%s*(.-)%s*$")
    if cmd=="on" or cmd=="off" then
        ChalkBox_IntelSet("enabled",cmd=="on")
    elseif cmd=="skill" or cmd=="gold" then
        ChalkBox_IntelSet("mode",cmd)
    elseif cmd=="reserve" then
        local id,n=arg:match("^(%d+)%s+(%d+)$")
        if id and n then ChalkBox_IntelReserve(tonumber(id),tonumber(n)) end
    elseif cmd=="ignore" or cmd=="unignore" then
        local id=tonumber(arg)
        if id then ChalkBox_IntelIgnore(id,cmd=="ignore") end
    elseif cmd=="target" or cmd=="margin" then
        ChalkBox_IntelSet(cmd,tonumber(arg))
    elseif cmd=="learn" and (arg=="on" or arg=="off") then
        ChalkBox_IntelSet("learn",arg=="on")
    elseif cmd=="profession" then
        for profession in pairs(PROF_IDS) do
            if profession:lower()==arg then
                ChalkBox_IntelSet("profession",profession);break
            end
        end
    end
    local s=ChalkBox_IntelStatus()
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff67c6b7ChalkBox Intelligence|r "..
            (s.enabled and "ON" or "OFF").." | "..s.mode..
            " | "..tostring(s.profession or "No profession scanned")..
            " | "..s.summary..
            " | commands: on/off, skill/gold, target 10/25/50, margin 15/25/50, reserve ID QTY, ignore ID, unignore ID")
    end
    return s
end
