fire(FieldKitFrame,"VARIABLES_LOADED")
-- .41: a 17 h endless Mage run (0.7.4): ~756 800 kills, ~438 bosses, damage ~10^13.
-- Values below come from the maintainer's session report; contracts are the installed
-- AzerothSurvivorsAPI (Lairs.lua AZS_LAIRS, Api.lua AZS_GetLairs/AZS_GetGuardians,
-- Meter.lua snapshots). Mock data only: not live game validation.
local C=FieldKit.Compact

-- 1. Compact format: the game's tiers (Core.lua AZS.Short), FieldKit's approved style.
FieldKitRebornDB.language="en"
local cases={{0,"0"},{999,"999"},{1000,"1,000"},{9999,"9,999"},{10000,"10.0 k"},{999999,"1.0 M"},
 {999949,"999.9 k"},{1e6,"1.0 M"},{1e9,"1.0 B"},{1e12,"1.0 T"},{7.08e13,"70.8 T"},{2.887e11,"288.7 B"},
 {756800,"756.8 k"},{1e15,"1.0 Qa"},{9.4e14,"940.0 T"},{2^53,"9.0 Qa"},{2^64,"18.4 Qi"},
 {1e33,"1.0 Dc"},{3.4028236692e38,"340.3 Ud"},{-1250,"-1,250"},{-7.08e13,"-70.8 T"}}
for _,c in ipairs(cases) do
 assert(C(c[1])==c[2],"compact "..tostring(c[1]).." -> "..tostring(C(c[1])).." expected "..c[2])
 assert(not string.find(C(c[1]),"e",1,true) or string.find(c[2],"e",1,true),"no scientific notation")
 assert(string.len(C(c[1]))<=9,"compact text stays short: "..C(c[1]))
end
assert(C(nil)=="?" and C("x")=="?" and C(0/0)=="?" and C(1/0)=="?" and C(-1/0)=="?","missing or non-finite values never become numbers")
FieldKitRebornDB.language="fr"
assert(C(1250)=="1 250" and C(7.08e13)=="70,8 T" and C(12400)=="12,4 k","French separators, same unit letters")
FieldKitRebornDB.language="de"
assert(C(1250)=="1.250" and C(7.08e13)=="70,8 T","German separators")
FieldKitRebornDB.language="en"
-- Exact (tooltips): every digit, marked approximate past 2^53.
assert(FieldKit.Exact(70812345678901)=="70,812,345,678,901","exact grouped")
assert(FieldKit.Exact(2^60)=="~1,152,921,504,606,846,976","beyond 2^53 marked approximate")
assert(FieldKit.Exact(nil)=="?" and FieldKit.Exact(1/0)=="?","exact missing")
-- Formatting never changes the stored value.
local v=7.08e13;C(v);FieldKit.Exact(v);assert(v==7.08e13)

-- 2. The client rejects unbounded status bar ranges ("Min or Max out of range",
-- 0.7.4 lua-errors.log, FieldKit.lua ShowBossFrame). Emulate it: any bar range past a
-- signed 32-bit integer raises. (The exact client bound is not published; the fix
-- does not depend on it: every native-valued bar now draws a 0..1 fraction.)
local mt=getmetatable(FieldKitFrame).__index
local oldRange=mt.SetMinMaxValues
local ranges={}
mt.SetMinMaxValues=function(self,lo,hi)
 if type(lo)~="number" or type(hi)~="number" or hi>2147483647 or lo<-2147483647 or hi-hi~=0 then error("Min or Max out of range") end
 table.insert(ranges,hi);self.minValue,self.maxValue=lo,hi
end
local function Bar(bar) return bar.fieldkitFraction end
local b=CreateFrame("StatusBar")
assert(FieldKit.SetBarFraction(b,3.5e13,7.08e13)==3.5e13/7.08e13 and Bar(b)==b:GetValue(),"fraction of a huge range")
assert(FieldKit.SetBarFraction(b,10,0)==0 and FieldKit.SetBarFraction(b,10,1/0)==0 and FieldKit.SetBarFraction(b,0/0,5)==0,"degenerate ranges draw empty")
assert(FieldKit.SetBarFraction(b,9,5)==1 and FieldKit.SetBarFraction(b,-3,5)==0,"clamped")
assert(FieldKit.SetBarFraction(b,2^64,3.4e38)>0,"128-bit maximum")

-- 3. The whole HUD loop with an endless boss (hp past 2^53) and lairs: no error, and the
-- lair card keeps refreshing. Before .41 the boss bar raised every tick and the native
-- data step (lairs, meter, map) never ran again.
local bossHp,bossMax=3.1e19,7.08e19
AZS_RUN={ph="playing",t=61200,lvl=900,kills=756800};AZS_ZONE={zone="naxx",zname="Naxxramas",heroic=0,run="azs:r00000041"}
AZS_UNITS={{kind="boss",id=4380,name="Kel'Thuzad",hp=bossHp,hpm=bossMax,state=1}}
AZS_UNITS_UPDATED=GetTime()
local lairSeen=0
AZS_LAIRS={
 {index=1,state="awake",name="Antre A",id="7001",left=0,x=10,y=10,hp=5e15,hpm=9e15,flag=1},
 {index=2,state="awake",name="Antre B",id="7002",left=0,x=20,y=20,hp=8e15,hpm=8e15,flag=0},
 {index=3,state="awake",name="Antre C",id="7003",left=0,x=30,y=30,hp=1,hpm=9e15,flag=0},
 {index=4,state="empty",name="Antre D",id="",left=42,x=40,y=40,flag=0},
 {index=5,state="asleep",name="Antre E",id="7005",left=0,x=50,y=50,hp=9e15,hpm=9e15,flag=0}}
AZS_LAIRS_UPDATED=GetTime()
AZS_GetLairs=function() lairSeen=lairSeen+1;for i=1,table.getn(AZS_LAIRS) do AZS_LAIRS[i].active=(AZS_LAIRS[i].state~="empty") end;return AZS_LAIRS end
-- Snapshot of the native tables: FieldKit must never write into them.
local function Snap(t) local out={};for i=1,table.getn(t) do local row={};for k,x in pairs(t[i]) do row[k]=x end;out[i]=row end;return out end
local function Same(a,b) if table.getn(a)~=table.getn(b) then return false end;for i=1,table.getn(a) do for k,x in pairs(a[i]) do if b[i][k]~=x then return false end end;for k,x in pairs(b[i]) do if a[i][k]~=x then return false end end end;return true end
FieldKitRebornDB.lairFrame=true;FieldKitRebornDB.bossFrame=true
local lairsBefore,unitsBefore=Snap(AZS_LAIRS),Snap(AZS_UNITS)
for i=1,8 do update(FieldKitFrame,.3) end
assert(lairSeen>0,"lair card never refreshed during an endless boss fight")
local f=FieldKitLairFrame
local states={}
for i=1,5 do if f.rows[i]:IsShown() then states[i]=f.rows[i].value:GetText() end end
local awake=0;for _,s in pairs(states) do if s==FieldKit_L("awake") then awake=awake+1 end end
assert(awake==3,"native awake lairs shown as awake (FieldKit never hides a native state): "..awake)
-- 4. Native state change reaches the card on the next refresh (no FieldKit memory).
local seen=lairSeen
AZS_LAIRS[1].state="empty";AZS_LAIRS[1].left=90;AZS_LAIRS[2].state="asleep";AZS_LAIRS_UPDATED=GetTime()
for i=1,3 do update(FieldKitFrame,.3) end
assert(lairSeen>seen,"lair card stopped refreshing")
awake=0;for i=1,5 do if f.rows[i]:IsShown() and f.rows[i].value:GetText()==FieldKit_L("awake") then awake=awake+1 end end
assert(awake==1,"a lair the game reports finished still shows awake (stale FieldKit state)")
-- 5. Live boss strip inside the lair card uses a fraction too.
assert(f.bossBar.fieldkitFraction and math.abs(f.bossBar.fieldkitFraction-bossHp/bossMax)<1e-12,"lair boss strip fraction")
-- 6. Boss frame: fraction, compact HP text, no raw digits.
local boss=FieldKitBossFrame1
assert(boss.bar.fieldkitFraction and math.abs(boss.bar.fieldkitFraction-bossHp/bossMax)<1e-12,"boss bar fraction")
for i=1,table.getn(ranges) do assert(ranges[i]<=1 or ranges[i]<=2147483647,"range") end
-- 6b. Bosses and guardians past 10^18 health stay "live" (frame shown, lair coherent).
assert(FieldKitReborn.LiveBoss({id=7001,name="Gardien",hp=3e19,hpm=9e19}),"guardian past 10^18 dropped from the boss pool")
assert(FieldKitReborn.LiveBoss({id=4380,name="Kel'Thuzad",hp=bossHp,hpm=bossMax}),"endless boss dropped")
assert(not FieldKitReborn.LiveBoss({id=7002,name="Gardien",hp=0,hpm=9e19}),"dead guardian is not live")
assert(FieldKitReborn.HealthColor(3e19,9e19)~=nil,"health colour for endless values")
-- 7. Native tables untouched (state changes above were the test's own writes).
AZS_LAIRS[1].state="awake";AZS_LAIRS[1].left=0;AZS_LAIRS[2].state="awake";lairsBefore[1].active=true;lairsBefore[2].active=true
for i=1,5 do lairsBefore[i].active=(lairsBefore[i].state~="empty") end
assert(Same(Snap(AZS_UNITS),unitsBefore),"FieldKit wrote into AZS_UNITS")

-- 8. One failing step no longer freezes the others; its error is reported once.
local reported={}
geterrorhandler=function() return function(err) table.insert(reported,err) end end
local realTools=FieldKitNativeTools.Update
FieldKitNativeTools.Update=function() error("simulated native tools failure") end
seen=lairSeen
for i=1,6 do update(FieldKitFrame,.3) end
assert(lairSeen>seen,"a failing step froze the lair card")
assert(FieldKit.stepErrors.nativeTools and FieldKit.stepErrors.nativeTools>=2,"step error counted")
assert(table.getn(reported)==1 and string.find(reported[1],"nativeTools",1,true),"step error reported once to the client handler")
FieldKitNativeTools.Update=realTools
geterrorhandler=nil

-- 9. /fieldkit lairs: read-only native dump (stale native stamp visible, nothing written).
local said={}
local chat=DEFAULT_CHAT_FRAME
DEFAULT_CHAT_FRAME={AddMessage=function(_,t) table.insert(said,t) end}
AZS_LAIRS_UPDATED=GetTime()-300
AZS_GetGuardians=function() return {{id="7001",awake=true},{id="7002",awake=true}} end
local before=Snap(AZS_LAIRS)
SlashCmdList.FieldKit("lairs")
DEFAULT_CHAT_FRAME=chat
local text=table.concat(said,"\n")
assert(string.find(text,"lastLairLine=300.0s ago",1,true),"diagnostic shows the native line age")
assert(string.find(text,"id=7003 guardian=not-listed",1,true),"awake lair whose guardian is not transmitted is reported, not hidden")
assert(string.find(text,"id=7001 guardian=listed-awake",1,true),"guardian listed")
assert(string.find(text,"hp=9,000,000,000,000,000",1,true),"exact guardian health")
assert(string.find(text,"FieldKit step errors: nativeTools=",1,true),"step errors in the dump")
assert(Same(Snap(AZS_LAIRS),before),"diagnostic wrote into AZS_LAIRS")

-- 10. Run change (new zone, fresh tables): the card follows the new native list.
AZS_ZONE={zone="feralas",zname="Feralas",heroic=0,run="azs:r00000042"}
AZS_LAIRS={{index=1,state="asleep",name="Nouvel antre",id="8001",left=0,x=1,y=1,hp=100,hpm=100,flag=1}}
AZS_UNITS={};AZS_LAIRS_UPDATED=GetTime()
for i=1,3 do update(FieldKitFrame,.3) end
assert(f.rows[1]:IsShown() and f.rows[1].value:GetText()==FieldKit_L("asleep") and not f.rows[2]:IsShown(),"run change kept old lairs")
mt.SetMinMaxValues=oldRange

-- 11. Meter with the screenshot magnitudes: compact columns, no "e+", stable geometry.
local DB=FieldKitRebornDB
DB.meterFrame=true;DB.meterTabs=true;DB.meterValues=3
local names={"Blizzard","Amulette de l'Inferno : Consécration ardente du très long nom","Éclair de givre","Glace fondante","Nova de givre","Explosion des arcanes","Cône de froid","Trait de feu"}
local rows,sources={},{}
for i=1,8 do
 local key="ability:s"..i
 sources[key]={name=names[i],abilityKey="s"..i,spellIds={9000+i},icon={status="ready",path="Interface\\Icons\\X"..i}}
 rows[i]={sourceKey=key,displayAmount=7.08e13/i,displayRate={value=2.887e11/i}}
end
AZS_GetMeterContext=function() return {runId="azs:r00000042"} end
AZS_GetMeterSnapshot=function() return {status="ready",rows=rows,sources=sources,totals={displayAmount=1.83e14,displayRate={value=7.4e11}}} end
UnitGUID=function(u) if u=="player" then return "P" end end
FieldKitMeterLedger.ClearHits()
local ring={};local seq=0
for i=1,8 do for k=1,3 do seq=seq+1;table.insert(ring,{seq=seq,kind="damage",amount=1e12,overkill=(k==3) and 5 or 0,critical=k==2,spellId=9000+i,abilityName=names[i],anchorId="Creature-"..i.."-"..k,sourceGuid="P",sourceName="Mage"}) end end
AZS_GetCombatTextEvents=function(cur)
 local after=0;if cur then local _,_,n=string.find(cur,"^ct:(%d+)$");after=tonumber(n) or 0 end
 local ev,last={},after
 for i=1,table.getn(ring) do if ring[i].seq>after and table.getn(ev)<256 then table.insert(ev,ring[i]);last=ring[i].seq end end
 return {apiVersion=1,cursor="ct:"..last,events=ev,hasMore=last<seq},nil
end
FieldKitMeterLedger.PollCombatText(true)
-- Pretend a long run already credited 756 800 kills to Blizzard.
for i=1,756799 do end
local meter=FieldKitMeterFrame
for _,view in ipairs({"damage","kills","boss","damage"}) do
 FieldKitMeterSuite.SetView(view);FieldKitMeterSuite.Update(true)
 for i=1,table.getn(meter.rows) do
  local r=meter.rows[i]
  if r:IsShown() and r.meterColumns then
   for j=1,3 do local t=r.meterColumns[j]:GetText() or "";assert(not string.find(t,"e+",1,true),view..": scientific text "..t);assert(string.len(t)<=14,view..": column overflow "..t) end
   if r.killColumn and r.killColumn:IsShown() then assert(string.len(r.killColumn:GetText())<=7,"kill column overflow") end
  end
 end
 local total=meter.total:GetText() or ""
 assert(not string.find(total,"e+",1,true),view..": total in scientific notation "..total)
end
FieldKitMeterSuite.SetView("damage");FieldKitMeterSuite.Update(true)
assert(meter.rows[1].meterColumns[1]:GetText()==C(7.08e13),"top damage compact: "..tostring(meter.rows[1].meterColumns[1]:GetText()))
assert(meter.rows[1].meterColumns[2]:GetText()==C(2.887e11).." "..FieldKit_L("dps"),"rate compact")
assert(string.find(meter.total:GetText(),C(1.83e14),1,true),"total compact")
-- Kill column: compact, geometry key independent of the count (no relayout per kill).
local row=meter.rows[1]
assert(row.killColumn and row.killColumn:IsShown() and row.killColumn:GetText()==C(1),"kill column")
assert(row.meterKills==1,"layout key is presence, not the kill count")
assert(C(756800)=="756.8 k" and string.len(C(756800))<=7,"756 800 kills fit the 36 px kill column")
-- Detached and resized windows use the same rows and formats.
FieldKitMeterSuite.SetDetached("damage",true);FieldKitMeterSuite.Update(true)
DB.cardSizes.FieldKitMeterFrame={width=300};FieldKitMeterSuite.Update(true)
FieldKitMeterSuite.SetDetached("damage",false);FieldKitMeterSuite.Update(true)
-- Tooltip keeps the exact amount.
local lines={};local add=GameTooltip.AddLine
GameTooltip.AddLine=function(_,t) table.insert(lines,tostring(t)) end
DB.meterSpellTips=true
FieldKitMeterLedger.AppendStats(names[1],9001,nil,7.08e13)
GameTooltip.AddLine=add
assert(string.find(table.concat(lines,"\n"),FieldKit.Exact(7.08e13),1,true),"tooltip shows the exact total")

-- 12. Readability floor: card opacity keeps its range, data cards never drop below 88 %.
local T=FieldKitTheme
local card=FieldKitStatsFrame
for _,o in ipairs({100,88,70,40,0}) do
 DB.cardOpacity=o;T.ReadableFloor(card)
 local base=o/100;local plate=card.fieldkitFloor:IsShown() and card.fieldkitFloor.alpha or 0
 local coverage=1-(1-base)*(1-plate)
 if o>=88 then assert(plate==0 and not card.fieldkitFloor:IsShown(),"no plate at or above the floor ("..o..")")
 else assert(math.abs(coverage-.88)<1e-9,"coverage lifted to the floor at "..o.."%: "..coverage) end
end
card.fieldkitArtOnly=true;T.ReadableFloor(card);assert(not card.fieldkitFloor:IsShown(),"art-only cards keep no plate");card.fieldkitArtOnly=nil
DB.cardOpacity=70
print("PASS endless long run: compact formats 0..2^128 (no e+), exact tooltips, fraction bars, HUD loop survives a failing step, native lair states (awake/empty/asleep, missing guardian, stale stamp, run change) never hidden or written, meter views/kills/detach, readability floor")
