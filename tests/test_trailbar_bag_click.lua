-- A normal left click on The Bar's bag counter uses Blizzard's bag
-- shortcut, without changing item controls or interfering with edit mode.
local events
_G.CreateFrame=function()
    local f={}
    function f:RegisterEvent() end
    function f:SetScript(kind,fn) if kind=="OnEvent" then events=fn end end
    return f
end
_G.ChalkBoxDB={}
_G.InCombatLockdown=function() return false end
local toggles=0
_G.ToggleAllBags=function() toggles=toggles+1 end
assert(loadfile("TrailBar.lua"))("ChalkBox")
assert(type(ChalkBox_BarToggleBags)=="function",
    "The Bar exposes a safe native bag action")
assert(ChalkBox_BarToggleBags() and toggles==1,
    "ordinary click toggles bags through the existing Blizzard API")
assert(ChalkBox_BarToggleBags() and toggles==2,
    "a second click toggles the same bags without new container manipulation")
assert(ChalkBox_BarEditSet(true))
assert(not ChalkBox_BarToggleBags() and toggles==2,
    "edit mode reserves Bar clicks for drag-and-drop only")
assert(ChalkBox_BarEditSet(false))
_G.InCombatLockdown=function() return true end
assert(not ChalkBox_BarToggleBags() and toggles==2,
    "no insecure bag toggle while in combat")
_G.InCombatLockdown=function() error("combat state unavailable") end
assert(not ChalkBox_BarToggleBags() and toggles==2,
    "unknown combat state fails closed")
_G.InCombatLockdown=function() return false end
_G.ToggleAllBags=function() error("game rejected bag shortcut") end
assert(not ChalkBox_BarToggleBags(),
    "Blizzard rejection is not leaked as a Lua error")
_G.ToggleAllBags=nil
assert(not ChalkBox_BarToggleBags(),
    "missing Forever bag API does not throw or simulate inventory movement")
print("PASS: Bar bags left-click native toggle, edit-mode, combat and unsupported-API safety")
