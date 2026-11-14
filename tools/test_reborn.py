"""Reborn fixtures; --game additionally executes the installed public API sources.
No client files are modified. Mock rendering is not live game validation.
"""
from pathlib import Path
import argparse,json
from lupa.lua51 import LuaRuntime
base=Path(__file__).resolve().parents[1]
root=base/'AzerothFieldKitReborn'
def runtime(prelude=None):
    l=LuaRuntime(unpack_returned_tuples=True)
    l.execute((base/'tests/mock.lua').read_text(encoding='utf8'))
    l.execute('GetPlayerBuff=nil;GetPlayerBuffTexture=nil;GetPlayerBuffTimeLeft=nil;GetPlayerBuffApplications=nil')
    if prelude: l.execute(prelude)
    for name in (root/'AzerothFieldKitReborn.toc').read_text().splitlines():
        if name.endswith('.lua'): l.execute((root/name).read_text(encoding='utf8'),name=name)
    return l
def main():
    p=argparse.ArgumentParser();p.add_argument('--game',type=Path);a=p.parse_args()
    l=runtime();l.execute((base/'tests/reborn.lua').read_text(encoding='utf8'))
    l=runtime();l.execute((base/'tests/reborn_party.lua').read_text(encoding='utf8'))
    l=runtime();l.execute((base/'tests/reborn_buffs.lua').read_text(encoding='utf8'))
    l=runtime();l.execute((base/'tests/reborn_themes.lua').read_text(encoding='utf8'))
    l=runtime();l.execute((base/'tests/reborn_hud_details.lua').read_text(encoding='utf8'))
    l=runtime();l.execute((base/'tests/reborn_visual_integration.lua').read_text(encoding='utf8'))
    l=runtime();l.execute((base/'tests/reborn_ready_hud.lua').read_text(encoding='utf8'))
    l=runtime();l.execute((base/'tests/reborn_presentation_regressions.lua').read_text(encoding='utf8'))
    l=runtime();l.execute((base/'tests/reborn_chat_controls.lua').read_text(encoding='utf8'))
    l=runtime();l.execute((base/'tests/reborn_settings_audit.lua').read_text(encoding='utf8'))
    l=runtime();l.execute((base/'tests/reborn_optional_art.lua').read_text(encoding='utf8'))
    l=runtime();l.execute((base/'tests/reborn_difficulty_context.lua').read_text(encoding='utf8'))
    l=runtime();l.execute((base/'tests/reborn_taken_layout.lua').read_text(encoding='utf8'))
    l=runtime();l.execute((base/'tests/reborn_boss_progression.lua').read_text(encoding='utf-8-sig'))
    l=runtime();l.execute((base/'tests/reborn_064.lua').read_text(encoding='utf8'))
    l=runtime();l.execute((base/'tests/reborn_native_hud.lua').read_text(encoding='utf8'))
    l=runtime('AZS={};function AZS.On(prefix,fn) if prefix=="AZSZONE" then ZONE_CAPTURE=fn end end')
    l.execute('''
    GetRealZoneText=function() return "Hellfire Peninsula" end
    AZS_ZONE={zone="hellfire",dt=0};AZS_RUN={ph="ready",t=0}
    assert(FieldKitRebornDB==nil and type(ZONE_CAPTURE)=="function")
    ZONE_CAPTURE()
    AZS_ZONE={};AZS_RUN={ph="playing",t=1}
    fire(FieldKitFrame,"VARIABLES_LOADED")
    assert(FieldKit.GetHeroicLevel()==0,"Native router capture before database initialization lost Normal")
    AZS_ZONE={zone="hellfire",dt=3};ZONE_CAPTURE()
    assert(FieldKit.GetHeroicLevel()==3)
    AZS_ZONE={};ZONE_CAPTURE();assert(FieldKit.GetHeroicLevel()==nil,"New packet retained an unobserved rank")
    print("PASS native zone callback before settings initialization and new zone invalidation")
    ''')
    if a.game:
        l=runtime()
        l.execute('''
        time=function() return 1000 end
        IsLoggedIn=function() return true end
        UnitExists=function(u) return u=="player" end
        UnitName=function(u) return u=="player" and "Tester" or nil end
        AZS={handlers={}}
        function AZS.On(prefix,fn)
          AZS.handlers[prefix]=AZS.handlers[prefix] or {};table.insert(AZS.handlers[prefix],fn)
        end
        function AZS.ParseKV(msg)
          local t={};for k,v in string.gmatch(msg or "","(%w+)=([^;]*)") do t[k]=tonumber(v) or v end;return t
        end
        function AZS.ParseList(msg,names)
          local out={};for row in string.gmatch(msg or "","[^;]+") do
            local v={};local i=1;for s in string.gmatch(row..",","(.-),") do v[names[i] or i]=tonumber(s) or s;i=i+1 end
            table.insert(out,v)
          end;return out
        end
        AZS_List=AZS.ParseList;AZS_Fields=AZS.ParseKV
        function ROUTE(prefix,msg) for _,fn in ipairs(AZS.handlers[prefix] or {}) do fn(msg,prefix) end end
        AZS_ZONE={zone="hellfire",class="monk",len=1200};AZS_RUN={ph="playing",t=100}
        AZS_SCHEDULE={};AZS_REVIVE={};AZS_END={};AZS_SPELLS={};AZS_GEAR={}
        ''')
        addons=a.game/'Interface/AddOns'
        for path in (addons/'AzerothSurvivors/Generated/Content.lua',addons/'AzerothSurvivorsAPI/Api.lua',addons/'AzerothSurvivorsAPI/Meter.lua'):
            l.execute(path.read_text(encoding='utf8'),name=path.name)
        l.execute('''
        fire(FieldKitFrame,"VARIABLES_LOADED")
        ROUTE("AZSZONE","");ROUTE("AZSRUN","t=100")
        ROUTE("AZSMETER","Jab,200,2,1,0,0")
        local rows,total,rate,known=FieldKitMeterLedger.Read("damage")
        assert(known and total==200 and rows[1].name=="Jab")
        ROUTE("AZSHEAL","Heal,50,0.5,1,0,0")
        FieldKitRebornDB.meterHealDone=false
        rows,total,rate,known=FieldKitMeterLedger.Read("healing")
        assert(not known and total==nil)
        FieldKitRebornDB.meterHealDone=true
        rows,total,rate,known=FieldKitMeterLedger.Read("healing")
        assert(known and total==50)
        local capabilities=AZS_GetMeterCapabilities()
        local checkpoints=capabilities and capabilities.features and capabilities.features.atomicCheckpoints==true
        assert(FieldKitMeterLedger.Reset()==checkpoints,"Reset did not follow native checkpoint capabilities")
        if checkpoints then
          rows,total,rate,known=FieldKitMeterLedger.Read("damage")
          assert(known and total==0,"Checkpoint reset retained damage from before the reset")
          ROUTE("AZSMETER","Jab,275,2.75,1,0,0")
          rows,total,rate,known=FieldKitMeterLedger.Read("damage")
          assert(known and total==75,"Checkpoint did not count only subsequent damage")
        end
        AZS_RUN.ph="ready";AZS_ZONE.class="hunter"
        AZS_SPELLS={{key="auto_shot",spell=75,rank=1},{key="aimed_shot",spell=19434,rank=1}}
        FieldKitNative.Packet("AZSSPELLS");FieldKitLoadout.scanAt=0;FieldKitLoadout.Update()
        assert(#FieldKitLoadout.spells==2,"Installed retained-run API lost ready spells")
        local context=AZS_GetMeterContext()
        local snapshot=AZS_GetMeterLoadout({apiVersion=1,runId=context.runId})
        assert(snapshot and #snapshot.abilities==2,"Installed structured API was not exercised")
        AZS_RUN.ph="playing"
        AZS_UNITS={{kind="boss",id=1,name="Boss",hp=100,hpm=200,state=1}}
        AZS_LAIRS={{state="awake",id=2,name="Guardian",hp=50,hpm=80}}
        local units=FieldKitReborn.BossUnits()
        assert(#AZS_UNITS==1 and #units==2 and units[2].kind=="guardian" and units[2].state==1)
        assert(units[1].state==1 and units[2].hp==50)
        AZS_LAIRS[1].state="asleep";units=FieldKitReborn.BossUnits();assert(units[2].state==0)
        for _,zone in ipairs(AZS_GEN.zones) do
          AZS_ZONE.zone=zone.key
          FieldKitRebornDB.zoneThemes=true;FieldKitRebornDB.zoneThemeMode="auto"
          assert(FieldKitZoneThemes.Resolve()=="elwynn","Auto theme unavailable on "..zone.key)
          assert(zone.bosses and #zone.bosses>0)
          assert(FieldKitRunMode.ChartLines(1)[1]==nil)
        end
        for _,class in ipairs(AZS_GEN.classes) do
          AZS_ZONE.class=class.key
          for _,spell in ipairs(AZS_GEN.spells[class.token]) do
            local s=FieldKitReborn.Spell(spell.key)
            assert(s and s.name==spell.name and s.icon)
          end
        end
        print("PASS installed Reborn Api.lua + Meter.lua: damage, healing, capability-based checkpoints; every generated class/spell and map")
        ''')
        l.execute((base/'tests/reborn_064_native.lua').read_text(encoding='utf8'))
    print(json.dumps({'rebornFixtures':True,'installedApiExecuted':bool(a.game),'liveGameTest':False}))
if __name__=='__main__':main()
