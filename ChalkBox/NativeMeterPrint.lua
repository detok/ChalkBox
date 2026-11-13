-- ChalkBox native damage-meter integration for WoW Forever.
-- Extend Blizzard's existing gear menu, not its protected windows or data.
-- Never inspect secret combat values, post automatically, or send outside PARTY.
local addonName=...
local installed=false
local lastSentAt=-1000000000

local function Safe(v)
    return v~=nil and (type(issecretvalue)~="function" or not issecretvalue(v))
end

local function Note(message)
    if DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage)=="function" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffefc574ChalkBox|r "..message)
    end
end

local function Enabled()
    return type(ChalkBoxDB)=="table"
        and (type(ChalkBoxDB.meter)~="table" or ChalkBoxDB.meter.nativePrint~=false)
end

local function TypeInfo(kind)
    if not Safe(kind) or type(kind)~="number" then return end
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

local function SessionLabel(frame)
    if type(frame.GetSessionType)=="function" then
        local ok,kind=pcall(frame.GetSessionType,frame)
        if ok and Safe(kind) and type(kind)=="number" then
            local e=Enum and Enum.DamageMeterSessionType or {}
            if kind==e.Current then return "Current",true end
            if kind==e.Overall then return "Overall",false end
        end
    end
    if type(frame.GetSessionID)=="function" then
        local ok,id=pcall(frame.GetSessionID,frame)
        if ok and Safe(id) and type(id)=="number" and id>=0 then
            return "Fight "..tostring(math.floor(id)),false
        end
    end
    return "Fight",false
end

local function ReadSession(frame,kind)
    if type(frame.GetCombatSession)~="function" then return end
    local ok,session=pcall(frame.GetCombatSession,frame)
    if not ok or not Safe(session) or type(session)~="table" then return end
    return session
end

local function CombatSources(session)
    if not Safe(session) or type(session)~="table" then return end
    local sources=session.combatSources
    if not Safe(sources) or type(sources)~="table" then return end
    return sources
end

local function SendNativeReport(frame)
    if not Enabled() then Note("Blizzard meter PRINT is disabled in ChalkBox.");return false end
    if type(InCombatLockdown)=="function" and InCombatLockdown() then
        Note("Finish combat before reporting; combat values may be protected.")
        return false
    end
    if type(IsInGroup)~="function" or not IsInGroup()
        or (type(IsInRaid)=="function" and IsInRaid()) then
        Note("Join a normal party to use PRINT. No message sent.")
        return false
    end
    if not frame or type(frame.GetDamageMeterType)~="function" then
        Note("Blizzard meter selection unavailable.")
        return false
    end
    if type(frame.IsEditing)=="function" then
        local ok,editing=pcall(frame.IsEditing,frame)
        if not ok or not Safe(editing) or editing then
            Note("Close Edit Mode before printing an actual fight.")
            return false
        end
    end
    local send=(C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
    if type(send)~="function" then Note("Party chat API unavailable.");return false end
    local now=type(GetTime)=="function" and GetTime() or nil
    if Safe(now) and type(now)=="number" and now-lastSentAt<3 then
        Note("The previous report was just sent. Try again in a moment.")
        return false
    end
    local ok,kind=pcall(frame.GetDamageMeterType,frame)
    if not ok or not Safe(kind) then Note("Meter statistic unavailable.");return false end
    local label,perSecond=TypeInfo(kind)
    if not label then Note("Meter statistic unavailable.");return false end
    local title,isCurrent=SessionLabel(frame)
    local sources=CombatSources(ReadSession(frame,kind))
    if (not sources or #sources==0) and isCurrent
        and C_DamageMeter and type(C_DamageMeter.GetCombatSessionFromType)=="function" then
        local e=Enum and Enum.DamageMeterSessionType or {}
        local expired=e.Expired
        if type(expired)=="number" then
            local previousOK,previous=pcall(C_DamageMeter.GetCombatSessionFromType,expired,kind)
            if previousOK then
                sources=CombatSources(previous)
                if sources and #sources>0 then title="Last" end
            end
        end
    end
    if not sources or #sources==0 then
        Note("No fight values available for this Blizzard meter selection.")
        return false
    end
    local parts={}
    for i=1,math.min(#sources,3) do
        local source=sources[i]
        if not Safe(source) or type(source)~="table" then
            Note("Fight data is protected. Try after combat.")
            return false
        end
        local name=source.name
        local amount=perSecond and source.amountPerSecond or source.totalAmount
        if not Safe(name) or type(name)~="string"
            or not Safe(amount) or type(amount)~="number" then
            Note("Fight results are still protected or incomplete. No message sent.")
            return false
        end
        name=name:gsub("[%c|]","")
        if name=="" then name="Unknown" end
        parts[#parts+1]=string.format("%d %s %.0f",i,name,amount)
    end
    local prefix="CB "..label.." ("..title.."): "
    local message=prefix..table.concat(parts," | ")
    while #message>255 and #parts>1 do
        table.remove(parts)
        message=prefix..table.concat(parts," | ")
    end
    if #message>255 then
        Note("Party report is too long. No message sent.")
        return false
    end
    local sent,result=pcall(send,message,"PARTY")
    if not sent or result==false then
        Note("Party chat rejected the report. No alternate channel used.")
        return false
    end
    if Safe(now) and type(now)=="number" then lastSentAt=now end
    Note("Blizzard meter report submitted to PARTY.")
    return true
end

function ChalkBox_NativeMeterPrint(frame)
    return SendNativeReport(frame)
end

function ChalkBox_NativeMeterStatus()
    return {installed=installed,enabled=Enabled()}
end

function ChalkBox_NativeMeterCommand(message)
    local value=(message or ""):lower():match("^%s*(.-)%s*$")
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    if type(ChalkBoxDB.meter)~="table" then ChalkBoxDB.meter={} end
    if value=="on" or value=="off" then
        ChalkBoxDB.meter.nativePrint=value=="on"
        Note("Blizzard damage meter gear-menu PRINT "..(value=="on" and "enabled." or "disabled."))
    else
        Note("Blizzard meter PRINT "..(Enabled() and "enabled" or "disabled")..
            ", native menu hook "..(installed and "ready." or "unavailable on this client.")..
            " Use /chalk meter native on|off.")
    end
end

local function Install()
    if installed or not Menu or type(Menu.ModifyMenu)~="function" then return end
    local ok=pcall(Menu.ModifyMenu,"MENU_DAMAGE_METER_WINDOW_SETTINGS",
        function(owner,root)
            if not Enabled() or not root or type(root.CreateButton)~="function" then return end
            -- The settings dropdown's parent is the selected native session
            -- window. Each gear menu prints that window's selected mode/fight.
            local frame
            if owner and type(owner.GetParent)=="function" then
                local parentOK,parent=pcall(owner.GetParent,owner)
                if parentOK and type(parent)=="table" then frame=parent end
            end
            if not frame or type(frame.GetCombatSession)~="function"
                or type(frame.GetDamageMeterType)~="function" then return end
            if type(root.CreateDivider)=="function" then root:CreateDivider() end
            root:CreateButton("ChalkBox: PRINT top 3 to PARTY",function()
                SendNativeReport(frame)
            end)
        end)
    installed=ok
end

local events=CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent",function(_,event,name)
    if event=="ADDON_LOADED" then
        if name==addonName then
            if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
            Install()
        elseif not installed then
            -- Blizzard_Menu/Blizzard_DamageMeter can load on demand.
            Install()
        end
    elseif event=="PLAYER_LOGIN" then
        Install()
    end
end)
