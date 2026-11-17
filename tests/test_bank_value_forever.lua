-- Forever-style bank: Camelot's hidden BankFrame and visible BankPanel,
-- C_Bank-purchased character tabs without a CharacterBankTab enum,
-- delayed bank data, a visible no-snapshot card and OnShow fallback.
_G.ChalkBoxZoneDB={}
_G.issecretvalue=function() return false end
_G.GetServerTime=function() return 1794873600 end
local events,frames,labels,reads={}, {},{},{}
local function Frame(kind,name,parent)
    local f={kind=kind,name=name,parent=parent,shown=false,script={},hooks={}}
    function f:RegisterEvent(e) events[e]=self end
    function f:SetScript(e,fn) self.script[e]=fn end
    function f:HookScript(e,fn) self.hooks[e]=fn end
    function f:SetSize(w,h) self.w=w;self.h=h end
    function f:SetPoint(...) self.point={...} end
    function f:ClearAllPoints() self.point=nil end
    function f:SetParent(target) self.parent=target end
    function f:SetFrameLevel(n) self.level=n end
    function f:GetFrameLevel() return 20 end
    function f:EnableMouse() end
    function f:Show()
        local was=self.shown
        self.shown=true
        if not was and self.hooks.OnShow then self.hooks.OnShow(self) end
    end
    function f:Hide() self.shown=false end
    function f:IsShown() return self.shown end
    function f:CreateTexture()
        self.textures=(self.textures or 0)+1
        return {SetAllPoints=function() end,
            SetColorTexture=function() end}
    end
    function f:CreateFontString()
        local font={parent=self}
        function font:SetPoint() end
        function font:SetWidth() end
        function font:SetJustifyH() end
        function font:SetTextColor() end
        function font:SetText(s) self.text=s end
        labels[#labels+1]=font
        return font
    end
    frames[#frames+1]=f
    return f
end
_G.CreateFrame=Frame
_G.UIParent=Frame("Frame","UIParent")
_G.BankFrame=Frame("Frame","BankFrame",UIParent) -- hidden Camelot parent
_G.BankPanel=Frame("Frame","BankPanel",BankFrame)
_G.Enum={BankType={Character=0,Account=2,Guild=1}}
local fetches,accountReads=0,0
_G.C_Bank={
    FetchPurchasedBankTabIDs=function(typeID)
        fetches=fetches+1
        assert(typeID==0,"never fetch account/guild bank")
        return {6,7}
    end,
    CanViewBank=function(typeID)
        assert(typeID==0)
        return BankPanel:IsShown()
    end
}
local ready=0
local itemData={
    [6]={[1]={itemID=101,stackCount=3}},
    [7]={[1]={itemID=202,stackCount=2}},
    [12]={[1]={itemID=999,stackCount=100}}
}
_G.C_Container={
    GetContainerNumSlots=function(tab)
        reads[#reads+1]=tab
        if tab==12 then accountReads=accountReads+1 end
        if ready==0 then return nil end
        if tab==6 then return 1 end
        if tab==7 then return ready>=2 and 1 or nil end
        if tab==12 then return 1 end
        return nil
    end,
    GetContainerItemInfo=function(tab,slot)
        if tab==12 then accountReads=accountReads+1 end
        return itemData[tab] and itemData[tab][slot]
    end,
    GetContainerItemID=function(tab,slot)
        return itemData[tab] and itemData[tab][slot].itemID
    end
}
_G.C_Item={GetItemInfo=function(id)
    local p=({[101]=200,[202]=500})[id]
    return "item "..id,"item:"..id,1,nil,nil,nil,nil,nil,nil,nil,p
end}
_G.ChalkBox_AuctionPrice=function(id)
    if id==101 then return {low=1000,stale=false,mixed=false} end
    return {low=500,stale=true,mixed=false}
end
_G.ChalkBox_BarBankValueRefresh=function() end
assert(loadfile("BankValue.lua"))("ChalkBox")
assert(ChalkBox_BankValueStatus()==nil,
    "a fresh character has no saved bank snapshot")
assert(events.BANKFRAME_OPENED and
    events.BANKFRAME_OPENED==events.BANKFRAME_CLOSED)
local listener=events.BANKFRAME_OPENED
local function Text(needle)
    for _,v in ipairs(labels) do
        if type(v.text)=="string" and v.text:find(needle,1,true) then
            return true
        end
    end
    return false
end
BankPanel:Show() -- fallback OnShow, no BANKFRAME_OPENED event
local info=ChalkBox_BankValueDebug()
assert(info.open and info.bankFrame=="BankPanel" and
    info.panel and info.tabs==2 and info.tabSource:find("C_Bank"),
    "visible BankPanel initializes the card without a global bank enum/event")
assert(ChalkBox_BankValueStatus()==nil and
    Text("Bank --") and
    ChalkBox_BankValueDebug().reason=="Bank tab contents not loaded yet",
    "header shows a clean Bank -- while no item data is available")
local valuePanel
for _,frame in ipairs(frames) do
    if frame.name=="ChalkBoxBankValuePanel" then valuePanel=frame end
end
assert(valuePanel and valuePanel.parent==BankPanel and
    valuePanel.w==160 and valuePanel.h==17 and
    valuePanel.point[1]=="TOPRIGHT" and
    valuePanel.point[4]==-145 and valuePanel.point[5]==-29 and
    not valuePanel.textures,
    "inline bank label sits left of search with NO painted box, border, or item-slot overlap")
assert(accountReads==0,"no account bank API is ever queried")
ready=1
listener.script.OnEvent(listener,"BANK_TABS_CHANGED")
listener.script.OnUpdate(listener,.8)
local status=ChalkBox_BankValueStatus()
assert(status and status.vendorCopper==600 and
    status.vendorComplete==false and status.missingTabs==1,
    "partial character bank scans are lower-bound estimates")
ready=2
listener.script.OnEvent(listener,"PLAYERBANKSLOTS_CHANGED")
listener.script.OnUpdate(listener,.8)
status=ChalkBox_BankValueStatus()
assert(status.vendorCopper==1600 and status.vendorComplete and
    status.stacks==2 and status.ahCopper==3000 and status.ahPriced==1 and
    Text("Bank 16s"),
    "bank value appears as a single inline vendor total; AH prices remain tooltip-only")
local readCount=#reads
BankPanel:Hide()
listener.script.OnEvent(listener,"BANKFRAME_CLOSED")
listener.script.OnUpdate(listener,2)
assert(#reads==readCount and not ChalkBox_BankValueDebug().open
    and ChalkBox_BankValueStatus().vendorCopper==1600,
    "bank close stops scans but preserves the per-character value")
assert(accountReads==0,"never read AccountBankTab_1 despite its numeric ID")
-- Explicit event also works when the containing Camelot frame is hidden.
BankPanel:Show()
listener.script.OnEvent(listener,"BANKFRAME_OPENED")
assert(ChalkBox_BankValueDebug().panel and
    ChalkBox_BankValueStatus().open,
    "native bank event and OnShow can both initialize safely")
print("PASS: Forever BankPanel late init, visible Bank -- card, C_Bank tab IDs, partial cache, vendor snapshot and account isolation")
