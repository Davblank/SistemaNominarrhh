-- =====================================================================
-- 08 | TCL (Transaction Control Language)
-- START TRANSACTION, COMMIT, ROLLBACK, SAVEPOINT
-- Ejecutar al final, después de 07_dcl.sql. Requiere tablas InnoDB.
-- Nota: los comandos DDL (CREATE, ALTER, DROP) confirman la transacción en forma automática.
-- =====================================================================
USE nomina_rrhh;

-- ---------------------------------------------------------------------
-- 1. ROLLBACK: probar un aumento masivo y deshacerlo
-- ---------------------------------------------------------------------
START TRANSACTION;
  SELECT empleado_id, salario_base FROM contratos WHERE fecha_fin IS NULL;
  UPDATE contratos SET salario_base = salario_base * 1.10 WHERE fecha_fin IS NULL;
  SELECT empleado_id, salario_base AS salario_con_aumento FROM contratos WHERE fecha_fin IS NULL;
ROLLBACK;
SELECT empleado_id, salario_base AS salario_tras_rollback FROM contratos WHERE fecha_fin IS NULL;

-- ---------------------------------------------------------------------
-- 2. SAVEPOINT: deshacer solo una parte de la transacción
-- ---------------------------------------------------------------------
START TRANSACTION;
  INSERT INTO asistencia (empleado_id, fecha, hora_entrada, hora_salida, horas_extra)
  VALUES (5, '2026-09-29', '08:00', '18:00', 2);
  SAVEPOINT sp_a;

  INSERT INTO asistencia (empleado_id, fecha, hora_entrada, hora_salida, horas_extra)
  VALUES (6, '2026-09-29', '08:00', '17:00', 1);
  SAVEPOINT sp_b;

  INSERT INTO asistencia (empleado_id, fecha, hora_entrada, hora_salida, horas_extra)
  VALUES (8, '2026-09-29', '08:00', '23:00', 6);   -- registro erróneo

  ROLLBACK TO SAVEPOINT sp_b;   -- se deshace solo el registro del empleado 8
  RELEASE SAVEPOINT sp_a;
COMMIT;                          -- quedan confirmados los registros de los empleados 5 y 6

-- ---------------------------------------------------------------------
-- 3. COMMIT: recalcular y cerrar el periodo con bloqueo de fila
-- ---------------------------------------------------------------------
CALL sp_generar_nomina(2);       -- el procedimiento maneja su propia transacción

START TRANSACTION;
  SELECT id, estado FROM periodos_nomina WHERE id = 2 FOR UPDATE;   -- bloquea el periodo
  UPDATE periodos_nomina SET estado = 'CERRADO' WHERE id = 2;
  INSERT INTO auditoria (usuario, accion, tabla, registro_id, detalle)
  VALUES (USER(), 'CIERRE', 'periodos_nomina', 2, 'Periodo cerrado');
COMMIT;

-- ---------------------------------------------------------------------
-- 4. Control del modo automático
-- ---------------------------------------------------------------------
SET autocommit = 0;
  UPDATE empleados SET telefono = '3000000000' WHERE documento = '1008';
ROLLBACK;
SET autocommit = 1;

SELECT id, estado FROM periodos_nomina;
-- Prueba: este CALL debe fallar porque el periodo está cerrado
-- CALL sp_generar_nomina(2);
