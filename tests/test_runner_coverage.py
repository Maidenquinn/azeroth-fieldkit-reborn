"""QA-01 guard: every Lua fixture must be executed by a runner the CI calls.

A fixture referenced by no runner silently stops protecting anything (three
meter / timeline suites ran nowhere before QA-01). Helpers are listed explicitly.
"""
from pathlib import Path
import re, unittest

BASE = Path(__file__).resolve().parents[1]
HELPERS = {'mock.lua', 'snapshot.lua', 'native50.lua'}
RUNNERS = ['tools/test_reborn.py', 'tools/verify.py', 'tests/native50.lua']


class RunnerCoverage(unittest.TestCase):
    def test_every_fixture_has_a_runner(self):
        text = '\n'.join((BASE / r).read_text(encoding='utf8') for r in RUNNERS)
        orphans = [p.name for p in sorted((BASE / 'tests').glob('*.lua'))
                   if p.name not in HELPERS and not re.search(r'\b' + re.escape(p.name) + r'\b', text)]
        self.assertEqual(orphans, [], 'fixtures executed by no runner')

    def test_ci_runs_native_lua50(self):
        ci = (BASE / '.github/workflows/verify.yml').read_text(encoding='utf8')
        self.assertIn('verify.py --lua50', ci)
        self.assertIn('1193a61b0e08acaa6eee0eecf29709179ee49c71baebc59b682a25c3b5a45671', ci)

    def test_native50_reads_the_toc(self):
        harness = (BASE / 'tests/native50.lua').read_text(encoding='utf8')
        self.assertIn('io.lines("AzerothFieldKitReborn/AzerothFieldKitReborn.toc")', harness)
        self.assertNotRegex(harness, r'local files=\{"', 'hard-coded module list is back')


if __name__ == '__main__':
    unittest.main()
