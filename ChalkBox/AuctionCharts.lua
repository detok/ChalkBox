-- AuctionSense Charts Lab: experimental, read-only native graphing.
-- Accessible only in Options > AddOns > ChalkBox > AuctionSense > Charts.
-- Never sends AH requests, alters secure auction controls or fabricates data.
local MAX_POINTS=7
local function Number(v)
    return (type(issecretvalue)~="function" or not issecretvalue(v))
        and type(v)=="number" and v==v and v~=math.huge
        and v~=-math.huge and v>=0
end
local function Money(copper)
    if not Number(copper) then return "--" end
    copper=math.floor(copper)
    local gold=math.floor(copper/10000)
    local silver=math.floor(copper%10000/100)
    local c=copper%100
    if gold>0 then return ("%dg %ds"):format(gold,silver) end
    if silver>0 then return ("%ds %dc"):format(silver,c) end
    return c.."c"
end
local function DateLabel(stamp)
    if not Number(stamp) then return "Unknown time" end
    if type(date)=="function" then
        local ok,value=pcall(date,"%b %d %H:%M",stamp)
        if ok and type(value)=="string" then return value end
    end
    return "Scan "..tostring(math.floor(stamp))
end
local function Label(parent,style,text,x,y,w)
    local f=parent:CreateFontString(nil,"OVERLAY",style or "GameFontHighlightSmall")
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    f:SetWidth(w or 490)
    if f.SetJustifyH then f:SetJustifyH("LEFT") end
    f:SetText(text)
    return f
end
local function Paint(texture,r,g,b,a)
    if type(texture.SetColorTexture)=="function" then
        texture:SetColorTexture(r,g,b,a)
    end
end
-- Returns a refresh callback for the parent native Settings page.
function ChalkBox_AuctionChartsMount(panel)
    if not panel or type(panel.CreateFontString)~="function" or
        type(CreateFrame)~="function" then return end
    Label(panel,"GameFontNormal","SEARCH SAVED ASKING PRICES",28,-103,475)
    local input=CreateFrame("EditBox",nil,panel,"InputBoxTemplate")
    input:SetSize(305,24)
    input:SetPoint("TOPLEFT",panel,"TOPLEFT",32,-134)
    if input.SetAutoFocus then input:SetAutoFocus(false) end
    if input.SetMaxLetters then input:SetMaxLetters(72) end
    local result=Label(panel,"GameFontHighlightSmall",
        "Enter an item name or numeric item ID, then Find.",28,-172,500)
    local canvas=CreateFrame("Frame",nil,panel)
    canvas:SetSize(476,166)
    canvas:SetPoint("TOPLEFT",panel,"TOPLEFT",32,-202)
    local background=canvas:CreateTexture(nil,"BACKGROUND")
    background:SetAllPoints(canvas)
    local grid={}
    for i=1,3 do
        local stripe=canvas:CreateTexture(nil,"ARTWORK")
        stripe:SetSize(439,1)
        stripe:SetPoint("BOTTOMLEFT",canvas,"BOTTOMLEFT",21,20+(i-1)*58)
        Paint(stripe,0.55,0.57,0.58,i==1 and 0.46 or 0.20)
        grid[i]=stripe
    end
    local top=Label(canvas,"GameFontHighlightSmall","",22,-6,350)
    local bottom=Label(canvas,"GameFontHighlightSmall","",22,-126,350)
    local source=Label(panel,"GameFontHighlightSmall",
        "Only completed scans are plotted. No sales prices inferred.",28,-380,500)
    local dates=Label(panel,"GameFontHighlightSmall",
        "Existing storage: last 7 observations per item. No new data collected.",28,-401,505)
    local details=Label(panel,"GameFontHighlightSmall",
        "Chart lab is read-only and available only through settings.",28,-421,505)
    local segments,barStrips,dots={},{},{}
    local linesReady=type(canvas.CreateLine)=="function"
    if linesReady then
        for i=1,MAX_POINTS-1 do
            local ok,line=pcall(canvas.CreateLine,canvas,nil,"ARTWORK")
            if not ok or not line or
                type(line.SetStartPoint)~="function" or
                type(line.SetEndPoint)~="function" or
                type(line.SetColorTexture)~="function" or
                type(line.SetThickness)~="function" then
                linesReady=false
                break
            end
            local configured=pcall(function()
                line:SetThickness(2)
                line:SetColorTexture(0.91,0.73,0.42,1)
                line:Hide()
            end)
            if not configured then linesReady=false;break end
            segments[#segments+1]=line
        end
    end
    for i=1,MAX_POINTS do
        local bar=canvas:CreateTexture(nil,"ARTWORK")
        Paint(bar,0.76,0.61,0.35,0.75)
        bar:Hide()
        barStrips[i]=bar
        local dot=CreateFrame("Button",nil,canvas)
        dot:SetSize(12,12)
        local fill=dot:CreateTexture(nil,"ARTWORK")
        fill:SetAllPoints(dot)
        Paint(fill,0.98,0.81,0.47,1)
        dot:EnableMouse(true)
        dot:Hide()
        dot:SetScript("OnEnter",function(self)
            local sample=self.chartSample
            local tooltip=GameTooltip
            if not sample or not tooltip or
                type(tooltip.SetOwner)~="function" or
                type(tooltip.AddLine)~="function" then return end
            tooltip:SetOwner(self,"ANCHOR_RIGHT")
            if type(tooltip.ClearLines)=="function" then tooltip:ClearLines() end
            if type(ChalkBox_TipLine)=="function" then
                ChalkBox_TipLine(tooltip,DateLabel(sample.t),"title")
                ChalkBox_TipMetric(tooltip,"Lowest ask / unit",
                    Money(sample.low),"value")
                ChalkBox_TipLine(tooltip,
                    "Observed asking price, not a completed sale","muted")
            else
                tooltip:AddLine(DateLabel(sample.t),1,0.83,0.45)
                tooltip:AddLine("Lowest ask / unit: "..Money(sample.low),
                    0.90,0.93,0.95)
                tooltip:AddLine("Asking price, not a completed sale",
                    0.65,0.70,0.73)
            end
            if type(tooltip.Show)=="function" then tooltip:Show() end
        end)
        dot:SetScript("OnLeave",function()
            if GameTooltip and type(GameTooltip.Hide)=="function" then
                GameTooltip:Hide()
            end
        end)
        dots[i]=dot
    end
    local selectedID
    local function Clear()
        for _,line in ipairs(segments) do line:Hide() end
        for _,bar in ipairs(barStrips) do bar:Hide() end
        for _,dot in ipairs(dots) do dot:Hide();dot.chartSample=nil end
        top:SetText("")
        bottom:SetText("")
    end
    local function Plot()
        Clear()
        local status=type(ChalkBox_AuctionStatus)=="function"
            and ChalkBox_AuctionStatus() or {}
        if not selectedID then
            source:SetText("Prices are asking prices, not confirmed sales.")
            return
        end
        local data=type(ChalkBox_AuctionChartHistory)=="function"
            and ChalkBox_AuctionChartHistory(selectedID) or nil
        if not data then
            result:SetText("No current saved snapshot for that item on this realm/faction.")
            return
        end
        local points=data.points or {}
        result:SetText((data.name or "Item").." (#"..tostring(data.itemID)..
            ")  |  "..#points.." recorded observations")
        source:SetText((data.realm or "?").." / "..(data.faction or "?")..
            "  |  "..(data.source=="full" and "Full listing" or "Browse")..
            " low asks"..(data.mixed and "  |  VARIANTS MIXED" or ""))
        dates:SetText(#points>0 and
            (DateLabel(points[1].t).."  to  "..
             DateLabel(points[#points].t).."  |  newest 7 scans retained") or
            "No saved price observations yet.")
        if #points==0 then
            details:SetText("No recorded prices to draw yet.")
            return
        end
        if #points==1 then
            details:SetText("One scan recorded. Scan again later for a trend.")
        end
        local low,high=points[1].low,points[1].low
        for _,p in ipairs(points) do
            if p.low<low then low=p.low end
            if p.low>high then high=p.low end
        end
        local range=high-low
        local padding=range>0 and range*0.12 or math.max(1,high*0.08)
        local floor=math.max(0,low-padding)
        local ceiling=high+padding
        local delta=math.max(1,ceiling-floor)
        top:SetText("High "..Money(high))
        bottom:SetText("Low "..Money(low))
        -- Real horizontal time spacing. Equal timestamps use fixed spacing.
        local firstTime,lastTime=points[1].t,points[#points].t
        local coordinates={}
        for i,p in ipairs(points) do
            local fraction
            if #points==1 then fraction=0.5
            elseif lastTime==firstTime then fraction=(i-1)/(#points-1)
            else fraction=(p.t-firstTime)/(lastTime-firstTime) end
            local x=24+fraction*429
            local y=22+(p.low-floor)/delta*115
            coordinates[i]={x=x,y=y}
            local dot=dots[i]
            dot:ClearAllPoints()
            dot:SetPoint("CENTER",canvas,"BOTTOMLEFT",x,y)
            dot.chartSample=p
            dot:Show()
        end
        local asLine=linesReady and #points>1
        if asLine then
            for i=1,#points-1 do
                local a,b=coordinates[i],coordinates[i+1]
                local line=segments[i]
                local ok=pcall(function()
                    line:SetStartPoint("BOTTOMLEFT",canvas,a.x,a.y)
                    line:SetEndPoint("BOTTOMLEFT",canvas,b.x,b.y)
                    line:Show()
                end)
                if not ok then asLine=false;break end
            end
            if not asLine then
                for _,line in ipairs(segments) do line:Hide() end
            end
        end
        if not asLine then
            -- Not every Forever build exposes Line. Native texture columns
            -- still show the same REAL samples without a dependency.
            for i,p in ipairs(coordinates) do
                local bar=barStrips[i]
                bar:SetSize(11,math.max(1,p.y-20))
                bar:ClearAllPoints()
                bar:SetPoint("BOTTOM",canvas,"BOTTOMLEFT",p.x,20)
                bar:Show()
            end
        end
        if #points>1 then
            details:SetText(asLine and
                "Native Line renderer  |  Hover points for recorded prices." or
                "Texture fallback  |  Hover samples for recorded prices.")
        end
    end
    local function Find()
        local query=type(input.GetText)=="function" and input:GetText() or ""
        if type(query)~="string" then return end
        query=query:match("^%s*(.-)%s*$"):sub(1,72)
        selectedID=nil
        if query=="" then
            result:SetText("Enter an item name or numeric item ID, then Find.")
            Clear();return
        end
        local found=type(ChalkBox_AuctionRows)=="function"
            and ChalkBox_AuctionRows(query,40) or {}
        local wanted=tonumber(query)
        local selected
        for _,item in ipairs(found) do
            if wanted and wanted==item.itemID or
                (type(item.name)=="string" and
                item.name:lower()==query:lower()) then
                selected=item;break
            end
        end
        selected=selected or found[1]
        if not selected or not Number(selected.itemID) then
            result:SetText("No matching item in the saved market snapshot.")
            Clear();return
        end
        selectedID=selected.itemID
        Plot()
    end
    local findButton=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate")
    findButton:SetSize(138,25)
    findButton:SetPoint("TOPLEFT",panel,"TOPLEFT",360,-132)
    findButton:SetText("Find Item")
    findButton:SetScript("OnClick",Find)
    input:SetScript("OnEnterPressed",function(self)
        Find()
        if self.ClearFocus then self:ClearFocus() end
    end)
    local function Refresh()
        local r,g,b,a=0.055,0.065,0.08,0.8
        if type(ChalkBox_ThemeBackground)=="function" then
            r,g,b,a=ChalkBox_ThemeBackground(0.8)
        end
        Paint(background,r,g,b,math.max(0.38,a))
        if selectedID then Plot() end
    end
    return Refresh
end
