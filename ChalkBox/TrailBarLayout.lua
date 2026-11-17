-- ChalkBox 1.9: deterministic, per-character TrailBar layout preferences.
-- Never touches protected game frames. Records order/section/justification only.
local DEFAULT={
    left={"level","rate"},
    center={"time","eta","rested"},
    right={"bags","gear","repair","bagvalue","bankvalue","gold","latency","pet"},
}
local orderedKeys={"level","rate","bags","gear","eta","rested","pet","time","latency","bagvalue","bankvalue","repair","gold"}
local valid={}
for _,key in ipairs(orderedKeys) do valid[key]=true end
local sectionNames={"left","center","right"}
-- Saved widths are independent of order/alignment and are intentionally
-- bounded. Widths are per character and never change Blizzard frames.
local MIN_WIDTH,MAX_WIDTH=60,280
local function Width(value)
    return type(value)=="number" and value==value and
        value>=MIN_WIDTH and value<=MAX_WIDTH and value%1==0
end

local function Store()
    if type(ChalkBoxZoneDB)~="table" then ChalkBoxZoneDB={} end
    if type(ChalkBoxZoneDB.trailLayout)~="table" then
        ChalkBoxZoneDB.trailLayout={}
    end
    return ChalkBoxZoneDB.trailLayout
end
local function Normalized()
    local saved=Store()
    local layout={left={},center={},right={},align={}}
    local placed={}
    for _,section in ipairs(sectionNames) do
        local list=type(saved[section])=="table" and saved[section] or {}
        for _,key in ipairs(list) do
            if valid[key] and not placed[key] then
                layout[section][#layout[section]+1]=key
                placed[key]=true
            end
        end
    end
    for _,section in ipairs(sectionNames) do
        for _,key in ipairs(DEFAULT[section]) do
            if not placed[key] then
                layout[section][#layout[section]+1]=key
                placed[key]=true
            end
        end
    end
    for _,key in ipairs(orderedKeys) do
        local mode=type(saved.align)=="table" and saved.align[key]
        if mode=="left" or mode=="center" or mode=="right" then
            layout.align[key]=mode
        end
    end
    return layout
end
local function Persist(layout)
    local saved=Store()
    for _,section in ipairs(sectionNames) do
        saved[section]={}
        for _,key in ipairs(layout[section]) do
            saved[section][#saved[section]+1]=key
        end
    end
    saved.align={}
    for key,mode in pairs(layout.align) do saved.align[key]=mode end
end
function ChalkBox_BarLayoutGet()
    return Normalized()
end
function ChalkBox_BarLayoutWidthGet(key)
    if not valid[key] then return nil end
    local saved=Store()
    local value=type(saved.widths)=="table" and saved.widths[key]
    return Width(value) and value or nil
end
function ChalkBox_BarLayoutWidthSet(key,value)
    if not valid[key] or type(value)~="number" or value~=value or
        value==math.huge or value==-math.huge then return false end
    local width=math.floor(math.max(MIN_WIDTH,
        math.min(MAX_WIDTH,value))/4+0.5)*4
    local saved=Store()
    if type(saved.widths)~="table" then saved.widths={} end
    saved.widths[key]=width
    return true
end
function ChalkBox_BarLayoutWidthReset(key)
    if not valid[key] then return false end
    local saved=Store()
    if type(saved.widths)=="table" then saved.widths[key]=nil end
    return true
end
function ChalkBox_BarLayoutMove(key,section,position)
    if not valid[key] or not DEFAULT[section] then return false end
    local layout=Normalized()
    for _,group in ipairs(sectionNames) do
        for i=#layout[group],1,-1 do
            if layout[group][i]==key then table.remove(layout[group],i) end
        end
    end
    local list=layout[section]
    local index=tonumber(position) or #list+1
    index=math.max(1,math.min(#list+1,math.floor(index)))
    table.insert(list,index,key)
    Persist(layout)
    return true
end
function ChalkBox_BarLayoutAlign(key,align)
    if not valid[key] or (align~="left" and align~="center" and align~="right") then
        return false
    end
    local layout=Normalized()
    layout.align[key]=align
    Persist(layout)
    return true
end
function ChalkBox_BarLayoutReset()
    local saved=Store()
    for _,section in ipairs(sectionNames) do saved[section]=nil end
    saved.align=nil
    saved.widths=nil
    return Normalized()
end
function ChalkBox_BarLayoutDescription()
    local layout=Normalized()
    return ("Left: %s  |  Center: %s  |  Right: %s"):format(
        table.concat(layout.left,", "),
        table.concat(layout.center,", "),
        table.concat(layout.right,", "))
end
