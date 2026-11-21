-- Integrated top UI reservation: recreate Titan-style spacing without
-- resizing Blizzard's root, changing bag/item buttons, or moving in combat.
local combat=false
_G.ChalkBoxDB={bar="top",barReserve=false}
_G.UIParent={
    ClearAllPoints=function() error("cannot move UIParent") end,
    SetPoint=function() error("cannot anchor UIParent") end,
    SetSize=function() error("cannot resize UIParent") end,
}
local function Native(point,x,y,protected,user)
    local f={point=point,relative=UIParent,relativePoint=point,
        x=x,y=y,protected=protected,user=user,moves=0}
    function f:GetNumPoints() return 1 end
    function f:GetPoint() return self.point,self.relative,
        self.relativePoint,self.x,self.y end
    function f:ClearAllPoints() self.point=nil end
    function f:SetPoint(p,rel,relP,dx,dy)
        self.point,self.relative,self.relativePoint,self.x,self.y=
            p,rel,relP,dx,dy
        self.moves=self.moves+1
    end
    function f:IsProtected() return self.protected end
    function f:IsUserPlaced() return self.user end
    return f
end
_G.MinimapCluster=Native("TOPRIGHT",-23,-8,false,false)
_G.BuffFrame=Native("TOPRIGHT",-176,-6,false,false)
_G.PlayerFrame=Native("TOPLEFT",14,-20,true,false)
_G.TargetFrame=Native("TOPLEFT",230,-20,false,true)
_G.TicketStatusFrame=Native("TOPRIGHT",-40,-15,false,false)
_G.WorldStateAlwaysUpFrame=Native("TOP",0,-21,false,false)
_G.InCombatLockdown=function() return combat end
local events={}
_G.CreateFrame=function()
    local f={registered={}}
    function f:RegisterEvent(event) self.registered[event]=true end
    function f:SetScript(_,callback) self.callback=callback end
    events[#events+1]=f
    return f
end
assert(loadfile("ScreenLayout.lua"))("ChalkBox")
local e=events[1]
local function Fire(event,...)
    assert(e.registered[event],event.." must be subscribed")
    e.callback(e,event,...)
end
Fire("ADDON_LOADED","ChalkBox")
assert(ChalkBoxDB.barShiftChrome==true,"the saved preference is kept")
local before={
    MinimapCluster.y,BuffFrame.y,PlayerFrame.y,TargetFrame.y,
    TicketStatusFrame.y,WorldStateAlwaysUpFrame.y,
    MinimapCluster.moves,PlayerFrame.moves,
}
Fire("PLAYER_ENTERING_WORLD")
Fire("UI_SCALE_CHANGED")
Fire("DISPLAY_SIZE_CHANGED")
ChalkBox_ScreenLayoutAdjust()
assert(MinimapCluster.y==before[1] and BuffFrame.y==before[2]
    and PlayerFrame.y==before[3] and TargetFrame.y==before[4]
    and TicketStatusFrame.y==before[5] and WorldStateAlwaysUpFrame.y==before[6]
    and MinimapCluster.moves==before[7] and PlayerFrame.moves==before[8],
    "login never moves the minimap, buffs, or unit frames")
local st=ChalkBox_ScreenLayoutStatus()
assert(st.moved==0 and st.reason=="Blizzard frames stay put"
    and st.skippedProtected>=1,
    "status reports that Blizzard frames were left alone")
combat=true
assert(ChalkBox_ScreenLayoutSet(false)==true)
assert(ChalkBox_ScreenLayoutStatus().pending
    and MinimapCluster.moves==before[7],
    "combat does not move chrome either")
combat=false
Fire("PLAYER_REGEN_ENABLED")
assert(MinimapCluster.y==before[1] and PlayerFrame.moves==before[8],
    "leaving combat still does not move Blizzard frames")
assert(ChalkBox_ScreenLayoutSet(true) and ChalkBoxDB.barShiftChrome==true)
assert(MinimapCluster.moves==before[7],
    "turning the old shift back on does not resume moving frames")
print("PASS: top chrome is never moved, so login cannot block a Blizzard-only action")
