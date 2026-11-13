-- ChalkBox Updates: honest version-awareness without unsupported HTTPS APIs.
-- WoW addon Lua CANNOT fetch GitHub directly. Users can select the
-- releases URL to copy; optionally compare versions with group peers.
local PREFIX="CBXVER2"
local RELEASES="https://github.com/detok/ChalkBox/releases"
local registered=false
local lastBroadcast=-100000
local warnedThisSession=false
local function Public(v)
    return v~=nil and (type(issecretvalue)~="function" or not issecretvalue(v))
end
local function DB()
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    if type(ChalkBoxDB.updates)~="table" then
        ChalkBoxDB.updates={peerCheck=false}
    end
    return ChalkBoxDB.updates
end
local function Version(v)
    if not Public(v) or type(v)~="string" then return end
    local a,b,c=v:match("^(%d+)%.(%d+)%.(%d+)$")
    if not a then return end
    a,b,c=tonumber(a),tonumber(b),tonumber(c)
    if a>999 or b>999 or c>999 then return end
    return a,b,c
end
function ChalkBox_UpdateCompare(a,b)
    local am,an,ap=Version(a)
    local bm,bn,bp=Version(b)
    if not am or not bm then return nil end
    if am~=bm then return am>bm and 1 or -1 end
    if an~=bn then return an>bn and 1 or -1 end
    if ap~=bp then return ap>bp and 1 or -1 end
    return 0
end
local function Installed()
    local fn=C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    if type(fn)=="function" then
        local ok,value=pcall(fn,"ChalkBox","Version")
        if ok and Version(value) then return value end
    end
    return "2.0.1"
end
local function Note(msg)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff67c6b7ChalkBox Updates|r "..msg)
    end
end
function ChalkBox_UpdateStatus()
    local d=DB()
    local installed=Installed()
    local newest=d.peerVersion
    local comparison=newest and ChalkBox_UpdateCompare(newest,installed)
    return {installed=installed,peerVersion=newest,
        peerCheck=d.peerCheck==true,
        newerSeen=comparison==1,
        latestGitHubVersion=nil, -- impossible to fetch in addon Lua
        releases=RELEASES,
        directGitHubCheck=false}
end
function ChalkBox_UpdateSetPeer(on)
    local d=DB()
    d.peerCheck=on==true
    return d.peerCheck
end
local function Register()
    if registered then return true end
    local fn=C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix
    if type(fn)~="function" then return false end
    local ok,success=pcall(fn,PREFIX)
    if ok and success~=false then registered=true end
    return registered
end
local function Broadcast()
    if not DB().peerCheck or not Register() then return end
    if type(IsInGroup)~="function" or not IsInGroup() then return end
    local now=type(GetTime)=="function" and GetTime() or nil
    if type(now)~="number" or now-lastBroadcast<300 then return end
    local channel="PARTY"
    if type(IsInRaid)=="function" and IsInRaid() then
        channel="RAID"
    elseif type(IsInGroup)=="function" and
        LE_PARTY_CATEGORY_INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        channel="INSTANCE_CHAT"
    end
    local fn=C_ChatInfo and C_ChatInfo.SendAddonMessage
    if type(fn)~="function" then return end
    local ok,success=pcall(fn,PREFIX,Installed(),channel)
    if ok and success~=false then lastBroadcast=now end
end
local function Receive(prefix,message)
    if not DB().peerCheck or prefix~=PREFIX then return end
    if not Version(message) then return end
    local d=DB()
    if not d.peerVersion or ChalkBox_UpdateCompare(message,d.peerVersion)==1 then
        d.peerVersion=message
    end
    if not warnedThisSession and
        ChalkBox_UpdateCompare(message,Installed())==1 then
        warnedThisSession=true
        Note("A group member runs "..message.." (you have "..Installed()..
            "). A newer build may exist; check GitHub Releases.")
        if type(ChalkBox_UpdateRefresh)=="function" then
            ChalkBox_UpdateRefresh()
        end
    end
end
function ChalkBox_UpdateCommand()
    local s=ChalkBox_UpdateStatus()
    Note("Installed version: "..s.installed..".")
    if s.newerSeen then
        Note("A newer version "..s.peerVersion..
            " was seen on another player's ChalkBox.")
    else
        Note("No newer peer version recorded (this does NOT prove you're up to date).")
    end
    Note("WoW cannot contact GitHub directly. Copy this release link:")
    Note(s.releases)
    return s
end
local frame=CreateFrame("Frame")
for _,name in ipairs({"PLAYER_ENTERING_WORLD",
    "GROUP_ROSTER_UPDATE","CHAT_MSG_ADDON"}) do
    frame:RegisterEvent(name)
end
frame:SetScript("OnEvent",function(_,event,prefix,message)
    if event=="CHAT_MSG_ADDON" then Receive(prefix,message)
    else Broadcast() end
end)
