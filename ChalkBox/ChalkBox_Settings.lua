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
    line:SetColorTexture(0.42, 0.52, 0.63, 0.55)
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

local function Toggle(panel, caption, description, y, value, onChange, x)
    x = x or 24
    local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    check:SetSize(25, 25)
    check:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
    Label(panel, caption, "GameFontNormal", x + 34, y - 4, 445)
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
    local panel = Panel(title, "Personal loot, quest, XP and emote helpers. All controls are in this native Options menu.")
    Label(panel, "Choose a section", "GameFontNormalLarge", 28, -110)
    local items = {
        {"loot", "LootSense", "Item tooltip advice and your personal don't-sell list"},
        {"quests", "QuestSense", "Automatically follow accepted quests in your current zone"},
        {"bar", "TrailBar", "An unobtrusive 18px strip for XP/hour, ETA, gold and time"},
        {"emota", "Emota", "Character jokes, emotes and optional diagnostic messages"},
        {"catalog", "Emote Catalog", "Every client-known emote, with switches and preview buttons"},
        {"guard", "QuietGuard", "Block random guild invites and duels; optional social filters"},
        {"prep", "Adventure Prep", "Camping supplies, buffs and race/class-care reminders"}
    }
    for index, info in ipairs(items) do
        local y = -132 - (index-1) * 45
        Button(panel, info[2], 28, y, 205, function() Activate(info[1]) end)
        Label(panel, info[3], "GameFontHighlightSmall", 247, y - 7, 276)
    end
    Label(panel, "Open this page with /chalk or /cb.",
        "GameFontHighlight", 28, -436, 490)
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

local function MakeQuests()
    local panel = Panel("QuestSense", "Automatically updates Blizzard's own quest objective tracker. No replacement window.")
    Toggle(panel, "Automatically track quests for my current zone",
        "Changes watches on zone entry, quest acceptance and turn-ins.", -114,
        function() local db=ZoneDB();return db and db.enabled == true end,
        function(on)
            if ChalkBox_QuestCommand then
                ChalkBox_QuestCommand(on and "on" or "off")
            end
        end)
    Label(panel, "How it works", "GameFontNormalLarge", 28, -207)
    Label(panel, "Uses map quest objectives and exact quest-log zone headings. Quests " ..
        "without sufficient zone data may not be automatically included.",
        "GameFontHighlight", 28, -237, 485)
    Label(panel, "Your manually tracked quests stay tracked. Untracking an auto-added quest " ..
        "suppresses it until the next zone visit.",
        "GameFontHighlightSmall", 28, -293, 480)
    Button(panel, "Refresh Zone Quests", 27, -349, 190, function()
        if ChalkBox_QuestCommand then ChalkBox_QuestCommand("refresh") end
    end)
    Button(panel, "Show Tracking Status", 228, -349, 190, function()
        if ChalkBox_QuestCommand then ChalkBox_QuestCommand("status") end
    end)
    return panel
end

local function MakeBar()
    local panel=Panel("TrailBar", "An 18px strip with left, center and right-aligned information.")
    Label(panel,"Placement","GameFontNormalLarge",28,-111)
    local position={
        {"top","Top of screen",-145},
        {"bottom","Bottom of screen",-199},
        {"off","Hide bar",-253}
    }
    for _,entry in ipairs(position) do
        Toggle(panel,entry[2],nil,entry[3],
            function() local db=DB(); return db and db.bar==entry[1] end,
            function() if ChalkBox_BarCommand then ChalkBox_BarCommand(entry[1]) end end)
    end
    Toggle(panel,"Reserve screen space for TrailBar",
        "On by default. Resizes the usable UI area; bar stays at the physical edge.",-310,
        function() local db=DB(); return db and db.barReserve~=false end,
        function(on)
            if ChalkBox_BarCommand then
                ChalkBox_BarCommand(on and "reserve on" or "reserve off")
            end
        end)
    Button(panel,"Reset Session Stats",28,-391,190,function()
        if ChalkBox_BarCommand then ChalkBox_BarCommand("reset") end end)
    Button(panel,"Check Screen Layout",232,-391,190,function()
        if ChalkBox_BarCommand then ChalkBox_BarCommand("status") end end)
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
    Button(panel,"Wave",27,-393,82,function()
        if ChalkBox_EmotaCommand then ChalkBox_EmotaCommand("test") end end)
    Button(panel,"Test Joke",116,-393,85,function()
        if ChalkBox_EmotaTestJoke then ChalkBox_EmotaTestJoke() end end)
    Button(panel,"Surprise Me",208,-393,101,function()
        if ChalkBox_EmotaPreviewIdle then ChalkBox_EmotaPreviewIdle() end end)
    Button(panel,"Reset Idle",316,-393,88,function()
        if ChalkBox_EmotaCommand then ChalkBox_EmotaCommand("idle reset") end end)
    Button(panel,"Catalog",411,-393,86,function()
        Activate("catalog") end)
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
        {"enabled","Enable periodic prep reminders",-99},
        {"toast","Show reminders on screen (recommended)",-147},
        {"buffs","Check Camp Benefits buff and expiration",-195},
        {"supplies","Also remind me about camp supplies",-243},
        {"classCare","Also remind me about class and pet care",-291},
    }
    for _,opt in ipairs(options) do
        Toggle(panel,opt[2],nil,opt[3],
            function()
                local db=DB();return db and db.camp and db.camp[opt[1]]~=false
            end,
            function(on)
                local key=opt[1]=="classCare" and "classcare" or opt[1]
                local value=on and "on" or "off"
                if ChalkBox_CampCommand then
                    ChalkBox_CampCommand(opt[1]=="enabled" and value or (key.." "..value))
                end
            end)
    end
    Label(panel,"Reminder interval:","GameFontNormal",28,-350,166)
    for i,minutes in ipairs({20,45,90}) do
        Button(panel,minutes.."m",171+(i-1)*80,-347,70,function()
            if ChalkBox_CampCommand then ChalkBox_CampCommand("interval "..minutes) end
            if panel.OnRefresh then panel.OnRefresh() end
        end)
    end
    Button(panel,"Test Reminder",28,-396,140,function()
        if ChalkBox_CampTestToast then ChalkBox_CampTestToast() end
    end)
    Button(panel,"Print Checklist",181,-396,139,function()
        if ChalkBox_CampChecklist then ChalkBox_CampChecklist() end
    end)
    local summary=Label(panel,"","GameFontHighlightSmall",331,-392,168)
    panel:AddRefresh(function()
        local status=ChalkBox_CampStatus and ChalkBox_CampStatus() or nil
        if not status then
            summary:SetText("Camp status unavailable")
            return
        end
        local state=status.buff and status.buff.state or "unknown"
        summary:SetText("Buff: "..state.." | "..tostring(status.interval).."m")
    end)
    return panel
end

local function Register()
    if registered then return end
    panels.home = MakeHome()
    panels.loot = MakeLoot()
    panels.quests = MakeQuests()
    panels.bar = MakeBar()
    panels.emota = MakeEmota()
    panels.catalog = MakeCatalog()
    panels.guard = MakeGuard()
    panels.prep = MakePrep()
    if Settings and type(Settings.RegisterCanvasLayoutCategory) == "function"
        and type(Settings.RegisterAddOnCategory) == "function" then
        rootCategory = Settings.RegisterCanvasLayoutCategory(panels.home, title)
        Settings.RegisterAddOnCategory(rootCategory)
        if type(Settings.RegisterCanvasLayoutSubcategory) == "function" then
            for _, item in ipairs({
                {"loot", "LootSense"},
                {"quests", "QuestSense"},
                {"bar", "TrailBar"},
                {"emota", "Emota"},
                {"catalog", "Emote Catalog"},
                {"guard", "QuietGuard"},
                {"prep", "Adventure Prep"},
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
            {"loot", "LootSense"},
            {"quests", "QuestSense"},
            {"bar", "TrailBar"},
            {"emota", "Emota"},
            {"catalog", "Emote Catalog"},
            {"guard", "QuietGuard"},
            {"prep", "Adventure Prep"},
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
