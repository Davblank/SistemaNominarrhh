"""Presentación: tablas en consola, comprobante de pago en texto y exportación a CSV."""
import csv
from decimal import Decimal


def dinero(valor):
    return f"{valor:,.2f}"


def _texto(valor):
    if isinstance(valor, Decimal):
        return dinero(valor)
    return "" if valor is None else str(valor)


def tabla(filas):
    """Imprime una lista de diccionarios como tabla alineada."""
    if not filas:
        print("  (sin resultados)")
        return
    columnas = list(filas[0].keys())
    anchos = {c: max(len(c), *(len(_texto(f[c])) for f in filas)) for c in columnas}
    numericas = {c: isinstance(filas[0][c], (Decimal, int, float)) for c in columnas}
    print("  " + "  ".join((c.upper().rjust(anchos[c]) if numericas[c] else c.upper().ljust(anchos[c])) for c in columnas))
    print("  " + "  ".join("-" * anchos[c] for c in columnas))
    for f in filas:
        celdas = []
        for c in columnas:
            t = _texto(f[c])
            celdas.append(t.rjust(anchos[c]) if isinstance(f[c], (Decimal, int, float)) else t.ljust(anchos[c]))
        print("  " + "  ".join(celdas))


def formatear_comprobante(filas):
    """Convierte las filas de v_comprobante en un comprobante de pago en texto."""
    if not filas:
        return "No hay comprobante para ese empleado y periodo. ¿Ya se calculó la nómina?"
    h = filas[0]
    ancho = 56
    linea = "=" * ancho
    out = [linea,
           f"{h['razon_social']}  NIT {h['nit']}".center(ancho),
           f"COMPROBANTE DE PAGO {h['numero']} [{h['estado']}]".center(ancho),
           linea,
           f"Empleado : {h['empleado']} (doc. {h['documento']})",
           f"Cargo    : {h['cargo']} - {h['departamento']}",
           f"Periodo  : {h['fecha_inicio']} a {h['fecha_fin']}   Días pagados: {h['dias_pagados']}",
           f"Fecha de pago: {h['fecha_pago']}",
           "-" * ancho]
    for titulo, tipo in (("DEVENGOS", "DEVENGO"), ("DEDUCCIONES", "DEDUCCION")):
        out.append(titulo)
        for f in filas:
            if f["tipo"] == tipo:
                out.append(f"  {f['concepto']:<38}{dinero(f['valor']):>14}")
        out.append("")
    out += ["-" * ancho,
            f"{'Total devengado':<40}{dinero(h['total_devengado']):>14}",
            f"{'Total deducciones':<40}{dinero(h['total_deducciones']):>14}",
            f"{'NETO A PAGAR':<40}{dinero(h['neto']):>14}",
            linea]
    return "\n".join(out)


def exportar_csv(filas, ruta):
    """Guarda las filas en CSV con codificación que Excel abre bien (UTF-8 con BOM)."""
    if not filas:
        raise ValueError("No hay datos para exportar")
    with open(ruta, "w", newline="", encoding="utf-8-sig") as f:
        escritor = csv.DictWriter(f, fieldnames=list(filas[0].keys()))
        escritor.writeheader()
        escritor.writerows(filas)
