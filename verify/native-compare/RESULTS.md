# Результаты сравнения родной библиотеки 22 и Фортран-порта

Шаблон отчёта и реальный протокол. Выдуманные результаты сюда не заносятся:
все числа ниже скопированы из вывода `./run.sh` и файлов метрик в
`/var/tmp/native-compare.J2jZYK` (сохранено через `KEEP_WORK=1`). Прочерк
означает «артефакт не получен», а не нулевое значение.

## Состояние зависимостей на момент прогона

- Бэкенд БЕНСОНа в бинарнике присутствует: маркер `BESM6_DUDKA_PLOT` найден в
  `/home/azizz/Yandex.Disk/dispak/build/dispak/dispak` (mtime 2026-11-22
  20:28:43 +0300).
- `verify/native-decks/` ещё не существует. Родная сторона представлена
  legacy-декой `verify/native/native-final.b6` и SHIM
  `verify/native/shim.b6` (`SHIM.mad` всё ещё резервирует кадр через
  `BUFPL: ,BSS,64` и не пишет туда координаты).
- Артефакты субагентов A (SHIM с записью координат в кадр) и B (прототипы
  вызовов) ещё не появились. Поэтому ожидаемые `НЕ ГОТОВО` - это честный
  результат, а не сбой раннера.
- Обновление после R2: в `verify/native-decks/` появились файлы
  `sig-arcia1.b6`, `sig-arcia3.b6`, `sig-arcia5.b6` (сигнатурные пробы
  ARCIA). Деки с именами `C1-line.b6`, `C2-circle.b6` и т.д. там по-прежнему
  нет, поэтому поиск деки раннером и verdict C1-line не изменились.

Команда воспроизведения:

```
cd /home/azizz/Yandex.Disk/re-niti-graph/verify/native-compare
KEEP_WORK=1 TIMEOUT=240 ./run.sh 2>&1 | tee /var/tmp/nativecomp-full-R2.log
```

Окружение прогона: `BESM6_DUDKA_PLOT=benson`, `BESM6_DUDKA_TEST=1`,
`BESM6_DUBNA_PLOT_KEEP=1`; `BESM6_PATH` указывает на копию дисков внутри
временного каталога (родная сторона: `/usr/local/share/besm6/2348`, порт:
`fortran/verify/2348-niti.img`). Наследуемый `TMPDIR` раннером игнорируется,
всё временное лежит в `/var/tmp`.

## Прогон R2 (2026-11-22, реальный вывод)

```
=== Родная библиотека 22 vs Фортран-порт: честное сравнение ===
dispak      : /home/azizz/Yandex.Disk/dispak/build/dispak/dispak
native 2348 : /usr/local/share/besm6/2348
port   2348 : /home/azizz/Yandex.Disk/re-niti-graph/fortran/verify/2348-niti.img
shim        : /home/azizz/Yandex.Disk/re-niti-graph/verify/native/shim.b6
workdir     : /var/tmp/native-compare.J2jZYK
пары        : C1-line C2-circle C3-text C4-page C5-counters

PAIR        SIDE    ROUND END   ERR   FORB  PLOT-SHA-12   FRAMES  PLOT-B    OUT-SHA-12    CMDS  SVG-PATHS DET RESULT
----------- ------- ------ ----- ----- ----- ------------- ------- --------- ------------- ----- --------- --- ------
C1-line     native  r1   Y     N     Y     15450e0b433b  1       1600      b458dd3471bb  756   1         -   Y
C1-line     native  r2   Y     N     Y     15450e0b433b  1       1600      b458dd3471bb  756   1         Y   Y
C1-line     port    r1   Y     N     N     7b362ec4efd7  2       3200      cf84d96a8bf6  228   2         -   Y
C1-line     port    r2   Y     N     N     7b362ec4efd7  2       3200      cf84d96a8bf6  228   2         Y   Y
C1-line    NATIVE-READY=N   FMT=Y CMD=Y DET(n/p)=Y/Y PORT-OK=Y NATIVE-SHA=15450e0b433b  PORT-SHA=7b362ec4efd7  НЕ ГОТОВО
  why:SHIM.mad всё ещё BSS-only (координаты не пишутся в кадр); ВЫВОД ЗАПРЕЩЕН в логе родной деки; plot.dat = SHA неинициализированного BSS
C2-circle   native  r1   N     N     N     -             -       -         -             0     0         -   N
C2-circle   native  r2   N     N     N     -             -       -         -             0     0         N   N
C2-circle   port    r1   Y     N     N     d56888913f02  25      40000     -             0     0         -   N
C2-circle   port    r2   Y     N     N     d56888913f02  25      40000     -             0     0         Y   N
C2-circle  NATIVE-READY=N   FMT=N CMD=N/A DET(n/p)=N/Y PORT-OK=N NATIVE-SHA=-             PORT-SHA=d56888913f02  НЕ ГОТОВО
  why:нет родной деки для C2-circle; у порта нет корректного benson.out; у порта нет benson.svg с <path>
C3-text     native  r1   N     N     N     -             -       -         -             0     0         -   N
C3-text     native  r2   N     N     N     -             -       -         -             0     0         N   N
C3-text     port    r1   Y     N     N     31c016da5ea3  3       4800      -             0     0         -   N
C3-text     port    r2   Y     N     N     31c016da5ea3  3       4800      -             0     0         Y   N
C3-text    NATIVE-READY=N   FMT=N CMD=N/A DET(n/p)=N/Y PORT-OK=N NATIVE-SHA=-             PORT-SHA=31c016da5ea3  НЕ ГОТОВО
  why:нет родной деки для C3-text; у порта нет корректного benson.out; у порта нет benson.svg с <path>
C4-page     native  r1   N     N     N     -             -       -         -             0     0         -   N
C4-page     native  r2   N     N     N     -             -       -         -             0     0         N   N
C4-page     port    r1   Y     N     N     4688d7250d3d  2       3200      1644f4430106  8     0         -   N
C4-page     port    r2   Y     N     N     4688d7250d3d  2       3200      1644f4430106  8     0         Y   N
C4-page    NATIVE-READY=N   FMT=N CMD=N DET(n/p)=N/Y PORT-OK=N NATIVE-SHA=-             PORT-SHA=4688d7250d3d  НЕ ГОТОВО
  why:нет родной деки для C4-page; у порта нет benson.svg с <path>
C5-counters native  r1   N     N     N     -             -       -         -             0     0         -   N
C5-counters native  r2   N     N     N     -             -       -         -             0     0         N   N
C5-counters port    r1   Y     N     N     bdd76e1e9bca  3       4800      -             0     0         -   N
C5-counters port    r2   Y     N     N     bdd76e1e9bca  3       4800      -             0     0         Y   N
C5-countersNATIVE-READY=N   FMT=N CMD=N/A DET(n/p)=N/Y PORT-OK=N NATIVE-SHA=-             PORT-SHA=bdd76e1e9bca  НЕ ГОТОВО
  why:нет родной деки для C5-counters; у порта нет корректного benson.out; у порта нет benson.svg с <path>

Summary: 0 СОВМЕСТИМО, 5 НЕ ГОТОВО, 0 РАСХОЖДЕНИЕ (всего 5)
Не требуются равными: координаты, порядок шагов X/Y, число кадров, SHA256, размер SVG.
workdir: /var/tmp/native-compare.J2jZYK
```

Код возврата раннера: **1** (ожидаемо: есть `НЕ ГОТОВО`).

## Детали C1-line (полные SHA256)

| Артефакт | Родная дека | Порт C1-line |
|---|---|---|
| `plot.dat`, байт | 1600 | 3200 |
| `plot.dat`, кадров | 1 | 2 |
| `plot.dat`, SHA256 | `15450e0b433bfbc2c2cac11d2528e7a9626f444a0d60b2290c6b325ddff25b2d` | `7b362ec4efd79e11fe0cbaebfc6de10194fa24dc7eaa76fb989f0bd445472d4c` |
| `benson.out`, байт / строк | 46874 / 756 | 14140 / 228 |
| `benson.out`, SHA256 | `b458dd3471bb0ed9a50d76f25e3444d1ea35f780bd59ab01a26e717fbfbefd29` | `cf84d96a8bf6c845f86ae136aeec66aea5060b854bb159fabe0d9988f9e9284e` |
| Алфавит кодов | `6501,6502,6511,6512,6514` | `6501,6502,6511,6512,6514` |
| `benson.svg`, байт / `<path>` | 358 / 1 | 401 / 2 |
| `benson.svg`, dimensions | 4 × 751 | 112 × 111 |
| `benson.svg`, SHA256 | `9ba875aea84b2647228c3bc1b286e06ec099ec5406c6247e51a38992d3bb82fa` | `e505aba4e4d494ac9f9099f27160494602b6909f8309d51cb9df7bfc48748a68` |
| `NITI: summary` | `schemes=1 frames=1 words=64 active=1 scheme=1210` | `schemes=2 frames=2 words=128 active=1 scheme=1210` |
| `ВЫВОД ЗАПРЕЩЕН` | есть | нет |
| Детерминированность r1=r2 | Y | Y |

Ширина 112 × 111 у порта совпадает с описанной в контексте задачи. Родной
кадр даёт вытянутый SVG 4 × 751 из неосмысленного содержимого BSS.

## Честные находки R2

1. **Родная сторона не обновлена.** SHIM.mad резервирует `BUFPL: ,BSS,64`,
   в логе присутствует `ВЫВОД ЗАПРЕЩЕН`, `plot.dat` побайтово равен
   историческому эталону неинициализированного буфера. Сравнение геометрии
   сейчас невозможно, поэтому verdict - `НЕ ГОТОВО`.
2. **Родных дек для C2-C5 нет.** `verify/native-decks/` отсутствует, legacy
   fallback предусмотрен только для C1-line. Остальные четыре пары честно
   помечены как неготовые.
3. **У порта C2/C3/C5 нет `benson.out` и `benson.svg`.** Из логов:
   `DUDKA: BENSON coords out of range X=-8384497 Y=755317` (C2) и
   `X=135181 Y=135174` (C3). Декодер в режиме `benson` ожидает координаты
   в шагах 0.1 мм; старые тестовые деки C2/C3/C5 выдают значения вне
   диапазона стенда, команд не эмитируется. Это наблюдение, а не гипотеза
   о причине; исправление дек выходит за рамки задачи.
4. **У порта C4-page есть `benson.out` (8 команд), но в `benson.svg` нет ни
   одного `<path>`** (размер 2 × 1, пустая группа). Значит, проверка
   «структура SVG» для этой пары не проходит; это не ошибка раннера.
5. **Алфавит команд у C1 совпал**, хотя содержимое кадров нет. Это ровно тот
   инвариант, который раннер обязан проверять, и он уже работает.

Прочерки в таблицах выше означают «не получено», а не «ноль команд».

## Шаблон для следующего раунда (после артефактов A/B)

Скопировать раздел и заполнить **только** реальными данными:

```
Раунд: R__    Дата: __________
Команда: __________________________________________________________
dispak: __________  native 2348: __________  port 2348: __________
Родная дека: __________  SHIM: __________

| Пара | NATIVE-READY | FMT | CMD | DET (n/p) | PORT-OK | NATIVE-SHA-12 | PORT-SHA-12 | Вердикт |
|------|--------------|-----|-----|-----------|---------|---------------|-------------|---------|
|      |              |     |     |           |         |               |             |         |

Summary: __ СОВМЕСТИМО, __ НЕ ГОТОВО, __ РАСХОЖДЕНИЕ
Причины НЕ ГОТОВО / РАСХОЖДЕНИЕ: __________________________________
Повторный прогон той же сборки: SHA r1=r2 (Y/N) ____________________
```

Порядок заполнения:

1. Дождаться артефактов A/B в `verify/native/` и `verify/native-decks/`.
2. Прогнать `KEEP_WORK=1 ./run.sh` и сохранить лог в `/var/tmp`.
3. Перенести в таблицу только строки verdict и колонки `why` из вывода.
4. Для каждой пары сверить `EXPECTED.md`; расхождение записать текстом.
5. Если родная сторона по-прежнему даёт SHA `15450e0b...`, раунд снова
   `НЕ ГОТОВО`, даже если все остальные колонки зелёные.
