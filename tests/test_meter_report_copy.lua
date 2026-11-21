-- No manual copy/report workflow is present in shipped addon.
local function Read(path)
    local f=assert(io.open(path,"r"))
    local text=f:read("*a");f:close()
    return text
end
assert(not Read("ChalkBox.toc"):find("MeterReportCopy.lua",1,true))
assert(not Read("ChalkBox_Camelot.toc"):find("MeterReportCopy.lua",1,true))
assert(not Read("../scripts/package.py"):find('"MeterReportCopy.lua"',1,true))
print("PASS: report copy window absent from installable addon")
