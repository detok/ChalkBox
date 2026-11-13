-- ChalkBox - native AddOns settings pages.
-- Uses Blizzard's Settings category. No detached configuration windows.

local title = "ChalkBox"
local rootCategory
local categories = {}
local panels = {}
local registered = false

local function DB()
    return _G.ChalkBoxDB
end
local function ZoneDB()
    return _G.ChalkBoxZoneDB
end
local function Note(text)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff55ccaaChalkBox|r " .. text)
    end
end

local function Label(panel, value, style, x, y, width)
    local font = panel:CreateFontString(nil, "ARTWORK", style or "GameFontHighlight")
    font:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
    font:SetWidth(width or 495)
    font:SetJustifyH("LEFT")
    font:SetText(value)
    return font
end

local function Panel(titleText, subtitle)
    local panel = CreateFrame("Frame", nil, UIParent)
    panel:SetSize(560, 450)
    panel.name = titleText
    panel:Hide()
    Label(panel, titleText, "GameFontNormalHuge", 24, -22, 500)
    Label(panel, subtitle, "GameFontHighlightSmall", 24, -59, 505)
    local line = panel:CreateTexture(nil, "ARTWORK")
    line:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -86)
    line:SetSize(495, 1)
    line:SetColorTexture(0.74, 0.56, 0.31, 0.68)
    local callbacks = {}
    local function Refresh()
        for _, callback in ipairs(callbacks) do callback() end
    end
    function panel:AddRefresh(callback)
        callbacks[#callbacks+1] = callback
    end
    panel.OnRefresh = Refresh
    panel.OnCommit = function() end
    panel.OnDefault = function() end
    panel:SetScript("OnShow", Refresh)
    return panel
end

local function Button(panel, caption, x, y, w, fn)
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetSize(w, 26)
    button:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
    button:SetText(caption)
    button:SetScript("OnClick", fn)
    return button
end

local function Toggle(panel, caption, description, y, value, onChange, x, labelWidth)
    x = x or 24
    local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    check:SetSize(25, 25)
    check:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
    Label(panel, caption, "GameFontNormal", x + 34, y - 4, labelWidth or 445)
    if description then
        Label(panel, description, "GameFontHighlightSmall", x + 34, y - 28, 445)
    end
    check:SetScript("OnClick", function(self)
        onChange(not not self:GetChecked())
        if panel.OnRefresh then panel.OnRefresh() end
    end)
    panel:AddRefresh(function()
        check:SetChecked(value() == true)
    end)
    return check
end

local function Activate(key)
    local category = categories[key] or rootCategory
    if category and Settings and type(Settings.OpenToCategory) == "function" then
        local identifier = category.GetID and category:GetID() or category.ID
        Settings.OpenToCategory(identifier or category)
    elseif InterfaceOptionsFrame_OpenToCategory then
        local panel = panels[key] or panels.home
        InterfaceOptionsFrame_OpenToCategory(panel)
    else
        Note("Open Game Menu > Options > AddOns > ChalkBox.")
    end
end

function ChalkBox_OpenSettings(page)
    if not registered then
        Note("The settings page isn't registered yet. Open Options > AddOns > ChalkBox.")
        return
    end
    Activate(page or "home")
end

function ChalkBox_OnAddonCompartmentClick()
    ChalkBox_OpenSettings()
end

local function MakeHome()
    local panel=Panel(title,
        "Small, configurable tools for WoW Forever. Everything stays within native AddOns Options.")
    Label(panel,"ADVENTURE TOOLS","GameFontNormalLarge",28,-103,390)
    local items={
        {"loot","LootSense","Item insights and personal keep list"},
        {"loothighlight","LootSense Appearance","Verified reagent highlighting"},
        {"quests","QuestSense","Native accepted-quest watches"},
        {"bar","The Bar","Bar position and bag correction"},
        {"barstats","The Bar Stats","Stats, toggles and presets"},
        {"barappearance","The Bar Appearance","Drag layout and opacity"},
        {"emota","Emota","Automatic emote personality"},
        {"races","Emota Race Behavior","Racial flavor and live presets"},
        {"catalog","Emote Catalog","Emotes and individual permissions"},
        {"guard","QuietGuard","Invitation controls"},
        {"prep","Adventure Prep","Camp and class care reminders"},
        {"meter","Combat Meter","DPS, healing and party reports"},
        {"theme","Global Appearance","One color theme for ChalkBox panels"},
        {"drops","DropSense","Automatic zone loot discoveries and calculator"},
        {"journal","Session Journal","Current and previous adventures"},
        {"forge","MacroForge","Spellbook-aware macro creation"},
        {"updates","Updates","Installed version and release links"},
    }
    for index,entry in ipairs(items) do
        local row=math.floor((index-1)/2)
        local col=(index-1)%2
        local x=28+col*258
        local y=-123-row*40
        local pageKey=entry[1]
        Button(panel,entry[2],x,y,228,function() Activate(pageKey) end)
        Label(panel,entry[3],"GameFontHighlightSmall",x+4,y-29,228)
    end
    return panel
end

-- Global appearance is a shared, optional surface layer. Local opacity
-- controls on the Bar/toast/meter are preserved and apply independently.
local function MakeTheme()
    local panel=Panel("Global Appearance",
        "One background and accent palette for ChalkBox windows, The Bar and camp alerts.")
    Label(panel,"BACKGROUND PRESET","GameFontNormalLarge",28,-111,480)
    local options={{"Charcoal","charcoal"},{"Midnight","midnight"},
        {"Slate","slate"},{"Custom","custom"}}
    for i,v in ipairs(options) do
        Button(panel,v[1],26+(i-1)*125,-140,116,function()
            if ChalkBox_ThemeSet then ChalkBox_ThemeSet("preset",v[2]) end
            if panel.OnRefresh then panel.OnRefresh() end
        end)
    end
    Label(panel,"ACCENT","GameFontNormal",27,-190,112)
    for i,v in ipairs({{"Gold","gold"},{"Teal","teal"},
        {"Neutral","neutral"}}) do
        Button(panel,v[1],147+(i-1)*120,-184,111,function()
            if ChalkBox_ThemeSet then ChalkBox_ThemeSet("accent",v[2]) end
            if panel.OnRefresh then panel.OnRefresh() end
        end)
    end
    local loading=false
    local sliders={}
    local controls={
        {"opacity","Global background strength",0,100,-232},
        {"r","Custom red",0,255,-288},
        {"g","Custom green",0,255,-344},
        {"b","Custom blue",0,255,-400},
    }
    for _,info in ipairs(controls) do
        Label(panel,info[2],"GameFontHighlightSmall",28,info[5],220)
        local slider=CreateFrame("Slider",nil,panel,"OptionsSliderTemplate")
        slider:SetSize(260,16)
        slider:SetPoint("TOPLEFT",panel,"TOPLEFT",238,info[5]+2)
        slider:SetMinMaxValues(info[3],info[4])
        if slider.SetValueStep then slider:SetValueStep(1) end
        local key=info[1]
        slider:SetScript("OnValueChanged",function(_,v)
            if loading or type(v)~="number" then return end
            if ChalkBox_ThemeSet then ChalkBox_ThemeSet(key,v) end
        end)
        sliders[key]=slider
    end
    local current=Label(panel,"","GameFontHighlightSmall",28,-432,495)
    panel:AddRefresh(function()
        local t=ChalkBox_ThemeGet and ChalkBox_ThemeGet() or
            {preset="charcoal",accent="gold",opacity=100,r=24,g=29,b=36}
        loading=true
        for key,slider in pairs(sliders) do slider:SetValue(t[key]) end
        loading=false
        current:SetText(t.preset.." / "..t.accent.." / "..
            tostring(t.opacity).."%  |  RGB "..t.r..","..t.g..","..t.b)
    end)
    return panel
end

-- Never label a player sample as Blizzard's server drop rate.
-- WoW addon Lua has no HTTPS API. Display the actual installed TOC
-- version and a selectable GitHub Releases link, not a fake network check.
-- Optional group-peer version notices use WoW addon messages, not GitHub.
local function MakeUpdates()
    local panel=Panel("Updates",
        "Version awareness for ChalkBox. WoW cannot fetch GitHub from addon Lua.")
    Label(panel,"INSTALLED VERSION","GameFontNormalLarge",28,-109,480)
    local version=Label(panel,"","GameFontHighlight",28,-147,492)
    local peer=Label(panel,"","GameFontHighlightSmall",28,-184,492)
    Toggle(panel,"Compare versions with other ChalkBox group members (optional)",
        nil,-227,
        function()
            local s=ChalkBox_UpdateStatus and ChalkBox_UpdateStatus()
            return s and s.peerCheck==true
        end,
        function(on)
            if ChalkBox_UpdateSetPeer then ChalkBox_UpdateSetPeer(on) end
        end)
    Label(panel,"GITHUB RELEASES","GameFontNormalLarge",28,-284,492)
    Label(panel,"Select the link, press Ctrl+C, then open it in your browser.",
        "GameFontHighlightSmall",28,-315,492)
    local address=CreateFrame("EditBox",nil,panel,"InputBoxTemplate")
    address:SetSize(460,24)
    address:SetPoint("TOPLEFT",panel,"TOPLEFT",37,-340)
    address:SetAutoFocus(false)
    address:SetText("https://github.com/detok/ChalkBox/releases")
    if address.SetScript then
        address:SetScript("OnEscapePressed",function(self)
            if self.ClearFocus then self:ClearFocus() end
        end)
    end
    Button(panel,"Select Release Link",28,-385,217,function()
        if address.SetText then
            address:SetText("https://github.com/detok/ChalkBox/releases")
        end
        if address.SetFocus then address:SetFocus() end
        if address.HighlightText then address:HighlightText() end
    end)
    Button(panel,"Print Update Status",278,-385,216,function()
        if ChalkBox_UpdateCommand then ChalkBox_UpdateCommand() end
    end)
    panel:AddRefresh(function()
        local s=ChalkBox_UpdateStatus and ChalkBox_UpdateStatus() or {}
        version:SetText("ChalkBox "..(s.installed or "unknown")..
            "  ·  Installed locally")
        if s.newerSeen then
            peer:SetText("Another player has version "..s.peerVersion..
                ". See GitHub Releases.")
        else
            peer:SetText("Latest GitHub version unknown inside WoW."..
                " Peer comparison is not a GitHub check.")
        end
    end)
    return panel
end

local function MakeDrops()
    local panel=Panel("DropSense",
        "Every observed loot-window item is recorded locally. Map Discoveries never invents official rates.")
    Toggle(panel,"Automatically record every item (recommended)",nil,-105,
        function()
            local s=ChalkBox_DropOptions and ChalkBox_DropOptions()
            return s and s.enabled==true
        end,
        function(on)
            if ChalkBox_DropSetOption then ChalkBox_DropSetOption("enabled",on) end
        end)
    Toggle(panel,"Show personal observations in native loot-window tooltips",
        nil,-146,
        function()
            local s=ChalkBox_DropOptions and ChalkBox_DropOptions()
            return s and s.tooltip==true
        end,
        function(on)
            if ChalkBox_DropSetOption then ChalkBox_DropSetOption("tooltip",on) end
        end)
    Toggle(panel,"Show Discoveries button on the World Map",
        nil,-187,
        function()
            local s=ChalkBox_DropOptions and ChalkBox_DropOptions()
            return s and s.mapButton==true
        end,
        function(on)
            if ChalkBox_DropSetOption then ChalkBox_DropSetOption("mapButton",on) end
        end)
    local status=Label(panel,"","GameFontHighlightSmall",28,-236,500)
    panel:AddRefresh(function()
        local s=ChalkBox_DropOptions and ChalkBox_DropOptions() or {}
        status:SetText(("%d unique items · %d loot windows · %d mapped areas"):format(
            s.watched or 0,s.windows or 0,s.areas or 0))
    end)
    Button(panel,"Open Map Discoveries",28,-267,224,function()
        if ChalkBox_OpenMapDiscoveries then
            ChalkBox_OpenMapDiscoveries()
        end
    end)
    Button(panel,"Reset Map Button",270,-267,224,function()
        if ChalkBox_MapDiscoveriesResetButton then
            ChalkBox_MapDiscoveriesResetButton()
        end
    end)
    Label(panel,"DROP CHANCE CALCULATOR","GameFontNormalLarge",28,-310,455)
    Label(panel,"Your reference %","GameFontHighlightSmall",28,-349,150)
    local rate=CreateFrame("EditBox",nil,panel,"InputBoxTemplate")
    rate:SetSize(76,24)
    rate:SetPoint("TOPLEFT",panel,"TOPLEFT",171,-341)
    rate:SetAutoFocus(false)
    Label(panel,"Attempts","GameFontHighlightSmall",265,-349,67)
    local attempts=CreateFrame("EditBox",nil,panel,"InputBoxTemplate")
    attempts:SetSize(62,24)
    attempts:SetPoint("TOPLEFT",panel,"TOPLEFT",334,-341)
    attempts:SetAutoFocus(false)
    local feedback=Label(panel,
        "Rates are user-supplied; actual Forever drop probabilities are unknown.",
        "GameFontHighlightSmall",28,-395,495)
    Button(panel,"Calculate",411,-340,107,function()
        local result=ChalkBox_DropCalculate and
            ChalkBox_DropCalculate(rate:GetText(),attempts:GetText())
        feedback:SetText(result and
            (("%.2f%% chance in %s independent tries"):format(
                result,attempts:GetText())) or
            "Enter a rate from 0 to 100 and a whole number of attempts.")
    end)
    Label(panel,"Outdoor loot and dungeons remain separate. Percentages require",
        "GameFontHighlightSmall",28,-416,495)
    Label(panel,"a known creature source; mixed-source loot shows counts only.",
        "GameFontHighlightSmall",28,-431,495)
    return panel
end

local function MakeJournal()
    local panel=Panel("Session Journal",
        "Your actual adventures, current session and up to 20 saved previous sessions.")
    Label(panel,"ADVENTURE RECAP","GameFontNormalLarge",28,-111,460)
    Label(panel,"XP, levels, net gold, quest turn-ins, observed loot and camp prompts.",
        "GameFontHighlightSmall",28,-145,505)
    Label(panel,"The journal stores only observed facts. No inferred kills or auction prices.",
        "GameFontHighlightSmall",28,-168,505)
    Button(panel,"Open Current Session",28,-207,221,function()
        if ChalkBox_OpenSessionJournal then
            ChalkBox_OpenSessionJournal("current")
        end
    end)
    Button(panel,"Open Last Session",273,-207,221,function()
        if ChalkBox_OpenSessionJournal then
            ChalkBox_OpenSessionJournal("last")
        end
    end)
    local summary=Label(panel,"","GameFontHighlight",28,-275,505)
    panel:AddRefresh(function()
        local s=ChalkBox_JournalStatus and ChalkBox_JournalStatus() or {}
        summary:SetText("Current: "..(s.current and "recording" or "not started")..
            "  |  Saved adventures: "..tostring(s.history or 0))
    end)
    Label(panel,"Use /chalk session or /chalk session last from anywhere.",
        "GameFontHighlightSmall",28,-328,500)
    Label(panel,"History is stored for this character and survives future logins.",
        "GameFontHighlightSmall",28,-355,500)
    return panel
end

-- MacroForge lives quietly in AddOns options; the large spellbook builder
-- opens only after a user asks for it. Never runs secure actions on its own.
local function MakeForge()
    local panel=Panel("MacroForge",
        "Build, validate and save character-aware macros with the abilities you know.")
    Label(panel,"YOUR SPELLBOOK, YOUR BUTTONS","GameFontNormalLarge",
        27,-110,505)
    Label(panel,"One purpose, one learned spell per press. Choose modifier",
        "GameFontHighlightSmall",27,-145,497)
    Label(panel,"branches or a deliberate /castsequence for repeat presses.",
        "GameFontHighlightSmall",27,-165,497)
    Button(panel,"Open MacroForge",28,-208,244,function()
        if type(ChalkBox_OpenMacroForge)=="function" then
            ChalkBox_OpenMacroForge()
        else Note("MacroForge UI could not be loaded in this client.") end
    end)
    Button(panel,"Rescan Spellbook",287,-208,213,function()
        if type(ChalkBox_ForgeScan)=="function" then
            ChalkBox_ForgeScan(true)
        end
        if panel.OnRefresh then panel.OnRefresh() end
        if type(ChalkBox_MacroForgeRefresh)=="function" then
            ChalkBox_MacroForgeRefresh()
        end
    end)
    local scan=Label(panel,"","GameFontHighlight",28,-254,500)
    panel:AddRefresh(function()
        local s=type(ChalkBox_ForgeStatus)=="function"
            and ChalkBox_ForgeStatus() or nil
        scan:SetText(s and (s.class.."  ·  "..s.spells..
            " learned active spells  ·  "..s.saved.." saved builds") or
            "Spellbook information unavailable.")
    end)
    Label(panel,"NO AUTOMATIC COMBAT OR HIDDEN MACRO CHANGES",
        "GameFontNormal",27,-307,499)
    Label(panel,"MacroForge cannot bypass GCDs, skip cooldowns,",
        "GameFontHighlightSmall",27,-335,495)
    Label(panel,"or execute a rotation from one click. All macro text is",
        "GameFontHighlightSmall",27,-355,495)
    Label(panel,"generated visibly and checked before copying.",
        "GameFontHighlightSmall",27,-375,495)
    Label(panel,"Copy with Ctrl+C, or explicitly create a NEW macro outside combat.",
        "GameFontHighlightSmall",27,-415,505)
    return panel
end

local function MakeLoot()
    local panel = Panel("LootSense",
        "Shows learned recipes first; offline Forever catalog is optional. No automatic selling.")
    Toggle(panel, "Show my profession and quest item hints",
        "Know WHY something is useful before you sell or discard it.", -107,
        function() local db=DB(); return db and db.lootAdvice ~= false end,
        function(on)
            local db=DB()
            if db then db.lootAdvice=on end
        end)
    local info=Label(panel, "", "GameFontHighlightSmall", 26, -167, 450)
    panel:AddRefresh(function()
        local professions,materials="Unknown",0
        if type(ChalkBox_ProfessionSummary)=="function" then
            professions,materials=ChalkBox_ProfessionSummary()
        end
        local status,count="not installed",0
        if type(ChalkBox_RecipeAdvisorStatus)=="function" then
            status,count=ChalkBox_RecipeAdvisorStatus()
        end
        info:SetText("Professions: "..professions.." | Observed reagents: "..materials..
            "\nOffline recipe data: "..status.." ("..count.." indexed recipes)")
    end)
    Button(panel, "Scan Open Profession", 314, -179, 186, function()
        if ChalkBox_ProfessionRefresh then ChalkBox_ProfessionRefresh() end
        if ChalkBox_RecipeAdvisorRescan then ChalkBox_RecipeAdvisorRescan() end
        if panel.OnRefresh then panel.OnRefresh() end
    end)
    Label(panel, "Protect or unprotect an item", "GameFontNormalLarge", 26, -205)
    Label(panel, "Type its exact item name, or paste an item link:",
        "GameFontHighlightSmall", 27, -227, 475)
    local edit = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    edit:SetAutoFocus(false)
    edit:SetSize(355, 24)
    edit:SetPoint("TOPLEFT", panel, "TOPLEFT", 32, -247)
    edit:SetMaxLetters(220)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    local feedback = Label(panel, "", "GameFontHighlightSmall", 27, -309, 490)
    local function Apply(command)
        local entered = edit:GetText() or ""
        if entered:match("^%s*$") then
            feedback:SetText("Enter an item name or link first.")
            return
        end
        if SlashCmdList and SlashCmdList.CHALKBOX then
            SlashCmdList.CHALKBOX(command .. " " .. entered)
            feedback:SetText(command == "keep" and "Protection added." or "Protection removed (if present).")
            edit:SetText("")
            edit:ClearFocus()
            if panel.OnRefresh then panel.OnRefresh() end
        end
    end
    Button(panel, "Keep Item", 28, -280, 134, function() Apply("keep") end)
    Button(panel, "Forget Item", 172, -280, 134, function() Apply("forget") end)

    local page = 1
    local rows = {}
    for index = 1, 2 do
        local y = -332 - (index-1) * 33
        local name = Label(panel, "", "GameFontHighlightSmall", 29, y, 340)
        local remove = Button(panel, "Remove", 402, y + 5, 90, function()
            if rows[index] and rows[index].key and ChalkBox_RemoveKeepKey then
                ChalkBox_RemoveKeepKey(rows[index].key)
                if panel.OnRefresh then panel.OnRefresh() end
            end
        end)
        rows[index] = {label=name,button=remove}
    end
    local pageText = Label(panel, "", "GameFontHighlightSmall", 30, -419, 210)
    Button(panel, "<", 302, -405, 44, function()
        page = math.max(1,page-1)
        if panel.OnRefresh then panel.OnRefresh() end
    end)
    Button(panel, ">", 352, -405, 44, function()
        page = page+1
        if panel.OnRefresh then panel.OnRefresh() end
    end)

    panel:AddRefresh(function()
        local list = ChalkBox_GetKeepList and ChalkBox_GetKeepList() or {}
        local pages = math.max(1, math.ceil(#list / 2))
        if page > pages then page=pages end
        pageText:SetText(("Protected: %d    Page %d/%d"):format(#list,page,pages))
        for i, row in ipairs(rows) do
            local entry = list[(page-1)*2+i]
            row.key = entry and entry.key or nil
            row.label:SetText(entry and entry.label or "")
            if entry then row.button:Show() else row.button:Hide() end
        end
    end)
    return panel
end

local function MakeLootAppearance()
    local panel=Panel("LootSense Appearance",
        "Choose the kinds of item insights you want without changing WoW's item art.")
    Label(panel,"ITEM INSIGHT FILTERS","GameFontNormalLarge",27,-104,490)
    local kinds={
        {"crafting","Learned crafting uses","Confirmed uses take priority.",-134},
        {"potential","Possible or unverified uses","Hide speculative catalog hints.",-170},
        {"camp","Camping item hints","Hide camp-related reagent notes.",-206},
    }
    for _,item in ipairs(kinds) do
        local key=item[1]
        Toggle(panel,item[2],nil,item[4],
            function()
                local d=DB()
                return d and (not d.lootCategories or
                    d.lootCategories[key]~=false)
            end,
            function(on)
                local d=DB()
                if not d then return end
                if type(d.lootCategories)~="table" then
                    d.lootCategories={}
                end
                d.lootCategories[key]=on
            end)
    end
    Label(panel,"VERIFIED BAG REAGENT MARKERS","GameFontNormalLarge",
        27,-246,480)
    Toggle(panel,"Highlight ingredients for learned recipes",
        nil,-275,
        function()
            local d=DB();return d and d.lootHighlightKnown~=false
        end,
        function(on)
            if ChalkBox_BagHighlightSet then ChalkBox_BagHighlightSet(on) end
        end)
    Label(panel,"Marker opacity","GameFontNormal",27,-326,145)
    local slider=CreateFrame("Slider",nil,panel,"OptionsSliderTemplate")
    slider:SetSize(255,17)
    slider:SetPoint("TOPLEFT",panel,"TOPLEFT",182,-322)
    slider:SetMinMaxValues(15,100)
    if slider.SetValueStep then slider:SetValueStep(5) end
    local alpha=Label(panel,"75%","GameFontHighlightSmall",448,-328,65)
    local loading=false
    slider:SetScript("OnValueChanged",function(_,value)
        if loading or type(value)~="number" then return end
        if ChalkBox_BagHighlightOpacity then
            ChalkBox_BagHighlightOpacity(value)
        end
        alpha:SetText(tostring(math.floor(value+0.5)).."%")
    end)
    panel:AddRefresh(function()
        local status=ChalkBox_BagHighlightStatus and ChalkBox_BagHighlightStatus()
        local value=status and status.opacity or 75
        loading=true;slider:SetValue(value);loading=false
        alpha:SetText(tostring(value).."%")
    end)
    Button(panel,"Refresh Bag Markers",28,-371,224,function()
        if ChalkBox_BagHighlightsRefresh then
            ChalkBox_BagHighlightsRefresh()
        end
    end)
    Button(panel,"Scan Open Profession",270,-371,224,function()
        if ChalkBox_ProfessionRefresh then ChalkBox_ProfessionRefresh() end
        if ChalkBox_BagHighlightsRefresh then
            ChalkBox_BagHighlightsRefresh()
        end
    end)
    Label(panel,"Your quest and personal KEEP protections always stay prioritized.",
        "GameFontHighlightSmall",27,-420,510)
    return panel
end

local function MakeQuests()
    local panel=Panel("QuestSense",
        "WoW Forever C_QuestLog: track accepted quests without guessing map pins.")
    local function Run(command)
        if ChalkBox_QuestCommand then ChalkBox_QuestCommand(command) end
        if panel.OnRefresh then panel.OnRefresh() end
    end
    Toggle(panel,"Auto-track accepted quests",
        "Smart mode prefers nearby and new quests, with a reliable fallback.",-111,
        function() local d=ZoneDB();return d and d.enabled==true end,
        function(on) Run(on and "on" or "off") end)
    Label(panel,"Tracking mode","GameFontNormalLarge",28,-177,490)
    Button(panel,"Smart (recommended)",27,-208,160,function() Run("smart") end)
    Button(panel,"Nearby only",198,-208,145,function() Run("zone") end)
    Button(panel,"All accepted",354,-208,145,function() Run("all") end)
    Label(panel,"Smart prioritizes nearby/new quests, then fills open watch slots from your",
        "GameFontHighlightSmall",28,-247,502)
    Label(panel,"accepted quest log. Nearby-only requires a zone match; All uses log order.",
        "GameFontHighlightSmall",28,-265,502)
    Label(panel,"Auto-watch limit","GameFontNormalLarge",28,-302,210)
    for i,n in ipairs({5,10,15,20}) do
        Button(panel,tostring(n),195+(i-1)*75,-298,64,
            function() Run("limit "..n) end)
    end
    Button(panel,"Refresh Quests",27,-348,198,function() Run("refresh") end)
    Button(panel,"Tracking Diagnostics",234,-348,210,function() Run("status") end)
    local info=Label(panel,"","GameFontHighlightSmall",28,-397,498)
    panel:AddRefresh(function()
        local st=ChalkBox_QuestStatus and ChalkBox_QuestStatus() or nil
        if not st then info:SetText("QuestSense not loaded yet.");return end
        info:SetText((st.api and "Forever APIs ready" or "Quest APIs unavailable")..
            " | "..tostring(st.mode).." | limit "..tostring(st.limit)..
            " | active "..tostring(st.accepted).." | tracked "..tostring(st.tracked)..
            " | "..tostring(st.reason))
    end)
    return panel
end

local function MakeBar()
    local panel=Panel("The Bar",
        "Keep the 18px bar clean. Set placement and adjust Blizzard's separate bags.")
    Label(panel,"BAR POSITION","GameFontNormalLarge",28,-108)
    Button(panel,"Stats & Presets",282,-100,126,function() Activate("barstats") end)
    Button(panel,"Appearance",416,-100,112,function() Activate("barappearance") end)
    local position={
        {"top","Top of screen",-151},
        {"bottom","Bottom of screen",-194},
        {"off","Hide the bar",-237},
    }
    for _,entry in ipairs(position) do
        Toggle(panel,entry[2],nil,entry[3],
            function() local db=DB(); return db and db.bar==entry[1] end,
            function() if ChalkBox_BarCommand then ChalkBox_BarCommand(entry[1]) end end)
    end
    Toggle(panel,"Reserve screen space (18px)",
        "Recommended: keeps Blizzard's UI out of the bar's screen strip.",-284,
        function() local db=DB(); return db and db.barReserve~=false end,
        function(on)
            if ChalkBox_BarCommand then
                ChalkBox_BarCommand(on and "reserve on" or "reserve off")
            end
        end)
    Label(panel,"SEPARATE BAG POSITION","GameFontNormalLarge",28,-335,300)
    Label(panel,"Move bags relative to Blizzard's original anchor.",
        "GameFontHighlightSmall",28,-360,315)
    local current=Label(panel,"0  —  Blizzard default",
        "GameFontHighlight",28,-385,318)
    local bagSlider=CreateFrame("Slider",nil,panel)
    bagSlider:SetSize(22,115)
    bagSlider:SetPoint("TOPLEFT",panel,"TOPLEFT",363,-312)
    if bagSlider.SetOrientation then bagSlider:SetOrientation("VERTICAL") end
    bagSlider:SetMinMaxValues(-120,120)
    if bagSlider.SetValueStep then bagSlider:SetValueStep(5) end
    if bagSlider.SetThumbTexture then
        bagSlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Vertical")
    end
    local track=bagSlider:CreateTexture(nil,"BACKGROUND")
    track:SetSize(5,115)
    track:SetPoint("CENTER",bagSlider,"CENTER",0,0)
    track:SetColorTexture(0.30,0.30,0.31,0.85)
    Label(panel,"UP  −120","GameFontHighlightSmall",399,-313,120)
    Label(panel,"0 · BLIZZARD","GameFontHighlightSmall",399,-365,120)
    Label(panel,"DOWN  +120","GameFontHighlightSmall",399,-418,120)
    local updating=false
    bagSlider:SetScript("OnValueChanged",function(_,value)
        if updating or type(value)~="number" then return end
        -- Vertical sliders put their maximum at the top. Negate to make the
        -- top move bags UP and bottom move bags DOWN, with Blizzard 0 centered.
        local offset=math.floor(-value+0.5)
        if ChalkBox_BagOffsetSet then ChalkBox_BagOffsetSet(offset) end
        current:SetText((offset==0 and "0  —  Blizzard default") or
            ((offset>0 and "+" or "")..offset.." points  ("..
            (offset>0 and "down" or "up")..")"))
    end)
    panel:AddRefresh(function()
        local status=ChalkBox_BagStatus and ChalkBox_BagStatus()
        local offset=status and status.offset or 0
        updating=true
        bagSlider:SetValue(-offset)
        updating=false
        current:SetText((offset==0 and "0  —  Blizzard default") or
            ((offset>0 and "+" or "")..offset.." points  ("..
            (offset>0 and "down" or "up")..")"))
    end)
    Button(panel,"Reset Session",28,-416,133,function()
        if ChalkBox_BarCommand then ChalkBox_BarCommand("reset") end
    end)
    Button(panel,"Reset Bags",172,-416,112,function()
        if ChalkBox_BagOffsetSet then ChalkBox_BagOffsetSet(0) end
        if panel.OnRefresh then panel.OnRefresh() end
    end)
    return panel
end

local function MakeBarStats()
    local panel=Panel("The Bar Stats",
        "Choose visible stats. The 18px strip automatically fits the screen width.")
    local options={
        {"bags","Free bag slots","Includes profession-bag free slots"},
        {"gear","Gear durability","Weighted repair condition; warns when low"},
        {"rested","Rested XP","Bonus XP as a percent of one level"},
        {"latency","World latency","Home/world ms shown in tooltip"},
        {"pet","Hunter pet health","Never guesses secret health during combat"},
        {"rate","XP per hour","Session XP/hour"},
        {"eta","Time to level","Estimate from XP/hour"},
        {"time","Session timer","Since login or last bar reset"},
        {"gold","Gold and session net","Current money and net change"},
        {"bagvalue","Bag vendor value","Click the stat or the mode button to flip"},
        {"repair","Repair estimate","Exact at a repair vendor; ~ based on prior quote"},
    }
    for index,item in ipairs(options) do
        local key,title,description=unpack(item)
        local column=math.floor((index-1)/6)
        local line=(index-1)%6
        local x=25+column*260
        Toggle(panel,title,nil,-110-line*35,
            function()
                if ChalkBox_BarStatEnabled then
                    return ChalkBox_BarStatEnabled(key)
                end
                local d=DB()
                return d and d.barStats and d.barStats[key]==true
            end,
            function(on)
                if ChalkBox_BarCommand then
                    ChalkBox_BarCommand("stat "..key..(on and " on" or " off"))
                end
            end,x,214)
    end
    Label(panel,"Right-click any visible stat for its menu.",
        "GameFontHighlightSmall",28,-325,490)
    Label(panel,"Bag resale display:","GameFontHighlightSmall",28,-352,260)
    local modeButton=Button(panel,"Value: Total",303,-340,199,function()
        if ChalkBox_BarBagValueModeToggle then
            ChalkBox_BarBagValueModeToggle()
        elseif ChalkBox_BarCommand then
            ChalkBox_BarCommand("bagvalue toggle")
        end
        if panel.OnRefresh then panel.OnRefresh() end
    end)
    panel:AddRefresh(function()
        local mode=ChalkBox_BarBagValueModeGet and
            ChalkBox_BarBagValueModeGet() or "total"
        modeButton:SetText("Value: "..(mode=="junk" and "Junk" or "Total"))
    end)
    Label(panel,"Quick layouts","GameFontNormalLarge",28,-380)
    local function Choose(preset)
        if ChalkBox_BarCommand then ChalkBox_BarCommand("stats "..preset) end
        if panel.OnRefresh then panel.OnRefresh() end
    end
    Button(panel,"Balanced",28,-401,146,function() Choose("balanced") end)
    Button(panel,"Minimal",185,-401,146,function() Choose("minimal") end)
    Button(panel,"All",342,-401,146,function() Choose("all") end)
    Label(panel,"Even 'All' hides lowest-priority widgets on narrow screens.",
        "GameFontHighlightSmall",28,-433,496)
    return panel
end

local function MakeBarAppearance()
    local panel=Panel("The Bar Appearance",
        "Blizzard-inspired charcoal, transparent background and a per-character drag layout.")
    Label(panel,"BACKGROUND","GameFontNormalLarge",28,-111,370)
    Label(panel,"Only the panel fades. Text, hover details and the XP line remain clear.",
        "GameFontHighlightSmall",28,-145,500)
    local slider=CreateFrame("Slider",nil,panel,"OptionsSliderTemplate")
    slider:SetSize(340,18)
    slider:SetPoint("TOPLEFT",panel,"TOPLEFT",42,-192)
    slider:SetMinMaxValues(0,100)
    if slider.SetValueStep then slider:SetValueStep(5) end
    local info=Label(panel,"70%","GameFontHighlight",401,-197,95)
    local loading=false
    slider:SetScript("OnValueChanged",function(_,value)
        if loading or type(value)~="number" then return end
        if ChalkBox_BarAppearanceSet then ChalkBox_BarAppearanceSet(value) end
        info:SetText(math.floor(value+0.5).."%")
    end)
    panel:AddRefresh(function()
        local value=ChalkBox_BarAppearanceGet and ChalkBox_BarAppearanceGet() or 70
        loading=true
        slider:SetValue(value)
        loading=false
        info:SetText(tostring(value).."%")
    end)
    Label(panel,"0% = text only     ·     100% = solid charcoal",
        "GameFontHighlightSmall",36,-225,460)
    Label(panel,"LAYOUT EDITOR","GameFontNormalLarge",28,-274,460)
    Button(panel,"Edit Bar",28,-306,150,function()
        if ChalkBox_BarCommand then ChalkBox_BarCommand("edit on") end
        if panel.OnRefresh then panel.OnRefresh() end
    end)
    Button(panel,"Done Editing",190,-306,150,function()
        if ChalkBox_BarCommand then ChalkBox_BarCommand("edit off") end
        if panel.OnRefresh then panel.OnRefresh() end
    end)
    Button(panel,"Reset Layout",352,-306,150,function()
        if ChalkBox_BarCommand then ChalkBox_BarCommand("layout reset") end
        if panel.OnRefresh then panel.OnRefresh() end
    end)
    local mode=Label(panel,"","GameFontHighlightSmall",29,-349,500)
    panel:AddRefresh(function()
        mode:SetText("Edit mode: "..(ChalkBox_BarEditStatus and
            ChalkBox_BarEditStatus() and "ON — move modules" or "OFF — locked"))
    end)
    Label(panel,"Outside Edit Mode, right-click a stat for its context menu.",
        "GameFontHighlightSmall",28,-378,500)
    Label(panel,"Inside Edit Mode, drag to move modules between thirds;",
        "GameFontHighlightSmall",28,-400,500)
    Label(panel,"right-click cycles alignment. Layout is per character.",
        "GameFontHighlightSmall",28,-422,500)
    return panel
end

local function MakeEmota()
    local panel=Panel("Emota","Occasional, randomized idle personality. Existing reactions remain optional.")
    local function Change(key,on)
        if not ChalkBox_EmotaCommand then return end
        if key=="idleAuto" then ChalkBox_EmotaCommand("idle " .. (on and "on" or "off"))
        elseif key=="idleVariety" then ChalkBox_EmotaCommand("variety " .. (on and "on" or "off"))
        elseif key=="contextual" then ChalkBox_EmotaCommand("context " .. (on and "on" or "off"))
        else ChalkBox_EmotaCommand((key=="auto" and "auto " or "debug ") ..
            (on and "on" or "off")) end
    end
    local opts={
        {"auto","Enable automatic character reactions",-105},
        {"idleAuto","Random idle personality: jokes, dance, poses and more",-151},
        {"debug","Show optional local diagnostics",-197},
        {"idleVariety","Also include extra emotes you enable in the catalog",-243},
        {"contextual","Adapt idle behavior to race, class, resting area and pet",-289},
    }
    for _,o in ipairs(opts) do
        Toggle(panel,o[2],nil,o[3],
            function() local db=DB();return db and db.emota and
                (o[1]=="contextual" and db.emota.contextual~=false or
                db.emota[o[1]]==true) end,
            function(on) Change(o[1],on) end)
    end
    Label(panel,"Idle activity: very rare  <   normal   >  annoying",
        "GameFontNormal",29,-324,480)
    local slider=CreateFrame("Slider",nil,panel,"OptionsSliderTemplate")
    slider:SetSize(440,18)
    slider:SetPoint("TOPLEFT",panel,"TOPLEFT",39,-350)
    slider:SetMinMaxValues(0,100)
    if slider.SetValueStep then slider:SetValueStep(1) end
    local setting=false
    slider:SetScript("OnValueChanged",function(_,value)
        if not setting and ChalkBox_EmotaSetJokeFrequency and type(value)=="number" then
            ChalkBox_EmotaSetJokeFrequency(value)
        end
    end)
    panel:AddRefresh(function()
        local db=DB()
        local value=db and db.emota and db.emota.jokeFrequency or 50
        setting=true
        slider:SetValue(value)
        setting=false
    end)
    Button(panel,"Wave",27,-393,67,function()
        if ChalkBox_EmotaCommand then ChalkBox_EmotaCommand("test") end end)
    Button(panel,"Test Joke",100,-393,86,function()
        if ChalkBox_EmotaTestJoke then ChalkBox_EmotaTestJoke() end end)
    Button(panel,"Surprise Me",191,-393,108,function()
        if ChalkBox_EmotaPreviewIdle then ChalkBox_EmotaPreviewIdle() end end)
    Button(panel,"Reset Idle",304,-393,84,function()
        if ChalkBox_EmotaCommand then ChalkBox_EmotaCommand("idle reset") end end)
    Button(panel,"Catalog",393,-393,66,function() Activate("catalog") end)
    Button(panel,"Races",463,-393,66,function() Activate("races") end)
    return panel
end

local function MakeRacePreferences()
    local panel=Panel("Emota Race Behavior",
        "Inspect real racial emote flavor and customize your character's own race.")
    local list=ChalkBox_RaceCatalog and ChalkBox_RaceCatalog() or {}
    local selectedIndex=1
    local detected
    if type(UnitRace)=="function" then
        local _,token=UnitRace("player")
        if type(token)=="string" then
            detected=token
            for i,row in ipairs(list) do
                if row.token==token then selectedIndex=i;break end
            end
        end
    end
    Label(panel,"RACE TO INSPECT","GameFontNormalLarge",28,-105,420)
    local selectedText=Label(panel,"","GameFontHighlight",29,-149,480)
    local statusText=Label(panel,"","GameFontHighlightSmall",28,-228,492)
    local examples=Label(panel,"","GameFontHighlightSmall",28,-254,492)
    local modeText=Label(panel,"","GameFontHighlight",28,-286,492)
    local function Choose(index)
        if #list==0 then return end
        selectedIndex=(index-1)%#list+1
        if panel.OnRefresh then panel.OnRefresh() end
    end
    local dropdown
    if type(UIDropDownMenu_Initialize)=="function" and
        type(UIDropDownMenu_CreateInfo)=="function" and
        type(UIDropDownMenu_AddButton)=="function" then
        dropdown=CreateFrame("Frame",nil,panel,"UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT",panel,"TOPLEFT",178,-132)
        if type(UIDropDownMenu_SetWidth)=="function" then
            UIDropDownMenu_SetWidth(dropdown,262)
        end
        UIDropDownMenu_Initialize(dropdown,function(_,level)
            for i,item in ipairs(list) do
                local info=UIDropDownMenu_CreateInfo()
                info.text=item.label..(item.implemented and "" or " (planned)")
                info.checked=i==selectedIndex
                local selection=i
                info.func=function() Choose(selection) end
                UIDropDownMenu_AddButton(info,level)
            end
        end)
    end
    Button(panel,"Previous race",28,-183,154,function()
        Choose(selectedIndex-1)
    end)
    Button(panel,"Next race",192,-183,154,function()
        Choose(selectedIndex+1)
    end)
    Button(panel,"My race",356,-183,142,function()
        for i,row in ipairs(list) do
            if row.token==detected then Choose(i);return end
        end
    end)
    Label(panel,"RACIAL FLAVOR INTENSITY","GameFontNormalLarge",28,-318,460)
    for i,item in ipairs({
        {"off","Off"},{"subtle","Subtle"},{"default","Default"},{"expressive","Expressive"},
    }) do
        local behaviorMode=item[1]
        Button(panel,item[2],27+(i-1)*128,-345,114,function()
            local target=list[selectedIndex]
            if target and ChalkBox_RaceBehaviorSet then
                ChalkBox_RaceBehaviorSet(target.token,behaviorMode)
            end
            if panel.OnRefresh then panel.OnRefresh() end
        end)
    end
    Label(panel,"Only your character's actual race affects live behavior.",
        "GameFontHighlightSmall",28,-396,492)
    Label(panel,"Planned races are visible in the picker, but have no invented behavior.",
        "GameFontHighlightSmall",28,-418,500)
    panel:AddRefresh(function()
        local item=list[selectedIndex]
        if not item then
            selectedText:SetText("Race list unavailable.")
            return
        end
        local status=ChalkBox_RaceBehaviorStatus and
            ChalkBox_RaceBehaviorStatus(item.token)
        selectedText:SetText(item.label..(item.implemented and
            "  •  Live behavior" or "  •  Planned / placeholder"))
        statusText:SetText(detected==item.token and
            "This is your current race." or
            "Preview only. Selecting this does not change your character's race.")
        examples:SetText(item.implemented and
            ("Signature emotes: "..(status and status.examples or "None")) or
            "No special emote weighting is implemented for this race yet.")
        modeText:SetText(item.implemented and
            ("Current racial flavor: "..(status and status.mode or "default")) or
            "Racial intensity: unavailable until that race is implemented.")
        if dropdown and type(UIDropDownMenu_SetText)=="function" then
            UIDropDownMenu_SetText(dropdown,item.label..
                (item.implemented and "" or " (planned)"))
        end
    end)
    return panel
end

local function MakeCatalog()
    local panel=Panel("Emote Catalog",
        "Each token has its own switch. Try previews it without waiting for idle.")
    Label(panel,"Reactions and curated idle emotes are enabled initially; extras are opt-in.",
        "GameFontHighlightSmall",26,-104,494)
    local page=1
    local rows={}
    local perPage=6
    for i=1,perPage do
        local y=-137-(i-1)*43
        local check=CreateFrame("CheckButton",nil,panel,"UICheckButtonTemplate")
        check:SetPoint("TOPLEFT",panel,"TOPLEFT",27,y)
        check:SetSize(23,23)
        local title=Label(panel,"","GameFontHighlightSmall",66,y-4,306)
        local test=Button(panel,"Try",400,y+2,86,function()
            if rows[i] and rows[i].token and ChalkBox_EmotaTest then
                ChalkBox_EmotaTest(rows[i].token)
            end
        end)
        rows[i]={check=check,title=title,test=test,token=nil}
        check:SetScript("OnClick",function(self)
            local token=rows[i].token
            if token and ChalkBox_EmotaSetEnabled then
                ChalkBox_EmotaSetEnabled(token,not not self:GetChecked())
            end
            if panel.OnRefresh then panel.OnRefresh() end
        end)
    end
    local pagination=Label(panel,"","GameFontHighlightSmall",27,-419,255)
    Button(panel,"Previous",301,-403,91,function()
        page=math.max(1,page-1)
        if panel.OnRefresh then panel.OnRefresh() end
    end)
    Button(panel,"Next",403,-403,91,function()
        page=page+1
        if panel.OnRefresh then panel.OnRefresh() end
    end)
    panel:AddRefresh(function()
        local available=ChalkBox_EmotaCatalog and ChalkBox_EmotaCatalog() or {}
        local total=math.max(1,math.ceil(#available/perPage))
        page=math.min(page,total)
        pagination:SetText(("Emotes: %d  |  page %d / %d"):format(#available,page,total))
        for i,row in ipairs(rows) do
            local entry=available[(page-1)*perPage+i]
            row.token=entry and entry.token or nil
            if entry then
                local role=entry.automatic and "reaction" or (entry.idle and "idle" or "extra")
                row.title:SetText(entry.token .. "   (" .. role .. ")")
                row.check:SetChecked(ChalkBox_EmotaGetEnabled and
                    ChalkBox_EmotaGetEnabled(entry.token)==true)
                row.check:Show()
                row.test:Show()
            else
                row.title:SetText("")
                row.check:Hide()
                row.test:Hide()
            end
        end
    end)
    return panel
end

-- QuietGuard relies on Blizzard's own native guild/trade/channel blocks
-- and only handles duel or optional party invites when available.
local function MakeGuard()
    local panel=Panel("QuietGuard","Quiet social filters, no chat spam and no new windows.")
    local opts={
        {"guild","Block unsolicited guild invitations",-112},
        {"duel","Auto-decline duel challenges",-170},
        {"party","Auto-decline party invites (OFF by default)",-228},
        {"trade","Block unsolicited trade requests",-286},
        {"channel","Block channel invitations",-344},
    }
    for _,o in ipairs(opts) do
        Toggle(panel,o[2],nil,o[3],
            function()
                local db=DB();return db and db.guard and db.guard[o[1]]==true
            end,
            function(on)
                if ChalkBox_GuardSet then ChalkBox_GuardSet(o[1],on) end
            end)
    end
    Button(panel,"Show Protection Status",28,-406,240,function()
        if ChalkBox_GuardCommand then ChalkBox_GuardCommand("status") end
    end)
    Label(panel,"Some social controls depend on available Forever client APIs.",
        "GameFontHighlightSmall",285,-410,225)
    return panel
end

local function MakePrep()
    local panel=Panel("Adventure Prep",
        "Checks your actual camping buff and reminds you when it is missing or fading.")
    local options={
        {"enabled","Enable smart prep notifications",-99},
        {"toast","Show compact notifications on screen",-139},
        {"buffs","Check Camp Benefits and tent readiness",-179},
        {"supplies","Check actual camp supplies in bags",-219},
        {"classCare","Check Hunter pet care when available",-259},
        {"repeatUnresolved","Repeat unchanged alerts (optional)",-299},
    }
    for _,opt in ipairs(options) do
        Toggle(panel,opt[2],nil,opt[3],
            function()
                local d=DB()
                if not d or not d.camp then return false end
                if opt[1]=="repeatUnresolved" then
                    return d.camp.repeatUnresolved==true
                end
                return d.camp[opt[1]]~=false
            end,
            function(on)
                local key=opt[1]=="classCare" and "classcare" or
                    (opt[1]=="repeatUnresolved" and "repeat" or opt[1])
                local value=on and "on" or "off"
                if ChalkBox_CampCommand then
                    ChalkBox_CampCommand(opt[1]=="enabled" and value or (key.." "..value))
                end
            end)
    end
    Label(panel,"Repeat after (if on):","GameFontNormal",28,-350,166)
    for i,minutes in ipairs({20,45,90}) do
        Button(panel,minutes.."m",171+(i-1)*80,-347,70,function()
            if ChalkBox_CampCommand then ChalkBox_CampCommand("interval "..minutes) end
            if panel.OnRefresh then panel.OnRefresh() end
        end)
    end
    Button(panel,"Test",413,-347,103,function()
        if ChalkBox_CampTestToast then ChalkBox_CampTestToast() end
    end)
    Button(panel,"Print Checklist",27,-390,146,function()
        if ChalkBox_CampChecklist then ChalkBox_CampChecklist() end
    end)
    Button(panel,"Tent Used",185,-390,136,function()
        if ChalkBox_CampCommand then ChalkBox_CampCommand("tent done") end
        if panel.OnRefresh then panel.OnRefresh() end
    end)
    Button(panel,"Toast Appearance",332,-390,169,function()
        Activate("toast")
    end)
    local summary=Label(panel,"","GameFontHighlightSmall",29,-421,495)
    panel:AddRefresh(function()
        local status=ChalkBox_CampStatus and ChalkBox_CampStatus() or nil
        if not status then
            summary:SetText("Camp status unavailable")
            return
        end
        local state=status.buff and status.buff.state or "unknown"
        local tent=status.tent and status.tent.state or "unknown"
        summary:SetText("Stat buffs: "..state.." | Tent XP: "..tent..
            " | General tips: "..tostring(status.interval).."m")
    end)
    return panel
end

local function MakeToast()
    local panel=Panel("Toast Appearance",
        "Top-screen Adventure Prep alerts. Drag only when unlocked, then lock.")
    local function Run(command)
        if ChalkBox_ToastCommand then ChalkBox_ToastCommand(command) end
        if panel.OnRefresh then panel.OnRefresh() end
    end
    Toggle(panel,"Lock toast position (click-through when locked)",
        "Unlock, preview the notice and drag it where you want.",-113,
        function()
            local st=ChalkBox_ToastStatus and ChalkBox_ToastStatus()
            return st and st.locked==true
        end,
        function(on) Run(on and "lock" or "unlock") end)
    Label(panel,"Transparency","GameFontNormalLarge",28,-194,155)
    local slider=CreateFrame("Slider",nil,panel,"OptionsSliderTemplate")
    slider:SetSize(296,18)
    slider:SetPoint("TOPLEFT",panel,"TOPLEFT",180,-190)
    slider:SetMinMaxValues(35,100)
    if slider.SetValueStep then slider:SetValueStep(5) end
    local loading=false
    slider:SetScript("OnValueChanged",function(_,value)
        if not loading and type(value)=="number" then
            Run("opacity "..math.floor(value+0.5))
        end
    end)
    local info=Label(panel,"","GameFontHighlight",28,-246,480)
    panel:AddRefresh(function()
        local st=ChalkBox_ToastStatus and ChalkBox_ToastStatus()
        loading=true
        slider:SetValue(math.floor(((st and st.opacity) or 0.92)*100+0.5))
        loading=false
        info:SetText("Opacity "..math.floor(((st and st.opacity) or 0.92)*100+0.5)..
            "% | "..((st and st.locked) and "LOCKED" or "UNLOCKED")..
            " | "..(st and st.position or "top"))
    end)
    Button(panel,"Preview / Move (25s)",27,-302,222,function()
        Run("preview")
    end)
    Button(panel,"Reset to Top",264,-302,202,function()
        Run("reset")
    end)
    Label(panel,"1. Uncheck Lock. 2. Click Preview / Move. 3. Drag the toast.",
        "GameFontHighlight",28,-362,500)
    Label(panel,"4. Lock it again here. Position and transparency are saved.",
        "GameFontHighlight",28,-388,500)
    Label(panel,"Normal reminders fade after 9 seconds. Preview stays for 25.",
        "GameFontHighlightSmall",28,-416,500)
    return panel
end

local function MakeMeter()
    local panel=Panel("Combat Meter",
        "Blizzard-native damage data. No combat-log parsing or secret-value calculations.")
    local function Run(command)
        if ChalkBox_MeterCommand then ChalkBox_MeterCommand(command) end
        if panel.OnRefresh then panel.OnRefresh() end
    end
    Toggle(panel,"Show compact DPS meter window",
        "Appears by default; doesn't replace Blizzard's own meter.",-108,
        function()
            local status=ChalkBox_MeterStatus and ChalkBox_MeterStatus()
            return status and status.shown==true
        end,
        function(on) Run(on and "show" or "hide") end)
    Toggle(panel,"Lock meter position",nil,-173,
        function()
            local status=ChalkBox_MeterStatus and ChalkBox_MeterStatus()
            return status and status.locked==true
        end,
        function(on) Run(on and "lock" or "unlock") end)
    Label(panel,"Icons","GameFontNormal",220,-179,51)
    Button(panel,"Class",276,-171,67,function() Run("icons class") end)
    Button(panel,"Spec",351,-171,67,function() Run("icons spec") end)
    Button(panel,"Off",426,-171,67,function() Run("icons off") end)
    local iconInfo=Label(panel,"","GameFontHighlightSmall",30,-207,460)
    panel:AddRefresh(function()
        local st=ChalkBox_MeterStatus and ChalkBox_MeterStatus()
        local current=st and st.iconMode or "class"
        iconInfo:SetText("Icon style: "..current..
            "  |  Spec uses Blizzard's icon ID when available.")
    end)
    Label(panel,"Rows visible","GameFontNormalLarge",30,-235,340)
    for i,n in ipairs({5,8,12}) do
        Button(panel,tostring(n).." rows",27+(i-1)*138,-259,120,
            function() Run("rows "..n) end)
    end
    Label(panel,"Window size","GameFontNormalLarge",30,-295,340)
    for i,n in ipairs({85,100,115}) do
        Button(panel,tostring(n).."%",27+(i-1)*138,-318,120,
            function() Run("scale "..n) end)
    end
    Label(panel,"Transparency","GameFontNormalLarge",30,-355,132)
    local opacity=CreateFrame("Slider",nil,panel,"OptionsSliderTemplate")
    opacity:SetSize(244,17)
    opacity:SetPoint("TOPLEFT",panel,"TOPLEFT",170,-351)
    opacity:SetMinMaxValues(35,100)
    if opacity.SetValueStep then opacity:SetValueStep(5) end
    local loading=false
    opacity:SetScript("OnValueChanged",function(_,value)
        if not loading and type(value)=="number" then
            Run("opacity "..math.floor(value+0.5))
        end
    end)
    panel:AddRefresh(function()
        local status=ChalkBox_MeterStatus and ChalkBox_MeterStatus()
        loading=true
        opacity:SetValue(math.floor(((status and status.opacity) or 0.94)*100+0.5))
        loading=false
    end)
    Button(panel,"Show Window",27,-396,133,function() Run("show") end)
    Button(panel,"Reset Position",172,-396,145,function() Run("position reset") end)
    Button(panel,"Reset Data...",328,-396,140,function() Run("reset") end)
    Label(panel,"Blizzard meter gear menu: ChalkBox PRINT to PARTY. Hide this extra meter if preferred.",
        "GameFontHighlightSmall",28,-428,495)
    return panel
end

local function Register()
    if registered then return end
    panels.home = MakeHome()
    panels.theme = MakeTheme()
    panels.drops = MakeDrops()
    panels.journal = MakeJournal()
    panels.forge = MakeForge()
    panels.updates = MakeUpdates()
    panels.loot = MakeLoot()
    panels.loothighlight = MakeLootAppearance()
    panels.quests = MakeQuests()
    panels.bar = MakeBar()
    panels.barstats = MakeBarStats()
    panels.barappearance = MakeBarAppearance()
    panels.emota = MakeEmota()
    panels.races = MakeRacePreferences()
    panels.catalog = MakeCatalog()
    panels.guard = MakeGuard()
    panels.prep = MakePrep()
    panels.toast = MakeToast()
    panels.meter = MakeMeter()
    if Settings and type(Settings.RegisterCanvasLayoutCategory) == "function"
        and type(Settings.RegisterAddOnCategory) == "function" then
        rootCategory = Settings.RegisterCanvasLayoutCategory(panels.home, title)
        Settings.RegisterAddOnCategory(rootCategory)
        if type(Settings.RegisterCanvasLayoutSubcategory) == "function" then
            for _, item in ipairs({
                {"theme", "Global Appearance"},
                {"drops", "DropSense"},
                {"journal", "Session Journal"},
                {"forge", "MacroForge"},
                {"updates", "Updates"},
                {"loot", "LootSense"},
                {"loothighlight", "LootSense Appearance"},
                {"quests", "QuestSense"},
                {"bar", "The Bar"},
                {"barstats", "The Bar Stats"},
                {"barappearance", "The Bar Appearance"},
                {"emota", "Emota"},
                {"races", "Emota Race Behavior"},
                {"catalog", "Emote Catalog"},
                {"guard", "QuietGuard"},
                {"prep", "Adventure Prep"},
                {"toast", "Toast Appearance"},
                {"meter", "Combat Meter"},
            }) do
                local sub = Settings.RegisterCanvasLayoutSubcategory(rootCategory,
                    panels[item[1]], item[2])
                if sub then
                    categories[item[1]] = sub
                end
            end
        end
        -- Older builds without canvas subcategory support still expose all pages
        -- by using the home navigation, and the Classic fallback below.
        registered = true
    elseif type(InterfaceOptions_AddCategory) == "function" then
        InterfaceOptions_AddCategory(panels.home)
        for _, item in ipairs({
            {"theme", "Global Appearance"},
            {"drops", "DropSense"},
            {"journal", "Session Journal"},
            {"forge", "MacroForge"},
            {"updates", "Updates"},
            {"loot", "LootSense"},
                {"loothighlight", "LootSense Appearance"},
            {"quests", "QuestSense"},
            {"bar", "The Bar"},
                {"barstats", "The Bar Stats"},
                {"barappearance", "The Bar Appearance"},
            {"emota", "Emota"},
                {"races", "Emota Race Behavior"},
            {"catalog", "Emote Catalog"},
            {"guard", "QuietGuard"},
            {"prep", "Adventure Prep"},
                {"toast", "Toast Appearance"},
                {"meter", "Combat Meter"},
        }) do
            local panel = panels[item[1]]
            panel.parent = title
            InterfaceOptions_AddCategory(panel)
        end
        registered = true
    else
        Note("No supported Blizzard AddOns settings API was available.")
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self)
    Register()
    self:UnregisterEvent("PLAYER_LOGIN")
end)
