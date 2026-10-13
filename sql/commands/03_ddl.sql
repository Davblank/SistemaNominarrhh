-- =====================================================================
-- 03 | DDL (Data Definition Language)
-- CREATE / ALTER / DROP de tablas, índices, triggers y procedimientos.
-- Las vistas están en 06_vdl.sql
-- =====================================================================
USE nomina_rrhh;

-- ---------------------------------------------------------------------
-- CREATE TABLE
-- ---------------------------------------------------------------------
CREATE TABLE departamentos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(80) NOT NULL UNIQUE,
  activo TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE cargos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(80) NOT NULL UNIQUE,
  salario_min DECIMAL(12,2) NOT NULL,
  salario_max DECIMAL(12,2) NOT NULL,
  CHECK (salario_max >= salario_min)
) ENGINE=InnoDB;

CREATE TABLE empleados (
  id INT AUTO_INCREMENT PRIMARY KEY,
  documento VARCHAR(20) NOT NULL UNIQUE,
  nombres VARCHAR(80) NOT NULL,
  apellidos VARCHAR(80) NOT NULL,
  email VARCHAR(120) UNIQUE,
  fecha_ingreso DATE NOT NULL,
  departamento_id INT NOT NULL,
  cargo_id INT NOT NULL,
  activo TINYINT(1) NOT NULL DEFAULT 1,
  fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (departamento_id) REFERENCES departamentos(id),
  FOREIGN KEY (cargo_id) REFERENCES cargos(id)
) ENGINE=InnoDB;

CREATE TABLE contratos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  empleado_id INT NOT NULL,
  tipo ENUM('INDEFINIDO','FIJO','PRESTACION') NOT NULL,
  salario_base DECIMAL(12,2) NOT NULL CHECK (salario_base > 0),
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NULL,
  FOREIGN KEY (empleado_id) REFERENCES empleados(id)
) ENGINE=InnoDB;

CREATE TABLE asistencia (
  id INT AUTO_INCREMENT PRIMARY KEY,
  empleado_id INT NOT NULL,
  fecha DATE NOT NULL,
  hora_entrada TIME NULL,
  hora_salida TIME NULL,
  horas_extra DECIMAL(4,2) NOT NULL DEFAULT 0,
  UNIQUE KEY uq_asistencia (empleado_id, fecha),
  FOREIGN KEY (empleado_id) REFERENCES empleados(id)
) ENGINE=InnoDB;

CREATE TABLE ausencias (
  id INT AUTO_INCREMENT PRIMARY KEY,
  empleado_id INT NOT NULL,
  tipo ENUM('VACACIONES','PERMISO','INCAPACIDAD','LICENCIA') NOT NULL,
  fecha_desde DATE NOT NULL,
  fecha_hasta DATE NOT NULL,
  con_pago TINYINT(1) NOT NULL DEFAULT 1,
  estado ENUM('PENDIENTE','APROBADA','RECHAZADA') NOT NULL DEFAULT 'PENDIENTE',
  CHECK (fecha_hasta >= fecha_desde),
  FOREIGN KEY (empleado_id) REFERENCES empleados(id)
) ENGINE=InnoDB;

CREATE TABLE parametros (
  clave VARCHAR(40) PRIMARY KEY,
  valor DECIMAL(12,4) NOT NULL,
  descripcion VARCHAR(120)
) ENGINE=InnoDB;

CREATE TABLE conceptos_nomina (
  id INT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(20) NOT NULL UNIQUE,
  nombre VARCHAR(80) NOT NULL,
  tipo ENUM('DEVENGO','DEDUCCION','PROVISION','APORTE_EMPLEADOR') NOT NULL,
  porcentaje DECIMAL(6,3) NOT NULL DEFAULT 0,
  base_exenta DECIMAL(12,2) NOT NULL DEFAULT 0,
  activo TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE periodos_nomina (
  id INT AUTO_INCREMENT PRIMARY KEY,
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NOT NULL,
  estado ENUM('ABIERTO','CALCULADO','CERRADO') NOT NULL DEFAULT 'ABIERTO',
  UNIQUE KEY uq_periodo (fecha_inicio, fecha_fin)
) ENGINE=InnoDB;

CREATE TABLE nominas (
  id INT AUTO_INCREMENT PRIMARY KEY,
  periodo_id INT NOT NULL,
  empleado_id INT NOT NULL,
  salario_base DECIMAL(12,2) NOT NULL DEFAULT 0,
  dias_pagados INT NOT NULL DEFAULT 30,
  aplica_auxilio TINYINT(1) NOT NULL DEFAULT 0,
  total_devengado DECIMAL(12,2) NOT NULL DEFAULT 0,
  base_salarial DECIMAL(12,2) NOT NULL DEFAULT 0,
  total_deducciones DECIMAL(12,2) NOT NULL DEFAULT 0,
  neto DECIMAL(12,2) NOT NULL DEFAULT 0,
  UNIQUE KEY uq_nomina (periodo_id, empleado_id),
  FOREIGN KEY (periodo_id) REFERENCES periodos_nomina(id) ON DELETE CASCADE,
  FOREIGN KEY (empleado_id) REFERENCES empleados(id)
) ENGINE=InnoDB;

CREATE TABLE detalle_nomina (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nomina_id INT NOT NULL,
  concepto_id INT NOT NULL,
  valor DECIMAL(12,2) NOT NULL,
  FOREIGN KEY (nomina_id) REFERENCES nominas(id) ON DELETE CASCADE,
  FOREIGN KEY (concepto_id) REFERENCES conceptos_nomina(id)
) ENGINE=InnoDB;

CREATE TABLE empresa (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nit VARCHAR(20) NOT NULL,
  razon_social VARCHAR(120) NOT NULL,
  direccion VARCHAR(120),
  ciudad VARCHAR(60)
) ENGINE=InnoDB;

-- Prestaciones sociales y aportes del empleador (no afectan el neto del empleado)
CREATE TABLE provisiones_nomina (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nomina_id INT NOT NULL,
  concepto_id INT NOT NULL,
  base DECIMAL(12,2) NOT NULL,
  valor DECIMAL(12,2) NOT NULL,
  FOREIGN KEY (nomina_id) REFERENCES nominas(id) ON DELETE CASCADE,
  FOREIGN KEY (concepto_id) REFERENCES conceptos_nomina(id)
) ENGINE=InnoDB;

CREATE TABLE comprobantes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nomina_id INT NOT NULL UNIQUE,
  numero VARCHAR(25) NOT NULL UNIQUE,
  fecha_emision DATE NOT NULL,
  fecha_pago DATE NOT NULL,
  estado ENUM('EMITIDO','ANULADO') NOT NULL DEFAULT 'EMITIDO',
  FOREIGN KEY (nomina_id) REFERENCES nominas(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE usuarios (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(120) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  rol ENUM('ADMIN','RRHH','EMPLEADO') NOT NULL,
  empleado_id INT NULL,
  FOREIGN KEY (empleado_id) REFERENCES empleados(id)
) ENGINE=InnoDB;

CREATE TABLE auditoria (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario VARCHAR(120),
  accion VARCHAR(20) NOT NULL,
  tabla VARCHAR(40) NOT NULL,
  registro_id INT,
  detalle VARCHAR(255),
  fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- ALTER TABLE
-- ---------------------------------------------------------------------
ALTER TABLE empleados ADD COLUMN telefono VARCHAR(20) NULL AFTER email;
ALTER TABLE empleados ADD COLUMN fecha_nacimiento DATE NULL AFTER apellidos;
ALTER TABLE contratos MODIFY COLUMN tipo ENUM('INDEFINIDO','FIJO','PRESTACION','APRENDIZAJE') NOT NULL;

-- ---------------------------------------------------------------------
-- CREATE INDEX
-- ---------------------------------------------------------------------
CREATE INDEX idx_contrato_vigencia ON contratos (empleado_id, fecha_inicio, fecha_fin);
CREATE INDEX idx_ausencias_empleado ON ausencias (empleado_id, fecha_desde, fecha_hasta);
CREATE INDEX idx_empleados_depto ON empleados (departamento_id);

-- ---------------------------------------------------------------------
-- TRIGGERS DE AUDITORÍA
-- ---------------------------------------------------------------------
DELIMITER //
CREATE TRIGGER trg_empleados_upd AFTER UPDATE ON empleados
FOR EACH ROW
BEGIN
  INSERT INTO auditoria (usuario, accion, tabla, registro_id, detalle)
  VALUES (USER(), 'UPDATE', 'empleados', NEW.id,
          CONCAT('activo ', OLD.activo, '->', NEW.activo, '; cargo ', OLD.cargo_id, '->', NEW.cargo_id));
END//

CREATE TRIGGER trg_contratos_ins AFTER INSERT ON contratos
FOR EACH ROW
BEGIN
  INSERT INTO auditoria (usuario, accion, tabla, registro_id, detalle)
  VALUES (USER(), 'INSERT', 'contratos', NEW.id, CONCAT('salario ', NEW.salario_base));
END//

CREATE TRIGGER trg_contratos_upd AFTER UPDATE ON contratos
FOR EACH ROW
BEGIN
  INSERT INTO auditoria (usuario, accion, tabla, registro_id, detalle)
  VALUES (USER(), 'UPDATE', 'contratos', NEW.id,
          CONCAT('salario ', OLD.salario_base, '->', NEW.salario_base));
END//

-- ---------------------------------------------------------------------
-- PROCEDIMIENTO DE CÁLCULO DE NÓMINA, PRESTACIONES Y COMPROBANTES
--   salario prop = salario / 30 * días pagados
--   horas extra  = horas * (salario / 30 / 8) * (1 + recargo/100)
--   auxilio      = auxilio mensual / 30 * días pagados (si salario <= tope)
--   deducción    = MAX(0, base salarial - base_exenta) * porcentaje / 100
--   prestación   = base * días pagados * (días al año / 30) / días base
--   Todos los porcentajes y días salen de las tablas parametros y conceptos_nomina
-- ---------------------------------------------------------------------
CREATE PROCEDURE sp_generar_nomina(IN p_periodo INT)
BEGIN
  DECLARE v_ini DATE;
  DECLARE v_fin DATE;
  DECLARE v_estado VARCHAR(10);
  DECLARE v_aux_id INT;
  DECLARE v_recargo, v_aux, v_smmlv, v_tope, v_base, v_d_ces, v_pct_int, v_d_prima, v_d_vac DECIMAL(12,4);

  SELECT fecha_inicio, fecha_fin, estado INTO v_ini, v_fin, v_estado
    FROM periodos_nomina WHERE id = p_periodo;
  IF v_ini IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El periodo no existe';
  END IF;
  IF v_estado = 'CERRADO' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El periodo está cerrado y no se puede recalcular';
  END IF;

  SELECT valor INTO v_recargo  FROM parametros WHERE clave = 'RECARGO_HORA_EXTRA';
  SELECT valor INTO v_aux      FROM parametros WHERE clave = 'AUXILIO_TRANSPORTE';
  SELECT valor INTO v_smmlv    FROM parametros WHERE clave = 'SALARIO_MINIMO';
  SELECT valor INTO v_tope     FROM parametros WHERE clave = 'TOPE_AUXILIO_SMMLV';
  SELECT valor INTO v_base     FROM parametros WHERE clave = 'DIAS_BASE_PRESTACIONES';
  SELECT valor INTO v_d_ces    FROM parametros WHERE clave = 'DIAS_CESANTIAS_ANIO';
  SELECT valor INTO v_pct_int  FROM parametros WHERE clave = 'PCT_INTERES_CESANTIAS';
  SELECT valor INTO v_d_prima  FROM parametros WHERE clave = 'DIAS_PRIMA_ANIO';
  SELECT valor INTO v_d_vac    FROM parametros WHERE clave = 'DIAS_VACACIONES_ANIO';
  SELECT id INTO v_aux_id      FROM conceptos_nomina WHERE codigo = 'AUX_TRANSPORTE';

  IF v_recargo IS NULL OR v_aux IS NULL OR v_smmlv IS NULL OR v_tope IS NULL OR v_base IS NULL
     OR v_d_ces IS NULL OR v_pct_int IS NULL OR v_d_prima IS NULL OR v_d_vac IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Faltan parámetros en la tabla parametros';
  END IF;
  SET v_tope = v_tope * v_smmlv;   -- salario máximo para recibir auxilio de transporte

  START TRANSACTION;

  DELETE FROM nominas WHERE periodo_id = p_periodo;   -- borra en cascada detalle, provisiones y comprobantes

  -- 1. Una nómina por empleado activo con contrato en el periodo (se usa el contrato más reciente).
  --    dias_pagados = días del contrato dentro del periodo (máx. 30) menos ausencias aprobadas sin pago.
  INSERT INTO nominas (periodo_id, empleado_id, salario_base, dias_pagados, aplica_auxilio)
  SELECT p_periodo, e.id, c.salario_base,
         GREATEST(0,
           LEAST(30, DATEDIFF(LEAST(IFNULL(c.fecha_fin, v_fin), v_fin), GREATEST(c.fecha_inicio, v_ini)) + 1)
           - LEAST(30, IFNULL((
               SELECT SUM(DATEDIFF(LEAST(a.fecha_hasta, v_fin), GREATEST(a.fecha_desde, v_ini)) + 1)
                 FROM ausencias a
                WHERE a.empleado_id = e.id AND a.con_pago = 0 AND a.estado = 'APROBADA'
                  AND a.fecha_desde <= v_fin AND a.fecha_hasta >= v_ini), 0))),
         IF(c.salario_base <= v_tope, 1, 0)
    FROM empleados e
    JOIN contratos c ON c.empleado_id = e.id
     AND c.id = (SELECT c2.id FROM contratos c2
                  WHERE c2.empleado_id = e.id AND c2.fecha_inicio <= v_fin
                    AND (c2.fecha_fin IS NULL OR c2.fecha_fin >= v_ini)
                  ORDER BY c2.fecha_inicio DESC LIMIT 1)
   WHERE e.activo = 1;

  -- 2. Devengos
  INSERT INTO detalle_nomina (nomina_id, concepto_id, valor)
  SELECT n.id, (SELECT id FROM conceptos_nomina WHERE codigo = 'SALARIO'),
         ROUND(n.salario_base / 30 * n.dias_pagados, 2)
    FROM nominas n WHERE n.periodo_id = p_periodo;

  INSERT INTO detalle_nomina (nomina_id, concepto_id, valor)
  SELECT n.id, (SELECT id FROM conceptos_nomina WHERE codigo = 'HORAS_EXTRA'),
         ROUND(IFNULL((SELECT SUM(s.horas_extra) FROM asistencia s
                        WHERE s.empleado_id = n.empleado_id AND s.fecha BETWEEN v_ini AND v_fin), 0)
               * (n.salario_base / 30 / 8) * (1 + v_recargo / 100), 2)
    FROM nominas n WHERE n.periodo_id = p_periodo;

  INSERT INTO detalle_nomina (nomina_id, concepto_id, valor)
  SELECT n.id, v_aux_id, ROUND(v_aux / 30 * n.dias_pagados, 2)
    FROM nominas n WHERE n.periodo_id = p_periodo AND n.aplica_auxilio = 1;

  UPDATE nominas n
     SET total_devengado = (SELECT IFNULL(SUM(d.valor), 0) FROM detalle_nomina d WHERE d.nomina_id = n.id)
   WHERE n.periodo_id = p_periodo;

  -- Base salarial = devengado sin auxilio de transporte (base de deducciones y aportes)
  UPDATE nominas n
     SET base_salarial = n.total_devengado
                         - IFNULL((SELECT SUM(d.valor) FROM detalle_nomina d
                                    WHERE d.nomina_id = n.id AND d.concepto_id = v_aux_id), 0)
   WHERE n.periodo_id = p_periodo;

  -- 3. Deducciones del empleado
  INSERT INTO detalle_nomina (nomina_id, concepto_id, valor)
  SELECT n.id, k.id, ROUND(GREATEST(0, n.base_salarial - k.base_exenta) * k.porcentaje / 100, 2)
    FROM nominas n CROSS JOIN conceptos_nomina k
   WHERE n.periodo_id = p_periodo AND k.tipo = 'DEDUCCION' AND k.activo = 1;

  UPDATE nominas n
     SET total_deducciones = (SELECT IFNULL(SUM(d.valor), 0)
                                FROM detalle_nomina d JOIN conceptos_nomina k ON k.id = d.concepto_id
                               WHERE d.nomina_id = n.id AND k.tipo = 'DEDUCCION')
   WHERE n.periodo_id = p_periodo;

  UPDATE nominas SET neto = total_devengado - total_deducciones WHERE periodo_id = p_periodo;

  -- 4. Prestaciones sociales (provisión del periodo)
  --    valor = base * días pagados * (días de la prestación al año / 30) / días base del año
  INSERT INTO provisiones_nomina (nomina_id, concepto_id, base, valor)
  SELECT n.id, (SELECT id FROM conceptos_nomina WHERE codigo = 'CESANTIAS'),
         n.salario_base + IF(n.aplica_auxilio = 1, v_aux, 0),
         ROUND((n.salario_base + IF(n.aplica_auxilio = 1, v_aux, 0)) * n.dias_pagados * (v_d_ces / 30) / v_base, 2)
    FROM nominas n WHERE n.periodo_id = p_periodo;

  INSERT INTO provisiones_nomina (nomina_id, concepto_id, base, valor)
  SELECT n.id, (SELECT id FROM conceptos_nomina WHERE codigo = 'INT_CESANTIAS'),
         pc.valor, ROUND(pc.valor * n.dias_pagados * (v_pct_int / 100) / v_base, 2)
    FROM nominas n
    JOIN provisiones_nomina pc ON pc.nomina_id = n.id
     AND pc.concepto_id = (SELECT id FROM conceptos_nomina WHERE codigo = 'CESANTIAS')
   WHERE n.periodo_id = p_periodo;

  INSERT INTO provisiones_nomina (nomina_id, concepto_id, base, valor)
  SELECT n.id, (SELECT id FROM conceptos_nomina WHERE codigo = 'PRIMA'),
         n.salario_base + IF(n.aplica_auxilio = 1, v_aux, 0),
         ROUND((n.salario_base + IF(n.aplica_auxilio = 1, v_aux, 0)) * n.dias_pagados * (v_d_prima / 30) / v_base, 2)
    FROM nominas n WHERE n.periodo_id = p_periodo;

  INSERT INTO provisiones_nomina (nomina_id, concepto_id, base, valor)
  SELECT n.id, (SELECT id FROM conceptos_nomina WHERE codigo = 'VACACIONES'),
         n.salario_base, ROUND(n.salario_base * n.dias_pagados * (v_d_vac / 30) / v_base, 2)
    FROM nominas n WHERE n.periodo_id = p_periodo;

  -- 5. Aportes del empleador (sobre la base salarial)
  INSERT INTO provisiones_nomina (nomina_id, concepto_id, base, valor)
  SELECT n.id, k.id, n.base_salarial, ROUND(n.base_salarial * k.porcentaje / 100, 2)
    FROM nominas n CROSS JOIN conceptos_nomina k
   WHERE n.periodo_id = p_periodo AND k.tipo = 'APORTE_EMPLEADOR' AND k.activo = 1;

  -- 6. Comprobante de pago (número estable: CP-AAAAMM-ID del empleado)
  INSERT INTO comprobantes (nomina_id, numero, fecha_emision, fecha_pago)
  SELECT n.id, CONCAT('CP-', DATE_FORMAT(v_fin, '%Y%m'), '-', LPAD(n.empleado_id, 4, '0')), CURDATE(), v_fin
    FROM nominas n WHERE n.periodo_id = p_periodo;

  UPDATE periodos_nomina SET estado = 'CALCULADO' WHERE id = p_periodo;
  COMMIT;
END//
DELIMITER ;

-- ---------------------------------------------------------------------
-- DROP (ejemplos, comentados para no borrar nada)
-- ---------------------------------------------------------------------
-- DROP INDEX idx_empleados_depto ON empleados;
-- ALTER TABLE empleados DROP COLUMN telefono;
-- DROP TRIGGER IF EXISTS trg_contratos_upd;
-- DROP TABLE IF EXISTS auditoria;

SHOW TABLES;
