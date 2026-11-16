-- Stock-style Price Lens regression. Always read-only; native AH Buy is
-- authoritative and this companion never writes Blizzard trading state.
local frames,fonts={},{}
local function Frame(kind,name,parent,template)
    local f={kind=kind,name=name,parent=parent,template=template,
        shown=true,scripts={}}
    function f:SetSize(w,h) self.w,self.h=w,h end
    function f:SetPoint(...) self.point={...} end
    function f:ClearAllPoints() self.point=nil end
    function f:GetParent() return self.parent end
    function f:SetText(s) self.text=s end
    function f:GetText() return self.text end
    function f:SetTextColor(...) self.color={...} end
    function f:SetJustifyH() end
    function f:SetFrameStrata(s) self.strata=s end
    function f:SetFrameLevel(level) self.level=level end
    function f:GetFrameLevel() return self.level or 10 end
    function f:GetRight() return self.right end
    function f:SetClampedToScreen(value) self.clamped=value end
    function f:SetMovable(value) self.movable=value end
    function f:EnableMouse() end
    function f:RegisterForDrag(...) self.drag={...} end
    function f:StartMoving() self.moving=true end
    function f:StopMovingOrSizing() self.moving=false end
    function f:SetAutoFocus() end
    function f:SetMaxLetters(n) self.maxLetters=n end
    function f:ClearFocus() end
    function f:SetScript(event,fn) self.scripts[event]=fn end
    function f:HookScript(event,fn)
        self.hooks=self.hooks or {};self.hooks[event]=fn
    end
    function f:Show()
        self.shown=true
        if self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    function f:Hide()
        self.shown=false
        if self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function f:IsShown() return self.shown end
    function f:CreateTexture()
        local t=Frame("Texture",nil,self)
        function t:SetAllPoints() end
        function t:SetTexture() end
        function t:SetVertexColor(...) self.color={...} end
        function t:SetColorTexture(...) self.color={...} end
        return t
    end
    function f:CreateFontString()
        local t=Frame("Font",nil,self)
        fonts[#fonts+1]=t
        return t
    end
    frames[#frames+1]=f
    return f
end
_G.CreateFrame=Frame
_G.UIParent=Frame("Root")
function UIParent:GetRight() return 1648 end
_G.AuctionHouseFrame=Frame("Frame","AuctionHouseFrame",UIParent)
AuctionHouseFrame.right=650
AuctionHouseFrame.level=25
local nativeBuy=Frame("Button","Buy",AuctionHouseFrame)
local nativeSell=Frame("Button","Sell",AuctionHouseFrame)
local nativeAuctions=Frame("Button","Auctions",AuctionHouseFrame)
AuctionHouseFrame.Tabs={nativeBuy,nativeSell,nativeAuctions}
local writes,scans,purchases=0,0,0
function AuctionHouseFrame:SetDisplayMode() writes=writes+1 end
_G.C_AuctionHouse={
    ReplicateItems=function() scans=scans+1 end,
    PlaceBid=function() purchases=purchases+1 end,
}
local function Find(name)
    for _,f in ipairs(frames) do if f.name==name then return f end end
end
local function Text(value)
    for _,f in ipairs(fonts) do if f.text==value then return true end end
end
local function Button(value)
    for _,f in ipairs(frames) do
        if f.kind=="Button" and f.text==value then return f end
    end
    error("Button missing: "..value)
end
local tool={owner=nil,lines={},shown=false}
function tool:GetOwner() return self.owner end
function tool:SetOwner(owner) self.owner=owner end
function tool:ClearLines() self.lines={} end
function tool:AddLine(text) self.lines[#self.lines+1]=text end
function tool:Show() self.shown=true end
function tool:Hide() self.shown=false end
_G.GameTooltip=tool
local historyReads,priceReads,rowsRead=0,0,0
local stamp=1700000000
local history={
    {t=stamp,low=10000},
    {t=stamp+86400,low=8000},
    {t=stamp+172800,low=9500}
}
local currentMixed,currentStale=false,false
_G.ChalkBox_AuctionChartHistory=function(itemID)
    historyReads=historyReads+1
    if itemID~=2589 then return nil end
    local pts={}
    for i,p in ipairs(history) do pts[i]={t=p.t,low=p.low} end
    return {itemID=2589,name="Wool Cloth",realm="Whitemane",
        faction="Alliance",points=pts,mixed=currentMixed}
end
_G.ChalkBox_AuctionPrice=function(itemID)
    priceReads=priceReads+1
    if itemID~=2589 then return nil end
    return {low=history[#history].low,age=currentStale and
        172800 or 100,mixed=currentMixed,stale=currentStale}
end
local scannedAt=stamp+172800
_G.ChalkBox_AuctionStatus=function()
    return {scannedAt=scannedAt,marketKey="Whitemane:Alliance"}
end
_G.ChalkBox_AuctionRows=function(query)
    rowsRead=rowsRead+1
    if query:lower():find("wool",1,true) then
        return {{itemID=2589,name="Wool Cloth"}}
    end
    if query:lower():find("amber",1,true) then
        return {{itemID=111,name="Amber Hoop of the Knight"},
            {itemID=112,name="Amber Hoop of the Eagle"}}
    end
    return {}
end
assert(loadfile("AuctionPriceLens.lua"))("ChalkBox")
assert(not ChalkBox_PriceLensStatus().attached)
assert(ChalkBox_PriceLensAttach())
local panel=Find("ChalkBoxPriceLens")
local toggle=Find("ChalkBoxPriceLensButton")
assert(panel and toggle and panel.parent==AuctionHouseFrame
    and panel.w==326 and panel.h==296 and not panel:IsShown()
    and toggle.point[2]==AuctionHouseFrame,
    "optional Price Lens attaches outside native Buy and starts closed")
assert(#AuctionHouseFrame.Tabs==3 and AuctionHouseFrame.Tabs[1]==nativeBuy
    and writes==0 and scans==0 and purchases==0,
    "launcher must not change native trading modes, tabs or send auctions")
assert(ChalkBox_PriceLensToggle(true))
assert(panel:IsShown() and Text("Choose an item to inspect"))
local buyRow=Frame("Button","NativeBuyResult",Frame("Frame",nil,AuctionHouseFrame))
local otherItem=Frame("Button","BagItem",UIParent)
tool.owner=otherItem
assert(not ChalkBox_PriceLensObserveTooltip(tool,"item:2589")
    and not ChalkBox_PriceLensStatus().selectedID,
    "ordinary bag tooltips never override research item selection")
tool.owner=buyRow
assert(ChalkBox_PriceLensObserveTooltip(tool,
    "|Hitem:2589:0|h[Wool Cloth]|h"))
local status=ChalkBox_PriceLensStatus()
assert(status.selectedID==2589 and not status.pinned
    and Text("Wool Cloth") and Text("95s 0c")
    and Text("-5.0% ASK") and Text("LOW 80s 0c   HIGH 1g 0s 0c"),
    "valid AH tooltip records chart values, low/high and correct percent delta")
local plotted=0
for _,f in ipairs(frames) do if f.sample then plotted=plotted+1 end end
assert(plotted==3,"native-line fallback renders real three scan observations")
assert(historyReads==1 and priceReads==1,
    "each selected item chart is fetched only once and never rescanned")
local sample
for _,f in ipairs(frames) do if f.sample then sample=f;break end end
sample.scripts.OnEnter(sample)
assert(tool.shown and table.concat(tool.lines," "):find(
    "Lowest observed ask / unit: 1g 0s 0c",1,true),
    "chart dot hover shows actual saved timestamp and unit price")
sample.scripts.OnLeave(sample)
assert(not tool.shown)
Button("Pin").scripts.OnClick()
assert(ChalkBox_PriceLensStatus().pinned and Text("Wool Cloth"))
tool.owner=buyRow
assert(not ChalkBox_PriceLensObserveTooltip(tool,"item:777")
    and ChalkBox_PriceLensStatus().selectedID==2589,
    "pinned graph stays visible while hovering other auction items")
Button("Unpin").scripts.OnClick()
assert(not ChalkBox_PriceLensStatus().pinned)
assert(ChalkBox_PriceLensObserveTooltip(tool,"item:777")
    and ChalkBox_PriceLensStatus().selectedID==777
    and Text("No saved history for this realm / faction"),
    "items with no saved observations display a safe empty state")
assert(ChalkBox_PriceLensCommand("wool")
    and ChalkBox_PriceLensStatus().selectedID==2589,
    "manual search works even if Forever doesn't expose AH tooltips")
assert(not ChalkBox_PriceLensCommand("amber")
    and ChalkBox_PriceLensStatus().selectedID==2589
    and Text("Several matches. Refine your search."),
    "ambiguous saved-name search never picks an arbitrary gear variant")
currentMixed=true
scannedAt=scannedAt+1
ChalkBox_PriceLensRefresh()
assert(Text("MIXED GEAR"),"mixed gear never claims a like-for-like change")
currentMixed=false;currentStale=true
scannedAt=scannedAt+1
ChalkBox_PriceLensRefresh()
local footer
for _,f in ipairs(fonts) do
    if type(f.text)=="string" and f.text:find("STALE",1,true)
        then footer=f.text end
end
assert(footer and footer:find("STALE",1,true),
    "stale samples are labeled, not presented as a live buying quote")
-- Rendering never issues another auction scan, sale or bid.
assert(writes==0 and scans==0 and purchases==0 and
    #AuctionHouseFrame.Tabs==3)
assert(ChalkBox_PriceLensCommand("off") and not panel:IsShown())
assert(ChalkBox_PriceLensToggle(true))
if AuctionHouseFrame.hooks and AuctionHouseFrame.hooks.OnHide then
    AuctionHouseFrame.hooks.OnHide()
end
assert(not panel:IsShown() and not ChalkBox_PriceLensStatus().pinned,
    "closing the AH hides research panel and releases its pin")
print("PASS: independent Price Lens, real price-history chart, tooltip scope, pin, search, mixed and stale, no scan/transactions/native mode changes")
