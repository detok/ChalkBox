-- Tests for the real Blizzard damage meter gear menu extension.
local callback,eventFrame
local chat,sends={},{}
local group,raid,combat,editing=true,false,false,false
local now=100
local secret="SECRET"
local source1={name="Detok",amountPerSecond=555,totalAmount=5550}
local source2={name="Friend",amountPerSecond=423,totalAmount=4230}
local source3={name="Party|Mate",amountPerSecond=318,totalAmount=3180}
local source4={name="Fourth",amountPerSecond=202,totalAmount=2020}
local source5={name="Fifth",amountPerSecond=101,totalAmount=1010}
local data={combatSources={source1,source2,source3,source4,source5}}
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
    assert(not callback,"register native menu extension once")
    callback=fn
end}
_G.DEFAULT_CHAT_FRAME={AddMessage=function(_,message)
    chat[#chat+1]=message
end}
_G.C_ChatInfo={SendChatMessage=function(message,channel)
    sends[#sends+1]={text=message,channel=channel}
end}
_G.C_DamageMeter={GetCombatSessionFromType=function(kind,stat)
    assert(kind==2 and (stat==meterType or stat==Enum.DamageMeterType.Dps
        or stat==Enum.DamageMeterType.DamageDone
        or stat==Enum.DamageMeterType.HealingDone))
    return old
end}
_G.InCombatLockdown=function() return combat end
_G.IsInGroup=function() return group end
_G.IsInRaid=function() return raid end
_G.GetTime=function() return now end
_G.issecretvalue=function(v) return v==secret end
_G.CreateFrame=function()
    local frame={scripts={},registered={}}
    function frame:RegisterEvent(name) self.registered[name]=true end
    function frame:SetScript(name,fn) self.scripts[name]=fn end
    eventFrame=frame
    return frame
end
local native={
    GetDamageMeterType=function() return meterType end,
    GetSessionType=function() return sessionType end,
    GetSessionID=function() return sessionID end,
    GetCombatSession=function() return sessionID and saved or current end,
    IsEditing=function() return editing end,
}
local gear={GetParent=function() return native end}
local calls={}
local function MenuOpen()
    calls={}
    local root={
        CreateDivider=function() calls[#calls+1]={type="divider"} end,
        CreateTitle=function(_,name)
            calls[#calls+1]={type="title",name=name}
        end,
        CreateButton=function(_,name,action)
            calls[#calls+1]={type="button",name=name,action=action}
        end,
    }
    callback(gear,root)
    return calls
end
local function Button(prefix)
    for _,item in ipairs(calls) do
        if item.type=="button" and item.name:find(prefix,1,true)==1 then
            return item.action
        end
    end
    error("No native gear menu option: "..prefix)
end
local function Fire(name,...)
    assert(eventFrame.registered[name],"event not registered: "..name)
    eventFrame.scripts.OnEvent(eventFrame,name,...)
end
local function Tick(seconds)
    eventFrame.scripts.OnUpdate(eventFrame,seconds or 1)
end
assert(loadfile("NativeMeterPrint.lua"))("ChalkBox")
Fire("ADDON_LOADED","ChalkBox")
local status=ChalkBox_NativeMeterStatus()
assert(status.installed and status.enabled and status.rows==3 and
    status.auto==false and status.channel=="PARTY",
    "default has manual PARTY/SAY reports but auto is OFF")
assert(eventFrame.registered.PLAYER_REGEN_DISABLED and
    eventFrame.registered.PLAYER_REGEN_ENABLED,
    "after-combat automation uses client combat state transitions")
MenuOpen()
assert(#calls==10 and calls[2].name=="ChalkBox  |  Combat reports")
Button("Print top 3 to PARTY")()
assert(#sends==1 and sends[1].channel=="PARTY")
assert(sends[1].text==
    "CB DPS (Current): 1 Detok 555 | 2 Friend 423 | 3 PartyMate 318",
    "native current session, sorted rankings, and escaped chat")
now=104
Button("Print top 3 to SAY")()
assert(#sends==2 and sends[2].channel=="SAY",
    "explicit SAY destination must not route to PARTY")
Button("Report size: Top 3")()
assert(ChalkBox_NativeMeterStatus().rows==5)
MenuOpen()
assert(Button("Print top 5 to PARTY"))
now=108
Button("Print top 5 to PARTY")()
assert(#sends==3 and sends[3].text:find("5 Fifth 101",1,true),
    "user-selected Top 5 ranks use the native meter")
Button("Report size: Top 5")()
Button("Report size: Top 5")() -- Menu action retains the same callback
assert(ChalkBox_NativeMeterStatus().rows==10)
MenuOpen()
assert(Button("Print top 10 to SAY"))
now=112
meterType=0;sessionType=nil;sessionID=5
Button("Print top 10 to SAY")()
assert(#sends==4 and sends[4].channel=="SAY" and
    sends[4].text=="CB DMG (Fight 5): 1 Buddy 900",
    "history session and selected stat survive channel selection")
now=116
meterType=1;sessionType=1;sessionID=nil
current={combatSources={}}
Button("Print top 10 to PARTY")()
assert(#sends==5 and sends[5].text=="CB DPS (Last): 1 Previous 99",
    "Current-empty falls back to Blizzard's expired fight")
current=data
now=120
combat=true
Button("Print top 10 to PARTY")()
assert(#sends==5,"never read or send protected in-combat data")
combat=false
raid=true
Button("Print top 10 to PARTY")()
assert(#sends==5,"never redirect party report to raid")
Button("Print top 10 to SAY")()
assert(#sends==6 and sends[6].channel=="SAY",
    "SAY remains a deliberate separate option in raids")
raid=false
group=false
now=124
Button("Print top 10 to PARTY")()
assert(#sends==6,"PARTY never sends while solo")
Button("Print top 10 to SAY")()
assert(#sends==7 and sends[7].channel=="SAY",
    "manual SAY can be used while solo")
group=true
editing=true
now=128
Button("Print top 10 to PARTY")()
assert(#sends==7,"edit-mode preview isn't fight data")
editing=false
source2.amountPerSecond=secret
Button("Print top 10 to PARTY")()
assert(#sends==7,"never format protected values")
source2.amountPerSecond=423
source1.name=secret
Button("Print top 10 to PARTY")()
assert(#sends==7,"never send protected names")
source1.name="Detok"
now=132
Button("Print top 10 to PARTY")()
assert(#sends==8)
Button("Print top 10 to PARTY")()
assert(#sends==8,"manual 3-second throttle prevents accidental double click")

-- A short fight is not broadcast; auto must be explicitly turned on.
now=200
Fire("PLAYER_REGEN_DISABLED");now=225
Fire("PLAYER_REGEN_ENABLED");Tick(4)
assert(#sends==8,"auto default OFF")
MenuOpen()
Button("After combat: ")()
assert(ChalkBox_NativeMeterStatus().auto)
MenuOpen()
Button("Auto channel: PARTY")()
Button("Auto stat: DPS")()
assert(ChalkBox_NativeMeterStatus().channel=="SAY" and
    ChalkBox_NativeMeterStatus().metric=="damage")
-- Cycle back to DPS: damage -> healing -> dps
Button("Auto stat: DPS")()
Button("Auto stat: DPS")()
assert(ChalkBox_NativeMeterStatus().metric=="dps")
now=300;Fire("PLAYER_REGEN_DISABLED");now=305
Fire("PLAYER_REGEN_ENABLED");Tick(3)
assert(#sends==8,"minimum fight length defaults to 10s")
now=310;Fire("PLAYER_REGEN_DISABLED");now=322
old={combatSources={{name="Previous",amountPerSecond=201,totalAmount=2001}}}
Fire("PLAYER_REGEN_ENABLED")
Tick(1)
assert(#sends==8,"auto report waits for completed native session")
Tick(1.5)
assert(#sends==9 and sends[9].channel=="SAY"
    and sends[9].text=="CB DPS (Last): 1 Previous 201",
    "after-combat auto report uses selected auto stat and explicit channel")
-- Cooldown prevents a second rapid report even if another fight ends.
now=330;Fire("PLAYER_REGEN_DISABLED")
now=344;old={combatSources={{name="Previous",amountPerSecond=301,totalAmount=3001}}}
Fire("PLAYER_REGEN_ENABLED");Tick(3)
assert(#sends==9,"auto cooldown prevents repeated chat spam")
-- After cooldown, old unchanged snapshot is not re-broadcast.
now=400;Fire("PLAYER_REGEN_DISABLED");now=412
old={combatSources={{name="Previous",amountPerSecond=201,totalAmount=2001}}}
Fire("PLAYER_REGEN_ENABLED");Tick(3)
assert(#sends==9,"identical old auto summary is not repeated")
now=500;Fire("PLAYER_REGEN_DISABLED");now=512
old={combatSources={{name="Previous",amountPerSecond=405,totalAmount=4050}}}
Fire("PLAYER_REGEN_ENABLED");Tick(3)
assert(#sends==10 and sends[10].channel=="SAY" and
    sends[10].text:find("405",1,true),
    "new completed result can be posted once cooldown clears")
MenuOpen()
Button("After combat: ")()
assert(not ChalkBox_NativeMeterStatus().auto)
now=520;Fire("PLAYER_REGEN_DISABLED");now=535
Fire("PLAYER_REGEN_ENABLED");Tick(4)
assert(#sends==10,"disabled auto never posts")
now=540
ChalkBox_NativeMeterCommand("off")
assert(not ChalkBox_NativeMeterStatus().enabled)
local root2={CreateButton=function() error("disabled menu must be empty") end}
callback(gear,root2)
assert(not ChalkBox_NativeMeterPrint(native) and #sends==10)
ChalkBox_NativeMeterCommand("on")
MenuOpen()
Button("Print top 10 to PARTY")()
assert(#sends==11,"native gear report returns after re-enable")
assert(ChalkBox_NativeMeterStatus().auto==false,
    "re-enabling must not silently enable auto")
ChalkBox_NativeMeterCommand("rows 3")
ChalkBox_NativeMeterCommand("channel party")
ChalkBox_NativeMeterCommand("min 30")
ChalkBox_NativeMeterCommand("cooldown 120")
assert(ChalkBox_NativeMeterStatus().rows==3 and
    ChalkBox_NativeMeterStatus().channel=="PARTY" and
    ChalkBox_NativeMeterStatus().minFight==30 and
    ChalkBox_NativeMeterStatus().cooldown==120,
    "saved settings also respond to slash commands")
ChalkBox_NativeMeterCommand("status")
print("PASS: native PARTY/SAY print, Top 3/5/10, auto opt-in, duration/cooldown, no secret data, selected session and no spam")
