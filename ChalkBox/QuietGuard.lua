-- ChalkBox QuietGuard: unobtrusive, reversible nuisance protections.
-- Use Blizzard's own social options where available. No chat censorship,
-- auto-whispers, blocking friends, protected API bypasses or hidden windows.
local addonName=...
local db,ready
local frame=CreateFrame("Frame")
local count={duel=0,party=0}
local function Public(v)
    return v~=nil and (type(issecretvalue)~="function" or not issecretvalue(v))
end
local function Warn(message)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff55ccaaChalkBox QuietGuard|r "..message)
    end
end
local function Value(name)
    if type(GetCVar)=="function" then return GetCVar(name) end
    if C_CVar and type(C_CVar.GetCVar)=="function" then return C_CVar.GetCVar(name) end
end
local function SetValue(name,value)
    local setter=type(SetCVar)=="function" and SetCVar
        or C_CVar and C_CVar.SetCVar
    if type(setter)~="function" then return false end
    local before=Value(name)
    if not Public(before) then return false end
    if before==value then return true end
    local ok=pcall(setter,name,value)
    return ok and Value(name)==value
end
local backedUp={}
local function ToggleNativeCVar(key,cvar,enabled)
    local snapshot=backedUp[cvar]
    local before=Value(cvar)
    if not Public(before) or (before~="0" and before~="1") then return false end
    if enabled then
        if not snapshot and before=="0" then
            snapshot={previous=before}
            backedUp[cvar]=snapshot
        end
        return SetValue(cvar,"1")
    elseif snapshot then
        backedUp[cvar]=nil
        if before=="1" then return SetValue(cvar,snapshot.previous) end
    end
    return true
end
local guildOriginal
local guildOwned=false
local function GuildActive()
    if type(GetAutoDeclineGuildInvites)~="function" then return end
    local ok,value=pcall(GetAutoDeclineGuildInvites)
    if ok and Public(value) then return value==true end
end
local function ToggleGuild(on)
    if type(SetAutoDeclineGuildInvites)~="function" then return false end
    local current=GuildActive()
    if current==nil then return false end
    if on then
        if not current then
            if not guildOwned then guildOriginal=current;guildOwned=true end
            return pcall(SetAutoDeclineGuildInvites,true)
        end
        return true
    end
    if guildOwned then
        guildOwned=false
        if current then return pcall(SetAutoDeclineGuildInvites,guildOriginal) end
    end
    return true
end
local function ApplyNative()
    if not db then return end
    ToggleGuild(db.guild)
    ToggleNativeCVar("trade","blockTrades",db.trade)
    ToggleNativeCVar("channel","blockChannelInvites",db.channel)
end

function ChalkBox_GuardSet(key,on)
    if not db or not ({guild=true,duel=true,party=true,trade=true,channel=true})[key] then return end
    db[key]=on==true
    if key=="guild" or key=="trade" or key=="channel" then ApplyNative() end
end
function ChalkBox_GuardStatus()
    local guild=GuildActive()
    return {
        guild=(guild==nil and "not available" or tostring(guild)),
        duel=tostring(db and db.duel==true),
        party=tostring(db and db.party==true),
        trade=tostring(Value("blockTrades") or "not available"),
        channel=tostring(Value("blockChannelInvites") or "not available"),
        duelBlocked=count.duel,partyBlocked=count.party,
    }
end
local function Decline(which)
    if type(InCombatLockdown)=="function" and InCombatLockdown() then return end
    if which=="duel" and type(CancelDuel)=="function" then
        local ok=pcall(CancelDuel)
        if ok then
            count.duel=count.duel+1
            if type(StaticPopup_Hide)=="function" then pcall(StaticPopup_Hide,"DUEL_REQUESTED") end
        end
    elseif which=="party" and C_PartyInfo and type(C_PartyInfo.DeclineInvite)=="function" then
        local ok=pcall(C_PartyInfo.DeclineInvite)
        if ok then
            count.party=count.party+1
            if type(StaticPopup_Hide)=="function" then pcall(StaticPopup_Hide,"PARTY_INVITE") end
        end
    end
end
function ChalkBox_GuardCommand(message)
    if not db then return end
    local action,arg=(message or ""):match("^(%S*)%s*(.-)%s*$")
    action=string.lower(action or "")
    arg=string.lower(arg or "")
    if ({guild=true,duel=true,party=true,trade=true,channel=true})[action]
        and (arg=="on" or arg=="off") then
        ChalkBox_GuardSet(action,arg=="on")
        Warn(action.." protection "..arg..".")
    else
        local state=ChalkBox_GuardStatus()
        Warn("Guild="..state.guild.."; duels="..state.duel..
            "; parties="..state.party.."; trades="..state.trade..
            "; channels="..state.channel..
            ". Filtered requests: "..state.duelBlocked.." duels / "..state.partyBlocked.." parties.")
        Warn("Change via Options > AddOns > ChalkBox > QuietGuard or /chalk guard guild|duel|party|trade|channel on|off.")
    end
end
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("DUEL_REQUESTED")
frame:RegisterEvent("PARTY_INVITE_REQUEST")
frame:SetScript("OnEvent",function(_,event,name)
    if event=="ADDON_LOADED" then
        if name~=addonName then return end
        if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
        if type(ChalkBoxDB.guard)~="table" then ChalkBoxDB.guard={} end
        db=ChalkBoxDB.guard
        if db.guild==nil then db.guild=true end
        if db.duel==nil then db.duel=true end
        db.party=db.party==true
        db.trade=db.trade==true
        db.channel=db.channel==true
        ready=true
        ApplyNative()
    elseif event=="PLAYER_ENTERING_WORLD" then
        if ready then ApplyNative() end
    elseif event=="DUEL_REQUESTED" and db and db.duel then
        Decline("duel")
    elseif event=="PARTY_INVITE_REQUEST" and db and db.party then
        Decline("party")
    end
end)
