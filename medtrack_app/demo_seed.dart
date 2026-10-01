import 'dart:convert';

/// Deterministic, local-only sample data. It contains no real people or products.
/// This fixture intentionally has no owner IDs and cannot be sent to Supabase.
class DemoSeedData {
  DemoSeedData._();

  static const marker = 'MEDTRACK_DEMO_ONLY';

  static Map<String, Object?> build() {
    final customers = <Map<String, Object?>>[];
    final purchases = <Map<String, Object?>>[];
    final items = <Map<String, Object?>>[];
    final payments = <Map<String, Object?>>[];

    for (var customerNumber = 1; customerNumber <= 24; customerNumber++) {
      final customerId = _id('1', customerNumber);
      final isDeleted = customerNumber >= 23;
      customers.add({
        'id': customerId,
        'name': 'Sample Customer ${customerNumber.toString().padLeft(2, '0')}',
        'phone': 'TEST-NO-CALL-${customerNumber.toString().padLeft(4, '0')}',
        'village': 'Demo Ward ${(customerNumber % 5) + 1}',
        'is_favorite': customerNumber % 4 == 0,
        'deleted_at': isDeleted ? '2025-01-15T10:00:00Z' : null,
        'created_at': '2025-01-01T09:00:00Z',
      });

      // First four customers have no purchases. Others have 1–5 varied bills.
      if (customerNumber <= 4) {
        continue;
      }
      final purchaseCount = 1 + (customerNumber % 5);
      for (var purchaseNumber = 1;
          purchaseNumber <= purchaseCount;
          purchaseNumber++) {
        final purchaseId = _id('2', customerNumber * 10 + purchaseNumber);
        final firstQty = 1 + ((customerNumber + purchaseNumber) % 3);
        final firstRate = 35 + (customerNumber * 7) + (purchaseNumber * 4);
        final secondQty = 1 + (purchaseNumber % 2);
        final secondRate = 22 + (customerNumber * 3);
        final purchaseItems = [
          {
            'medicine_name': 'Sample Tablet ${1 + (customerNumber % 6)}',
            'pack_label': 'Demo strip',
            'qty': firstQty,
            'rate': firstRate,
            'amount': firstQty * firstRate,
          },
          {
            'medicine_name': 'Sample Syrup ${1 + (purchaseNumber % 4)}',
            'pack_label': 'Demo bottle',
            'qty': secondQty,
            'rate': secondRate,
            'amount': secondQty * secondRate,
          },
        ];
        final subtotal = purchaseItems.fold<int>(
          0,
          (sum, item) => sum + (item['amount']! as int),
        );
        final discountPercent =
            (customerNumber + purchaseNumber) % 4 == 0 ? 5 : 0;
        final discountAmount = (subtotal * discountPercent / 100).round();
        final total = subtotal - discountAmount;
        final purchasedAt = DateTime.utc(
          2025,
          1 + ((customerNumber + purchaseNumber) % 6),
          1 + purchaseNumber,
          10,
        ).toIso8601String();

        purchases.add({
          'id': purchaseId,
          'customer_id': customerId,
          'purchased_at': purchasedAt,
          'subtotal': subtotal,
          'discount_percent': discountPercent,
          'discount_amount': discountAmount,
          'total': total,
          'deleted_at': null,
        });
        items.addAll(purchaseItems.map((item) => {
              ...item,
              'purchase_id': purchaseId,
            }));

        // 5–8 are fully settled, 9–12 partially paid, and the rest vary by bill.
        final isSettled = customerNumber >= 5 && customerNumber <= 8;
        final isPartial = customerNumber >= 9 && customerNumber <= 12;
        final paidAmount = isSettled
            ? total
            : isPartial
                ? (purchaseNumber == 1 ? (total ~/ 2) : 0)
                : ((customerNumber + purchaseNumber) % 3 == 0 ? total : 0);
        if (paidAmount > 0) {
          payments.add({
            'id': _id('3', customerNumber * 100 + purchaseNumber),
            'customer_id': customerId,
            'purchase_id': purchaseId,
            'amount': paidAmount,
            'method': [
              'cash',
              'upi',
              'card'
            ][(customerNumber + purchaseNumber) % 3],
            'paid_at': purchasedAt,
            'notes': 'Demo payment',
          });
        }
      }
    }

    return {
      'marker': marker,
      'description': 'Fictional local test data; never upload to Supabase.',
      'customers': customers,
      'purchases': purchases,
      'purchase_items': items,
      'payments': payments,
    };
  }

  static String encode() => const JsonEncoder.withIndent('  ').convert(build());

  static String _id(String category, int value) =>
      '00000000-0000-4000-800$category-${value.toString().padLeft(12, '0')}';
}
