import 'package:flutter/material.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key, required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Customer Profile'),
        backgroundColor: AppColors.surface,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Customer Profile', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Text('ID: $customerId', style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text('Coming in next milestone', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

