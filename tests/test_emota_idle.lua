-- Emota idle personality integration tests for WoW Forever-compatible Lua 5.1.
-- Real native emotes are dispatched through C_ChatInfo.PerformEmote, never chat commands.
local now, moving, combat, mounted, feigning, casting, standalone = 0,false,false,false,false,false,false
local emotes,timers,frames,notes = {},{},{},{}
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
    emotes[#emotes+1]=token
    return false -- Forever was observed to animate even when API returns false.
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
local originalRandom=math.random
local queued={}
local function Queue(...)
    for _,value in ipairs({...}) do queued[#queued+1]=value end
end
math.random=function(a,b)
    if #queued>0 then
        local v=table.remove(queued,1)
        assert(a and b and v>=a and v<=b,
            ("random roll %s out of %s..%s"):format(tostring(v),tostring(a),tostring(b)))
        return v
    end
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
assert(#timers==1)
assert(ChalkBoxDB.emota.auto==false)
assert(ChalkBox_EmotaGetEnabled("JOKE")==true)
for _,token in ipairs({"DANCE","SIT","SLEEP","LAYDOWN","YAWN","PONDER","SHRUG"}) do
    assert(ChalkBox_EmotaGetEnabled(token)==true,token.." must be part of default idle personality")
end

now=61;Tick()
assert(#emotes==0,"auto reactions stay opt-in")
ChalkBox_EmotaCommand("auto on")
now=122
Queue(100) -- idle opportunity occurs, but random roll chooses silence.
Tick()
assert(#emotes==0,"a random idle opportunity may intentionally do nothing")

now=183
Queue(1,31,24) -- pass quiet roll; weighted selection 31 = SIT; pose lasts 24s
Tick()
assert(emotes[#emotes]=="SIT","the native sit emote can be a rare automatic idle activity")
local count=#emotes
now=203;Tick()
assert(#emotes==count,"don't interrupt an active pose before its expiry")
now=208;Tick()
assert(emotes[#emotes]=="STAND","Emota must stand again after its own temporary pose")
assert(#emotes==count+1)
now=299;Queue(1,1);Tick()
assert(emotes[#emotes]=="JOKE","jokes remain one of several idle events")
now=420;Queue(1,1);Tick()
assert(emotes[#emotes]=="DANCE","anti-repeat must avoid the two most recent idle tokens")

-- A user's single emote switch must disable that behavior in automatic mode.
ChalkBox_EmotaSetEnabled("DANCE",false)
ChalkBox_EmotaSetEnabled("JOKE",false)
ChalkBox_EmotaCommand("idle reset")
now=481;Queue(1,1);Tick()
assert(emotes[#emotes]~="JOKE" and emotes[#emotes]~="DANCE",
    "disabled emotes are not selected for the idle pool")

-- A feigning hunter, casting player, or open vendor window must suppress idle.
ChalkBox_EmotaCommand("idle reset")
now=482;Tick()
local before=#emotes
now=544;feigning=true;Tick()
assert(#emotes==before,"Feign Death must suppress spontaneous emotes")
feigning=false;casting=true;Tick()
assert(#emotes==before,"casting must suppress spontaneous emotes")
casting=false;mounted=true;Tick()
assert(#emotes==before,"mounted players must not emote automatically")
mounted=false
_G.MerchantFrame={IsShown=function() return true end}
Tick()
assert(#emotes==before,"merchant interactions must suppress spontaneous emotes")
_G.MerchantFrame=nil
moving=true;Tick()
assert(#emotes==before,"movement must suppress spontaneous emotes")

-- Escape an active pose by moving: never send STAND on behalf of the player
-- when combat/movement has already interrupted the pose.
moving=false
for _,entry in ipairs(ChalkBox_EmotaCatalog()) do
    if entry.idle then ChalkBox_EmotaSetEnabled(entry.token,entry.token=="SLEEP") end
end
Fire("PLAYER_STOPPED_MOVING")
now=605;Queue(1,1,20);Tick()
assert(emotes[#emotes]=="SLEEP")
local sleepCount=#emotes
moving=true
Fire("PLAYER_STARTED_MOVING")
now=645;Tick()
assert(#emotes==sleepCount,"moving cancels our pose without forcing a stand emote")
moving=false
Fire("PLAYER_STOPPED_MOVING")
now=706;combat=true;Tick()
assert(#emotes==sleepCount,"combat blocks all idle emotes")
Fire("PLAYER_REGEN_DISABLED")
combat=false
Fire("PLAYER_REGEN_ENABLED")

-- Optional extra emotes are only considered when explicitly enabled, and
-- the manual preview button never requires turning on automatic reactions.
for _,entry in ipairs(ChalkBox_EmotaCatalog()) do
    if entry.idle then ChalkBox_EmotaSetEnabled(entry.token,false) end
end
ChalkBox_EmotaSetEnabled("HELLO",true)
ChalkBox_EmotaCommand("variety on")
assert(ChalkBox_EmotaPreviewIdle()==true)
assert(emotes[#emotes]=="HELLO","surprise preview uses user's selected extra emote")
ChalkBox_EmotaCommand("auto off")
assert(ChalkBox_EmotaPreviewIdle()==true,
    "manual preview remains available while automatic emotes are disabled")
math.random=originalRandom
print("PASS: opt-in, weighted idle JOKE/SIT/DANCE, pose-to-STAND, anti-repeat, quiet rolls, profession-like safety gates, disabled tokens, movement/combat cancellation and surprise preview")
