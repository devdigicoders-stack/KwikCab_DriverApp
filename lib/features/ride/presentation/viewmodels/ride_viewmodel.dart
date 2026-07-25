import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kwikcabdriver/core/network/app_http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:kwikcabdriver/core/network/app_http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../../../core/network/api_constants.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../main.dart'; // For navigatorKey
import 'package:location/location.dart' as loc;

enum DriverStatus { offline, online, rideRequested, rideAccepted, driverArrived, rideStarted, rideCompleted }

class RideStop {
  final String id;
  final String address;
  final double latitude;
  final double longitude;
  final String status;

  RideStop({
    required this.id,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  factory RideStop.fromJson(Map<String, dynamic> json) {
    return RideStop(
      id: json['_id'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Pending',
    );
  }
}

class RideRequest {
  final String id;
  final String bookingId;
  final String passengerName;
  final String passengerPhone;
  final String pickup;
  final String drop;
  final double pickupLat;
  final double pickupLng;
  final double dropLat;
  final double dropLng;
  final double distance;
  final double fare;
  final String rideType;
  final int seatsBooked;
  final List<String> selectedSeats;
  final List<RideStop> stops;
  final int expiresAt;
  final int freeWaitingMin;
  final double waitingChargePerMin;
  String bookingStatus;
  Map<String, dynamic> tripData;

  RideRequest({
    required this.id,
    required this.bookingId,
    required this.passengerName,
    required this.passengerPhone,
    required this.pickup,
    required this.drop,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropLat,
    required this.dropLng,
    required this.distance,
    required this.fare,
    required this.rideType,
    required this.seatsBooked,
    required this.selectedSeats,
    required this.stops,
    required this.expiresAt,
    required this.freeWaitingMin,
    required this.waitingChargePerMin,
    required this.bookingStatus,
    required this.tripData,
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'] ?? {};
    final passenger = booking['passengerDetails'] ?? {};
    final pickup = booking['pickup'] ?? {};
    final drop = booking['drop'] ?? {};

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int seats = booking['seatsBooked'] ?? 1;
    List<String> parsedSelectedSeats = [];
    if (booking['selectedSeats'] != null) {
      parsedSelectedSeats = List<String>.from(booking['selectedSeats']);
    }
    
    List<RideStop> parsedStops = [];
    if (booking['stops'] != null) {
      parsedStops = (booking['stops'] as List).map((s) => RideStop.fromJson(s)).toList();
    }
    
    final carCategoryData = booking['carCategory'];
    int freeWait = 3;
    double waitCharge = 2.0;

    if (carCategoryData is Map<String, dynamic>) {
      freeWait = carCategoryData['freeWaitingMin'] ?? 3;
      double parsedCharge = parseDouble(carCategoryData['waitingChargePerMin']);
      if (parsedCharge > 0.0) waitCharge = parsedCharge;
    }

    return RideRequest(
      id: json['_id'] ?? '',
      bookingId: booking['_id'] ?? '',
      passengerName: passenger['name'] ?? 'Passenger',
      passengerPhone: passenger['phone'] ?? '',
      pickup: pickup['address'] ?? 'Unknown Pickup',
      drop: drop['address'] ?? 'Unknown Drop',
      pickupLat: parseDouble(pickup['latitude']),
      pickupLng: parseDouble(pickup['longitude']),
      dropLat: parseDouble(drop['latitude']),
      dropLng: parseDouble(drop['longitude']),
      distance: parseDouble(booking['estimatedDistanceKm']),
      fare: parseDouble(booking['fareEstimate']),
      rideType: booking['rideType'] ?? 'Private',
      seatsBooked: seats,
      selectedSeats: parsedSelectedSeats,
      stops: parsedStops,
      expiresAt: json['expiresAt'] ?? 0,
      freeWaitingMin: freeWait,
      waitingChargePerMin: waitCharge,
      bookingStatus: booking['bookingStatus'] ?? 'Unknown',
      tripData: booking['tripData'] ?? {},
    );
  }
}

class RideViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();
  DriverStatus _status = DriverStatus.offline;
  RideRequest? _currentRequest;
  List<RideRequest> _activeRides = [];
  int _selectedRideIndex = 0;
  int _requestTimer = 0;

  RideRequest? _lastCompletedRide;
  RideRequest? get lastCompletedRide => _lastCompletedRide;
  bool _disposed = false;

  bool _isToggling = false;
  Position? _currentPosition;
  Position? _targetPosition;
  Timer? _animationTimer;
  Timer? _pollingTimer;
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;
  StreamSubscription<Map<String, dynamic>>? _bookingUpdateSubscription;
  StreamSubscription<Map<String, dynamic>>? _timeoutSubscription;
  StreamSubscription<Map<String, dynamic>>? _newAgentLeadSubscription;
  StreamSubscription<Map<String, dynamic>>? _collectCashSubscription;
  String? _driverId;
  BitmapDescriptor? _carIcon;

  Set<Polyline> _polylines = {};
  List<LatLng> _currentRoutePoints = [];
  DateTime? _lastRerouteTime;
  static const String _googleMapsApiKey = "AIzaSyBEss4wpsQ0o9WPBjDgHsSByUzFuo2oSNE";

  DateTime? _arrivedAt;
  Timer? _waitingTimer;
  int _waitingSeconds = 0;

  // Today's stats
  int _todayRides = 0;
  double _todayEarnings = 0.0;

  bool _isWaitingForPayment = false;
  bool _isWaitingForCash = false;

  DateTime? get arrivedAt => _arrivedAt;
  int get waitingSeconds => _waitingSeconds;
  int get todayRides => _todayRides;
  double get todayEarnings => _todayEarnings;
  bool get isWaitingForPayment => _isWaitingForPayment;
  bool get isWaitingForCash => _isWaitingForCash;
  PolylinePoints _polylinePoints = PolylinePoints(apiKey: _googleMapsApiKey);

  DriverStatus get status => _status;
  RideRequest? get currentRequest => _currentRequest;
  List<RideRequest> get activeRides => _activeRides;
  RideRequest? get activeRide => _activeRides.isNotEmpty && _selectedRideIndex < _activeRides.length ? _activeRides[_selectedRideIndex] : null;
  int get selectedRideIndex => _selectedRideIndex;
  int get requestTimer => _requestTimer;
  bool get isOnline => _status != DriverStatus.offline;
  bool get isToggling => _isToggling;
  Position? get currentPosition => _currentPosition;
  BitmapDescriptor? get carIcon => _carIcon;
  Set<Polyline> get polylines => _polylines;

  void setSelectedRide(int index) {
    if (index >= 0 && index < _activeRides.length) {
      _selectedRideIndex = index;
      _drawRouteForCurrentStatus();
      notifyListeners();
    }
  }

  RideViewModel() {
    _initLocation();
    _fetchInitialStatus();
    _loadCarIcon();
    _fetchTodayStats();
    WidgetsBinding.instance.addObserver(this);
  }

  void _playRingtone() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('WhatsApp Audio 2026-06-26 at 21.43.14.mpeg'));
    } catch (e) {
      print('Ringtone play error: $e');
    }
  }

  void _stopRingtone() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_status != DriverStatus.offline) {
        _fetchPendingRequests();
        _fetchActiveRidesFromBackend();
        if (_driverId != null) {
          SocketService.instance.initSocket(_driverId!, 'driver');
          SocketService.instance.driverOnline(_driverId!);
        }
      }
    }
  }

  Future<void> _fetchTodayStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse(ApiConstants.getDriverTrips),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['trips'] != null) {
          final List trips = body['trips'];

          // Aaj ka date (local time)
          final now = DateTime.now().toLocal();
          final todayStart = DateTime(now.year, now.month, now.day);

          int rideCount = 0;
          double earningsTotal = 0.0;

          for (var trip in trips) {
            final status = trip['bookingStatus'] ?? '';
            if (status != 'Completed') continue;

            final createdAtStr = trip['createdAt'] ?? '';
            if (createdAtStr.isEmpty) continue;

            final createdAt = DateTime.tryParse(createdAtStr)?.toLocal();
            if (createdAt == null) continue;

            final tripDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
            if (!tripDay.isAtSameMomentAs(todayStart)) continue;

            rideCount++;
            final fare = trip['actualFare'] ?? trip['fareEstimate'] ?? 0;
            if (fare is num) earningsTotal += fare.toDouble();
          }

          _todayRides = rideCount;
          _todayEarnings = earningsTotal;
          if (!_disposed) notifyListeners();
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _loadCarIcon() async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final size = 100.0;
    
    // Draw background circle
    final paint = Paint()..color = AppColors.yellow;
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
    
    // Draw navigation arrow icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.navigation_rounded.codePoint),
      style: TextStyle(
        fontSize: size * 0.6,
        fontFamily: Icons.navigation_rounded.fontFamily,
        package: Icons.navigation_rounded.fontPackage,
        color: AppColors.black,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2)
    );
    
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    _carIcon = BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
    notifyListeners();
  }

  Future<void> _fetchInitialStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse(ApiConstants.driverProfile),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      final body = jsonDecode(response.body);
      if (body['success'] == true && body['driver'] != null) {
        _driverId = body['driver']['_id']?.toString();
        bool isOnlineApi = body['driver']['isOnline'] ?? false;
        _status = isOnlineApi ? DriverStatus.online : DriverStatus.offline;
        
        if (isOnlineApi) {
          _startLocationTracking();
          List<String> activeIds = prefs.getStringList('active_booking_ids') ?? [];
          if (activeIds.isNotEmpty) {
            await _fetchActiveRidesFromBackend();
          } else {
            _startSocketListening();
          }
        }
        
        notifyListeners();
      }
    } catch (e) {
      // Handle silently
    }
  }

  Future<void> _fetchActiveRidesFromBackend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token');
      if (token == null) return;

      final url = ApiConstants.getDriverTrips;
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['trips'] != null) {
          final List trips = body['trips'];
          _activeRides.clear();
          
          for (var trip in trips) {
            String statusStr = trip['bookingStatus'] ?? '';
            
            if (statusStr == 'Accepted' && trip['tripData'] != null && trip['tripData']['arrivedAt'] != null && trip['tripData']['startedAt'] == null) {
              trip['bookingStatus'] = 'Arrived';
              statusStr = 'Arrived';
            }

            if (statusStr != 'Completed' && statusStr != 'Cancelled' && statusStr != 'Pending') {
              _activeRides.add(RideRequest.fromJson({'booking': trip}));
            }
          }
          
          if (_activeRides.isNotEmpty) {
            _selectedRideIndex = 0;
            // Determine overall status based on the first ride (simplified)
            final statusStr = _activeRides.first.bookingStatus;
            if (statusStr == 'Payment_Pending') {
              _status = DriverStatus.rideStarted;
              _isWaitingForPayment = true;
            } else if (statusStr == 'Arrived') {
              _status = DriverStatus.driverArrived;
            } else if (statusStr == 'Ongoing') {
              _status = DriverStatus.rideStarted;
            } else {
              _status = DriverStatus.rideAccepted;
            }
            _drawRouteForCurrentStatus();
            _startSocketListening(); // resume listening if shared ride
          } else {
            prefs.remove('active_booking_ids');
            _status = DriverStatus.online;
            _startSocketListening();
          }
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error fetching active rides data: $e');
    }
  }

  Future<void> _initLocation() async {
    print('--- _initLocation started ---');
    try {
      loc.Location location = loc.Location();

      // Check & request permission
      loc.PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted && permissionGranted != loc.PermissionStatus.grantedLimited) {
          print('_initLocation: Permission denied');
          _setDefaultLocation();
          return;
        }
      }

      // Check & request service (Native Google Dialog)
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          print('_initLocation: Service disabled by user');
          _setDefaultLocation();
          return;
        }
      }

      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _currentPosition = lastKnown;
        notifyListeners();
        _animateToCurrentPosition();
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 10),
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );
      print('_initLocation: Position fetched successfully');
    } catch (e) {
      print('Error in _initLocation: $e');
      _setDefaultLocation();
    }
    
    notifyListeners();
    _animateToCurrentPosition();
  }

  void _setDefaultLocation() {
    // Default to New Delhi (28.7041, 77.1025) if location cannot be fetched
    _currentPosition = Position(
      longitude: 77.1025,
      latitude: 28.7041,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0
    );
    notifyListeners();
    _animateToCurrentPosition();
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _animateToCurrentPosition();
  }

  void _animateToCurrentPosition() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 15,
          ),
        ),
      );
    }
  }

  void _startLocationTracking() {
    if (_positionStreamSubscription != null) return;
    
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // Update frequently for smooth animation
      ),
    ).listen((Position position) {
      if (_currentPosition == null) {
        _currentPosition = position;
        notifyListeners();
        _animateToCurrentPosition();
      } else {
        _targetPosition = position;
        _startMarkerAnimation();
      }
      
      if (_status != DriverStatus.offline) {
        if (_driverId != null) {
          SocketService.instance.updateLocation(_driverId!, position.latitude, position.longitude, position.heading);
        }
        _sendLocationToBackend(position);
      }
      
      // Update route dynamically if moving towards pickup or drop
      if (_status == DriverStatus.rideAccepted || _status == DriverStatus.driverArrived || _status == DriverStatus.rideStarted) {
        _updateRouteDynamic();
      }
    });
  }

  void _startMarkerAnimation() {
    _animationTimer?.cancel();
    if (_currentPosition == null || _targetPosition == null) return;
    
    final startLat = _currentPosition!.latitude;
    final startLng = _currentPosition!.longitude;
    final startHeading = _currentPosition!.heading;
    
    final endLat = _targetPosition!.latitude;
    final endLng = _targetPosition!.longitude;
    final endHeading = _targetPosition!.heading;

    int steps = 20; // 1 second animation (20 frames of 50ms)
    int currentStep = 0;
    
    _animationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      currentStep++;
      double t = currentStep / steps;
      
      double newLat = startLat + (endLat - startLat) * t;
      double newLng = startLng + (endLng - startLng) * t;
      
      // Simple shortest-path rotation interpolation
      double diff = endHeading - startHeading;
      if (diff > 180) diff -= 360;
      if (diff < -180) diff += 360;
      double newHeading = startHeading + (diff * t);
      
      _currentPosition = Position(
        latitude: newLat,
        longitude: newLng,
        heading: newHeading,
        timestamp: DateTime.now(),
        accuracy: 0, altitude: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0,
      );
      
      notifyListeners();
      
      // Only animate map camera on the final step to avoid stuttering user map interactions
      if (currentStep >= steps) {
        timer.cancel();
        _animateToCurrentPosition();
      }
    });
  }

  void _stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _animationTimer?.cancel();
  }

  Future<void> _sendLocationToBackend(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token');
      if (token == null) return;

      final body = jsonEncode({
        "latitude": position.latitude,
        "longitude": position.longitude,
        "heading": position.heading,
      });

      await http.put(
        Uri.parse(ApiConstants.updateLocation),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );
    } catch (e) {
      _isToggling = false;
      notifyListeners();
    }
  }

  void _startSocketListening() {
    _stopSocketListening();
    
    if (_driverId == null || _status == DriverStatus.offline) return;
    
    SocketService.instance.initSocket(_driverId!, 'driver');
    SocketService.instance.driverOnline(_driverId!);
    
    // Always listen to booking updates (like cancellations) if we are not offline
    _bookingUpdateSubscription = SocketService.instance.onBookingUpdate.listen((data) {
      if (data['status'] == 'Completed') {
         _isWaitingForPayment = false;
         _isWaitingForCash = false;
         // Same as Cash flow: show ride completed screen with rating option
         _lastCompletedRide = activeRide;
         _activeRides.removeWhere((r) => r.bookingId == (data['bookingId'] ?? activeRide?.bookingId));
         if (_activeRides.isEmpty) {
           _status = DriverStatus.rideCompleted;
         } else {
           _polylines.clear();
           _currentRoutePoints.clear();
         }
         _selectedRideIndex = 0;
         notifyListeners();
      } else if (data['status'] == 'Cancelled') {
        _currentRequest = null;
        
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.black,
              title: const Text("Ride Cancelled", style: TextStyle(color: AppColors.yellow, fontWeight: FontWeight.bold)),
              content: const Text("The rider has cancelled this trip. You are now online for new rides.", style: TextStyle(color: Colors.white)),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    
                    if (data['bookingId'] != null) {
                      _activeRides.removeWhere((r) => r.bookingId == data['bookingId']);
                    }

                    if (_activeRides.isEmpty) {
                      _status = DriverStatus.online;
                      _waitingTimer?.cancel();
                      _arrivedAt = null;
                      _polylines.clear();
                      SharedPreferences.getInstance().then((prefs) => prefs.remove('active_booking_ids'));
                    } else {
                      _selectedRideIndex = 0;
                    }
                    
                    notifyListeners();
                    _fetchActiveRidesFromBackend();
                  },
                  child: const Text("OK", style: TextStyle(color: AppColors.yellow, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        } else {
          // Fallback if no context
          if (data['bookingId'] != null) {
            _activeRides.removeWhere((r) => r.bookingId == data['bookingId']);
          }

          if (_activeRides.isEmpty) {
            _status = DriverStatus.online;
            _waitingTimer?.cancel();
            _arrivedAt = null;
            _polylines.clear();
            SharedPreferences.getInstance().then((prefs) => prefs.remove('active_booking_ids'));
          } else {
            _selectedRideIndex = 0;
          }
          
          notifyListeners();
          _fetchActiveRidesFromBackend();
        }
      }
    });

    bool canPoll = _status == DriverStatus.online || 
        (_activeRides.isNotEmpty && _activeRides.every((r) => r.rideType.trim().toLowerCase() == 'shared'));
        
    if (canPoll) {
      _socketSubscription = SocketService.instance.onNewRideRequest.listen((data) {
        _fetchPendingRequests();
      });

      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        bool stillCanPoll = _status == DriverStatus.online || 
            (_activeRides.isNotEmpty && _activeRides.every((r) => r.rideType.trim().toLowerCase() == 'shared'));
        if (stillCanPoll) {
          _fetchPendingRequests();
        } else {
          _pollingTimer?.cancel();
        }
      });

      _timeoutSubscription = SocketService.instance.onRideRequestTimeout.listen((data) {
        // If the request timed out for this driver, dismiss it
        if (_currentRequest != null && (_currentRequest!.id == data['requestId'] || _currentRequest!.bookingId == data['bookingId'])) {
          _currentRequest = null;
          _stopRingtone();
          if (_activeRides.isEmpty) {
            _status = DriverStatus.online;
          }
          notifyListeners();
        }
      });
    }

    _newAgentLeadSubscription = SocketService.instance.onNewAgentLead.listen((data) {
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('🚀 New Agent Lead! Earn ₹${data['earning']}. Check Marketplace!'),
             backgroundColor: Colors.green,
             duration: const Duration(seconds: 8),
           ),
         );
      }
    });
    
    _collectCashSubscription = SocketService.instance.onCollectCash.listen((data) {
      print('DEBUG: onCollectCash triggered. data: $data');
      if (activeRide != null) {
        _isWaitingForPayment = false;
        _isWaitingForCash = true;
        notifyListeners();
      }
    });
    
    _fetchPendingRequests(); // fetch immediately just in case
  }

  void _stopSocketListening({bool emitOffline = false}) {
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _bookingUpdateSubscription?.cancel();
    _bookingUpdateSubscription = null;
    _timeoutSubscription?.cancel();
    _timeoutSubscription = null;
    _newAgentLeadSubscription?.cancel();
    _newAgentLeadSubscription = null;
    _collectCashSubscription?.cancel();
    _collectCashSubscription = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;

    if (emitOffline && _driverId != null) {
      SocketService.instance.driverOffline(_driverId!);
    }
  }

  Future<void> _fetchPendingRequests() async {
    bool canPoll = _status == DriverStatus.online || 
        (_activeRides.isNotEmpty && _activeRides.every((r) => r.rideType.trim().toLowerCase() == 'shared'));
        
    if (!canPoll) return;
    
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
        if (body['success'] == true && body['requests'] != null) {
          final List requests = body['requests'];
          if (requests.isNotEmpty) {
            final newRequest = RideRequest.fromJson(requests.first);
            if (canPoll) {
              _currentRequest = newRequest;
              if (_status == DriverStatus.online) {
                _status = DriverStatus.rideRequested;
              }
              _playRingtone();
              _startRequestTimer(newRequest.expiresAt);
              _stopSocketListening(); // pause listening
              notifyListeners();
            }
          }
        }
      }
    } catch (e) {
      // ignore background polling errors
    }
  }

  void _startRequestTimer(int expiresAtTimestamp) {
    int remaining = ((expiresAtTimestamp - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
    _requestTimer = remaining > 0 ? remaining : 0;

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_disposed || _currentRequest == null) return false;
      
      remaining = ((expiresAtTimestamp - DateTime.now().millisecondsSinceEpoch) / 1000).ceil();
      if (remaining <= 0) {
        _requestTimer = 0;
        if (_activeRides.isEmpty) {
          _status = DriverStatus.online;
        }
        _currentRequest = null;
        _stopRingtone();
        _startSocketListening(); // resume listening since it expired
        notifyListeners();
        return false;
      }
      _requestTimer = remaining;
      notifyListeners();
      return true;
    });
  }

  Future<void> toggleOnline(BuildContext context) async {
    if (_isToggling) return;
    print('--- toggleOnline started ---');

    if (_status == DriverStatus.offline) {
      loc.Location location = loc.Location();

      loc.PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted && permissionGranted != loc.PermissionStatus.grantedLimited) {
          print('toggleOnline: Permission denied');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission is required to go online')),
            );
          }
          return;
        }
      } else if (permissionGranted == loc.PermissionStatus.deniedForever) {
         print('toggleOnline: Permission permanently denied');
         if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission is permanently denied. Please allow in App Settings.')),
            );
          }
          return;
      }

      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        print('toggleOnline: requesting service');
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          print('toggleOnline: service request denied by user');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enable GPS to go online')),
            );
          }
          return;
        }
      }
    }

    _isToggling = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token');

      if (token == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication error. Please login again.')),
          );
        }
        return;
      }

      // Try to get the fresh accurate location before sending request
      try {
        Position freshPos = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 5),
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        _currentPosition = freshPos;
        _animateToCurrentPosition();
        notifyListeners();
      } catch (e) {
        // If it fails, we keep the previous/default _currentPosition
      }

      final body = jsonEncode({
        "latitude": _currentPosition?.latitude ?? 28.7041,
        "longitude": _currentPosition?.longitude ?? 77.1025
      });

      final response = await http.put(
        Uri.parse(ApiConstants.toggleOnline),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 8));

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success'] == true) {
        bool newIsOnline = responseBody['isOnline'] ?? (_status == DriverStatus.offline);
        if (newIsOnline) {
          _status = DriverStatus.online;
          if (responseBody['driver'] != null) {
            _driverId = responseBody['driver']['_id']?.toString() ?? _driverId;
          }
          _startLocationTracking();
          _startSocketListening();
          notifyListeners();
        } else {
          _status = DriverStatus.offline;
          _stopLocationTracking();
          _stopSocketListening(emitOffline: true);
          SocketService.instance.disconnect();
          notifyListeners();
        }
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseBody['message'] ?? 'Status updated successfully')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseBody['message'] ?? 'Failed to update status')),
          );
        }
      }
    } on TimeoutException catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server is taking too long to respond. Please check your internet or try again.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Please try again later.')),
        );
      }
    } finally {
      _isToggling = false;
      notifyListeners();
    }
  }

  Future<void> logout(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.grey900,
        title: const Text('Logout', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: AppColors.grey500)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.grey500)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('driver_token');
      await prefs.remove('driver_data');
      await prefs.remove('active_booking_ids');
      
      _stopLocationTracking();
      _stopSocketListening(emitOffline: true);
      _status = DriverStatus.offline;

      if (context.mounted) {
         Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
       print('Error during logout: $e');
    }
  }
  Future<void> acceptRide(BuildContext context) async {
    await _respondToRide(context, 'Accept');
  }

  Future<void> rejectRide(BuildContext context) async {
    await _respondToRide(context, 'Reject');
  }

  Future<void> _respondToRide(BuildContext context, String action) async {
    if (_currentRequest == null || _isToggling) return;
    
    _isToggling = true;
    _stopRingtone();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token');
      if (token == null) throw Exception("No token");

      final url = '${ApiConstants.respondToRide}/${_currentRequest!.id}/respond';
      
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'action': action}),
      ).timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        if (action == 'Accept') {
          _activeRides.add(_currentRequest!);
          _selectedRideIndex = _activeRides.length - 1;
          _currentRequest = null;
          
          if (_activeRides.length > 1) {
            // Already in a shared ride
            // Keep status as whatever it currently is (rideStarted, etc.)
          } else {
            _status = DriverStatus.rideAccepted;
          }
          
          if (activeRide != null) {
             List<String> ids = _activeRides.map((r) => r.bookingId).toList();
             prefs.setStringList('active_booking_ids', ids);
             _fetchActiveRidesFromBackend();
          }
          _drawRouteForCurrentStatus();
          _startSocketListening(); // resume listening for shared rides
        } else {
          _currentRequest = null;
          if (_activeRides.isEmpty) {
            _status = DriverStatus.online;
          }
          _startSocketListening();
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(body['message'] ?? 'Failed to $action ride')),
          );
        }
        if (body['message'] != null && body['message'].toString().contains('no longer available')) {
          _currentRequest = null;
          if (_activeRides.isEmpty) {
            _status = DriverStatus.online;
          }
          _startSocketListening();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error while responding to ride.')),
        );
      }
    } finally {
      _isToggling = false;
      notifyListeners();
    }
  }

  void _startWaitingTimer() {
    _waitingTimer?.cancel();
    if (_arrivedAt == null) return;
    _waitingSeconds = DateTime.now().difference(_arrivedAt!).inSeconds;
    if (_waitingSeconds < 0) _waitingSeconds = 0;
    
    _waitingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_arrivedAt != null) {
        _waitingSeconds = DateTime.now().difference(_arrivedAt!).inSeconds;
        if (_waitingSeconds < 0) _waitingSeconds = 0;
        notifyListeners();
      }
    });
  }

  Future<bool> cancelTrip(String reason) async {
    if (activeRide == null) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token') ?? '';

      final url = ApiConstants.executeCancel.replaceAll(':bookingId', activeRide!.bookingId);
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"reason": reason}),
      );

      print('cancelTrip response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        _activeRides.removeWhere((r) => r.bookingId == activeRide!.bookingId);
        if (_activeRides.isEmpty) {
          _status = DriverStatus.online;
          prefs.remove('active_booking_ids');
          _waitingTimer?.cancel();
          _arrivedAt = null;
          _polylines.clear();
        } else {
          _selectedRideIndex = 0;
          List<String> ids = _activeRides.map((r) => r.bookingId).toList();
          prefs.setStringList('active_booking_ids', ids);
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('cancelTrip error: $e');
      return false;
    }
  }

  void startRide() {
    _status = DriverStatus.rideStarted;
    _drawRouteForCurrentStatus();
    notifyListeners();
  }

  Future<bool> markArrived() async {
    if (activeRide == null) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token') ?? '';

      final url = ApiConstants.executeArrived.replaceAll(':bookingId', activeRide!.bookingId);
      print('Calling API: PUT $url');
      final response = await http.put(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('markArrived response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        activeRide!.bookingStatus = 'Arrived';
        if (data['arrivedAt'] != null) {
          activeRide!.tripData['arrivedAt'] = data['arrivedAt'];
          // Use local time instead of server time to avoid clock sync issues jumping the timer
          _arrivedAt = DateTime.now();
          _startWaitingTimer();
        }
        _status = DriverStatus.driverArrived;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('markArrived error: $e');
      return false;
    }
  }

  Future<bool> startRideWithOtp(String otp) async {
    if (activeRide == null) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token') ?? '';

      final url = ApiConstants.executeStart.replaceAll(':bookingId', activeRide!.bookingId);
      print('Calling API: PUT $url with OTP: $otp');
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"otp": otp}),
      );

      print('startRideWithOtp response: ${response.statusCode} - ${response.body}');
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        activeRide!.bookingStatus = 'Ongoing';
        startRide();
        return true;
      }
      return false;
    } catch (e) {
      print('startRideWithOtp error: $e');
      return false;
    }
  }

  Future<bool> markStopArrived(int stopIndex) async {
    if (activeRide == null) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token') ?? '';

      final url = ApiConstants.executeStopArrived
          .replaceAll(':bookingId', activeRide!.bookingId)
          .replaceAll(':stopIndex', stopIndex.toString());
      
      print('Calling API: PUT $url');
      final response = await http.put(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('markStopArrived response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        activeRide!.stops[stopIndex] = RideStop(
          id: activeRide!.stops[stopIndex].id,
          address: activeRide!.stops[stopIndex].address,
          latitude: activeRide!.stops[stopIndex].latitude,
          longitude: activeRide!.stops[stopIndex].longitude,
          status: 'Arrived',
        );
        _waitingSeconds = 0;
        _arrivedAt = DateTime.now();
        _startWaitingTimer();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('markStopArrived error: $e');
      return false;
    }
  }

  Future<bool> completeStop(int stopIndex) async {
    if (activeRide == null) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token') ?? '';

      final url = ApiConstants.executeStopComplete
          .replaceAll(':bookingId', activeRide!.bookingId)
          .replaceAll(':stopIndex', stopIndex.toString());
      
      print('Calling API: PUT $url');
      final response = await http.put(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('completeStop response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        activeRide!.stops[stopIndex] = RideStop(
          id: activeRide!.stops[stopIndex].id,
          address: activeRide!.stops[stopIndex].address,
          latitude: activeRide!.stops[stopIndex].latitude,
          longitude: activeRide!.stops[stopIndex].longitude,
          status: 'Completed',
        );
        _waitingTimer?.cancel();
        _arrivedAt = null;
        _waitingSeconds = 0;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('completeStop error: $e');
      return false;
    }
  }

  Future<bool> initiateTripCompletion() async {
    if (activeRide == null) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token') ?? '';

      final url = ApiConstants.initiateCompletion.replaceAll(':bookingId', activeRide!.bookingId);
      print('Calling API: POST $url');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('initiateTripCompletion response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        _isWaitingForPayment = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('initiateTripCompletion error: $e');
      return false;
    }
  }

  Future<bool> confirmCashCollection() async {
    if (activeRide == null) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token') ?? '';

      final url = ApiConstants.confirmCash.replaceAll(':bookingId', activeRide!.bookingId);
      print('Calling API: POST $url');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('confirmCashCollection response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        _isWaitingForCash = false;
        _isWaitingForPayment = false;
        
        _lastCompletedRide = activeRide;
        _activeRides.removeWhere((r) => r.bookingId == activeRide!.bookingId);
        if (_activeRides.isEmpty) {
          _status = DriverStatus.rideCompleted;
        } else {
          _polylines.clear();
          _currentRoutePoints.clear();
        }
        _selectedRideIndex = 0;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('confirmCashCollection error: $e');
      return false;
    }
  }

  void resetPaymentState() {
    _isWaitingForPayment = false;
    _isWaitingForCash = false;
    notifyListeners();
  }

  void handlePaymentSuccessLocally() {
    if (activeRide != null) {
      _lastCompletedRide = activeRide;
      _activeRides.removeWhere((r) => r.bookingId == activeRide!.bookingId);
      if (_activeRides.isEmpty) {
        _status = DriverStatus.rideCompleted;
      } else {
        _polylines.clear();
        _currentRoutePoints.clear();
      }
      _selectedRideIndex = 0;
      _fetchTodayStats();
      notifyListeners();
    }
  }

  Future<bool> submitRating(String bookingId, int rating, {String message = ''}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token') ?? '';

      final url = ApiConstants.rateUser.replaceAll(':bookingId', bookingId);
      print('Calling API: POST $url with rating: $rating, message: $message');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({"rating": rating, "review": message}),
      );
      
      print('submitRating response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      print('submitRating error: $e');
      return false;
    }
  }

  Future<void> resetAfterComplete() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('active_booking_ids');
    _activeRides.clear();
    _lastCompletedRide = null;
    _status = DriverStatus.online;
    _polylines.clear();
    _currentRoutePoints.clear();
    _fetchTodayStats();
    notifyListeners();
    _startSocketListening();
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _stopLocationTracking();
    _stopSocketListening();
    _animationTimer?.cancel();
    _waitingTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _drawRouteForCurrentStatus({bool isRerouting = false}) async {
    if (activeRide == null || _currentPosition == null) return;
    
    LatLng origin;
    LatLng destination;

    if (_status == DriverStatus.rideAccepted || _status == DriverStatus.driverArrived) {
      // Driver to Pickup
      origin = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      destination = LatLng(activeRide!.pickupLat, activeRide!.pickupLng);
    } else if (_status == DriverStatus.rideStarted) {
      // Driver to Drop
      origin = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      destination = LatLng(activeRide!.dropLat, activeRide!.dropLng);
    } else {
      return;
    }

    // fallback straight line just in case API fails
    List<LatLng> polylineCoordinates = [origin, destination];

    try {
      List<PolylineWayPoint> waypoints = [];
      if (_status == DriverStatus.rideStarted && activeRide!.stops.isNotEmpty) {
        waypoints = activeRide!.stops
            .where((s) => s.status == 'Pending')
            .map((s) => PolylineWayPoint(location: '${s.latitude},${s.longitude}'))
            .toList();
      }

      PolylineResult result = await _polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
          wayPoints: waypoints,
        ),
      );

      if (result.points.isNotEmpty) {
        polylineCoordinates = result.points.map((point) => LatLng(point.latitude, point.longitude)).toList();
      }
    } catch (e) {
      // ignore
    }

    _polylines.clear();
    _currentRoutePoints = polylineCoordinates;
    _polylines.add(
      Polyline(
        polylineId: PolylineId('route_${DateTime.now().millisecondsSinceEpoch}'),
        color: AppColors.yellow,
        width: 5,
        points: polylineCoordinates,
      ),
    );
    notifyListeners();
    
    // Zoom to fit bounds
    _fitRouteToBounds(origin, destination);
  }

  void _updateRouteDynamic() {
    if (_currentPosition == null || _currentRoutePoints.isEmpty) return;
    
    // Reroute checking debounce (min 10 seconds between API calls to save costs)
    if (_lastRerouteTime != null && DateTime.now().difference(_lastRerouteTime!).inSeconds < 10) {
      return;
    }

    // Find distance to the closest point on the current route
    double minDistance = double.infinity;
    for (var point in _currentRoutePoints) {
      double dist = Geolocator.distanceBetween(
        _currentPosition!.latitude, _currentPosition!.longitude,
        point.latitude, point.longitude
      );
      if (dist < minDistance) {
        minDistance = dist;
      }
    }

    // If driver is more than 30 meters off the route, recalculate
    if (minDistance > 30) {
      _lastRerouteTime = DateTime.now();
      _drawRouteForCurrentStatus(isRerouting: true);
    }
  }

  void _fitRouteToBounds(LatLng origin, LatLng destination) {
    if (_mapController == null) return;
    
    double minLat = origin.latitude < destination.latitude ? origin.latitude : destination.latitude;
    double maxLat = origin.latitude > destination.latitude ? origin.latitude : destination.latitude;
    double minLng = origin.longitude < destination.longitude ? origin.longitude : destination.longitude;
    double maxLng = origin.longitude > destination.longitude ? origin.longitude : destination.longitude;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50.0, // padding
      ),
    );
  }

  Future<void> openGoogleMapsForNavigation() async {
    if (_currentPosition == null) return;
    
    double lat = _currentPosition!.latitude;
    double lng = _currentPosition!.longitude;
    
    if (activeRide != null) {
      if (_status == DriverStatus.rideAccepted || _status == DriverStatus.driverArrived) {
        lat = activeRide!.pickupLat;
        lng = activeRide!.pickupLng;
      } else if (_status == DriverStatus.rideStarted) {
        lat = activeRide!.dropLat;
        lng = activeRide!.dropLng;
      }
    }
    
    final url = Uri.parse('google.navigation:q=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      final webUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    }
  }
}
