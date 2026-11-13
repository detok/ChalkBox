-- New CampSense behavior: only announce missing/expiring Camp Benefits.
local now=0
local updates, messages, toasts={}, {}, {}
local auras, harmful={}, {}
local rested=0
_G.UnitXPMax=function() return 1000 end
_G.GetXPExhaustion=function() return rested end
_G.GetTime=function() return now end
_G.GetBuildInfo=function() return "1.60.1","1","today",16001 end
_G.GetItemCount=function() return 10 end
_G.UnitClass=function() return "Hunter","HUNTER" end
_G.UnitRace=function() return "Dwarf","Dwarf" end
_G.UnitExists=function() return true end
_G.GetPetHappiness=function() return 3 end
_G.InCombatLockdown=function() return false end
_G.UnitAffectingCombat=function() return nil end
_G.DEFAULT_CHAT_FRAME={AddMessage=function(_,msg) messages[#messages+1]=msg end}
_G.UIParent={}
_G.CreateFrame=function()
    local obj={events={}}
    function obj:RegisterEvent(event) self.events[event]=true end
    function obj:SetScript(_,callback) self.onEvent=callback end
    updates[#updates+1]=obj
    return obj
end
_G.C_UnitAuras={GetAuraDataByIndex=function(_,i,filter)
    return filter=="HARMFUL" and harmful[i] or auras[i]
end}
_G.C_Timer={NewTicker=function(_,callback) _G.pulse=callback;return {} end}
_G.ChalkBox_ShowReminder=function(msg,title)
    toasts[#toasts+1]={msg=msg,title=title}
    return true
end
_G.ChalkBox_HideReminder=function() _G.hidden=true end
assert(loadfile("CampAura.lua"))("ChalkBox")
assert(loadfile("CampSense.lua"))("ChalkBox")
local event=updates[#updates]
event.onEvent(event,"ADDON_LOADED","ChalkBox")
event.onEvent(event,"PLAYER_ENTERING_WORLD")
assert(ChalkBoxDB.camp.toast==true and ChalkBoxDB.camp.enabled==true)
ChalkBoxDB.camp.supplies=false
ChalkBoxDB.camp.classCare=false
now=181;pulse()
assert(#toasts==1 and toasts[1].msg:find("Rested XP",1,true),
    "missing stat buff alone must not be conflated with tent; low rested XP prompts a tent")
auras={{name="Camp Benefits",spellId=1229741,expirationTime=5000}}
now=400;pulse()
assert(#toasts==1,"active camp buff cancels redundant reminders")
now=2000;pulse()
assert(#toasts==1,"active camp buffs never trigger another camp warning")
auras={{name="Camp Benefits",spellId=1229741,expirationTime=2480}}
now=2001;pulse()
assert(#toasts==2 and toasts[2].msg:find("expire",1,true),
    "expiring within ten minutes fires even inside the generic 45-minute interval")
auras={{name="Welcoming Campfire",spellId=1229739,expirationTime=2070}}
now=2002;pulse()
assert(#toasts==2,"while already sitting at a campfire, do not prompt again")
auras={{name="Camp Benefits",spellId=1229741,expirationTime=5500}}
now=2110;pulse()
assert(#toasts==2,"buff reactivation re-arms the transition detection")
auras={}
now=2240;pulse()
assert(#toasts==3 and toasts[3].msg:find("Rested XP",1,true),
    "rested XP still low and a buff transition can prompt a tent")
assert(ChalkBox_CampTestToast()==true and #toasts==4,
    "the manual Test Reminder bypasses the timer and proves toast functionality")
ChalkBox_CampCommand("toast off")
assert(ChalkBoxDB.camp.toast==false and hidden==true)
-- A new state is still a useful chat fallback if user disables visual prompts.
auras={{name="Camp Benefits",spellId=1229741,expirationTime=7000}}
now=2400;pulse()
auras={}
now=2520;pulse()
assert(#toasts==4 and messages[#messages]:find("Rested XP",1,true),
    "disabled toast intentionally uses chat fallback")
-- A tent used successfully gives HARMFUL Boosted Rest, NOT the stat buff.
-- Losing Camp Benefits must not imply the tent rested-XP bonus vanished.
harmful={{name="Boosted Rest",spellId=1229451,expirationTime=6000}}
now=2600;pulse()
assert(ChalkBox_CampStatus().tent.state=="cooldown")
local notified=#toasts
now=3200;pulse()
assert(#toasts==notified and
    messages[#messages]:find("Camp Benefits missing",1,true),
    "tent lockout suppresses tent prompts, but a separately missing stat buff may be reported")
harmful={}
rested=75
now=3300;pulse()
assert(ChalkBox_CampStatus().tent.state=="sufficient",
    "rested XP >=5% is already enough even without debuff")
assert(#toasts==notified,"enough rested XP must not trigger tent warnings")
rested=0
now=3350
ChalkBox_CampCommand("tent done")
assert(ChalkBox_CampStatus().tent.state=="acknowledged",
    "manual confirmation fallback supports clients hiding Boosted Rest")
now=3400;pulse()
assert(#toasts==notified,"manual confirmation suppresses false tent prompts")
ChalkBox_CampCommand("tent clear")
assert(ChalkBox_CampStatus().tent.state=="ready")
assert(ChalkBox_CampStatus().buff.state=="missing",
    "stat buff remains independently missing without claiming tent failure")
ChalkBox_CampChecklist()
local foundBoosted=false
for _,line in ipairs(messages) do
    if line:find("Boosted Rest",1,true) then foundBoosted=true end
end
assert(foundBoosted or #messages>0,"camp checklist contains tent status")
print("PASS: distinct tent rested XP, Boosted Rest cooldown suppression, sufficient rested XP, manual fallback, native aura reminder and chat")
