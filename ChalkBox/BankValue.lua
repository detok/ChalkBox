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
local lastReason="Bank has not opened yet"
local lastTabSource="none"
local lastTabCount=0
local lastReadable=0
local lastMissing=0
local lastBankParent="none"
local panelParent=nil

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
    -- This Forever API is stronger evidence than the enum: only PURCHASED
    -- bank tabs of Enum.BankType.Character (0), never account/guild tabs.
    local bank=C_Bank
    local fn=type(bank)=="table" and bank.FetchPurchasedBankTabIDs
    local bankType=type(Enum)=="table" and
        type(Enum.BankType)=="table" and Enum.BankType.Character or 0
    if type(fn)=="function" then
        local result=Read(fn,bankType)
        if type(result)=="table" then
            for _,id in ipairs(result) do
                if Integer(id) and id>0 and id<=100 and not seen[id] then
                    seen[id]=true;ids[#ids+1]=id
                end
            end
            lastTabSource="C_Bank purchased character tabs"
            lastTabCount=#ids
            if #ids>0 then return ids,"purchased" end
            -- Some client builds return an empty list on bank open before
            -- receiving purchased-tab data. Continue with explicit enum
            -- names, then require actual readable slots before saving.
        end
    end
    -- Some Forever patches expose only the CharacterBankTab_N enum, and
    -- older patches use the explicit Bank/BankBag_N entries instead.
    local indexes=type(Enum)=="table" and Enum.BagIndex or nil
    if type(indexes)=="table" then
        for i=1,12 do
            local id=indexes["CharacterBankTab_"..i]
            if Integer(id) and id>0 and id<=100 and not seen[id] then
                seen[id]=true;ids[#ids+1]=id
            end
        end
        if #ids>0 then
            lastTabSource="Enum.CharacterBankTab"
            lastTabCount=#ids
            return ids,"tabs"
        end
        local first=indexes.Bank
        if type(first)=="number" and first<0 then
            ids[#ids+1]=first
            for i=1,9 do
                local id=indexes["BankBag_"..i]
                if Integer(id) and id>0 and not seen[id] then
                    seen[id]=true;ids[#ids+1]=id
                end
            end
            lastTabSource="Enum.Bank / BankBag"
            lastTabCount=#ids
            return ids,"legacy"
        end
    end
    -- Strict legacy fallback: BANK_CONTAINER must be explicitly named
    -- by the client, not inferred from 6-14 (which overlap account tabs).
    local legacy=Public(BANK_CONTAINER) and BANK_CONTAINER or nil
    if type(legacy)=="number" and legacy<0 then
        ids[1]=legacy
        local base=type(NUM_BAG_SLOTS)=="number" and NUM_BAG_SLOTS or 4
        local total=type(NUM_BANKBAGSLOTS)=="number" and NUM_BANKBAGSLOTS or 0
        if total>0 and total<=7 then
            for i=1,total do ids[#ids+1]=base+i end
        end
        lastTabSource="legacy BANK_CONTAINER"
        lastTabCount=#ids
        return ids,"legacy"
    end
    lastTabSource="unavailable"
    lastTabCount=0
    return nil,"Forever bank tab IDs unavailable"
end
local function BankVisible()
    -- BANKFRAME_OPENED/CLOSED is the authoritative interaction boundary.
    -- Camelot's BankFrame can briefly be hidden while its BankPanel is shown;
    -- requiring BankFrame:IsShown() silently suppressed every read and card.
    return open
end
local function BankParent()
    local frame=BankFrame
    if frame and type(frame.IsShown)=="function" and
        Read(frame.IsShown,frame)==true then
        return frame,"BankFrame"
    end
    local panel=BankPanel
    if panel and type(panel.IsShown)=="function" and
        Read(panel.IsShown,panel)==true then
        return panel,"BankPanel"
    end
    if frame then return frame,"BankFrame (loading)" end
    if panel then return panel,"BankPanel (loading)" end
    if UIParent then return UIParent,"UIParent fallback" end
    return nil,"Bank frame not ready"
end
local function Snapshot()
    if not open then
        lastReason="Bank closed";return nil
    end
    local containers,kind=CharacterContainers()
    if not containers or #containers==0 then
        lastReason=kind or "Waiting for character bank tabs"
        return nil
    end
    local api=C_Container
    local countFn=api and api.GetContainerNumSlots or GetContainerNumSlots
    local infoFn=api and api.GetContainerItemInfo or GetContainerItemInfo
    local idFn=api and api.GetContainerItemID or GetContainerItemID
    local itemFn=(C_Item and C_Item.GetItemInfo) or GetItemInfo
    if type(countFn)~="function" or type(infoFn)~="function" or
        type(itemFn)~="function" then
        lastReason="Container or item-price API unavailable";return nil
    end
    local snapshot={vendorCopper=0,vendorUnknown=0,
        ahCopper=0,ahUnknown=0,ahPriced=0,
        stacks=0,units=0,containers=0,kind=kind}
    local any=false
    local missing=0
    for _,containerID in ipairs(containers) do
        local count=Read(countFn,containerID)
        if Integer(count) and count>0 and count<=120 then
            any=true
            snapshot.containers=snapshot.containers+1
            for slot=1,count do
                local ok,raw,qOld,_,_,_,_,linkOld,_,noValueOld,idOld=
                    pcall(infoFn,containerID,slot)
                if not ok or (type(issecretvalue)=="function" and
                    issecretvalue(raw)) then
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
        else
            -- Purchased tabs may be delayed / inaccessible; do not report
            -- their missing items as a complete valuation.
            missing=missing+1
        end
    end
    lastReadable=snapshot.containers
    lastMissing=missing
    if not any then
        lastReason="Bank tab contents not loaded yet"
        return nil
    end
    snapshot.missingTabs=missing
    snapshot.vendorComplete=snapshot.vendorUnknown==0 and missing==0
    snapshot.ahComplete=snapshot.ahUnknown==0 and missing==0
    lastReason=missing>0 and "Partial bank scan (tab data pending)" or
        "Character bank snapshot saved"
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
        "containers","missingTabs","at","kind"}) do
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
        primary:SetText("Bank vendor value: --")
        market:SetText("AH estimate: --")
        note:SetText(lastReason)
        return
    end
    primary:SetText("Vendor value: "..
        (v.vendorComplete and "" or "at least ")..Coin(v.vendorCopper))
    market:SetText("Auction asks: "..
        (v.ahPriced>0 and ((v.ahComplete and "" or "at least ")..
            Coin(v.ahCopper)) or "no usable prices"))
    note:SetText(("%d stacks  /  %d AH priced  /  %s"):format(
        v.stacks or 0,v.ahPriced or 0,v.age or "last bank visit"))
end
local function EnsurePanel()
    local bank,where=BankParent()
    lastBankParent=where
    if not bank then return end
    if not panel then
        panel=CreateFrame("Frame","ChalkBoxBankValuePanel",bank)
        panel:SetSize(269,78)
        if type(panel.EnableMouse)=="function" then panel:EnableMouse(true) end
        local bg=panel:CreateTexture(nil,"BACKGROUND")
        bg:SetAllPoints(panel)
        if type(bg.SetColorTexture)=="function" then
            bg:SetColorTexture(.035,.041,.05,.95)
        elseif type(bg.SetTexture)=="function" then
            bg:SetTexture("Interface\\Buttons\\WHITE8X8")
            if bg.SetVertexColor then bg:SetVertexColor(.035,.041,.05,.95) end
        end
        local function Label(template,y,r,g,b)
            local font=panel:CreateFontString(nil,"OVERLAY",template)
            font:SetPoint("TOPLEFT",panel,"TOPLEFT",10,y)
            font:SetWidth(251)
            font:SetJustifyH("LEFT")
            font:SetTextColor(r,g,b)
            return font
        end
        local headline=Label("GameFontNormal",-5,.95,.75,.38)
        headline:SetText("ChalkBox  /  BANK VALUE")
        primary=Label("GameFontNormal",-25,.94,.88,.66)
        market=Label("GameFontHighlightSmall",-46,.59,.86,.79)
        note=Label("GameFontHighlightSmall",-64,.71,.73,.73)
        panel:SetScript("OnEnter",function(self)
            if not GameTooltip or type(GameTooltip.SetOwner)~="function"
                then return end
            GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            GameTooltip:AddLine("ChalkBox · Character Bank",1,.82,.4)
            local v=ChalkBox_BankValueStatus()
            if v then
                GameTooltip:AddLine("Vendor (last seen): "..
                    (v.vendorComplete and "" or "at least ")..
                    Coin(v.vendorCopper),1,1,1)
                GameTooltip:AddLine("AH asks (not sales): "..
                    (v.ahPriced>0 and Coin(v.ahCopper) or "unavailable"),
                    .65,.84,.9)
                GameTooltip:AddLine(("%d/%d stacks with usable AH prices"):format(
                    v.ahPriced or 0,v.stacks or 0),.68,.71,.77)
                GameTooltip:AddLine("Last snapshot: "..(v.age or "unknown"),
                    .68,.71,.77)
            else
                GameTooltip:AddLine(lastReason,.8,.72,.65)
            end
            GameTooltip:Show()
        end)
        panel:SetScript("OnLeave",function()
            if GameTooltip then GameTooltip:Hide() end
        end)
    end
    if panelParent~=bank then
        if type(panel.SetParent)=="function" then panel:SetParent(bank) end
        if type(panel.ClearAllPoints)=="function" then
            panel:ClearAllPoints()
        end
        -- Keep the summary inside the bank UI's own top-right corner.
        if where=="UIParent fallback" then
            panel:SetPoint("TOPRIGHT",bank,"TOPRIGHT",-110,-135)
        else
            panel:SetPoint("TOPRIGHT",bank,"TOPRIGHT",-18,-55)
        end
        panelParent=bank
    end
    if type(bank.GetFrameLevel)=="function" and
        type(panel.SetFrameLevel)=="function" then
        local level=Read(bank.GetFrameLevel,bank)
        if Numeric(level) then panel:SetFrameLevel(level+35) end
    end
end
local function Refresh()
    if not open then
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
-- BankPanel can be loaded lazily after ChalkBox and its OnShow can
-- precede the Camelot BANKFRAME_OPENED event. Observe both safe signals.
-- We never hook a protected bank-item button or alter Blizzard frame state.
local hooked=setmetatable({},{__mode="k"})
local function HookBankFrames()
    for _,bank in ipairs({BankPanel or false,BankFrame or false}) do
        if bank and not hooked[bank] and
            type(bank.HookScript)=="function" then
            local ok=pcall(bank.HookScript,bank,"OnShow",function()
                if not open then
                    open=true
                    lastReason="Bank window shown; reading character tabs"
                    pending=8
                    elapsed=0
                end
                Refresh()
            end)
            if ok then hooked[bank]=true end
        end
    end
end
-- Register and retry against late-loaded bank frames without relying on a
-- specific load order for the Camelot BankFrame/BankPanel.
HookBankFrames()
local listener=CreateFrame("Frame")
for _,event in ipairs({"BANKFRAME_OPENED","BANKFRAME_CLOSED",
    "PLAYERBANKSLOTS_CHANGED","PLAYERBANKBAGSLOTS_CHANGED",
    "BANK_TABS_CHANGED","BANK_TAB_SETTINGS_UPDATED",
    "BAG_UPDATE_DELAYED","GET_ITEM_INFO_RECEIVED","ITEM_DATA_LOAD_RESULT",
    "PLAYER_ENTERING_WORLD"}) do
    local valid=C_EventUtils and type(C_EventUtils.IsEventValid)=="function"
        and Read(C_EventUtils.IsEventValid,event)
    if valid~=false then pcall(listener.RegisterEvent,listener,event) end
end
listener:SetScript("OnEvent",function(_,event)
    if event=="BANKFRAME_CLOSED" or event=="PLAYER_ENTERING_WORLD" then
        open=false
        pending=0
        lastReason="Bank closed"
        if panel then panel:Hide() end
    elseif event=="BANKFRAME_OPENED" then
        HookBankFrames()
        open=true
        lastReason="Bank opened; checking character tabs"
        pending=8
        elapsed=0
        Refresh()
    elseif open then
        pending=3
        elapsed=0
    end
end)
listener:SetScript("OnUpdate",function(_,dt)
    elapsed=elapsed+(type(dt)=="number" and dt or 0)
    if elapsed<.7 then return end
    elapsed=0
    HookBankFrames()
    if not open then
        -- Last-resort discovery if Camelot omitted the BANKFRAME event or
        -- the panel was already visible when ChalkBox registered hooks.
        local frame=BankPanel
        local visible=frame and Read(frame.IsShown,frame)==true
        local canView=type(C_Bank)=="table" and
            Read(C_Bank.CanViewBank,
                type(Enum)=="table" and type(Enum.BankType)=="table"
                    and Enum.BankType.Character or 0)
        if visible and canView==true then
            open=true
            pending=8
            lastReason="BankPanel visible; character bank accessible"
            Refresh()
        end
        return
    end
    if pending>0 then
        pending=pending-1
        Refresh()
    end
end)
-- Diagnostics are available even without a saved bank visit.
function ChalkBox_BankValueDebug()
    local bank,where=BankParent()
    local saved=Current()
    return {
        initialized=true,open=open,
        bankFrame=where or "none",
        panel=panel and panel.IsShown and Read(panel.IsShown,panel)==true
            or false,
        tabSource=lastTabSource,tabs=lastTabCount,
        readable=lastReadable,missing=lastMissing,
        reason=lastReason,saved=saved~=nil,
        vendorCopper=saved and saved.vendorCopper or nil,
    }
end
