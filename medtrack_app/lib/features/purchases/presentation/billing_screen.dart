import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/routes.dart';
import '../../../core/utils/money.dart';


class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key, this.customerId});
  final String? customerId;

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _supabase = Supabase.instance.client;
  final _discountCtrl = TextEditingController(text: '0');
  final _paidCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();

  bool _isLoading = false;

  String? _error;
  Map<String, dynamic>? _customer;
  String? _resolvedCustomerId;
  String _paymentMethod = 'cash';

  final List<_BillItem> _items = [];

  @override
  void initState() {
    super.initState();
    _resolvedCustomerId = widget.customerId;
    if (_resolvedCustomerId != null) {
      _loadCustomer(_resolvedCustomerId!);
    }
    _addItem();
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    _paidCtrl.dispose();
    _notesCtrl.dispose();
    for (final item in _items) { item.dispose(); }
    super.dispose();
  }

  Future<void> _loadCustomer(String id) async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;
      final res = await _supabase
          .from('customers')
          .select('id, name, phone, village')
          .eq('id', id)
          .eq('owner_id', uid)
          .single();
      if (mounted) setState(() => _customer = Map<String, dynamic>.from(res));
    } catch (_) {}
  }

  void _addItem() {
    setState(() => _items.add(_BillItem()));
  }

  void _removeItem(int index) {
    if (_items.length == 1) return; // keep at least one row
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  BillTotals get _totals {
    final lineItems = _items
        .where((i) => i.medicineName.trim().isNotEmpty && i.rateDouble > 0)
        .map((i) => LineItem(
              medicineName: i.medicineName,
              qty: i.qty,
              ratePaise: MoneyUtils.rupeesToPaise(i.rateDouble),
            ))
        .toList();
    final discount = double.tryParse(_discountCtrl.text) ?? 0;
    return BillingMath.computeTotals(lineItems, discount);
  }

  bool get _hasValidItems => _items.any(
      (i) => i.medicineName.trim().isNotEmpty && i.rateDouble > 0 && i.qty > 0);

  Future<void> _submit() async {
    if (!_hasValidItems) {
      setState(() => _error = 'Add at least one medicine item.');
      return;
    }
    final custId = _resolvedCustomerId;
    if (custId == null) {
      setState(() => _error = 'No customer selected.');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) throw Exception('Not logged in');

      final discount = double.tryParse(_discountCtrl.text) ?? 0;
      final paidAmount = double.tryParse(_paidCtrl.text) ?? 0;
      final totals = _totals;

      // Build items JSON for RPC
      final itemsJson = _items
          .where((i) => i.medicineName.trim().isNotEmpty && i.rateDouble > 0 && i.qty > 0)
          .map((i) => {
                'medicine_name': i.medicineName.trim(),
                'pack_label': i.packLabel.trim().isEmpty ? null : i.packLabel.trim(),
                'qty': i.qty,
                'rate_rupees': i.rateDouble,
                'amount_rupees': MoneyUtils.paisToRupees(i.qty * MoneyUtils.rupeesToPaise(i.rateDouble)),
              })
          .toList();

      final purchaseId = await _supabase.rpc('create_purchase', params: {
        'p_owner_id': uid,
        'p_customer_id': custId,
        'p_items': itemsJson,
        'p_discount_percent': discount,
        'p_paid_amount': paidAmount,
        'p_payment_method': paidAmount > 0 ? _paymentMethod : null,
        'p_notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        'p_purchased_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        context.pushReplacement(AppRoutes.purchaseSuccess, extra: {
          'purchase_id': purchaseId as String,
          'customer_name': _customer?['name'] as String? ?? '',
          'total_rupees': MoneyUtils.paisToRupees(totals.totalPaise),
          'paid_rupees': paidAmount,
          'due_rupees': MoneyUtils.paisToRupees(totals.totalPaise) - paidAmount,
        });
      }
    } catch (e) {
      setState(() => _error = 'Failed to create purchase. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('New Purchase'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.charcoal,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer chip
                  if (_customer != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_rounded,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _customer!['name'] as String? ?? '',
                                  style: AppTextStyles.labelLarge
                                      .copyWith(color: AppColors.primary),
                                ),
                                Text(
                                  (_customer!['phone'] as String? ?? '') +
                                      ((_customer!['village'] as String?)?.isNotEmpty == true
                                          ? ' · ${_customer!['village']}'
                                          : ''),
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Error
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Text(_error!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.danger)),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Items section
                  Row(
                    children: [
                      Expanded(
                        child: Text('Medicine Items', style: AppTextStyles.titleSmall),
                      ),
                      TextButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Row'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Item headers
                  const _ItemHeader(),
                  const Divider(height: 8),

                  // Item rows
                  ..._items.asMap().entries.map((e) => _ItemRow(
                        key: ValueKey(e.key),
                        item: e.value,
                        index: e.key,
                        onRemove: () => _removeItem(e.key),
                        onChanged: () => setState(() {}),
                        canRemove: _items.length > 1,
                      )),

                  const Divider(height: 16),

                  // Totals
                  _buildTotalsSection(),

                  const SizedBox(height: 16),

                  // Payment method
                  _buildPaymentSection(),

                  const SizedBox(height: 16),

                  // Notes
                  Text('Notes (optional)', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Prescription notes, doctor name, etc.',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Submit bar
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.fromLTRB(
              16, 12, 16, 12 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: PrimaryButton(
              label: 'Save Purchase',
              icon: Icons.check_rounded,
              onPressed: _hasValidItems ? _submit : null,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    final totals = _totals;
    final discount = double.tryParse(_discountCtrl.text) ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: AppTextStyles.bodyMedium),
              Text(MoneyUtils.formatPaise(totals.subtotalPaise),
                  style: AppTextStyles.labelLarge),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: Text('Discount (%)', style: AppTextStyles.bodyMedium)),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _discountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelLarge,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: '0',
                    suffixText: '%',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          if (discount > 0 && totals.discountPaise > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Discount', style: AppTextStyles.caption),
                Text(
                  '- ${MoneyUtils.formatPaise(totals.discountPaise)}',
                  style:
                      AppTextStyles.caption.copyWith(color: AppColors.success),
                ),
              ],
            ),
          ],
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.labelLarge),
              Text(
                MoneyUtils.formatPaise(totals.totalPaise),
                style: AppTextStyles.amount.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment (optional)', style: AppTextStyles.titleSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount Paid', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _paidCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: const InputDecoration(
                        hintText: '0',
                        prefixText: '₹ ',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Method', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'upi', child: Text('UPI')),
                        DropdownMenuItem(value: 'card', child: Text('Card')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _paymentMethod = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Due summary
          Builder(builder: (ctx) {
            final total = _totals.totalPaise;
            final paid = MoneyUtils.rupeesToPaise(
                double.tryParse(_paidCtrl.text) ?? 0);
            final due = total - paid;
            if (total == 0) return const SizedBox.shrink();
            return Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: AppColors.grey500),
                const SizedBox(width: 6),
                Text(
                  due > 0
                      ? 'Remaining due: ${MoneyUtils.formatPaise(due)}'
                      : due == 0
                          ? 'Fully paid ✓'
                          : 'Overpaid by ${MoneyUtils.formatPaise(-due)}',
                  style: AppTextStyles.caption.copyWith(
                    color: due > 0
                        ? AppColors.warn
                        : due == 0
                            ? AppColors.success
                            : AppColors.danger,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _ItemHeader extends StatelessWidget {
  const _ItemHeader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text('Medicine', style: TextStyle(
              fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600,
              color: AppColors.grey500, letterSpacing: 0.3,
            )),
          ),
          SizedBox(width: 6),
          SizedBox(width: 40, child: Text('Qty', textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 11,
              fontWeight: FontWeight.w600, color: AppColors.grey500))),
          SizedBox(width: 6),
          SizedBox(width: 72, child: Text('Rate (₹)', textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 11,
              fontWeight: FontWeight.w600, color: AppColors.grey500))),
          SizedBox(width: 6),
          SizedBox(width: 72, child: Text('Amount', textAlign: TextAlign.right,
              style: TextStyle(fontFamily: 'Inter', fontSize: 11,
              fontWeight: FontWeight.w600, color: AppColors.grey500))),
          SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    super.key,
    required this.item,
    required this.index,
    required this.onRemove,
    required this.onChanged,
    required this.canRemove,
  });

  final _BillItem item;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    final amount = item.qty * item.rateDouble;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medicine name
          Expanded(
            flex: 4,
            child: TextField(
              controller: item.nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Medicine name',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 6),

          // Qty
          SizedBox(
            width: 40,
            child: TextField(
              controller: item.qtyCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: '1',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                isDense: true,
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 6),

          // Rate
          SizedBox(
            width: 72,
            child: TextField(
              controller: item.rateCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                hintText: '0',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                isDense: true,
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          const SizedBox(width: 6),

          // Amount (computed)
          SizedBox(
            width: 72,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                amount > 0 ? MoneyUtils.formatDouble(amount) : '-',
                textAlign: TextAlign.right,
                style: AppTextStyles.amountSmall,
              ),
            ),
          ),

          // Remove
          SizedBox(
            width: 28,
            child: IconButton(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.close_rounded,
                size: 16,
                color: canRemove ? AppColors.danger : AppColors.grey300,
              ),
              onPressed: canRemove ? onRemove : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// State holder for a single billing line item
class _BillItem {
  final nameCtrl = TextEditingController();
  final qtyCtrl = TextEditingController(text: '1');
  final rateCtrl = TextEditingController();
  final packCtrl = TextEditingController();

  String get medicineName => nameCtrl.text;
  String get packLabel => packCtrl.text;
  int get qty => int.tryParse(qtyCtrl.text) ?? 1;
  double get rateDouble => double.tryParse(rateCtrl.text) ?? 0;

  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    rateCtrl.dispose();
    packCtrl.dispose();
  }
}
