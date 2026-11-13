-- Toasts default to the TOP, are click-through when locked, movable
-- only while unlocked, and save opacity and location in the existing camp DB.
local now=200
_G.GetTime=function() return now end
_G.InCombatLockdown=function() return false end
_G.UIParent={GetCenter=function() return 700,450 end}
_G.ChalkBoxDB={camp={}}
local frames={}
_G.CreateFrame=function(kind,name)
    local f={name=name,shown=false,x=920,y=580}
    function f:SetSize(w,h) self.w,self.h=w,h end
    function f:SetPoint(...) self.anchor={...} end
    function f:ClearAllPoints() self.anchor=nil end
    function f:SetFrameStrata(s) self.strata=s end
    function f:SetMovable(v) self.movable=v end
    function f:SetClampedToScreen(v) self.clamped=v end
    function f:RegisterForDrag(v) self.dragButton=v end
    function f:EnableMouse(v) self.mouse=v end
    function f:StartMoving() self.moving=true end
    function f:StopMovingOrSizing() self.moving=false end
    function f:GetCenter() return self.x,self.y end
    function f:CreateTexture()
        local t={}
        function t:SetAllPoints() end
        function t:SetColorTexture(...) self.color={...} end
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
    function f:SetAlpha(a) self.alpha=a end
    function f:SetScript(k,callback) self[k]=callback end
    frames[#frames+1]=f
    return f
end
assert(loadfile("ReminderToast.lua"))("ChalkBox")
assert(ChalkBox_ShowReminder("Time to check your camping.","Adventure Prep"))
local root=frames[1]
assert(root.name=="ChalkBoxAdventureToast" and #frames==1)
assert(root.shown and not root.mouse and root.movable and root.dragButton=="LeftButton")
assert(root.w==430 and root.h==72,
    "compact branded toast instead of large blue reminder rectangle")
assert(root.anchor[1]=="TOP" and root.anchor[5]==-112,
    "new toast starts near the TOP of the game screen")
assert(root.strata=="DIALOG" and root.alpha==1,
    "background strength does not reduce the text opacity")
assert(ChalkBox_ToastStatus().locked and ChalkBox_ToastStatus().opacity==0.92)
now=207.5;root.OnUpdate(root)
assert(root.shown and root.alpha<0.92 and root.alpha>0,
    "fades from saved transparency, never starts at full opacity")
now=210;root.OnUpdate(root)
assert(not root.shown)
assert(ChalkBox_ToastCommand("unlock"))
assert(root.mouse and not ChalkBox_ToastStatus().locked,
    "unlocked notice becomes draggable only while preview is visible")
assert(ChalkBox_ToastCommand("preview"))
assert(root.shown and root.alpha==1)
root.OnDragStart(root)
assert(root.moving)
root.OnDragStop(root)
assert(not root.moving and ChalkBoxDB.camp.toastOptions.position=="custom")
assert(ChalkBoxDB.camp.toastOptions.x==220 and
    ChalkBoxDB.camp.toastOptions.y==130,
    "drag stores offsets relative to UIParent center")
assert(root.anchor[1]=="CENTER" and root.anchor[4]==220)
assert(ChalkBox_ToastCommand("opacity 65"))
assert(root.alpha==1 and root.background.color[4]==0.65 and
    ChalkBox_ToastStatus().opacity==0.65,
    "toast local opacity affects its background, not its readable words")
now=223;root.OnUpdate(root)
assert(root.shown,"extended position preview lasts 25 seconds")
assert(ChalkBox_ToastCommand("lock"))
assert(not root.mouse and ChalkBox_ToastStatus().locked)
root.OnDragStart(root)
assert(not root.moving,"locked notice never begins a drag")
assert(ChalkBox_ToastCommand("reset"))
assert(root.anchor[1]=="TOP" and ChalkBox_ToastStatus().position=="top")
now=236;root.OnUpdate(root)
assert(not root.shown,"preview eventually disappears")
assert(ChalkBox_ShowReminder("Second reminder"))
assert(#frames==1,"one reused toast, no stacking or duplicate frame")
assert(root.alpha==1 and root.background.color[4]==0.65,
    "background transparency persists between alerts while text remains crisp")
ChalkBox_HideReminder()
assert(not root.shown)
print("PASS: top-screen toast, click-through lock, drag and saved position, 35-100% opacity, 25s preview, timed fade and reuse")
