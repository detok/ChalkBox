-- MacroForge native /macro UI integration: optional tab, safe docking,
-- no native frame script replacement or automatic writes to macros.
local connected={}
local listener
local buttons={}
_G.UIParent={}
_G.CreateFrame=function(kind,name,parent,template)
    local f={kind=kind,name=name,parent=parent}
    function f:SetSize(w,h) self.w=w;self.h=h end
    function f:SetPoint(...) self.point={...} end
    function f:SetText(v) self.text=v end
    function f:SetScript(key,fn) self[key]=fn end
    function f:RegisterEvent(event)
        self.events=self.events or {}
        self.events[event]=true
    end
    if name=="ChalkBoxMacroForgeNativeButton" then
        buttons[#buttons+1]=f
    elseif not name then listener=f end
    return f
end
local native={hooks={},shown=true}
function native:HookScript(key,fn)
    assert(key=="OnHide")
    self.hooks[#self.hooks+1]=fn
end
_G.MacroFrame=nil  -- load-on-demand
_G.InCombatLockdown=function() return false end
local count=0
local status={docked=false,shown=false}
_G.ChalkBox_OpenMacroForge=function()
    count=count+1
    status.shown=true
    return true
end
_G.ChalkBox_MacroForgeDockStatus=function() return status end
_G.ChalkBox_MacroForgeDockTo=function(owner)
    assert(owner==native)
    status.docked=true
    return true
end
_G.ChalkBox_MacroForgeHideDocked=function(owner)
    assert(owner==native)
    if not status.docked then return false end
    status.docked=false;status.shown=false
    return true
end
assert(loadfile("MacroForgeDock.lua"))("ChalkBox")
assert(listener and listener.events.ADDON_LOADED
    and #buttons==0,"addon load does not invent a native macro editor")
_G.MacroFrame=native
listener.OnEvent(listener,"ADDON_LOADED","Blizzard_MacroUI")
assert(#buttons==1 and #native.hooks==1
    and buttons[1].parent==native
    and buttons[1].text=="MacroForge"
    and buttons[1].point[1]=="BOTTOMLEFT",
    "one modest tab is added above existing native /macro frame")
listener.OnEvent(listener,"PLAYER_ENTERING_WORLD")
listener.OnEvent(listener,"ADDON_LOADED","OtherAddon")
assert(#buttons==1 and #native.hooks==1,
    "frame load or revisit never creates extra buttons or hooks")
buttons[1].OnClick()
assert(status.docked and status.shown and count==1,
    "click uses the existing MacroForge workbench docked beside Blizzard")
buttons[1].OnClick()
assert(not status.docked and not status.shown and count==1,
    "second click closes only a docked MacroForge instance")
buttons[1].OnClick()
assert(status.docked and count==2)
native.hooks[1]()
assert(not status.docked and not status.shown,
    "closing Blizzard /macro hides an attached Forge but not game macros")
local current=count
_G.InCombatLockdown=function() return true end
buttons[1].OnClick()
assert(count==current,"tab refuses protected interactions while in combat")
_G.InCombatLockdown=function() return false end
-- If docking isn't possible, the existing full standalone workbench
-- remains open, and a second click does not close it accidentally.
_G.ChalkBox_MacroForgeDockTo=function() return false end
buttons[1].OnClick()
assert(status.shown and not status.docked,
    "no-screen-room fallback preserves standalone Forge instead")
native.hooks[1]()
assert(status.shown,"closing native macro editor does not close standalone Forge")
print("PASS: opt-in native MacroFrame tab, lazy load, docking, close/restore, small-screen fallback, combat and no macro edits")
