import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _formatterCompact = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 1,
  );

  /// Format as full currency: Rp 1.250.000
  static String format(double amount) => _formatter.format(amount.abs());

  /// Format compact: Rp 1,2Jt
  static String formatCompact(double amount) =>
      _formatterCompact.format(amount.abs());

  /// Format with sign: +Rp 1.250.000 or -Rp 750.000
  static String formatSigned(double amount) {
    final prefix = amount >= 0 ? '+' : '-';
    return '$prefix${_formatter.format(amount.abs())}';
  }
}

class DateFormatter {
  static const _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const _monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  /// Example: 22 Okt
  static String dayMonth(DateTime d) =>
      '${d.day} ${_monthsShort[d.month - 1]}';

  /// Example: 22 Oktober 2026
  static String full(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  /// Example: Oktober 2026
  static String monthYear(DateTime d) =>
      '${_months[d.month - 1]} ${d.year}';

  /// Example: 22 Okt 2026
  static String short(DateTime d) =>
      '${d.day} ${_monthsShort[d.month - 1]} ${d.year}';

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
