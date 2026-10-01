import 'package:flutter/material.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key, this.customerId});
  final String? customerId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('New Purchase'),
        backgroundColor: AppColors.surface,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
              child: const Icon(Icons.shopping_cart_rounded, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text('New Purchase', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            if (customerId != null)
              Text('Customer: $customerId', style: AppTextStyles.caption),
            Text('Coming in next milestone', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

