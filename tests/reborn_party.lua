fire(FieldKitFrame,"VARIABLES_LOADED")
function AZS_GetMeterContext() return {runId="sorted-party"} end
function AZS_GetMeterSnapshot(q)
 return {status="ready",rows={{ownerId="hero:Alice",displayAmount=100},{ownerId="hero:Bob",displayAmount=500}},
  actors={["hero:Alice"]={name="Alice"},["hero:Bob"]={name="Bob"}},totals={displayAmount=600}}
end
local rows,total,rate,known=FieldKitMeterLedger.Read("party")
assert(known and total==600 and #rows==2)
assert(rows[1].name=="Bob" and rows[1].ownerId=="hero:Bob")
assert(rows[2].name=="Alice" and rows[2].ownerId=="hero:Alice")
print("PASS Reborn party drill-down retains player identity after ranking")
