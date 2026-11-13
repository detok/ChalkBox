-- ChalkBox reminder toast: top-screen, adjustable transparency and position.
-- One reused frame, no protected actions and no gameplay clicks while locked.
local box,headline,body,shownAt,untilSeconds
local duration=9
local function Clock()
    if type(GetTime)=="function" then
        local n=GetTime()
        if (type(issecretvalue)~="function" or not issecretvalue(n))
            and type(n)=="number" then return n end
    end
    return 0
end
local function DB()
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    if type(ChalkBoxDB.camp)~="table" then ChalkBoxDB.camp={} end
    if type(ChalkBoxDB.camp.toastOptions)~="table" then
        ChalkBoxDB.camp.toastOptions={}
    end
    local options=ChalkBoxDB.camp.toastOptions
    if options.locked==nil then options.locked=true end
    if type(options.opacity)~="number" or
        options.opacity<0.35 or options.opacity>1 then options.opacity=0.92 end
    return options
end
local function Position()
    if not box then return end
    local d=DB()
    if box.ClearAllPoints then box:ClearAllPoints() end
    if d.position=="custom" and type(d.x)=="number" and type(d.y)=="number" then
        box:SetPoint("CENTER",UIParent,"CENTER",d.x,d.y)
    else
        box:SetPoint("TOP",UIParent,"TOP",0,-112)
    end
end
local function Opacity()
    if not box or not box.SetAlpha then return end
    local d=DB()
    local factor=1
    if shownAt then
        local elapsed=Clock()-shownAt
        local stop=untilSeconds or duration
        if elapsed>stop-2 then
            factor=math.max(0,math.min(1,(stop-elapsed)/2))
        end
    end
    box:SetAlpha(d.opacity*factor)
end
local function Lock()
    if not box then return end
    local d=DB()
    if box.EnableMouse then box:EnableMouse(d.locked~=true) end
end
local function Ensure()
    if box then return true end
    if not UIParent or type(CreateFrame)~="function" then return false end
    local root=CreateFrame("Frame","ChalkBoxAdventureToast",UIParent)
    if not root or not root.SetSize or not root.CreateTexture or
        not root.CreateFontString then return false end
    root:SetSize(490,85)
    if root.SetMovable then root:SetMovable(true) end
    if root.SetClampedToScreen then root:SetClampedToScreen(true) end
    if root.SetFrameStrata then root:SetFrameStrata("DIALOG") end
    local back=root:CreateTexture(nil,"BACKGROUND")
    back:SetAllPoints(root)
    back:SetColorTexture(0.035,0.055,0.075,0.92)
    local line=root:CreateTexture(nil,"ARTWORK")
    line:SetPoint("TOPLEFT",root,"TOPLEFT",0,0)
    line:SetPoint("BOTTOMLEFT",root,"BOTTOMLEFT",0,0)
    line:SetWidth(4)
    line:SetColorTexture(0.93,0.68,0.26,1)
    headline=root:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
    headline:SetPoint("TOPLEFT",root,"TOPLEFT",18,-12)
    headline:SetPoint("RIGHT",root,"RIGHT",-16,0)
    if headline.SetJustifyH then headline:SetJustifyH("LEFT") end
    body=root:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    body:SetPoint("TOPLEFT",root,"TOPLEFT",18,-36)
    body:SetPoint("BOTTOMRIGHT",root,"BOTTOMRIGHT",-16,9)
    if body.SetJustifyH then body:SetJustifyH("LEFT") end
    if body.SetJustifyV then body:SetJustifyV("TOP") end
    root:Hide()
    box=root
    Position()
    Lock()
    Opacity()
    if root.RegisterForDrag then root:RegisterForDrag("LeftButton") end
    root:SetScript("OnDragStart",function(self)
        if DB().locked~=true and self.StartMoving then self:StartMoving() end
    end)
    root:SetScript("OnDragStop",function(self)
        if self.StopMovingOrSizing then self:StopMovingOrSizing() end
        if DB().locked==true then return end
        local x,y=self.GetCenter and self:GetCenter()
        local cx,cy=UIParent.GetCenter and UIParent:GetCenter()
        if type(x)=="number" and type(y)=="number"
            and type(cx)=="number" and type(cy)=="number" then
            local d=DB()
            d.position="custom";d.x=x-cx;d.y=y-cy
            Position()
        end
    end)
    root:SetScript("OnUpdate",function(self)
        if not shownAt then return end
        local elapsed=Clock()-shownAt
        if elapsed>= (untilSeconds or duration) then
            shownAt=nil;untilSeconds=nil
            self:Hide()
        elseif elapsed>= (untilSeconds or duration)-2 then
            Opacity()
        end
    end)
    return true
end
function ChalkBox_ShowReminder(message,title,preview)
    if type(message)~="string" or message=="" or not Ensure() then return false end
    if type(InCombatLockdown)=="function" and InCombatLockdown() then return false end
    headline:SetText(title or "CHALKBOX  -  ADVENTURE PREP")
    body:SetText(message)
    shownAt=Clock()
    untilSeconds=preview==true and 25 or duration
    Lock()
    Opacity()
    box:Show()
    return true
end
function ChalkBox_HideReminder()
    shownAt=nil;untilSeconds=nil
    if box then box:Hide() end
end
function ChalkBox_ToastStatus()
    local d=DB()
    return {locked=d.locked==true,opacity=d.opacity,position=d.position or "top"}
end
function ChalkBox_ToastCommand(command)
    local d=DB()
    command=string.lower((command or ""):match("^%s*(.-)%s*$") or "")
    if command=="lock" then d.locked=true
    elseif command=="unlock" then d.locked=false
    elseif command=="reset" then
        d.x=nil;d.y=nil;d.position=nil
        Position()
    elseif command:match("^opacity %d+$") then
        local number=tonumber(command:match("%d+"))
        if number>=35 and number<=100 then
            d.opacity=math.floor(number+0.5)/100
        end
    elseif command=="preview" then
        return ChalkBox_ShowReminder(
            d.locked and "Unlock in Adventure Prep to drag this notice, then lock it again."
                or "Drag this notice to your preferred position. It saves when released.",
            "CAMP REMINDER  -  POSITION PREVIEW",true)
    else
        return false
    end
    Lock()
    Opacity()
    return true
end
