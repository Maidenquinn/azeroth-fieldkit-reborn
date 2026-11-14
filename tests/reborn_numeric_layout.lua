fire(FieldKitFrame,"VARIABLES_LOADED")
local C,V,T=FieldKitZoneThemes,FieldKitReferenceHUD,FieldKitThemeTarget
AZS_ZONE={zone='naxx',zname='Naxxramas',heroic=0}
AZS_RUN={ph='playing',t=30};AZS_UNITS={}
local native=CreateFrame('Button','AzerothSurvivorsUnitFrameTarget',UIParent)
UnitExists=function(unit) return unit=='target' or unit=='player' end
UnitName=function(unit) return unit=='target' and 'Tisseur d’âmes' or 'Tester' end
UnitHealth=function(unit) return unit=='target' and 350 or 100 end
UnitHealthMax=function(unit) return unit=='target' and 1000 or 100 end
UnitClassification=function() return 'elite' end
FieldKitRebornDB.zoneThemeMode='elwynn'
for _,variant in ipairs({'minimal','complete','alternative'}) do
 FieldKitRebornDB.zoneThemeVariant=variant;C.Set('zoneThemes',true);T.Update(variant)
 T.bar:SetFrameStrata('LOW');T.bar:SetAlpha(0);T.bar:Hide();T.Update(variant)
 assert(T.frame:IsShown() and T.bar:IsShown() and T.bar:GetValue()==350 and T.bar:GetAlpha()==1)
 assert(T.bar:GetFrameStrata()==T.frame:GetFrameStrata() and T.bar:GetFrameLevel()>T.frame:GetFrameLevel())
 assert(T.hp:GetHeight()==19 and T.hp:IsShown() and T.hp:GetText()~='')
 C.Set('zoneThemes',false)
end
AZS_GetPlayerPosition=function() return {x=103,y=204} end
AZS_GetLairs=function() return {{index=1,state='empty',left=28,x=0,y=0},
 {index=2,state='awake',id=2,name='Live',x=100,y=200},
 {index=3,state='asleep',id=3,name='No position',x=0,y=0}} end
FieldKitRebornDB.lairFrame=true;update(FieldKitFrame,.3)
local distances=0
for _,row in ipairs(FieldKitLairFrame.rows) do if row:IsShown() and row.dist:GetText()~='' then
 distances=distances+1;assert(row.dist:GetText()=='5 yd')
end end
assert(distances==1,'Absent or placeholder guardian produced a false distance')
FieldKitRebornDB.zoneThemeVariant='complete';FieldKitRebornDB.meterFrame=true
local read=FieldKitMeterLedger.Read
FieldKitMeterLedger.Read=function() return {{name='Visée',dmg=31685,dps=331,share=.56}},31685,331,true end
for _,mode in ipairs({1,2,3}) do
 FieldKitRebornDB.meterValues=mode;C.Set('zoneThemes',true);C.Refresh()
 local row=V.frames.Damage.rows[1]
 assert(row.amount:GetHeight()==15)
 if mode==3 then
  local point,_,_,_,y=row.rateText:GetPoint()
  assert(row.rateText:IsShown() and point=='TOPRIGHT' and y==-16 and row.rateText:GetHeight()==12,'Amount and DPS overlap vertically')
  assert(row.rateText:GetWidth()==row.amount:GetWidth(),'Rate spills into share column')
  assert(row.rateText:GetWidth()>=row.rateText:GetStringWidth(),'Rate text does not fit its column')
 else assert(not row.rateText:IsShown(),'Duplicate rate in single-line value mode') end
 C.Set('zoneThemes',false)
end
FieldKitMeterLedger.Read=read
print('PASS elite target health surface above chrome in three Elwynn layouts, absent/zero-pose guardian distances suppressed, live distance retained, separate amount/rate geometry in all value modes')
