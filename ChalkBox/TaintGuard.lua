-- Records Blizzard's blocked-action notices and reports what ChalkBox
-- will and will not touch. It never moves, shows, hides, or hooks a frame.
local addonName=...
local lastEvent,lastFunc
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
    return {
        addon=addonName,
        combat=Combat(),
        lastEvent=lastEvent,
        lastFunc=lastFunc,
        chrome=chrome,
        layout=layout and layout.reason or "not loaded",
        bagsPending=bags and bags.pending or false,
        trackerHooked=quests and quests.attached or false,
    }
end
function ChalkBox_TaintCheck()
    local st=ChalkBox_TaintStatus()
    Note("Taint check. Combat lockdown: "..(st.combat and "yes" or "no")..".")
    Note("Last blocked action: "..(st.lastEvent and
        (st.lastEvent.." "..tostring(st.lastFunc or "")) or "none recorded")..".")
    Note("Top frames stay with Blizzard ("..(st.layout or "unread")..").")
    local bits={}
    for name,state in pairs(st.chrome) do
        bits[#bits+1]=name.." "..state
    end
    table.sort(bits)
    Note("Frames: "..table.concat(bits,", ")..".")
    Note("Bag offset waiting: "..tostring(st.bagsPending)
        ..". Quest tracker hook: "..tostring(st.trackerHooked)..".")
    return st
end
local frame=CreateFrame("Frame")
frame:SetScript("OnEvent",function(_,event,addon,func)
    if Secret(addon) or addon~=addonName then return end
    lastEvent=event
    lastFunc=Secret(func) and "secret" or tostring(func or "")
end)
for _,event in ipairs({"ADDON_ACTION_BLOCKED","ADDON_ACTION_FORBIDDEN"}) do
    pcall(frame.RegisterEvent,frame,event)
end
