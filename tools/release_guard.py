"""Release gate shared by the publish workflow and local dry runs.

Derives the one version being released from data/publication-status.json and
refuses anything inconsistent: TOC and Runtime.lua must carry the same version,
the release notes file must exist, and an explicitly requested version must
match. Prints KEY=VALUE lines for $GITHUB_OUTPUT. No network, no writes.

Exit codes: 0 = publish, 3 = not approved for publication (nothing to do),
anything else = inconsistent repository (fail the workflow).
Usage: python tools/release_guard.py [--expect 0.1.0-reborn.39]
"""
from pathlib import Path
import argparse, json, re, sys

BASE = Path(__file__).resolve().parents[1]
NOT_APPROVED = 3


class GuardError(Exception):
    pass


def evaluate(base=BASE, expect=None):
    status = json.loads((base / 'data/publication-status.json').read_text(encoding='utf8'))
    version = status.get('version')
    if not isinstance(version, str) or not re.fullmatch(r'0\.1\.0-reborn\.\d+', version):
        raise GuardError(f'unexpected version format: {version!r}')
    if expect is not None and expect != version:
        raise GuardError(f'requested {expect} but publication-status.json says {version}')
    toc = (base / 'AzerothFieldKitReborn/AzerothFieldKitReborn.toc').read_text(encoding='utf8')
    runtime = (base / 'AzerothFieldKitReborn/Runtime.lua').read_text(encoding='utf8')
    if f'## Version: {version}' not in toc.splitlines():
        raise GuardError(f'TOC version differs from {version}')
    if f'version = "{version}"' not in runtime:
        raise GuardError(f'Runtime.lua version differs from {version}')
    number = version.rsplit('.', 1)[1]
    notes = base / f'docs/RELEASE_REBORN_{number}.md'
    approved = status.get('maintainerAcceptedForPublication') is True
    result = {'version': version, 'tag': 'v' + version, 'approved': approved,
              'prerelease': status.get('githubPrerelease') is True,
              'notes': notes.relative_to(base).as_posix(), 'title': None}
    if not approved:
        return result
    if status.get('githubPrerelease') not in (True, False):
        raise GuardError('githubPrerelease must be true or false for an approved release')
    if not notes.is_file():
        raise GuardError(f'missing release notes {result["notes"]}')
    first = notes.read_text(encoding='utf8').splitlines()[0] if notes.stat().st_size else ''
    if not first.startswith('# ') or len(first) < 6:
        raise GuardError(f'{result["notes"]} must start with a "# Title" line')
    result['title'] = first[2:].strip()
    return result


def main(argv=None):
    p = argparse.ArgumentParser()
    p.add_argument('--expect', help='version the operator intends to publish')
    a = p.parse_args(argv)
    try:
        r = evaluate(expect=a.expect or None)
    except GuardError as e:
        print(f'release guard: {e}', file=sys.stderr)
        return 1
    for key in ('version', 'tag', 'notes', 'title'):
        print(f'{key}={r[key] or ""}')
    print(f'prerelease={"true" if r["prerelease"] else "false"}')
    print(f'approved={"true" if r["approved"] else "false"}')
    if not r['approved']:
        print(f'release guard: {r["version"]} is not accepted for publication; nothing to publish.', file=sys.stderr)
        return NOT_APPROVED
    return 0


if __name__ == '__main__':
    sys.exit(main())
