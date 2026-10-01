import 'package:flutter/material.dart' hide DateUtils;
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/router/routes.dart';
import '../../../core/utils/dates.dart';
import '../../../core/utils/money.dart';

/// Home Dashboard - stat cards, recent customers, quick actions
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String? _error;

  // Stats
  int _totalDuePaise = 0;
  int _todayCollectionPaise = 0;
  int _todaySalesPaise = 0;
  int _totalCustomers = 0;
  int _totalDueCustomers = 0;
  int _todayBillCount = 0;
  int _todayPaymentCount = 0;

  // Recent customers
  List<Map<String, dynamic>> _recentCustomers = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning!';
    if (hour < 17) return 'Good Afternoon!';
    return 'Good Evening!';
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;

      final now = DateTime.now();
      final todayStart = DateUtils.startOfDay(now).toIso8601String();
      final todayEnd = DateUtils.endOfDay(now).toIso8601String();

      // Total due across all customers
      final balanceRes = await _supabase
          .from('customer_balances')
          .select('due_rupees')
          .eq('owner_id', uid);

      _totalDuePaise = 0;
      _totalDueCustomers = 0;
      for (final row in balanceRes as List) {
        final due = (row['due_rupees'] as num?)?.toDouble() ?? 0;
        if (due > 0) {
          _totalDuePaise += MoneyUtils.rupeesToPaise(due);
          _totalDueCustomers++;
        }
      }

      // Today's collections
      final collectRes = await _supabase
          .from('payments')
          .select('amount')
          .eq('owner_id', uid)
          .gte('paid_at', todayStart)
          .lte('paid_at', todayEnd);

      _todayCollectionPaise = 0;
      _todayPaymentCount = 0;
      for (final row in collectRes as List) {
        _todayCollectionPaise +=
            MoneyUtils.rupeesToPaise((row['amount'] as num).toDouble());
        _todayPaymentCount++;
      }

      // Today's sales
      final salesRes = await _supabase
          .from('purchases')
          .select('total')
          .eq('owner_id', uid)
          .gte('purchased_at', todayStart)
          .lte('purchased_at', todayEnd)
          .isFilter('deleted_at', null);

      _todaySalesPaise = 0;
      _todayBillCount = 0;
      for (final row in salesRes as List) {
        _todaySalesPaise +=
            MoneyUtils.rupeesToPaise((row['total'] as num).toDouble());
        _todayBillCount++;
      }

      // Total customers
      final custRes = await _supabase
          .from('customers')
          .select('id')
          .eq('owner_id', uid)
          .isFilter('deleted_at', null);
      _totalCustomers = (custRes as List).length;

      // Recent customers (last 10)
      final recentRes = await _supabase
          .from('customers')
          .select('id, name, phone, village, created_at')
          .eq('owner_id', uid)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .limit(10);

      _recentCustomers = List<Map<String, dynamic>>.from(recentRes as List);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load dashboard data.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      safeAreaBottom: false,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // App bar header
            SliverToBoxAdapter(child: _buildHeader()),

            // Stat cards
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverToBoxAdapter(
                child: _isLoading ? _buildStatsSkeleton() : _buildStatsGrid(),
              ),
            ),

            // Quick actions
            SliverToBoxAdapter(child: _buildQuickActions()),

            // Recent customers
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recent Customers',
                        style: AppTextStyles.titleSmall,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.customers),
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
            ),

            if (_error != null)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ),
              )
            else if (_recentCustomers.isEmpty && !_isLoading)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'No customers yet',
                  subtitle: 'Add your first customer to get started',
                  actionLabel: 'Add Customer',
                  onAction: () => context.push(AppRoutes.newCustomer),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (_isLoading) {
                      return _buildCustomerSkeleton();
                    }
                    final customer = _recentCustomers[index];
                    return _RecentCustomerTile(customer: customer);
                  },
                  childCount: _isLoading ? 5 : _recentCustomers.length,
                ),
              ),

            // Backup banner
            SliverToBoxAdapter(
              child: _buildBackupBanner(),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          const Icon(Icons.local_pharmacy_rounded,
              color: AppColors.primary, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MedTrack', style: AppTextStyles.titleSmall),
                Text(
                  '$_greeting Sri Sai Medicals',
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Notification bell
          IconButton(
            onPressed: () => context.push(AppRoutes.notifications),
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.grey700,
          ),
          // Search
          IconButton(
            onPressed: () => context.go(AppRoutes.customers),
            icon: const Icon(Icons.search_rounded),
            color: AppColors.grey700,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        StatCard(
          title: 'Total Due',
          value: MoneyUtils.formatPaise(_totalDuePaise),
          subtitle: '$_totalDueCustomers customers',
          icon: Icons.account_balance_wallet_outlined,
          valueColor: _totalDuePaise > 0 ? AppColors.danger : AppColors.primary,
          backgroundColor:
              _totalDuePaise > 0 ? AppColors.dangerBg : AppColors.surface,
          iconColor: _totalDuePaise > 0 ? AppColors.danger : AppColors.primary,
          onTap: () => context.go(AppRoutes.reports),
        ),
        StatCard(
          title: "Today's Collection",
          value: MoneyUtils.formatPaise(_todayCollectionPaise),
          subtitle: '$_todayPaymentCount payments',
          icon: Icons.payments_outlined,
          iconColor: AppColors.success,
          onTap: () => context.go(AppRoutes.reports),
        ),
        StatCard(
          title: "Today's Sales",
          value: MoneyUtils.formatPaise(_todaySalesPaise),
          subtitle: '$_todayBillCount bills',
          icon: Icons.receipt_long_outlined,
          iconColor: AppColors.info,
          onTap: () => context.go(AppRoutes.reports),
        ),
        StatCard(
          title: 'Total Customers',
          value: _totalCustomers.toString(),
          subtitle: 'Active',
          icon: Icons.people_outline_rounded,
          onTap: () => context.go(AppRoutes.customers),
        ),
      ],
    );
  }

  Widget _buildStatsSkeleton() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: List.generate(
        4,
        (_) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              Container(height: 20, color: AppColors.grey100, width: 80),
              const SizedBox(height: 6),
              Container(height: 12, color: AppColors.grey100, width: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionBtn(
              label: 'Find Customer',
              icon: Icons.search_rounded,
              subtitle: 'Search & view history',
              color: AppColors.primary,
              onTap: () => context.go(AppRoutes.customers),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionBtn(
              label: 'Add Purchase',
              icon: Icons.add_shopping_cart_rounded,
              subtitle: 'Record medicines',
              color: const Color(0xFF1565C0),
              onTap: () => context.go(AppRoutes.customers),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.grey100,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, color: AppColors.grey100, width: 120),
                const SizedBox(height: 6),
                Container(height: 11, color: AppColors.grey100, width: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_done_outlined,
              color: AppColors.info, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your records are safe - Last backup: Today',
              style: AppTextStyles.caption.copyWith(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  const _QuickActionBtn({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentCustomerTile extends StatelessWidget {
  const _RecentCustomerTile({required this.customer});
  final Map<String, dynamic> customer;

  @override
  Widget build(BuildContext context) {
    final name = customer['name'] as String? ?? '';
    final phone = customer['phone'] as String? ?? '';
    final village = customer['village'] as String? ?? '';
    final createdAt = customer['created_at'] != null
        ? DateTime.tryParse(customer['created_at'] as String)
        : null;

    return InkWell(
      onTap: () =>
          context.push(AppRoutes.customerProfile(customer['id'] as String)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            AvatarInitials(name: name, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.labelLarge),
                  Text(
                    '$phone${village.isNotEmpty ? ' Â· $village' : ''}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            if (createdAt != null)
              Text(
                DateUtils.formatRelativeTime(createdAt),
                style: AppTextStyles.caption,
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.grey500, size: 18),
          ],
        ),
      ),
    );
  }
}
