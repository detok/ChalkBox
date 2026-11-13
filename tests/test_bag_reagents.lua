-- Known (observed) recipe bag markers, no synthetic craft claims or UI mutations.
local onEvent,hooks={},{}
local textures={}
local idForSlot={[1]=101,[2]=102,[3]=103}
local hasKnown={[101]=true,[102]=false,[103]=false}
local eventFrame
local buttons={}
for slot=1,3 do
    local btn={slot=slot,visible=true}
    function btn:GetBagID() return 0 end
    function btn:GetID() return self.slot end
    function btn:IsShown() return self.visible end
    function btn:CreateTexture()
        local t={shown=false}
        function t:SetPoint() end
        function t:SetHeight() end
        function t:SetWidth() end
        function t:SetColorTexture(_,_,_,alpha) self.opacity=alpha end
        function t:Show() self.shown=true end
        function t:Hide() self.shown=false end
        textures[#textures+1]=t
        return t
    end
    buttons[#buttons+1]=btn
end
local bag={shown=true}
function bag:IsShown() return self.shown end
function bag:EnumerateValidItems() return ipairs(buttons) end
_G.ChalkBoxDB={}
_G.CreateFrame=function()
    local f={events={}}
    function f:RegisterEvent(ev) self.events[ev]=true end
    function f:SetScript(which,cb) assert(which=="OnEvent");self.onEvent=cb end
    eventFrame=f
    return f
end
_G.C_Container={GetContainerItemID=function(bag,slot)
    assert(bag==0);return idForSlot[slot]
end}
_G.ChalkBox_LearnedRecipeUses=function(id)
    return hasKnown[id] and {{recipe="Verified Craft",profession="Leatherworking"}}
        or {}
end
_G.ContainerFrameUtil_EnumerateContainerFrames=function() return ipairs({bag}) end
_G.ContainerFrame_UpdateAll=function() end
_G.hooksecurefunc=function(name,cb)
    assert(name=="ContainerFrame_UpdateAll")
    hooks[#hooks+1]=cb
end
_G.C_Timer={After=function(_,callback) callback() end}
_G.issecretvalue=function(v) return v=="SECRET" end
assert(loadfile("BagReagents.lua"))("ChalkBox")
eventFrame.onEvent(eventFrame,"ADDON_LOADED","ChalkBox")
eventFrame.onEvent(eventFrame,"PLAYER_ENTERING_WORLD")
local s=ChalkBox_BagHighlightStatus()
assert(s.enabled and s.visible==3 and s.marked==1,
    "only character-learned ingredients should highlight")
assert(#textures==4 and buttons[1].ChalkBoxReagentBorder,
    "render a delicate four-sided inset around verified item only")
assert(not buttons[2].ChalkBoxReagentBorder and not buttons[3].ChalkBoxReagentBorder,
    "potential-use and irrelevant items get no green outlines")
assert(textures[1].shown and textures[1].opacity==0.75,
    "marker opacity comes from saved setting")
ChalkBox_BagHighlightOpacity(40)
assert(ChalkBoxDB.lootHighlightOpacity==40 and textures[1].opacity==0.4,
    "marker strength is independently adjustable")
hasKnown[101]=false
hooks[1]()
assert(not textures[1].shown and ChalkBox_BagHighlightStatus().marked==0,
    "removed recipe evidence removes previously drawn outline")
hasKnown[102]=true
ChalkBox_BagHighlightsRefresh()
assert(ChalkBox_BagHighlightStatus().marked==1
    and buttons[2].ChalkBoxReagentBorder,
    "newly observed recipe adds marker without reloading UI")
ChalkBox_BagHighlightSet(false)
assert(not textures[1].shown and not buttons[2].ChalkBoxReagentBorder[1].shown,
    "opt-out immediately hides all added borders")
ChalkBox_BagHighlightSet(true)
assert(buttons[2].ChalkBoxReagentBorder[1].shown,
    "re-enable restores only verified ingredient")
idForSlot[2]="SECRET"
ChalkBox_BagHighlightsRefresh()
assert(not buttons[2].ChalkBoxReagentBorder[1].shown,
    "secret item IDs are never classified, formatted, or highlighted")
-- Some legacy scans identify learned reagents only by localized item name.
local original=ChalkBox_LearnedRecipeUses
_G.C_Item={GetItemInfo=function(itemID)
    return itemID==103 and "Legacy Cloth" or nil
end}
_G.ChalkBox_LearnedRecipeUses=function(itemID,name)
    if itemID==103 and name=="Legacy Cloth" then
        return {{recipe="Legacy Bandage",profession="First Aid"}}
    end
    return original(itemID,name)
end
ChalkBox_BagHighlightsRefresh()
assert(buttons[3].ChalkBoxReagentBorder
    and buttons[3].ChalkBoxReagentBorder[1].shown,
    "name-only learned recipes get outlines only when item info corroborates them")
_G.C_Item=nil
_G.ChalkBox_LearnedRecipeUses=original
print("PASS: native learned-only bag markers, legacy name lookup, opacity, refresh and secret IDs")
