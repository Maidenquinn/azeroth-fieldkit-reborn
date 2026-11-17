-- Public installed Api.lua / Meter.lua, executed only in the isolated mock VM.
local R,T,S,L,d=FieldKitReborn,FieldKitNativeTools,FieldKitRebornStats,FieldKitMeterLedger,FieldKitRebornDB
AZS_ZONE={zone="naxx",class="hunter",run="r00000699"}
AZS_RUN={ph="paused",t=1000,endless=1,nbs="unknown",nbm="time",nbc=6,nbin=72,nb=1072}
AZS_SCHEDULE={};AZS_UNITS={};ROUTE("AZSZONE","");ROUTE("AZSRUN","")
local b=T.NextBoss();assert(b.left==72 and b.ordinal==6 and b.unknown and b.progress==nil)
local key=b.key
AZS_RUN={ph="paused",t=1001,endless=1,nbs="unknown",nbm="time",nbc=6,nbin=71}
ROUTE("AZSRUN","");assert(T.NextBoss().key==key and T.NextBoss().left==71)
ROUTE("AZSCAPS","cdr=75;crit=100;red=90;echo=25;haste=80")
assert(#S.CapLines()==5 and S.CapLines("crit")[1]==FieldKit_L("Maximum").." · "..FieldKit_L("Crit Chance")..": 100%")
ROUTE("AZSCAPS","crit=65");assert(#S.CapLines()==1 and string.find(S.CapLines("crit")[1],"65%%"))
-- Amounts beyond 64 bits remain doubles throughout native API and FieldKit.
d.meterRecent=false;L.Boundary();ROUTE("AZSMETER","Aimed Shot,200000000000000000000,20000000000000000000,1,0,19434")
local rows,total,rate,known=L.Read("damage")
assert(known and total==2e20 and rows[1].dmg==2e20,"Large native totals rejected/truncated")
local snap=AZS_GetMeterSnapshot({apiVersion=1,runId=AZS_API_RunId(),metric="damage",scope="self",period="run",groupBy="source",windowSeconds=0})
assert(snap and rate==snap.totals.displayRate.value,"Native rate time base changed")
assert(FieldKit.Number(2e20)==nil,"Geometry validator widened")
assert(FieldKit.MeterNumber(0/0)==nil and FieldKit.MeterNumber(math.huge)==nil)
assert(FieldKit.MeterNumber(3.402823669209385e38)~=nil and FieldKit.MeterNumber(1e100)==nil)
for _,lang in ipairs({"en","fr"}) do
 FieldKit_SetLanguage(lang);assert(string.len(FieldKitReferenceHUD.Amount(total))<15)
end
assert(L.Reset());ROUTE("AZSMETER","Aimed Shot,300000000000000000000,30000000000000000000,1,0,19434")
rows,total,rate,known=L.Read("damage");assert(known and total==1e20,"Large checkpoint difference broken")
local caps=AZS_GetMeterCapabilities()
assert(not R.SupportsHealing("received") and caps.features.nativeRecentWindows and caps.features.atomicCheckpoints)
print("PASS installed 0.6.9 public API: countdown remapping/sync ordinal, replaced stat caps, 128-bit-sized double totals and checkpoint differences, honest received-healing capabilities")
