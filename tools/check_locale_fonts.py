"""Check bundled locale glyphs; optionally build OFL derivatives from pinned font inputs.

No network access or player files. Original font inputs and the public native text
catalog are developer build inputs, never installed with the addon.
"""
from pathlib import Path
import argparse, copy, hashlib, json
from fontTools.ttLib import TTFont
from fontTools import __version__ as fontToolsVersion
from fontTools.pens.recordingPen import DecomposingRecordingPen
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.ttGlyphPen import TTGlyphPen

BASE=Path(__file__).resolve().parents[1]
ROOT=BASE/'AzerothFieldKitReborn'

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def characters():
    from lupa.lua51 import LuaRuntime
    lua=LuaRuntime()
    for name in ('Localization.lua','InterfaceStrings.lua','International.lua'):
        lua.execute((ROOT/name).read_text(encoding='utf8'))
    result={'en':set(), 'fr':set()}
    for key,value in lua.globals().FieldKitLocale.fr.items():
        result['en'].update(key);result['fr'].update(value)
    for code in ('pl','cs','de','pt','es','ro','tr','ru','uk','zh','ja','ko'):
        lua.execute((ROOT/f'Locale_{code}.lua').read_text(encoding='utf8'))
        result[code]=set(''.join(lua.globals().FieldKitLocale[code].values()))
    for row in lua.globals().FieldKitLocale.languages.values():
        if row[1] in result:result[row[1]].update(row[2])
    return {code:{ord(c) for c in chars if not c.isspace()} for code,chars in result.items()}

def add_glyphs(font,source,points):
    """Copy decomposed CFF outlines as TrueType quadratics, preserving the Latin tables."""
    assert font['head'].unitsPerEm==source['head'].unitsPerEm
    cmap=font.getBestCmap();source_map=source.getBestCmap();glyphs=source.getGlyphSet()
    order=list(font.getGlyphOrder())
    for point in sorted(points-set(cmap)):
        assert point in source_map, f'No source glyph U+{point:04X}'
        original=source_map[point];name=f'fieldkit{point:06X}'
        recording=DecomposingRecordingPen(glyphs);glyphs[original].draw(recording)
        pen=TTGlyphPen(None)
        recording.replay(Cu2QuPen(pen,1.0,reverse_direction=True))
        font['glyf'][name]=pen.glyph();order.append(name)
        font['hmtx'].metrics[name]=source['hmtx'].metrics[original]
        for table in font['cmap'].tables:
            if table.isUnicode() and (point<=0xFFFF or table.format in (12,13)):
                table.cmap[point]=name
    font.setGlyphOrder(order)
    font['OS/2'].recalcUnicodeRanges(font)
    font['OS/2'].recalcCodePageRanges(font)

def rename(font,family,cjk):
    for record in font['name'].names:
        if record.nameID in (1,3,4,6,16):
            value=family.replace(' ','') if record.nameID==6 else family
            record.string=value.encode(record.getEncoding(),errors='replace')
    # Both original notices survive the derivative. Fonts remain under OFL.
    notice='\n'+cjk['name'].getDebugName(0)
    for record in font['name'].names:
        if record.nameID==0:
            record.string=(record.toUnicode()+notice).encode(record.getEncoding(),errors='replace')

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-dir',type=Path)
    parser.add_argument('--native-catalog',type=Path)
    args=parser.parse_args();needed=characters()
    recipe_path=BASE/'data/locale-fonts.json'
    if args.source_dir:
        assert args.native_catalog, 'Build requires the public native text catalog'
        inputs=args.source_dir;sources=json.loads((inputs/'sources.json').read_text(encoding='utf8'))
        latin={'AzerothSans.ttf':'eabcbfd9d8f91780eabcf59f4628d00cf629dcfb3f20c7fd4c94f163fbcd0fe0',
               'NotoSerif-Regular.ttf':'c8f669ceb2c9c60ccf55198b305e08a997ffca79a38cc7eeb551e643cbe66505'}
        for filename,expected in latin.items():assert digest(inputs/filename)==expected,filename
        assert digest(inputs/'OFL.txt')==sources['license']['sha256']
        for code in ('zh','ja','ko'):
            assert digest(inputs/f'{code}.otf')==sources[code]['sha256']
        native=json.loads(args.native_catalog.read_text(encoding='utf8'))
        union=set().union(*needed.values())
        for code in ('zhCN','jaJP','koKR'):
            union.update(ord(c) for text in native.get(code,{}).values() for c in text if not c.isspace())
        cjk={code:TTFont(inputs/f'{code}.otf',recalcTimestamp=False) for code in ('zh','ja','ko')}
        # Ignore nonprinting controls; every actual UI character must be present.
        union={point for point in union if point>=32}
        fonts={}
        for code in ('zh','ja','ko'):
            font=TTFont(inputs/'AzerothSans.ttf',recalcTimestamp=False)
            missing=union-set(font.getBestCmap())-set(cjk[code].getBestCmap())
            assert not missing, f'Uncovered glyphs: {sorted(missing)}'
            add_glyphs(font,cjk[code],union);rename(font,'FieldKit Sans '+code,cjk[code])
            target=ROOT/f'media/FieldKitSans-{code}.ttf';font.save(target)
            fonts[code]={'file':target.name,'sha256':digest(target),'glyphs':len(font.getBestCmap())}
        # Historical UI arrows/checkmarks also need glyphs in the Latin body/headings.
        for filename in ('AzerothSans.ttf','NotoSerif-Regular.ttf'):
            font=TTFont(inputs/filename,recalcTimestamp=False)
            points=set().union(*(v for k,v in needed.items() if k not in cjk))
            add_glyphs(font,cjk['zh'],points);rename(font,'FieldKit '+filename.split('.')[0],cjk['zh'])
            output='FieldKitLatin.ttf' if filename=='AzerothSans.ttf' else 'FieldKitSerif.ttf'
            target=ROOT/'media'/output;font.save(target)
            fonts[filename]={'file':output,'sha256':digest(target),'glyphs':len(font.getBestCmap())}
        license_path=ROOT/'media/OFL-NotoCJK.txt';license_path.write_bytes((inputs/'OFL.txt').read_bytes())
        recipe={'sources':sources,'latinInputs':latin,'fontToolsVersion':fontToolsVersion,'derivatives':fonts,'nativeCatalogSHA256':digest(args.native_catalog),
                'method':'Pinned OFL Noto CJK outlines converted to quadratics and added to the bundled Latin face; Latin shaping tables retained. Regional outlines selected per language.'}
        recipe_path.write_text(json.dumps(recipe,indent=2)+'\n',encoding='utf8',newline='\n')
        assets_path=BASE/'data/theme-assets.json';assets=json.loads(assets_path.read_text(encoding='utf8'))
        for path in [license_path,*[ROOT/'media'/v['file'] for v in fonts.values()]]:
            assets['files'][path.relative_to(ROOT).as_posix()]={'sha256':digest(path),'bytes':path.stat().st_size,
                'source':'data/locale-fonts.json; OFL Noto derivatives'}
        assets_path.write_text(json.dumps(assets,indent=2)+'\n',encoding='utf8',newline='\n')
    recipe=json.loads(recipe_path.read_text(encoding='utf8'))
    for entry in recipe['derivatives'].values():
        assert digest(ROOT/'media'/entry['file'])==entry['sha256'],entry['file']
    # All CJK faces must cover mixed addon/game scripts and every selectable autonym.
    mixed=set().union(*needed.values())
    for code in needed:
        names=(f'FieldKitSans-{code}.ttf',) if code in ('zh','ja','ko') else ('FieldKitLatin.ttf','FieldKitSerif.ttf')
        for filename in names:
            points=mixed if code in ('zh','ja','ko') else needed[code]
            font=TTFont(ROOT/'media'/filename)
            assert not points-set(font.getBestCmap()),(code,filename,sorted(points-set(font.getBestCmap())))
    print('PASS bundled glyph coverage: 14 UI languages, autonyms and mixed scripts; hash-pinned OFL derivatives')

if __name__=='__main__':main()
