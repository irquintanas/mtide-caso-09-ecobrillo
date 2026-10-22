# Caso 09 · EcoBrillo — el encargo

> Negocio y datos **ficticios**, creados para la asignatura. Es tu mismo caso de la J3.

## Qué ha pasado desde la J3

En la J3 limpiaste el parte en un cuaderno y contestaste tres preguntas. EcoBrillo quiere su parte de servicios cargado solo. Y quiere comprobar el agua que gasta cada furgoneta con los **contadores** del depósito, que ya registran sus lecturas.

Ahora conviertes aquel cuaderno en un **lakehouse** de verdad, en tu propio repositorio, y publicas un **portal** que
cuenta lo que has hecho. Cómo preparar el repositorio y el ciclo de trabajo de cada bloque: [README.md](README.md).

## Lo que tienes al empezar

- En bronce, el parte de la J3: `lakehouse/bronce/parte/fecha_carga=2026-05-06/`.
- En `dbt/models/plata/stg_parte.sql`, la limpieza que hiciste en la J3, con unos tests básicos (`_plata.yml`, `dbt/tests/`).
- `dbt build` en verde. La capa oro, vacía: la construyes tú.
- En `paginas/`, las cuatro páginas del portal que escribirás, cada una con un guion de lo que debe contar.

**Bronce no se toca nunca**: todo arreglo va en plata.

---

## Bloque 1 · La remesa nueva · rama `remesa`

1. `python herramientas/sistema_simulado.py remesa`: llega una entrega nueva del parte en `bronce/parte/fecha_carga=2026-05-16/` (unos diez días más de servicios).
2. `dbt build --project-dir dbt --profiles-dir dbt`. La remesa viene de un ordenador con otra configuración regional. `dbt build` ni siquiera llega a los tests.

   > 🔎 **Pista · mirar dentro antes de arreglar.** `dbt build` te dice *dónde* duele, no *por qué*.
   > Para eso tienes `dbt show`: ejecuta una consulta y te enseña el resultado sin construir nada.
   >
   > ```bash
   > dbt show --project-dir dbt --profiles-dir dbt --select <un_test>
   > dbt show --project-dir dbt --profiles-dir dbt --inline "select ... from {{ ref('<modelo>') }} ..."
   > dbt show --project-dir dbt --profiles-dir dbt --inline "select ... from {{ source('bronce', 'parte') }} ..."
   > ```
   >
   > El primero te enseña las filas que un test rechaza. Los otros dos te dejan preguntar lo que quieras
   > a plata o a bronce tal como llegó. Antes de tocar el SQL, intenta contestar tres preguntas:
   > **¿qué filas?**, **¿desde cuándo?** y **¿venía ya así en bronce?** Bronce guarda cada entrega en su
   > carpeta `fecha_carga=…`, y esa columna te deja comparar una entrega con otra.
   >
   > *Aquí el modelo ni se construye: no hay test que consultar y lo que haya en plata es de la ejecución anterior. Lee bien el mensaje de error (te dice la columna y el valor) y pregunta directamente a bronce cuántas filas son así y en qué entrega.*

3. Arregla `dbt/models/plata/stg_parte.sql` hasta que `dbt build` quede en verde y el problema esté resuelto (no siempre hay un test que lo grite: a veces tienes que escribirlo tú). Deja un comentario en el SQL: **qué** venía mal y **por qué** lo arreglas así.
4. Escribe `paginas/1-remesa.md`.
5. Pull request en tu repositorio, Actions en verde y lo fusionas.

## Bloque 2 · El oro · rama `oro`

Crea en `dbt/models/oro/` estos modelos, **con estos nombres exactos** (el portal y la jornada de Visualización los leen así):

| Modelo | Qué tiene |
|---|---|
| `dim_operario` | una fila por cada valor distinto de `operario` |
| `dim_furgoneta` | una fila por cada valor distinto de `furgoneta` |
| `dim_tipo_lavado` | una fila por cada valor distinto de `tipo_lavado` |
| `fact_servicios` | un servicio por fila: `servicio`, `fecha`, `operario`, `furgoneta`, `tipo_lavado`, `minutos`, `litros_agua`, `importe_eur`, `con_incidencia` |
| `pregunta_1` | ¿Qué **tipo de lavado** deja menos ingreso por hora? Una fila por `tipo_lavado`, con `tipo_lavado` en la primera columna y `ingreso_hora` (€/hora), de menor a mayor |
| `pregunta_2` | ¿Qué **operario** gasta más agua por hora? Una fila por `operario`, con `operario` en la primera columna y `l_agua_hora` (litros de agua por hora), de mayor a menor |
| `pregunta_3` | ¿Qué **furgoneta** acumula más incidencias por cada 100 horas de servicio? Una fila por `furgoneta`, con `furgoneta` en la primera columna y `incidencias_100h` (incidencias por 100 h), de mayor a menor |

> 🔎 **Pista · un modelo, un fichero.** Cada modelo de la tabla es un fichero `.sql` en `dbt/models/oro/`
> con su mismo nombre (`dim_tipo_lavado.sql`, `fact_servicios.sql`…). Dentro va **un solo `select`**, sin
> `create table`: dbt se encarga de guardarlo como Parquet en `lakehouse/oro/`. Las dimensiones y el hecho
> leen de plata con `{{ ref('stg_parte') }}`; las preguntas leen del hecho con `{{ ref('fact_servicios') }}`.
> Así dbt sabe en qué orden construirlos.
>
> Ve de uno en uno: escribes el modelo, lo construyes solo a él y miras lo que ha salido.
>
> ```bash
> dbt build --project-dir dbt --profiles-dir dbt --select dim_tipo_lavado
> dbt show  --project-dir dbt --profiles-dir dbt --select dim_tipo_lavado
> ```
>
> Antes de pasar al siguiente, comprueba que el resultado tiene sentido: ¿cuántas filas salen?
> (`dbt show` enseña cinco; `--limit` te deja ver más, y en el bloque 1 ya viste cómo preguntar lo que quieras con `--inline`),
> ¿hay alguna repetida o vacía?, ¿las columnas se llaman exactamente como pide la tabla? Para `_oro.yml`, toma como
> plantilla `dbt/models/plata/_plata.yml`: ahí está la forma de escribir un test con `arguments:`.

En un `_oro.yml`, sus tests: en las dimensiones, `unique` y `not_null`; en el hecho, `unique` en `servicio` y `relationships` con cada dimensión.

> 🔎 **Pista · los tests del oro.** `_oro.yml` tiene la misma forma que `dbt/models/plata/_plata.yml`:
> una entrada por modelo y, dentro, sus columnas con sus `data_tests`. `unique` y `not_null` se escriben tal cual.
> `relationships` necesita dos datos, igual que `accepted_values` necesita su lista: a qué modelo apunta y en qué
> columna tiene que encontrar el valor. Escríbelos dentro de `arguments:`.
>
> Lanza `dbt build` completo: todo en verde y sin avisos. Después comprueba que los tests vigilan de verdad:
> apunta un momento un `relationships` a la dimensión equivocada, mira cómo se pone rojo y déjalo como estaba.

Escribe `paginas/2-oro.md`: tu estrella y las tres respuestas. Con la remesa nueva (un 25 % más de datos), ¿siguen saliendo las mismas que en la J3? Pull request, verde, fusionas.

> 🔎 **Pista · la página.** Las reglas están en el README (*Las cifras de tus páginas*): borra la primera línea,
> cambia cada `> ✏️` por tu texto y conserva las marcas `{{ … }}`, que son las que ponen las cifras.
> Antes de subir:
>
> ```bash
> python web/build.py --check    # te dice qué línea del guion queda o qué marca no tiene valor
> python web/build.py            # genera el portal: abre _site/index.html
> ```
>
> En la portada, las tres primeras preguntas tienen que haber dejado de estar en gris y la bitácora tiene que
> marcar «2 · El oro» como escrita.

## Bloque 3 · Fuentes nuevas · rama `fuentes`

1. `python herramientas/sistema_simulado.py fuentes`: llegan estos ficheros a bronce y quedan declarados en `dbt/models/plata/_fuentes.yml`.

| Fichero | Qué es | Columnas |
|---|---|---|
| `bronce/furgonetas/furgonetas.csv` | capacidad del depósito de agua de cada furgoneta (litros) | furgoneta, deposito_l |
| `bronce/eventos/lecturas_contador_2026-05-18.json` | Los contadores de agua exportan un registro con una `lectura` de cada furgoneta cada pocos minutos, y un evento `fin_servicio` al acabar cada lavado. | evento_id, furgoneta, tipo (lectura / fin_servicio), ts, contador_l |

2. **El giro.** El contador es **acumulado**: lo que gastas es la diferencia con la lectura anterior. Y cuando se rellena el depósito **vuelve a cero**. Además, se pierden algunas lecturas.

   > 🔎 **Pista · conoce el registro antes de modelarlo.** Un registro de eventos no es una tabla limpia:
   > cada fila es algo que pasó, y una misma cosa (un pedido, un vuelo, un ticket…) puede ocupar varias filas.
   > Antes de escribir `stg_eventos`, pregúntale a bronce con `dbt show --inline`, como en el bloque 1:
   > ¿cuántas filas hay y cuántos identificadores distintos? ¿Qué tipos de evento hay y cuántos de cada?
   > ¿Entre qué horas y qué valores se mueve? ¿Cómo se ve una misma cosa de principio a fin?
   >
   > Para resolver el giro casi siempre necesitarás una de estas dos herramientas de SQL:
   > **agrupar** por la cosa que importa (`group by`, con `count(*) filter (where …)` o `min(…) filter (where …)`),
   > o una **función de ventana** (`row_number()`, `lag()`… `over (partition by … order by …)`) para quedarte
   > con una fila de cada grupo o comparar cada fila con la anterior. Cuál te sirve depende de tu giro.

3. Modelos de plata: `stg_furgonetas` y `stg_consumos` y `stg_eventos` (el registro lo lees con `source('bronce', 'eventos')`).
4. **Test protagonista.** **Un consumo de agua nunca es negativo.** Calcula el consumo entre lecturas en un modelo de plata (`stg_consumos`) y escribe un test que devuelva los consumos negativos. Rojo si restas sin pensar; verde cuando entiendas qué pasa al rellenar.

   > 🔎 **Pista · el test protagonista.** Si es un test genérico (`unique`, `relationships`…), va en el `.yml`
   > de plata, como los del bloque 2. Si es singular, es un `select` en `dbt/tests/` que devuelve las filas
   > que **incumplen** la regla; si no devuelve nada, pasa. En esa carpeta tienes dos de ejemplo.
   > Escríbelo **antes** de arreglar los datos y comprueba que se pone rojo: un test que nunca ha fallado
   > no demuestra nada. Con `dbt show --select <tu_test>` ves qué filas lo hacen fallar.

5. **Pregunta 4** (`dbt/models/oro/pregunta_4.sql`): ¿Qué furgoneta **gasta más agua por servicio**, medida por el contador? ¿Coincide con lo que dice el parte?

   > 🔎 **Pista · la pregunta 4.** Cruza la fuente nueva con el registro o con tu oro. Antes de unirlos,
   > decide **a qué nivel** contestas (una fila por zona, por impresora, por creador…) y lleva cada parte
   > a ese nivel por separado; después las unes. Si unes dos tablas que tienen varias filas por cada zona,
   > los números se multiplican. Mira el resultado con `dbt show --select pregunta_4`: ¿encaja con lo que
   > viste al explorar el registro?

6. Escribe `paginas/3-fuentes.md`. Pull request, verde, fusionas.

   > 🔎 **Pista · la página.** Igual que en el bloque 2: `python web/build.py --check` y `python web/build.py`.
   > Ahora es la cuarta pregunta de la portada la que tiene que dejar de estar en gris.

## Bloque 4 · El memo · rama `memo`

Escribe `paginas/memo.md`: el memo para la dirección de EcoBrillo, con las cuatro respuestas citadas con marcas. La comprobación exige que existan `pregunta_1` a `pregunta_4`. Repasa el portal entero antes de fusionar.

---

## Lo que se entrega

- Tu repositorio en tu cuenta, con los cuatro pull requests fusionados y la última ejecución de `main` en verde.
- Tu portal publicado, con sus cuatro páginas escritas, y tu `dbt-docs`.
- La presentación oral (5 minutos): con tu portal en pantalla, el problema de calidad, tu test protagonista, las cuatro respuestas y tu recomendación.
