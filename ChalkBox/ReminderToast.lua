-- ChalkBox ReminderToast: unobtrusive central notice, never a modal window.
-- Render once and reuse. Does not take keyboard/mouse focus or cast spells.
local box,headline,body,shownAt
local duration=9
local function Clock()
    if type(GetTime)=="function" then
        local now=GetTime()
        if type(now)=="number" and (type(issecretvalue)~="function" or not issecretvalue(now)) then return now end
    end
    return 0
end
local function Ensure()
    if box then return true end
    if not UIParent or type(CreateFrame)~="function" then return false end
    local root=CreateFrame("Frame",nil,UIParent)
    if not root or not root.SetSize or not root.CreateTexture or not root.CreateFontString then return false end
    root:SetSize(490,85)
    root:SetPoint("CENTER",UIParent,"CENTER",0,135)
    if root.SetFrameStrata then root:SetFrameStrata("DIALOG") end
    if root.EnableMouse then root:EnableMouse(false) end
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
    root:SetScript("OnUpdate",function(self)
        if not shownAt then return end
        local elapsed=Clock()-shownAt
        if elapsed>=duration then
            shownAt=nil
            self:Hide()
        elseif elapsed>=duration-2 then
            if self.SetAlpha then self:SetAlpha(math.max(0,(duration-elapsed)/2)) end
        end
    end)
    box=root
    return true
end
function ChalkBox_ShowReminder(message,title)
    if type(message)~="string" or message=="" or not Ensure() then return false end
    if type(InCombatLockdown)=="function" and InCombatLockdown() then return false end
    headline:SetText(title or "CHALKBOX  •  ADVENTURE PREP")
    body:SetText(message)
    if box.SetAlpha then box:SetAlpha(1) end
    shownAt=Clock()
    box:Show()
    return true
end
function ChalkBox_HideReminder()
    shownAt=nil
    if box then box:Hide() end
end
