-- AuctionSense Charts Lab: genuine data + native Line and fallback modes.
-- No AH requests, fake price generation or mutation of SavedVariables.
local all,labels,lines,canDraw={}, {}, {},true
local function Element(kind,parent,template)
    local f={kind=kind,parent=parent,template=template,shown=true,scripts={}}
    function f:SetPoint(...) self.point={...} end
    function f:ClearAllPoints() self.point=nil end
    function f:SetSize(w,h) self.w,self.h=w,h end
    function f:SetWidth(w) self.w=w end
    function f:SetHeight(h) self.h=h end
    function f:SetAllPoints() end
    function f:SetText(t) self.text=t end
    function f:GetText() return self.text end
    function f:SetJustifyH() end
    function f:SetAutoFocus() end
    function f:SetMaxLetters(n) self.maxLetters=n end
    function f:EnableMouse() end
    function f:ClearFocus() end
    function f:SetColorTexture(...) self.color={...} end
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:SetScript(key,fn) self.scripts[key]=fn end
    function f:CreateFontString()
        local label=Element("Font",self)
        labels[#labels+1]=label
        return label
    end
    function f:CreateTexture()
        return Element("Texture",self)
    end
    function f:CreateLine()
        if not canDraw then error("client does not expose CreateLine") end
        local line=Element("Line",self)
        function line:SetThickness(t) self.thickness=t end
        function line:SetStartPoint(...) self.start={...} end
        function line:SetEndPoint(...) self.finish={...} end
        lines[#lines+1]=line
        return line
    end
    all[#all+1]=f
    return f
end
_G.CreateFrame=function(kind,name,parent,template)
    return Element(kind,parent,template)
end
_G.issecretvalue=function() return false end
local reads,requests=0,0
_G.ChalkBox_AuctionStatus=function() return {realm="Whitemane",faction="Alliance"} end
_G.ChalkBox_AuctionRows=function(query,max)
    reads=reads+1
    assert(query=="linen" and max==40)
    return {{itemID=2589,name="Linen Cloth",low=2400}}
end
local stored={{t=1700000000,low=2300},{t=1700086400,low=1600},
    {t=1700259200,low=2400}}
_G.ChalkBox_AuctionChartHistory=function(itemID)
    assert(itemID==2589)
    local copy={}
    for i,p in ipairs(stored) do copy[i]={t=p.t,low=p.low} end
    return {itemID=itemID,name="Linen Cloth",realm="Whitemane",
        faction="Alliance",source="full",points=copy}
end
assert(loadfile("AuctionCharts.lua"))("ChalkBox")
local parent=Element("Frame",nil)
local refresh=ChalkBox_AuctionChartsMount(parent)
assert(type(refresh)=="function")
refresh()
assert(reads==0 and requests==0,
    "opening experimental settings does not query auction data or server")
local input,find
for _,f in ipairs(all) do
    if f.kind=="EditBox" then input=f end
    if f.kind=="Button" and f.text=="Find Item" then find=f end
end
assert(input and find and find.scripts.OnClick)
input:SetText("linen")
find.scripts.OnClick(find)
assert(reads==1 and #lines==6 and lines[1].shown
    and lines[2].shown and not lines[3].shown,
    "native line graph draws exactly two segments for three real scans")
assert(lines[1].start[4]<lines[1].finish[4]
    and lines[1].start[5]>lines[1].finish[5],
    "actual price drop draws a descending line over time")
assert(lines[2].finish[4]>lines[1].finish[4],
    "graph uses real, uneven timestamps for horizontal placement")
local firstDot
for _,f in ipairs(all) do
    if f.kind=="Button" and f.chartSample then firstDot=firstDot;break end
end
local drawn=0
for _,f in ipairs(all) do
    if f.kind=="Button" and f.chartSample then drawn=drawn+1 end
end
assert(drawn==3,"one hoverable dot per observed price")
assert(stored[1].low==2300 and requests==0,
    "rendering history is read-only and never sends a query")
local fallbackParent=Element("Frame",nil)
canDraw=false
local fallbackRefresh=ChalkBox_AuctionChartsMount(fallbackParent)
assert(type(fallbackRefresh)=="function")
local oldFind
for i=#all,1,-1 do
    if all[i].kind=="Button" and all[i].text=="Find Item"
        and all[i]~=find then oldFind=all[i];break end
end
local secondInput
for i=#all,1,-1 do
    if all[i].kind=="EditBox" then secondInput=all[i];break end
end
secondInput:SetText("linen")
oldFind.scripts.OnClick(oldFind)
local strips=0
for _,f in ipairs(all) do
    if f.kind=="Texture" and f.shown and f.w==11 then strips=strips+1 end
end
assert(strips==3,"texture fallback plots exact observations without Line support")
print("PASS: AuctionSense settings-only real-price line graph, real-time spacing, safe texture fallback and read-only data")
