import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/routes.dart';
import '../../../core/utils/money.dart';

class PurchaseSuccessScreen extends StatelessWidget {
  const PurchaseSuccessScreen({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final customerName = data['customer_name'] as String? ?? 'Customer';
    final totalRupees = (data['total_rupees'] as num?)?.toDouble() ?? 0;
    final paidRupees = (data['paid_rupees'] as num?)?.toDouble() ?? 0;
    final dueRupees = (data['due_rupees'] as num?)?.toDouble() ?? 0;

    return AppScaffold(
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.successBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.success,
                size: 52,
              ),
            ),
            const SizedBox(height: 24),
            Text('Purchase Saved!', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            Text(
              'For $customerName',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey500),
            ),
            const SizedBox(height: 32),

            // Summary card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'Total Bill',
                    value: MoneyUtils.formatDouble(totalRupees),
                    valueStyle: AppTextStyles.amount,
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Amount Paid',
                    value: MoneyUtils.formatDouble(paidRupees),
                    valueStyle: AppTextStyles.amountSmall
                        .copyWith(color: AppColors.success),
                  ),
                  if (dueRupees > 0) ...[
                    const Divider(),
                    _SummaryRow(
                      label: 'Remaining Due',
                      value: MoneyUtils.formatDouble(dueRupees),
                      valueStyle: AppTextStyles.amountSmall
                          .copyWith(color: AppColors.danger),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 16),
                        const SizedBox(width: 6),
                        Text('Fully Settled',
                            style: AppTextStyles.labelMedium
                                .copyWith(color: AppColors.success)),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Actions
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.go(AppRoutes.home),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Back to Home'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: AppTextStyles.button,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.customers),
                icon: const Icon(Icons.people_rounded),
                label: const Text('Go to Customers'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: AppTextStyles.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text(value, style: valueStyle ?? AppTextStyles.labelLarge),
      ],
    );
  }
}
