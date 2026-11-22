# Результаты: минимальный слой перехвата команд управления ГП (ДУДКА)

Копия дек и отчёта лежит в `re-niti-graph/verify/dudka/`. Реализация перехвата
в `dispak`: коммит `1589976` (`cu.c`, `extra.c`, `optab.c`).

Дата: 2026-11-22. Бинарник: `/home/azizz/Yandex.Disk/dispak/build/dispak/dispak`
(собран после правок). Диски: 2048/2053/2099 из `build/dispak/`, 2148 из
`/usr/local/share/besm6/` (symlinks в `/var/tmp/dudkactl/disks/`).

Деки: `/var/tmp/dudkactl/d1.b6`, `d2.b6`, `d3.b6` (копии в
`/var/tmp/dudkactl/run/`, где сохранены логи и `plot.dat`).

Команда запуска (для каждого теста, из `/var/tmp/dudkactl/run/`):

```
BESM6_DUDKA_TEST=1 <dispak> --path=/var/tmp/dudkactl/disks \
    --input-encoding=utf8 dN.b6 > dN.out 2> dN.err
```

`BESM6_DUDKA_TEST=1` — тестовый переключатель, добавленный в этом изменении:
пакетные дека `*assem/*execute` МОНИТОР-80 запускает в пользовательском режиме,
поэтому без него `,MOD,` и `,033,` дают `ЗАПРЕЩ.КОМАНДА` (E_PRIV) ещё до
перехвата. При выключенной переменной поведение полностью прежнее.

## Таблица результатов

| Тест | Ожидаемые строки | Реальный результат | `plot.dat` |
|------|------------------|--------------------|------------|
| `d1.b6` (9 записей РЕГ '34', `*50,1210B`, `*50,1211B`, `*62,0B`) | 9 строк `DUDKA: REG34 word=...`, `NITI: scheme 1210 selected`, непустой `plot.dat` | PASS: 9 строк `DUDKA: REG34` со значениями `40000000, 00000040, 00000001..7`; `NITI: scheme 1210 selected`; `NITI: summary ... frames=1 words=64`; итог `reg34=9` | 1600 байт, 64 строки |
| `d2.b6` (2 чтения РЕГ '240') | `DUDKA: REG240 read=...`, `NITI: scheme 1210 selected` | PASS: `read=0000001140000000` (D10171), затем `read=0000001500000040` (D10167); итог `reg240=2` | не создан (1211 нет) |
| `d3.b6` (УВВ 7/155/166/164/165/4023/147) | `DUDKA: UVV <octal>` для каждого устройства | PASS: 7 строк `DUDKA: UVV 7/155/166/164/165/4023/147`; итог `uvv=7` | не создан (1211 нет) |

`plot.dat` отсутствует в d2/d3, что подтверждает: новая имитация не пишет
графику, файл по-прежнему создаётся только через ЭК 01211 → `niti_frame()`.

## Фрагменты логов

### d1.err
```
NITI: scheme 1210 selected
DUDKA: REG34 word=40000000
DUDKA: REG34 word=00000040
DUDKA: REG34 word=00000001
DUDKA: REG34 word=00000002
DUDKA: REG34 word=00000003
DUDKA: REG34 word=00000004
DUDKA: REG34 word=00000005
DUDKA: REG34 word=00000006
DUDKA: REG34 word=00000007
NITI: summary schemes=1 frames=1 words=64 active=1 scheme=1210
DUDKA: summary reg34=9 reg240=0 uvv=0
```

### d2.err
```
NITI: scheme 1210 selected
DUDKA: REG240 read=0000001140000000
DUDKA: REG240 read=0000001500000040
NITI: summary schemes=1 frames=0 words=0 active=1 scheme=1210
DUDKA: summary reg34=0 reg240=2 uvv=0
```

### d3.err
```
NITI: scheme 1210 selected
DUDKA: UVV 7
DUDKA: UVV 155
DUDKA: UVV 166
DUDKA: UVV 164
DUDKA: UVV 165
DUDKA: UVV 4023
DUDKA: UVV 147
NITI: summary schemes=1 frames=0 words=0 active=1 scheme=1210
DUDKA: summary reg34=0 reg240=0 uvv=7
```

## Синтаксис, найденный экспериментально

- `,MOD,34B` и `,MOD,240B` — короткий opcode 002 в МАДЛЕН; `B` = восьмеричный
  суффикс, кавычки `'34'` транслируются как ошибка адреса.
- `,033,7B` — opcode 033 (УВВ); мнемоника `,UVV,` в МАДЛЕН отсутствует
  (`ОШИБКА В КОП`), поэтому в d3 использован числовой opcode.
- Метка данных должна начинаться с пробела (` *K1: ,LОG,...`, `О` кириллическое),
  `,END,` — последняя строка исходника перед `*execute`.

## Регрессия

`ctest --output-on-failure` в `build/`: **52/52 passed** (0 failed, 40.57 s).
`git diff` содержит только `dispak/cu.c`, `dispak/extra.c`, `dispak/optab.c`;
строки `nat_done` в diff отсутствуют (предупреждение `-Werror=unused-variable`
в `lun45_native_view` временно удалялось для сборки и восстановлено из копии
`/var/tmp/dudkactl/extra.c.pre-natdone2`). Git commit/push не выполнялись.
