import 'package:intl/intl.dart';

class DataUnitConverter {
  static const int bitsInMB = 1024 * 1024 * 8;

  static double bitsToMB(int bits) => bits / bitsInMB;

  static double mbToBits(double mb) => mb * bitsInMB;

  static String formatBits(int bits, [String locale = 'en_US']) {
    final numberFormat = NumberFormat.decimalPattern(locale);
    numberFormat.minimumFractionDigits = 2;
    numberFormat.maximumFractionDigits = 2;

    if (bits < 1024) {
      return '$bits bits';
    } else if (bits < 1024 * 1024 * 8) {
      final kb = (bits / (1024 * 8));
      return '${numberFormat.format(kb)} KB';
    } else {
      final mb = bitsToMB(bits);
      return '${numberFormat.format(mb)} MB';
    }
  }
}
