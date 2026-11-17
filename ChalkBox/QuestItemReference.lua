-- Read-only Classic item -> quest reference. No Questie, network, timers,
-- saved state, login-time scan, or external addon dependency.
-- The bundled MIT data is historical Classic evidence, not proof of current
-- Forever quest availability. Live accepted-quest details always take priority.
local function Safe(v)
    return v~=nil and (type(issecretvalue)~="function" or not issecretvalue(v))
end
local function CallBool(fn,id)
    if type(fn)~="function" then return nil end
    local ok,v=pcall(fn,id)
    if ok and Safe(v) and type(v)=="boolean" then return v end
end
local function LiveTitle(id,base)
    local fn=C_QuestLog and C_QuestLog.GetTitleForQuestID
    if type(fn)=="function" then
        local ok,value=pcall(fn,id)
        if ok and Safe(value) and type(value)=="string"
            and value~="" and not value:find("^%s*$") then
            return value
        end
    end
    return base
end
function ChalkBox_QuestReferenceCandidates(itemID,maxLines)
    if not Safe(itemID) or type(itemID)~="number"
        or itemID<=0 or itemID~=math.floor(itemID) then return nil end
    local db=ChalkBoxClassicQuestReference
    if type(db)~="table" or type(db.items)~="table"
        or type(db.titles)~="table" then return nil end
    local links=db.items[itemID]
    if type(links)~="table" or #links==0 then return nil end
    local result={}
    -- Bound the work on frequent tooltip hovers, even for shared materials.
    -- Large lists are necessarily examples, not an exhaustive quest list.
    for i=1,math.min(#links,48) do
        local signed=links[i]
        if type(signed)=="number" and signed~=0 then
            local id=math.abs(signed)
            local title=db.titles[id]
            if type(title)=="string" and title~="" then
                title=LiveTitle(id,title)
                -- Tooltip text is treated as text, never allow a raw WoW
                -- escape marker or control character from reference data.
                title=title:gsub("[%c|]",""):sub(1,90)
                if title~="" then
                    local onQuest=CallBool(C_QuestLog and
                        C_QuestLog.IsOnQuest,id)
                    local completed=CallBool(C_QuestLog and
                        C_QuestLog.IsQuestFlaggedCompleted,id)
                    result[#result+1]={
                        id=id,title=title,
                        relation=signed>0 and "required" or "starts",
                        onQuest=onQuest,completed=completed,
                        provenance="Classic reference",
                    }
                end
            end
        end
    end
    table.sort(result,function(a,b)
        if (a.onQuest==true)~=(b.onQuest==true) then
            return a.onQuest==true
        end
        if (a.completed==true)~=(b.completed==true) then
            return a.completed~=true
        end
        if a.relation~=b.relation then return a.relation=="required" end
        return a.id<b.id
    end)
    local limit=type(maxLines)=="number" and math.floor(maxLines) or 3
    limit=math.max(1,math.min(5,limit))
    local total=#result
    while #result>limit do table.remove(result) end
    return result,total
end
