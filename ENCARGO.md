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

En un `_oro.yml`, sus tests: en las dimensiones, `unique` y `not_null`; en el hecho, `unique` en `servicio` y `relationships` con cada dimensión.

Escribe `paginas/2-oro.md`: tu estrella y las tres respuestas. Con la remesa nueva (un 25 % más de datos), ¿siguen saliendo las mismas que en la J3? Pull request, verde, fusionas.

## Bloque 3 · Fuentes nuevas · rama `fuentes`

1. `python herramientas/sistema_simulado.py fuentes`: llegan estos ficheros a bronce y quedan declarados en `dbt/models/plata/_fuentes.yml`.

| Fichero | Qué es | Columnas |
|---|---|---|
| `bronce/furgonetas/furgonetas.csv` | capacidad del depósito de agua de cada furgoneta (litros) | furgoneta, deposito_l |
| `bronce/eventos/lecturas_contador_2026-05-18.json` | Los contadores de agua exportan un registro con una `lectura` de cada furgoneta cada pocos minutos, y un evento `fin_servicio` al acabar cada lavado. | evento_id, furgoneta, tipo (lectura / fin_servicio), ts, contador_l |

2. **El giro.** El contador es **acumulado**: lo que gastas es la diferencia con la lectura anterior. Y cuando se rellena el depósito **vuelve a cero**. Además, se pierden algunas lecturas.
3. Modelos de plata: `stg_furgonetas` y `stg_consumos` y `stg_eventos` (el registro lo lees con `source('bronce', 'eventos')`).
4. **Test protagonista.** **Un consumo de agua nunca es negativo.** Calcula el consumo entre lecturas en un modelo de plata (`stg_consumos`) y escribe un test que devuelva los consumos negativos. Rojo si restas sin pensar; verde cuando entiendas qué pasa al rellenar.
5. **Pregunta 4** (`dbt/models/oro/pregunta_4.sql`): ¿Qué furgoneta **gasta más agua por servicio**, medida por el contador? ¿Coincide con lo que dice el parte?
6. Escribe `paginas/3-fuentes.md`. Pull request, verde, fusionas.

## Bloque 4 · El memo · rama `memo`

Escribe `paginas/memo.md`: el memo para la dirección de EcoBrillo, con las cuatro respuestas citadas con marcas. La comprobación exige que existan `pregunta_1` a `pregunta_4`. Repasa el portal entero antes de fusionar.

---

## Lo que se entrega

- Tu repositorio en tu cuenta, con los cuatro pull requests fusionados y la última ejecución de `main` en verde.
- Tu portal publicado, con sus cuatro páginas escritas, y tu `dbt-docs`.
- La presentación oral (5 minutos): con tu portal en pantalla, el problema de calidad, tu test protagonista, las cuatro respuestas y tu recomendación.
