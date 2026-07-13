import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../viewmodels/bookings_viewmodel.dart';
import 'history_detail_screen.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingsViewModel(),
      child: const _BookingsBody(),
    );
  }
}

class _BookingsBody extends StatefulWidget {
  const _BookingsBody();
  @override
  State<_BookingsBody> createState() => _BookingsBodyState();
}

class _BookingsBodyState extends State<_BookingsBody> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tab.indexIsChanging) {
      final vm = context.read<BookingsViewModel>();
      if (_tab.index == 0) {
        vm.fetchActiveRide();
      } else if (_tab.index == 1) {
        vm.fetchHistory();
      }
    }
  }

  @override
  void dispose() { 
    _tab.removeListener(_handleTabSelection);
    _tab.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingsViewModel>();
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Bookings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.white)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: vm.isOnline ? AppColors.success.withValues(alpha: 0.15) : AppColors.grey900,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: vm.isOnline ? AppColors.success : AppColors.grey700),
                    ),
                    child: Row(
                      children: [
                        Container(width: 7, height: 7, decoration: BoxDecoration(color: vm.isOnline ? AppColors.success : AppColors.grey600, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(vm.isOnline ? 'Online' : 'Offline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: vm.isOnline ? AppColors.success : AppColors.grey600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: AppColors.grey900, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.grey800)),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(10)),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.black,
                unselectedLabelColor: AppColors.grey500,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Incoming'),
                        if (vm.incomingRequests.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)),
                            child: Text('${vm.incomingRequests.length}', style: const TextStyle(fontSize: 10, color: AppColors.white, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'History'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _IncomingTab(vm: vm),
                  _HistoryTab(vm: vm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Incoming Requests Tab ──────────────────────────────────────────────────
class _IncomingTab extends StatelessWidget {
  final BookingsViewModel vm;
  const _IncomingTab({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.activeRide != null) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          const Text('Current Active Ride', style: TextStyle(color: AppColors.yellow, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          _HistoryCard(ride: vm.activeRide!),
        ],
      );
    }

    if (!vm.isOnline) {
      return const _EmptyState(
        icon: Icons.power_settings_new_rounded,
        title: 'You are Offline',
        subtitle: 'Go online from the Ride tab to receive bookings',
      );
    }
    if (vm.incomingRequests.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_rounded,
        title: 'Looking for rides...',
        subtitle: 'New booking requests will appear here',
        showLoader: true,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: vm.incomingRequests.length,
      itemBuilder: (_, i) => _IncomingCard(request: vm.incomingRequests[i], vm: vm),
    );
  }
}

class _IncomingCard extends StatelessWidget {
  final BookingRequest request;
  final BookingsViewModel vm;
  const _IncomingCard({required this.request, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.grey900,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.yellow.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          // Timer bar
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: LinearProgressIndicator(
              value: request.timer / 20,
              backgroundColor: AppColors.grey800,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.yellow),
              minHeight: 4,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Passenger + timer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.person_rounded, color: AppColors.black, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(request.passengerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.white)),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.yellow, size: 13),
                                const SizedBox(width: 3),
                                Text(request.passengerRating, style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(20)),
                      child: Text('${request.timer}s', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.black)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Route
                _RouteRow(pickup: request.pickup, drop: request.drop),
                const SizedBox(height: 14),
                // Chips
                Row(
                  children: [
                    _Chip(icon: Icons.straighten_rounded, label: request.distance),
                    const SizedBox(width: 8),
                    _Chip(icon: Icons.access_time_rounded, label: request.duration),
                    const SizedBox(width: 8),
                    _Chip(icon: Icons.my_location_rounded, label: '${request.pickupDistance} km'),
                  ],
                ),
                const SizedBox(height: 14),
                // Fare
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.yellow.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.currency_rupee, color: AppColors.yellow, size: 18),
                      Text(request.fare, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.yellow)),
                      const SizedBox(width: 8),
                      Text('• ${request.paymentMode}', style: const TextStyle(fontSize: 13, color: AppColors.grey500)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => vm.rejectRequest(request.id),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.grey700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Reject', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => vm.acceptRequest(request.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.yellow,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Accept', style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── History Tab ─────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  final BookingsViewModel vm;
  const _HistoryTab({required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.history.isEmpty) {
      return _EmptyState(icon: Icons.history_rounded, title: 'No rides yet', subtitle: 'Your completed rides will appear here');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: vm.history.length,
      itemBuilder: (_, i) => _HistoryCard(ride: vm.history[i]),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final BookingHistory ride;
  const _HistoryCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    final statusColor = ride.status == 'Completed' 
        ? AppColors.success 
        : (ride.status == 'Cancelled' ? AppColors.error : AppColors.yellow);
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryDetailScreen(ride: ride)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.grey900, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.grey800)),
        child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: AppColors.yellow.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.person_rounded, color: AppColors.yellow, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ride.passengerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.white)),
                      Text(ride.date, style: const TextStyle(fontSize: 11, color: AppColors.grey600)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(ride.fare, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.white)),
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text(ride.status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _RouteRow(pickup: ride.pickup, drop: ride.drop),
          const SizedBox(height: 10),
          Row(
            children: [
              _Chip(icon: Icons.straighten_rounded, label: ride.distance),
              const SizedBox(width: 8),
              _Chip(icon: Icons.access_time_rounded, label: ride.duration),
              const SizedBox(width: 8),
              _Chip(icon: Icons.payment_rounded, label: ride.paymentMode),
            ],
          ),
        ],
      ),
    ));
  }
}

// ─── Shared Widgets ──────────────────────────────────────────────────────────
class _RouteRow extends StatelessWidget {
  final String pickup;
  final String drop;
  const _RouteRow({required this.pickup, required this.drop});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.success, width: 2.5))),
            Container(width: 2, height: 22, color: AppColors.grey700),
            Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.yellow, width: 2.5))),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pickup, style: const TextStyle(fontSize: 12, color: AppColors.white, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 14),
              Text(drop, style: const TextStyle(fontSize: 12, color: AppColors.white, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.grey800)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.yellow),
            const SizedBox(width: 4),
            Flexible(child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.white), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showLoader;
  const _EmptyState({required this.icon, required this.title, required this.subtitle, this.showLoader = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppColors.grey700),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.white)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.grey500), textAlign: TextAlign.center),
          if (showLoader) ...[
            const SizedBox(height: 24),
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.yellow)),
          ],
        ],
      ),
    );
  }
}
