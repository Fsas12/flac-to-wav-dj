"""One real Windows download; subsequent checks reuse the isolated private cache."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import wave

ROOT = Path(__file__).resolve().parents[1]
FFMPEG = shutil.which('ffmpeg')


@unittest.skipUnless(os.name == 'nt' and FFMPEG, 'Requires Windows and test-fixture FFmpeg')
class WindowsSetupTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory(prefix='WAV installer test ')
        cls.root = Path(cls.temporary.name)
        cls.cache = cls.root / 'local' / 'FLAC-to-WAV-DJ' / 'ffmpeg'
        cls.install_command = [
            'powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass',
            '-File', str(ROOT / 'Install-FFmpeg.ps1'), '-NonInteractive',
            '-InstallDirectory', str(cls.cache),
        ]
        cls.installation = subprocess.run(cls.install_command, stdout=subprocess.PIPE,
                                          stderr=subprocess.PIPE, text=True, timeout=600)

    @classmethod
    def tearDownClass(cls):
        cls.temporary.cleanup()

    def test_download_checksum_extraction_and_cached_relaunch(self):
        self.assertEqual(self.installation.returncode, 0, self.installation.stderr)
        binary = self.cache / 'ffmpeg.exe'
        self.assertTrue(binary.is_file())
        version = subprocess.run([str(binary), '-version'], stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE, text=True, timeout=15)
        self.assertEqual(version.returncode, 0, version.stderr)
        self.assertIn('ffmpeg version', version.stdout)
        self.assertIn('SHA256:', (self.cache / 'SOURCE.txt').read_text(encoding='utf-8-sig'))
        stamp = binary.stat().st_mtime_ns
        again = subprocess.run(self.install_command, stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE, text=True, timeout=30)
        self.assertEqual(again.returncode, 0, again.stderr)
        self.assertEqual(binary.stat().st_mtime_ns, stamp)

    def test_bat_uses_private_install_without_path_or_powershell_conversion(self):
        self.assertEqual(self.installation.returncode, 0, self.installation.stderr)
        music = self.root / 'music'
        music.mkdir(exist_ok=True)
        launcher = music / 'convert_flac_to_wav.bat'
        shutil.copy2(ROOT / launcher.name, launcher)
        subprocess.run([
            FFMPEG, '-hide_banner', '-loglevel', 'error', '-f', 'lavfi',
            '-i', 'sine=frequency=440:duration=0.1:sample_rate=48000',
            '-c:a', 'pcm_s24be', str(music / 'track.aiff'),
        ], check=True)
        environment = dict(os.environ)
        environment['LOCALAPPDATA'] = str(self.root / 'local')
        environment['PATH'] = str(Path(os.environ['SystemRoot']) / 'System32')
        result = subprocess.run([
            str(Path(os.environ['SystemRoot']) / 'System32' / 'cmd.exe'),
            '/d', '/c', str(launcher),
        ], cwd=self.root, env=environment, input='\n', stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, encoding='utf-8', errors='replace', timeout=30)
        self.assertEqual(result.returncode, 0, result.stderr)
        with wave.open(str(music / 'wav' / 'track.wav')) as audio:
            self.assertEqual((audio.getsampwidth(), audio.getframerate(), audio.getnframes()), (2, 48000, 4800))


if __name__ == '__main__':
    unittest.main()
