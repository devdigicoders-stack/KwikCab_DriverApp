import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:kwikcabdriver/main.dart';
import 'package:kwikcabdriver/routes/app_routes.dart';
import 'api_constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  static SocketService get instance => _instance;

  IO.Socket? _socket;
  bool _isInitialized = false;

  final _newRideRequestController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNewRideRequest => _newRideRequestController.stream;

  final _bookingUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onBookingUpdate => _bookingUpdateController.stream;

  final _rideRequestTimeoutController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onRideRequestTimeout => _rideRequestTimeoutController.stream;

  final _newAgentLeadController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNewAgentLead => _newAgentLeadController.stream;

  final _newFixedPackageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNewFixedPackage => _newFixedPackageController.stream;

  final _fixedPackagePaymentVerifiedController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onFixedPackagePaymentVerified => _fixedPackagePaymentVerifiedController.stream;

  final _collectCashController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onCollectCash => _collectCashController.stream;

  SocketService._internal();

  void initSocket(String driverId, String role) {
    if (_socket != null) {
      if (!_socket!.connected) {
        debugPrint('Socket reconnecting...');
        _socket!.connect();
      } else {
        debugPrint('Socket already initialized and connected.');
      }
      return;
    }

    _socket = IO.io(ApiConstants.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.onConnect((_) {
      debugPrint('Socket connected. Joining room for driver: $driverId');
      _socket!.emit('join_room', {
        'userId': driverId,
        'role': role,
      });
    });

    _socket!.onDisconnect((_) {
      debugPrint('Socket disconnected.');
    });

    _socket!.onError((error) {
      debugPrint('Socket error: $error');
    });

    _socket!.on('new_ride_request', (data) {
      debugPrint('Received new ride request via socket: $data');
      if (data != null && data is Map) {
        _newRideRequestController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('booking_update', (data) {
      debugPrint('Received booking update via socket: $data');
      if (data != null && data is Map) {
        _bookingUpdateController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('ride_request_timeout', (data) {
      debugPrint('Received ride request timeout via socket: $data');
      if (data != null && data is Map) {
        _rideRequestTimeoutController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('new_agent_lead', (data) {
      debugPrint('Received new agent lead via socket: $data');
      if (data != null && data is Map) {
        _newAgentLeadController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('new_fixed_package', (data) {
      debugPrint('Received new fixed package via socket: $data');
      if (data != null && data is Map) {
        _newFixedPackageController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('fixed_package_payment_verified', (data) {
      debugPrint('Received fixed_package_payment_verified via socket: $data');
      if (data != null && data is Map) {
        _fixedPackagePaymentVerifiedController.add(Map<String, dynamic>.from(data));
      }
    });

    // Also listen for the actual backend event name
    _socket!.on('fixedBookingPaymentSuccess', (data) {
      debugPrint('Received fixedBookingPaymentSuccess via socket: $data');
      if (data != null && data is Map) {
        _fixedPackagePaymentVerifiedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('collect_cash', (data) {
      debugPrint('==============================');
      debugPrint('Socket EVENT: collect_cash');
      debugPrint('Raw Data: $data');
      debugPrint('Raw Data Type: ${data.runtimeType}');
      
      if (data != null) {
        try {
          final Map<String, dynamic> mappedData = Map<String, dynamic>.from(data);
          debugPrint('Successfully cast to Map<String, dynamic>');
          _collectCashController.sink.add(mappedData);
          debugPrint('Added to _collectCashController sink!');
          debugPrint('Stream hasListener? ${_collectCashController.hasListener}');
        } catch (e) {
          debugPrint('Error mapping collect_cash data: $e');
        }
      } else {
        debugPrint('collect_cash data is NULL!');
      }
      debugPrint('==============================');
    });

    _socket!.on('force_logout', (data) async {
      debugPrint('Received force_logout via socket: $data');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('driver_token');
      await prefs.remove('driver_isLoggedIn');
      
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Logged in from another device.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    });

    _socket!.connect();
    _isInitialized = true;
  }

  void driverOnline(String driverId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('driver_online', {'driverId': driverId});
      debugPrint('Emitted driver_online');
    }
  }

  void driverOffline(String driverId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('driver_offline', {'driverId': driverId});
      debugPrint('Emitted driver_offline');
    }
  }

  void updateLocation(String driverId, double latitude, double longitude, double heading) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('update_location', {
        'driverId': driverId,
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
      });
      // debugPrint('Emitted update_location'); // Commented to reduce log spam
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isInitialized = false;
    }
  }
}
