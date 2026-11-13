-- ReminderToast uses a non-clickable 9 second centered UI frame, reusing it.
local now=200
_G.GetTime=function() return now end
_G.InCombatLockdown=function() return false end
_G.UIParent={}
local frames={}
_G.CreateFrame=function()
    local f={shown=false}
    function f:SetSize(w,h) self.w,self.h=w,h end
    function f:SetPoint(...) self.anchor={...} end
    function f:SetFrameStrata(s) self.strata=s end
    function f:EnableMouse(v) self.mouse=v end
    function f:CreateTexture()
        local t={}
        function t:SetAllPoints() end
        function t:SetColorTexture(...) end
        function t:SetPoint(...) end
        function t:SetWidth(...) end
        return t
    end
    function f:CreateFontString()
        local t={}
        function t:SetPoint(...) end
        function t:SetJustifyH(...) end
        function t:SetJustifyV(...) end
        function t:SetText(value) self.text=value end
        return t
    end
    function f:Hide() self.shown=false end
    function f:Show() self.shown=true end
    function f:SetAlpha(n) self.alpha=n end
    function f:SetScript(which,fn) self[which]=fn end
    frames[#frames+1]=f
    return f
end
assert(loadfile("ReminderToast.lua"))("ChalkBox")
assert(ChalkBox_ShowReminder("No Camp Benefits found.","CHALKBOX"))
local root=frames[1]
assert(root.shown and root.mouse==false)
assert(root.w==490 and root.h==85)
assert(root.anchor[1]=="CENTER","notice centered and out of the way")
assert(root.strata=="DIALOG","notice overlays without being clickable")
now=207.5;root.OnUpdate(root)
assert(root.shown and root.alpha<1 and root.alpha>0,"fade out in last two seconds")
now=210;root.OnUpdate(root)
assert(not root.shown,"notice disappears after nine seconds")
assert(ChalkBox_ShowReminder("Your camp buffs expire soon."))
assert(#frames==1,"reuse a single frame instead of stacking popups")
ChalkBox_HideReminder()
assert(not root.shown)
print("PASS: nonblocking center toast, no input capture, timed fade, manual dismissal and no popup stacking")
