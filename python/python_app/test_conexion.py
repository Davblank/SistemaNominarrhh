"""Primera prueba: verifica la conexión y que la base esté instalada.
Ejecuta:  python test_conexion.py
"""
import pymysql

import config
from db import consultar


def main():
    print(f"Conectando a {config.DB_HOST}:{config.DB_PORT} como '{config.DB_USER}'...")
    try:
        version = consultar("SELECT VERSION() AS version")[0]["version"]
        print(f"  Conexión correcta. Servidor: {version}")
        tablas = consultar("SELECT COUNT(*) AS n FROM information_schema.tables "
                           "WHERE table_schema = %s AND table_type = 'BASE TABLE'", (config.DB_NAME,))[0]["n"]
        vistas = consultar("SELECT COUNT(*) AS n FROM information_schema.views "
                           "WHERE table_schema = %s", (config.DB_NAME,))[0]["n"]
        print(f"  Base '{config.DB_NAME}': {tablas} tablas y {vistas} vistas (se esperan 16 y 8).")
        for etiqueta, sql in (("Departamentos", "SELECT COUNT(*) AS n FROM departamentos"),
                              ("Cargos", "SELECT COUNT(*) AS n FROM cargos"),
                              ("Periodos de nómina", "SELECT COUNT(*) AS n FROM periodos_nomina"),
                              ("Empleados activos", "SELECT COUNT(*) AS n FROM v_empleados_activos")):
            n = consultar(sql)[0]["n"]
            aviso = "" if n else "   <-- VACÍO: falta importar insert_sistema_nomina.sql"
            print(f"  {etiqueta}: {n}{aviso}")
    except pymysql.err.OperationalError as e:
        print(f"  No se pudo conectar: {e.args[1] if len(e.args) > 1 else e}")
        print("  Revisa que MySQL esté iniciado en XAMPP, que importaste los dos archivos .sql")
        print("  y que el usuario y la contraseña de config.py sean correctos.")
    except pymysql.MySQLError as e:
        print(f"  Error de base de datos: {e.args[1] if len(e.args) > 1 else e}")


if __name__ == "__main__":
    main()
