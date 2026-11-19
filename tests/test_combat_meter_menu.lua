-- Compact meter menu shares Blizzard-native report preferences. Menu opens
-- only from a user click, never sends chat automatically or bypasses lockdown.
local st={mode="dps",session="current",rows=5,opacity=.70,
    iconMode="class",locked=false}
local report={rows=3,auto=false,channel="PARTY",metric="dps",
    minFight=10,cooldown=60}
local sent,commands,opened={}, {}, {}
_G.UIParent={}
_G.ChalkBox_MeterStatus=function() return st end
_G.ChalkBox_NativeMeterStatus=function() return report end
_G.ChalkBox_MeterCommand=function(command)
    commands[#commands+1]="meter "..command
    if command=="last" then st.session="expired"
    elseif command=="overall" or command=="current" then st.session=command
    elseif command=="lock" then st.locked=true
    elseif command=="unlock" then st.locked=false
    elseif command=="reset" then _G.resetRequested=true
    else
        local rows=command:match("^rows (%d+)$")
        local opacity=command:match("^opacity (%d+)$")
        local icons=command:match("^icons (%w+)$")
        if rows then st.rows=tonumber(rows)
        elseif opacity then st.opacity=tonumber(opacity)/100
        elseif icons then st.iconMode=icons
        else st.mode=command end
    end
end
_G.ChalkBox_NativeMeterCommand=function(command)
    commands[#commands+1]="native "..command
    local size=command:match("^rows (%d+)$")
    if size then report.rows=tonumber(size) end
    local channel=command:match("^channel (%a+)$")
    if channel then report.channel=channel:upper() end
    local metric=command:match("^metric (%a+)$")
    if metric then report.metric=metric end
    local min=command:match("^min (%d+)$")
    if min then report.minFight=tonumber(min) end
    local cool=command:match("^cooldown (%d+)$")
    if cool then report.cooldown=tonumber(cool) end
    if command=="auto on" then report.auto=true end
    if command=="auto off" then report.auto=false end
end
_G.ChalkBox_MeterReportSelected=function(channel)
    sent[#sent+1]=channel
end
_G.ChalkBox_OpenSettings=function(which)
    opened[#opened+1]=which
end
local locked=false
_G.InCombatLockdown=function() return locked end
local entries={}
_G.MenuUtil={CreateContextMenu=function(owner,builder)
    entries={}
    local root={
        CreateTitle=function(_,text) entries[#entries+1]={title=text} end,
        CreateDivider=function() entries[#entries+1]={divider=true} end,
        CreateButton=function(_,title,action)
            entries[#entries+1]={title=title,action=action}
        end,
    }
    builder(owner,root)
end}
_G.CreateFrame=function() error("new frames not needed with modern menus") end
assert(loadfile("CombatMeterMenu.lua"))("ChalkBox")
local owner={}
local function Open()
    assert(ChalkBox_MeterOpenMenu(owner))
    return entries
end
local function Click(prefix)
    for _,item in ipairs(entries) do
        if item.action and item.title:sub(1,#prefix)==prefix then
            return item.action()
        end
    end
    error("Missing menu item: "..prefix)
end
Open()
assert(entries[1].title=="ChalkBox Combat Meter")
assert(#entries>=19,"display, reports and window sections exposed")
Click("Print top 3 to PARTY")
Click("Print top 3 to SAY")
assert(#sent==2 and sent[1]=="PARTY" and sent[2]=="SAY",
    "both manual destinations route through one native report engine")
Click("Report size:")
assert(report.rows==5)
Open()
Click("Print top 5 to PARTY")
assert(sent[3]=="PARTY" and report.rows==5,
    "compact reports honor the same Top 3/5/10 setting")
Click("Auto after combat:")
assert(report.auto,"shared auto-report setting toggles")
Open();Click("Auto channel:")
assert(report.channel=="SAY","auto-channel change uses existing native command")
Open();Click("Auto stat:")
assert(report.metric=="damage")
Open();Click("Minimum fight:")
assert(report.minFight==20)
Open();Click("Auto cooldown:")
assert(report.cooldown==120)
Open();Click("Fight:")
assert(st.session=="expired",
    "current to last uses the established slash command rather than 'expired'")
Open();Click("Fight:")
assert(st.session=="overall","last to overall uses the original meter command")
Open();Click("Maximum rows:")
assert(st.rows==8,"five default rows can expand for a raid")
Open();Click("Class icons:")
assert(st.iconMode=="spec")
Open();Click("Background:")
assert(st.opacity==.85,"background opacity uses same 0-100 meter preference")
Open();Click("Lock position")
assert(st.locked)
Open();Click("Reset all combat sessions...")
assert(_G.resetRequested,"reset only requests existing confirmation")
Open();Click("Open meter settings")
assert(opened[1]=="meter")
report.ready=true
report.readyChannel="PARTY"
local readyClicks=0
_G.ChalkBox_NativeMeterSendReady=function()
    readyClicks=readyClicks+1
    report.ready=false
    return true
end
Open()
assert(Click("Send ready report to PARTY")
    and readyClicks==1 and not report.ready,
    "compact gear menu exposes a real player click for restricted auto chat")
locked=true
assert(not ChalkBox_MeterOpenMenu(owner) and #sent==3,
    "meter refuses right-click popup while combat-protected")
locked=false
_G.MenuUtil=nil
local fallback
_G.CreateFrame=function() return {} end
_G.EasyMenu=function(list,parent)
    fallback=list
end
assert(ChalkBox_MeterOpenMenu(owner) and #fallback>15,
    "classic Forever popup fallback exposes the same actions")
_G.EasyMenu=nil
assert(ChalkBox_MeterOpenMenu(owner) and opened[2]=="meter",
    "unsupported menus fall back to existing settings instead of hiding actions")
print("PASS: compact gear menu native/legacy fallback, shared top-size, safe reporting, auto options, combat and reset guard")
