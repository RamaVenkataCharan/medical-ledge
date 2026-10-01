import 'package:intl/intl.dart';

/// Money utilities — all amounts are stored as int paise (1 rupee = 100 paise)
/// NEVER use double for currency calculations.
class MoneyUtils {
  MoneyUtils._();

  static final _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _inrFormatterPaise = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Format paise as ₹ with Indian grouping (e.g., ₹1,24,000)
  static String formatPaise(int paise) {
    if (paise % 100 == 0) {
      return _inrFormatter.format(paise ~/ 100);
    }
    return _inrFormatterPaise.format(paise / 100);
  }

  /// Format rupees (int) as ₹ with Indian grouping
  static String formatRupees(int rupees) {
    return _inrFormatter.format(rupees);
  }

  /// Format double rupees for display
  static String formatDouble(double rupees) {
    final wholeRupees = rupees.round();
    if ((rupees - wholeRupees).abs() < 0.005) {
      return _inrFormatter.format(wholeRupees);
    }
    return _inrFormatterPaise.format(rupees);
  }

  /// Convert rupees (num) to paise (int), rounded
  static int rupeesToPaise(num rupees) => (rupees * 100).round();

  /// Convert paise to rupees (double)
  static double paisToRupees(int paise) => paise / 100;

  /// Parse a display string like "1,24,000" or "1240" back to paise
  static int? parseRupees(String input) {
    final clean = input.replaceAll(',', '').replaceAll('₹', '').trim();
    final val = double.tryParse(clean);
    if (val == null) return null;
    return (val * 100).round();
  }
}

/// Billing math — pure functions, unit-tested
class BillingMath {
  BillingMath._();

  /// Compute bill totals. All monetary values in paise.
  static BillTotals computeTotals(
    List<LineItem> items,
    double discountPercent,
  ) {
    final subtotalPaise =
        items.fold<int>(0, (sum, item) => sum + item.qty * item.ratePaise);
    // Round discount to nearest rupee (100 paise)
    final discountPaise =
        ((subtotalPaise * discountPercent) / 100).round();
    final totalPaise = subtotalPaise - discountPaise;
    return BillTotals(
      subtotalPaise: subtotalPaise,
      discountPaise: discountPaise,
      totalPaise: totalPaise,
    );
  }
}

class LineItem {
  const LineItem({
    required this.medicineName,
    required this.qty,
    required this.ratePaise,
  });

  final String medicineName;
  final int qty;
  final int ratePaise; // rate per unit in paise
}

class BillTotals {
  const BillTotals({
    required this.subtotalPaise,
    required this.discountPaise,
    required this.totalPaise,
  });

  final int subtotalPaise;
  final int discountPaise;
  final int totalPaise;
}
