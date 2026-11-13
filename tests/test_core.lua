-- Lua 5.1 event/tooltip/vendor regression test (no WoW client needed).
local onTooltip
local eventCallback
local hooks = {}
local quests = {{type="item",text="Flask of Oil: 1/5",numFulfilled=1,numRequired=5,finished=false}}
local vendorItems = { [1]={name="Flask of Oil"}, [11]={name="Flask of Oil"} }
local vendorOpen = true
_G.MERCHANT_ITEMS_PER_PAGE = 10
_G.MerchantFrame = { selectedTab = 1, IsShown = function() return vendorOpen end }
_G.C_QuestLog = {
    GetNumQuestLogEntries = function() return 1 end,
    GetInfo = function() return {title="Keeper of the Flame",questID=345,isHeader=false} end,
    GetQuestObjectives = function() return quests end,
}
_G.C_MerchantFrame = {GetItemInfo=function(index) return vendorItems[index] end}
_G.Enum = {TooltipDataType={Item=0}}
_G.TooltipDataProcessor = {AddTooltipPostCall=function(_,fn) onTooltip=fn end}
_G.C_Timer = {After=function(_,fn) fn() end}
_G.hooksecurefunc = function(name,fn) hooks[name]=fn end
_G.MerchantFrame_Update = function() end
local anim = {playing=false}
function anim:SetLooping() end
function anim:CreateAnimation()
    return {SetFromAlpha=function() end,SetToAlpha=function() end,SetDuration=function() end}
end
function anim:IsPlaying() return self.playing end
function anim:Play() self.playing=true end
function anim:Stop() self.playing=false end
local overlay
local edgeCount = 0
local markerText
local button = {id=1,shown=true}
function button:GetID() return self.id end
function button:GetParent() return nil end
function button:IsShown() return self.shown end
function button:GetFrameLevel() return 4 end
_G.MerchantItem1ItemButton = button
_G.CreateFrame = function(_, _, parent)
    if parent then
        local frame = {}
        function frame:SetAllPoints(target) assert(target == button) end
        function frame:SetFrameLevel(level) assert(level > button:GetFrameLevel()) end
        function frame:EnableMouse(value) assert(value == false) end
        function frame:CreateTexture()
            edgeCount = edgeCount + 1
            return {
                SetColorTexture=function(_,r,g,b,a) assert(r == 1 and g > 0 and b > 0 and a == 1) end,
                SetPoint=function() end,
                SetHeight=function() end,
                SetWidth=function() end,
            }
        end
        function frame:CreateFontString()
            return {
                SetPoint=function() end,
                SetText=function(_,txt) markerText=txt end,
                SetTextColor=function() end,
            }
        end
        function frame:CreateAnimationGroup() return anim end
        function frame:Show() self.shown=true end
        function frame:Hide() self.shown=false end
        overlay = frame
        return frame
    end
    return {RegisterEvent=function() end, SetScript=function(_,_,fn) eventCallback=fn end}
end
local tooltip = {lines={},owner=button,itemName="Flask of Oil"}
function tooltip:GetItem() return self.itemName end
function tooltip:GetOwner() return self.owner end
function tooltip:GetName() return "FakeTooltip" end
function tooltip:NumLines() return #self.lines end
function tooltip:AddLine(message)
    table.insert(self.lines,message)
    _G["FakeTooltipTextLeft"..#self.lines]={GetText=function() return message end}
end
function tooltip:Show() end

assert(loadfile("Core.lua"))()
assert(type(onTooltip)=="function")
eventCallback(nil,"PLAYER_ENTERING_WORLD")
eventCallback(nil,"MERCHANT_SHOW")
assert(overlay.shown==true,"merchant glow should appear for unfulfilled quest item")
assert(edgeCount == 4 and markerText == "!","raised overlay needs four visible borders and quest marker")
onTooltip(tooltip)
assert(#tooltip.lines==1 and tooltip.lines[1]=="BUY THIS FOR QUEST: Keeper of the Flame (need 4 more)","vendor should say BUY with remaining count")
onTooltip(tooltip)
assert(#tooltip.lines==1,"duplicate tooltip should not repeat a line")
tooltip.lines={};tooltip.owner={}
onTooltip(tooltip)
assert(#tooltip.lines==1 and tooltip.lines[1]=="Don't sell: needed for Keeper of the Flame","bag should say DON'T SELL")
quests={{type="item",text="Flask of Oil: 5/5",numFulfilled=5,numRequired=5,finished=true}}
eventCallback(nil,"QUEST_LOG_UPDATE")
assert(overlay.shown==false,"completed objective should hide merchant glow")
tooltip.lines={};tooltip.owner=button
onTooltip(tooltip)
assert(#tooltip.lines==0,"completed objective should not say BUY")
tooltip.owner={};onTooltip(tooltip)
assert(#tooltip.lines==1 and tooltip.lines[1]:find("Don't sell"),"completed objective should preserve original reminder")
quests={{type="item",text="Flask of Oil: 0/5",numFulfilled=0,numRequired=5}}
eventCallback(nil,"QUEST_LOG_UPDATE")
button.id=11
assert(overlay.shown==true,"page 2 vendor item should highlight")
MerchantFrame.selectedTab=2
hooks.MerchantFrame_Update()
assert(overlay.shown==false,"no vendor glow on buyback tab")
tooltip.lines={};tooltip.owner=button
onTooltip(tooltip)
assert(#tooltip.lines==0,"no buy or sell warning on buyback tab")
MerchantFrame.selectedTab=1
hooks.MerchantFrame_Update()
assert(overlay.shown==true,"vendor glow should return on buy tab")
eventCallback(nil,"MERCHANT_CLOSED")
assert(overlay.shown==false,"closing merchant should clear glow")
print("PASS: visible raised buy border, strong BUY copy, buy/sell, quantities, no duplicate lines, pages, buyback, close")
