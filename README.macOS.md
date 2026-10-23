# FLAC → WAV on macOS / для macOS

[Download ZIP](https://github.com/Fsas12/flac-to-wav-dj/archive/refs/heads/main.zip) · [Windows / English](README.md) · [Windows / Русский](README.ru.md)

## Русская инструкция

Небольшой скрипт для запуска двойным кликом: FLAC лежат рядом с ним, готовые WAV появляются в папке `wav`. Нужен отдельно установленный FFmpeg. Скрипт рассчитан на штатный `/bin/bash` macOS и ищет FFmpeg в PATH, рядом с собой и в стандартных папках Homebrew для Apple Silicon и Intel.

### Один раз: подготовка

1. Скачай ZIP по ссылке выше и распакуй его. Открой папку с `convert_flac_to_wav.command`.
2. Если FFmpeg ещё не установлен и у тебя есть Homebrew, открой Terminal и выполни:

   ```sh
   brew install ffmpeg
   ```

   Если Homebrew нет, установи его по инструкции на [brew.sh](https://brew.sh), включая шаги после установки, а затем выполни команду выше. Если твоя версия macOS не поддерживается текущим Homebrew, используй совместимую с ней сборку FFmpeg из [вариантов на сайте FFmpeg](https://ffmpeg.org/download.html#build-mac) и положи исполняемый файл `ffmpeg` рядом со скриптом. Бинарный FFmpeg в ZIP не включён.

### Каждый раз: конвертация

1. Скопируй FLAC-треки непосредственно в папку с `convert_flac_to_wav.command`.
2. Дважды кликни `convert_flac_to_wav.command`. Откроется окно Terminal с ходом обработки.
3. Забери результат из подпапки `wav`. В конце будет количество готовых, пропущенных и ошибочных файлов.

Исходные FLAC остаются без изменений. Существующие выходные WAV пропускаются. При ошибке одного трека скрипт продолжает обработку остальных; незавершённый временный WAV удаляется, если скрипт может выполнить очистку. После принудительного завершения процесса временный файл может остаться скрытым в `wav`.

**Звук:** PCM WAV 16 бит, без явного изменения частоты и количества каналов. Для 24-битного FLAC это означает снижение разрядности. Выбора 24 бит в этой версии нет. Вложенные папки не сканируются; CSV-логов нет. Скрипт не загружает аудио в интернет и не устанавливает программы автоматически.

Проверь 1–2 результата в своём DJ-софте и на нужном плеере перед обработкой всей подборки. WAV обычно занимает больше места; сохранение обложек и всех данных DJ-библиотеки не гарантируется.

### Если не запускается

- **Нет права на выполнение:** в Terminal набери `chmod +x ` с пробелом в конце, перетащи `convert_flac_to_wav.command` из Finder в это окно и нажми Enter. Затем повтори двойной клик.
- **macOS требует разрешить запуск:** проверь источник файла и следуй [инструкции Apple для доверенных приложений](https://support.apple.com/102445). Отключать Gatekeeper целиком не требуется.
- **FFmpeg not found:** проверь установку FFmpeg. Скрипт также ищет `/opt/homebrew/bin/ffmpeg` и `/usr/local/bin/ffmpeg`, даже когда Finder не загрузил настройки PATH из Terminal.
- **No FLAC files found:** положи треки непосредственно рядом со скриптом. Поддерживаются расширения `.flac`, `.FLAC` и смешанный регистр.
- **Ошибка конвертации:** прочитай сообщение FFmpeg в окне, проверь исходник и свободное место. Исходный FLAC не удаляется.

Из Terminal можно обработать другую папку, не копируя музыку:

```sh
/bin/bash ./convert_flac_to_wav.command "/путь/к/папке с музыкой"
```

## English instructions

Download and extract the ZIP above. This small script uses macOS's built-in `/bin/bash`; FFmpeg is a separate dependency. It searches PATH, the script folder, `/opt/homebrew/bin`, and `/usr/local/bin`.

1. Install FFmpeg once: if Homebrew is installed, run `brew install ffmpeg` in Terminal. Otherwise follow [brew.sh](https://brew.sh) first, including its post-install steps. On a macOS version unsupported by current Homebrew, use a compatible macOS build from the [FFmpeg download options](https://ffmpeg.org/download.html#build-mac) and put the executable named `ffmpeg` beside the script.
2. Copy a few FLAC tracks directly beside `convert_flac_to_wav.command`.
3. Double-click the `.command` file. Find the results in its `wav` subfolder and check them in your DJ software or player.

Originals are untouched. Existing outputs are skipped. Processing continues after a failed track, with converted/skipped/failed counts at the end. Temporary output files are cleaned up on handled failures; a force-killed process can leave a hidden temporary file behind. Filenames with spaces and Cyrillic characters and uppercase FLAC extensions are supported.

Output is **16-bit PCM WAV**, with no explicit sample-rate or channel-count change. This reduces bit depth for 24-bit sources. There is no 24-bit selection, subfolder scanning or CSV log. Audio stays local; the script does not install dependencies automatically. Preservation of all artwork and DJ metadata is not guaranteed.

If the file is not executable, type `chmod +x ` in Terminal, drag the `.command` file into the window, press Return, and retry. If macOS asks you to approve the file, follow [Apple's instructions for trusted software](https://support.apple.com/102445) after checking its source.

To convert a different folder from Terminal:

```sh
/bin/bash ./convert_flac_to_wav.command "/path/to/music folder"
```

Exit codes: `0` = completed/skipped or no FLAC files; `1` = at least one file failed; `2` = setup error. `Ctrl+C` stops the run.

## Development checks

With Python 3 and FFmpeg installed, run:

```sh
/bin/bash -n convert_flac_to_wav.command
python3 -m unittest discover -s tests -v
```

Tests use generated synthetic audio. They do not need access to a music library.
