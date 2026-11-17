-- ChalkBox report controls for Blizzard's native damage-meter gear menu.
-- Read Blizzard-owned sessions only; do not guess secret combat data.
local addonName=...
local installed=false
local lastSentAt=-1000000000
local lastAutoAt=-1000000000
local lastAutoMessage=nil
local combatStartedAt=nil
local pendingDelay=nil

local function Safe(value)
    return value~=nil and
        (type(issecretvalue)~="function" or not issecretvalue(value))
end
local function Number(value)
    return Safe(value) and type(value)=="number" and value==value
        and value~=math.huge and value~=-math.huge
end
local function Clock()
    local now=type(GetTime)=="function" and GetTime() or nil
    return Number(now) and now or nil
end
local function Note(message)
    if DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage)=="function" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffefc574ChalkBox Meter|r "..message)
    end
end
local function OneOf(value,list)
    for _,option in ipairs(list) do if value==option then return true end end
    return false
end
local function Settings()
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    if type(ChalkBoxDB.meter)~="table" then ChalkBoxDB.meter={} end
    local db=ChalkBoxDB.meter
    if db.nativePrint==nil then db.nativePrint=true end
    if not OneOf(db.nativeReportRows,{3,5,10}) then db.nativeReportRows=3 end
    if type(db.nativeAutoPrint)~="boolean" then db.nativeAutoPrint=false end
    if not OneOf(db.nativeAutoChannel,{"PARTY","SAY"}) then
        db.nativeAutoChannel="PARTY"
    end
    if not OneOf(db.nativeAutoMinFight,{0,10,20,30}) then
        db.nativeAutoMinFight=10
    end
    if not OneOf(db.nativeAutoCooldown,{30,60,120}) then
        db.nativeAutoCooldown=60
    end
    if not OneOf(db.nativeAutoMetric,{"dps","damage","healing"}) then
        db.nativeAutoMetric="dps"
    end
    return db
end
local function Enabled()
    return Settings().nativePrint~=false
end
local function TypeInfo(kind)
    if not Number(kind) then return end
    local enums=Enum and Enum.DamageMeterType or {}
    for _,entry in ipairs({
        {"Dps","DPS",true}, {"DamageDone","DMG",false},
        {"Hps","HPS",true}, {"HealingDone","HEAL",false},
        {"DamageTaken","TAKEN",false},
        {"AvoidableDamageTaken","AVOID",false},
        {"EnemyDamageTaken","ENEMY",false},
        {"Absorbs","ABSORB",false},
        {"Interrupts","INT",false}, {"Dispels","DISPEL",false},
        {"Deaths","DEATHS",false},
    }) do
        if enums[entry[1]]==kind then return entry[2],entry[3] end
    end
    return "STAT",false
end
local function AutoType()
    local enums=Enum and Enum.DamageMeterType or {}
    local metric=Settings().nativeAutoMetric
    local key=metric=="damage" and "DamageDone"
        or (metric=="healing" and "HealingDone" or "Dps")
    local kind=enums[key]
    return Number(kind) and kind or nil
end
local function SessionLabel(frame)
    if type(frame.GetSessionType)=="function" then
        local ok,kind=pcall(frame.GetSessionType,frame)
        if ok and Number(kind) then
            local enums=Enum and Enum.DamageMeterSessionType or {}
            if kind==enums.Current then return "Current",true end
            if kind==enums.Overall then return "Overall",false end
            if kind==enums.Expired then return "Last",false end
        end
    end
    if type(frame.GetSessionID)=="function" then
        local ok,id=pcall(frame.GetSessionID,frame)
        if ok and Number(id) and id>=0 then
            return "Fight "..tostring(math.floor(id)),false
        end
    end
    return "Fight",false
end
local function CombatSources(session)
    if not Safe(session) or type(session)~="table" then return end
    local sources=session.combatSources
    if not Safe(sources) or type(sources)~="table" then return end
    return sources
end
local function ExpiredSources(kind)
    local api=C_DamageMeter
    local types=Enum and Enum.DamageMeterSessionType or {}
    if not api or type(api.GetCombatSessionFromType)~="function"
        or not Number(types.Expired) then return end
    local ok,session=pcall(api.GetCombatSessionFromType,types.Expired,kind)
    if not ok then return end
    return CombatSources(session)
end
local function SelectedSources(frame)
    if not frame or type(frame.GetCombatSession)~="function" then return end
    local ok,session=pcall(frame.GetCombatSession,frame)
    if not ok then return end
    return CombatSources(session)
end
local function BuildMessages(sources,label,title,perSecond,limit)
    if not sources or #sources==0 then return nil,"No completed fight values." end
    -- WoW chat does not accept newline characters or bare pipe separators.
    -- The heading and each ranked player are separate ordinary chat sends.
    local lines={"CB "..label.." ("..title.."):"}
    for i=1,math.min(#sources,limit) do
        local source=sources[i]
        if not Safe(source) or type(source)~="table" then
            return nil,"Fight data is protected or incomplete."
        end
        local name=source.name
        local amount=perSecond and source.amountPerSecond or source.totalAmount
        if not Safe(name) or type(name)~="string" or not Number(amount)
            or amount<0 then
            return nil,"Fight data is protected or incomplete."
        end
        name=name:gsub("[%c|]",""):sub(1,64)
        if name=="" then name="Unknown" end
        local line=string.format("%d %s %.0f",i,name,amount)
        if #line>255 then return nil,"Report line exceeds chat limit." end
        lines[#lines+1]=line
    end
    return lines
end
local function MessagingRestricted()
    local api=C_ChatInfo
    if not api then return false end
    for _,name in ipairs({
        "InChatMessagingLockdown",
        "AreOutgoingAddonChatMessagesRestricted",
    }) do
        local check=api[name]
        if type(check)=="function" then
            local ok,blocked=pcall(check)
            -- Fail closed if the client cannot answer its own safety query.
            if not ok or blocked==true then return true end
        end
    end
    return false
end
local function SendReport(frame,channel,auto)
    local function Reject(why)
        if not auto then Note(why) end
        return false
    end
    if not Enabled() then return Reject("Native reports disabled.") end
    if type(InCombatLockdown)=="function" and InCombatLockdown() then
        return Reject("Finish combat before reporting.")
    end
    if channel~="PARTY" and channel~="SAY" then
        return Reject("Choose PARTY or SAY.")
    end
    -- Automatic SAY outside an instance cannot satisfy Forever's
    -- hardware-event requirement. Do not run a doomed send from OnUpdate.
    if auto and channel=="SAY" and type(IsInInstance)=="function"
        and not IsInInstance() then return false end
    if channel=="PARTY" and (type(IsInGroup)~="function"
        or not IsInGroup() or
        (type(IsInRaid)=="function" and IsInRaid())) then
        return Reject("PARTY requires a normal party. No message sent.")
    end
    local now=Clock()
    if not now then return Reject("Combat report clock unavailable.") end
    if now-lastSentAt<3 then return Reject("Report just sent. Try again shortly.") end
    if auto and now-lastAutoAt<Settings().nativeAutoCooldown then return false end
    local send=type(SendChatMessage)=="function" and SendChatMessage or
        (C_ChatInfo and C_ChatInfo.SendChatMessage)
    if type(send)~="function" then return Reject("Chat API unavailable.") end
    local kind,label,perSecond,title,sources
    if auto then
        kind=AutoType()
        label,perSecond=TypeInfo(kind)
        title="Last"
        sources=kind and ExpiredSources(kind) or nil
    else
        if not frame or type(frame.GetDamageMeterType)~="function" then
            return Reject("Native meter selection unavailable.")
        end
        local ok,selected=pcall(frame.GetDamageMeterType,frame)
        if not ok or not Safe(selected) then
            return Reject("Meter statistic unavailable.")
        end
        kind=selected
        label,perSecond=TypeInfo(kind)
        title=SessionLabel(frame)
        sources=SelectedSources(frame)
        local _,current=SessionLabel(frame)
        if (not sources or #sources==0) and current then
            sources=ExpiredSources(kind)
            if sources and #sources>0 then title="Last" end
        end
    end
    if not label then return Reject("Meter statistic unavailable.") end
    local lines,reason=BuildMessages(sources,label,title,perSecond,
        Settings().nativeReportRows)
    if not lines then return Reject(reason) end
    -- Only the local fingerprint uses a newline; no newline goes to chat.
    local fingerprint=table.concat(lines,"\n")
    if auto and fingerprint==lastAutoMessage then return false end
    if auto and MessagingRestricted() then return false end
    -- Send each visual line as its own normal PARTY/SAY message, directly
    -- from the click rather than deferring to a timer that loses hardware context.
    -- Never retry or redirect a failed line.
    for i,line in ipairs(lines) do
        local ok,result=pcall(send,line,channel)
        if not ok or (Safe(result) and result==false) then
            if auto then return false end
            local detail=not ok and Safe(result) and type(result)=="string"
                and result:sub(1,180) or "chat API returned false"
            Note(channel.." report stopped at line "..i..": "..detail)
            return false
        end
        if i==1 then lastSentAt=now end
    end
    if auto then lastAutoAt=now;lastAutoMessage=fingerprint end
    -- A successful API call is not a delivery acknowledgment.
    Note((auto and "Auto report" or "Report").." requested in "..channel..
        " (delivery is controlled by the game).")
    return true
end
function ChalkBox_NativeMeterPrint(frame,channel)
    return SendReport(frame,channel or "PARTY",false)
end
function ChalkBox_NativeMeterStatus()
    local db=Settings()
    return {installed=installed,enabled=Enabled(),rows=db.nativeReportRows,
        auto=db.nativeAutoPrint,channel=db.nativeAutoChannel,
        minFight=db.nativeAutoMinFight,cooldown=db.nativeAutoCooldown,
        metric=db.nativeAutoMetric}
end
local function Cycle(value,choices)
    for i,choice in ipairs(choices) do
        if choice==value then return choices[i%#choices+1] end
    end
    return choices[1]
end
function ChalkBox_NativeMeterCommand(message)
    local value=(message or ""):lower():match("^%s*(.-)%s*$")
    local db=Settings()
    if value=="on" or value=="off" then
        db.nativePrint=value=="on"
        if not db.nativePrint then db.nativeAutoPrint=false;pendingDelay=nil end
        Note("Native meter reports "..(db.nativePrint and "ON" or "OFF")..".")
    elseif value=="auto on" or value=="auto off" then
        db.nativeAutoPrint=value=="auto on"
        if not db.nativeAutoPrint then pendingDelay=nil end
        Note("After-combat reports "..(db.nativeAutoPrint and "ON" or "OFF")..".")
    elseif value=="print party" or value=="print say" then
        Note("Use Blizzard meter gear menu to print the selected session.")
    elseif value:match("^rows (%d+)$") then
        local n=tonumber(value:match("^rows (%d+)$"))
        if OneOf(n,{3,5,10}) then db.nativeReportRows=n end
    elseif value=="channel party" or value=="channel say" then
        db.nativeAutoChannel=value:match("channel (%a+)"):upper()
    elseif value:match("^min (%d+)$") then
        local n=tonumber(value:match("^min (%d+)$"))
        if OneOf(n,{0,10,20,30}) then db.nativeAutoMinFight=n end
    elseif value:match("^cooldown (%d+)$") then
        local n=tonumber(value:match("^cooldown (%d+)$"))
        if OneOf(n,{30,60,120}) then db.nativeAutoCooldown=n end
    elseif value=="metric dps" or value=="metric damage"
        or value=="metric healing" then
        db.nativeAutoMetric=value:match("metric (%a+)")
    else
        local st=ChalkBox_NativeMeterStatus()
        Note("Native "..(st.enabled and "ON" or "OFF")..
            " | Top "..st.rows.." | Auto "..(st.auto and "ON" or "OFF")..
            " to "..st.channel.." | "..st.metric..
            " | min "..st.minFight.."s | pause "..st.cooldown.."s")
    end
end
local function Install()
    if installed or not Menu or type(Menu.ModifyMenu)~="function" then return end
    local ok=pcall(Menu.ModifyMenu,"MENU_DAMAGE_METER_WINDOW_SETTINGS",
        function(owner,root)
            if not Enabled() or not root or type(root.CreateButton)~="function" then
                return
            end
            local frame
            if owner and type(owner.GetParent)=="function" then
                local success,parent=pcall(owner.GetParent,owner)
                if success and parent and type(parent.GetCombatSession)=="function"
                    and type(parent.GetDamageMeterType)=="function" then
                    frame=parent
                end
            end
            if not frame then return end
            local db=Settings()
            if type(root.CreateDivider)=="function" then root:CreateDivider() end
            if type(root.CreateTitle)=="function" then
                root:CreateTitle("Combat reports")
            end
            root:CreateButton("Print top "..db.nativeReportRows.." to PARTY",
                function() SendReport(frame,"PARTY",false) end)
            root:CreateButton("Print top "..db.nativeReportRows.." to SAY",
                function() SendReport(frame,"SAY",false) end)
            root:CreateButton("Report size: Top "..db.nativeReportRows..
                "  (3 / 5 / 10)",function()
                db.nativeReportRows=Cycle(db.nativeReportRows,{3,5,10})
                Note("Report size: Top "..db.nativeReportRows..".")
            end)
            root:CreateButton("After combat: "..(db.nativeAutoPrint and
                "|cff4ce39aON|r" or "|cffaaaaaaOFF|r"),function()
                db.nativeAutoPrint=not db.nativeAutoPrint
                if not db.nativeAutoPrint then pendingDelay=nil end
                Note("After-combat reports "..(db.nativeAutoPrint and "ON" or "OFF")..".")
            end)
            root:CreateButton("Auto channel: "..db.nativeAutoChannel,
                function()
                db.nativeAutoChannel=Cycle(db.nativeAutoChannel,{"PARTY","SAY"})
                Note("Auto reports use "..db.nativeAutoChannel..
                    (db.nativeAutoChannel=="SAY" and " (nearby players can see)." or "."))
            end)
            local names={dps="DPS",damage="Damage",healing="Healing"}
            root:CreateButton("Auto stat: "..names[db.nativeAutoMetric],
                function()
                db.nativeAutoMetric=Cycle(db.nativeAutoMetric,
                    {"dps","damage","healing"})
                Note("Auto stat: "..names[db.nativeAutoMetric]..".")
            end)
            root:CreateButton("Minimum fight: "..db.nativeAutoMinFight.."s",
                function()
                db.nativeAutoMinFight=Cycle(db.nativeAutoMinFight,{0,10,20,30})
                Note("Auto minimum: "..db.nativeAutoMinFight.."s.")
            end)
            root:CreateButton("Auto cooldown: "..db.nativeAutoCooldown.."s",
                function()
                db.nativeAutoCooldown=Cycle(db.nativeAutoCooldown,{30,60,120})
                Note("Auto cooldown: "..db.nativeAutoCooldown.."s.")
            end)
        end)
    installed=ok
end
local events=CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent",function(_,event,name)
    if event=="ADDON_LOADED" then
        if name==addonName then Settings();Install()
        elseif not installed then Install() end
    elseif event=="PLAYER_LOGIN" then
        Install()
    elseif event=="PLAYER_REGEN_DISABLED" then
        combatStartedAt=Clock()
        pendingDelay=nil
    elseif event=="PLAYER_REGEN_ENABLED" then
        local finishedAt=Clock()
        local startedAt=combatStartedAt
        combatStartedAt=nil
        local db=Settings()
        if Enabled() and db.nativeAutoPrint and finishedAt and startedAt
            and finishedAt>=startedAt
            and finishedAt-startedAt>=db.nativeAutoMinFight then
            pendingDelay=2
        end
    end
end)
events:SetScript("OnUpdate",function(_,elapsed)
    if not pendingDelay then return end
    if not Number(elapsed) or elapsed<0 then return end
    if type(InCombatLockdown)=="function" and InCombatLockdown() then
        pendingDelay=nil
        return
    end
    pendingDelay=pendingDelay-elapsed
    if pendingDelay<=0 then
        pendingDelay=nil
        local db=Settings()
        if Enabled() and db.nativeAutoPrint then
            SendReport(nil,db.nativeAutoChannel,true)
        end
    end
end)
