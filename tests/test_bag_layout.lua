-- ChalkBox Bag Layout: reversible signed vertical shift around Blizzard's default.
-- Tests source-compatible anchors, idempotence, combat deferral and reset.
local parent={}
local stockY=85
local combined=false
local combat=false
local frame={shown=true,point=nil,relative=nil,relativePoint=nil,x=0,y=0}
function frame:GetParent() return parent end
function frame:IsShown() return self.shown end
function frame:GetPoint()
    return self.point,self.relative,self.relativePoint,self.x,self.y
end
function frame:ClearAllPoints() self.point=nil;self.relative=nil end
function frame:SetPoint(point,relative,relativePoint,x,y)
    self.point,self.relative,self.relativePoint,self.x,self.y=
        point,relative,relativePoint,x,y
end

_G.ChalkBoxDB={}
_G.DEFAULT_CHAT_FRAME={AddMessage=function() end}
_G.ContainerFrameSettingsManager={
    GetBagsShown=function() return {frame} end,
    IsUsingCombinedBags=function() return combined end,
}
local updateCalls=0
_G.UpdateContainerFrameAnchors=function()
    updateCalls=updateCalls+1
    frame:ClearAllPoints()
    frame:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT",-10,stockY)
end
_G.hooksecurefunc=function(name,callback)
    assert(name=="UpdateContainerFrameAnchors")
    local original=_G[name]
    _G[name]=function(...)
        original(...)
        callback(...)
    end
end
_G.InCombatLockdown=function() return combat end
local eventFrame
_G.CreateFrame=function()
    local f={}
    function f:RegisterEvent() end
    function f:SetScript(_,fn) self.callback=fn end
    eventFrame=f
    return f
end
assert(loadfile("BagLayout.lua"))("ChalkBox")
eventFrame.callback(eventFrame,"ADDON_LOADED","ChalkBox")
assert(ChalkBox_BagStatus().hooked and ChalkBox_BagStatus().offset==0,
    "should detect Forever's native bag anchor API without changing defaults")
UpdateContainerFrameAnchors()
assert(frame.y==85,"zero default does not touch Blizzard's anchor")

ChalkBox_BagOffsetSet(30)
assert(ChalkBoxDB.bagOffsetY==30 and frame.y==55,
    "30 pixel slider nudges whole column down")
UpdateContainerFrameAnchors()
assert(frame.y==55,"each Blizzard layout update reapplies, never stacks the offset")
ChalkBox_BagOffsetSet(40)
assert(frame.y==45 and ChalkBox_BagStatus().applied==40,
    "changing offset uses Blizzard's fresh baseline, not previous shifted anchor")

combined=true
ChalkBox_BagOffsetSet(50)
assert(frame.y==85 and ChalkBox_BagStatus().applied==0,
    "combined bags retain stock placement")
combined=false
ChalkBox_BagOffsetSet(30)
assert(frame.y==55,"returning to separate bags restores saved position")

combat=true
local previousCalls=updateCalls
ChalkBox_BagOffsetSet(70)
assert(frame.y==55 and updateCalls==previousCalls and ChalkBox_BagStatus().pending,
    "combat defers frame movement")
combat=false
eventFrame.callback(eventFrame,"PLAYER_REGEN_ENABLED")
assert(frame.y==15 and not ChalkBox_BagStatus().pending,
    "deferred layout safely resumes after combat")

ChalkBox_BagOffsetSet(999)
assert(ChalkBoxDB.bagOffsetY==120 and frame.y==-35,
    "maximum +120 clamp limits excessive downward movement")
ChalkBox_BagOffsetSet(-120)
assert(ChalkBoxDB.bagOffsetY==-120 and frame.y==205,
    "negative values move the bag UP relative to Blizzard's anchor")
ChalkBox_BagCommand("offset -35")
assert(ChalkBoxDB.bagOffsetY==-35 and frame.y==120,
    "signed slash offsets provide real above-default positioning")
ChalkBox_BagCommand("reset")
assert(ChalkBoxDB.bagOffsetY==0 and frame.y==85,
    "reset returns Blizzard's original anchor")
ChalkBox_BagCommand("offset 30")
assert(frame.y==55,"slash command uses same safe slider path")
ChalkBox_BagCommand("status")
ChalkBox_BagCommand("not a command")
assert(frame.y==55,"unrecognized commands do not move bags")
print("PASS: signed separate-bag offset -120..120, no stacking, combined bags untouched, combat deferral, and stock reset")
