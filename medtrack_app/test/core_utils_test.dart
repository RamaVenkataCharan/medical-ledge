import 'package:flutter_test/flutter_test.dart';
import 'package:medtrack_app/core/utils/money.dart';
import 'package:medtrack_app/core/utils/validators.dart';
import 'package:medtrack_app/core/utils/dates.dart' as date_utils;

void main() {
  group('BillingMath.computeTotals', () {
    test('zero items returns zero totals', () {
      final result = BillingMath.computeTotals([], 0);
      expect(result.subtotalPaise, 0);
      expect(result.discountPaise, 0);
      expect(result.totalPaise, 0);
    });

    test('single item, no discount', () {
      final items = [
        const LineItem(medicineName: 'Paracetamol', qty: 2, ratePaise: 4000)
      ];
      final result = BillingMath.computeTotals(items, 0);
      expect(result.subtotalPaise, 8000); // ₹80
      expect(result.discountPaise, 0);
      expect(result.totalPaise, 8000);
    });

    test('10% discount rounds correctly', () {
      // ₹145 subtotal, 10% = ₹14.5 → rounds to ₹15 (1500 paise)
      final items = [
        const LineItem(medicineName: 'Med A', qty: 2, ratePaise: 4000), // ₹80
        const LineItem(medicineName: 'Med B', qty: 1, ratePaise: 4500), // ₹45
        const LineItem(medicineName: 'Med C', qty: 1, ratePaise: 2000), // ₹20
      ];
      // subtotal = ₹145 = 14500 paise
      // 10% of 14500 = 1450 paise = ₹14.50 → rounds to 1450 (nearest rupee = 1500? no)
      // round(14500 * 10 / 100) = round(1450) = 1450
      final result = BillingMath.computeTotals(items, 10);
      expect(result.subtotalPaise, 14500);
      expect(result.discountPaise, 1450); // 10% of 14500 exactly
      expect(result.totalPaise, 13050);
    });

    test('multiple items with 15% discount', () {
      // ₹1000 subtotal, 15% = ₹150
      final items = [
        const LineItem(medicineName: 'Med', qty: 1, ratePaise: 100000),
      ];
      final result = BillingMath.computeTotals(items, 15);
      expect(result.subtotalPaise, 100000);
      expect(result.discountPaise, 15000);
      expect(result.totalPaise, 85000);
    });

    test('fractional percentage discount rounds correctly', () {
      // 3 × ₹40 = ₹120 subtotal = 12000 paise, 7% = 840 paise exactly
      final items = [
        const LineItem(medicineName: 'Med', qty: 3, ratePaise: 4000),
      ];
      final result = BillingMath.computeTotals(items, 7);
      expect(result.subtotalPaise, 12000);
      expect(result.discountPaise, 840);
      expect(result.totalPaise, 11160);
    });
  });

  group('MoneyUtils.formatPaise', () {
    test('formats whole rupees without decimals', () {
      expect(MoneyUtils.formatPaise(14500), '₹145');
    });

    test('formats paise with decimals when needed', () {
      expect(MoneyUtils.formatPaise(14550), '₹145.50');
    });

    test('formats large amount with Indian grouping', () {
      // ₹1,24,000
      expect(MoneyUtils.formatPaise(12400000), '₹1,24,000');
    });

    test('zero formats as ₹0', () {
      expect(MoneyUtils.formatPaise(0), '₹0');
    });
  });

  group('MoneyUtils.rupeesToPaise', () {
    test('converts whole rupees', () {
      expect(MoneyUtils.rupeesToPaise(145), 14500);
    });

    test('converts decimal rupees', () {
      expect(MoneyUtils.rupeesToPaise(14.5), 1450);
    });
  });

  group('PhoneValidator', () {
    test('valid phone passes', () {
      expect(PhoneValidator.validate('9876543210'), isNull);
    });

    test('phone starting with 6 passes', () {
      expect(PhoneValidator.validate('6123456789'), isNull);
    });

    test('phone starting with 5 fails', () {
      expect(PhoneValidator.validate('5123456789'), isNotNull);
    });

    test('9-digit phone fails', () {
      expect(PhoneValidator.validate('987654321'), isNotNull);
    });

    test('empty phone fails', () {
      expect(PhoneValidator.validate(''), isNotNull);
    });

    test('phone with spaces is trimmed and validated', () {
      expect(PhoneValidator.validate('98765 43210'), isNull);
    });
  });

  group('Validators.email', () {
    test('valid email passes', () {
      expect(Validators.email('user@example.com'), isNull);
    });

    test('invalid email fails', () {
      expect(Validators.email('notanemail'), isNotNull);
    });

    test('empty email fails', () {
      expect(Validators.email(''), isNotNull);
    });
  });

  group('Validators.discountPercent', () {
    test('valid 0 passes', () {
      expect(Validators.discountPercent('0'), isNull);
    });

    test('valid 100 passes', () {
      expect(Validators.discountPercent('100'), isNull);
    });

    test('101 fails', () {
      expect(Validators.discountPercent('101'), isNotNull);
    });

    test('negative fails', () {
      expect(Validators.discountPercent('-1'), isNotNull);
    });
  });

  group('DateUtils.recycleBinDaysLeft', () {
    test('returns 30 for just-deleted', () {
      final deletedAt = DateTime.now().toUtc();
      final left = date_utils.DateUtils.recycleBinDaysLeft(deletedAt);
      expect(left, 30);
    });

    test('returns 0 for 30+ days ago', () {
      final deletedAt =
          DateTime.now().subtract(const Duration(days: 31)).toUtc();
      final left = date_utils.DateUtils.recycleBinDaysLeft(deletedAt);
      expect(left, 0);
    });

    test('returns correct days for 7 days ago', () {
      final deletedAt =
          DateTime.now().subtract(const Duration(days: 7)).toUtc();
      final left = date_utils.DateUtils.recycleBinDaysLeft(deletedAt);
      expect(left, 23);
    });
  });

  group('DateUtils.daysUntil', () {
    test('future date returns positive', () {
      final future = DateTime.now().add(const Duration(days: 30));
      expect(date_utils.DateUtils.daysUntil(future), 30);
    });

    test('past date returns negative', () {
      final past = DateTime.now().subtract(const Duration(days: 5));
      expect(date_utils.DateUtils.daysUntil(past), -5);
    });
  });
}
