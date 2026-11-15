-- DisenchantSense: read-only Forever client bracket + Classic-reference odds.
-- Data is vendored intact under Libs/ForeverDisenchantData (MIT APGM82).
-- No network calls, automatic disenchanting, bag hooks, or item actions.
local addonName, ns = ...
local enabled=true
local ref=ns and ns.materials
local blocked=ns and ns.noDisenchant
local special=ns and ns.ownLoot
local function Public(v)
    return v~=nil and (type(issecretvalue)~="function" or not issecretvalue(v))
end
local function ID(item)
    if type(item)=="number" and item>0 and item==math.floor(item) then
        return item
    end
    if not Public(item) or type(item)~="string" then return nil end
    local id=item:match("item:(%d+)")
    if not id then id=item:match("^(%d+)$") end
    return id and tonumber(id) or nil
end
local function Money(n)
    if type(n)~="number" or n~=n or n<0 then return "—" end
    n=math.floor(n+0.5)
    local g=math.floor(n/10000)
    local s=math.floor(n%10000/100)
    local c=n%100
    if g>0 then return ("%dg %ds %dc"):format(g,s,c) end
    if s>0 then return ("%ds %dc"):format(s,c) end
    return ("%dc"):format(c)
end
local function Metadata(item)
    local fn=(C_Item and C_Item.GetItemInfo) or GetItemInfo
    if type(fn)~="function" then return nil end
    local ok,name,link,quality,ilvl,reqLevel,category,subtype,stack,slot,
        icon,vendor,classID,subclassID=pcall(fn,item)
    if not ok or not Public(name) or not Public(ilvl)
        or type(ilvl)~="number" or ilvl<5 or ilvl>99
        or (quality~=2 and quality~=3 and quality~=4) then return nil end
    -- Verify exact item ID for known exceptions; no special-yield guessing.
    local itemID=ID(item) or ID(link)
    if not itemID or (blocked and blocked[itemID])
        or (special and special[itemID]) then return nil end
    if classID~=2 and classID~=4 then return nil end
    -- Craftable wands are not guaranteed valid material candidates.
    if classID==2 and subclassID==19 then return nil end
    -- Prefer Forever's exact/scaled effective ilvl when exposed. A missing
    -- API is not a reason to use the character's required level instead.
    local levelFn=(C_Item and C_Item.GetDetailedItemLevelInfo)
        or GetDetailedItemLevelInfo
    if type(levelFn)=="function" then
        local valid,level=pcall(levelFn,item)
        if valid and Public(level) and type(level)=="number"
            and level>=5 and level<=99 then ilvl=level end
    end
    -- Reject empty equipment slots, including non-equippable special items.
    if type(slot)~="string" or slot=="" or slot=="INVTYPE_BAG"
        or slot=="INVTYPE_BODY" or slot=="INVTYPE_TABARD" then
        return nil
    end
    local weapon=classID==2
    return {itemID=itemID,name=name,quality=quality,classID=classID,
        itemLevel=math.floor(ilvl),weapon=weapon,
        vendor=Public(vendor) and type(vendor)=="number"
            and vendor>=0 and vendor or nil}
end
-- Use the exact Forever item-quality/class/level brackets. The
-- accompanying yields are openly licensed VMaNGOS/CMaNGOS estimates,
-- NOT server-confirmed Forever odds. These tables are independent of
-- recipe reagent requirements in LibProfessionDB.
local function Outcomes(info)
    if not ref or type(ref.Find)~="function" then return nil end
    local row=ref.Find(info.classID,info.quality,info.itemLevel)
    if not row then return nil end
    local results={}
    local sum=0
    for i=3,#row do
        local outcome=row[i]
        if type(outcome)~="table" or type(outcome[1])~="number"
            or type(outcome[2])~="number" or type(outcome[3])~="number"
            or type(outcome[4])~="number" then return nil end
        local pct,min,max,id=unpack(outcome)
        if pct<=0 or min<=0 or max<min then return nil end
        sum=sum+pct
        results[#results+1]={id=id,min=min,max=max,chance=pct/100}
    end
    if #results==0 or math.abs(sum-100)>0.001 then return nil end
    return results,row.unconfirmed==true
end
local function ValidAsk(itemID)
    if type(ChalkBox_AuctionPrice)~="function" then return nil end
    local ok,price=pcall(ChalkBox_AuctionPrice,itemID)
    if ok and type(price)=="table" and price.stale~=true
        and price.mixed~=true and type(price.low)=="number"
        and price.low>0 and price.low==price.low then
        return price.low,price
    end
end
-- Public read-only result. nil means "not safely modeled", not zero value.
function ChalkBox_DisenchantEvaluate(item)
    if not enabled then return nil end
    local info=Metadata(item)
    if not info then return nil end
    local results,unconfirmed=Outcomes(info)
    if not results then return nil end
    local expected,priced,total=0,0,#results
    for _,entry in ipairs(results) do
        entry.name=ref and ref.names and ref.names[entry.id]
        entry.expected=entry.chance*(entry.min+entry.max)/2
        entry.ask=ValidAsk(entry.id)
        if entry.ask then
            entry.value=entry.expected*entry.ask
            expected=expected+entry.value
            priced=priced+1
        end
    end
    local itemAsk,itemPrice=ValidAsk(info.itemID or item)
    local complete=priced==total and not unconfirmed
    -- Unconfirmed client-only bracket rewards cannot produce an estimate,
    -- even with complete price coverage.
    local estimate=complete and math.floor(expected+0.5) or nil
    local better,delta
    if estimate and (itemAsk or info.vendor) then
        local alternative,source
        if itemAsk and (not info.vendor or itemAsk>info.vendor) then
            alternative,source=itemAsk,"AH ask"
        else
            alternative,source=info.vendor,"vendor"
        end
        delta=estimate-alternative
        if delta>math.max(1,alternative*0.10) then
            better="DE higher vs "..source
        elseif delta<(-math.max(1,alternative*0.10)) then
            better=source.." higher"
        else
            better="Close estimate"
        end
    end
    return {itemID=info.itemID,itemLevel=info.itemLevel,
        quality=info.quality,name=info.name,
        weapon=info.weapon,vendor=info.vendor,
        outcomes=results,priced=priced,total=total,
        complete=complete,unconfirmed=unconfirmed,estimated=estimate,
        itemAsk=itemAsk,itemPrice=itemPrice,
        verdict=better,difference=delta,
        model="Forever client bracket; Classic reference odds"}
end
local function AlreadyAnnotated(tooltip)
    local name=type(tooltip.GetName)=="function" and tooltip:GetName()
    if not name or type(tooltip.NumLines)~="function" then return false end
    for i=1,math.min(60,tooltip:NumLines()) do
        local line=_G[name.."TextLeft"..i]
        local message=line and type(line.GetText)=="function" and line:GetText()
        if type(message)=="string" and
            message:find("DE estimate  |",1,true) then return true end
    end
    return false
end
local function Metric(tip,label,value,role)
    if type(ChalkBox_TipMetric)=="function" then
        ChalkBox_TipMetric(tip,label,value,role)
    elseif type(tip.AddDoubleLine)=="function" then
        tip:AddDoubleLine(label,value,0.81,0.84,0.85,0.95,0.79,0.39)
    else
        tip:AddLine(label..": "..value,0.95,0.79,0.39)
    end
end
local function Color(role)
    if type(ChalkBox_TipColor)=="function" then
        return ChalkBox_TipColor(role)
    end
    if role=="good" then return 0.39,0.94,0.62 end
    return 0.78,0.82,0.85
end
local function AddLines(tip,model,shift,protected)
    if not model or type(tip.AddLine)~="function" then return false end
    local r,g,b=Color("info")
    tip:AddLine("DE estimate  |  Forever bracket (ilvl "..model.itemLevel..")",
        r,g,b)
    if model.unconfirmed then
        Metric(tip,"Material outcome","Unconfirmed for this bracket","warning")
    elseif model.complete then
        Metric(tip,"Materials · gross ask",Money(model.estimated),"value")
    else
        Metric(tip,"Material prices",
            model.priced.."/"..model.total.." · scan missing materials","warning")
    end
    if not protected and model.verdict then
        local role=model.difference and model.difference>0 and
            "good" or "warning"
        Metric(tip,"Compared with item",
            model.verdict..(model.itemAsk and " (if tradable)" or ""),
            role)
    end
    if shift then
        for _,entry in ipairs(model.outcomes) do
            local title=(model.unconfirmed and "? " or
                (("%d%% "):format(math.floor(entry.chance*100+0.5))))..
                (" %d-%dx %s"):format(entry.min,entry.max,
                    entry.name or ("#"..entry.id))
            Metric(tip,title,entry.ask and Money(entry.ask).."/unit" or "No price",
                entry.ask and "count" or "muted")
        end
        local cr,cg,cb=Color("muted")
        tip:AddLine("Expected averages · asking prices, not sales",cr,cg,cb)
        tip:AddLine("Forever bracket · Classic odds · no automatic DE",cr,cg,cb)
    end
    return true
end
function ChalkBox_DisenchantTooltip(tooltip,item,protected)
    if not enabled or not tooltip or AlreadyAnnotated(tooltip) then return false end
    local model=ChalkBox_DisenchantEvaluate(item)
    if not model then return false end
    local shift=type(IsShiftKeyDown)=="function" and IsShiftKeyDown()
    local ok=AddLines(tooltip,model,shift,protected==true)
    if ok and type(tooltip.Show)=="function" then tooltip:Show() end
    return ok
end
function ChalkBox_DisenchantMarketHint(tooltip,item)
    local model=ChalkBox_DisenchantEvaluate(item)
    if not model or type(tooltip.AddLine)~="function" then return false end
    local label=model.unconfirmed and "DE outcomes unconfirmed" or
        (model.complete and ("DE model ~"..Money(model.estimated).." in materials")
            or ("DE prices missing ("..model.priced.."/"..model.total..")"))
    local r,g,b=Color(model.complete and "value" or "muted")
    tooltip:AddLine(label,r,g,b)
    if model.verdict then
        local dr,dg,db=Color(model.difference and model.difference>0 and
            "good" or "warning")
        tooltip:AddLine(model.verdict.." · if tradable",dr,dg,db)
    end
    return true
end
function ChalkBox_DisenchantSetTooltips(on)
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    ChalkBoxDB.disenchantInfo=on==true
    enabled=ChalkBoxDB.disenchantInfo
    return enabled
end
function ChalkBox_DisenchantTooltipsEnabled()
    return enabled
end
function ChalkBox_DisenchantCommand(command)
    local input=(command or ""):match("^%s*(.-)%s*$")
    local word=input:lower()
    if word=="on" or word=="off" then
        ChalkBox_DisenchantSetTooltips(word=="on")
        if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(
            "ChalkBox DE tooltips "..(enabled and "ON" or "OFF")) end
        return
    end
    local model=ChalkBox_DisenchantEvaluate(input)
    local function Say(msg)
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
            DEFAULT_CHAT_FRAME:AddMessage("|cff55ccaaChalkBox DE|r "..msg)
        end
    end
    if not model then
        Say("Shift-click a green/blue weapon or armor link: /chalk de [item].")
        return
    end
    Say((model.name or "Item").." (ilvl "..model.itemLevel..")  |  "..
        (model.unconfirmed and "DE outcome unconfirmed" or
          (model.complete and "DE est "..Money(model.estimated) or
            ("DE missing prices "..model.priced.."/"..model.total)))..
        "  |  AH ask "..Money(model.itemAsk))
    for _,entry in ipairs(model.outcomes) do
        Say(("%d%%: %d-%dx %s (%s/unit)"):format(
            math.floor(entry.chance*100+0.5),entry.min,entry.max,
            entry.name or ("Item #"..entry.id),Money(entry.ask)))
    end
    Say("Forever client bracket · Classic reference odds · asks, not sales.")
end
local loader=CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent",function(_,event,name)
    if name~=addonName then return end
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    if ChalkBoxDB.disenchantInfo==nil then
        ChalkBoxDB.disenchantInfo=true
    end
    enabled=ChalkBoxDB.disenchantInfo~=false
    if type(loader.UnregisterEvent)=="function" then
        loader:UnregisterEvent("ADDON_LOADED")
    end
end)
