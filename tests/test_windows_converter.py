"""Real cmd.exe + FFmpeg checks, using only generated audio."""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import wave

SCRIPT = Path(__file__).resolve().parents[1] / "convert_flac_to_wav.bat"
FFMPEG = shutil.which("ffmpeg")


@unittest.skipUnless(os.name == "nt" and FFMPEG, "Requires Windows and FFmpeg")
class WindowsConverterTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fixtures = tempfile.TemporaryDirectory()
        cls.flac = Path(cls.fixtures.name) / "source.flac"
        cls.aiff = Path(cls.fixtures.name) / "source.aiff"
        subprocess.run([
            FFMPEG, "-hide_banner", "-loglevel", "error", "-f", "lavfi",
            "-i", "sine=frequency=440:duration=0.1:sample_rate=48000",
            "-ac", "2", "-c:a", "flac", str(cls.flac),
        ], check=True)
        subprocess.run([
            FFMPEG, "-hide_banner", "-loglevel", "error", "-i", str(cls.flac),
            "-c:a", "pcm_s24be", str(cls.aiff),
        ], check=True)

    @classmethod
    def tearDownClass(cls):
        cls.fixtures.cleanup()

    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="AIFF test ")
        self.root = Path(self.directory.name)
        self.launcher = self.root / SCRIPT.name
        shutil.copy2(SCRIPT, self.launcher)
        shutil.copy2(SCRIPT.parent / 'Convert-AudioTree.ps1', self.root / 'Convert-AudioTree.ps1')

    def tearDown(self):
        self.directory.cleanup()

    def track(self, name, directory=None):
        target = (directory or self.root) / name
        shutil.copy2(self.flac if target.suffix.lower() == ".flac" else self.aiff, target)
        return target

    def convert(self, folder=None):
        command = f'"{os.environ["COMSPEC"]}" /d /s /c ""{self.launcher}"'
        if folder is not None:
            command += f' "{folder}"'
        command += '"'
        return subprocess.run(
            command, cwd=self.root,
            input="n\nn\nn\n\n", stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            encoding="utf-8", errors="replace", timeout=40,
        )

    def test_mixed_formats_case_names_and_source_integrity(self):
        names = ["original.flac", "short.aif", "Кириллица & [mix] (live).AIFF", "mixed.AiFf"]
        sources = [self.track(name) for name in names]
        before = {p: hashlib.sha256(p.read_bytes()).digest() for p in sources}
        result = self.convert()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(list((self.root / "wav").glob("*.wav"))), 4)
        for source in sources:
            self.assertEqual(hashlib.sha256(source.read_bytes()).digest(), before[source])
            with wave.open(str(self.root / "wav" / (source.stem + ".wav"))) as audio:
                self.assertEqual((audio.getsampwidth(), audio.getframerate(), audio.getnchannels(), audio.getnframes()), (2, 48000, 2, 4800))

    def test_existing_wav_can_be_kept(self):
        self.track("track.aiff")
        (self.root / "wav").mkdir()
        target = self.root / "wav" / "track.wav"
        target.write_bytes(b"existing output must stay")
        self.convert()
        self.assertEqual(target.read_bytes(), b"existing output must stay")

    def test_empty_folder_ignores_other_files(self):
        (self.root / "notes.txt").write_text("not audio")
        self.convert()
        self.assertEqual(list((self.root / "wav").glob("*.wav")), [])

    def test_soulseek_tree_and_dragged_folder(self):
        music = self.root / 'Soulseek downloads'
        folders = [music / 'Пользователь [1]' / 'Album A', music / 'Пользователь [1]' / 'Album B', music / 'User & (2) !' / 'Album C']
        sources = []
        for folder, name in zip(folders, ['01.flac', '01.aiff', '01.AIF']):
            folder.mkdir(parents=True)
            sources.append(self.track(name, directory=folder))
        originals = {path: path.read_bytes() for path in sources}
        result = self.convert(music)
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        self.assertIn('Converted: 3 | Skipped: 0 | Failed: 0', result.stdout)
        outputs = []
        for source in sources:
            target = (music / 'wav' / source.relative_to(music)).with_suffix('.wav')
            outputs.append(target)
            self.assertEqual(source.read_bytes(), originals[source])
            with wave.open(str(target)) as audio:
                self.assertEqual(audio.getnframes(), 4800)
        before = {path: path.read_bytes() for path in outputs}
        again = self.convert(music)
        self.assertEqual(again.returncode, 0, again.stderr + again.stdout)
        self.assertIn('Converted: 0 | Skipped: 3 | Failed: 0', again.stdout)
        self.assertTrue(all(path.read_bytes() == data for path, data in before.items()))

    def test_output_tree_is_not_scanned(self):
        self.track('original.flac')
        output = self.root / 'wav'
        output.mkdir()
        self.track('ignore.aiff', directory=output)
        result = self.convert()
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        self.assertIn('Converted: 1 | Skipped: 0 | Failed: 0', result.stdout)
        self.assertFalse((output / 'wav').exists())

    def test_directory_junction_loop_is_not_followed(self):
        self.track('original.flac')
        link = self.root / 'loop'
        command = f'"{os.environ["COMSPEC"]}" /d /s /c mklink /J "{link}" "{self.root}"'
        created = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if created.returncode != 0:
            self.skipTest('This machine does not allow directory junctions')
        result = self.convert()
        self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
        self.assertIn('Converted: 1 | Skipped: 0 | Failed: 0', result.stdout)
        self.assertFalse((self.root / 'wav' / 'loop').exists())

    def test_corrupt_aiff_does_not_stop_other_files(self):
        (self.root / "bad.aif").write_bytes(b"not AIFF")
        self.track("good.aiff")
        self.convert()
        with wave.open(str(self.root / "wav" / "good.wav")) as audio:
            self.assertEqual(audio.getnframes(), 4800)
        self.assertEqual((self.root / "bad.aif").read_bytes(), b"not AIFF")


if __name__ == "__main__":
    unittest.main()
