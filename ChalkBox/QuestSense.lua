-- ChalkBox QuestSense: zone-aware watches using the Forever C_QuestLog API.
-- No map coordinates or quest-database guesses; never replaces Blizzard's
-- tracker. Nearby temporarily suspends remote manual watches and restores them
-- when they become relevant or when the player switches tracking modes.
local addonName=...
local settings
local queued,busy,pending=false,false,false
local lastZone,lastReason=nil,"not scanned"
local lastStats={accepted=0,candidates=0,watched=0,auto=0,added=0,removed=0,mode="smart"}
local recentlyAccepted={}
local seenManual,seenManualZone={},nil
local hooksInstalled=false
local function Public(value)
    return (type(issecretvalue)~="function" or not issecretvalue(value)) and value~=nil
end
local function ValidID(value)
    return Public(value) and type(value)=="number" and value>0
end
local function Note(message)
    if DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage)=="function" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff55ccaaChalkBox Quests|r "..message)
    end
end
local function Call(fn,...)
    if type(fn)~="function" then return nil end
    local ok,result=pcall(fn,...)
    if ok and Public(result) then return result end
end
local function API()
    return type(C_QuestLog)=="table"
        and type(C_QuestLog.GetNumQuestLogEntries)=="function"
        and type(C_QuestLog.GetInfo)=="function"
        and type(C_QuestLog.AddQuestWatch)=="function"
        and type(C_QuestLog.RemoveQuestWatch)=="function"
        and type(C_QuestLog.GetNumQuestWatches)=="function"
        and type(C_QuestLog.GetQuestIDForQuestWatchIndex)=="function"
end
local function CurrentZone()
    local id=Call(C_Map and C_Map.GetBestMapForUnit,"player")
    local best,zoneName,depth=id,nil,0
    if ValidID(id) and C_Map and type(C_Map.GetMapInfo)=="function" then
        local visited={}
        while ValidID(id) and depth<10 and not visited[id] do
            visited[id]=true
            depth=depth+1
            local info=Call(C_Map.GetMapInfo,id)
            if not info or type(info)~="table" then break end
            if Public(info.name) and type(info.name)=="string" then
                zoneName=info.name
                best=id
            end
            if info.mapType==3 or info.mapType==4 then break end
            id=info.parentMapID
        end
    end
    local zoneText=Call(GetZoneText)
    if type(zoneText)~="string" or zoneText=="" then zoneText=Call(GetRealZoneText) end
    if not zoneName then zoneName=zoneText end
    local normalized={}
    if type(zoneName)=="string" then normalized[string.lower(zoneName)]=true end
    if type(zoneText)=="string" then normalized[string.lower(zoneText)]=true end
    return best,zoneName,normalized
end
local function ReadLog()
    local num=Call(C_QuestLog.GetNumQuestLogEntries)
    if type(num)~="number" or num<0 then return nil,"quest log isn't ready" end
    local quests={}
    local header=nil
    for i=1,math.min(num,600) do
        local info=Call(C_QuestLog.GetInfo,i)
        if type(info)=="table" then
            if info.isHeader then
                header=Public(info.title) and type(info.title)=="string"
                    and info.title or nil
            elseif ValidID(info.questID) and info.isHidden~=true
                and info.isInternalOnly~=true then
                quests[#quests+1]={
                    id=info.questID,title=Public(info.title) and info.title or
                        ("Quest #"..info.questID),
                    header=header,localPOI=info.hasLocalPOI==true,
                    onMap=info.isOnMap==true,index=i,
                }
            end
        end
    end
    return quests
end
local function Watches()
    local num=Call(C_QuestLog.GetNumQuestWatches)
    if type(num)~="number" or num<0 then return nil end
    local watched={}
    for i=1,math.min(num,500) do
        local id=Call(C_QuestLog.GetQuestIDForQuestWatchIndex,i)
        if ValidID(id) then watched[id]=true end
    end
    return watched
end
local function Count(set)
    local n=0
    for _ in pairs(set or {}) do n=n+1 end
    return n
end
local function MaxWatches()
    local n=Constants and Constants.QuestWatchConsts
        and Constants.QuestWatchConsts.MAX_QUEST_WATCHES
    return type(n)=="number" and n>0 and n or 25
end
local function Relevant(quests,zoneID,zoneNames)
    local onMap,hasMapData={},false
    if ValidID(zoneID) and C_QuestLog and
        type(C_QuestLog.GetQuestsOnMap)=="function" then
        local list=Call(C_QuestLog.GetQuestsOnMap,zoneID)
        if type(list)=="table" then
            hasMapData=true
            for _,q in ipairs(list) do
                if type(q)=="table" and ValidID(q.questID) then
                    onMap[q.questID]=true
                end
            end
        end
    end
    local marked,nearby={},{}
    local headerMatch=false
    for _,quest in ipairs(quests) do
        local score=0
        local inZone=type(quest.header)=="string"
            and zoneNames[string.lower(quest.header)]==true
        if onMap[quest.id] then score=score+400 end
        if inZone then score=score+350;headerMatch=true end
        if inZone or onMap[quest.id] then nearby[quest.id]=true end
        -- A local POI flag does not identify the current zone, and a newly
        -- accepted quest may be far away. Neither bypasses Nearby-only.
        if quest.localPOI or quest.onMap then score=score+80 end
        if recentlyAccepted[quest.id] then score=score+600 end
        marked[quest.id]=score
    end
    -- No zone map and no matching quest header means the client hasn't
    -- supplied enough evidence to safely change existing watches.
    return marked,nearby,hasMapData or headerMatch
end
local function CanEdit()
    if type(InCombatLockdown)=="function" and InCombatLockdown() then
        return false,"in combat"
    end
    if WorldMapFrame and type(WorldMapFrame.IsShown)=="function"
        and WorldMapFrame:IsShown() then return false,"world map open" end
    if QuestLogFrame and type(QuestLogFrame.IsShown)=="function"
        and QuestLogFrame:IsShown() then return false,"quest log open" end
    if type(IsInInstance)=="function" then
        local inside,kind=IsInInstance()
        if inside and (kind=="party" or kind=="raid" or kind=="scenario") then
            return false,"instance: preserving current quest watches"
        end
    end
    return true
end
local QueueUpdate
local function Reconcile()
    queued=false
    if not settings or not API() then
        lastReason="Forever C_QuestLog watch APIs unavailable"
        return
    end
    if not settings.enabled and not settings.cleanup
        and next(settings.suspendedManual)==nil then return end
    local allowed,why=CanEdit()
    if not allowed then pending=true;lastReason=why;return end
    local quests,err=ReadLog()
    if not quests then pending=true;lastReason=err;return end
    local watched=Watches()
    if not watched then pending=true;lastReason="watch list unavailable";return end
    local zoneID,name,names=CurrentZone()
    local zoneKey=tostring(zoneID or "-")..":"..tostring(name or "-")
    local zoneChanged=zoneKey~=lastZone
    if zoneChanged then
        settings.muted={}
        lastZone=zoneKey
    end
    if seenManualZone~=zoneKey then
        seenManual={}
        seenManualZone=zoneKey
    end
    local before=Count(watched)
    if #quests==0 and before>0 then
        pending=true
        lastReason="quest log still loading; preserving watched quests"
        return
    end
    local accepted={}
    for _,quest in ipairs(quests) do accepted[quest.id]=true end
    local scores,nearby,zoneReady=Relevant(quests,zoneID,names)
    local mode=settings.mode or "smart"
    if settings.enabled and mode=="zone" and not zoneReady then
        pending=true
        lastReason="nearby zone data unavailable; keeping current watches"
        return
    end
    -- Respect a player removing a manual watch, including one restored
    -- automatically on returning to its zone. Never immediately re-add it.
    for id in pairs(seenManual) do
        if not watched[id] and accepted[id]
            and not settings.suspendedManual[id] then
            settings.muted[id]=true
        end
    end
    for id in pairs(watched) do
        if not settings.managed[id] then
            settings.muted[id]=nil
        end
    end
    for id in pairs(settings.managed) do
        if not watched[id] then
            -- Player manually removed an auto-watch. Don't fight their choice.
            settings.managed[id]=nil
            settings.muted[id]=true
        end
    end
    for id in pairs(settings.suspendedManual) do
        if not ValidID(id) or not accepted[id] or watched[id] then
            -- A manually restored or completed quest is no longer suspended.
            settings.suspendedManual[id]=nil
        end
    end
    local prioritized={}
    for _,quest in ipairs(quests) do
        local score=mode=="all" and 0 or (scores[quest.id] or 0)
        if mode~="zone" or nearby[quest.id] then
            prioritized[#prioritized+1]={id=quest.id,title=quest.title,score=score,
                logIndex=quest.index}
        end
    end
    table.sort(prioritized,function(a,b)
        if a.score~=b.score then return a.score>b.score end
        return a.logIndex<b.logIndex
    end)

    -- Nearby is a strict current-zone filter, including previously MANUALLY
    -- watched non-local quests. Suspend those selections rather than losing
    -- them; restore them when relevant again or when Nearby is turned off.
    local toSuspend,restoreManual={},{}
    for id in pairs(settings.suspendedManual) do
        if mode~="zone" or not settings.enabled or nearby[id] then
            restoreManual[id]=true
        end
    end
    local manualRetained=0
    for id in pairs(watched) do
        if not settings.managed[id] then
            if settings.enabled and mode=="zone" and accepted[id]
                and not nearby[id] then
                toSuspend[id]=true
            else
                manualRetained=manualRetained+1
            end
        end
    end
    local reservedManual=manualRetained+Count(restoreManual)
    local capacity=math.max(0,math.min(settings.limit or 10,
        MaxWatches()-reservedManual))
    local desired={}
    local autoSlots=0
    if settings.enabled then
        for _,quest in ipairs(prioritized) do
            local id=quest.id
            if not settings.muted[id] then
                if watched[id] and not settings.managed[id] then
                    -- Existing manual selection takes precedence.
                elseif restoreManual[id] then
                    -- Temporarily suspended manual selection takes precedence.
                elseif autoSlots<capacity then
                    desired[id]=true
                    autoSlots=autoSlots+1
                end
            end
        end
    end

    -- Remove outdated auto-watches first, then suspend non-local manual
    -- selections, restore relevant ones, and fill remaining auto slots.
    -- Never clear Blizzard's entire watch list or super-tracked quest.
    busy=true
    local removed,added,restored,failed=0,0,0,0
    for id in pairs(settings.managed) do
        if not desired[id] or not accepted[id] or not settings.enabled then
            if watched[id] then
                local ok=pcall(C_QuestLog.RemoveQuestWatch,id)
                if ok then
                    local after=Watches()
                    if after and not after[id] then
                        removed=removed+1
                        watched=after
                        settings.managed[id]=nil
                    else
                        failed=failed+1
                    end
                else failed=failed+1 end
            else
                settings.managed[id]=nil
            end
        end
    end
    for id in pairs(toSuspend) do
        if watched[id] then
            local ok=pcall(C_QuestLog.RemoveQuestWatch,id)
            if ok then
                local after=Watches()
                if after and not after[id] then
                    settings.suspendedManual[id]=true
                    removed=removed+1
                    watched=after
                else failed=failed+1 end
            else failed=failed+1 end
        end
    end
    for id in pairs(restoreManual) do
        if not watched[id] then
            if Count(watched)>=MaxWatches() then
                failed=failed+1
            else
                local ok=pcall(C_QuestLog.AddQuestWatch,id)
                if ok then
                    local after=Watches()
                    if after and after[id] then
                        settings.suspendedManual[id]=nil
                        watched=after
                        restored=restored+1
                    else failed=failed+1 end
                else failed=failed+1 end
            end
        end
    end
    if settings.enabled then
        for _,quest in ipairs(prioritized) do
            local id=quest.id
            if desired[id] and not watched[id] then
                if Count(watched)>=MaxWatches() then
                    failed=failed+1
                else
                    local ok=pcall(C_QuestLog.AddQuestWatch,id)
                    if ok then
                        local after=Watches()
                        if after and after[id] then
                            watched=after
                            settings.managed[id]=true
                            added=added+1
                        else failed=failed+1 end
                    else failed=failed+1 end
                end
            end
        end
    end
    busy=false
    settings.cleanup=nil
    pending=failed>0
    recentlyAccepted={}
    lastReason=failed>0 and ("watch API rejected "..failed..
        " change(s); retry when safe") or "ready"
    local manualNow=0
    seenManual={}
    for id in pairs(watched) do
        if not settings.managed[id] then
            manualNow=manualNow+1
            seenManual[id]=true
        end
    end
    lastStats={accepted=#quests,candidates=#prioritized,
        watched=Count(watched),auto=Count(settings.managed),added=added,
        removed=removed,restored=restored,hidden=Count(settings.suspendedManual),
        zone=name or "unknown",mode=mode,max=MaxWatches(),
        manual=manualNow,initialWatches=before}
end
QueueUpdate=function()
    if not settings or queued or busy then return end
    if not API() then
        lastReason="Forever C_QuestLog APIs not available"
        return
    end
    if not settings.enabled and not settings.cleanup
        and next(settings.suspendedManual)==nil then return end
    queued=true
    if C_Timer and type(C_Timer.After)=="function" then
        C_Timer.After(0.4,Reconcile)
    else
        Reconcile()
    end
end
local function SetupHooks()
    if hooksInstalled then return end
    hooksInstalled=true
    for _,frame in ipairs({WorldMapFrame or false,QuestLogFrame or false}) do
        if frame and type(frame.HookScript)=="function" then
            pcall(frame.HookScript,frame,"OnHide",function()
                if pending then QueueUpdate() end
            end)
        end
    end
end
function ChalkBox_QuestStatus()
    local zoneID,name=CurrentZone()
    return {enabled=settings and settings.enabled~=false,
        mode=settings and settings.mode or "smart",
        limit=settings and settings.limit or 10,
        zone=name or "unknown",mapID=zoneID,reason=lastReason,
        accepted=lastStats.accepted,candidates=lastStats.candidates,
        tracked=lastStats.watched,auto=lastStats.auto,
        added=lastStats.added,removed=lastStats.removed,
        hidden=Count(settings and settings.suspendedManual),
        restored=lastStats.restored or 0,
        api=API(),pending=pending}
end
function ChalkBox_QuestCommand(text)
    if not settings then return end
    local cmd=string.lower((text or ""):match("^%s*(.-)%s*$") or "")
    if cmd=="on" then
        settings.enabled=true
        QueueUpdate()
        Note("QuestSense enabled. Smart mode tracks accepted quests without requiring map pins.")
    elseif cmd=="off" then
        settings.enabled=false
        settings.cleanup=true
        pending=true
        QueueUpdate()
        Note("QuestSense disabled. Removing only ChalkBox-managed watches when safe.")
    elseif cmd=="refresh" or cmd=="scan" then
        QueueUpdate()
        Note("Quest watch scan queued. Type /chalk quests status after closing your map.")
    elseif cmd=="status" then
        local st=ChalkBox_QuestStatus()
        Note("QuestSense "..(st.enabled and "ON" or "OFF")..
            " | "..st.mode.." mode | zone "..st.zone.." (#"..tostring(st.mapID or "-")..")")
        Note("Accepted "..st.accepted.." | nearby "..st.candidates..
            " | watched "..st.tracked.." | hidden "..st.hidden..
            " | last change +"..st.added.."/-"..st.removed)
        Note("Forever APIs "..(st.api and "ready" or "MISSING")..
            " | "..st.reason..(st.pending and " (retry pending)" or ""))
    elseif cmd=="smart" or cmd=="zone" or cmd=="all" then
        settings.mode=cmd
        QueueUpdate()
        Note("QuestSense: "..(cmd=="zone" and
            "Nearby only (auto-updates; other watches saved)." or
            (cmd=="all" and "All accepted." or "Smart.")))
    elseif cmd:match("^limit %d+$") then
        local n=tonumber(cmd:match("%d+"))
        if n==5 or n==10 or n==15 or n==20 then
            settings.limit=n;QueueUpdate()
            Note("Maximum automatically managed watches: "..n)
        else
            Note("Choose limit 5, 10, 15 or 20.")
        end
    else
        Note("/chalk quests on|off|refresh|status|smart|zone|all|limit 5/10/15/20")
    end
end
local events=CreateFrame("Frame")
for _,event in ipairs({
    "ADDON_LOADED","PLAYER_ENTERING_WORLD","PLAYER_LOGIN",
    "ZONE_CHANGED","ZONE_CHANGED_INDOORS","ZONE_CHANGED_NEW_AREA",
    "QUEST_LOG_UPDATE","QUEST_ACCEPTED","QUEST_REMOVED","QUEST_TURNED_IN",
    "QUEST_WATCH_LIST_CHANGED","PLAYER_REGEN_ENABLED",
}) do
    pcall(events.RegisterEvent,events,event)
end
events:SetScript("OnEvent",function(_,event,arg1,arg2)
    if event=="ADDON_LOADED" then
        if arg1~=addonName then return end
        if type(ChalkBoxZoneDB)~="table" then ChalkBoxZoneDB={} end
        settings=ChalkBoxZoneDB
        settings.enabled=settings.enabled~=false
        if type(settings.managed)~="table" then settings.managed={} end
        if type(settings.muted)~="table" then settings.muted={} end
        if type(settings.suspendedManual)~="table" then
            settings.suspendedManual={}
        end
        if settings.mode~="smart" and settings.mode~="zone" and settings.mode~="all" then
            settings.mode="smart"
        end
        if type(settings.limit)~="number" or settings.limit<5 or settings.limit>20 then
            settings.limit=10
        end
        -- Leave old per-character manual watch history alone.
    elseif event=="PLAYER_LOGIN" then
        SetupHooks()
        QueueUpdate()
        if C_Timer and type(C_Timer.NewTicker)=="function" then
            local ticks=0
            C_Timer.NewTicker(3,function()
                ticks=ticks+1
                -- Retry deferred edits promptly. Nearby also rechecks every
                -- 12 seconds so missed map/watch events cannot leave stale
                -- quests on screen until the player presses Refresh.
                if pending or (settings and settings.enabled
                    and settings.mode=="zone" and ticks%4==0) then
                    QueueUpdate()
                end
            end)
        end
    elseif event=="QUEST_ACCEPTED" then
        local id=ValidID(arg2) and arg2 or nil
        if not id and ValidID(arg1) then
            local info=Call(C_QuestLog and C_QuestLog.GetInfo,arg1)
            id=type(info)=="table" and info.questID or arg1
        end
        if ValidID(id) then recentlyAccepted[id]=true end
        QueueUpdate()
    elseif event=="QUEST_WATCH_LIST_CHANGED" then
        if not busy then QueueUpdate() end
    elseif event=="PLAYER_REGEN_ENABLED" then
        if pending then QueueUpdate() end
    else
        QueueUpdate()
    end
end)
