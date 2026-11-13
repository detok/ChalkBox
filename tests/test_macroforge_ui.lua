-- MacroForge UI: native spell browsing, safe selection/copy and explicit
-- creation. Does not require running the WoW client in CI.
local frames,fonts,printed={}, {},{}
_G.UIParent={}
_G.DEFAULT_CHAT_FRAME={AddMessage=function(_,s) printed[#printed+1]=s end}
_G.ChatFontNormal={}
local function Create(kind,name,parent)
    local f={kind=kind,name=name,parent=parent,shown=false,
        text="",checked=false,scripts={}}
    function f:SetSize(w,h) self.w=w;self.h=h end
    function f:SetPoint(...) self.point={...} end
    function f:SetFrameStrata() end
    function f:SetMovable() end
    function f:SetClampedToScreen() end
    function f:EnableMouse() end
    function f:RegisterForDrag() end
    function f:SetScript(event,fn) self.scripts[event]=fn end
    function f:SetText(value)
        self.text=value
        if self.kind=="EditBox" and self.scripts.OnTextChanged then
            self.scripts.OnTextChanged(self)
        end
    end
    function f:GetText() return self.text end
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:IsShown() return self.shown end
    function f:SetAutoFocus() end
    function f:SetMultiLine(on) self.multiLine=on end
    function f:SetFontObject() end
    function f:SetFocus() self.focused=true end
    function f:ClearFocus() self.focused=false end
    function f:HighlightText(a,b) self.highlighted={a,b} end
    function f:GetChecked() return self.checked end
    function f:SetChecked(v) self.checked=v end
    function f:CreateTexture()
        local t={}
        function t:SetAllPoints() end
        function t:SetPoint() end
        function t:SetSize() end
        function t:SetHeight() end
        function t:SetColorTexture(...) self.color={...} end
        function t:SetTexture(value) self.texture=value end
        function t:Show() end
        function t:Hide() end
        return t
    end
    function f:CreateFontString()
        local t={text=""}
        function t:SetPoint() end
        function t:SetWidth() end
        function t:SetJustifyH() end
        function t:SetText(s) self.text=s end
        fonts[#fonts+1]=t
        return t
    end
    frames[#frames+1]=f
    return f
end
_G.CreateFrame=Create
local spells={{name="Hunter's Mark",id=1130,icon=123},
    {name="Serpent Sting",id=1978,icon=124},
    {name="Rapid Fire",id=3045,icon=125},
    {name="Mend Pet",id=136,icon=126}}
local saves={}
local installs=0
_G.ChalkBox_ForgeTemplates=function()
    return {{id="engage",name="Engage Target"},
        {id="burst",name="Burst + Trinkets"},
        {id="modifiers",name="Modifier Keys"},
        {id="sequence",name="Manual Sequence"},
        {id="utility",name="Mouseover Utility"}}
end
_G.ChalkBox_ForgeScan=function() return spells end
_G.ChalkBox_ForgeSpells=function(filter)
    local filtered={}
    for _,s in ipairs(spells) do
        if not filter or filter=="" or
            s.name:lower():find(filter:lower(),1,true) then
            filtered[#filtered+1]=s
        end
    end
    return filtered
end
_G.ChalkBox_ForgeDraft=function(t)
    return {version=1,template=t or "engage",class="HUNTER",
        main=t=="burst" and 3045 or 1130,shift=nil,pet=t=="engage"}
end
_G.ChalkBox_ForgeGetDraft=function() return ChalkBox_ForgeDraft("engage") end
_G.ChalkBox_ForgeStatus=function()
    return {class="HUNTER",spells=#spells,saved=#saves}
end
_G.ChalkBox_ForgeSet=function(d,key,val)
    d[key]=val;return true
end
_G.ChalkBox_ForgeGenerate=function(d)
    local ability
    for _,s in ipairs(spells) do
        if s.id==d.main then ability=s.name end
    end
    if not ability then return {body="",bytes=0,limit=255,
        valid=false,errors={"No learned spell"},warnings={}} end
    local body="#showtooltip\n/cast "..ability
    return {body=body,bytes=#body,limit=255,valid=true,
        errors={},warnings={"One spell per press."}}
end
_G.ChalkBox_ForgeSaved=function()
    local r={}
    for _,s in ipairs(saves) do r[#r+1]={name=s.name} end
    return r
end
_G.ChalkBox_ForgeSave=function(name,d)
    saves[#saves+1]={name=name,draft=d}
    return true,"saved"
end
_G.ChalkBox_ForgeLoad=function(i)
    if saves[i] then return saves[i].draft,saves[i].name end
end
_G.ChalkBox_ForgeDelete=function(i)
    if not saves[i] then return false end
    table.remove(saves,i)
    return true
end
_G.ChalkBox_ForgeInstall=function(name,d)
    installs=installs+1
    return true,"created"
end
_G.ChalkBox_ThemeBackground=function() return 0.1,0.2,0.3,0.88 end
_G.ChalkBox_ThemeAccent=function() return 0.8,0.7,0.4 end
assert(loadfile("MacroForgeUI.lua"))("ChalkBox")
assert(installs==0 and #frames==0,"UI is lazy; no frame or macro created on login")
assert(ChalkBox_OpenMacroForge())
local window
for _,f in ipairs(frames) do
    if f.name=="ChalkBoxMacroForge" then window=f end
end
assert(window and window:IsShown() and window.w==786 and
    window.h==678,"builder is a standalone movable, themed window")
assert(window.back.color[4]==0.88)
assert(installs==0,"opening the builder never alters existing macros")
local function Click(label)
    for _,f in ipairs(frames) do
        if f.kind=="Button" and f.text==label and f.scripts.OnClick then
            f.scripts.OnClick(f)
            return f
        end
    end
    error("Missing button: "..label)
end
Click("Burst + Trinkets")
local found=false
for _,f in ipairs(frames) do
    if f.kind=="EditBox" and f.text=="#showtooltip\n/cast Rapid Fire" then
        found=true
    end
end
assert(found,"purpose template regenerates actual preview")
local textSelect=Click("Select Text")
local preview
for _,f in ipairs(frames) do
    if f.kind=="EditBox" and f.multiLine then preview=f end
end
assert(preview and preview.focused and preview.highlighted and
    preview.highlighted[1]==0 and
    preview.highlighted[2]==#preview.text,
    "select highlights generated macro for manual Ctrl+C")
assert(installs==0,"selecting text does not install a native macro")
Click("Install New")
assert(installs==1,"one explicit click installs a macro")
Click("Save")
assert(#saves==1,"saved recipe created only on button click")
Click("Load")
Click("Delete")
assert(#saves==1,"first delete click only requests confirmation")
Click("Delete")
assert(#saves==0,"second explicit click deletes saved recipe only")
Click("X")
assert(not window:IsShown(),"builder can close without touching game macros")
print("PASS: lazy native MacroForge wizard, template selection, preview Ctrl+C, explicit install, save/load and confirmed delete")
