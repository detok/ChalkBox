-- Native emotes are cosmetic and cannot reach protected combat actions.
local now,moving,combat,mounted,feigning,casting,standalone=0,false,false,false,false,false,false
local emotes,timers,frames,notes={},{},{},{}
_G.DEFAULT_CHAT_FRAME={AddMessage=function(_,line) notes[#notes+1]=line end}
_G.ChalkBoxDB={}
_G.CreateFrame=function()
    local f={events={}}
    function f:RegisterEvent(event) self.events[event]=true end
    function f:SetScript(which,callback) self[which]=callback end
    frames[#frames+1]=f
    return f
end
_G.C_Timer={NewTicker=function(_,callback) timers[#timers+1]=callback end}
_G.C_AddOns={IsAddOnLoaded=function() return standalone end}
_G.C_ChatInfo={PerformEmote=function(token)
    assert(not combat,"protected emote API must never be called during combat")
    emotes[#emotes+1]=token
    return false -- Forever can animate even when the API returns false.
end}
_G.GetTime=function() return now end
_G.GetInstanceInfo=function() return "Test","none" end
_G.IsPlayerMoving=function() return moving end
_G.InCombatLockdown=function() return combat end
_G.UnitAffectingCombat=function() return combat end
_G.UnitIsFeignDeath=function() return feigning end
_G.UnitIsDeadOrGhost=function() return false end
_G.UnitIsAFK=function() return false end
_G.IsMounted=function() return mounted end
_G.UnitOnTaxi=function() return false end
_G.UnitCastingInfo=function() return casting and "Test Cast" or nil end
_G.UnitChannelInfo=function() return nil end
_G.UnitGUID=function() return nil end
_G.IsInGroup=function() return false end
_G.IsInRaid=function() return false end
_G.wipe=function(t) for k in pairs(t) do t[k]=nil end end
_G.strsplit=function(_,str)
    local a,b=str:match("^(%S+)%s*(.*)$")
    return a or "",b or ""
end
_G.ERR_OUT_OF_MANA="Not enough mana"
local originalRandom=math.random
math.random=function(a,b)
    if a and b then return a end
    if a then return 1 end
    return 0.5
end
local function Fire(event,...)
    for _,f in ipairs(frames) do
        if f.events[event] then f.OnEvent(f,event,...) end
    end
end
local function Tick()
    for _,callback in ipairs(timers) do callback() end
end
assert(loadfile("Emota.lua"))("ChalkBox")
Fire("ADDON_LOADED","ChalkBox")
Fire("PLAYER_ENTERING_WORLD")
assert(#timers==1 and not ChalkBoxDB.emota.auto)
assert(ChalkBox_EmotaGetEnabled("JOKE") and
    ChalkBox_EmotaGetEnabled("SIT"),
    "the emote catalog remains available")
now=61;Tick()
assert(#emotes==0,"cosmetic reactions are opt-in")

-- Limit the automatic pool to JOKE to make the idle roll deterministic.
for _,entry in ipairs(ChalkBox_EmotaCatalog()) do
    if entry.idle then
        ChalkBox_EmotaSetEnabled(entry.token,entry.token=="JOKE")
    end
end
ChalkBox_EmotaCommand("auto on")
now=122;Tick()
assert(#emotes==1 and emotes[1]=="JOKE",
    "safe non-pose idle personality still runs when opted in")

-- Movement, casting, feign, riding, and vendors all suppress idle reactions.
local count=#emotes
ChalkBox_EmotaCommand("idle reset")
now=185;moving=true;Tick()
assert(#emotes==count)
moving=false;casting=true;Tick()
assert(#emotes==count)
casting=false;feigning=true;Tick()
assert(#emotes==count)
feigning=false;mounted=true;Tick()
assert(#emotes==count)
mounted=false
_G.MerchantFrame={IsShown=function() return true end}
Tick()
assert(#emotes==count)
_G.MerchantFrame=nil

-- Sleeping, sitting and standing are manual-only: they must not interrupt
-- drinking, food use, or player-controlled poses in the background.
for _,entry in ipairs(ChalkBox_EmotaCatalog()) do
    if entry.idle then ChalkBox_EmotaSetEnabled(entry.token,entry.token=="SIT") end
end
ChalkBox_EmotaCommand("idle reset")
now=260;Tick()
assert(#emotes==count,"no automatic sit/sleep/stand pose")
assert(ChalkBox_EmotaTest("SIT"))
assert(emotes[#emotes]=="SIT","the manual pose preview remains available")
count=#emotes

-- The lockdown event and the direct combat API are both independent gates.
now=300;combat=true
Fire("PLAYER_REGEN_DISABLED")
assert(not ChalkBox_EmotaTest("WAVE"),
    "manual preview is not an excuse to call a protected API")
Fire("UI_ERROR_MESSAGE",0,"Not enough mana")
Fire("PLAYER_LEVEL_UP")
Tick()
assert(#emotes==count,
    "no reactive, idle, or preview emotes in combat")
combat=false
assert(not ChalkBox_EmotaTest("WAVE"),
    "combat flag remains latched until PLAYER_REGEN_ENABLED")
now=320;Fire("PLAYER_REGEN_ENABLED")
assert(ChalkBox_EmotaTest("WAVE") and emotes[#emotes]=="WAVE",
    "manual emotes recover normally after combat")
count=#emotes
combat=true
assert(not ChalkBox_EmotaTest("WAVE") and #emotes==count,
    "direct combat lockdown is enough even without an event")
combat=false

-- A standalone addon takes precedence; integrated module stays quiet.
standalone=true
assert(not ChalkBox_EmotaTest("WAVE") and #emotes==count)
standalone=false
-- /reload reports isReloadingUi. Automatic emotes wait one second.
-- A click during that second still plays, and idle afterward still plays.
now=400
Fire("PLAYER_ENTERING_WORLD", false, true)
Fire("UI_ERROR_MESSAGE", 0, "Not enough mana")
Fire("PLAYER_LEVEL_UP")
assert(#emotes==count, "reload does not fire an automatic emote")
assert(ChalkBox_EmotaTest("WAVE") and emotes[#emotes]=="WAVE",
    "a click still plays during the reload moment")
count=#emotes
now=402
Fire("UI_ERROR_MESSAGE", 0, "Not enough mana")
assert(#emotes==count+1 and emotes[#emotes]=="OOM",
    "automatic reactions return as soon as the reload moment has passed")
ChalkBox_EmotaCommand("auto off")
assert(not ChalkBoxDB.emota.auto)
math.random=originalRandom
print("PASS: native emotes opt-in, out-of-combat idle safe, no automatic poses, combat/event guard, manual-only preview, standalone precedence")
