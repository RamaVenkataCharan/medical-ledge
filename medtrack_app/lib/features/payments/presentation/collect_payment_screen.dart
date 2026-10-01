import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';

class CollectPaymentScreen extends StatefulWidget {
  const CollectPaymentScreen({super.key, required this.customerId});
  final String customerId;

  @override
  State<CollectPaymentScreen> createState() => _CollectPaymentScreenState();
}

class _CollectPaymentScreenState extends State<CollectPaymentScreen> {
  final _supabase = Supabase.instance.client;
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingData = true;
  String? _error;
  Map<String, dynamic>? _customer;
  double _dueAmount = 0;
  String _paymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;

      final custRes = await _supabase
          .from('customers')
          .select('id, name, phone, village')
          .eq('id', widget.customerId)
          .eq('owner_id', uid)
          .single();
      _customer = Map<String, dynamic>.from(custRes);

      // Due = total purchased - total paid
      final purchRes = await _supabase
          .from('purchases')
          .select('total')
          .eq('customer_id', widget.customerId)
          .eq('owner_id', uid)
          .isFilter('deleted_at', null);
      final totalPurchased = (purchRes as List)
          .fold<double>(0, (s, r) => s + ((r['total'] as num?)?.toDouble() ?? 0));

      final payRes = await _supabase
          .from('payments')
          .select('amount')
          .eq('customer_id', widget.customerId)
          .eq('owner_id', uid);
      final totalPaid = (payRes as List)
          .fold<double>(0, (s, r) => s + ((r['amount'] as num?)?.toDouble() ?? 0));

      _dueAmount = (totalPurchased - totalPaid).clamp(0, double.infinity);
      // Pre-fill amount with due
      _amountCtrl.text = _dueAmount > 0 ? _dueAmount.toStringAsFixed(0) : '';
    } catch (e) {
      _error = 'Failed to load customer data.';
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _save() async {
    final amountStr = _amountCtrl.text.trim();
    final error = Validators.positiveAmount(amountStr);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    final amount = double.parse(amountStr);
    setState(() { _isLoading = true; _error = null; });

    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) throw Exception('Not logged in');

      await _supabase.from('payments').insert({
        'owner_id': uid,
        'customer_id': widget.customerId,
        'amount': amount,
        'method': _paymentMethod,
        'paid_at': DateTime.now().toIso8601String(),
        'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment of ${MoneyUtils.formatDouble(amount)} recorded!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (_) {
      setState(() => _error = 'Failed to record payment. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Collect Payment'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.charcoal,
        elevation: 0,
      ),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer info
                  if (_customer != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_rounded,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_customer!['name'] as String? ?? '',
                                  style: AppTextStyles.labelLarge
                                      .copyWith(color: AppColors.primary)),
                              Text(
                                (_customer!['phone'] as String? ?? '') +
                                    ((_customer!['village'] as String?)
                                                ?.isNotEmpty ==
                                            true
                                        ? ' · ${_customer!['village']}'
                                        : ''),
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  if (_dueAmount > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_outlined,
                              color: AppColors.danger, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Outstanding due: ${MoneyUtils.formatDouble(_dueAmount)}',
                            style: AppTextStyles.labelMedium
                                .copyWith(color: AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  if (_error != null) ...[
                    Container(
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
                    const SizedBox(height: 16),
                  ],

                  Text('Amount Received *', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    style: AppTextStyles.amount,
                    decoration: const InputDecoration(
                      hintText: '0',
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.charcoal),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: 20),
                  Text('Payment Method', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final method in ['cash', 'upi', 'card', 'other'])
                        ChoiceChip(
                          label: Text(method.toUpperCase()),
                          selected: _paymentMethod == method,
                          selectedColor: AppColors.primaryTint,
                          labelStyle: TextStyle(
                            color: _paymentMethod == method
                                ? AppColors.primary
                                : AppColors.grey700,
                            fontWeight: _paymentMethod == method
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          onSelected: (_) =>
                              setState(() => _paymentMethod = method),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Text('Notes (optional)', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Any notes about this payment…',
                    ),
                  ),

                  const SizedBox(height: 32),

                  PrimaryButton(
                    label: 'Record Payment',
                    icon: Icons.check_rounded,
                    onPressed: _save,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
    );
  }
}
