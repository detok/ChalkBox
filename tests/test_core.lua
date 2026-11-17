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
local matching=ChalkBox_QuestItemDetails("Flask of Oil")
assert(type(matching)=="table" and #matching==1 and
    matching[1].title=="Keeper of the Flame" and
    matching[1].id==345 and
    matching[1].have==1 and matching[1].required==5 and
    not matching[1].complete,
    "core already knows quest name, quest ID and exact objective progress")
matching[1].title="NOT THE QUEST NAME"
assert(ChalkBox_QuestItemDetails("Flask of Oil")[1].title==
    "Keeper of the Flame","quest details are returned as safe detached copies")
assert(ChalkBox_QuestItemDetails("Not an objective")==nil,
    "unknown items do not receive guessed quest names")
assert(overlay.shown==true,"merchant glow should appear for unfulfilled quest item")
assert(edgeCount == 4 and markerText == "!","raised overlay needs four visible borders and quest marker")
onTooltip(tooltip)
assert(#tooltip.lines==1 and tooltip.lines[1]=="BUY FOR QUEST  ·  Keeper of the Flame (4 more)","vendor should say BUY with remaining count")
onTooltip(tooltip)
assert(#tooltip.lines==1,"duplicate tooltip should not repeat a line")
tooltip.lines={};tooltip.owner={}
onTooltip(tooltip)
assert(#tooltip.lines==1 and tooltip.lines[1]=="DO NOT SELL  ·  Keeper of the Flame","bag should say DON'T SELL")
quests={{type="item",text="Flask of Oil: 5/5",numFulfilled=5,numRequired=5,finished=true}}
eventCallback(nil,"QUEST_LOG_UPDATE")
assert(overlay.shown==false,"completed objective should hide merchant glow")
tooltip.lines={};tooltip.owner=button
onTooltip(tooltip)
assert(#tooltip.lines==0,"completed objective should not say BUY")
tooltip.owner={};onTooltip(tooltip)
assert(#tooltip.lines==1 and tooltip.lines[1]:find("DO NOT SELL"),"completed objective should preserve original reminder")
matching=ChalkBox_QuestItemDetails("Flask of Oil")
assert(matching[1].have==5 and matching[1].required==5 and
    matching[1].complete,
    "completed objectives retain their exact title/progress until quest turn-in")
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
-- Two accepted quests may need the same item. Keep every real
-- source quest, but never claim an unrelated quest needs the item.
local byQuest={
    [345]={{type="item",text="Flask of Oil: 2/5",
        numFulfilled=2,numRequired=5,finished=false}},
    [876]={{type="item",text="Flask of Oil: 3/3",
        numFulfilled=3,numRequired=3,finished=true}},
}
C_QuestLog.GetNumQuestLogEntries=function() return 2 end
C_QuestLog.GetInfo=function(index)
    if index==1 then return {title="Keeper of the Flame",
        questID=345,isHeader=false} end
    return {title="Another Oil Quest",questID=876,isHeader=false}
end
C_QuestLog.GetQuestObjectives=function(id) return byQuest[id] end
eventCallback(nil,"QUEST_LOG_UPDATE")
matching=ChalkBox_QuestItemDetails("Flask of Oil")
assert(#matching==2 and
    matching[1].title=="Keeper of the Flame" and
    matching[1].have==2 and
    matching[2].title=="Another Oil Quest" and
    matching[2].complete,
    "both accepted quest titles are preserved, including complete objectives")
assert(ChalkBox_IsTrackedQuestItem("Flask of Oil"),
    "shared quest item remains protected while either quest is accepted")
-- Forever commonly reports item objectives with progress first rather
-- than the legacy "Name: 0/8" wording. Case and extra spaces in tooltip text
-- must not suppress an otherwise verified quest title.
C_QuestLog.GetNumQuestLogEntries=function() return 1 end
C_QuestLog.GetInfo=function()
    return {title="A Special Delivery",questID=9901,isHeader=false}
end
C_QuestLog.GetQuestObjectives=function()
    return {{type="item",text="0/8  Flintfire's   Shipment",
        numFulfilled=0,numRequired=8,finished=false}}
end
eventCallback(nil,"QUEST_LOG_UPDATE")
matching=ChalkBox_QuestItemDetails("  FLINTFIRE'S shipment  ")
assert(matching and #matching==1 and matching[1].title=="A Special Delivery"
    and matching[1].have==0 and matching[1].required==8
    and ChalkBox_IsTrackedQuestItem("Flintfire's Shipment"),
    "Forever progress-first objectives resolve the actual accepted quest despite spaces/case")
assert(ChalkBox_QuestItemDetails("Random Shipment")==nil,
    "different item text cannot inherit a nearby quest title")
C_QuestLog.GetQuestObjectives=function()
    return {{type="item",text="Flintfire's Shipment (3/8)",
        numFulfilled=3,numRequired=8,finished=false}}
end
eventCallback(nil,"QUEST_LOG_UPDATE")
matching=ChalkBox_QuestItemDetails("Flintfire's Shipment")
assert(matching and matching[1].have==3 and matching[1].required==8,
    "parenthesized objective progress is matched without dropping the quest title")

-- Quest objective details can be unavailable on the first Forever API read.
-- Retrying a missing cache must never invent a result or require /reload.
local loading=true
local questClock=42
_G.GetTime=function() return questClock end
C_QuestLog.GetQuestObjectives=function()
    if loading then return nil end
    return {{type="item",text="0/8 Flintfire's Shipment",
        numFulfilled=2,numRequired=8,finished=false}}
end
eventCallback(nil,"QUEST_LOG_UPDATE")
matching=ChalkBox_QuestItemDetails("Flintfire's Shipment")
assert(matching and matching[1].title=="A Special Delivery"
    and matching[1].stale==true and matching[1].have==3,
    "temporarily unreadable objectives retain the last verified quest title, with stale progress")
loading=false
questClock=44.5
matching=ChalkBox_QuestItemDetails("Flintfire's Shipment")
assert(matching and matching[1].title=="A Special Delivery"
    and matching[1].have==2 and not matching[1].stale,
    "next eligible tooltip lookup refreshes delayed Forever quest details and clears stale state")
-- Identical wording from a non-item objective does not prove this item
-- belongs to the quest.
C_QuestLog.GetQuestObjectives=function()
    return {{type="monster",text="Flintfire's Shipment: 2/8",
        numFulfilled=2,numRequired=8}}
end
eventCallback(nil,"QUEST_LOG_UPDATE")
assert(ChalkBox_QuestItemDetails("Flintfire's Shipment")==nil,
    "non-item objectives cannot claim an item or quest title")

-- Some Forever-compatible quest log variants omit isHeader on real
-- entries. Do not mistake that for a failed header read.
C_QuestLog.GetInfo=function()
    return {title="A Special Delivery",questID=9901}
end
C_QuestLog.GetQuestObjectives=function()
    return {{type="item",text="Flintfire's Shipment: 2/8",
        numFulfilled=2,numRequired=8,finished=false}}
end
eventCallback(nil,"QUEST_LOG_UPDATE")
matching=ChalkBox_QuestItemDetails("Flintfire's Shipment")
assert(matching and matching[1].title=="A Special Delivery",
    "missing isHeader flag should not invalidate a genuine accepted quest")
-- If the quest APIs disappear temporarily, keep previously verified names.
C_QuestLog.GetQuestObjectives=nil
eventCallback(nil,"QUEST_LOG_UPDATE")
matching=ChalkBox_QuestItemDetails("Flintfire's Shipment")
assert(matching and matching[1].title=="A Special Delivery",
    "transient objective API unavailability cannot clear known quest protection")
C_QuestLog.GetNumQuestLogEntries=function() error("quest log not ready") end
eventCallback(nil,"QUEST_LOG_UPDATE")
matching=ChalkBox_QuestItemDetails("Flintfire's Shipment")
assert(matching and matching[1].title=="A Special Delivery",
    "transient quest count failure cannot wipe verified quest titles")
C_QuestLog.GetNumQuestLogEntries=function() return 0 end
eventCallback(nil,"QUEST_REMOVED")
assert(ChalkBox_QuestItemDetails("Flask of Oil")==nil
    and not ChalkBox_IsTrackedQuestItem("Flask of Oil"),
    "completed/removed quest cache is cleared rather than kept indefinitely")
print("PASS: quest title/progress read-only API, shared quests, completed objectives, removed quests, vendor protections and native merchant border")
