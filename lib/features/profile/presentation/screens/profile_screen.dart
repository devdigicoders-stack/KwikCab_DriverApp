import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../routes/app_routes.dart';
import 'package:provider/provider.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/api_constants.dart';
import 'help_support_screen.dart';
import 'notifications_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'change_password_screen.dart';
import '../../../earnings/presentation/screens/earnings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileViewModel()..fetchProfile(),
      child: const _ProfileScreenContent(),
    );
  }
}

class _ProfileScreenContent extends StatelessWidget {
  const _ProfileScreenContent();

  String _formatDate(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('MMM yyyy').format(date);
    } catch (_) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.black,
            body: Center(child: CircularProgressIndicator(color: AppColors.yellow)),
          );
        }

        if (vm.error != null) {
          return Scaffold(
            backgroundColor: AppColors.black,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(vm.error!, style: const TextStyle(color: AppColors.white), textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: vm.fetchProfile,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.yellow),
                      child: const Text('Retry', style: TextStyle(color: AppColors.black)),
                    )
                  ],
                ),
              ),
            ),
          );
        }

        final driver = vm.driverData;
        if (driver == null) return const SizedBox();

        final carDetails = driver['carDetails'] ?? {};
        final bankDetails = driver['bankDetails'] ?? {};

        return Scaffold(
          backgroundColor: AppColors.black,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: vm.fetchProfile,
              color: AppColors.yellow,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(context, driver, vm),
                    const SizedBox(height: 16),
                    _buildStatsRow(driver),
                    const SizedBox(height: 16),
                    _buildVehicleCard(carDetails),
                    const SizedBox(height: 8),

                    _buildSectionTitle('Personal Info'),
                    _buildMenuItem(Icons.email_outlined, 'Email', subtitle: driver['email'], onTap: () => _goToEditProfile(context, driver, vm)),
                    _buildMenuItem(Icons.location_on_outlined, 'Address', subtitle: '${driver['address']}, ${driver['city']}, ${driver['state']} - ${driver['pincode']}', onTap: () => _goToEditProfile(context, driver, vm)),
                    _buildMenuItem(Icons.credit_card_outlined, 'Aadhar Number', subtitle: driver['aadharNumber'], imageUrl: driver['documents']?['aadhar'], onTap: () => _handleItemTap(context, driver, vm, driver['documents']?['aadhar'])),
                    _buildMenuItem(Icons.credit_card_outlined, 'PAN Number', subtitle: driver['panNumber'], imageUrl: driver['documents']?['pan'], onTap: () => _handleItemTap(context, driver, vm, driver['documents']?['pan'])),
                    
                    const SizedBox(height: 8),
                    _buildSectionTitle('Preferences'),
                    _buildMenuItem(
                      Icons.map_outlined, 
                      'Home-Bound Rides', 
                      subtitle: 'Set a destination filter (Limit: 4/day)', 
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.destinationFilter);
                      }
                    ),

                    const SizedBox(height: 8),
                    _buildSectionTitle('Account'),
                    _buildMenuItem(Icons.account_balance_wallet_outlined, 'Wallet Balance', subtitle: '₹${driver['walletBalance']}', onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const EarningsScreen()));
                    }),
                    _buildMenuItem(Icons.account_balance_rounded, 'Bank Details', subtitle: '${bankDetails['bankName']} - ${bankDetails['accountNumber']}', onTap: () => _goToEditProfile(context, driver, vm)),
                    _buildMenuItem(Icons.lock_outline_rounded, 'Change Password', onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
                    }),
                    _buildMenuItem(Icons.history_rounded, 'Total Trips', subtitle: '${driver['totalTrips']} lifetime trips'),
                    const SizedBox(height: 8),

                    _buildSectionTitle('Agent Leads'),
                    _buildMenuItem(Icons.storefront_outlined, 'Leads Marketplace', subtitle: 'View new leads', onTap: () {
                      Navigator.pushNamed(context, AppRoutes.agentLeadMarketplace);
                    }),
                    _buildMenuItem(Icons.assignment_turned_in_outlined, 'My Accepted Leads', subtitle: 'View unlocked leads', onTap: () {
                      Navigator.pushNamed(context, AppRoutes.myAcceptedLeads);
                    }),
                    const SizedBox(height: 8),

                    _buildSectionTitle('Fixed Packages'),
                    _buildMenuItem(Icons.local_shipping_outlined, 'Packages Marketplace', subtitle: 'View new fixed packages', onTap: () {
                      Navigator.pushNamed(context, AppRoutes.fixedPackageMarketplace);
                    }),
                    _buildMenuItem(Icons.check_circle_outline, 'My Accepted Packages', subtitle: 'View your ongoing packages', onTap: () {
                      Navigator.pushNamed(context, AppRoutes.myAcceptedFixedPackages);
                    }),
                    const SizedBox(height: 8),
                    
                    _buildSectionTitle('Documents'),
                    _buildMenuItem(Icons.badge_outlined, 'Driving License', subtitle: '${driver['licenseNumber']} (Exp: ${_formatDate(driver['licenseExpiry'])})', subtitleColor: AppColors.grey500, imageUrl: driver['documents']?['license'], onTap: () => _handleItemTap(context, driver, vm, driver['documents']?['license'])),
                    _buildMenuItem(Icons.directions_car_outlined, 'Vehicle Insurance', subtitle: 'Exp: ${_formatDate(carDetails['insuranceExpiry'])}', subtitleColor: AppColors.grey500, imageUrl: carDetails['carDocuments']?['insurance'], onTap: () => _handleItemTap(context, driver, vm, carDetails['carDocuments']?['insurance'])),
                    _buildMenuItem(Icons.description_outlined, 'Vehicle RC', subtitle: 'Registration Certificate', subtitleColor: AppColors.grey500, imageUrl: carDetails['carDocuments']?['rc'], onTap: () => _handleItemTap(context, driver, vm, carDetails['carDocuments']?['rc'])),
                    _buildMenuItem(Icons.security_outlined, 'Vehicle Permit', subtitle: 'Exp: ${_formatDate(carDetails['permitExpiry'])}', subtitleColor: AppColors.grey500, imageUrl: carDetails['carDocuments']?['permit'], onTap: () => _handleItemTap(context, driver, vm, carDetails['carDocuments']?['permit'])),
                    _buildMenuItem(Icons.approval_outlined, 'PUC Certificate', subtitle: 'Exp: ${_formatDate(carDetails['pucExpiry'])}', subtitleColor: AppColors.grey500, imageUrl: carDetails['carDocuments']?['puc'], onTap: () => _handleItemTap(context, driver, vm, carDetails['carDocuments']?['puc'])),
                    const SizedBox(height: 8),
                    _buildSectionTitle('Support & Others'),
                    _buildMenuItem(Icons.notifications_outlined, 'Notifications', onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
                    }),
                    _buildMenuItem(Icons.help_outline_rounded, 'Help & Support', onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
                    }),
                    _buildMenuItem(Icons.privacy_tip_outlined, 'Privacy Policy', onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
                    }),
                    _buildMenuItem(Icons.description_outlined, 'Terms of Service', onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()));
                    }),
                    const SizedBox(height: 20),
                    _buildLogoutButton(context),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _goToEditProfile(BuildContext context, Map<String, dynamic> driver, ProfileViewModel vm) async {
    final didUpdate = await Navigator.pushNamed(context, AppRoutes.editProfile, arguments: {'driverData': driver});
    if (didUpdate == true) {
      vm.fetchProfile();
    }
  }

  void _handleItemTap(BuildContext context, Map<String, dynamic> driver, ProfileViewModel vm, String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                child: Image.network('${ApiConstants.baseUrl}/uploads/$imageUrl', fit: BoxFit.contain),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
        ),
      );
    } else {
      _goToEditProfile(context, driver, vm);
    }
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> driver, ProfileViewModel vm) {
    final String? imageFilename = driver['image'];
    final String? imageUrl = (imageFilename != null && imageFilename.isNotEmpty) 
        ? '${ApiConstants.baseUrl}/uploads/$imageFilename' 
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.grey900,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.yellow, width: 2),
                ),
                child: ClipOval(
                  child: imageUrl != null
                      ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Image.asset('assets/logo_icon.png', fit: BoxFit.contain))
                      : Image.asset('assets/logo_icon.png', fit: BoxFit.contain),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driver['name'] ?? 'Driver Name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.white)),
                const SizedBox(height: 4),
                Text('+91 ${driver['phone']}', style: const TextStyle(fontSize: 13, color: AppColors.grey500)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.yellow, size: 16),
                    const SizedBox(width: 4),
                    Text('${driver['rating']} Rating', style: const TextStyle(fontSize: 12, color: AppColors.grey400)),
                    const SizedBox(width: 10),
                    if (driver['isApproved'] == true) ...[
                      const Icon(Icons.verified_rounded, color: AppColors.success, size: 16),
                      const SizedBox(width: 4),
                      const Text('Verified', style: TextStyle(fontSize: 12, color: AppColors.success)),
                    ] else ...[
                      const Icon(Icons.pending_actions_rounded, color: AppColors.error, size: 16),
                      const SizedBox(width: 4),
                      const Text('Pending', style: TextStyle(fontSize: 12, color: AppColors.error)),
                    ]
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _goToEditProfile(context, driver, vm),
            icon: const Icon(Icons.edit, color: AppColors.yellow),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> driver) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatCard(value: '${driver['totalTrips']}', label: 'Total Trips'),
          const SizedBox(width: 10),
          _StatCard(value: '₹${driver['totalEarnings']}', label: 'Total Earned'),
          const SizedBox(width: 10),
          _StatCard(value: '${driver['rating']}★', label: 'Rating'),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> carDetails) {
    final brand = carDetails['carBrand'] ?? 'Unknown';
    final model = carDetails['carModel'] ?? 'Vehicle';
    final number = carDetails['carNumber'] ?? 'UN-REG';
    final color = carDetails['carColor'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey900,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.grey800),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.yellow.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.directions_car_rounded, color: AppColors.yellow, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$brand $model', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white)),
                  const SizedBox(height: 4),
                  Text('$number • $color', style: const TextStyle(fontSize: 13, color: AppColors.grey500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.grey600, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {String? subtitle, Color subtitleColor = AppColors.grey500, String? imageUrl, VoidCallback? onTap}) {
    final String? fullImageUrl = (imageUrl != null && imageUrl.isNotEmpty) 
        ? '${ApiConstants.baseUrl}/uploads/$imageUrl' 
        : null;

    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: AppColors.grey900, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.grey800)),
            child: Icon(icon, color: AppColors.white, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.white)),
          subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: subtitleColor)) : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (fullImageUrl != null)
                Container(
                  width: 40, height: 40,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.grey800),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.network(fullImageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: AppColors.grey600, size: 20)),
                  ),
                ),
              const Icon(Icons.chevron_right, color: AppColors.grey600),
            ],
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        ),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: AppColors.grey800)),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity, height: 50,
        child: OutlinedButton.icon(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('driver_isLoggedIn');
            await prefs.remove('driver_token');
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
            }
          },
          icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
          label: const Text('Logout', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 15)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.error),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppColors.grey900, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey800)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.yellow)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grey500)),
          ],
        ),
      ),
    );
  }
}
