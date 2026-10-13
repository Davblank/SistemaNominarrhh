-- =====================================================================
-- 04 | DML (Data Manipulation Language)
-- INSERT / UPDATE / DELETE y ejecución del cálculo de nómina
-- Ejecutar después de 02_datos_ficticios.sql
-- =====================================================================
USE nomina_rrhh;

-- ---------------------------------------------------------------------
-- INSERT: contratar a un nuevo empleado
-- ---------------------------------------------------------------------
INSERT INTO empleados (documento, nombres, apellidos, email, telefono, fecha_ingreso, departamento_id, cargo_id)
VALUES ('1009', 'Valentina', 'Ríos', 'valentina@empresa.test', '3001110009', '2026-09-15', 1, 1);

INSERT INTO contratos (empleado_id, tipo, salario_base, fecha_inicio)
VALUES (LAST_INSERT_ID(), 'FIJO', 2800, '2026-09-15');

INSERT INTO asistencia (empleado_id, fecha, hora_entrada, hora_salida, horas_extra)
VALUES ((SELECT id FROM empleados WHERE documento = '1009'), '2026-09-16', '08:00', '17:00', 0);

-- ---------------------------------------------------------------------
-- UPDATE: aprobar una ausencia y corregir un dato
-- ---------------------------------------------------------------------
UPDATE ausencias SET estado = 'APROBADA'
 WHERE empleado_id = 7 AND estado = 'PENDIENTE';

UPDATE empleados SET telefono = '3109998877' WHERE documento = '1002';

-- Aumento salarial: se cierra el contrato anterior y se abre uno nuevo (queda historial)
UPDATE contratos SET fecha_fin = '2026-09-30'
 WHERE empleado_id = 1 AND fecha_fin IS NULL;

INSERT INTO contratos (empleado_id, tipo, salario_base, fecha_inicio)
VALUES (1, 'INDEFINIDO', 3300, '2026-10-01');

-- ---------------------------------------------------------------------
-- DELETE: borrar registros de prueba
-- ---------------------------------------------------------------------
INSERT INTO ausencias (empleado_id, tipo, fecha_desde, fecha_hasta, con_pago, estado)
VALUES (8, 'PERMISO', '2026-09-30', '2026-09-30', 0, 'RECHAZADA');

DELETE FROM ausencias WHERE estado = 'RECHAZADA';

-- Baja lógica (recomendada en lugar de borrar empleados con historial)
-- UPDATE empleados SET activo = 0 WHERE documento = '1008';

-- ---------------------------------------------------------------------
-- Cálculo de nómina de los dos periodos
-- ---------------------------------------------------------------------
CALL sp_generar_nomina(1);
CALL sp_generar_nomina(2);

SELECT periodo_id, COUNT(*) AS empleados, SUM(neto) AS neto_total
  FROM nominas GROUP BY periodo_id;

-- ---------------------------------------------------------------------
-- UPDATE de parámetros y comprobantes
-- ---------------------------------------------------------------------
-- Cambiar un parámetro modifica el cálculo sin tocar el código (aplica al recalcular un periodo)
-- UPDATE parametros SET valor = 35 WHERE clave = 'RECARGO_HORA_EXTRA';

-- Anular un comprobante emitido por error
UPDATE comprobantes SET estado = 'ANULADO' WHERE numero = 'CP-202608-0008';
UPDATE comprobantes SET estado = 'EMITIDO' WHERE numero = 'CP-202608-0008';  -- se revierte para dejar los datos limpios

SELECT numero, estado, fecha_emision, fecha_pago FROM comprobantes ORDER BY numero LIMIT 5;
