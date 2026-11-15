local P=FieldKitProfiles;local factory=P.factoryPresets
assert(factory and factory[1].values.zoneThemes and not factory[2].values.zoneThemes)
fire(FieldKitFrame,"VARIABLES_LOADED")
local d=FieldKitRebornDB
assert(d.activeHudProfile==1 and d.factoryPresetVersion==1 and d.zoneThemes and d.cardOpacity==70)
assert(d.zoneThemeScale==80 and d.nativePlayerScale==70 and d.nativeMinimapScale==75)
assert(d.interfaceProfiles[1]~=factory[1] and d.interfaceProfiles[2]~=factory[2] and not d.interfaceProfiles[3])
AZS_RUN={ph="playing",t=10};AZS_ZONE={zone="zangarmarsh",dt=0}
AZS_SCHEDULE={{index=1,name="Hungarfen",state="due"}}
FieldKitNative.Watch();FieldKitNative.Packet("AZSBOSSES")
for pass=1,3 do
 for _,slot in ipairs({2,1}) do
  assert(P.Load(slot));FieldKitNativeTools.Update();FieldKitZoneThemes.Refresh(true)
  assert(d.zoneThemes==(slot==1) and d.cardOpacity==70 and d.nativeCardScale==75)
  assert(d.frameAnchors.FieldKitBossListFrame and d.frameAnchors.FieldKitGearFrame)
  assert(FieldKitBossListFrame:IsShown() and FieldKitGearFrame:IsShown() or (slot==1 and FieldKitReferenceHUD.frames.Accessories:IsShown()))
 end
end
local old=d.interfaceProfiles[1];d.cardOpacity=43
FieldKit.InitializeSettings({});assert(d.cardOpacity==43 and d.interfaceProfiles[1]==old)
local live=d
for _,themed in ipairs({true,false}) do
 assert(P.PreviewDefaults(themed));assert(d.zoneThemes==themed and d.cardOpacity==70)
 assert(P.CancelPreview());assert(FieldKitRebornDB==live and d.cardOpacity==43)
end
assert(factory[1].values.cardOpacity==70 and factory[2].values.cardOpacity==70)
print("PASS shipped maintainer presets: exact themed/native settings, first install/slot 1, six switches, live cards, fresh previews, deep-copy and existing-settings preservation")
