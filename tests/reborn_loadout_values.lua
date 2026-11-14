fire(FieldKitFrame,"VARIABLES_LOADED")
local L,C,R=FieldKitLoadout,FieldKitZoneThemes,FieldKitReferenceHUD
AZS_ZONE={zone="icecrown",zname="Icecrown",heroic=0,class="hunter"}
AZS_RUN={ph="playing",t=200,hp=100,hpm=100}
AZS_SPELLS={{key="aimed_shot",spell=19434,rank=16,cdmax=.9},{key="rapid_fire",spell=3045,rank=4,cdmax=20}}
AZS_SPELLTIPS={aimed_shot="Frappe jusqu'à 9 ennemis à moins de 35 m pour 5364 dégâts chacun. Toutes les 0.9 s.",rapid_fire="Augmente votre vitesse d'attaque de 40% pendant 12 s."}
AZS_GEAR={{slot="amulet",name="Eye",amount=4,icon="EyeIcon",text="+1 target"},{slot="ring",name="Ring",amount=103.1,text="+103.1% damage"},{slot="trinket",name="Trinket",amount=201.1,text="+201.1% crit damage"}}
HasAction=function() return false end
GetSpellInfo=function(id) if id==19434 then return "Visée",nil,"AimedIcon" elseif id==3045 then return "Rapid Fire",nil,"RapidIcon" end end
FieldKitNative.Watch()
for _,prefix in ipairs({"AZSSPELLS","AZSSPELLTIP","AZSGEAR"}) do FieldKitNative.Packet(prefix) end
L.scanAt=0;L.Scan()
local spell=L.spells[1]
assert(spell.spellId==19434 and spell.rankValue==16)
local compact=table.concat(spell.effects,"\n")
for _,n in ipairs({"5364","9","35 m","0.9 s"}) do assert(string.find(compact,n,1,true),"Native current effect omitted: "..n) end
assert(not string.find(compact,"Frappe",1,true),"Full prose used as card summary")
assert(string.find(table.concat(L.spells[2].effects," "),"40%",1,true))
assert(L.items[2].rank==string.format(FieldKit_L("Rank %d"),4))
assert(L.items[11].rank==nil and L.items[13].rank==nil,"Accessory stat value presented as a rank")
FieldKitRebornDB.zoneThemes=false;FieldKitRebornDB.loadoutTab=2;L.Render(FieldKitGearFrame)
assert(FieldKitGearFrame.spellRows[1].bonus:GetText()==compact)
FieldKitRebornDB.loadoutTab=1;L.Render(FieldKitGearFrame)
assert(FieldKitGearFrame.slots[1].value:GetText()==L.items[2].rank)
assert(FieldKitGearFrame.slots[1].label:GetWidth()+FieldKitGearFrame.slots[1].value:GetWidth()<FieldKitGearFrame:GetWidth())
local lines={};local add=GameTooltip.AddLine
GameTooltip.AddLine=function(_,text) table.insert(lines,text) end
FieldKitRebornDB.meterSpellTips=true;FieldKitMeterLedger.NoteHit("Visée",5364,true)
L.Tip(UIParent,spell)
local tip=table.concat(lines,"\n")
assert(string.find(tip,AZS_SPELLTIPS.aimed_shot,1,true),"Available native tooltip omitted")
assert(not string.find(tip,FieldKit_L("Bonus details not provided"),1,true))
assert(string.find(tip,FieldKit_L("Max crit"),1,true),"Native-bar combat statistics missing in loadout hover")
GameTooltip.AddLine=add
local english=table.concat(L.SpellEffects("Hits up to 9 enemies within 35 yards for 5364 damage each. Every 0.9 sec.",.9)," ")
assert(string.find(english,"35 yd",1,true) and not string.find(english,"35 m",1,true),"Native range units silently converted")
local unknown=L.SpellEffects("Unrecognised translated effect.",.125)
assert(table.getn(unknown)==1 and string.find(unknown[1],"0.125",1,true),"Public cooldown precision lost")
C.allowUnfinishedThemes=true
for _,family in ipairs({"elwynn","naxx"}) do
 for _,variant in ipairs({"minimal","complete","alternative"}) do
  FieldKitRebornDB.zoneThemeMode=family;FieldKitRebornDB.zoneThemeVariant=variant
  C.Set("zoneThemes",true);FieldKitRebornDB.loadoutTab=1;C.Refresh()
  if variant=="complete" and R.frames.Accessories and R.frames.Accessories:IsShown() then
   local row=R.frames.Accessories.rows[1]
   assert(row.entry.rankValue==4 and (row.value.referenceFullText or row.value:GetText())==row.entry.rank,"Themed amulet rank omitted")
  end
  C.Set("zoneThemes",false)
 end
end
local old=L.ContentKey();AZS_GEAR[1].amount=5;L.scanAt=0;L.Scan()
assert(L.items[2].rankValue==5 and L.ContentKey()~=old,"Rank-only native update left stale card")
AZS_SPELLTIPS.aimed_shot="Frappe jusqu'à 10 ennemis à moins de 35 m pour 6000 dégâts chacun. Toutes les 0.8 s."
L.scanAt=0;L.Scan();assert(string.find(table.concat(L.spells[1].effects," "),"6000",1,true),"Spell values remained stale")
print("PASS screenshot-native FR/EN current effects without Bonus label, exact units/cadence, amulet rank vs jewelry amount, rank/value refresh, themed ranks and shared combat-stat hover")
