"""Read-only static audit: FieldKit runtime vs an installed Reborn client.

Cross-references every AZS_* symbol FieldKit touches with what the installed
game Lua actually defines (functions AND data globals), and collects per-module
structural metrics (events, OnUpdate handlers, frame/texture creation sites,
protected vs unprotected native calls, Lua 5.0 hazards).

Static evidence only: a reference is not proof that a branch runs in game.
No client file is modified; output goes to build/fieldkit_074_audit.json.
Usage: python tools/audit_fieldkit_074.py --game "<game root>"
"""
from pathlib import Path
import argparse, json, re

BASE = Path(__file__).resolve().parents[1]
RUNTIME = BASE / 'AzerothFieldKitReborn'
GAME_FOLDERS = ('AzerothSurvivorsAPI', 'AzerothSurvivors', 'AzerothSurvivorsUI', '!AzerothSurvivorsCompat')

DEF_FUNC = re.compile(r'(?:^|[^.\w])function\s+(AZS_\w+)\s*\(|(?:^|[^.\w])(AZS_\w+)\s*=\s*function\b')
DEF_DATA = re.compile(r'^\s*(AZS_\w+)\s*=(?!=)')
DEF_FIELD = re.compile(r'^\s*(AZS_\w+)\.(\w+)\s*=(?!=)')
SYMBOL = re.compile(r'\bAZS_\w+')
CALL = re.compile(r'\b(AZS_\w+)\s*\(')
PCALL = re.compile(r'pcall\(\s*(AZS_\w+)')
EVENT = re.compile(r'RegisterEvent\(\s*"([A-Z0-9_]+)"')
UNREG = re.compile(r'UnregisterEvent\(\s*"([A-Z0-9_]+)"')
ONUPDATE = re.compile(r'SetScript\(\s*"OnUpdate"')
CREATEFRAME = re.compile(r'\bCreateFrame\(')
CREATETEX = re.compile(r'(?::|\.)CreateTexture\(|(?::|\.)CreateFontString\(')


def strip_comment(line):
    # Good enough for metrics: drop "--" outside of strings.
    out, quote = [], None
    i = 0
    while i < len(line):
        c = line[i]
        if quote:
            out.append(c)
            if c == '\\':
                out.append(line[i + 1:i + 2]); i += 2; continue
            if c == quote: quote = None
        else:
            if c in '"\'': quote = c
            elif line.startswith('--', i): break
            out.append(c)
        i += 1
    return ''.join(out)


def scan_game(addons):
    funcs, data, fields, hdr = {}, {}, {}, {}
    files = 0
    for folder in GAME_FOLDERS:
        root = addons / folder
        if not root.exists():
            continue
        for path in sorted(root.rglob('*.lua')):
            files += 1
            rel = path.relative_to(addons).as_posix()
            for n, raw in enumerate(path.read_text(encoding='utf8', errors='replace').splitlines(), 1):
                line = strip_comment(raw)
                for m in DEF_FUNC.finditer(line):
                    funcs.setdefault(m[1] or m[2], []).append(f'{rel}:{n}')
                m = DEF_DATA.match(line)
                if m and not DEF_FUNC.search(line):
                    data.setdefault(m[1], []).append(f'{rel}:{n}')
                # Api.lua assigns stamps and list tables by name: Stamp("AZS_X_UPDATED"),
                # LISTS = { AZSMETER = { "AZS_METER", ... } } then _G[global .. "_UPDATED"].
                for lit in re.findall(r'"(AZS_[A-Z][A-Z0-9_]*)"', line):
                    data.setdefault(lit, []).append(f'{rel}:{n} (by name)')
                    if '.. "_UPDATED"' in path.read_text(encoding='utf8', errors='replace') and not lit.endswith('_UPDATED'):
                        data.setdefault(lit + '_UPDATED', []).append(f'{rel}:{n} (dynamic stamp)')
                m = DEF_FIELD.match(line)
                if m:
                    fields.setdefault(m[1], set()).add(m[2])
                if raw.lstrip().startswith('--'):
                    for s in SYMBOL.findall(raw):
                        hdr.setdefault(s, f'{rel}:{n}')
    return funcs, data, {k: sorted(v) for k, v in fields.items()}, hdr, files


def scan_fieldkit():
    toc = (RUNTIME / 'AzerothFieldKitReborn.toc').read_text(encoding='utf8').splitlines()
    modules = [s for s in toc if s.endswith('.lua')]
    refs, per = {}, {}
    for name in modules:
        text = (RUNTIME / name).read_text(encoding='utf8')
        m = {'lines': 0, 'events': [], 'unregistered': [], 'onUpdate': 0, 'createFrame': 0,
             'createTextureOrFont': 0, 'azsCalls': 0, 'azsPcalls': 0, 'azsSymbols': set(),
             'luaHazards': [], 'globalsDefined': set()}
        for n, raw in enumerate(text.splitlines(), 1):
            m['lines'] += 1
            line = strip_comment(raw)
            for s in SYMBOL.findall(line):
                refs.setdefault(s, []).append(f'{name}:{n}')
                m['azsSymbols'].add(s)
            m['azsCalls'] += len(CALL.findall(line))
            m['azsPcalls'] += len(PCALL.findall(line))
            m['events'] += EVENT.findall(line)
            m['unregistered'] += UNREG.findall(line)
            m['onUpdate'] += len(ONUPDATE.findall(line))
            m['createFrame'] += len(CREATEFRAME.findall(line))
            m['createTextureOrFont'] += len(CREATETEX.findall(line))
            if 'string.match' in line or 'gmatch' in line:
                m['luaHazards'].append(f'{n}:string.match/gmatch')
            if re.search(r'(?<![\w"\'])#\s*[A-Za-z_(]', line):
                m['luaHazards'].append(f'{n}:# length operator (Lua 5.1+)')
            if re.search(r'\bselect\s*\(', line):
                m['luaHazards'].append(f'{n}:select() (Lua 5.1+)')
            g = re.match(r'^([A-Z][A-Za-z0-9_]*)\s*=', line)
            if g:
                m['globalsDefined'].add(g[1])
        m['azsSymbols'] = sorted(m['azsSymbols'])
        m['globalsDefined'] = sorted(m['globalsDefined'])
        m['events'] = sorted(set(m['events']))
        m['unregistered'] = sorted(set(m['unregistered']))
        per[name] = m
    return modules, refs, per


def test_coverage(per):
    """Map module global tables to the test files that mention them."""
    tests = {p.name: p.read_text(encoding='utf8', errors='replace') for p in (BASE / 'tests').glob('*.lua')}
    runner = (BASE / 'tools/test_reborn.py').read_text(encoding='utf8') + (BASE / 'tools/verify.py').read_text(encoding='utf8')
    executed = {t for t in tests if t in runner}
    out = {}
    for name, m in per.items():
        hits = set()
        for g in m['globalsDefined']:
            if len(g) < 6:
                continue
            for t, body in tests.items():
                if re.search(r'\b' + re.escape(g) + r'\b', body):
                    hits.add(t)
        out[name] = {'tests': sorted(hits), 'executedTests': sorted(hits & executed)}
    return out, sorted(set(tests) - executed)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--game', type=Path, required=True)
    a = p.parse_args()
    addons = a.game / 'Interface/AddOns'
    funcs, data, fields, headers, files = scan_game(addons)
    modules, refs, per = scan_fieldkit()
    symbols = []
    for s in sorted(refs):
        if s in funcs:
            status = 'function'
        elif s in data:
            status = 'data'
        elif s in fields or s in headers:
            status = 'documented-in-header'
        else:
            status = 'not-defined-in-installed-lua'
        users = sorted({r.split(':')[0] for r in refs[s]})
        symbols.append({'name': s, 'installed': status, 'definedAt': (funcs.get(s) or data.get(s) or [])[:3],
                        'fields': fields.get(s, [])[:40], 'fieldkitModules': users, 'referenceCount': len(refs[s])})
    unused = sorted(set(funcs) - set(refs))
    unused_data = sorted(set(data) - set(refs) - set(funcs))
    cov, unexecuted = test_coverage(per)
    report = {'scope': 'TOC runtime modules vs installed game Lua (' + ', '.join(GAME_FOLDERS) + '). Static only.',
              'installedLuaFiles': files, 'fieldkitModules': len(modules),
              'symbols': symbols, 'installedFunctionsUnusedByFieldKit': unused,
              'installedDataUnusedByFieldKit': unused_data,
              'modules': {k: dict(v, **cov[k]) for k, v in per.items()},
              'testFilesNotExecutedByRunners': unexecuted}
    out = BASE / 'build'
    out.mkdir(exist_ok=True)
    (out / 'fieldkit_074_audit.json').write_text(json.dumps(report, indent=1, ensure_ascii=False) + '\n', encoding='utf8')
    missing = [s['name'] for s in symbols if s['installed'] == 'not-defined-in-installed-lua']
    print(json.dumps({'installedLuaFiles': files, 'referenced': len(symbols), 'notDefined': len(missing),
                      'unusedInstalledFunctions': len(unused), 'unusedInstalledData': len(unused_data),
                      'testFilesNotExecuted': unexecuted}))
    print('Referenced but not defined in installed Lua:', missing)


if __name__ == '__main__':
    main()
