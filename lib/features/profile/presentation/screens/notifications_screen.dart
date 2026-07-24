import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../viewmodels/notifications_viewmodel.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationsViewModel(),
      child: const _NotificationsBody(),
    );
  }
}

class _NotificationsBody extends StatefulWidget {
  const _NotificationsBody();

  @override
  State<_NotificationsBody> createState() => _NotificationsBodyState();
}

class _NotificationsBodyState extends State<_NotificationsBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsViewModel>().fetchNotifications();
    });
  }

  void _showNotificationDetails(BuildContext context, NotificationItem n) {
    final dateObj = DateTime.tryParse(n.createdAt);
    final dateStr = dateObj != null ? DateFormat('dd MMM yyyy, hh:mm a').format(dateObj) : n.createdAt;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.black,
          appBar: AppBar(
            backgroundColor: AppColors.black,
            title: const Text('Notification Detail', style: TextStyle(color: AppColors.white)),
            iconTheme: const IconThemeData(color: AppColors.white),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(color: AppColors.yellow.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(18)),
                      child: const Icon(Icons.notifications_active_rounded, color: AppColors.yellow, size: 32),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.white)),
                          const SizedBox(height: 6),
                          Text(dateStr, style: const TextStyle(fontSize: 14, color: AppColors.grey500)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Divider(color: AppColors.grey800),
                const SizedBox(height: 24),
                Text(n.message, style: const TextStyle(fontSize: 16, color: AppColors.grey400, height: 1.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<NotificationItem> list, NotificationsViewModel vm) {
    if (list.isEmpty) {
      return RefreshIndicator(
        color: AppColors.yellow,
        onRefresh: vm.fetchNotifications,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Icon(Icons.notifications_off_outlined, color: AppColors.grey600, size: 64),
            SizedBox(height: 16),
            Center(child: Text('No notifications found', style: TextStyle(color: AppColors.grey500, fontSize: 16))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.yellow,
      onRefresh: vm.fetchNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final n = list[index];
          final dateObj = DateTime.tryParse(n.createdAt);
          final dateStr = dateObj != null ? DateFormat('dd MMM, hh:mm a').format(dateObj) : n.createdAt;

          return GestureDetector(
            onTap: () => _showNotificationDetails(context, n),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey900,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.grey800),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: AppColors.yellow, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Text(n.message, style: const TextStyle(color: AppColors.grey400, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Text(dateStr, style: const TextStyle(color: AppColors.grey600, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationsViewModel>();

    final msgNotifs = vm.notifications.where((n) {
      final creator = n.createdByModel.toLowerCase();
      return creator == 'admin' || creator == 'subadmin';
    }).toList();

    final rideNotifs = vm.notifications.where((n) {
      final creator = n.createdByModel.toLowerCase();
      return creator != 'admin' && creator != 'subadmin';
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          backgroundColor: AppColors.black,
          title: const Text('Notifications', style: TextStyle(color: AppColors.white)),
          iconTheme: const IconThemeData(color: AppColors.white),
          bottom: const TabBar(
            indicatorColor: AppColors.yellow,
            labelColor: AppColors.yellow,
            unselectedLabelColor: AppColors.grey500,
            tabs: [
              Tab(text: 'Messages'),
              Tab(text: 'Rides'),
            ],
          ),
        ),
        body: SafeArea(
          child: vm.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.yellow))
              : TabBarView(
                  children: [
                    _buildList(msgNotifs, vm),
                    _buildList(rideNotifs, vm),
                  ],
                ),
        ),
      ),
    );
  }
}
