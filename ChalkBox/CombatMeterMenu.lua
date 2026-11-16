-- ChalkBox compact meter menu. Reuse native reporting and its preferences,
-- not an independent serializer or alternate chat sender.
local dropdown
local function Next(value,options)
    for i,v in ipairs(options) do
        if v==value then return options[i%#options+1] end
    end
    return options[1]
end
local function Lockdown()
    if type(InCombatLockdown)~="function" then return false end
    local ok,locked=pcall(InCombatLockdown)
    return not ok or locked==true
end
local function Items()
    local st=type(ChalkBox_MeterStatus)=="function" and
        ChalkBox_MeterStatus() or {}
    local report=type(ChalkBox_NativeMeterStatus)=="function" and
        ChalkBox_NativeMeterStatus() or {}
    local mode=st.mode or "dps"
    local session=st.session or "current"
    local modeLabel={dps="DPS",damage="Damage",hps="HPS",
        healing="Healing",taken="Damage taken",interrupts="Interrupts"}
    local sessionLabel={current="Current",expired="Last",overall="Overall"}
    local modes={"dps","damage","hps","healing","taken","interrupts"}
    local sessions={"current","expired","overall"}
    local icons={"class","spec","off"}
    local opacity=math.floor((st.opacity or 0.70)*100+0.5)
    local sizes={0,25,50,70,85,100}
    local function Meter(command)
        if type(ChalkBox_MeterCommand)=="function" then
            ChalkBox_MeterCommand(command)
        end
    end
    local function Native(command)
        if type(ChalkBox_NativeMeterCommand)=="function" then
            ChalkBox_NativeMeterCommand(command)
        end
    end
    local function Add(group,title,action)
        return {group=group,title=title,action=action}
    end
    local entries={
        Add("Display","Statistic: "..(modeLabel[mode] or mode),function()
            Meter(Next(mode,modes))
        end),
        Add("Display","Fight: "..(sessionLabel[session] or session),function()
            Meter(Next(session,sessions))
        end),
        Add("Display","Maximum rows: "..(st.rows or 5).." (5 / 8 / 12)",function()
            Meter("rows "..Next(st.rows or 5,{5,8,12}))
        end),
        Add("Display","Class icons: "..(st.iconMode or "class"),function()
            Meter("icons "..Next(st.iconMode or "class",icons))
        end),
        Add("Reports","Print top "..(report.rows or 3).." to PARTY",function()
            if type(ChalkBox_MeterReportSelected)=="function" then
                ChalkBox_MeterReportSelected("PARTY")
            end
        end),
        Add("Reports","Print top "..(report.rows or 3).." to SAY",function()
            if type(ChalkBox_MeterReportSelected)=="function" then
                ChalkBox_MeterReportSelected("SAY")
            end
        end),
        Add("Reports","Report size: Top "..(report.rows or 3).." (3 / 5 / 10)",function()
            Native("rows "..Next(report.rows or 3,{3,5,10}))
        end),
        Add("Reports","Auto after combat: "..(report.auto and "ON" or "OFF"),function()
            Native(report.auto and "auto off" or "auto on")
        end),
        Add("Reports","Auto channel: "..(report.channel or "PARTY"),function()
            Native("channel "..Next((report.channel or "PARTY"):lower(),{"party","say"}))
        end),
        Add("Reports","Auto stat: "..(report.metric or "dps"),function()
            Native("metric "..Next(report.metric or "dps",{"dps","damage","healing"}))
        end),
        Add("Reports","Minimum fight: "..(report.minFight or 10).."s",function()
            Native("min "..Next(report.minFight or 10,{0,10,20,30}))
        end),
        Add("Reports","Auto cooldown: "..(report.cooldown or 60).."s",function()
            Native("cooldown "..Next(report.cooldown or 60,{30,60,120}))
        end),
        Add("Window","Background: "..opacity.."%",function()
            local index=sizes[1]
            for _,v in ipairs(sizes) do
                if v>=opacity then index=v;break end
            end
            Meter("opacity "..Next(index,sizes))
        end),
        Add("Window",st.locked and "Unlock position" or "Lock position",function()
            Meter(st.locked and "unlock" or "lock")
        end),
        Add("Window","Reset all combat sessions...",function()
            Meter("reset") -- existing confirmation, never immediate reset
        end),
        Add("Window","Open meter settings",function()
            if type(ChalkBox_OpenSettings)=="function" then
                ChalkBox_OpenSettings("meter")
            end
        end),
    }
    return entries
end
function ChalkBox_MeterOpenMenu(owner)
    if Lockdown() then return false end
    local entries=Items()
    if type(MenuUtil)=="table" and
        type(MenuUtil.CreateContextMenu)=="function" then
        local ok=pcall(MenuUtil.CreateContextMenu,owner or UIParent,
            function(_,root)
                if not root or type(root.CreateButton)~="function" then return end
                if type(root.CreateTitle)=="function" then
                    root:CreateTitle("ChalkBox Combat Meter")
                end
                local current
                for _,entry in ipairs(entries) do
                    if entry.group~=current then
                        if current and type(root.CreateDivider)=="function" then
                            root:CreateDivider()
                        end
                        if type(root.CreateTitle)=="function" then
                            root:CreateTitle(entry.group)
                        end
                        current=entry.group
                    end
                    root:CreateButton(entry.title,entry.action)
                end
            end)
        if ok then return true end
    end
    if type(EasyMenu)=="function" then
        if not dropdown then
            dropdown=CreateFrame("Frame","ChalkBoxCompactMeterDropdown",
                UIParent,"UIDropDownMenuTemplate")
        end
        local list={{text="ChalkBox Combat Meter",isTitle=true,notCheckable=true}}
        local current
        for _,entry in ipairs(entries) do
            if entry.group~=current then
                list[#list+1]={text=entry.group,isTitle=true,
                    notCheckable=true}
                current=entry.group
            end
            list[#list+1]={text=entry.title,notCheckable=true,func=entry.action}
        end
        return pcall(EasyMenu,list,dropdown,"cursor",0,0,"MENU")
    end
    if type(ChalkBox_OpenSettings)=="function" then
        ChalkBox_OpenSettings("meter")
        return true
    end
    return false
end
