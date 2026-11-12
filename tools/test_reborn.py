"""Reborn fixtures; --game additionally executes the installed public API sources.
No client files are modified. Mock rendering is not live game validation.
"""
from pathlib import Path
import argparse,json
from lupa.lua51 import LuaRuntime
base=Path(__file__).resolve().parents[1]
root=base/'AzerothFieldKitReborn'
def runtime():
    l=LuaRuntime(unpack_returned_tuples=True)
    l.execute((base/'tests/mock.lua').read_text(encoding='utf8'))
    for name in (root/'AzerothFieldKitReborn.toc').read_text().splitlines():
        if name.endswith('.lua'): l.execute((root/name).read_text(encoding='utf8'),name=name)
    return l
def main():
    p=argparse.ArgumentParser();p.add_argument('--game',type=Path);a=p.parse_args()
    l=runtime();l.execute((base/'tests/reborn.lua').read_text(encoding='utf8'))
    l=runtime();l.execute((base/'tests/reborn_party.lua').read_text(encoding='utf8'))
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
        assert(FieldKitMeterLedger.Reset()==false)
        for _,zone in ipairs(AZS_GEN.zones) do
          AZS_ZONE.zone=zone.key
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
        print("PASS installed Reborn Api.lua + Meter.lua: damage, healing, unsupported checkpoints; every generated class/spell and map")
        ''')
    print(json.dumps({'rebornFixtures':True,'installedApiExecuted':bool(a.game),'liveGameTest':False}))
if __name__=='__main__':main()
