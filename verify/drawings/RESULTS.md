# Результаты прогона тестовых рисунков

Все значения ниже взяты из реального прогона 2026-11-22 после перехода на
передачу адреса кадра аргументом. Ничего не выдумано: если артефакта не
было, в таблице стоит прочерк, а не нуль.

## Команда и окружение

```
cd /home/azizz/Yandex.Disk/re-niti-graph
DISPAK_BIN=/home/azizz/Yandex.Disk/dispak/build/dispak/dispak \
TMPDIR=/var/tmp KEEP_WORK=1 ./verify/drawings/run.sh
```

- dispak: `/home/azizz/Yandex.Disk/dispak/build/dispak/dispak`
- диск 2348: `/home/azizz/Yandex.Disk/re-niti-graph/fortran/verify/2348-niti.img`
- env каждого прогона: `BESM6_DUDKA_PLOT=benson BESM6_DUDKA_TEST=1
  BESM6_DUBNA_PLOT_KEEP=1`, `BESM6_PATH=<workdir>/disks`
- рабочий каталог финального прогона: `/var/tmp/plotter-drawings.QCH2mS`
- каждая дека прогонялась дважды (r1, r2)

## Итог

**10 PASS, 0 FAIL** из 10 дек. Раньше требование было минимум 6 PASS;
теперь требуется, чтобы прошли все деки, включая 3- и 4-точечные d09/d10.

Во всех 20 прогонках: `NITI: summary`, `КОНЕЦ ЗАДАЧИ`, нет `ОШ`/`ERR`/
`ОТСУТСТВУЕТ`, непустые `benson.out` и `benson.svg`, SVG начинается с `<?xml`
и содержит `<path>`. SHA256 `benson.out` и `benson.svg` совпали между r1 и r2
для каждой деки. Адрес `/PDEVXY/` из кросс-ссылки теперь только для справки:
у d01..d08 он `0o3150`, у d09 `0o3155`, у d10 `0o3160`. Раньше такие адреса
давали пустой SVG, теперь все деки рисуют.

Регрессия `verify/C1-line.b6` (проверена отдельно и раннером
`verify/benson-commands/run.sh`) даёт прежние три хэша:

| Артефакт | SHA256 |
|---|---|
| `plot.dat` | `7b362ec4efd79e11fe0cbaebfc6de10194fa24dc7eaa76fb989f0bd445472d4c` |
| `benson.out` | `cf84d96a8bf6c845f86ae136aeec66aea5060b854bb159fabe0d9988f9e9284e` |
| `benson.svg` | `e505aba4e4d494ac9f9099f27160494602b6909f8309d51cb9df7bfc48748a68` |

## Таблица результатов

| Дека | `benson.out` SHA256 (12) | `benson.svg` SHA256 (12) | SVG WxH | `<path>` | ADR | DET | Результат |
|---|---|---|---:|---:|---|---|---|
| d01-horizontal | `765c6da46515` | `e587256d86d7` | 152x151 | 2 | 03150 | Y | PASS |
| d02-vertical | `80c00d7bc876` | `1da6cf813b54` | 22x141 | 2 | 03150 | Y | PASS |
| d03-diagonal | `fa29663f8ab3` | `ac662c810d9c` | 152x151 | 2 | 03150 | Y | PASS |
| d04-rectangle | `9f48597bc1f6` | `47b5f5dea796` | 162x161 | 2 | 03150 | Y | PASS |
| d05-zigzag | `0d1f4861937f` | `8bf1b69ab7f7` | 132x131 | 2 | 03150 | Y | PASS |
| d06-steep | `3cdd5e337823` | `d716b04e5149` | 42x181 | 2 | 03150 | Y | PASS |
| d07-shallow | `3ba59eb8a1ab` | `a7738621f4b1` | 182x21 | 2 | 03150 | Y | PASS |
| d08-tiny | `4be196fc5b40` | `c66e6c71028f` | 14x13 | 2 | 03150 | Y | PASS |
| d09-triangle | `99bf6a4f817f` | `16f5ac56eff7` | 112x111 | 3 | 03155 | Y | PASS |
| d10-quad | `31f7ac47a204` | `4348bedf3c9a` | 132x91 | 4 | 03160 | Y | PASS |

Полные хэши (SHA256, r1 = r2):

| Дека | `benson.out` | `benson.svg` |
|---|---|---|
| d01-horizontal | `765c6da465152b2b360a816243f1de54bc303748fce2a2c0fe34bf0478d6d122` | `e587256d86d7295789a08fcb792c160b802ca64f87875498b9aa7fc915a3dbcb` |
| d02-vertical | `80c00d7bc876276be7547b6c226d29f6c87dffc7636bdaae7c87d2c54f8365d0` | `1da6cf813b54e199b3510f02963e9462fcdb39d24d0f49907f23c2e6685441c6` |
| d03-diagonal | `fa29663f8ab3553a46396d8b285d52760a04b08a4ae6065d9ede190f77f2985e` | `ac662c810d9ca1c8a0a1eea4b9e9464e0cbdbcce0f5165783660689bc410b717` |
| d04-rectangle | `9f48597bc1f628a00d11997355c2a71e32e0c4d8a599db8d62fcf2027f04094a` | `47b5f5dea796eee17b3986e16b8766f6f0eb8f169cf0f926a44662a5dbe22f72` |
| d05-zigzag | `0d1f4861937f429a04edbe2996e4993846725a4f3d85d9ff194f5e2b4d12e198` | `8bf1b69ab7f78a3b3eeeac4cb03fb5f82aa9e0ef2595d0d006b66529b9ca339b` |
| d06-steep | `3cdd5e337823e71e60706de8a952f9f0ac7ff99533534f649383a5c7ca4c73c9` | `d716b04e5149c72cfbd74e440a29ea72b10243c02311c796714bcc2fe167b580` |
| d07-shallow | `3ba59eb8a1ab26a168265b7c63665c4947f9f6f8df1d982cd1e5dbd28289b828` | `a7738621f4b1928d2b03b85f92964fd4645351f425b94999cd6b2c7b2803bde8` |
| d08-tiny | `4be196fc5b409c5f96c6db82ab9f326f93ca889ecf625e726786a4474ec473eb` | `c66e6c71028fcf387350f328858db076d82f313be15b6fdc53e643924296aa9e` |
| d09-triangle | `99bf6a4f817f95c312fd6358282b9004e03a6a4d4dd0174ecd4cf408870e7ef9` | `16f5ac56eff7155d6f4f966d805253a63e897d7cd89a7b046e4ed7e75ea4947f` |
| d10-quad | `31f7ac47a204b5f2b86ee978b1b5414215460046964d64e9f6b7a45fc13e4792` | `4348bedf3c9a3bd6a780c7c2830751a8cd18fed0e1e39b36c171f5b81db8ce62` |

## Фактические path из SVG (новые деки)

Строки ниже скопированы из `benson.svg` финального прогона.

| Дека | path |
|---|---|
| d09-triangle | `M 1 110 10 110 10 100` |
| d09-triangle | `M 10 100 110 100` |
| d09-triangle | `M 110 100 60 100 60 0` |
| d10-quad | `M 1 90 10 90 10 80` |
| d10-quad | `M 10 80 130 80` |
| d10-quad | `M 130 80 130 0` |
| d10-quad | `M 130 0 10 0` |

Обе новые деки дают осмысленные размеры (112x111 и 132x91) и 3/4 элемента
`<path>` по числу кадров. Десять SVG уникальны.

## Исторический отрицательный контроль (до исправления)

Со старым диском, где адрес `/PDEVXY/` был захардкожен, дека с тремя
различными координатами давала:

```
*PDEVXY* C 03154
NITI-C1 NPLOT=     3
NITI: summary schemes=3 frames=3 words=192 active=1 scheme=1210
```

При этом `benson.svg` был создан, но содержал 0 элементов `<path>`
(`width=2 height=1`). Четыре пары `MOVE`/`PLOT` давали `*PDEVXY* C 03155`
и тоже пустой SVG. После перехода на `CALL PDEV(FRAME(1))` те же деки дают
3 и 4 элемента `<path>`; старое ограничение снято.

## Оговорки

- Хэши привязаны к конкретному бинарнику dispak, образу диска 2348-niti.img
  и побайтному содержимому дек. Сборка другой версии или правка дека меняют
  хэши; это не считается регрессией без проверки геометрии.
- `benson.out`/`benson.svg` это пометка `[аналог NASA, БЕНСОН-501]`, а не
  реальный протокол НИТИ/БЭСМ-6.
- SVG не является «идеальной» геометрией: см. `EXPECTED.md` (шаги X затем Y,
  перевёрнутая ось Y, соединитель от начала координат, схлопывание точек).
- Раннер не трогает репозиторий: весь вывод идёт в `TMPDIR`, а при
  `KEEP_WORK` не задано рабочий каталог удаляется через `trap`. Git commit
  и push не выполнялись.
