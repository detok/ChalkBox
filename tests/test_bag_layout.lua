-- Combat safety: ChalkBox must not modify Blizzard bag/item frames.
-- This test deliberately makes every attempted native anchor hook or move fail.
_G.ChalkBoxDB={bagOffsetY=45}
local chat={}
_G.DEFAULT_CHAT_FRAME={AddMessage=function(_,msg) chat[#chat+1]=msg end}
_G.hooksecurefunc=function() error("must never hook Blizzard bag layout") end
_G.UpdateContainerFrameAnchors=function() error("must not run stock layout") end
_G.ContainerFrameSettingsManager={
    GetBagsShown=function() error("must not inspect native bag frame") end,
}
_G.ContainerFrame1={ClearAllPoints=function()
    error("native bag frame must remain secure")
end}
_G.InCombatLockdown=function() return true end
local events
_G.CreateFrame=function()
    local f={registered={}}
    function f:RegisterEvent(name) self.registered[name]=true end
    function f:SetScript(_,callback) self.callback=callback end
    events=f
    return f
end
assert(loadfile("BagLayout.lua"))("ChalkBox")
events.callback(events,"ADDON_LOADED","ChalkBox")
local status=ChalkBox_BagStatus()
assert(status.suspended and not status.hooked and status.applied==0
    and not status.pending and status.offset==0 and status.savedOffset==45,
    "old bag offset is remembered without ever moving a protected container")
assert(ChalkBox_BagOffsetSet(30)==false
    and ChalkBoxDB.bagOffsetY==45,
    "unsafe reposition requests are rejected and stored layout untouched")
ChalkBox_BagCommand("offset -35")
assert(ChalkBoxDB.bagOffsetY==45,
    "slash commands cannot reactivate unsafe bag hooks")
events.callback(events,"PLAYER_LOGIN")
events.callback(events,"PLAYER_REGEN_ENABLED")
assert(ChalkBox_BagStatus().applied==0,
    "combat exit cannot trigger a deferred Blizzard frame move")
ChalkBox_BagCommand("status")
assert(chat[#chat]:find("Blizzard owns",1,true),
    "safety status is explicit")
ChalkBox_BagCommand("reset")
assert(ChalkBoxDB.bagOffsetY==0,
    "users can clear an old saved preference without touching bag UI")
print("PASS: native bag frames untouched, no protected hooks, no combat movement, saved preferences retained")
