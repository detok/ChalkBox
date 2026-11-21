-- Permanent release invariant: no combat reporting code is loadable.
local function Read(path)
    local f=assert(io.open(path,"r"))
    local text=f:read("*a");f:close()
    return text
end
for _,toc in ipairs({"ChalkBox.toc","ChalkBox_Camelot.toc"}) do
    local content=Read(toc)
    assert(not content:find("NativeMeterPrint.lua",1,true)
        and not content:find("MeterReportCopy.lua",1,true),
        "no report modules load in either WoW client")
end
local p=Read("../scripts/package.py")
assert(not p:find('"NativeMeterPrint.lua"',1,true)
    and not p:find('"MeterReportCopy.lua"',1,true),
    "the distributable archive contains no reporter modules")
local meter=Read("CombatMeter.lua")
assert(not meter:find("SendChatMessage",1,true)
    and not meter:find("C_ChatInfo",1,true),
    "meter display itself contains no group chat sender")
assert(meter:find("function ChalkBox_MeterPrintFight() return false end",1,true)
    and meter:find("function ChalkBox_MeterReportSelected() return false end",1,true))
local menu=Read("CombatMeterMenu.lua")
assert(not menu:find('Add("Reports"',1,true)
    and not menu:find("ChalkBox_MeterReportSelected",1,true)
    and not menu:find("ChalkBox_NativeMeterCommand",1,true))
print("PASS: report modules are excluded, no chat sender remains, legacy calls silent")
