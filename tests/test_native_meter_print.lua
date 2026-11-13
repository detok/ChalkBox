-- Regression: actual Forever native damage-meter menu extension, not a clone.
local callback,frame
local chat,sends={},{}
local group=true
local raid=false
local combat=false
local editing=false
local time=100
local secret="SECRET"
local source1={name="Detok",amountPerSecond=555,totalAmount=5550}
local source2={name="Friend",amountPerSecond=423,totalAmount=4230}
local source3={name="Party|Mate",amountPerSecond=318,totalAmount=3180}
local data={combatSources={source1,source2,source3}}
local current=data
local saved={combatSources={{name="Buddy",amountPerSecond=111,totalAmount=900}}}
local old={combatSources={{name="Previous",amountPerSecond=99,totalAmount=999}}}
local meterType,sessionType,sessionID=1,1,nil
_G.ChalkBoxDB={meter={shown=false}}
_G.Enum={DamageMeterType={
    DamageDone=0,Dps=1,HealingDone=2,Hps=3,Interrupts=5,
    DamageTaken=7,Dispels=8,Deaths=9
}, DamageMeterSessionType={Overall=0,Current=1,Expired=2}}
_G.Menu={ModifyMenu=function(tag,fn)
    assert(tag=="MENU_DAMAGE_METER_WINDOW_SETTINGS")
    assert(not callback,"only register Blizzard menu extension once")
    callback=fn
end}
_G.DEFAULT_CHAT_FRAME={AddMessage=function(_,message) chat[#chat+1]=message end}
_G.C_ChatInfo={SendChatMessage=function(message,channel)
    sends[#sends+1]={text=message,channel=channel}
end}
_G.C_DamageMeter={GetCombatSessionFromType=function(kind,stat)
    assert(kind==2 and stat==meterType)
    return old
end}
_G.InCombatLockdown=function() return combat end
_G.IsInGroup=function() return group end
_G.IsInRaid=function() return raid end
_G.GetTime=function() return time end
_G.issecretvalue=function(v) return v==secret end
local eventFrame
_G.CreateFrame=function()
    local frame={}
    function frame:RegisterEvent() end
    function frame:SetScript(_,fn) self.callback=fn end
    eventFrame=frame
    return frame
end
local native={
    GetDamageMeterType=function() return meterType end,
    GetSessionType=function() return sessionType end,
    GetSessionID=function() return sessionID end,
    GetCombatSession=function()
        return sessionID and saved or current
    end,
    IsEditing=function() return editing end,
}
local gear={GetParent=function() return native end}
local calls={}
local root={
    CreateDivider=function() calls[#calls+1]={type="divider"} end,
    CreateButton=function(_,name,action)
        calls[#calls+1]={type="button",name=name,action=action}
    end
}
assert(loadfile("NativeMeterPrint.lua"))("ChalkBox")
eventFrame.callback(eventFrame,"ADDON_LOADED","ChalkBox")
local state=ChalkBox_NativeMeterStatus()
assert(state.installed and state.enabled)
callback(gear,root)
assert(#calls==2 and calls[2].name=="ChalkBox: PRINT top 3 to PARTY")
calls[2].action()
assert(#sends==1 and sends[1].channel=="PARTY")
assert(sends[1].text=="CB DPS (Current): 1 Detok 555 | 2 Friend 423 | 3 PartyMate 318",
    "must print the native window selection and escape chat markup")

time=105
meterType=0
sessionType=nil
sessionID=5
calls[2].action()
assert(#sends==2 and sends[2].text=="CB DMG (Fight 5): 1 Buddy 900",
    "historical native window should print its own session and damage mode")

time=110
meterType=1
sessionType=1
sessionID=nil
current={combatSources={}}
calls[2].action()
assert(#sends==3 and sends[3].text=="CB DPS (Last): 1 Previous 99",
    "empty Current window should prefer completed Last session")
current=data

time=115
combat=true
calls[2].action()
assert(#sends==3,"never send protected in-combat data")
combat=false
raid=true
calls[2].action()
assert(#sends==3,"raid must not be accidentally sent to PARTY")
raid=false
group=false
calls[2].action()
assert(#sends==3,"solo must not send party chat")
group=true
editing=true
calls[2].action()
assert(#sends==3,"Edit Mode preview is never real combat data")
editing=false

source2.amountPerSecond=secret
time=120
calls[2].action()
assert(#sends==3,"secret numeric data must not be read, formatted, or posted")
source2.amountPerSecond=423
source1.name=secret
calls[2].action()
assert(#sends==3,"secret player names must never be sent")
source1.name="Detok"

time=125
ChalkBox_NativeMeterCommand("off")
assert(not ChalkBox_NativeMeterStatus().enabled)
local other={}
local root2={
    CreateButton=function() error("disabled menu must not create buttons") end
}
callback(gear,root2)
assert(not ChalkBox_NativeMeterPrint(native) and #sends==3,
    "disabled option must reject direct print too")
ChalkBox_NativeMeterCommand("on")
time=126
calls[2].action()
assert(#sends==4,"re-enable should restore native menu function")
calls[2].action()
assert(#sends==4,"duplicate-click cooldown must prevent spam")
ChalkBox_NativeMeterCommand("status")
assert(#sends==4,"status command never sends chat")
print("PASS: native Blizzard gear PRINT, selected type/session, last fallback, party-only, secret-safe, combat/edit-mode guards, toggle and duplicate cooldown")
