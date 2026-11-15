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
local questDetails={}
_G.ChalkBox_QuestItemDetails=function(name)
    return questDetails[name]
end
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
        ["211527"]="XP UTILITY: Rest for up to +3% XP (2h).",
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
local deCommands, deCalls={},{}
_G.ChalkBox_DisenchantCommand=function(arg)
    deCommands[#deCommands+1]=arg
end
_G.ChalkBox_DisenchantTooltip=function(_,link,isProtected)
    deCalls[#deCalls+1]={link=link,protected=isProtected}
    return false
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
    [211527]={name="Cozy Sleeping Bag",quality=1,sell=0,classID=0},
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
function tip:AddLine(message,r,g,b)
    self.lines[#self.lines+1]=message
    self.colors=self.colors or {}
    self.colors[message]={r,g,b}
    _G["LootSenseTestTooltipTextLeft"..#self.lines]={GetText=function() return message end}
end
function tip:Show() end
local function Hover(id)
    tip.lines={}
    tip.colors={}
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
assert(ChalkBox_LootPresentation("KNOWN RECIPE: Example")=="LEARNED RECIPE",
    "the presentation layer provides a concise native tooltip heading")
assert(Hover(102):find("POSSIBLE MATERIAL",1,true) and
    Hover(102):find("Leatherworking",1,true),"character profession hint")
local cleanInsight=Hover(102)
assert(not cleanInsight:find("CHALKBOX",1,true) and
    not cleanInsight:find("ITEM INSIGHT",1,true),
    "item tooltip shows the classification without duplicate brand banner")
recipeMode="known"
assert(Hover(102):find("LEARNED RECIPE",1,true) and
    Hover(102):find("Camp Tent",1,true),
    "verified learned recipe must outrank generic family info")
recipeMode="future"
assert(Hover(102):find("POSSIBLE RECIPE",1,true) and Hover(102):find("learned status unknown",1,true),
    "potential recipe is labeled not learned")
recipeMode=nil
-- Forever may call OnTooltipSetItem before item metadata finishes caching.
-- A trusted tooltip link and item name still support learned-recipe advice.
local getInfo=C_Item.GetItemInfo
C_Item.GetItemInfo=function() return nil end
recipeMode="known"
assert(Hover(102):find("LEARNED RECIPE",1,true) and Hover(102):find("Camp Tent",1,true),
    "cold item cache must not suppress known recipe tooltip advice")
C_Item.GetItemInfo=nil
assert(Hover(102):find("LEARNED RECIPE",1,true) and Hover(102):find("Camp Tent",1,true),
    "missing item info API must not suppress known recipe advice")
C_Item.GetItemInfo=getInfo
recipeMode=nil
assert(Hover(108)=="","irrelevant trade material should be quiet")
assert(Hover(4470):find("CAMP SUPPLY",1,true),"wood must always be flagged for Forever camping")
assert(Hover(4471):find("CAMP TOOL",1,true),"flint/tinder reusable utility flagged")
assert(Hover(279981):find("CAMP USE",1,true),"camp kit should be identified")
assert(Hover(279978):find("CAMP USE",1,true),"camp tent should be identified")
assert(Hover(211527):find("BONUS XP",1,true) and
    not Hover(211527):find("Item insight",1,true),
    "sleeping bag has a single useful XP heading, no generic brand")
assert(Hover(103)=="","no unverified auction prediction")
assert(deCalls[#deCalls].link:find("item:103",1,true),
    "read-only disenchant evidence is requested for gear tooltips")
SlashCmdList.CHALKBOX("de |Hitem:103:0|h[Green Trinket]|h")
assert(deCommands[#deCommands]=="|Hitem:103:0|h[Green Trinket]|h",
    "slash routing supports linked items without changing protected actions")
SlashCmdList.CHALKBOX("keep |Hitem:103:0|h[Green Trinket]|h")
Hover(103)
assert(deCalls[#deCalls].protected,
    "personally protected items suppress DE trade recommendations")
SlashCmdList.CHALKBOX("forget |Hitem:103:0|h[Green Trinket]|h")
assert(Hover(104)=="","no generic equipment reviews")
local unknownQuest=Hover(106)
assert(unknownQuest:find("KEEP",1,true) and
    not unknownQuest:find("Needed for:",1,true),
    "quest-class items without matched accepted objectives get no fake quest")
assert(Hover(107)=="","uncached quality should not produce sell advice")
activeQuest["Broken Fang"]=true
questDetails["Broken Fang"]={{title="Fangs for the Hunter",
    id=1234,have=2,required=6,complete=false}}
local questLoot=Hover(101)
assert(questLoot:find("KEEP",1,true)
    and questLoot:find("Needed for: Fangs for the Hunter",1,true)
    and questLoot:find("2 / 6 collected",1,true),
    "LootSense uses Core's actual accepted quest and objective progress")
local questCountColor=tip.colors["2 / 6 collected"]
assert(questCountColor and questCountColor[3]>questCountColor[1]
    and questCountColor[3]>questCountColor[2],
    "quest collection progress uses blue count emphasis")
local beforeQuest=#tip.lines
onTooltip(tip)
assert(#tip.lines==beforeQuest,
    "quest detail callback cannot duplicate entries on tooltip refresh")
questDetails["Broken Fang"]={{title="Fangs for the Hunter",
    id=1234,have=6,required=6,complete=true}}
questLoot=Hover(101)
assert(questLoot:find("6 / 6 collected",1,true)
    and questLoot:find("Objective complete",1,true),
    "completed objectives still identify quest until hand-in")
questDetails["Broken Fang"]={
    {title="Fangs for the Hunter",id=1234,have=2,required=6},
    {title="Another Fang Quest",id=9876,have=1,required=4}
}
questLoot=Hover(101)
assert(questLoot:find("Needed for 2 accepted quests",1,true)
    and questLoot:find("Fangs for the Hunter  ·  2/6",1,true)
    and questLoot:find("Another Fang Quest  ·  1/4",1,true),
    "items shared between accepted quests show all matching quest titles")
activeQuest["Broken Fang"]=nil
questDetails["Broken Fang"]=nil
SlashCmdList.CHALKBOX("keep |Hitem:101:0|h[Broken Fang]|h")
assert(ChalkBoxDB.keep["id:101"] ~= nil,"keep command should use item ID")
assert(Hover(101):find("KEEP",1,true),"user protection overrides vendor advice")
activeQuest["Broken Fang"]=true
questDetails["Broken Fang"]={{title="Fangs for the Hunter",
    id=1234,have=2,required=6}}
local protectedQuest=Hover(101)
assert(protectedQuest:find("Personal protection",1,true)
    and protectedQuest:find("Needed for: Fangs for the Hunter",1,true),
    "personal KEEP reason stays visible alongside verified quest name")
activeQuest["Broken Fang"]=nil
questDetails["Broken Fang"]=nil
local before=#tip.lines
onTooltip(tip)
assert(#tip.lines==before and before>=3,
    "hover refresh must not duplicate the clean item summary")
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
assert(Hover(102):find("KEEP",1,true),"name protection applies to item link")
SlashCmdList.CHALKBOX("forget Light Leather")
merchantOpen=true
tip.name="Broken Fang";tip.link="|Hitem:101:0|h[Broken Fang]|h";tip.lines={};tip.owner=vendorButton
onTooltip(tip)
assert(#tip.lines==0,"vendor items must never receive bag sell advice")
merchantOpen=false
assert(Hover(101)=="","junk remains quiet")
hasLW=false
assert(Hover(102)=="","profession hint must disappear when profession is absent")
print("PASS: native LootSense quest title/progress, multi-quest and completed objectives, personal KEEP protection, merchant separation and prior camp/profession hints")
