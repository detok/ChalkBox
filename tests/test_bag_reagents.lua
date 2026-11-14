-- Combat regression: visual reagent hints may never taint item buttons.
_G.ChalkBoxDB={lootHighlightKnown=true,lootHighlightOpacity=75}
_G.ContainerFrame1={
    CreateTexture=function() error("must never create texture on secure button") end,
    GetBagID=function() error("must never inspect secure item button") end,
}
_G.ContainerFrameMixin={UpdateItems=function() error("no bag hooks") end}
_G.ContainerFrame_UpdateAll=function() error("no bag update hook") end
_G.hooksecurefunc=function() error("no bag frame hooks allowed") end
_G.ContainerFrameUtil_EnumerateContainerFrames=function()
    error("protected bag enumeration must not run")
end
_G.InCombatLockdown=function() return true end
local eventFrame
_G.CreateFrame=function()
    local f={}
    function f:RegisterEvent() end
    function f:SetScript(_,callback) self.callback=callback end
    eventFrame=f
    return f
end
assert(loadfile("BagReagents.lua"))("ChalkBox")
eventFrame.callback(eventFrame,"ADDON_LOADED","ChalkBox")
eventFrame.callback(eventFrame,"BAG_UPDATE_DELAYED")
eventFrame.callback(eventFrame,"PLAYER_REGEN_ENABLED")
local s=ChalkBox_BagHighlightStatus()
assert(s.suspended and not s.enabled and s.requested and
    s.opacity==75 and s.marked==0,
    "visual decoration is suspended without deleting old user settings")
assert(ChalkBox_BagHighlightsRefresh().suspended,
    "manual refresh cannot touch protected Blizzard item buttons")
assert(ChalkBox_BagHighlightOpacity(40)==false)
assert(ChalkBoxDB.lootHighlightOpacity==40,
    "user's preferred border opacity stays saved for safe replacement")
assert(ChalkBox_BagHighlightSet(false)==false)
assert(ChalkBoxDB.lootHighlightKnown==false
    and not ChalkBox_BagHighlightStatus().requested)
assert(ChalkBox_BagHighlightSet(true)==false)
assert(ChalkBox_BagHighlightStatus().requested and
    not ChalkBox_BagHighlightStatus().enabled)
print("PASS: reagent insights kept, no Blizzard bag scripts/textures/hooks, protected item buttons stay untouched")
