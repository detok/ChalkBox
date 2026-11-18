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
            margin=25,reserves={},ignored={},recipes={},skills={},
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
        profession=db and db.profession or nil,
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
        key~="target" and key~="margin" and key~="profession" then return false end
    if key=="enabled" and value~=true and value~=false then return false end
    if key=="mode" and value~="skill" and value~="gold" then return false end
    if key=="learn" and value~=true and value~=false then return false end
    if key=="target" and value~=10 and value~=25 and value~=50 then return false end
    if key=="margin" and value~=15 and value~=25 and value~=50 then return false end
    if key=="profession" and value~=nil and not PROF_IDS[value] then return false end
    local db=DB(true)
    db[key]=value
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
    lastPlan=nil
    return true
end
local function Reagents(schematic)
    if type(schematic)~="table" or
        type(schematic.reagentSlotSchematics)~="table" then return nil end
    local inputs,slots={},0
    for _,slot in ipairs(schematic.reagentSlotSchematics) do
        if type(slot)~="table" then return nil end
        if slot.required~=false then
            slots=slots+1
            -- Alternatives / optional or quality-choice slots are NOT additive.
            -- If we cannot prove one exact required reagent, omit the recipe.
            if type(slot.reagents)~="table" or #slot.reagents~=1 then
                return nil
            end
            local reagent=slot.reagents[1]
            local id=type(reagent)=="table" and
                (reagent.itemID or reagent.itemId) or nil
            local qty=slot.quantityRequired or
                (type(reagent)=="table" and reagent.quantityRequired)
            if not Int(id) or id<1 or not Int(qty) or qty<1 or
                qty>1000 then return nil end
            inputs[id]=(inputs[id] or 0)+qty
        end
    end
    if slots==0 then return nil end
    return inputs
end
-- Input comes ONLY from C_TradeSkillUI for a genuinely learned recipe.
-- Offline database may enrich difficulty, never grant learned status.
function ChalkBox_IntelObserveRecipe(profession,id,info,schematic)
    if not Enabled() or not PROF_IDS[profession] or not Int(id)
        or id<1 or type(info)~="table" or
        not (info.learned==true or info.isLearned==true) then return false end
    local db=DB(true)
    local inputs=Reagents(schematic)
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
    if not inputs and type(record)=="table" and
        type(record.reagents)=="table" then
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
        -- Stable, single-item outputs can still be inferred from the
        -- bundled catalog, but never claim an uncertain multiple yield.
        yield=1
        if source=="client" then source="output estimate" end
    end
    local old=db.recipes[tostring(id)]
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
    if r.inputs and next(r.inputs) and r.output then
        db.recipes[tostring(id)]=r
    elseif not old then
        -- Keep an incomplete marker for diagnostics, but never plan it.
        db.recipes[tostring(id)]={id=id,profession=profession,
            name=r.name,known=true,source="incomplete"}
    end
    db.profession=profession
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
    local n,units,net=0,0,0
    for _,row in ipairs(sales) do
        if type(row)=="table" and row.name==name and
            Int(row.count) and row.count>0 and
            Int(row.gross) and Int(row.cut) and row.gross>=row.cut then
            n=n+1;units=units+row.count;net=net+row.gross-row.cut
        end
    end
    return n,units>0 and math.floor(net/units) or nil
end
local function UnitValue(id,row,cut)
    local p=Price(id)
    local vendor=row and Int(row.vendor) and row.vendor or 0
    if not p then return vendor,vendor,nil end
    local net=math.floor(p.low*(1-cut))
    -- 15-35% appraisal haircuts are risk buffers, NOT sale probabilities.
    local risk= p.listings and p.listings>=3 and
        p.quantity and p.quantity>=5 and 0.85 or 0.65
    local sample=0
    if row and row.classID==7 and row.name then
        local db=DB(false)
        if not db or db.learn~=false then
            local observed,netSale=Sold(row.name)
            sample=observed
            if observed>=2 and netSale then
                net=math.min(net,netSale)
                risk=0.95
            end
        end
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
    if type(t)=="table" and Int(t.grey) and
        Int(t.green) and Int(t.yellow) and Int(t.orange) then
        if rank>=t.grey then return nil end
        if rank>=t.green then return 0.25 end
        if rank>=t.yellow then return 0.65 end
        return 1
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
local function Forecast(plan,db,list,stock,rowsByID,cut)
    local s=Settings()
    local prof=s.profession
    local skill=db.skills and db.skills[prof]
    if not skill or not Int(skill.rank) or not Int(skill.cap) then
        plan.summary="Skill rank unavailable - open "..tostring(prof or
            "your profession").." window"
        plan.uncertain=true
        return
    end
    local rank,cap=skill.rank,skill.cap
    local capped=rank>=cap
    local steps=s.target
    if not capped then steps=math.min(steps,cap-rank) end
    if capped then
        plan.summary="Skill capped at "..rank.."; planning after rank training"
        plan.uncertain=true
    else
        plan.summary="Forecasting "..steps.." skill points for "..prof
    end
    local counts,selected={},{}
    local planned=0
    for delta=0,steps-1 do
        local at=rank+delta
        local best,bestWeight,bestCost
        for _,r in ipairs(list) do
            if r.profession==prof then
                local w=Weights(r,at)
                if w then
                    local cost,valid=0,true
                    for id,qty in pairs(r.inputs) do
                        local value=UnitValue(id,rowsByID[id],cut)
                        -- A reagent with no price AND no observed vendor
                        -- value is unknown, not a free ingredient.
                        if not Num(value) or value<=0 then
                            valid=false;break
                        end
                        cost=cost+value*qty
                    end
                    local output=UnitValue(r.output,rowsByID[r.output],cut)
                    if valid then
                        cost=math.max(0,cost-output*r.yield)
                        local rate=cost/w
                        if not bestCost or rate<bestCost then
                            best,bestWeight,bestCost=r,w,rate
                        end
                    end
                end
            end
        end
        if not best then break end
        local crafts=math.ceil(1/bestWeight)
        for id,qty in pairs(best.inputs) do
            counts[id]=(counts[id] or 0)+qty*crafts
        end
        selected[best.id]=(selected[best.id] or 0)+crafts
        planned=planned+1
    end
    plan.forecastSteps=planned
    plan.forecastRecipes=selected
    for id,qty in pairs(counts) do
        plan.reserved[id]=math.max(plan.reserved[id] or 0,qty)
    end
    if planned<steps then
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
local function ProfitCandidates(list,byID,cut,s)
    local candidates={}
    local function Add(inputs,output,yield,name,sourceID,steps)
        if not Int(output) or not Int(yield) or yield<1 then return end
        local price=Price(output)
        if not price then return end
        local revenue=UnitValue(output,byID[output],cut)*yield
        local cost=0
        for id,qty in pairs(inputs) do
            if not byID[id] or byID[id].protected or byID[id].bound or
                s.ignored[tostring(id)] or not Price(id) then
                -- Never mistake an unpriced reagent's vendor value for its
                -- market opportunity cost.
                return
            end
            local v=UnitValue(id,byID[id],cut)
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
    local recipes=RecipeList(db)
    if s.mode=="skill" then
        Forecast(plan,db,recipes,stock,byID,cut)
    else
        plan.summary="Profit comparison uses risk-discounted asking prices"
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
        local proposals=ProfitCandidates(recipes,byID,cut,s)
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
                        row.reason="Materials allocated to "..candidate.name..
                            " (estimated added value, not confirmed sales)"
                        row.qty=(row.qty or 0)+n*qty
                        row.advantage=benefit
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
        elseif suggestion then
            kind,qty,reason=suggestion.kind,suggestion.qty,suggestion.reason
        elseif s.mode=="skill" and plan.uncertain and
            type(ChalkBox_LearnedRecipeUses)=="function" and
            #((Call(ChalkBox_LearnedRecipeUses,id,item.name)) or {})>0 and
            reserve==0 then
            kind,qty,reason="REVIEW",item.count,
                "Recipe use known; skill forecast incomplete"
        elseif reserve>=item.count and item.count>0 then
            kind,qty,reason="KEEP",item.count,
                "Reserved for "..(s.mode=="skill" and "skill progression" or "your preference")
        elseif remaining>0 then
            local value,net,evidence=UnitValue(id,item,cut)
            local vendor=Int(item.vendor) and item.vendor or 0
            local netGain=net and (net-vendor)*remaining or 0
            if evidence and netGain>=2000 and net>=vendor*(1+s.margin/100) then
                kind,qty="AUCTION",remaining
                reason="Surplus; "..evidence.source.." asking price "..
                    (evidence.sample=="thin" and "has limited depth" or
                    "has listing sample")..
                    "; outcome not guaranteed"
            elseif item.de and Num(item.de) and
                item.de>(value or 0)*1.25 and reserve==0 then
                kind,qty,reason="CHECK DE",remaining,
                    "Modeled disenchant return may exceed sale alternatives"
            elseif vendor>0 and evidence and net<=vendor then
                kind,qty,reason="VENDOR",remaining,
                    "Vendor price meets/exceeds observed auction net estimate"
            else
                kind,qty,reason="REVIEW",remaining,
                    evidence and "Insufficient net advantage to auction" or
                    "No fresh reliable market asking price"
            end
        else
            kind,qty,reason="KEEP",item.count,"Reserved or allocated to crafts"
        end
        local p=plan.rows[id] or {}
        p.kind,p.qty,p.reason=kind,qty,reason
        p.reserve=reserve
        p.confidence=kind=="KEEP" and "verified" or
            (kind=="AUCTION" or kind=="CRAFT") and "estimate" or "uncertain"
        plan.rows[id]=p
        item.intel=p
        item.note=kind.." "..tostring(qty)..
            (kind=="KEEP" and reserve>0 and " | goal reserve" or
            kind=="AUCTION" and " | observed asks" or "")
        if kind=="AUCTION" then
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
            tooltip:AddLine("Intelligence  |  "..p.kind.." "..tostring(p.qty),
                0.42,0.89,0.73)
            tooltip:AddLine(p.reason,0.68,0.73,0.78,true)
            if p.reserve and p.reserve>0 then
                tooltip:AddLine("Goal reserve: "..p.reserve..
                    " (planning estimate / personal preference)",
                    0.81,0.78,0.52,true)
            end
            tooltip:AddLine("Read-only estimate; no automatic trades",
                0.58,0.63,0.67,true)
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
