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
local displayRank={}
local displayGroup={}
local displayGeneration=0
-- The compass delegates native watch writes to QuestSense.
local navFocusID
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
                    level=Public(info.level) and type(info.level)=="number"
                        and info.level or nil,
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
-- Forever's own quest-helper distance points toward the current quest
-- objective/turn-in. No third-party quest database and no guessed spawn.
local function NativeDistance(id)
    local fn=C_QuestLog and C_QuestLog.GetDistanceSqToQuest
    if type(fn)~="function" then return nil end
    local ok,distance,onContinent=pcall(fn,id)
    if ok and Public(distance) and type(distance)=="number"
        and distance>=0 and distance<1e14
        and Public(onContinent) and onContinent==true then
        return distance
    end
end
local function QuestComplete(id)
    local fn=C_QuestLog and C_QuestLog.IsComplete
    local value=Call(fn,id)
    return value==true
end
-- Compare only actual client-provided squared distances. The tracker
-- must not rank a 90-yard quest ahead of a 20-yard quest in the same bucket.
local function DistanceRank(value)
    return value
end
local function Relevant(quests,zoneID,zoneNames)
    local onMap,hasMapData={},false
    -- Check the actual player subzone and its zone ancestors, stopping
    -- before the continent. Forever can attach quest POIs to micro maps
    -- that never appear in the top-level zone query.
    local map=Call(C_Map and C_Map.GetBestMapForUnit,"player")
    if not ValidID(map) then map=zoneID end
    local seen={}
    for _=1,10 do
        if not ValidID(map) or seen[map] then break end
        seen[map]=true
        if C_QuestLog and type(C_QuestLog.GetQuestsOnMap)=="function" then
            local list=Call(C_QuestLog.GetQuestsOnMap,map)
            if type(list)=="table" then
                hasMapData=true
                for _,q in ipairs(list) do
                    if type(q)=="table" and ValidID(q.questID) then
                        onMap[q.questID]=true
                    end
                end
            end
        end
        if map==zoneID then break end
        local info=Call(C_Map and C_Map.GetMapInfo,map)
        if type(info)~="table" or info.mapType==2 or
            not ValidID(info.parentMapID) then break end
        map=info.parentMapID
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
        -- A local POI flag doesn't identify the zone, but actual client
        -- coordinates for THIS zone are valid local evidence.
        local waypoint=C_QuestLog and C_QuestLog.GetNextWaypointForMap
        if not nearby[quest.id] and ValidID(zoneID) and
            type(waypoint)=="function" then
            local ok,x,y=pcall(waypoint,quest.id,zoneID)
            if ok and Public(x) and Public(y) and
                type(x)=="number" and type(y)=="number" and
                x>=0 and x<=1 and y>=0 and y<=1 then
                nearby[quest.id]=true
                score=score+375
                hasMapData=true
            end
        end
        -- Optional short-distance catchment. Never cross continents:
        -- distance is the native quest helper's current objective/turn-in.
        local radius=settings and settings.nearbyRange or 0
        if not nearby[quest.id] and type(radius)=="number" and
            radius>0 then
            local d=NativeDistance(quest.id)
            if d and d<=radius*radius then
                nearby[quest.id]=true
                score=score+300
                hasMapData=true
            end
        end
        if quest.localPOI or quest.onMap then score=score+80 end
        if recentlyAccepted[quest.id] then score=score+40 end
        marked[quest.id]=score
    end
    return marked,nearby,hasMapData or headerMatch
end
-- Only the explicit Smart mode changes behavior in actual party dungeons.
-- Do not treat every quest tagged "Dungeon" as belonging to this instance.
local function CurrentDungeon()
    if type(GetInstanceInfo)~="function" then return end
    local ok,name,kind,_,_,_,_,_,instanceID=pcall(GetInstanceInfo)
    if not ok or kind~="party" or not Public(name)
        or type(name)~="string" or name=="" then return end
    if type(IsInInstance)=="function" then
        local worked,inside,instanceType=pcall(IsInInstance)
        if worked and (not inside or instanceType~="party") then return end
    end
    return {name=name,instanceID=ValidID(instanceID) and instanceID or nil,
        mapID=Call(C_Map and C_Map.GetBestMapForUnit,"player")}
end
local function DungeonName(value)
    if type(value)~="string" then return nil end
    value=value:lower():gsub("^%s+",""):gsub("%s+$","")
        :gsub("%s+"," ")
    -- The Deadmines and Deadmines are the same label, but a generic
    -- "Dungeon" quest tag alone does NOT identify the current instance.
    value=value:gsub("^the ","")
    return value
end
local function DungeonMatches(quests,dungeon)
    local found,seenMaps={},{}
    local mapID=dungeon.mapID
    -- Instance floor maps are often micro maps parented to the dungeon.
    -- Never climb to the outdoor zone, where its POIs can be unrelated.
    for _=1,10 do
        if not ValidID(mapID) or seenMaps[mapID] then break end
        seenMaps[mapID]=true
        local info=Call(C_Map and C_Map.GetMapInfo,mapID)
        if type(info)~="table" or
            (info.mapType~=4 and info.mapType~=5) then break end
        local data=Call(C_QuestLog and C_QuestLog.GetQuestsOnMap,mapID)
        if type(data)=="table" then
            for _,q in ipairs(data) do
                if type(q)=="table" and ValidID(q.questID) then
                    found[q.questID]=true
                end
            end
        end
        mapID=info.parentMapID
    end
    local title=DungeonName(dungeon.name)
    for _,quest in ipairs(quests) do
        if (DungeonName(quest.header)==title or
            DungeonName(quest.title)==title) and title then
            found[quest.id]=true
        end
    end
    -- Retain only accepted-quest IDs. World Map POIs can include quests
    -- the player does not yet have.
    local accepted={}
    for _,quest in ipairs(quests) do
        if found[quest.id] then accepted[quest.id]=true end
    end
    return accepted
end
local function CanEdit(dungeonSmart)
    if type(InCombatLockdown)=="function" and InCombatLockdown() then
        return false,"in combat"
    end
    if WorldMapFrame and type(WorldMapFrame.IsShown)=="function"
        and WorldMapFrame:IsShown() then return false,"world map open" end
    if QuestLogFrame and type(QuestLogFrame.IsShown)=="function"
        and QuestLogFrame:IsShown() then return false,"quest log open" end
    if type(IsInInstance)=="function" then
        local inside,kind=IsInInstance()
        if inside and (kind=="party" or kind=="raid" or kind=="scenario")
            and not (kind=="party" and dungeonSmart) then
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
        and next(settings.suspendedManual)==nil and not navFocusID then return end
    local mode=settings.mode or "smart"
    local dungeon=settings.enabled and mode=="smart" and CurrentDungeon() or nil
    local allowed,why=CanEdit(dungeon~=nil)
    if not allowed then pending=true;lastReason=why;return end
    local quests,err=ReadLog()
    if not quests then pending=true;lastReason=err;return end
    local watched=Watches()
    if not watched then pending=true;lastReason="watch list unavailable";return end
    local zoneID,name,names=CurrentZone()
    local zoneKey=tostring(zoneID or "-")..":"..tostring(name or "-")
        ..":"..(dungeon and ("dungeon:"..dungeon.name..":"..
            tostring(dungeon.instanceID or "-")) or "outdoor")
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
    local focusID=ValidID(navFocusID) and accepted[navFocusID] and
        navFocusID or nil
    local navigationBlocked=false
    -- Keep the chosen quest inside Blizzard's existing objective tracker.
    -- Treat it as a manual watch: never auto-trim or suspend it.
    if focusID then
        settings.muted[focusID]=nil
        settings.managed[focusID]=nil
        settings.suspendedManual[focusID]=nil
        if not watched[focusID] then
            if Count(watched)<MaxWatches() then
                local ok=pcall(C_QuestLog.AddQuestWatch,focusID)
                if ok then
                    local after=Watches()
                    if after and after[focusID] then
                        watched=after
                        seenManual[focusID]=true
                    else navigationBlocked=true end
                else navigationBlocked=true end
            else
                navigationBlocked=true
                lastReason="watch list full; selected quest not added"
            end
        end
    end
    local scores,nearby,zoneReady=Relevant(quests,zoneID,names)
    local dungeonQuests=dungeon and DungeonMatches(quests,dungeon) or nil
    local dungeonCount=Count(dungeonQuests)
    -- A Forever instance without quest POIs or named headers supplies no
    -- dependable association. Preserve the tracker instead of hiding every
    -- manual quest on an unverified guess.
    if dungeon and dungeonCount==0 then
        pending=navigationBlocked
        lastReason="no verified quests for "..dungeon.name..
            "; preserving current watches"
        lastStats={accepted=#quests,candidates=0,watched=before,
            auto=Count(settings.managed),added=0,removed=0,
            hidden=Count(settings.suspendedManual),mode=mode,
            dungeon=dungeon.name,dungeonMatches=0}
        return
    end
    local focusOnly=mode=="zone" or dungeon~=nil
    local localQuests=dungeonQuests or nearby
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
    local sortMode=(mode=="all") and "log" or
        (settings.smartSort or "nearest")
    for _,quest in ipairs(quests) do
        local score=mode=="all" and 0 or (scores[quest.id] or 0)
        if not focusOnly or localQuests[quest.id] then
            local d=NativeDistance(quest.id)
            local nearbyQuest=localQuests[quest.id]==true
            prioritized[#prioritized+1]={
                id=quest.id,title=quest.title,score=score,
                logIndex=quest.index,header=quest.header or "Other",
                level=quest.level,complete=QuestComplete(quest.id),
                distance=d,bucket=DistanceRank(d),
                inArea=nearbyQuest,
                recent=recentlyAccepted[quest.id]==true,
            }
        end
    end
    -- Smart: local evidence before remote, then closest verified objective.
    -- Nearby has already removed nonlocal quests. All remains log-order
    -- compatible unless the player explicitly chooses another sort.
    local function Compare(a,b)
        if mode~="all" and settings.smartCompleteFirst~=false and
            a.complete~=b.complete then
            return a.complete
        end
        if mode=="smart" and settings.smartNearbyFirst~=false and
            a.inArea~=b.inArea then return a.inArea end
        if sortMode=="zone" and a.header~=b.header then
            if a.inArea~=b.inArea then return a.inArea end
            return a.header<b.header
        end
        if sortMode=="title" and type(a.title)=="string" and
            type(b.title)=="string" and a.title~=b.title then
            return a.title:lower()<b.title:lower()
        end
        if sortMode=="level" and type(a.level)=="number" and
            type(b.level)=="number" and a.level~=b.level then
            return a.level<b.level
        end
        if sortMode=="nearest" then
            if a.bucket~=b.bucket then
                if not a.bucket then return false end
                if not b.bucket then return true end
                return a.bucket<b.bucket
            end
        end
        if sortMode~="log" and sortMode~="level" and
            a.score~=b.score then return a.score>b.score end
        return a.logIndex<b.logIndex
    end
    table.sort(prioritized,Compare)
    displayRank,displayGroup={},{}
    for position,q in ipairs(prioritized) do
        displayRank[q.id]=position
        displayGroup[q.id]=q.header
    end
    displayGeneration=displayGeneration+1

    -- Nearby is a strict current-zone filter, including previously MANUALLY
    -- watched non-local quests. Suspend those selections rather than losing
    -- them; restore them when relevant again or when Nearby is turned off.
    local toSuspend,restoreManual={},{}
    for id in pairs(settings.suspendedManual) do
        if not focusOnly or not settings.enabled or localQuests[id] then
            restoreManual[id]=true
        end
    end
    local manualRetained=0
    for id in pairs(watched) do
        if not settings.managed[id] then
            if settings.enabled and focusOnly and accepted[id]
                and not localQuests[id] and id~=focusID then
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
    pending=failed>0 or navigationBlocked
    recentlyAccepted={}
    lastReason=navigationBlocked and
        "selected quest could not be added; native tracker full or API rejected" or
        (failed>0 and ("watch API rejected "..failed..
        " change(s); retry when safe") or "ready")
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
        manual=manualNow,initialWatches=before,
        dungeon=dungeon and dungeon.name or nil,
        dungeonMatches=dungeon and dungeonCount or nil,
        sort=sortMode,nearest=prioritized[1] and prioritized[1].id or nil}
end
QueueUpdate=function()
    if not settings or queued or busy then return end
    if not API() then
        lastReason="Forever C_QuestLog APIs not available"
        return
    end
    if not settings.enabled and not settings.cleanup
        and next(settings.suspendedManual)==nil and not navFocusID then return end
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
-- This is only invoked by an enabled navigator when a player chooses
-- a different accepted quest. It never changes Blizzard quest selection.
function ChalkBox_QuestNavFocus(id)
    id=ValidID(id) and id or nil
    if id==navFocusID then return end
    navFocusID=id
    if id then QueueUpdate() end
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
        api=API(),pending=pending,
        dungeon=lastStats.dungeon,dungeonMatches=lastStats.dungeonMatches,
        navigationWatch=navFocusID,
        sort=settings and settings.smartSort or "nearest",
        nearbyFirst=settings and settings.smartNearbyFirst~=false,
        completeFirst=settings and settings.smartCompleteFirst~=false,
        nativeOrder=false,
        nearbyRange=settings and settings.nearbyRange or 0,
        nearest=lastStats.nearest}
end
-- Read-only view of Smart's ranked candidates. The built-in tracker can
-- sort its display without altering Blizzard quest-watch ownership/order.
function ChalkBox_QuestDisplayOrder()
    return displayRank,displayGroup,displayGeneration
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
        Note("Accepted "..st.accepted.." | candidates "..st.candidates..
            " | watched "..st.tracked.." | hidden "..st.hidden..
            " | last change +"..st.added.."/-"..st.removed)
        Note("Smart completed-first "..(st.completeFirst and "ON" or
            "OFF").." | sort "..st.sort.." | nearest #"..tostring(st.nearest or "-"))
        if st.dungeon then
            Note("Dungeon "..st.dungeon.." | confirmed quests "..
                tostring(st.dungeonMatches or 0))
        end
        Note("Forever APIs "..(st.api and "ready" or "MISSING")..
            " | "..st.reason..(st.pending and " (retry pending)" or ""))
    elseif cmd=="smart" or cmd=="zone" or cmd=="all" then
        settings.mode=cmd
        QueueUpdate()
        Note("QuestSense: "..(cmd=="zone" and
            "Nearby only (auto-updates; other watches saved)." or
            (cmd=="all" and "All accepted." or "Smart.")))
    elseif cmd:match("^sort %a+$") then
        local sort=cmd:match("^sort (%a+)$")
        if sort=="nearest" or sort=="zone" or sort=="level" or
            sort=="title" or sort=="log" then
            settings.smartSort=sort;QueueUpdate()
            Note("Smart selection order: "..sort..".")
        else Note("Choose sort nearest, zone, level, title or log.") end
    elseif cmd:match("^range %d+$") then
        local range=tonumber(cmd:match("%d+"))
        if range==0 or range==500 or range==1000 or range==2000 then
            settings.nearbyRange=range
            QueueUpdate()
            Note("Nearby distance allowance: "..(range==0 and
                "current zone only" or (range.." yards"))..".")
        else
            Note("Choose range 0, 500, 1000 or 2000.")
        end
    elseif cmd=="nativeorder on" or cmd=="nativeorder off" then
        -- Never patch a live Blizzard ObjectiveTracker method: doing so can
        -- taint secure MapCanvas pin pass-through configuration.
        settings.nativeOrder=false
        Note("Native tracker reordering is unavailable: protected UI safety.")
    elseif cmd=="nearbyfirst on" or cmd=="nearbyfirst off" then
        settings.smartNearbyFirst=cmd=="nearbyfirst on"
        QueueUpdate()
        Note("Smart current-zone priority "..(settings.smartNearbyFirst and
            "on." or "off."))
    elseif cmd=="completefirst on" or cmd=="completefirst off" then
        settings.smartCompleteFirst=cmd=="completefirst on"
        QueueUpdate()
        Note("Smart completed-quest priority "..(settings.smartCompleteFirst
            and "on." or "off."))
    elseif cmd:match("^limit %d+$") then
        local n=tonumber(cmd:match("%d+"))
        if n==5 or n==10 or n==15 or n==20 then
            settings.limit=n;QueueUpdate()
            Note("Maximum automatically managed watches: "..n)
        else
            Note("Choose limit 5, 10, 15 or 20.")
        end
    else
        Note("/chalk quests on|off|smart|zone|all|sort nearest/zone/level/title/log|nearbyfirst on/off|range 0/500/1000/2000|completefirst on/off|limit 5/10/15/20|refresh|status")
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
        if settings.smartSort~="nearest" and settings.smartSort~="zone"
            and settings.smartSort~="level" and settings.smartSort~="title" and
            settings.smartSort~="log" then
            settings.smartSort="nearest"
        end
        if settings.smartNearbyFirst==nil then
            settings.smartNearbyFirst=true
        end
        -- A quest that is ready to hand in must not silently disappear from
        -- Smart just because another objective is closer. Preserve an
        -- explicit saved opt-out instead of overriding the user's choice.
        if settings.smartCompleteFirst==nil then
            settings.smartCompleteFirst=true
        end
        settings.nativeOrder=false -- migrate unsafe beta opt-in to safe default
        if settings.nearbyRange~=0 and settings.nearbyRange~=500 and
            settings.nearbyRange~=1000 and settings.nearbyRange~=2000 then
            settings.nearbyRange=0
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
                local watchDungeon=settings and settings.enabled and
                    settings.mode=="smart" and CurrentDungeon()~=nil
                if pending or (settings and settings.enabled
                    and (settings.mode=="zone" or watchDungeon or
                        (settings.mode=="smart" and
                         settings.smartSort=="nearest"))
                    and ticks%4==0) then
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
