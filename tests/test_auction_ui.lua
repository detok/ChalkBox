-- AuctionSense native AH tab regression; no standalone popover or protected changes.
local allFrames,fonts={},{}
local function Element(kind,parent,name,template)
    local f={kind=kind,parent=parent,name=name,template=template,
        scripts={},shown=true}
    function f:SetSize(w,h) self.w,self.h=w,h end
    function f:SetPoint(...) self.point={...} end
    function f:SetWidth(w) self.w=w end
    function f:SetText(v) self.text=v end
    function f:GetText() return self.text end
    function f:SetTextColor(...) self.color={...} end
    function f:SetJustifyH() end
    function f:SetFrameLevel(v) self.level=v end
    function f:GetFrameLevel() return self.level or 10 end
    function f:SetToplevel(v) self.toplevel=v end
    function f:EnableMouse() end
    function f:SetAutoFocus() end
    function f:SetMaxLetters() end
    function f:ClearFocus() end
    function f:SetEnabled(v) self.enabled=v end
    function f:SetScript(event,fn) self.scripts[event]=fn end
    function f:HookScript(event,fn)
        self.hooks=self.hooks or {}
        self.hooks[event]=fn
    end
    function f:Hide() self.shown=false end
    function f:Show() self.shown=true end
    function f:IsShown() return self.shown end
    function f:CreateTexture()
        local t=Element("Texture",self)
        function t:SetAllPoints() end
        function t:SetColorTexture() end
        function t:SetTexture() end
        function t:SetVertexColor() end
        return t
    end
    function f:CreateFontString()
        local t=Element("Font",self)
        fonts[#fonts+1]=t
        return t
    end
    function f:Click()
        assert(self.scripts.OnClick, "not a clickable native button")
        self.scripts.OnClick(self)
        if self.hooks and self.hooks.OnClick then
            self.hooks.OnClick(self)
        end
    end
    allFrames[#allFrames+1]=f
    return f
end
_G.UIParent=Element("Root")
_G.CreateFrame=function(kind,name,parent,template)
    return Element(kind,parent,name,template)
end
_G.AuctionHouseFrame=Element("Frame",UIParent,"AuctionHouseFrame")
AuctionHouseFrame.level=15
local buy=Element("Button",AuctionHouseFrame,"AHBuy")
local sell=Element("Button",AuctionHouseFrame,"AHSell")
local auctions=Element("Button",AuctionHouseFrame,"AHAuctions")
AuctionHouseFrame.Tabs={buy,sell,auctions}
for _,native in ipairs(AuctionHouseFrame.Tabs) do
    native:SetScript("OnClick",function() end)
end
local nativeRegistryEdits=0
_G.PanelTemplates_SetTab=function()
    nativeRegistryEdits=nativeRegistryEdits+1
    error("Never modify protected Blizzard tab selection")
end
_G.PanelTemplates_SetNumTabs=PanelTemplates_SetTab
_G.PanelTemplates_SelectTab=function(b) b.selected=true end
_G.PanelTemplates_DeselectTab=function(b) b.selected=false end
_G.hooksecurefunc=function(parent,method,callback)
    assert(parent==AuctionHouseFrame and method=="SetDisplayMode")
    parent.modeHook=callback
end
AuctionHouseFrame.SetDisplayMode=function() end
local function FindFrame(name)
    for _,v in ipairs(allFrames) do
        if v.name==name then return v end
    end
end
local function Button(name)
    for _,v in ipairs(allFrames) do
        if v.kind=="Button" and v.text==name then return v end
    end
    error("missing button "..name)
end
local function Text(value)
    for _,v in ipairs(fonts) do
        if v.text==value then return true end
    end
end
local browseScans,fullScans,reads=0,0,0
local stamp=500
local status={
    available=true,fullAvailable=true,open=true,busy=false,
    state="Ready to browse market",realm="Whitemane",
    faction="Alliance",marketKey="whitemane|alliance",
    items=2,source="browse",auctions=0,
    scannedAt=stamp,age=10,cooldown=400,
}
_G.ChalkBox_AuctionStatus=function() return status end
_G.ChalkBox_AuctionRows=function()
    reads=reads+1
    return {{name="Linen Cloth",itemID=2589,low=1500,
        average=nil,listings=nil,quantity=24}}
end
_G.ChalkBox_AuctionScan=function() browseScans=browseScans+1;return true end
_G.ChalkBox_AuctionFullScan=function() fullScans=fullScans+1;return true end
assert(loadfile("AuctionSenseUI.lua"))("ChalkBox")
assert(ChalkBox_AuctionAttach())
local tab=FindFrame("ChalkBoxAuctionSenseTab")
local pane=FindFrame("ChalkBoxAuctionSensePane")
assert(tab and pane and pane.parent==AuctionHouseFrame,
    "AuctionSense is built directly inside Blizzard's auction house")
assert(tab.template=="AuctionHouseFrameDisplayModeTabTemplate" and
    tab.text=="AuctionSense",
    "native AH-style tab, not a settings-only link or loose popup")
assert(tab.point and tab.point[2]==auctions and
    pane.point[2]==AuctionHouseFrame,
    "new tab aligns after Blizzard's native tabs")
assert(not pane.shown)
assert(nativeRegistryEdits==0,"never touch protected Blizzard tab registry")
assert(ChalkBox_AuctionOpen() and pane.shown and tab.selected)
assert(Text("AuctionSense") and Text("Whitemane / Alliance"))
assert(Text("15s 0c") and Text("—"),
    "browse results have a low price but no fabricated average")
assert(Text("24 units listed") and
    (function()
        for _,font in ipairs(fonts) do
            if type(font.text)=="string" and
                font.text:find("Browse prices",1,true) then return true end
        end
    end)(),"browse summaries label their source clearly")
assert(fullScans==0 and browseScans==0)
assert(Button("Full listings (15m)").enabled==false,
    "full scan button honors cooldown")
assert(Button("Scan Market").enabled==true,
    "everyday browse scan is available during full cooldown")
Button("Scan Market"):Click()
assert(browseScans==1 and fullScans==0,
    "normal scan uses confirmed browse API, not legacy replicate")
local original=reads
pane.scripts.OnUpdate(pane,1.5)
assert(reads==original,"status refresh doesn't rescan the sorted market")
status.scannedAt=stamp+100
pane.scripts.OnUpdate(pane,1.5)
assert(reads==original+1,"new market scan refreshes browser rows")
status.cooldown=0
pane.scripts.OnUpdate(pane,1.5)
Button("Full listings (15m)"):Click()
assert(fullScans==1,"advanced full scan is a separate explicit action")
buy:Click()
assert(not pane.shown and not tab.selected,
    "native Buy tab automatically closes the custom panel")
tab:Click()
assert(pane.shown,"returning to AuctionSense opens inline again")
AuctionHouseFrame.modeHook()
assert(not pane.shown,"Blizzard display mode changes restore native panels")
assert(nativeRegistryEdits==0,"no protected PanelTemplates mutations")
ChalkBox_AuctionHide()
assert(not pane.shown)
print("PASS: AuctionSense real AH tab, no popup or secure-tab edits, browser summary labels, scan separation, live native tab switching")
