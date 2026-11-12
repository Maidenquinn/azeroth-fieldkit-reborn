-- Reborn-specific tests run without the historical fixture compatibility flag.
assert(not FieldKit.rebornLegacyFixture)
assert(FieldKit.folder=="AzerothFieldKitReborn")
assert(FieldKit.Number(1e15)==1e15 and FieldKit.Number(1/0)==nil)
assert(FieldKit_FormatHealth(1e15,1e15,1)=="1000000000000000 / 1000000000000000")
FieldKitDB={sentinel="original-game"}
fire(FieldKitFrame,"VARIABLES_LOADED")
assert(FieldKit.zoneThemeReady and FieldKitMeterFrame and FieldKitStatsFrame and FieldKitGearFrame,
 "Reborn startup stopped before the complete HUD was created")
assert(FieldKitDB.sentinel=="original-game" and FieldKitRebornDB~=FieldKitDB)
AZS_GEN={classes={{key="monk",token="MONK"}},spells={MONK={{key="jab",name="Jab",icon="ability_monk_jab"}}}}
AZS_ZONE={zone="new-expansion-map",class="monk"}
AZS_L={Jab="Coup direct"}
local spell=FieldKitReborn.Spell("jab")
assert(spell.name=="Coup direct" and spell.icon=="Interface\\Icons\\ability_monk_jab")
assert(FieldKitReborn.Spell("not-learned")==nil)
AZS_GEAR={{slot="ring",name="Reborn ring 1",text="+15% crit",icon="ring"},{slot="ring",name="Reborn ring 2",text="+12% haste"},
 {slot="trinket",name="Reborn trinket",text="+20% damage"},{slot="amulet",name="Reborn amulet",amount=8}}
local gear=FieldKitReborn.Gear()
assert(gear[11].name=="Reborn ring 1" and gear[12].name=="Reborn ring 2" and gear[13].name=="Reborn trinket" and gear[2].rankValue==8)
function AZS_GetMeterCapabilities() return {healingPerspectives={"performed"},features={atomicCheckpoints=false}} end
local calls=0
AZS_GetHealing=function() calls=calls+1;return {{name="Heal",dmg=25}},25,5 end
FieldKitRebornDB.meterHealDone=false
local rows,total,rate,known=FieldKitMeterLedger.Read("healing")
assert(not known and total==nil and calls==0,"Performed healing leaked into received")
FieldKitRebornDB.meterHealDone=true
rows,total,rate,known=FieldKitMeterLedger.Read("healing")
assert(known and total==25 and calls==1)
FieldKitMeterLedger.NoteHit("Jab",123,true)
assert(FieldKitMeterLedger.Reset()==false)
assert(FieldKitMeterLedger.Stats("Jab")==nil,"Unsupported checkpoint must still clear local hits")
assert(table.getn(FieldKitRunMode.ChartLines(1))==0,"Old difficulty chart leaked into Reborn")
local id="reborn:1"
AZS_API_RunId=function() return id end
FieldKitMeterLedger.Boundary();FieldKitMeterLedger.NoteHit("Jab",99,false)
id="reborn:2";FieldKitMeterLedger.Boundary()
assert(FieldKitMeterLedger.Stats("Jab")==nil,"Same-map new run retained hit stats")
local f={portrait={SetTexture=function(self,path) self.path=path end}}
AZS_UNITS={{id=987,entry=42}};AZS_GEN.creatureIcons={[42]="BossIcon"}
FieldKit_Portraits.Apply(f,"New boss","boss",987)
assert(f.portrait.path=="Interface\\Icons\\BossIcon")
AZS_UNITS={{id=42}}
FieldKit_Portraits.Apply(f,"New boss","boss",42)
assert(f.portrait.path=="Interface\\Icons\\INV_Misc_QuestionMark","Instance id misused as creature entry")
print("PASS Reborn identity, native class assets, jewelry, healing semantics, checkpoint rejection, same-map run boundary and portrait identity")
