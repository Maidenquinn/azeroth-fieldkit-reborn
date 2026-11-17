"""Check UI coverage and format safety in every selectable locale."""
from pathlib import Path
import re

def check(base, lua):
    catalog=lua.globals().FieldKitLocale
    literal=r'("(?:[^"\\]|\\.)*"|\'(?:[^\'\\]|\\.)*\')'
    calls=re.compile(r'(?:FieldKit_L\(|FieldKit_Text\([^,\n]+,\s*)'+literal)
    widgets=re.compile(r'\b(?:T\.Label\([^,\n]+,\s*|T\.Button\([^,\n]+,[^,\n]+,\s*|Text\([^,\n]+,\s*)'+literal)
    descriptors=re.compile(r'\b(?:label|title|tip|help|text|heading)\s*=\s*'+literal)
    missing=[];checked=set()
    markup={'|cff%02x%02x%02x%s|r','|cffff2020','|cffff8000','|cffffd100','AZEROTH FIELDKIT','FIELDKIT  +','FieldKit'}
    for path in (base/'AzerothFieldKitReborn').glob('*.lua'):
        if path.name in ('Localization.lua','InterfaceStrings.lua') or path.name.startswith('Locale_'): continue
        text=path.read_text(encoding='utf8')
        patterns=[calls,widgets]
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
    # The entire historical catalog, not just the regex-discovered subset, is
    # required in each new language. A literal English fallback cannot hide a hole.
    tokens=re.compile(r'%%|%[-+0]*\d*(?:\.\d+)?[cdeEfgGiouXxsq]')
    issues=[]
    for row in catalog.languages.values():
        code=row[1]
        if code in ('auto','en','fr'): continue
        target=catalog[code]
        for key in catalog.fr.keys():
            value=target[key] if target else None
            if not isinstance(value,str) or not value.strip(): issues.append(f'{code}: missing {key}')
            elif any(marker in value for marker in ('\u2047','\ufffd','<unk>')): issues.append(f'{code}: unknown translation token {key}')
            elif tokens.findall(key)!=tokens.findall(value): issues.append(f'{code}: formats {key}: {value}')
            elif key.count('\n')!=value.count('\n'): issues.append(f'{code}: newlines {key}')
    assert not issues,'Locale completeness/format errors:\n'+'\n'.join(issues)
    print(f'PASS 14-language catalogs: {len(list(catalog.fr.keys()))} canonical strings; formats and newlines preserved')

if __name__=='__main__':
    from test_reborn import runtime,base
    check(base,runtime())
