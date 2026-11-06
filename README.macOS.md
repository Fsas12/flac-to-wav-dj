# FLAC / AIFF → WAV on macOS / для macOS

[Download ZIP](https://github.com/Fsas12/flac-to-wav-dj/archive/refs/heads/main.zip) · [Windows / English](README.md) · [Windows / Русский](README.ru.md)

## Русская инструкция

### Без установки программ и без Terminal

1. Скачай ZIP и распакуй его.
2. Открой **FLAC to WAV DJ.app** двойным кликом.
3. Выбери корневую папку загрузок Soulseek или другую папку с FLAC / AIFF. Все подпапки обработаются автоматически.
4. После обработки нажми **Open WAV folder**: результат находится в подпапке `wav` выбранной папки.

Приложение использует `afconvert`, встроенный в macOS. FFmpeg и Homebrew не нужны; дополнительных загрузок нет. Папку приложения можно перенести отдельно от остальных файлов проекта, например в «Программы»: конвертер включён внутрь пакета.

При первом открытии macOS может запросить разрешение. У приложения нет подписи и нотариального заверения Apple Developer ID. Если система блокирует открытие, проверь источник и следуй [инструкции Apple для доверенных приложений](https://support.apple.com/102445): после попытки запуска открыть «Системные настройки → Конфиденциальность и безопасность → Всё равно открыть». Вводить команды или отключать Gatekeeper целиком не нужно.

### Поведение и звук

- Поддерживаются `.flac`, `.aif`, `.aiff`, включая верхний и смешанный регистр.
- Обрабатываются файлы в выбранной папке и всех её обычных подпапках. Внутри корневой `wav` сохраняется структура пользователей и альбомов.
- Корневая папка результата `wav` исключена из поиска. Символические ссылки не обходятся, чтобы избежать зацикливания.
- Исходники не изменяются. Существующие выходные WAV пропускаются.
- При ошибке одного трека остальные продолжают обрабатываться. Итоговое окно показывает количество готовых, пропущенных и ошибочных файлов.
- Выход — PCM WAV 16 бит, без явного изменения частоты и количества каналов. Для 24-битных исходников разрядность снижается; выбора 24 бит нет.
- Аудио остаётся на компьютере. CSV-логов нет, обложки и все данные DJ-библиотеки могут не сохраниться.
- Одинаковое базовое имя внутри одной исходной папки даёт один результат: `track.flac` и `track.aiff` используют `wav/track.wav`. Для обоих результатов в одной папке задай разные имена; треки из разных папок сохраняются отдельно.

Приложение рассчитано на macOS 11 и новее. Проверь 1–2 результата на своём плеере перед обработкой всей библиотеки.

### Дополнительный вариант: старый запускатель

`convert_flac_to_wav.command` также сохранён. Положи запускатель в корневую папку с FLAC / AIFF и запусти двойным кликом: откроется окно Terminal с ходом обработки, вводить команды не нужно. Если FFmpeg уже установлен, этот запускатель использует его. Если FFmpeg нет, он автоматически использует встроенный `afconvert`.

После принудительного завершения процесса скрытый временный файл может остаться в `wav`. При обычной ошибке скрипт удаляет свой незавершённый временный файл.

## English instructions

### No dependency installation or Terminal commands

1. Download and extract the ZIP.
2. Double-click **FLAC to WAV DJ.app**.
3. Choose your root Soulseek downloads folder, or any folder containing FLAC / AIFF tracks. All ordinary subfolders are processed automatically.
4. Click **Open WAV folder** when conversion finishes.

The app uses macOS's built-in `afconvert`. No FFmpeg, Homebrew, or extra software download is needed. The converter is embedded in the app bundle, so you can move the app on its own to Applications.

macOS may ask for first-open approval. The app is not signed or notarized with an Apple Developer ID; follow [Apple's trusted-software instructions](https://support.apple.com/102445) if blocked. No global Gatekeeper change or Terminal command is needed.

Files in the selected folder and its ordinary subfolders are converted to **16-bit PCM WAV** inside one root `wav` subfolder, preserving relative user/album paths. Originals stay untouched, existing outputs are skipped, and processing continues after a failed track. The final dialog shows converted/skipped/failed counts. Sample rate and channel count are not explicitly changed. There is no 24-bit selector or CSV log. The root output `wav` tree is excluded from scanning; file and directory symlinks are not followed. For 24-bit sources, bit depth is reduced. Artwork and all DJ metadata are not guaranteed to survive.

Matching base names within the same input folder share one output: `track.flac` and `track.aiff` both map to `wav/track.wav`. Use distinct base names to keep both versions within that folder. Identically named tracks in different user/album folders stay separate.

The app targets macOS 11 and newer. Check a few results in your intended player before converting a whole library.

The original `convert_flac_to_wav.command` remains available: put it in the root audio folder and double-click it; it also scans all ordinary subfolders. It uses an existing FFmpeg or automatically falls back to built-in `afconvert`. It opens a Terminal window but needs no typed commands.

## Development checks

Python 3 and FFmpeg are needed only to generate synthetic test fixtures. The end-user Mac app has neither dependency.

```sh
python3 -m unittest discover -s tests -p test_macos_converter.py -v
FLAC_TO_WAV_ENGINE=afconvert python3 -m unittest discover -s tests -p test_macos_converter.py -v
python3 -m unittest discover -s tests -p test_app_bundle.py -v
```

When editing the shared converter, also copy it into `FLAC to WAV DJ.app/Contents/Resources/convert_flac_to_wav.command`. The bundle test checks that both copies are identical. UI dialogs require an interactive Mac session; native audio conversion and bundle structure are checked in CI.
