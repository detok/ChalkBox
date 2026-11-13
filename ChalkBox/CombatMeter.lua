-- ChalkBox CombatMeter 1.7: compact, native-data combat scoreboard for Forever.
-- No COMBAT_LOG_EVENT_UNFILTERED, GUID parsing, pet attribution guesses, or
-- calculations on secret combat data. Use Blizzard's C_DamageMeter directly.
local addonName=...
local db,window,header,notice
local rows={}
local refreshQueued=false
local modes={
    {key="dps", label="DPS", enum="Dps", perSecond=true},
    {key="damage", label="DMG", enum="DamageDone"},
    {key="hps", label="HPS", enum="Hps", perSecond=true},
    {key="healing", label="HEAL", enum="HealingDone"},
    {key="taken", label="TAKEN", enum="DamageTaken"},
    {key="interrupts", label="INT", enum="Interrupts"},
}
local sessions={
    {key="current",label="Fight",enum="Current"},
    {key="expired",label="Last",enum="Expired"},
    {key="overall",label="Overall",enum="Overall"},
}
local meterButton,sessionButton
local function Safe(v)
    return v~=nil and (type(issecretvalue)~="function" or not issecretvalue(v))
end
local function Chat(message)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cffefc574ChalkBox Meter|r "..message)
    end
end
local function Settings()
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    local value=ChalkBoxDB.meter
    if type(value)~="table" then value={};ChalkBoxDB.meter=value end
    if value.shown==nil then value.shown=true end
    if value.locked==nil then value.locked=false end
    if value.mode==nil then value.mode="dps" end
    if value.session==nil then value.session="current" end
    if value.rows~=5 and value.rows~=8 and value.rows~=12 then value.rows=8 end
    if value.scale~=0.85 and value.scale~=1 and value.scale~=1.15 then value.scale=1 end
    return value
end
local function Find(list,key)
    for i,choice in ipairs(list) do
        if choice.key==key then return choice,i end
    end
    return list[1],1
end
local function EnumValue(group,key,fallback)
    local enum=Enum and Enum[group]
    local value=enum and enum[key]
    if type(value)=="number" then return value end
    return fallback
end
local function Choice()
    return Find(modes,db and db.mode)
end
local function Session()
    return Find(sessions,db and db.session)
end
local function IsAvailable()
    if type(C_DamageMeter)~="table" or
        type(C_DamageMeter.GetCombatSessionFromType)~="function" then
        return false,"Blizzard's C_DamageMeter API is unavailable on this client."
    end
    if type(C_DamageMeter.IsDamageMeterAvailable)=="function" then
        local ok,available,reason=pcall(C_DamageMeter.IsDamageMeterAvailable)
        if not ok or available~=true then
            return false,Safe(reason) and type(reason)=="string" and reason
                or "Blizzard's damage meter is not available right now."
        end
    end
    return true
end
local function Font(parent,template,r,g,b)
    local f=parent:CreateFontString(nil,"OVERLAY",template or "GameFontHighlightSmall")
    if f.SetTextColor then f:SetTextColor(r or 0.94,g or 0.94,b or 0.94) end
    return f
end
local function Note(text)
    if notice then notice:SetText(text or "") end
end
local function ApplyLayout()
    if not window or not db then return end
    window:SetScale(db.scale)
    window:SetSize(326,72+db.rows*25)
    if window.ClearAllPoints then window:ClearAllPoints() end
    if db.position=="custom" and type(db.x)=="number" and type(db.y)=="number" then
        window:SetPoint("CENTER",UIParent,"CENTER",db.x,db.y)
    else
        window:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-32,190)
    end
    for i,row in ipairs(rows) do
        if i<=db.rows then row:Show() else row:Hide() end
    end
end
local function MakeRow(i)
    local frame=CreateFrame("Frame",nil,window)
    frame:SetHeight(23)
    frame:SetPoint("TOPLEFT",window,"TOPLEFT",11,-41-(i-1)*25)
    frame:SetPoint("TOPRIGHT",window,"TOPRIGHT",-11,-41-(i-1)*25)
    local bg=frame:CreateTexture(nil,"BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetColorTexture(0.095,0.14,0.19,i%2==0 and 0.78 or 0.64)
    local bar=CreateFrame("StatusBar",nil,frame)
    bar:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
    bar:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,0)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    bar:SetMinMaxValues(0,1)
    bar:SetValue(0)
    bar:SetStatusBarColor(0.27,0.60,0.78,0.52)
    local marker=frame:CreateTexture(nil,"ARTWORK")
    marker:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
    marker:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",0,0)
    marker:SetWidth(3)
    marker:SetColorTexture(0.98,0.75,0.25,1)
    marker:Hide()
    local rank=Font(frame,"GameFontHighlightSmall",0.71,0.79,0.85)
    rank:SetPoint("LEFT",frame,"LEFT",7,0)
    rank:SetWidth(18)
    if rank.SetJustifyH then rank:SetJustifyH("LEFT") end
    rank:SetText(i..".")
    local name=Font(frame,"GameFontHighlightSmall",0.98,0.98,0.99)
    name:SetPoint("LEFT",frame,"LEFT",27,0)
    name:SetWidth(142)
    if name.SetJustifyH then name:SetJustifyH("LEFT") end
    local value=Font(frame,"GameFontHighlightSmall",1,0.94,0.77)
    value:SetPoint("RIGHT",frame,"RIGHT",-7,0)
    value:SetWidth(104)
    if value.SetJustifyH then value:SetJustifyH("RIGHT") end
    frame.bar=bar
    frame.marker=marker
    frame.playerName=name
    frame.value=value
    return frame
end
local function ResetDisplay(message)
    for _,row in ipairs(rows) do
        row.playerName:SetText("")
        row.value:SetText("")
        row.marker:Hide()
        row.bar:SetMinMaxValues(0,1)
        row.bar:SetValue(0)
        row.bar:SetStatusBarColor(0.27,0.60,0.78,0.50)
    end
    Note(message or "No fight recorded yet.")
end
-- Pass secret combat values directly to Blizzard's C setters. Never convert,
-- compare, sort, format with Lua string.format, or persist these numbers.
local function DisplayValue(font,value)
    if type(issecretvalue)=="function" and issecretvalue(value) then
        font:SetFormattedText("%.0f",value)
    elseif type(value)=="number" then
        font:SetText(string.format("%.0f",value))
    else
        font:SetText("--")
    end
end
local function DrawRow(row,source,maxValue,perSecond)
    local displayName=source.name
    if type(issecretvalue)=="function" and issecretvalue(displayName) then
        row.playerName:SetText(displayName)
    elseif type(displayName)=="string" and displayName~="" then
        row.playerName:SetText(displayName)
    else
        row.playerName:SetText("Unknown")
    end
    local class=Safe(source.classFilename) and source.classFilename or nil
    local color=class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if color then
        row.bar:SetStatusBarColor(color.r,color.g,color.b,0.62)
    else
        row.bar:SetStatusBarColor(0.25,0.64,0.78,0.55)
    end
    if source.isLocalPlayer==true then row.marker:Show() else row.marker:Hide() end
    local amount=perSecond and source.amountPerSecond or source.totalAmount
    if Safe(maxValue) and type(maxValue)=="number" and maxValue<=0 then
        maxValue=1
    end
    if maxValue~=nil then
        -- C_DamageMeter's own maximum is used. These C UI setters accept
        -- secret values; do not compute a percentage in Lua.
        row.bar:SetMinMaxValues(0,maxValue)
    else
        row.bar:SetMinMaxValues(0,1)
    end
    if amount~=nil then
        row.bar:SetValue(amount)
        DisplayValue(row.value,amount)
    else
        row.bar:SetValue(0)
        row.value:SetText("--")
    end
end
local function Refresh()
    refreshQueued=false
    if not window or not db or db.shown==false or not window:IsShown() then return end
    local available,reason=IsAvailable()
    if not available then ResetDisplay(reason);return end
    local mode=Choice()
    local session=Session()
    local modeId=EnumValue("DamageMeterType",mode.enum,
        ({Dps=1,DamageDone=0,Hps=3,HealingDone=2,DamageTaken=7,Interrupts=5})[mode.enum])
    local sessionId=EnumValue("DamageMeterSessionType",session.enum,
        ({Current=1,Expired=2,Overall=0})[session.enum])
    -- The native API is readable even in combat, but can return secret fields.
    local ok,data=pcall(C_DamageMeter.GetCombatSessionFromType,sessionId,modeId)
    if not ok or type(data)~="table" then
        ResetDisplay("Waiting for Blizzard combat data...")
        return
    end
    local sources=data.combatSources
    if type(issecretvalue)=="function" and issecretvalue(sources) then
        ResetDisplay("Combat data protected: enable the Blizzard meter.")
        return
    end
    if type(sources)~="table" then ResetDisplay("No recorded data yet.");return end
    local visible=0
    for i=1,db.rows do
        local source=sources[i]
        if type(source)=="table" then
            DrawRow(rows[i],source,data.maxAmount,mode.perSecond)
            visible=visible+1
        else
            rows[i].playerName:SetText("")
            rows[i].value:SetText("")
            rows[i].marker:Hide()
            rows[i].bar:SetMinMaxValues(0,1)
            rows[i].bar:SetValue(0)
        end
    end
    if visible==0 then
        Note("No fight data yet. Attack something!")
    else
        Note("Gold stripe = you  |  Native Blizzard data")
    end
end
local function QueueRefresh()
    if refreshQueued then return end
    if not window or not db or db.shown==false then return end
    if C_Timer and type(C_Timer.After)=="function" then
        refreshQueued=true
        C_Timer.After(0.12,Refresh)
    else
        Refresh()
    end
end
local function SetShown(on)
    db.shown=on==true
    if not window then return end
    if db.shown then window:Show();QueueRefresh() else window:Hide() end
end
local function UpdateButtons()
    if not window or not db then return end
    local mode=Choice()
    local session=Session()
    meterButton:SetText(mode.label.."  >")
    sessionButton:SetText(session.label.."  >")
end
local function SetMode(value)
    local choice=Find(modes,value)
    if not choice or choice.key~=value then return false end
    db.mode=value
    UpdateButtons()
    QueueRefresh()
    return true
end
local function SetSession(value)
    local choice=Find(sessions,value)
    if not choice or choice.key~=value then return false end
    db.session=value
    UpdateButtons()
    QueueRefresh()
    return true
end
local function Next(list,key,setter)
    local _,index=Find(list,db[key])
    local choice=list[index%#list+1]
    setter(choice.key)
end
local function MakeButton(parent,title,width,offset,action)
    local button=CreateFrame("Button",nil,parent)
    button:SetSize(width,22)
    button:SetPoint("TOPRIGHT",parent,"TOPRIGHT",offset,-6)
    local bg=button:CreateTexture(nil,"BACKGROUND")
    bg:SetAllPoints(button)
    bg:SetColorTexture(0.14,0.21,0.28,0.94)
    local text=Font(button,"GameFontHighlightSmall",0.96,0.90,0.75)
    text:SetAllPoints(button)
    if text.SetJustifyH then text:SetJustifyH("CENTER") end
    function button:SetText(v) text:SetText(v) end
    button:SetText(title)
    button:SetScript("OnClick",action)
    return button
end
local function CreateWindow()
    if window or not UIParent then return end
    window=CreateFrame("Frame","ChalkBoxCombatMeterFrame",UIParent)
    window:SetFrameStrata("MEDIUM")
    window:SetMovable(true)
    if window.SetClampedToScreen then window:SetClampedToScreen(true) end
    window:EnableMouse(true)
    local bg=window:CreateTexture(nil,"BACKGROUND")
    bg:SetAllPoints(window)
    bg:SetColorTexture(0.045,0.075,0.11,0.94)
    local accent=window:CreateTexture(nil,"ARTWORK")
    accent:SetPoint("TOPLEFT",window,"TOPLEFT",0,0)
    accent:SetPoint("TOPRIGHT",window,"TOPRIGHT",0,0)
    accent:SetHeight(3)
    accent:SetColorTexture(0.96,0.67,0.27,1)
    header=CreateFrame("Frame",nil,window)
    header:SetPoint("TOPLEFT",window,"TOPLEFT",4,-4)
    header:SetPoint("TOPRIGHT",window,"TOPRIGHT",-4,-4)
    header:SetHeight(31)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart",function()
        if not db.locked then window:StartMoving() end
    end)
    header:SetScript("OnDragStop",function()
        window:StopMovingOrSizing()
        if db.locked then return end
        local x,y=window:GetCenter()
        local ux,uy=UIParent:GetCenter()
        if type(x)=="number" and type(y)=="number"
            and type(ux)=="number" and type(uy)=="number" then
            db.x,db.y=x-ux,y-uy
            db.position="custom"
        end
    end)
    local logo=Font(header,"GameFontNormal",0.96,0.74,0.34)
    logo:SetPoint("LEFT",header,"LEFT",9,0)
    logo:SetWidth(94)
    logo:SetText("CHALKBOX")
    meterButton=MakeButton(header,"DPS",67,-113,function() Next(modes,"mode",SetMode) end)
    sessionButton=MakeButton(header,"Fight",74,-35,function() Next(sessions,"session",SetSession) end)
    local close=MakeButton(header,"x",24,-7,function() SetShown(false) end)
    local footer=Font(window,"GameFontHighlightSmall",0.53,0.66,0.72)
    footer:SetPoint("BOTTOMLEFT",window,"BOTTOMLEFT",13,11)
    footer:SetPoint("BOTTOMRIGHT",window,"BOTTOMRIGHT",-12,11)
    if footer.SetJustifyH then footer:SetJustifyH("CENTER") end
    notice=footer
    for i=1,12 do rows[i]=MakeRow(i) end
    ApplyLayout()
    UpdateButtons()
    if db.shown then window:Show() else window:Hide() end
end
local function ResetNative()
    if type(InCombatLockdown)=="function" and InCombatLockdown() then
        Chat("Cannot reset damage data during combat.")
        return false
    end
    if not C_DamageMeter or type(C_DamageMeter.ResetAllCombatSessions)~="function" then
        Chat("Blizzard damage reset API unavailable.")
        return false
    end
    C_DamageMeter.ResetAllCombatSessions()
    Chat("All Blizzard damage meter sessions reset (including other meter windows).")
    QueueRefresh()
    return true
end
local function ConfirmReset()
    if not StaticPopupDialogs or type(StaticPopup_Show)~="function" then
        Chat("This also clears Blizzard's meter. Type /chalk meter reset confirm.")
        return
    end
    if not StaticPopupDialogs.CHALKBOX_METER_RESET then
        StaticPopupDialogs.CHALKBOX_METER_RESET={
            text="Reset ALL Blizzard damage meter sessions? This affects other damage meters too.",
            button1=YES or "Yes",button2=NO or "No",
            OnAccept=ResetNative,timeout=0,whileDead=true,hideOnEscape=true,
            preferredIndex=3,
        }
    end
    StaticPopup_Show("CHALKBOX_METER_RESET")
end
local function Help()
    Chat("/chalk meter [show|hide|toggle|dps|damage|hps|healing|taken|interrupts]")
    Chat("/chalk meter [current|last|overall|lock|unlock|rows 5/8/12|scale 85/100/115|reset]")
    Chat("Drag the heading to move. Mode and Fight controls cycle views. Reset also clears Blizzard's meter.")
end
function ChalkBox_MeterCommand(input)
    if not db then db=Settings() end
    if not window then CreateWindow() end
    local value=(input or ""):lower():gsub("^%s+",""):gsub("%s+$","")
    if value=="" or value=="toggle" then SetShown(not db.shown)
    elseif value=="show" or value=="on" then SetShown(true)
    elseif value=="hide" or value=="off" then SetShown(false)
    elseif value=="reset" then ConfirmReset()
    elseif value=="reset confirm" then ResetNative()
    elseif value=="help" then Help()
    elseif value=="status" then
        local enabled=IsAvailable()
        Chat("Native API: "..(enabled and "available" or "unavailable")..
            " | "..db.mode.." | "..db.session..
            " | "..db.rows.." rows | "..(db.shown and "shown" or "hidden"))
    elseif value=="lock" or value=="unlock" then
        db.locked=value=="lock"
        Chat(db.locked and "Window locked." or "Drag header to move the window.")
    elseif value=="position reset" then
        db.position=nil;db.x=nil;db.y=nil
        ApplyLayout()
    elseif value=="current" or value=="last" or value=="overall" then
        SetSession(value=="last" and "expired" or value)
    elseif value=="dps" or value=="damage" or value=="hps" or value=="healing"
        or value=="taken" or value=="interrupts" then SetMode(value)
    else
        local n=value:match("^rows (%d+)$")
        local scale=value:match("^scale (%d+)$")
        if n and (tonumber(n)==5 or tonumber(n)==8 or tonumber(n)==12) then
            db.rows=tonumber(n)
            ApplyLayout();QueueRefresh()
        elseif scale and (tonumber(scale)==85 or tonumber(scale)==100 or tonumber(scale)==115) then
            db.scale=tonumber(scale)/100
            ApplyLayout()
        else Help() end
    end
end
function ChalkBox_MeterStatus()
    if not db then db=Settings() end
    local enabled=IsAvailable()
    return {shown=db.shown,locked=db.locked,mode=db.mode,session=db.session,
        rows=db.rows,scale=db.scale,available=enabled}
end
local event=CreateFrame("Frame")
event:RegisterEvent("ADDON_LOADED")
event:RegisterEvent("PLAYER_LOGIN")
event:RegisterEvent("DAMAGE_METER_COMBAT_SESSION_UPDATED")
event:RegisterEvent("DAMAGE_METER_CURRENT_SESSION_UPDATED")
event:RegisterEvent("DAMAGE_METER_RESET")
event:SetScript("OnEvent",function(_,name,loaded)
    if name=="ADDON_LOADED" then
        if loaded~=addonName then return end
        db=Settings()
    elseif name=="PLAYER_LOGIN" then
        db=db or Settings()
        CreateWindow()
        QueueRefresh()
    elseif db and db.shown then
        QueueRefresh()
    end
end)
