import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/ride_viewmodel.dart';
import '../../../../core/constants/app_colors.dart';
import 'payment_webview_screen.dart';

class RideScreen extends StatelessWidget {
  const RideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RideViewModel(),
      child: const _RideBody(),
    );
  }
}

class _RideBody extends StatelessWidget {
  const _RideBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RideViewModel>();

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          // Google Map Background
          Positioned.fill(
            child: vm.currentPosition == null
                ? const Center(child: CircularProgressIndicator(color: AppColors.yellow))
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(vm.currentPosition!.latitude, vm.currentPosition!.longitude),
                      zoom: 15,
                    ),
                    onMapCreated: vm.onMapCreated,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    polylines: vm.polylines,
                    markers: {
                      Marker(
                        markerId: const MarkerId('driver_marker'),
                        position: LatLng(vm.currentPosition!.latitude, vm.currentPosition!.longitude),
                        icon: vm.carIcon ?? BitmapDescriptor.defaultMarkerWithHue(
                          vm.isOnline ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
                        ),
                        rotation: vm.currentPosition!.heading,
                        flat: true,
                        anchor: const Offset(0.5, 0.5),
                        infoWindow: InfoWindow(
                          title: vm.isOnline ? 'You are Online' : 'You are Offline',
                        ),
                      ),
                      if (vm.activeRide != null)
                        Marker(
                          markerId: const MarkerId('pickup_marker'),
                          position: LatLng(vm.activeRide!.pickupLat, vm.activeRide!.pickupLng),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                          infoWindow: const InfoWindow(title: 'Pickup Location'),
                        ),
                      if (vm.activeRide != null)
                        Marker(
                          markerId: const MarkerId('drop_marker'),
                          position: LatLng(vm.activeRide!.dropLat, vm.activeRide!.dropLng),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          infoWindow: const InfoWindow(title: 'Drop Location'),
                        ),
                      if (vm.activeRide != null)
                        ...vm.activeRide!.stops.asMap().entries.map((e) => Marker(
                          markerId: MarkerId('stop_marker_${e.key}'),
                          position: LatLng(e.value.latitude, e.value.longitude),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                          infoWindow: InfoWindow(title: 'Stop ${e.key + 1}'),
                        )),
                    },
                  ),
          ),
          
          // An optional overlay if Offline to dim the map
          if (!vm.isOnline)
            Positioned.fill(
              child: Container(
                color: AppColors.black.withValues(alpha: 0.5),
              ),
            ),
          // Google Maps Navigation Button
          Positioned(
            top: 60,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'google_maps_btn',
              backgroundColor: AppColors.white,
              onPressed: () => vm.openGoogleMapsForNavigation(),
              child: const Icon(Icons.directions_rounded, color: Colors.blue, size: 28),
            ),
          ),
          
          // Bottom panel
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.15,
            maxChildSize: 0.75,
            snap: true,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(top: BorderSide(color: AppColors.grey800)),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: _buildBottomPanel(context, vm),
                ),
              );
            },
          ),
          // Ride request overlay
          if (vm.currentRequest != null)
            _RideRequestOverlay(request: vm.currentRequest!, timer: vm.requestTimer, vm: vm),

          // Waiting for Payment Overlay
          if (vm.isWaitingForPayment)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.yellow),
                    SizedBox(height: 24),
                    Text('Waiting for Customer', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('to select payment method...', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              ),
            ),
            
          // Collect Cash Overlay
          if (vm.isWaitingForCash)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.6),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
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
                          const Text(
                            'Collect Cash',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (vm.activeRide != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '₹${vm.activeRide!.fare.toInt()}',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          const Text(
                            'Please collect the cash from the customer before completing the trip.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () async {
                                bool success = await vm.confirmCashCollection();
                                if (!success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to confirm cash!')));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('CONFIRM PAYMENT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
    );
  }

  Widget _buildBottomPanel(BuildContext context, RideViewModel vm) {
    if (vm.status == DriverStatus.rideAccepted || vm.status == DriverStatus.driverArrived || vm.status == DriverStatus.rideStarted) {
      return _ActiveRidePanel(vm: vm);
    }
    if (vm.status == DriverStatus.rideCompleted) {
      return _RideCompletedPanel(vm: vm);
    }
    return _TogglePanel(vm: vm);
  }
}

// ─── Toggle Online/Offline Panel ───────────────────────────────────────────
class _TogglePanel extends StatelessWidget {
  final RideViewModel vm;
  const _TogglePanel({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey700, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 24),
            // Stats row
            Row(
              children: [
                _StatBox(label: 'Today', value: '₹${vm.todayEarnings.toInt()}', icon: Icons.currency_rupee),
                const SizedBox(width: 12),
                _StatBox(label: 'Rides', value: '${vm.todayRides}', icon: Icons.local_taxi_rounded),
                const SizedBox(width: 12),
                _StatBox(label: 'Rating', value: '4.8★', icon: Icons.star_rounded),
              ],
            ),
            const SizedBox(height: 24),
            // Toggle button
            GestureDetector(
              onTap: vm.isToggling ? null : () => vm.toggleOnline(context),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  color: vm.isOnline ? AppColors.error.withValues(alpha: 0.15) : AppColors.yellow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: vm.isOnline ? AppColors.error : AppColors.yellowDark,
                    width: 2,
                  ),
                ),
                child: vm.isToggling
                    ? Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: vm.isOnline ? AppColors.error : AppColors.black,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            vm.isOnline ? Icons.power_settings_new_rounded : Icons.power_settings_new_rounded,
                            color: vm.isOnline ? AppColors.error : AppColors.black,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            vm.isOnline ? 'Go Offline' : 'Go Online',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: vm.isOnline ? AppColors.error : AppColors.black,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (vm.isOnline) ...[
              const SizedBox(height: 12),
              const Text('Waiting for ride requests...', style: TextStyle(fontSize: 13, color: AppColors.grey500)),
            ],
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => vm.logout(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.grey900,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grey800),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.error)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatBox({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.grey900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey800),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.yellow),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.white)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grey500)),
          ],
        ),
      ),
    );
  }
}

// ─── Ride Request Overlay ───────────────────────────────────────────────────
class _RideRequestOverlay extends StatelessWidget {
  final RideRequest request;
  final int timer;
  final RideViewModel vm;
  const _RideRequestOverlay({required this.request, required this.timer, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: AppColors.black.withValues(alpha: 0.7),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.yellow, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Timer bar
                Container(
                  height: 6,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    color: AppColors.grey800,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (timer / 16).clamp(0.0, 1.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.yellow,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.person_rounded, color: AppColors.black, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Text(request.passengerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(20)),
                            child: Text('$timer s', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.black)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Route
                      _RouteRow(pickup: request.pickup, drop: request.drop, stops: request.stops),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: [
                          _InfoChip(icon: Icons.straighten_rounded, label: '${request.distance.toStringAsFixed(1)} km'),
                          _InfoChip(icon: Icons.local_taxi_rounded, label: request.rideType),
                          if (request.rideType.toLowerCase() == 'shared')
                            _InfoChip(
                              icon: Icons.airline_seat_recline_normal, 
                              label: '${request.seatsBooked} Seat(s)' + (request.selectedSeats.isNotEmpty ? ' (${request.selectedSeats.join(", ")})' : '')
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Fare
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: AppColors.yellow.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.yellow.withValues(alpha: 0.3))),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const SizedBox(width: 12),
                            Text('₹${request.fare.toInt()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.yellow)),
                            const SizedBox(width: 6),
                            Text('• ${request.rideType}', style: const TextStyle(fontSize: 14, color: AppColors.grey500)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Accept / Reject
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => vm.rejectRide(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.grey700),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Reject', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () => vm.acceptRide(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.yellow,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Accept Ride', style: TextStyle(color: AppColors.black, fontWeight: FontWeight.w800, fontSize: 15)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Active Ride Panel ──────────────────────────────────────────────────────
class _ActiveRidePanel extends StatefulWidget {
  final RideViewModel vm;
  const _ActiveRidePanel({required this.vm});

  @override
  State<_ActiveRidePanel> createState() => _ActiveRidePanelState();
}

class _ActiveRidePanelState extends State<_ActiveRidePanel> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    if (vm.activeRide == null) return const SizedBox.shrink();
    
    final ride = vm.activeRide!;
    final isAccepted = ride.bookingStatus == 'Accepted';
    final isArrived = ride.bookingStatus == 'Arrived';
    final isStarted = ride.bookingStatus == 'Ongoing' || ride.bookingStatus == 'Payment_Pending';

    // Check stops
    int nextStopIndex = -1;
    bool nextStopArrived = false;
    if (isStarted && ride.stops.isNotEmpty) {
      for (int i = 0; i < ride.stops.length; i++) {
        if (ride.stops[i].status == 'Pending') {
          nextStopIndex = i;
          break;
        } else if (ride.stops[i].status == 'Arrived') {
          nextStopIndex = i;
          nextStopArrived = true;
          break;
        }
      }
    }
    final hasPendingStops = nextStopIndex != -1;

    String statusText = 'Heading to Pickup';
    if (isArrived) statusText = 'Arrived at Pickup';
    if (isStarted) statusText = hasPendingStops ? 'Heading to Stop ${nextStopIndex + 1}' : 'Ride in Progress';

    Color statusColor = isStarted ? AppColors.success : AppColors.yellow;

    return Container(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey700, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 16),
              
              // Passenger Selector (for Shared Rides)
              if (vm.activeRides.length > 1) ...[
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: vm.activeRides.length,
                    itemBuilder: (context, index) {
                      final r = vm.activeRides[index];
                      final isSelected = vm.selectedRideIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(r.passengerName, style: TextStyle(color: isSelected ? AppColors.black : AppColors.white, fontWeight: FontWeight.bold)),
                          selected: isSelected,
                          selectedColor: AppColors.yellow,
                          backgroundColor: AppColors.grey800,
                          onSelected: (val) {
                            if (val) vm.setSelectedRide(index);
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Status badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: statusColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Passenger info
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: AppColors.grey900, shape: BoxShape.circle, border: Border.all(color: AppColors.yellow, width: 2)),
                    child: const Icon(Icons.person_rounded, color: AppColors.yellow, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ride.passengerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white)),
                        Text('₹${ride.fare.toInt()} • ${ride.rideType}', style: const TextStyle(fontSize: 13, color: AppColors.grey500)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final phone = ride.passengerPhone;
                      if (phone.isNotEmpty) {
                        final url = Uri.parse('tel:$phone');
                        try {
                          await launchUrl(url);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch phone app')));
                          }
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number not available')));
                        }
                      }
                    },
                    child: Container(
                      width: 44, height: 44,
                      decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
                      child: const Icon(Icons.call_rounded, color: AppColors.black, size: 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _RouteRow(pickup: ride.pickup, drop: ride.drop, stops: ride.stops),
              const SizedBox(height: 16),

              if ((isArrived || (isStarted && nextStopArrived)) && vm.arrivedAt != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.grey900,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.grey800),
                  ),
                  child: Builder(
                    builder: (context) {
                      int elapsed = vm.waitingSeconds;
                      if (elapsed < 0) elapsed = 0;
                      int freeSeconds = ride.freeWaitingMin * 60;
                      bool isCharging = elapsed > freeSeconds;
                      int displaySeconds = isCharging ? (elapsed - freeSeconds) : (freeSeconds - elapsed);
                      String minStr = (displaySeconds ~/ 60).toString().padLeft(2, '0');
                      String secStr = (displaySeconds % 60).toString().padLeft(2, '0');
                      
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isCharging ? 'Waiting Charges Applying' : 'Free Waiting Time', style: TextStyle(fontSize: 13, color: isCharging ? AppColors.error : AppColors.success, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(isCharging ? 'Rate: ₹${ride.waitingChargePerMin.toInt()}/min' : 'Please wait for passenger', style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
                            ],
                          ),
                          Text('$minStr:$secStr', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isCharging ? AppColors.error : AppColors.success)),
                        ],
                      );
                    }
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (isArrived) ...[
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  style: const TextStyle(color: AppColors.white, fontSize: 18, letterSpacing: 8, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Enter 4-digit OTP',
                    hintStyle: const TextStyle(color: AppColors.grey500, letterSpacing: 0, fontSize: 16, fontWeight: FontWeight.normal),
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.grey900,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    setState(() => _isLoading = true);
                    if (isAccepted) {
                      bool success = await vm.markArrived();
                      if (!success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to mark arrived! Check network/logs.')));
                      }
                    } else if (isArrived) {
                      if (_otpController.text.length == 4) {
                        bool success = await vm.startRideWithOtp(_otpController.text);
                        if (!success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP! Please try again.')));
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter 4-digit OTP')));
                      }
                    } else if (isStarted) {
                      if (hasPendingStops) {
                        if (nextStopArrived) {
                          await vm.completeStop(nextStopIndex);
                        } else {
                          await vm.markStopArrived(nextStopIndex);
                        }
                      } else {
                        bool success = await vm.initiateTripCompletion();
                        if (!success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to initiate payment!')));
                        }
                      }
                    }
                    if (mounted) setState(() => _isLoading = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isStarted && !hasPendingStops ? AppColors.success : AppColors.yellow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2))
                    : Text(
                      isAccepted ? 'Arrived at Pickup' :
                      isArrived ? 'Start Ride' :
                      (isStarted && hasPendingStops) ? (nextStopArrived ? 'Complete Stop ${nextStopIndex + 1}' : 'Arrived at Stop ${nextStopIndex + 1}') :
                      'Complete Ride',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.black),
                    ),
                ),
              ),

              if (isAccepted || isArrived) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isLoading ? null : () => _showCancelDialog(context, vm),
                    child: const Text('Cancel Trip', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  void _showCancelDialog(BuildContext context, RideViewModel vm) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.grey900,
        title: const Text('Cancel Trip', style: TextStyle(color: AppColors.white)),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: AppColors.white),
          decoration: const InputDecoration(
            hintText: 'Reason for cancellation...',
            hintStyle: TextStyle(color: AppColors.grey500),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.grey700)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.yellow)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back', style: TextStyle(color: AppColors.grey500)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              bool success = await vm.cancelTrip(reasonController.text.isNotEmpty ? reasonController.text : "Driver cancelled");
              if (mounted) setState(() => _isLoading = false);
              if (!success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to cancel trip')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Cancel Trip', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }
}

// ─── Ride Completed Panel ───────────────────────────────────────────────────
class _RideCompletedPanel extends StatefulWidget {
  final RideViewModel vm;
  const _RideCompletedPanel({required this.vm});

  @override
  State<_RideCompletedPanel> createState() => _RideCompletedPanelState();
}

class _RideCompletedPanelState extends State<_RideCompletedPanel> {
  int _rating = 0;
  bool _isLoading = false;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    if (vm.lastCompletedRide == null) return const SizedBox.shrink();
    final ride = vm.lastCompletedRide!;
    return Container(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: AppColors.white, size: 40),
              ),
              const SizedBox(height: 16),
              const Text('Ride Completed!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.white)),
              const SizedBox(height: 4),
              Text(ride.passengerName, style: const TextStyle(fontSize: 14, color: AppColors.grey500)),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.grey900, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.grey800)),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Fare Earned', value: '₹${ride.fare.toInt()}', valueColor: AppColors.yellow),
                    const SizedBox(height: 10),
                    _SummaryRow(label: 'Distance', value: '${ride.distance.toStringAsFixed(1)} km'),
                    const SizedBox(height: 10),
                    _SummaryRow(label: 'Type', value: ride.rideType),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Rate the Passenger', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.white)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: AppColors.yellow,
                      size: 36,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reviewController,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'Leave a message (optional)',
                  hintStyle: const TextStyle(color: AppColors.grey500),
                  filled: true,
                  fillColor: AppColors.grey900,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () {
                        vm.resetAfterComplete();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.grey700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Skip', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _rating == 0 || _isLoading ? null : () async {
                        setState(() => _isLoading = true);
                        await vm.submitRating(ride.bookingId, _rating, message: _reviewController.text.trim());
                        vm.resetAfterComplete();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellow,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2))
                          : const Text('Submit', style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _SummaryRow({required this.label, required this.value, this.valueColor = AppColors.white});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.grey500)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor)),
      ],
    );
  }
}

// ─── Shared Widgets ─────────────────────────────────────────────────────────
class _RouteRow extends StatelessWidget {
  final String pickup;
  final String drop;
  final List<dynamic> stops;
  const _RouteRow({required this.pickup, required this.drop, this.stops = const []});

  @override
  Widget build(BuildContext context) {
    List<Widget> locations = [];
    
    // Pickup
    locations.add(
      Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.success, width: 2.5))),
          const SizedBox(width: 12),
          Expanded(child: Text(pickup, style: const TextStyle(fontSize: 13, color: AppColors.white, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      )
    );

    // Stops
    for (var stop in stops) {
      locations.add(
        Padding(
          padding: const EdgeInsets.only(left: 4.5, top: 2, bottom: 2),
          child: Container(width: 1.5, height: 12, color: AppColors.grey700),
        )
      );
      locations.add(
        Row(
          children: [
            Container(width: 8, height: 8, margin: const EdgeInsets.only(left: 1), decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent)),
            const SizedBox(width: 13),
            Expanded(child: Text(stop.address, style: const TextStyle(fontSize: 12, color: AppColors.grey500, fontWeight: FontWeight.w400), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        )
      );
    }

    // Line to Drop
    locations.add(
      Padding(
        padding: const EdgeInsets.only(left: 4.5, top: 2, bottom: 2),
        child: Container(width: 1.5, height: 12, color: AppColors.grey700),
      )
    );

    // Drop
    locations.add(
      Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.yellow, width: 2.5))),
          const SizedBox(width: 12),
          Expanded(child: Text(drop, style: const TextStyle(fontSize: 13, color: AppColors.white, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      )
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: locations,
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(color: AppColors.grey900, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.grey800)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.yellow),
          const SizedBox(width: 4),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.white, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}


