-- Character bank valuation: trustworthy vendor prices first, read-only
-- AuctionSense asks second. Bank UI and Trail Bar retain last-seen snapshots.
local allFrames,events={},{}
_G.ChalkBoxZoneDB={}
local clock=1794873600
_G.GetServerTime=function() return clock end
_G.issecretvalue=function() return false end
local function Frame(kind,name,parent)
    local f={kind=kind,name=name,parent=parent,shown=true,scripts={}}
    function f:RegisterEvent(e) events[e]=self end
    function f:SetScript(e,fn) self.scripts[e]=fn end
    function f:SetSize(w,h) self.w,self.h=w,h end
    function f:SetPoint(...) self.point={...} end
    function f:SetFrameLevel(n) self.level=n end
    function f:GetFrameLevel() return 20 end
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:IsShown() return self.shown end
    function f:CreateTexture()
        local t={parent=self}
        function t:SetAllPoints() end
        function t:SetColorTexture(...) self.color={...} end
        function t:SetTexture(path) self.texture=path end
        function t:SetVertexColor(...) end
        return t
    end
    function f:CreateFontString()
        local v={parent=self}
        function v:SetPoint() end
        function v:SetWidth() end
        function v:SetJustifyH() end
        function v:SetTextColor() end
        function v:SetText(text) self.text=text end
        return v
    end
    allFrames[#allFrames+1]=f
    return f
end
_G.CreateFrame=Frame
local bank=Frame("Frame","BankFrame")
_G.BankFrame=bank
local bankVisible=false
function bank:IsShown() return bankVisible end
_G.Enum={BagIndex={
    CharacterBankTab_1=6,CharacterBankTab_2=7,AccountBankTab_1=12
}}
local containerReads,bankItemReads,accountReads=0,0,0
local bankSlots={
    [6]={[1]={stackCount=3,itemID=101,hasNoValue=false},
        [2]={stackCount=2,itemID=102,hasNoValue=false},
        [3]={stackCount=1,itemID=103,hasNoValue=true}},
    [7]={[1]={stackCount=4,itemID=104,hasNoValue=false}},
    [12]={[1]={stackCount=100,itemID=999,hasNoValue=false}}
}
local prices={[101]=200,[103]=0,[104]=100,[999]=999999}
_G.C_Item={
    GetItemInfo=function(id)
        local p=prices[id]
        if p==nil then return nil end
        return "item"..id,"item:"..id,1,1,1,1,1,200,1,111,p
    end
}
_G.C_Container={
    GetContainerNumSlots=function(bag)
        containerReads=containerReads+1
        if bag==12 then accountReads=accountReads+1 end
        if bag==6 then return 3 end
        if bag==7 then return 1 end
        if bag==12 then return 1 end
        return 0
    end,
    GetContainerItemInfo=function(bag,slot)
        bankItemReads=bankItemReads+1
        if bag==12 then accountReads=accountReads+1 end
        return bankSlots[bag] and bankSlots[bag][slot]
    end,
    GetContainerItemID=function(bag,slot)
        local item=bankSlots[bag] and bankSlots[bag][slot]
        return item and item.itemID
    end
}
local auctionReads=0
_G.ChalkBox_AuctionPrice=function(id)
    auctionReads=auctionReads+1
    if id==101 then return {low=1000,stale=false,mixed=false} end
    if id==103 then return {low=9999,stale=true,mixed=false} end
    if id==104 then return {low=5000,stale=false,mixed=true} end
end
local barRefresh=0
_G.ChalkBox_BarBankValueRefresh=function()
    barRefresh=barRefresh+1
end
assert(loadfile("BankValue.lua"))("ChalkBox")
local listener=events.BANKFRAME_OPENED
assert(listener and listener==events.BANKFRAME_CLOSED and
    listener==events.PLAYERBANKSLOTS_CHANGED)
assert(ChalkBox_BankValueStatus()==nil,
    "no prior visit means unavailable, never fabricate zero value")
assert(bankItemReads==0 and auctionReads==0 and accountReads==0,
    "never read bank items or prices outside bank")
bankVisible=true
listener.scripts.OnEvent(listener,"BANKFRAME_OPENED")
local v=ChalkBox_BankValueStatus()
assert(v and v.open and v.vendorCopper==1000 and
    v.vendorUnknown==1 and not v.vendorComplete and v.containers==2
    and v.stacks==4 and v.units==10,
    "vendor estimate counts stacks and quantities, flags uncached prices")
assert(v.ahCopper==3000 and v.ahPriced==1 and v.ahUnknown==3
    and not v.ahComplete and auctionReads==4,
    "AH comparison is additional and excludes stale, mixed, missing prices")
assert(accountReads==0,"account/guild bank never read")
local valuePanel
for _,frame in ipairs(allFrames) do
    if frame.name=="ChalkBoxBankValuePanel" then valuePanel=frame end
end
assert(valuePanel and valuePanel.parent==bank and valuePanel.shown,
    "read-only Bank Value card appears INSIDE native BankFrame")
assert(barRefresh>0,"snapshot change requests a Trail Bar text refresh")
local reads=bankItemReads
bankVisible=false
listener.scripts.OnEvent(listener,"BANKFRAME_CLOSED")
assert(not valuePanel.shown and ChalkBox_BankValueStatus().open==false
    and bankItemReads==reads and
    ChalkBox_BankValueStatus().vendorCopper==1000,
    "closing bank hides card, preserves last-seen value, never scans remotely")
clock=clock+4000
assert(ChalkBox_BankValueStatus().age=="1h ago",
    "saved snapshot shows last bank visit, not current holdings")
prices[102]=250
bankVisible=true
listener.scripts.OnEvent(listener,"BANKFRAME_OPENED")
v=ChalkBox_BankValueStatus()
assert(v.vendorCopper==1500 and v.vendorUnknown==0 and v.vendorComplete,
    "visiting bank again updates previously unknown vendor cache values")
bankVisible=false
listener.scripts.OnEvent(listener,"BANKFRAME_CLOSED")
local original=ChalkBoxZoneDB
_G.ChalkBoxZoneDB={}
assert(ChalkBox_BankValueStatus()==nil,
    "other character's saved bank never becomes this character's value")
_G.ChalkBoxZoneDB=original
local snapshot=ChalkBoxZoneDB.bankValue.snapshot
ChalkBoxZoneDB.bankValue={version=99,snapshot=snapshot}
assert(ChalkBox_BankValueStatus()==nil and
    ChalkBoxZoneDB.bankValue.version==99,
    "unknown newer bank data schema must remain untouched")
ChalkBoxZoneDB.bankValue={version=1,snapshot=snapshot}
assert(ChalkBox_BankValueStatus().vendorCopper==1500,
    "saved snapshot survives reload of reader without migrating data")
print("PASS: Bank Value vendor primary, separate AH coverage, bank-only access, saved last-seen cache, per-character isolation")
