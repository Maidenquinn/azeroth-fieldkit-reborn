"""Inventory the actual journey schema and run its synthetic setter matrix.

Uses production descriptors and the same mock client as test_reborn.py.
No live game interaction or client files are modified by this tool.
"""
from pathlib import Path
import hashlib,json
from test_reborn import runtime

base=Path(__file__).resolve().parents[1]
l=runtime()
l.execute((base/'tests/reborn_settings_audit.lua').read_text(encoding='utf8'))
sections=[]
for section in l.globals().FieldKitUI.sections.values():
    items=[]
    for item in section['items'].values():
        entry={'kind':item['kind'],'label':item['label'],'id':item['id'],
               'getter':bool(item['get']),'setter':bool(item['set'])}
        if item['min'] is not None: entry['minimum']=item['min']
        if item['max'] is not None: entry['maximum']=item['max']
        if item['values'] is not None: entry['choices']=list(item['values'].values())
        items.append(entry)
    sections.append({'id':section['id'],'title':section['title'],'items':items})
report={'schemaVersion':1,'validation':'synthetic production-schema setter matrix; not live visual/co-op acceptance',
        'cases':l.globals().FieldKitSettingsAudit.cases,
        'variants':list(l.globals().FieldKitSettingsAudit.variants.values()),
        'pages':sections,
        'customEditors':'Combat text, world markers, theme composition and profiles use custom widgets, separately exercised by the full verification fixtures.',
        'runtimeHashes':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((base/'AzerothFieldKitReborn').glob('*.lua'))}}
(base/'docs/REBORN_SETTINGS_AUDIT.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf8',newline='\n')
print(json.dumps({'pages':len(sections),'schemaItems':sum(len(s['items']) for s in sections),'setterCases':report['cases']}))
