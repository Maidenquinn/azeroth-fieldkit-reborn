fire(FieldKitFrame,"VARIABLES_LOADED")
AZS_ZONE={zone="hellfire",heroic=0};AZS_RUN={ph="playing",t=9999,rift=65,nb=6,nbn="Wrong legacy boss"}
AZS_SCHEDULE={{name="Slain",state="slain",at=240,index=1},{name="Nazan",state="due",at=480,index=2}}
AZS_GetUpcomingBosses=function() return {{name="Wrong clock",left=6}} end
local T,B,R=FieldKitNativeTools,FieldKitBossTimeline,FieldKitReborn
local boss=T.NextBoss();assert(boss.name=="Nazan" and boss.progress==.65 and boss.left==nil)
assert(T.BossValue(boss)=="65%")
FieldKitRebornDB.zoneThemes=false;FieldKitRebornDB.bossTimeline=true
B.Update();local f=FieldKitBossTimelineFrame
assert(f:IsShown() and f:GetHeight()==36 and f.progressFill:GetValue()==.65)
assert(f.titleText:GetText()=="Nazan · 65%" and not f.clockText:IsShown() and not f.elapsedText:IsShown() and not f.callout:IsShown())
for _,m in ipairs(f.marks) do assert(not m:IsShown()) end
AZS_RUN.t=20000;B.Update();assert(f.progressFill:GetValue()==.65,"Elapsed clock changed boss progression")
AZS_RUN.rift=0;B.Update();assert(f.progressFill:GetValue()==0)
AZS_RUN.rift=nil;B.Update();assert(f.titleText:GetText()=="Nazan · ?","Missing progression inferred from elapsed time")
FieldKitRebornDB.nextBossCard=true;FieldKitRebornDB.nextBossAlert=true;FieldKitRebornDB.bossWarningLead=10
AZS_RUN.rift=89;T.Reminders();assert(T.frames[3].lastRows[1].value=="89%" and table.getn(T.warnings)==0)
AZS_RUN.rift=90;T.Reminders();assert(table.getn(T.warnings)==1 and T.warnings[1].text=="Nazan · 90%")
T.Reminders();assert(table.getn(T.warnings)==1)
FieldKitZoneThemes.Set("zoneThemes",true);B.Update();assert(not f:IsShown() and R.progressFrame:IsShown(),"Duplicate themed calendar")
FieldKitZoneThemes.Set("zoneThemes",false);B.Update();assert(f:IsShown())
AZS_SCHEDULE[2].state="up";assert(T.NextBoss()==nil and R.BossProgress()==nil)
B.Update();assert(not f:IsShown())
print("PASS Reborn progression independent of elapsed/schedule times, past due identity, 0/missing, themed single gauge, classic gauge, progress warning")
