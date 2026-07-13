import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/network/api_constants.dart';

class BookingRequest {
  final String id;
  final String passengerName;
  final String passengerRating;
  final String pickup;
  final String drop;
  final String distance;
  final String duration;
  final String fare;
  final String paymentMode;
  final double pickupDistance;
  int timer;

  BookingRequest({
    required this.id,
    required this.passengerName,
    required this.passengerRating,
    required this.pickup,
    required this.drop,
    required this.distance,
    required this.duration,
    required this.fare,
    required this.paymentMode,
    required this.pickupDistance,
    this.timer = 20,
  });
}

class BookingHistory {
  final String id;
  final String passengerName;
  final String pickup;
  final String drop;
  final String distance;
  final String duration;
  final String fare;
  final String paymentMode;
  final String date;
  final String status;
  
  // New detailed fields
  final String passengerPhone;
  final String carCategoryName;
  final String rideType;
  final String arrivedAt;
  final String startedAt;
  final String endedAt;
  final String waitingTimeMin;
  final String waitingCharges;
  final String cancelReason;

  const BookingHistory({
    required this.id,
    required this.passengerName,
    required this.pickup,
    required this.drop,
    required this.distance,
    required this.duration,
    required this.fare,
    required this.paymentMode,
    required this.date,
    required this.status,
    required this.passengerPhone,
    required this.carCategoryName,
    required this.rideType,
    required this.arrivedAt,
    required this.startedAt,
    required this.endedAt,
    required this.waitingTimeMin,
    required this.waitingCharges,
    required this.cancelReason,
  });
}


class BookingsViewModel extends ChangeNotifier {
  BookingsViewModel() {
    _checkInitialOnlineStatus();
  }

  Future<void> _checkInitialOnlineStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse(ApiConstants.driverProfile),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['driver'] != null) {
          bool isOnlineApi = body['driver']['isOnline'] ?? false;
          setOnlineStatus(isOnlineApi);
        }
      }
      
      // Also fetch history when viewmodel initializes
      await fetchHistory();
      await fetchActiveRide();
    } catch (_) {}
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final m = months[dt.month - 1];
      final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return "${dt.day} $m, $h:$min $ampm";
    } catch (e) {
      return 'Recent';
    }
  }

  Future<void> fetchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse(ApiConstants.getDriverTrips),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List trips = body['trips'] ?? [];
          List<BookingHistory> newHistory = [];
          for (var trip in trips) {
            newHistory.add(BookingHistory(
              id: trip['_id'] ?? '',
              passengerName: trip['user']?['name'] ?? trip['passengerDetails']?['name'] ?? 'Passenger',
              passengerPhone: trip['user']?['phone'] ?? trip['passengerDetails']?['phone'] ?? 'N/A',
              pickup: trip['pickup']?['address'] ?? 'Unknown Pickup',
              drop: trip['drop']?['address'] ?? 'Unknown Drop',
              distance: trip['estimatedDistanceKm'] != null ? "${trip['estimatedDistanceKm']} km" : 'N/A',
              duration: 'N/A', 
              fare: "₹${trip['actualFare'] ?? trip['fareEstimate'] ?? '0'}",
              paymentMode: trip['paymentMethod'] ?? 'Cash',
              date: _formatDate(trip['createdAt'] ?? ''),
              status: trip['bookingStatus'] ?? 'Unknown',
              carCategoryName: trip['carCategory']?['name'] ?? 'N/A',
              rideType: trip['rideType'] ?? 'Private',
              arrivedAt: trip['tripData']?['arrivedAt'] != null ? _formatDate(trip['tripData']['arrivedAt']) : 'N/A',
              startedAt: trip['tripData']?['startedAt'] != null ? _formatDate(trip['tripData']['startedAt']) : 'N/A',
              endedAt: trip['tripData']?['endedAt'] != null ? _formatDate(trip['tripData']['endedAt']) : 'N/A',
              waitingTimeMin: trip['tripData']?['waitingTimeMin']?.toString() ?? '0',
              waitingCharges: "₹${trip['tripData']?['waitingCharges'] ?? '0'}",
              cancelReason: trip['cancelReason'] ?? '',
            ));
          }
          _history = newHistory;
          if (!_disposed) notifyListeners();
        }
      }
    } catch (e) {
      print('Error fetching history: $e');
    }
  }

  Future<void> fetchActiveRide() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeBookingId = prefs.getString('active_booking_id');
      
      if (activeBookingId == null) {
        // Fallback: Check history for an active ride
        final activeStatus = ['Accepted', 'Ongoing', 'Driver Arrived', 'Started'];
        try {
          _activeRide = _history.firstWhere((r) => activeStatus.contains(r.status));
          if (_activeRide != null) {
            prefs.setString('active_booking_id', _activeRide!.id);
            if (!_disposed) notifyListeners();
          }
        } catch (_) {}
        return;
      }
      
      final token = prefs.getString('driver_token');
      if (token == null) return;

      final url = ApiConstants.getSingleBooking.replaceAll(':bookingId', activeBookingId);
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['booking'] != null) {
          final trip = body['booking'];
          
          final statusStr = trip['bookingStatus'] ?? 'Unknown';
          if (statusStr == 'Completed' || statusStr == 'Cancelled') {
            _activeRide = null;
            prefs.remove('active_booking_id');
            if (!_disposed) notifyListeners();
            return;
          }

          _activeRide = BookingHistory(
            id: trip['_id'] ?? '',
            passengerName: trip['user']?['name'] ?? trip['passengerDetails']?['name'] ?? 'Passenger',
            passengerPhone: trip['user']?['phone'] ?? trip['passengerDetails']?['phone'] ?? 'N/A',
            pickup: trip['pickup']?['address'] ?? 'Unknown Pickup',
            drop: trip['drop']?['address'] ?? 'Unknown Drop',
            distance: trip['estimatedDistanceKm'] != null ? "${trip['estimatedDistanceKm']} km" : 'N/A',
            duration: 'N/A', 
            fare: "₹${trip['actualFare'] ?? trip['fareEstimate'] ?? '0'}",
            paymentMode: trip['paymentMethod'] ?? 'Cash',
            date: _formatDate(trip['createdAt'] ?? ''),
            status: statusStr,
            carCategoryName: trip['carCategory']?['name'] ?? 'N/A',
            rideType: trip['rideType'] ?? 'Private',
            arrivedAt: trip['tripData']?['arrivedAt'] != null ? _formatDate(trip['tripData']['arrivedAt']) : 'N/A',
            startedAt: trip['tripData']?['startedAt'] != null ? _formatDate(trip['tripData']['startedAt']) : 'N/A',
            endedAt: trip['tripData']?['endedAt'] != null ? _formatDate(trip['tripData']['endedAt']) : 'N/A',
            waitingTimeMin: trip['tripData']?['waitingTimeMin']?.toString() ?? '0',
            waitingCharges: "₹${trip['tripData']?['waitingCharges'] ?? '0'}",
            cancelReason: trip['cancelReason'] ?? '',
          );
          if (!_disposed) notifyListeners();
        } else {
          _activeRide = null;
          prefs.remove('active_booking_id');
          if (!_disposed) notifyListeners();
        }
      } else {
        _activeRide = null;
        prefs.remove('active_booking_id');
        if (!_disposed) notifyListeners();
      }
    } catch (e) {
      print('Error fetching active ride: $e');
    }
  }

  void _fallbackToHistory(SharedPreferences prefs) {
    final activeStatus = ['Accepted', 'Ongoing', 'Driver Arrived', 'Started'];
    try {
      final found = _history.where((r) => activeStatus.contains(r.status));
      if (found.isNotEmpty) {
        _activeRide = found.first;
        prefs.setString('active_booking_id', _activeRide!.id);
      } else {
        _activeRide = null;
      }
      if (!_disposed) notifyListeners();
    } catch (_) {
      _activeRide = null;
      if (!_disposed) notifyListeners();
    }
  }

  bool _disposed = false;
  bool _isOnline = false;

  List<BookingRequest> _incoming = [];
  List<BookingHistory> _history = [];
  BookingHistory? _activeRide;
  Timer? _pollingTimer;
  Timer? _countdownTimer;

  bool get isOnline => _isOnline;
  List<BookingRequest> get incomingRequests => List.unmodifiable(_incoming);
  List<BookingHistory> get history => List.unmodifiable(_history);
  BookingHistory? get activeRide => _activeRide;

  void setOnlineStatus(bool online) {
    _isOnline = online;
    notifyListeners();
    if (online) {
      _startPolling();
      _startCountdown();
    } else {
      _stopPolling();
      _incoming.clear();
      notifyListeners();
    }
  }

  void _startPolling() {
    // Removed polling of /api/trips/requests/pending as per user instructions
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
  }

  void _startCountdown() {
    // Countdown disabled
  }

  Future<void> _fetchPendingRequests() async {
    if (!_isOnline || _disposed) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse(ApiConstants.getPendingRequests),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List requests = body['requests'] ?? [];
          List<BookingRequest> newIncoming = [];
          
          Position? currentPos;
          try {
            currentPos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          } catch (_) {}

          int currentTime = DateTime.now().millisecondsSinceEpoch;

          for (var req in requests) {
            final booking = req['booking'];
            if (booking == null) continue;

            int expiresAt = req['expiresAt'] ?? currentTime;
            int remainingSeconds = ((expiresAt - currentTime) / 1000).floor();
            
            if (remainingSeconds <= 0) {
              // Backend test data has stale expiresAt. 
              // Preserve existing timer if it's already in the list, else default 60s.
              int idx = _incoming.indexWhere((r) => r.id == req['_id']);
              if (idx != -1) {
                remainingSeconds = _incoming[idx].timer;
              } else {
                remainingSeconds = 60; 
              }
            }

            double pickupLat = booking['pickup']['latitude'] ?? 0.0;
            double pickupLng = booking['pickup']['longitude'] ?? 0.0;
            
            double pickupDistance = 0.0;
            if (currentPos != null && pickupLat != 0.0 && pickupLng != 0.0) {
              pickupDistance = Geolocator.distanceBetween(
                currentPos.latitude, currentPos.longitude, pickupLat, pickupLng
              ) / 1000.0; // convert to km
            }

            newIncoming.add(BookingRequest(
              id: req['_id'],
              passengerName: booking['passengerDetails']?['name'] ?? 'Passenger',
              passengerRating: '4.8', // default if not provided
              pickup: booking['pickup']?['address'] ?? 'Unknown Pickup',
              drop: booking['drop']?['address'] ?? 'Unknown Drop',
              distance: '${booking['estimatedDistanceKm'] ?? '0'} km',
              duration: 'N/A', // not provided directly
              fare: '₹${booking['fareEstimate'] ?? '0'}',
              paymentMode: booking['paymentMethod'] ?? 'Cash',
              pickupDistance: pickupDistance,
              timer: remainingSeconds > 60 ? 60 : remainingSeconds, // Max out to 60s for UI safety
            ));
          }

          // Update only if different (simplified diffing)
          _incoming = newIncoming;
          if (!_disposed) notifyListeners();
        }
      }
    } catch (e) {
      print('Error fetching pending requests: \$e');
    }
  }

  void acceptRequest(String id) {
    // Calling accept API is usually handled by RideViewModel's acceptRide 
    // but we can just remove it from incoming here for UI smoothness
    _incoming.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  void rejectRequest(String id) {
    // Calling reject API should be done here or handled elsewhere.
    // For now just removing it from list.
    _incoming.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopPolling();
    super.dispose();
  }
}