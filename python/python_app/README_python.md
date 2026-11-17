# Conexión con Python

Aplicación de consola que usa la base de datos `nomina_rrhh`. Python solo invoca y consulta: el cálculo de la nómina sigue viviendo en el procedimiento `sp_generar_nomina`.

## Requisitos

- Python 3.8 o superior (se recomienda 3.10+)
- XAMPP con MySQL (MariaDB) iniciado
- `nomina_rrhh.sql` e `insert_sistema_nomina.sql` ya importados

## Instalación

```bash
cd python_app
python -m venv venv
venv\Scripts\activate          # Windows
# source venv/bin/activate     # Linux / macOS
pip install -r requirements.txt
```

## Primera prueba

```bash
python test_conexion.py
```

Debe mostrar la versión del servidor, 16 tablas, 8 vistas y los empleados activos.

## Ejecutar la aplicación

```bash
python main.py
```

Para ver comprobantes primero usa la opción «Calcular nómina de un periodo».

## Usuario de base de datos

Por defecto usa `rrhh_nomina` (rol de RR. HH.), creado por `nomina_rrhh.sql`. Para usar otro usuario, por ejemplo `root` en XAMPP:

```powershell
$env:NOMINA_DB_USER = "root"
$env:NOMINA_DB_PASSWORD = ""
python main.py
```

El rol de RR. HH. no puede cerrar periodos ni modificar parámetros; para eso usa el usuario administrador.

Crear departamentos y cargos desde el menú también requiere un usuario con permiso de escritura sobre esas tablas (`root` o `admin_nomina`). Si prefieres que `rrhh_nomina` pueda hacerlo, ejecuta una vez como administrador:

```sql
GRANT INSERT ON nomina_rrhh.departamentos TO rol_rrhh;
GRANT INSERT ON nomina_rrhh.cargos TO rol_rrhh;
```

## Archivos

| Archivo | Función |
|---|---|
| `config.py` | Parámetros de conexión |
| `db.py` | Conexión, transacciones y consultas con parámetros |
| `services.py` | Operaciones: empleados, asistencia, ausencias y nómina |
| `reportes.py` | Tablas en consola, comprobante en texto y exportación a CSV |
| `main.py` | Menú de consola |
| `test_conexion.py` | Prueba de conexión |

## Ideas para crecer

Interfaz web con Flask, interfaz de escritorio con Tkinter, exportar el comprobante a PDF o análisis de la nómina con pandas.
