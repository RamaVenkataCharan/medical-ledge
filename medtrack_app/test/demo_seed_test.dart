import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import '../demo_seed.dart';

void main() {
  final seed = DemoSeedData.build();
  final customers = seed['customers']! as List<Map<String, Object?>>;
  final purchases = seed['purchases']! as List<Map<String, Object?>>;
  final items = seed['purchase_items']! as List<Map<String, Object?>>;
  final payments = seed['payments']! as List<Map<String, Object?>>;

  test('demo seed is deterministic and safely labeled', () {
    expect(DemoSeedData.encode(), DemoSeedData.encode());
    expect(seed['marker'], DemoSeedData.marker);
    expect(customers, hasLength(24));
    expect(
        customers.every(
            (row) => (row['phone'] as String).startsWith('TEST-NO-CALL-')),
        isTrue);
    expect(seed.containsKey('owner_id'), isFalse);
    expect(seed.containsKey('supabase_url'), isFalse);
  });

  test('generated fixture has unique IDs and repeated runs replace by ID', () {
    final firstRun = _indexById(seed);
    final secondRun =
        _indexById(jsonDecode(DemoSeedData.encode()) as Map<String, Object?>);
    expect(secondRun.keys, firstRun.keys);
    expect(secondRun, firstRun);
  });

  test('purchase item sums, bill totals, payments, and customer dues balance',
      () {
    for (final purchase in purchases) {
      final purchaseItems =
          items.where((item) => item['purchase_id'] == purchase['id']);
      final subtotal = purchaseItems.fold<int>(
        0,
        (sum, item) => sum + (item['qty']! as int) * (item['rate']! as int),
      );
      expect(subtotal, purchase['subtotal']);
      final discount =
          (subtotal * (purchase['discount_percent']! as int) / 100).round();
      expect(discount, purchase['discount_amount']);
      expect(subtotal - discount, purchase['total']);
      expect(purchaseItems, isNotEmpty);
    }

    for (final customer in customers) {
      final customerId = customer['id'];
      final purchased = purchases
          .where((purchase) => purchase['customer_id'] == customerId)
          .fold<int>(0, (sum, purchase) => sum + (purchase['total']! as int));
      final paid = payments
          .where((payment) => payment['customer_id'] == customerId)
          .fold<int>(0, (sum, payment) => sum + (payment['amount']! as int));
      expect(paid, lessThanOrEqualTo(purchased));
      expect(purchased - paid, greaterThanOrEqualTo(0));
    }

    final dues = customers.map((customer) {
      final id = customer['id'];
      final purchased = purchases
          .where((purchase) => purchase['customer_id'] == id)
          .fold<int>(0, (sum, purchase) => sum + (purchase['total']! as int));
      final paid = payments
          .where((payment) => payment['customer_id'] == id)
          .fold<int>(0, (sum, payment) => sum + (payment['amount']! as int));
      return purchased - paid;
    });
    expect(dues, contains(0));
    expect(dues.any((due) => due > 0), isTrue);
    expect(purchases.length, greaterThan(20));
    expect(items.length, greaterThan(purchases.length));
  });

  test('fixture includes supported soft-deleted customer examples', () {
    expect(customers.where((row) => row['deleted_at'] != null), hasLength(2));
  });
}

Map<String, Map<String, Object?>> _indexById(Map<String, Object?> data) {
  final indexed = <String, Map<String, Object?>>{};
  for (final table in ['customers', 'purchases', 'payments']) {
    for (final row in (data[table]! as List).cast<Map<String, Object?>>()) {
      final id = row['id']! as String;
      expect(indexed.containsKey(id), isFalse, reason: 'duplicate ID $id');
      indexed[id] = row;
    }
  }
  return indexed;
}
