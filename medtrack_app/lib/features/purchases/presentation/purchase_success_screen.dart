import 'package:flutter/material.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class PurchaseSuccessScreen extends StatelessWidget {
  const PurchaseSuccessScreen({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 80),
        const SizedBox(height: 16),
        Text('Purchase Saved!', style: AppTextStyles.titleMedium),
        Text('Coming in next milestone', style: AppTextStyles.caption),
      ])),
    );
  }
}

