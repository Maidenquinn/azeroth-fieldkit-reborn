"""Reject actual model unknown markers while retaining legitimate punctuation."""
import importlib.util
from pathlib import Path
import unittest

spec=importlib.util.spec_from_file_location('build_locales',Path(__file__).resolve().parents[1]/'tools/build_locales.py')
compiler=importlib.util.module_from_spec(spec);spec.loader.exec_module(compiler)

class LocaleTokens(unittest.TestCase):
    def test_unknown_markers_are_rejected(self):
        for marker in ('\u2047','\ufffd','<unk>'):
            with self.subTest(marker=marker), self.assertRaisesRegex(AssertionError,'unknown translation token'):
                compiler.check_unknown_tokens('zh','Pin','固定 '+marker)

    def test_real_punctuation_and_scripts_are_retained(self):
        for text in ('法术 %d–%d / %d','미리보기 — 예시 데이터','Прозрачность: %d%%','What?','Friz Quadrata'):
            compiler.check_unknown_tokens('test','label',text)

if __name__=='__main__': unittest.main()
