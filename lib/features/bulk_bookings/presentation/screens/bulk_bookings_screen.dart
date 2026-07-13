import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../ride/presentation/screens/payment_webview_screen.dart';
import '../viewmodels/bulk_bookings_viewmodel.dart';
import 'bulk_booking_details_screen.dart';

class BulkBookingsScreen extends StatelessWidget {
  const BulkBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BulkBookingsViewModel(),
      child: const _BulkBookingsBody(),
    );
  }
}

class _BulkBookingsBody extends StatefulWidget {
  const _BulkBookingsBody();

  @override
  State<_BulkBookingsBody> createState() => _BulkBookingsBodyState();
}

class _BulkBookingsBodyState extends State<_BulkBookingsBody> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      // Fetch assignments whenever the user switches tabs
      context.read<BulkBookingsViewModel>().fetchAssignments();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BulkBookingsViewModel>().fetchAssignments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showStartDialog(BuildContext context, BulkBookingsViewModel vm, String bookingId) async {
    final otpController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.grey900,
            title: const Text('Start Bulk Trip', style: TextStyle(color: AppColors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please ask the customer for the Start OTP.', style: TextStyle(color: AppColors.grey400)),
                const SizedBox(height: 16),
                TextField(
                  controller: otpController,
                  style: const TextStyle(color: AppColors.white, fontSize: 24, letterSpacing: 8),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.black,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.grey500)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.yellow, foregroundColor: AppColors.black),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final otp = otpController.text.trim();
                        if (otp.length != 4) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter 4 digit OTP')));
                          return;
                        }
                        setState(() => isSubmitting = true);
                        try {
                          await vm.startTrip(bookingId, otp);
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip Started successfully!')));
                          }
                        } catch (e) {
                          setState(() => isSubmitting = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black))
                    : const Text('Start Trip', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showEndDialog(BuildContext context, BulkBookingsViewModel vm, String bookingId) async {
    String selectedMode = 'Cash';
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.grey900,
            title: const Text('End Bulk Trip', style: TextStyle(color: AppColors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How is the customer paying the remaining balance? (Required if you are the last driver to drop)', style: TextStyle(color: AppColors.grey400)),
                const SizedBox(height: 16),
                RadioListTile<String>(
                  title: const Text('Cash', style: TextStyle(color: AppColors.white)),
                  value: 'Cash',
                  groupValue: selectedMode,
                  activeColor: AppColors.yellow,
                  onChanged: (val) => setState(() => selectedMode = val!),
                ),
                RadioListTile<String>(
                  title: const Text('Online', style: TextStyle(color: AppColors.white)),
                  value: 'Online',
                  groupValue: selectedMode,
                  activeColor: AppColors.yellow,
                  onChanged: (val) => setState(() => selectedMode = val!),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.grey500)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.yellow, foregroundColor: AppColors.black),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setState(() => isSubmitting = true);
                        try {
                          final data = await vm.endTrip(bookingId, selectedMode);
                          if (mounted) {
                            Navigator.pop(ctx);
                            if (data['isOnlinePayment'] == true) {
                              final String? paymentUrl = data['paymentLinks']?['web'] ?? data['paymentLinks']?['mobile'];
                              if (paymentUrl != null) {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaymentWebviewScreen(
                                      paymentUrl: paymentUrl,
                                      bookingId: bookingId,
                                    ),
                                  ),
                                );
                                // Refresh after returning from webview
                                vm.fetchAssignments();
                                if (result == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Successful & Trip Completed!')));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment pending or cancelled.')));
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment link not found.')));
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip Ended successfully!')));
                            }
                          }
                        } catch (e) {
                          setState(() => isSubmitting = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black))
                    : const Text('End Trip', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BulkBookingsViewModel>();

    final activeAssignments = vm.assignments.where((a) => a.myStatus == 'Pending' || a.myStatus == 'Ongoing').toList();
    final historyAssignments = vm.assignments.where((a) => a.myStatus == 'Completed' || a.myStatus == 'Cancelled').toList();

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text('Bulk Bookings', style: TextStyle(color: AppColors.white)),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.yellow,
          labelColor: AppColors.yellow,
          unselectedLabelColor: AppColors.grey500,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: SafeArea(
        child: vm.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.yellow))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildList(activeAssignments, vm, 'No active assignments yet'),
                  _buildList(historyAssignments, vm, 'No past assignments found'),
                ],
              ),
      ),
    );
  }

  Widget _buildList(List<BulkAssignment> list, BulkBookingsViewModel vm, String emptyMsg) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, color: AppColors.grey600, size: 64),
            const SizedBox(height: 16),
            Text(emptyMsg, style: const TextStyle(color: AppColors.grey500, fontSize: 16)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.yellow,
      onRefresh: vm.fetchAssignments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final a = list[index];
          final dateObj = DateTime.tryParse(a.pickupDateTime)?.toLocal();
          final dateStr = dateObj != null ? DateFormat('dd MMM, hh:mm a').format(dateObj) : a.pickupDateTime;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BulkBookingDetailsScreen(assignment: a)),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.grey900,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.grey800),
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.grey800)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(dateStr, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                          if (a.isOutstation) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.purple.withValues(alpha: 0.5)),
                              ),
                              child: const Text('OUTSTATION', style: TextStyle(color: Colors.purpleAccent, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                            ),
                          ],
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(a.myStatus).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getStatusColor(a.myStatus)),
                        ),
                        child: Text(a.myStatus, style: TextStyle(color: _getStatusColor(a.myStatus), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.my_location_rounded, color: AppColors.yellow, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(a.pickupAddress, style: const TextStyle(color: AppColors.grey400, fontSize: 14))),
                          const SizedBox(width: 8),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.directions, color: AppColors.yellow),
                            onPressed: () async {
                              final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(a.pickupAddress)}');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 9, top: 4, bottom: 4),
                        height: 20,
                        width: 2,
                        color: AppColors.grey800,
                      ),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text(a.dropAddress, style: const TextStyle(color: AppColors.grey400, fontSize: 14))),
                          const SizedBox(width: 8),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.directions, color: Colors.redAccent),
                            onPressed: () async {
                              final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(a.dropAddress)}');
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_car_rounded, color: AppColors.grey500, size: 20),
                            const SizedBox(width: 12),
                            Text(a.myCar?['carNumber'] ?? 'Car not specified', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Price Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.yellow.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.yellow.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Price:', style: TextStyle(color: AppColors.grey400, fontSize: 14)),
                            Text('₹${a.offeredPrice}', style: const TextStyle(color: AppColors.yellow, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Action Button
                      if (a.myStatus != 'Completed' && a.myStatus != 'Cancelled')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: a.myStatus == 'Pending'
                                ? () => _showStartDialog(context, vm, a.id)
                                : a.myStatus == 'Ongoing'
                                    ? () => _showEndDialog(context, vm, a.id)
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: a.myStatus == 'Pending' ? AppColors.yellow : (a.myStatus == 'Ongoing' ? Colors.redAccent : AppColors.grey800),
                              foregroundColor: a.myStatus == 'Pending' ? AppColors.black : AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              a.myStatus == 'Pending' ? 'Start Trip' : (a.myStatus == 'Ongoing' ? 'End Trip' : 'Completed'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppColors.yellow;
      case 'Ongoing':
        return Colors.blueAccent;
      case 'Completed':
        return Colors.green;
      default:
        return AppColors.grey500;
    }
  }
}
