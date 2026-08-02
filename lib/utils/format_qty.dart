/// Meal / quantity display: trim trailing `.0` (1 → `1`, 1.5 → `1.5`).
String formatQty(num n) {
  final d = n.toDouble();
  if (d == d.roundToDouble()) return d.toInt().toString();
  return d.toStringAsFixed(1);
}
