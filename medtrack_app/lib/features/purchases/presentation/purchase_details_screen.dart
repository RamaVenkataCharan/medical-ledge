import 'package:flutter/material.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PurchaseDetailsScreen extends StatelessWidget {
  const PurchaseDetailsScreen({super.key, required this.purchaseId});
  final String purchaseId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Purchase Details'),
        backgroundColor: AppColors.surface,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Purchase Details', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Text('ID: $purchaseId', style: AppTextStyles.caption),
            const SizedBox(height: 4),
            Text('Coming in next milestone', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
