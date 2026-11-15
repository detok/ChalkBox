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
local frameDelete={
    GetParent=function() return native end,
    GetRight=function() return 200 end,
}
local frameNew={GetLeft=function() return 294 end}
local frameExit={}
_G.MacroDeleteButton=frameDelete
_G.MacroNewButton=frameNew
_G.MacroExitButton=frameExit
function native:IsShown() return self.shown end
function native:Show() self.shown=true end
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
    and buttons[1].point[1]=="LEFT"
    and buttons[1].point[2]==frameDelete
    and buttons[1].point[3]=="RIGHT"
    and buttons[1].w==82 and buttons[1].h==22,
    "MacroForge button sits in the real gap beside Delete, before New and Exit")
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
-- Settings button must never strand the Forge behind Options.
local settings={shown=true,closed=0}
function settings:IsShown() return self.shown end
function settings:Hide() self.shown=false;self.closed=self.closed+1 end
_G.SettingsPanel=settings
local shownMacro=0
_G.MacroFrame_Show=function()
    native:Show()
    shownMacro=shownMacro+1
end
_G.ChalkBox_MacroForgeDockTo=function(owner)
    assert(owner==native)
    status.docked=true
    return true
end
native.shown=false
status.docked=false;status.shown=false
assert(ChalkBox_MacroForgeFromSettings() and
    settings.closed==1 and not settings.shown and
    native:IsShown() and shownMacro==1 and
    status.docked and status.shown,
    "settings closes before it opens the native macro editor and docks Forge")
-- With no exposed native MacroFrame, settings still closes and the
-- standalone builder remains accessible.
_G.MacroFrame=nil
settings.shown=true
status.docked=false;status.shown=false
_G.C_AddOns={LoadAddOn=function()
    return false,"not available"
end}
assert(ChalkBox_MacroForgeFromSettings() and not settings.shown
    and not status.docked and status.shown,
    "missing native macro UI gracefully falls back to standalone")
-- Missing footer controls must not install a hook or an overlapping button.
local absent={hooks={}}
function absent:HookScript(_,fn) self.hooks[#self.hooks+1]=fn end
_G.MacroFrame=absent
_G.MacroDeleteButton=nil
_G.MacroNewButton=nil
_G.MacroExitButton=nil
local beforeButtons=#buttons
assert(not ChalkBox_MacroForgeNativeStatus().attached and
    #absent.hooks==0 and #buttons==beforeButtons,
    "a different native macro layout is never covered by guessed controls")
print("PASS: native /macro footer button beside Delete/New/Exit, late-load and no-overlap safeguards, settings closes then docks, standalone fallback and no macro edits")
