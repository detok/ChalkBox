-- ChalkBox integrated Emota module, adapted from detok/emotaspeak v0.3.0.
-- Retains movement, reaction, social and post-combat logic; expands safe idle personality.
-- Experimental low-health probe intentionally excluded from the combined addon.
-- Native emote attempts are OPT-IN. Standalone EmotaSpeak takes precedence if installed.
-- No custom /e, outgoing chat, combat log, or forbidden secret-value calculations.

local addonName = ...
local frame = CreateFrame("Frame")
local settings
local inCombat = false
local combatStarted = 0
local guidToCompanion = {}
local lastAttempt = -1e8
local lastMeaningfulAttempt = -1e8
local lastWaveReply = -1e8
local lastByReason = {}
-- Per-login session pacing; intentionally not written to SavedVariables.
local idleSince = nil
local idleAfterSeconds = nil
local sessionJokeCount = 0
local sessionIdleActions = 0
local lastIdleToken, previousIdleToken = nil, nil
local activePose, poseUntil = nil, nil
local idleTicker = nil

-- Blizzard's EMOTE##_TOKEN constants expose this client's native emote list.
-- Triggered emotes stay enabled by default; other entries are opt-in for idle
-- variety, but each can be previewed manually from the native settings page.
local automatic={WAVE=true,JOKE=true,TRAIN=true,CHEER=true,CRY=true,
    MOURN=true,OOM=true,SIGH=true,BOW=true,LAUGH=true,FLEX=true}
-- Intentional, curated *default* idle reactions. They are checked by default in
-- the emote catalog, and each can be disabled independently. Pose actions alter
-- character state: only use them while the player is stationary and safe.
local idlePresets = {
    {token="JOKE", weight=21},
    {token="DANCE", weight=9},
    {token="SIT", weight=4, pose=true},
    {token="SLEEP", weight=3, pose=true},
    {token="LAYDOWN", weight=3, pose=true},
    {token="YAWN", weight=8},
    {token="PONDER", weight=10},
    {token="SHRUG", weight=8},
    {token="FLEX", weight=5},
    {token="ROFL", weight=5},
    {token="SALUTE", weight=4},
    {token="SIGH", weight=6},
    {token="STARE", weight=4},
    {token="CHICKEN", weight=3},
    {token="APPLAUD", weight=3},
    {token="LOOK", weight=4},
}
local idleFeatured, poseTokens = {}, {}
for _,entry in ipairs(idlePresets) do
    idleFeatured[entry.token]=true
    if entry.pose then poseTokens[entry.token]=true end
end
local defaults={"WAVE","JOKE","TRAIN","CHEER","CRY","MOURN","OOM","SIGH",
    "BOW","LAUGH","FLEX","DANCE","SALUTE","KNEEL","THANK","HELLO",
    "GOODBYE","NO","YES","APPLAUD","ROAR","SHY","SLEEP","SIT",
    "LAYDOWN","STAND","YAWN","PONDER","SHRUG","ROFL","STARE","LOOK",
    "POINT","BEG","CHICKEN","TALK","WELCOME","CONGRATULATE"}
local catalog
local function Catalog()
    if catalog then return catalog end
    local found={}
    for _,token in ipairs(defaults) do found[token]=true end
    for name,token in pairs(_G) do
        if type(name)=="string" and name:match("^EMOTE%d+_TOKEN$")
            and type(token)=="string" and token:match("^[A-Z][A-Z0-9_]*$") then
            found[token]=true
        end
    end
    catalog={}
    for token in pairs(found) do
        catalog[#catalog+1]={
            token=token,automatic=automatic[token]==true,idle=idleFeatured[token]==true
        }
    end
    table.sort(catalog,function(a,b)
        if a.automatic~=b.automatic then return a.automatic end
        if a.idle~=b.idle then return a.idle end
        return a.token<b.token
    end)
    return catalog
end
function ChalkBox_EmotaCatalog()
    return Catalog()
end
function ChalkBox_EmotaGetEnabled(token)
    if not automatic[token] then
        local found=false
        for _,entry in ipairs(Catalog()) do if entry.token==token then found=true;break end end
        if not found then return false end
    end
    local overrides=settings and settings.allowedEmotes
    if overrides and overrides[token]~=nil then return overrides[token]==true end
    return automatic[token]==true or idleFeatured[token]==true
end
function ChalkBox_EmotaSetEnabled(token,value)
    for _,entry in ipairs(Catalog()) do
        if entry.token==token and settings then
            settings.allowedEmotes=settings.allowedEmotes or {}
            settings.allowedEmotes[token]=value==true
            return
        end
    end
end
local function JokeScale()
    local value=settings and settings.jokeFrequency or 50
    if value<50 then return 1+(50-value)*9/50 end
    return 1-(value-50)*0.82/50
end
local function Hidden(value)
    return value ~= nil and type(issecretvalue) == "function" and issecretvalue(value)
end

local function Note(message, always)
    if always or (settings and settings.debug) then
        DEFAULT_CHAT_FRAME:AddMessage("|cff77ccffChalkBox Emota|r " .. message)
    end
end

local function Remember(unit, relation)
    local guid = UnitGUID(unit)
    if guid and not Hidden(guid) then
        guidToCompanion[guid] = relation
    end
end

local function RefreshCompanions()
    wipe(guidToCompanion)
    Remember("pet", "pet")
    if IsInRaid() then
        for index = 1, GetNumGroupMembers() do
            Remember("raid" .. index, "group")
        end
    elseif IsInGroup() then
        for index = 1, GetNumSubgroupMembers() do
            Remember("party" .. index, "group")
        end
    end
end

local function StandaloneEnabled()
    if C_AddOns and type(C_AddOns.IsAddOnLoaded) == "function" then
        local loaded = C_AddOns.IsAddOnLoaded("EmotaSpeak")
        if not Hidden(loaded) and loaded then return true end
    elseif type(IsAddOnLoaded) == "function" then
        local loaded = IsAddOnLoaded("EmotaSpeak")
        if not Hidden(loaded) and loaded then return true end
    end
    return false
end

local function NativeEmote(token, reason, manual, targetName)
    if StandaloneEnabled() then
        if manual then Note("Standalone EmotaSpeak is active; integrated emotes are paused. Disable the standalone addon to use this module.", true) end
        return false
    end
    if not C_ChatInfo or not C_ChatInfo.PerformEmote then
        Note("C_ChatInfo.PerformEmote does not exist in this client.", true)
        return false
    end
    if not manual and not (settings and settings.auto) then
        return false
    end
    if not manual and token~="STAND" and not ChalkBox_EmotaGetEnabled(token) then
        return false
    end

    local now = GetTime()
    if not manual then
        -- A single global cooldown and a longer per-trigger lock prevent spam.
        local idleReason=(reason=="idle-joke" or reason=="idle-personality" or
            reason=="idle-variety" or reason=="idle-pose-finish")
        local cooldown=idleReason and 15 or 45
        if now - lastAttempt < cooldown or now - (lastByReason[reason] or -1e8) < cooldown then
            return false
        end
        lastAttempt = now
        if not idleReason then lastMeaningfulAttempt = now end
        lastByReason[reason] = now
    end

    if C_ChatInfo.InChatMessagingLockdown then
        local lockdown = C_ChatInfo.InChatMessagingLockdown()
        if Hidden(lockdown) or lockdown then
            Note("Skipped " .. token .. ": chat messaging is restricted.", true)
            return false
        end
    end
    local _, instanceType = GetInstanceInfo()
    if instanceType == "pvp" or instanceType == "arena" then
        Note("Skipped emote attempt in a PvP instance.")
        return false
    end

    -- pcall catches a Lua error; it does NOT bypass a protected-action rule.
    local ok, returned
    if targetName then
        ok, returned = pcall(C_ChatInfo.PerformEmote, token, targetName)
    else
        ok, returned = pcall(C_ChatInfo.PerformEmote, token)
    end
    if ok then
        -- A false return was observed even when Forever visibly played WAVE/TRAIN.
        -- Do not label this harmless return as an error or spam it in chat.
        -- It remains an observation, not proof of successful playback.
        Note(("Emote requested: %s (%s)"):format(token, reason), manual)
        return true
    else
        Note(("%s -> %s: API raised an error or restriction"):format(reason, token), true)
    end
    return false
end

local function React(token, reason, chance, targetName)
    if not settings or not settings.auto then
        return
    end
    if math.random() <= chance then
        NativeEmote(token, reason, false, targetName)
    end
end

-- Only replies to an English /wave clearly directed at our character.
-- No reply to untargeted emotes, our own emotes or another LivingSoul user
-- repeatedly responding: the 5-minute social lock prevents ping-pong loops.

-- Idle personality is a weighted, low-frequency rotation, not a
-- time-based chat spammer. It can choose to do nothing, and avoids both of the
-- previous two actions when there are enough enabled choices.
local function NextIdleDelay()
    local baseline
    if sessionIdleActions==0 then baseline=60
    elseif sessionIdleActions==1 then baseline=math.random(90,180)
    elseif sessionIdleActions==2 then baseline=math.random(120,300)
    elseif sessionIdleActions==3 then baseline=math.random(180,420)
    else baseline=math.random(240,600) end
    return math.max(20,math.floor(baseline*JokeScale()+0.5))
end

local function StartIdle()
    idleSince=GetTime()
    idleAfterSeconds=NextIdleDelay()
    Note(("Idle window begins; possible event in %ds (session idle events: %d)"):format(
        idleAfterSeconds,sessionIdleActions))
end

local function EndIdle()
    idleSince=nil
    idleAfterSeconds=nil
    -- Walking or combat naturally breaks sitting/sleeping poses. Never send a
    -- potentially restricted STAND command while moving or in combat.
    activePose=nil
    poseUntil=nil
end

local function IdleIsSafe()
    if type(InCombatLockdown)=="function" and InCombatLockdown() then return false end
    if type(UnitAffectingCombat)=="function" then
        local fighting=UnitAffectingCombat("player")
        if Hidden(fighting) or fighting then return false end
    end
    if type(IsPlayerMoving)=="function" then
        local moving=IsPlayerMoving()
        if Hidden(moving) or moving then return false end
    end
    if type(UnitIsDeadOrGhost)=="function" then
        local dead=UnitIsDeadOrGhost("player")
        if Hidden(dead) or dead then return false end
    end
    if type(UnitIsFeignDeath)=="function" then
        local feign=UnitIsFeignDeath("player")
        if Hidden(feign) or feign then return false end
    end
    if type(UnitIsAFK)=="function" then
        local afk=UnitIsAFK("player")
        if Hidden(afk) or afk then return false end
    end
    if type(IsMounted)=="function" then
        local mounted=IsMounted()
        if Hidden(mounted) or mounted then return false end
    end
    if type(UnitOnTaxi)=="function" then
        local taxi=UnitOnTaxi("player")
        if Hidden(taxi) or taxi then return false end
    end
    for _,fn in ipairs({"UnitCastingInfo","UnitChannelInfo"}) do
        local api=_G[fn]
        if type(api)=="function" then
            local cast=api("player")
            if Hidden(cast) or cast then return false end
        end
    end
    for _,name in ipairs({"MerchantFrame","TradeFrame","BankFrame","MailFrame",
        "AuctionHouseFrame","AuctionFrame"}) do
        local ui=_G[name]
        if ui and ui.IsShown then
            local shown=ui:IsShown()
            if Hidden(shown) or shown then return false end
        end
    end
    return true
end

local function IdlePool()
    local pool={}
    local context=nil
    if settings and settings.contextual~=false and
        type(ChalkBox_PersonalityContext)=="function" then
        context=ChalkBox_PersonalityContext()
    end
    for _,entry in ipairs(idlePresets) do
        if ChalkBox_EmotaGetEnabled(entry.token) then
            local extra=context and context.weights[entry.token] or 0
            pool[#pool+1]={token=entry.token,weight=entry.weight+extra,pose=entry.pose}
        end
    end
    if context and context.weights then
        for token,weight in pairs(context.weights) do
            if ChalkBox_EmotaGetEnabled(token) then
                local found=false
                for _,entry in ipairs(pool) do if entry.token==token then found=true;break end end
                if not found then pool[#pool+1]={token=token,weight=weight} end
            end
        end
        if context.petName and ChalkBox_EmotaGetEnabled("CHEER") then
            pool[#pool+1]={token="CHEER",weight=5,petName=context.petName}
        end
    end
    if settings and settings.idleVariety then
        -- Explicitly enabled additional emotes can join the pool. The curated
        -- set above remains the primary source of animated behaviors.
        for _,entry in ipairs(Catalog()) do
            if not automatic[entry.token] and not idleFeatured[entry.token]
                and entry.token~="STAND" and ChalkBox_EmotaGetEnabled(entry.token) then
                pool[#pool+1]={token=entry.token,weight=2}
            end
        end
    end
    if #pool>2 then
        local filtered={}
        for _,entry in ipairs(pool) do
            if entry.token~=lastIdleToken and entry.token~=previousIdleToken then
                filtered[#filtered+1]=entry
            end
        end
        if #filtered>0 then return filtered end
    end
    return pool
end

local function PickIdle()
    local pool=IdlePool()
    local total=0
    for _,entry in ipairs(pool) do total=total+entry.weight end
    if total<=0 then return nil end
    local pick=math.random(1,total)
    for _,entry in ipairs(pool) do
        pick=pick-entry.weight
        if pick<=0 then return entry end
    end
end

local function CheckIdle()
    if StandaloneEnabled() then return end
    if not settings or not settings.auto or not settings.idleAuto then return end
    if not IdleIsSafe() then return end
    local now=GetTime()
    if activePose then
        if poseUntil and now>=poseUntil then
            if NativeEmote("STAND","idle-pose-finish",false) then
                activePose,poseUntil=nil,nil
                StartIdle()
            end
        end
        return
    end
    if not idleSince or not idleAfterSeconds then return end
    if now-idleSince<idleAfterSeconds then return end
    if now-lastMeaningfulAttempt<120 then return end
    -- Quiet roll: even when the timer expires, nothing may happen. At the
    -- center slider 25% of opportunities are skipped; very frequent settings
    -- skip a little less, very rare settings skip a little more.
    local frequency=settings.jokeFrequency or 50
    local chance=75+(frequency-50)*0.30
    if math.random(1,100)>chance then
        StartIdle()
        return
    end
    local selected=PickIdle()
    if not selected then
        StartIdle()
        return
    end
    local token=selected.token
    local reason=token=="JOKE" and "idle-joke" or "idle-personality"
    if NativeEmote(token,reason,false,selected.petName) then
        previousIdleToken,lastIdleToken=lastIdleToken,token
        sessionIdleActions=sessionIdleActions+1
        if token=="JOKE" then sessionJokeCount=sessionJokeCount+1 end
        Note(("Idle personality: %s (event %d)"):format(token,sessionIdleActions))
        if selected.pose then
            -- We only stand the character up again if Emota initiated this pose,
            -- it remained safe, and the player has not moved or entered combat.
            activePose=token
            poseUntil=now+math.random(20,38)
            return
        end
    end
    StartIdle()
end

function ChalkBox_EmotaPreviewIdle()
    if not settings then return end
    local picked=PickIdle()
    if not picked then
        Note("Enable at least one idle emote in the Emote Catalog first.",true)
        return
    end
    return NativeEmote(picked.token,"idle-preview",true,picked.petName)
end

local function MaybeWaveBack(text, sender, target)
    if not settings or not settings.auto or InCombatLockdown() then return end
    if not text or not sender or Hidden(text) or Hidden(sender) or Hidden(target) then return end
    if GetLocale() ~= "enUS" and GetLocale() ~= "enGB" then return end
    local me = UnitName("player")
    if not me or sender == me or sender:match("^[^-]+") == me then return end
    local targetIsMe = target and (target == me or target:match("^[^-]+") == me)
    local isWaveToMe = text:lower():find("waves at you", 1, true)
    if not targetIsMe or not isWaveToMe then return end
    local now = GetTime()
    if now - lastWaveReply < 300 then return end
    lastWaveReply = now
    Note("Targeted /wave from " .. sender .. " detected.")
    React("WAVE", "wave-return", 1.0, sender)
end

local function OnDeath(guid)
    if not guid or Hidden(guid) then
        Note("UNIT_DIED received with unavailable/secret GUID; cannot identify unit.")
        return
    end
    local relation = guidToCompanion[guid]
    if relation == "pet" then
        Note("My pet died.")
        React("CRY", "pet-died", 1.0)
    elseif relation == "group" then
        Note("A party/raid member died.")
        React("MOURN", "group-died", 0.7)
    end
end

local function OnEvent(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon ~= addonName then return end
        if type(ChalkBoxDB) ~= "table" then ChalkBoxDB = {} end
        if type(ChalkBoxDB.emota) ~= "table" then ChalkBoxDB.emota = {} end
        local saved = ChalkBoxDB.emota
        saved.auto = saved.auto == true
        saved.debug = saved.debug == true
        saved.idleAuto = saved.idleAuto ~= false
        saved.idleVariety = saved.idleVariety == true
        if saved.contextual==nil then saved.contextual=true end
        saved.jokeFrequency = type(saved.jokeFrequency)=="number"
            and math.max(0,math.min(100,math.floor(saved.jokeFrequency+0.5))) or 50
        if type(saved.allowedEmotes)~="table" then saved.allowedEmotes={} end
        settings = saved
        if not idleTicker and C_Timer and C_Timer.NewTicker then
            idleTicker = C_Timer.NewTicker(5, CheckIdle)
        end

    elseif event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" then
        RefreshCompanions()
        if event == "PLAYER_ENTERING_WORLD" then
            EndIdle()
            if type(IsPlayerMoving) == "function" then
                local moving = IsPlayerMoving()
                if not Hidden(moving) and not moving then StartIdle() end
            end
        end
    elseif event == "PLAYER_STARTED_MOVING" then
        EndIdle()
    elseif event == "PLAYER_STOPPED_MOVING" then
        StartIdle()
    elseif event == "UNIT_PET" then
        local unit = ...
        if unit == "player" then
            local guid = UnitGUID("pet")
            if guid and not Hidden(guid) then
                guidToCompanion[guid] = "pet"
            end
        end
    elseif event == "UNIT_DIED" then
        OnDeath(...)
    elseif event == "UI_ERROR_MESSAGE" then
        local errorID, message = ...
        if message and not Hidden(message) then
            if ERR_OUT_OF_MANA and message == ERR_OUT_OF_MANA then
                Note("A cast failed because there was not enough mana.")
                React("OOM", "oom-cast-error", 1.0)
            elseif ERR_OUT_OF_FOCUS and message == ERR_OUT_OF_FOCUS then
                Note("An ability failed because there was not enough focus.")
                React("SIGH", "focus-cast-error", 0.25)
            elseif ERR_OUT_OF_ENERGY and message == ERR_OUT_OF_ENERGY then
                Note("An ability failed because there was not enough energy.")
                React("SIGH", "energy-cast-error", 0.2)
            end
        end
    elseif event == "UI_INFO_MESSAGE" then
        local infoID, message = ...
        if message and not Hidden(message) then
            if ERR_TRADE_COMPLETE and message == ERR_TRADE_COMPLETE then
                Note("Trade completed successfully.")
                React("BOW", "trade-complete", 0.85)
            elseif ERR_TRADE_CANCELLED and message == ERR_TRADE_CANCELLED then
                Note("Trade was canceled; no emote.")
            end
        end
    elseif event == "UNIT_COMBAT" then
        local unit, combatEvent = ...
        if unit == "player" and not Hidden(combatEvent) then
            if combatEvent == "DODGE" then
                Note("Dodged an attack.")
                React("LAUGH", "dodge", 0.04)
            elseif combatEvent == "PARRY" or combatEvent == "BLOCK" then
                Note("Parried or blocked.")
                React("FLEX", "defense", 0.03)
            end
        end
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
        local unit = ...
        if unit == "player" then
            Note("My cast was interrupted.")
            React("SIGH", "interrupted", 0.08)
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true
        combatStarted = GetTime()
        EndIdle()
        Note("Combat started.")
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false
        local duration = GetTime() - combatStarted
        Note(("Combat ended after %.1fs (does not imply kills)."):format(duration))
        if combatStarted > 0 and duration >= 20 then
            React("TRAIN", "long-fight-ended", 0.12)
        end
        combatStarted = 0
        -- The player may be standing still after combat without a STOPPED event.
        -- Start a fresh idle timer only if the movement API confirms stationary.
        if type(IsPlayerMoving) == "function" then
            local moving = IsPlayerMoving()
            if not Hidden(moving) and not moving then StartIdle() end
        end
    elseif event == "PLAYER_LEVEL_UP" then
        Note("Level up!")
        React("CHEER", "level-up", 1.0)
    elseif event == "QUEST_TURNED_IN" then
        Note("Quest turned in.")
        React("CHEER", "quest-turn-in", 0.12)
    elseif event == "PLAYER_UNGHOST" then
        Note("Returned from ghost form.")
        React("SIGH", "resurrection", 0.65)
    elseif event == "CHAT_MSG_TEXT_EMOTE" then
        local text, sender, _, _, target = ...
        MaybeWaveBack(text, sender, target)
    elseif event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
        local sourceAddon, functionName = ...
        if sourceAddon == addonName then
            Note("Blizzard blocked an addon action: " .. (Hidden(functionName) and "(secret)" or tostring(functionName)), true)
        end
    end
end

frame:SetScript("OnEvent", OnEvent)
for _, event in ipairs({
    "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "UNIT_PET",
    "UNIT_DIED", "UI_ERROR_MESSAGE", "UI_INFO_MESSAGE", "UNIT_COMBAT", "UNIT_SPELLCAST_INTERRUPTED",
    "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
    "PLAYER_STARTED_MOVING", "PLAYER_STOPPED_MOVING",
    "PLAYER_LEVEL_UP", "QUEST_TURNED_IN", "PLAYER_UNGHOST",
    "CHAT_MSG_TEXT_EMOTE", "ADDON_ACTION_BLOCKED",
    "ADDON_ACTION_FORBIDDEN",
}) do
    frame:RegisterEvent(event)
end

function ChalkBox_EmotaTest(token)
    if type(token)=="string" then
        for _,entry in ipairs(Catalog()) do
            if entry.token==token then return NativeEmote(token,"catalog-preview",true) end
        end
    end
    return false
end
function ChalkBox_EmotaSetJokeFrequency(value)
    if not settings or type(value)~="number" then return end
    settings.jokeFrequency=math.max(0,math.min(100,math.floor(value+0.5)))
    ChalkBox_EmotaOnSettingChanged("idleAuto")
end

function ChalkBox_EmotaTestJoke()
    NativeEmote("JOKE", "manual-settings-joke-test", true)
end

-- Called by both the native settings checkboxes and slash commands.
-- Re-arming from a toggle prevents an immediate joke when the user
-- has been standing still for a long time with reactions disabled.
function ChalkBox_EmotaOnSettingChanged(key)
    if key ~= "auto" and key ~= "idleAuto" and key ~= "jokeFrequency" then return end
    EndIdle()
    if settings and settings.auto and settings.idleAuto and type(IsPlayerMoving) == "function" then
        local moving = IsPlayerMoving()
        if not Hidden(moving) and not moving then StartIdle() end
    end
end

function ChalkBox_EmotaCommand(message)
    if not settings then return end
    local command, arg = strsplit(" ", string.lower(message or ""))
    if command == "" or command == "settings" or command == "config" then
        Note("Use /chalk emota auto on/off | idle on/off/test/reset/preview | variety on/off | status", true)
    elseif command == "auto" and (arg == "on" or arg == "off") then
        settings.auto = arg == "on"
        ChalkBox_EmotaOnSettingChanged("auto")
        Note("Automatic native-emote attempts: " .. (settings.auto and "ON (experimental)" or "OFF"), true)
    elseif command == "context" and (arg == "on" or arg == "off") then
        settings.contextual=arg=="on"
        Note("Race/class and resting-area idle flavor: "..arg,true)
    elseif command == "variety" and (arg == "on" or arg == "off") then
        settings.idleVariety=(arg=="on")
        Note("Optional idle emote variety: " .. (settings.idleVariety and "ON" or "OFF"),true)
    elseif command == "debug" and (arg == "on" or arg == "off") then
        settings.debug = arg == "on"
        Note("Local event diagnostics: " .. (settings.debug and "ON" or "OFF"), true)
    elseif command == "status" then
        Note("auto=" .. tostring(settings.auto) .. ", debug=" .. tostring(settings.debug) ..
            ", combat=" .. tostring(inCombat) ..
            ", idleAuto=" .. tostring(settings.idleAuto) ..
            ", jokeFrequency=" .. tostring(settings.jokeFrequency) ..
            ", idleVariety=" .. tostring(settings.idleVariety) ..
            ", contextual=" .. tostring(settings.contextual) ..
            ", sessionJokes=" .. sessionJokeCount ..
            ", idleEvents=" .. sessionIdleActions ..
            ", lastIdle=" .. tostring(lastIdleToken) ..
            ", pose=" .. tostring(activePose) ..
            ", nextIdle=" .. tostring(idleAfterSeconds) .. "s", true)
    elseif command == "test" then
        NativeEmote("WAVE", "manual-test", true)
    elseif command == "idle" then
        if arg == "on" or arg == "off" then
            settings.idleAuto = arg == "on"
            ChalkBox_EmotaOnSettingChanged("idleAuto")
            Note("Idle personality: " .. (settings.idleAuto and "ON" or "OFF") ..
                " (master /chalk emota auto must also be enabled)", true)
        elseif arg == "test" then
            NativeEmote("JOKE", "manual-idle-joke-test", true)
        elseif arg == "preview" then
            ChalkBox_EmotaPreviewIdle()
        elseif arg == "reset" then
            sessionJokeCount = 0
            sessionIdleActions = 0
            previousIdleToken, lastIdleToken = nil, nil
            EndIdle()
            if type(IsPlayerMoving) == "function" then
                local moving = IsPlayerMoving()
                if not Hidden(moving) and not moving then StartIdle() end
            end
            Note("Idle personality pacing reset for this session.", true)
        else
            local timer = idleSince and math.floor(GetTime() - idleSince) or 0
            Note(("Idle for %ds; next opportunity after %ss; actions: %d; jokes: %d; enabled: %s"):format(
                timer,tostring(idleAfterSeconds or "-"),sessionIdleActions,
                sessionJokeCount,tostring(settings.idleAuto)),true)
        end
    else
        Note("Commands: /chalk emota auto on/off | variety on/off | idle on/off/test/preview/reset | status",true)
    end
end
