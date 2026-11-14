fire(FieldKitFrame,"VARIABLES_LOADED")
SlashCmdList.FieldKit("")
FieldKit_SetLanguage("fr")
local d,L,C,R=FieldKitRebornDB,FieldKitLoadout,FieldKitZoneThemes,FieldKitReferenceHUD
AZS_LOCALE="frFR"
AZS_L={["Aimed Shot"]="Visée",["Rapid Fire"]="Tir rapide",["Divine Shield"]="Bouclier divin",["Lifesteal"]="Vol de vie",["Earthstrike"]="Frappe-terre"}
AZS_ZONE={zone="naxx",zname="Naxxramas",heroic=0};AZS_RUN={ph="playing",t=100}
AZS_SPELLS={{key="aimed_shot",name="Aimed Shot",spell=19434,rank=5}}
AZS_GEN={spells={HUNTER={{key="aimed_shot",name="Aimed Shot",icon="AimedIcon"}}}}
UnitClass=function() return "Hunter","HUNTER" end
GetSpellInfo=function(id) if id==19434 then return "Aimed Shot",nil,"AimedIcon" elseif id==3045 then return "Rapid Fire",nil,"RapidIcon" else return "Surge of Strength",nil,"StrengthIcon" end end
-- The server name list covers procs absent from AZS_L.
AZS_SpellName=function(id) if id==999 then return "Afflux de force" end;return GetSpellInfo(id) end
UnitAura=function(_,i) if i==1 then return "Surge of Strength",nil,"StrengthIcon",3,nil,20,GetTime()+20,nil,nil,nil,999 elseif i==2 then return "Rapid Fire",nil,"RapidIcon",1,nil,10,GetTime()+10,nil,nil,nil,3045 end end
AZS_BUFFS={};AZS_GEAR={{slot="trinket",name="Earthstrike",text="+20% de dégâts",icon="GearIcon"}}
HasAction=function() return false end
local snapshot=true
AZS_GetMeterContext=function() return {runId="fr-matrix",localOwnerId="p1"} end
AZS_GetMeterCapabilities=function() return {features={nativeRecentWindows=true},healingPerspectives={"performed"}} end
AZS_GetMeterSnapshot=function(q)
 if not snapshot then return nil end
 if q.groupBy=="owner" then return {status="ready",actors={p1={name="Aimed Shot"}},rows={{ownerId="p1",displayAmount=100,displayRate={value=10}}},totals={displayAmount=100,displayRate={value=10}}} end
 local heal=q.metric=="healing"
 return {status="ready",sources={s={name=heal and "Lifesteal" or "Aimed Shot",spellIds=heal and {} or {19434},abilityKey="aimed_shot"}},
 rows={{sourceKey="s",displayAmount=100,windowAmount=50,displayRate={value=10}}},totals={displayAmount=100,windowAmount=50,recentRate={status="ready",value=10},displayRate={status="ready",value=10}}}
end
AZS_GetMeter=function() return {{name="Aimed Shot",dmg=100,dps=10,share=1}},100,10 end
AZS_GetHealing=function() return {{name="Lifesteal",dmg=100,dps=10,share=1}},100,10 end
AZS_GetBossMeter=AZS_GetMeter
d.meterHealDone=true;d.effectBuffs=true;d.effectsFrame=true;d.effectTotems=false;d.effectSummons=false;d.effectTimers=false
FieldKitNative.Watch();FieldKitNative.Packet("AZSSPELLS");FieldKitNative.Packet("AZSGEAR")
for _,theme in ipairs({"elwynn","naxx"}) do
 for _,variant in ipairs({"off","minimal","complete","alternative"}) do
  C.Set("zoneThemes",false);d.zoneThemeMode=theme;d.zoneThemeVariant=variant=="off" and "complete" or variant
  if variant~="off" then C.Set("zoneThemes",true) end
  L.scanAt=0;L.Scan()
  assert(L.spells[1].name=="Visée" and L.items[13].name=="Frappe-terre")
  local buffs=FieldKitReborn.PlayerBuffs();assert(buffs[1].name=="Afflux de force" and buffs[2].name=="Tir rapide")
  FieldKitNativeTools.Update();local effects=FieldKitNativeTools.frames[1]
  assert(effects.rows[1].label:GetText()=="Afflux de force")
  for _,recent in ipairs({false,true}) do
   d.meterRecent=recent;d.meterWindowSeconds=5
   for _,view in ipairs({"damage","healing","boss","kills"}) do
    if view~="kills" then
     local lines=FieldKitMeterLedger.Read(view);assert(lines[1].name==(view=="healing" and "Lifesteal" or "Aimed Shot"))
     assert(lines[1].displayName==(view=="healing" and "Vol de vie" or "Visée"))
     FieldKitMeterSuite.SetView(view);FieldKitMeterSuite.Update(true);C.Refresh(true)
     if variant~="off" and R.layout.rects.Effects then
      local label=R.frames.Effects.rows[1].label
      assert((label.referenceFullText or label:GetText())=="Afflux de force","Themed proc label untranslated")
     end
     if variant=="off" or not R.layout.rects.Damage then
      if variant~="off" then C.Open("Damage") end
      assert(FieldKitMeterFrame.rows[1].label:GetText()==lines[1].displayName)
     else assert(R.frames.Damage.rows[1].label:GetText()==lines[1].displayName)
      if view=="healing" and R.frames.Damage.rateLabel:IsShown() then assert(not string.find(R.frames.Damage.rateLabel:GetText(),"HPS",1,true),"Themed HPS label remains English") end
     end
     FieldKitMeterSuite.SetDetached(view,true)
     assert(getglobal("FieldKitMeterExtra_"..view).rows[1].label:GetText()==lines[1].displayName)
     FieldKitMeterSuite.SetDetached(view,false)
     local D=FieldKitPartyDetails;D.Build();D.data=D.Data(UnitName("player"),view=="healing" and 2 or 1);D.Render()
     assert(D.frame.rows[1].label:GetText()==lines[1].displayName)
     FieldKitMeterLedger.ShowTip({fieldkitSpell=lines[1].name,fieldkitLine=lines[1]})
     assert(GameTooltip:GetText()==lines[1].displayName)
    end
   end
  end
  d.meterRecent=false
  local party=FieldKitMeterLedger.Read("party");assert(party[1].name=="Aimed Shot" and party[1].displayName==nil,"Player name translated as a spell")
  -- Same adapter when a structured snapshot is unavailable.
  snapshot=false;local lines=FieldKitMeterLedger.Read("damage");assert(lines[1].displayName=="Visée");snapshot=true
  d.loadoutTab=2;L.Render(FieldKitGearFrame);C.Refresh(true)
  assert(FieldKitGearFrame.spellRows[1].label:GetText()=="Visée")
  if variant~="off" and R.layout.rects.Accessories then assert(R.frames.Accessories.rows[1].label:GetText()=="Visée") end
 end
end
-- Language switching rescans cached rank labels immediately; names keep game language.
FieldKit_SetLanguage("en");assert(FieldKit_L("Naxxramas")=="Naxxramas");assert(L.spells[1].rank=="Rank 5")
FieldKit_SetLanguage("fr");assert(L.spells[1].rank=="Rang 5")
assert(L.CompactBonus("Increases your haste by 20%.")=="+20% hâte")
assert(FieldKitReborn.DisplayName("Surge of Strength")=="Afflux de force")
local text=FieldKitGroupHistory.Line({spell="Aimed Shot",kind="cast"})
assert(text=="Visée")
local nativeInfo=GetSpellInfo
AZS_SPELL_NAMES={[13809]="Piège de givre"}
GetSpellInfo=function(id) if id==13809 then return "Freezing Trap" end;return nativeInfo(id) end
assert(FieldKitReborn.DisplayName("Freezing Trap")=="Piège de givre","DBC alias leaked English")
assert(FieldKitReborn.DisplayName("My pet: Freezing Trap")=="My pet: Piège de givre")
AZS_SPELL_NAMES[13809]="Piège de givre actualisé";NOW=NOW+2.1
assert(FieldKitReborn.DisplayName("Freezing Trap")=="Piège de givre actualisé","Late names packet remained cached")
GetSpellInfo=nativeInfo;AZS_SPELL_NAMES=nil
assert(FieldKitReborn.DisplayName("My pet: Aimed Shot",19434)=="My pet: Visée")
local nativeNames=AZS_SpellName
AZS_SpellName=function() return nil end;assert(FieldKitReborn.DisplayName("Rapid Fire",3045)=="Tir rapide")
AZS_SpellName=function() error("Optional API unavailable") end;assert(FieldKitReborn.DisplayName("Rapid Fire",3045)=="Tir rapide")
AZS_SpellName=nativeNames
AZS_RUNSTATS={};assert(FieldKitReborn.DisplayName("Custom untouched name")=="Custom untouched name")
print("PASS FR locale matrix: two themes x off/three variants; raw meter identities, damage/healing/boss/recent/fallback/detached/modal/tooltips, player-name preservation, loadout, gear, procs and live rank refresh")
