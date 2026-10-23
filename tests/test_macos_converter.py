"""Integration tests: real FFmpeg and synthetic audio, no music-library fixtures."""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import wave


SCRIPT = Path(__file__).resolve().parents[1] / "convert_flac_to_wav.command"
FFMPEG = shutil.which("ffmpeg")


@unittest.skipUnless(FFMPEG, "FFmpeg is required for these integration tests")
class MacConverterTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.fixture_dir = tempfile.TemporaryDirectory()
        cls.fixture = Path(cls.fixture_dir.name) / "source.flac"
        subprocess.run([
            FFMPEG, "-hide_banner", "-loglevel", "error", "-f", "lavfi",
            "-i", "sine=frequency=440:duration=0.1:sample_rate=48000",
            "-ac", "2", "-c:a", "flac", "-sample_fmt", "s32", str(cls.fixture),
        ], check=True)

    @classmethod
    def tearDownClass(cls):
        cls.fixture_dir.cleanup()

    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="FLAC test Кириллица ")
        self.root = Path(self.directory.name)
        self.launcher = self.root / SCRIPT.name
        shutil.copy2(SCRIPT, self.launcher)

    def tearDown(self):
        self.directory.cleanup()

    def track(self, name="track.flac", directory=None):
        path = (directory or self.root) / name
        shutil.copy2(self.fixture, path)
        return path

    def run_converter(self, *args, env=None):
        return subprocess.run(
            ["/bin/bash", str(self.launcher), *map(str, args)], cwd="/",
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            text=True, env=env, timeout=30,
        )

    def test_audio_names_and_source_integrity(self):
        names = ["normal.flac", "Кириллица & $cash [mix] 'quote'.FLAC", "-leading.flac"]
        sources = [self.track(name) for name in names]
        hashes = [hashlib.sha256(path.read_bytes()).digest() for path in sources]
        result = self.run_converter()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Converted: 3 | Skipped: 0 | Failed: 0", result.stdout)
        for source, digest in zip(sources, hashes):
            self.assertEqual(hashlib.sha256(source.read_bytes()).digest(), digest)
            with wave.open(str(self.root / "wav" / (source.stem + ".wav"))) as audio:
                self.assertEqual((audio.getsampwidth(), audio.getframerate(), audio.getnchannels()), (2, 48000, 2))
                self.assertEqual(audio.getnframes(), 4800)

    def test_repeat_run_preserves_existing_wav_bytes(self):
        self.track()
        first = self.run_converter()
        self.assertEqual(first.returncode, 0, first.stderr)
        target = self.root / "wav" / "track.wav"
        original = target.read_bytes()
        second = self.run_converter()
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertIn("Converted: 0 | Skipped: 1 | Failed: 0", second.stdout)
        self.assertEqual(target.read_bytes(), original)

    def test_damaged_input_does_not_publish_partial_wav(self):
        (self.root / "bad.flac").write_bytes(b"not FLAC")
        self.track("good.flac")
        result = self.run_converter()
        self.assertEqual(result.returncode, 1)
        self.assertIn("Converted: 1 | Skipped: 0 | Failed: 1", result.stdout)
        self.assertTrue((self.root / "wav" / "good.wav").is_file())
        self.assertFalse((self.root / "wav" / "bad.wav").exists())
        self.assertEqual(list((self.root / "wav").glob(".flac-to-wav.*")), [])

    def test_empty_folder_and_subfolders_are_not_scanned(self):
        child = self.root / "subfolder"
        child.mkdir()
        self.track(directory=child)
        result = self.run_converter()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("No FLAC files found", result.stdout)
        self.assertFalse((self.root / "wav").exists())

    def test_optional_input_folder(self):
        folder = self.root / "another folder"
        folder.mkdir()
        self.track(directory=folder)
        result = self.run_converter(folder)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((folder / "wav" / "track.wav").is_file())
        self.assertFalse((self.root / "wav").exists())

    def test_broken_output_symlink_is_not_replaced(self):
        self.track()
        (self.root / "wav").mkdir()
        target = self.root / "wav" / "track.wav"
        target.symlink_to(self.root / "missing.wav")
        result = self.run_converter()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Skipped: 1", result.stdout)
        self.assertTrue(target.is_symlink())

    def test_missing_dependency_has_actionable_message(self):
        if any(Path(path).exists() for path in ["/opt/homebrew/bin/ffmpeg", "/usr/local/bin/ffmpeg"]):
            self.skipTest("Homebrew fallback is installed on this host")
        self.track()
        result = self.run_converter(env={**os.environ, "PATH": ""})
        self.assertEqual(result.returncode, 2)
        self.assertIn("brew install ffmpeg", result.stdout)
        self.assertFalse((self.root / "wav").exists())

    def test_invalid_input_folder(self):
        result = self.run_converter(self.root / "missing")
        self.assertEqual(result.returncode, 2)
        self.assertIn("Cannot open the input folder", result.stderr)

    def test_local_ffmpeg_executable_is_found(self):
        self.track()
        local = self.root / "ffmpeg"
        # A local symlink exercises executable discovery without copying a binary.
        local.symlink_to(FFMPEG)
        result = self.run_converter()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.root / "wav" / "track.wav").is_file())

    def test_output_folder_blocked_by_existing_file(self):
        self.track()
        (self.root / "wav").write_bytes(b"keep me")
        result = self.run_converter()
        self.assertEqual(result.returncode, 2)
        self.assertEqual((self.root / "wav").read_bytes(), b"keep me")

    def test_concurrent_runs_do_not_replace_output(self):
        self.track()
        processes = [subprocess.Popen(
            ["/bin/bash", str(self.launcher)], cwd="/", stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        ) for _ in range(2)]
        outputs = [process.communicate(timeout=30) for process in processes]
        for process, (out, err) in zip(processes, outputs):
            self.assertEqual(process.returncode, 0, out + err)
        self.assertEqual(sum("Converted: 1" in out for out, _ in outputs), 1)
        self.assertEqual(sum("Skipped: 1" in out for out, _ in outputs), 1)
        self.assertEqual(list((self.root / "wav").glob(".flac-to-wav.*")), [])
        with wave.open(str(self.root / "wav" / "track.wav")) as audio:
            self.assertEqual(audio.getnframes(), 4800)


if __name__ == "__main__":
    unittest.main()
