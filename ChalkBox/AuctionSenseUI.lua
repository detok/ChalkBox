-- AuctionSense market browser: clear prices with source, age and scan state.
-- Separate from Blizzard's trading controls: display only, never transact.
local WINDOW_WIDTH,WINDOW_HEIGHT=660,482
local PER_PAGE=7
local frame,labels=nil,{}
local searchText,page="",1
local seconds=0
local cachedRows,cachedMarket,cachedTime,cachedSearch={},"",0,nil

local function Font(parent,style,x,y,width)
    local label=parent:CreateFontString(nil,"OVERLAY",style or "GameFontHighlight")
    label:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    label:SetWidth(width or 180)
    if label.SetJustifyH then label:SetJustifyH("LEFT") end
    if label.SetTextColor then label:SetTextColor(0.94,0.94,0.93,1) end
    return label
end
local function Button(parent,title,x,y,width,callback)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(width,25)
    b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    b:SetText(title)
    b:SetScript("OnClick",callback)
    return b
end
local function Coin(value)
    if type(value)~="number" or value<0 then return "--" end
    value=math.floor(value+0.5)
    local gold=math.floor(value/10000)
    local silver=math.floor(value%10000/100)
    local copper=value%100
    if gold>0 then return ("%dg %ds %dc"):format(gold,silver,copper) end
    if silver>0 then return ("%ds %dc"):format(silver,copper) end
    return copper.."c"
end
local function Age(secondsOld)
    if not secondsOld then return "Never" end
    if secondsOld<60 then return "Just now" end
    if secondsOld<3600 then return math.floor(secondsOld/60).."m ago" end
    if secondsOld<86400 then return math.floor(secondsOld/3600).."h ago" end
    return math.floor(secondsOld/86400).."d ago"
end
local function Refresh()
    if not frame or not frame.IsShown or not frame:IsShown() then return end
    local status=ChalkBox_AuctionStatus and ChalkBox_AuctionStatus() or {}
    local market=status.realm and (status.realm.." / "..(status.faction or "?"))
        or "Market unavailable"
    labels.market:SetText(market)
    labels.status:SetText(status.state or "Ready")
    labels.progress:SetText(status.busy and
        ("Reading "..tostring(status.progress or 0).."%") or
        (status.scannedAt and ("Last scan "..Age(status.age)) or "No scan yet"))
    local cooldown=status.cooldown or 0
    labels.cooldown:SetText(cooldown>0 and
        ("Next full scan in "..math.ceil(cooldown/60).."m") or
        (status.open and "Scan available" or "Visit an auctioneer to scan"))
    labels.details:SetText(("%d items  /  %d auctions"):format(
        status.items or 0,status.auctions or 0))
    labels.info:SetText(status.age and status.age>86400 and
        "Old data — check the scan date before using prices." or
        "Low / average are asking prices per item, not completed sales.")
    if cachedSearch~=searchText or
        cachedMarket~=(status.marketKey or "") or
        cachedTime~=(status.scannedAt or 0) then
        cachedMarket=status.marketKey or ""
        cachedTime=status.scannedAt or 0
        cachedSearch=searchText
        cachedRows=ChalkBox_AuctionRows and
            ChalkBox_AuctionRows(searchText,12000) or {}
    end
    local entries=cachedRows
    local maxPages=math.max(1,math.ceil(#entries/PER_PAGE))
    page=math.max(1,math.min(page,maxPages))
    local start=(page-1)*PER_PAGE
    for i,row in ipairs(labels.rows) do
        local item=entries[start+i]
        if item then
            row.name:SetText(item.name or ("Item #"..tostring(item.itemID)))
            row.low:SetText(Coin(item.low))
            row.average:SetText(Coin(item.average))
            row.listings:SetText(tostring(item.listings).." listings")
            row.note:SetText(item.mixed and
                "Variants mixed — confirm the exact item before selling" or
                (tostring(item.quantity or 0).." units available"))
            row.frame:Show()
        else
            row.frame:Hide()
        end
    end
    labels.page:SetText(("Page %d / %d"):format(page,maxPages))
    if labels.scan and labels.scan.SetEnabled then
        labels.scan:SetEnabled(status.open and status.available and
            not status.busy and cooldown==0)
    end
end
function ChalkBox_AuctionRefreshUI() Refresh() end
local function Ensure()
    if frame then return end
    local f=CreateFrame("Frame","ChalkBoxAuctionSenseWindow",UIParent)
    f:SetSize(WINDOW_WIDTH,WINDOW_HEIGHT)
    f:SetPoint("CENTER",UIParent,"CENTER",0,0)
    if f.SetFrameStrata then f:SetFrameStrata("DIALOG") end
    if f.SetFrameLevel then f:SetFrameLevel(220) end
    if f.SetToplevel then f:SetToplevel(true) end
    if f.EnableMouse then f:EnableMouse(true) end
    if f.SetMovable then f:SetMovable(true) end
    if f.RegisterForDrag then f:RegisterForDrag("LeftButton") end
    f:SetScript("OnDragStart",function(self)
        if type(InCombatLockdown)~="function" or not InCombatLockdown() then
            if self.StartMoving then self:StartMoving() end
        end
    end)
    f:SetScript("OnDragStop",function(self)
        if self.StopMovingOrSizing then self:StopMovingOrSizing() end
    end)
    local background=f:CreateTexture(nil,"BACKGROUND")
    background:SetAllPoints(f)
    if background.SetTexture and background.SetVertexColor then
        background:SetTexture("Interface\\Buttons\\WHITE8X8")
        background:SetVertexColor(0.025,0.036,0.046,0.98)
    elseif background.SetColorTexture then
        background:SetColorTexture(0.025,0.036,0.046,0.98)
    end
    labels.title=Font(f,"GameFontNormalHuge",22,-18,420)
    labels.title:SetText("AuctionSense")
    labels.market=Font(f,"GameFontHighlightSmall",23,-52,420)
    labels.status=Font(f,"GameFontNormal",22,-83,450)
    labels.progress=Font(f,"GameFontHighlight",23,-109,255)
    labels.cooldown=Font(f,"GameFontHighlight",318,-109,310)
    labels.details=Font(f,"GameFontHighlight",23,-135,500)
    Button(f,"Close",546,-16,88,function() f:Hide() end)
    labels.scan=Button(f,"Scan Market",498,-75,136,function()
        if type(ChalkBox_AuctionScan)=="function" then
            local ok,reason=ChalkBox_AuctionScan()
            if not ok then labels.status:SetText(reason or "Scan unavailable") end
            Refresh()
        end
    end)
    local input=CreateFrame("EditBox",nil,f,"InputBoxTemplate")
    input:SetSize(392,24)
    input:SetPoint("TOPLEFT",f,"TOPLEFT",175,-165)
    if input.SetAutoFocus then input:SetAutoFocus(false) end
    if input.SetMaxLetters then input:SetMaxLetters(70) end
    input:SetScript("OnTextChanged",function(self)
        searchText=type(self.GetText)=="function" and self:GetText() or ""
        page=1;Refresh()
    end)
    input:SetScript("OnEscapePressed",function(self)
        if self.ClearFocus then self:ClearFocus() end
    end)
    Font(f,"GameFontNormal",23,-170,148):SetText("Search items")
    Font(f,"GameFontNormal",23,-205,285):SetText("ITEM")
    Font(f,"GameFontNormal",339,-205,102):SetText("LOW")
    Font(f,"GameFontNormal",454,-205,104):SetText("AVG ASK")
    Font(f,"GameFontNormal",568,-205,82):SetText("LISTINGS")
    labels.rows={}
    for i=1,PER_PAGE do
        local y=-226-(i-1)*28
        local row=CreateFrame("Frame",nil,f)
        row:SetSize(622,27)
        row:SetPoint("TOPLEFT",f,"TOPLEFT",20,y)
        local name=Font(row,"GameFontHighlight",4,-1,310)
        local low=Font(row,"GameFontHighlight",315,-1,111)
        local average=Font(row,"GameFontHighlight",430,-1,109)
        local listings=Font(row,"GameFontHighlightSmall",542,-1,89)
        local note=Font(row,"GameFontHighlightSmall",4,-15,615)
        if note.SetTextColor then note:SetTextColor(0.55,0.68,0.70,1) end
        labels.rows[#labels.rows+1]={frame=row,name=name,low=low,
            average=average,listings=listings,note=note}
    end
    Button(f,"Previous",23,-434,115,function()
        page=math.max(1,page-1);Refresh()
    end)
    labels.page=Font(f,"GameFontHighlightSmall",279,-439,110)
    Button(f,"Next",526,-434,112,function()
        page=page+1;Refresh()
    end)
    labels.info=Font(f,"GameFontHighlightSmall",23,-464,610)
    frame=f
    f:SetScript("OnUpdate",function(self,elapsed)
        seconds=seconds+(type(elapsed)=="number" and elapsed or 0)
        if seconds>=1 then seconds=0;Refresh() end
    end)
    f:Hide()
end
function ChalkBox_AuctionOpen()
    Ensure()
    if not frame then return false end
    page=1
    frame:Show()
    if frame.Raise then frame:Raise() end
    Refresh()
    return true
end
