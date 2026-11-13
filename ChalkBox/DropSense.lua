-- ChalkBox DropSense: entirely local, explicitly opt-in sampling.
-- Counts *opened readable loot windows*, not kills, independent loot rolls or
-- verified Forever server drop chances. Never claims a true server rate.
local addonName=...
local MAX_WATCH=32
local function Public(v)
    return v~=nil and (type(issecretvalue)~="function" or not issecretvalue(v))
end
local function Numeric(v)
    return Public(v) and type(v)=="number" and v==v and v>=0 and v<1e9
end
local function State()
    if type(ChalkBoxZoneDB)~="table" then ChalkBoxZoneDB={} end
    local s=ChalkBoxZoneDB.dropSense
    if type(s)~="table" or s.version~=1 then
        s={version=1,enabled=false,tooltip=true,items={},
            windows=0,observedItems=0}
        ChalkBoxZoneDB.dropSense=s
    end
    if type(s.items)~="table" then s.items={} end
    if s.tooltip==nil then s.tooltip=true end
    return s
end
local function ID(link)
    if type(link)=="number" and Numeric(link) and link>=1 then
        return tostring(math.floor(link))
    end
    if not Public(link) or type(link)~="string" then return end
    return link:match("item:(%d+)") or link:match("^%s*(%d+)%s*$")
end
local function Note(msg)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff67c6b7ChalkBox Drops|r "..msg)
    end
end
function ChalkBox_DropOptions()
    local s=State()
    local total=0
    for _ in pairs(s.items) do total=total+1 end
    return {enabled=s.enabled==true,tooltip=s.tooltip~=false,
        watched=total,windows=s.windows or 0,items=s.observedItems or 0}
end
function ChalkBox_DropSetOption(key,on)
    if key~="enabled" and key~="tooltip" then return false end
    State()[key]=on==true
    return true
end
function ChalkBox_DropWatch(item,name)
    local id=ID(item)
    if not id then return false,"Provide an item link or numeric item ID" end
    local s=State()
    if s.items[id] then return true,"Already watching item #"..id end
    local total=0
    for _ in pairs(s.items) do total=total+1 end
    if total>=MAX_WATCH then return false,"Maximum 32 watched items" end
    s.items[id]={id=id,name=type(name)=="string" and name:sub(1,64)
        or ("Item #"..id),windows=0,hits=0,quantity=0}
    return true,"Now watching "..s.items[id].name
end
function ChalkBox_DropUnwatch(item)
    local id=ID(item)
    if not id or not State().items[id] then return false end
    State().items[id]=nil
    return true
end
function ChalkBox_DropReference(item,rate)
    local id=ID(item)
    local entry=id and State().items[id]
    if not entry then return false end
    if rate==nil then entry.reference=nil;return true end
    local num=tonumber(rate)
    if not Numeric(num) or num>100 then return false end
    entry.reference=num
    return true
end
function ChalkBox_DropCalculate(rate,attempts)
    rate=tonumber(rate);attempts=tonumber(attempts)
    if not Numeric(rate) or rate>100 or not Numeric(attempts) or
        attempts>100000 or attempts%1~=0 then return end
    return 100*(1-math.pow(1-rate/100,attempts))
end
function ChalkBox_DropRead(item)
    local id=ID(item)
    local v=id and State().items[id]
    if type(v)~="table" then return end
    local n=Numeric(v.windows) and v.windows or 0
    local hits=Numeric(v.hits) and math.min(v.hits,n) or 0
    local p=n>0 and hits/n or 0
    -- 95% Wilson interval: conservative at low sample size. It is a
    -- confidence interval for *observed loot windows*, not server loot odds.
    local z=1.96
    local d=1+z*z/math.max(1,n)
    local center=(p+z*z/(2*math.max(1,n)))/d
    local half=z*math.sqrt(p*(1-p)/math.max(1,n)+
        z*z/(4*math.max(1,n)^2))/d
    return {id=id,name=v.name,windows=n,hits=hits,
        quantity=v.quantity or 0,rate=n>0 and 100*p or nil,
        low=n>0 and 100*math.max(0,center-half) or nil,
        high=n>0 and 100*math.min(1,center+half) or nil,
        reference=v.reference}
end
function ChalkBox_DropTooltip(tooltip,link)
    local s=State()
    if not s.enabled or s.tooltip==false or not tooltip or
        type(tooltip.AddLine)~="function" then return false end
    -- Only annotate native loot-window item tooltips. Never claim a rate
    -- when browsing bank, bags, auction, merchant or general item tooltips.
    local owner=type(tooltip.GetOwner)=="function" and tooltip:GetOwner()
    local frameName=owner and type(owner.GetName)=="function" and owner:GetName()
    if type(frameName)~="string" or
        not frameName:match("^LootButton") then return false end
    local data=ChalkBox_DropRead(link)
    if not data then return false end
    if type(tooltip.GetName)=="function" and
        type(tooltip.NumLines)=="function" then
        local name=tooltip:GetName()
        if type(name)=="string" then
            for i=1,tooltip:NumLines() do
                local row=_G[name.."TextLeft"..i]
                if row and row.GetText and
                    row:GetText()=="CHALKBOX | DROP JOURNAL" then
                    return false
                end
            end
        end
    end
    tooltip:AddLine("CHALKBOX | DROP JOURNAL",0.86,0.66,0.38)
    if data.windows==0 then
        tooltip:AddLine("Watching; no readable loot windows recorded yet.",
            0.72,0.76,0.79,true)
    else
        tooltip:AddLine(("%d / %d opened loot windows (%.1f%%)"):format(
            data.hits,data.windows,data.rate),0.42,0.82,0.72,true)
        tooltip:AddLine(("Observed window range: %.1f%%–%.1f%% (95%% interval)"):format(
            data.low,data.high),0.72,0.76,0.79,true)
    end
    if data.reference then
        tooltip:AddLine(("Your reference: %.2f%% (user-provided, not verified)"):format(
            data.reference),0.90,0.74,0.42,true)
    end
    tooltip:AddLine("Your sampled loot windows; NOT an official drop chance.",
        0.72,0.76,0.79,true)
    if type(tooltip.Show)=="function" then tooltip:Show() end
    return true
end
local captured=false
local lastSignature,lastTime=nil,-1e9
local function Capture()
    if not State().enabled or captured or
        type(GetNumLootItems)~="function" or
        type(GetLootSlotLink)~="function" then return end
    local ok,count=pcall(GetNumLootItems)
    if not ok or not Numeric(count) or count<1 or count>60 or
        count%1~=0 then return end
    local items={}
    local total=0
    local sourceGUID
    for slot=1,count do
        local slotOK,link=pcall(GetLootSlotLink,slot)
        if not slotOK or (type(issecretvalue)=="function" and
            issecretvalue(link)) then return end
        if link~=nil then
            local id=ID(link)
            if id then
                local qty=1
                if type(GetLootSlotInfo)=="function" then
                    local infoOK,_,_,quantity=pcall(GetLootSlotInfo,slot)
                    if infoOK and Numeric(quantity) and quantity>=1
                        and quantity<=100000 then qty=math.floor(quantity) end
                end
                items[id]=(items[id] or 0)+qty
                total=total+qty
                -- The source GUID is an optional dedup aid, not a claim
                -- that all windows correspond to one identical creature.
                if not sourceGUID and type(GetLootSourceInfo)=="function" then
                    local sourceOK,guid=pcall(GetLootSourceInfo,slot)
                    if sourceOK and Public(guid) and type(guid)=="string"
                        and #guid<=100 then sourceGUID=guid end
                end
            end
        end
    end
    captured=true
    local now=type(GetTime)=="function" and GetTime() or nil
    local signature=sourceGUID and ("source:"..sourceGUID) or nil
    if signature and Numeric(now) and
        signature==lastSignature and now-lastTime<120 then return end
    lastSignature=signature
    if Numeric(now) then lastTime=now end
    local s=State()
    s.windows=(s.windows or 0)+1
    s.observedItems=(s.observedItems or 0)+total
    for id,entry in pairs(s.items) do
        if type(entry)=="table" then
            entry.windows=math.min(1e8,(entry.windows or 0)+1)
            if items[id] then
                entry.hits=math.min(1e8,(entry.hits or 0)+1)
                entry.quantity=math.min(1e8,(entry.quantity or 0)+items[id])
            end
        end
    end
    if type(ChalkBox_JournalNoteLoot)=="function" then
        pcall(ChalkBox_JournalNoteLoot,total,items)
    end
end
function ChalkBox_DropCommand(input)
    local command,args=(input or ""):match("^%s*(%S*)%s*(.-)%s*$")
    command=string.lower(command or "")
    if command=="on" or command=="off" then
        ChalkBox_DropSetOption("enabled",command=="on")
        Note("Personal loot-window sampling "..command..".")
    elseif command=="tooltip" and (args=="on" or args=="off") then
        ChalkBox_DropSetOption("tooltip",args=="on")
        Note("Loot window tooltips "..args..".")
    elseif command=="watch" then
        local id=ID(args)
        local name=args:match("%[([^%]]+)%]")
        local ok,msg=ChalkBox_DropWatch(id,name)
        Note(msg or (ok and "Watching" or "Invalid item"))
    elseif command=="unwatch" then
        Note(ChalkBox_DropUnwatch(args) and "Removed watch." or "Unknown watch.")
    elseif command=="reference" then
        local id,rate=args:match("^(%d+)%s+([%d%.]+)$")
        Note(ChalkBox_DropReference(id,rate) and
            "Saved your manually provided reference." or
            "Watch the item first; usage: /chalk drops reference <itemID> <percent>")
    elseif command=="chance" then
        local rate,attempts=args:match("^([%d%.]+)%s+(%d+)$")
        local chance=ChalkBox_DropCalculate(rate,attempts)
        Note(chance and ("At "..rate.."% per independent attempt, the chance of "..
            "at least one drop in "..attempts.." attempts is "..
            ("%.2f"):format(chance).."% (mathematical model).") or
            "Usage: /chalk drops chance <percent> <attempts>")
    elseif command=="status" or command=="" then
        local opt=ChalkBox_DropOptions()
        Note((opt.enabled and "ON" or "OFF")..
            ": "..opt.watched.." watched item(s), "..
            opt.windows.." recorded loot windows. No verified server rates.")
        local shown=0
        for id,entry in pairs(State().items) do
            if shown<8 then
                local d=ChalkBox_DropRead(id)
                Note((entry.name or ("Item #"..id))..": "..d.hits.."/"..d.windows..
                    " windows"..(d.rate and (" ("..("%.1f"):format(d.rate).."%)") or ""))
                shown=shown+1
            end
        end
    else
        Note("/chalk drops on|off | watch [item] | unwatch <itemID> | status")
        Note("/chalk drops reference <itemID> <percent> | chance <percent> <attempts>")
    end
end
local frame=CreateFrame("Frame")
for _,event in ipairs({"LOOT_READY","LOOT_OPENED","LOOT_CLOSED"}) do
    frame:RegisterEvent(event)
end
frame:SetScript("OnEvent",function(_,event)
    if event=="LOOT_CLOSED" then captured=false
    else Capture() end
end)
