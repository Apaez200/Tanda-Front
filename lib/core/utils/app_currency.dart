import 'package:intl/intl.dart';

final NumberFormat _mxn = NumberFormat.currency(
  locale: 'es_MX',
  symbol: r'$',
  decimalDigits: 2,
  
);

/// Formato de peso mexicano visible: `$1,000.00 MXN`
String formatMxn(double value) => '${_mxn.format(value)} MXN';

String formatMxnShort(double value) => _mxn.format(value);
