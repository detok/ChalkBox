-- ChalkBox QuestSense Navigation: an optional, self-contained quest arrow.
-- Reads accepted quest waypoints; delegates a single native tracker watch to
-- QuestSense so the selected quest stays visible. Never changes quest choice,
-- Blizzard super-tracking, map pins or secure combat state.
local addonName=...
local frame,chosen,reason,options,refreshTimer=nil,nil,"Navigation off",{},0
local target
local lastNativeWatch
-- Manual Next/Follow remains possible, but selecting a new Blizzard quest
-- should release a stale manual override. Only state changes trigger it.
local lastTracked,lastSelected,observedSelection,selectedFocus=nil,nil,false,nil
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
    -- Preserve both legacy choices and add a literal original minimap
    -- arrow choice. Invalid values fall back to the current HD default.
    if saved.arrowStyle~="classic" and saved.arrowStyle~="original"
        and saved.arrowStyle~="hd" then saved.arrowStyle="hd" end
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
    -- The active quest's current-map travel stop is more useful than
    -- an objective on a remote map. Both calls are read-only game APIs.
    if ID(playerMap) then
        local x,y=Call(C_QuestLog and
            C_QuestLog.GetNextWaypointForMap,id,playerMap)
        local localPoint=MapPoint(playerMap,x,y)
        if localPoint then return localPoint end
    end
    -- Prefer the explicitly routed *next* step before raw POIs.
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
local function Ghost()
    local ghost=Call(UnitIsGhost,"player")
    local dead=Call(UnitIsDeadOrGhost,"player")
    local trackedCorpse=Call(C_SuperTrack and
        C_SuperTrack.IsSuperTrackingCorpse)
    return ghost==true or dead==true or trackedCorpse==true
end
local function CorpsePoint()
    local mapID=Map()
    local visited={}
    -- Graveyards are sometimes on a sub-map while the corpse is
    -- exposed on its parent zone. Never fabricate a corpse position.
    for _=1,8 do
        if not ID(mapID) or visited[mapID] then break end
        visited[mapID]=true
        local pos=Call(C_DeathInfo and
            C_DeathInfo.GetCorpseMapPosition,mapID)
        local x,y=XY(pos)
        local point=MapPoint(mapID,x,y)
        if point then return point end
        local info=Call(C_Map and C_Map.GetMapInfo,mapID)
        if type(info)~="table" or not ID(info.parentMapID) then break end
        mapID=info.parentMapID
    end
end
local function GameSelection(db)
    -- A super-tracked quest is the actual focused quest in Blizzard's
    -- world-map/objective tracker. The quest-log row selection is also
    -- readable, and can change independently when the player clicks it.
    local s=Call(C_SuperTrack and C_SuperTrack.GetSuperTrackedQuestID)
    local selected=Call(C_QuestLog and C_QuestLog.GetSelectedQuest)
    s=ID(s) and s or nil
    selected=ID(selected) and selected or nil
    if not observedSelection then
        observedSelection=true
        lastTracked=s;lastSelected=selected
        -- A stale saved Next/Follow from a previous login must not
        -- override the newly selected game quest on first load.
        if (s or selected) and db.questID and
            db.questID~=(s or selected) then db.questID=nil end
    else
        if s~=lastTracked then
            db.questID=nil;selectedFocus=nil
            lastTracked=s
        end
        if selected~=lastSelected then
            db.questID=nil
            selectedFocus=selected
            lastSelected=selected
        end
    end
    if selectedFocus then return selectedFocus,"Selected" end
    if s then return s,"Tracked" end
    if selected then return selected,"Selected" end
    return nil,"Auto"
end
local function SyncNativeWatch(id)
    if id==lastNativeWatch then return end
    lastNativeWatch=id
    if type(ChalkBox_QuestNavFocus)=="function" then
        ChalkBox_QuestNavFocus(id)
    end
end
local function Refresh()
    local db=DB()
    if not db or not db.enabled then
        target=nil;reason="Navigation off"
        SyncNativeWatch(nil)
        if frame then frame:Hide() end
        return
    end
    -- Corpse recovery always wins. Keep the prior manually chosen
    -- quest intact, and restore it when the character is alive again.
    if Ghost() then
        local point=CorpsePoint()
        target={kind="corpse",name="Your corpse",point=point}
        chosen="Corpse"
        reason=point and "Ready" or "Corpse position unavailable"
        if frame then frame:Show() end
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
    local gameID,gameSource=GameSelection(db)
    local manual,focused
    for _,q in ipairs(options) do
        if db.questID and q.id==db.questID then manual=q end
        if gameID and q.id==gameID then focused=q end
    end
    if db.questID and not manual then db.questID=nil end
    local player,why=PlayerPosition()
    local nearest,nearestDistance,previous
    for _,q in ipairs(options) do
        if q.point then
            local dist=player and Distance(q.point,player)
            if dist and (not nearestDistance or dist<nearestDistance) then
                nearest,nearestDistance=q,dist
            end
            if not gameID and target and target.id==q.id and
                (not player or dist) then previous=q end
        end
    end
    local first
    for _,q in ipairs(options) do
        if q.point then first=q;break end
    end
    -- Never quietly switch the selected quest to a different one
    -- just because its POI is missing or temporarily unreadable.
    target=manual or focused or
        (gameID and {id=gameID,name="Tracked quest #"..gameID}) or
        previous or nearest or first
    chosen=manual and "Manual" or (gameID and gameSource or "Auto")
    reason=player and "Ready" or (why or "No coordinates")
    if not target then reason="No accepted quest waypoints"
    elseif not target.point then reason="Selected quest waypoint unavailable" end
    SyncNativeWatch(target and ID(target.id) and target.id or nil)
    if frame then frame:Show() end
end
local function Face()
    if not target then return nil,reason end
    if not target.point then
        if target.kind=="corpse" then
            return nil,"Corpse position unavailable"
        end
        return nil,"No waypoint for selected quest"
    end
    local player,why=PlayerPosition()
    if not player then return nil,why end
    local dist,dx,dy=Distance(target.point,player)
    if not dist then return nil,"Quest is in another region" end
    if type(math.atan2)~="function" then
        return nil,"Directional math unavailable"
    end
    -- WoW world-space axes are rotated from map UI axes:
    -- +X is north, +Y is west. Facing 0 = north, CCW positive.
    -- The previous atan2(dx,dy) reversed the axes and sent the
    -- compass east/west for north/south quests.
    if dist<7 then
        return {distance=dist,angle=0,arrived=true},"Arrived"
    end
    local angle=math.atan2(dy,dx)-player.facing
    -- Keep the displayed heading continuous across the -pi/pi seam.
    angle=math.atan2(math.sin(angle),math.cos(angle))
    return {distance=dist,angle=angle},"Ready"
end
local function UpdateDisplay()
    if not frame or not frame:IsShown() then return end
    local data,why=Face()
    -- Keep the invisible frame usable for right-click even when Forever
    -- cannot expose GPS. Never leave a stale, misleading direction visible.
    frame.arrow:Show()
    if frame.distanceLabel then
        frame.distanceLabel:SetText(data and
            (tostring(math.floor(data.distance+0.5)).." yd") or "—")
    end
    if not data or type(frame.arrow.SetRotation)~="function" then
        if type(frame.arrow.SetRotation)=="function" then
            frame.arrow:SetRotation(0)
        end
        if type(frame.arrow.SetVertexColor)=="function" then
            frame.arrow:SetVertexColor(0.57,0.57,0.57,0.40)
        end
        frame.readout=why or "Direction unavailable"
    else
        frame.arrow:SetRotation(data.angle)
        frame.readout=math.floor(data.distance+0.5).." yd (straight line)"
        if type(frame.arrow.SetVertexColor)=="function" then
            if data.arrived or data.distance<30 then
                frame.arrow:SetVertexColor(0.40,0.86,0.52,1)
            else
                frame.arrow:SetVertexColor(0.96,0.76,0.38,1)
            end
        end
    end
end
-- Identical menu APIs to the existing Trail Bar and Discoveries.
-- No extra always-visible buttons or background frame.
local fallbackMenu
local function MenuEntries()
    return {
        {text="Auto (follow tracked)",action=function()
            ChalkBox_NavCommand("auto")
        end},
        {text="Next quest",action=function()
            ChalkBox_NavCommand("next")
        end},
        {text="Hide arrow",action=function()
            ChalkBox_NavCommand("off")
        end},
    }
end
function ChalkBox_NavOpenMenu(owner)
    if type(InCombatLockdown)=="function" and
        InCombatLockdown() then return false end
    local entries=MenuEntries()
    if type(MenuUtil)=="table" and
        type(MenuUtil.CreateContextMenu)=="function" then
        local ok=pcall(MenuUtil.CreateContextMenu,owner or frame,
            function(_,root)
                for _,entry in ipairs(entries) do
                    root:CreateButton(entry.text,function() entry.action() end)
                end
            end)
        if ok then return true end
    end
    if type(EasyMenu)=="function" then
        if not fallbackMenu then
            local ok,menu=pcall(CreateFrame,"Frame",
                "ChalkBoxNavigationDropdown",UIParent,
                "UIDropDownMenuTemplate")
            if ok then fallbackMenu=menu end
        end
        if fallbackMenu then
            local items={}
            for _,entry in ipairs(entries) do
                items[#items+1]={text=entry.text,func=entry.action,
                    notCheckable=true}
            end
            local ok=pcall(EasyMenu,items,fallbackMenu,
                "cursor",0,0,"MENU")
            if ok then return true end
        end
    end
    -- On clients without either standard popup system, the player
    -- still has the native QuestSense Navigation settings as fallback.
    if type(ChalkBox_OpenSettings)=="function" then
        ChalkBox_OpenSettings("questnav")
    end
    return false
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
    local f=CreateFrame("Frame","ChalkBoxQuestNavigator",UIParent)
    -- Arrow-sized hit area only. No dialog frame, backdrop, bronze edges,
    -- text panel, quest title, or permanently visible buttons.
    -- Still no panel: just a 64px arrow and a discreet distance below.
    f:SetSize(76,90)
    if type(f.SetFrameStrata)=="function" then f:SetFrameStrata("DIALOG") end
    if type(f.SetClampedToScreen)=="function" then
        f:SetClampedToScreen(true)
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
    local function ArrowStyle()
        local db=DB()
        if db and db.arrowStyle=="hd" then
            -- 256px antialiased, original north-up silhouette rendered
            -- from our SVG into a bundled native WoW 32-bit TGA.
            a:SetTexture("Interface\\AddOns\\ChalkBox\\assets\\QuestArrowHD")
            return
        elseif db and db.arrowStyle=="original" then
            -- The very first ChalkBox compass artwork, before we
            -- adopted the new Blizzard tracked-navigation atlas.
            a:SetTexture("Interface\\Minimap\\MinimapArrow")
            return
        end
        local atlasOK=false
        if type(a.SetAtlas)=="function" then
            local ok,result=pcall(a.SetAtlas,a,
                "Navigation-Tracked-Arrow",false)
            atlasOK=ok and result~=false
            if atlasOK and type(a.GetAtlas)=="function" then
                local good,name=pcall(a.GetAtlas,a)
                atlasOK=good and name=="Navigation-Tracked-Arrow"
            end
        end
        if not atlasOK then
            a:SetTexture("Interface\\Minimap\\MinimapArrow")
        end
    end
    ArrowStyle()
    a:SetSize(64,64)
    a:SetPoint("TOP",f,"TOP",0,-2)
    f.ApplyArrowStyle=ArrowStyle
    local distance=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    distance:SetPoint("TOP",f,"TOP",0,-69)
    distance:SetWidth(76)
    if type(distance.SetJustifyH)=="function" then
        distance:SetJustifyH("CENTER")
    end
    if type(distance.SetTextColor)=="function" then
        distance:SetTextColor(1,0.84,0.48,1)
    end
    if type(distance.SetShadowOffset)=="function" then
        distance:SetShadowOffset(1,-1)
    end
    distance:SetText("—")
    f.distanceLabel=distance
    f.arrow=a
    f:SetScript("OnMouseUp",function(self,button)
        if button=="RightButton" then ChalkBox_NavOpenMenu(self) end
    end)
    f:SetScript("OnEnter",function(self)
        if not GameTooltip or
            type(GameTooltip.SetOwner)~="function" or
            type(GameTooltip.AddLine)~="function" then return end
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        GameTooltip:AddLine(target and target.name or "QuestSense Navigation",
            1,0.82,0.48)
        GameTooltip:AddLine(self.readout or reason,0.9,0.9,0.85)
        GameTooltip:AddLine("Right-click: Auto / Next / Hide",
            0.65,0.72,0.75)
        if type(GameTooltip.Show)=="function" then GameTooltip:Show() end
    end)
    f:SetScript("OnLeave",function()
        if GameTooltip and type(GameTooltip.Hide)=="function" then
            GameTooltip:Hide()
        end
    end)
    f:SetScript("OnUpdate",function(self,elapsed)
        if not Number(elapsed) or elapsed<0 then return end
        refreshTimer=refreshTimer+elapsed
        if refreshTimer>=0.7 then refreshTimer=0;Refresh() end
        self._display=(self._display or 0)+elapsed
        if self._display>=0.075 then
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
        arrowStyle=db and db.arrowStyle or "classic",
        manualID=db and db.questID or nil,
        questID=target and target.id or nil,
        targetType=target and target.kind or "quest",
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
    elseif action=="hd" or action=="classic" or action=="original" then
        db.arrowStyle=action
        if frame and frame.ApplyArrowStyle then frame.ApplyArrowStyle() end
    elseif action=="lock" or action=="unlock" then
        db.locked=action=="lock"
    elseif action=="reset" then
        db.offsetX=nil;db.offsetY=nil
        if frame then Pos(frame) end
    elseif action=="status" then
        Refresh()
        UpdateDisplay()
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
            Message("Use /chalk nav on|off|auto|next|prev|follow ID|original|classic|hd|lock|unlock|reset|status")
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
    "ZONE_CHANGED_NEW_AREA","PLAYER_REGEN_ENABLED",
    "QUEST_LOG_SELECTION_CHANGED","PLAYER_DEAD","PLAYER_ALIVE",
    "PLAYER_UNGHOST","CORPSE_IN_RANGE","CORPSE_OUT_OF_RANGE",
    "PLAYER_CORPSE_POSITION_UPDATE"}) do
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
