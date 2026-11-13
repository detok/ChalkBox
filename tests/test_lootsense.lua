-- LootSense v1 regression tests: no WoW client or protected combat data required.
_G.SlashCmdList = {}
_G.Enum = {TooltipDataType={Item=0}}
local callback, onTooltip
_G.TooltipDataProcessor = {AddTooltipPostCall=function(_, fn) onTooltip = fn end}
_G.CreateFrame = function()
    return {
        RegisterEvent=function() end,
        UnregisterEvent=function() end,
        SetScript=function(_, name, fn) assert(name=="OnEvent"); callback=fn end,
    }
end

local merchantOpen, activeQuest, vendorButton = false, {}, {}
vendorButton.GetParent=function() return nil end
_G.MerchantItem1ItemButton=vendorButton
_G.MerchantFrame={IsShown=function() return merchantOpen end}
_G.MERCHANT_ITEMS_PER_PAGE=10
_G.ChalkBox_IsTrackedQuestItem=function(name) return activeQuest[name] == true end
local hasLW=true
_G.ChalkBox_ProfessionMatch=function(id,name,subtype,classID)
    if hasLW and name=="Light Leather" then return "Leatherworking","possible" end
end
_G.ChalkBox_CampUtility=function(id,name)
    local materials={
        ["4470"]="CAMP SUPPLY: 1 wood crafts a Basic Campfire Kit (Cooking).",
        ["4471"]="CAMP TOOL: reusable Flint and Tinder.",
        ["279981"]="CAMP: deploy a campsite.",
        ["279978"]="CAMP: restores rested XP when used correctly.",
    }
    return materials[id]
end
local recipeMode=nil
_G.ChalkBox_RecipeAdvice=function(id,name)
    if recipeMode=="known" and name=="Light Leather" then
        return "KNOWN RECIPE: Camp Tent (Leatherworking) - 3/5 in bags",0.3,0.97,0.51
    end
    if recipeMode=="future" and name=="Light Leather" then
        return "POTENTIAL USE: Camp Tent (Leatherworking, not confirmed learned)",0.84,0.88,0.48
    end
end
local meterCommands={}
_G.ChalkBox_MeterCommand=function(cmd) meterCommands[#meterCommands+1]=cmd end
local bagCommands={}
_G.ChalkBox_BagCommand=function(cmd) bagCommands[#bagCommands+1]=cmd end
local messages = {}
_G.DEFAULT_CHAT_FRAME={AddMessage=function(_, msg) messages[#messages+1]=msg end}
local catalog = {
    [101]={name="Broken Fang",quality=0,sell=25,classID=0},
    [102]={name="Light Leather",quality=1,sell=15,classID=7,subType="Leather"},
    [103]={name="Green Trinket",quality=2,sell=300,classID=4,bindType=2},
    [104]={name="Sharp Sword",quality=1,sell=75,classID=2,equip="INVTYPE_WEAPON"},
    [105]={name="Flask of Oil",quality=0,sell=5,classID=0},
    [106]={name="Quest Relic",quality=1,sell=0,classID=12},
    [107]={name="Mystery Item",quality=nil,sell=0,classID=0},
    [108]={name="Silk Cloth",quality=1,sell=50,classID=7,subType="Cloth"},
    [4470]={name="Simple Wood",quality=1,sell=8,classID=7},
    [4471]={name="Flint and Tinder",quality=1,sell=33,classID=7},
    [279981]={name="Basic Campfire Kit",quality=1,sell=0,classID=0},
    [279978]={name="Camp Tent",quality=1,sell=0,classID=0},
}
_G.C_Item = {GetItemInfo=function(arg)
    local id = arg:match("item:(%d+)")
    local data = catalog[tonumber(id)]
    if not data then
        for _, entry in pairs(catalog) do
            if entry.name == arg then data=entry;break end
        end
    end
    if not data then return nil end
    return data.name, arg, data.quality, 1, 0, "Tradeskill", data.subType or "",
        20, data.equip or "", "", data.sell, data.classID, 0, data.bindType, 0, 0, false
end}

local tip={lines={},name="Broken Fang",link="|Hitem:101:0|h[Broken Fang]|h",owner={}}
function tip:GetItem() return self.name,self.link end
function tip:GetOwner() return self.owner end
function tip:GetName() return "LootSenseTestTooltip" end
function tip:NumLines() return #self.lines end
function tip:AddLine(message)
    self.lines[#self.lines+1]=message
    _G["LootSenseTestTooltipTextLeft"..#self.lines]={GetText=function() return message end}
end
function tip:Show() end
local function Hover(id)
    tip.lines={}
    tip.name=catalog[id].name
    tip.link="|Hitem:"..id..":0|h["..tip.name.."]|h"
    tip.owner={}
    onTooltip(tip)
    return table.concat(tip.lines," | ")
end

assert(loadfile("LootSense.lua"))("ChalkBox")
assert(type(onTooltip)=="function")
callback(nil,"ADDON_LOADED","ChalkBox")
assert(type(ChalkBoxDB)=="table" and type(ChalkBoxDB.keep)=="table")
assert(Hover(101)=="","ordinary junk should not receive extra noise")
assert(ChalkBox_LootPresentation("KNOWN RECIPE: Example")=="Used in a learned recipe",
    "the presentation layer provides a concise native tooltip heading")
assert(Hover(102):find("Possible profession material",1,true) and
    Hover(102):find("possible Leatherworking",1,true),"character profession hint")
recipeMode="known"
assert(Hover(102):find("Used in a learned recipe",1,true) and
    Hover(102):find("Camp Tent",1,true),
    "verified learned recipe must outrank generic family info")
recipeMode="future"
assert(Hover(102):find("Possible crafting use",1,true) and Hover(102):find("not confirmed learned",1,true),
    "potential recipe is labeled not learned")
recipeMode=nil
-- Forever may call OnTooltipSetItem before item metadata finishes caching.
-- A trusted tooltip link and item name still support learned-recipe advice.
local getInfo=C_Item.GetItemInfo
C_Item.GetItemInfo=function() return nil end
recipeMode="known"
assert(Hover(102):find("Used in a learned recipe",1,true) and Hover(102):find("Camp Tent",1,true),
    "cold item cache must not suppress known recipe tooltip advice")
C_Item.GetItemInfo=nil
assert(Hover(102):find("Used in a learned recipe",1,true) and Hover(102):find("Camp Tent",1,true),
    "missing item info API must not suppress known recipe advice")
C_Item.GetItemInfo=getInfo
recipeMode=nil
assert(Hover(108)=="","irrelevant trade material should be quiet")
assert(Hover(4470):find("Camp supply",1,true),"wood must always be flagged for Forever camping")
assert(Hover(4471):find("Reusable camp tool",1,true),"flint/tinder reusable utility flagged")
assert(Hover(279981):find("Camping utility",1,true),"camp kit should be identified")
assert(Hover(279978):find("Camping utility",1,true),"camp tent should be identified")
assert(Hover(103)=="","no unverified auction prediction")
assert(Hover(104)=="","no generic equipment reviews")
assert(Hover(106):find("Keep this item",1,true),"quest class should stay protected")
assert(Hover(107)=="","uncached quality should not produce sell advice")
activeQuest["Broken Fang"]=true
assert(Hover(101):find("Keep this item",1,true),"active quest protection overrides grey quality")
activeQuest["Broken Fang"]=nil
SlashCmdList.CHALKBOX("keep |Hitem:101:0|h[Broken Fang]|h")
assert(ChalkBoxDB.keep["id:101"] ~= nil,"keep command should use item ID")
assert(Hover(101):find("Keep this item",1,true),"user protection overrides vendor advice")
local before=#tip.lines
onTooltip(tip)
assert(#tip.lines==before and before>=4,
    "hover refresh must not duplicate the styled multi-line section")
SlashCmdList.CHALKBOX("list")
assert(messages[#messages]:find("Broken Fang",1,true),"list should show protected items")
SlashCmdList.CHALKBOX("bags offset 30")
SlashCmdList.CHALKBOX("bags reset")
assert(#bagCommands==2 and bagCommands[1]=="offset 30" and bagCommands[2]=="reset",
    "new bag commands must route to BagLayout without changing meter commands")
SlashCmdList.CHALKBOX("meter")
SlashCmdList.CHALKBOX("meter overall")
SlashCmdList.CHALKBOX("dps show")
assert(#meterCommands==3 and meterCommands[1]=="" and
    meterCommands[2]=="overall" and meterCommands[3]=="show",
    "new combat meter must route through original ChalkBox slash handler")
SlashCmdList.CHALKBOX("forget |Hitem:101:0|h[Broken Fang]|h")
assert(Hover(101)=="","forget restores quiet default")
SlashCmdList.CHALKBOX("keep Light Leather")
assert(ChalkBoxDB.keep["name:light leather"],"exact name protection must be available")
assert(Hover(102):find("Keep this item",1,true),"name protection applies to item link")
SlashCmdList.CHALKBOX("forget Light Leather")
merchantOpen=true
tip.name="Broken Fang";tip.link="|Hitem:101:0|h[Broken Fang]|h";tip.lines={};tip.owner=vendorButton
onTooltip(tip)
assert(#tip.lines==0,"vendor items must never receive bag sell advice")
merchantOpen=false
assert(Hover(101)=="","junk remains quiet")
hasLW=false
assert(Hover(102)=="","profession hint must disappear when profession is absent")
print("PASS: camp supplies wood/flint/kit/tent, quiet unrelated loot, profession relevance, quest protection and vendor separation")
