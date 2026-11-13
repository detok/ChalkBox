-- Updates are honest: WoW cannot do GitHub HTTPS checks. Show the
-- installed TOC version, offer a copyable link and optional group peer awareness.
_G.ChalkBoxDB={}
local received={}
local frame
_G.CreateFrame=function()
    local f={}
    function f:RegisterEvent(e) received[e]=true end
    function f:SetScript(e,fn) if e=="OnEvent" then frame=fn end end
    return f
end
_G.C_AddOns={
    GetAddOnMetadata=function(addon,field)
        assert(addon=="ChalkBox" and field=="Version")
        return "2.0.1"
    end
}
local sends,registrations={},0
_G.C_ChatInfo={
    RegisterAddonMessagePrefix=function(prefix)
        assert(prefix=="CBXVER2")
        registrations=registrations+1
        return true
    end,
    SendAddonMessage=function(prefix,message,channel)
        sends[#sends+1]={prefix=prefix,message=message,channel=channel}
        return true
    end,
}
_G.GetTime=function() return 1000 end
_G.IsInGroup=function() return true end
_G.IsInRaid=function() return false end
local text={}
_G.DEFAULT_CHAT_FRAME={AddMessage=function(_,line)
    text[#text+1]=line
end}
assert(loadfile("UpdateCheck.lua"))("ChalkBox")
assert(received.PLAYER_ENTERING_WORLD and received.CHAT_MSG_ADDON)
assert(ChalkBox_UpdateCompare("2.1.0","2.0.9")==1)
assert(ChalkBox_UpdateCompare("2.0.0","2.0.1")==-1)
assert(ChalkBox_UpdateCompare("2.0.1","2.0.1")==0)
assert(ChalkBox_UpdateCompare("2.0.1-rc", "2.0.0")==nil)
local status=ChalkBox_UpdateStatus()
assert(status.installed=="2.0.1" and status.directGitHubCheck==false
    and status.latestGitHubVersion==nil,
    "WoW addon never falsely claims to fetch GitHub release data")
assert(not status.peerCheck,"version broadcasting defaults OFF")
frame(nil,"PLAYER_ENTERING_WORLD")
assert(#sends==0,"no unsolicited group addon traffic")
assert(ChalkBox_UpdateSetPeer(true))
frame(nil,"PLAYER_ENTERING_WORLD")
assert(#sends==1 and sends[1].message=="2.0.1" and
    sends[1].channel=="PARTY" and registrations==1)
frame(nil,"GROUP_ROSTER_UPDATE")
assert(#sends==1,"version awareness is throttled")
frame(nil,"CHAT_MSG_ADDON","CBXVER2","2.0.2")
assert(ChalkBox_UpdateStatus().newerSeen,
    "actual newer peer version can trigger advisory flag")
frame(nil,"CHAT_MSG_ADDON","CBXVER2","2.0.0")
assert(ChalkBox_UpdateStatus().peerVersion=="2.0.2",
    "older peer version does not overwrite newer evidence")
frame(nil,"CHAT_MSG_ADDON","MALICIOUS","99.0.0")
assert(ChalkBox_UpdateStatus().peerVersion=="2.0.2")
frame(nil,"CHAT_MSG_ADDON","CBXVER2","garbage")
assert(ChalkBox_UpdateStatus().peerVersion=="2.0.2",
    "peer messages must be numeric semver and exact addon prefix")
local report=ChalkBox_UpdateCommand()
assert(report.installed=="2.0.1" and
    table.concat(text," "):find("github.com/detok/ChalkBox/releases",1,true),
    "manual status gives installed version and real GitHub Releases address")
assert(ChalkBox_UpdateSetPeer(false)==false)
frame(nil,"CHAT_MSG_ADDON","CBXVER2","3.0.0")
assert(ChalkBox_UpdateStatus().peerVersion=="2.0.2",
    "turning peer awareness off stops handling addon messages")
print("PASS: installed-version reading, honest no-HTTPS status, opt-in throttled peer awareness and release URL")
