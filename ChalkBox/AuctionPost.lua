-- Suggest an asking price and, on a real button click, copy it into
-- Blizzard's sell box when that box is not protected.
-- Never calls SetDisplayMode, never clicks Post, never loops.
local function Secret(v)
    return type(issecretvalue)=="function" and issecretvalue(v)
end
local function Int(n)
    if Secret(n) or type(n)~="number" or n~=n or n<1 or n>1e12 or n%1~=0 then
        return nil
    end
    return n
end
local function Enabled()
    return type(ChalkBoxDB)~="table" or ChalkBoxDB.auctionPostHelp~=false
end
function ChalkBox_AuctionPostEnabled()
    return Enabled()
end
function ChalkBox_AuctionPostSet(on)
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    ChalkBoxDB.auctionPostHelp=on==true
    return true
end
function ChalkBox_AuctionPostSuggestion(itemID)
    if not Enabled() then return nil end
    itemID=Int(itemID)
    if not itemID then return nil end
    local price=type(ChalkBox_AuctionPrice)=="function" and
        ChalkBox_AuctionPrice(itemID) or nil
    if type(price)=="table" and Int(price.low) and price.stale~=true
        and price.mixed~=true then
        return {itemID=itemID,copper=price.low,
            reason="Lowest saved ask. The auction cut and deposit are not included. You still click Post."}
    end
    return {itemID=itemID,copper=nil,
        reason="No fresh ask. Choose your own price. ChalkBox will not press Post."}
end
local function Protected(widget)
    if not widget or type(widget.IsProtected)~="function" then return false end
    local ok,value=pcall(widget.IsProtected,widget)
    return not ok or value==true
end
local function MoneyBoxes(copper)
    local gold=math.floor(copper/10000)
    local silver=math.floor(copper%10000/100)
    local rest=copper%100
    return gold,silver,rest
end
local function SetBox(edit,text)
    if Protected(edit) or type(edit)~="table" or type(edit.SetText)~="function" then
        return false
    end
    local ok=pcall(edit.SetText,edit,tostring(text))
    return ok
end
local function TryMoney(root,copper)
    if type(root)~="table" or Protected(root) then return false end
    if type(root.SetAmount)=="function" and not Protected(root) then
        local ok=pcall(root.SetAmount,root,copper)
        if ok then return true end
    end
    local gold,silver,rest=MoneyBoxes(copper)
    local g=root.gold or root.Gold
    local s=root.silver or root.Silver
    local c=root.copper or root.Copper
    if g and s and c and SetBox(g,gold) and SetBox(s,silver) and SetBox(c,rest) then
        return true
    end
    return false
end
local function FillNative(copper)
    local host=AuctionHouseFrame or AuctionFrame
    if not host then return false end
    local candidates={
        host.CommoditiesSellFrame and host.CommoditiesSellFrame.PriceInput,
        host.ItemSellFrame and host.ItemSellFrame.PriceInput,
        host.BuyoutPrice,
        host.StartPrice,
        _G.AuctionsBuyoutPrice,
        _G.AuctionsBidPrice,
        _G.BuyoutPrice,
    }
    for _,box in ipairs(candidates) do
        if TryMoney(box,copper) then return true end
    end
    return false
end
function ChalkBox_AuctionPostFill(itemID)
    if type(InCombatLockdown)=="function" and InCombatLockdown() then
        return false,"Leave combat before filling a price."
    end
    local suggestion=ChalkBox_AuctionPostSuggestion(itemID)
    if not suggestion or not suggestion.copper then
        return false,suggestion and suggestion.reason
            or "Choose an item in My Items first."
    end
    if not FillNative(suggestion.copper) then
        return false,"Open the Sell tab yourself and click the item, then Fill price again. ChalkBox will not change the auction tab or press Post."
    end
    return true,"Price filled from your saved ask. Click Post yourself."
end
local note
function ChalkBox_AuctionPostNote(_,itemID,view)
    if not note or not note.SetText then return end
    if view~="bags" or not Enabled() then
        note:SetText("")
        return
    end
    local suggestion=ChalkBox_AuctionPostSuggestion(itemID)
    note:SetText(suggestion and suggestion.reason or "")
end
function ChalkBox_AuctionPostAttach(parent)
    if not parent or parent.chalkPostButton or type(CreateFrame)~="function" then
        return false
    end
    local button=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    if not button then return false end
    parent.chalkPostButton=button
    button:SetSize(110,22)
    button:SetPoint("TOPRIGHT",parent,"TOPRIGHT",-16,-106)
    button:SetText("Fill price")
    button:SetScript("OnClick",function()
        local id=type(ChalkBox_AuctionSelected)=="function" and
            ChalkBox_AuctionSelected() or nil
        local ok,message=ChalkBox_AuctionPostFill(id)
        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
            DEFAULT_CHAT_FRAME:AddMessage("|cff67c6b7ChalkBox|r "..
                (message or (ok and "Filled." or "Could not fill.")))
        end
    end)
    note=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    note:SetPoint("BOTTOMLEFT",parent,"BOTTOMLEFT",21,36)
    note:SetWidth(420)
    note:SetJustifyH("LEFT")
    return true
end
