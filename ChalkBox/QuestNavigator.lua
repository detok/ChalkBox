-- ChalkBox QuestSense Navigation: an optional, self-contained quest arrow.
-- Reads only accepted quest waypoints. Never edits watches, super-tracking,
-- Blizzard map pins or secure combat state. No copied TomTom code/data.
local addonName=...
local frame,chosen,reason,options,refreshTimer=nil,nil,"Navigation off",{},0
local target
local function Public(v)
    return v~=nil and (type(issecretvalue)~="function" or
        not issecretvalue(v))
end
local function Number(v)
    return Public(v) and type(v)=="number" and v==v and
        v>-1e12 and v<1e12
end
local function ID(v)
    return Number(v) and v>0 and v%1==0
end
local function XY(v)
    if not Public(v) or (type(v)~="table" and type(v)~="userdata") then
        return nil
    end
    local ok,x,y=pcall(function()
        if type(v.GetXY)=="function" then return v:GetXY() end
        return v.x,v.y
    end)
    if ok and Number(x) and Number(y) then return x,y end
end
local function Call(fn,...)
    if type(fn)~="function" then return nil end
    local ok,a,b,c=pcall(fn,...)
    if ok and Public(a) then return a,b,c end
end
local function DB()
    if type(ChalkBoxZoneDB)~="table" then return nil end
    local saved=ChalkBoxZoneDB.questNavigator
    if type(saved)~="table" then
        saved={enabled=false,locked=false}
        ChalkBoxZoneDB.questNavigator=saved
    end
    if saved.enabled~=true then saved.enabled=false end
    if saved.locked~=true then saved.locked=false end
    if not ID(saved.questID) then saved.questID=nil end
    if not Number(saved.offsetX) or not Number(saved.offsetY)
        or math.abs(saved.offsetX)>1500 or math.abs(saved.offsetY)>1000 then
        saved.offsetX=nil;saved.offsetY=nil
    end
    return saved
end
local function Message(v)
    if DEFAULT_CHAT_FRAME and
        type(DEFAULT_CHAT_FRAME.AddMessage)=="function" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff55ccaaChalkBox Navigation|r "..v)
    end
end
local function Instance()
    if type(IsInInstance)~="function" then return false end
    local ok,inside=pcall(IsInInstance)
    -- A protected or unreadable result must not authorize a compass.
    return not ok or not Public(inside) or inside==true
end
local function Map()
    local m=Call(C_Map and C_Map.GetBestMapForUnit,"player")
    return ID(m) and m or nil
end
local function MapPoint(mapID,x,y)
    if not ID(mapID) or not Number(x) or not Number(y) or
        x<0 or x>1 or y<0 or y>1 or (x==0 and y==0) then
        return nil
    end
    return {mapID=mapID,x=x,y=y}
end
local function QuestPoint(id,playerMap)
    -- Prefer Blizzard's explicit *next* waypoint: it may include the
    -- intermediate travel stop rather than the final quest objective.
    local m,x,y=Call(C_QuestLog and C_QuestLog.GetNextWaypoint,id)
    local p=MapPoint(m,x,y)
    if p then return p end
    -- Only a real POI returned on the player's map (or its zone parent)
    -- counts as a fallback. Never guess coordinates from a quest title.
    local seen={}
    local mapID=playerMap
    for _=1,4 do
        if not ID(mapID) or seen[mapID] then break end
        seen[mapID]=true
        local list=Call(C_QuestLog and C_QuestLog.GetQuestsOnMap,mapID)
        if type(list)=="table" then
            for _,entry in ipairs(list) do
                if type(entry)=="table" and ID(entry.questID)
                    and entry.questID==id then
                    p=MapPoint(ID(entry.mapID) and entry.mapID or mapID,
                        entry.x,entry.y)
                    if p then return p end
                end
            end
        end
        local info=Call(C_Map and C_Map.GetMapInfo,mapID)
        if type(info)~="table" or not ID(info.parentMapID) or
            info.mapType==2 or info.mapType==1 then break end
        mapID=info.parentMapID
    end
end
local function World(mapID,x,y)
    if type(C_Map)~="table" then return nil end
    local ok,continent,pos=pcall(C_Map.GetWorldPosFromMapPos,
        mapID,{x=x,y=y})
    -- C_Map uses world instance 0 for Eastern Kingdoms; this is valid.
    if not ok or not Number(continent) or continent<0 or
        continent%1~=0 then return nil end
    local xx,yy=XY(pos)
    if xx then return continent,xx,yy end
end
local function PlayerPosition()
    if Instance() then return nil,"No GPS inside instances" end
    local mapID=Map()
    if not mapID then return nil,"Player map unavailable" end
    local pos=Call(C_Map and C_Map.GetPlayerMapPosition,mapID,"player")
    local x,y=XY(pos)
    if not x or x<0 or x>1 or y<0 or y>1 then
        return nil,"Player position unavailable"
    end
    local continent,xx,yy=World(mapID,x,y)
    if not continent then return nil,"World coordinates unavailable" end
    local facing=Call(GetPlayerFacing)
    if not Number(facing) or facing<0 or facing>math.pi*2+0.01 then
        return nil,"Facing unavailable"
    end
    return {mapID=mapID,continent=continent,x=xx,y=yy,
        facing=facing}
end
local function Distance(point,player)
    if not point or not player then return nil end
    local continent,x,y=World(point.mapID,point.x,point.y)
    if continent~=player.continent or not x then return nil end
    local dx,dy=x-player.x,y-player.y
    local distance=math.sqrt(dx*dx+dy*dy)
    if not Number(distance) then return nil end
    return distance,dx,dy
end
local function Accepted()
    local n=Call(C_QuestLog and C_QuestLog.GetNumQuestLogEntries)
    if not Number(n) or n<0 or n>1000 then return nil end
    local result={}
    local mapID=Map()
    for i=1,math.min(n,600) do
        local q=Call(C_QuestLog and C_QuestLog.GetInfo,i)
        if type(q)=="table" and q.isHeader~=true and
            q.isHidden~=true and q.isInternalOnly~=true
            and ID(q.questID) then
            local point=QuestPoint(q.questID,mapID)
            local name=Public(q.title) and type(q.title)=="string"
                and q.title or ("Quest #"..q.questID)
            name=name:sub(1,90)
            result[#result+1]={id=q.questID,name=name,
                point=point,index=i}
        end
    end
    return result
end
local function Refresh()
    local db=DB()
    if not db or not db.enabled then
        target=nil;reason="Navigation off"
        if frame then frame:Hide() end
        return
    end
    local accepted=Accepted()
    if not accepted then
        target=nil;options={}
        reason="Quest log loading"
        if frame then frame:Show() end
        return
    end
    options=accepted
    local manual
    if db.questID then
        for _,q in ipairs(options) do
            if q.id==db.questID then manual=q;break end
        end
        if not manual then db.questID=nil end
    end
    local player,why=PlayerPosition()
    local super=Call(C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID)
    local preferred
    local nearest,nearestDistance
    for _,q in ipairs(options) do
        if q.point then
            if ID(super) and q.id==super then preferred=q end
            local dist=player and Distance(q.point,player)
            if dist and (not nearestDistance or dist<nearestDistance) then
                nearest,nearestDistance=q,dist
            end
        end
    end
    local first
    for _,q in ipairs(options) do
        if q.point then first=q;break end
    end
    target=manual or preferred or nearest or first
    chosen=manual and "Manual" or (preferred and "Tracked" or "Smart")
    reason=player and "Ready" or (why or "No coordinates")
    if not target then reason="No accepted quest waypoints"
    elseif not target.point then reason="Waiting for quest waypoint" end
    if frame then frame:Show() end
end
local function Face()
    if not target then return nil,reason end
    if not target.point then return nil,"No waypoint for selected quest" end
    local player,why=PlayerPosition()
    if not player then return nil,why end
    local dist,dx,dy=Distance(target.point,player)
    if not dist then return nil,"Quest is in another region" end
    if type(math.atan2)~="function" then
        return nil,"Directional math unavailable"
    end
    -- World X increases westward; world Y increases northward.
    -- Facing is 0 north and grows counterclockwise in Forever.
    local angle=math.atan2(dx,dy)-player.facing
    return {distance=dist,angle=angle},"Ready"
end
local function UpdateDisplay()
    if not frame or not frame:IsShown() then return end
    frame.title:SetText(target and target.name or "No quest waypoint")
    frame.mode:SetText(chosen or "Smart")
    local data,why=Face()
    if not data then
        frame.arrow:Hide()
        frame.distance:SetText(why or reason)
    elseif type(frame.arrow.SetRotation)~="function" then
        frame.arrow:Hide()
        frame.distance:SetText("Directional display unavailable")
    else
        frame.arrow:Show()
        frame.arrow:SetRotation(data.angle)
        frame.distance:SetText(math.floor(data.distance+0.5).." yd  ·  straight line")
        if type(frame.arrow.SetVertexColor)=="function" then
            if data.distance<30 then
                frame.arrow:SetVertexColor(0.40,0.86,0.52,1)
            else
                frame.arrow:SetVertexColor(0.96,0.76,0.38,1)
            end
        end
    end
end
local function Pos(frame)
    local db=DB()
    if not db then return end
    frame:ClearAllPoints()
    frame:SetPoint("TOP",UIParent,"TOP",
        db.offsetX or 0,db.offsetY or -130)
end
local function Build()
    if frame or not UIParent or type(CreateFrame)~="function" then return end
    local template=type(BackdropTemplateMixin)=="table" and
        "BackdropTemplate" or nil
    local f=CreateFrame("Frame","ChalkBoxQuestNavigator",UIParent,template)
    f:SetSize(274,116)
    if type(f.SetFrameStrata)=="function" then f:SetFrameStrata("DIALOG") end
    if type(f.SetClampedToScreen)=="function" then
        f:SetClampedToScreen(true)
    end
    if type(f.SetBackdrop)=="function" then
        f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
            edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
            edgeSize=16,tile=true,tileSize=16,
            insets={left=6,right=6,top=6,bottom=6}})
        f:SetBackdropColor(0.09,0.07,0.055,0.94)
        f:SetBackdropBorderColor(0.76,0.57,0.32,1)
    else
        local back=f:CreateTexture(nil,"BACKGROUND")
        back:SetAllPoints(f)
        back:SetColorTexture(0.09,0.07,0.055,0.94)
        f.back=back
        -- Older Forever builds have no BackdropTemplate; keep a thin
        -- complete frame rather than leaving a bare floating rectangle.
        local function Border(x,y,w,h)
            local line=f:CreateTexture(nil,"BORDER")
            line:SetPoint("TOPLEFT",f,"TOPLEFT",x,y)
            line:SetSize(w,h)
            line:SetColorTexture(0.71,0.52,0.30,0.95)
        end
        Border(1,-1,272,2);Border(1,-113,272,2)
        Border(1,-2,2,112);Border(271,-2,2,112)
    end
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart",function(self)
        local db=DB()
        if db and not db.locked and
            (type(InCombatLockdown)~="function" or
                not InCombatLockdown()) then
            self:StartMoving()
        end
    end)
    f:SetScript("OnDragStop",function(self)
        if self.StopMovingOrSizing then self:StopMovingOrSizing() end
        local db=DB()
        if not db or db.locked then return end
        if not self.GetCenter or not UIParent.GetCenter then return end
        local x,y=self:GetCenter()
        local px,py=UIParent:GetCenter()
        local top=UIParent.GetTop and UIParent:GetTop()
        if Number(x) and Number(y) and Number(px) and Number(py)
            and Number(top) and self.GetHeight then
            local offsetX=x-px
            local offsetY=y+self:GetHeight()/2-top
            if math.abs(offsetX)<1500 and math.abs(offsetY)<1000 then
                db.offsetX=offsetX;db.offsetY=offsetY
            end
        end
    end)
    Pos(f)
    local a=f:CreateTexture(nil,"ARTWORK")
    a:SetTexture("Interface\\Minimap\\MinimapArrow")
    a:SetPoint("TOPLEFT",f,"TOPLEFT",20,-27)
    a:SetSize(48,48)
    f.arrow=a
    local function Text(style,x,y,w)
        local t=f:CreateFontString(nil,"OVERLAY",style)
        t:SetPoint("TOPLEFT",f,"TOPLEFT",x,y)
        t:SetWidth(w)
        t:SetJustifyH("LEFT")
        if type(t.SetWordWrap)=="function" then t:SetWordWrap(false) end
        return t
    end
    Text("GameFontNormal",18,-10,246):SetText("QUESTSENSE / NAVIGATION")
    f.title=Text("GameFontHighlight",75,-31,177)
    f.distance=Text("GameFontHighlightSmall",75,-56,190)
    f.mode=Text("GameFontHighlightSmall",18,-85,78)
    local function Button(label,x,w,action)
        local b=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
        b:SetSize(w,21)
        b:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",x,10)
        b:SetText(label)
        b:SetScript("OnClick",action)
        return b
    end
    Button("Auto",102,46,function()
        ChalkBox_NavCommand("auto")
    end)
    Button("Next",151,50,function()
        ChalkBox_NavCommand("next")
    end)
    Button("Hide",204,54,function()
        ChalkBox_NavCommand("off")
    end)
    f:SetScript("OnUpdate",function(self,elapsed)
        if not Number(elapsed) or elapsed<0 then return end
        refreshTimer=refreshTimer+elapsed
        if refreshTimer>=2.5 then refreshTimer=0;Refresh() end
        self._display=(self._display or 0)+elapsed
        if self._display>=0.15 then
            self._display=0
            UpdateDisplay()
        end
    end)
    frame=f
    f:Hide()
end
function ChalkBox_NavStatus()
    local db=DB()
    return {enabled=db and db.enabled or false,
        locked=db and db.locked or false,
        manualID=db and db.questID or nil,
        questID=target and target.id or nil,
        title=target and target.name or nil,
        mode=chosen or "Smart",reason=reason,
        candidates=(function()
            local count=0
            for _,q in ipairs(options) do
                if q.point then count=count+1 end
            end
            return count
        end)()}
end
function ChalkBox_NavChoices()
    local candidates=Accepted()
    local result={}
    for _,v in ipairs(candidates or {}) do
        if v.point then
            result[#result+1]={id=v.id,name=v.name}
        end
    end
    return result
end
function ChalkBox_NavCommand(input)
    local db=DB()
    if not db then return false end
    local action=(input or ""):match("^%s*(.-)%s*$"):lower()
    if action=="on" or action=="show" then
        db.enabled=true
    elseif action=="off" or action=="hide" then
        db.enabled=false
    elseif action=="auto" then
        db.enabled=true;db.questID=nil
    elseif action=="next" or action=="previous" or action=="prev" then
        local items=ChalkBox_NavChoices()
        if #items==0 then
            Message("No accepted quests with known waypoints.")
            return false
        end
        local index=0
        for i,q in ipairs(items) do
            if q.id==db.questID or (not db.questID and target and
                q.id==target.id) then index=i;break end
        end
        if action=="next" then index=index%#items+1
        else index=(index-2+#items)%#items+1 end
        db.questID=items[index].id
        db.enabled=true
    elseif action=="lock" or action=="unlock" then
        db.locked=action=="lock"
    elseif action=="reset" then
        db.offsetX=nil;db.offsetY=nil
        if frame then Pos(frame) end
    elseif action=="status" then
        Refresh()
        local s=ChalkBox_NavStatus()
        Message((s.enabled and "ON" or "OFF").." | "..
            s.mode.." | "..(s.title or "No target")..
            " | "..s.reason.." | "..s.candidates.." candidates")
        return true
    else
        local id=action:match("^follow%s+(%d+)$")
        if id then
            id=tonumber(id)
            local found=false
            for _,q in ipairs(ChalkBox_NavChoices()) do
                if q.id==id then found=true;break end
            end
            if not found then
                Message("That accepted quest has no verified waypoint.")
                return false
            end
            db.questID=id
            db.enabled=true
        else
            Message("Use /chalk nav on|off|auto|next|prev|follow ID|lock|unlock|reset|status")
            return false
        end
    end
    if db.enabled then Build() end
    Refresh()
    UpdateDisplay()
    return true
end
local listener=CreateFrame("Frame")
for _,name in ipairs({"ADDON_LOADED","PLAYER_ENTERING_WORLD",
    "QUEST_LOG_UPDATE","QUEST_ACCEPTED","QUEST_REMOVED",
    "QUEST_TURNED_IN","SUPER_TRACKING_CHANGED",
    "ZONE_CHANGED_NEW_AREA","PLAYER_REGEN_ENABLED"}) do
    pcall(listener.RegisterEvent,listener,name)
end
listener:SetScript("OnEvent",function(_,name,arg)
    if name=="ADDON_LOADED" and arg~=addonName then return end
    if name=="ADDON_LOADED" or name=="PLAYER_ENTERING_WORLD" then
        local db=DB()
        if db and db.enabled then Build() end
    end
    if frame or (DB() and DB().enabled) then
        Refresh()
        UpdateDisplay()
    end
end)
