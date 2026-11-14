-- Combat safety: do not decorate Blizzard's secure item buttons.
-- Previous versions created textures directly on bag item buttons and wrote
-- custom fields to those buttons. Even visual-only writes can propagate taint
-- into protected item-click handling later in combat.
--
-- Learned-recipe evidence remains available through Item Insight tooltips.
-- Keep the user's outline/opacity preferences for a future independent
-- overlay implementation. This module does not hook or mutate Blizzard bags.
local addonName=...
local db
local function Settings()
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    db=ChalkBoxDB
    if db.lootHighlightKnown==nil then db.lootHighlightKnown=true end
    if type(db.lootHighlightOpacity)~="number" then
        db.lootHighlightOpacity=75
    end
    return db
end
local function State()
    if not db then Settings() end
    return {enabled=false,requested=db.lootHighlightKnown~=false,
        opacity=math.max(15,math.min(100,math.floor(db.lootHighlightOpacity+0.5))),
        marked=0,visible=0,reason="paused: protected item-button safety",
        suspended=true}
end
function ChalkBox_BagHighlightsRefresh()
    return State()
end
function ChalkBox_BagHighlightSet(enabled)
    Settings().lootHighlightKnown=enabled==true
    return false -- setting saved; no protected button touched
end
function ChalkBox_BagHighlightOpacity(value)
    if type(value)~="number" or value~=value then return false end
    Settings().lootHighlightOpacity=math.max(15,math.min(100,math.floor(value+0.5)))
    return false -- setting saved for future safe implementation
end
function ChalkBox_BagHighlightStatus()
    return State()
end
local events=CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent",function(_,event,name)
    if event=="ADDON_LOADED" and name==addonName then Settings() end
end)
