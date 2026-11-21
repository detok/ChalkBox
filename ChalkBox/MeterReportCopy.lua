-- RETIRED. This file is not listed in ChalkBox.toc or ChalkBox_Camelot.toc.
-- Do not add it back to the load list. The combat meter no longer opens a copy window.
-- It remains in the source tree so the old behavior can still be read and tested.
-- Read-only report copy window. This is a manual alternative when Forever
-- refuses addon-created party / say messages. It never sends chat itself.
local window,edit
local function Tell(message)
    if DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage)=="function" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffefc574ChalkBox Meter|r "..message)
    end
end
function ChalkBox_MeterShowCopy(message,reason)
    if type(issecretvalue)=="function" and issecretvalue(message) then
        return false
    end
    if type(message)~="string" or message=="" or #message>255 then
        return false
    end
    local hint=reason or "Copy this report and paste it into chat yourself."
    -- Unit-test and client fallback: never lose a valid report merely
    -- because a particular native frame template is unavailable.
    if not UIParent or type(CreateFrame)~="function" then
        Tell(hint.." Copy: "..message)
        return true
    end
    if not window then
        local ok,frame=pcall(CreateFrame,"Frame","ChalkBoxMeterCopyFrame",
            UIParent,"BasicFrameTemplateWithInset")
        if not ok or not frame or
            type(frame.SetSize)~="function" or
            type(frame.CreateFontString)~="function" then
            Tell(hint.." Copy: "..message)
            return true
        end
        window=frame
        frame:SetSize(540,164)
        frame:SetPoint("CENTER",UIParent,"CENTER",0,110)
        frame:SetFrameStrata("DIALOG")
        if frame.SetMovable then frame:SetMovable(true) end
        if frame.EnableMouse then frame:EnableMouse(true) end
        if frame.RegisterForDrag then frame:RegisterForDrag("LeftButton") end
        if frame.StartMoving and frame.StopMovingOrSizing then
            frame:SetScript("OnDragStart",function(f) f:StartMoving() end)
            frame:SetScript("OnDragStop",function(f) f:StopMovingOrSizing() end)
        end
        if frame.TitleText and frame.TitleText.SetText then
            frame.TitleText:SetText("ChalkBox - Copy Fight Report")
        end
        local info=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        info:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-39)
        info:SetWidth(490)
        info:SetJustifyH("LEFT")
        info:SetText("Select / Ctrl+C, then paste into party chat manually. "..
            "This never broadcasts automatically.")
        local boxOk,field=pcall(CreateFrame,"EditBox",nil,frame,"InputBoxTemplate")
        if not boxOk or not field then
            window=nil
            if frame.Hide then frame:Hide() end
            Tell(hint.." Copy: "..message)
            return true
        end
        edit=field
        edit:SetSize(475,30)
        edit:SetPoint("TOPLEFT",frame,"TOPLEFT",30,-76)
        edit:SetAutoFocus(false)
        edit:SetMaxLetters(255)
        edit:SetScript("OnEscapePressed",function() frame:Hide() end)
        edit:SetScript("OnEnterPressed",function(self)
            self:HighlightText()
        end)
        local footer=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        footer:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-125)
        footer:SetWidth(490)
        footer:SetJustifyH("LEFT")
        footer:SetText("Report is prepared locally. The game has not sent it.")
    end
    edit:SetText(message)
    window:Show()
    edit:SetFocus()
    edit:HighlightText()
    Tell(hint.." Report is ready to copy (Ctrl+C).")
    return true
end
