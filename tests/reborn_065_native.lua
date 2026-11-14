-- Run after the actual installed generated content, Api.lua, Meter.lua,
-- CombatText.lua and Anchors.lua have been loaded into the mock VM.
local R=FieldKitReborn
local n=0
for _,zone in ipairs(AZS_GEN.zones) do if zone.world==4 then
 AZS_ZONE={zone=zone.key};assert(table.getn(zone.bosses)==5)
 for _,boss in ipairs(zone.bosses) do
  n=n+1;assert(R.CreatureIcon(boss.name),zone.key..":"..boss.name)
 end
end end
assert(n==60)
-- All generated jewelry remains data-driven, including new proc accessories.
local jewels=0
for _,j in ipairs(AZS_GEN.jewels) do
 AZS_GEAR={{slot="trinket1",name=j.name,icon=j.icon,text="+10% damage · A native proc",amount=1}}
 local item=R.Gear()[13];assert(item.name==j.name and item.icon==R.Icon(j.icon) and table.getn(item.bonuses)==1 and table.getn(item.nativeDetails)==2 and item.nativeDetails[2]=="A native proc")
 jewels=jewels+1
end
assert(jewels>=6)
-- Native world-position retention must end after its documented grace period.
local available=true
AZS_UnitWorldPosition=function(guid) if available then return 10,20,30,2,true,0,1,123 end end
NOW=10000;assert(AZS_ApiWorld.UnitPlace("0x0000000000000017").alive)
available=false;NOW=10002;assert(AZS_ApiWorld.UnitPlace("0x0000000000000017"))
NOW=10007;assert(AZS_ApiWorld.UnitPlace("0x0000000000000017")==nil,"Dead world location retained forever")
-- Inspect only the test VM's native Lua upvalues: unlike runtime addon code,
-- this proves the installed cleanup actually removes retained dead GUIDs.
local function Upvalue(fn,name)
 for i=1,40 do local key,value=debug.getupvalue(fn,i);if not key then return end;if key==name then return value end end
end
available=true
for i=1,2000 do NOW=11000+i;AZS_ApiWorld.UnitPlace("enemy:"..i) end
available=false;NOW=15000;AZS_ApiWorld.UnitPlace("sweep")
local retained=Upvalue(Upvalue(AZS_ApiWorld.UnitPlace,"Fresh"),"lastPlace")
assert(type(retained)=="table" and next(retained)==nil,"Native long-run positions never swept")
-- Projection follows current native coordinates, including changed floors.
AZS_ProjectWorldPoint=function(x,y,z) return x,y,z,1,true end
local state,x,y=AZS_ApiWorld.Project(15,25,30);assert(state=="onScreen" and x and y)
for _,zone in ipairs({"naxxramas","dalaran","scarlet_monastery"}) do
 AZS_ZONE={zone=zone}
 AZS_ProjectWorldPoint=function(x,y,z) return x+z,y+z,1,1,true end
 local a,x1,y1=AZS_ApiWorld.Project(15,25,1)
 local b,x2,y2=AZS_ApiWorld.Project(15,25,2)
 assert(a=="onScreen" and b=="onScreen" and x1~=x2 and y1~=y2,"Projection flattened the floor")
end
print("PASS installed 0.6.5: 60 Cataclysm boss names, all "..jewels.." jewelry definitions and native projection/expired world positions")
