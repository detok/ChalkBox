-- Compact meter options remain functional, but report controls are absent.
local st={mode="dps",session="current",rows=5,opacity=.70,iconMode="class",locked=false}
local opened={}
_G.UIParent={}
_G.ChalkBox_MeterStatus=function() return st end
_G.ChalkBox_NativeMeterStatus=function() error("native reporting must never be queried") end
_G.ChalkBox_MeterReportSelected=function() error("report action must never run") end
_G.ChalkBox_NativeMeterCommand=function() error("auto report must never run") end
_G.ChalkBox_OpenSettings=function(which) opened[#opened+1]=which end
_G.ChalkBox_MeterCommand=function(cmd)
    if cmd=="last" then st.session="expired"
    elseif cmd=="overall" or cmd=="current" then st.session=cmd
    elseif cmd=="lock" then st.locked=true
    elseif cmd=="unlock" then st.locked=false
    elseif cmd=="reset" then _G.resetRequested=true
    else
        local rows=cmd:match("^rows (%d+)$")
        local opacity=cmd:match("^opacity (%d+)$")
        local icons=cmd:match("^icons (%w+)$")
        if rows then st.rows=tonumber(rows)
        elseif opacity then st.opacity=tonumber(opacity)/100
        elseif icons then st.iconMode=icons
        else st.mode=cmd end
    end
end
local locked=false
_G.InCombatLockdown=function() return locked end
local entries={}
_G.MenuUtil={CreateContextMenu=function(_,builder)
    entries={}
    local root={
        CreateTitle=function(_,name) entries[#entries+1]={title=name} end,
        CreateDivider=function() entries[#entries+1]={divider=true} end,
        CreateButton=function(_,name,callback)
            entries[#entries+1]={title=name,action=callback}
        end
    }
    builder({},root)
end}
_G.CreateFrame=function() return {} end
assert(loadfile("CombatMeterMenu.lua"))("ChalkBox")
local owner={}
local function Open()
    assert(ChalkBox_MeterOpenMenu(owner))
    for _,entry in ipairs(entries) do
        local title=entry.title or ""
        assert(not title:find("Print") and not title:find("Report")
            and not title:find("Auto") and not title:find("Send"),
            "no report controls appear in the compact meter menu")
    end
end
local function Click(prefix)
    for _,entry in ipairs(entries) do
        if entry.action and entry.title:sub(1,#prefix)==prefix then
            entry.action();return
        end
    end
    error("Missing menu action: "..prefix)
end
Open()
assert(#entries>=10 and #entries<=13,"only display and window sections remain")
Click("Fight:"); assert(st.session=="expired")
Open();Click("Fight:"); assert(st.session=="overall")
Open();Click("Maximum rows:"); assert(st.rows==8)
Open();Click("Class icons:"); assert(st.iconMode=="spec")
Open();Click("Background:"); assert(st.opacity==.85)
Open();Click("Lock position"); assert(st.locked)
Open();Click("Reset all combat sessions..."); assert(_G.resetRequested)
Open();Click("Open meter settings"); assert(opened[1]=="meter")
locked=true;assert(not ChalkBox_MeterOpenMenu(owner));locked=false
_G.MenuUtil=nil
local legacy
_G.EasyMenu=function(list) legacy=list end
assert(ChalkBox_MeterOpenMenu(owner) and #legacy>8)
for _,entry in ipairs(legacy) do
    local t=entry.text or ""
    assert(not t:find("Print") and not t:find("Report")
        and not t:find("Auto") and not t:find("Send"),
        "the legacy client popup also hides all report actions")
end
_G.EasyMenu=nil
assert(ChalkBox_MeterOpenMenu(owner) and opened[2]=="meter")
print("PASS: meter window menus work with reporting completely removed")
