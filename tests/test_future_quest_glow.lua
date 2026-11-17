-- Detached future-quest border must not taint or alter secure bag buttons.
_G.ChalkBoxDB={}
local inCombat=false
_G.InCombatLockdown=function() return inCombat end
local requested={1274}
local active=false
local itemID=1274
local root,overlays,created=nil,{},0
_G.UIParent={GetEffectiveScale=function() return 1 end}
local texMethods={
    SetColorTexture=function() end,SetPoint=function() end,
    SetWidth=function() end,SetHeight=function() end,
}
local function Overlay()
    local f={shown=false,x=0,y=0,w=0,h=0}
    function f:EnableMouse(value) assert(value==false,"overlays cannot intercept clicks") end
    function f:SetFrameStrata(value) assert(value=="DIALOG") end
    function f:CreateTexture() return setmetatable({}, {__index=texMethods}) end
    function f:ClearAllPoints() end
    function f:SetSize(w,h) self.w,self.h=w,h end
    function f:SetPoint(_,parent,_,x,y)
        assert(parent==UIParent,"the overlay must attach to UIParent")
        self.x,self.y=x,y
    end
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    return f
end
_G.CreateFrame=function(_,name,parent)
    created=created+1
    if parent==UIParent then
        local frame=Overlay()
        overlays[#overlays+1]=frame
        return frame
    end
    assert(not root,"only one watcher frame")
    root={
        RegisterEvent=function() end,
        SetScript=function(self,event,callback) self[event]=callback end,
    }
    return root
end
local button={
    IsShown=function() return true end,
    IsVisible=function() return true end,
    GetID=function() return 3 end,
    GetCenter=function() return 110,200 end,
    GetWidth=function() return 36 end,
    GetHeight=function() return 36 end,
    GetEffectiveScale=function() return 1 end,
    -- Deliberately NO SetPoint, CreateTexture or any mutation functions.
}
_G.ContainerFrame1Item1=button
_G.ContainerFrame1={
    IsShown=function() return true end,
    GetBagID=function() return 0 end,
    GetName=function() return "ContainerFrame1" end,
}
_G.C_Container={
    GetContainerItemID=function(bag,slot)
        assert(bag==0 and slot==3)
        return itemID
    end,
    GetContainerItemQuestInfo=function() return nil,nil,active end,
}
_G.C_Item={GetItemInfo=function() return "Hops" end}
_G.ChalkBox_IsTrackedQuestItem=function() return active end
_G.ChalkBox_FutureQuestUses=function(id)
    requested[#requested+1]=id
    if tonumber(id)==1274 then
        return {{questID=117,questName="Thunderbrew",required=5}}
    end
end
assert(loadfile("FutureQuestGlow.lua"))("ChalkBox")
root.OnEvent(root,"ADDON_LOADED","ChalkBox")
assert(ChalkBoxDB.futureQuestGlow==true,
    "future overlay defaults to on, independently of paused reagent outlines")
assert(#overlays==1 and overlays[1].shown and
    overlays[1].x==110 and overlays[1].y==200,
    "eligible Hops draws exactly one UIParent-owned outline, no bag button writes")
assert(ChalkBox_FutureQuestGlowStatus().visible==1)
root.OnUpdate(root,0.4)
assert(#overlays==1 and overlays[1].shown,
    "repeat scans reuse the independent overlay, never accumulate textures")
-- Never cover an actively needed quest item with the future marker.
active=true
root.OnEvent(root,"QUEST_LOG_UPDATE")
assert(not overlays[1].shown
    and ChalkBox_FutureQuestGlowStatus().visible==0,
    "native active quest item flag outranks purple future item border")
active=false
itemID=732
root.OnEvent(root,"BAG_UPDATE_DELAYED")
assert(not overlays[1].shown,"sorting the bag does not leave a stale marker")
itemID=1274
inCombat=true
root.OnEvent(root,"PLAYER_REGEN_DISABLED")
assert(not overlays[1].shown,"combat hides optional marker without touching buttons")
inCombat=false
root.OnEvent(root,"PLAYER_REGEN_ENABLED")
assert(overlays[1].shown,"marker returns after combat ends")
ChalkBox_FutureQuestGlowSet(false)
assert(not overlays[1].shown and ChalkBoxDB.futureQuestGlow==false)
ChalkBox_FutureQuestGlowSet(true)
assert(overlays[1].shown)
assert(ChalkBox_BagHighlightsRefresh==nil,
    "separate future overlay must not restore the taint-prone reagent system")
print("PASS: detached future quest purple marker, no secure bag writes, active quest precedence, combat, sorting, toggle")
