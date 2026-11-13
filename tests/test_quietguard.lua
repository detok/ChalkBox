-- QuietGuard: native social controls, reversible original settings and opt-in decline.
local frames,notes,declined,hidden={}, {},0,{}
local guild=false
local cvars={blockTrades="0",blockChannelInvites="0"}
_G.ChalkBoxDB={}
_G.GetAutoDeclineGuildInvites=function() return guild end
_G.SetAutoDeclineGuildInvites=function(value) guild=value end
_G.GetCVar=function(key) return cvars[key] end
_G.SetCVar=function(key,val) cvars[key]=val end
_G.CancelDuel=function() declined=declined+1 end
_G.C_PartyInfo={DeclineInvite=function() declined=declined+100 end}
_G.StaticPopup_Hide=function(name) hidden[#hidden+1]=name end
_G.InCombatLockdown=function() return _G.testCombat==true end
_G.DEFAULT_CHAT_FRAME={AddMessage=function(_,s) notes[#notes+1]=s end}
_G.CreateFrame=function()
    local frame={events={}}
    function frame:RegisterEvent(name) self.events[name]=true end
    function frame:SetScript(_,fn) self.onEvent=fn end
    frames[#frames+1]=frame
    return frame
end
assert(loadfile("QuietGuard.lua"))("ChalkBox")
local frame=frames[#frames]
local function Fire(event,...)
    assert(frame.events[event]);frame.onEvent(frame,event,...)
end
Fire("ADDON_LOADED","ChalkBox")
assert(ChalkBoxDB.guard.guild and ChalkBoxDB.guard.duel)
assert(not ChalkBoxDB.guard.party and not ChalkBoxDB.guard.trade and not ChalkBoxDB.guard.channel)
assert(guild==true,"guild invites disabled using the native setting")
assert(cvars.blockTrades=="0","trade is opt-in, not blocked by default")
Fire("DUEL_REQUESTED","Stranger")
assert(declined==1 and hidden[#hidden]=="DUEL_REQUESTED",
    "duel invite should be automatically cancelled and its popup hidden")
Fire("PARTY_INVITE_REQUEST","Friend")
assert(declined==1,"party invites should be untouched by default")
ChalkBox_GuardSet("party",true)
Fire("PARTY_INVITE_REQUEST","Stranger")
assert(declined==101,"explicitly enabled party filter declines")
_G.testCombat=true
Fire("DUEL_REQUESTED","Stranger")
assert(declined==101,"do not run social API actions during combat lockdown")
_G.testCombat=false
ChalkBox_GuardSet("duel",false)
Fire("DUEL_REQUESTED","Stranger")
assert(declined==101,"duels can be allowed again")
ChalkBox_GuardSet("trade",true)
ChalkBox_GuardSet("channel",true)
assert(cvars.blockTrades=="1" and cvars.blockChannelInvites=="1",
    "native social CVars block trades/channels")
ChalkBox_GuardSet("trade",false)
ChalkBox_GuardSet("channel",false)
assert(cvars.blockTrades=="0" and cvars.blockChannelInvites=="0",
    "original native settings restored when filters disabled")
ChalkBox_GuardSet("guild",false)
assert(guild==false,"guild setting restored if we changed it")
local status=ChalkBox_GuardStatus()
assert(status.duelBlocked==1 and status.partyBlocked==1)
ChalkBox_GuardCommand("status")
assert(#notes>0,"manual status is available without spamming each invite")
print("PASS: QuietGuard default guild/duel block; party/trade/channel opt-in; native reversible prefs, combat skip, status")
