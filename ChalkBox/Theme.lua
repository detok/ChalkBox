-- ChalkBox global presentation system. Decorative surfaces only;
-- never recolor Blizzard's own interface, rarity borders or secure frames.
local presets={
    charcoal={0.018,0.018,0.022},
    midnight={0.035,0.055,0.075},
    slate={0.095,0.115,0.14},
}
local accents={
    gold={0.86,0.66,0.38},
    teal={0.40,0.79,0.72},
    neutral={0.76,0.78,0.80},
}
-- One restrained semantic palette for our tooltips. Blizzard rarity/text
-- colors remain untouched; only ChalkBox-added lines use these roles.
local tooltipColors={
    title={0.94,0.76,0.42},
    good={0.39,0.94,0.62},
    info={0.40,0.83,0.78},
    value={0.98,0.79,0.39},
    count={0.51,0.76,0.98},
    warning={0.98,0.66,0.33},
    danger={0.98,0.45,0.40},
    muted={0.65,0.70,0.73},
    text={0.85,0.87,0.88},
}
function ChalkBox_TipColor(role)
    local rgb=tooltipColors[role] or tooltipColors.text
    return rgb[1],rgb[2],rgb[3]
end
-- One small presentation contract for our OWN tooltip lines. No secure
-- frame mutation, no edits to Blizzard's text, no persistent state.
function ChalkBox_TipLine(tooltip,message,role,wrap)
    if not tooltip or type(tooltip.AddLine)~="function" or
        message==nil then return false end
    local r,g,b=ChalkBox_TipColor(role or "text")
    tooltip:AddLine(tostring(message),r,g,b,wrap==true)
    return true
end
function ChalkBox_TipSection(tooltip,title,spacer)
    if not tooltip or type(tooltip.AddLine)~="function" or
        type(title)~="string" or title=="" then return false end
    if spacer==true then ChalkBox_TipLine(tooltip," ","muted") end
    return ChalkBox_TipLine(tooltip,title,"info")
end
function ChalkBox_TipMetric(tooltip,label,value,role)
    if not tooltip or type(tooltip.AddLine)~="function" then return false end
    local r,g,b=ChalkBox_TipColor(role)
    if type(tooltip.AddDoubleLine)=="function" then
        tooltip:AddDoubleLine(label,tostring(value),0.81,0.84,0.85,r,g,b)
    else
        tooltip:AddLine(label..": "..tostring(value),r,g,b)
    end
    return true
end

local function Number(v)
    return type(v)=="number" and v==v and
        (type(issecretvalue)~="function" or not issecretvalue(v))
end
local function Clamp(v)
    return math.max(0,math.min(100,math.floor(v+0.5)))
end
local function Settings()
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    local s=ChalkBoxDB.theme
    if type(s)~="table" then s={};ChalkBoxDB.theme=s end
    if s.preset~="charcoal" and s.preset~="midnight" and
        s.preset~="slate" and s.preset~="custom" then s.preset="charcoal" end
    if s.accent~="gold" and s.accent~="teal" and
        s.accent~="neutral" then s.accent="gold" end
    if not Number(s.opacity) or s.opacity<0 or s.opacity>100 then
        s.opacity=100 -- preserve the old independent opacity sliders
    end
    if type(s.custom)~="table" then s.custom={24,29,36} end
    for i=1,3 do
        if not Number(s.custom[i]) or s.custom[i]<0 or s.custom[i]>255 then
            s.custom[i]=24+i*4
        end
    end
    return s
end
function ChalkBox_ThemeGet()
    local s=Settings()
    return {preset=s.preset,opacity=s.opacity,accent=s.accent,
        r=s.custom[1],g=s.custom[2],b=s.custom[3]}
end
function ChalkBox_ThemeBackground(baseAlpha)
    local s=Settings()
    local rgb=presets[s.preset]
    local r,g,b
    if rgb then r,g,b=rgb[1],rgb[2],rgb[3]
    else r,g,b=s.custom[1]/255,s.custom[2]/255,s.custom[3]/255 end
    local alpha=Number(baseAlpha) and math.max(0,math.min(1,baseAlpha)) or 1
    return r,g,b,alpha*s.opacity/100
end
function ChalkBox_ThemeAccent()
    local rgb=accents[Settings().accent]
    return rgb[1],rgb[2],rgb[3]
end
local function Notify()
    for _,name in ipairs({"ChalkBox_BarThemeRefresh",
        "ChalkBox_ToastThemeRefresh","ChalkBox_MeterThemeRefresh",
        "ChalkBox_MapDiscoveriesThemeRefresh",
        "ChalkBox_MacroForgeThemeRefresh",
        "ChalkBox_JournalThemeRefresh"}) do
        if type(_G[name])=="function" then pcall(_G[name]) end
    end
end
function ChalkBox_ThemeSet(key,value)
    local s=Settings()
    if key=="preset" and
        (value=="charcoal" or value=="midnight" or value=="slate" or
            value=="custom") then s.preset=value
    elseif key=="accent" and accents[value] then s.accent=value
    elseif key=="opacity" and Number(value) and value>=0 and value<=100 then
        s.opacity=Clamp(value)
    elseif (key=="r" or key=="g" or key=="b") and Number(value) and
        value>=0 and value<=255 then
        local i=key=="r" and 1 or (key=="g" and 2 or 3)
        s.custom[i]=math.floor(value+0.5)
        s.preset="custom"
    else return false end
    Notify()
    return true
end
function ChalkBox_ThemeReset()
    if type(ChalkBoxDB)~="table" then ChalkBoxDB={} end
    ChalkBoxDB.theme=nil
    Notify()
end
