fire(FieldKitFrame,"VARIABLES_LOADED")
local T,C,d,N=FieldKitNativeTools,FieldKitZoneThemes,FieldKitRebornDB,FieldKitNative
C.allowUnfinishedThemes=true
AZS_L={["Hogger"]="Lardeur",["Mother Fang"]="Mère Croc"}
AZS_ZONE={zone="elwynn",heroic=0};AZS_RUN={ph="playing",t=999999,rift=9,nb=-1}
local first={index=1,name="Hogger",state="dead",at=9999999}
AZS_SCHEDULE={{index=3,name="Boss C",state="due",at=1},first,{index=2,name="Mother Fang",state="up",at=1},
 {index=4,name="Boss D",state="due"},{index=5,name="Boss E",state="due"}}
N.Watch();N.Packet("AZSBOSSES")
local rows,dead,known=T.BossListRows()
assert(known and dead==1 and #rows==5 and rows[1].index==1 and rows[3].fraction==.09)
assert(rows[2].value=="In combat" and rows[3].value=="Next · 9%" and rows[4].value=="Upcoming")
assert(first.state=="dead" and AZS_SCHEDULE[1].index==3,"Native schedule mutated or reordered")
for _,lang in ipairs({"en","fr"}) do
 FieldKit_SetLanguage(lang)
 for _,theme in ipairs({"elwynn","naxx"}) do for _,variant in ipairs({"off","minimal","complete","alternative"}) do
  C.Set("zoneThemes",false);d.zoneThemeMode=theme;d.zoneThemeVariant=variant=="off" and "complete" or variant
  if variant~="off" then C.Set("zoneThemes",true) end
  d.bossListCard=true;T.Update()
  local f=FieldKitBossListFrame
  assert(f:IsShown() and f.total:GetText()=="1 / 5" and #f.lastRows==5)
  assert(f.rows[1].bossListEntry.label=="1. Lardeur")
  assert(f.rows[1].bossListEntry.value==FieldKit_L("Defeated"))
  assert(f.rows[2].bossListEntry.value==FieldKit_L("In combat"))
  assert(f.rows[3].bossListEntry.value==FieldKit_L("Next").." · 9%")
  assert(FieldKitTheme.Style(f)==(variant=="off" and 4 or 3),"Boss list ignores the active card material")
  assert(f.fieldkitFooterHeight==0 and not f.note:IsShown())
  assert(FieldKitCardLayout.ValidName(f:GetName()) and f:GetScript("OnDragStart") and f:GetScript("OnDragStop"))
  for i=1,5 do assert(f.rows[i].label:GetStringWidth()<=f.rows[i].label:GetWidth()) end
  local count=#objects;for i=1,15 do T.Update() end;assert(#objects==count,"Boss list reallocates frames")
  AZS_RUN.endless=1;for _,b in ipairs(AZS_SCHEDULE) do b.state="dead" end
  T.Update();assert(f:IsShown() and f.total:GetText()=="5 / 5" and f.note:IsShown())
  assert(f.note:GetText()==FieldKit_L("Endless: the game does not provide the upcoming boss sequence."))
  for _,r in ipairs(f.lastRows) do assert(r.value==FieldKit_L("Defeated") and r.fraction==1) end
  click(FieldKitBossListFrameCollapse);assert(f.mashCollapsed and not f.note:IsShown())
  click(FieldKitBossListFrameCollapse);assert(not f.mashCollapsed and f.note:IsShown())
  AZS_RUN.endless=nil;AZS_SCHEDULE[1].state="due";AZS_SCHEDULE[3].state="up";AZS_SCHEDULE[4].state="due";AZS_SCHEDULE[5].state="due"
  d.bossListCard=false;T.Update();assert(not f:IsShown())
 end end
end
d.cardSizes.FieldKitBossListFrame={width=380,height=260};d.bossListCard=true;T.Update()
local movable=FieldKitBossListFrame
assert(movable:GetWidth()==380 and movable:GetHeight()>=260,"Boss card size preferences ignored")
d.windowsLocked=false;this=movable;movable.scripts.OnDragStart()
assert(movable.azsMoving,"Boss card drag is not wired")
movable:SetPoint("TOPLEFT",UIParent,"TOPLEFT",360,-60);this=movable;movable.scripts.OnDragStop()
assert(not movable.azsMoving and d.zoneThemePositions[C.currentLayout].FieldKitBossListFrame,"Theme card position was not saved")
FieldKitProfiles.Save(1);d.bossListCard=false;FieldKitProfiles.Load(1);assert(d.bossListCard,"Boss list preference escaped the HUD profile")
-- A late fresh schedule must never inherit another zone's roster.
N.Watch();AZS_ZONE={zone="naxx"};N.Watch()
assert(not N.Fresh("AZSBOSSES"));d.bossListCard=true;T.Update()
assert(FieldKitBossListFrame.lastRows[1].label==FieldKit_L("Boss list not provided"))
AZS_SCHEDULE={};for i=1,12 do AZS_SCHEDULE[i]={index=i,name="Native boss "..i,state="due"} end
N.Packet("AZSBOSSES");T.Update();local f=FieldKitBossListFrame
assert(f.bossListCount==12 and #f.lastRows==8)
arg1=-1;this=f;f.scripts.OnMouseWheel();assert(f.bossListOffset==1 and f.lastRows[1].index==2)
AZS_RUN.ph="ready";T.Update();assert(f:IsShown(),"Roster hidden before combat starts")
AZS_RUN.ph="choosing";FieldKitScreenLayers.ApplyChoice();assert(f:IsShown() and not f:IsMouseEnabled())
AZS_RUN.ph="paused";FieldKitScreenLayers.ClearChoice();T.Update()
AZS_RUN.ph="dead";T.Update();assert(not f:IsShown())
print("PASS campaign boss card: native index/state/charge and no schedule mutation; FR/EN x two theme families/off/variants; opt-out, frame reuse, endless completed roster, missing/stale data, pagination, ready/choice/end phases")

-- Reference material and measured content bounds, including opacity and theme release.
AZS_RUN.ph="playing";d.bossListCard=true;d.cardSizes.FieldKitBossListFrame=nil
AZS_SCHEDULE={{index=1,name="Hogger",state="due"},{index=2,name="Mother Fang",state="up"}}
N.Watch();N.Packet("AZSBOSSES")
for _,zone in ipairs({"elwynn","naxx"}) do
 d.zoneThemeMode=zone;d.zoneThemeVariant="complete";C.Set("zoneThemes",true);T.Update()
 local f=FieldKitBossListFrame;local r=FieldKitReferenceHUD
 assert(f.bossReference and f.fieldkitArtOnly and #f.bossRim==8)
 assert(f:GetWidth()==400 and f:GetScale()==r.canvas:GetScale()*C.ElementScale(f:GetName()))
 local _,_,_,tx,ty=f.title:GetPoint();local _,_,_,rx,ry=f.rows[1]:GetPoint()
 assert(tx==65 and -ry>=-ty+f.title:GetHeight()+8,"Roster header overlaps the first row")
 assert(rx>=20 and rx+f.rows[1]:GetWidth()<=f:GetWidth()-20)
 assert(f.rows[1].icon:GetWidth()==20 and f.rows[1].label:GetHeight()==24)
 for _,opacity in ipairs({0,37,100}) do
  d.cardOpacity=opacity;r.ApplyOpacity();assert(f.cleanBody:GetAlpha()==opacity/100)
  for _,edge in ipairs(f.bossRim) do assert(edge:GetAlpha()==1) end
  assert(f.rows[1].icon:GetAlpha()==1 and f:GetAlpha()==1)
 end
 click(FieldKitBossListFrameCollapse);assert(f:GetHeight()>=46 and not f.rows[1]:IsShown())
 click(FieldKitBossListFrameCollapse);assert(f.rows[1]:IsShown())
 C.Set("zoneThemes",false);T.Update()
 assert(not f.bossReference and not f.fieldkitArtOnly and not f.cleanBody:IsShown())
 for _,edge in ipairs(f.bossRim) do assert(not edge:IsShown()) end
 assert(f.rows[1].icon:GetWidth()==14)
end
print("PASS campaign roster reference rim/body/opacity/viewport scale, padded header/rows, collapse and native material restoration")
