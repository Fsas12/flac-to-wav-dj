"""Keep the standalone Finder bundle in sync with the shared converter."""
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
BUNDLE = ROOT / 'FLAC to WAV DJ.app' / 'Contents'


class AppBundleTests(unittest.TestCase):
    def test_plist_and_executable(self):
        with (BUNDLE / 'Info.plist').open('rb') as stream:
            info = plistlib.load(stream)
        executable = BUNDLE / 'MacOS' / info['CFBundleExecutable']
        self.assertTrue(executable.is_file())
        self.assertEqual(info['CFBundlePackageType'], 'APPL')
        self.assertIn('choose folder', executable.read_text())

    def test_embedded_converter_matches_standalone(self):
        self.assertEqual(
            (BUNDLE / 'Resources' / 'convert_flac_to_wav.command').read_bytes(),
            (ROOT / 'convert_flac_to_wav.command').read_bytes(),
        )

    @unittest.skipUnless(Path('/bin/bash').is_file(), 'Requires Bash')
    def test_finder_launcher_shell_syntax(self):
        subprocess.run(['/bin/bash', '-n', str(BUNDLE / 'MacOS' / 'launch')], check=True)

    @unittest.skipUnless(shutil.which('osacompile'), 'Requires AppleScript compiler')
    def test_dialog_applescript_syntax(self):
        source = (BUNDLE / 'MacOS' / 'launch').read_text()
        scripts = re.findall(r"<<'APPLESCRIPT'\n(.*?)\nAPPLESCRIPT", source, re.S)
        self.assertEqual(len(scripts), 2)
        with tempfile.TemporaryDirectory() as directory:
            for index, script in enumerate(scripts):
                result = subprocess.run(['osacompile', '-o', str(Path(directory) / f'{index}.scpt')],
                                        input=script, text=True, stdout=subprocess.PIPE,
                                        stderr=subprocess.PIPE, timeout=30)
                self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == '__main__':
    unittest.main()
