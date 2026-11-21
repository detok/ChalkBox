-- Optional compact meter. Blizzard's native combat data remains authoritative.
-- No COMBAT_LOG_EVENT_UNFILTERED, GUID parsing, pet attribution guesses, or
-- calculations on secret combat data. Use Blizzard's C_DamageMeter directly.
local addonName=...
local db,window,header,notice,opacitySlider,lockButton,resizeHandle
local rows={}
local refreshQueued=false
local refreshElapsed=0
local lastDisplayError=nil
local feedState={source="none",reason="idle"}
local LIVE_REFRESH_SECONDS=0.75
local function RememberFeed(source,reason)
    feedState={source=source or "none",reason=reason or "unknown"}
end
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
local meterTitle
local function Safe(v)
    -- Inspect the secrecy of a value before asking Lua to evaluate it at all.
    return (type(issecretvalue)~="function" or not issecretvalue(v)) and v~=nil
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
    if value.shown==nil then value.shown=false end
    if value.locked==nil then value.locked=false end
    if value.mode==nil then value.mode="dps" end
    if value.session==nil then value.session="current" end
    if type(value.rows)~="number" or value.rows~=value.rows or
        value.rows<5 or value.rows>12 then value.rows=5 end
    -- A manual resize may select 6, 7, 9, 10 or 11 rows; preserve it.
    value.rows=math.floor(value.rows+0.5)
    if value.scale~=0.85 and value.scale~=1 and value.scale~=1.15 then value.scale=1 end
    if type(value.width)~="number" or value.width<300 or value.width>600 then value.width=326 end
    -- Same as The Bar: opacity controls background surfaces, not names,
    -- numbers, class badges or bar values. Preserve saved values on upgrade.
    if type(value.opacity)~="number" or value.opacity<0 or value.opacity>1 then value.opacity=0.70 end
    if value.iconMode~="off" and value.iconMode~="class" and value.iconMode~="spec" then
        value.iconMode="class"
    end
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
local function Clamp(v,low,high)
    return math.min(high,math.max(low,v))
end
-- Mirror The Bar: tint only ChalkBox surfaces and multiply the local
-- background transparency by the global theme opacity. Never fade the
-- entire meter, player names, combat numbers or class icons.
local function ApplyMeterTheme()
    if not window then return end
    local surfaceAlpha=db and db.opacity or 0.70
    local r,g,b,a=0.045,0.075,0.11,surfaceAlpha
    if type(ChalkBox_ThemeBackground)=="function" then
        r,g,b,a=ChalkBox_ThemeBackground(surfaceAlpha)
    end
    if window.background then
        window.background:SetColorTexture(r,g,b,a)
    end
    for i,entry in ipairs(rows) do
        if entry.background then
            entry.background:SetColorTexture(
                math.min(1,r*2+0.035),math.min(1,g*2+0.035),
                math.min(1,b*2+0.04),a*(i%2==0 and 0.80 or 0.66))
        end
    end
    for _,button in ipairs(window.themeButtons or {}) do
        if button.background then
            button.background:SetColorTexture(
                math.min(1,r*2+0.08),math.min(1,g*2+0.08),
                math.min(1,b*2+0.08),a*0.94)
        end
    end
    local ar,ag,ab=0.96,0.67,0.27
    if type(ChalkBox_ThemeAccent)=="function" then
        ar,ag,ab=ChalkBox_ThemeAccent()
    end
    if window.accent then window.accent:SetColorTexture(ar,ag,ab,1) end
end
function ChalkBox_MeterThemeRefresh() ApplyMeterTheme() end
local function ApplyOpacity()
    if window and window.SetAlpha then window:SetAlpha(1) end
    ApplyMeterTheme()
end
local function ApplyLocked()
    if lockButton and db then
        lockButton:SetText(db.locked and "UNLOCK" or "LOCK")
    end
end
local function ApplyLayout()
    if not window or not db then return end
    window:SetScale(db.scale)
    window:SetSize(db.width,66+db.rows*25)
    ApplyOpacity()
    ApplyLocked()
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
local function SaveResizedWindow()
    if not window or not db or db.locked then return end
    if type(window.GetWidth)~="function" or type(window.GetHeight)~="function" then return end
    local width,height=window:GetWidth(),window:GetHeight()
    if type(width)~="number" or type(height)~="number" then return end
    db.width=Clamp(math.floor(width+0.5),300,600)
    db.rows=Clamp(math.floor((height-66)/25+0.5),5,12)
    ApplyLayout()
end
-- WoW's original nine class badges are stored together in the client UI
-- texture atlas. Coordinates match Blizzard's CLASS_ICON_TCOORDS; keep this
-- fallback because the global table isn't present in every Forever build.
-- Texture files and numeric specIconID values come from the CLIENT itself.
local CLASS_ICON_TEXTURE="Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
local UNKNOWN_ICON_TEXTURE="Interface\\Icons\\INV_Misc_QuestionMark"
local CLASS_ICON_FALLBACK={
    WARRIOR={0,0.25,0,0.25},
    MAGE={0.25,0.49609375,0,0.25},
    ROGUE={0.49609375,0.7421875,0,0.25},
    DRUID={0.7421875,0.98828125,0,0.25},
    HUNTER={0,0.25,0.25,0.5},
    SHAMAN={0.25,0.49609375,0.25,0.5},
    PRIEST={0.49609375,0.7421875,0.25,0.5},
    WARLOCK={0.7421875,0.98828125,0.25,0.5},
    PALADIN={0,0.25,0.5,0.75},
}
local function DisplayClassIcon(row,source)
    local icon=row.classIcon
    if db.iconMode=="off" then
        icon:Hide()
        return
    end
    local specID=source.specIconID
    if db.iconMode=="spec" and Safe(specID) and
        type(specID)=="number" and specID>0 then
        icon:SetTexture(specID)
        icon:SetTexCoord(0.08,0.92,0.08,0.92)
        icon:Show()
        return
    end
    local class=Safe(source.classFilename) and source.classFilename or nil
    local coords=type(class)=="string" and
        ((type(CLASS_ICON_TCOORDS)=="table" and CLASS_ICON_TCOORDS[class]) or
            CLASS_ICON_FALLBACK[class]) or nil
    if coords and type(coords)=="table" then
        icon:SetTexture(CLASS_ICON_TEXTURE)
        icon:SetTexCoord(coords[1],coords[2],coords[3],coords[4])
    else
        -- Never identify a pet/unknown source as a player class.
        icon:SetTexture(UNKNOWN_ICON_TEXTURE)
        icon:SetTexCoord(0.08,0.92,0.08,0.92)
    end
    icon:Show()
end
local function ArrangeRowName(row)
    if not db then return end
    local off=db.iconMode=="off"
    if row.playerName.ClearAllPoints then row.playerName:ClearAllPoints() end
    row.playerName:SetPoint("LEFT",row.frame,"LEFT",off and 27 or 49,0)
    row.playerName:SetWidth(off and 142 or 120)
    if off then row.classIcon:Hide() end
end
local function MakeRow(i)
    local frame=CreateFrame("Frame",nil,window)
    frame:SetHeight(23)
    frame:SetPoint("TOPLEFT",window,"TOPLEFT",11,-39-(i-1)*25)
    frame:SetPoint("TOPRIGHT",window,"TOPRIGHT",-11,-39-(i-1)*25)
    local bg=frame:CreateTexture(nil,"BACKGROUND")
    bg:SetAllPoints(frame)
    frame.background=bg
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
    local classIcon=frame:CreateTexture(nil,"ARTWORK")
    classIcon:SetSize(18,18)
    classIcon.isChalkBoxClassIcon=true
    classIcon:SetPoint("LEFT",frame,"LEFT",27,0)
    classIcon:SetTexture(UNKNOWN_ICON_TEXTURE)
    classIcon:SetTexCoord(0.08,0.92,0.08,0.92)
    local name=Font(frame,"GameFontHighlightSmall",0.98,0.98,0.99)
    name:SetPoint("LEFT",frame,"LEFT",49,0)
    name:SetWidth(120)
    if name.SetJustifyH then name:SetJustifyH("LEFT") end
    local value=Font(frame,"GameFontHighlightSmall",1,0.94,0.77)
    value:SetPoint("RIGHT",frame,"RIGHT",-7,0)
    value:SetWidth(104)
    if value.SetJustifyH then value:SetJustifyH("RIGHT") end
    frame.bar=bar
    frame.marker=marker
    frame.classIcon=classIcon
    frame.playerName=name
    frame.frame=frame
    ArrangeRowName(frame)
    frame.value=value
    return frame
end
-- Never leave old damage figures beside a cleared player name. This is
-- particularly important when a player drops off the native leaderboard.
local function ClearRow(row)
    row.playerName:SetText("")
    row.value:SetText("")
    row.classIcon:Hide()
    row.marker:Hide()
    row.bar:SetMinMaxValues(0,1)
    row.bar:SetValue(0)
    row.bar:SetStatusBarColor(0.27,0.60,0.78,0.50)
end
local function ResetDisplay(message)
    for _,row in ipairs(rows) do pcall(ClearRow,row) end
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
    DisplayClassIcon(row,source)
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
    -- Forever may return a secret boolean. Never compare it in Lua.
    local localPlayer=source.isLocalPlayer
    if Safe(localPlayer) and localPlayer==true then
        row.marker:Show()
    else
        row.marker:Hide()
    end
    local amount=perSecond and source.amountPerSecond or source.totalAmount
    if Safe(maxValue) and type(maxValue)=="number" and maxValue<=0 then
        maxValue=1
    end
    -- Never compare a potentially secret number with nil in Lua. The built-in
    -- SetMinMaxValues / SetValue / SetFormattedText methods take the data directly.
    local secretMax=type(issecretvalue)=="function" and issecretvalue(maxValue)
    local secretAmount=type(issecretvalue)=="function" and issecretvalue(amount)
    if secretMax or maxValue~=nil then
        row.bar:SetMinMaxValues(0,maxValue)
    else
        row.bar:SetMinMaxValues(0,1)
    end
    if secretAmount or amount~=nil then
        row.bar:SetValue(amount)
        DisplayValue(row.value,amount)
    else
        row.bar:SetValue(0)
        row.value:SetText("--")
    end
end
local function Refresh()
    refreshQueued=false
    lastDisplayError=nil
    if not window or not db or db.shown==false or not window:IsShown() then return end
    local available,reason=IsAvailable()
    if not available then
        RememberFeed("none", reason and reason:find("this client",1,true)
            and "api-missing" or "unavailable")
        ResetDisplay(reason)
        return
    end
    local mode=Choice()
    local session=Session()
    local modeId=EnumValue("DamageMeterType",mode.enum,
        ({Dps=1,DamageDone=0,Hps=3,HealingDone=2,DamageTaken=7,Interrupts=5})[mode.enum])
    local sessionId=EnumValue("DamageMeterSessionType",session.enum,
        ({Current=1,Expired=2,Overall=0})[session.enum])
    -- The native API is readable even in combat, but can return secret fields.
    local ok,data=pcall(C_DamageMeter.GetCombatSessionFromType,sessionId,modeId)
    if not ok or not Safe(data) or type(data)~="table" then
        RememberFeed("blizzard","unreadable")
        ResetDisplay("Waiting for Blizzard combat data...")
        return
    end
    local sources=data.combatSources
    if not Safe(sources) or type(sources)~="table" then
        RememberFeed("blizzard","protected")
        ResetDisplay("Native combat sources unavailable or protected.")
        return
    end
    local usingLast=false
    if session.key=="current" and #sources==0 then
        -- Blizzard may close Current as soon as the fight ends. The
        -- compact window should behave like our report sender and show
        -- the most recently completed fight rather than a blank panel.
        local expiredID=EnumValue("DamageMeterSessionType","Expired",2)
        local savedOK,saved=pcall(C_DamageMeter.GetCombatSessionFromType,
            expiredID,modeId)
        if savedOK and Safe(saved) and type(saved)=="table" and
            Safe(saved.combatSources) and
            type(saved.combatSources)=="table" and
            #saved.combatSources>0 then
            data,sources=saved,saved.combatSources
            usingLast=true
        end
    end
    if meterTitle then
        meterTitle:SetText(mode.label.."  /  "..(usingLast and "Last" or session.label))
    end
    local visible,unreadable=0,false
    for i=1,db.rows do
        local source=sources[i]
        if Safe(source) and type(source)=="table" then
            -- A single inconsistent native row must not blank the whole
            -- meter or throw an error from an input/click handler.
            local drawn,detail=pcall(DrawRow,rows[i],source,data.maxAmount,
                mode.perSecond)
            if drawn then
                visible=visible+1
            else
                unreadable=true
                if not lastDisplayError then
                    lastDisplayError=tostring(detail):sub(1,180)
                end
                pcall(ClearRow,rows[i])
            end
        else
            pcall(ClearRow,rows[i])
        end
    end
    -- Treat saved rows as a maximum, not permanent blank slots.
    -- Always retain one row of space for the empty-session message.
    local shown=math.max(1,math.min(db.rows,visible))
    for i,row in ipairs(rows) do
        if i<=shown then row:Show() else row:Hide() end
    end
    if window.SetHeight then window:SetHeight(66+shown*25) end
    local auto=type(ChalkBox_NativeMeterStatus)=="function" and
        ChalkBox_NativeMeterStatus() or nil
    if auto and auto.ready then
        RememberFeed("blizzard", visible>0 and "showing" or "empty")
        Note("Report ready  ·  Menu > Send ready to "..(
            auto.readyChannel or "PARTY"))
    elseif visible==0 then
        RememberFeed("blizzard","empty")
        Note(unreadable and "Combat data unavailable on this client."
            or "No fight data yet. Attack something!")
    else
        RememberFeed("blizzard", unreadable and "partial" or "showing")
        Note(unreadable and "Some native combat rows could not be displayed." or "")
    end
end
-- An unexpected native API response should be diagnosable rather than
-- breaking the next menu click or leaving stale numbers in the window.
local function SafeRefresh()
    local ok,reason=pcall(Refresh)
    if not ok then
        lastDisplayError=tostring(reason):sub(1,180)
        ResetDisplay("Meter display issue. Use /chalk meter status.")
    end
end
local function QueueRefresh()
    if refreshQueued then return end
    if not window or not db or db.shown==false then return end
    if C_Timer and type(C_Timer.After)=="function" then
        refreshQueued=true
        C_Timer.After(0.12,SafeRefresh)
    else
        SafeRefresh()
    end
end
local function SetShown(on)
    db.shown=on==true
    refreshElapsed=0
    if not window then return end
    if db.shown then window:Show();QueueRefresh() else window:Hide() end
end
local function UpdateButtons()
    if not window or not db or not meterTitle then return end
    local mode=Choice()
    local session=Session()
    meterTitle:SetText(mode.label.."  /  "..session.label)
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
    button.background=bg
    bg:SetColorTexture(0.14,0.21,0.28,0.94)
    if window then
        window.themeButtons=window.themeButtons or {}
        window.themeButtons[#window.themeButtons+1]=button
    end
    local text=Font(button,"GameFontHighlightSmall",0.96,0.90,0.75)
    text:SetAllPoints(button)
    if text.SetJustifyH then text:SetJustifyH("CENTER") end
    function button:SetText(v)
        self.caption=v
        text:SetText(v)
    end
    button:SetText(title)
    button:SetScript("OnClick",action)
    return button
end
-- Reporting retired: silent, side-effect-free compatibility entry points.
function ChalkBox_MeterPrintFight() return false end
function ChalkBox_MeterReportAdapter() return nil end
function ChalkBox_MeterReportSelected() return false end

local function CreateWindow()
    if window or not UIParent then return end
    window=CreateFrame("Frame","ChalkBoxCombatMeterFrame",UIParent)
    window:SetFrameStrata("MEDIUM")
    window:SetMovable(true)
    if window.SetResizable then window:SetResizable(true) end
    if window.SetResizeBounds then
        window:SetResizeBounds(300,66+1*25,600,66+12*25)
    elseif window.SetMinResize and window.SetMaxResize then
        window:SetMinResize(300,66+1*25)
        window:SetMaxResize(600,66+12*25)
    end
    if window.SetClampedToScreen then window:SetClampedToScreen(true) end
    window:EnableMouse(true)
    local bg=window:CreateTexture(nil,"BACKGROUND")
    bg:SetAllPoints(window)
    window.background=bg
    bg:SetColorTexture(0.045,0.075,0.11,0.94)
    local accent=window:CreateTexture(nil,"ARTWORK")
    accent:SetPoint("TOPLEFT",window,"TOPLEFT",0,0)
    accent:SetPoint("TOPRIGHT",window,"TOPRIGHT",0,0)
    accent:SetHeight(2)
    window.accent=accent
    accent:SetColorTexture(0.96,0.67,0.27,1)
    ApplyMeterTheme()

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
    -- Bar-style compact header. Both gear and right-click use the same
    -- menu; all existing actions remain accessible from that menu.
    meterTitle=Font(header,"GameFontHighlightSmall",1,0.91,0.72)
    meterTitle:SetPoint("LEFT",header,"LEFT",10,0)
    meterTitle:SetWidth(210)
    header:SetScript("OnMouseUp",function(self,button)
        if button=="RightButton" and
            type(ChalkBox_MeterOpenMenu)=="function" then
            ChalkBox_MeterOpenMenu(self)
        end
    end)
    MakeButton(header,"Menu",56,-3,function()
        if type(ChalkBox_MeterOpenMenu)=="function" then
            ChalkBox_MeterOpenMenu(header)
        end
    end)

    notice=Font(window,"GameFontHighlightSmall",0.62,0.70,0.77)
    notice:SetPoint("TOPLEFT",window,"TOPLEFT",28,-67)
    notice:SetPoint("TOPRIGHT",window,"TOPRIGHT",-20,-67)
    if notice.SetJustifyH then notice:SetJustifyH("CENTER") end
    notice:SetText("")

    for i=1,12 do rows[i]=MakeRow(i) end

    local opacityLabel=Font(window,"GameFontHighlightSmall",0.65,0.76,0.85)
    opacityLabel:SetPoint("BOTTOMLEFT",window,"BOTTOMLEFT",12,8)
    opacityLabel:SetText("Background")
    opacitySlider=CreateFrame("Slider",nil,window,"OptionsSliderTemplate")
    opacitySlider:SetSize(120,12)
    opacitySlider:SetPoint("BOTTOMLEFT",window,"BOTTOMLEFT",65,8)
    opacitySlider:SetMinMaxValues(0,100)
    if opacitySlider.SetValueStep then opacitySlider:SetValueStep(5) end
    opacitySlider:SetScript("OnValueChanged",function(_,amount)
        if db and type(amount)=="number" then
            db.opacity=Clamp(math.floor(amount+0.5),0,100)/100
            ApplyOpacity()
        end
    end)
    opacitySlider:SetValue(math.floor(db.opacity*100+0.5))

    resizeHandle=CreateFrame("Button",nil,window)
    resizeHandle.isChalkBoxResizeGrip=true
    resizeHandle:SetSize(20,20)
    resizeHandle:SetPoint("BOTTOMRIGHT",window,"BOTTOMRIGHT",-2,2)
    resizeHandle:EnableMouse(true)
    for i=1,3 do
        local stripe=resizeHandle:CreateTexture(nil,"OVERLAY")
        stripe:SetSize(2+i*3,1)
        stripe:SetPoint("BOTTOMRIGHT",resizeHandle,"BOTTOMRIGHT",-2,-2-i*4)
        stripe:SetColorTexture(0.75,0.77,0.79,0.78)
    end
    resizeHandle:SetScript("OnMouseDown",function(_,button)
        if button=="LeftButton" and not db.locked and window.StartSizing then
            window:StartSizing("BOTTOMRIGHT")
        end
    end)
    resizeHandle:SetScript("OnMouseUp",function()
        window:StopMovingOrSizing()
        SaveResizedWindow()
    end)

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
    Chat("/chalk meter [current|last|overall|print|lock|unlock|icons class/spec/off|rows 5/8/12|opacity 0-100|reset]")
    Chat("Combat meter is a local display. RESET asks before clearing Blizzard sessions.")
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
    elseif value=="print" or value=="print local" or
        value=="print party" or value=="print say" or
        value=="party" or value=="say" or
        value:match("^native%s+") then
        return false -- historical reporter commands are silent and inert
    elseif value=="help" then Help()
    elseif value=="status" then
        local enabled=IsAvailable()
        Chat("Native API: "..(enabled and "available" or "unavailable")..
            " | feed "..feedState.source.." ("..feedState.reason..")"..
            " | "..db.mode.." | "..db.session..
            " | "..db.rows.." rows | "..db.iconMode.." icons | "..math.floor(db.opacity*100)..
            "% background | "..(db.locked and "locked" or "unlocked")..
            " | "..(db.shown and "shown" or "hidden"))
        if lastDisplayError then Chat("Last meter error: "..lastDisplayError) end
    elseif value=="icons class" or value=="icons spec" or value=="icons off" then
        db.iconMode=value:match("icons (%w+)")
        for _,row in ipairs(rows) do ArrangeRowName(row) end
        QueueRefresh()
    elseif value=="lock" or value=="unlock" then
        db.locked=value=="lock"
        ApplyLocked()
        Chat(db.locked and "Meter locked in place." or "Meter unlocked: drag the header or resize grip.")
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
        local opacity=value:match("^opacity (%d+)$")
        if opacity and tonumber(opacity)>=0 and tonumber(opacity)<=100 then
            db.opacity=math.floor(tonumber(opacity)+0.5)/100
            if opacitySlider then opacitySlider:SetValue(db.opacity*100) end
            ApplyOpacity()
        elseif n and (tonumber(n)==5 or tonumber(n)==8 or tonumber(n)==12) then
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
        rows=db.rows,scale=db.scale,opacity=db.opacity,width=db.width,
        iconMode=db.iconMode,displayError=lastDisplayError,
        available=enabled,feed=feedState.source,reason=feedState.reason}
end
local event=CreateFrame("Frame")
event:RegisterEvent("ADDON_LOADED")
event:RegisterEvent("PLAYER_LOGIN")
event:RegisterEvent("DAMAGE_METER_COMBAT_SESSION_UPDATED")
event:RegisterEvent("DAMAGE_METER_CURRENT_SESSION_UPDATED")
event:RegisterEvent("DAMAGE_METER_RESET")
-- Server-side damage updates should normally arrive via events. A small
-- visible-only heartbeat heals missed events on Forever; hidden meters
-- remain completely idle and no combat-log parsing is introduced.
event:SetScript("OnUpdate",function(_,elapsed)
    if not db or db.shown==false or not window or
        not window:IsShown() then
        refreshElapsed=0
        return
    end
    if type(elapsed)~="number" or elapsed~=elapsed or elapsed<0 then return end
    refreshElapsed=refreshElapsed+elapsed
    if refreshElapsed>=LIVE_REFRESH_SECONDS then
        refreshElapsed=refreshElapsed%LIVE_REFRESH_SECONDS
        if not refreshQueued then SafeRefresh() end
    end
end)
event:SetScript("OnEvent",function(_,name,loaded)
    if name=="ADDON_LOADED" then
        if loaded~=addonName then return end
        db=Settings()
    elseif name=="PLAYER_LOGIN" then
        db=db or Settings()
        -- The compact meter is a tool, not a startup HUD. Always begin
        -- hidden, even if it was open when this character last logged out.
        -- Showing it again is an explicit settings, slash or UI action.
        db.shown=false
        CreateWindow()
        if window then window:Hide() end
    elseif db and db.shown then
        QueueRefresh()
    end
end)
