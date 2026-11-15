fire(FieldKitFrame,"VARIABLES_LOADED")
FieldKit_SetLanguage("fr")
local shared={Blizzard=true,Dispersion=true,Pestilence=true,Corruption=true,Rupture=true}
local count=0
for _,class in ipairs(AZS_GEN.classes) do
 AZS_ZONE={class=class.key,zone="naxx"};AZS_RUN={ph="playing",t=1}
 for _,spell in ipairs(AZS_GEN.spells[class.token]) do
  local expected=AZS_L[spell.name]
  assert(expected or shared[spell.name],"Untranslated native spell: "..spell.name)
  expected=expected or spell.name
  assert(FieldKitReborn.Spell(spell.key).name==expected)
  assert(FieldKitReborn.DisplayName(spell.name)==expected)
  assert(FieldKitCombat.NativeLabel(spell.name)==expected)
  count=count+1
 end
end
local items=0
for _,group in ipairs({AZS_GEN.amulets,AZS_GEN.jewels}) do
 for _,item in ipairs(group) do assert(AZS_L[item.name],"Missing native French jewelry name: "..item.name);assert(FieldKitReborn.DisplayName(item.name)==(AZS_L[item.name] or item.name));items=items+1 end
end
assert(count>=241 and items>=66)
assert(FieldKitReborn.DisplayName("Rapid Fire")=="Tir rapide")
assert(FieldKitReborn.DisplayName("Surge of Strength")=="Afflux de force")
print("PASS installed native French catalog: "..count.." class spells, "..items.." jewelry names; 5 French spell names legitimately identical to English")

local maps=0
for _,zone in ipairs(AZS_GEN.zones) do
 AZS_ZONE={zone=zone.key};AZS_RUN={ph="playing",t=100,rift=25};AZS_SCHEDULE={}
 for i,b in ipairs(zone.bosses) do AZS_SCHEDULE[i]={index=i,name=b.name,state=i==1 and "dead" or "due"} end
 FieldKitNative.Watch();FieldKitNative.Packet("AZSBOSSES")
 local rows,dead,known=FieldKitNativeTools.BossListRows()
 assert(known and #rows==#zone.bosses and dead==1)
 for i,b in ipairs(zone.bosses) do assert(rows[i].label==i..". "..FieldKitReborn.DisplayName(b.name)) end
 maps=maps+1
end
print("PASS campaign boss roster against all "..maps.." installed native map catalogs")
