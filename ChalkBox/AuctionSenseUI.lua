-- AuctionSense market browser: clear prices with source, age and scan state.
-- Separate from Blizzard's trading controls: display only, never transact.
local PER_PAGE=7
local frame,tab,host,labels=nil,nil,nil,{}
local searchText,page="",1
local seconds=0
local cachedRows,cachedMarket,cachedTime,cachedSearch={},"",0,nil
local COLOR={
    low={0.39,0.94,0.62},average={0.98,0.79,0.39},
    counts={0.51,0.76,0.98},ready={0.40,0.85,0.75},
    warning={0.98,0.66,0.33},error={0.98,0.45,0.40},
    muted={0.65,0.70,0.73},neutral={0.83,0.86,0.88},
}
local function Tint(label,rgb)
    if label and type(label.SetTextColor)=="function" then
        label:SetTextColor(rgb[1],rgb[2],rgb[3],1)
    end
end
local function StartTooltip(owner,title)
    local tip=GameTooltip
    if not tip or type(tip.SetOwner)~="function" or
        type(tip.AddLine)~="function" then return nil end
    tip:SetOwner(owner,"ANCHOR_RIGHT")
    if type(tip.ClearLines)=="function" then tip:ClearLines() end
    tip:AddLine(title,0.95,0.95,0.93)
    return tip
end
local function Metric(tip,label,value,rgb)
    if type(tip.AddDoubleLine)=="function" then
        tip:AddDoubleLine(label,value,0.79,0.82,0.85,
            rgb[1],rgb[2],rgb[3])
    else
        tip:AddLine(label..": "..value,rgb[1],rgb[2],rgb[3])
    end
end
local function EndTooltip(tip)
    if tip and type(tip.Show)=="function" then tip:Show() end
end
local function HideTooltip()
    if GameTooltip and type(GameTooltip.Hide)=="function" then
        GameTooltip:Hide()
    end
end
local function Hint(button,title,summary,extra)
    button:SetScript("OnEnter",function(self)
        local tip=StartTooltip(self,title)
        if not tip then return end
        tip:AddLine(summary,COLOR.neutral[1],COLOR.neutral[2],
            COLOR.neutral[3])
        if extra then
            tip:AddLine(extra,COLOR.muted[1],COLOR.muted[2],
                COLOR.muted[3])
        end
        EndTooltip(tip)
    end)
    button:SetScript("OnLeave",HideTooltip)
end

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
    Tint(labels.status,status.error and COLOR.error or
        (status.busy and COLOR.warning or COLOR.ready))
    labels.progress:SetText(status.busy and
        (status.mode=="browse" and
            (tostring(status.scannedItems or 0).." items read") or
            ("Full scan "..tostring(status.progress or 0).."%")) or
        (status.scannedAt and ("Last scan "..Age(status.age)) or "No scan yet"))
    local cooldown=status.cooldown or 0
    labels.cooldown:SetText(cooldown>0 and
        ("Full scan  |  "..math.ceil(cooldown/60).."m cooldown") or
        (status.fullAvailable and "Full scan ready" or
        "Full scan unavailable"))
    Tint(labels.cooldown,cooldown>0 and COLOR.warning or
        (status.fullAvailable and COLOR.ready or COLOR.muted))
    labels.details:SetText(("%d items  ·  %s"):format(
        status.items or 0,
        status.source=="browse" and "Browse prices" or
        (status.source=="full" and
            (tostring(status.auctions or 0).." listings") or "No scan")))
    labels.info:SetText(status.error or
        (status.age and status.age>86400 and
            "OLD SCAN  |  Refresh before buying" or
            "Asking prices  ·  not sales"))
    Tint(labels.info,status.error and COLOR.error or
        (status.age and status.age>86400 and COLOR.warning or COLOR.muted))
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
            row.listings:SetText(item.listings and
                (tostring(item.listings).." lots") or "—")
            row.note:SetText(item.mixed and
                "VARIANTS MIXED  |  Verify exact gear" or
                (tostring(item.quantity or 0).." units"))
            Tint(row.note,item.mixed and COLOR.warning or COLOR.muted)
            row.frame.marketData=item
            row.frame:Show()
        else
            row.frame.marketData=nil
            row.frame:Hide()
        end
    end
    labels.page:SetText(("Page %d / %d"):format(page,maxPages))
    if labels.scan and labels.scan.SetEnabled then
        labels.scan:SetEnabled(status.open and status.available and
            not status.busy)
    end
    if labels.fullscan and labels.fullscan.SetEnabled then
        labels.fullscan:SetEnabled(status.open and status.fullAvailable
            and not status.busy and cooldown==0)
    end
end
function ChalkBox_AuctionRefreshUI() Refresh() end
-- The journal is mounted INSIDE Blizzard's AH, not a detached window.
-- No edits to Blizzard's protected Tabs list or PanelTemplates_SetTab.
local function Ensure()
    if frame then return true end
    local ah=AuctionHouseFrame
    if not ah then return false end
    host=ah
    local f=CreateFrame("Frame","ChalkBoxAuctionSensePane",ah)
    -- The stock AH has a title, decorative frame edge and bottom tabs.
    -- Confine our content to its inner body; never cover the footer/tabs.
    f:SetPoint("TOPLEFT",ah,"TOPLEFT",13,-56)
    f:SetPoint("BOTTOMRIGHT",ah,"BOTTOMRIGHT",-13,68)
    if f.SetFrameLevel then
        local base=type(ah.GetFrameLevel)=="function" and
            ah:GetFrameLevel() or 20
        f:SetFrameLevel(base+20)
    end
    if f.EnableMouse then f:EnableMouse(true) end
    local background=f:CreateTexture(nil,"BACKGROUND")
    background:SetAllPoints(f)
    if background.SetColorTexture then
        background:SetColorTexture(0.11,0.085,0.061,0.985)
    elseif background.SetTexture then
        background:SetTexture("Interface\\Buttons\\WHITE8X8")
        if background.SetVertexColor then
            background:SetVertexColor(0.11,0.085,0.061,0.985)
        end
    end
    labels.title=Font(f,"GameFontNormalHuge",20,-9,410)
    labels.title:SetText("AuctionSense")
    labels.market=Font(f,"GameFontHighlightSmall",21,-35,425)
    labels.status=Font(f,"GameFontNormal",20,-56,560)
    labels.progress=Font(f,"GameFontHighlight",21,-78,270)
    labels.cooldown=Font(f,"GameFontHighlight",313,-78,295)
    labels.details=Font(f,"GameFontHighlight",21,-100,545)
    labels.scan=Button(f,"Scan Market",21,-119,140,function()
        if type(ChalkBox_AuctionScan)=="function" then
            local ok,reason=ChalkBox_AuctionScan()
            if not ok then labels.status:SetText(reason or "Browse unavailable") end
            Refresh()
        end
    end)
    Hint(labels.scan,"Scan Market","Browse asking prices","No full-scan cooldown")
    labels.fullscan=Button(f,"Full listings (15m)",172,-119,167,function()
        if type(ChalkBox_AuctionFullScan)=="function" then
            local ok,reason=ChalkBox_AuctionFullScan()
            if not ok then labels.status:SetText(reason or "Full scan unavailable") end
            Refresh()
        end
    end)
    Hint(labels.fullscan,"Full listings","Complete auction listing snapshot",
        "Server limit: once every 15 minutes")
    local input=CreateFrame("EditBox",nil,f,"InputBoxTemplate")
    input:SetSize(224,24)
    input:SetPoint("TOPLEFT",f,"TOPLEFT",386,-120)
    if input.SetAutoFocus then input:SetAutoFocus(false) end
    if input.SetMaxLetters then input:SetMaxLetters(70) end
    input:SetScript("OnTextChanged",function(self)
        searchText=type(self.GetText)=="function" and self:GetText() or ""
        page=1;Refresh()
    end)
    input:SetScript("OnEscapePressed",function(self)
        if self.ClearFocus then self:ClearFocus() end
    end)
    Font(f,"GameFontNormal",345,-126,45):SetText("Find")
    Font(f,"GameFontNormal",21,-156,255):SetText("ITEM")
    local lowHeader=Font(f,"GameFontNormal",316,-156,102)
    lowHeader:SetText("LOW / UNIT")
    Tint(lowHeader,COLOR.low)
    local averageHeader=Font(f,"GameFontNormal",428,-156,104)
    averageHeader:SetText("AVG ASK")
    Tint(averageHeader,COLOR.average)
    local listingHeader=Font(f,"GameFontNormal",541,-156,92)
    listingHeader:SetText("LISTINGS")
    Tint(listingHeader,COLOR.counts)
    labels.rows={}
    for i=1,PER_PAGE do
        local y=-179-(i-1)*24
        local row=CreateFrame("Frame",nil,f)
        row:SetSize(610,23)
        row:SetPoint("TOPLEFT",f,"TOPLEFT",17,y)
        local name=Font(row,"GameFontHighlight",4,-1,287)
        local low=Font(row,"GameFontHighlight",299,-1,102)
        local average=Font(row,"GameFontHighlight",411,-1,102)
        local listings=Font(row,"GameFontHighlightSmall",524,-1,85)
        local note=Font(row,"GameFontHighlightSmall",4,-13,588)
        Tint(low,COLOR.low)
        Tint(average,COLOR.average)
        Tint(listings,COLOR.counts)
        Tint(note,COLOR.muted)
        if type(row.EnableMouse)=="function" then row:EnableMouse(true) end
        row:SetScript("OnEnter",function(self)
            local item=self.marketData
            if not item then return end
            local tip=StartTooltip(self,item.name or
                ("Item #"..tostring(item.itemID)))
            if not tip then return end
            Metric(tip,"Low ask / unit",Coin(item.low),COLOR.low)
            Metric(tip,"Avg ask / unit",Coin(item.average),
                item.average and COLOR.average or COLOR.muted)
            Metric(tip,"Listings",item.listings and
                tostring(item.listings) or "—",COLOR.counts)
            Metric(tip,"Units",item.quantity and
                tostring(item.quantity) or "—",COLOR.neutral)
            local current=ChalkBox_AuctionStatus and
                ChalkBox_AuctionStatus() or {}
            local source=current.source=="browse" and "Browse" or
                (current.source=="full" and "Full listings" or "Unknown")
            tip:AddLine(source.."  |  Updated "..Age(current.age),
                COLOR.muted[1],COLOR.muted[2],COLOR.muted[3])
            if current.realm and current.faction then
                tip:AddLine(current.realm.." / "..current.faction,
                    COLOR.muted[1],COLOR.muted[2],COLOR.muted[3])
            end
            if item.mixed then
                tip:AddLine("VARIANTS MIXED  |  Check exact gear",
                    COLOR.warning[1],COLOR.warning[2],COLOR.warning[3])
            end
            if current.age and current.age>86400 then
                tip:AddLine("OLD SCAN  |  Refresh prices",
                    COLOR.error[1],COLOR.error[2],COLOR.error[3])
            end
            tip:AddLine("Asking prices, not sales",
                COLOR.muted[1],COLOR.muted[2],COLOR.muted[3])
            EndTooltip(tip)
        end)
        row:SetScript("OnLeave",HideTooltip)
        labels.rows[#labels.rows+1]={frame=row,name=name,low=low,
            average=average,listings=listings,note=note}
    end
    Button(f,"Previous",21,-356,111,function()
        page=math.max(1,page-1);Refresh()
    end)
    labels.page=Font(f,"GameFontHighlightSmall",281,-363,106)
    Button(f,"Next",500,-356,111,function()
        page=page+1;Refresh()
    end)
    labels.info=Font(f,"GameFontHighlightSmall",21,-392,594)
    frame=f
    f:SetScript("OnUpdate",function(self,elapsed)
        seconds=seconds+(type(elapsed)=="number" and elapsed or 0)
        if seconds>=1 then seconds=0;Refresh() end
    end)
    f:Hide()
    return true
end
local function HidePane()
    if frame then frame:Hide() end
    if tab and type(PanelTemplates_DeselectTab)=="function" then
        pcall(PanelTemplates_DeselectTab,tab)
    end
end
local hooked={}
local function HookOtherTabs()
    if not host then return end
    local tabs=type(host.Tabs)=="table" and host.Tabs or
        {host.BuyTab,host.SellTab,host.AuctionsTab}
    for _,button in pairs(tabs) do
        if button and button~=tab and not hooked[button] and
            type(button.HookScript)=="function" then
            hooked[button]=true
            pcall(button.HookScript,button,"OnClick",HidePane)
        end
    end
end
function ChalkBox_AuctionAttach()
    if not Ensure() then return false end
    if not tab then
        local tabs=type(host.Tabs)=="table" and host.Tabs or nil
        local previous=tabs and tabs[#tabs] or
            host.AuctionsTab or host.SellTab or host.BuyTab
        -- Blizzard's tab template keeps the same visual language as the AH.
        -- Never append to host.Tabs or edit its secure tab numbers ourselves.
        local ok,button=pcall(CreateFrame,"Button",
            "ChalkBoxAuctionSenseTab",host,
            "AuctionHouseFrameDisplayModeTabTemplate")
        if not ok or not button then
            button=CreateFrame("Button","ChalkBoxAuctionSenseTab",
                host,"UIPanelButtonTemplate")
        end
        tab=button
        -- Short tab label fits Blizzard's tab strip at normal UI scale.
        tab:SetText("Market")
        if tab.SetWidth then tab:SetWidth(92) end
        if previous then
            tab:SetPoint("LEFT",previous,"RIGHT",-3,0)
        else
            tab:SetPoint("BOTTOMLEFT",host,"BOTTOMLEFT",240,3)
        end
        tab:SetScript("OnClick",function()
            if type(InCombatLockdown)=="function" and
                InCombatLockdown() then return end
            frame:Show()
            if type(PanelTemplates_SelectTab)=="function" then
                pcall(PanelTemplates_SelectTab,tab)
            end
            Refresh()
        end)
        if type(host.HookScript)=="function" then
            host:HookScript("OnHide",HidePane)
            host:HookScript("OnShow",HidePane)
        end
        if type(hooksecurefunc)=="function" and
            type(host.SetDisplayMode)=="function" then
            pcall(hooksecurefunc,host,"SetDisplayMode",HidePane)
        end
    end
    HookOtherTabs()
    return true
end
function ChalkBox_AuctionHide()
    HidePane()
end
function ChalkBox_AuctionOpen()
    if not AuctionHouseFrame then
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
            DEFAULT_CHAT_FRAME:AddMessage(
                "|cff67c6b7AuctionSense|r Open an auctioneer to use the AH tab.")
        end
        return false
    end
    if not ChalkBox_AuctionAttach() then return false end
    if tab and tab.Click then
        tab:Click()
    elseif frame then
        frame:Show()
    end
    Refresh()
    return true
end
