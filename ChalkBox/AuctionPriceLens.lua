-- Price Lens: an optional, read-only market research companion to the
-- native Forever Auction House Buy page. No queries, bids, purchases, native
-- displayMode writes, tab registry edits, or protected frame manipulation.
-- All numbers come from the existing, bounded AuctionSense scan history.
local lens,launcher,host
local selectedID,pinned=nil,false
local lastScanKey
local fonts={}
local dots,lines,columns={},{},{}
local nativeLines=false
local palette={
    bronze={0.96,0.77,0.44},green={0.40,0.90,0.66},
    red={0.98,0.54,0.42},blue={0.65,0.79,0.98},
    text={0.87,0.90,0.94},muted={0.64,0.70,0.76},
    warning={0.98,0.67,0.33},
}
local function Public(v)
    return type(issecretvalue)~="function" or not issecretvalue(v)
end
local function Valid(v)
    return Public(v) and type(v)=="number" and v==v and
        v>=0 and v<1e13
end
local function ItemID(item)
    if not Public(item) then return end
    if Valid(item) and item%1==0 and item>0 then return item end
    if type(item)~="string" then return end
    local id=item:match("item:(%d+)") or item:match("^%s*(%d+)%s*$")
    id=tonumber(id)
    if Valid(id) and id%1==0 and id>0 then return id end
end
local function Money(value)
    if not Valid(value) then return "—" end
    local n=math.floor(value+0.5)
    local g,s,c=math.floor(n/10000),math.floor(n%10000/100),n%100
    if g>0 then return ("%dg %ds %dc"):format(g,s,c) end
    if s>0 then return ("%ds %dc"):format(s,c) end
    return c.."c"
end
local function Age(age)
    if not Valid(age) then return "No scan time" end
    if age<60 then return "Just now" end
    if age<3600 then return math.floor(age/60).."m ago" end
    if age<86400 then return math.floor(age/3600).."h ago" end
    return math.floor(age/86400).."d ago"
end
local function Paint(texture,r,g,b,a)
    if not texture then return end
    if type(texture.SetTexture)=="function" and
        type(texture.SetVertexColor)=="function" then
        texture:SetTexture("Interface\\Buttons\\WHITE8X8")
        texture:SetVertexColor(r,g,b,a)
    elseif type(texture.SetColorTexture)=="function" then
        texture:SetColorTexture(r,g,b,a)
    end
end
local function Text(parent,style,x,y,w)
    local t=parent:CreateFontString(nil,"OVERLAY",style or "GameFontHighlightSmall")
    t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    t:SetWidth(w)
    if type(t.SetJustifyH)=="function" then t:SetJustifyH("LEFT") end
    fonts[#fonts+1]=t
    return t
end
local function Tint(t,c)
    if t and type(t.SetTextColor)=="function" then
        t:SetTextColor(c[1],c[2],c[3],1)
    end
end
local function Button(parent,label,x,y,w,fn)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(w,23)
    b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    b:SetText(label)
    b:SetScript("OnClick",fn)
    return b
end
local function Tip(owner,title,detail)
    local t=GameTooltip
    if not t or type(t.SetOwner)~="function" or
        type(t.AddLine)~="function" then return end
    t:SetOwner(owner,"ANCHOR_RIGHT")
    if type(t.ClearLines)=="function" then t:ClearLines() end
    t:AddLine(title,0.96,0.80,0.48)
    if detail then t:AddLine(detail,0.84,0.89,0.93) end
    t:AddLine("Recorded low asking prices, not completed sales.",
        0.65,0.70,0.75)
    if type(t.Show)=="function" then t:Show() end
end
local function HideTip()
    if GameTooltip and type(GameTooltip.Hide)=="function" then
        GameTooltip:Hide()
    end
end
local function SafeDate(timestamp)
    if type(date)=="function" then
        local ok,v=pcall(date,"%b %d, %H:%M",timestamp)
        if ok and type(v)=="string" then return v end
    end
    return "Scan "..tostring(timestamp)
end
local function ClearPlot()
    for _,line in ipairs(lines) do line:Hide() end
    for _,bar in ipairs(columns) do bar:Hide() end
    for _,dot in ipairs(dots) do
        dot.sample=nil
        dot:Hide()
    end
end
local function Draw(points)
    ClearPlot()
    if #points==0 then return end
    local low,high=points[1].low,points[1].low
    for _,p in ipairs(points) do
        low=math.min(low,p.low)
        high=math.max(high,p.low)
    end
    local span=high-low
    local pad=span>0 and span*0.12 or math.max(1,high*0.06)
    local origin=math.max(0,low-pad)
    local scale=math.max(1,high+pad-origin)
    local t0,t1=points[1].t,points[#points].t
    local xy={}
    for i,p in ipairs(points) do
        local fraction=(#points==1) and 0.5 or
            ((t1==t0) and ((i-1)/(#points-1)) or ((p.t-t0)/(t1-t0)))
        local x=12+fraction*280
        local y=10+(p.low-origin)/scale*47
        xy[i]={x=x,y=y}
        local dot=dots[i]
        dot:ClearAllPoints()
        dot:SetPoint("CENTER",lens.chart,"BOTTOMLEFT",x,y)
        dot.sample=p
        dot:Show()
    end
    local useLine=nativeLines and #points>1
    if useLine then
        for i=1,#points-1 do
            local line=lines[i]
            local ok=pcall(function()
                line:SetStartPoint("BOTTOMLEFT",lens.chart,xy[i].x,xy[i].y)
                line:SetEndPoint("BOTTOMLEFT",lens.chart,xy[i+1].x,xy[i+1].y)
                line:Show()
            end)
            if not ok then useLine=false;break end
        end
    end
    if not useLine then
        for _,line in ipairs(lines) do line:Hide() end
        for i,p in ipairs(xy) do
            local bar=columns[i]
            bar:ClearAllPoints()
            bar:SetPoint("BOTTOM",lens.chart,"BOTTOMLEFT",p.x,8)
            bar:SetSize(6,math.max(2,p.y-8))
            bar:Show()
        end
    end
end
local function ValidPoints(data)
    local points={}
    if type(data)~="table" or type(data.points)~="table" then return points end
    for _,p in ipairs(data.points) do
        if type(p)=="table" and Valid(p.t) and Valid(p.low) and
            p.t>0 and p.low>0 then
            points[#points+1]={t=p.t,low=p.low}
            if #points==7 then break end
        end
    end
    table.sort(points,function(a,b) return a.t<b.t end)
    return points
end
local function Render()
    if not lens then return end
    lens.pinButton:SetText(pinned and "Unpin" or "Pin")
    if launcher then launcher:SetText(lens:IsShown() and "Lens ●" or "Price Lens") end
    ClearPlot()
    if not selectedID then
        lens.item:SetText("Choose an item to inspect")
        lens.market:SetText("Hover an AH item or search your saved scans")
        lens.price:SetText("—")
        lens.delta:SetText("No chart")
        lens.range:SetText("No price observations selected")
        lens.foot:SetText("Up to 7 real scans  ·  No automatic AH queries")
        Tint(lens.delta,palette.muted)
        return
    end
    local fn=ChalkBox_AuctionChartHistory
    local ok,data=false,nil
    if type(fn)=="function" then ok,data=pcall(fn,selectedID) end
    local price
    if type(ChalkBox_AuctionPrice)=="function" then
        local got,value=pcall(ChalkBox_AuctionPrice,selectedID)
        if got and type(value)=="table" then price=value end
    end
    if not ok or type(data)~="table" then
        lens.item:SetText("Item #"..tostring(selectedID))
        lens.market:SetText("No saved history for this realm / faction")
        lens.price:SetText("—")
        lens.delta:SetText("No data")
        lens.range:SetText("Scan the market when you're ready")
        lens.foot:SetText("No auction requests were made")
        Tint(lens.delta,palette.muted)
        return
    end
    local name=type(data.name)=="string" and data.name or
        ("Item #"..tostring(selectedID))
    lens.item:SetText(#name>39 and (name:sub(1,37).."...") or name)
    local market=(type(data.realm)=="string" and data.realm or "?")..
        " / "..(type(data.faction)=="string" and data.faction or "?")
    local points=ValidPoints(data)
    lens.market:SetText(market.."  ·  "..#points..
        (#points==1 and " scan" or " scans"))
    if #points==0 then
        lens.price:SetText("—")
        lens.delta:SetText("No samples")
        lens.range:SetText("No usable recorded prices")
        lens.foot:SetText("Market scans only; never a live buying quote")
        Tint(lens.delta,palette.muted)
        return
    end
    local latest=points[#points].low
    lens.price:SetText(Money(latest))
    local low,high=latest,latest
    for _,p in ipairs(points) do
        low=math.min(low,p.low)
        high=math.max(high,p.low)
    end
    lens.range:SetText("LOW "..Money(low).."   HIGH "..Money(high))
    local age=price and price.age or nil
    local stamp=Age(age)
    local mixed=data.mixed==true or (price and price.mixed)
    if mixed then
        lens.delta:SetText("MIXED GEAR")
        Tint(lens.delta,palette.warning)
    elseif #points<2 then
        lens.delta:SetText("1 sample")
        Tint(lens.delta,palette.muted)
    else
        local change=(latest/points[1].low-1)*100
        if change>0.05 then
            lens.delta:SetText(("+%.1f%% ASK"):format(change))
            Tint(lens.delta,palette.red)
        elseif change< -0.05 then
            lens.delta:SetText(("%.1f%% ASK"):format(change))
            Tint(lens.delta,palette.green)
        else
            lens.delta:SetText("≈ FLAT ASK")
            Tint(lens.delta,palette.muted)
        end
    end
    lens.foot:SetText((mixed and "Mixed variants · Compare exact gear  |  " or
        "Historic low asks, not sales  |  ")..
        (price and price.stale and "STALE " or "")..stamp)
    Draw(points)
end
local function Select(item,origin)
    local id=ItemID(item)
    if not id then return false end
    if pinned and origin=="hover" then return false end
    if selectedID~=id then
        selectedID=id
        lastScanKey=nil
        Render()
    end
    return true
end
local function Search(input)
    if not Public(input) or type(input)~="string" then return false end
    local id=ItemID(input)
    if not id and type(ChalkBox_AuctionRows)=="function" then
        local ok,found=pcall(ChalkBox_AuctionRows,input,40)
        if ok and type(found)=="table" then
            local exact,only,amount=nil,nil,0
            for _,entry in ipairs(found) do
                if type(entry)=="table" and ItemID(entry.itemID) then
                    amount=amount+1;only=entry.itemID
                    if type(entry.name)=="string" and
                        entry.name:lower()==input:lower() then
                        exact=entry.itemID
                        break
                    end
                end
            end
            id=exact or (amount==1 and only or nil)
            if not id and lens then
                lens.market:SetText(amount>1 and
                    "Several matches. Refine your search." or
                    "No item matches saved market data.")
            end
        end
    end
    if not id then return false end
    pinned=false
    return Select(id,"search")
end
local function IsAuctionItemTooltip(tooltip)
    if not lens or not lens:IsShown() or pinned or not host then return false end
    if not tooltip or type(tooltip.GetOwner)~="function" then return false end
    local ok,owner=pcall(tooltip.GetOwner,tooltip)
    if not ok or not owner then return false end
    for _=1,12 do
        if owner==host then return true end
        if owner==lens or owner==launcher then return false end
        if type(owner.GetParent)~="function" then break end
        ok,owner=pcall(owner.GetParent,owner)
        if not ok or not owner then break end
    end
    return false
end
function ChalkBox_PriceLensObserveTooltip(tooltip,link)
    if not IsAuctionItemTooltip(tooltip) then return false end
    return Select(link,"hover")
end
function ChalkBox_PriceLensSelect(item)
    return lens and lens:IsShown() and Select(item,"manual") or false
end
function ChalkBox_PriceLensStatus()
    return {attached=lens~=nil,shown=lens and lens:IsShown() or false,
        selectedID=selectedID,pinned=pinned}
end
function ChalkBox_PriceLensRefresh()
    if not lens or not lens:IsShown() or not selectedID then return end
    local fn=ChalkBox_AuctionStatus
    if type(fn)~="function" then return end
    local ok,status=pcall(fn)
    if not ok or type(status)~="table" then return end
    local key=tostring(status.marketKey or "")..":"..
        tostring(status.scannedAt or "")
    if key~=lastScanKey then lastScanKey=key;Render() end
end
function ChalkBox_PriceLensAttach()
    if lens then return true end
    host=AuctionHouseFrame
    if not host or not UIParent or type(CreateFrame)~="function" then
        return false
    end
    local b=CreateFrame("Button","ChalkBoxPriceLensButton",host,
        "UIPanelButtonTemplate")
    b:SetSize(105,25)
    local right=type(UIParent.GetRight)=="function" and
        UIParent:GetRight() or nil
    local hostRight=type(host.GetRight)=="function" and
        host:GetRight() or nil
    local canRight=not (Valid(right) and Valid(hostRight) and
        right-hostRight<350)
    local side=canRight and "right" or "left"
    if canRight then
        b:SetPoint("TOPLEFT",host,"TOPRIGHT",8,-54)
    else
        b:SetPoint("TOPRIGHT",host,"TOPLEFT",-8,-54)
    end
    launcher=b
    local f=CreateFrame("Frame","ChalkBoxPriceLens",host)
    f:SetSize(326,296)
    if canRight then
        f:SetPoint("TOPLEFT",b,"BOTTOMLEFT",0,-4)
    else
        f:SetPoint("TOPRIGHT",b,"BOTTOMRIGHT",0,-4)
    end
    if type(f.SetFrameStrata)=="function" then
        f:SetFrameStrata("FULLSCREEN_DIALOG")
    end
    if type(f.SetFrameLevel)=="function" and
        type(host.GetFrameLevel)=="function" then
        local level=host:GetFrameLevel()
        if Valid(level) then f:SetFrameLevel(level+25) end
    end
    if type(f.SetClampedToScreen)=="function" then
        f:SetClampedToScreen(true)
    end
    if type(f.SetMovable)=="function" then f:SetMovable(true) end
    if type(f.EnableMouse)=="function" then f:EnableMouse(true) end
    if type(f.RegisterForDrag)=="function" then
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart",function(self)
            if type(InCombatLockdown)=="function" and
                InCombatLockdown() then return end
            if type(self.StartMoving)=="function" then self:StartMoving() end
        end)
        f:SetScript("OnDragStop",function(self)
            if type(self.StopMovingOrSizing)=="function" then
                self:StopMovingOrSizing()
            end
        end)
    end
    local background=f:CreateTexture(nil,"BACKGROUND")
    background:SetAllPoints(f)
    Paint(background,0.045,0.053,0.058,0.97)
    local edge=f:CreateTexture(nil,"ARTWORK")
    edge:SetPoint("TOPLEFT",f,"TOPLEFT",0,0)
    edge:SetSize(326,2)
    Paint(edge,0.87,0.66,0.33,1)
    Text(f,"GameFontNormal",11,-12,170):SetText("PRICE LENS")
    Text(f,"GameFontHighlightSmall",11,-29,195):SetText("AuctionSense · Research only")
    lens=f
    local pin=Button(f,"Pin",208,-10,52,function()
        if not selectedID then return end
        pinned=not pinned
        Render()
    end)
    lens.pinButton=pin
    Button(f,"X",269,-10,44,function() f:Hide();Render() end)
    local box=CreateFrame("EditBox",nil,f,"InputBoxTemplate")
    box:SetSize(205,24)
    box:SetPoint("TOPLEFT",f,"TOPLEFT",13,-52)
    if type(box.SetAutoFocus)=="function" then box:SetAutoFocus(false) end
    if type(box.SetMaxLetters)=="function" then box:SetMaxLetters(75) end
    if type(box.SetScript)=="function" then
        box:SetScript("OnEnterPressed",function(self)
            Search(type(self.GetText)=="function" and self:GetText() or "")
            if type(self.ClearFocus)=="function" then self:ClearFocus() end
        end)
        box:SetScript("OnEscapePressed",function(self)
            if type(self.ClearFocus)=="function" then self:ClearFocus() end
        end)
    end
    lens.search=box
    Button(f,"Find",234,-52,78,function()
        Search(type(box.GetText)=="function" and box:GetText() or "")
    end)
    lens.item=Text(f,"GameFontNormal",12,-86,300)
    lens.market=Text(f,"GameFontHighlightSmall",12,-108,300)
    Tint(lens.market,palette.muted)
    Text(f,"GameFontHighlightSmall",12,-130,160):SetText("LATEST LOW ASK / UNIT")
    lens.price=Text(f,"GameFontNormalLarge",12,-145,176)
    Tint(lens.price,palette.bronze)
    lens.delta=Text(f,"GameFontHighlight",194,-147,120)
    Tint(lens.delta,palette.muted)
    local canvas=CreateFrame("Frame",nil,f)
    canvas:SetSize(304,74)
    canvas:SetPoint("TOPLEFT",f,"TOPLEFT",11,-175)
    lens.chart=canvas
    local graphBG=canvas:CreateTexture(nil,"BACKGROUND")
    graphBG:SetAllPoints(canvas)
    Paint(graphBG,0.025,0.036,0.042,0.93)
    for y=8,57,24 do
        local grid=canvas:CreateTexture(nil,"ARTWORK")
        grid:SetSize(304,1)
        grid:SetPoint("BOTTOMLEFT",canvas,"BOTTOMLEFT",0,y)
        Paint(grid,0.35,0.48,0.47,0.20)
    end
    nativeLines=type(canvas.CreateLine)=="function"
    if nativeLines then
        for i=1,6 do
            local ok,line=pcall(canvas.CreateLine,canvas,nil,"ARTWORK")
            if not ok or not line or type(line.SetStartPoint)~="function" or
                type(line.SetEndPoint)~="function" or
                type(line.SetThickness)~="function" or
                type(line.SetColorTexture)~="function" then
                nativeLines=false;break
            end
            local valid=pcall(function()
                line:SetThickness(2)
                line:SetColorTexture(0.42,0.91,0.74,1)
                line:Hide()
            end)
            if not valid then nativeLines=false;break end
            lines[#lines+1]=line
        end
    end
    for i=1,7 do
        local bar=canvas:CreateTexture(nil,"ARTWORK")
        Paint(bar,0.42,0.91,0.74,0.85)
        bar:Hide()
        columns[i]=bar
        local dot=CreateFrame("Button",nil,canvas)
        dot:SetSize(10,10)
        local fill=dot:CreateTexture(nil,"ARTWORK")
        fill:SetAllPoints(dot)
        Paint(fill,1,0.83,0.48,1)
        dot:SetScript("OnEnter",function(self)
            local p=self.sample
            if p then Tip(self,SafeDate(p.t),
                "Lowest observed ask / unit: "..Money(p.low)) end
        end)
        dot:SetScript("OnLeave",HideTip)
        dot:Hide()
        dots[i]=dot
    end
    lens.range=Text(f,"GameFontHighlightSmall",12,-255,301)
    Tint(lens.range,palette.blue)
    lens.foot=Text(f,"GameFontHighlightSmall",12,-277,301)
    Tint(lens.foot,palette.muted)
    f:SetScript("OnShow",function()
        lastScanKey=nil
        Render()
    end)
    if type(host.HookScript)=="function" then
        host:HookScript("OnHide",function()
            f:Hide()
            pinned=false
        end)
    end
    b:SetScript("OnClick",function()
        if f:IsShown() then f:Hide()
        else f:Show() end
        Render()
    end)
    f:Hide()
    Render()
    return true
end
function ChalkBox_PriceLensToggle(open)
    if not ChalkBox_PriceLensAttach() then return false end
    if type(InCombatLockdown)=="function" and InCombatLockdown() then
        return false
    end
    if type(host.IsShown)=="function" and not host:IsShown() then
        return false
    end
    if open==false or (open==nil and lens:IsShown()) then lens:Hide()
    else lens:Show() end
    Render()
    return true
end
function ChalkBox_PriceLensCommand(input)
    if not ChalkBox_PriceLensAttach() then return false end
    input=type(input)=="string" and input or ""
    if input=="off" or input=="hide" then return ChalkBox_PriceLensToggle(false) end
    if input=="on" or input=="show" or input=="" then
        return ChalkBox_PriceLensToggle(true)
    end
    if not ChalkBox_PriceLensToggle(true) then return false end
    return Search(input)
end
