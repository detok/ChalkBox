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
assert(ChalkBoxDB.barShiftChrome==true,"top chrome spacing enabled by default")
Fire("PLAYER_ENTERING_WORLD")
assert(MinimapCluster.y==-26 and BuffFrame.y==-24
    and TicketStatusFrame.y==-33 and WorldStateAlwaysUpFrame.y==-39,
    "unprotected Blizzard chrome shifts down exactly 18px")
assert(PlayerFrame.y==-20 and TargetFrame.y==-20,
    "protected unit frame and user-placed frame are never touched")
local st=ChalkBox_ScreenLayoutStatus()
assert(st.moved==4 and st.skippedProtected>=1 and st.skippedCustom>=1,
    "layout reports moved, protected, and custom frame counts")
local prior=MinimapCluster.moves
Fire("PLAYER_ENTERING_WORLD")
Fire("UI_SCALE_CHANGED")
assert(MinimapCluster.moves==prior and MinimapCluster.y==-26,
    "repeated events never stack offsets or reposition already shifted UI")
_G.ChalkBox_BarTopInsetStatus=function()
    return {mode="manual",effective=40}
end
ChalkBox_ScreenLayoutAdjust()
assert(MinimapCluster.y==-66 and BuffFrame.y==-64,
    "Mac safe area is added to the normal 18px bar spacing")
local movesAt40=MinimapCluster.moves
ChalkBox_ScreenLayoutAdjust()
assert(MinimapCluster.moves==movesAt40 and MinimapCluster.y==-66,
    "rechecking the same notch inset never stacks or drifts native UI")
_G.ChalkBox_BarTopInsetStatus=function()
    return {mode="auto",effective=0}
end
ChalkBox_ScreenLayoutAdjust()
assert(MinimapCluster.y==-26,
    "switching to an external display restores the ordinary top chrome shift")
_G.ChalkBox_BarTopInsetStatus=nil
assert(ChalkBox_ScreenLayoutSet(false))
assert(MinimapCluster.y==-8 and BuffFrame.y==-6
    and TicketStatusFrame.y==-15 and WorldStateAlwaysUpFrame.y==-21,
    "disabling restores exact original anchors")
assert(ChalkBox_ScreenLayoutStatus().moved==0)
assert(ChalkBox_ScreenLayoutSet(true))
assert(MinimapCluster.y==-26 and BuffFrame.y==-24)
-- Another addon / Edit Mode takes ownership while our offset is active.
BuffFrame:ClearAllPoints()
BuffFrame:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-176,-90)
Fire("DISPLAY_SIZE_CHANGED")
assert(BuffFrame.y==-90,"never override an external frame move")
-- If combat starts, defer disabling; a combat event cannot move any frame.
local moves=MinimapCluster.moves
combat=true
ChalkBox_ScreenLayoutSet(false)
assert(MinimapCluster.y==-26 and MinimapCluster.moves==moves
    and ChalkBox_ScreenLayoutStatus().pending,
    "combat locks down even unprotected top chrome repositioning")
combat=false
Fire("PLAYER_REGEN_ENABLED")
assert(MinimapCluster.y==-8 and BuffFrame.y==-90,
    "after-combat restore honors other addons' moved frames")
ChalkBox_ScreenLayoutSet(true)
assert(BuffFrame.y==-90,
    "externally owned frames stay untouched for the rest of the session")
-- The bottom Bar should never push top UI around.
ChalkBoxDB.bar="bottom"
ChalkBox_ScreenLayoutAdjust()
assert(MinimapCluster.y==-8 and BuffFrame.y==-90)
ChalkBoxDB.bar="off"
ChalkBox_ScreenLayoutAdjust()
assert(ChalkBox_ScreenLayoutStatus().moved==0)
-- Unknown protection state is not permission to relocate a stock frame.
_G.MinimapCluster=Native("TOPRIGHT",-23,-8,false,false)
MinimapCluster.IsProtected=nil
ChalkBoxDB.bar="top"
ChalkBox_ScreenLayoutAdjust()
assert(MinimapCluster.y==-8,
    "frames without IsProtected must be left to Blizzard")
print("PASS: Titan-style safe top-chrome shift, no UIParent or secure frame writes, reversible anchors, no combat moves and no stacking")
