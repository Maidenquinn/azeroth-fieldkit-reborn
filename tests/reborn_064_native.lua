-- Executed against the actual installed 0.6.4 Api.lua and Meter.lua, in a mock VM.
local caps=AZS_GetMeterCapabilities()
if not caps.features.nativeRecentWindows then return end
local L,W,d=FieldKitMeterLedger,FieldKitMeterWindow,FieldKitRebornDB
d.zoneThemes=false;d.meterViewKey="damage";d.meterHealDone=true
AZS_ZONE={zone="hellfire",class="hunter",heroic=0,run="r00000641"}
AZS_RUN={ph="playing",t=0}
ROUTE("AZSZONE","")
local id=AZS_API_RunId();assert(id=="azs:r00000641")
local function tick(t)
 NOW=1000+t;AZS_RUN.t=t;ROUTE("AZSRUN","t="..t)
 ROUTE("AZSMETER","Fire,"..(70*t)..",70,0.7,0,0;Frost,"..(30*t)..",30,0.3,0,0")
 ROUTE("AZSHEAL","Heal,"..(10*t)..",10,1,0,0")
end
for t=0,135 do tick(t) end
for seconds=5,120 do
 d.meterRecent=true;d.meterWindowSeconds=seconds
 for _,view in ipairs({"damage","healing"}) do
  local rows,total,rate,known=L.Read(view)
  local scale=view=="healing" and 10 or 100
  assert(known and math.abs(total-seconds*scale)<.001,view.." window "..seconds.." total "..tostring(total))
  assert(math.abs(rate-scale)<.001,view.." rate "..tostring(rate))
  assert(rows[1].windowSeconds==seconds)
  local sum,shares=0,0
  for _,row in ipairs(rows) do sum=sum+row.dmg;shares=shares+(row.share or 0) end
  assert(math.abs(sum-total)<.001 and math.abs(shares-1)<.001)
 end
end
assert(L.Reset());tick(137)
local rows,total,rate,known=L.Read("damage")
assert(known and total==200 and rate==100,"Recent window ignored checkpoint floor")
-- Retained run id across a new world/API lifetime; meter history is not retained.
local nativeEvents
for _,o in ipairs(objects) do if o.events.PLAYER_LEAVING_WORLD and o.events.PLAYER_ENTERING_WORLD and not o.name then nativeEvents=o end end
assert(nativeEvents)
nativeEvents:GetScript("OnEvent")(nativeEvents,"PLAYER_LEAVING_WORLD")
AZS_RUN.ph=nil;L.Boundary();AZS_RUN.ph="playing"
nativeEvents:GetScript("OnEvent")(nativeEvents,"PLAYER_ENTERING_WORLD")
AZS_ZONE.run="r00000641";ROUTE("AZSZONE","");assert(AZS_API_RunId()==id)
d.meterWindowSeconds=5;tick(137)
rows,total,rate,known=L.Read("damage")
assert(not known and total==nil and W.states.damage.reason=="history_not_retained","Reload history was fabricated")
for t=138,143 do tick(t) end
rows,total,rate,known=L.Read("damage")
assert(known and total==500 and rate==100,"Recent window failed to recover after retaining sufficient history")
print("PASS installed 0.6.4: all 116 window lengths for damage/healing, rates/shares, checkpoints, stable run id, missing reload history and recovery")
