import 'package:flutter/material.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Text('Reminders'),
        backgroundColor: AppColors.surface,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
              child: const Icon(Icons.alarm_rounded, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text('Reminders', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Text('Coming in next milestone', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

