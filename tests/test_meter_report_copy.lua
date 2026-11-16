-- Read-only copy fallback for protected Forever chat.
local chat={}
local frames={}
local edit
_G.UIParent={}
_G.DEFAULT_CHAT_FRAME={AddMessage=function(_,message) chat[#chat+1]=message end}
_G.issecretvalue=function(value) return value=="SECRET" end
local function Font()
    return {SetPoint=function() end,SetWidth=function() end,
        SetJustifyH=function() end,SetText=function() end}
end
_G.CreateFrame=function(kind,name,parent,template)
    local frame={kind=kind,name=name,template=template}
    function frame:SetSize(w,h) self.width,self.height=w,h end
    function frame:SetPoint() end
    function frame:SetFrameStrata() end
    function frame:SetMovable() end
    function frame:EnableMouse() end
    function frame:RegisterForDrag() end
    function frame:SetScript(event,fn) self[event]=fn end
    function frame:CreateFontString() return Font() end
    function frame:Show() self.shown=true end
    function frame:Hide() self.shown=false end
    function frame:SetAutoFocus() end
    function frame:SetMaxLetters(n) self.max=n end
    function frame:SetText(text) self.value=text end
    function frame:SetFocus() self.focus=true end
    function frame:HighlightText() self.highlight=true end
    if kind=="EditBox" then edit=frame end
    if kind=="Frame" then frame.TitleText=Font() end
    frames[#frames+1]=frame
    return frame
end
assert(loadfile("MeterReportCopy.lua"))("ChalkBox")
assert(not ChalkBox_MeterShowCopy("SECRET","no"),"secret text cannot be copied")
assert(not ChalkBox_MeterShowCopy(string.rep("x",256),"too long"),
    "copy popup respects single-chat-line length")
local msg="CB DPS (Last): 1 Hunter 900 | 2 Warrior 850"
assert(ChalkBox_MeterShowCopy(msg,"Forever declined addon chat"))
assert(edit and edit.value==msg and edit.highlight and edit.focus
    and edit.max==255 and frames[1].shown,
    "native edit box contains untouched selected report ready for Ctrl+C")
assert(#chat==1 and chat[1]:find("ready to copy",1,true),
    "the user is told no chat was sent")
assert(ChalkBox_MeterShowCopy("CB DPS (Last): 1 Hunter 901","again"))
assert(#frames==2 and edit.value:find("901",1,true),
    "copy window is reused, not recreated every report")
_G.UIParent=nil
assert(ChalkBox_MeterShowCopy(msg,"no frames")
    and chat[#chat]:find(msg,1,true),
    "no-UI environment retains a local copyable message")
print("Meter report copy fallback: OK")
