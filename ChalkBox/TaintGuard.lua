-- Records Blizzard's blocked-action notices. It never moves a frame.
-- /chalk taintcheck prints the last few, which are also kept in ChalkBoxDB.taintLog.
local addonName=...
local MAX_LOG=8
local lastEvent,lastFunc,lastModule
local function Secret(v)
    return type(issecretvalue)=="function" and issecretvalue(v)
end
local function Combat()
    if type(InCombatLockdown)~="function" then return false end
    local ok,locked=pcall(InCombatLockdown)
    return ok and locked==true
end
local function Note(text)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff55ccaaChalkBox|r "..text)
    end
end
local function Log()
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    if type(ChalkBoxDB.taintLog)~="table" then ChalkBoxDB.taintLog={} end
    return ChalkBoxDB.taintLog
end
local function ModuleFromStack(stack)
    local name=tostring(stack or ""):match("([%w_]+)%.lua")
    return name
end
function ChalkBox_TaintMark(module)
    ChalkBoxTaintMark=module
end
function ChalkBox_TaintClear()
    ChalkBoxTaintMark=nil
end
local function Protected(name)
    local frame=_G[name]
    if not frame then return "missing" end
    if type(frame.IsProtected)~="function" then return "unknown" end
    local ok,value=pcall(frame.IsProtected,frame)
    if not ok or Secret(value) then return "unknown" end
    return value==true and "protected" or "not protected"
end
function ChalkBox_TaintStatus()
    local chrome={}
    for _,name in ipairs({"MinimapCluster","BuffFrame","PlayerFrame",
        "TargetFrame","TicketStatusFrame","WorldStateAlwaysUpFrame"}) do
        chrome[name]=Protected(name)
    end
    local layout=type(ChalkBox_ScreenLayoutStatus)=="function"
        and ChalkBox_ScreenLayoutStatus() or nil
    local bags=type(ChalkBox_BagStatus)=="function" and ChalkBox_BagStatus() or nil
    local quests=type(ChalkBox_QuestTrackerMenuStatus)=="function"
        and ChalkBox_QuestTrackerMenuStatus() or nil
    local saved=type(ChalkBoxDB)=="table" and ChalkBoxDB.taintLog or nil
    return {
        addon=addonName,
        combat=Combat(),
        lastEvent=lastEvent,
        lastFunc=lastFunc,
        lastModule=lastModule,
        log=saved,
        chrome=chrome,
        layout=layout and layout.reason or "not loaded",
        bagsPending=bags and bags.pending or false,
        trackerHooked=quests and quests.attached or false,
    }
end
function ChalkBox_TaintCheck()
    local st=ChalkBox_TaintStatus()
    Note("Taint check. Combat lockdown: "..(st.combat and "yes" or "no")..".")
    local saved=type(st.log)=="table" and st.log or {}
    if #saved==0 then
        Note("No blocked action has been recorded yet.")
    end
    for i,entry in ipairs(saved) do
        Note(("%d. %s %s | %s | %s"):format(
            i, tostring(entry.event or ""), tostring(entry.func or "UNKNOWN()"),
            tostring(entry.module or "unknown"), tostring(entry.time or "")))
        if type(entry.stack)=="string" and entry.stack~="" then
            Note(entry.stack:sub(1,180))
        end
    end
    Note("Top frames stay with Blizzard ("..(st.layout or "unread")..").")
    return st
end
local frame=CreateFrame("Frame")
frame:SetScript("OnEvent",function(_,event,addon,func)
    if Secret(addon) or (addon~=addonName and addon~="ChalkBox") then return end
    local name=Secret(func) and "secret" or tostring(func or "UNKNOWN()")
    local stack=""
    if type(debugstack)=="function" then
        local ok,text=pcall(debugstack,2,12,2)
        if ok and type(text)=="string" then stack=text end
    end
    local module=ChalkBoxTaintMark or ModuleFromStack(stack) or "unknown"
    lastEvent,lastFunc,lastModule=event,name,module
    local when
    if type(time)=="function" then
        local ok,t=pcall(time)
        if ok then when=t end
    end
    local saved=Log()
    saved[#saved+1]={
        time=when,event=event,func=name,module=module,
        stack=stack:sub(1,500),
    }
    while #saved>MAX_LOG do table.remove(saved,1) end
end)
for _,event in ipairs({"ADDON_ACTION_BLOCKED","ADDON_ACTION_FORBIDDEN"}) do
    pcall(frame.RegisterEvent,frame,event)
end
