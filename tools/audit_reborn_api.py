"""Inventory documented engine exports, compatibility functions and client helpers.
References are static evidence, never proof that a branch executed in game.
Only public Lua and official web documentation are read; no account files.
"""
from pathlib import Path
from html.parser import HTMLParser
import argparse, hashlib, json, re, urllib.request

BASE = Path(__file__).resolve().parents[1]
class Text(HTMLParser):
    def __init__(self): super().__init__(); self.parts=[]; self.skip=0
    def handle_starttag(self,tag,attrs):
        if tag in ('style','script'): self.skip+=1
    def handle_endtag(self,tag):
        if tag in ('style','script'): self.skip=max(0,self.skip-1)
    def handle_data(self,data):
        if not self.skip: self.parts.append(data)

def main():
    p=argparse.ArgumentParser();p.add_argument('--game',type=Path,required=True);a=p.parse_args()
    runtime=BASE/'AzerothFieldKitReborn'; addons=a.game/'Interface/AddOns'
    loaded=[s for s in (runtime/'AzerothFieldKitReborn.toc').read_text().splitlines() if s.endswith('.lua')]
    refs={}; calls={}; hashes={}; exports={}
    for name in loaded:
        path=runtime/name;raw=path.read_bytes();text=raw.decode('utf8');hashes[name]=hashlib.sha256(raw).hexdigest()
        for line,s in enumerate(text.splitlines(),1):
            for symbol in set(re.findall(r'\bAZS_\w+',s)):
                refs.setdefault(symbol,[]).append({'file':name,'line':line})
            for symbol in re.findall(r'\b(AZS_\w+)\s*\(',s): calls.setdefault(symbol,[]).append({'file':name,'line':line})
    evidence={}
    for folder in ('AzerothSurvivorsAPI','AzerothSurvivors','AzerothSurvivorsUI'):
        for path in sorted((addons/folder).rglob('*.lua')):
            raw=path.read_bytes();text=raw.decode('utf8');rel=path.relative_to(addons).as_posix()
            evidence[rel]=hashlib.sha256(raw).hexdigest()
            for line,s in enumerate(text.splitlines(),1):
                for m in re.finditer(r'(?:function\s+(AZS_\w+)\s*\(|\b(AZS_\w+)\s*=\s*function\s*\()',s):
                    symbol=m[1] or m[2];exports.setdefault(symbol,[]).append({'file':rel,'line':line})
    docs={}; documented=set();(BASE/'build').mkdir(exist_ok=True)
    for slug in ('addon-api','runs-and-zones','classes-and-talents','co-op','progression-and-cosmetics','getting-started','troubleshooting','leaderboards-and-discord'):
        url='https://azreborn.com/guides/'+slug
        try:
            raw=urllib.request.urlopen(url,timeout=40).read();parser=Text();parser.feed(raw.decode('utf8'));text='\n'.join(parser.parts)
            (BASE/'build'/('reborn-'+slug+'.txt')).write_text(text,encoding='utf8')
            docs[url]={'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}
            if slug=='addon-api': documented=set(re.findall(r'\bAZS_\w+',text))
        except Exception as e: docs[url]={'error':str(e)}
    inventory=[]
    for symbol in sorted(set(exports)|documented|set(refs)):
        hits=refs.get(symbol,[]);functional=[h for h in hits if h['file']!='Diagnostics.lua']
        inventory.append({'name':symbol,'documentedMention':symbol in documented,'definitions':exports.get(symbol,[]),
                          'references':hits,'directCallSites':calls.get(symbol,[]),
                          'coverage':'referenced' if functional else ('diagnostic-only' if hits else 'unused')})
    report={'scope':'All TOC runtime modules; public installed Lua declarations and official guide mentions. Engine binary implementation excluded.',
            'liveGameValidation':False,'runtimeModules':len(loaded),'runtimeSHA256':hashes,'nativeLuaSHA256':evidence,'webEvidence':docs,
            'symbols':inventory,'counts':{'runtimeModules':len(loaded),'nativeLuaFiles':len(evidence),'declaredFunctions':len(exports),
            'documentedAZSSymbols':len(documented),'referencedAZSSymbols':len(refs)}}
    (BASE/'docs/REBORN_API_COVERAGE.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
    print(json.dumps(report['counts']))
    print('Unused compatibility declarations:',[s['name'] for s in inventory if s['coverage']=='unused' and any(d['file'].startswith('AzerothSurvivorsAPI/') for d in s['definitions'])])
    print('Unused documented symbols:',[s['name'] for s in inventory if s['coverage']=='unused' and s['documentedMention']])
    print('Web reads:',{k:('error' if 'error' in v else 'ok') for k,v in docs.items()})
if __name__=='__main__':main()
