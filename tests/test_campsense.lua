-- CampSense: Forever-specific item utility and unobtrusive personal checklist.
local now,level,class,race=0,25,"HUNTER","Dwarf"
local counts={[4470]=0,[4471]=0,[279981]=0,[279978]=0}
local frames,timers,messages={}, {}, {}
_G.ChalkBoxDB={}
_G.GetTime=function() return now end
_G.GetBuildInfo=function() return "1.60.1","123","today",16001 end
_G.UnitClass=function() return class,class end
_G.UnitRace=function() return race,race end
_G.UnitLevel=function() return level end
_G.UnitExists=function() return true end
_G.GetPetHappiness=function() return 2 end
_G.GetItemCount=function(id) return counts[id] or 0 end
_G.InCombatLockdown=function() return false end
_G.UnitAffectingCombat=function() return nil end -- real WoW may return nil out of combat
_G.DEFAULT_CHAT_FRAME={AddMessage=function(_,msg) messages[#messages+1]=msg end}
_G.C_Timer={NewTicker=function(_,fn) timers[#timers+1]=fn end}
_G.CreateFrame=function()
    local f={events={}}
    function f:RegisterEvent(name) self.events[name]=true end
    function f:SetScript(_,fn) self.onEvent=fn end
    frames[#frames+1]=f
    return f
end
assert(loadfile("CampSense.lua"))("ChalkBox")
local f=frames[#frames]
f.onEvent(f,"ADDON_LOADED","ChalkBox")
f.onEvent(f,"PLAYER_ENTERING_WORLD")
assert(#timers==1,"camp reminder uses one timer")
assert(ChalkBoxDB.camp.enabled==true and ChalkBoxDB.camp.interval==45)
assert(ChalkBox_CampUtility(4470) and
    ChalkBox_CampUtility("4471"):find("reusable",1,true))
assert(ChalkBox_CampUtility(279981):find("campsite",1,true))
assert(ChalkBox_CampUtility(279978):find("rested",1,true))
assert(ChalkBox_CampUtility(11291):find("Journeyman",1,true))
assert(ChalkBox_CampUtility(272941):find("higher-tier",1,true))
assert(ChalkBox_CampUtility(211527):find("3%",1,true))
assert(ChalkBox_CampUtility(1)==nil and
    ChalkBox_CampUtility(nil,"Broken Fang")==nil)
now=179;timers[1]()
assert(#messages==0,"no messages immediately after login")
now=181;timers[1]()
assert(#messages==1 and messages[1]:find("No Campfire Kits",1,true),
    "missing ready-to-use kits and wood is more actionable than generic flint warning")
now=400;timers[1]()
assert(#messages==1,"reminders throttled to every 45 minutes")
counts[4471]=1
counts[4470]=10
counts[279981]=4
now=2900;timers[1]()
assert(#messages==2 and messages[2]:lower():find("pet",1,true),
    "hunter receives pet mood nudge when supplies are covered")
ChalkBox_CampCommand("interval 20")
assert(ChalkBoxDB.camp.interval==20)
ChalkBox_CampChecklist()
local sawForever=false
for _,line in ipairs(messages) do
    if line:find("Forever",1,true) then sawForever=true end
end
assert(sawForever,"manual prep checklist must explain Forever camp bonuses")
class="MAGE";race="Human"
local state=ChalkBox_CampStatus()
assert(state.class=="MAGE" and state.race=="Human" and state.pet==nil)
ChalkBox_CampChecklist()
local found=false
for _,v in ipairs(messages) do if v:find("Arcane Intellect",1,true) then found=true end end
assert(found,"class-specific reminder works for non-hunter")
ChalkBox_CampCommand("off")
local before=#messages
now=6000;timers[1]()
assert(#messages==before,"disabled reminder never fires on timer")
-- Forever-only utility advice should not bleed into the historical Classic addon.
_G.GetBuildInfo=function() return "1.15","1","now",11509 end
assert(ChalkBox_CampUtility(4470)==nil)
print("PASS: Forever campsite tools/wood/kit/tent, manual checklist, anti-spam timer, hunter and mage class-aware hints")
