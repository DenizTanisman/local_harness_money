// Amount parsing/formatting shared by every money screen (moved here from
// the monolith's home input bodies and analysis repository).

/// Lenient number parse for amount fields: accepts ',' or '.' as the
/// decimal separator; empty or invalid → null.
double? parseNum(String raw) {
  final cleaned = raw.replaceAll(',', '.').trim();
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

/// Turkish-style amount: '.' thousands separator, ',' decimals, and no
/// decimals for whole numbers (15000 → '15.000', 12.5 → '12,50').
String formatAmount(double value) {
  final whole = value == value.roundToDouble();
  final text = whole ? value.toInt().toString() : value.toStringAsFixed(2);
  final parts = text.split('.');
  final digits = parts.first;
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0 && digits[i - 1] != '-') {
      buffer.write('.');
    }
    buffer.write(digits[i]);
  }
  return parts.length > 1 ? '$buffer,${parts[1]}' : buffer.toString();
}
