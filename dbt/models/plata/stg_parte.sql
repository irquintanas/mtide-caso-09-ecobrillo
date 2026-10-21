-- PLATA · el parte diario limpio: la limpieza que hiciste en la J3, ahora como modelo dbt.
-- Cada entrega del parte es una carpeta fecha_carga=… en bronce: aquí se leen todas juntas.
with bruto as (
    select *, parse_filename(filename) as archivo
    from {{ source('bronce', 'parte') }}
),
sin_dup as (
    -- una fila por servicio
    select * from bruto
    qualify row_number() over (partition by servicio order by fecha_carga desc) = 1
),
mediana_tipo_lavado as (
    select tipo_lavado, median(minutos::integer) as minutos_mediana
    from sin_dup
    where minutos::integer between 1 and 360
    group by tipo_lavado
)
select
    s.servicio,
    s.fecha::date                                              as fecha,
    upper(trim(s.operario))                                         as operario,
    s.furgoneta,
    s.tipo_lavado,
    case when s.minutos::integer between 1 and 360 then s.minutos::integer
         else round(m.minutos_mediana)::integer end               as minutos,
    not (s.minutos::integer between 1 and 360)                   as minutos_corregido,
    s.litros_agua::double                                              as litros_agua,
    s.importe_eur::double                                      as importe_eur,
    s.incidencia,
    s.archivo,
    s.fecha_carga
from sin_dup s
join mediana_tipo_lavado m using (tipo_lavado)
