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

    def tearDown(self):
        self.directory.cleanup()

    def track(self, name, directory=None):
        target = (directory or self.root) / name
        shutil.copy2(self.flac if target.suffix.lower() == ".flac" else self.aiff, target)
        return target

    def convert(self):
        return subprocess.run(
            ["cmd.exe", "/d", "/c", str(self.launcher)], cwd=self.root,
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

    def test_empty_folder_ignores_other_files_and_subfolders(self):
        child = self.root / "subfolder"
        child.mkdir()
        self.track("nested.aiff", directory=child)
        (self.root / "notes.txt").write_text("not audio")
        self.convert()
        self.assertEqual(list((self.root / "wav").glob("*.wav")), [])

    def test_corrupt_aiff_does_not_stop_other_files(self):
        (self.root / "bad.aif").write_bytes(b"not AIFF")
        self.track("good.aiff")
        self.convert()
        with wave.open(str(self.root / "wav" / "good.wav")) as audio:
            self.assertEqual(audio.getnframes(), 4800)
        self.assertEqual((self.root / "bad.aif").read_bytes(), b"not AIFF")


if __name__ == "__main__":
    unittest.main()
