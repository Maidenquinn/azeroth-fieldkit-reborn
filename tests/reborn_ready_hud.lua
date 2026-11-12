fire(FieldKitFrame,"VARIABLES_LOADED")
local L,N,R,C,H,V=FieldKitLoadout,FieldKitNative,FieldKitReborn,FieldKitZoneThemes,FieldKitThemeHUD,FieldKitReferenceHUD
AZS_GetPhase=function() return AZS_RUN.ph end
AZS_ZONE={zone="zangarmarsh",class="hunter"}
AZS_RUN={ph="ready",t=0,rift=0,en=0,enm=300,kills=0,gold=0,chest=20}
AZS_SCHEDULE={{state="due",name="Hungarfen",at=240}}
AZS_GetUpcomingBosses=function() return {{name="Hungarfen",left=240}} end
AZS_SPELLS={{key="auto_shot",spell=75,rank=1},{key="aimed_shot",spell=19434,rank=1}}
GetSpellInfo=function(id) if id==75 then return "Tir automatique",nil,"Interface\\Icons\\Auto" end;return "Visée",nil,"Interface\\Icons\\Aimed" end
N.Watch();L.Update();assert(#L.spells==2 and L.spells[1].name=="Tir automatique","Starting spells lost during ready")
AZS_GetMeterContext=function() return {runId="ready1",localOwnerId="me"} end
AZS_GetMeterLoadout=function(q)
 assert(q.apiVersion==1 and q.runId=="ready1" and q.ownerId=="me")
 return {abilities={{learned=true,rank=3,slotId=1,sourceKey="ability:auto"}},sources={
  ["ability:auto"]={abilityKey="auto_shot",name="Native",spellIds={75},icon={status="known",path="Interface\\Icons\\Native"}}}}
end
L.scanAt=0;L.Update();assert(#L.spells==1 and L.spells[1].rankValue==3,"Structured native loadout ignored")
AZS_GetMeterLoadout=function() return nil,{code="NO_RUN"} end
L.scanAt=0;L.Update();assert(#L.spells==2,"Raw fresh packet fallback missing")
-- Stale data must not be resurrected by the structured API.
N.barriers.AZSSPELLS={AZS_SPELLS,AZS_SPELLS_UPDATED,N.generation.AZSSPELLS or 0}
L.scanAt=0;L.Update();assert(#L.spells==0)
N.Packet("AZSSPELLS");L.scanAt=0;L.Update();assert(#L.spells==2)
AZS_EVENT={key="hallows_end",n=0};AZS_EventCurrency=function() return "Bonbons","Interface\\Icons\\Candy",{1,.5,.1} end
for _,variant in ipairs({"minimal","complete","alternative"}) do
 FieldKitRebornDB.zoneThemeVariant=variant;C.Set("zoneThemes",true)
 assert(#R.sixSlots==6 and R.sixPlate:IsShown())
 for _,slot in ipairs(R.sixSlots) do assert(slot:IsShown() and #slot.tiles>0,"Six-slot atlas crop empty: "..variant) end
 assert(R.progressFrame:GetHeight()==30 and R.progressFrame.fieldkitSkin)
 for _,f in ipairs({R.progressFrame,R.hordeFrame}) do
  assert(f.fill:GetWidth()>0 and f.fill:GetHeight()==16 and f.fill:GetFrameLevel()>f:GetFrameLevel())
  for _,e in ipairs(f.fieldkitSkin.parts) do assert(e.texture.width>0 and e.texture.height>0 and e.texture.height<=30) end
 end
 assert(R.hordeFrame:IsShown() and R.hordeFrame.label:GetText()=="Horde  0 / 300")
 AZS_RUN.en=299;R.UpdateRunDetails();assert(R.hordeFrame.fill:GetValue()>99)
 AZS_RUN.en=0
 for i,f in ipairs(R.counterCells) do
  assert(f:IsShown() and f:GetHeight()==R.counterCells[1]:GetHeight() and f:GetWidth()==R.counterCells[1]:GetWidth())
  assert(f.label:GetText()==(i==3 and "20" or "0"))
 end
 C.Set("zoneThemes",false)
 for _,f in ipairs(R.counterCells) do assert(not f:IsShown()) end
 assert(not R.hordeFrame:IsShown() and not R.sixPlate:IsShown())
end
-- Reproduce an unresolved native frame at 0x0, rather than mock defaults 232x100.
local f=CreateFrame("Frame");f:SetWidth(0);f:SetHeight(0);FieldKitTheme.Surface(f,"card")
for _,p in ipairs(f.fieldkitSkin.parts) do assert(p.texture.width>0 and p.texture.height>0,"Intrinsic-size texture regression") end
AZS_GetLairs=function() return {{name="Lair",index=1,state="empty",left=40,x=100,y=200}} end
AZS_GetPlayerPosition=function() return {x=103,y=204} end
AZS_RUN.px=0;AZS_RUN.py=0;AZS_RUN.ph="ready";update(FieldKitFrame,.3)
assert(FieldKitLairFrame.rows[1].dist:GetText()=="","Ready placeholder produced a false distance")
AZS_RUN.ph="playing";update(FieldKitFrame,.3);assert(FieldKitLairFrame.rows[1].dist:GetText()=="5 yd","Lair distance ignored live pose API")
print("PASS ready starting spells, structured loadout/freshness, six visible sockets in all layouts, bounded thin meters, restored Horde and equal footer cells")
