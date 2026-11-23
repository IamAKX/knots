import 'package:intl/intl.dart';

final _full = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

/// ₹12,50,000
String money(num v) => _full.format(v);

/// ₹12.5L, ₹1.2Cr, ₹45K — compact for tight spaces.
String moneyShort(num v) {
  final a = v.abs();
  final s = v < 0 ? '-' : '';
  String t(double x) =>
      x.toStringAsFixed(x >= 10 || x == x.roundToDouble() ? 0 : 1);
  if (a >= 10000000) return '$s₹${t(a / 10000000)}Cr';
  if (a >= 100000) return '$s₹${t(a / 100000)}L';
  if (a >= 1000) return '$s₹${t(a / 1000)}K';
  return '$s₹${a.round()}';
}

String dateShort(DateTime d) => DateFormat('d MMM yyyy').format(d);
String dateDay(DateTime d) => DateFormat('d MMM').format(d);
String monthKey(DateTime d) => DateFormat('MMM yy').format(d);
