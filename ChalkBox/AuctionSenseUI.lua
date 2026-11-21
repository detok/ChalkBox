-- AuctionSense market browser: clear prices with source, age and scan state.
-- Separate from Blizzard's trading controls: display only, never transact.
local MAX_ROWS=7
local visibleRows=4
-- The actual AH content height varies across Forever UI scales.
local frame,tab,host,labels=nil,nil,nil,{}
-- NEVER call AuctionHouseFrame:SetDisplayMode from addon code.
-- Forever's secure bag-item path reads the frame's displayMode; writing it
-- from our tab can taint item use (including the Cozy Sleeping Bag) until /reload.
-- Preserve the Market UI by temporarily hiding only safe native content
-- frames, without changing the Blizzard-owned auction/trading state.
local hiddenMode=nil
local hiddenNative={}
-- Visual tab state only. Blizzard continues to own its native displayMode.
-- Remember a Market selection through SetDisplayMode hooks, which may hide
-- our pane BEFORE the native tab's own OnClick hook runs.
local marketSelectionActive=false
local searchText,page="",1
local view="market"  -- Market / My Items / Sales: same native AH pane.
local seconds=0
local cachedRows,cachedMarket,cachedTime,cachedSearch={},"",0,nil
local selectedItemID,pricePreview,pricePreviewKey=nil,nil,nil
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
-- Larger Market-side price history, still using the same seven saved
-- observations as Charts. Never scans, buys, bids, or changes native tabs.
local function PreviewPaint(texture,r,g,b,a)
    if type(texture.SetTexture)=="function" and
        type(texture.SetVertexColor)=="function" then
        texture:SetTexture("Interface\\Buttons\\WHITE8X8")
        texture:SetVertexColor(r,g,b,a)
    elseif type(texture.SetColorTexture)=="function" then
        texture:SetColorTexture(r,g,b,a)
    end
end
-- A small, consistent native-inspired frame used by both the price list
-- and graph. Decorative textures only: no extra buttons, events or state.
local function PanelSurface(panel,width,headerHeight,footerHeight)
    local body=panel:CreateTexture(nil,"BACKGROUND")
    body:SetAllPoints(panel)
    PreviewPaint(body,0.035,0.046,0.052,0.92)
    local header=panel:CreateTexture(nil,"BORDER")
    header:SetHeight(headerHeight)
    header:SetPoint("TOPLEFT",panel,"TOPLEFT",1,-1)
    header:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-1,-1)
    PreviewPaint(header,0.14,0.16,0.17,0.85)
    if footerHeight and footerHeight>0 then
        local bottom=panel:CreateTexture(nil,"BORDER")
        bottom:SetHeight(footerHeight)
        bottom:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",1,1)
        bottom:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-1,1)
        PreviewPaint(bottom,0.11,0.13,0.14,0.86)
    end
    local function Stroke(anchor,other,vertical)
        local line=panel:CreateTexture(nil,"ARTWORK")
        if vertical then
            line:SetWidth(1)
            line:SetPoint(anchor,panel,anchor,0,0)
            line:SetPoint(other,panel,other,0,0)
        else
            line:SetHeight(1)
            line:SetPoint(anchor,panel,anchor,0,0)
            local otherEdge=anchor=="TOPLEFT" and "TOPRIGHT" or
                "BOTTOMRIGHT"
            line:SetPoint(otherEdge,panel,otherEdge,0,0)
        end
        PreviewPaint(line,0.56,0.44,0.28,0.69)
        return line
    end
    Stroke("TOPLEFT",nil,false)
    Stroke("BOTTOMLEFT",nil,false)
    Stroke("TOPLEFT","BOTTOMLEFT",true)
    Stroke("TOPRIGHT","BOTTOMRIGHT",true)
    local separator=panel:CreateTexture(nil,"ARTWORK")
    separator:SetHeight(1)
    separator:SetPoint("TOPLEFT",panel,"TOPLEFT",1,-headerHeight-1)
    separator:SetPoint("TOPRIGHT",panel,"TOPRIGHT",-1,-headerHeight-1)
    PreviewPaint(separator,0.71,0.56,0.34,0.36)
end
local function PreviewDate(stamp)
    if type(date)=="function" then
        local ok,value=pcall(date,"%b %d %H:%M",stamp)
        if ok and type(value)=="string" then return value end
    end
    return "Recorded scan "..tostring(stamp)
end
local function BuildPricePreview(parent,listPanel)
    local panel=CreateFrame("Frame","ChalkBoxAuctionPricePreview",parent)
    -- A dedicated right-hand sidebar next to the result rows. It grows
    -- when the native AH is taller, and always stops above the page footer.
    -- This avoids overlapping the mode buttons, search bar and scan controls.
    -- A narrow gutter separates this card from the framed price table
    -- on Forever's fixed-width Auction House.
    local width=248
    -- Match the list panel's exact top and bottom; a 12px column gutter.
    -- Anchor constraints, not guessed heights, keep this even at UI scales.
    panel:SetSize(width,156)
    panel:SetPoint("TOPLEFT",listPanel,"TOPRIGHT",12,0)
    panel:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT",-16,27)
    local function Height()
        local h=type(panel.GetHeight)=="function" and panel:GetHeight()
        return type(h)=="number" and h==h and h>96 and h or 156
    end
    local function Width()
        local w=type(panel.GetWidth)=="function" and panel:GetWidth()
        return type(w)=="number" and w==w and w>140 and w or width
    end
    local lastHeight=Height()
    local lastWidth=Width()
    PanelSurface(panel,width,40,27)
    -- Inner chart field, below the item heading and above the summary strip.
    -- The anchors stretch automatically as the AH window's height changes.
    local plot=panel:CreateTexture(nil,"BACKGROUND")
    plot:SetPoint("TOPLEFT",panel,"TOPLEFT",10,-43)
    plot:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-10,33)
    PreviewPaint(plot,0.016,0.025,0.030,0.65)
    local title=Font(panel,"GameFontHighlightSmall",10,-7,width-20)
    local footer=Font(panel,"GameFontHighlightSmall",10,-8,width-20)
    if type(footer.ClearAllPoints)=="function" then footer:ClearAllPoints() end
    footer:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",10,11)
    local selectHint=Font(panel,"GameFontHighlightSmall",10,-24,width-20)
    selectHint:SetText("Recorded asking prices / unit")
    Tint(selectHint,COLOR.muted)
    if type(title.SetMaxLines)=="function" then title:SetMaxLines(1) end
    if type(title.SetWordWrap)=="function" then title:SetWordWrap(false) end
    Tint(title,COLOR.average)
    Tint(footer,COLOR.muted)
    local hoverName,hoverSummary,hoverMixed=nil,nil,false
    if type(panel.EnableMouse)=="function" then panel:EnableMouse(true) end
    panel:SetScript("OnEnter",function(self)
        local tip=StartTooltip(self,hoverName or "Saved price history")
        if not tip then return end
        tip:AddLine(hoverSummary or
            "Select a market item to view recorded low asks.",
            COLOR.neutral[1],COLOR.neutral[2],COLOR.neutral[3])
        if hoverMixed then
            tip:AddLine("Different equipment variants may not be comparable.",
                COLOR.warning[1],COLOR.warning[2],COLOR.warning[3])
        end
        tip:AddLine("Observed asking prices only, not completed sales.",
            COLOR.muted[1],COLOR.muted[2],COLOR.muted[3])
        EndTooltip(tip)
    end)
    panel:SetScript("OnLeave",HideTooltip)
    local baseline=panel:CreateTexture(nil,"ARTWORK")
    baseline:SetHeight(1)
    baseline:SetPoint("BOTTOMLEFT",panel,"BOTTOMLEFT",11,33)
    baseline:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-11,33)
    PreviewPaint(baseline,0.6,0.64,0.68,0.35)
    local segments,strips,dots={},{},{}
    local canLine=type(panel.CreateLine)=="function"
    if canLine then
        for i=1,6 do
            local ok,line=pcall(panel.CreateLine,panel,nil,"ARTWORK")
            if not ok or not line or
                type(line.SetStartPoint)~="function" or
                type(line.SetEndPoint)~="function" or
                type(line.SetThickness)~="function" or
                type(line.SetColorTexture)~="function" then
                canLine=false;break
            end
            local configured=pcall(function()
                line:SetThickness(2)
                line:SetColorTexture(0.42,0.90,0.72,1)
                line:Hide()
            end)
            if not configured then canLine=false;break end
            segments[#segments+1]=line
        end
    end
    for i=1,7 do
        local bar=panel:CreateTexture(nil,"ARTWORK")
        PreviewPaint(bar,0.42,0.90,0.72,0.78)
        bar:Hide()
        strips[i]=bar
        local dot=CreateFrame("Button",nil,panel)
        dot:SetSize(8,8)
        local fill=dot:CreateTexture(nil,"ARTWORK")
        fill:SetAllPoints(dot)
        PreviewPaint(fill,1,0.83,0.47,1)
        if type(dot.EnableMouse)=="function" then dot:EnableMouse(true) end
        dot:SetScript("OnEnter",function(self)
            local sample=self.priceSample
            if not sample then return end
            local tip=StartTooltip(self,PreviewDate(sample.t))
            if not tip then return end
            tip:AddLine("Lowest ask per unit: "..Coin(sample.low),
                COLOR.low[1],COLOR.low[2],COLOR.low[3])
            tip:AddLine("Recorded listing price, not a completed sale",
                COLOR.muted[1],COLOR.muted[2],COLOR.muted[3])
            EndTooltip(tip)
        end)
        dot:SetScript("OnLeave",HideTooltip)
        dot:Hide()
        dots[i]=dot
    end
    local function Clear()
        for _,line in ipairs(segments) do line:Hide() end
        for _,bar in ipairs(strips) do bar:Hide() end
        for _,dot in ipairs(dots) do
            dot.priceSample=nil
            dot:Hide()
        end
    end
    return function(itemID)
        lastHeight=Height()
        lastWidth=Width()
        Clear()
        hoverName,hoverSummary,hoverMixed=nil,nil,false
        if not itemID then
            title:SetText("PRICE HISTORY  /  LOW ASK")
            footer:SetText("Select a row to see its price history")
            Tint(footer,COLOR.muted)
            return
        end
        local fn=ChalkBox_AuctionChartHistory
        local ok,data=false,nil
        if type(fn)=="function" then ok,data=pcall(fn,itemID) end
        if not ok or type(data)~="table" then
            title:SetText("PRICE HISTORY  /  LOW ASK")
            footer:SetText("No saved scan for this item")
            hoverSummary="No recorded low asking prices for this item."
            Tint(footer,COLOR.muted)
            return
        end
        local name=type(data.name)=="string" and data.name or
            ("Item #"..tostring(itemID))
        hoverName=name
        -- The existing suffix consumed a third of the label and needlessly
        -- abbreviated names like "Amber Hoop of the Knight".
        local shortName=#name>37 and (name:sub(1,35).."...") or name
        title:SetText(shortName)
        local points={}
        if type(data.points)=="table" then
            for _,p in ipairs(data.points) do
                if type(p)=="table" and type(p.t)=="number" and
                    type(p.low)=="number" and p.low>0 and
                    p.low==p.low and p.t>0 and p.t==p.t then
                    points[#points+1]=p
                    if #points==7 then break end
                end
            end
        end
        hoverMixed=data.mixed==true
        if #points==0 then
            footer:SetText("No recorded asking prices")
            hoverSummary="This item has no saved price observations."
            Tint(footer,COLOR.muted)
            return
        end
        local latest=points[#points]
        hoverSummary=("%d saved scan%s. Latest low ask: %s per unit."):format(
            #points,#points==1 and "" or "s",Coin(latest.low))
        if data.mixed then
            -- Item IDs can represent multiple gear variants. Keep real
            -- observations visible, without claiming like-for-like trends.
            footer:SetText("LOW "..Coin(latest.low).."  |  "..#points..
                " scans  |  MIXED")
            Tint(footer,COLOR.warning)
        elseif #points==1 then
            footer:SetText("LOW "..Coin(latest.low).."  |  1 scan")
            Tint(footer,COLOR.muted)
        else
            footer:SetText("LOW "..Coin(latest.low).."  |  "..#points.." scans")
            Tint(footer,COLOR.ready)
        end
        local low,high=points[1].low,points[1].low
        for _,p in ipairs(points) do
            low=math.min(low,p.low)
            high=math.max(high,p.low)
        end
        local range=high-low
        local padding=range>0 and range*0.12 or math.max(1,high*0.08)
        local floor=math.max(0,low-padding)
        local scale=math.max(1,high+padding-floor)
        local first,last=points[1].t,points[#points].t
        local plotted={}
        for i,p in ipairs(points) do
            local xFraction
            if #points==1 then xFraction=0.5
            elseif first==last then xFraction=(i-1)/(#points-1)
            else xFraction=(p.t-first)/(last-first) end
            local x=16+xFraction*(lastWidth-32)
            -- Keep points between the framed plot's 43px header and
            -- 33px footer, with a few pixels of breathing room.
            local y=40+(p.low-floor)/scale*math.max(20,lastHeight-87)
            plotted[i]={x=x,y=y}
            local dot=dots[i]
            dot:ClearAllPoints()
            dot:SetPoint("CENTER",panel,"BOTTOMLEFT",x,y)
            dot.priceSample=p
            dot:Show()
        end
        local drewLines=canLine and #points>1
        if drewLines then
            for i=1,#points-1 do
                local line=segments[i]
                local a,b=plotted[i],plotted[i+1]
                local okLine=pcall(function()
                    line:SetStartPoint("BOTTOMLEFT",panel,a.x,a.y)
                    line:SetEndPoint("BOTTOMLEFT",panel,b.x,b.y)
                    line:Show()
                end)
                if not okLine then drewLines=false;break end
            end
            if not drewLines then
                for _,line in ipairs(segments) do line:Hide() end
            end
        end
        if not drewLines then
            -- Older Forever clients without Line still get real sample columns.
            for i,p in ipairs(plotted) do
                local bar=strips[i]
                bar:SetSize(5,math.max(2,p.y-33))
                bar:ClearAllPoints()
                bar:SetPoint("BOTTOM",panel,"BOTTOMLEFT",p.x,33)
                bar:Show()
            end
        end
    end
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
    -- Only claim progress once the server provided a real listing count.
    if status.busy and status.mode=="full" then
        if status.phase=="reading" and (status.totalListings or 0)>0 then
            labels.progress:SetText(("%d / %d auctions  ·  %d%%"):format(
                status.processedListings or 0,status.totalListings,
                status.progress or 0))
        elseif status.phase=="settling" then
            labels.progress:SetText(("%d listings arriving  ·  confirming total"):format(
                status.reportedListings or 0))
        elseif status.phase=="finalizing" then
            labels.progress:SetText(("%d / %d auctions  ·  checking final batch"):format(
                status.processedListings or 0,status.totalListings or 0))
        else
            labels.progress:SetText(("%ds elapsed  ·  awaiting server"):format(
                math.floor(status.waitSeconds or 0)))
        end
    elseif status.busy and status.mode=="browse" then
        labels.progress:SetText(tostring(status.scannedItems or 0).." items read")
    else
        labels.progress:SetText(status.scannedAt and
            ("Last scan "..Age(status.age)) or "No scan yet")
    end
    local cooldown=status.cooldown or 0
    labels.cooldown:SetText(cooldown>0 and
        ("Full scan  |  "..math.ceil(cooldown/60).."m cooldown") or
        (status.fullAvailable and "Full scan ready" or
        "Full scan unavailable"))
    Tint(labels.cooldown,cooldown>0 and COLOR.warning or
        (status.fullAvailable and COLOR.ready or COLOR.muted))
    local entries
    local extra
    if view=="bags" then
        entries,extra={},{}
        if type(ChalkBox_MarketBagRows)=="function" then
            entries,extra=ChalkBox_MarketBagRows(searchText,250)
        end
        extra=extra or {}
        if type(ChalkBox_IntelAnnotate)=="function" then
            pcall(ChalkBox_IntelAnnotate,entries,extra)
        end
        if type(ChalkBox_AuctionPostNote)=="function" then
            pcall(ChalkBox_AuctionPostNote,labels,selectedItemID,view)
        end
        labels.details:SetText(("Bags: %d items  ·  %d priced"):format(
            extra.stacks or 0,extra.priced or 0))
        labels.info:SetText("Bag asks "..Coin(extra.marketValue or 0)..
            "  ·  Vendor "..Coin(extra.vendorValue or 0)..
            "  ·  Price is not a guaranteed sale")
    elseif view=="sales" then
        entries=type(ChalkBox_MarketSaleRows)=="function" and
            ChalkBox_MarketSaleRows(searchText,250) or {}
        extra=type(ChalkBox_MarketSalesStatus)=="function" and
            ChalkBox_MarketSalesStatus() or {}
        labels.details:SetText(("%d receipts  ·  %d captured in last 30d"):format(
            extra.count or 0,extra.last30 or 0))
        labels.info:SetText((extra.count or 0)==0 and
            "No receipts yet · Open a mailbox to capture completed seller invoices"
            or ("Gross "..Coin(extra.gross or 0)..
            "  ·  Proceeds "..Coin(extra.proceeds or 0)..
            "  ·  Fees "..Coin(extra.fees or 0)..
            "  ·  Captured invoices only"))
    else
        labels.details:SetText(("%d items  ·  %s"):format(
            status.items or 0,
            status.source=="browse" and "Browse prices" or
            (status.source=="full" and
                (tostring(status.auctions or 0).." listings") or "No scan")))
        labels.info:SetText(status.error or
            (status.age and status.age>86400 and
                "OLD SCAN  |  Refresh before buying" or
                "Asking prices  ·  not sales"))
        if cachedSearch~=searchText or
            cachedMarket~=(status.marketKey or "") or
            cachedTime~=(status.scannedAt or 0) then
            cachedMarket=status.marketKey or ""
            cachedTime=status.scannedAt or 0
            cachedSearch=searchText
            cachedRows=ChalkBox_AuctionRows and
                ChalkBox_AuctionRows(searchText,12000) or {}
        end
        entries=cachedRows
    end
    if labels.hdrLow then
        labels.hdrLow:SetText(view=="bags" and "LOW / UNIT" or
            (view=="sales" and "GROSS" or "LOW / UNIT"))
        labels.hdrAverage:SetText(view=="bags" and "DE / ITEM" or
            (view=="sales" and "PROCEEDS" or "AVG ASK"))
        labels.hdrListings:SetText(view=="bags" and "IN BAG" or
            (view=="sales" and "SOLD" or "LISTINGS"))
        for _,mode in ipairs({"market","bags","sales"}) do
            Tint(labels["mode_"..mode],view==mode and COLOR.ready or COLOR.muted)
        end
    end
    Tint(labels.info,status.error and view=="market" and COLOR.error or
        (status.age and status.age>86400 and view~="sales" and
         COLOR.warning or COLOR.muted))
    local height=type(frame.GetHeight)=="function" and frame:GetHeight() or 345
    if type(height)~="number" or height~=height then height=345 end
    -- Header + tools occupy 157px. Keep pager and footer entirely inside
    -- the native AH body, regardless of actual window size/UI scale.
    visibleRows=math.max(1,math.min(MAX_ROWS,
        math.floor((height-220)/24)))
    local maxPages=math.max(1,math.ceil(#entries/visibleRows))
    page=math.max(1,math.min(page,maxPages))
    local start=(page-1)*visibleRows
    -- The graph should be useful on opening Market, not an empty box until
    -- the user discovers they must click a row. Keep manual row selection.
    if view=="market" then
        -- Keep the chart aligned with the actual visible page. A new scan,
        -- search, or page may replace its entries without a row click.
        local selectedOnPage=false
        for i=1,visibleRows do
            local item=entries[start+i]
            if item and item.itemID==selectedItemID then
                selectedOnPage=true;break
            end
        end
        if not selectedOnPage then
            local first=entries[start+1]
            selectedItemID=first and
                type(first.itemID)=="number" and first.itemID or nil
        end
    end
    for i,row in ipairs(labels.rows) do
        local item=(i<=visibleRows) and entries[start+i] or nil
        if item then
            row.name:SetText(item.name or ("Item #"..tostring(item.itemID)))
            if view=="bags" then
                row.low:SetText(Coin(item.low))
                row.average:SetText(Coin(item.de))
                row.listings:SetText(tostring(item.count or 0).."x")
                row.note:SetText(item.note or "Compare prices")
                Tint(row.note,(item.protected or item.bound) and COLOR.warning or
                    COLOR.muted)
            elseif view=="sales" then
                row.low:SetText(Coin(item.gross))
                row.average:SetText(Coin(item.proceeds))
                row.listings:SetText(tostring(item.count or 1).."x")
                row.note:SetText("Confirmed seller invoice  ·  "..Coin(item.cut).." fee")
                Tint(row.note,COLOR.muted)
            else
                row.low:SetText(Coin(item.low))
                row.average:SetText(Coin(item.average))
                row.listings:SetText(item.listings and
                    (tostring(item.listings).." lots") or "—")
                row.note:SetText(item.mixed and
                    "VARIANTS MIXED  |  Verify exact gear" or
                    (tostring(item.quantity or 0).." units"))
                Tint(row.note,item.mixed and COLOR.warning or COLOR.muted)
            end
            local chosen=selectedItemID==item.itemID
            Tint(row.name,chosen and COLOR.ready or COLOR.neutral)
            if row.frame.selectedBack then
                if chosen then row.frame.selectedBack:Show()
                else row.frame.selectedBack:Hide() end
            end
            row.frame.marketView=view
            row.frame.marketData=item
            row.frame:Show()
        else
            if row.frame.selectedBack then row.frame.selectedBack:Hide() end
            row.frame.marketData=nil
            row.frame.marketView=nil
            row.frame:Hide()
        end
    end
    if pricePreview then
        local key=tostring(selectedItemID or "").."|"..
            tostring(status.marketKey or "").."|"..
            tostring(status.scannedAt or 0).."|"..
            tostring(type(frame.GetHeight)=="function" and
                frame:GetHeight() or 316).."|"..
            tostring(type(frame.GetWidth)=="function" and
                frame:GetWidth() or 784)
        if key~=pricePreviewKey then
            pricePreviewKey=key
            pricePreview(selectedItemID)
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
function ChalkBox_AuctionSelected() return selectedItemID end
function ChalkBox_AuctionRefreshUI() Refresh() end
-- The journal is mounted INSIDE Blizzard's AH, not a detached window.
-- No edits to Blizzard's protected Tabs list or PanelTemplates_SetTab.
local function Ensure()
    if frame then return true end
    local ah=AuctionHouseFrame
    if not ah then return false end
    host=ah
    -- Use native inset framing and auction index artwork. The previous
    -- opaque rectangle covered the Blizzard panel instead of belonging
    -- to it. The parent frame owns its portrait, money footer and tabs.
    local f=CreateFrame("Frame","ChalkBoxAuctionSensePane",ah,
        "InsetFrameTemplate")
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
    -- Same atlas as AuctionHouseBrowseResultsFrame.ItemList in Forever.
    -- Fallback remains opaque if the atlas is unavailable in a client.
    local themed=false
    if type(background.SetAtlas)=="function" then
        themed=pcall(background.SetAtlas,background,
            "auctionhouse-background-index",false)
    end
    if not themed then
        if type(background.SetColorTexture)=="function" then
            background:SetColorTexture(0.18,0.14,0.11,1)
        elseif type(background.SetTexture)=="function" then
            background:SetTexture("Interface\\Buttons\\WHITE8X8")
            if type(background.SetVertexColor)=="function" then
                background:SetVertexColor(0.18,0.14,0.11,1)
            end
        end
    end
    labels.title=Font(f,"GameFontNormalHuge",20,-9,330)
    labels.title:SetText("AuctionSense")
    labels.market=Font(f,"GameFontHighlightSmall",21,-31,390)
    labels.status=Font(f,"GameFontNormal",20,-49,395)
    labels.progress=Font(f,"GameFontHighlight",21,-67,252)
    labels.cooldown=Font(f,"GameFontHighlight",296,-67,275)
    local function Mode(buttonView)
        view=buttonView
        selectedItemID=nil;pricePreviewKey=nil
        searchText=""
        page=1
        cachedSearch=nil
        if labels.search and labels.search.SetText then
            labels.search:SetText("")
        end
        Refresh()
    end
    labels.mode_market=Button(f,"Prices",21,-87,78,function() Mode("market") end)
    labels.mode_bags=Button(f,"My Items",104,-87,92,function() Mode("bags") end)
    labels.mode_sales=Button(f,"Sales & Stats",201,-87,114,function() Mode("sales") end)
    -- Scan results live under the view choices, not between buttons/search.
    labels.details=Font(f,"GameFontHighlightSmall",21,-117,446)
    labels.scan=Button(f,"Scan Market",21,-106,125,function()
        if type(ChalkBox_AuctionScan)=="function" then
            local ok,reason=ChalkBox_AuctionScan()
            if not ok then labels.status:SetText(reason or "Browse unavailable") end
            Refresh()
        end
    end)
    Hint(labels.scan,"Scan Market","Browse asking prices","No full-scan cooldown")
    labels.fullscan=Button(f,"Full listings (15m)",154,-106,153,function()
        if type(ChalkBox_AuctionFullScan)=="function" then
            local ok,reason=ChalkBox_AuctionFullScan()
            if not ok then labels.status:SetText(reason or "Full scan unavailable") end
            Refresh()
        end
    end)
    Hint(labels.fullscan,"Full listings","Complete auction listing snapshot",
        "Server limit: once every 15 minutes")
    -- Dedicated top-right action row in the unused AH header space.
    -- Do not change the scan callbacks, cooldown or secure AH state.
    if labels.fullscan.ClearAllPoints then
        labels.fullscan:ClearAllPoints()
    end
    labels.fullscan:SetPoint("TOPRIGHT",f,"TOPRIGHT",-18,-29)
    if labels.scan.ClearAllPoints then labels.scan:ClearAllPoints() end
    labels.scan:SetPoint("RIGHT",labels.fullscan,"LEFT",-8,0)
    local input=CreateFrame("EditBox",nil,f,"SearchBoxTemplate")
    input:SetSize(258,24)
    input:ClearAllPoints()
    input:SetPoint("TOPRIGHT",f,"TOPRIGHT",-25,-87)
    labels.search=input
    if input.SetAutoFocus then input:SetAutoFocus(false) end
    if input.SetMaxLetters then input:SetMaxLetters(70) end
    input:SetScript("OnTextChanged",function(self)
        searchText=type(self.GetText)=="function" and self:GetText() or ""
        selectedItemID=nil;pricePreviewKey=nil
        page=1;Refresh()
    end)
    input:SetScript("OnEscapePressed",function(self)
        if self.ClearFocus then self:ClearFocus() end
    end)
    local find=Font(f,"GameFontNormal",0,0,36)
    find:ClearAllPoints()
    find:SetPoint("RIGHT",input,"LEFT",-8,0)
    find:SetText("Find")
    -- Matching inset surrounds the table, including its built-in pager.
    -- Its non-interactive background is created BEFORE clickable rows.
    local listPanel=CreateFrame("Frame","ChalkBoxAuctionMarketListPanel",f)
    listPanel:SetWidth(469)
    listPanel:SetPoint("TOPLEFT",f,"TOPLEFT",13,-132)
    listPanel:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",13,27)
    PanelSurface(listPanel,469,22,33)
    pricePreview=BuildPricePreview(f,listPanel)
    Font(f,"GameFontNormal",21,-138,213):SetText("ITEM")
    labels.hdrLow=Font(f,"GameFontNormal",252,-138,82)
    Tint(labels.hdrLow,COLOR.low)
    labels.hdrAverage=Font(f,"GameFontNormal",340,-138,87)
    Tint(labels.hdrAverage,COLOR.average)
    labels.hdrListings=Font(f,"GameFontNormal",430,-138,48)
    Tint(labels.hdrListings,COLOR.counts)
    labels.rows={}
    for i=1,MAX_ROWS do
        local y=-157-(i-1)*24
        local row=CreateFrame("Frame",nil,f)
        row:SetSize(459,22)
        row:SetPoint("TOPLEFT",f,"TOPLEFT",17,y)
        if i%2==0 then
            local zebra=row:CreateTexture(nil,"BACKGROUND")
            zebra:SetAllPoints(row)
            PreviewPaint(zebra,0.24,0.27,0.28,0.17)
        end
        local selectedBack=row:CreateTexture(nil,"BACKGROUND")
        selectedBack:SetAllPoints(row)
        PreviewPaint(selectedBack,0.16,0.42,0.38,0.30)
        selectedBack:Hide()
        row.selectedBack=selectedBack
        local name=Font(row,"GameFontHighlight",4,-1,215)
        local low=Font(row,"GameFontHighlight",231,-1,82)
        local average=Font(row,"GameFontHighlight",320,-1,86)
        local listings=Font(row,"GameFontHighlightSmall",413,-1,47)
        local note=Font(row,"GameFontHighlightSmall",4,-12,454)
        Tint(low,COLOR.low)
        Tint(average,COLOR.average)
        Tint(listings,COLOR.counts)
        Tint(note,COLOR.muted)
        if type(row.EnableMouse)=="function" then row:EnableMouse(true) end
        row:SetScript("OnMouseDown",function(self,button)
            if button and button~="LeftButton" then return end
            local item=self.marketData
            if not item or type(item.itemID)~="number" or
                item.itemID<=0 then return end
            selectedItemID=item.itemID
            pricePreviewKey=nil
            HideTooltip()
            Refresh()
        end)
        row:SetScript("OnEnter",function(self)
            local item=self.marketData
            if not item then return end
            local tip=StartTooltip(self,item.name or
                ("Item #"..tostring(item.itemID)))
            if not tip then return end
            if self.marketView=="bags" then
                Metric(tip,"In your bags",tostring(item.count or 0),COLOR.neutral)
                Metric(tip,"Low ask / unit",Coin(item.low),
                    item.low and COLOR.low or COLOR.muted)
                Metric(tip,"Estimated bag ask",Coin(item.marketTotal),
                    item.marketTotal and COLOR.low or COLOR.muted)
                Metric(tip,"Vendor total",Coin(item.vendorTotal),
                    COLOR.neutral)
                Metric(tip,"DE estimate / item",Coin(item.de),
                    item.de and COLOR.average or COLOR.muted)
                if item.protected or item.bound then
                    tip:AddLine(item.protected and "KEEP: protected by you" or
                        "Bound item: check tradeability",
                        COLOR.warning[1],COLOR.warning[2],COLOR.warning[3])
                else
                    tip:AddLine("Candidate only: verify bind status, fees and competition",
                        COLOR.muted[1],COLOR.muted[2],COLOR.muted[3])
                end
                tip:AddLine("Asking prices are not sale proceeds",
                    COLOR.muted[1],COLOR.muted[2],COLOR.muted[3])
                EndTooltip(tip)
                return
            elseif self.marketView=="sales" then
                Metric(tip,"Gross auction sale",Coin(item.gross),COLOR.low)
                Metric(tip,"House cut",Coin(item.cut),COLOR.warning)
                Metric(tip,"Returned deposit",Coin(item.deposit),COLOR.neutral)
                Metric(tip,"Invoice proceeds",Coin(item.proceeds),COLOR.average)
                tip:AddLine("Verified seller mail; excludes item acquisition costs",
                    COLOR.muted[1],COLOR.muted[2],COLOR.muted[3])
                EndTooltip(tip)
                return
            end
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
            tip:AddLine(source.." low price  |  Updated "..Age(current.age),
                COLOR.muted[1],COLOR.muted[2],COLOR.muted[3])
            if item.detailAge and current.source=="browse" then
                tip:AddLine("Avg/listings: full snapshot "..Age(item.detailAge),
                    COLOR.muted[1],COLOR.muted[2],COLOR.muted[3])
            elseif not item.average then
                tip:AddLine("No full listing sample yet",
                    COLOR.muted[1],COLOR.muted[2],COLOR.muted[3])
            end
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
            tip:AddLine("Left-click row for saved price history",
                COLOR.ready[1],COLOR.ready[2],COLOR.ready[3])
            tip:AddLine("Asking prices, not sales",
                COLOR.muted[1],COLOR.muted[2],COLOR.muted[3])
            if type(ChalkBox_DisenchantMarketHint)=="function" then
                pcall(ChalkBox_DisenchantMarketHint,tip,item.itemID)
            end
            EndTooltip(tip)
        end)
        row:SetScript("OnLeave",HideTooltip)
        labels.rows[#labels.rows+1]={frame=row,name=name,low=low,
            average=average,listings=listings,note=note}
    end
    local previous=Button(f,"Previous",21,-10,104,function()
        page=math.max(1,page-1)
        selectedItemID=nil;pricePreviewKey=nil
        Refresh()
    end)
    -- Anchor pager and disclaimer to the BOTTOM of the actual AH content
    -- instead of assuming every client has 450px of vertical room.
    if previous.ClearAllPoints then previous:ClearAllPoints() end
    previous:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",21,34)
    labels.page=Font(f,"GameFontHighlightSmall",0,0,120)
    if labels.page.ClearAllPoints then labels.page:ClearAllPoints() end
    labels.page:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",188,41)
    local nextButton=Button(f,"Next",0,-10,104,function()
        page=page+1
        selectedItemID=nil;pricePreviewKey=nil
        Refresh()
    end)
    if nextButton.ClearAllPoints then nextButton:ClearAllPoints() end
    nextButton:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",354,34)
    labels.info=Font(f,"GameFontHighlightSmall",21,-10,715)
    if labels.info.ClearAllPoints then labels.info:ClearAllPoints() end
    labels.info:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",21,12)
    frame=f
    if type(ChalkBox_AuctionPostAttach)=="function" then
        pcall(ChalkBox_AuctionPostAttach,f)
    end
    f:SetScript("OnUpdate",function(self,elapsed)
        seconds=seconds+(type(elapsed)=="number" and elapsed or 0)
        if seconds>=1 then seconds=0;Refresh() end
    end)
    f:Hide()
    return true
end
local function CombatLocked()
    return type(InCombatLockdown)=="function" and InCombatLockdown()
end
-- A missing protection query is not proof the frame is secure. A positive
-- or failed answer is. Never hook a secure auction tab's click.
local function ProtectedFrame(widget)
    if not widget or type(widget.IsProtected)~="function" then return false end
    local ok,value=pcall(widget.IsProtected,widget)
    return not ok or value==true
end
local function NativeMode()
    if not host or type(host.GetDisplayMode)~="function" then return nil end
    local ok,value=pcall(host.GetDisplayMode,host)
    if ok and type(value)=="table" then return value end
end
local function CanChangeNativeVisibility(widget)
    if not widget or type(widget.Show)~="function" or
        type(widget.Hide)~="function" or
        type(widget.IsShown)~="function" or
        type(widget.IsProtected)~="function" then return false end
    local ok,isProtected=pcall(widget.IsProtected,widget)
    return ok and isProtected==false
end
local function HideNativeContent()
    if hiddenMode or CombatLocked() then return end
    local mode=NativeMode()
    if not mode then return end
    hiddenMode=mode
    hiddenNative={}
    -- Blizzard owns the displayMode and trading actions. We only hide the
    -- unprotected subframes of the currently displayed page while Market is
    -- visible. They can be restored without asking Blizzard to switch mode.
    for _,name in ipairs(mode) do
        local widget=type(name)=="string" and host[name] or nil
        if widget~=frame and CanChangeNativeVisibility(widget) then
            local ok,shown=pcall(widget.IsShown,widget)
            if ok and shown then
                local hidden=pcall(widget.Hide,widget)
                if hidden then hiddenNative[#hiddenNative+1]=widget end
            end
        end
    end
end
local function RestoreNativeContent()
    if not hiddenMode then return end
    if CombatLocked() then return end
    -- If Blizzard has switched to another tab, don't reopen an old page.
    local same=NativeMode()==hiddenMode
    if same then
        for _,widget in ipairs(hiddenNative) do
            if CanChangeNativeVisibility(widget) then
                pcall(widget.Show,widget)
            end
        end
    end
    hiddenMode=nil
    hiddenNative={}
end
local function HidePane()
    if frame then frame:Hide() end
    RestoreNativeContent()
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
            not ProtectedFrame(button) and
            type(button.HookScript)=="function" then
            hooked[button]=true
            pcall(button.HookScript,button,"OnClick",function(clicked)
                local restoringNative=marketSelectionActive
                HidePane()
                marketSelectionActive=false
                -- The Blizzard handler can short-circuit SetDisplayMode when
                -- Buy was already active beneath Market. Its first click then
                -- leaves Buy visually deselected. Restore ONLY the clicked
                -- native tab's appearance, never the protected tab registry
                -- or Blizzard's authoritative auction displayMode.
                if restoringNative and not CombatLocked() and
                    type(PanelTemplates_SelectTab)=="function" and clicked then
                    pcall(PanelTemplates_SelectTab,clicked)
                end
            end)
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
        -- This is our own addon tab, not one of Blizzard's protected tabs.
        -- Forever's tab template can ellipsize "Market" at the stock width.
        -- Reserve real text space after the template initializes.
        tab:SetText("Market")
        if tab.SetWidth then tab:SetWidth(122) end
        local label=type(tab.GetFontString)=="function" and
            tab:GetFontString() or tab.Text
        if label and type(label.SetWidth)=="function" then
            label:SetWidth(106)
        end
        -- The inherited AH tab template can start in the selected artwork
        -- state even though Blizzard opens on Buy. Start Market unselected.
        if type(PanelTemplates_DeselectTab)=="function" then
            pcall(PanelTemplates_DeselectTab,tab)
        end
        if previous then
            tab:SetPoint("LEFT",previous,"RIGHT",-3,0)
        else
            tab:SetPoint("BOTTOMLEFT",host,"BOTTOMLEFT",240,3)
        end
        tab:SetScript("OnClick",function()
            if type(InCombatLockdown)=="function" and
                InCombatLockdown() then return end
            -- Do not call SetDisplayMode: Blizzard's bag-use path consults
            -- that native state. Market has its own cosmetic presentation.
            HideNativeContent()
            frame:Show()
            marketSelectionActive=true
            if type(PanelTemplates_DeselectTab)=="function" then
                local nativeTabs=type(host.Tabs)=="table" and host.Tabs or
                    {host.BuyTab,host.SellTab,host.AuctionsTab}
                for _,native in pairs(nativeTabs) do
                    if native and native~=tab then
                        pcall(PanelTemplates_DeselectTab,native)
                    end
                end
            end
            if type(PanelTemplates_SelectTab)=="function" then
                pcall(PanelTemplates_SelectTab,tab)
            end
            Refresh()
        end)
        if type(host.HookScript)=="function" and not ProtectedFrame(host) then
            host:HookScript("OnHide",function()
                HidePane()
                marketSelectionActive=false
            end)
            host:HookScript("OnShow",function()
                HidePane()
                marketSelectionActive=false
            end)
        end
        if type(hooksecurefunc)=="function" and
            type(host.SetDisplayMode)=="function" then
            pcall(hooksecurefunc,host,"SetDisplayMode",function()
                if frame and type(frame.IsShown)=="function" and
                    frame:IsShown() then HidePane() end
            end)
        end
    end
    HookOtherTabs()
    return true
end
function ChalkBox_AuctionHide()
    HidePane()
    marketSelectionActive=false
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
        if not CombatLocked() then
            HideNativeContent()
            frame:Show()
        end
    end
    Refresh()
    return true
end
