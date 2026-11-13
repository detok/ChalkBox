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
        "ChalkBox_MapDiscoveriesThemeRefresh"}) do
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
