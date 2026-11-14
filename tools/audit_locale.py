"""Check literal UI calls/descriptors against the complete French UI catalog."""
from pathlib import Path
import re

def check(base, lua):
    catalog=lua.globals().FieldKitLocale
    literal=r'("(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\')'
    calls=re.compile(r'(?:FieldKit_L\(|FieldKit_Text\([^,\n]+,\s*)'+literal)
    descriptors=re.compile(r'\b(?:label|title|tip|help|text|heading)\s*=\s*'+literal)
    missing=[];checked=set()
    markup={'|cff%02x%02x%02x%s|r','|cffff2020','|cffff8000','|cffffd100'}
    for path in (base/'AzerothFieldKitReborn').glob('*.lua'):
        if path.name in ('Localization.lua','InterfaceStrings.lua'): continue
        text=path.read_text(encoding='utf8')
        patterns=[calls]
        if path.name in ('OptionsSchema.lua','Settings.lua','CombatOptions.lua','Interface.lua','ZoneThemeRegistry.lua'): patterns.append(descriptors)
        for pattern in patterns:
            for match in pattern.finditer(text):
                key=lua.execute('return '+match[1])
                if not re.search('[A-Za-z]{3}',key) or key in markup: continue
                checked.add(key)
                if catalog.fr[key] is None and catalog.en[key] is None:
                    missing.append(f'{path.name}:{text.count(chr(10),0,match.start())+1}: {key}')
    lua.execute('fire(FieldKitFrame,"VARIABLES_LOADED");SlashCmdList.FieldKit("")')
    for section in lua.globals().FieldKitUI.sections.values():
        if section['items']:
            for item in section['items'].values():
                values=item['values']
                if lua.eval('type')(values)=='table':
                    for key in values.values():
                        if isinstance(key,str):
                            checked.add(key)
                            if catalog.fr[key] is None and catalog.en[key] is None:
                                missing.append(f'Choice {item.label}: {key}')
    assert not missing,'Missing French UI translations:\n'+'\n'.join(missing)
    print(f'PASS French UI catalog: {len(checked)} literal labels/help texts and option descriptors')

if __name__=='__main__':
    from test_reborn import runtime,base
    check(base,runtime())
