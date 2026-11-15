-- MacroForge UI: native spell browsing, safe selection/copy and explicit
-- creation. Does not require running the WoW client in CI.
local frames,fonts,printed={}, {},{}
_G.UIParent={}
_G.ChalkBoxDB={}
_G.BackdropTemplateMixin={}
_G.DEFAULT_CHAT_FRAME={AddMessage=function(_,s) printed[#printed+1]=s end}
_G.ChatFontNormal={}
local function Create(kind,name,parent,template)
    local f={kind=kind,name=name,parent=parent,shown=false,
        text="",checked=false,scripts={}}
    if template=="BackdropTemplate" then
        function f:SetBackdrop(spec) self.backdrop=spec end
        function f:SetBackdropColor(...) self.backdropFill={...} end
        function f:SetBackdropBorderColor(...) self.backdropBorder={...} end
    end
    function f:SetSize(w,h) self.w=w;self.h=h end
    function f:SetHeight(h) self.h=h end
    function f:GetStringHeight()
        return math.max(12,math.ceil(#(self.text or "")/35)*12)
    end
    function f:SetScrollChild(child) self.child=child end
    function f:SetVerticalScroll(pos) self.scroll=pos end
    function f:GetVerticalScroll() return self.scroll or 0 end
    function f:GetVerticalScrollRange()
        return math.max(0,((self.child and self.child.h) or 0)-(self.h or 0))
    end
    function f:EnableMouseWheel(value) self.mouseWheel=value end
    function f:LockHighlight() self.highlightLocked=true end
    function f:UnlockHighlight() self.highlightLocked=false end
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
        function t:SetPoint(...) self.anchor={...} end
        function t:SetSize(w,h) self.w=w;self.h=h end
        function t:SetHeight() end
        function t:SetColorTexture(...) self.color={...} end
        function t:SetTexture(value) self.texture=value end
        function t:SetAtlas(value)
            if _G.testNoMapAtlas then return false end
            self.atlas=value;return true
        end
        function t:SetHorizTile(on) self.horizontal=on end
        function t:SetVertTile(on) self.vertical=on end
        function t:Show() self.shown=true end
        function t:Hide() self.shown=false end
        return t
    end
    function f:CreateFontString()
        local t={text=""}
        function t:SetPoint(...) self.anchor={...} end
        function t:SetWidth(w) self.w=w end
        function t:SetHeight(h) self.h=h end
        function t:SetJustifyH() end
        function t:SetJustifyV(v) self.vAlign=v end
        function t:SetWordWrap(on) self.wordWrap=on end
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
assert(window.back.color[4]>=0.30 and window.back.color[4]<=0.37
    and window.back.color[1]>window.back.color[2]
    and window.back.color[2]>window.back.color[3]
    and window.mapArt.atlas==
    "gamepad-mapquestlog-bgtile-2k" and window.mapArt.horizontal
    and window.mapArt.vertical,
    "native map art is tiled under a dark readable theme glaze")
assert(window.backdrop and window.backdrop.edgeFile==
    "Interface\\DialogFrame\\UI-DialogBox-Border"
    and window.backdropBorder and window.backdropBorder[4]==1,
    "MacroForge's standalone window gets Discoveries' native outer border")
for _,key in ipairs({"purpose","slots","spellbook","options","saved",
    "preview","name"}) do
    local visual=window.sectionVisuals[key]
    assert(window.sections[key] and window.sections[key].width>0,
        "each MacroForge group has its own decorative inset: "..key)
    assert(visual and visual.shadow and visual.rim and visual.glint
        and visual.fill and visual.lower,
        "each inset has a bronze rim, bevel and soft shadow: "..key)
    assert(visual.fill.color[1]>visual.fill.color[2]
        and visual.fill.color[2]>visual.fill.color[3]
        and visual.fill.color[4]>=0.9,
        "warm charcoal insets replace the former gray sheet")
    assert(visual.shadow.color[4]>0.6,
        "the workbench panels have visible depth without changing controls")
end
assert(window.sections.saved.y-window.sections.saved.height>=
    window.sections.name.y,"saved warning area ends above macro naming section")
assert(window.previewEditor and window.previewViewport
    and window.previewViewport.child==window.previewEditor,
    "macro preview uses a real clipped multiline scroll viewport")
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
local bounds=window.previewViewport
preview:SetText(("#showtooltip\n/cast Hunter's Mark\n"):rep(15))
assert(preview.h>bounds.h and preview:GetText():find("Hunter's Mark"),
    "long multi-line preview expands within the scroll child, not its border")
bounds.scripts.OnMouseWheel(bounds,-1)
assert((bounds.scroll or 0)>0,"scrollwheel reaches long macro text")
Click("Engage Target")
local warning
for _,font in ipairs(fonts) do
    if font.text=="One spell per press." then warning=font end
end
assert(warning and warning.h==59 and warning.wordWrap and warning.vAlign=="TOP",
    "warnings have a reserved bounded, multiline-aware area")
assert(warning.anchor[5]-warning.h >
    window.sections.name.y,
    "warning text ends above the macro name inset")
assert(installs==0,"copying and scrolling never installs a native macro")
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
assert(not ChalkBox_MacroForgeCompartmentStatus().enabled and
    not ChalkBox_MacroForgeCompartmentRefresh(),
    "the optional compartment entry is absent on fresh load")
local registrations={}
_G.AddonCompartmentFrame={RegisterAddon=function(_,entry)
    registrations[#registrations+1]=entry
    return true
end}
assert(ChalkBox_MacroForgeCompartmentSet(true))
assert(#registrations==1 and registrations[1].text=="MacroForge"
    and registrations[1].notCheckable==true,
    "opt-in adds only one native MacroForge compartment entry")
assert(ChalkBox_MacroForgeCompartmentRefresh() and #registrations==1,
    "login refresh never duplicates the compartment entry")
registrations[1].func()
assert(window:IsShown(),"compartment shortcut opens the existing wizard")
assert(ChalkBox_MacroForgeCompartmentSet(false))
assert(ChalkBox_MacroForgeCompartmentStatus().reloadRequired
    and not ChalkBox_MacroForgeCompartmentStatus().enabled,
    "unchecking persists OFF without mutating Blizzard compartment internals")
assert(#registrations==1,"native registration remains until reload")
-- A client without the native atlas must still get an opaque readable
-- editor; never leave a see-through dark map placeholder.
_G.testNoMapAtlas=true
_G.BackdropTemplateMixin=nil
assert(loadfile("MacroForgeUI.lua"))("ChalkBox")
assert(ChalkBox_OpenMacroForge())
local fallback=frames[#frames]
for i=#frames,1,-1 do
    if frames[i].name=="ChalkBoxMacroForge" then
        fallback=frames[i];break
    end
end
assert(not fallback.hasMapArt and fallback.back.color[4]>=0.94,
    "missing Forever map atlas falls back to an opaque panel")
assert(not fallback.backdrop,
    "client without BackdropTemplate does not attempt protected native methods")
_G.testNoMapAtlas=nil
fallback:RefreshMapArt()
assert(fallback.hasMapArt,
    "MacroForge retries the same native atlas after it becomes available")
ChalkBox_OpenMacroForge()
assert(fallback.back.color[4]<=0.37,
    "refreshed MacroForge warm wood remains visible after late atlas load")
print("PASS: warm wood MacroForge with matching dialog border and shadowed bronze insets, map fallback, preview, warnings, compartment and saved macros")
