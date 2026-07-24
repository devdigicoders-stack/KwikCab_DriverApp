import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/network/socket_service.dart';
import '../viewmodels/fixed_package_viewmodel.dart';

class MyAcceptedFixedPackagesScreen extends StatelessWidget {
  const MyAcceptedFixedPackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FixedPackageViewModel()..fetchAcceptedPackages(),
      child: const _AcceptedContent(),
    );
  }
}

class _AcceptedContent extends StatefulWidget {
  const _AcceptedContent();

  @override
  State<_AcceptedContent> createState() => _AcceptedContentState();
}

class _AcceptedContentState extends State<_AcceptedContent> {
  StreamSubscription? _paymentVerifiedSub;
  bool _isWaitingForOnlinePayment = false;
  bool _showCashModal = false;
  bool _showPaymentSuccessModal = false;
  Map<String, dynamic>? _completingPackage;

  @override
  void initState() {
    super.initState();
    // Listen for backend payment success socket event (correct event name from backend)
    _paymentVerifiedSub = SocketService.instance.onFixedPackagePaymentVerified.listen((data) {
      if (mounted) {
        setState(() {
          _isWaitingForOnlinePayment = false;
          _showPaymentSuccessModal = true;
        });
        context.read<FixedPackageViewModel>().fetchAcceptedPackages();
        // Auto-dismiss after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() => _showPaymentSuccessModal = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _paymentVerifiedSub?.cancel();
    super.dispose();
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (_) {
      return 'N/A';
    }
  }

  void _handleCompletePackage(BuildContext context, FixedPackageViewModel vm, Map<String, dynamic> pkg) async {
    final packageId = pkg['_id'] ?? '';

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.yellow)),
    );

    final res = await vm.completePackage(packageId);
    if (context.mounted) Navigator.pop(context); // close loader

    if (res['success'] == true) {
      // Backend marks it Completed immediately.
      // For CASH rides: show cash collection modal.
      // For ONLINE rides: just inform and refresh (backend handles payment separately).
      final paymentMethod = (pkg['paymentMethod'] ?? pkg['paymentType'] ?? 'CASH').toString().toUpperCase();
      if (paymentMethod == 'CASH') {
        setState(() {
          _completingPackage = pkg;
          _showCashModal = true;
        });
      } else {
        // Online payment — show waiting screen
        setState(() {
          _completingPackage = pkg;
          _isWaitingForOnlinePayment = true;
        });
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to complete package'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Block back button when waiting for online payment
      canPop: !_isWaitingForOnlinePayment,
      onPopInvoked: (didPop) {
        if (_isWaitingForOnlinePayment) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Please wait — online payment is being processed.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.black,
        appBar: AppBar(
          title: const Text('My Packages', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.white)),
          backgroundColor: AppColors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.white),
          bottom: const TabBar(
            indicatorColor: AppColors.yellow,
            labelColor: AppColors.yellow,
            unselectedLabelColor: AppColors.grey500,
            tabs: [
              Tab(text: 'Ongoing'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: Stack(
          children: [
            Consumer<FixedPackageViewModel>(
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
                            onPressed: vm.fetchAcceptedPackages,
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.yellow),
                            child: const Text('Retry', style: TextStyle(color: AppColors.black)),
                          )
                        ],
                      ),
                    ),
                  );
                }

                final ongoingStatuses = ['ACCEPTED', 'ONGOING', 'PAYMENT_PENDING', 'CASH_COLLECTED'];
                final historyStatuses = ['COMPLETED', 'CANCELLED'];

                final ongoingPackages = vm.acceptedPackages.where((pkg) {
                  final status = (pkg['status'] ?? 'ACCEPTED').toString().toUpperCase();
                  final paymentStatus = (pkg['paymentStatus'] ?? '').toString().toUpperCase();
                  final paymentMethod = (pkg['paymentMethod'] ?? pkg['paymentType'] ?? 'CASH').toString().toUpperCase();
                  
                  bool isOnlinePending = status == 'COMPLETED' && paymentStatus == 'PENDING' && paymentMethod != 'CASH';
                  
                  return ongoingStatuses.contains(status) || (!historyStatuses.contains(status)) || isOnlinePending;
                }).toList();

                final historyPackages = vm.acceptedPackages.where((pkg) {
                  final status = (pkg['status'] ?? '').toString().toUpperCase();
                  final paymentStatus = (pkg['paymentStatus'] ?? '').toString().toUpperCase();
                  final paymentMethod = (pkg['paymentMethod'] ?? pkg['paymentType'] ?? 'CASH').toString().toUpperCase();
                  
                  bool isOnlinePending = status == 'COMPLETED' && paymentStatus == 'PENDING' && paymentMethod != 'CASH';

                  return historyStatuses.contains(status) && !isOnlinePending;
                }).toList();

                return TabBarView(
                  children: [
                    _buildPackageList(context, vm, ongoingPackages, isOngoing: true),
                    _buildPackageList(context, vm, historyPackages, isOngoing: false),
                  ],
                );
              },
            ),

            // Waiting for Online Payment Overlay — FULLY NON-DISMISSIBLE
            if (_isWaitingForOnlinePayment)
              Positioned.fill(
                child: GestureDetector(
                  // Absorb ALL taps so user cannot accidentally dismiss
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('⚠️ Please wait — payment is being processed by the customer.'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  behavior: HitTestBehavior.opaque,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.7),
                      child: Center(
                        child: GestureDetector(
                          // Prevent inner taps from propagating to outer dismiss
                          onTap: () {},
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: AppColors.grey900,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.grey800),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 4,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.yellow),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text('Waiting for Payment', style: TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                const Text('Customer is completing their online payment.\nPlease do NOT close this screen.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.grey500, fontSize: 14, height: 1.5)),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.lock_outline, color: Colors.orange, size: 14),
                                      SizedBox(width: 6),
                                      Flexible(child: Text('Screen locked until payment is verified', textAlign: TextAlign.center, style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold))),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (_completingPackage != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(color: AppColors.yellow.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                    child: Text(
                                      '₹${_completingPackage!['totalFare'] ?? _completingPackage!['price'] ?? 0}',
                                      style: const TextStyle(color: AppColors.yellow, fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Cash Collection Modal
            if (_showCashModal)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.payments_rounded, size: 40, color: AppColors.success),
                            ),
                            const SizedBox(height: 24),
                            const Text('Collect Cash', style: TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (_completingPackage != null)
                              Text(
                                '₹${_completingPackage!['totalFare'] ?? _completingPackage!['price'] ?? 0}',
                                style: const TextStyle(color: AppColors.success, fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                            const SizedBox(height: 8),
                            const Text('Please collect the cash from the customer before marking the package complete.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.5)),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _showCashModal = false;
                                    _completingPackage = null;
                                  });
                                  context.read<FixedPackageViewModel>().fetchAcceptedPackages();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Package Completed! Cash Collected ✓', style: TextStyle(color: Colors.black)), backgroundColor: AppColors.success),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text('Cash Collected ✓', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Payment Success Modal (for online)
            if (_showPaymentSuccessModal)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_circle_rounded, size: 50, color: AppColors.success),
                            ),
                            const SizedBox(height: 24),
                            const Text('Payment Verified!', style: TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text('The online payment has been successfully verified by the system.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.5)),
                            const SizedBox(height: 8),
                            const Text('Package Completed ✓', style: TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => setState(() => _showPaymentSuccessModal = false),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Done', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildPackageList(BuildContext context, FixedPackageViewModel vm, List<dynamic> packages, {required bool isOngoing}) {
    if (packages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isOngoing ? Icons.local_shipping_outlined : Icons.history, color: AppColors.grey600, size: 64),
            const SizedBox(height: 16),
            Text(isOngoing ? 'No Ongoing Packages' : 'No History Found', style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(isOngoing ? 'Packages you accept will appear here.' : 'Completed packages will appear here.', style: const TextStyle(color: AppColors.grey500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.fetchAcceptedPackages,
      color: AppColors.yellow,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final pkg = packages[index];
          final pickup = pkg['pickupLocation'] ?? pkg['pickup']?['address'] ?? 'Unknown';
          final drop = pkg['dropLocation'] ?? pkg['drop']?['address'] ?? 'Unknown';
          final date = _formatDateTime(pkg['scheduledAt'] ?? pkg['createdAt']);
          final price = pkg['totalFare'] ?? pkg['price'] ?? 0;
          final pkgName = pkg['route']?['name'] ?? pkg['packageName'] ?? 'Fixed Package';
          
          String status = (pkg['status'] ?? 'ACCEPTED').toString().toUpperCase();
          final paymentStatus = (pkg['paymentStatus'] ?? '').toString().toUpperCase();
          final paymentMethod = (pkg['paymentMethod'] ?? pkg['paymentType'] ?? 'CASH').toString().toUpperCase();
          
          if (status == 'COMPLETED' && paymentStatus == 'PENDING' && paymentMethod != 'CASH') {
             status = 'PAYMENT PENDING';
          }

          return InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/fixed-package-details', arguments: pkg);
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
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.yellow.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(pkgName, style: const TextStyle(color: AppColors.yellow, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        Text(status, style: TextStyle(color: status == 'COMPLETED' ? AppColors.success : (status == 'CANCELLED' ? AppColors.error : AppColors.yellow), fontSize: 13, fontWeight: FontWeight.w600)),
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
                            Text(date, style: const TextStyle(color: AppColors.grey500, fontSize: 13)),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: paymentMethod == 'CASH' ? AppColors.success.withValues(alpha: 0.1) : AppColors.yellow.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                  child: Text(paymentMethod, style: TextStyle(color: paymentMethod == 'CASH' ? AppColors.success : AppColors.yellow, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Text('₹$price', style: const TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        if (isOngoing && status != 'COMPLETED' && status != 'CANCELLED' && status != 'PAYMENT PENDING') ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => _handleCompletePackage(context, vm, pkg),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.yellow,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Mark as Completed', style: TextStyle(color: AppColors.black, fontSize: 15, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ]
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
}
