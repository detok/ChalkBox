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
    if not native or attached[native] or Combat() or
        type(native.HookScript)~="function" then return false end
    -- HookScript is additive. Never replace MacroFrame OnShow/OnHide or
    -- register a new macro selection/editing handler.
    local ok=pcall(native.HookScript,native,"OnHide",function()
        if type(ChalkBox_MacroForgeHideDocked)=="function" then
            ChalkBox_MacroForgeHideDocked(native)
        end
    end)
    if not ok then return false end
    if type(CreateFrame)~="function" then return false end
    local made,button=pcall(CreateFrame,"Button",
        "ChalkBoxMacroForgeNativeButton",native,"UIPanelButtonTemplate")
    if not made or not button then return false end
    button:SetSize(110,23)
    -- A small tab above the macro frame; never cover its selected
    -- macro list, native edit area, close button or internal tabs.
    button:SetPoint("BOTTOMLEFT",native,"TOPLEFT",18,0)
    button:SetText("MacroForge")
    button:SetScript("OnClick",function()
        ChalkBox_MacroForgeOpenBeside(native)
    end)
    attached[native]=button
    return true
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
Attach()
