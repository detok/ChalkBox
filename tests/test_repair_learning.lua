-- RepairLearning: save observed merchant quotes, learn rate per damage,
-- weight matching equipment, limit history, detect errors and reset safely.
_G.ChalkBoxZoneDB={}
local function Gear(missing,max,fingerprint,items)
    return {current=max-missing,max=max,items=items or 4,
        fingerprint=fingerprint}
end
assert(loadfile("RepairLearning.lua"))("ChalkBox")
local first=Gear(150,400,"gear-a",4)
local prediction=ChalkBox_RepairLearningPredict(Gear(160,400,"gear-a"))
assert(prediction.state=="unavailable" and prediction.copper==nil,
    "no price predictions without observed repair costs")
assert(ChalkBox_RepairLearningObserve(first,30000),
    "merchant quote is added as one real training example")
assert(not ChalkBox_RepairLearningObserve(first,30000),
    "repeated five-second observations must not skew the training")
local status=ChalkBox_RepairLearningStatus()
assert(status.samples==1 and status.limit==32)
prediction=ChalkBox_RepairLearningPredict(Gear(160,400,"gear-a"))
assert(prediction.state=="estimate" and prediction.copper==32000 and
    prediction.source=="same-gear" and prediction.samples==1,
    "estimate scales verified cost per damage for the same gear")
assert(ChalkBox_RepairLearningObserve(Gear(100,400,"gear-a"),22000),
    "new damage/quote combination is a new training sample")
status=ChalkBox_RepairLearningStatus()
assert(status.samples==2 and status.lastError==9,
    "actual new quote grades previous estimate as 9% different")
prediction=ChalkBox_RepairLearningPredict(Gear(160,400,"gear-a"))
assert(prediction.state=="estimate" and
    prediction.copper>32000 and prediction.copper<36000 and
    prediction.matched==2,"multiple observations adjust the prediction")
-- A radically different repair price for another gear setup must not distort
-- the estimate for the known setup, even if the durability pool is the same.
assert(ChalkBox_RepairLearningObserve(Gear(90,400,"gear-b"),90000))
prediction=ChalkBox_RepairLearningPredict(Gear(160,400,"gear-a"))
assert(prediction.copper>32000 and prediction.copper<36000 and
    prediction.matched==2,
    "different gear is stored but does not contaminate same-gear estimates")
prediction=ChalkBox_RepairLearningPredict(Gear(160,900,"gear-c"))
assert(prediction.state=="needs-calibration" and prediction.copper==nil,
    "very different durability pools cannot borrow an old quote")
prediction=ChalkBox_RepairLearningPredict(Gear(0,400,"gear-a"))
assert(prediction.state=="no-damage" and prediction.copper==0,
    "undamaged equipped gear is zero, but may not cover items in bags")
assert(not ChalkBox_RepairLearningObserve(Gear(150,400,"gear-a"),0),
    "zero quote never teaches a positive repair rate")
assert(not ChalkBox_RepairLearningObserve(Gear(150,400,"gear-a"),-1),
    "invalid cost cannot corrupt persistent learning data")
assert(ChalkBoxZoneDB.repairLearning.samples[1].cost==30000,
    "merchant price is persisted per character")
-- Compact stable persistence: no giant unbounded SaveVariables or repeated
-- identical samples, even after many visits.
for i=1,38 do
    ChalkBox_RepairLearningObserve(Gear(10+i,400,"gear-a"),(10+i)*200)
end
assert(ChalkBox_RepairLearningStatus().samples==32 and
    #ChalkBoxZoneDB.repairLearning.samples==32,
    "learned history is capped at 32 distinct merchant observations")
assert(loadfile("RepairLearning.lua"))("ChalkBox")
assert(ChalkBox_RepairLearningStatus().samples==32,
    "model and samples survive module reload/logging back in")
assert(ChalkBox_RepairLearningReset())
assert(ChalkBox_RepairLearningStatus().samples==0 and
    ChalkBox_RepairLearningPredict(Gear(180,400,"gear-a")).state=="unavailable",
    "reset removes learned history without affecting other user settings")
ChalkBoxZoneDB.repairReference={rate=200,max=400}
prediction=ChalkBox_RepairLearningPredict(Gear(150,400,"gear-a"))
assert(prediction.state=="estimate" and prediction.copper==30000 and
    prediction.source=="legacy" and prediction.samples==0,
    "existing 1.9.2 character-specific calibration remains usable")
ChalkBox_RepairLearningReset()
-- Malformed saved data must not crash or fabricate counts.
ChalkBoxZoneDB.repairLearning={version=1,samples={
    {cost=-9,missing=99,max=100,items=3},
    {cost=30000,missing=150,max=400,items=4}
},errors={}}
assert(ChalkBox_RepairLearningStatus().samples==1,
    "invalid past data is ignored rather than counted")
assert(not ChalkBox_RepairLearningObserve({},30000),
    "invalid equipment data is ignored")
print("PASS: RepairLearning same-gear matching, persistent bounded samples, predicted error, outlier isolation, invalidation, legacy fallback and reset")
