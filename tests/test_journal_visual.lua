-- Adventure Journal is a separate movable native frame, with atlas/no-atlas
-- fallback, readable opacity, two ordered inset sections and theme refresh.
_G.ChalkBoxZoneDB={}
_G.BackdropTemplateMixin={}
_G.UIParent={}
local atlasAvailable=false
local accent={0.86,0.66,0.38}
local windows={}
local active
_G.GetTime=function() return 100 end
_G.UnitXP=function() return 0 end
_G.UnitXPMax=function() return 1000 end
_G.GetMoney=function() return 10000 end
_G.C_Texture={GetAtlasExists=function() return atlasAvailable end}
_G.ChalkBox_ThemeBackground=function() return 0.018,0.018,0.022,0 end
_G.ChalkBox_ThemeAccent=function()
    return accent[1],accent[2],accent[3]
end
local function Frame(kind,name,parent,template)
    local f={kind=kind,name=name,parent=parent,textureRegions={},
        fonts={},scripts={}}
    if name then windows[name]=f end
    function f:RegisterEvent() end
    function f:SetScript(event,fn) self.scripts[event]=fn end
    function f:SetSize(w,h) self.w=w;self.h=h end
    function f:SetPoint(...) self.anchor={...} end
    function f:SetFrameStrata(value) self.strata=value end
    function f:SetMovable(value) self.movable=value end
    function f:EnableMouse(value) self.mouse=value end
    function f:RegisterForDrag(...) self.drag={...} end
    function f:SetText(value) self.caption=value end
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:IsShown() return self.shown end
    function f:CreateTexture(_,layer,_,sublevel)
        local t={layer=layer,sublevel=sublevel}
        function t:SetAllPoints() self.all=true end
        function t:SetPoint(...) self.anchor={...} end
        function t:SetSize(w,h) self.w=w;self.h=h end
        function t:SetHeight(h) self.h=h end
        function t:SetTexture(value) self.texture=value end
        function t:SetColorTexture(...) self.color={...} end
        function t:SetVertexColor(...) self.color={...} end
        function t:SetAtlas(value)
            if not atlasAvailable then return false end
            self.atlas=value;return true
        end
        function t:GetAtlas() return self.atlas end
        function t:SetHorizTile(value) self.tileX=value end
        function t:SetVertTile(value) self.tileY=value end
        function t:Hide() self.shown=false end
        function t:Show() self.shown=true end
        f.textureRegions[#f.textureRegions+1]=t
        return t
    end
    function f:CreateFontString(_,layer,style)
        local t={layer=layer,style=style}
        function t:SetPoint(...) self.anchor={...} end
        function t:SetWidth(w) self.width=w end
        function t:SetJustifyH(value) self.align=value end
        function t:SetText(value) self.value=value end
        f.fonts[#f.fonts+1]=t
        return t
    end
    if template=="BackdropTemplate" then
        function f:SetBackdrop(value) self.backdrop=value end
        function f:SetBackdropColor(...) self.backdropColor={...} end
        function f:SetBackdropBorderColor(...) self.borderColor={...} end
    end
    return f
end
_G.CreateFrame=Frame
assert(loadfile("SessionJournal.lua"))("ChalkBox")
assert(ChalkBox_OpenSessionJournal("current"))
local journal=windows.ChalkBoxSessionJournal
assert(journal and journal.w==590 and journal.h==460,
    "journal frame remains movable and has the original footprint")
assert(journal.backdrop and journal.backdrop.edgeFile==
    "Interface\\DialogFrame\\UI-DialogBox-Border",
    "journal matches the Discoveries native outer frame")
assert(not journal.hasMapArt and journal.bg.color[4]>=0.92,
    "no atlas and zero theme opacity still produce an opaque reading body")
assert(#journal.panels==2 and journal.panels[1].shadow.color[4]>=0.65
    and journal.panels[1].fill.color[4]>=0.9,
    "warm bronze inset sections and shadows are visible")
local headings={}
for _,font in ipairs(journal.fonts) do
    if font.value then headings[font.value]=true end
end
assert(headings["SESSION SUMMARY"] and headings["FIELD NOTES"],
    "sections have clearly distinguishable headings")
assert(not journal.hasMapArt,"atlas is not inferred when client says unavailable")
atlasAvailable=true
assert(ChalkBox_OpenSessionJournal("current"))
assert(journal.hasMapArt and journal.mapArt.atlas==
    "gamepad-mapquestlog-bgtile-2k" and journal.mapArt.tileX
    and journal.mapArt.tileY,
    "opening retries native map art and keeps the same journal frame")
assert(journal.bg.color[4]>0.25 and journal.bg.color[4]<0.36
    and journal.backdropColor[4]<0.2,
    "warm wood art stays visible under a light glaze")
accent={0.40,0.79,0.72}
ChalkBox_JournalThemeRefresh()
assert(journal.stripe.color[2]==0.79 and journal.borderColor[2]==0.79,
    "global theme changes update the accent and border immediately")
assert(ChalkBoxZoneDB.sessionJournal.version==1 and
    type(ChalkBoxZoneDB.sessionJournal.current)=="table",
    "visual upgrade does not migrate or corrupt the existing v1 session data")
local old=journal
assert(ChalkBox_OpenSessionJournal("current") and
    windows.ChalkBoxSessionJournal==old,
    "reopening reuses the same movable journal rather than duplicating windows")
print("PASS: Journal native frame, warm insets, atlas retry, zero-opacity fallback, live accent and preserved session schema")
