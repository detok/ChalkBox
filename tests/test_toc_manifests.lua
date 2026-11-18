-- Every supported Forever TOC loads the same code, in the same order.
-- A new module included in only one client's TOC is effectively broken.
local function Files(name)
    local result={}
    for line in io.lines(name) do
        if line:match("%.lua$") then
            local path=line:gsub("\\","/")
            local file=io.open(path,"r")
            assert(file,"listed addon source missing: "..path)
            file:close()
            result[#result+1]=path
        end
    end
    return result
end
local main=Files("ChalkBox.toc")
local camelot=Files("ChalkBox_Camelot.toc")
assert(#main==#camelot and #main>30,
    "supported WoW TOCs must have the same source count")
local coordinator,loot
for i,path in ipairs(main) do
    assert(path==camelot[i],
        "different addon load order across Forever clients: "..path)
    if path=="TooltipCoordinator.lua" then coordinator=i end
    if path=="LootSense.lua" then loot=i end
end
assert(coordinator and loot and coordinator<loot,
    "the unified tooltip module must load before LootSense's callback")
assert(main[coordinator-1]=="FutureQuestItems.lua",
    "future-quest data must be available before tooltip coordination")
print("PASS: both supported WoW TOCs include one coordinator with identical load ordering and source files")
