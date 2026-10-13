-- =====================================================================
-- insert_sistema_nomina.sql
-- Datos iniciales y de prueba del sistema de nómina y RR. HH.
-- Ejecutar DESPUÉS de nomina_rrhh.sql.
-- =====================================================================
USE nomina_rrhh;

INSERT INTO departamentos (nombre) VALUES
  ('Tecnología'), ('Contabilidad'), ('Ventas'), ('Recursos Humanos'), ('Administración');

INSERT INTO cargos (nombre, salario_min, salario_max) VALUES
  ('Desarrollador',           2000, 5000),
  ('Contador',                1800, 4000),
  ('Asesor comercial',        1200, 3000),
  ('Analista de RR. HH.',     1800, 3500),
  ('Gerente',                 4000, 8000),
  ('Auxiliar administrativo', 1000, 2000);

INSERT INTO empleados (documento, nombres, apellidos, email, telefono, fecha_ingreso, departamento_id, cargo_id) VALUES
  ('1001', 'Ana',    'Torres', 'ana@empresa.test',    '3001110001', '2023-02-01', 1, 1),
  ('1002', 'Luis',   'Gómez',  'luis@empresa.test',   '3001110002', '2022-06-15', 2, 2),
  ('1003', 'Marta',  'Ruiz',   'marta@empresa.test',  '3001110003', '2024-01-10', 3, 3),
  ('1004', 'Carlos', 'Pérez',  'carlos@empresa.test', '3001110004', '2021-09-01', 1, 1),
  ('1005', 'Sofía',  'Mejía',  'sofia@empresa.test',  '3001110005', '2023-07-20', 4, 4),
  ('1006', 'Andrés', 'Castro', 'andres@empresa.test', '3001110006', '2020-03-02', 5, 5),
  ('1007', 'Laura',  'Vega',   'laura@empresa.test',  '3001110007', '2024-05-06', 3, 3),
  ('1008', 'Diego',  'Salas',  'diego@empresa.test',  '3001110008', '2022-11-14', 5, 6);

INSERT INTO contratos (empleado_id, tipo, salario_base, fecha_inicio) VALUES
  (1, 'INDEFINIDO', 3000, '2023-02-01'),
  (2, 'INDEFINIDO', 2500, '2022-06-15'),
  (3, 'FIJO',       1500, '2024-01-10'),
  (4, 'INDEFINIDO', 4200, '2021-09-01'),
  (5, 'INDEFINIDO', 2200, '2023-07-20'),
  (6, 'INDEFINIDO', 4800, '2020-03-02'),
  (7, 'FIJO',       1400, '2024-05-06'),
  (8, 'INDEFINIDO', 1300, '2022-11-14');

INSERT INTO asistencia (empleado_id, fecha, hora_entrada, hora_salida, horas_extra) VALUES
  (1, '2026-08-20', '08:00', '18:00', 2),
  (1, '2026-09-08', '08:00', '19:00', 3),
  (1, '2026-09-15', '08:00', '21:00', 5),
  (3, '2026-09-10', '08:00', '18:00', 2),
  (4, '2026-09-22', '08:00', '20:00', 4),
  (7, '2026-09-17', '08:00', '17:30', 1.5),
  (8, '2026-09-03', '08:00', '17:00', 0);

INSERT INTO ausencias (empleado_id, tipo, fecha_desde, fecha_hasta, con_pago, estado) VALUES
  (3, 'PERMISO',    '2026-09-24', '2026-09-25', 0, 'APROBADA'),   -- descuenta 2 días
  (2, 'VACACIONES', '2026-09-14', '2026-09-18', 1, 'APROBADA'),   -- con pago, no descuenta
  (7, 'PERMISO',    '2026-09-28', '2026-09-29', 0, 'PENDIENTE');  -- se aprueba en 04_dml.sql

INSERT INTO empresa (nit, razon_social, direccion, ciudad) VALUES
  ('900000000-1', 'Empresa Ficticia S.A.S.', 'Calle 1 # 2-34', 'Bogotá');

-- Parámetros editables. Los valores monetarios son ficticios, en la misma escala de los datos de prueba.
-- Si tu proyecto sigue una norma concreta, ajusta aquí los valores sin tocar el código.
INSERT INTO parametros (clave, valor, descripcion) VALUES
  ('RECARGO_HORA_EXTRA',     25,   'Porcentaje de recargo sobre la hora ordinaria'),
  ('SALARIO_MINIMO',         1500, 'Salario mínimo mensual (ficticio)'),
  ('AUXILIO_TRANSPORTE',     150,  'Auxilio de transporte mensual (ficticio)'),
  ('TOPE_AUXILIO_SMMLV',     2,    'Recibe auxilio quien gane hasta N salarios mínimos'),
  ('DIAS_BASE_PRESTACIONES', 360,  'Días del año para liquidar prestaciones'),
  ('DIAS_CESANTIAS_ANIO',    30,   'Días de salario por año de cesantías'),
  ('PCT_INTERES_CESANTIAS',  12,   'Porcentaje anual de intereses sobre cesantías'),
  ('DIAS_PRIMA_ANIO',        30,   'Días de salario por año de prima de servicios'),
  ('DIAS_VACACIONES_ANIO',   15,   'Días de salario por año de vacaciones');

INSERT INTO conceptos_nomina (codigo, nombre, tipo, porcentaje, base_exenta) VALUES
  ('SALARIO',            'Salario proporcional',          'DEVENGO',          0,     0),
  ('HORAS_EXTRA',        'Horas extra',                   'DEVENGO',          0,     0),
  ('AUX_TRANSPORTE',     'Auxilio de transporte',         'DEVENGO',          0,     0),
  ('SALUD',              'Aporte salud (empleado)',       'DEDUCCION',        4,     0),
  ('PENSION',            'Aporte pensión (empleado)',     'DEDUCCION',        4,     0),
  ('IMPUESTO',           'Impuesto sobre renta',          'DEDUCCION',        8,     2000),
  ('CESANTIAS',          'Cesantías',                     'PROVISION',        0,     0),
  ('INT_CESANTIAS',      'Intereses sobre cesantías',     'PROVISION',        0,     0),
  ('PRIMA',              'Prima de servicios',            'PROVISION',        0,     0),
  ('VACACIONES',         'Vacaciones',                    'PROVISION',        0,     0),
  ('APORTE_SALUD_EMP',   'Salud (empleador)',             'APORTE_EMPLEADOR', 8.5,   0),
  ('APORTE_PENSION_EMP', 'Pensión (empleador)',           'APORTE_EMPLEADOR', 12,    0),
  ('APORTE_ARL',         'Riesgos laborales (ARL)',       'APORTE_EMPLEADOR', 0.522, 0),
  ('APORTE_CAJA',        'Caja de compensación',          'APORTE_EMPLEADOR', 4,     0);

INSERT INTO periodos_nomina (fecha_inicio, fecha_fin) VALUES
  ('2026-08-01', '2026-08-31'),
  ('2026-09-01', '2026-09-30');

-- Los hashes son ficticios; en la aplicación se generan con password_hash() de PHP
INSERT INTO usuarios (email, password_hash, rol, empleado_id) VALUES
  ('admin@empresa.test', 'HASH_FICTICIO_ADMIN',   'ADMIN',    6),
  ('rrhh@empresa.test',  'HASH_FICTICIO_RRHH',    'RRHH',     5),
  ('ana@empresa.test',   'HASH_FICTICIO_EMPLEADO','EMPLEADO', 1);

-- =====================================================================
-- Cálculo de nómina (opcional): genera nóminas, prestaciones y comprobantes
-- Descomenta estas líneas o ejecútalas desde la aplicación.
-- =====================================================================
-- CALL sp_generar_nomina(1);   -- agosto 2026
-- CALL sp_generar_nomina(2);   -- septiembre 2026
-- SELECT * FROM v_comprobante WHERE periodo_id = 2 AND documento = '1003';
