-- Adventure Chronicle: notable moments from this update forward.
-- Does not rewrite ChalkBoxZoneDB.sessionJournal. Old sessions stay summaries.
local MAX_EVENTS=600
local DEDUP_SECONDS=45
local addonName=...
local window,rows,filter
local function Secret(v)
    if type(issecretvalue)=="function" and issecretvalue(v) then return true end
    return false
end
local function Num(v)
    if Secret(v) or type(v)~="number" or v~=v or v<0 or v>1e12 then return nil end
    return v
end
local function Text(v,max)
    if Secret(v) or type(v)~="string" then return nil end
    v=v:gsub("[%c|]"," "):sub(1,max or 80)
    if v=="" then return nil end
    return v
end
local function Now()
    if type(time)~="function" then return nil end
    local ok,t=pcall(time)
    return ok and Num(t) or nil
end
local function DB()
    if type(ChalkBoxZoneDB)~="table" then ChalkBoxZoneDB={} end
    local s=ChalkBoxZoneDB.adventureChronicle
    if type(s)~="table" then
        -- New ledger only. Never copy or rewrite sessionJournal history.
        s={version=1,nextId=1,enabled=true,events={}}
        ChalkBoxZoneDB.adventureChronicle=s
    end
    if s.version~=1 then return s,false end
    if type(s.events)~="table" then s.events={} end
    if type(s.nextId)~="number" or s.nextId<1 then s.nextId=#s.events+1 end
    if s.enabled==nil then s.enabled=true end
    return s,true
end
function ChalkBox_ChronicleEnabled()
    local s=DB()
    return s.enabled==true
end
function ChalkBox_ChronicleSetEnabled(on)
    local s,ok=DB()
    if not ok then return false end
    s.enabled=on==true
    return true
end
local function Recent(s,kind,key,now)
    local events=s.events
    for i=#events,math.max(1,#events-12),-1 do
        local e=events[i]
        if type(e)=="table" and e.kind==kind and e.key==key then
            if not now or not Num(e.time) or now-e.time<=DEDUP_SECONDS then
                return true
            end
        end
    end
    return false
end
local function Zone()
    local map,name
    if type(C_Map)=="table" and type(C_Map.GetBestMapForUnit)=="function" then
        local ok,id=pcall(C_Map.GetBestMapForUnit,"player")
        map=ok and Num(id) or nil
        if map and type(C_Map.GetMapInfo)=="function" then
            local infoOK,info=pcall(C_Map.GetMapInfo,map)
            if infoOK and type(info)=="table" then
                name=Text(info.name,64)
            end
        end
    end
    if not name and type(GetZoneText)=="function" then
        local ok,z=pcall(GetZoneText)
        name=ok and Text(z,64) or nil
    end
    return map,name
end
local function Add(kind,key,label,extra)
    local s,ok=DB()
    if not ok or s.enabled~=true then return false end
    local now=Now()
    if kind=="level" then
        for i=#s.events,1,-1 do
            local e=s.events[i]
            if type(e)=="table" and e.kind=="level" and e.level==extra then
                return false
            end
        end
    elseif Recent(s,kind,key,now) then
        return false
    end
    local map,zone=Zone()
    local event={
        id=s.nextId,kind=kind,key=key,time=now,label=label,
        level=kind=="level" and extra or nil,
        mapID=map,zone=zone,source=extra and kind or kind,
    }
    if kind=="quest" then event.questID=extra end
    if kind=="dungeon" then event.label=label end
    s.nextId=s.nextId+1
    s.events[#s.events+1]=event
    while #s.events>MAX_EVENTS do table.remove(s.events,1) end
    return true
end
local lastInstance
local function InstanceName()
    if type(GetInstanceInfo)~="function" then return nil end
    local ok,name,kind=pcall(GetInstanceInfo)
    if not ok or Secret(name) then return nil end
    name=Text(name,64)
    kind=Text(kind,32)
    if not name or not kind then return nil end
    if kind~="party" and kind~="scenario" then return nil end
    return name
end
local function OnEvent(_,event,arg1)
    if event=="PLAYER_LEVEL_UP" then
        local level=Num(arg1)
        if not level and type(UnitLevel)=="function" then
            local ok,v=pcall(UnitLevel,"player")
            level=ok and Num(v) or nil
        end
        if level then Add("level","level:"..level,"Reached level "..level,level) end
    elseif event=="QUEST_TURNED_IN" then
        local id=Num(arg1)
        if not id then return end
        local title
        if type(C_QuestLog)=="table" and type(C_QuestLog.GetTitleForQuestID)=="function" then
            local ok,name=pcall(C_QuestLog.GetTitleForQuestID,id)
            title=ok and Text(name,80) or nil
        end
        Add("quest","quest:"..id,title or ("Quest "..id),id)
    elseif event=="PLAYER_DEAD" then
        Add("death","death","You died")
    elseif event=="PLAYER_ENTERING_WORLD" then
        local name=InstanceName()
        if name and name~=lastInstance then
            Add("dungeon","in:"..name,"Entered "..name)
            lastInstance=name
        elseif not name and lastInstance then
            Add("dungeon","out:"..lastInstance,"Left "..lastInstance)
            lastInstance=nil
        end
    end
end
local frame=CreateFrame("Frame")
frame:SetScript("OnEvent",OnEvent)
for _,name in ipairs({"PLAYER_LEVEL_UP","QUEST_TURNED_IN","PLAYER_DEAD",
    "PLAYER_ENTERING_WORLD"}) do
    pcall(frame.RegisterEvent,frame,name)
end
function ChalkBox_ChronicleNoteLoot(counts)
    if type(counts)~="table" then return false end
    local best,bestCount
    for id,count in pairs(counts) do
        local n=tonumber(id)
        local qty=Num(count)
        if n and qty and qty>0 then
            local quality
            if C_Item and type(C_Item.GetItemInfo)=="function" then
                local ok,_, _, q=pcall(C_Item.GetItemInfo,n)
                quality=ok and Num(q) or nil
            elseif type(GetItemInfo)=="function" then
                local ok,_, _, q=pcall(GetItemInfo,n)
                quality=ok and Num(q) or nil
            end
            if quality and quality>=3 and (not bestCount or qty>bestCount) then
                best,bestCount=n,qty
            end
        end
    end
    if not best then return false end
    return Add("loot","loot:"..best,"Notable drop #"..best.." x"..bestCount)
end
function ChalkBox_ChronicleClear()
    local s,ok=DB()
    if not ok then return false end
    s.events={}
    s.nextId=1
    return true
end
local function Copy(e)
    local out={}
    for k,v in pairs(e) do
        if type(v)~="table" then out[k]=v end
    end
    return out
end
function ChalkBox_ChronicleEvents(which,limit)
    local s=DB()
    local events=type(s.events)=="table" and s.events or {}
    limit=Num(limit) and math.min(limit,80) or 40
    local now=Now()
    local list={}
    for i=#events,1,-1 do
        local e=events[i]
        if type(e)=="table" then
            local keep=true
            if which=="today" and now and Num(e.time) then
                keep=now-e.time<24*3600
            elseif which=="today" and not Num(e.time) then
                keep=i>#events-15
            end
            if keep then list[#list+1]=Copy(e) end
            if #list>=limit then break end
        end
    end
    return {enabled=s.enabled==true,count=#events,events=list,
        version=s.version}
end
local function Line(e)
    local when="time unknown"
    if Num(e.time) and type(date)=="function" then
        local ok,text=pcall(date,"%m-%d %H:%M",e.time)
        if ok and type(text)=="string" then when=text end
    end
    local where=e.zone and (" · "..e.zone) or ""
    return when.."  "..(e.label or e.kind or "Event")..where
end
local function Paint()
    if not window then return end
    local snap=ChalkBox_ChronicleEvents(filter or "timeline",12)
    local title=filter=="today" and "TODAY" or
        (filter=="history" and "HISTORY" or "TIMELINE")
    if window.section and window.section.SetText then
        window.section:SetText(title)
    end
    local lines={}
    if snap.version~=1 then
        lines[1]="This chronicle save is from a newer ChalkBox. It was left unread."
    elseif not snap.enabled then
        lines[1]="Recording is off. Older events are still here."
    elseif #snap.events==0 then
        lines[1]="No events yet. New moments are recorded from now on."
        lines[2]="Older session summaries were not rewritten."
    else
        for i,e in ipairs(snap.events) do lines[i]=Line(e) end
    end
    for i,row in ipairs(rows) do
        row:SetText(lines[i] or "")
    end
end
local function ChroniclePlace()
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    if type(ChalkBoxDB.chroniclePlace)~="table" then ChalkBoxDB.chroniclePlace={} end
    return ChalkBoxDB.chroniclePlace
end
local function SaveChroniclePlace()
    if not window or not window.GetCenter or not UIParent or not UIParent.GetCenter then
        return
    end
    local x,y=window:GetCenter()
    local ux,uy=UIParent:GetCenter()
    if type(x)=="number" and type(y)=="number"
        and type(ux)=="number" and type(uy)=="number" then
        local box=ChroniclePlace()
        box.x,box.y=math.floor(x-ux),math.floor(y-uy)
    end
end
function ChalkBox_OpenChronicle(which)
    filter=which=="today" and "today" or (which=="history" and "history" or "timeline")
    if not UIParent or type(CreateFrame)~="function" then return false end
    if not window then
        local template=type(BackdropTemplateMixin)=="table" and "BackdropTemplate" or nil
        window=CreateFrame("Frame","ChalkBoxChronicleFrame",UIParent,template)
        if not window or type(window.SetSize)~="function" then
            window=nil
            return false
        end
        window:SetSize(520,360)
        local box=ChroniclePlace()
        window:SetPoint("CENTER",UIParent,"CENTER",box.x or 40,box.y or 40)
        if window.SetFrameStrata then window:SetFrameStrata("DIALOG") end
        if window.SetMovable then window:SetMovable(true) end
        if window.EnableMouse then window:EnableMouse(true) end
        if window.RegisterForDrag then window:RegisterForDrag("LeftButton") end
        if type(window.SetBackdrop)=="function" then
            window:SetBackdrop({
                bgFile="Interface\\Buttons\\WHITE8X8",
                edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
                tile=true,tileSize=32,edgeSize=24,
                insets={left=8,right=8,top=8,bottom=8},
            })
            if window.SetBackdropColor then window:SetBackdropColor(0.018,0.018,0.022,0.96) end
            if window.SetBackdropBorderColor then
                window:SetBackdropBorderColor(0.86,0.66,0.38,1)
            end
        end
        local stripe=window:CreateTexture(nil,"ARTWORK")
        if stripe.SetPoint then stripe:SetPoint("TOPLEFT",window,"TOPLEFT",13,-44) end
        if stripe.SetSize then stripe:SetSize(400,2) end
        if stripe.SetColorTexture then stripe:SetColorTexture(0.63,0.44,0.22,0.95) end
        window.title=window:CreateFontString(nil,"OVERLAY","GameFontNormalHuge")
        window.title:SetPoint("TOPLEFT",window,"TOPLEFT",22,-16)
        window.title:SetText("CHALKBOX  /  ADVENTURE CHRONICLE")
        window.section=window:CreateFontString(nil,"OVERLAY","GameFontNormal")
        window.section:SetPoint("TOPLEFT",window,"TOPLEFT",27,-52)
        window.section:SetText("TIMELINE")
        window:SetScript("OnDragStart",function(self)
            if self.StartMoving and (type(InCombatLockdown)~="function"
                or not InCombatLockdown()) then self:StartMoving() end
        end)
        window:SetScript("OnDragStop",function(self)
            if self.StopMovingOrSizing then self:StopMovingOrSizing() end
            SaveChroniclePlace()
        end)
        rows={}
        for i=1,12 do
            local row=window:CreateFontString(nil,"OVERLAY","GameFontHighlight")
            row:SetPoint("TOPLEFT",window,"TOPLEFT",27,-76-(i-1)*18)
            row:SetWidth(470)
            row:SetJustifyH("LEFT")
            rows[i]=row
        end
        local function Tab(text,x,mode)
            local b=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
            b:SetSize(100,26)
            b:SetPoint("BOTTOMLEFT",window,"BOTTOMLEFT",x,14)
            b:SetText(text)
            b:SetScript("OnClick",function()
                filter=mode
                Paint()
            end)
        end
        Tab("Today",16,"today")
        Tab("Timeline",124,"timeline")
        Tab("History",232,"history")
        local close=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
        close:SetSize(100,26)
        close:SetPoint("BOTTOMRIGHT",window,"BOTTOMRIGHT",-16,14)
        close:SetText("Close")
        close:SetScript("OnClick",function() window:Hide() end)
    end
    Paint()
    if type(UISpecialFrames)=="table" and window.GetName then
        local name=window:GetName()
        local listed=false
        if type(name)=="string" then
            for _,entry in ipairs(UISpecialFrames) do
                if entry==name then listed=true end
            end
            if not listed then UISpecialFrames[#UISpecialFrames+1]=name end
        end
    end
    window:Show()
    return true
end
function ChalkBox_ChronicleCommand(text)
    text=(text or ""):lower():match("^%s*(.-)%s*$") or ""
    if text=="off" then
        ChalkBox_ChronicleSetEnabled(false)
    elseif text=="on" then
        ChalkBox_ChronicleSetEnabled(true)
    elseif text=="clear confirm" then
        ChalkBox_ChronicleClear()
    elseif text=="today" or text=="timeline" or text=="history" or text=="" then
        ChalkBox_OpenChronicle(text=="" and "timeline" or text)
    end
    return true
end
