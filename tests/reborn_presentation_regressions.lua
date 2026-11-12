fire(FieldKitFrame,"VARIABLES_LOADED")
local R,D,L=FieldKitReborn,FieldKitPartyDetails,FieldKitLoadout
AZS_ZONE={zone="zangarmarsh"};AZS_RUN={ph="playing",t=20}
local run="first";AZS_API_RunId=function() return run end
AZS_WorldUnits=function() return {} end
AZS_UNITS={}
assert(R.EnemyIcon("Hungarfen")=="Interface\\Icons\\Creature_SporeMushroom")
for _,name in ipairs({"Restless Skeleton","Pumpkin Soldier","Wailing Banshee","Hallowed Spirit"}) do
 assert(R.EnemyIcon(name)~="Interface\\Icons\\INV_Misc_QuestionMark",name)
end
local n=0
for zone,list in pairs(FieldKitRebornCreatures.zones) do
 AZS_ZONE.zone=zone
 for _,c in ipairs(list) do
  if c.kind=="boss" then
   n=n+1;local f={portrait={SetTexture=function(self,path) self.path=path end}}
   R.Portrait(f,c.name,"boss",99999)
   assert(f.portrait.path~="Interface\\Icons\\INV_Misc_QuestionMark",zone..":"..c.name)
  end
 end
end
assert(n==192)
AZS_ZONE.zone="zangarmarsh"
local l={index=1,name=""}
assert(R.LairName(l)=="Guardian · lair 1")
l.name="Native guardian";l.id=42;l.state="asleep";assert(R.LairName(l)==l.name)
l.name="";assert(R.LairName(l)=="Native guardian")
l.id=nil;l.state="empty";assert(R.LairName(l)=="Guardian · lair 1","Old guardian predicted as next spawn")
run="next";assert(R.LairName(l)=="Guardian · lair 1","Previous run identity leaked")
assert(L.Icon("Lifesteal")=="Interface\\Icons\\Spell_Shadow_LifeDrain02")
AZS_GetMeterContext=function() return {runId="healing"} end
AZS_GetMeterCapabilities=function() return {healingPerspectives={"performed"}} end
AZS_GetMeterSnapshot=function() return {status="ready",sources={
 ["line:"]={name="",kind="other",icon={status="ready",path="Interface\\Icons\\NativeHeal"}}},
 rows={{sourceKey="line:",displayAmount=235,displayRate={value=2}}},totals={displayAmount=235}} end
FieldKitRebornDB.meterHealDone=true
local healing,total,rate,known=FieldKitMeterLedger.Read("healing")
assert(known and total==235 and healing[1].name=="Unidentified source" and healing[1].icon=="Interface\\Icons\\NativeHeal")
D.Build();D.data={name="Tester",own=true,mode=1,damage=350,dps=35,rows={
 {name="Auto Shot",dmg=150,dps=15,icon="Interface\\Icons\\NativeAuto",hits=3,avg=50},
 {name="Aimed Shot",dmg=200,dps=20,hits=2,avg=100}}};D.Render()
for i=1,2 do
 local row=D.frame.rows[i]
 assert(row:IsShown() and row:GetFrameStrata()==D.frame:GetFrameStrata())
 assert(row:GetFrameLevel()>D.frame:GetFrameLevel(),"Rows behind modal material")
 assert(row.label:IsShown() and row.label:GetHeight()>0)
 assert(row.label.point[4]>=3+(row.fieldkitIconInset or 0),"Spell icon overlaps its name on first render")
 for _,v in ipairs(row.hitColumns) do assert(v:IsShown() and v:GetHeight()>0 and v:GetText()~="") end
end
for _,button in ipairs({D.pin,D.previous,D.next,D.close}) do
 assert(button:GetFrameLevel()>D.frame:GetFrameLevel() and button:GetFrameStrata()==D.frame:GetFrameStrata(),"Modal controls behind material")
end
for _,cap in ipairs(D.hitCaptions) do assert(cap.text==nil and cap:GetText()==cap.cap:GetText() and cap.cap:GetText()~="","Duplicate native caption") end
local native=D.frame.rows[2].fieldkitSpellIcon
assert(native and native:GetTexture()=="Interface\\Icons\\NativeAuto","Native source icon discarded")
D.SetSort("dmg");assert(D.frame.rows[1]:GetValue()==.75 and D.frame.rows[2]:GetValue()==1,"Ascending sort changed damage bar scale")
print("PASS all 192 boss icons across 48 zones, seasonal icons, lair identity freshness, modal layers and single captions, native meter icons")
