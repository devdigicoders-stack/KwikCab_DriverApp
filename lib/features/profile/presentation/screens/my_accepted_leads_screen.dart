import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_constants.dart';
import '../viewmodels/agent_lead_viewmodel.dart';

class MyAcceptedLeadsScreen extends StatelessWidget {
  const MyAcceptedLeadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AgentLeadViewModel()..fetchAcceptedLeads(),
      child: const _AcceptedContent(),
    );
  }
}

class _AcceptedContent extends StatelessWidget {
  const _AcceptedContent();

  String _formatDateTime(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (_) {
      return 'N/A';
    }
  }

  void _callCustomer(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _downloadReceipt(BuildContext context, String leadId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('driver_token') ?? '';
    final url = Uri.parse('${ApiConstants.baseUrl}/api/agent-leads/driver-receipt/$leadId?token=$token');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open browser to download receipt.'), backgroundColor: AppColors.error));
      }
    }
  }

  void _completeRide(BuildContext context, AgentLeadViewModel vm, String leadId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.grey900,
        title: const Text('Complete Ride?', style: TextStyle(color: AppColors.white)),
        content: const Text('Are you sure you have completed this ride and collected the cash?', style: TextStyle(color: AppColors.grey400)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: AppColors.grey500))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes, Completed', style: TextStyle(color: AppColors.yellow))),
        ],
      ),
    );

    if (confirm == true) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.yellow)),
        );
      }
      
      final res = await vm.completeLead(leadId);
      if (context.mounted) Navigator.pop(context); // close loader
      
      if (res['success'] == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ride completed successfully!'), backgroundColor: AppColors.success),
          );
        }
        vm.fetchAcceptedLeads();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Failed to complete ride'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Widget _buildLeadsList(BuildContext context, AgentLeadViewModel vm, List<dynamic> leads, String emptyTitle, String emptySubtitle) {
    if (leads.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_turned_in_outlined, color: AppColors.grey600, size: 64),
            const SizedBox(height: 16),
            Text(emptyTitle, style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(emptySubtitle, style: const TextStyle(color: AppColors.grey500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.fetchAcceptedLeads,
      color: AppColors.yellow,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leads.length,
        itemBuilder: (context, index) {
          final lead = leads[index];
          final pickup = lead['pickup']?['address'] ?? 'Unknown';
          final drop = lead['drop']?['address'] ?? 'Unknown';
          final date = _formatDateTime(lead['pickupDateTime']);
          final price = lead['totalPrice'] ?? 0;
          final customerName = lead['customerName'] ?? 'Unknown';
          final customerPhone = lead['customerPhone'] ?? '';
          final isCompleted = lead['status'] == 'Completed';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.grey900,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.grey800),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: isCompleted ? AppColors.success.withValues(alpha: 0.1) : AppColors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(isCompleted ? 'COMPLETED' : 'ONGOING', style: TextStyle(color: isCompleted ? AppColors.success : AppColors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      Text(date, style: const TextStyle(color: AppColors.grey400, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                
                // Unlocked Customer Details Section
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.black.withValues(alpha: 0.2),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: AppColors.yellow.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.person, color: AppColors.yellow),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(customerName, style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(customerPhone, style: const TextStyle(color: AppColors.grey400, fontSize: 14)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _callCustomer(customerPhone),
                        icon: const Icon(Icons.call, color: AppColors.success),
                        style: IconButton.styleFrom(backgroundColor: AppColors.success.withValues(alpha: 0.1)),
                      )
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.grey800),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.circle, color: AppColors.success, size: 12),
                          const SizedBox(width: 12),
                          Expanded(child: Text(pickup, style: const TextStyle(color: AppColors.white, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(width: 2, height: 20, color: AppColors.grey700),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppColors.error, size: 14),
                          const SizedBox(width: 10),
                          Expanded(child: Text(drop, style: const TextStyle(color: AppColors.white, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isCompleted)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Collect Cash', style: TextStyle(color: AppColors.grey500, fontSize: 13)),
                            Text('₹$price', style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => _completeRide(context, vm, lead['_id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Complete Ride', style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => _downloadReceipt(context, lead['_id']),
                        icon: const Icon(Icons.download, color: AppColors.yellow),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.yellow),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        label: const Text('Download Receipt', style: TextStyle(color: AppColors.yellow, fontSize: 15, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.black,
        appBar: AppBar(
          title: const Text('My Accepted Leads', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.white)),
          backgroundColor: AppColors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.white),
          bottom: const TabBar(
            indicatorColor: AppColors.yellow,
            labelColor: AppColors.yellow,
            unselectedLabelColor: AppColors.grey500,
            tabs: [
              Tab(text: 'Current'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: Consumer<AgentLeadViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.yellow));
            }

            if (vm.error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                      const SizedBox(height: 16),
                      Text(vm.error!, style: const TextStyle(color: AppColors.white), textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: vm.fetchAcceptedLeads,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.yellow),
                        child: const Text('Retry', style: TextStyle(color: AppColors.black)),
                      )
                    ],
                  ),
                ),
              );
            }

            final currentLeads = vm.acceptedLeads.where((lead) => lead['status'] != 'Completed' && lead['status'] != 'Cancelled').toList();
            final historyLeads = vm.acceptedLeads.where((lead) => lead['status'] == 'Completed' || lead['status'] == 'Cancelled').toList();

            return TabBarView(
              children: [
                _buildLeadsList(context, vm, currentLeads, 'No Current Leads', 'Unlock leads from the marketplace.'),
                _buildLeadsList(context, vm, historyLeads, 'No History', 'You do not have any completed leads.'),
              ],
            );
          },
        ),
      ),
    );
  }
}
