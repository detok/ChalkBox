-- Combat-safe bag compatibility layer.
-- A previous bag offset hooked Blizzard's container-anchor updater and
-- reanchored stock bag frames. Those frames contain secure item buttons;
-- touching their anchors can taint item use later in combat.
-- Keep saved preferences for a future safe implementation. Do not hook,
-- move, resize, or modify any Blizzard bag or item button at runtime.
local addonName=...
local db
local function Settings()
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    db=ChalkBoxDB
    if type(db.bagOffsetY)~="number" or db.bagOffsetY~=db.bagOffsetY then
        db.bagOffsetY=0
    end
    return db
end
function ChalkBox_BagOffsetSet(value)
    if not db then Settings() end
    -- An old nonzero preference stays saved, but is deliberately not applied.
    -- Returning false prevents the UI from claiming the move succeeded.
    return false
end
function ChalkBox_BagStatus()
    if not db then Settings() end
    return {offset=0,savedOffset=db.bagOffsetY,hooked=false,
        pending=false,applied=0,suspended=true}
end
local function Note(message)
    if DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage)=="function" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff55ccaaChalkBox|r "..message)
    end
end
function ChalkBox_BagCommand(command)
    local text=(command or ""):match("^%s*(.-)%s*$")
    if text=="reset" then
        Settings().bagOffsetY=0
        Note("Bag offset preference reset. Blizzard bags remain untouched.")
    elseif text=="status" then
        Note("Bag positioning: protected-action safety mode. Blizzard owns all bag anchors.")
    else
        Note("Custom bag movement is suspended to protect combat item use. Blizzard bags remain fully functional.")
    end
end
local events=CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent",function(_,event,name)
    if event=="ADDON_LOADED" and name==addonName then Settings() end
end)
