-- ChalkBox Bank Value (LootSense / Trail Bar)
-- Read-only, per-character snapshot of the character's bank.
-- Vendor sell prices are primary. AuctionSense asking prices are secondary
-- and omitted when stale, mixed-variant or unavailable.
-- Does not read another character's bank, the warband bank, guild bank,
-- ordinary carried bags, or any unobserved remote bank data.
local open=false
local panel,primary,market,note
local pending=0
local elapsed=0
local lastMark=0

local function Public(v)
    if type(issecretvalue)=="function" and issecretvalue(v) then return false end
    return v~=nil
end
local function Numeric(v)
    return Public(v) and type(v)=="number" and v==v and v>=0 and
        v<1e12 and v~=math.huge
end
local function Integer(v)
    return Numeric(v) and v%1==0
end
local function Read(fn,...)
    if type(fn)~="function" then return nil end
    local ok,a,b,c,d=pcall(fn,...)
    if ok and Public(a) then return a,b,c,d end
end
local function Stamp()
    local now=Read(GetServerTime)
    if not Integer(now) then now=Read(time) end
    return Integer(now) and now or nil
end
local function Saved()
    if type(ChalkBoxZoneDB)~="table" then return nil end
    local db=ChalkBoxZoneDB.bankValue
    if db==nil then
        db={version=1}
        ChalkBoxZoneDB.bankValue=db
    end
    if type(db)~="table" or db.version~=1 then return nil end
    return db
end
local function Coin(n)
    if not Numeric(n) then return "--" end
    n=math.floor(n)
    local g=math.floor(n/10000)
    local s=math.floor(n%10000/100)
    local c=n%100
    if g>0 then return ("%dg %02ds"):format(g,s) end
    if s>0 then return ("%ds %02dc"):format(s,c) end
    return c.."c"
end
local function Age(at)
    local now=Stamp()
    if not Integer(now) or not Integer(at) or now<at then
        return "last bank visit"
    end
    local seconds=now-at
    if seconds<60 then return "just seen" end
    if seconds<3600 then return math.floor(seconds/60).."m ago" end
    if seconds<86400 then return math.floor(seconds/3600).."h ago" end
    return math.floor(seconds/86400).."d ago"
end
-- Never guess bank tab IDs from a numeric range: Forever and other WoW
-- generations use overlapping bank / account-bank enum values.
local function CharacterContainers()
    local ids,seen={},{}
    local indexes=Enum and Enum.BagIndex
    if type(indexes)=="table" then
        for i=1,12 do
            local id=indexes["CharacterBankTab_"..i]
            if Integer(id) and not seen[id] then
                seen[id]=true;ids[#ids+1]=id
            end
        end
    end
    if #ids>0 then return ids,"tabs" end
    -- Only a legacy Classic bank uses these special container constants.
    -- A modern client with no exposed character-tab enum is unsupported;
    -- do not accidentally scan account bank tabs by index.
    if Public(BANK_CONTAINER) and type(BANK_CONTAINER)=="number" and
        BANK_CONTAINER<0 and type(GetContainerNumSlots)=="function" then
        ids[1]=BANK_CONTAINER
        local base=type(NUM_BAG_SLOTS)=="number" and NUM_BAG_SLOTS or 4
        local bank=type(NUM_BANKBAGSLOTS)=="number" and
            NUM_BANKBAGSLOTS or 0
        if bank>0 and bank<=7 then
            for i=1,bank do ids[#ids+1]=base+i end
        end
        return ids,"legacy"
    end
    return nil,nil
end
local function BankVisible()
    local bank=BankFrame or BankPanel
    if bank and type(bank.IsShown)=="function" then
        local shown=Read(bank.IsShown,bank)
        return shown==true
    end
    return open
end
local function Snapshot()
    if not open or not BankVisible() then return nil end
    local containers,kind=CharacterContainers()
    if not containers or #containers==0 then return nil end
    local api=C_Container
    local countFn=api and api.GetContainerNumSlots or GetContainerNumSlots
    local infoFn=api and api.GetContainerItemInfo or GetContainerItemInfo
    local idFn=api and api.GetContainerItemID or GetContainerItemID
    local itemFn=(C_Item and C_Item.GetItemInfo) or GetItemInfo
    if type(countFn)~="function" or type(infoFn)~="function" or
        type(itemFn)~="function" then return nil end
    local snapshot={vendorCopper=0,vendorUnknown=0,
        ahCopper=0,ahUnknown=0,ahPriced=0,
        stacks=0,units=0,containers=0,kind=kind}
    local any=false
    for _,containerID in ipairs(containers) do
        local count=Read(countFn,containerID)
        if Integer(count) and count>0 and count<=120 then
            any=true
            snapshot.containers=snapshot.containers+1
            for slot=1,count do
                local ok,raw,qOld,_,_,_,_,linkOld,_,noValueOld,idOld=
                    pcall(infoFn,containerID,slot)
                if not ok or (raw~=nil and not Public(raw)) then
                    snapshot.vendorUnknown=snapshot.vendorUnknown+1
                    snapshot.ahUnknown=snapshot.ahUnknown+1
                elseif raw~=nil then
                    local quantity,link,id,noValue
                    if type(raw)=="table" then
                        local fieldsOK
                        fieldsOK,quantity,link,id,noValue=pcall(function()
                            return raw.stackCount,raw.hyperlink,raw.itemID,
                                raw.hasNoValue
                        end)
                        if not fieldsOK then quantity=nil end
                    else
                        quantity,link,id,noValue=qOld,linkOld,idOld,noValueOld
                    end
                    if not Integer(quantity) or quantity<=0 or
                        quantity>100000 then
                        snapshot.vendorUnknown=snapshot.vendorUnknown+1
                        snapshot.ahUnknown=snapshot.ahUnknown+1
                    else
                        if not Public(link) or
                            type(link)~="string" then link=nil end
                        if not Integer(id) and type(idFn)=="function" then
                            id=Read(idFn,containerID,slot)
                        end
                        local identity=link or (Integer(id) and id or nil)
                        snapshot.stacks=snapshot.stacks+1
                        snapshot.units=snapshot.units+quantity
                        local sell
                        if noValue==true then
                            sell=0
                        elseif identity then
                            local cached,price=pcall(function()
                                local _,_,_,_,_,_,_,_,_,_,sell=itemFn(identity)
                                return sell
                            end)
                            if cached and Numeric(price) and price<=1e9 then
                                sell=price
                            end
                        end
                        if Numeric(sell) and
                            snapshot.vendorCopper+sell*quantity<1e12 then
                            snapshot.vendorCopper=
                                snapshot.vendorCopper+sell*quantity
                        else
                            snapshot.vendorUnknown=snapshot.vendorUnknown+1
                        end
                        local estimate
                        if identity and
                            type(ChalkBox_AuctionPrice)=="function" then
                            local okPrice,p=pcall(ChalkBox_AuctionPrice,identity)
                            if okPrice and type(p)=="table" and not p.stale and
                                not p.mixed and Numeric(p.low) and p.low>0 then
                                estimate=p.low
                            end
                        end
                        if Numeric(estimate) and
                            snapshot.ahCopper+estimate*quantity<1e12 then
                            snapshot.ahCopper=snapshot.ahCopper+
                                estimate*quantity
                            snapshot.ahPriced=snapshot.ahPriced+1
                        else
                            snapshot.ahUnknown=snapshot.ahUnknown+1
                        end
                    end
                elseif type(idFn)=="function" then
                    local id=Read(idFn,containerID,slot)
                    if Public(id) then
                        snapshot.vendorUnknown=snapshot.vendorUnknown+1
                        snapshot.ahUnknown=snapshot.ahUnknown+1
                    end
                end
            end
        end
    end
    -- Fail closed. Bank tabs with zero currently accessible slots are
    -- unpurchased or not yet loaded; never replace a valid saved value with
    -- an imagined empty bank.
    if not any then return nil end
    snapshot.vendorComplete=snapshot.vendorUnknown==0
    snapshot.ahComplete=snapshot.ahUnknown==0
    snapshot.at=Stamp() or 0
    return snapshot
end
local function Current()
    local db=Saved()
    return db and type(db.snapshot)=="table" and
        db.snapshot.version==1 and db.snapshot or nil
end
function ChalkBox_BankValueStatus()
    local v=Current()
    if not v then return nil end
    local result={}
    for _,key in ipairs({"vendorCopper","vendorUnknown","vendorComplete",
        "ahCopper","ahUnknown","ahComplete","ahPriced","stacks","units",
        "containers","at","kind"}) do
        result[key]=v[key]
    end
    result.open=open and BankVisible()
    result.age=Age(v.at)
    return result
end
local function Paint()
    if not panel then return end
    local v=ChalkBox_BankValueStatus()
    if not v then
        primary:SetText("Vendor value: collecting...")
        market:SetText("Auction estimates: unavailable")
        note:SetText("Character bank only")
        return
    end
    primary:SetText("Vendor value: "..
        (v.vendorComplete and "" or "at least ")..Coin(v.vendorCopper))
    market:SetText("Auction asks: "..
        (v.ahPriced>0 and ((v.ahComplete and "" or "at least ")..
            Coin(v.ahCopper)) or "no usable prices"))
    note:SetText(("%d stacks · AH %d priced · %s"):format(
        v.stacks or 0,v.ahPriced or 0,
        v.vendorUnknown>0 and (v.vendorUnknown.." vendor unknown") or
            "vendor complete"))
end
local function EnsurePanel()
    if panel then return end
    local bank=BankFrame or BankPanel
    if not bank or type(bank.CreateFontString)~="function" then return end
    panel=CreateFrame("Frame","ChalkBoxBankValuePanel",bank)
    panel:SetSize(258,67)
    panel:SetPoint("TOPRIGHT",bank,"TOPRIGHT",-28,-43)
    if type(bank.GetFrameLevel)=="function" and
        type(panel.SetFrameLevel)=="function" then
        panel:SetFrameLevel(bank:GetFrameLevel()+15)
    end
    local bg=panel:CreateTexture(nil,"BACKGROUND")
    bg:SetAllPoints(panel)
    if type(bg.SetColorTexture)=="function" then
        bg:SetColorTexture(.035,.041,.05,.92)
    else
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        if bg.SetVertexColor then bg:SetVertexColor(.035,.041,.05,.92) end
    end
    local function Label(template,y,r,g,b)
        local font=panel:CreateFontString(nil,"OVERLAY",template)
        font:SetPoint("TOPLEFT",panel,"TOPLEFT",9,y)
        font:SetWidth(242)
        font:SetJustifyH("LEFT")
        font:SetTextColor(r,g,b)
        return font
    end
    primary=Label("GameFontNormal",-7,.94,.84,.58)
    market=Label("GameFontHighlightSmall",-29,.59,.86,.79)
    note=Label("GameFontHighlightSmall",-49,.71,.73,.73)
    panel:SetScript("OnEnter",function(self)
        if GameTooltip and type(GameTooltip.SetOwner)=="function" then
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:AddLine("ChalkBox · Character Bank",1,.82,.4)
            local v=ChalkBox_BankValueStatus()
            if v then
                GameTooltip:AddLine("Vendor value: "..
                    (v.vendorComplete and "" or "at least ")..
                    Coin(v.vendorCopper),1,1,1)
                GameTooltip:AddLine("Auction asking prices: "..
                    (v.ahPriced>0 and Coin(v.ahCopper) or "unavailable"),
                    .65,.84,.9)
                GameTooltip:AddLine(("%d/%d stacks with comparable AH prices"):format(
                    v.ahPriced or 0,v.stacks or 0),.68,.71,.77)
                GameTooltip:AddLine("AH figures are last scanned asking prices, not sales.",
                    .65,.69,.73,true)
            end
            GameTooltip:Show()
        end
    end)
    panel:SetScript("OnLeave",function()
        if GameTooltip then GameTooltip:Hide() end
    end)
end
local function Refresh()
    if not open or not BankVisible() then
        if panel then panel:Hide() end
        return
    end
    EnsurePanel()
    local snapshot=Snapshot()
    if snapshot then
        local db=Saved()
        if db then snapshot.version=1;db.snapshot=snapshot end
    end
    if panel then panel:Show();Paint() end
    if type(ChalkBox_BarBankValueRefresh)=="function" then
        ChalkBox_BarBankValueRefresh()
    end
end
local listener=CreateFrame("Frame")
for _,event in ipairs({"BANKFRAME_OPENED","BANKFRAME_CLOSED",
    "PLAYERBANKSLOTS_CHANGED","PLAYERBANKBAGSLOTS_CHANGED",
    "BAG_UPDATE_DELAYED","GET_ITEM_INFO_RECEIVED","ITEM_DATA_LOAD_RESULT",
    "BANK_TAB_SETTINGS_UPDATED"}) do listener:RegisterEvent(event) end
listener:SetScript("OnEvent",function(_,event)
    if event=="BANKFRAME_CLOSED" then
        open=false
        pending=0
        if panel then panel:Hide() end
    elseif event=="BANKFRAME_OPENED" then
        open=true
        pending=5
        elapsed=0
        Refresh()
    elseif open then
        pending=2
        elapsed=0
    end
end)
listener:SetScript("OnUpdate",function(_,dt)
    if not open then return end
    elapsed=elapsed+(type(dt)=="number" and dt or 0)
    if elapsed<.7 then return end
    elapsed=0
    if pending>0 then
        pending=pending-1
        Refresh()
    end
end)
