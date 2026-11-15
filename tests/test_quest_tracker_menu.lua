-- Quest tracker integration: native header-only HookScript, non-invasive
-- modern/legacy menu, safe QuestSense mode and navigation actions.
local header={hooks={}}
function header:HookScript(event,fn)
    assert(event=="OnMouseUp")
    self.hooks[#self.hooks+1]=fn
end
local root={}
function root:HookScript()
    error("must hook header, not individual quest rows or the whole tracker")
end
root.Header=header
_G.ObjectiveTrackerFrame=root
local calls,opened,menus={},{},{}
local state={enabled=true,mode="smart"}
local nav={enabled=false}
_G.ChalkBox_QuestStatus=function() return state end
_G.ChalkBox_NavStatus=function() return nav end
_G.ChalkBox_QuestCommand=function(command)
    calls[#calls+1]=command
    if command=="on" then state.enabled=true end
    if command=="off" then state.enabled=false end
    if command=="smart" or command=="zone" or command=="all" then
        state.mode=command
    end
end
_G.ChalkBox_NavCommand=function(command)
    calls[#calls+1]="nav:"..command
    nav.enabled=command=="on"
end
_G.ChalkBox_OpenSettings=function(page) opened[#opened+1]=page end
_G.InCombatLockdown=function() return false end
local listener
_G.CreateFrame=function(kind,name,parent,template)
    if name then return {name=name} end
    listener={events={}}
    function listener:RegisterEvent(event) self.events[event]=true end
    function listener:SetScript(event,fn) self[event]=fn end
    return listener
end
_G.MenuUtil={CreateContextMenu=function(owner,build)
    assert(owner==header)
    menus={}
    local context={}
    function context:CreateTitle(v) self.title=v end
    function context:CreateButton(label,cb)
        menus[#menus+1]={label=label,run=cb}
    end
    build(owner,context)
    assert(context.title=="ChalkBox / QuestSense")
end}
assert(loadfile("QuestTrackerMenu.lua"))("ChalkBox")
assert(#header.hooks==1 and listener.events.ADDON_LOADED,
    "tracker header hooked once using HookScript, not replaced")
listener.OnEvent(listener,"ADDON_LOADED","Blizzard_ObjectiveTracker")
listener.OnEvent(listener,"PLAYER_ENTERING_WORLD")
assert(#header.hooks==1,"late game events do not duplicate mouse hooks")
header.hooks[1](header,"LeftButton")
assert(#menus==0,"normal left-clicks still belong to Blizzard")
header.hooks[1](header,"RightButton")
assert(#menus==5 and menus[1].label=="QuestSense Settings",
    "header right-click opens the small ChalkBox context menu")
local function Click(needle)
    for _,e in ipairs(menus) do
        if e.label:find(needle,1,true) then
            e.run()
            return
        end
    end
    error("missing menu action "..needle)
end
Click("QuestSense Settings")
assert(opened[#opened]=="quests","settings action opens native QuestSense page")
Click("Nearby")
assert(state.enabled and state.mode=="zone" and
    calls[#calls-1]=="on" and calls[#calls]=="zone",
    "Nearby uses existing QuestSense command path")
header.hooks[1](header,"RightButton")
assert(menus[4].label:find("Nearby",1,true) and
    menus[4].label:find("✓",1,true),
    "menu reflects the current chosen mode")
Click("Off")
assert(state.enabled==false,"Off disables only QuestSense automatic watches")
header.hooks[1](header,"RightButton")
Click("Smart")
assert(state.enabled==true and state.mode=="smart" and
    calls[#calls-1]=="on" and calls[#calls]=="smart",
    "Smart re-enables tracking using the native QuestSense command")
header.hooks[1](header,"RightButton")
Click("Navigation: Off")
assert(nav.enabled and calls[#calls]=="nav:on",
    "navigation option shows the optional floating arrow")
header.hooks[1](header,"RightButton")
Click("Navigation: On")
assert(not nav.enabled and calls[#calls]=="nav:off",
    "navigation option hides the arrow without changing watches")
_G.MenuUtil=nil
local legacy
_G.EasyMenu=function(entries,frame,anchor,x,y,kind)
    assert(anchor=="cursor" and kind=="MENU" and
        frame.name=="ChalkBoxQuestTrackerMenu")
    legacy=entries
end
assert(ChalkBox_QuestTrackerMenuOpen(header) and #legacy==6,
    "legacy EasyMenu path works without replacing Blizzard menus")
legacy[4].func()
assert(state.mode=="smart","legacy Smart acts on same QuestSense state")
_G.InCombatLockdown=function() return true end
assert(not ChalkBox_QuestTrackerMenuOpen(header),
    "in combat, no insecure popup or protected changes are attempted")
_G.InCombatLockdown=function() return false end
-- No available game menu still falls back to the native settings page.
_G.EasyMenu=nil
assert(not ChalkBox_QuestTrackerMenuOpen(header) and opened[#opened]=="quests",
    "missing popup APIs never cause a Lua error")
assert(ChalkBox_QuestTrackerMenuStatus().attached and #header.hooks==1,
    "status retains the existing native tracker hook")
print("PASS: additive tracker header right-click menu, settings, off/smart/nearby, nav toggle, native/legacy/absent APIs and combat guard")
