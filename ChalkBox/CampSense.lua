-- ChalkBox CampSense: Forever travel preparation without intrusive panels.
-- Reminds rather than casts spells or consumes items. Forever-only camping
-- recipes are explicit exceptions to profession-recipe cache guessing.
local addonName=...
local db,entryTime,lastNotice,lastCampState= nil,nil,-1e8,nil
local frame=CreateFrame("Frame")
local ticker
local utility={
    [2318]={label="Light Leather",text="CAMP REAGENT: 5 for Camp Tent (Leatherworking 20); 3 + 2 Simple Wood for Camp Chair (Skinning 20)."},
    [2319]={label="Medium Leather",text="CAMP REAGENT: 5 for Tanning Rack (Leatherworking 140); 3 for Field Guide (Skinning 140)."},
    [2321]={label="Fine Thread",text="CAMP REAGENT: 3 for Tanning Rack; 1 for Field Guide. Higher-tier campsite crafting."},
    [4234]={label="Heavy Leather",text="CAMP REAGENT: 4 for Trapper's Workbench (Skinning 300)."},
    [4470]={label="Simple Wood",text="CAMP REAGENT: 1 for Basic Campfire Kit; 2 for Camp Chair, Tanning Rack or Trapper's Workbench."},
    [4471]={label="Flint and Tinder",text="CAMP TOOL: reusable tool for making campfire kits. Keep one handy."},
    [279981]={label="Basic Campfire Kit",text="CAMP: deploy a campsite; sit or craft near features for about 1 minute."},
    [279978]={label="Camp Tent",text="CAMP: Leatherworking feature; can restore rested XP up to 5% of a level."},
    [279979]={label="Camp Chair",text="CAMP: Skinning feature; increases crit chance by 2% while camp benefit is active."},
    [11291]={label="Star Wood",text="CAMP SUPPLY: used in Journeyman Campfire crafting (Cooking)."},
    [272941]={label="Thick Logs",text="CAMP SUPPLY: higher-tier Cooking campfire reagent."},
    [211527]={label="Cozy Sleeping Bag",text="XP UTILITY: rest on the bag for up to 3% bonus XP for 2 hours."},
}
local function Safe(value)
    return value~=nil and (type(issecretvalue)~="function" or not issecretvalue(value))
end
local function Note(msg)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff55ccaaChalkBox Prep|r "..msg)
    end
end
local function CurrentClass()
    if type(UnitClass)~="function" then return end
    local localized,token=UnitClass("player")
    if Safe(token) and type(token)=="string" then return token end
    if Safe(localized) and type(localized)=="string" then return string.upper(localized) end
end
local function CurrentRace()
    if type(UnitRace)~="function" then return end
    local _,token=UnitRace("player")
    if Safe(token) and type(token)=="string" then return token end
end
local hints={
    HUNTER="Check pet happiness/food, ammunition (if needed), and your preferred Aspect.",
    MAGE="Review Arcane Intellect, conjured food/water, and your current armor spell.",
    PRIEST="Review Power Word: Fortitude and your active defensive buffs.",
    DRUID="Review Mark of the Wild, Thorns and your chosen form.",
    WARLOCK="Review active demon, soul shards, and Demon Armor.",
    WARRIOR="Review your Battle Shout uptime and weapon condition.",
    ROGUE="Review equipped poisons, thrown supplies and weapon condition.",
    PALADIN="Review your Blessing, Aura and Seal choices.",
    SHAMAN="Review Lightning Shield, weapon enhancements and any required totem reagents.",
}
local function PetStatus()
    if CurrentClass()~="HUNTER" then return nil end
    if type(UnitExists)=="function" then
        local exists=UnitExists("pet")
        if Safe(exists) and not exists then return "No active pet. Call or revive if needed." end
    end
    if type(GetPetHappiness)=="function" then
        local level=GetPetHappiness()
        if Safe(level) and type(level)=="number" and level>=1 and level<=3 then
            return ({"Pet unhappy: feed suitable food.","Pet content: consider feeding soon.",
                "Pet happy."})[level]
        end
    end
    return "Check pet happiness and carry suitable pet food."
end
local function Count(id)
    local fn=type(GetItemCount)=="function" and GetItemCount or
        C_Item and C_Item.GetItemCount
    if type(fn)~="function" then return nil end
    local ok,v=pcall(fn,id,false,false)
    if ok and Safe(v) and type(v)=="number" and v>=0 then return v end
end
local function Forever()
    if type(GetBuildInfo)~="function" then return true end
    local _,_,_,interface=GetBuildInfo()
    if not Safe(interface) then return false end
    return tonumber(interface)==16001
end
local function CampingStatus()
    local wood,flint,kit=Count(4470),Count(4471),Count(279981)
    local parts={}
    if kit~=nil then
        parts[#parts+1]="Camp kits "..kit
    else
        parts[#parts+1]="Camp kits ?"
    end
    parts[#parts+1]="wood "..(wood or "?")
    parts[#parts+1]="flint "..(flint or "?")
    return table.concat(parts," | "),wood,flint,kit
end
function ChalkBox_CampUtility(itemID,itemName)
    if not Forever() then return end
    local id=tonumber(itemID)
    local found=id and utility[id]
    if not found and Safe(itemName) and type(itemName)=="string" then
        for _,entry in pairs(utility) do
            if string.lower(itemName)==string.lower(entry.label) then found=entry;break end
        end
    end
    return found and found.text
end
local function IsBusy()
    if type(InCombatLockdown)=="function" and InCombatLockdown() then return true end
    if type(UnitAffectingCombat)=="function" then
        local state=UnitAffectingCombat("player")
        if type(issecretvalue)=="function" and issecretvalue(state) then return true end
        -- WoW frequently returns nil (not false) for a player out of combat.
        if state then return true end
    end
    return false
end
local function CampStatus()
    if not Forever() or type(ChalkBox_CampBuffStatus)~="function" then
        return {state="unknown"}
    end
    return ChalkBox_CampBuffStatus()
end
local function CampBuffHint(status)
    if status.state=="gathering" then return nil end
    if status.state=="missing" then
        return "Camp Benefits are missing. Find or make a campfire, place features, and /sit for 1 minute."
    end
    if status.state=="expiring" then
        local mins=math.max(1,math.ceil((status.seconds or 0)/60))
        return "Camp Benefits expire in about "..mins.." min. Plan to rest at a campsite soon."
    end
end
local function MeaningfulHint(buffs)
    buffs=buffs or CampStatus()
    -- Camping countdown is already running. Never interrupt it or tell the
    -- character to start another camp while the buff is active.
    if buffs.state=="gathering" then return nil end
    if db.buffs~=false and (buffs.state=="missing" or buffs.state=="expiring") then
        local message=CampBuffHint(buffs)
        local _,wood,flint,kit=CampingStatus()
        if message and db.supplies~=false and buffs.state=="missing"
            and kit==0 and flint==0 then
            message=message.." You need Flint and Tinder and Simple Wood."
        elseif message and db.supplies~=false and buffs.state=="missing"
            and kit==0 and wood==0 then
            message=message.." Buy Simple Wood for a campfire kit."
        end
        return message
    end
    local _,wood,flint,kit=CampingStatus()
    if Forever() and db.supplies~=false then
        if flint==0 then return "Camp prep: buy Flint and Tinder when you see a vendor (reusable)." end
        if kit==0 and wood==0 then return "Camp prep: buy Simple Wood or craft/carry a Basic Campfire Kit." end
        if wood~=nil and wood<2 and (kit==nil or kit<2) then
            return "Camp prep: low on Simple Wood/Basic Campfire Kits. Stock up before roaming."
        end
    end
    if db.classCare~=false and CurrentClass()=="HUNTER" then
        local pet=PetStatus()
        if pet and not pet:find("happy.",1,true) then return pet end
    end
    -- Camp Benefits are already active (or unreadable): never invent an
    -- expiring/missing buff. Optional class-care hints remain separate.
    if db.classCare~=false then return hints[CurrentClass()] end
end

local function Pulse()
    if not db or db.enabled==false or IsBusy() then return end
    local now=type(GetTime)=="function" and GetTime() or 0
    if not Safe(now) or type(now)~="number" then return end
    if not entryTime then entryTime=now end
    if now-entryTime<180 then return end
    local current=CampStatus()
    local changed=current.state~=lastCampState
    lastCampState=current.state
    local interval=math.max(20,math.min(120,tonumber(db.interval) or 45))
    local urgent=changed and (current.state=="missing" or current.state=="expiring")
        and db.buffs~=false
    -- Camp buff state changes deserve a prompt as soon as they are observed,
    -- independent of generic supplies/class reminder cadence.
    if now-lastNotice<interval*60 and not urgent then return end
    local msg=MeaningfulHint(current)
    if msg then
        local shown=false
        if db.toast~=false and type(ChalkBox_ShowReminder)=="function" then
            shown=ChalkBox_ShowReminder(msg,"CHALKBOX  -  ADVENTURE PREP")==true
        end
        -- Chat fallback covers clients that cannot create safe screen frames,
        -- or users who explicitly disable on-screen reminders.
        if not shown then Note(msg.."  (/chalk prep for a checklist)") end
        lastNotice=now
    end
end
function ChalkBox_CampStatus()
    local summary=CampingStatus()
    return {summary=summary,class=CurrentClass() or "Unknown",
        race=CurrentRace() or "Unknown",pet=PetStatus(),buff=CampStatus(),
        interval=(db and db.interval or 45),enabled=db and db.enabled~=false,
        toast=db and db.toast~=false}
end
function ChalkBox_CampTestToast()
    local msg=MeaningfulHint() or "Take a moment to check your food, camping and class buffs."
    if type(ChalkBox_ShowReminder)=="function" and
        ChalkBox_ShowReminder(msg,"CHALKBOX  -  TEST REMINDER") then return true end
    Note("Reminder preview: "..msg)
    return false
end

function ChalkBox_CampChecklist()
    local s=ChalkBox_CampStatus()
    Note("Prep: "..s.summary..". Race/Class: "..s.race.."/"..s.class..".")
    if s.buff then
        if s.buff.state=="active" then
            Note("Camp Benefits: ACTIVE"..(s.buff.seconds and
                (" ("..math.ceil(s.buff.seconds/60).." min left)") or "")..".")
        elseif s.buff.state=="gathering" then
            Note("Welcoming Campfire: gathering buffs now; finish resting for 1 minute.")
        elseif s.buff.state=="expiring" then
            Note("Camp Benefits: expiring in "..math.ceil((s.buff.seconds or 0)/60).." min.")
        elseif s.buff.state=="missing" then
            Note("Camp Benefits: MISSING; rest at a campsite to refresh.")
        else
            Note("Camp Benefits: unable to read auras; no missing-buff assumptions.")
        end
    end
    if s.pet then Note("Pet: "..s.pet) end
    if hints[s.class] then Note(hints[s.class]) end
    if Forever() then
        Note("Forever: camp near profession features for ~1 minute to gain applicable buffs. Camp Tent may top up rested XP.")
        Note("Check Well Fed cooked-food XP bonus and Cozy Sleeping Bag; buffs depend on the actual items/skills.")
    end
end
function ChalkBox_CampCommand(msg)
    if not db then return end
    local key,value=(msg or ""):match("^(%S*)%s*(.-)%s*$")
    key=string.lower(key or ""); value=string.lower(value or "")
    if (key=="on" or key=="off") and value=="" then
        db.enabled=key=="on"
        Note("Periodic prep tips "..(db.enabled and "ON" or "OFF")..".")
    elseif (key=="supplies" or key=="buffs" or key=="classcare")
        and (value=="on" or value=="off") then
        local k=key=="classcare" and "classCare" or key
        db[k]=value=="on"
        Note(k.." reminders "..value..".")
    elseif key=="toast" and (value=="on" or value=="off") then
        db.toast=value=="on"
        if not db.toast and type(ChalkBox_HideReminder)=="function" then
            ChalkBox_HideReminder()
        end
        Note("On-screen prep reminders "..value..".")
    elseif key=="test" then
        ChalkBox_CampTestToast()
    elseif key=="interval" and tonumber(value) then
        db.interval=math.max(20,math.min(120,math.floor(tonumber(value))))
        Note("Prep reminder interval: "..db.interval.." min.")
    else
        ChalkBox_CampChecklist()
    end
end
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("MERCHANT_SHOW")
frame:SetScript("OnEvent",function(_,event,name)
    if event=="ADDON_LOADED" then
        if name~=addonName then return end
        if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
        if type(ChalkBoxDB.camp)~="table" then ChalkBoxDB.camp={} end
        db=ChalkBoxDB.camp
        if db.enabled==nil then db.enabled=true end
        if db.toast==nil then db.toast=true end
        if db.supplies==nil then db.supplies=true end
        if db.buffs==nil then db.buffs=true end
        if db.classCare==nil then db.classCare=true end
        if type(db.interval)~="number" then db.interval=45 end
        if C_Timer and type(C_Timer.NewTicker)=="function" and not ticker then
            ticker=C_Timer.NewTicker(120,Pulse)
        end
    elseif event=="PLAYER_ENTERING_WORLD" then
        if not entryTime then entryTime=type(GetTime)=="function" and GetTime() or 0 end
    elseif event=="MERCHANT_SHOW" then
        Pulse()
    end
end)
