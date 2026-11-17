fire(FieldKitFrame,"VARIABLES_LOADED")
assert(FieldKitRebornDB.language=="auto","Fresh factory presets must follow the game language")
local P=FieldKitProfiles
-- Synthetic preferences exercise the first-install transaction independently of the shipped artwork/coordinates.
local previous=P.factoryPresets
FieldKitRebornDB.cardOpacity=70;FieldKitRebornDB.zoneThemes=true;assert(P.Save(1))
FieldKitRebornDB.zoneThemes=false;FieldKitRebornDB.nativePlayerScale=60;assert(P.Save(2))
local source=FieldKitRebornDB.interfaceProfiles;P.factoryPresets=source
FieldKitRebornDB={};FieldKit.InitializeSettings({})
local d=FieldKitRebornDB
assert(d.activeHudProfile==1 and d.factoryPresetVersion==1 and d.zoneThemes and d.cardOpacity==70)
assert(d.interfaceProfiles[1]~=source[1] and d.interfaceProfiles[2]~=source[2])
assert(d.interfaceProfiles[2].values.nativePlayerScale==60 and not d.interfaceProfiles[2].values.zoneThemes)
d.interfaceProfiles[1].tables.frameAnchors.Test={"TOPLEFT","TOPLEFT",123,-456}
assert(source[1].tables.frameAnchors.Test==nil and d.interfaceProfiles[2].tables.frameAnchors.Test==nil)
local slot=d.interfaceProfiles[1];d.cardOpacity=43
FieldKit.InitializeSettings({});assert(d.cardOpacity==43 and d.interfaceProfiles[1]==slot,"Reload reset a user's presets")
FieldKitRebornDB={schema=3,cardOpacity=26};FieldKit.InitializeSettings({})
assert(FieldKitRebornDB.cardOpacity==26 and not FieldKitRebornDB.factoryPresetVersion,"Upgrade overwrote an existing player")
P.factoryPresets=previous
print("PASS first-install factory profiles: two independent deep copies, profile 1 active, reload/edit preservation and existing-player isolation")
