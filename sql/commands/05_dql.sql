-- =====================================================================
-- 05 | DQL (Data Query Language)
-- Consultas SELECT para reportes. Ejecutar después de 04_dml.sql
-- =====================================================================
USE nomina_rrhh;

-- 1. Listado de empleados con su departamento y cargo
SELECT e.documento, CONCAT(e.nombres, ' ', e.apellidos) AS empleado,
       d.nombre AS departamento, c.nombre AS cargo
  FROM empleados e
  JOIN departamentos d ON d.id = e.departamento_id
  JOIN cargos c ON c.id = e.cargo_id
 WHERE e.activo = 1
 ORDER BY d.nombre, e.apellidos;

-- 2. Salario actual de cada empleado (contrato vigente)
SELECT e.documento, CONCAT(e.nombres, ' ', e.apellidos) AS empleado, ct.salario_base
  FROM empleados e
  JOIN contratos ct ON ct.empleado_id = e.id AND ct.fecha_fin IS NULL
 ORDER BY ct.salario_base DESC;

-- 3. Cantidad de empleados y salario promedio por departamento
SELECT d.nombre AS departamento, COUNT(*) AS empleados, ROUND(AVG(ct.salario_base), 2) AS salario_promedio
  FROM empleados e
  JOIN departamentos d ON d.id = e.departamento_id
  JOIN contratos ct ON ct.empleado_id = e.id AND ct.fecha_fin IS NULL
 GROUP BY d.nombre
HAVING COUNT(*) >= 1
 ORDER BY salario_promedio DESC;

-- 4. Ranking de salarios dentro de cada departamento (función de ventana)
SELECT d.nombre AS departamento, CONCAT(e.nombres, ' ', e.apellidos) AS empleado, ct.salario_base,
       RANK() OVER (PARTITION BY d.id ORDER BY ct.salario_base DESC) AS puesto
  FROM empleados e
  JOIN departamentos d ON d.id = e.departamento_id
  JOIN contratos ct ON ct.empleado_id = e.id AND ct.fecha_fin IS NULL;

-- 5. Empleados que ganan más que el promedio general (subconsulta)
SELECT CONCAT(e.nombres, ' ', e.apellidos) AS empleado, ct.salario_base
  FROM empleados e
  JOIN contratos ct ON ct.empleado_id = e.id AND ct.fecha_fin IS NULL
 WHERE ct.salario_base > (SELECT AVG(salario_base) FROM contratos WHERE fecha_fin IS NULL);

-- 6. Desprendible de pago de un empleado en un periodo
SELECT k.nombre AS concepto, k.tipo, d.valor
  FROM detalle_nomina d
  JOIN nominas n ON n.id = d.nomina_id
  JOIN empleados e ON e.id = n.empleado_id
  JOIN conceptos_nomina k ON k.id = d.concepto_id
 WHERE e.documento = '1003' AND n.periodo_id = 2
 ORDER BY k.tipo, k.nombre;

-- 7. Resumen de la nómina del periodo por departamento
SELECT dep.nombre AS departamento, COUNT(*) AS empleados,
       SUM(n.total_devengado) AS devengado, SUM(n.total_deducciones) AS deducciones, SUM(n.neto) AS neto
  FROM nominas n
  JOIN empleados e ON e.id = n.empleado_id
  JOIN departamentos dep ON dep.id = e.departamento_id
 WHERE n.periodo_id = 2
 GROUP BY dep.nombre WITH ROLLUP;

-- 8. Horas extra acumuladas por empleado en septiembre de 2026
SELECT CONCAT(e.nombres, ' ', e.apellidos) AS empleado, SUM(a.horas_extra) AS horas_extra
  FROM asistencia a
  JOIN empleados e ON e.id = a.empleado_id
 WHERE a.fecha BETWEEN '2026-09-01' AND '2026-09-30'
 GROUP BY e.id
HAVING SUM(a.horas_extra) > 0
 ORDER BY horas_extra DESC;

-- 9. Ausencias aprobadas sin pago (las que descuentan salario)
SELECT CONCAT(e.nombres, ' ', e.apellidos) AS empleado, a.tipo, a.fecha_desde, a.fecha_hasta,
       DATEDIFF(a.fecha_hasta, a.fecha_desde) + 1 AS dias
  FROM ausencias a
  JOIN empleados e ON e.id = a.empleado_id
 WHERE a.estado = 'APROBADA' AND a.con_pago = 0;

-- 10. Empleados sin ninguna ausencia registrada (LEFT JOIN)
SELECT CONCAT(e.nombres, ' ', e.apellidos) AS empleado
  FROM empleados e
  LEFT JOIN ausencias a ON a.empleado_id = e.id
 WHERE a.id IS NULL;

-- 11. Antigüedad en años de cada empleado
SELECT CONCAT(nombres, ' ', apellidos) AS empleado, fecha_ingreso,
       TIMESTAMPDIFF(YEAR, fecha_ingreso, CURDATE()) AS anios_antiguedad
  FROM empleados
 ORDER BY fecha_ingreso;

-- 12. Salarios fuera del rango permitido por el cargo
SELECT CONCAT(e.nombres, ' ', e.apellidos) AS empleado, c.nombre AS cargo, ct.salario_base, c.salario_min, c.salario_max
  FROM empleados e
  JOIN cargos c ON c.id = e.cargo_id
  JOIN contratos ct ON ct.empleado_id = e.id AND ct.fecha_fin IS NULL
 WHERE ct.salario_base NOT BETWEEN c.salario_min AND c.salario_max;

-- 13. Últimos movimientos de auditoría
SELECT fecha, usuario, accion, tabla, detalle FROM auditoria ORDER BY id DESC LIMIT 10;

-- 14. Comprobante de pago completo de un empleado (encabezado y conceptos)
SELECT numero, razon_social, nit, empleado, documento, cargo, dias_pagados,
       fecha_inicio, fecha_fin, fecha_pago, concepto, tipo, valor
  FROM v_comprobante
 WHERE documento = '1003' AND periodo_id = 2
 ORDER BY tipo, concepto;

-- 15. Totales del comprobante (una fila por empleado)
SELECT DISTINCT numero, empleado, total_devengado, total_deducciones, neto
  FROM v_comprobante
 WHERE periodo_id = 2
 ORDER BY numero;

-- 16. Prestaciones sociales de un empleado en el periodo
SELECT concepto, base, valor
  FROM v_prestaciones
 WHERE documento = '1001' AND periodo_id = 2 AND tipo = 'PROVISION';

-- 17. Total de prestaciones por empleado (pivote con CASE)
SELECT empleado,
       SUM(CASE WHEN concepto = 'Cesantías' THEN valor ELSE 0 END)                  AS cesantias,
       SUM(CASE WHEN concepto = 'Intereses sobre cesantías' THEN valor ELSE 0 END)  AS intereses,
       SUM(CASE WHEN concepto = 'Prima de servicios' THEN valor ELSE 0 END)         AS prima,
       SUM(CASE WHEN concepto = 'Vacaciones' THEN valor ELSE 0 END)                 AS vacaciones
  FROM v_prestaciones
 WHERE periodo_id = 2 AND tipo = 'PROVISION'
 GROUP BY empleado;

-- 18. Costo laboral total del empleador en el periodo
SELECT empleado, total_devengado, aportes_empleador, prestaciones, costo_total
  FROM v_costo_laboral
 WHERE periodo_id = 2
 ORDER BY costo_total DESC;

SELECT SUM(total_devengado) AS devengado, SUM(aportes_empleador) AS aportes,
       SUM(prestaciones) AS prestaciones, SUM(costo_total) AS costo_total
  FROM v_costo_laboral WHERE periodo_id = 2;

-- 19. Validación de cuadre: devengado - deducciones debe ser igual al neto (debe devolver 0 filas)
SELECT n.id, n.total_devengado, n.total_deducciones, n.neto
  FROM nominas n
 WHERE ROUND(n.total_devengado - n.total_deducciones - n.neto, 2) <> 0;

-- 20. Empleados con auxilio de transporte en el periodo
SELECT CONCAT(e.nombres, ' ', e.apellidos) AS empleado, n.salario_base, d.valor AS auxilio
  FROM nominas n
  JOIN empleados e ON e.id = n.empleado_id
  JOIN detalle_nomina d ON d.nomina_id = n.id
  JOIN conceptos_nomina k ON k.id = d.concepto_id AND k.codigo = 'AUX_TRANSPORTE'
 WHERE n.periodo_id = 2;
