"""Configuración de la conexión a MariaDB.

Por defecto usa el usuario de RR. HH. que crea nomina_rrhh.sql (rrhh_nomina).
Puedes cambiarlo con variables de entorno, sin tocar el código:

    Windows (PowerShell):  $env:NOMINA_DB_USER = "root"; $env:NOMINA_DB_PASSWORD = ""
    Linux / macOS:         export NOMINA_DB_USER=root NOMINA_DB_PASSWORD=
"""
import os

DB_HOST = os.environ.get("NOMINA_DB_HOST", "127.0.0.1")
DB_PORT = int(os.environ.get("NOMINA_DB_PORT", "3306"))
DB_NAME = os.environ.get("NOMINA_DB_NAME", "nomina_rrhh")
DB_USER = os.environ.get("NOMINA_DB_USER", "rrhh_nomina")
# Contraseña de DEMOSTRACIÓN definida en el script de seguridad. Cámbiala fuera de pruebas.
DB_PASSWORD = os.environ.get("NOMINA_DB_PASSWORD", "Rrhh#2026")
