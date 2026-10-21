-- litros_agua tiene que estar en un rango creíble para este negocio (2.45 a 121.6).
select servicio, litros_agua from {{ ref('stg_parte') }}
where litros_agua not between 2.45 and 121.6
