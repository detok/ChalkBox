-- Unified ChalkBox presentation should recolor only its own registered frames.
_G.ChalkBoxDB={}
local counts={bar=0,toast=0,meter=0}
_G.ChalkBox_BarThemeRefresh=function() counts.bar=counts.bar+1 end
_G.ChalkBox_ToastThemeRefresh=function() counts.toast=counts.toast+1 end
_G.ChalkBox_MeterThemeRefresh=function() counts.meter=counts.meter+1 end
assert(loadfile("Theme.lua"))("ChalkBox")
local t=ChalkBox_ThemeGet()
assert(t.preset=="charcoal" and t.opacity==100 and t.accent=="gold")
local r,g,b,a=ChalkBox_ThemeBackground(0.7)
assert(r<0.02 and a==0.7,"default preserves The Bar's local opacity")
assert(ChalkBox_ThemeSet("preset","midnight"))
assert(ChalkBox_ThemeSet("opacity",40))
assert(ChalkBox_ThemeSet("accent","teal"))
r,g,b,a=ChalkBox_ThemeBackground(0.7)
assert(r>0.03 and b>g and a>0.27 and a<0.29,
    "global opacity is a separate background-only multiplier")
assert(counts.bar==3 and counts.toast==3 and counts.meter==3,
    "changing a global theme live-refreshes all three current modules")
local ar,ag,ab=ChalkBox_ThemeAccent()
assert(ag>ar and ag>ab/2,"selected accent is teal")
assert(ChalkBox_ThemeSet("r",95))
assert(ChalkBox_ThemeSet("g",110))
assert(ChalkBox_ThemeSet("b",130))
t=ChalkBox_ThemeGet()
assert(t.preset=="custom" and t.r==95 and t.g==110 and t.b==130)
assert(not ChalkBox_ThemeSet("opacity",-1) and
    not ChalkBox_ThemeSet("preset","typo"),
    "out of range color data is rejected")
ChalkBox_ThemeReset()
assert(ChalkBox_ThemeGet().preset=="charcoal" and
    ChalkBox_ThemeGet().opacity==100)
print("PASS: one global color system, safe custom RGB, local alpha multiplier, live refresh and reset")
