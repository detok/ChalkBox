-- DisenchantSense: read-only item economics, no protected item actions.
-- Expected yield weighted by classic item level, quality and weapon/armor.
local events={}
_G.ChalkBoxDB={}
_G.CreateFrame=function()
    local f={}
    function f:RegisterEvent(event) events[event]=true end
    function f:UnregisterEvent(event) events[event]=nil end
    function f:SetScript(_,cb) self.cb=cb end
    return f
end
local records={
    [9001]={"Green Armor",2,30,4,0,"INVTYPE_CHEST",35},
    [9002]={"Green Weapon",2,30,2,7,"INVTYPE_WEAPON",60},
    [9003]={"Blue Armor",3,35,4,1,"INVTYPE_CHEST",90},
    [9004]={"High Blue",3,60,4,1,"INVTYPE_CHEST",100},
    [9005]={"Purple Armor",4,30,4,1,"INVTYPE_CHEST",100},
    [9006]={"Green Consumable",2,30,0,0,"",100},
    [9007]={"Low Sword",2,7,2,7,"INVTYPE_WEAPON",50},
    [9008]={"Enchanter Wand",2,30,2,19,"INVTYPE_RANGEDRIGHT",50},
    [9009]={"Out of bracket",2,105,4,1,"INVTYPE_CHEST",10},
    [9010]={"Low Blue",3,9,4,1,"INVTYPE_CHEST",50},
    [9011]={"High Bracket Blue",3,65,4,1,"INVTYPE_CHEST",100},
    [9012]={"Effective Level Sword",2,51,2,7,"INVTYPE_WEAPON",50},
    [9013]={"Epic Armor",4,60,4,1,"INVTYPE_CHEST",300},
    [11287]={"NO_DE flag gear",2,30,4,1,"INVTYPE_CHEST",90},
    [279246]={"Special disenchant gear",2,35,4,1,"INVTYPE_CHEST",95},
}
_G.C_Item={GetItemInfo=function(item)
    local id=tonumber(item) or tostring(item):match("item:(%d+)")
    local row=records[tonumber(id)]
    if not row then return nil end
    return row[1],"item:"..id,row[2],row[3],25,"Armor","",
        1,row[6],nil,row[7],row[4],row[5],2,nil,nil,false
end,
GetDetailedItemLevelInfo=function(item)
    local id=tonumber(item) or tostring(item):match("item:(%d+)")
    if tonumber(id)==9012 then return 65 end
    return nil
end}
local asks={
    [11083]={low=100,stale=false},
    [11082]={low=200,stale=false},
    [11084]={low=300,stale=false},
    [9001]={low=150,stale=false},
    [9002]={low=500,stale=false},
    [11138]={low=2000,stale=false},
    [9003]={low=1700,stale=false},
    [14344]={low=1500,stale=false},
    [20725]={low=3000,stale=false},
    [9004]={low=1200,stale=false},
    [9010]={low=1000,stale=false},
    [9011]={low=1000,stale=false},
    [9013]={low=2000,stale=false},
    [10938]={low=100,stale=false},
    [10940]={low=50,stale=false},
}
_G.ChalkBox_AuctionPrice=function(id)
    local n=type(id)=="number" and id or
        tonumber(tostring(id):match("item:(%d+)") or tostring(id))
    return asks[n]
end
local printed={}
_G.DEFAULT_CHAT_FRAME={AddMessage=function(_,msg) printed[#printed+1]=msg end}
_G.IsShiftKeyDown=function() return false end
local ns={}
local base="Libs/ForeverDisenchantData/"
assert(loadfile(base.."Materials.lua"))("ChalkBox",ns)
assert(loadfile(base.."NoDisenchant.lua"))("ChalkBox",ns)
assert(loadfile(base.."OwnLoot.lua"))("ChalkBox",ns)
assert(ns.materials and ns.noDisenchant and ns.ownLoot)
assert(ns.noDisenchant[11287] and ns.ownLoot[279246],
    "client exception tables are present and correctly loaded")
assert(loadfile("DisenchantSense.lua"))("ChalkBox",ns)
assert(events.ADDON_LOADED,"module should initialize from addon load")
-- Find loader script by intercepting construction in a second test instance?
-- Mock CreateFrame registers, stores the script as a field.
-- For this test, the module has safe defaults even before ADDON_LOADED.
local armor=ChalkBox_DisenchantEvaluate(9001)
assert(armor and armor.itemLevel==30 and armor.quality==2
    and #armor.outcomes==3 and armor.complete)
assert(armor.outcomes[1].id==11083 and
    math.abs(armor.outcomes[1].expected-1.125)<0.00001,
    "green armor has weighted Soul Dust yield at ilvl 30")
assert(armor.outcomes[2].id==11082 and
    math.abs(armor.outcomes[2].expected-0.30)<0.00001)
assert(armor.outcomes[3].id==11084 and
    math.abs(armor.outcomes[3].expected-0.05)<0.00001)
assert(armor.estimated==188 and armor.itemAsk==150 and
    armor.verdict=="DE higher vs AH ask",
    "expected value sums probability x average quantity x low ask")
local weapon=ChalkBox_DisenchantEvaluate("item:9002")
assert(weapon.weapon and weapon.complete and weapon.estimated==270,
    "green weapons have essence-biased yields, unlike armor")
assert(weapon.verdict=="AH ask higher",
    "do not tell player to disenchant a clearly better-priced weapon")
local rare=ChalkBox_DisenchantEvaluate(9003)
assert(rare.quality==3 and #rare.outcomes==1 and
    rare.outcomes[1].id==11138 and rare.estimated==2000,
    "blue ilvl 35 produces Small Glowing Shard in Classic model")
local high=ChalkBox_DisenchantEvaluate(9004)
assert(high and #high.outcomes==1 and high.complete and
    high.outcomes[1].id==14344 and high.outcomes[1].chance==1 and
    high.estimated==1500,
    "Forever 56-60 blues yield a Large Brilliant Shard; no phantom crystal")
local highBracket=ChalkBox_DisenchantEvaluate(9011)
assert(highBracket and #highBracket.outcomes==2 and highBracket.complete
    and highBracket.outcomes[1].chance==0.99
    and highBracket.outcomes[2].chance==0.01
    and highBracket.estimated==1515,
    "the crystal chance applies to the client 61+ rare bracket")
local lowest=ChalkBox_DisenchantEvaluate(9007)
assert(lowest and lowest.itemLevel==7 and lowest.weapon and
    #lowest.outcomes==2 and lowest.complete
    and lowest.outcomes[1].id==10938
    and lowest.outcomes[1].chance==0.8
    and lowest.estimated==135,
    "Forever 5-15 uncommon weapons are eligible; essence weighted")
local lowBlue=ChalkBox_DisenchantEvaluate(9010)
assert(lowBlue and lowBlue.unconfirmed==true
    and lowBlue.estimated==nil and lowBlue.verdict==nil,
    "Forever 5-15 blue bracket's unverified reward must not be valued")
local epic=ChalkBox_DisenchantEvaluate(9013)
assert(epic and epic.quality==4 and epic.estimated==3000
    and epic.outcomes[1].id==20725,
    "Forever-supported 56-60 epic bracket values a Nexus Crystal")
local scaled=ChalkBox_DisenchantEvaluate(9012)
assert(scaled and scaled.itemLevel==65
    and scaled.outcomes[1].id==16203,
    "live exact item level takes priority over generic cached item level")
assert(ChalkBox_DisenchantEvaluate(9005)==nil and
    ChalkBox_DisenchantEvaluate(9006)==nil and
    ChalkBox_DisenchantEvaluate(9008)==nil and
    ChalkBox_DisenchantEvaluate(9009)==nil and
    ChalkBox_DisenchantEvaluate(11287)==nil and
    ChalkBox_DisenchantEvaluate(279246)==nil,
    "unsupported items, unusable wands, explicit no-DE flags and special-loot gear stay quiet")
asks[11084]=nil
local partial=ChalkBox_DisenchantEvaluate(9001)
assert(partial and not partial.complete and partial.priced==2
    and partial.estimated==nil and partial.verdict==nil,
    "unknown price yields NO fake total or recommendation")
asks[11084]={low=300,stale=true}
partial=ChalkBox_DisenchantEvaluate(9001)
assert(not partial.complete,"outdated auction scan never values that material")
asks[11084]={low=300,mixed=true}
partial=ChalkBox_DisenchantEvaluate(9001)
assert(not partial.complete,"mixed pricing is not valid material evidence")
asks[11084]={low=300,stale=false}
asks[9001]={low=150,mixed=true}
local mixed=ChalkBox_DisenchantEvaluate(9001)
assert(mixed.complete and mixed.itemAsk==nil
    and mixed.verdict=="DE higher vs vendor",
    "mixed gear must not be compared to its aggregated asking price")
asks[9001]={low=150,stale=false}
-- Tooltip uses no item actions, never duplicates headings, shift expands
-- individual material odds only when the player requests details.
local tip={lines={},name="DisenchantTest"}
function tip:GetName() return self.name end
function tip:NumLines() return #self.lines end
function tip:AddLine(msg)
    self.lines[#self.lines+1]=msg
    _G[self.name.."TextLeft"..#self.lines]={
        GetText=function() return msg end}
end
function tip:AddDoubleLine(a,b)
    self:AddLine(a)
    self.lines[#self.lines+1]=b
end
function tip:Show() self.shown=true end
assert(ChalkBox_DisenchantTooltip(tip,"|Hitem:9001:0|h[Green Armor]|h"))
assert(tip.shown and not ChalkBox_DisenchantTooltip(tip,9001),
    "repeated tooltip callbacks do not duplicate DE information")
local seen={}
for _,l in ipairs(tip.lines) do seen[l]=true end
assert(seen["DE estimate  |  Forever bracket (ilvl 30)"] and
    seen["1s 88c"] and seen["DE higher vs AH ask (if tradable)"],
    "simple DE tooltip compares material EV with actual item ask")
tip.lines={}
assert(ChalkBox_DisenchantTooltip(tip,9001,true))
seen={}
for _,l in ipairs(tip.lines) do seen[l]=true end
assert(not seen["DE higher vs AH ask (if tradable)"],
    "personally protected or quest items never get destruction advice")
tip.lines={}
_G.IsShiftKeyDown=function() return true end
assert(ChalkBox_DisenchantTooltip(tip,9001))
seen={}
for _,l in ipairs(tip.lines) do seen[l]=true end
assert(seen["75%  1-2x Soul Dust"] and
    seen["20%  1-2x Greater Astral Essence"] and
    seen["5%  1-1x Large Glimmering Shard"],
    "Shift reveals fully labeled probabilities and ranges")
tip.lines={}
assert(ChalkBox_DisenchantMarketHint(tip,9001))
seen={}
for _,l in ipairs(tip.lines) do seen[l]=true end
assert(seen["DE model ~1s 88c in materials"] and
    seen["DE higher vs AH ask · if tradable"],
    "Market hover shares the same read-only DE price model")
ChalkBox_DisenchantCommand("item:9002")
assert(printed[#printed]:find("Classic reference odds",1,true),
    "chat command separates client bracket from reference-server probabilities")
-- Verify every client-sourced bracket (both edges, class and rarity),
-- without inventing rewards for non-disenchantable unsupported ranges.
local ranges={
    {5,15},{16,20},{21,25},{26,30},{31,35},
    {36,40},{41,45},{46,50},{51,55},{56,60},{61,99},
}
local epicRanges={
    {40,45},{46,50},{51,55},{56,60},{61,99}
}
for _,class in ipairs({2,4}) do
    for _,quality in ipairs({2,3,4}) do
        local correctRanges=quality==4 and epicRanges or ranges
        for _,range in ipairs(correctRanges) do
            for _,lvl in ipairs(range) do
                local row=ns.materials.Find(class,quality,lvl)
                assert(row and row[1]==range[1] and row[2]==range[2],
                    "Forever reference bracket mismatch at "..class.."/"..quality.."/"..lvl)
                local sum=0
                for j=3,#row do sum=sum+row[j][1] end
                assert(sum==100,"all bracket outcomes must total 100 percent")
            end
        end
        if quality==4 then
            assert(ns.materials.Find(class,quality,39)==nil,
                "client disallows epic disenchant bracket below item level 40")
        end
    end
end
print("PASS: 54 client quality/class brackets, flags and special loot, Forever level/rarity boundaries, Classic odds, item-level API, partial/stale/mixed price safety, tooltip and Market")
