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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text('Notifications', style: TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SafeArea(
        child: vm.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.yellow))
            : vm.notifications.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, color: AppColors.grey600, size: 64),
                        SizedBox(height: 16),
                        Text('No notifications found', style: TextStyle(color: AppColors.grey500, fontSize: 16)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    color: AppColors.yellow,
                    onRefresh: vm.fetchNotifications,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: vm.notifications.length,
                      itemBuilder: (context, index) {
                        final n = vm.notifications[index];
                        final dateObj = DateTime.tryParse(n.createdAt);
                        final dateStr = dateObj != null ? DateFormat('dd MMM, hh:mm a').format(dateObj) : n.createdAt;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                                    Text(n.title, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 6),
                                    Text(n.message, style: const TextStyle(color: AppColors.grey400, fontSize: 14)),
                                    const SizedBox(height: 8),
                                    Text(dateStr, style: const TextStyle(color: AppColors.grey600, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
