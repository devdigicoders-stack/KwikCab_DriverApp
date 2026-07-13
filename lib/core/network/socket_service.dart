import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
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
      if (data != null && data is Map<String, dynamic>) {
        _newRideRequestController.add(data);
      }
    });

    _socket!.on('booking_update', (data) {
      debugPrint('Received booking update via socket: $data');
      if (data != null && data is Map<String, dynamic>) {
        _bookingUpdateController.add(data);
      }
    });

    _socket!.on('ride_request_timeout', (data) {
      debugPrint('Received ride request timeout via socket: $data');
      if (data != null && data is Map<String, dynamic>) {
        _rideRequestTimeoutController.add(data);
      }
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
