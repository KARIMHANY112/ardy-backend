/// Formatting helpers shared by listing widgets. No `intl` dependency in the
/// project yet, so thousands-separators are done by hand.
library;

String formatThousands(num value) {
  final isNegative = value < 0;
  final wholePart = value.abs().truncate().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < wholePart.length; i++) {
    if (i > 0 && (wholePart.length - i) % 3 == 0) buffer.write(',');
    buffer.write(wholePart[i]);
  }
  return '${isNegative ? '-' : ''}$buffer';
}

/// "EGP 4.2M" for amounts >= 1,000,000, otherwise "EGP 950,000".
String formatEgp(num value) {
  if (value >= 1000000) {
    final millions = value / 1000000;
    final rounded = (millions * 10).round() / 10;
    final label = rounded == rounded.truncate() ? rounded.truncate().toString() : rounded.toStringAsFixed(1);
    return 'EGP ${label}M';
  }
  return 'EGP ${formatThousands(value)}';
}

String formatSqm(num value) => '${formatThousands(value)} sqm';
