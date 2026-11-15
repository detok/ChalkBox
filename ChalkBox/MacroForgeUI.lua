-- ChalkBox MacroForge UI: native, editable-in-config macro wizard.
-- No action runs in combat, no rotation automation, no hidden macro edits.
local window,draft,rendered
local presetButtons,slotButtons,spellRows,checks={},{},{},{}
local spellPage,libraryIndex,activeSlot=1,1,"main"
local search,macroText,warningText,statusText,libraryText,nameEdit,selectionText
local themeTextures={}
local sectionFrames={}
local MAP_ATLAS="gamepad-mapquestlog-bgtile-2k"
local compartmentRegistered=false
local slots={
    {"main","Main spell"},{"shift","Shift"},{"alt","Alt"},
    {"ctrl","Ctrl"},{"sequenceSecond","Sequence #2"},
    {"sequenceThird","Sequence #3"},
}
local switches={
    {"pet","Pet attack"},{"autoShot","Auto Shot"},
    {"trinket13","Trinket 13"},{"trinket14","Trinket 14"},
    {"mouseover","Mouseover"},{"ally","Friendly target"},
}
local function Note(msg)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff67c6b7MacroForge|r "..msg)
    end
end
local function Theme()
    if not window then return end
    local r,g,b,a=0.018,0.018,0.022,0.97
    if type(ChalkBox_ThemeBackground)=="function" then
        r,g,b,a=ChalkBox_ThemeBackground(0.97)
    end
    -- Readable even with a transparent global theme.
    local alpha=window.hasMapArt and math.max(0.84,math.min(a,0.92))
        or math.max(0.94,a)
    if window.back then window.back:SetColorTexture(r,g,b,alpha) end
    if window.accent then
        local ar,ag,ab=0.86,0.66,0.38
        if type(ChalkBox_ThemeAccent)=="function" then
            ar,ag,ab=ChalkBox_ThemeAccent()
        end
        window.accent:SetColorTexture(ar,ag,ab,1)
    end
    for _,t in ipairs(themeTextures) do
        if t and t.SetColorTexture then
            t:SetColorTexture(math.min(1,r*3+0.055),
                math.min(1,g*3+0.06),math.min(1,b*3+0.08),0.91)
        end
    end
end
function ChalkBox_MacroForgeThemeRefresh() Theme() end
local function Font(parent,text,style,x,y,width)
    local f=parent:CreateFontString(nil,"OVERLAY",style or "GameFontHighlight")
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    f:SetWidth(width)
    if f.SetJustifyH then f:SetJustifyH("LEFT") end
    f:SetText(text or "")
    return f
end
local function Button(parent,caption,w,x,y,callback)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(w,24)
    b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    b:SetText(caption)
    b:SetScript("OnClick",callback)
    return b
end
local function Checkbox(parent,caption,x,y,callback)
    local b=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate")
    b:SetSize(23,23)
    b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    Font(parent,caption,"GameFontHighlightSmall",x+28,y-4,139)
    b:SetScript("OnClick",function(self)
        callback(self.GetChecked and self:GetChecked() or false)
    end)
    return b
end
local function Edit(parent,width,height,x,y)
    local f=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
    f:SetSize(width,height)
    f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    if f.SetAutoFocus then f:SetAutoFocus(false) end
    if f.SetScript then
        f:SetScript("OnEscapePressed",function(self)
            if self.ClearFocus then self:ClearFocus() end
        end)
    end
    return f
end

-- Decorative inset borders surround existing Blizzard widgets; they never
-- own input and do not require the client to support BackdropTemplate.
local function Inset(parent,label,x,y,width,height)
    local fill=parent:CreateTexture(nil,"BORDER")
    fill:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    fill:SetSize(width,height)
    themeTextures[#themeTextures+1]=fill
    local function Edge(px,py,w,h)
        local edge=parent:CreateTexture(nil,"BORDER")
        edge:SetPoint("TOPLEFT",parent,"TOPLEFT",px,py)
        edge:SetSize(w,h)
        edge:SetColorTexture(0.47,0.38,0.22,0.65)
    end
    Edge(x,y,width,1);Edge(x,y-height+1,width,1)
    Edge(x,y,1,height);Edge(x+width-1,y,1,height)
    sectionFrames[label]={x=x,y=y,width=width,height=height}
end

-- Multiline edit text lives in a clipped viewport; a single-line native
-- InputBox border cannot contain a variable-length macro preview.
local function Preview(parent,x,y,width,height)
    local backing=parent:CreateTexture(nil,"ARTWORK")
    backing:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    backing:SetSize(width,height)
    backing:SetColorTexture(0.012,0.014,0.018,0.93)
    local function Edge(px,py,w,h)
        local t=parent:CreateTexture(nil,"ARTWORK")
        t:SetPoint("TOPLEFT",parent,"TOPLEFT",px,py)
        t:SetSize(w,h)
        t:SetColorTexture(0.40,0.33,0.21,0.78)
    end
    Edge(x,y,width,1);Edge(x,y-height+1,width,1)
    Edge(x,y,1,height);Edge(x+width-1,y,1,height)
    local viewport=CreateFrame("ScrollFrame",nil,parent)
    viewport:SetSize(width-14,height-10)
    viewport:SetPoint("TOPLEFT",parent,"TOPLEFT",x+7,y-5)
    local editor=CreateFrame("EditBox",nil,viewport)
    editor:SetSize(width-23,height-12)
    if editor.SetAutoFocus then editor:SetAutoFocus(false) end
    if editor.SetMultiLine then editor:SetMultiLine(true) end
    if editor.SetFontObject and ChatFontNormal then
        editor:SetFontObject(ChatFontNormal)
    end
    editor:SetPoint("TOPLEFT",viewport,"TOPLEFT",0,0)
    if viewport.SetScrollChild then viewport:SetScrollChild(editor) end
    if editor.SetScript then
        editor:SetScript("OnEscapePressed",function(self)
            if self.ClearFocus then self:ClearFocus() end
        end)
        editor:SetScript("OnTextChanged",function(self)
            local h=self.GetStringHeight and self:GetStringHeight() or 0
            if type(h)~="number" then h=0 end
            if self.SetHeight then self:SetHeight(math.max(height-12,h+16)) end
            if viewport.SetVerticalScroll then viewport:SetVerticalScroll(0) end
        end)
    end
    if viewport.EnableMouseWheel then viewport:EnableMouseWheel(true) end
    if viewport.SetScript then
        viewport:SetScript("OnMouseWheel",function(self,delta)
            if not self.SetVerticalScroll then return end
            local range=self.GetVerticalScrollRange and
                self:GetVerticalScrollRange() or 0
            if type(range)~="number" or range<=0 then return end
            local position=self.GetVerticalScroll and
                self:GetVerticalScroll() or 0
            self:SetVerticalScroll(math.max(0,math.min(range,position-delta*24)))
        end)
    end
    return editor,viewport
end

-- Blizzard exposes RegisterAddon but not a reliable public unregister API.
-- Keep the existing ChalkBox compartment entry and add one opt-in launcher.
-- Turning off an already registered launcher requires /reload.
local function CompartmentEnabled()
    return type(ChalkBoxDB)=="table" and ChalkBoxDB.macroCompartment==true
end
function ChalkBox_MacroForgeCompartmentStatus()
    return {
        enabled=CompartmentEnabled(),
        available=AddonCompartmentFrame~=nil and
            type(AddonCompartmentFrame.RegisterAddon)=="function",
        registered=compartmentRegistered,
        reloadRequired=compartmentRegistered and not CompartmentEnabled(),
    }
end
function ChalkBox_MacroForgeCompartmentRefresh()
    if compartmentRegistered then return true end
    if not CompartmentEnabled() then return false end
    local compartment=AddonCompartmentFrame
    if not compartment or type(compartment.RegisterAddon)~="function" then
        return false
    end
    if type(InCombatLockdown)=="function" and InCombatLockdown() then
        return false
    end
    local ok,registered=pcall(compartment.RegisterAddon,compartment,{
        text="MacroForge",
        icon="Interface\\AddOns\\ChalkBox\\assets\\Icon",
        notCheckable=true,
        func=function()
            if type(ChalkBox_OpenMacroForge)=="function" then
                ChalkBox_OpenMacroForge()
            end
        end,
    })
    compartmentRegistered=ok and registered~=false
    return compartmentRegistered
end
function ChalkBox_MacroForgeCompartmentSet(on)
    if type(ChalkBoxDB)~="table" then return false end
    ChalkBoxDB.macroCompartment=on==true
    if on then return ChalkBox_MacroForgeCompartmentRefresh() end
    return true
end

local function SpellLabel(id)
    if not id then return "(none)" end
    for _,spell in ipairs(ChalkBox_ForgeScan()) do
        if spell.id==id then return spell.name end
    end
    return "Unlearned #"..tostring(id)
end
local function DisplayWarnings(result)
    local warnings={}
    if not result.valid then
        for i=1,math.min(2,#result.errors) do
            warnings[#warnings+1]="ERROR: "..result.errors[i]
        end
    end
    for i=1,math.min(result.valid and 2 or 1,#result.warnings) do
        warnings[#warnings+1]=result.warnings[i]
    end
    return table.concat(warnings,"\n")
end
local function Spells()
    local filter=search and search.GetText and search:GetText() or ""
    return ChalkBox_ForgeSpells(filter)
end
local function RefreshSpells()
    if not window then return end
    local spells,err=Spells()
    local pages=math.max(1,math.ceil(#spells/#spellRows))
    if spellPage>pages then spellPage=pages end
    if spellPage<1 then spellPage=1 end
    selectionText:SetText(("Select %s  ·  %d spells  ·  page %d/%d"):format(
        activeSlot,#spells,spellPage,pages))
    for i,row in ipairs(spellRows) do
        local item=spells[(spellPage-1)*#spellRows+i]
        if item then
            row.spell=item
            row:SetText(item.name)
            if row.icon and row.icon.SetTexture then
                row.icon:SetTexture(item.icon or 134400)
                if row.icon.Show then row.icon:Show() end
            end
            row:Show()
        else
            row.spell=nil
            row:SetText("")
            if row.icon and row.icon.Hide then row.icon:Hide() end
            row:Hide()
        end
    end
    if err and statusText then statusText:SetText(err) end
end
local function Refresh()
    if not window then return end
    rendered=ChalkBox_ForgeGenerate(draft)
    for i,slot in ipairs(slots) do
        local label=slot[2].."  ·  "..SpellLabel(draft[slot[1]])
        if #label>29 then label=label:sub(1,26).."..." end
        local selected=activeSlot==slot[1]
        slotButtons[i]:SetText((selected and "› " or "")..label)
        if selected and slotButtons[i].LockHighlight then
            slotButtons[i]:LockHighlight()
        elseif not selected and slotButtons[i].UnlockHighlight then
            slotButtons[i]:UnlockHighlight()
        end
    end
    for i,opt in ipairs(switches) do
        checks[i]:SetChecked(draft[opt[1]]==true)
    end
    local status=ChalkBox_ForgeStatus()
    if statusText then
        statusText:SetText(("%s  ·  %d readable spells  ·  %d/%d bytes  ·  %s"):format(
            status.class,status.spells,rendered.bytes,rendered.limit,
            rendered.valid and "READY TO COPY" or "NEEDS ATTENTION"))
    end
    if macroText then macroText:SetText(rendered.body) end
    if warningText then warningText:SetText(DisplayWarnings(rendered)) end
    if nameEdit and nameEdit.GetText and nameEdit:GetText()=="" then
        nameEdit:SetText("CB "..(draft.template or "Macro"):sub(1,12))
    end
    if libraryText then
        local items=ChalkBox_ForgeSaved()
        local entry=items[libraryIndex]
        libraryText:SetText(entry and
            (("Saved %d/%d: %s"):format(libraryIndex,#items,entry.name)) or
            "No saved builds yet")
    end
    RefreshSpells()
end
function ChalkBox_MacroForgeRefresh()
    if window and window.IsShown and window:IsShown() then Refresh() end
end
local function PickTemplate(id)
    draft=ChalkBox_ForgeDraft(id)
    activeSlot="main";spellPage=1
    if search then search:SetText("") end
    Refresh()
end
local function SelectSpell(slot,id)
    if not ChalkBox_ForgeSet(draft,slot,id) then
        Note("Could not assign this ability.")
        return
    end
    Refresh()
end
local function SavedName()
    if not nameEdit or not nameEdit.GetText then return end
    local name=nameEdit:GetText() or ""
    name=name:gsub("^%s+",""):gsub("%s+$","")
    return name
end
local function SelectAll()
    if not rendered or not rendered.valid then
        Note("Fix validation errors before copying.")
        return false
    end
    if macroText then
        macroText:SetText(rendered.body)
        if macroText.SetFocus then macroText:SetFocus() end
        if macroText.HighlightText then
            macroText:HighlightText(0,#rendered.body)
        end
    end
    Note("Macro text selected. Press Ctrl+C, then open /macro and paste.")
    return true
end
local function Install()
    if not rendered or not rendered.valid then
        Note("Fix invalid spell selections first.")
        return
    end
    local name=SavedName()
    if not name then return end
    local ok,msg=ChalkBox_ForgeInstall(name,draft)
    Note(msg or (ok and "Created" or "Could not create macro"))
end
local function Save()
    local name=SavedName()
    if not name then return end
    local ok,msg=ChalkBox_ForgeSave(name,draft)
    Note(msg or (ok and "Saved" or "Could not save recipe"))
    if ok then libraryIndex=#ChalkBox_ForgeSaved() end
    Refresh()
end
local function Load()
    local d,name=ChalkBox_ForgeLoad(libraryIndex)
    if not d then
        Note("No saved recipe selected.")
        return
    end
    draft=d
    if nameEdit then nameEdit:SetText(name) end
    activeSlot="main"
    Refresh()
    Note("Loaded recipe. Spell choices are revalidated against your current book.")
end
local function Delete()
    if not window then return end
    if not window.pendingDelete then
        window.pendingDelete=true
        Note("Press Delete Saved again to confirm; this cannot affect WoW macros.")
        return
    end
    window.pendingDelete=false
    if ChalkBox_ForgeDelete(libraryIndex) then
        local count=#ChalkBox_ForgeSaved()
        libraryIndex=math.max(1,math.min(libraryIndex,count))
        Note("Saved recipe removed. Native macros were not changed.")
    end
    Refresh()
end
local function Native()
    if type(InCombatLockdown)=="function" and InCombatLockdown() then
        Note("Open /macro after combat.")
        return
    end
    if type(ShowMacroFrame)=="function" then
        local ok=pcall(ShowMacroFrame)
        if ok then return end
    end
    Note("Type /macro to open WoW's native macro list.")
end
local function Create()
    if window then return end
    if not UIParent or type(CreateFrame)~="function" then return end
    local f=CreateFrame("Frame","ChalkBoxMacroForge",UIParent)
    f:SetSize(786,678)
    f:SetPoint("CENTER",UIParent,"CENTER",0,0)
    if f.SetFrameStrata then f:SetFrameStrata("DIALOG") end
    if f.SetMovable then f:SetMovable(true) end
    if f.SetClampedToScreen then f:SetClampedToScreen(true) end
    if f.EnableMouse then f:EnableMouse(true) end
    if f.RegisterForDrag then f:RegisterForDrag("LeftButton") end
    f:SetScript("OnDragStart",function(self)
        if self.StartMoving and (type(InCombatLockdown)~="function"
            or not InCombatLockdown()) then self:StartMoving() end
    end)
    f:SetScript("OnDragStop",function(self)
        if self.StopMovingOrSizing then self:StopMovingOrSizing() end
    end)
    -- Native map parchment under an opaque-enough reading surface.
    local art=f:CreateTexture(nil,"BACKGROUND",nil,0)
    art:SetAllPoints(f)
    local hasArt=false
    if art.SetAtlas then
        local ok,result=pcall(art.SetAtlas,art,MAP_ATLAS,false)
        hasArt=ok and result~=false
    end
    if hasArt then
        if art.SetHorizTile then art:SetHorizTile(true) end
        if art.SetVertTile then art:SetVertTile(true) end
    elseif art.Hide then art:Hide() end
    f.mapArt=art
    f.hasMapArt=hasArt
    local back=f:CreateTexture(nil,"BACKGROUND",nil,1)
    back:SetAllPoints(f)
    f.back=back
    Inset(f,"purpose",14,-86,758,59)
    Inset(f,"slots",14,-150,408,213)
    Inset(f,"spellbook",430,-150,342,258)
    Inset(f,"options",14,-367,408,104)
    Inset(f,"saved",430,-410,342,152)
    Inset(f,"preview",14,-474,408,181)
    Inset(f,"name",430,-568,342,87)
    f.sections=sectionFrames
    local accent=f:CreateTexture(nil,"ARTWORK")
    accent:SetPoint("TOPLEFT",f,"TOPLEFT",0,0)
    accent:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0)
    accent:SetHeight(3);f.accent=accent
    Font(f,"MACROFORGE","GameFontNormalHuge",23,-19,550)
    Font(f,"Build from learned spells. One press cannot automate a rotation.",
        "GameFontHighlightSmall",25,-53,600)
    Button(f,"X",31,736,-20,function() f:Hide() end)
    Font(f,"CHOOSE A PURPOSE","GameFontNormal",23,-90,320)
    local x=22
    for _,tpl in ipairs(ChalkBox_ForgeTemplates()) do
        local id=tpl.id
        local label=tpl.name
        local width=id=="modifiers" and 145 or 137
        presetButtons[#presetButtons+1]=Button(f,label,width,x,-113,function()
            PickTemplate(id)
        end)
        x=x+width+9
    end
    Font(f,"ASSIGN LEARNED SPELLS","GameFontNormal",23,-158,362)
    Font(f,"SPELLBOOK","GameFontNormal",438,-158,300)
    local searchBox=Edit(f,254,22,444,-181)
    search=searchBox
    if search.SetScript then
        search:SetScript("OnTextChanged",function()
            spellPage=1;RefreshSpells()
        end)
    end
    Button(f,"Rescan",64,705,-180,function()
        ChalkBox_ForgeScan(true);Refresh()
    end)
    for i,slot in ipairs(slots) do
        local id=slot[1]
        local y=-184-(i-1)*29
        slotButtons[i]=Button(f,slot[2],366,23,y,function()
            activeSlot=id
            Refresh()
        end)
    end
    selectionText=Font(f,"Select main","GameFontHighlightSmall",438,-215,318)
    local top=-237
    for i=1,5 do
        local row=Button(f,"",298,445,top-(i-1)*27,function(self)
            if self.spell then SelectSpell(activeSlot,self.spell.id) end
        end)
        if row.CreateTexture then
            local icon=row:CreateTexture(nil,"ARTWORK")
            icon:SetSize(17,17)
            icon:SetPoint("LEFT",row,"LEFT",5,0)
            row.icon=icon
        end
        spellRows[#spellRows+1]=row
    end
    Button(f,"◀ Previous",111,446,-379,function()
        spellPage=math.max(1,spellPage-1);RefreshSpells()
    end)
    Button(f,"Next ▶",111,563,-379,function()
        spellPage=spellPage+1;RefreshSpells()
    end)
    Button(f,"Clear Slot",91,679,-379,function()
        SelectSpell(activeSlot,nil)
    end)
    Font(f,"OPTIONS","GameFontNormal",23,-366,160)
    for i,opt in ipairs(switches) do
        local col=math.floor((i-1)/3)
        local row=(i-1)%3
        checks[i]=Checkbox(f,opt[2],23+col*194,-389-row*26,
            function(on)
                ChalkBox_ForgeSet(draft,opt[1],on);Refresh()
            end)
    end
    Font(f,"MACRO PREVIEW","GameFontNormal",23,-480,210)
    local preview,viewport=Preview(f,24,-500,371,103)
    macroText=preview
    f.previewViewport=viewport
    f.previewEditor=preview
    Font(f,"Select Text highlights this preview so you can copy with Ctrl+C.",
        "GameFontHighlightSmall",24,-609,392)
    warningText=Font(f,"","GameFontHighlightSmall",438,-497,319)
    if warningText.SetHeight then warningText:SetHeight(59) end
    if warningText.SetJustifyV then warningText:SetJustifyV("TOP") end
    if warningText.SetWordWrap then warningText:SetWordWrap(true) end
    statusText=Font(f,"","GameFontHighlightSmall",24,-75,712)
    Font(f,"MACRO NAME","GameFontNormal",439,-576,170)
    nameEdit=Edit(f,214,22,438,-600)
    Button(f,"Select Text",121,25,-625,function() SelectAll() end)
    Button(f,"Install New",121,153,-625,function() Install() end)
    Button(f,"Native Macros",109,280,-625,function() Native() end)
    -- Saved recipes have no impact on Blizzard's own macro list.
    Font(f,"SAVED BUILDS","GameFontNormal",438,-417,196)
    libraryText=Font(f,"No saved builds","GameFontHighlightSmall",438,-440,318)
    Button(f,"◀",40,438,-462,function()
        libraryIndex=math.max(1,libraryIndex-1);Refresh()
    end)
    Button(f,"▶",40,483,-462,function()
        libraryIndex=math.min(#ChalkBox_ForgeSaved(),libraryIndex+1)
        Refresh()
    end)
    Button(f,"Save",73,529,-462,function() Save() end)
    Button(f,"Load",73,607,-462,function() Load() end)
    Button(f,"Delete",73,685,-462,function() Delete() end)
    window=f
    Theme()
    f:Hide()
end
function ChalkBox_OpenMacroForge()
    Create()
    if not window then
        Note("Could not open MacroForge on this client.")
        return false
    end
    draft=ChalkBox_ForgeGetDraft()
    activeSlot="main"
    spellPage=1
    libraryIndex=1
    if search then search:SetText("") end
    Refresh()
    window:Show()
    return true
end
