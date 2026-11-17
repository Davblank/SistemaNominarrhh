"""Aplicación de consola del Sistema de Nómina y RR. HH.
Ejecuta:  python main.py
"""
import sys
from datetime import date
from decimal import Decimal, InvalidOperation

import pymysql

import reportes
import services


# ----------------------------- entradas validadas -----------------------------
def pedir_texto(mensaje, obligatorio=True):
    while True:
        valor = input(f"  {mensaje}: ").strip()
        if valor or not obligatorio:
            return valor
        print("    Este dato es obligatorio.")


def pedir_entero(mensaje):
    while True:
        try:
            return int(input(f"  {mensaje}: ").strip())
        except ValueError:
            print("    Escribe un número entero.")


def pedir_decimal(mensaje, minimo=Decimal("0")):
    while True:
        try:
            valor = Decimal(input(f"  {mensaje}: ").strip().replace(",", "."))
            if valor >= minimo:
                return valor
            print(f"    Debe ser mayor o igual que {minimo}.")
        except InvalidOperation:
            print("    Escribe un número válido.")


def pedir_fecha(mensaje):
    while True:
        try:
            return date.fromisoformat(input(f"  {mensaje} (AAAA-MM-DD): ").strip())
        except ValueError:
            print("    Formato de fecha inválido. Ejemplo: 2026-09-15")


def elegir(mensaje, opciones):
    """Muestra una lista de diccionarios con 'id' y pide elegir uno."""
    if not opciones:
        raise ValueError("La lista está vacía. Créala desde el menú (gestión de departamentos y cargos) "
                         "o importa insert_sistema_nomina.sql.")
    reportes.tabla(opciones)
    ids = {o["id"] for o in opciones}
    while True:
        elegido = pedir_entero(mensaje)
        if elegido in ids:
            return elegido
        print("    Ese número no está en la lista.")


def elegir_periodo():
    print("\n  Periodos disponibles:")
    return elegir("Número del periodo", services.listar_periodos())


# ----------------------------- acciones -----------------------------
def ver_empleados():
    reportes.tabla(services.listar_empleados())


def gestionar_departamentos():
    print("\n  Departamentos actuales:")
    reportes.tabla(services.listar_departamentos())
    if input("\n  ¿Crear un departamento nuevo? (s/n): ").strip().lower() != "s":
        return
    nombre = pedir_texto("Nombre del departamento")
    nuevo_id = services.crear_departamento(nombre)
    print(f"  Departamento creado con id {nuevo_id}.")
    reportes.tabla(services.listar_departamentos())


def gestionar_cargos():
    print("\n  Cargos actuales:")
    reportes.tabla(services.listar_cargos())
    if input("\n  ¿Crear un cargo nuevo? (s/n): ").strip().lower() != "s":
        return
    nombre = pedir_texto("Nombre del cargo")
    minimo = pedir_decimal("Salario mínimo", Decimal("0.01"))
    maximo = pedir_decimal("Salario máximo", minimo)
    nuevo_id = services.crear_cargo(nombre, minimo, maximo)
    print(f"  Cargo creado con id {nuevo_id}.")
    reportes.tabla(services.listar_cargos())


def nuevo_empleado():
    print("\n  Datos del nuevo empleado")
    datos = {
        "documento": pedir_texto("Documento"),
        "nombres": pedir_texto("Nombres"),
        "apellidos": pedir_texto("Apellidos"),
        "email": pedir_texto("Email (opcional)", obligatorio=False),
        "telefono": pedir_texto("Teléfono (opcional)", obligatorio=False),
        "fecha_ingreso": pedir_fecha("Fecha de ingreso"),
    }
    print("\n  Departamentos:")
    datos["departamento_id"] = elegir("Número del departamento", services.listar_departamentos())
    print("\n  Cargos:")
    datos["cargo_id"] = elegir("Número del cargo", services.listar_cargos())
    tipos = {"1": "INDEFINIDO", "2": "FIJO", "3": "PRESTACION", "4": "APRENDIZAJE"}
    print("\n  Tipo de contrato: 1) Indefinido  2) Fijo  3) Prestación  4) Aprendizaje")
    while (t := input("  Opción: ").strip()) not in tipos:
        print("    Elige 1, 2, 3 o 4.")
    datos["tipo"] = tipos[t]
    datos["salario"] = pedir_decimal("Salario base", Decimal("0.01"))
    nuevo_id = services.crear_empleado(datos)
    print(f"\n  Empleado creado con id {nuevo_id}.")


def nueva_asistencia():
    print("\n  Registro de asistencia")
    documento = pedir_texto("Documento del empleado")
    fecha = pedir_fecha("Fecha")
    entrada = pedir_texto("Hora de entrada HH:MM (opcional)", obligatorio=False)
    salida = pedir_texto("Hora de salida HH:MM (opcional)", obligatorio=False)
    horas = pedir_decimal("Horas extra")
    services.registrar_asistencia(documento, fecha, entrada, salida, horas)
    print("  Asistencia registrada.")


def nueva_ausencia():
    print("\n  Solicitud de ausencia")
    documento = pedir_texto("Documento del empleado")
    tipos = {"1": "VACACIONES", "2": "PERMISO", "3": "INCAPACIDAD", "4": "LICENCIA"}
    print("  Tipo: 1) Vacaciones  2) Permiso  3) Incapacidad  4) Licencia")
    while (t := input("  Opción: ").strip()) not in tipos:
        print("    Elige 1, 2, 3 o 4.")
    desde = pedir_fecha("Desde")
    hasta = pedir_fecha("Hasta")
    if hasta < desde:
        raise ValueError("La fecha final no puede ser anterior a la inicial")
    con_pago = input("  ¿Con pago? (s/n): ").strip().lower() == "s"
    services.solicitar_ausencia(documento, tipos[t], desde, hasta, con_pago)
    print("  Solicitud registrada como PENDIENTE.")


def aprobar_ausencias():
    pendientes = services.ausencias_pendientes()
    if not pendientes:
        print("  No hay solicitudes pendientes.")
        return
    reportes.tabla(pendientes)
    numero = pedir_entero("Número de la solicitud a resolver")
    decision = input("  ¿Aprobar (a) o rechazar (r)?: ").strip().lower()
    if decision not in ("a", "r"):
        raise ValueError("Escribe 'a' para aprobar o 'r' para rechazar")
    services.resolver_ausencia(numero, decision == "a")
    print("  Solicitud actualizada.")


def calcular():
    periodo = elegir_periodo()
    services.calcular_nomina(periodo)
    print("  Nómina calculada. Se generaron prestaciones, aportes y comprobantes.")
    reportes.tabla(services.resumen_nomina(periodo))


def resumen():
    reportes.tabla(services.resumen_nomina(elegir_periodo()))


def costo():
    reportes.tabla(services.costo_laboral(elegir_periodo()))


def ver_comprobante():
    periodo = elegir_periodo()
    documento = pedir_texto("Documento del empleado")
    print()
    print(reportes.formatear_comprobante(services.comprobante(documento, periodo)))


def exportar():
    periodo = elegir_periodo()
    documento = pedir_texto("Documento del empleado")
    filas = services.comprobante(documento, periodo)
    if not filas:
        raise ValueError("No hay comprobante para exportar. ¿Ya se calculó la nómina?")
    ruta = f"comprobante_{filas[0]['numero']}.csv"
    reportes.exportar_csv(filas, ruta)
    print(f"  Archivo guardado: {ruta}")


MENU = [
    ("Ver empleados activos", ver_empleados),
    ("Gestionar departamentos (ver y crear)", gestionar_departamentos),
    ("Gestionar cargos (ver y crear)", gestionar_cargos),
    ("Registrar empleado y contrato", nuevo_empleado),
    ("Registrar asistencia y horas extra", nueva_asistencia),
    ("Solicitar ausencia", nueva_ausencia),
    ("Aprobar o rechazar ausencias pendientes", aprobar_ausencias),
    ("Calcular nómina de un periodo", calcular),
    ("Resumen de nómina por departamento", resumen),
    ("Costo laboral para la empresa", costo),
    ("Ver comprobante de pago", ver_comprobante),
    ("Exportar comprobante a CSV", exportar),
]


def main():
    while True:
        print("\n===== SISTEMA DE NÓMINA Y RR. HH. =====")
        for i, (texto, _) in enumerate(MENU, start=1):
            print(f"  {i:>2}. {texto}")
        print("   0. Salir")
        opcion = input("\n  Elige una opción: ").strip()
        if opcion == "0":
            print("  Hasta luego.")
            return
        if not opcion.isdigit() or not 1 <= int(opcion) <= len(MENU):
            print("  Opción inválida.")
            continue
        try:
            print()
            MENU[int(opcion) - 1][1]()
        except ValueError as e:
            print(f"\n  Dato no válido: {e}")
        except pymysql.err.IntegrityError as e:
            print(f"\n  La base de datos rechazó el dato: {e.args[1]}")
        except pymysql.err.OperationalError as e:
            if e.args[0] == 1142:
                print(f"\n  Tu usuario de base de datos no tiene permiso para esta acción: {e.args[1]}")
                print("  Usa el usuario root/administrador (ver README_python.md) o pide el permiso con un GRANT.")
            else:
                print(f"\n  Error de conexión o de permisos: {e.args[1]}")
        except pymysql.MySQLError as e:
            # Aquí llegan, por ejemplo, los mensajes del SIGNAL del procedimiento de nómina
            print(f"\n  Error de la base de datos: {e.args[1] if len(e.args) > 1 else e}")
        except (KeyboardInterrupt, EOFError):
            print("\n  Operación cancelada.")


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, EOFError):
        sys.exit(0)
