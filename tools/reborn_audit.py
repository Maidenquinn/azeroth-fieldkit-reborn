"""Read-only inventory of a supplied Reborn client; no game assets are exported."""
from pathlib import Path
import argparse, hashlib, json, re
from lupa.lua51 import LuaRuntime

base=Path(__file__).resolve().parents[1]
def inspect(game):
    addons=game/'Interface/AddOns'
    api=addons/'AzerothSurvivorsAPI'
    generated=addons/'AzerothSurvivors/Generated/Content.lua'
    l=LuaRuntime(unpack_returned_tuples=True)
    l.execute(generated.read_text(encoding='utf8'))
    g=l.globals().AZS_GEN
    n=lambda t:sum(1 for _ in t.items()) if t is not None else 0
    counts={k:n(g[k]) for k in ('classes','zones','jewels','amulets','gearTiers','creatureIcons','pieces','achievements')}
    counts['spells']=sum(n(pool) for _,pool in g.spells.items())
    zones=[{'key':z.key,'name':z.name,'world':z.world,'scheduledBosses':n(z.bosses)} for _,z in g.zones.items()]
    native='\n'.join(p.read_text(encoding='utf8') for p in api.glob('*.lua'))
    supplied=set(re.findall(r'function\s+(AZS_\w+)\s*\(',native))|{'AZS_GetRunTime'}
    used=set()
    for p in (base/'AzerothFieldKitReborn').glob('*.lua'):
        used.update(re.findall(r'\b(AZS_\w+)\s*\(',p.read_text(encoding='utf8')))
    evidence={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in api.glob('*') if p.is_file()}
    evidence['Generated/Content.lua']=hashlib.sha256(generated.read_bytes()).hexdigest()
    return {'clientReadOnly':True,'liveGameTest':False,'counts':counts,'zones':zones,'clientEvidenceSHA256':evidence,
            'directCalls':sorted(used),'directCallsAbsentFromApiFiles':sorted(used-supplied)}
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--game',type=Path,required=True);a=p.parse_args()
    result=inspect(a.game)
    (base/'docs/REBORN_CLIENT_INVENTORY.json').write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    print(json.dumps(result['counts'],ensure_ascii=False));print('Optional calls absent:',result['directCallsAbsentFromApiFiles'])
