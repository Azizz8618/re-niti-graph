# Прототипы нативных подпрограмм библиотеки 22 (ГРАФОР-СУД)

Исследование выполнено по задаче: восстановить число и типы аргументов подпрограмм
библиотеки 22, чтобы вызывать родные DMS-модули из Фортран-деки.
Только research и документация; код `dispak/`, `fortran/`, существующие `verify/` и
`docs/` не изменялись. Новые файлы: этот документ и каталог
`verify/native-decks/sig-*.b6`.

---

## 1. Метод восстановления прототипа

### 1.1. Соглашение вызова FORTRAN -> автокод (БЭСМ-6 / ДИСПАК)

Первичный источник: `besm6-new/besm6.net/book/fortran-1976/03-madlen.md:671-725`
(§ 46 «Правила оформления автокодных подпрограмм»):

- адреса фактических параметров заталкиваются в магазин в порядке следования;
  на входе в подпрограмму адрес **последнего** параметра лежит в сумматоре
  (`03-madlen.md:689-707`);
- R13 хранит адрес возврата; R8-R12 и R14 можно портить; R1-R7 надо сохранить;
- извлечение адресов идёт в обратном порядке; SUBROUTINE выталкивает ровно *n*
  слов, FUNCTION - *n-1* (`03-madlen.md:713-721`).

Типовая «шапка» модуля библиотеки 22 (пример `MOVE1.mad:376-387`,
`ARCIA.mad:223-234`):

```text
*xxxxB:7,MTJ,8      ; сохранить R13 -> R8
14,MTJ,10           ; ...
7,VTM,*yyyyB        ; база ячеек параметров
7,STX,21B           ; вытолкнуть адрес параметра N в (база)+21B
7,STX,20B           ; ... параметра N-1
7,STX,17B           ; ... параметра 1
,ITS,13             ; сохранить R13
,ITS,8              ; сохранить R8
,ITS,               ; сохранить сумматор
,NTR,3
,NTR,2
10,UJ,
```

**Число инструкций `7,STX,...` в шапке равно числу формальных параметров.**
Если параметров много, компилятор использует цикл с индексным регистром R9:

```text
7,VTM,*база
9,VTM,12B           ; 12B = 10 параметров (POLREG)
*метка:9,UTM,-1
9,UTC,
7,STX,40B           ; одна STX в цикле = все параметры
9,V1M,*метка
```

Значение `9,VTM,N` (восьмеричное) и есть число параметров. Проверено на
`POLINE` (`9,VTM,7` -> 7), `HISTGM` (`9,VTM,6` -> 6), `THREED`
(`9,VTM,15B` -> 13), `HCSURF` (`9,VTM,16B` -> 14), `AXES` (`9,VTM,11B` -> 9),
`POLREG` (`9,VTM,12B` -> 10). Независимое подтверждение - число `,ITS,14`
перед каждым `13,VJM,<имя>` в call-сайтах: `ARCIA` - 3 во всех 9 точках,
`MINMAX` - 4, `LIMITS` - 4, `BOX` - 4, `LINEMO` - 5, `HCSURF` - 14.

Типы определялись по использованию ячеек параметров в теле модуля:
`WTC,*cell / ,XTA,` - чтение **вещественного** скаляра (или адреса элемента
массива, если дальше идёт `1,UTC,-1`); `,ITA,14` + `IABS`/`FLOAT`/`I*MU*I` -
**целое**; `,XTS,` / `,ATX,` по адресу из `WTC,*cell` - выходной параметр;
`14,VTM,*cell / ,ITS,14` в вызове - передача адреса массива или строки.

Второй независимый источник - задокументированный Grafor API в
`besm6-new/dubna/examples/grafor/*.dub` (тот же семейный API): там числа
аргументов совпадают с нативными шапками для LIMITS, BOX, POLINE, POLREG,
HISTGM, MINMAX, THREED, SYMBOL, LINEMO, AXES. Фортран-порт
`re-niti-graph/fortran/*.FTN` **не** является надёжным источником прототипа:
например, `ARCIA.FTN:2` объявляет 5 аргументов, `LIMITS.FTN` - 8,
`HISTGM.FTN` - 4, `THREED.FTN` - 3, `HCSURF.FTN` - 2, хотя нативная шапка
даёт 3, 4, 6, 13 и 14 соответственно.

### 1.2. Два канала данных в ГРАФОР

1. **Стек (R15)** - сверху перечисленные формальные параметры; адреса
   фактических аргументов, не значения.
2. **Общие блоки `*GF...*`** (`*GFBFTR*`, `*GFAFTR*`, `*GFATRN*`, `*GFBLAN*`,
   `*GFMATR*`, `*GFGEL*`, ...) и **буферные примитивы вторичного каталога**
   `RDB`/`IRDB` (чтение вещественного/целого слота) и `WDB`/`IWDB` (запись).
   `RDB`/`IRDB` получают номер слота **через модификатор**, без `,ITS,`:
   `14,VTM,*cell / ,ITA,14 / 13,VJM,RDB` (например `ARCIA.mad:107-114`).

Поэтому «аргумент подпрограммы» и «параметр в буфере ГРАФОР» - разные вещи:
например `HISTGM` имеет 6 формальных аргументов, но дополнительно читает
слоты 2 и 3 через `IRDB` (`HISTGM.mad:20-33`).

---

## 2. Сводная таблица прототипов

Уверенность: **HIGH** - число аргументов подтверждено шапкой и/или вызовами и
прогоном; **MED** - число подтверждено шапкой/вызовами, типы - по использованию
и/или аналогу Дубны; **LOW** - только косвенные данные.

| Подпрограмма | N | Типы (предполагаемые) | Как передаются | Источник | Уверенность |
|---|---:|---|---|---|---|
| `MOVE1` | 3 | `INTEGER N; REAL X(*), Y(*)` | стек, 3 адреса; R13/R14; данные ещё через `*GFATRN*`, `*GFBLAN*`, `RDB` | `MOVE1.mad:376-387`, `functions/FUNCTIONS-I-M.md:68`, `verify/native/native-final.b6:17`; прогон OK | HIGH |
| `ARCIA` | 3 | `REAL R, A0, DA` (порядок R,A0,DA - гипотеза) | стек, 3 адреса; текущая точка в `*GFBFTR*`; точка эмиттится через `MOVE` | `ARCIA.mad:223-234`; 9 call-сайтов по 3 `,ITS,`; прогон `sig-arcia3/5` | HIGH (N) / MED (types) |
| `PAGE` | 5 | `REAL X,Y; CHARACTER*(*) TITLE; INTEGER NTITLE, MODE` | стек, 5 адресов; тело во вторичном каталоге утеряно | `docs/SECONDARY-CATALOG.md:116`; `dubna/examples/grafor/README.md:86`; `sig-page5.b6` | MED |
| `ENDPG` | 1 | `INTEGER FLAG` или `CHARACTER*4 NAME` (у Дубны и то и другое) | стек, 1 адрес; вторичный каталог, тело утеряно / указывает на SYMTAB | `GFFALS.mad:49-51` (1 push); `SECONDARY-CATALOG.md:117`; Dubna `endpg(0)` | MED |
| `LIMITS` | 4 | `REAL X1,X2,Y1,Y2` | стек, 4 адреса; результат пишется в буфер через `WDB`/`IWDB` | `LIMITS.mad:79-90`, `MNMX.mad:516-524`, `TDLIM.mad:215-223`; Dubna `limits` 4; `sig-limits4.b6` | HIGH (N) / MED (types) |
| `GETPEN` | 1 | `INTEGER PEN` (1..6) | в библиотеке 22 **не найден**; только API Дубны | `dubna/examples/grafor/README.md:63-65`, `getpen(3)` | LOW для lib22 / HIGH для Grafor API |
| `SYMBOL` | 6 | `REAL X,Y,SIZE; CHARACTER*(*) TEXT; INTEGER NL; REAL ANGLE` | стек, 6 адресов; тело во вторичном каталоге зачищено | `AXES.mad:601,637,...` (по 6 `,ITS,`); Dubna `symbol(X,Y,SIZE,TEXT,N,ANGLE)`; `sig-symbol6.b6` -> `OTCYTCTBYET SYMBOL` | HIGH (N) / MED (types) |
| `AXES` | 9 | `CHARACTER*6 XL; INTEGER NXL; REAL STEPX; INTEGER NTX; CHARACTER*6 YL; INTEGER NYL; REAL STEPY; INTEGER NTY; INTEGER MODE` | стек, 9 адресов (цикл `9,VTM,11B`); параметры читаются также через `IRDB`/`RDB` | `AXES.mad:1396+` (шапка), `functions/FUNCTIONS-A-B.md:99`; Dubna `axes(...)` 9; `sig-axes9.b6` | HIGH (N) / MED (types) |
| `LINEMO` | 5 | `REAL X(*),Y(*); INTEGER N, MODE, MARK` | стек, 5 адресов; данные через `IRDB`/`RDB`, плюс `WHERE`, `TMF` | `LINEMO.mad:287+`; `SUPLIN.mad:140-152` (5 push); Dubna `linemo(x,y,85,2,10)` | HIGH |
| `BROKEN` | 4 | `REAL X,Y,DX,DY` | стек, 4 адреса; тело во вторичном каталоге зачищено | `SECONDARY-CATALOG.md:115-125`; Dubna `broken(0.5,0.2,0.3,0.2)`; `sig-group-secondary.b6` -> missing | MED |
| `BRLINE` | 3 | `REAL X(*),Y(*); INTEGER N` | стек, 3 адреса; тело во вторичном каталоге зачищено | `LINNUM.mad:332,524` (3 push); `SUPLIN.mad:162` (3 push); Dubna `brline(x,z,85)`; `sig-group-secondary.b6` -> missing | MED |
| `POLREG` | 10 | 6 `REAL` + 4 `INTEGER` (порядок по Dubna: X,Y,Xmin,Xmax,Ymin,Ymax, I1,I2,I3,I4) | стек, 10 адресов (`9,VTM,12B`), плюс `IRDB`/`RDB`/`WDB`/`IWDB` | `POLREG.mad:423+`, `functions/FUNCTIONS-N-R.md:36`; Dubna `polreg(...)` 10; `sig-polreg10.b6` | HIGH (N) / MED (types) |
| `POLINE` | 7 | `REAL X(*),Y(*); INTEGER N, I1, IMARK, I2, I3` | стек, 7 адресов (`9,VTM,7`), плюс `IRDB`, `TPF`, `WHERE` | `POLINE.mad:334+`, `FUNCTIONS-N-R.md:35`; Dubna `poline(r,t,180,-1,1,0,1)`; `sig-poline7.b6` | HIGH (N) / MED (types) |
| `BOX` | 4 | `REAL X,Y,DX,DY` | стек, 4 адреса; рисует 5 вызовами `MOVE(X,Y,IPEN)` | `BOX.mad:68-75`, `REGION.mad:157-167` (4 push); Dubna `box(0,0,10,8)`; `sig-box4.b6` | HIGH |
| `SET` | 1 | `INTEGER MODE` (0..3) | в основном каталоге тело зачищено; вторичная запись `SET` | `SECONDARY-CATALOG.md:115`; Dubna `set(0..3)`; `sig-group-secondary.b6` -> missing | MED |
| `MINMAX` | 4 | `REAL Y(*); INTEGER N; REAL YMN, YMX` (2 последних - выход) | стек, 4 адреса; вызывает `AMIN1`/`AMAX1` (FOREX) | `MINMAX.mad:62-75`; `LEVFUN.mad:34`, `LSFIT.mad:78,106`; Dubna `minmax(yv,12,ymn,ymx)`; `sig-minmax4.b6` OK | HIGH |
| `HISTGM` | 6 | 4 `REAL`/массива + 2 `INTEGER` (у Дубны: `R,R,Y(*),H(*),I,I`) | стек, 6 адресов (`9,VTM,6`), плюс `IRDB` слоты 2,3 | `HISTGM.mad:18-39,520+`, `FUNCTIONS-E-H.md:419`; Dubna `histgm(0.,1.,y0,yv,-12,4)`; `sig-histgm6.b6` | HIGH (N) / MED (types) |
| `INIT` | 0 | нет | шапка без `STX`; только `*GFMATR*` и `HCUNIT` | `INIT.mad:32-40`, `FUNCTIONS-I-M.md:65`; `sig-init0.b6` OK | HIGH |
| `ISOMET` | 0 | нет | шапка без `STX`; только `*GFMATR*` и 2 вызова `TDROT` | `ISOMET.mad:47-55`, `FUNCTIONS-I-M.md:66`; `sig-isomet0.b6` OK | HIGH |
| `THREED` | 13 | у Дубны: `REAL X(*),Y(*),Z(*); INTEGER NU,NV,I1,I2,I3,IP1,IP2; ...` (13 всего) | стек, 13 адресов (`9,VTM,15B`), плюс `*GFMATR*` и `HCSURF` | `THREED.mad:978+`, `FUNCTIONS-S-Z.md:206`; Dubna `threed(x,y,z,41,41,1,41,1,41,0,100,a,ar)`; `sig-threed13.b6` | HIGH (N) / MED (types) |
| `SURF` | - | **не найден** в библиотеке 22 | у Дубны `surf(x,y,z)` - 3 аргумента, но это другой Grafor | `dubna/examples/grafor/surface.dub`; в lib22 есть только `HCSURF` (14 адресов) | NOT FOUND |
| `HCSURF` (доп.) | 14 | целочисленные индексы/лимиты + вещественные масштабы | стек, 14 адресов; вызывается из THREED с 14 `,ITS,` | `HCSURF.mad:273+`; `THREED.mad:400-442` | HIGH (N) |

### Замечания по отдельным прототипам

- **`ARCIA`**. param1 -> `*0216B`, param2 -> `*0217B`, param3 -> `*0220B`.
  Тело читает `GFBFTR(1/2)` как текущую точку, `param1` через `ABS` как радиус,
  разность `param2-param3` как угловой шаг/диапазон, затем цикл `MOVE`
  (`ARCIA.mad:25-45,115-121,170-198`). Вызывающие `CIRC`, `ARCIB`, `ARCIC`,
  `ARCID`, `ARROW`, `DIMDRO`, `FATARC` передают ровно 3 адреса. Фортран-порт
  `ARCIA.FTN:2` (5 аргументов) не соответствует нативному коду.
- **`MINMAX`**. param1 - адрес массива (читается и с индексом `1,UTC,-1`),
  param2 - счётчик (цикл до `WTC,*0053B`), param3/param4 - выходы min/max
  (`MINMAX.mad:17-61`).
- **`HISTGM`**. param1-param4 - адреса массивов (используются через
  `1,VTM` / `1,UTC,-1` и передаются в `TMF`), param5/param6 - скаляры
  (знаковые проверки, `ABS`, `R*ST*I`) (`HISTGM.mad:38-64,72-150`).
- **`INIT`, `ISOMET`** - единственные в списке модули с **нулевым** числом
  формальных параметров; все входные данные берутся из COMMON.

---

## 3. Экспериментальная проверка (деки `verify/native-decks/sig-*.b6`)

Все деки строились по образцу `verify/native/native-final.b6`:
`*perso:602700,cont`, `*forex`, `*library:22`, `*execute`. Прослойка - штатная
`verify/native/shim.b6` (PERSO `0o2700`: `PLOT`, `MOVE`, `RDB`, `ENDPG`, `PAGE`).
Прогон в `/var/tmp/sig-research/run`, логи там же (в репозиторий не попадают).

| Дека | Вызов | Результат |
|---|---|---|
| `sig-arcia3.b6` | `MOVE1(2,X,Y)` + `ARCIA(5.0,0.0,0.5)` | без ошибок, кадр 1600 байт, 197 шагов |
| `sig-arcia1.b6` | `MOVE1` + `ARCIA(0.0)` | без ошибок, 185 шагов |
| `sig-arcia5.b6` | `MOVE1` + `ARCIA(10.,10.,0.,0.5,12)` | без ошибок, 195 шагов |
| `sig-arcia-alone.b6` | `ARCIA(R,A0,DA)` без инициализации COMMON | `ДЕЛЕНИЕ НА НУЛЬ` |
| `sig-arcia-alone1.b6` | `ARCIA(0.0)` без COMMON | `ДЕЛЕНИЕ НА НУЛЬ` |
| `sig-arcia-alone5.b6` | `ARCIA(10.,10.,0.,0.5,12)` без COMMON | **`НЕ ТЕ ПАРАМЕТРЫ`** |
| `sig-minmax4.b6` | `MINMAX(Y,4,YMN,YMX)` | `КОНЕЦ ЗАДАЧИ`, без ошибок |
| `sig-box4.b6` | `BOX(1.,1.,10.,8.)` | 5 сегментов `MOVE` отрисованы, затем зависание: `15 30 00000 uj` (R15 испорчен прослойкой `MOVE`, см. §4) |
| `sig-init0.b6` | `CALL INIT` | `КОНЕЦ ЗАДАЧИ`, без ошибок |
| `sig-isomet0.b6` | `CALL ISOMET` | `КОНЕЦ ЗАДАЧИ`, без ошибок |
| `sig-limits4.b6` | `LIMITS(0.,14.,0.,10.)` | `ОТСУТСТВУЕТ WDB`, `ОТСУТСТВУЕТ IWDB` |
| `sig-histgm6.b6` | `HISTGM(0.,1.,Y,Z,-12,4)` | `ОТСУТСТВУЕТ IRDB` |
| `sig-poline7.b6` | `POLINE(X,Y,10,-1,1,0,1)` | `ОТСУТСТВУЕТ IRDB` |
| `sig-polreg10.b6` | `POLREG(15.,11.,0.,10.,0.,360.,0,0,0,0)` | `ОТСУТСТВУЕТ IRDB`, `IWDB`, `WDB`, `SYMBOL` |
| `sig-axes9.b6` | `AXES('X',6,1.,5,'Y',6,.3,4,0)` | `ОТСУТСТВУЕТ IRDB`, `SYMBOL` |
| `sig-threed13.b6` | `THREED(...,13 арг.)` | `ОТСУТСТВУЕТ IRDB` |
| `sig-symbol6.b6` | `SYMBOL(1.,2.,.8,'ABCD',4,0.)` | `ОТСУТСТВУЕТ SYMBOL` |
| `sig-page5.b6` | `PAGE(14.,10.,'PAGE',4,0)` | `КОНЕЦ ЗАДАЧИ` (SHIM-заглушка PAGE) |
| `sig-group-secondary.b6` | `PEN(2)`, `GETPEN(3)`, `SET(1)`, `BROKEN(...)`, `BRLINE(...)` | `ОТСУТСТВУЕТ` для всех пяти |

Диагностика линкера в логах пишется латиницей: `OTCYTCTBYET <ИМЯ>`, а не
кириллическим `ОТСУТСТВУЕТ`.

Дополнительно подготовлены три групповые деки-шаблона (по 3-5 вызовов в каждой),
которые нужно прогонять уже с расширенным SHIM из §4:

- `sig-group-core.b6` - `MOVE1(3)`, `ARCIA(3)`, `BOX(4)`, `LIMITS(4)`, `MINMAX(4)`;
- `sig-group-draw.b6` - `LINEMO(5)`, `POLINE(7)`, `POLREG(10)`, `HISTGM(6)`, `SYMBOL(6)`;
- `sig-group-3d.b6` - `INIT(0)`, `ISOMET(0)`, `THREED(13)`, `AXES(9)`, `ENDPG(1)`.

Они не прогонялись: текущая прослойка не обеспечивает выталкивание аргументов в
`MOVE`/`PLOT` и не содержит `IRDB`, `WDB`, `IWDB`, `SYMBOL`.

### 3.1. Разбор сообщения «НЕ ТЕ ПАРАМЕТРЫ» у `ARCIA`

`НЕ ТЕ ПАРАМЕТРЫ` - это не диагностика Fortran-компилятора о неверном числе
аргументов, а одно из 8 сообщений **GRAFOR-овнера `GFFALS`**
(`GFFALS.mad:132-135`, таблица сообщений в `functions/FUNCTIONS-E-H.md:298-307`).
`ARCIA` вызывает `GFFALS` со своим кодом `*0166B = INT 5` на ветке проверки
`IVEST` (`ARCIA.mad:52-56,219-221`).

Эксперимент доказал: с 5 аргументами (и без предварительной инициализации COMMON)
сообщение появляется; с 3 аргументами его нет, а при правильно
инициализированном `MOVE1` отрабатывает нормально. Причина - **разбаланс
магазина**: `ARCIA` выталкивает 3 адреса, а передано 5; лишние слова остаются
в стеке, ячейки `*0216B/*0217B/*0220B` получают чужие значения, `IVEST`
возвращает признак ошибки и вызывается `GFFALS`. Вывод: `ARCIA` ждёт **три**
аргумента; гипотеза «ждёт 1» из `verify/native/README.md:72-74` неверна,
она объясняется тем, что при 1 аргументе стек также разбалансирован.
Одновременно опровергнут прототип `ARCIA(X0,Y0,A0,DA,N)` из `ARCIA.FTN:2`.

---

## 4. Какие точки входа вторичного каталога нужны в SHIM

Штатная прослойка `verify/native/SHIM.mad` содержит только `PLOT`, `MOVE`,
`RDB`, `ENDPG`, `PAGE`. Для проверки прототипов из §2 нужно добавить:

| Entry | Число аргументов | Назначение в SHIM | Кто вызывает |
|---|---:|---|---|
| `PLOT` | 3 | уже есть; выдаёт ЭК 1210/1211 (кадр) | `MOVE1`, `MOVE2`, `MOVE3`, ... |
| `MOVE` | 3 | уже есть; должен **выталкивать 3 адреса** (сейчас нет, см. ниже) | `ARCIA`, `BOX`, `AXES`, `POLINE`, ... |
| `RDB` | 1 (через M, не стек) | уже есть; вернуть вещественное из буфера | `ARCIA`, `LIMITS`, `POLREG`, ... |
| `PAGE`, `ENDPG` | 5 и 1 | уже есть; заглушки возврата | GFFALS, Fortran-драйвер |
| `IRDB` | 1 (через M) | **добавить**: вернуть целое из буфера | `HISTGM`, `POLINE`, `POLREG`, `AXES`, `THREED`, `LINEMO` |
| `WDB` | 2 (стек: слот, адрес) | **добавить**: записать вещественное в буфер | `LIMITS`, `POLREG`, `REGION` |
| `IWDB` | 2 (стек: слот, адрес) | **добавить**: записать целое в буфер | `LIMITS`, `POLREG` |
| `SYMBOL` | 6 | **добавить**: заглушка с 6 `,STX,`; при желании эмитировать текст | `AXES`, `AXISC`, `POLREG`, `REGION` |
| `BRLINE` | 3 | **добавить**: заглушка с 3 `,STX,` | `LINNUM`, `SUPLIN` |
| `BROKEN` | 4 | **добавить**: заглушка с 4 `,STX,` | Fortran-драйвер (Dubna API) |
| `PEN`, `GETPEN`, `SET` | 1, 1, 1 | **добавить**: заглушки с 1 `,STX,`; `GETPEN` может возвращать номер пера | Fortran-драйвер |
| `TMF`, `MARKER`, `WHERE`, `TPF`, `IABS`, `ISIGN`, `FLOAT` | по 1-8 | часть уже линкуется из FOREX/основного каталога; проверить по `OTCYTCTBYET` в логе | `HISTGM`, `POLINE`, `LINEMO` |

**Критическое требование к заглушкам.** Каждая заглушка должна выталкивать
ровно столько адресов, сколько параметров объявлено, и восстанавливать R15.
Штатная `MOVE` в `SHIM.mad:8-12` этого не делает: `13,VJM,PLOT / 13,UJ,` оставляет
3 слова на стеке за вызов. Пяти вызовов `BOX -> MOVE` достаточно, чтобы R15
ушёл в `030000B` и программа зависла на `uj 15,30`. Минимальная схема заглушки:

```text
NAME: ,NAME,NAME
7,VTM,*SCR
7,STX,2          ; вытолкнуть адрес последнего параметра
7,STX,1
7,STX,0          ; ... первого
,STX,            ; восстановить сохранённый сумматор (R15)
13,UJ,           ; R13 не портился - leaf-заглушка
SCR: ,BSS,3
,END,
```

(Для `PLOT` надо сохранить исходную последовательность ЭК 1210/1211 и
указатель буфера кадра: её changing можно проверять только после того, как
будет подтверждено на практике, берёт ли ЭК адрес буфера из сумматора или из R1; см.
`fortran/verify/PDEV.mad:15-23`.)

---

## 5. Что доказано / что гипотеза / что не найдено

### Доказано ( statically + runtime)

1. Число формальных аргументов всех модулей с телом в §2 получено из шапок `.mad`
   и подтверждено числом `,ITS,` в calling-сайтах (ARCIA - 9 сайтов, MINMAX - 3,
   LIMITS - 3, BOX - 1, LINEMO - 1, HCSURF - 2).
2. `ARCIA` имеет ровно **3** аргумента; сообщение `НЕ ТЕ ПАРАМЕТРЫ` при 5
   аргументах есть `GFFALS`-код из-за разбаланса магазина, а не «ожидание 1
   аргумента» (прогон `sig-arcia-alone5.b6` против `sig-arcia-alone.b6`).
3. `MOVE1(N,X,Y)` (3), `MINMAX(A,N,AMN,AMX)` (4), `INIT()` (0), `ISOMET()` (0)
   реально вызываются из Фортран-деки с `*library:22` и отрабатывают без ошибок.
4. `BOX` имеет 4 вещественных аргумента: все 5 сегментов `MOVE` отрисованы
   до зависания, вызванного дефектом текущей SHIM.
5. Точки входа `IRDB`, `WDB`, `IWDB`, `SYMBOL`, `BRLINE`, `BROKEN`, `PEN`,
   `GETPEN`, `SET` отсутствуют в текущей прослойке и/или-library и дают
   `OTCYTCTBYET` при линковке; `PAGE`, `ENDPG`, `PLOT`, `MOVE`, `RDB` уже есть.
6. Вызовы из Дубны (`besm6-new/dubna/examples/grafor/`) дают те же числа
   аргументов для всех подпрограмм списка, у которых есть дубнинский аналог
   (PAGE, ENDPG, GETPEN, SYMBOL, AXES, LINEMO, BROKEN, BRLINE, POLREG, POLINE,
   BOX, SET, LIMITS, MINMAX, HISTGM, THREED).

### Гипотеза

1. Точный порядок и имена параметров `ARCIA`: гипотеза `(R, A0, DA)` по
   использованию param-ячеек и вызову из `CIRC.mad:36-43`, где передаются
   указатель на радиус, `0.0` и константа `DK0` (π/2). Не проверено прогоном с
   осмысленными числами из-за неинициализированных `*GFBFTR*`/`*GFGOBS*`.
2.семантика 4 младших параметров `POLREG` и 5 младших `LINEMO`/`HISTGM`
   (целые/вещественные флаги) - по дубнинским аналогам; нативная шапка даёт только
   число, а не тип.
3. `PAGE` (5) и `ENDPG` (1): тела во вторичном каталоге утеряны, прототипы
   взяты из Grafor API Дубны; нативная сигнатура может отличаться.
4. `SYMBOL` (6) - число подтверждено calling-сайтами `AXES`, но типы (особенно
   4-й аргумент - строка vs. массив слов) нуждаются в проверке с реальным
   entry в SHIM, который печатает текст.

### Не найдено

1. **`GETPEN`, `SURF`, `SET`, `BROKEN`, `BRLINE`, `PAGE`, `ENDPG`, `SYMBOL`,
   `PEN`, `PLOT`, `MOVE` как DMS-модули с телом в библиотеке 22** - они
   являются точками вторичного каталога (`SECONDARY-CATALOG.md:104-125`) или
   вообще отсутствуют (GETPEN, SURF). Их прототипы можно восстановить только
   по calling-сайтам и Дубне.
2. **`SURF`** в библиотеке 22 нет. Ближайший модуль - `HCSURF` с 14
   аргументами; `surf(x,y,z)` из Дубны - другой уровень API.
3. Тип 3-го аргумента `PLOT` (нативные вызовы передают 3 `,ITS,`) не установлен
   из-за нерасшифрованного тела `secondary/madlen/PLOT.mad` (`dunno` в 14 местах).
4. Нет исчерпывающего описания форматов `IRDB/WDB/IWDB` в самой библиотеке 22;
   их контракт («слот -> ячейка») выведен из calling-сайтов и Grafor API.

---

## 6. Источники

- `functions/FUNCTIONS-A-B.md:74,99,118`; `FUNCTIONS-E-H.md:305,419`;
  `FUNCTIONS-I-M.md:43,46,65,66,68`; `FUNCTIONS-N-R.md:35,36`;
  `FUNCTIONS-S-Z.md:206`.
- `madlen/{MOVE1,ARCIA,AXES,LIMITS,LINEMO,POLREG,POLINE,BOX,MINMAX,HISTGM,INIT,ISOMET,THREED,HCSURF,GFFALS}.mad`
  (шапки, CALL-сайты, DATA/SET), `madlen/INDEX.md`.
- `functions/FUNCTIONS.md` (238 DMS-модулей), `extract/catalog.txt`.
- `docs/SECONDARY-CATALOG.md:62-125,160-172`.
- `verify/native/{SHIM.mad,shim.b6,native-final.b6,README.md}`;
  `fortran/verify/PDEV.mad`.
- `besm6-new/besm6.net/book/fortran-1976/03-madlen.md:671-725`.
- `besm6-new/dubna/examples/grafor/README.md:37-99` и `*.dub`.
- Собственные прогоны: деки `verify/native-decks/sig-*.b6`, логи в
  `/var/tmp/sig-research/run/`.
