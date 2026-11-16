-- AuctionSense native AH tab regression; no standalone popover or protected changes.
local allFrames,fonts={},{}
local function Element(kind,parent,name,template)
    local f={kind=kind,parent=parent,name=name,template=template,
        scripts={},shown=true,
        -- Some native AH tab templates draw selected until explicitly reset.
        selected=template=="AuctionHouseFrameDisplayModeTabTemplate"}
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
    function f:IsProtected() return self.protected==true end
    function f:CreateTexture()
        local t=Element("Texture",self)
        function t:SetAllPoints() end
        function t:SetColorTexture() end
        function t:SetAtlas(atlas,resize) self.atlas=atlas;self.resize=resize end
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
-- The actual Forever Blizzard SetDisplayMode hides every native page
-- before showing subframes belonging to the requested display mode.
_G.AuctionHouseFrameDisplayMode={
    Buy={"CategoriesList","SearchBar","BrowseResultsFrame"},
    Sell={"ItemSellFrame","ItemSellList"},
    Auctions={"AuctionsFrame"},
}
for _,name in ipairs({"CategoriesList","SearchBar","BrowseResultsFrame",
    "ItemSellFrame","ItemSellList","AuctionsFrame"}) do
    AuctionHouseFrame[name]=Element("Frame",AuctionHouseFrame,name)
end
for i,native in ipairs(AuctionHouseFrame.Tabs) do
    local mode=({AuctionHouseFrameDisplayMode.Buy,
        AuctionHouseFrameDisplayMode.Sell,
        AuctionHouseFrameDisplayMode.Auctions})[i]
    native:SetScript("OnClick",function()
        AuctionHouseFrame:SetDisplayMode(mode)
    end)
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
-- The Forever item-use pathway checks AH:IsListingAuctions() while the
-- Auction House is open. A custom addon call to SetDisplayMode contaminates
-- that security-sensitive state and can block using a Cozy Sleeping Bag.
-- Enforce Blizzard-only modes; Market must never call SetDisplayMode.
local nativeModeWrites=0
AuctionHouseFrame.SetDisplayMode=function(self,mode)
    assert(mode==AuctionHouseFrameDisplayMode.Buy
        or mode==AuctionHouseFrameDisplayMode.Sell
        or mode==AuctionHouseFrameDisplayMode.Auctions,
        "addon must never write its own market mode into Blizzard state")
    nativeModeWrites=nativeModeWrites+1
    if self.displayMode==mode then return end
    self.displayMode=mode
    -- Blizzard updates the selected native tab when the display mode changes.
    -- Its early return above leaves stale visuals when returning from Market
    -- to an already-selected Buy mode: that's the regression under test.
    for i,native in ipairs(self.Tabs) do
        if mode==({AuctionHouseFrameDisplayMode.Buy,
            AuctionHouseFrameDisplayMode.Sell,
            AuctionHouseFrameDisplayMode.Auctions})[i] then
            PanelTemplates_SelectTab(native)
        else
            PanelTemplates_DeselectTab(native)
        end
    end
    -- Simulated native behavior: this does not modify the native
    -- registry; it simply uses an existing method for our own pane.
    for _,list in pairs(AuctionHouseFrameDisplayMode) do
        for _,name in ipairs(list) do self[name]:Hide() end
    end
    for _,name in ipairs(mode) do
        assert(self[name],"unknown auction display-mode frame "..name)
        self[name]:Show()
    end
    if self.modeHook then self.modeHook(self,mode) end
end
AuctionHouseFrame.GetDisplayMode=function(self)
    return self.displayMode
end
AuctionHouseFrame.IsListingAuctions=function(self)
    return self:GetDisplayMode()==AuctionHouseFrameDisplayMode.Sell
end
-- Actual right-clicks of soulbound/usable items read this first, then
-- ultimately call the protected C_Container.UseContainerItem API.
local protectedItemUses=0
local function UseSoulboundBagItem()
    assert(not AuctionHouseFrame:IsListingAuctions(),
        "not attempting to post a soulbound Cozy Sleeping Bag")
    assert(AuctionHouseFrame:GetDisplayMode()==
        AuctionHouseFrameDisplayMode.Buy,
        "market browsing must not change the AH trading state")
    protectedItemUses=protectedItemUses+1
end
AuctionHouseFrame:SetDisplayMode(AuctionHouseFrameDisplayMode.Buy)
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
local deMarketReads={}
_G.ChalkBox_DisenchantMarketHint=function(tip,id)
    deMarketReads[#deMarketReads+1]=id
    return false
end
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
-- Compact Market graph must use saved observations and never send AH queries.
local chartReads,chartName,chartMixed=0,"Linen Cloth",false
local history={{t=1700000000,low=1500},{t=1700086400,low=1800},
    {t=1700259200,low=1350}}
_G.ChalkBox_AuctionChartHistory=function(itemID)
    chartReads=chartReads+1
    if itemID~=2589 then return nil end
    local copy={}
    for i,p in ipairs(history) do copy[i]={t=p.t,low=p.low} end
    return {itemID=itemID,name=chartName,mixed=chartMixed,realm="Whitemane",
        faction="Alliance",source="browse",points=copy}
end
_G.ChalkBox_AuctionScan=function() browseScans=browseScans+1;return true end
_G.ChalkBox_AuctionFullScan=function() fullScans=fullScans+1;return true end
local bagsRead,salesRead=0,0
_G.ChalkBox_MarketBagRows=function()
    bagsRead=bagsRead+1
    return {{name="My Test Green",itemID=8888,low=1000,
        count=2,marketTotal=2000,vendorTotal=500,
        de=1500,note="DE candidate",protected=false,bound=false}},
        {stacks=1,priced=1,marketValue=2000,vendorValue=500}
end
_G.ChalkBox_MarketSaleRows=function()
    salesRead=salesRead+1
    return {{name="Sold Linen",count=4,gross=10000,
        proceeds=9600,deposit=200,cut=600,at=10000}}
end
_G.ChalkBox_MarketSalesStatus=function()
    return {count=1,gross=10000,proceeds=9600,fees=600}
end
assert(loadfile("AuctionBrowser.lua"))("ChalkBox")
assert(loadfile("AuctionSenseUI.lua"))("ChalkBox")
assert(ChalkBox_AuctionAttach())
local tab=FindFrame("ChalkBoxAuctionSenseTab")
local pane=FindFrame("ChalkBoxAuctionSensePane")
local browserTab=FindFrame("ChalkBoxAuctionBrowserTab")
local browserPane=FindFrame("ChalkBoxAuctionBrowserPane")
assert(browserTab and browserPane and not browserPane.shown and
    browserTab.text=="Browser" and browserTab.point[2]==tab and
    #AuctionHouseFrame.Tabs==3,
    "separate Browser tab is positioned after Market without editing native tabs")
assert(tab and pane and pane.parent==AuctionHouseFrame,
    "AuctionSense is built directly inside Blizzard's auction house")
assert(tab.selected==false and buy.selected==true,
    "first Auction House opening shows Buy, never prehighlights Market")
if AuctionHouseFrame.hooks and AuctionHouseFrame.hooks.OnShow then
    AuctionHouseFrame.hooks.OnShow(AuctionHouseFrame)
end
assert(not tab.selected and buy.selected,
    "reopening AH keeps Blizzard's Buy highlight authoritative")
assert(AuctionHouseFrame.ChalkBoxAuctionSensePane==nil
    and pane.template=="InsetFrameTemplate",
    "Market uses native-looking art without writing custom data on AH")
local matchingAtlas=false
for _,v in ipairs(allFrames) do
    if v.kind=="Texture" and v.parent==pane and
        v.atlas=="auctionhouse-background-index" then
        matchingAtlas=true
    end
end
assert(matchingAtlas,"Market uses the same auctionhouse-background-index artwork as native Browse")
assert(tab.template=="AuctionHouseFrameDisplayModeTabTemplate" and
    tab.text=="Market" and tab.w==122,
    "Market tab reserves enough width to avoid the client's Ma... truncation")
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
        and f.w==735 and f.h==22 then rows[#rows+1]=f end
end
for _,font in ipairs(fonts) do
    if font.parent==pane and font.point and
        font.point[1]=="BOTTOMLEFT" and font.point[5]==12 then
        footer=font
    end
end
assert(#rows==7 and footer and previousButton and nextButton,
    "rows, pager, and scan disclaimer all exist within the native pane")
assert(rows[1].w==735 and rows[1].h==22
    and nextButton.point[1]=="BOTTOMRIGHT",
    "columns fill the native AH body; Next is aligned to the right edge")
assert(rows[1].point[5]==-157 and rows[7].point[5]==-301,
    "compact rows share a fixed 24px rhythm")
assert(previousButton.point[1]=="BOTTOMLEFT"
    and nextButton.point[1]=="BOTTOMRIGHT"
    and previousButton.point[5]==34 and nextButton.point[5]==34
    and footer.point[5]==12,
    "paging and notes anchor to the pane bottom, not a hard-coded height")
local function VisibleRows()
    local n=0
    for _,row in ipairs(rows) do if row.shown then n=n+1 end end
    return n
end
assert(nativeRegistryEdits==0,"never touch protected Blizzard tab registry")
local modeWritesBeforeMarket=nativeModeWrites
assert(ChalkBox_AuctionOpen() and pane.shown and tab.selected
    and not buy.selected and not sell.selected and not auctions.selected,
    "Market alone has the selected highlight while Market is visible")
assert(AuctionHouseFrame:GetDisplayMode()==AuctionHouseFrameDisplayMode.Buy
    and nativeModeWrites==modeWritesBeforeMarket,
    "Market must NOT call native SetDisplayMode or alter AH displayMode")
UseSoulboundBagItem()
assert(protectedItemUses==1,
    "using Cozy Sleeping Bag while AH is open remains permitted after Market")
assert(not AuctionHouseFrame.BrowseResultsFrame.shown
    and not AuctionHouseFrame.SearchBar.shown
    and not AuctionHouseFrame.CategoriesList.shown,
    "Blizzard's own Browse controls are hidden, not overlapped by dark sheet")
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
assert(fullScans==0 and browseScans==0 and chartReads==0 and
    Text("Click an item to view its trend"),
    "inline preview is idle until a player selects an item")
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
assert(deMarketReads[#deMarketReads]==2589,
    "Market item hover includes read-only DE intelligence without changing scan data")
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
assert(type(hoverRow.scripts.OnMouseDown)=="function",
    "Market rows are explicitly selectable without native AH handlers")
hoverRow.scripts.OnMouseDown(hoverRow,"RightButton")
assert(chartReads==0,"right-click does not select a history graph")
hoverRow.scripts.OnMouseDown(hoverRow,"LeftButton")
assert(chartReads==1 and Text("Linen Cloth")
    and Text("LOW 13s 50c  |  3 scans") and
    rows[1].selectedBack and rows[1].selectedBack.shown,
    "click displays the latest real low ask, scan count and a subtle row highlight")
local preview=FindFrame("ChalkBoxAuctionPricePreview")
assert(preview and preview.w==232 and preview.h==80 and
    preview.point[1]=="TOPRIGHT" and preview.point[5]==-5,
    "polished preview preserves screenshot-verified geometry without overlapping controls")
preview.scripts.OnEnter(preview)
assert(tip.shown and tip.lines[1].text=="Linen Cloth" and
    tip.lines[2].text:find("Latest low ask: 13s 50c",1,true),
    "hovering the chart explains the real low-ask samples and full item title")
preview.scripts.OnLeave(preview)
local dots,bars=0,0
local sampleDot
for _,widget in ipairs(allFrames) do
    if widget.priceSample then
        dots=dots+1
        sampleDot=sampleDot or widget
    end
    if widget.kind=="Texture" and widget.parent and
        widget.parent.parent==pane and widget.w==5 and widget.shown then
        bars=bars+1
    end
end
assert(dots==3 and bars==3,
    "compact preview plots all three recorded samples with texture fallback")
sampleDot.scripts.OnEnter(sampleDot)
assert(tip.shown and tip.lines[2].text=="Lowest ask per unit: 15s 0c",
    "price dots provide real scan price details on hover")
sampleDot.scripts.OnLeave()
assert(not tip.shown and browseScans==0 and fullScans==0 and
    nativeModeWrites==modeWritesBeforeMarket,
    "preview is read-only and does not taint auction trading state")
history[3].low=1400
status.scannedAt=stamp+3
pane.scripts.OnUpdate(pane,1.2)
assert(chartReads==2 and Text("LOW 14s 0c  |  3 scans"),
    "completed scan update redraws latest low ask without a new query")
chartName="Amber Hoop of the Knight"
chartMixed=true
status.scannedAt=stamp+4
pane.scripts.OnUpdate(pane,1.2)
assert(Text("Amber Hoop of the Knight") and
    Text("LOW 14s 0c  |  3 scans  |  MIXED"),
    "compact chart displays full screenshot item name and visibly flags mixed variants")
preview.scripts.OnEnter(preview)
assert(tip.shown and tip.lines[1].text=="Amber Hoop of the Knight"
    and tip.lines[3].text:find("not be comparable",1,true),
    "mixed-variant tooltip prevents treating unlike gear as comparable prices")
preview.scripts.OnLeave(preview)
chartName="Linen Cloth";chartMixed=false
-- My Items and Sales are subviews INSIDE Market; never touch secure
-- native auction displayMode or Blizzard's native tab registry.
local modeBefore=nativeModeWrites
Button("My Items"):Click()
assert(Text("Click an item to view its trend") and
    rows[1].selectedBack and not rows[1].selectedBack.shown,
    "changing subviews resets stale chart selection and its row background")
rows[1].scripts.OnMouseDown(rows[1],"LeftButton")
assert(Text("No saved scan for this item"),
    "item without recorded market history has an honest empty state")
assert(Text("DE / ITEM") and Text("IN BAG") and Text("My Test Green")
    and bagsRead>0 and rows[1].marketView=="bags",
    "My Items integrates bag/DE appraisal into native Market frame")
rows[1].scripts.OnEnter(rows[1])
local hasBag,hasDE=false,false
for _,entry in ipairs(tip.lines) do
    if entry.text=="In your bags" and entry.value=="2" then hasBag=true end
    if entry.text=="DE estimate / item" and entry.value=="15s 0c" then
        hasDE=true
    end
end
assert(hasBag and hasDE and tip.shown,"My Items hover compares unit, vendor and DE")
rows[1].scripts.OnLeave()
Button("Sales & Stats"):Click()
assert(Text("GROSS") and Text("PROCEEDS") and
    Text("Sold Linen") and salesRead>0 and
    rows[1].marketView=="sales",
    "Sales & Stats lists only verified seller-mail receipts")
rows[1].scripts.OnEnter(rows[1])
local hasProceeds,hasFee=false,false
for _,entry in ipairs(tip.lines) do
    if entry.text=="Invoice proceeds" and entry.value=="96s 0c" then
        hasProceeds=true
    elseif entry.text=="House cut" and entry.value=="6s 0c" then
        hasFee=true
    end
end
assert(hasProceeds and hasFee,"sale hover includes invoice proceeds and AH cut")
rows[1].scripts.OnLeave()
Button("Prices"):Click()
assert(Text("AVG ASK") and rows[1].marketView=="market"
    and rows[1].marketData.itemID==2589,
    "returning to Prices restores original Market view without losing data")
assert(nativeModeWrites==modeBefore and nativeRegistryEdits==0
    and AuctionHouseFrame:GetDisplayMode()==AuctionHouseFrameDisplayMode.Buy,
    "switching internal Market views never mutates Blizzard trading state")
UseSoulboundBagItem()
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
status.busy=true;status.mode="full";status.phase="waiting";status.waitSeconds=401
pane.scripts.OnUpdate(pane,1.2)
assert(Text("401s elapsed  ·  awaiting server"),
    "long waits show elapsed time, not invented receiving progress")
status.phase="settling";status.reportedListings=200002
pane.scripts.OnUpdate(pane,1.2)
assert(Text("200002 listings arriving  ·  confirming total"),
    "full scans show the real count while receiving the snapshot")
status.phase="reading";status.totalListings=200002
status.processedListings=5600;status.progress=2
pane.scripts.OnUpdate(pane,1.2)
assert(Text("5600 / 200002 auctions  ·  2%"),
    "full scans show actual processed listings and percentage")
status.busy=false;status.phase=nil
buy:Click()
assert(not pane.shown and not tab.selected and buy.selected
    and not sell.selected and not auctions.selected,
    "first native Buy click from Market immediately restores Buy highlight")
assert(AuctionHouseFrame.BrowseResultsFrame.shown
    and AuctionHouseFrame.SearchBar.shown
    and AuctionHouseFrame:GetDisplayMode()==AuctionHouseFrameDisplayMode.Buy,
    "clicking native Buy restores the same display mode's hidden frames")
UseSoulboundBagItem()
assert(protectedItemUses==3,
    "bag use remains permitted after switching Market subviews and leaving AH")
tab:Click()
assert(pane.shown and not AuctionHouseFrame.BrowseResultsFrame.shown,
    "returning to Market hides the native Buy screen again")
assert(nativeModeWrites==modeWritesBeforeMarket+1,
    "opening Market does not call SetDisplayMode after native Buy click")
sell:Click()
assert(not pane.shown and sell.selected and not tab.selected
    and not buy.selected and not auctions.selected,
    "first native Sell click from Market immediately restores Sell highlight")
assert(AuctionHouseFrame.ItemSellFrame.shown
    and AuctionHouseFrame:GetDisplayMode()==AuctionHouseFrameDisplayMode.Sell,
    "native Sell owns its untainted mode and shows real auction controls")
tab:Click()
assert(pane.shown and not AuctionHouseFrame.ItemSellFrame.shown
    and AuctionHouseFrame:GetDisplayMode()==AuctionHouseFrameDisplayMode.Sell,
    "Market safely overlays Sell without changing native Sell state")
auctions:Click()
assert(not pane.shown and auctions.selected and not tab.selected
    and not buy.selected and not sell.selected,
    "first Auctions click from Market immediately restores its highlight")
assert(AuctionHouseFrame.AuctionsFrame.shown
    and AuctionHouseFrame:GetDisplayMode()==AuctionHouseFrameDisplayMode.Auctions,
    "native Auctions tab retains Blizzard's state and visible controls")
-- Opening and closing Market within the SAME native mode restores frames
-- even when SetDisplayMode short-circuits because the mode is unchanged.
tab:Click()
assert(pane.shown and not AuctionHouseFrame.AuctionsFrame.shown)
ChalkBox_AuctionHide()
assert(not pane.shown and AuctionHouseFrame.AuctionsFrame.shown,
    "closing Market restores Blizzard native subframes without changing mode")
assert(nativeRegistryEdits==0,"no protected PanelTemplates mutations")
-- The new Browser is a proper native-looking sibling tab, NOT a floating
-- item-tooltip companion. Rows choose market history silently on hover.
local nativeBeforeBrowser=nativeModeWrites
browserTab:Click()
assert(browserPane.shown and not pane.shown and browserTab.selected
    and not tab.selected and not auctions.selected
    and not AuctionHouseFrame.AuctionsFrame.shown,
    "Browser displays its own framed list and chart without native overlays")
assert(nativeModeWrites==nativeBeforeBrowser and nativeRegistryEdits==0
    and #AuctionHouseFrame.Tabs==3,
    "new Browser never mutates protected displayMode or tab registry")
local browserRows={}
for _,v in ipairs(allFrames) do
    if v.parent==browserPane and v.kind=="Frame" and v.w==360
        and v.h==22 then browserRows[#browserRows+1]=v end
end
assert(#browserRows==8 and browserRows[1].shown and
    browserRows[1].data.itemID==2589,
    "Browser offers paginated read-only saved results on the left")
local beforeHistory=chartReads
tip.shown=false
browserRows[1].scripts.OnEnter(browserRows[1])
assert(not tip.shown and not GameTooltip.shown
    and chartReads==beforeHistory,
    "hovering Browser results never invokes item/equipment comparison tooltips")
browserRows[1].scripts.OnMouseDown(browserRows[1],"LeftButton")
assert(ChalkBox_AuctionBrowserStatus().pinned
    and ChalkBox_AuctionBrowserStatus().selectedID==2589,
    "left-clicking a Browser result pins its existing chart")
assert(ChalkBox_AuctionBrowserSelect("|Hitem:2589:0|h[Linen Cloth]|h"),
    "deliberate selection accepts an item link without opening Blizzard tooltips")
buy:Click()
assert(not browserPane.shown and not browserTab.selected and
    buy.selected and AuctionHouseFrame.BrowseResultsFrame.shown,
    "native Buy immediately restores Blizzard controls from Browser")
UseSoulboundBagItem()
browserTab:Click()
assert(browserPane.shown and browserTab.selected)
tab:Click()
assert(pane.shown and not browserPane.shown and tab.selected
    and not browserTab.selected,
    "switching Browser to Market swaps addon panes without native mode writes")
assert(nativeModeWrites==nativeBeforeBrowser+1,
    "only the user's native Buy click changed Blizzard displayMode")
ChalkBox_AuctionHide()
assert(not browserPane.shown and not pane.shown
    and AuctionHouseFrame.BrowseResultsFrame.shown,
    "closing either custom pane restores Blizzard subframes")
assert(nativeRegistryEdits==0,
    "both addon tabs preserve protected UI ownership")
-- Browser pagination and safe filters must use saved data, not native AH
-- result rows or extra browsing APIs, even on a short 316px AH pane.
local testItems={}
for i=1,13 do
    testItems[i]={name=("Test Item %02d"):format(i),itemID=6000+i,
        low=1000+i*50,quantity=i,mixed=i==2 or i==5}
end
local browserReads=0
_G.ChalkBox_AuctionRows=function(query)
    browserReads=browserReads+1
    local found={}
    for _,item in ipairs(testItems) do
        if query=="" or item.name:lower():find(query:lower(),1,true) then
            found[#found+1]=item
        end
    end
    return found
end
browserPane.h=316
status.scannedAt=stamp+201
browserTab:Click()
local function BrowserVisible()
    local n=0
    for _,row in ipairs(browserRows) do
        if row.shown then n=n+1 end
    end
    return n
end
assert(BrowserVisible()==5 and Text("Page 1 / 3"),
    "compact AH Browser dynamically paginates instead of covering footer")
local function BrowserButton(label)
    for _,widget in ipairs(allFrames) do
        if widget.parent==browserPane and widget.kind=="Button" and
            widget.text==label then return widget end
    end
    error("missing Browser control "..label)
end
local function BrowserClick(label)
    local b=BrowserButton(label)
    b:Click()
end
BrowserClick("Next")
assert(Text("Page 2 / 3") and BrowserVisible()==5 and
    browserRows[1].data.itemID==6006,
    "next page shows actual subsequent saved items")
BrowserClick("All items")
assert(BrowserButton("Mixed gear") and BrowserVisible()==2 and
    browserRows[1].data.itemID==6002 and
    browserRows[2].data.itemID==6005 and
    Text("Page 1 / 1"),
    "mixed variant filter acts only on recorded variant evidence")
BrowserClick("Mixed gear")
BrowserClick("Name")
assert(BrowserButton("Low ↑") and browserRows[1].data.itemID==6001,
    "saved low-price ascending sort is stable and data driven")
BrowserClick("Low ↑")
assert(BrowserButton("Low ↓") and browserRows[1].data.itemID==6013,
    "descending market sort never requests live Blizzard auctions")
local edit
for _,widget in ipairs(allFrames) do
    if widget.parent==browserPane and widget.kind=="EditBox" then
        edit=widget;break
    end
end
assert(edit and edit.scripts.OnTextChanged)
edit:SetText("nothing-matches")
edit.scripts.OnTextChanged(edit)
assert(BrowserVisible()==0 and Text("Choose an item") and
    Text("Past low asking prices will appear here"),
    "empty search clears the old chart and visible rows without inventing data")
edit:SetText("")
edit.scripts.OnTextChanged(edit)
assert(BrowserVisible()==5 and Text("Page 1 / 3"),
    "clearing search restores saved market browsing")
local readsBefore=browserReads
browserPane.scripts.OnUpdate(browserPane,1.1)
assert(browserReads==readsBefore and fullScans==1 and browseScans==1,
    "passive refresh reuses cached sorted market data without scanning")
assert(nativeModeWrites==nativeBeforeBrowser+1 and nativeRegistryEdits==0,
    "filtering and graphing never modify native auction state")
ChalkBox_AuctionHide()
-- Regression: opening Browser DIRECTLY from native Buy must pass through
-- the same proven Market overlay path, not just highlight the Browser tab.
local marketPrimed=0
local originalMarketShow=pane.Show
pane.Show=function(self)
    marketPrimed=marketPrimed+1
    originalMarketShow(self)
end
buy:Click()
local modeBeforeDirect=nativeModeWrites
browserTab:Click()
assert(browserPane.shown and not pane.shown and browserTab.selected
    and not AuctionHouseFrame.BrowseResultsFrame.shown and
    marketPrimed>=1 and nativeModeWrites==modeBeforeDirect,
    "Browser directly from Buy hides the actual native page on first click")
pane.Show=originalMarketShow

-- Real client APIs expose loaded browse summaries WITHOUT sending a query.
-- Browser compares those unit asks with our OWN historical saved baseline.
local nativeReads,queries,bids=0,0,0
_G.C_AuctionHouse={
    GetBrowseResults=function()
        nativeReads=nativeReads+1
        return {
            {itemKey={itemID=2589,itemSuffix=0,itemLevel=0},
                minPrice=1000,totalQuantity=8},
            {itemKey={itemID=6003,itemSuffix=55,itemLevel=32},
                minPrice=2300,totalQuantity=1}
        }
    end,
    GetItemKeyInfo=function(key)
        return {itemName=key.itemID==2589 and "Linen Cloth" or
            "Variant Gear"}
    end,
    SendBrowseQuery=function() queries=queries+1 end,
    PlaceBid=function() bids=bids+1 end,
}
_G.ChalkBox_AuctionPrice=function(id)
    if id==2589 then return {itemID=2589,name="Linen Cloth",
        low=1500,age=120,stale=false,mixed=false} end
end
BrowserClick("Saved")
local linenRow,gearRow
for _,row in ipairs(browserRows) do
    if row.data and row.data.itemID==2589 then linenRow=row end
    if row.data and row.data.itemID==6003 then gearRow=row end
end
assert(BrowserButton("AH Results") and BrowserVisible()==2 and
    linenRow and linenRow.data.low==1000 and gearRow,
    "Current AH mode displays loaded summaries independent of price sort")
linenRow.scripts.OnEnter(linenRow)
assert(Text("10s 0c") and Text("-33.3% VS SCAN") and
    not tip.shown and queries==0 and bids==0,
    "current ask compared to saved 15s baseline without item tooltip or queries")
gearRow.scripts.OnEnter(gearRow)
assert(gearRow.data.variantSpecific and Text("VARIANTS"),
    "variant-specific equipment is not compared to aggregated old itemID prices")
assert(nativeReads>=1 and queries==0 and bids==0
    and nativeRegistryEdits==0 and nativeModeWrites==modeBeforeDirect,
    "native loaded results are observed only; AH trading is unmodified")
BrowserClick("AH Results")
assert(BrowserButton("Saved") and BrowserVisible()==5
    and browserRows[1].data.itemID==6013,
    "returning to saved mode recovers stored market history immediately")
local browseReadBefore=nativeReads
BrowserClick("Search AH")
assert(queries==1 and bids==0 and BrowserButton("AH Results") and
    BrowserVisible()==0 and nativeReads==browseReadBefore and
    Text("Searching the Auction House"),
    "explicit Search AH starts one user-triggered query and hides stale results")
local nativeListener
for _,candidate in ipairs(allFrames) do
    if candidate.kind=="Frame" and candidate.scripts.OnEvent then
        nativeListener=candidate
    end
end
assert(nativeListener,"Browser has a read-only native-results event listener")
nativeListener.scripts.OnEvent(nativeListener,
    "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
assert(BrowserVisible()==2 and nativeReads>browseReadBefore and
    queries==1 and bids==0,
    "new native browse results populate after the actual client event")
ChalkBox_AuctionHide()
print("PASS: Browser first-click native visibility, actual loaded AH summaries compared with saved scans, variant safety, and no buying/query side effects")
