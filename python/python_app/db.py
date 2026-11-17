"""Capa de conexión: abre conexiones y ejecuta consultas con parámetros."""
from contextlib import contextmanager

import pymysql
from pymysql.cursors import DictCursor

import config


def conectar():
    """Abre una conexión nueva. Las filas se devuelven como diccionarios."""
    return pymysql.connect(
        host=config.DB_HOST,
        port=config.DB_PORT,
        user=config.DB_USER,
        password=config.DB_PASSWORD,
        database=config.DB_NAME,
        charset="utf8mb4",
        cursorclass=DictCursor,
        autocommit=False,
    )


@contextmanager
def transaccion():
    """Entrega un cursor; hace COMMIT si todo sale bien y ROLLBACK si hay un error."""
    conn = conectar()
    try:
        with conn.cursor() as cur:
            yield cur
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def consultar(sql, params=None):
    """Ejecuta un SELECT y devuelve una lista de diccionarios.

    Siempre se usan parámetros (%s) y nunca texto pegado a la consulta;
    así se evita la inyección SQL.
    """
    with transaccion() as cur:
        cur.execute(sql, params or ())
        return cur.fetchall()
