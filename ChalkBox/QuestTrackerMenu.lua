-- ChalkBox: non-invasive context actions on Blizzard's Objective Tracker
-- header. Attach only with HookScript: never replace tracker scripts, modify
-- header mouse flags, suppress per-quest right-clicks or draw a new tracker.
local addonName=...
local hooked=setmetatable({},{__mode="k"})
local dropdown
local function Busy()
    if type(InCombatLockdown)~="function" then return false end
    local ok,yes=pcall(InCombatLockdown)
    return not ok or yes==true
end
local function State()
    local q=type(ChalkBox_QuestStatus)=="function" and
        ChalkBox_QuestStatus() or {}
    local n=type(ChalkBox_NavStatus)=="function" and
        ChalkBox_NavStatus() or {}
    return q,n
end
local function SetMode(command)
    if type(ChalkBox_QuestCommand)~="function" then return end
    if command=="off" then
        ChalkBox_QuestCommand("off")
    else
        ChalkBox_QuestCommand("on")
        ChalkBox_QuestCommand(command)
    end
end
local function Entries()
    local q,n=State()
    local off=q.enabled==false
    local smart=not off and q.mode=="smart"
    local zone=not off and q.mode=="zone"
    return {
        {label="QuestSense Settings",run=function()
            if type(ChalkBox_OpenSettings)=="function" then
                ChalkBox_OpenSettings("quests")
            end
        end},
        {label=(off and "✓ " or "").."Off",run=function() SetMode("off") end},
        {label=(smart and "✓ " or "").."Smart",run=function() SetMode("smart") end},
        {label=(zone and "✓ " or "").."Nearby",run=function() SetMode("zone") end},
        {label="Navigation: "..(n.enabled and "On" or "Off"),
            run=function()
                if type(ChalkBox_NavCommand)=="function" then
                    ChalkBox_NavCommand(n.enabled and "off" or "on")
                end
            end},
    }
end
function ChalkBox_QuestTrackerMenuOpen(owner)
    if Busy() then return false end
    local entries=Entries()
    if type(MenuUtil)=="table" and
        type(MenuUtil.CreateContextMenu)=="function" then
        local ok=pcall(MenuUtil.CreateContextMenu,owner,
            function(_,root)
                if type(root.CreateTitle)=="function" then
                    root:CreateTitle("ChalkBox / QuestSense")
                end
                for _,e in ipairs(entries) do
                    root:CreateButton(e.label,function() e.run() end)
                end
            end)
        if ok then return true end
    end
    if type(EasyMenu)=="function" and type(CreateFrame)=="function" then
        if not dropdown then
            local ok,value=pcall(CreateFrame,"Frame",
                "ChalkBoxQuestTrackerMenu",UIParent,
                "UIDropDownMenuTemplate")
            if ok then dropdown=value end
        end
        if dropdown then
            local menu={{text="ChalkBox / QuestSense",
                isTitle=true,notCheckable=true}}
            for _,e in ipairs(entries) do
                menu[#menu+1]={text=e.label,func=e.run,
                    notCheckable=true}
            end
            local ok=pcall(EasyMenu,menu,dropdown,"cursor",0,0,"MENU")
            if ok then return true end
        end
    end
    -- Only if both game menu APIs are missing.
    if type(ChalkBox_OpenSettings)=="function" then
        ChalkBox_OpenSettings("quests")
    end
    return false
end
local function HookHeader(frame)
    if not frame or hooked[frame] or
        type(frame.HookScript)~="function" then return false end
    local ok=pcall(frame.HookScript,frame,"OnMouseUp",
        function(self,button)
            if button=="RightButton" then
                ChalkBox_QuestTrackerMenuOpen(self)
            end
        end)
    if ok then hooked[frame]=true end
    return ok
end
local function Attach()
    -- Some Forever builds expose a separate header; others have just the
    -- tracker container. Hook only the real existing header or tracker.
    -- Do not touch individual quest rows or their Blizzard context menus.
    local tracker=ObjectiveTrackerFrame
    local sub=QuestObjectiveTracker
    local installed=false
    if tracker then
        for _,f in ipairs({tracker.Header or false,
            tracker.HeaderFrame or false,
            tracker.ContentsFrame and tracker.ContentsFrame.Header or false,
            tracker.TitleBar or false}) do
            if f and HookHeader(f) then installed=true end
        end
        if not installed then installed=HookHeader(tracker) end
    end
    if not installed and sub then
        installed=HookHeader(sub.Header or sub)
    end
    return installed
end
function ChalkBox_QuestTrackerMenuStatus()
    return {attached=Attach(),nativeTracker=ObjectiveTrackerFrame~=nil}
end
local listener=CreateFrame("Frame")
for _,event in ipairs({"ADDON_LOADED","PLAYER_ENTERING_WORLD"}) do
    pcall(listener.RegisterEvent,listener,event)
end
listener:SetScript("OnEvent",function(_,event,name)
    if event=="ADDON_LOADED" and name==addonName then
        Attach()
    elseif event=="ADDON_LOADED" or event=="PLAYER_ENTERING_WORLD" then
        -- The actual Blizzard tracker might appear after another addon loads.
        Attach()
    end
end)
Attach()
