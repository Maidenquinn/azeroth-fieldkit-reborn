-- Modern next-encounter contract, distinct clocks, explicit unknown/none and caps.
fire(FieldKitFrame,"VARIABLES_LOADED")
local R,T,d,N=FieldKitReborn,FieldKitNativeTools,FieldKitRebornDB,FieldKitNative
AZS_ZONE={zone="naxx",run="modern"}
AZS_RUN={ph="playing",t=1000,endless=1,nbs="unknown",nbm="time",nbc=6,nb=72,rift=88,nbn="Stale name"}
AZS_SCHEDULE={{index=1,name="Stale campaign",state="due"}}
AZS_UNITS={};N.Watch();N.Packet("AZSBOSSES")
local clock=1002.25;AZS_GetRunTime=function() return clock end
local b=T.NextBoss()
assert(b.name==FieldKit_L("Next boss").." #6" and b.left==69.75 and b.progress==nil and b.unknown)
assert(R.BossProgress()==nil and T.BossValue(b)=="1:09","Timer became a charge percentage")
local key=b.key
AZS_RUN.ph="paused";clock=99999;assert(T.NextBoss().left==72)
AZS_RUN.ph="choosing";assert(T.NextBoss().left==72)
AZS_RUN.ph="playing";clock=1100;assert(T.NextBoss().left==0)
AZS_RUN.nb=nil;assert(T.NextBoss().unavailable and T.NextBoss().progress==nil)
AZS_RUN.nb=-1;assert(T.NextBoss().left==nil)
AZS_RUN.nb=72;clock=1000
-- A replaced sync table and a fresh module state preserve the server ordinal.
AZS_RUN={ph="paused",t=1000,endless=1,nbs="unknown",nbm="time",nbc=6,nb=72}
assert(T.NextBoss().key==key)
T.endlessCycle=999;assert(T.NextBoss().key==key,"Local guessed cycle used")
local rows,dead,known,campaign=T.BossListRows()
assert(known and campaign==1 and rows[1].unknown and rows[1].index==6 and rows[1].value=="1:12")
d.bossListCard=true;T.BossList();assert(T.frames[4].total:GetText()=="0 / 1")
AZS_RUN.nbs="up";AZS_RUN.nb=-1
AZS_UNITS={{kind="boss",id=123,name="Visible boss",hp=90,hpm=100}}
b=T.NextBoss();assert(b.active and b.name=="Visible boss" and b.left==nil and T.BossValue(b)==FieldKit_L("In combat"))
AZS_RUN.nbs="none";assert(T.NextBoss()==nil and R.BossProgress()==nil)
-- A current campaign charge takes only the native percent, including genuine 0.
AZS_RUN={ph="playing",t=20,nbs="known",nbm="rift",nbc=1,nb=30,rift=0}
b=T.NextBoss();assert(b.name=="Stale campaign" and b.progress==0 and b.left==nil)
AZS_RUN.rift=46;b=T.NextBoss();assert(T.BossValue(b)=="46%")
AZS_RUN.rift=nil;assert(T.NextBoss().unavailable)
-- Timer warnings are keyed by stable encounter id and require playing.
AZS_RUN={ph="paused",t=1000,endless=1,nbs="unknown",nbm="time",nbc=7,nb=8}
d.nextBossAlert=true;d.nextBossCard=true;d.bossWarningLead=10;T.warnings={};T.lastBoss={};T.recent={}
T.Reminders();assert(#T.warnings==0)
AZS_RUN.ph="playing";T.Reminders();T.Reminders();assert(#T.warnings==1)
AZS_RUN.nbs="up";T.Reminders();assert(#T.warnings==1)
-- Both families and off show the same timer; no filled time-as-charge bar.
AZS_RUN={ph="paused",t=1000,endless=1,nbs="unknown",nbm="time",nbc=8,nb=72,rift=99,en=10,enm=120}
d.bossTimeline=true
for _,lang in ipairs({"en","fr","zh"}) do
 FieldKit_SetLanguage(lang)
 for _,family in ipairs({"elwynn","naxx"}) do for _,variant in ipairs({"complete","minimal","alternative"}) do
  d.zoneThemeMode=family;d.zoneThemeVariant=variant;FieldKitZoneThemes.Set("zoneThemes",true)
  R.ProgressBar();assert(R.progressFrame:IsShown() and R.progressFrame.fill:GetValue()==0)
  assert(string.find(R.progressFrame.label:GetText(),"1:12",1,true))
 end end
 FieldKitZoneThemes.Set("zoneThemes",false);FieldKitBossTimeline.Update()
 assert(FieldKitBossTimelineFrame:IsShown() and FieldKitBossTimelineFrame.progressFill:GetValue()==0)
 assert(string.find(FieldKitBossTimelineFrame.titleText:GetText(),"1:12",1,true))
end
FieldKit_SetLanguage("en")
local S=FieldKitRebornStats
AZS_STATS={};local caps={cdr=75,haste=80,crit=100,red=90,echo=0}
AZS_GetStatCaps=function() return caps end
local lines=S.CapLines();assert(#lines==5 and lines[1]=="Maximum · Cooldown: 75%" and lines[5]=="Maximum · Echo: 0%")
assert(#S.CapLines("haste")==2 and #S.CapLines("crit")==1 and #S.CapLines("hp")==0)
caps={cdr=67.5};assert(S.CapLines("haste")[1]=="Maximum · Cooldown: 67.5%","Cap reference cached or units incorrect")
caps={crit=0/0,red=-1};assert(#S.CapLines()==0)
AZS_GetStatCaps=function() error("not ready") end;assert(#S.CapLines()==0)
AZS_GetStatCaps=nil;assert(#S.CapLines()==0)
print("PASS 0.6.9 encounter states/ordinals, unknown identity, timer vs charge, pause/reload, alerts, both theme families x variants x languages + off, fresh cap units/unavailability")
