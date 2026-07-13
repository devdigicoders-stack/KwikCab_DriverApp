import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_viewmodel.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../ride/presentation/screens/ride_screen.dart';
import '../../../ride/presentation/screens/bookings_screen.dart';
import '../../../earnings/presentation/screens/earnings_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../bulk_bookings/presentation/screens/bulk_bookings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<Widget> _pages = [
    RideScreen(),
    BookingsScreen(),
    BulkBookingsScreen(),
    EarningsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: Consumer<HomeViewModel>(
        builder: (context, vm, _) => Scaffold(
          backgroundColor: AppColors.black,
          body: IndexedStack(index: vm.selectedIndex, children: _pages),
          bottomNavigationBar: _BottomNav(selectedIndex: vm.selectedIndex, onTap: vm.setIndex),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;
  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.black,
        border: Border(top: BorderSide(color: AppColors.grey800)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(index: 0, icon: Icons.map_rounded, label: 'Ride', selectedIndex: selectedIndex, onTap: onTap),
              _NavItem(index: 1, icon: Icons.receipt_long_rounded, label: 'Bookings', selectedIndex: selectedIndex, onTap: onTap),
              _NavItem(index: 2, icon: Icons.group_work_rounded, label: 'Bulk', selectedIndex: selectedIndex, onTap: onTap),
              _NavItem(index: 3, icon: Icons.currency_rupee_rounded, label: 'Earnings', selectedIndex: selectedIndex, onTap: onTap),
              _NavItem(index: 4, icon: Icons.person_rounded, label: 'Profile', selectedIndex: selectedIndex, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final int selectedIndex;
  final void Function(int) onTap;

  const _NavItem({required this.index, required this.icon, required this.label, required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: isSelected ? AppColors.yellow : AppColors.grey600),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400, color: isSelected ? AppColors.yellow : AppColors.grey600)),
          ],
        ),
      ),
    );
  }
}
