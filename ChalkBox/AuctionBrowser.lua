-- AuctionSense Browser: an independent, research-only auction tab.
-- It browses saved market observations and never queries, bids, buys,
-- changes Blizzard displayMode, or hooks Blizzard's item comparison tooltips.
-- Row hover drives the chart INSIDE our pane; no popup item tooltip at all.
local pane,labels,rows=nil,{},{}
local selectedID,pinned=nil,false
local search,filter,sort,page="","all","name",1
local source="saved" -- live browse summaries only when explicitly selected
local nativeGeneration=0
local nativeSeenAt=nil
local nativeItems={}
local nativeSnapshotGeneration=-1
local nativeAvailable=false
local nativeRequestPending=false
local nativeRequestElapsed=0
local nativeMessage=nil
local results,cacheKey={},nil
local redrawClock=0
local drawnLines,dots,bars={}, {}, {}
local lineReady=false
local MAX_VISIBLE=8
local colors={
    good={0.40,0.90,0.67},bronze={0.97,0.78,0.42},
    muted={0.65,0.70,0.75},text={0.86,0.88,0.90},
    blue={0.52,0.77,0.97},warn={0.98,0.66,0.33},
}
local function Public(value)
    return type(issecretvalue)~="function" or not issecretvalue(value)
end
local function Positive(value)
    return Public(value) and type(value)=="number" and value==value and
        value>=0 and value<1e13
end
local function Coin(value)
    if not Positive(value) then return "—" end
    value=math.floor(value+0.5)
    local g,s,c=math.floor(value/10000),math.floor(value%10000/100),value%100
    if g>0 then return ("%dg %ds %dc"):format(g,s,c) end
    if s>0 then return ("%ds %dc"):format(s,c) end
    return c.."c"
end
local function Age(age)
    if not Positive(age) then return "Never" end
    if age<60 then return "Just now" end
    if age<3600 then return math.floor(age/60).."m ago" end
    if age<86400 then return math.floor(age/3600).."h ago" end
    return math.floor(age/86400).."d ago"
end
local function Paint(texture,r,g,b,a)
    if type(texture.SetTexture)=="function" and
        type(texture.SetVertexColor)=="function" then
        texture:SetTexture("Interface\\Buttons\\WHITE8X8")
        texture:SetVertexColor(r,g,b,a)
    elseif type(texture.SetColorTexture)=="function" then
        texture:SetColorTexture(r,g,b,a)
    end
end
local function Font(parent,style,x,y,width)
    local f=parent:CreateFontString(nil,"OVERLAY",style or "GameFontHighlightSmall")
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    f:SetWidth(width)
    if type(f.SetJustifyH)=="function" then f:SetJustifyH("LEFT") end
    return f
end
local function Tint(label,color)
    if label and type(label.SetTextColor)=="function" then
        label:SetTextColor(color[1],color[2],color[3],1)
    end
end
local function Button(parent,text,x,y,width,action)
    local button=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    button:SetSize(width,23)
    button:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    button:SetText(text)
    button:SetScript("OnClick",action)
    return button
end
local function DateText(stamp)
    if type(date)=="function" then
        local ok,value=pcall(date,"%b %d %H:%M",stamp)
        if ok and type(value)=="string" then return value end
    end
    return "Recorded "..tostring(stamp)
end
local function CleanPoints(data)
    local saved={}
    if type(data)=="table" and type(data.points)=="table" then
        for _,sample in ipairs(data.points) do
            if type(sample)=="table" and Positive(sample.t) and sample.t>0 and
                Positive(sample.low) and sample.low>0 then
                saved[#saved+1]={t=sample.t,low=sample.low}
                if #saved==7 then break end
            end
        end
    end
    table.sort(saved,function(a,b) return a.t<b.t end)
    return saved
end
local function ClearPlot()
    for _,line in ipairs(drawnLines) do line:Hide() end
    for _,bar in ipairs(bars) do bar:Hide() end
    for _,dot in ipairs(dots) do
        dot.sample=nil
        dot:Hide()
    end
end
local function Draw(points)
    ClearPlot()
    if #points==0 then return end
    local lowest,highest=points[1].low,points[1].low
    for _,sample in ipairs(points) do
        lowest=math.min(lowest,sample.low)
        highest=math.max(highest,sample.low)
    end
    local range=highest-lowest
    local pad=range>0 and range*0.12 or math.max(1,highest*0.06)
    local floor=math.max(0,lowest-pad)
    local scale=math.max(1,highest+pad-floor)
    local t0,t1=points[1].t,points[#points].t
    local plot={}
    for i,sample in ipairs(points) do
        local at
        if #points==1 then at=0.5
        elseif t1==t0 then at=(i-1)/(#points-1)
        else at=(sample.t-t0)/(t1-t0) end
        local x=15+at*285
        local y=10+(sample.low-floor)/scale*99
        plot[i]={x=x,y=y}
        local dot=dots[i]
        dot.sample=sample
        dot:ClearAllPoints()
        dot:SetPoint("CENTER",labels.chart,"BOTTOMLEFT",x,y)
        dot:Show()
    end
    local asLines=lineReady and #points>1
    if asLines then
        for i=1,#points-1 do
            local line=drawnLines[i]
            local a,b=plot[i],plot[i+1]
            local ok=pcall(function()
                line:SetStartPoint("BOTTOMLEFT",labels.chart,a.x,a.y)
                line:SetEndPoint("BOTTOMLEFT",labels.chart,b.x,b.y)
                line:Show()
            end)
            if not ok then asLines=false;break end
        end
    end
    if not asLines then
        for _,line in ipairs(drawnLines) do line:Hide() end
        for i,p in ipairs(plot) do
            local bar=bars[i]
            bar:ClearAllPoints()
            bar:SetPoint("BOTTOM",labels.chart,"BOTTOMLEFT",p.x,10)
            bar:SetSize(6,math.max(2,p.y-10))
            bar:Show()
        end
    end
end
local function DrawDetails()
    if not pane then return end
    ClearPlot()
    labels.pin:SetText(pinned and "Unpin" or "Pin")
    if not selectedID then
        labels.item:SetText("Choose an item")
        labels.context:SetText("Hover an item in the list to examine its history")
        labels.price:SetText("—")
        labels.trend:SetText("NO HISTORY")
        labels.range:SetText("Past low asking prices will appear here")
        labels.detail:SetText("Your existing market scans power these charts")
        Tint(labels.trend,colors.muted)
        return
    end
    local current=nil
    if source=="live" then
        for _,row in ipairs(results) do
            if row.itemID==selectedID then current=row;break end
        end
    end
    local getter=ChalkBox_AuctionChartHistory
    local ok,data=false,nil
    if type(getter)=="function" then ok,data=pcall(getter,selectedID) end
    local points=ok and CleanPoints(data) or {}
    local name=current and current.name or
        (ok and type(data)=="table" and data.name) or
        ("Item #"..tostring(selectedID))
    if type(name)~="string" then name="Item #"..tostring(selectedID) end
    if #name>39 then name=name:sub(1,36).."..." end
    labels.item:SetText(name)
    local price
    if type(ChalkBox_AuctionPrice)=="function" then
        local got,value=pcall(ChalkBox_AuctionPrice,selectedID)
        if got and type(value)=="table" then price=value end
    end
    local realm=ok and type(data)=="table" and data.realm or nil
    local faction=ok and type(data)=="table" and data.faction or nil
    if not realm or not faction then
        local status=type(ChalkBox_AuctionStatus)=="function" and
            ChalkBox_AuctionStatus() or {}
        realm=realm or status.realm or "?"
        faction=faction or status.faction or "?"
    end
    labels.context:SetText(realm.." / "..faction.."  ·  "..
        (current and "CURRENT BROWSE / " or "")..#points..
        (#points==1 and " saved scan" or " saved scans"))
    if current then labels.price:SetText(Coin(current.low))
    elseif #points>0 then labels.price:SetText(Coin(points[#points].low))
    else labels.price:SetText("—") end
    if #points==0 then
        labels.trend:SetText(current and (current.mixed or current.variantSpecific)
            and "VARIANTS" or (current and "NO BASELINE" or "NO HISTORY"))
        labels.range:SetText(current and
            "Current low ask has no historical comparison" or
            "No saved asking prices for this item")
        labels.detail:SetText(current and
            "Observed native browse result (not a completed sale)" or
            "Run a Market scan to begin recording prices")
        Tint(labels.trend,colors.muted)
        return
    end
    local first,latest=points[1].low,points[#points].low
    local low,high=first,first
    for _,p in ipairs(points) do
        low=math.min(low,p.low);high=math.max(high,p.low)
    end
    labels.range:SetText("SAVED LOW "..Coin(low).."   HIGH "..Coin(high))
    local mixed=(type(data)=="table" and data.mixed==true) or
        (price and price.mixed==true) or
        (current and (current.mixed or current.variantSpecific))
    local age=price and price.age or nil
    if mixed then
        labels.trend:SetText("VARIANTS")
        Tint(labels.trend,colors.warn)
    elseif current and price and Positive(price.low) and price.low>0 and
        not price.stale then
        local change=(current.low/price.low-1)*100
        labels.trend:SetText(("%+.1f%% VS SCAN"):format(change))
        Tint(labels.trend,change<0 and colors.good or
            (change>0 and colors.warn or colors.muted))
    elseif current then
        labels.trend:SetText("OLD BASELINE")
        Tint(labels.trend,colors.muted)
    elseif #points<2 then
        labels.trend:SetText("1 SAMPLE")
        Tint(labels.trend,colors.muted)
    else
        local change=(latest/first-1)*100
        labels.trend:SetText(("%+.1f%% ASK"):format(change))
        Tint(labels.trend,change<0 and colors.good or
            (change>0 and colors.warn or colors.muted))
    end
    if current then
        labels.detail:SetText(
            (mixed and "No gear variant comparison  ·  " or
            (price and price.stale and "Saved price stale  ·  " or
            "Current browse vs saved  ·  "))..
            "scan "..Age(age))
    else
        labels.detail:SetText((mixed and "Mixed equipment variants  ·  " or
            "Recorded asks, not sales  ·  ")..
            (price and price.stale and "STALE  " or "")..Age(age))
    end
    Draw(points)
end
local function Select(id,fromHover)
    if fromHover and pinned then return false end
    if not Positive(id) or id<=0 or id%1~=0 then return false end
    if selectedID~=id then
        selectedID=id
        DrawDetails()
    end
    return true
end
local function Status()
    local fn=ChalkBox_AuctionStatus
    if type(fn)~="function" then return {} end
    local ok,value=pcall(fn)
    return ok and type(value)=="table" and value or {}
end
-- Read the currently LOADED native browse summaries without requesting
-- additional results or changing Blizzard's native Buy/Sell mode.
-- These are item-key-level lowest asking prices, NOT individual auctions.
local function CurrentNativeRows()
    if nativeSnapshotGeneration==nativeGeneration then
        return nativeItems,nativeAvailable
    end
    nativeSnapshotGeneration=nativeGeneration
    nativeItems={}
    nativeAvailable=false
    local ah=type(C_AuctionHouse)=="table" and C_AuctionHouse or nil
    local fn=ah and ah.GetBrowseResults
    if type(fn)~="function" then return nativeItems,false end
    local ok,list=pcall(fn)
    if not ok or type(list)~="table" then return nativeItems,false end
    nativeAvailable=true
    local found={}
    for i=1,math.min(#list,12000) do
        local info=list[i]
        if type(info)=="table" and Public(info.itemKey) and
            type(info.itemKey)=="table" then
            local key=info.itemKey
            local id=key.itemID
            local price=info.minPrice
            local qty=info.totalQuantity
            if Positive(id) and id>0 and id%1==0 and
                Positive(price) and price>0 and
                Positive(qty) and qty%1==0 then
                local variant=tostring(Public(key.itemSuffix) and
                    key.itemSuffix or 0)..":"..
                    tostring(Public(key.itemLevel) and
                    key.itemLevel or 0)..":"..
                    tostring(Public(key.battlePetSpeciesID) and
                    key.battlePetSpeciesID or 0)
                local variantSpecific=
                    (Positive(key.itemSuffix) and key.itemSuffix~=0) or
                    (Positive(key.itemLevel) and key.itemLevel~=0) or
                    (Positive(key.battlePetSpeciesID) and
                        key.battlePetSpeciesID~=0)
                local entry=found[id]
                if not entry then
                    local name
                    if type(ah.GetItemKeyInfo)=="function" then
                        local named,details=pcall(ah.GetItemKeyInfo,key)
                        if named and type(details)=="table" then
                            local candidate=details.itemName or details.name
                            if Public(candidate) and type(candidate)=="string" then
                                name=candidate
                            end
                        end
                    end
                    if not name and Public(info.name) and
                        type(info.name)=="string" then name=info.name end
                    if not name and type(ChalkBox_AuctionPrice)=="function" then
                        local saved,record=pcall(ChalkBox_AuctionPrice,id)
                        if saved and type(record)=="table" and
                            type(record.name)=="string" then
                            name=record.name
                        end
                    end
                    entry={itemID=id,name=name or ("Item #"..id),
                        low=price,quantity=0,current=true,
                        variant=variant,variantSpecific=variantSpecific}
                    found[id]=entry
                    nativeItems[#nativeItems+1]=entry
                end
                if entry.variant~=variant then entry.mixed=true end
                if variantSpecific then entry.variantSpecific=true end
                entry.low=math.min(entry.low,price)
                entry.quantity=entry.quantity+qty
            end
        end
    end
    return nativeItems,true
end
local function GetRows(status)
    local key=tostring(status.marketKey or "").."|"..
        tostring(status.scannedAt or "").."|"..search.."|"..filter.."|"..sort..
        "|" ..source.."|"..nativeGeneration
    if cacheKey==key then return results end
    cacheKey=key
    local all={}
    if source=="live" then
        if not nativeRequestPending then all=CurrentNativeRows() end
    else
        local getter=ChalkBox_AuctionRows
        local ok,data=false,nil
        if type(getter)=="function" then ok,data=pcall(getter,search,12000) end
        if ok and type(data)=="table" then all=data end
    end
    local clean={}
    for _,row in ipairs(all) do
        if type(row)=="table" and Positive(row.itemID) and
            row.itemID>0 and row.itemID%1==0 and
            (filter~="mixed" or row.mixed==true) and
            (source~="live" or search=="" or
                (type(row.name)=="string" and
                    row.name:lower():find(search:lower(),1,true)) or
                tostring(row.itemID):find(search,1,true)) then
            clean[#clean+1]=row
        end
    end
    if sort~="name" then
        table.sort(clean,function(a,b)
            local x=Positive(a.low) and a.low or -1
            local y=Positive(b.low) and b.low or -1
            if x==y then return a.itemID<b.itemID end
            if x<0 then return false end
            if y<0 then return true end
            if sort=="lowest" then return x<y end
            return x>y
        end)
    end
    results=clean
    return results
end
local function Refresh()
    if not pane or not pane:IsShown() then return end
    local status=Status()
    local all=GetRows(status)
    if source=="live" then
        labels.market:SetText((status.realm or "Unknown realm").." / "..
            (status.faction or "?").."  ·  "..
            (nativeRequestPending and "Searching AH..." or
                (#all.." loaded AH browse results (not entire AH)")))
    else
        labels.market:SetText((status.realm or "Unknown realm").." / "..
            (status.faction or "?").."  ·  "..#all..
            " saved items  ·  scanned "..Age(status.age))
    end
    labels.source:SetText(source=="live" and "AH Results" or "Saved")
    labels.filter:SetText(filter=="mixed" and "Mixed gear" or "All items")
    labels.sort:SetText(sort=="name" and "Name" or
        (sort=="lowest" and "Low ↑" or "Low ↓"))
    local height=type(pane.GetHeight)=="function" and pane:GetHeight() or 316
    if not Positive(height) then height=316 end
    local visible=math.max(1,math.min(MAX_VISIBLE,math.floor((height-192)/24)))
    local pages=math.max(1,math.ceil(#all/visible))
    page=math.max(1,math.min(page,pages))
    local offset=(page-1)*visible
    local firstVisible
    for i,row in ipairs(rows) do
        local entry=i<=visible and all[offset+i] or nil
        if entry then
            row.data=entry
            row.name:SetText(entry.name or "Item #"..tostring(entry.itemID))
            row.low:SetText(Coin(entry.low))
            local compare=nil
            if source=="live" and not entry.mixed and
                not entry.variantSpecific and
                type(ChalkBox_AuctionPrice)=="function" then
                local ok,reference=pcall(ChalkBox_AuctionPrice,entry.itemID)
                if ok and type(reference)=="table" and
                    Positive(reference.low) and reference.low>0 and
                    not reference.mixed and not reference.stale then
                    compare=(entry.low/reference.low-1)*100
                end
            end
            if source=="live" and compare then
                row.units:SetText(("%+.0f%% vs scan"):format(compare))
                Tint(row.units,compare<0 and colors.good or colors.warn)
            else
                row.units:SetText(entry.mixed and "MIXED" or
                    (Positive(entry.quantity) and
                    tostring(entry.quantity).." units" or "—"))
                Tint(row.units,entry.mixed and colors.warn or colors.muted)
            end
            if row.selected then
                if entry.itemID==selectedID then row.selected:Show()
                else row.selected:Hide() end
            end
            row:Show()
            firstVisible=firstVisible or entry.itemID
        else
            row.data=nil
            if row.selected then row.selected:Hide() end
            row:Hide()
        end
    end
    labels.page:SetText(("Page %d / %d"):format(page,pages))
    if labels.empty then
        labels.empty:SetText(#all==0 and
            (source=="live" and
                (nativeMessage or (nativeRequestPending and
                    "Searching AH... waiting for auction results." or
                    "Click Search AH, or search in Blizzard Buy.")) or
                "No matching saved prices. Clear the search/filter.") or "")
    end
    if #all==0 then
        selectedID=nil
        pinned=false
        labels.drawnKey=nil
        if source=="live" then
            labels.item:SetText(nativeRequestPending and
                "Searching the Auction House" or
                "No AH browse results loaded")
            labels.context:SetText("Search items in Blizzard Buy, then return here")
            labels.price:SetText("—")
            labels.trend:SetText("NOT A LIVE MARKET FEED")
            labels.range:SetText("The browser cannot invent current auctions")
            labels.detail:SetText("Switch to Saved for ChalkBox's recorded market")
            ClearPlot()
            return
        elseif (status.items or 0)>0 then
            labels.item:SetText("No matching saved items")
            labels.context:SetText("Clear search or switch to All items")
        end
    end
    local hadSelection=selectedID~=nil
    if not selectedID and firstVisible then Select(firstVisible,false) end
    if cacheKey~=labels.drawnKey then
        labels.drawnKey=cacheKey
        if hadSelection or not selectedID then DrawDetails() end
    end
end
local function ControlsChanged()
    page=1
    cacheKey=nil
    selectedID=nil
    pinned=false
    Refresh()
end
-- Only an explicit click or Enter may request a fresh native AH browse.
local function SearchAuctionHouse()
    if not pane or not pane:IsShown() then return false end
    local status=Status()
    if status.busy then
        nativeMessage="Market scan running. Finish it before Search AH."
        Refresh()
        return false
    end
    if type(InCombatLockdown)=="function" and InCombatLockdown() then
        nativeMessage="Cannot query auctions during combat."
        Refresh()
        return false
    end
    local ah=type(C_AuctionHouse)=="table" and C_AuctionHouse or nil
    if not ah or type(ah.SendBrowseQuery)~="function" then
        nativeMessage="Auction browse search API unavailable."
        source="live";ControlsChanged()
        return false
    end
    source="live"
    filter="all"
    nativeRequestPending=true
    nativeRequestElapsed=0
    nativeMessage=nil
    nativeGeneration=nativeGeneration+1
    nativeSnapshotGeneration=-1
    nativeItems={}
    ControlsChanged()
    local query={searchString=search:sub(1,70),sorts={},
        filters={},itemClassFilters={}}
    -- Set pending BEFORE the request: Forever can emit a synchronous
    -- result event from SendBrowseQuery.
    local ok,accepted=pcall(ah.SendBrowseQuery,query)
    if not ok or accepted==false then
        nativeRequestPending=false
        nativeMessage="Search AH was refused; retry at the auctioneer."
        cacheKey=nil
        Refresh()
        return false
    end
    Refresh()
    return true
end
function ChalkBox_AuctionBrowserMount(ah)
    if pane then return pane end
    if not ah or type(CreateFrame)~="function" then return nil end
    local f=CreateFrame("Frame","ChalkBoxAuctionBrowserPane",ah,"InsetFrameTemplate")
    f:SetPoint("TOPLEFT",ah,"TOPLEFT",13,-56)
    f:SetPoint("BOTTOMRIGHT",ah,"BOTTOMRIGHT",-13,68)
    if type(f.SetFrameLevel)=="function" then
        local level=type(ah.GetFrameLevel)=="function" and
            ah:GetFrameLevel() or 20
        f:SetFrameLevel(level+35)
    end
    if type(f.EnableMouse)=="function" then f:EnableMouse(true) end
    local bg=f:CreateTexture(nil,"BACKGROUND")
    bg:SetAllPoints(f)
    local atlas=false
    if type(bg.SetAtlas)=="function" then
        atlas=pcall(bg.SetAtlas,bg,"auctionhouse-background-index",false)
    end
    if not atlas then Paint(bg,0.12,0.10,0.085,1) end
    pane=f
    labels.title=Font(f,"GameFontNormalHuge",16,-8,340)
    labels.title:SetText("AuctionSense Browser")
    labels.market=Font(f,"GameFontHighlightSmall",17,-29,735)
    Tint(labels.market,colors.muted)
    local box=CreateFrame("EditBox",nil,f,"SearchBoxTemplate")
    box:SetSize(219,24)
    box:SetPoint("TOPLEFT",f,"TOPLEFT",16,-53)
    if type(box.SetAutoFocus)=="function" then box:SetAutoFocus(false) end
    if type(box.SetMaxLetters)=="function" then box:SetMaxLetters(70) end
    box:SetScript("OnTextChanged",function(self)
        local value=type(self.GetText)=="function" and self:GetText() or ""
        if value~=search then search=value;ControlsChanged() end
    end)
    box:SetScript("OnEnterPressed",function(self)
        SearchAuctionHouse()
        if type(self.ClearFocus)=="function" then self:ClearFocus() end
    end)
    box:SetScript("OnEscapePressed",function(self)
        if type(self.ClearFocus)=="function" then self:ClearFocus() end
    end)
    labels.search=box
    Button(f,"Search AH",243,-53,115,SearchAuctionHouse)
    labels.filter=Button(f,"All items",16,-85,105,function()
        filter=filter=="all" and "mixed" or "all"
        ControlsChanged()
    end)
    labels.sort=Button(f,"Name",128,-85,103,function()
        sort=sort=="name" and "lowest" or
            (sort=="lowest" and "highest" or "name")
        ControlsChanged()
    end)
    labels.source=Button(f,"Saved",239,-85,120,function()
        source=source=="saved" and "live" or "saved"
        ControlsChanged()
    end)
    labels.empty=Font(f,"GameFontHighlightSmall",18,-148,335)
    Tint(labels.empty,colors.muted)
    labels.empty:SetText("")
    Font(f,"GameFontNormal",17,-114,237):SetText("ITEM")
    Font(f,"GameFontNormal",259,-114,94):SetText("LOW / UNIT")
    rows={}
    for i=1,MAX_VISIBLE do
        local row=CreateFrame("Frame",nil,f)
        row:SetSize(360,22)
        row:SetPoint("TOPLEFT",f,"TOPLEFT",15,-132-(i-1)*24)
        local selectBG=row:CreateTexture(nil,"BACKGROUND")
        selectBG:SetAllPoints(row)
        Paint(selectBG,0.15,0.42,0.36,0.30)
        selectBG:Hide()
        row.selected=selectBG
        row.name=Font(row,"GameFontHighlight",5,-1,231)
        row.low=Font(row,"GameFontHighlight",245,-1,104)
        row.units=Font(row,"GameFontHighlightSmall",5,-12,345)
        Tint(row.low,colors.good)
        Tint(row.units,colors.muted)
        if type(row.EnableMouse)=="function" then row:EnableMouse(true) end
        row:SetScript("OnEnter",function(self)
            -- No GameTooltip, no equipped-stat comparison, no side effects.
            if self.data then Select(self.data.itemID,true);Refresh() end
        end)
        row:SetScript("OnMouseDown",function(self,button)
            if button and button~="LeftButton" then return end
            if not self.data then return end
            if selectedID==self.data.itemID then pinned=not pinned
            else pinned=true;Select(self.data.itemID,false) end
            DrawDetails()
            Refresh()
        end)
        row:Hide()
        rows[#rows+1]=row
    end
    labels.page=Font(f,"GameFontHighlightSmall",146,-10,112)
    if type(labels.page.ClearAllPoints)=="function" then
        labels.page:ClearAllPoints()
    end
    labels.page:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",135,41)
    local prev=Button(f,"Previous",15,-10,90,function()
        page=math.max(1,page-1);Refresh()
    end)
    if type(prev.ClearAllPoints)=="function" then prev:ClearAllPoints() end
    prev:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",15,33)
    local next=Button(f,"Next",269,-10,90,function()
        page=page+1;Refresh()
    end)
    if type(next.ClearAllPoints)=="function" then next:ClearAllPoints() end
    next:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",267,33)
    local divider=f:CreateTexture(nil,"ARTWORK")
    divider:SetSize(1,275)
    divider:SetPoint("TOPLEFT",f,"TOPLEFT",379,-44)
    Paint(divider,0.72,0.50,0.28,0.50)
    labels.item=Font(f,"GameFontNormal",398,-52,326)
    labels.context=Font(f,"GameFontHighlightSmall",398,-74,250)
    Tint(labels.context,colors.muted)
    Font(f,"GameFontHighlightSmall",398,-94,190):SetText("LATEST LOW ASK / UNIT")
    labels.price=Font(f,"GameFontNormalLarge",398,-108,180)
    Tint(labels.price,colors.bronze)
    labels.trend=Font(f,"GameFontHighlight",581,-112,141)
    labels.pin=Button(f,"Pin",655,-82,74,function()
        if not selectedID then return end
        pinned=not pinned
        DrawDetails()
    end)
    local chart=CreateFrame("Frame",nil,f)
    chart:SetSize(317,120)
    chart:SetPoint("TOPLEFT",f,"TOPLEFT",396,-136)
    labels.chart=chart
    local chartBG=chart:CreateTexture(nil,"BACKGROUND")
    chartBG:SetAllPoints(chart)
    Paint(chartBG,0.035,0.045,0.050,0.95)
    for y=12,110,30 do
        local grid=chart:CreateTexture(nil,"ARTWORK")
        grid:SetSize(317,1)
        grid:SetPoint("BOTTOMLEFT",chart,"BOTTOMLEFT",0,y)
        Paint(grid,0.44,0.50,0.50,0.24)
    end
    lineReady=type(chart.CreateLine)=="function"
    if lineReady then
        for i=1,6 do
            local ok,line=pcall(chart.CreateLine,chart,nil,"ARTWORK")
            if not ok or not line or type(line.SetStartPoint)~="function"
                or type(line.SetEndPoint)~="function" or
                type(line.SetThickness)~="function" or
                type(line.SetColorTexture)~="function" then
                lineReady=false;break
            end
            local good=pcall(function()
                line:SetThickness(2)
                line:SetColorTexture(0.42,0.91,0.73,1)
                line:Hide()
            end)
            if not good then lineReady=false;break end
            drawnLines[#drawnLines+1]=line
        end
    end
    for i=1,7 do
        local bar=chart:CreateTexture(nil,"ARTWORK")
        Paint(bar,0.42,0.91,0.73,0.75)
        bar:Hide();bars[i]=bar
        local dot=CreateFrame("Button",nil,chart)
        dot:SetSize(9,9)
        local mark=dot:CreateTexture(nil,"ARTWORK")
        mark:SetAllPoints(dot)
        Paint(mark,0.99,0.82,0.46,1)
        dot:SetScript("OnEnter",function(self)
            if self.sample then
                labels.hover:SetText(DateText(self.sample.t)..
                    "  ·  Low ask "..Coin(self.sample.low))
            end
        end)
        dot:SetScript("OnLeave",function()
            labels.hover:SetText("Hover chart points for exact scan prices")
        end)
        dot:Hide();dots[i]=dot
    end
    labels.hover=Font(f,"GameFontHighlightSmall",399,-263,310)
    Tint(labels.hover,colors.muted)
    labels.range=Font(f,"GameFontHighlightSmall",399,-280,311)
    Tint(labels.range,colors.blue)
    labels.detail=Font(f,"GameFontHighlightSmall",399,-298,316)
    Tint(labels.detail,colors.muted)
    labels.hover:SetText("Hover chart points for exact scan prices")
    f:SetScript("OnShow",function()
        redrawClock=0
        cacheKey=nil
        Refresh()
    end)
    f:SetScript("OnUpdate",function(_,dt)
        dt=type(dt)=="number" and dt or 0
        redrawClock=redrawClock+dt
        if nativeRequestPending then
            nativeRequestElapsed=nativeRequestElapsed+dt
            if nativeRequestElapsed>=45 then
                nativeRequestPending=false
                nativeMessage="No AH response within 45s. Retry Search AH."
                nativeGeneration=nativeGeneration+1
                cacheKey=nil
            end
        end
        if redrawClock>=1 then redrawClock=0;Refresh() end
    end)
    f:Hide()
    return f
end
function ChalkBox_AuctionBrowserShow()
    if not pane then return false end
    pane:Show()
    Refresh()
    return true
end
function ChalkBox_AuctionBrowserHide()
    nativeRequestPending=false
    if pane then pane:Hide() end
end
function ChalkBox_AuctionBrowserIsShown()
    return pane and pane:IsShown() or false
end
function ChalkBox_AuctionBrowserRefresh()
    if pane and pane:IsShown() then Refresh() end
end
-- Only a user action (including /chalk auction browser <item link>) should
-- deliberately select an outside item; ordinary Blizzard tooltips are ignored.
function ChalkBox_AuctionBrowserSelect(item)
    local id=item
    if type(item)=="string" and Public(item) then
        id=tonumber(item:match("item:(%d+)") or item:match("^%s*(%d+)%s*$"))
    end
    if not Select(id,false) then return false end
    pinned=true
    if pane and pane:IsShown() then DrawDetails();Refresh() end
    return true
end
function ChalkBox_AuctionBrowserStatus()
    return {shown=ChalkBox_AuctionBrowserIsShown(),selectedID=selectedID,
        pinned=pinned,filter=filter,sort=sort,source=source,
        page=page,rows=#results}
end

-- Observe native browse-result events only. Never send a browse query.
local listener=CreateFrame("Frame")
for _,name in ipairs({"AUCTION_HOUSE_BROWSE_RESULTS_UPDATED",
    "AUCTION_HOUSE_BROWSE_RESULTS_ADDED"}) do
    if type(listener.RegisterEvent)=="function" then
        listener:RegisterEvent(name)
    end
end
listener:SetScript("OnEvent",function()
    nativeRequestPending=false
    nativeMessage=nil
    nativeGeneration=nativeGeneration+1
    nativeSnapshotGeneration=-1
    local timeFn=type(GetServerTime)=="function" and GetServerTime
        or time
    if type(timeFn)=="function" then
        local ok,stamp=pcall(timeFn)
        if ok and Positive(stamp) then nativeSeenAt=stamp end
    end
    cacheKey=nil
    if source=="live" then Refresh() end
end)
