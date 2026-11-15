-- Disenchant economics: deterministic, read-only, Classic-based yields.
-- Data model (not a spell or bag hook). Forever may have custom exceptions.
-- Material prices come ONLY from AuctionSense's same-realm/faction snapshot.
-- Green/blue weapons and armor, item levels 5-65. No item actions.
local addonName=...
local enabled=true
local function Public(v)
    return v~=nil and (type(issecretvalue)~="function" or not issecretvalue(v))
end
local materials={
    [10940]="Strange Dust", [10938]="Lesser Magic Essence",
    [10939]="Greater Magic Essence", [10978]="Small Glimmering Shard",
    [10998]="Lesser Astral Essence", [11083]="Soul Dust",
    [11082]="Greater Astral Essence", [11084]="Large Glimmering Shard",
    [11134]="Lesser Mystic Essence", [11138]="Small Glowing Shard",
    [11137]="Vision Dust", [11135]="Greater Mystic Essence",
    [11139]="Large Glowing Shard", [11174]="Lesser Nether Essence",
    [11177]="Small Radiant Shard", [11176]="Dream Dust",
    [11175]="Greater Nether Essence", [11178]="Large Radiant Shard",
    [16202]="Lesser Eternal Essence", [14343]="Small Brilliant Shard",
    [16204]="Illusion Dust", [16203]="Greater Eternal Essence",
    [14344]="Large Brilliant Shard", [20725]="Nexus Crystal",
}
-- Highest item level, dust ID/quantity, essence ID/quantity, shard ID.
-- These are Classic yield bands: do not substitute required-character level.
local bands={
    {15,10940,1,2,10938,1,2,nil},
    {20,10940,2,3,10939,1,2,10978},
    {25,10940,4,6,10998,1,2,10978},
    {30,11083,1,2,11082,1,2,11084},
    {35,11083,2,5,11134,1,2,11138},
    {40,11137,1,2,11135,1,2,11139},
    {45,11137,2,5,11174,1,2,11177},
    {50,11176,1,2,11175,1,2,11178},
    {55,11176,2,5,16202,1,2,14343},
    {60,16204,1,2,16203,1,2,14344},
    {65,16204,2,5,16203,2,3,14344},
}
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
        or type(ilvl)~="number" or ilvl<5 or ilvl>65
        or (quality~=2 and quality~=3) then return nil end
    -- Only equipment. Some enchanted wands cannot be disenchanted.
    -- Shields and off-hands use weapon-like Classic disenchant odds.
    if classID~=2 and classID~=4 then return nil end
    if classID==2 and subclassID==19 then return nil end
    -- Reject empty equipment slots, including non-equippable special items.
    -- Some items with classID=4 cannot be disenchanted in Forever.
    if type(slot)~="string" or slot=="" or slot=="INVTYPE_BAG"
        or slot=="INVTYPE_BODY" or slot=="INVTYPE_TABARD" then
        return nil
    end
    local weapon=classID==2 or slot=="INVTYPE_SHIELD"
        or slot=="INVTYPE_HOLDABLE"
    return {itemID=ID(item),name=name,quality=quality,
        itemLevel=math.floor(ilvl),weapon=weapon,
        vendor=Public(vendor) and type(vendor)=="number"
            and vendor>=0 and vendor or nil}
end
local function Outcomes(info)
    local level=info.itemLevel
    local tier
    for i=1,#bands do
        if level<=bands[i][1] then tier=bands[i];break end
    end
    if not tier then return nil end
    if info.quality==3 then
        -- Classic blues normally yield one shard. Very high Classic blues
        -- can rarely yield a crystal instead; count both price possibilities.
        local shard
        if level<=25 then shard=10978
        else shard=tier[8] end
        if not shard then return nil end
        if level>=56 then
            return {{id=shard,min=1,max=1,chance=0.995},
                {id=20725,min=1,max=1,chance=0.005}}
        end
        return {{id=shard,min=1,max=1,chance=1}}
    end
    -- The very lowest weapon levels are a special/uncertain band.
    if info.weapon and level<10 then return nil end
    local dustChance,essChance,shardChance
    if not tier[8] then
        dustChance=info.weapon and 0.20 or 0.80
        essChance=1-dustChance
        shardChance=0
    elseif level<=25 then
        dustChance=info.weapon and (level<=20 and 0.20 or 0.15) or 0.75
        essChance=info.weapon and 0.75 or (level<=20 and 0.20 or 0.15)
        shardChance=level<=20 and 0.05 or 0.10
    elseif info.weapon and level>=51 then
        dustChance,essChance,shardChance=0.22,0.75,0.03
    else
        dustChance=info.weapon and 0.20 or 0.75
        essChance=info.weapon and 0.75 or 0.20
        shardChance=0.05
    end
    local results={
        {id=tier[2],min=tier[3],max=tier[4],chance=dustChance},
        {id=tier[5],min=tier[6],max=tier[7],chance=essChance},
    }
    if tier[8] and shardChance>0 then
        results[#results+1]={id=tier[8],min=1,max=1,chance=shardChance}
    end
    return results
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
    local results=Outcomes(info)
    if not results then return nil end
    local expected,priced,total=0,0,#results
    for _,entry in ipairs(results) do
        entry.name=materials[entry.id]
        entry.expected=entry.chance*(entry.min+entry.max)/2
        entry.ask=ValidAsk(entry.id)
        if entry.ask then
            entry.value=entry.expected*entry.ask
            expected=expected+entry.value
            priced=priced+1
        end
    end
    local itemAsk,itemPrice=ValidAsk(info.itemID or item)
    local complete=priced==total
    -- Partial pricing never becomes a fake total or a recommendation.
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
        complete=complete,estimated=estimate,
        itemAsk=itemAsk,itemPrice=itemPrice,
        verdict=better,difference=delta,
        model="Classic baseline; Forever outcomes may differ"}
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
    tip:AddLine("DE estimate  |  Classic model (ilvl "..model.itemLevel..")",
        r,g,b)
    if model.complete then
        Metric(tip,"Materials · gross ask",Money(model.estimated),"value")
    else
        Metric(tip,"Material prices",
            model.priced.."/"..model.total.." · scan missing reagents","warning")
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
            local title=("%d%%  %d-%dx %s"):format(
                math.floor(entry.chance*100+0.5),
                entry.min,entry.max,entry.name or ("#"..entry.id))
            Metric(tip,title,entry.ask and Money(entry.ask).."/unit" or "No price",
                entry.ask and "count" or "muted")
        end
        local cr,cg,cb=Color("muted")
        tip:AddLine("Expected averages · asking prices, not sales",cr,cg,cb)
        tip:AddLine("Forever odds may differ · no automatic DE",cr,cg,cb)
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
    local label=model.complete and
        ("DE model ~"..Money(model.estimated).." in materials") or
        ("DE prices missing ("..model.priced.."/"..model.total..")")
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
        (model.complete and "DE est "..Money(model.estimated) or
            ("DE missing prices "..model.priced.."/"..model.total))..
        "  |  AH ask "..Money(model.itemAsk))
    for _,entry in ipairs(model.outcomes) do
        Say(("%d%%: %d-%dx %s (%s/unit)"):format(
            math.floor(entry.chance*100+0.5),entry.min,entry.max,
            entry.name or ("Item #"..entry.id),Money(entry.ask)))
    end
    Say("Classic baseline · Forever odds may differ · asks, not sales.")
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
