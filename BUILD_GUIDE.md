# OVERCLOCK — руководство по сборке и запуску (Windows)

Аддон — это обычная custom game. Собирать `.vmap` нужно в Hammer, потому что
карта — бинарный формат и существует только в Workshop Tools.

## 0. Что нужно

- Windows + Steam + **Dota 2** (установлена).
- **Dota 2 Workshop Tools** — в Steam: *Dota 2 → свойства → Betas* либо в
  библиотеке инструментов Steam (Workshop Tools ставится отдельно, ~ несколько ГБ).
- После установки появится второй набор папок:
  `...\steamapps\common\dota 2 beta\`

Итоговая схема папок (это важно, тут две разные `dota_addons`):

```
...\dota 2 beta\
├─ content\dota_addons\overclock\   ← сюда: папка content\ из репозитория
└─ game\dota_addons\overclock\      ← сюда: папка game\ из репозитория
```

Из репозитория `dota-overclock/` копируются **две** ветки:

- `content/dota_addons/overclock/` → в `dota 2 beta\content\dota_addons\overclock\`
- `game/dota_addons/overclock/`    → в `dota 2 beta\game\dota_addons\overclock\`

> `addoninfo.txt`, Lua-скрипты и KV лежат в **game**-ветке. Panorama (XML/JS/CSS)
> и `maps/` — в **content**-ветке. Инструменты компилируют `content → game`.

## 1. Создать карту в Hammer

1. Открой **Dota 2 Workshop Tools → Launch Tools** (откроется Hammer).
2. `File → New`. Сохрани карту как **`overclock.vmap`** в:
   `...\dota 2 beta\content\dota_addons\overclock\maps\overclock.vmap`
3. Минимум: поставь `info_player_start` / spawn-точки (или используй пустую
   плоскость — сценарий сам расставит камеры и героев).
4. `File → Build Map` (или `F9`) → соберётся `overclock.vmap_c` в game-ветке.

Если у тебя уже есть любая пустая карта — можно переименовать её в `overclock.vmap`
и использовать.

## 2. Указать карту в addoninfo.txt

В `game/dota_addons/overclock/addoninfo.txt` блок `maps → overclock` уже создан.
Убедись, что `MapName` совпадает с именем `.vmap` (без расширения).

## 3. Собрать ассеты Panorama

В Workshop Tools: **Assets → Compile All** (или `dota_tools` соберёт при запуске
карты). Компилируются `content .../panorama/*` в `game .../panorama/*_c`.

Если UI не появился — проверь, что XML/JS/CSS лежат именно в
`content\dota_addons\overclock\panorama\{layout,scripts,styles}\custom_game\`.

## 4. Запустить

Вариант A (проще):
- В клиенте Dota 2 → вкладка **Custom Games** → **Local Host** → выбери
  `overclock`.

Вариант B (из инструментов):
- Workshop Tools → **Launch Dota 2** (Tools mode) → консоль:
  ```
  dota_launch_custom_game overclock overclock
  ```

Вариант C (в лобби с друзьями) — опубликовать в Workshop (кнопка Publish в Hammer).

## 5. Горячие клавиши

| Клавиша | Панель                |
|---------|-----------------------|
| `F5`    | Hub                   |
| `F6`    | Sandbox               |
| `F7`    | Stats                 |
| `F8`    | Patch Lab             |
| `F9`    | Roguelike             |
| `F10`   | Modifier Console      |

Клавиши заданы в `addoninfo.txt → Default_Keys` и обрабатываются Panorama через
`Game.AddCommand` (см. `content/.../panorama/scripts/custom_game/keys.js`).

## 6. Как НЕ сломать обычную Доту

- Никогда не редактируй `...\dota 2 beta\game\dota\` и не трогай `pak01_*.vpk`.
- Все изменения — только в `dota_addons\overclock\`.
- Хочешь чистую проверку: `Steam → Dota 2 → Свойства → Установленные файлы →
  Проверить целостность файлов` — вернёт базовую игру как было.
- Удалил папку аддона — кастомка исчезла, обычная Дота не пострадала.
- Cheat-команды (`sv_cheats 1` и т.п.) — только внутри кастомки/инструментов.

## 7. Отладка

- Консоль: включи в настройках Dota и смотри `scripts/vscripts` ошибки (красные).
- Логи Lua: `overclock` пишет в консоль сервера (см. `core/logger.lua`).
- Panorama: правый клик → *Inspect* в Tools-режиме; ошибки JS — в консоли
  Panorama.

## Частые проблемы

| Симптом | Причина / решение |
|---------|-------------------|
| Кастомка не появляется в Local Host | `.vmap_c` не собран — `Build Map` в Hammer |
| Пустой экран вместо UI | Panorama лежит не в `content/.../panorama/...` или не скомпилен |
| Клавиши F5–F10 не работают | не совпадает `Default_Keys` в addoninfo / не скомпилен keys.js |
| Ошибка загрузки модификатора | имя файла в `data/modifiers.lua` ≠ имени в `lua_modifiers/` |
