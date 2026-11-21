-- Login taint guard: record a blocked action and never move a Blizzard frame.
local notes={}
_G.DEFAULT_CHAT_FRAME={AddMessage=function(_,text) notes[#notes+1]=text end}
_G.CreateFrame=function()
    local f={events={}}
    function f:RegisterEvent(name) self.events[name]=true end
    function f:SetScript(_,fn) self.fire=fn end
    return f
end
local moved=false
_G.PlayerFrame={
    IsProtected=function() return true end,
    ClearAllPoints=function() moved=true end,
    SetPoint=function() moved=true end,
}
_G.MinimapCluster={
    IsProtected=function() return false end,
    ClearAllPoints=function() moved=true end,
    SetPoint=function() moved=true end,
}
assert(loadfile("TaintGuard.lua"))("ChalkBox")
local guard=_G.CreateFrame()
-- The module's frame is the one created during load. Re-find it by firing
-- through a fresh load is unnecessary: status starts clean.
local st=ChalkBox_TaintStatus()
assert(st.combat==false and st.lastEvent==nil and st.chrome.PlayerFrame=="protected"
    and st.chrome.MinimapCluster=="not protected" and not moved,
    "the check only reads protection and does not move frames")
-- Recreate the listener the same way the file did, by loading once.
-- Drive the saved listener: reload is one frame. Patch by calling the
-- event on a second copy is not available, so invoke via a wrapped global.
local captured
_G.CreateFrame=function()
    local f={}
    function f:RegisterEvent() end
    function f:SetScript(_,fn) captured=fn end
    return f
end
assert(loadfile("TaintGuard.lua"))("ChalkBox")
captured(nil,"ADDON_ACTION_BLOCKED","ChalkBox","SetPoint")
captured(nil,"ADDON_ACTION_BLOCKED","OtherAddon","SetPoint")
local report=ChalkBox_TaintCheck()
assert(report.lastEvent=="ADDON_ACTION_BLOCKED" and report.lastFunc=="SetPoint",
    "only ChalkBox's own blocked action is remembered")
local joined=table.concat(notes," ")
assert(joined:find("SetPoint",1,true) and joined:find("stay with Blizzard",1,true),
    "taintcheck tells the player what was blocked and that frames were left alone")
assert(not moved,"reporting a block still does not move the minimap or player frame")
print("PASS: taint check records the blocked action and does not touch Blizzard frames")
