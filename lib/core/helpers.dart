import 'package:intl/intl.dart';

class Formatters {
  static final _money = NumberFormat('#,##0.00', 'en_US');

  static String money(num value) => _money.format(value);

  static String now() {
    final d = DateTime.now();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(d);
  }
}
