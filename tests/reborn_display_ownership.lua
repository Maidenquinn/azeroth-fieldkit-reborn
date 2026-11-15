fire(FieldKitFrame,"VARIABLES_LOADED")
local d,C,T,R=FieldKitRebornDB,FieldKitZoneThemes,FieldKitNativeTools,FieldKitReborn
C.allowUnfinishedThemes=true
AZS_ZONE={zone="naxx",heroic=0};AZS_RUN={ph="paused",t=391,endless=2,rift=37,nb=-1,nbn="Next native boss"};AZS_SCHEDULE={}
local values={CombatDamage="1",PetMeleeDamage="0",PetSpellDamage="1"};local writes=0
GetCVar=function(key) return values[key] end
SetCVar=function(key,value) assert(values[key]~=nil);values[key]=value;writes=writes+1 end
local parts={banners=true};local handler;local registered=0
AZS_IsHudShown=function(key) return parts[key]~=false end
AZS_SetHudShown=function(key,value) parts[key]=value end
AZS_RegisterBannerHandler=function(fn) handler=fn;registered=registered+1 end
AZS_UnregisterBannerHandler=function(fn) assert(fn==handler);handler=nil end
for _,theme in ipairs({"elwynn","naxx"}) do
 for _,variant in ipairs({"off","minimal","complete","alternative"}) do
  C.Set("zoneThemes",false);d.zoneThemeMode=theme;d.zoneThemeVariant=variant=="off" and "complete" or variant
  if variant~="off" then C.Set("zoneThemes",true) end
  d.hideDamage=nil;d.combatTextWithNative=false;d.combatText=true
  update(FieldKitCombatText,.1)
  assert(values.CombatDamage=="0" and values.PetSpellDamage=="0")
  assert(d.nativeDamageBefore.CombatDamage=="1" and d.nativeDamageBefore.PetMeleeDamage=="0")
  local old=writes;update(FieldKitCombatText,.1);assert(writes==old,"Steady combat text rewrites native CVars")
  -- The same persisted baseline survives a simulated /reload of its owner.
  local saved=d.nativeDamageBefore;FieldKit.ApplyDamageNumbers();assert(d.nativeDamageBefore==saved)
  d.combatText=false;update(FieldKitCombatText,.1)
  assert(values.CombatDamage=="1" and values.PetMeleeDamage=="0" and values.PetSpellDamage=="1" and d.nativeDamageBefore==nil)
  d.combatText=true;update(FieldKitCombatText,.1)
  d.combatTextWithNative=true;update(FieldKitCombatText,.1)
  assert(values.CombatDamage=="1" and values.PetMeleeDamage=="1" and values.PetSpellDamage=="1")
  d.combatTextWithNative=false;update(FieldKitCombatText,.1)
  FieldKit.ReleaseCombatDamage();assert(values.CombatDamage=="1" and d.nativeDamageBefore==nil)
  d.combatText=false;values.PetMeleeDamage="0"
  d.nativeWarnings=true;d.keepNativeBanners=false;d.otherBannerWarnings=true
  T.Update();assert(handler and parts.banners==false,"Native notifications not replaced")
  T.warnings={};T.recent={}
  handler({id="wave:"..theme..variant,kind="wave",text="A wall of foes closes in!"})
  assert(table.getn(T.warnings)==1 and T.warnings[1].text=="A wall of foes closes in!")
  handler({id="wave:"..theme..variant,kind="wave",text="A wall of foes closes in!"});assert(table.getn(T.warnings)==1)
  d.keepNativeBanners=true;T.Update();assert(parts.banners==true,"Both notification displays not enabled")
  d.nativeWarnings=false;T.Update();assert(parts.banners==true and d.nativeBannerBefore==nil and handler==nil)
  local boss=T.NextBoss();assert(boss.endless and boss.progress==.37 and boss.name=="Next native boss" and boss.left==nil)
  d.bossTimeline=true
  AZS_RUN.rift=nil;boss=T.NextBoss();assert(boss.endless and boss.unavailable and boss.progress==nil)
  if variant=="off" then FieldKitBossTimeline.Update();assert(FieldKitBossTimelineFrame:IsShown() and FieldKitBossTimelineFrame.progressFill:GetValue()==0)
  else C.Refresh(true);assert(R.progressFrame:IsShown() and R.progressFrame.fill:GetValue()==0) end
  AZS_RUN.rift=0;assert(R.BossProgress()==0)
  AZS_RUN.rift=37
 end
end
-- Restore an initially hidden native notification setting, including after reload.
parts.banners=false;d.nativeWarnings=true;d.keepNativeBanners=false;T.Update()
assert(d.nativeBannerBefore==false)
d.keepNativeBanners=true;T.Update();assert(parts.banners==true)
d.nativeWarnings=false;T.Update();assert(parts.banners==false)
-- An unavailable native subscription must never suppress native announcements.
parts.banners=true;AZS_RegisterBannerHandler=function() return false end
d.nativeWarnings=true;T.Update();assert(parts.banners==true and not T.subscribed)
-- The Game page's two native-damage controls share the same live setting.
SlashCmdList.FieldKit("")
local editor
for _,tab in ipairs(FieldKitPanel.tabs) do if tab.page.combatEditor then editor=tab.page.combatEditor end end
local both,native
for _,widget in ipairs(editor.widgets) do
 if widget.label=="Also show native damage numbers" then both=widget end
 if widget.label=="Show target damage (game)" then native=widget end
end
assert(both and native)
d.combatText=true;d.combatTextWithNative=false;d.hideDamage=nil
FieldKit.ApplyDamageNumbers();editor.Refresh();both:SetChecked(true);click(both)
assert(d.combatTextWithNative and values.CombatDamage=="1" and FieldKitUI.nativeTextOptions[1].get())
native:SetChecked(false);click(native);assert(not d.combatTextWithNative and values.CombatDamage=="0")
FieldKit.ReleaseCombatDamage();d.combatText=false;d.hideDamage=nil;update(FieldKitCombatText,.1)
values.CombatDamage="0";update(FieldKitCombatText,.1)
assert(values.CombatDamage=="0","Disabled FieldKit combat text overrode a native setting change")
print("PASS display ownership: themes off/on x two families; auto native damage suppression, mixed-CVar baseline/reload/release, explicit both mode; notification takeover/filter/dedup/both/restore/API failure; visible endless native/zero/missing progress without a timer")
