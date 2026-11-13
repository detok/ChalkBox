-- ChalkBox MacroForge: spellbook-aware, opt-in macro design.
-- This is a MACRO GENERATOR, not a rotation runner or combat automation.
-- Generated commands use Blizzard's ordinary macro UI and secure execution.
local MAX_BODY=255
local MAX_SAVED=16
local cachedSpells,cachedClass,cachedError=nil,nil,nil
local templates={
    {id="engage",name="Engage Target",detail="Start an attack with one learned spell"},
    {id="burst",name="Burst + Trinkets",detail="One spell and optional on-use trinket attempts"},
    {id="modifiers",name="Modifier Keys",detail="One spell per key combination"},
    {id="sequence",name="Manual Sequence",detail="Advance one spell per button press; may stall"},
    {id="utility",name="Mouseover Utility",detail="Explicit friendly or hostile target rules"},
}
local function Public(v)
    return v~=nil and (type(issecretvalue)~="function" or not issecretvalue(v))
end
local function SafeString(v)
    return Public(v) and type(v)=="string" and #v>0 and
        #v<115 and not v:find("[\r\n;%[%]]")
end
local function Number(v)
    return Public(v) and type(v)=="number" and v==v and
        v>=0 and v<100000000
end
local function Call(fn,...)
    if type(fn)~="function" then return end
    local ok,a,b,c,d=pcall(fn,...)
    if ok and (a==nil or Public(a)) then return a,b,c,d end
end
local function Class()
    local _,token=Call(UnitClass,"player")
    if type(token)=="string" and #token<25 then return token end
    return "UNKNOWN"
end
local function DB()
    if type(ChalkBoxZoneDB)~="table" then ChalkBoxZoneDB={} end
    local s=ChalkBoxZoneDB.macroForge
    if type(s)~="table" or s.version~=1 then
        s={version=1,recipes={},draft=nil}
        ChalkBoxZoneDB.macroForge=s
    end
    if type(s.recipes)~="table" then s.recipes={} end
    return s
end
local function AddSpell(result,seen,name,id,icon,group,helpful)
    if not SafeString(name) or not Number(id) or id<1 then return end
    if seen[name] then return end
    seen[name]=true
    result[#result+1]={id=id,name=name,icon=icon,
        group=group or "General",helpful=helpful==true}
end
local function ScanModern(result,seen)
    local book=C_SpellBook
    if type(book)~="table" or
        type(book.GetNumSpellBookSkillLines)~="function" or
        type(book.GetSpellBookSkillLineInfo)~="function" or
        type(book.GetSpellBookItemInfo)~="function" then return false end
    local num=Call(book.GetNumSpellBookSkillLines)
    if not Number(num) or num>50 then return false end
    local bank=Enum and Enum.SpellBookSpellBank and
        Enum.SpellBookSpellBank.Player or 0
    local spellType=Enum and Enum.SpellBookItemType and
        Enum.SpellBookItemType.Spell or 1
    for tab=1,num do
        local info=Call(book.GetSpellBookSkillLineInfo,tab)
        if type(info)=="table" and
            Number(info.itemIndexOffset) and Number(info.numSpellBookItems)
            and info.numSpellBookItems<600 and not info.shouldHide then
            local label=type(info.name)=="string" and info.name or "General"
            for slot=info.itemIndexOffset+1,
                info.itemIndexOffset+info.numSpellBookItems do
                local row=Call(book.GetSpellBookItemInfo,slot,bank)
                if type(row)=="table" and row.itemType==spellType
                    and not row.isPassive and not row.isOffSpec then
                    local id=row.spellID or row.actionID
                    local detail=Call(C_Spell and C_Spell.GetSpellInfo,id)
                    local name=type(detail)=="table" and detail.name or nil
                    if not name then
                        name=Call(book.GetSpellBookItemName,slot,bank)
                    end
                    local helpful=Call(book.IsSpellBookItemHelpful,slot,bank)
                    AddSpell(result,seen,name,id,
                        row.iconID or (type(detail)=="table" and detail.iconID),
                        label,helpful)
                end
            end
        end
    end
    return true
end
local function ScanLegacy(result,seen)
    if type(GetNumSpellTabs)~="function" or
        type(GetSpellTabInfo)~="function" or
        type(GetSpellBookItemInfo)~="function" then return false end
    local n=Call(GetNumSpellTabs)
    if not Number(n) or n>50 then return false end
    for tab=1,n do
        local name,_,offset,count=Call(GetSpellTabInfo,tab)
        if Number(offset) and Number(count) and count<600 then
            for slot=offset+1,offset+count do
                local kind,id=Call(GetSpellBookItemInfo,slot,
                    BOOKTYPE_SPELL or "spell")
                if kind=="SPELL" and Number(id) then
                    local spell=Call(GetSpellInfo,id)
                    AddSpell(result,seen,spell,id,nil,name)
                end
            end
        end
    end
    return true
end
function ChalkBox_ForgeScan(force)
    if cachedSpells and not force then return cachedSpells,cachedError end
    local result,seen={},{}
    local modern=ScanModern(result,seen)
    if not modern then ScanLegacy(result,seen) end
    table.sort(result,function(a,b)
        if a.group==b.group then return a.name<b.name end
        return a.group<b.group
    end)
    cachedSpells=result
    cachedClass=Class()
    cachedError=(not modern and #result==0) and
        "This client did not expose a readable spellbook API." or nil
    if #result==0 and not cachedError then
        cachedError="No active learned spells are readable yet; open the spellbook and rescan."
    end
    return result,cachedError
end
function ChalkBox_ForgeSpells(filter)
    local spells,err=ChalkBox_ForgeScan()
    if type(filter)~="string" or filter=="" then return spells,err end
    filter=filter:lower()
    local selected={}
    for _,s in ipairs(spells) do
        if s.name:lower():find(filter,1,true) or
            s.group:lower():find(filter,1,true) then
            selected[#selected+1]=s
        end
    end
    return selected,err
end
function ChalkBox_ForgeTemplates() return templates end
local function SpellName(id)
    if not Number(id) then return end
    for _,spell in ipairs(ChalkBox_ForgeScan()) do
        if spell.id==id then return spell.name,spell end
    end
end
local function Preferred(class,template,spells)
    local names={}
    if class=="HUNTER" then
        if template=="engage" then
            names={"Hunter's Mark","Serpent Sting","Arcane Shot"}
        elseif template=="burst" then
            names={"Rapid Fire","Storm Form","Aimed Shot"}
        elseif template=="sequence" then
            names={"Hunter's Mark","Serpent Sting","Arcane Shot"}
        elseif template=="utility" then
            names={"Mend Pet","Revive Pet","Tranquilizing Shot"}
        else names={"Arcane Shot","Serpent Sting","Hunter's Mark"} end
    elseif class=="MAGE" then
        names={"Fireball","Frostbolt","Arcane Blast","Counterspell"}
    elseif class=="WARRIOR" then
        names={"Charge","Heroic Strike","Battle Shout"}
    elseif class=="PRIEST" then
        names={"Flash Heal","Power Word: Shield","Smite"}
    elseif class=="DRUID" then
        names={"Wrath","Rejuvenation","Healing Touch"}
    elseif class=="WARLOCK" then
        names={"Corruption","Shadow Bolt","Drain Life"}
    elseif class=="PALADIN" then
        names={"Judgement","Holy Light","Hammer of Justice"}
    elseif class=="ROGUE" then
        names={"Sinister Strike","Kick","Eviscerate"}
    elseif class=="SHAMAN" then
        names={"Lightning Bolt","Healing Wave","Earth Shock"}
    else names={} end
    local list={}
    local used={}
    for _,name in ipairs(names) do
        for _,spell in ipairs(spells) do
            if spell.name==name and not used[spell.id] then
                list[#list+1]=spell.id
                used[spell.id]=true
                break
            end
        end
    end
    for _,spell in ipairs(spells) do
        if not used[spell.id] then
            list[#list+1]=spell.id
        end
    end
    return list
end
function ChalkBox_ForgeDraft(template)
    local allowed={engage=true,burst=true,modifiers=true,
        sequence=true,utility=true}
    if not allowed[template] then template="engage" end
    local spells=ChalkBox_ForgeScan()
    local class=cachedClass or Class()
    local ranked=Preferred(class,template,spells)
    local draft={
        version=1,class=class,template=template,
        main=ranked[1],shift=ranked[2],alt=ranked[3],
        ctrl=ranked[4],sequenceSecond=ranked[2],
        sequenceThird=nil,pet=false,autoShot=false,
        trinket13=false,trinket14=false,
        mouseover=false,ally=false,reset="target",
    }
    if class=="HUNTER" then
        draft.pet=template=="engage"
        for _,spell in ipairs(spells) do
            if spell.name=="Auto Shot" then
                draft.autoShot=template=="engage"
                break
            end
        end
    end
    return draft
end
local fields={
    main=true,shift=true,alt=true,ctrl=true,
    sequenceSecond=true,sequenceThird=true,
}
local switches={
    pet=true,autoShot=true,trinket13=true,trinket14=true,
    mouseover=true,ally=true,
}
local function Sanitize(incoming)
    local draft=ChalkBox_ForgeDraft(incoming and incoming.template)
    if type(incoming)~="table" then return draft end
    draft.class=type(incoming.class)=="string" and
        incoming.class:sub(1,24) or draft.class
    for key in pairs(fields) do
        draft[key]=Number(incoming[key]) and incoming[key] or nil
    end
    for key in pairs(switches) do draft[key]=incoming[key]==true end
    if incoming.reset=="target" or incoming.reset=="combat" or
        incoming.reset=="none" then draft.reset=incoming.reset end
    return draft
end
function ChalkBox_ForgeSet(draft,key,value)
    if type(draft)~="table" then return false end
    if fields[key] then
        if value~=nil and not Number(value) then return false end
        draft[key]=value
        return true
    end
    if switches[key] then
        draft[key]=value==true
        return true
    end
    if key=="reset" and
        (value=="target" or value=="combat" or value=="none") then
        draft.reset=value;return true
    end
    return false
end
local function HasSpellNamed(name)
    for _,spell in ipairs(ChalkBox_ForgeScan()) do
        if spell.name==name then return true end
    end
    return false
end
local function TrimWarnings(warnings)
    local res={}
    for _,msg in ipairs(warnings) do if #res<12 then
        res[#res+1]=msg end end
    return res
end
function ChalkBox_ForgeGenerate(recipe)
    local d=Sanitize(recipe)
    local errors,warnings={},{}
    local function Err(v) errors[#errors+1]=v end
    local function Warn(v) warnings[#warnings+1]=v end
    if d.class~=Class() then
        Err("This recipe belongs to a "..d.class..
            "; choose a learned spell on your current character.")
    end
    local names={}
    for key in pairs(fields) do
        local id=d[key]
        if id then
            local name=SpellName(id)
            if name then names[key]=name
            else Err("An assigned spell is no longer learned (ID "..id..").") end
        end
    end
    if not names.main then Err("Choose a learned main spell.") end
    local lines={"#showtooltip"}
    -- Trinket slots are attempts, not promises. A cooldown or passive trinket
    -- cannot be detected as a valid cast by a macro.
    if d.trinket13 then
        lines[#lines+1]="/use [combat] 13"
        Warn("Slot 13 is only attempted in combat; passive/on-cooldown trinkets do nothing.")
    end
    if d.trinket14 then
        lines[#lines+1]="/use [combat] 14"
        Warn("Slot 14 is only attempted in combat; shared item cooldowns may prevent a use.")
    end
    if d.trinket13 or d.trinket14 then
        local status=ChalkBox_ForgeTrinketStatus()
        for _,slot in ipairs({13,14}) do
            if (slot==13 and d.trinket13) or
                (slot==14 and d.trinket14) then
                local info=status[slot]
                if not info.itemID then
                    Warn("No trinket detected in slot "..slot.." right now.")
                elseif not info.hasOnUse then
                    Warn("Slot "..slot.." has no confirmed on-use effect; /use is only an attempt.")
                end
            end
        end
    end
    if d.pet then
        if d.class=="HUNTER" or d.class=="WARLOCK" then
            lines[#lines+1]="/petattack [harm,nodead]"
        else Warn("Pet attack was omitted: your class does not normally have a combat pet.") end
    end
    if d.template=="sequence" then
        local seq={}
        for _,key in ipairs({"main","sequenceSecond","sequenceThird"}) do
            if names[key] then seq[#seq+1]=names[key] end
        end
        if #seq<2 then Err("A sequence requires at least two learned spells.") end
        local reset=d.reset=="none" and "" or
            (d.reset=="combat" and "reset=combat " or "reset=target/6 ")
        lines[#lines+1]="/castsequence [harm,nodead] "..reset..
            table.concat(seq,", ")
        Warn("Sequence: one successful step per press; failed/out-of-range steps can stall.")
        Warn("A sequence cannot skip spells based on cooldowns or proc buffs.")
    elseif d.template=="modifiers" then
        local segments={}
        for _,key in ipairs({"shift","alt","ctrl"}) do
            if names[key] then
                segments[#segments+1]="[mod:"..key.."] "..names[key]
            end
        end
        if names.main then segments[#segments+1]="[nomod] "..names.main end
        lines[#lines+1]="/cast "..table.concat(segments,";")
        Warn("Hold Shift, Alt or Ctrl to cast that branch; one spell per press.")
    elseif d.template=="utility" then
        if d.ally then
            lines[#lines+1]="/cast [@mouseover,help,nodead][help,nodead][@player] "..
                (names.main or "")
        elseif d.mouseover then
            lines[#lines+1]="/cast [@mouseover,harm,nodead][] "..
                (names.main or "")
        else lines[#lines+1]="/cast "..(names.main or "") end
        if d.ally then
            Warn("Friendly targeting is user-chosen, not inferred from spell effects.")
        end
    else
        if d.mouseover then
            lines[#lines+1]="/cast [@mouseover,harm,nodead][] "..
                (names.main or "")
        else lines[#lines+1]="/cast "..(names.main or "") end
        if d.template=="burst" then
            Warn("Trinkets can be attempted with one cast; GCD-locked spells cannot chain.")
        end
    end
    if d.autoShot then
        if d.class=="HUNTER" and HasSpellNamed("Auto Shot") then
            lines[#lines+1]="/cast !Auto Shot"
            Warn("Auto Shot is a separate toggle attempt, not a guaranteed extra cast.")
        else
            Warn("Auto Shot omitted: the current spellbook does not include it.")
        end
    end
    local body=table.concat(lines,"\n")
    if #body>MAX_BODY then
        Err(("Macro is %d bytes; the safe macro limit is %d. Remove options."):format(
            #body,MAX_BODY))
    end
    Warn("WoW only executes secure actions on actual keypresses; no automatic rotation.")
    return {body=body,bytes=#body,limit=MAX_BODY,
        valid=#errors==0,errors=errors,warnings=TrimWarnings(warnings),
        class=d.class,template=d.template,previewOnly=true}
end
function ChalkBox_ForgeSaved()
    local s=DB()
    local result={}
    for _,rec in ipairs(s.recipes) do
        if type(rec)=="table" and type(rec.name)=="string" then
            result[#result+1]={name=rec.name,class=rec.class,
                template=rec.template}
        end
    end
    return result
end
function ChalkBox_ForgeSave(name,recipe)
    if not SafeString(name) or #name>24 then
        return false,"Use a name from 1 to 24 letters/characters." end
    local s=DB()
    local d=Sanitize(recipe)
    local generated=ChalkBox_ForgeGenerate(d)
    if not generated.valid then
        return false,"Fix invalid or unlearned spell choices before saving."
    end
    for i,entry in ipairs(s.recipes) do
        if entry.name==name then
            s.recipes[i]={name=name,class=d.class,template=d.template,
                draft=d}
            s.draft=d
            return true,"Updated saved recipe '"..name.."'."
        end
    end
    if #s.recipes>=MAX_SAVED then
        return false,"Save limit reached (16 recipes). Delete an old one first."
    end
    s.recipes[#s.recipes+1]={
        name=name,class=d.class,template=d.template,draft=d}
    s.draft=d
    return true,"Saved '"..name.."'."
end
function ChalkBox_ForgeLoad(index)
    local entry=DB().recipes[index]
    if type(entry)~="table" or type(entry.draft)~="table" then return end
    return Sanitize(entry.draft),entry.name
end
function ChalkBox_ForgeDelete(index)
    local s=DB()
    if type(index)~="number" or index%1~=0 or
        index<1 or index>#s.recipes then return false end
    table.remove(s.recipes,index)
    return true
end
function ChalkBox_ForgeGetDraft()
    local s=DB()
    return s.draft and Sanitize(s.draft) or ChalkBox_ForgeDraft("engage")
end
function ChalkBox_ForgeRemember(draft)
    DB().draft=Sanitize(draft)
    return true
end
function ChalkBox_ForgeInstall(name,recipe)
    -- Only invoked from an explicit user click by the UI, never from events.
    if type(InCombatLockdown)=="function" and InCombatLockdown() then
        return false,"Cannot create macros in combat."
    end
    if type(CreateMacro)~="function" or
        type(GetNumMacros)~="function" or
        type(GetMacroInfo)~="function" then
        return false,"Native macro installation unavailable; copy into /macro."
    end
    if not SafeString(name) or #name>16 then
        return false,"Choose a macro name 1–16 characters long."
    end
    local generated=ChalkBox_ForgeGenerate(recipe)
    if not generated.valid then
        return false,"Cannot install: fix validation warnings/errors first."
    end
    local account,character=Call(GetNumMacros)
    if not Number(account) or not Number(character) then
        return false,"Cannot read existing macro slots; copy manually."
    end
    local scanned=0
    for i=1,math.min(500,account+character+120) do
        local existing=Call(GetMacroInfo,i)
        if existing==name then
            return false,"A macro with that name already exists. Rename it; nothing overwritten."
        end
        scanned=scanned+1
    end
    local ok,id=pcall(CreateMacro,name,"INV_Misc_QuestionMark",
        generated.body,true)
    if not ok or not Number(id) or id<1 then
        return false,"WoW refused macro creation (possibly full slots). Copy manually."
    end
    return true,"Created a new character-specific macro '"..name..
        "'; place it on your action bar."
end
function ChalkBox_ForgeTrinketStatus()
    local result={}
    for _,slot in ipairs({13,14}) do
        local item=Call(GetInventoryItemID,"player",slot)
        local label,usable
        if Number(item) and item>0 then
            label=Call(C_Item and C_Item.GetItemNameByID,item) or
                ("Item #"..item)
            local spellName=Call(C_Item and C_Item.GetItemSpell,item)
            usable=type(spellName)=="string" and #spellName>0
        end
        result[slot]={itemID=item,name=label,hasOnUse=usable}
    end
    return result
end
function ChalkBox_ForgeStatus()
    local spells,err=ChalkBox_ForgeScan()
    return {class=cachedClass or Class(),spells=#spells,
        saved=#DB().recipes,limit=MAX_BODY,
        scanError=err}
end
function ChalkBox_ForgeCommand(args)
    local cmd=(args or ""):match("^%s*(%S+)") or "open"
    if cmd=="rescan" then
        ChalkBox_ForgeScan(true)
        if type(ChalkBox_MacroForgeRefresh)=="function" then
            ChalkBox_MacroForgeRefresh()
        end
    end
    if cmd=="open" or cmd=="rescan" or cmd=="show" or cmd=="" then
        if type(ChalkBox_OpenMacroForge)=="function" then
            ChalkBox_OpenMacroForge()
        end
    elseif cmd=="status" then
        local status=ChalkBox_ForgeStatus()
        if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(
            ("|cff67c6b7MacroForge|r %s | %d learned active spells | %d saved builds."):format(
                status.class,status.spells,status.saved))
        end
    end
end
local events=CreateFrame("Frame")
for _,e in ipairs({"SPELLS_CHANGED","PLAYER_TALENT_UPDATE",
    "ACTIVE_TALENT_GROUP_CHANGED"}) do events:RegisterEvent(e) end
events:SetScript("OnEvent",function()
    cachedSpells=nil
    if type(ChalkBox_MacroForgeRefresh)=="function" then
        ChalkBox_MacroForgeRefresh()
    end
end)
