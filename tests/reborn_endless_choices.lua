fire(FieldKitFrame,"VARIABLES_LOADED")
local R,C,H,N=FieldKitReborn,FieldKitZoneThemes,FieldKitThemeHUD,FieldKitNativeHUD
C.allowUnfinishedThemes=true -- Test the gated family without enabling it for players.
AZS_ZONE={zone="aq",zname="Gates of Ahn'Qiraj",heroic=0}
AZS_RUN={ph="playing",t=457,endless=1,rift=37,bs=8}
AZS_SCHEDULE={};AZS_UNITS={}
local guardian={id=42,name="Guardian",hp=100,hpm=200,awake=true}
AZS_GetGuardians=function() return {guardian,{id=43,name="",hp=0,hpm=0,awake=true},{id=44,name="Missing HP",awake=true},guardian} end
AZS_GetBosses=function() return {{id=45,name="Dead",hp=0,hpm=100},{id=46,name="",hp=50,hpm=100}} end
local units=R.BossUnits();assert(table.getn(units)==1 and units[1].id==42,"Invalid or duplicate guardian entered display pool")
assert(R.BossProgress()==.37)
local nextBoss=FieldKitNativeTools.NextBoss();assert(nextBoss and nextBoss.progress==.37 and nextBoss.left==nil)
assert(nextBoss.name==FieldKit_L("Next boss"),"Unknown endless boss identity invented")
AZS_RUN.nbn="Native endless boss";assert(FieldKitNativeTools.NextBoss().name==AZS_RUN.nbn)
AZS_RUN.rift=0;assert(R.BossProgress()==0)
AZS_RUN.rift=nil;assert(R.BossProgress()==nil and FieldKitNativeTools.NextBoss()==nil,"Missing percentage inferred from a timer")
AZS_RUN.rift=-1;assert(R.BossProgress()==nil,"Absent charge sentinel became zero progress")
AZS_RUN.rift=37
AZS_SCHEDULE={{name="Stale campaign boss",state="due",index=1}}
assert(FieldKitNativeTools.NextBoss().name==AZS_RUN.nbn,"Endless reused a stale campaign encounter")
AZS_SCHEDULE={}
local nativeNames={"AZSHudFrame","AZSTrackerFrame","AZSMeterFrame","AZSGearRow","AzerothSurvivorsSurvivorsResources","AzerothSurvivorsSurvivorsBossBar","AZSRiftBar"}
for _,name in ipairs(nativeNames) do local f=CreateFrame("Frame",name,UIParent);f:Show();f:SetAlpha(.8) end
for _,family in ipairs({"elwynn","naxx"}) do
 FieldKitRebornDB.zoneThemeMode=family
for _,variant in ipairs({"minimal","complete","alternative"}) do
 for _,themed in ipairs({false,true}) do
  AZS_RUN.ph="playing";FieldKitScreenLayers.ClearChoice()
  FieldKitRebornDB.zoneThemeVariant=variant;C.Set("zoneThemes",themed)
  FieldKitMeterFrame:Show();FieldKitGearFrame:Show();FieldKitStatsFrame:Show()
  local owner=themed and H.healthRoot or FieldKitMeterFrame
  local child=CreateFrame("Button",nil,owner);child:EnableMouse(true);child:SetFrameStrata("DIALOG")
  owner.GetChildren=function() return child end
  local alpha=owner:GetAlpha();local strata=owner:GetFrameStrata()
  AZS_RUN.ph="choosing"
  for i=1,3 do update(FieldKitFrame,.3);C.Refresh();N.Update();FieldKitScreenLayers.ApplyChoice() end
  assert(owner:IsShown() and owner:GetAlpha()>0,"HUD vanished during reward choice")
  assert(not child:IsMouseEnabled() and child:GetFrameStrata()=="MEDIUM","HUD child intercepted reward cards")
  H.Save(child)
  assert(H.saved[child].mouse==true and H.saved[child].strata=="DIALOG","Theme captured temporary choice presentation")
  for _,name in ipairs(nativeNames) do assert(getglobal(name):GetAlpha()==0,"Native duplicate under choice: "..name) end
  if themed then
   assert(H.healthRoot:IsShown() and H.healthRoot:GetAlpha()>0,"Theme health hidden during choice")
   assert(R.progressFrame:IsShown() and R.progressFrame:GetAlpha()>0,"Theme endless gauge hidden during choice: "..family.."/"..variant.." shown="..tostring(R.progressFrame:IsShown()).." alpha="..tostring(R.progressFrame:GetAlpha()))
  else
   assert(FieldKitMoneyFrame:IsShown() and FieldKitMoneyFrame:GetAlpha()>0,"Money hidden during choice")
   assert(FieldKitBossTimelineFrame:IsShown() and FieldKitBossTimelineFrame:GetAlpha()>0,"Endless gauge hidden during choice")
   assert(N.clock:IsShown() and N.clock:GetAlpha()>0,"Elapsed clock hidden during choice")
  end
  AZS_RUN.ph="playing";FieldKitScreenLayers.ClearChoice()
  assert(child:IsMouseEnabled() and child:GetFrameStrata()=="DIALOG","Input/strata did not restore")
  assert(owner:GetAlpha()==alpha and owner:GetFrameStrata()==strata)
  child:Hide()
 end
end
end
C.Set("zoneThemes",false)
AZS_SPELLS={{key="aimed_shot",spell=19434,rank=39}}
AZS_SPELLTIPS={aimed_shot="Deals 900 damage every 0.5 sec.\nAméliorations : +40% de dégâts, -16% de recharge\nVos bonus : +8% de dégâts"}
FieldKitNative.Packet("AZSSPELLS");FieldKitNative.Packet("AZSSPELLTIP")
HasAction=function() return false end
FieldKitLoadout.scanAt=0;FieldKitLoadout.Scan()
local e=FieldKitLoadout.spells[1]
assert(e and e.upgrades[1]=="+40% de dégâts" and e.bonuses[1]=="+8% de dégâts")
local b,u=FieldKitLoadout.SpellBonuses("Deals 120 damage. Your damage bonus: +56%.")
assert(b[1]=="+56% dmg" and table.getn(u)==0)
b,u=FieldKitLoadout.SpellBonuses("Increases damage by 20% and hits 2 targets.")
assert(table.getn(b)==0 and table.getn(u)==0,"Base spell description mislabelled as a learned bonus")
print("PASS endless real 0/missing/37% and identity, invalid/duplicate guardian filtering, visible noninteractive choice HUD in both theme families x three variants + off, native duplicates suppressed, exact layer/input restoration and native spell bonus extraction")
