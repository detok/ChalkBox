-- MacroForge regression: Forever C_SpellBook, actual learned spells, GCD
-- warnings, byte limit, saved recipes, out-of-combat explicit install.
_G.ChalkBoxZoneDB={}
local events={}
_G.CreateFrame=function()
    local f={}
    function f:RegisterEvent(name) events[name]=true end
    function f:SetScript(name,callback)
        if name=="OnEvent" then _G.forgeEvent=callback end
    end
    return f
end
_G.UnitClass=function() return "Hunter","HUNTER" end
_G.Enum={
    SpellBookSpellBank={Player=0},
    SpellBookItemType={Spell=1,FutureSpell=2,Flyout=4}
}
local rows={
    {name="Auto Shot",id=75},
    {name="Hunter's Mark",id=1130},
    {name="Serpent Sting",id=1978},
    {name="Rapid Fire",id=3045},
    {name="Storm Form",id=67890},
    {name="Mend Pet",id=136,helpful=true},
    {name="Follow",id=9999,passive=true},
    {name="Not Learned Yet",id=98765,future=true},
}
_G.C_SpellBook={
    GetNumSpellBookSkillLines=function() return 2 end,
    GetSpellBookSkillLineInfo=function(i)
        return {name=i==1 and "Beast Mastery" or "Marksmanship",
            itemIndexOffset=i==1 and 0 or 4,
            numSpellBookItems=4}
    end,
    GetSpellBookItemInfo=function(slot)
        local a=rows[slot]
        if not a then return end
        return {itemType=a.future and 2 or 1,actionID=a.id,
            spellID=a.id,iconID=12345+slot,isPassive=a.passive}
    end,
    IsSpellBookItemHelpful=function(slot)
        return rows[slot] and rows[slot].helpful
    end,
}
_G.C_Spell={GetSpellInfo=function(id)
    for _,a in ipairs(rows) do if a.id==id then
        return {name=a.name,spellID=id,iconID=140000+id}
    end end
end}
_G.GetInventoryItemID=function(_,slot)
    if slot==13 then return 400 else return nil end
end
_G.C_Item={
    GetItemNameByID=function() return "Activated Trinket" end,
    GetItemSpell=function(id)
        if id==400 then return "Test Aura",1 end
    end,
}
local created={}
local combat=false
_G.InCombatLockdown=function() return combat end
_G.GetNumMacros=function() return 2,1 end
_G.GetMacroInfo=function(index)
    if index==1 then return "OldMacro",134400,"/cast Foo" end
end
_G.CreateMacro=function(name,icon,body,character)
    created[#created+1]={name=name,icon=icon,body=body,character=character}
    return 125
end
assert(loadfile("MacroForge.lua"))("ChalkBox")
assert(events.SPELLS_CHANGED and events.PLAYER_TALENT_UPDATE,
    "respec and spellbook changes refresh available spells")
local spells=ChalkBox_ForgeSpells()
assert(#spells==6,"modern spellbook excludes future spells and passives")
assert(ChalkBox_ForgeStatus().class=="HUNTER" and
    ChalkBox_ForgeStatus().spells==6)
local engaged=ChalkBox_ForgeDraft("engage")
assert(engaged.main==1130 and engaged.pet and engaged.autoShot,
    "Hunter opener selects learned Hunter's Mark and pet/shot")
local output=ChalkBox_ForgeGenerate(engaged)
assert(output.valid and output.bytes<=255 and
    output.body:find("/cast Hunter's Mark",1,true) and
    output.body:find("/petattack [harm,nodead]",1,true) and
    output.body:find("/cast !Auto Shot",1,true),
    "opener is a real, compact macro from available spells")
local burst=ChalkBox_ForgeDraft("burst")
assert(burst.main==3045,"Hunter burst prioritizes known Rapid Fire")
assert(ChalkBox_ForgeSet(burst,"trinket13",true))
assert(ChalkBox_ForgeSet(burst,"trinket14",true))
output=ChalkBox_ForgeGenerate(burst)
assert(output.valid and output.body:find("/use [combat] 13",1,true)
    and output.body:find("/use [combat] 14",1,true)
    and output.body:find("/cast Rapid Fire",1,true))
assert(ChalkBox_ForgeTrinketStatus()[13].hasOnUse and
    not ChalkBox_ForgeTrinketStatus()[14].itemID)
assert(table.concat(output.warnings," "):find("Slot 14"),
    "trinkets without a confirmed on-use item show a warning")
local sequence=ChalkBox_ForgeDraft("sequence")
output=ChalkBox_ForgeGenerate(sequence)
assert(output.valid and
    output.body:find("/castsequence [harm,nodead] reset=target/6",1,true),
    "sequence requires explicit repeated presses and a known reset")
assert(table.concat(output.warnings," "):find("stall"),
    "sequence limitations are communicated")
local mod=ChalkBox_ForgeDraft("modifiers")
output=ChalkBox_ForgeGenerate(mod)
assert(output.valid and output.body:find("[mod:shift]",1,true)
    and output.body:find("[nomod]",1,true),
    "modifier choices are conditional branches, not concurrent GCD casts")
local utility=ChalkBox_ForgeDraft("utility")
assert(ChalkBox_ForgeSet(utility,"main",136))
ChalkBox_ForgeSet(utility,"ally",true)
output=ChalkBox_ForgeGenerate(utility)
assert(output.valid and output.body:find("[@mouseover,help,nodead]",1,true),
    "friendly mouseover is explicit; no auto classification of harmful spells")
local dirty=ChalkBox_ForgeDraft("burst")
ChalkBox_ForgeSet(dirty,"main",111111)
assert(not ChalkBox_ForgeGenerate(dirty).valid,
    "unlearned spells are invalid, never blindly generated")
assert(not ChalkBox_ForgeSet(dirty,"main","/run print('unsafe')"),
    "cannot inject raw Lua or arbitrary text into an action")
assert(ChalkBox_ForgeSave("Hunter Opener",engaged))
assert(#ChalkBox_ForgeSaved()==1)
local loaded=ChalkBox_ForgeLoad(1)
assert(loaded and loaded.main==1130)
assert(ChalkBox_ForgeInstall("CB Engage",engaged))
assert(#created==1 and created[1].character==true,
    "install only creates new character-specific macro")
local ok,msg=ChalkBox_ForgeInstall("OldMacro",engaged)
assert(not ok and msg:find("already exists") and #created==1,
    "cannot overwrite or collide with an existing macro")
combat=true
assert(not ChalkBox_ForgeInstall("CB Combat",engaged) and #created==1,
    "native macro writes are blocked during combat")
combat=false
assert(not ChalkBox_ForgeInstall("CB Script",dirty) and #created==1,
    "invalid spell selections cannot be installed")
-- A respec removes the main ability. Saved recipe must be flagged immediately.
rows[2].future=true
forgeEvent(nil,"SPELLS_CHANGED")
local changed=ChalkBox_ForgeGenerate(loaded)
assert(not changed.valid and
    table.concat(changed.errors," "):find("no longer learned"),
    "saved recipes revalidate after respec and show missing spells")
rows[2].future=false
forgeEvent(nil,"SPELLS_CHANGED")
local count=#ChalkBox_ForgeSpells()
assert(count==6)
local longNames={}
for i=1,4 do
    local name="Very Long and Highly Descriptive Spell Name Number "..i..
        " That Will Overflow the Macro"
    rows[#rows+1]={name=name,id=200000+i}
    longNames[#longNames+1]=200000+i
end
C_SpellBook.GetNumSpellBookSkillLines=function() return 1 end
C_SpellBook.GetSpellBookSkillLineInfo=function()
    return {name="Long",itemIndexOffset=0,numSpellBookItems=#rows}
end
forgeEvent(nil,"SPELLS_CHANGED")
local big=ChalkBox_ForgeDraft("modifiers")
ChalkBox_ForgeSet(big,"main",longNames[1])
ChalkBox_ForgeSet(big,"shift",longNames[2])
ChalkBox_ForgeSet(big,"alt",longNames[3])
ChalkBox_ForgeSet(big,"ctrl",longNames[4])
local large=ChalkBox_ForgeGenerate(big)
assert(not large.valid and large.bytes>large.limit,
    "never let WoW silently truncate a too-long generated macro")
assert(ChalkBox_ForgeDelete(1) and #ChalkBox_ForgeSaved()==0)
print("PASS: modern Forever spellbook, Hunter templates, trinkets, GCD guidance, modifiers, sequences, save/respec validation, byte limit and safe native install")
