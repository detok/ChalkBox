-- AuctionSense market browser: clear prices with source, age and scan state.
-- Separate from Blizzard's trading controls: display only, never transact.
local PER_PAGE=7
local frame,tab,host,labels=nil,nil,nil,{}
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
        (status.mode=="browse" and
            (tostring(status.scannedItems or 0).." items read") or
            ("Full scan "..tostring(status.progress or 0).."%")) or
        (status.scannedAt and ("Last scan "..Age(status.age)) or "No scan yet"))
    local cooldown=status.cooldown or 0
    labels.cooldown:SetText(cooldown>0 and
        ("Full scan: "..math.ceil(cooldown/60).."m cooldown") or
        (status.fullAvailable and "Full listing scan ready" or
        "Full listing scan unavailable"))
    labels.details:SetText(("%d items  ·  %s"):format(
        status.items or 0,
        status.source=="browse" and "Browse prices" or
        (status.source=="full" and
            (tostring(status.auctions or 0).." listings") or "No scan")))
    labels.info:SetText(status.error or
        (status.age and status.age>86400 and
            "Prices are old. Scan again before making decisions." or
            "Lowest unit asking prices, not completed sales."))
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
                "Gear variants mixed — check the exact item" or
                (tostring(item.quantity or 0).." units listed"))
            row.frame:Show()
        else
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
    f:SetPoint("TOPLEFT",ah,"TOPLEFT",13,-56)
    f:SetPoint("BOTTOMRIGHT",ah,"BOTTOMRIGHT",-13,39)
    if f.SetFrameLevel then
        local base=type(ah.GetFrameLevel)=="function" and
            ah:GetFrameLevel() or 20
        f:SetFrameLevel(base+45)
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
    labels.title=Font(f,"GameFontNormalHuge",20,-12,410)
    labels.title:SetText("AuctionSense")
    labels.market=Font(f,"GameFontHighlightSmall",21,-42,425)
    labels.status=Font(f,"GameFontNormal",20,-72,560)
    labels.progress=Font(f,"GameFontHighlight",21,-98,270)
    labels.cooldown=Font(f,"GameFontHighlight",313,-98,295)
    labels.details=Font(f,"GameFontHighlight",21,-124,545)
    labels.scan=Button(f,"Scan Market",21,-146,140,function()
        if type(ChalkBox_AuctionScan)=="function" then
            local ok,reason=ChalkBox_AuctionScan()
            if not ok then labels.status:SetText(reason or "Browse unavailable") end
            Refresh()
        end
    end)
    labels.fullscan=Button(f,"Full listings (15m)",172,-146,167,function()
        if type(ChalkBox_AuctionFullScan)=="function" then
            local ok,reason=ChalkBox_AuctionFullScan()
            if not ok then labels.status:SetText(reason or "Full scan unavailable") end
            Refresh()
        end
    end)
    local input=CreateFrame("EditBox",nil,f,"InputBoxTemplate")
    input:SetSize(224,24)
    input:SetPoint("TOPLEFT",f,"TOPLEFT",386,-147)
    if input.SetAutoFocus then input:SetAutoFocus(false) end
    if input.SetMaxLetters then input:SetMaxLetters(70) end
    input:SetScript("OnTextChanged",function(self)
        searchText=type(self.GetText)=="function" and self:GetText() or ""
        page=1;Refresh()
    end)
    input:SetScript("OnEscapePressed",function(self)
        if self.ClearFocus then self:ClearFocus() end
    end)
    Font(f,"GameFontNormal",345,-153,45):SetText("Find")
    Font(f,"GameFontNormal",21,-184,255):SetText("ITEM")
    Font(f,"GameFontNormal",316,-184,102):SetText("LOW")
    Font(f,"GameFontNormal",428,-184,104):SetText("AVG ASK")
    Font(f,"GameFontNormal",541,-184,92):SetText("LOTS")
    labels.rows={}
    for i=1,PER_PAGE do
        local y=-206-(i-1)*29
        local row=CreateFrame("Frame",nil,f)
        row:SetSize(610,28)
        row:SetPoint("TOPLEFT",f,"TOPLEFT",17,y)
        local name=Font(row,"GameFontHighlight",4,-1,287)
        local low=Font(row,"GameFontHighlight",299,-1,102)
        local average=Font(row,"GameFontHighlight",411,-1,102)
        local listings=Font(row,"GameFontHighlightSmall",524,-1,85)
        local note=Font(row,"GameFontHighlightSmall",4,-15,588)
        if note.SetTextColor then note:SetTextColor(0.72,0.66,0.54,1) end
        labels.rows[#labels.rows+1]={frame=row,name=name,low=low,
            average=average,listings=listings,note=note}
    end
    Button(f,"Previous",21,-413,111,function()
        page=math.max(1,page-1);Refresh()
    end)
    labels.page=Font(f,"GameFontHighlightSmall",281,-419,106)
    Button(f,"Next",500,-413,111,function()
        page=page+1;Refresh()
    end)
    labels.info=Font(f,"GameFontHighlightSmall",21,-446,594)
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
        tab:SetText("AuctionSense")
        if tab.SetWidth then tab:SetWidth(116) end
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
