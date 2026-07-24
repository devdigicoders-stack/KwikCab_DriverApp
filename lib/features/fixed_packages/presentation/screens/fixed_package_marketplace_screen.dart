import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../viewmodels/fixed_package_viewmodel.dart';

class FixedPackageMarketplaceScreen extends StatelessWidget {
  const FixedPackageMarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FixedPackageViewModel()..fetchMarketplacePackages(),
      child: const _MarketplaceContent(),
    );
  }
}

class _MarketplaceContent extends StatelessWidget {
  const _MarketplaceContent();

  String _formatDateTime(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (_) {
      return 'N/A';
    }
  }

  void _handleAcceptPackage(BuildContext context, FixedPackageViewModel vm, String packageId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.yellow)),
    );

    final res = await vm.acceptPackage(packageId);
    if (context.mounted) Navigator.pop(context); // close loader

    if (res['success'] == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Package Accepted Successfully!', style: TextStyle(color: AppColors.black)), backgroundColor: AppColors.success),
        );
        vm.fetchMarketplacePackages(); // refresh list
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to accept package'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('Fixed Packages Marketplace', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.white)),
        backgroundColor: AppColors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Consumer<FixedPackageViewModel>(
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
                      onPressed: vm.fetchMarketplacePackages,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.yellow),
                      child: const Text('Retry', style: TextStyle(color: AppColors.black)),
                    )
                  ],
                ),
              ),
            );
          }

          if (vm.marketplacePackages.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined, color: AppColors.grey600, size: 64),
                  SizedBox(height: 16),
                  Text('No Packages Available', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('Check back later for new packages.', style: TextStyle(color: AppColors.grey500)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: vm.fetchMarketplacePackages,
            color: AppColors.yellow,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.marketplacePackages.length,
              itemBuilder: (context, index) {
                final pkg = vm.marketplacePackages[index];
                final pickup = pkg['pickupLocation'] ?? pkg['pickup']?['address'] ?? 'Unknown';
                final drop = pkg['dropLocation'] ?? pkg['drop']?['address'] ?? 'Unknown';
                final date = _formatDateTime(pkg['scheduledAt'] ?? pkg['createdAt']);
                final price = pkg['totalFare'] ?? pkg['price'] ?? 0;
                final pkgName = pkg['route']?['name'] ?? pkg['packageName'] ?? 'Fixed Package';
                final paymentMethod = (pkg['paymentMethod'] ?? pkg['paymentType'] ?? 'CASH').toString().toUpperCase();

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
                                decoration: BoxDecoration(color: AppColors.yellow.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text(pkgName, style: const TextStyle(color: AppColors.yellow, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              Text(date, style: const TextStyle(color: AppColors.grey400, fontSize: 13, fontWeight: FontWeight.w600)),
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
                                  Row(
                                    children: [
                                      const Text('Total Fare', style: TextStyle(color: AppColors.grey500, fontSize: 13)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: paymentMethod == 'CASH' ? AppColors.success.withValues(alpha: 0.1) : AppColors.yellow.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                        child: Text(paymentMethod, style: TextStyle(color: paymentMethod == 'CASH' ? AppColors.success : AppColors.yellow, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  Text('₹$price', style: const TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () => _handleAcceptPackage(context, vm, pkg['_id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.yellow,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Accept Package', style: TextStyle(color: AppColors.black, fontSize: 15, fontWeight: FontWeight.w800)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
              },
            ),
          );
        },
      ),
    );
  }
}
