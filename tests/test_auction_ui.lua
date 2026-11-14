-- AuctionSense native AH tab regression; no standalone popover or protected changes.
local allFrames,fonts={},{}
local function Element(kind,parent,name,template)
    local f={kind=kind,parent=parent,name=name,template=template,
        scripts={},shown=true}
    function f:SetSize(w,h) self.w,self.h=w,h end
    function f:SetPoint(...)
        self.point={...}
        self.points=self.points or {}
        self.points[#self.points+1]={...}
    end
    function f:SetWidth(w) self.w=w end
    function f:ClearAllPoints() self.points={};self.point=nil end
    function f:GetHeight()
        if self.name=="ChalkBoxAuctionSensePane" then
            return self.mockHeight or 316
        end
        return self.h or 440
    end
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
local tip={lines={},shown=false}
function tip:SetOwner(owner,anchor)
    self.owner,self.anchor=owner,anchor
end
function tip:ClearLines() self.lines={} end
function tip:AddLine(message,r,g,b)
    self.lines[#self.lines+1]={text=message,color={r,g,b}}
end
function tip:AddDoubleLine(label,value,lr,lg,lb,vr,vg,vb)
    self.lines[#self.lines+1]={text=label,value=value,
        color={vr,vg,vb}}
end
function tip:Show() self.shown=true end
function tip:Hide() self.shown=false end
_G.GameTooltip=tip
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
    tab.text=="Market" and tab.w==92,
    "short native AH tab stays readable inside the native tab strip")
assert(tab.point and tab.point[2]==auctions and
    pane.point[2]==AuctionHouseFrame,
    "new tab aligns after Blizzard's native tabs")
assert(not pane.shown)
assert(pane.points[1][1]=="TOPLEFT"
    and pane.points[1][5]==-56
    and pane.points[2][1]=="BOTTOMRIGHT"
    and pane.points[2][5]==68,
    "AuctionSense reserves the stock AH title and a 68px footer/tab strip")
local footer,previousButton,nextButton
local rows={}
for _,f in ipairs(allFrames) do
    if f.parent==pane and f.kind=="Button" then
        if f.text=="Previous" then previousButton=f
        elseif f.text=="Next" then nextButton=f end
    end
    if f.parent==pane and f.kind=="Frame"
        and f.w==560 and f.h==22 then rows[#rows+1]=f end
end
for _,font in ipairs(fonts) do
    if font.parent==pane and font.point and
        font.point[1]=="BOTTOMLEFT" and font.point[5]==12 then
        footer=font
    end
end
assert(#rows==7 and footer and previousButton and nextButton,
    "rows, pager, and scan disclaimer all exist within the native pane")
assert(rows[1].point[5]==-157 and rows[7].point[5]==-301,
    "compact rows share a fixed 24px rhythm")
assert(previousButton.point[1]=="BOTTOMLEFT"
    and nextButton.point[1]=="BOTTOMLEFT"
    and previousButton.point[5]==34 and nextButton.point[5]==34
    and footer.point[5]==12,
    "paging and notes anchor to the pane bottom, not a hard-coded height")
local function VisibleRows()
    local n=0
    for _,row in ipairs(rows) do if row.shown then n=n+1 end end
    return n
end
assert(nativeRegistryEdits==0,"never touch protected Blizzard tab registry")
assert(ChalkBox_AuctionOpen() and pane.shown and tab.selected)
assert(Text("AuctionSense") and Text("Whitemane / Alliance"))
assert(Text("15s 0c") and Text("—"),
    "browse results have a low price but no fabricated average")
assert(VisibleRows()==1 and rows[1].shown and
    not rows[2].shown,
    "only available entries show; unused rows never cover footer")
assert(Text("24 units") and
    (function()
        for _,font in ipairs(fonts) do
            if type(font.text)=="string" and
                font.text:find("Browse prices",1,true) then return true end
        end
    end)(),"browse summaries label their source clearly")
assert(fullScans==0 and browseScans==0)
-- Size-aware pagination: the photographed 440px native AH leaves 316px
-- for content after its title/footer; 4 result rows can fit without overlap.
local items={}
for i=1,9 do
    items[i]={name="Item "..i,itemID=1000+i,low=1500+i,
        average=nil,listings=nil,quantity=1}
end
_G.ChalkBox_AuctionRows=function()
    reads=reads+1
    return items
end
status.scannedAt=stamp+1
pane.scripts.OnUpdate(pane,1.5)
assert(VisibleRows()==4 and Text("Page 1 / 3"),
    "short native pane uses four rows per page, never 7 overflowing rows")
local row4Bottom=157+3*24+22
local pagerTop=pane:GetHeight()-34-25
assert(row4Bottom<=pagerTop,
    "visible data stops above the bottom anchored pager")
pane.mockHeight=410
pane.scripts.OnUpdate(pane,1.5)
assert(VisibleRows()==7 and Text("Page 1 / 2"),
    "taller native AH uses seven rows without changing scan data")
pane.mockHeight=316
pane.scripts.OnUpdate(pane,1.5)
assert(VisibleRows()==4 and Text("Page 1 / 3"),
    "resizing smaller repaginates instead of clipping")
-- Restore the familiar sample before verifying prices and mouseover hints.
_G.ChalkBox_AuctionRows=function()
    reads=reads+1
    return {{name="Linen Cloth",itemID=2589,low=1500,
        average=nil,listings=nil,quantity=24}}
end
status.scannedAt=stamp+2
pane.scripts.OnUpdate(pane,1.5)
local hoverRow
for _,f in ipairs(allFrames) do
    if f.marketData and f.scripts.OnEnter then hoverRow=f;break end
end
assert(hoverRow,"each price row exposes a hover summary")
hoverRow.scripts.OnEnter(hoverRow)
assert(tip.shown and tip.owner==hoverRow)
local lowSeen,avgUnknown,unitsSeen,sourceSeen=false,false,false,false
for _,entry in ipairs(tip.lines) do
    if entry.text=="Low ask / unit" and entry.value=="15s 0c" then
        lowSeen=entry.color[2]>entry.color[1]
    elseif entry.text=="Avg ask / unit" and entry.value=="--" then
        avgUnknown=true
    elseif entry.text=="Units" and entry.value=="24" then
        unitsSeen=true
    elseif entry.text:find("Browse",1,true) then
        sourceSeen=true
    end
end
assert(lowSeen and avgUnknown and unitsSeen and sourceSeen,
    "row hover shows color-coded low, unavailable average, units and source")
hoverRow.scripts.OnLeave()
assert(not tip.shown,"hover tooltip hides on mouse leave")
local scanButton=Button("Scan Market")
scanButton.scripts.OnEnter(scanButton)
assert(tip.shown and tip.lines[1].text=="Scan Market",
    "scan controls have brief, useful tooltips")
scanButton.scripts.OnLeave()
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
print("PASS: AuctionSense compact inner-AH layout, safe footer, native tab, browse/full scans, mouseover and tab switching")
