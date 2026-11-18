-- Integration test: BOTH Core and LootSense native hooks, in modern
-- and legacy Forever tooltip modes. No WoW client or secure UI required.
local function Scenario(mode)
    local hooks,frames={},{}
    local vendorOpen=false
    _G.ChalkBoxZoneDB=nil
    _G.ChalkBoxDB=nil
    _G.SlashCmdList={}
    _G.MERCHANT_ITEMS_PER_PAGE=10
    _G.MerchantFrame={
        selectedTab=1,IsShown=function() return vendorOpen end}
    _G.C_MerchantFrame={
        GetItemInfo=function(index)
            if index==1 then return {name="Flask of Oil"} end
        end}
    local button={id=1}
    function button:GetID() return self.id end
    function button:GetParent() return nil end
    _G.MerchantItem1ItemButton=button
    _G.C_QuestLog={
        GetNumQuestLogEntries=function() return 1 end,
        GetInfo=function() return {
            title="Keeper of the Flame",questID=25,isHeader=false} end,
        GetQuestObjectives=function()
            return {{type="item",text="Flask of Oil: 1/5",
                numFulfilled=1,numRequired=5,finished=false}}
        end,
    }
    if mode=="modern" then
        _G.Enum={TooltipDataType={Item=0}}
        _G.TooltipDataProcessor={AddTooltipPostCall=function(_,fn)
            hooks[#hooks+1]=fn
        end}
        _G.GameTooltip=nil
    else
        _G.Enum=nil
        _G.TooltipDataProcessor=nil
        _G.GameTooltip={HookScript=function(_,event,fn)
            assert(event=="OnTooltipSetItem")
            hooks[#hooks+1]=fn
        end}
    end
    _G.CreateFrame=function()
        local frame={}
        function frame:RegisterEvent() end
        function frame:UnregisterEvent() end
        function frame:SetScript(_,event,fn)
            assert(event=="OnEvent")
            self.onEvent=fn
        end
        frames[#frames+1]=frame
        return frame
    end
    _G.ChalkBox_AuctionStatus=nil
    _G.ChalkBox_AuctionPrice=nil
    _G.ChalkBox_DisenchantEvaluate=nil
    _G.ChalkBox_DisenchantTooltipsEnabled=nil
    _G.ChalkBox_IntelEnabled=nil
    _G.ChalkBox_DropTooltipInsight=nil
    _G.ChalkBox_CampUtility=nil
    _G.ChalkBox_RecipeAdvice=nil
    _G.ChalkBox_ProfessionMatch=nil
    _G.C_Item=nil
    _G.GetItemInfo=nil
    assert(loadfile("Core.lua"))()
    assert(loadfile("TooltipCoordinator.lua"))()
    assert(loadfile("LootSense.lua"))("ChalkBox")
    assert(#hooks==2,"two native hooks must coexist in "..mode)
    assert(#frames==2)
    frames[1].onEvent(frames[1],"PLAYER_ENTERING_WORLD")
    frames[2].onEvent(frames[2],"ADDON_LOADED","ChalkBox")
    local lines,tipLines={},{}
    local tip={owner={},name="Flask of Oil",
        link="|Hitem:12345:0|h[Flask of Oil]|h"}
    function tip:GetItem() return self.name,self.link end
    function tip:GetOwner() return self.owner end
    function tip:GetName() return "CombinedTip" end
    function tip:NumLines() return #lines end
    function tip:AddLine(message)
        lines[#lines+1]=message
        _G["CombinedTipTextLeft"..#lines]={
            GetText=function() return message end}
    end
    function tip:Show() end
    local function Hover(owner)
        tip.owner=owner or {}
        lines={}
        for _,fn in ipairs(hooks) do fn(tip) end
        return table.concat(lines," | "),lines
    end
    local function Count(haystack,needle)
        local n=0
        for _ in haystack:gmatch(needle) do n=n+1 end
        return n
    end
    -- Legacy pathway must remain completely unchanged while OFF.
    local old=Hover()
    assert(old:find("KEEP",1,true) and
        not old:find("Item Insights",1,true),
        "OFF preserves original LootSense without a new banner: "..mode)
    assert(ChalkBox_TipCoordinatorSet(true))
    local bag=Hover()
    assert(Count(bag,"Item Insights")==1 and
        bag:find("Quest: Keeper of the Flame",1,true),
        "one combined item summary despite two callbacks: "..mode)
    -- With the merchant open, Core fires first. LootSense must detect the
    -- first already-rendered coordinator section and NOT append a second.
    vendorOpen=true
    MerchantFrame.selectedTab=1
    local merchant=Hover(button)
    assert(Count(merchant,"Item Insights")==1 and
        Count(merchant,"BUY FOR QUEST")==1 and
        not merchant:find("AUCTION",1,true),
        "one safe vendor-buy directive: "..mode)
    MerchantFrame.selectedTab=2
    assert(Hover(button)=="",
        "buyback is never confused with vendor stock: "..mode)
    MerchantFrame.selectedTab=1
    local questBag=Hover()
    assert(Count(questBag,"Item Insights")==1 and
        questBag:find("DO NOT SELL",1,true),
        "Core and LootSense cooperate on item safety near vendor: "..mode)
    -- Even if the entire coordinator call fails, Core's own cached
    -- quest item should still have its do-not-sell warning.
    local original=ChalkBox_TipCoordinatorShow
    _G.ChalkBox_TipCoordinatorShow=function() error("injected failure") end
    local failed=Hover()
    assert(Count(failed,"DO NOT SELL")==1,
        "Core safety fallback survives both failing callbacks: "..mode)
    _G.ChalkBox_TipCoordinatorShow=original
    assert(ChalkBox_TipCoordinatorSet(false))
    local oldAgain=Hover()
    assert(oldAgain:find("DO NOT SELL",1,true) and
        not oldAgain:find("Item Insights",1,true),
        "switch OFF restores original merchant-safe callback: "..mode)
end
Scenario("modern")
Scenario("legacy")
print("PASS: Core+LootSense together in modern/legacy hooks, quest vendor precedence, no double print, buyback separation, fault recovery and OFF rollback")
