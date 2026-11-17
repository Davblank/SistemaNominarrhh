"""Operaciones del sistema. Aquí no hay fórmulas de nómina: el cálculo vive
en la base de datos (sp_generar_nomina) y Python solo lo invoca y consulta."""
from db import consultar, transaccion


# ----------------------------- catálogos -----------------------------
def listar_periodos():
    return consultar("SELECT id, fecha_inicio, fecha_fin, estado FROM periodos_nomina ORDER BY fecha_inicio")


def listar_departamentos():
    return consultar("SELECT id, nombre FROM departamentos WHERE activo = 1 ORDER BY nombre")


def listar_cargos():
    return consultar("SELECT id, nombre, salario_min, salario_max FROM cargos ORDER BY nombre")


def crear_departamento(nombre):
    nombre = nombre.strip()
    if consultar("SELECT id FROM departamentos WHERE nombre = %s", (nombre,)):
        raise ValueError(f"Ya existe un departamento llamado '{nombre}'")
    with transaccion() as cur:
        cur.execute("INSERT INTO departamentos (nombre) VALUES (%s)", (nombre,))
        return cur.lastrowid


def crear_cargo(nombre, salario_min, salario_max):
    nombre = nombre.strip()
    if salario_max < salario_min:
        raise ValueError("El salario máximo no puede ser menor que el mínimo")
    if consultar("SELECT id FROM cargos WHERE nombre = %s", (nombre,)):
        raise ValueError(f"Ya existe un cargo llamado '{nombre}'")
    with transaccion() as cur:
        cur.execute("INSERT INTO cargos (nombre, salario_min, salario_max) VALUES (%s,%s,%s)",
                    (nombre, salario_min, salario_max))
        return cur.lastrowid


# ----------------------------- empleados -----------------------------
def listar_empleados():
    return consultar(
        "SELECT documento, empleado, departamento, cargo, salario_base "
        "FROM v_empleados_activos ORDER BY empleado"
    )


def _empleado_id(documento):
    filas = consultar("SELECT id FROM empleados WHERE documento = %s AND activo = 1", (documento,))
    if not filas:
        raise ValueError(f"No existe un empleado activo con documento {documento}")
    return filas[0]["id"]


def crear_empleado(d):
    """Crea el empleado y su primer contrato en una sola transacción."""
    cargo = consultar("SELECT salario_min, salario_max FROM cargos WHERE id = %s", (d["cargo_id"],))
    if not cargo:
        raise ValueError("El cargo indicado no existe")
    minimo, maximo = cargo[0]["salario_min"], cargo[0]["salario_max"]
    if not (minimo <= d["salario"] <= maximo):
        raise ValueError(f"Para este cargo el salario debe estar entre {minimo:,.2f} y {maximo:,.2f}")

    with transaccion() as cur:
        cur.execute(
            "INSERT INTO empleados (documento, nombres, apellidos, email, telefono, "
            "fecha_ingreso, departamento_id, cargo_id) VALUES (%s,%s,%s,%s,%s,%s,%s,%s)",
            (d["documento"], d["nombres"], d["apellidos"], d["email"] or None, d["telefono"] or None,
             d["fecha_ingreso"], d["departamento_id"], d["cargo_id"]),
        )
        empleado_id = cur.lastrowid
        cur.execute(
            "INSERT INTO contratos (empleado_id, tipo, salario_base, fecha_inicio) VALUES (%s,%s,%s,%s)",
            (empleado_id, d["tipo"], d["salario"], d["fecha_ingreso"]),
        )
    return empleado_id


# ----------------------------- asistencia y ausencias -----------------------------
def registrar_asistencia(documento, fecha, entrada, salida, horas_extra):
    empleado_id = _empleado_id(documento)
    with transaccion() as cur:
        cur.execute(
            "INSERT INTO asistencia (empleado_id, fecha, hora_entrada, hora_salida, horas_extra) "
            "VALUES (%s,%s,%s,%s,%s)",
            (empleado_id, fecha, entrada or None, salida or None, horas_extra),
        )


def solicitar_ausencia(documento, tipo, desde, hasta, con_pago):
    empleado_id = _empleado_id(documento)
    with transaccion() as cur:
        cur.execute(
            "INSERT INTO ausencias (empleado_id, tipo, fecha_desde, fecha_hasta, con_pago) "
            "VALUES (%s,%s,%s,%s,%s)",
            (empleado_id, tipo, desde, hasta, 1 if con_pago else 0),
        )


def ausencias_pendientes():
    return consultar("SELECT id, empleado, tipo, fecha_desde, fecha_hasta, dias, con_pago "
                     "FROM v_ausencias_pendientes ORDER BY fecha_desde")


def resolver_ausencia(ausencia_id, aprobar):
    nuevo_estado = "APROBADA" if aprobar else "RECHAZADA"
    with transaccion() as cur:
        cur.execute("UPDATE ausencias SET estado = %s WHERE id = %s AND estado = 'PENDIENTE'",
                    (nuevo_estado, ausencia_id))
        if cur.rowcount == 0:
            raise ValueError("No existe una solicitud pendiente con ese número")


# ----------------------------- nómina -----------------------------
def calcular_nomina(periodo_id):
    """Llama al procedimiento almacenado. Si el periodo no existe o está cerrado,
    la base de datos lanza un error con su propio mensaje."""
    with transaccion() as cur:
        cur.execute("CALL sp_generar_nomina(%s)", (periodo_id,))


def resumen_nomina(periodo_id):
    return consultar(
        "SELECT departamento, empleados, devengado, deducciones, neto "
        "FROM v_resumen_nomina WHERE periodo_id = %s ORDER BY departamento", (periodo_id,))


def costo_laboral(periodo_id):
    return consultar(
        "SELECT empleado, total_devengado, aportes_empleador, prestaciones, costo_total "
        "FROM v_costo_laboral WHERE periodo_id = %s ORDER BY costo_total DESC", (periodo_id,))


def comprobante(documento, periodo_id):
    return consultar("SELECT * FROM v_comprobante WHERE documento = %s AND periodo_id = %s "
                     "ORDER BY concepto", (documento, periodo_id))
