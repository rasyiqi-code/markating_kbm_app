import 'package:intl/intl.dart';

class AppFormatters {
  static final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final _numericFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  static String currency(num amount) {
    return _currencyFormatter.format(amount);
  }

  static String formatNumber(num amount) {
    return _numericFormatter.format(amount).trim();
  }
}
