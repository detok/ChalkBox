-- AuctionSense window smoke test; verifies actual click paths and row caching.
local objects={}
local allFrames={}
local function Element(kind,parent,name)
    local f={kind=kind,parent=parent,name=name,scripts={},shown=true}
    function f:SetSize(w,h) self.w,self.h=w,h end
    function f:SetPoint(...) self.point={...} end
    function f:SetWidth(w) self.w=w end
    function f:SetText(v) self.text=v end
    function f:GetText() return self.text end
    function f:SetTextColor(...) self.color={...} end
    function f:SetJustifyH() end
    function f:SetFrameStrata(s) self.strata=s end
    function f:SetFrameLevel(v) self.level=v end
    function f:SetToplevel(v) self.toplevel=v end
    function f:SetMovable() end
    function f:RegisterForDrag() end
    function f:EnableMouse() end
    function f:SetAutoFocus() end
    function f:SetMaxLetters() end
    function f:ClearFocus() end
    function f:SetEnabled(v) self.enabled=v end
    function f:Raise() self.raised=true end
    function f:SetScript(event,fn) self.scripts[event]=fn end
    function f:Hide() self.shown=false end
    function f:Show() self.shown=true end
    function f:IsShown() return self.shown end
    function f:CreateTexture()
        local obj=Element("Texture",self)
        function obj:SetAllPoints() end
        function obj:SetTexture() end
        function obj:SetVertexColor() end
        function obj:SetColorTexture() end
        return obj
    end
    function f:CreateFontString()
        local obj=Element("Font",self)
        objects[#objects+1]=obj
        return obj
    end
    function f:Click()
        assert(self.scripts.OnClick,"not a button")
        self.scripts.OnClick(self)
    end
    allFrames[#allFrames+1]=f
    return f
end
_G.UIParent=Element("Root")
_G.CreateFrame=function(kind,name,parent)
    return Element(kind,parent,name)
end
local function Button(text)
    for _,item in ipairs(allFrames) do
        if item.kind=="Button" and item.text==text then return item end
    end
    error("missing button "..text)
end
local function Label(text)
    for _,item in ipairs(objects) do
        if item.text==text then return item end
    end
end
local scanned=0
local rowsRead=0
local lastDate=1000
local status={
    available=true,open=true,busy=false,state="Ready to scan",
    realm="Whitemane",faction="Alliance",marketKey="whitemane|alliance",
    items=2,auctions=10,scannedAt=lastDate,age=450,cooldown=0,
}
_G.ChalkBox_AuctionStatus=function() return status end
_G.ChalkBox_AuctionRows=function(search)
    rowsRead=rowsRead+1
    if search~="" and search~="linen" then return {} end
    return {{name="Linen Cloth",itemID=2589,low=1200,
        average=1600,listings=4,quantity=30}}
end
_G.ChalkBox_AuctionScan=function() scanned=scanned+1;return true end
assert(loadfile("AuctionSenseUI.lua"))("ChalkBox")
assert(ChalkBox_AuctionOpen())
local window
for _,item in ipairs(allFrames) do
    if item.name=="ChalkBoxAuctionSenseWindow" then window=item end
end
assert(window and window.shown and window.strata=="DIALOG" and
    window.toplevel,"AuctionSense opens a separate native read-only window")
assert(Label("AuctionSense") and Label("Whitemane / Alliance"))
assert(Label("1,200c")==nil,"currency is formatted instead of raw copper")
assert(Label("12s 0c") and Label("16s 0c"),
    "lowest and average unit asking prices are clearly readable")
assert(Label("4 listings") and Label("30 units available"))
assert(scanned==0,"opening AuctionSense never triggers a full market scan")
local initial=rowsRead
window.scripts.OnUpdate(window,1.2)
window.scripts.OnUpdate(window,1.2)
assert(rowsRead==initial,
    "status refreshes do not repeatedly sort the full auction database")
Button("Scan Market"):Click()
assert(scanned==1,"scanner only runs after a real click")
status.scannedAt=lastDate+60
status.age=20
window.scripts.OnUpdate(window,1.2)
assert(rowsRead==initial+1,
    "a completed fresh scan invalidates the cached rows")
status.cooldown=600
status.open=false
window.scripts.OnUpdate(window,1.2)
assert(Button("Scan Market").enabled==false,
    "scanner action is disabled outside the AH or during cooldown")
status.open=true;status.cooldown=0
window.scripts.OnUpdate(window,1.2)
assert(Button("Scan Market").enabled==true)
local searchInput
for _,item in ipairs(allFrames) do
    if item.kind=="EditBox" then searchInput=item;break end
end
assert(searchInput and searchInput.scripts.OnTextChanged)
searchInput.text="unobtainium"
searchInput.scripts.OnTextChanged(searchInput)
assert(rowsRead==initial+2 and Label("Page 1 / 1"),
    "typing a search updates the market browser directly")
Button("Close"):Click()
assert(not window.shown)
assert(ChalkBox_AuctionOpen() and window.shown)
assert(scanned==1,"reopening does not automatically scan")
print("PASS: AuctionSense native market window, per-item prices, explicit scans, search, cache and closed-AH controls")
