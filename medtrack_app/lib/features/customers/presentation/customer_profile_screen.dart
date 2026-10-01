import 'package:flutter/material.dart' hide DateUtils;
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/routes.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/dates.dart';
import '../../../core/widgets/stat_card.dart' show AvatarInitials;

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key, required this.customerId});
  final String customerId;

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _customer;
  List<Map<String, dynamic>> _purchases = [];
  double _totalPurchased = 0;
  double _totalPaid = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  double get _due => _totalPurchased - _totalPaid;

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;

      // Customer
      final custRes = await _supabase
          .from('customers')
          .select('id, name, phone, village, address, notes, is_favorite, created_at')
          .eq('id', widget.customerId)
          .eq('owner_id', uid)
          .single();
      _customer = Map<String, dynamic>.from(custRes);

      // Purchases with items
      final purchRes = await _supabase
          .from('purchases')
          .select('id, purchased_at, subtotal, discount_percent, discount_amount, total, notes, purchase_items(medicine_name, qty, rate, amount)')
          .eq('customer_id', widget.customerId)
          .eq('owner_id', uid)
          .isFilter('deleted_at', null)
          .order('purchased_at', ascending: false);
      _purchases = List<Map<String, dynamic>>.from(purchRes as List);

      // Totals
      _totalPurchased = _purchases.fold(0, (sum, p) => sum + ((p['total'] as num?)?.toDouble() ?? 0));

      // Payments
      final payRes = await _supabase
          .from('payments')
          .select('amount')
          .eq('customer_id', widget.customerId)
          .eq('owner_id', uid);
      _totalPaid = (payRes as List).fold(0.0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0));
    } catch (e) {
      _error = 'Failed to load customer.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCustomer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Customer?'),
        content: const Text('Move this customer to Recycle Bin? '
            'They can be restored within 30 days.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _supabase
          .from('customers')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', widget.customerId)
          .eq('owner_id', uid);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete customer.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Text(_customer?['name'] as String? ?? 'Customer'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.charcoal,
        elevation: 0,
        actions: [
          if (_customer != null) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await context.push(AppRoutes.editCustomer(widget.customerId));
                _load();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger),
              onPressed: _deleteCustomer,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.danger, size: 40),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.danger)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _load,
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfile(),
                        _buildBalanceBanner(),
                        _buildActions(),
                        _buildPurchaseHistory(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfile() {
    final c = _customer!;
    final name = c['name'] as String? ?? '';
    final phone = c['phone'] as String? ?? '';
    final village = c['village'] as String? ?? '';
    final notes = c['notes'] as String? ?? '';

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          AvatarInitials(name: name, size: 64),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        size: 14, color: AppColors.grey500),
                    const SizedBox(width: 4),
                    Text(phone, style: AppTextStyles.caption),
                  ],
                ),
                if (village.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.grey500),
                      const SizedBox(width: 4),
                      Text(village, style: AppTextStyles.caption),
                    ],
                  ),
                ],
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(notes,
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceBanner() {
    final hasDue = _due > 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasDue ? AppColors.dangerBg : AppColors.successBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDue
              ? AppColors.danger.withValues(alpha: 0.3)
              : AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasDue
                ? Icons.account_balance_wallet_outlined
                : Icons.check_circle_outline_rounded,
            color: hasDue ? AppColors.danger : AppColors.success,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasDue ? 'Amount Due' : 'Fully Settled',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: hasDue ? AppColors.danger : AppColors.success,
                  ),
                ),
                Text(
                  hasDue
                      ? MoneyUtils.formatDouble(_due)
                      : 'No outstanding balance',
                  style: AppTextStyles.amountSmall.copyWith(
                    color: hasDue ? AppColors.danger : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Billed: ${MoneyUtils.formatDouble(_totalPurchased)}',
                  style: AppTextStyles.caption),
              Text('Paid: ${MoneyUtils.formatDouble(_totalPaid)}',
                  style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _ActionBtn(
              label: 'New Purchase',
              icon: Icons.shopping_cart_outlined,
              color: AppColors.primary,
              onTap: () async {
                await context.push(AppRoutes.newPurchase(widget.customerId));
                _load();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionBtn(
              label: 'Collect Payment',
              icon: Icons.payments_outlined,
              color: AppColors.info,
              onTap: () async {
                await context.push(AppRoutes.collectPayment(widget.customerId));
                _load();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            'Purchase History (${_purchases.length})',
            style: AppTextStyles.titleSmall,
          ),
        ),
        if (_purchases.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      color: AppColors.grey300, size: 48),
                  const SizedBox(height: 12),
                  Text('No purchases yet', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 4),
                  Text('Tap "New Purchase" to add the first one',
                      style: AppTextStyles.caption),
                ],
              ),
            ),
          )
        else
          ..._purchases.map((p) => _PurchaseTile(purchase: p)),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  const _PurchaseTile({required this.purchase});
  final Map<String, dynamic> purchase;

  @override
  Widget build(BuildContext context) {
    final purchasedAt = DateTime.tryParse(purchase['purchased_at'] as String? ?? '');
    final total = (purchase['total'] as num?)?.toDouble() ?? 0;
    final items = (purchase['purchase_items'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            context.push(AppRoutes.purchaseDetails(purchase['id'] as String)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      purchasedAt != null
                          ? DateUtils.formatDate(purchasedAt)
                          : 'Unknown date',
                      style: AppTextStyles.labelMedium,
                    ),
                  ),
                  Text(
                    MoneyUtils.formatDouble(total),
                    style: AppTextStyles.amountSmall,
                  ),
                ],
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...items.take(3).map((item) {
                  final name = item['medicine_name'] as String? ?? '';
                  final qty = item['qty'] as int? ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '• $name × $qty',
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
                if (items.length > 3)
                  Text('+ ${items.length - 3} more items',
                      style: AppTextStyles.caption),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
