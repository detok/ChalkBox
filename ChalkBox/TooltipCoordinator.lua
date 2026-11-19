-- ChalkBox Item Insights / Tooltip Coordinator (experimental).
-- Only the owner of addon-added ITEM TOOLTIP lines. Blizzard's own rows,
-- item rarity, native controls and secure frames are never modified.
-- This module is OFF per character until the player explicitly enables it.
local MAX_BASE=7
local MAX_DETAILS=13
local palette={
    info={0.40,0.83,0.78},title={0.94,0.76,0.42},
    good={0.39,0.94,0.62},value={0.98,0.79,0.39},
    count={0.51,0.76,0.98},warning={0.98,0.66,0.33},
    danger={0.98,0.45,0.40},muted={0.65,0.70,0.73},
    text={0.85,0.87,0.88},future={0.72,0.52,1.0},
}
local function Safe(value)
    return value~=nil and
        (type(issecretvalue)~="function" or not issecretvalue(value))
end
local function Num(n)
    return Safe(n) and type(n)=="number" and n==n and
        n>=0 and n<1e13
end
local function Call(fn,...)
    if type(fn)~="function" then return nil end
    local ok,result=pcall(fn,...)
    if ok then return result end
end
local function Money(copper)
    if not Num(copper) then return "unknown" end
    copper=math.floor(copper+0.5)
    local g=math.floor(copper/10000)
    local s=math.floor(copper%10000/100)
    local c=copper%100
    if g>0 then return ("%dg %ds %dc"):format(g,s,c) end
    if s>0 then return ("%ds %dc"):format(s,c) end
    return c.."c"
end
local function Age(seconds)
    if not Num(seconds) then return "unknown age" end
    if seconds<60 then return "just scanned" end
    if seconds<3600 then return math.floor(seconds/60).."m old" end
    if seconds<86400 then return math.floor(seconds/3600).."h old" end
    return math.floor(seconds/86400).."d old"
end
local function Add(list,message,role,limit)
    if type(message)~="string" or message=="" or #message>400 or
        #list>=limit then return end
    for _,entry in ipairs(list) do
        if entry.text==message then return end
    end
    list[#list+1]={text=message,role=role or "text"}
end
-- Character-scoped switch; reading the OFF state creates no saved data.
function ChalkBox_TipCoordinatorEnabled()
    return type(ChalkBoxZoneDB)=="table" and
        ChalkBoxZoneDB.tooltipCoordinator==true
end
function ChalkBox_TipCoordinatorSet(on)
    if type(on)~="boolean" then return false end
    if type(ChalkBoxZoneDB)~="table" then ChalkBoxZoneDB={} end
    ChalkBoxZoneDB.tooltipCoordinator=on
    return true
end
local function Read(context)
    local out={loot=nil,merchant=nil,intel=nil,price=nil,de=nil,drop=nil}
    local vendor=context.vendorOffer==true
    out.merchant=Call(ChalkBox_CoreQuestFact,context.tooltip)
    if vendor then return out end
    out.loot=Call(ChalkBox_LootInsight,context.name,context.link)
    -- If the safety classifier failed, a price is still a fact, but an
    -- economic action must not be presented as safe.
    out.safetyUnknown=out.loot==nil
    local id=type(context.link)=="string" and
        tonumber(context.link:match("item:(%d+)"))
    if not id or id<=0 then return out end
    if Call(ChalkBox_IntelEnabled)==true then
        -- Only a precomputed planner snapshot; no bag/AH scans on hover.
        out.intel=Call(ChalkBox_IntelTooltipInsight,id)
    end
    local status=Call(ChalkBox_AuctionStatus)
    if type(status)=="table" and status.tooltip==true then
        out.price=Call(ChalkBox_AuctionPrice,id)
    end
    -- Legacy DE still displays the modeled outcome for protected gear,
    -- but suppresses destructive comparisons. Keep that information.
    if Call(ChalkBox_DisenchantTooltipsEnabled)==true then
        out.de=Call(ChalkBox_DisenchantEvaluate,context.link)
    end
    out.drop=Call(ChalkBox_DropTooltipInsight,
        context.tooltip,context.link)
    return out
end
-- Pure view model: providers never receive a tooltip to draw into.
function ChalkBox_TipCoordinatorBuild(context)
    if type(context)~="table" or
        not Safe(context.name) or type(context.name)~="string" then
        return nil
    end
    local facts=Read(context)
    local main,extra={},{}
    local merchant=facts.merchant
    local loot=facts.loot
    local intel=facts.intel
    local price=facts.price
    local de=facts.de
    local drop=facts.drop
    local title,reason,role
    local protected=false
    local saleProtected=false
    if type(merchant)=="table" then
        title=merchant.message
        role=merchant.kind=="buy" and "good" or "danger"
        protected=merchant.kind=="keep"
    elseif context.vendorOffer then
        return {main=main,details=extra,facts=facts}
    end
    if type(loot)=="table" then
        protected=protected or loot.protected==true
        saleProtected=saleProtected or loot.saleProtected==true or
            loot.isQuest==true or loot.personalProtect==true
        if not title and loot.isQuest then
            title,reason,role="KEEP",loot.details or
                "Quest item: do not sell or disenchant","danger"
        elseif not title and loot.personalProtect then
            title,reason,role="KEEP","Protected by you","good"
        end
    end
    local riskyIntel=type(intel)=="table" and
        (intel.kind=="AUCTION" or intel.kind=="VENDOR" or
         intel.kind=="CRAFT" or intel.kind=="CHECK DE")
    local obsoleteSale=type(intel)=="table" and type(price)=="table"
        and (price.stale or price.mixed) and
        (intel.kind=="AUCTION" or
         (intel.kind=="VENDOR" and intel.confidence~="verified"))
    if not title and obsoleteSale then
        -- A scan can age or reveal mixed equipment variants AFTER My
        -- Items computed its plan. Never repeat an old sell directive.
        title,role="CHECK AH PRICE","warning"
        reason=price.mixed and
            "Mixed equipment variants; verify the exact item first" or
            "Market snapshot aged; refresh before selling"
    end
    if not title and (saleProtected or facts.safetyUnknown) and riskyIntel then
        title="HOLD"
        reason=facts.safetyUnknown and
            "Protection data unavailable; no sale recommendation" or
            "Quest or personal protection takes precedence"
        role="warning"
    end
    if not title and type(intel)=="table" and
        intel.kind~="IGNORE" and type(intel.headline)=="string" then
        title=intel.headline
        reason=intel.reason
        role=intel.kind=="KEEP" and
                (intel.confidence=="verified" and "good" or "info") or
            intel.kind=="HOLD" and "warning" or
            (intel.kind=="VENDOR" or intel.kind=="AUCTION") and "value" or
            "info"
    end
    if not title and type(loot)=="table" and
        type(loot.label)=="string" then
        title,reason=loot.label,loot.details
        role=loot.role or "text"
    end
    -- Qualifying a possible future quest is more important than a price
    -- or DE comparison, but never silently converts it into a quest KEEP.
    if not title and type(loot)=="table" and
        type(loot.future)=="table" and #loot.future>0 then
        title,role="FUTURE QUEST","future"
    end
    if not title and type(drop)=="table" then
        title,role="PERSONAL DROP HISTORY","count"
    end
    if not title and type(price)=="table" then
        title,role="MARKET OBSERVATION","info"
    end
    if not title and type(de)=="table" then
        title,role="DISENCHANT ESTIMATE","info"
    end
    if not title then
        return {main=main,details=extra,facts=facts}
    end
    Add(main,"ChalkBox  |  Item Insights","info",MAX_BASE)
    Add(main,title,role,MAX_BASE)
    if reason then Add(main,reason,"text",MAX_BASE) end
    if type(loot)=="table" and type(loot.quests)=="table" and
        #loot.quests>0 then
        local q=loot.quests[1]
        if type(q)=="table" then
            local name=type(q.title)=="string" and q.title or "Accepted quest"
            local count=type(q.have)=="number" and
                type(q.required)=="number" and q.required>0 and
                ("  ·  "..q.have.."/"..q.required) or ""
            Add(main,"Quest: "..name..count,"count",MAX_BASE)
        end
        for i,q in ipairs(loot.quests) do
            if i>4 then break end
            if type(q)=="table" and type(q.title)=="string" then
                Add(extra,"Quest "..i..": "..q.title..
                    (q.complete and " (objective complete)" or ""),
                    "count",MAX_DETAILS)
            end
        end
    end
    if type(intel)=="table" then
        Add(extra,intel.goalDetail,"value",MAX_DETAILS)
        if Num(intel.shortfall) and intel.shortfall>0 then
            Add(main,"Missing from bags: "..intel.shortfall,"warning",MAX_BASE)
        end
        Add(main,intel.trainingDetail,"warning",MAX_BASE)
        if obsoleteSale then
            Add(extra,"Earlier sale comparison may be outdated  ·  reopen My Items",
                "warning",MAX_DETAILS)
        else
            Add(extra,intel.comparisonDetail,"value",MAX_DETAILS)
            -- AuctionSense supplies the same raw ask when its switch is ON.
            if type(price)~="table" then
                Add(extra,intel.askDetail,"muted",MAX_DETAILS)
            end
            Add(extra,intel.craftValueDetail,"value",MAX_DETAILS)
        end
        Add(extra,intel.bankDetail,"muted",MAX_DETAILS)
        Add(extra,intel.evidenceDetail,"muted",MAX_DETAILS)
    end
    if type(loot)=="table" and type(loot.future)=="table" and
        #loot.future>0 and not loot.isQuest then
        local first=loot.future[1]
        if type(first)=="table" and type(first.questName)=="string" then
            if title~="FUTURE QUEST" then
                Add(main,"Possible later quest: "..first.questName,
                    "future",MAX_BASE)
            else
                Add(main,"Reference: "..first.questName,
                    "future",MAX_BASE)
            end
        end
        for i,q in ipairs(loot.future) do
            if i>3 then break end
            if type(q)=="table" and type(q.questName)=="string" then
                Add(extra,"Future quest: "..q.questName..
                    (Num(q.required) and "  ·  Need "..q.required or ""),
                    "future",MAX_DETAILS)
            end
        end
        Add(extra,"Reference only; not an active quest","muted",MAX_DETAILS)
    end
    if type(drop)=="table" then
        if Num(drop.quantity) and Num(drop.windows) then
            Add(main,drop.quantity.." found in "..drop.windows..
                " observed loots","count",MAX_BASE)
        end
        if Num(drop.rate) and Num(drop.hits) and Num(drop.attempts) then
            Add(extra,("%.1f%% observed (%d/%d), not official odds"):format(
                drop.rate,drop.hits,drop.attempts),"info",MAX_DETAILS)
        end
    end
    if type(price)=="table" and Num(price.low) then
        if not saleProtected then
            if price.mixed then
                Add(main,"Mixed variants  ·  check exact item",
                    "warning",MAX_BASE)
            elseif price.stale then
                Add(main,"Old AH ask: "..Money(price.low)..
                    "/unit  ·  refresh scan","warning",MAX_BASE)
            else
                Add(main,"AH low ask: "..Money(price.low)..
                    "/unit","value",MAX_BASE)
            end
        end
        Add(extra,"Market: "..tostring(price.market or "unknown")..
            "  ·  "..Age(price.age),"muted",MAX_DETAILS)
        Add(extra,"Lowest ask: "..Money(price.low)..
            "/unit  ·  asking price, not a sale","muted",MAX_DETAILS)
        if Num(price.average) then
            Add(extra,"Average ask: "..Money(price.average).."/unit",
                "value",MAX_DETAILS)
        end
        if price.mixed or price.stale then
            Add(extra,"Price unsuitable for confident sale advice",
                "warning",MAX_DETAILS)
        end
    end
    if type(de)=="table" then
        if de.complete and Num(de.estimated) then
            Add(main,"DE materials: ~"..Money(de.estimated)..
                " in observed asks","info",MAX_BASE)
        elseif de.unconfirmed then
            Add(main,"Disenchant output unconfirmed","warning",MAX_BASE)
        end
        Add(extra,"Disenchant model: Classic reference odds, not verified Forever yields",
            "muted",MAX_DETAILS)
        if not protected then
            Add(extra,de.verdict,"muted",MAX_DETAILS)
        else
            Add(extra,"Protected item  ·  DE model is informational only",
                "warning",MAX_DETAILS)
        end
    end
    if type(loot)=="table" and
        type(loot.recipeDetails)=="string" then
        Add(extra,loot.recipeDetails,"text",MAX_DETAILS)
    end
    return {main=main,details=extra,facts=facts}
end
local function AlreadyShown(tooltip)
    local name=Call(tooltip.GetName,tooltip)
    local num=Call(tooltip.NumLines,tooltip)
    if type(name)~="string" or not Num(num) then return false end
    for i=1,math.min(70,num) do
        local font=_G[name.."TextLeft"..i]
        local line=font and Call(font.GetText,font)
        if line=="ChalkBox  |  Item Insights" then return true end
    end
    return false
end
local function Paint(tooltip,message,role)
    local r,g,b
    if type(ChalkBox_TipColor)=="function" and role~="future" then
        r,g,b=ChalkBox_TipColor(role)
    end
    if not r then
        local color=palette[role] or palette.text
        r,g,b=color[1],color[2],color[3]
    end
    tooltip:AddLine(message,r,g,b,true)
end
function ChalkBox_TipCoordinatorShow(tooltip,context)
    if not ChalkBox_TipCoordinatorEnabled() or not tooltip or
        type(tooltip.AddLine)~="function" then return false end
    -- Core and LootSense both receive native item-tooltip callbacks.
    -- Once rendered, never ask providers to recalculate merely because
    -- the second callback fired for the same shown item.
    if AlreadyShown(tooltip) then return true end
    context=type(context)=="table" and context or {}
    context.tooltip=tooltip
    local ok,view=pcall(ChalkBox_TipCoordinatorBuild,context)
    if not ok or type(view)~="table" then return false end
    if #view.main==0 then return true end
    local shift=type(IsShiftKeyDown)=="function" and
        Call(IsShiftKeyDown)==true
    local written=false
    local renderOK=pcall(function()
        Paint(tooltip," ","muted")
        written=true
        for _,line in ipairs(view.main) do
            Paint(tooltip,line.text,line.role)
        end
        if shift then
            for i=1,math.min(MAX_DETAILS,#view.details) do
                local line=view.details[i]
                Paint(tooltip,line.text,line.role)
            end
        elseif #view.details>0 then
            Paint(tooltip,"Shift + re-hover for details","muted")
        end
        if type(tooltip.Show)=="function" then tooltip:Show() end
    end)
    -- If an exotic tooltip rejects a line after some have already been
    -- added, do not append the entire legacy renderer as a second block.
    return renderOK or written
end
