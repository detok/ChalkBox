-- Coordinator regression: isolated, OFF by default, single native tooltip
-- extension, contextual authority, no scans/actions and fault isolation.
_G.ChalkBoxZoneDB=nil
assert(loadfile("TooltipCoordinator.lua"))()
assert(not ChalkBox_TipCoordinatorEnabled() and ChalkBoxZoneDB==nil,
    "disabled coordinator never allocates saved variables")
assert(ChalkBox_TipCoordinatorSet(true))
assert(ChalkBox_TipCoordinatorEnabled() and ChalkBoxZoneDB.tooltipCoordinator==true)
local colorByLine,lines={},{}
_G.ChalkBox_TipColor=function(role)
    local roles={info={.4,.8,.7},danger={1,.2,.2},good={.2,1,.3},
        text={.8,.8,.8},value={1,.8,.3},muted={.5,.5,.5},
        count={.2,.6,1},warning={1,.6,.2},title={1,.7,.2}}
    return unpack(roles[role] or roles.text)
end
local tip={name="SampleItem",owner={},shown=0}
function tip:GetName() return self.name end
function tip:NumLines() return #lines end
function tip:AddLine(s,r,g,b)
    lines[#lines+1]=s
    colorByLine[s]={r,g,b}
    _G["SampleItemTextLeft"..#lines]={GetText=function() return s end}
end
function tip:Show() self.shown=self.shown+1 end
local function Clear()
    lines={}
    colorByLine={}
end
local ctx={name="Medium Leather",link="item:2319",tooltip=tip}
_G.ChalkBox_LootInsight=function()
    return {label="LEARNED RECIPE",details="Uses in Camp Tent",
        role="good",protected=false,recipeDetails="Other learned recipes: Bag"}
end
_G.ChalkBox_AuctionStatus=function() return {tooltip=true} end
_G.ChalkBox_AuctionPrice=function()
    return {low=12500,average=13000,age=180,market="Realm / Alliance",
        stale=false,mixed=false}
end
_G.ChalkBox_IntelEnabled=function() return true end
_G.ChalkBox_IntelTooltipInsight=function()
    return {kind="AUCTION",headline="Auction 8 | Keep 12",
        reason="8 units are surplus",goalDetail="12 for crafting",
        askDetail="Lowest observed ask: 1g 25s",shortfall=0,
        evidenceDetail="Evidence: provisional recipe or market calculation"}
end
_G.ChalkBox_DisenchantTooltipsEnabled=function() return false end
_G.ChalkBox_DropTooltipInsight=function() return nil end
_G.ChalkBox_CoreQuestFact=function() return nil end
_G.IsShiftKeyDown=function() return false end
_G.ChalkBox_MarketBagRows=function() error("hover must never scan bags") end
assert(ChalkBox_TipCoordinatorShow(tip,ctx))
local compact=table.concat(lines," | ")
assert(compact:find("Item Insights",1,true) and
    compact:find("Auction 8 | Keep 12",1,true) and
    compact:find("AH low ask:",1,true) and
    compact:find("Shift + re-hover",1,true))
assert(not compact:find("Other learned recipes:",1,true))
assert(#lines<=10,"normal tooltip is bounded")
local previous=#lines
local calls=0
local observed=ChalkBox_LootInsight
_G.ChalkBox_LootInsight=function(...)
    calls=calls+1
    return observed(...)
end
assert(ChalkBox_TipCoordinatorShow(tip,ctx) and #lines==previous
    and calls==0,
    "duplicate native callbacks neither redraw nor recalculate facts")
_G.ChalkBox_LootInsight=observed
Clear()
_G.IsShiftKeyDown=function() return true end
assert(ChalkBox_TipCoordinatorShow(tip,ctx))
local expanded=table.concat(lines," | ")
assert(expanded:find("Other learned recipes:",1,true) and
    expanded:find("asking price, not a sale",1,true))
assert(#lines>previous and not expanded:find("Shift + re-hover",1,true))
-- Verified character protection overrides potentially profitable advice.
Clear()
_G.ChalkBox_DisenchantTooltipsEnabled=function() return true end
_G.ChalkBox_DisenchantEvaluate=function()
    return {complete=true,estimated=22000,
        verdict="DE higher vs auction"}
end
_G.ChalkBox_LootInsight=function()
    return {label="KEEP",details="Required for an active quest",
        role="danger",protected=true,isQuest=true,
        quests={{title="A Real Quest",have=2,required=4}}}
end
assert(ChalkBox_TipCoordinatorShow(tip,ctx))
local protectedText=table.concat(lines," | ")
assert(protectedText:find("KEEP",1,true) and
    protectedText:find("Quest: A Real Quest  ·  2/4",1,true) and
    not protectedText:find("Auction 8",1,true) and
    not protectedText:find("AH low ask:",1,true) and
    protectedText:find("DE materials:",1,true) and
    not protectedText:find("DE higher vs auction",1,true),
    "accepted quest overrides economic advice; DE numbers remain informational")
-- A future-quest note is informational, not an automatic ban on sales.
Clear()
_G.ChalkBox_LootInsight=function()
    return {label="FUTURE QUEST",details="Reference only",
        future={{questName="A Later Quest",required=4}},
        protected=true,saleProtected=false,isQuest=false}
end
assert(ChalkBox_TipCoordinatorShow(tip,ctx))
local later=table.concat(lines," | ")
assert(later:find("Auction 8",1,true) and
    later:find("Possible later quest:",1,true) and
    not later:find("DE higher vs auction",1,true),
    "future quests are reminders, not sales bans, but DE stays informational")
-- A stale/mixed AH observation cannot masquerade as a confident current bid.
Clear()
_G.ChalkBox_AuctionPrice=function()
    return {low=15000,age=100000,stale=true,mixed=false}
end
assert(ChalkBox_TipCoordinatorShow(tip,ctx))
local staleText=table.concat(lines," | ")
assert(staleText:find("Old AH ask:",1,true) and
    not staleText:find("AH low ask:",1,true),
    "stale market evidence receives an explicit warning")
Clear()
_G.ChalkBox_AuctionPrice=function()
    return {low=15000,age=100,stale=false,mixed=true}
end
assert(ChalkBox_TipCoordinatorShow(tip,ctx))
assert(table.concat(lines," | "):find("Mixed variants",1,true),
    "mixed equipment variants never get a normal market-price label")
_G.ChalkBox_AuctionPrice=function()
    return {low=12500,average=13000,age=180,market="Realm / Alliance",
        stale=false,mixed=false}
end
-- Merchant offers use Core's own verified identity and never get a bag
-- inventory recommendation even if the matching item is in bags.
Clear()
_G.ChalkBox_CoreQuestFact=function()
    return {kind="buy",message="BUY FOR QUEST  ·  A Real Quest (2 more)"}
end
local buy={name="Medium Leather",link="item:2319",
    vendorOffer=true,tooltip=tip}
assert(ChalkBox_TipCoordinatorShow(tip,buy))
local buying=table.concat(lines," | ")
assert(buying:find("BUY FOR QUEST",1,true) and
    not buying:find("Auction",1,true))
assert(colorByLine["BUY FOR QUEST  ·  A Real Quest (2 more)"][2]>
    colorByLine["BUY FOR QUEST  ·  A Real Quest (2 more)"][1])
Clear()
_G.ChalkBox_CoreQuestFact=function() return nil end
assert(ChalkBox_TipCoordinatorShow(tip,buy) and #lines==0,
    "unrelated merchant offers get no addon sales recommendations")
-- Provider failures are isolated; other modules still show.
Clear()
_G.ChalkBox_LootInsight=function() error("simulated client API failure") end
_G.ChalkBox_AuctionPrice=function() error("no data") end
_G.ChalkBox_IntelTooltipInsight=function() return nil end
_G.ChalkBox_DropTooltipInsight=function()
    return {quantity=7,windows=12,rate=30,hits=3,attempts=10}
end
_G.IsShiftKeyDown=function() return true end
assert(ChalkBox_TipCoordinatorShow(tip,ctx))
assert(table.concat(lines," | "):find("7 found in 12 observed loots",1,true),
    "a broken provider does not suppress independent observed drops")
local old=#lines
assert(ChalkBox_TipCoordinatorSet(false))
assert(not ChalkBox_TipCoordinatorShow(tip,ctx) and #lines==old,
    "OFF is strict no-op")
assert(not ChalkBox_TipCoordinatorSet("on"),
    "invalid option never enables the experimental route")
print("PASS: coordinated item insights, merchant/protection priority, Shift details, no duplicate annotations, fault isolation and OFF fallback")
