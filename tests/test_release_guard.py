"""Release gate fixtures: temporary repository copies only, no network."""
from pathlib import Path
import json, shutil, sys, tempfile, unittest

BASE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE / 'tools'))
import release_guard as guard  # noqa: E402


class ReleaseGuard(unittest.TestCase):
    def repo(self, version='0.1.0-reborn.40', approved=True, prerelease=False, notes='# Azeroth FieldKit Reborn .40 — Test\n\nBody\n',
             toc_version=None, runtime_version=None):
        root = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, root)
        (root / 'data').mkdir()
        (root / 'docs').mkdir()
        (root / 'AzerothFieldKitReborn').mkdir()
        (root / 'data/publication-status.json').write_text(json.dumps(
            {'version': version, 'maintainerAcceptedForPublication': approved, 'githubPrerelease': prerelease}), encoding='utf8')
        (root / 'AzerothFieldKitReborn/AzerothFieldKitReborn.toc').write_text(
            f'## Interface: 11200\n## Version: {toc_version or version}\nRuntime.lua\n', encoding='utf8')
        (root / 'AzerothFieldKitReborn/Runtime.lua').write_text(
            f'FieldKit = {{ version = "{runtime_version or version}", folder = "AzerothFieldKitReborn" }}\n', encoding='utf8')
        if notes is not None:
            (root / f'docs/RELEASE_REBORN_{version.rsplit(".", 1)[1]}.md').write_text(notes, encoding='utf8')
        return root

    def test_approved_release(self):
        r = guard.evaluate(self.repo())
        self.assertTrue(r['approved'])
        self.assertEqual(r['tag'], 'v0.1.0-reborn.40')
        self.assertEqual(r['title'], 'Azeroth FieldKit Reborn .40 — Test')
        self.assertEqual(r['notes'], 'docs/RELEASE_REBORN_40.md')
        self.assertFalse(r['prerelease'])

    def test_prerelease_channel(self):
        self.assertTrue(guard.evaluate(self.repo(prerelease=True))['prerelease'])

    def test_not_approved_publishes_nothing_and_needs_no_notes(self):
        r = guard.evaluate(self.repo(approved=False, notes=None))
        self.assertFalse(r['approved'])

    def test_rejects_version_drift(self):
        with self.assertRaises(guard.GuardError):
            guard.evaluate(self.repo(toc_version='0.1.0-reborn.39'))
        with self.assertRaises(guard.GuardError):
            guard.evaluate(self.repo(runtime_version='0.1.0-reborn.39'))

    def test_rejects_requested_mismatch(self):
        with self.assertRaises(guard.GuardError):
            guard.evaluate(self.repo(), expect='0.1.0-reborn.39')
        self.assertTrue(guard.evaluate(self.repo(), expect='0.1.0-reborn.40')['approved'])

    def test_rejects_missing_or_untitled_notes(self):
        with self.assertRaises(guard.GuardError):
            guard.evaluate(self.repo(notes=None))
        with self.assertRaises(guard.GuardError):
            guard.evaluate(self.repo(notes='no title\n'))

    def test_rejects_bad_version_format(self):
        with self.assertRaises(guard.GuardError):
            guard.evaluate(self.repo(version='0.1.0-reborn.40; rm -rf x', notes=None))

    def test_current_repository_is_consistent(self):
        # Whatever this checkout carries must at least be internally consistent.
        r = guard.evaluate(BASE)
        self.assertTrue(r['version'].startswith('0.1.0-reborn.'))


if __name__ == '__main__':
    unittest.main()
