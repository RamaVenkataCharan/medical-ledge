import 'package:flutter/material.dart' hide DateUtils;
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/dates.dart';


class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _deleted = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;
      final res = await _supabase
          .from('customers')
          .select('id, name, phone, village, deleted_at')
          .eq('owner_id', uid)
          .not('deleted_at', 'is', null)
          .order('deleted_at', ascending: false);
      _deleted = List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      _error = 'Failed to load recycle bin.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restore(Map<String, dynamic> customer) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _supabase
          .from('customers')
          .update({'deleted_at': null})
          .eq('id', customer['id'] as String)
          .eq('owner_id', uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${customer['name']} restored!')),
        );
      }
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to restore customer.')),
        );
      }
    }
  }

  Future<void> _permanentDelete(Map<String, dynamic> customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Permanently Delete?'),
        content: Text(
          '"${customer['name']}" and all their purchase history will be '
          'permanently deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete Forever'),
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
          .delete()
          .eq('id', customer['id'] as String)
          .eq('owner_id', uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer permanently deleted.')),
        );
      }
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete permanently.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.charcoal,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.warnBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.warn.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.warn, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Customers here are automatically purged after 30 days. '
                    'Restore them or delete permanently.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.warn),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
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
                    : _deleted.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryTint,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.primary,
                                      size: 36),
                                ),
                                const SizedBox(height: 16),
                                Text('Recycle Bin is Empty',
                                    style: AppTextStyles.titleSmall),
                                const SizedBox(height: 6),
                                Text('Deleted customers will appear here',
                                    style: AppTextStyles.caption),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _load,
                            child: ListView.builder(
                              itemCount: _deleted.length,
                              itemBuilder: (ctx, i) {
                                final c = _deleted[i];
                                final deletedAt = DateTime.tryParse(
                                    c['deleted_at'] as String? ?? '');
                                final daysLeft = deletedAt != null
                                    ? DateUtils.recycleBinDaysLeft(deletedAt)
                                    : 0;
                                return _DeletedTile(
                                  customer: c,
                                  daysLeft: daysLeft,
                                  onRestore: () => _restore(c),
                                  onDelete: () => _permanentDelete(c),
                                  onTap: () async {
                                    await context.push(
                                        '/settings/recycle-bin/${c['id']}');
                                    _load();
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _DeletedTile extends StatelessWidget {
  const _DeletedTile({
    required this.customer,
    required this.daysLeft,
    required this.onRestore,
    required this.onDelete,
    required this.onTap,
  });

  final Map<String, dynamic> customer;
  final int daysLeft;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = customer['name'] as String? ?? '';
    final phone = customer['phone'] as String? ?? '';
    final village = customer['village'] as String? ?? '';
    final isExpiringSoon = daysLeft <= 7;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline_rounded,
                  color: AppColors.grey500, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.grey700)),
                  Text(
                    phone + (village.isNotEmpty ? ' · $village' : ''),
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$daysLeft days left',
                    style: AppTextStyles.caption.copyWith(
                      color: isExpiringSoon ? AppColors.danger : AppColors.warn,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onRestore,
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.success,
                  visualDensity: VisualDensity.compact),
              child: const Text('Restore'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever_rounded,
                  color: AppColors.danger, size: 20),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
