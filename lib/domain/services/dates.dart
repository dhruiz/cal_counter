/// Utilidades de fechas compartidas por los módulos de compras.
library;

/// Fecha como `YYYY-MM-DD` (formato de las columnas `fecha` de la BD).
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Solo la parte de fecha (medianoche local).
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Mismo día de hace 3 meses (sin hora). Si ese día no existe en el mes de
/// destino (31 de mayo → 31 de febrero) se usa el último día de ese mes.
DateTime threeMonthsAgo(DateTime now) {
  var year = now.year;
  var month = now.month - 3;
  if (month < 1) {
    month += 12;
    year -= 1;
  }
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = now.day > lastDay ? lastDay : now.day;
  return DateTime(year, month, day);
}
