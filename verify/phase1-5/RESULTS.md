# Фазы 1-5 плана BENSON-NITI-EMULATION: результаты

Дата: 2026-11-22. Область владения соблюдена: изменён **только**
`/home/azizz/Yandex.Disk/dispak/dispak/extra.c`. `re-niti-graph/` не трогался
(только запуск `verify/niti-lowlevel/run.sh`), git commit/push не выполнялись.
`cu.c` и `optab.c` не менялись: существующие перехваты `РЕГ '34'/'240'`
(`cu.c:759-768`), `УВВ` (`cu.c:954-957`) и `optab.c:49` уже работают и были
переиспользованы как есть.

Бинарник: `/home/azizz/Yandex.Disk/dispak/build/dispak/dispak` (Release,
`-O3 -Werror`). Диски 2048/2053/2099 из `build/dispak/`, 2148 из
`/usr/local/share/besm6/`, рабочие копии в `/var/tmp/phase1-5/disks/`.

Резервные копии (не `.bak`, вне репозитория):
`/var/tmp/phase1-5/extra.c.pristine` (`a5c778e4ea51…`),
`cu.c.pristine` (`9d8e6bdb59d5…`), `optab.c.pristine` (`6c70a9e1a98b…`).

## 1. Что реализовано

| Фаза | Реализация в `extra.c` |
|------|------------------------|
| 1 | `РЕГ '34'`: 9 слов трактуются как маски ПРП/ГРП (`DUDKA: MASK9 loaded (ПРП/ГРП)`), 5 слов как `MASK5 acknowledged`; распознавание последовательностей сохранено для регрессии. `DU_F_E18` больше не выставляется блоком масок. ` ext_plot()` принимает `04102`, логирует байт `0164/0165`, ведёт 40-словный ring `0330..0377` и возвращает готовность E13. ЭК `01214` проверяет `е27гп` (разряд 27 КУС, `1<<21` по тому же счёту, что `E28 = 1<<20`) и вызывает `dudka_frame_xfer()`; ЭК `01213` сохранён как честный безусловный тестовый hook. |
| 2 | `struct bench_state {x,y,pen_down,step_x,step_y,limit_x,limit_y,steps}`, шаг 0.1 мм, лимиты 5000×7500 шагов (50×75 см). Лог `DUDKA: PEN UP/DOWN step +X/-X/+Y/-Y X=… Y=…`, при упоре `DUDKA: LIMIT X/Y`. |
| 3 | Декодер 16-битных элементов: `class=(w>>13)&3`, `payload=w&017777`, `extra=(w>>15)&1`; три элемента на 48-битное слово. Настраиваемая таблица `BESM6_NITI_DECODE=builtin\|calcomp\|nasa`, все строки помечены `[hypothesis]` / `[аналог …]`. Вызывается из `niti_frame()` **после** `niti_plot_write()`. |
| 4 | Второй поток `plot-log.txt` (кадры, PEN, DECODE, IRQ), закрывается в уже зарегистрированном `atexit(niti_report)`. `plot.dat` не изменён, всегда пишется только `niti_plot_write()`. SVG не делался (не обязательно). |
| 5 | См. отдельный раздел ниже. |

`niti_frame()`, `niti_plot_write()`, `e53()`, `eraise()` и entry в `cu.c:144-188`
не изменены.

## 2. Фаза 5 (ограниченный объём, подтверждённый пользователем)

Full guest vector dispatch не требуется и не реализуется: таблица `обвнп1`,
ГРП/МГРП/ПРП/МПРП, приоритетный арбитр — вне объёма. Реализовано ровно то,
что перечислено в подтверждении.

Корректировка из `/var/tmp/irq-research/REPORT.md` принята полностью:

- `eraise(1<<17)` в dispak — это событие **18 «обращение в закрытый лист»**, а не
  прерывание от Бенсона. Введено имя `DU_PROXY_EVENT` и повсюду написано
  **CONDITIONAL PROXY**. Ни одна строка лога не называет его «IRQ benson» как
  подлинное аппаратное прерывание.
- `обвнп1+30` — **разряд 18 ГРП** (комментарий `dudka.be:121` про «31-й» ошибочен);
  в логе и комментариях фиксируется именно 18-й разряд.
- Пробуждение задачи — **отдельный факт**: `сч E37; или ШГ; зп ШГ; пб БПУ`.
  Моделируется счётчиком `du_waketasks` и строкой `DUDKA: WAKETASK E37 SHG=N`,
  **не** через `eraise`.
- Подъём proxy-event ограничен сначала программной маской TV67/TV67A
  (`du_grp18`, ЭК 01215), затем e53-семантикой `ehandler && eenab &&
  (emask & DU_PROXY_EVENT)`. Снятие маски сделано до «возврата вектора», как в
  `G10072` (порядок в guest-коде: `D10114 → D10157 → D10160 → ШГ E37 → … → БПУ`).

Новые строки лога:

```
DUDKA: TV67 MASK18 set (ГРП разряд 18)
DUDKA: MASK18 cleared (TV67A, AND NOT in МГРП)
DUDKA: buffer switched to 1 (D10157=1 D10160=D10161)
DUDKA: WAKETASK E37 SHG=1 (task wakeup NOT modeled: guest пб БПУ)
DUDKA: IRQ proxy event 18 frame=1 raised=1 goahead=1 NOT modeled: guest vector обвнп1+30 / GRP18 dispatch
DUDKA: IRQ raise event=18 arg=000000 goahead=1
DUDKA: IRQ proxy event 18 frame=1 raised=0 goahead=0 (ehandler=0 eenab=0 emask18=0) NOT modeled: guest vector обвнп1+30 / GRP18 dispatch
DUDKA: IRQ suppressed (TV67A mask cleared)
DUDKA: IRQ summary raised=1 taken=1 proxy=1
```

`taken` считается как число вызовов `eraise()`, после которых `goahead` стал
ненулевым. Это не guest-подтверждение прерывания; в C-эмуляторе нет ни
app-level acknowledge, ни guest-таблицы.

ЭК 01215 (субфункция в левой половине аккумулятора, аргумент в правой):
`0` = TV67, `1` = TV67A, `2` = поднять proxy без кадра, `3` = WAKETASK marker.
Больше субфункций нет; ПРП 19 и слот `обвнп1+30` не моделируются даже флагами.

## 3. Тесты

| Прогон | Результат | Детали |
|--------|-----------|--------|
| `cd build && ctest --output-on-failure` | **52/52 PASS**, 33.81 s | 0 failed |
| `TMPDIR=/var/tmp DISPAK_BIN=…/dispak ./run.sh` (re-niti-graph/verify/niti-lowlevel) | **6 PASS, 0 FAIL** | t01..t06, все SHA `plot.dat` совпали |
| `b1-init.b6` | PASS | `КОНЕЦ ЗАДАЧИ`, `MASK9 loaded`, plot.dat отсутствует |
| `b1-frame.b6` | PASS | `frames=1 words=64`, SHA совпал |
| `b1-toggle.b6` | PASS | `frames=2`, переключение `1 → 0`, SHA совпал |
| `b1-ack.b6` | PASS | `MASK9 loaded` + `MASK5 acknowledged` |
| `hook-uvv.b6` | PASS | все 5 `DUDKA: UVV`, byte/ring, `inv`, `ready E13` |
| `hook-fisobm.b6` | PASS | `KUS bit27 set` → кадр; `KUS no GP bit, ignored` → кадра нет |
| `hook-mask.b6` | PASS | TV67 → MASK18 cleared → кадр 2 подавлен (`IRQ suppressed`) |
| `hook-irq.b6` | PASS | `raised=1 goahead=1`, `IRQ summary raised=1 taken=1 proxy=1` |
| `hook-irq-alone.b6` | PASS | `IRQ raise event=18 … goahead=0` (без handler) и `goahead=1` (с handler) |
| `hook-limit.b6` (400 кадров) | PASS | `DUDKA: LIMIT X`, `BENCH X=5000 Y=0 steps=5000` — лимит не превышен |
| `BESM6_NITI_DECODE=builtin/calcomp/nasa` + `BESM6_NITI_DEBUG=1` | PASS | таблица переключается, тег `[аналог …]`/`[hypothesis]` в логе, plot.dat прежний |

Все hook-деки и логи: `/var/tmp/phase1-5/hook-*.b6`, `/var/tmp/phase1-5/run/*/out.txt`.
Генератор: `/var/tmp/phase1-5/gen_hooks.py`. Артефакты лежат в `/var/tmp/`, в
репозитории новых файлов нет.

### SHA `plot.dat` (сверка со старыми эталонами)

| Артефакт | SHA256 |
|----------|--------|
| `b1-frame` (новый и старый `/var/tmp/dudka-b1/run/b1-frame/plot.dat`) | `45274413e8ace79b24ced0bdb4e77c07875f0b7a3b8867175724604542045e6f` |
| `b1-toggle` (новый и старый) | `46b10946f5373255f2948bd313438e815c79b409ce2aecc696557039553ab5cc` |
| t02/t04/t05 | `27440f92e4c5039ed011d678d0fe2fbbab945fde8f05d4d415c8eba6c80db498` |
| t03 | `0ef90c9dfd06f24a4fdf21be4c4f616b938a17bdbec1a36bc80dbd7042ddb8a2` |
| t06 | `645a196a44165dad84b491dcab8467dd628519269f1adb661d1e0927b7b44d6b` |

Пример фрагмента лога `b1-frame` (1600 байт, 64 строки plot.dat):

```
DUDKA: MASK9 loaded (ПРП/ГРП)
DUDKA: FRAME 1 words=64
DUDKA: DECODE hypothesis table=builtin 13+2+1 (13 payload / 2 class / 1 extra bits)
DUDKA: PEN UP step +X X=00001 Y=00000 (mm 0.1,0.0) [аналог NASA]
DUDKA: PEN UP step +X X=00002 Y=00000 (mm 0.2,0.0) [аналог NASA]
DUDKA: DECODE unknown class=2 extra=1 payload=006112 [hypothesis]
DUDKA: buffer switched to 1 (D10157=1 D10160=D10161)
DUDKA: WAKETASK E37 SHG=1 (task wakeup NOT modeled: guest пб БПУ)
DUDKA: IRQ proxy event 18 frame=1 raised=0 NOT modeled: guest vector обвнп1+30 / GRP18 dispatch
DUDKA: IRQ suppressed (TV67A mask cleared)
DUDKA: BENCH X=28 Y=23 pen=UP steps=51 [аналог NASA]
```

## 4. Сборка и предсуществующее предупреждение

Предупреждение `-Werror=unused-variable` `nat_done` в `lun45_native_view` было
временно убрано **только на время сборки**, после всех прогонов восстановлено
редактированием из `/var/tmp/phase1-5/extra.c.pristine` (не `git checkout`).
Проверено: `git diff | grep nat_done` → пусто. `.bak`-файлы не создавались.
`git diff --name-only` → только `dispak/extra.c` (369 вставок / 22 удаления).

## 5. Честный список NOT modeled

1. **Guest-таблицы `обвнп1` (ГРП), МГРП, `обвнп3` (ПРП), МПРП в C отсутствуют.**
   Подлинная подмена `обвнп1+30` (guest-запись `рег '101'` / `зп` / `рег '107'`,
   инвалидация БРЗ) и vector dispatch `ОБВНПР` не моделируются. Это явно
   написано в коде и в каждой строке про IRQ.
2. **`eraise(DU_PROXY_EVENT)` — CONDITIONAL PROXY.** В dispak событие 18 это
   «обращение в закрытый лист», а не линия ГП. Настоящий разряд 18 ГРП и его
   маска `ТВ67/ТВ67А` как аппаратные регистры не эмулируются; `du_grp18` — только
   булев флаг, выставляемый тестовой декой через ЭК 01215.
3. **Пробуждение задачи не моделируется.** `ШГ E37` и `пб БПУ` исполняются
   guest-кодом; в C есть только счётчик `du_waketasks` и строка лога. `eraise()`
   не используется как замена ШГ.
4. **ПРП 19 / `УСТПРП E19` / перезапись `ОБВНП3+24-19`** не моделируется вообще
   (даже флагом, по подтверждённому ограниченному объёму). ГРП 18 и ПРП 19
   остаются разными линиями, в логе они не отождествляются.
5. **`пв ФИЗОБМ` с битом 27 КУС** как guest-подпрограмма не перехватывается;
   ЭК 01214 — минимальный hook, не подлинный перехват. ЭК 01213 сохранён как
   безусловный тестовый hook.
6. **Аппаратный протокол Бенсона:** данные `РЕГ '240'` детерминированы и
   цикличны, `сбр ЧЕРЕЗ1` побитно не воспроизводится, 1024-словная страница
   `D10155` сведена к счётчику. DMS-ячейки гостю недоступны.
7. **`сбр ЧЕРЕЗ1`, `рег '36'/'37'`, `рег '237'`, приоритетный арбитраж `ОБВНПР`
   и формат сохранения 11 слов контекста** — guest-механизмы, в C нет их модели.
8. При аварийном `G10110` восстановление вектора в исходниках не показано —
   неопределённость, в эмуляторе не моделируется.

## 6. Оговорки и гипотезы

- Раскладка 13+2+1 и соответствие классов действия — **гипотеза по аналогам**;
  прямого описания формата команд Бенсона периода НИТИ нет. Все строки
  декодера помечены. Таблица легко меняется через `BESM6_NITI_DECODE`.
- Шаг 0.1 мм и пять шин принесены из NASA TM-76182 (Электроника-1001), для
  НИТИ это `[аналог NASA]`. В брифе сказано «500×750 шагов» для 50×75 см;
  размерно корректно 5000×7500 шагов при 0.1 мм — использовано 5000/7500,
  что и проверено тестом `hook-limit`.
- `DU_UVV_READY_E13 = 1<<12` взято из simh `PI2_START`; по dispak-документации
  это-value не подтверждено, в логе прямо сказано `NOT verified`.
- Номер разряда КУС принят `1<<21` по тому же счёту слева, что и
  `E28 = 1<<20` в существующих константах; если в администраторе КУС
  используется другой счёт, это единственное место, которое нужно поправить.

## Итог

**DONE.** Фазы 1-5 реализованы; регрессия 52/52 + 6/6 + b1-* сохранена, новые
hook-тесты подтверждают все новые строки лога. `plot.dat` байт-в-байт прежний.
git commit/push не выполнялись, чужие каталоги не изменялись.
