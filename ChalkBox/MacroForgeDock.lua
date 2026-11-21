-- MacroForge alongside Blizzard's existing /macro window, not a
-- replacement macro editor. The native frame remains the owner of its
-- tabs, selection, editing and macro-save buttons.
local name=...
local attached=setmetatable({},{__mode="k"})
local function Combat()
    if type(InCombatLockdown)~="function" then return false end
    local ok,b=pcall(InCombatLockdown)
    return not ok or b==true
end
function ChalkBox_MacroForgeOpenBeside(native)
    native=native or MacroFrame
    if not native or Combat() or
        type(ChalkBox_OpenMacroForge)~="function" then return false end
    local st=type(ChalkBox_MacroForgeDockStatus)=="function" and
        ChalkBox_MacroForgeDockStatus()
    if st and st.docked and st.shown then
        if type(ChalkBox_MacroForgeHideDocked)=="function" then
            ChalkBox_MacroForgeHideDocked(native)
        end
        return true
    end
    if not ChalkBox_OpenMacroForge() then return false end
    if type(ChalkBox_MacroForgeDockTo)=="function" and
        ChalkBox_MacroForgeDockTo(native) then return true end
    -- When the UI is too narrow, preserve a working standalone editor.
    -- Never shove or scale Blizzard's MacroFrame to make room.
    return true
end
local function Attach()
    local native=MacroFrame
    if not native then return false end
    if attached[native] then return true end
    if Combat() or type(native.HookScript)~="function" or
        type(CreateFrame)~="function" then return false end
    -- The native Macro UI's action row is Delete | gap | New | Exit.
    -- Anchor in the real gap instead of adding a tab above the window.
    -- If this client exposes a different editor layout, do NOT cover
    -- Blizzard's own Save/New/Delete controls with a guessed button.
    local delete=MacroDeleteButton or native.DeleteButton
    local new=MacroNewButton or native.NewButton
    local exit=MacroExitButton or native.ExitButton
    if not delete or not new or not exit then return false end
    if type(delete.GetParent)=="function" and
        delete:GetParent()~=native then return false end
    local room
    if type(delete.GetRight)=="function" and
        type(new.GetLeft)=="function" then
        local ok,a=pcall(delete.GetRight,delete)
        local good,b=pcall(new.GetLeft,new)
        if ok and good and type(a)=="number" and
            type(b)=="number" then room=b-a end
    end
    if room and room<86 then return false end
    -- Only install OnHide after confirming there is a usable footer.
    -- Otherwise a client with no room could accumulate duplicate hooks
    -- on repeated load events.
    local ok=pcall(native.HookScript,native,"OnHide",function()
        if type(ChalkBox_MacroForgeHideDocked)=="function" then
            ChalkBox_MacroForgeHideDocked(native)
        end
    end)
    if not ok then return false end
    local made,button=pcall(CreateFrame,"Button",
        "ChalkBoxMacroForgeNativeButton",native,"UIPanelButtonTemplate")
    if not made or not button then return false end
    button:SetSize(82,22)
    button:SetPoint("LEFT",delete,"RIGHT",4,0)
    button:SetText("MacroForge")
    button:SetScript("OnClick",function()
        ChalkBox_MacroForgeOpenBeside(native)
    end)
    attached[native]=button
    return true
end
local function CloseSettings()
    -- Only close the options panel from which the user explicitly opened
    -- Forge. Never call CloseAllWindows or hide arbitrary Blizzard panels.
    for _,panel in ipairs({SettingsPanel or false,
        InterfaceOptionsFrame or false}) do
        if panel and type(panel.IsShown)=="function" and
            type(panel.Hide)=="function" then
            local ok,shown=pcall(panel.IsShown,panel)
            if ok and shown then pcall(panel.Hide,panel) end
        end
    end
end
function ChalkBox_MacroForgeFromSettings()
    -- Settings opens it as one workflow: close options, open Blizzard
    -- /macro, and place our existing builder alongside when possible.
    CloseSettings()
    if Combat() then
        -- The builder is read-only until the player explicitly installs.
        return type(ChalkBox_OpenMacroForge)=="function"
            and ChalkBox_OpenMacroForge() or false
    end
    if not MacroFrame then
        if type(C_AddOns)=="table" and
            type(C_AddOns.LoadAddOn)=="function" then
            pcall(C_AddOns.LoadAddOn,"Blizzard_MacroUI")
        elseif type(LoadAddOn)=="function" then
            pcall(LoadAddOn,"Blizzard_MacroUI")
        end
    end
    local native=MacroFrame
    if native then
        local opened=false
        if type(MacroFrame_Show)=="function" then
            opened=pcall(MacroFrame_Show)
        elseif type(ShowMacroFrame)=="function" then
            opened=pcall(ShowMacroFrame)
        elseif type(ShowUIPanel)=="function" then
            opened=pcall(ShowUIPanel,native)
        elseif type(native.Show)=="function" then
            opened=pcall(native.Show,native)
        end
        if opened and type(native.IsShown)=="function" and
            native:IsShown() then
            Attach()
            return ChalkBox_MacroForgeOpenBeside(native)
        end
    end
    -- Native MacroFrame not exposed: full standalone Forge still works.
    if type(ChalkBox_OpenMacroForge)=="function" then
        return ChalkBox_OpenMacroForge()
    end
    return false
end
function ChalkBox_MacroForgeNativeStatus()
    return {attached=Attach(),open=MacroFrame~=nil}
end
local events=CreateFrame("Frame")
for _,event in ipairs({"ADDON_LOADED","PLAYER_ENTERING_WORLD",
    "PLAYER_REGEN_ENABLED"}) do
    pcall(events.RegisterEvent,events,event)
end
events:SetScript("OnEvent",function(_,event,loadedName)
    if event~="ADDON_LOADED" or loadedName==name or
        loadedName=="Blizzard_MacroUI" or
        loadedName=="Blizzard_MacroFrame" then
        Attach()
    else
        -- In Forever, the native macro editor can be load-on-demand
        -- under a different Blizzard package name.
        if MacroFrame then Attach() end
    end
end)
