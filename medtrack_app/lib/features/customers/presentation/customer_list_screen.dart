import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/stat_card.dart' show AvatarInitials;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/routes.dart';
import '../../../core/utils/validators.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _supabase = Supabase.instance.client;
  final _searchCtrl = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _customers = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;
      final res = await _supabase
          .from('customers')
          .select('id, name, phone, village, is_favorite, created_at')
          .eq('owner_id', uid)
          .isFilter('deleted_at', null)
          .order('is_favorite', ascending: false)
          .order('name', ascending: true);
      _customers = List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      _error = 'Failed to load customers.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _customers;
    return _customers.where((c) {
      final name = (c['name'] as String? ?? '').toLowerCase();
      final phone = (c['phone'] as String? ?? '').toLowerCase();
      final village = (c['village'] as String? ?? '').toLowerCase();
      return name.contains(_query) ||
          phone.contains(_query) ||
          village.contains(_query);
    }).toList();
  }

  Future<void> _toggleFavorite(Map<String, dynamic> customer) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    final newVal = !(customer['is_favorite'] as bool? ?? false);
    try {
      await _supabase
          .from('customers')
          .update({'is_favorite': newVal})
          .eq('id', customer['id'] as String)
          .eq('owner_id', uid);
      _loadCustomers();
    } catch (_) {}
  }

  Future<void> _deleteCustomer(Map<String, dynamic> customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Customer?'),
        content: Text(
          'Move "${customer['name']}" to Recycle Bin? '
          'They can be restored within 30 days.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.danger),
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
          .eq('id', customer['id'] as String)
          .eq('owner_id', uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${customer['name']} moved to Recycle Bin'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                await _supabase
                    .from('customers')
                    .update({'deleted_at': null})
                    .eq('id', customer['id'] as String)
                    .eq('owner_id', uid);
                _loadCustomers();
              },
            ),
          ),
        );
      }
      _loadCustomers();
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
    final filtered = _filtered;

    return AppScaffold(
      safeAreaBottom: false,
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_rounded,
                        color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Text('Customers', style: AppTextStyles.titleSmall),
                    const Spacer(),
                    Text(
                      '${_customers.length} total',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () async {
                        await context.push(AppRoutes.newCustomer);
                        _loadCustomers();
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        textStyle: AppTextStyles.buttonSmall,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone or village…',
                    prefixIcon:
                        const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
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
                              onPressed: _loadCustomers,
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? EmptyState(
                            icon: _query.isNotEmpty
                                ? Icons.search_off_rounded
                                : Icons.people_outline_rounded,
                            title: _query.isNotEmpty
                                ? 'No results for "$_query"'
                                : 'No customers yet',
                            subtitle: _query.isNotEmpty
                                ? 'Try a different search term'
                                : 'Add your first customer to get started',
                            actionLabel:
                                _query.isEmpty ? 'Add Customer' : null,
                            onAction: _query.isEmpty
                                ? () async {
                                    await context.push(AppRoutes.newCustomer);
                                    _loadCustomers();
                                  }
                                : null,
                          )
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: _loadCustomers,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 100),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) => _CustomerTile(
                                customer: filtered[i],
                                onFavorite: () =>
                                    _toggleFavorite(filtered[i]),
                                onDelete: () => _deleteCustomer(filtered[i]),
                                onTap: () async {
                                  await context.push(
                                    AppRoutes.customerProfile(
                                      filtered[i]['id'] as String,
                                    ),
                                  );
                                  _loadCustomers();
                                },
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.customer,
    required this.onFavorite,
    required this.onDelete,
    required this.onTap,
  });

  final Map<String, dynamic> customer;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = customer['name'] as String? ?? '';
    final phone = customer['phone'] as String? ?? '';
    final village = customer['village'] as String? ?? '';
    final isFavorite = customer['is_favorite'] as bool? ?? false;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            AvatarInitials(name: name, size: 46),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            style: AppTextStyles.labelLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (isFavorite)
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFB26A00), size: 16),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    PhoneValidator.format(phone) +
                        (village.isNotEmpty ? ' · $village' : ''),
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  color: AppColors.grey500, size: 20),
              onSelected: (val) {
                if (val == 'favorite') onFavorite();
                if (val == 'delete') onDelete();
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'favorite',
                  child: Row(
                    children: [
                      Icon(
                        isFavorite
                            ? Icons.star_outline_rounded
                            : Icons.star_rounded,
                        size: 18,
                        color: AppColors.warn,
                      ),
                      const SizedBox(width: 8),
                      Text(isFavorite
                          ? 'Remove Favourite'
                          : 'Mark Favourite'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 18, color: AppColors.danger),
                      SizedBox(width: 8),
                      Text('Delete',
                          style: TextStyle(color: AppColors.danger)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


