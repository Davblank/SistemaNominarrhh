-- =====================================================================
-- 06 | VDL (View Definition Language)
-- Definición de vistas para reportes. Ejecutar después de 03_ddl.sql
-- =====================================================================
USE nomina_rrhh;

-- Empleados activos con su salario vigente
CREATE OR REPLACE VIEW v_empleados_activos AS
SELECT e.id, e.documento, CONCAT(e.nombres, ' ', e.apellidos) AS empleado,
       d.nombre AS departamento, c.nombre AS cargo, ct.salario_base, e.fecha_ingreso
  FROM empleados e
  JOIN departamentos d ON d.id = e.departamento_id
  JOIN cargos c ON c.id = e.cargo_id
  JOIN contratos ct ON ct.empleado_id = e.id AND ct.fecha_fin IS NULL
 WHERE e.activo = 1;

-- Desprendible de pago (una fila por concepto)
CREATE OR REPLACE VIEW v_desprendible AS
SELECT p.id AS periodo_id, p.fecha_inicio, p.fecha_fin,
       e.documento, CONCAT(e.nombres, ' ', e.apellidos) AS empleado,
       k.nombre AS concepto, k.tipo, d.valor
  FROM detalle_nomina d
  JOIN nominas n ON n.id = d.nomina_id
  JOIN periodos_nomina p ON p.id = n.periodo_id
  JOIN empleados e ON e.id = n.empleado_id
  JOIN conceptos_nomina k ON k.id = d.concepto_id;

-- Resumen de nómina por periodo y departamento
CREATE OR REPLACE VIEW v_resumen_nomina AS
SELECT n.periodo_id, dep.nombre AS departamento,
       COUNT(*) AS empleados,
       SUM(n.total_devengado) AS devengado,
       SUM(n.total_deducciones) AS deducciones,
       SUM(n.neto) AS neto
  FROM nominas n
  JOIN empleados e ON e.id = n.empleado_id
  JOIN departamentos dep ON dep.id = e.departamento_id
 GROUP BY n.periodo_id, dep.nombre;

-- Solicitudes de ausencia que esperan aprobación
CREATE OR REPLACE VIEW v_ausencias_pendientes AS
SELECT a.id, CONCAT(e.nombres, ' ', e.apellidos) AS empleado, a.tipo,
       a.fecha_desde, a.fecha_hasta, DATEDIFF(a.fecha_hasta, a.fecha_desde) + 1 AS dias, a.con_pago
  FROM ausencias a
  JOIN empleados e ON e.id = a.empleado_id
 WHERE a.estado = 'PENDIENTE';

-- Horas extra por empleado y mes
CREATE OR REPLACE VIEW v_horas_extra_mes AS
SELECT e.documento, CONCAT(e.nombres, ' ', e.apellidos) AS empleado,
       DATE_FORMAT(a.fecha, '%Y-%m') AS mes, SUM(a.horas_extra) AS horas_extra
  FROM asistencia a
  JOIN empleados e ON e.id = a.empleado_id
 GROUP BY e.id, DATE_FORMAT(a.fecha, '%Y-%m');

-- Comprobante de pago: una fila por concepto, con encabezado de empresa y empleado
CREATE OR REPLACE VIEW v_comprobante AS
SELECT cp.numero, cp.estado, cp.fecha_emision, cp.fecha_pago,
       emp.razon_social, emp.nit,
       p.id AS periodo_id, p.fecha_inicio, p.fecha_fin,
       e.documento, CONCAT(e.nombres, ' ', e.apellidos) AS empleado,
       dep.nombre AS departamento, c.nombre AS cargo,
       n.salario_base, n.dias_pagados,
       k.nombre AS concepto, k.tipo, d.valor,
       n.total_devengado, n.total_deducciones, n.neto
  FROM comprobantes cp
  JOIN nominas n ON n.id = cp.nomina_id
  JOIN periodos_nomina p ON p.id = n.periodo_id
  JOIN empleados e ON e.id = n.empleado_id
  JOIN departamentos dep ON dep.id = e.departamento_id
  JOIN cargos c ON c.id = e.cargo_id
  JOIN detalle_nomina d ON d.nomina_id = n.id
  JOIN conceptos_nomina k ON k.id = d.concepto_id
  CROSS JOIN empresa emp;

-- Prestaciones sociales y aportes del empleador por empleado y periodo
CREATE OR REPLACE VIEW v_prestaciones AS
SELECT n.periodo_id, e.documento, CONCAT(e.nombres, ' ', e.apellidos) AS empleado,
       k.nombre AS concepto, k.tipo, pr.base, pr.valor
  FROM provisiones_nomina pr
  JOIN nominas n ON n.id = pr.nomina_id
  JOIN empleados e ON e.id = n.empleado_id
  JOIN conceptos_nomina k ON k.id = pr.concepto_id;

-- Costo laboral total del empleador por empleado y periodo
CREATE OR REPLACE VIEW v_costo_laboral AS
SELECT n.periodo_id, e.documento, CONCAT(e.nombres, ' ', e.apellidos) AS empleado,
       n.total_devengado,
       IFNULL(SUM(CASE WHEN k.tipo = 'APORTE_EMPLEADOR' THEN pr.valor END), 0) AS aportes_empleador,
       IFNULL(SUM(CASE WHEN k.tipo = 'PROVISION' THEN pr.valor END), 0) AS prestaciones,
       n.total_devengado
         + IFNULL(SUM(CASE WHEN k.tipo = 'APORTE_EMPLEADOR' THEN pr.valor END), 0)
         + IFNULL(SUM(CASE WHEN k.tipo = 'PROVISION' THEN pr.valor END), 0) AS costo_total
  FROM nominas n
  JOIN empleados e ON e.id = n.empleado_id
  LEFT JOIN provisiones_nomina pr ON pr.nomina_id = n.id
  LEFT JOIN conceptos_nomina k ON k.id = pr.concepto_id
 GROUP BY n.id, n.periodo_id, e.documento, e.nombres, e.apellidos, n.total_devengado;

-- Consultar vistas definidas
SHOW FULL TABLES WHERE Table_type = 'VIEW';

-- Modificar o eliminar una vista (ejemplos)
-- ALTER VIEW v_ausencias_pendientes AS SELECT * FROM ausencias WHERE estado = 'PENDIENTE';
-- DROP VIEW IF EXISTS v_horas_extra_mes;
