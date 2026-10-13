-- =====================================================================
-- 07 | DCL (Data Control Language)
-- Roles, usuarios y permisos. Ejecutar con el usuario root, después de 06_vdl.sql
-- =====================================================================
USE nomina_rrhh;

-- ---------------------------------------------------------------------
-- Roles
-- ---------------------------------------------------------------------
CREATE ROLE IF NOT EXISTS rol_admin;
CREATE ROLE IF NOT EXISTS rol_rrhh;
CREATE ROLE IF NOT EXISTS rol_empleado;

-- Administrador: todo sobre la base de datos del sistema
GRANT ALL PRIVILEGES ON nomina_rrhh.* TO rol_admin;

-- RR. HH.: gestiona personal y ejecuta la nómina, sin tocar usuarios ni auditoría
GRANT SELECT, INSERT, UPDATE ON nomina_rrhh.empleados   TO rol_rrhh;
GRANT SELECT, INSERT, UPDATE ON nomina_rrhh.contratos   TO rol_rrhh;
GRANT SELECT, INSERT, UPDATE ON nomina_rrhh.asistencia  TO rol_rrhh;
GRANT SELECT, INSERT, UPDATE ON nomina_rrhh.ausencias   TO rol_rrhh;
GRANT SELECT ON nomina_rrhh.departamentos     TO rol_rrhh;
GRANT SELECT ON nomina_rrhh.cargos            TO rol_rrhh;
GRANT SELECT ON nomina_rrhh.conceptos_nomina  TO rol_rrhh;
GRANT SELECT ON nomina_rrhh.periodos_nomina   TO rol_rrhh;
GRANT SELECT ON nomina_rrhh.nominas           TO rol_rrhh;
GRANT SELECT ON nomina_rrhh.detalle_nomina    TO rol_rrhh;
GRANT SELECT ON nomina_rrhh.v_empleados_activos     TO rol_rrhh;
GRANT SELECT ON nomina_rrhh.v_resumen_nomina        TO rol_rrhh;
GRANT SELECT ON nomina_rrhh.v_ausencias_pendientes  TO rol_rrhh;
GRANT SELECT ON nomina_rrhh.v_horas_extra_mes       TO rol_rrhh;
GRANT SELECT ON nomina_rrhh.provisiones_nomina TO rol_rrhh;
GRANT SELECT, UPDATE ON nomina_rrhh.comprobantes TO rol_rrhh;
GRANT SELECT ON nomina_rrhh.empresa          TO rol_rrhh;
GRANT SELECT ON nomina_rrhh.v_comprobante    TO rol_rrhh;
GRANT SELECT ON nomina_rrhh.v_prestaciones   TO rol_rrhh;
GRANT SELECT ON nomina_rrhh.v_costo_laboral  TO rol_rrhh;
GRANT EXECUTE ON PROCEDURE nomina_rrhh.sp_generar_nomina TO rol_rrhh;

-- Empleado: solo consulta desprendibles.
-- La aplicación debe filtrar por el documento del usuario conectado.
GRANT SELECT ON nomina_rrhh.v_desprendible TO rol_empleado;
GRANT SELECT ON nomina_rrhh.v_comprobante  TO rol_empleado;

-- ---------------------------------------------------------------------
-- Usuarios (cambia las contraseñas en un entorno real)
-- ---------------------------------------------------------------------
CREATE USER IF NOT EXISTS 'admin_nomina'@'localhost'    IDENTIFIED BY 'Admin#2026';
CREATE USER IF NOT EXISTS 'rrhh_nomina'@'localhost'     IDENTIFIED BY 'Rrhh#2026';
CREATE USER IF NOT EXISTS 'empleado_nomina'@'localhost' IDENTIFIED BY 'Emp#2026';

GRANT rol_admin    TO 'admin_nomina'@'localhost';
GRANT rol_rrhh     TO 'rrhh_nomina'@'localhost';
GRANT rol_empleado TO 'empleado_nomina'@'localhost';

SET DEFAULT ROLE rol_admin    FOR 'admin_nomina'@'localhost';
SET DEFAULT ROLE rol_rrhh     FOR 'rrhh_nomina'@'localhost';
SET DEFAULT ROLE rol_empleado FOR 'empleado_nomina'@'localhost';

-- ---------------------------------------------------------------------
-- REVOKE: quitar un permiso
-- ---------------------------------------------------------------------
GRANT DELETE ON nomina_rrhh.asistencia TO rol_rrhh;
REVOKE DELETE ON nomina_rrhh.asistencia FROM rol_rrhh;

FLUSH PRIVILEGES;

-- ---------------------------------------------------------------------
-- Verificación
-- ---------------------------------------------------------------------
SHOW GRANTS FOR rol_rrhh;
SHOW GRANTS FOR rol_empleado;
SHOW GRANTS FOR 'rrhh_nomina'@'localhost';

-- Limpieza (comentado)
-- DROP USER IF EXISTS 'empleado_nomina'@'localhost';
-- DROP ROLE IF EXISTS rol_empleado;
