import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kwikcabdriver/core/network/app_http.dart' as http;
import '../../../../core/network/api_constants.dart';

class IncomingRideScreen extends StatefulWidget {
  final Map<String, dynamic> payload;

  const IncomingRideScreen({super.key, required this.payload});

  @override
  State<IncomingRideScreen> createState() => _IncomingRideScreenState();
}

class _IncomingRideScreenState extends State<IncomingRideScreen> {
  int _secondsLeft = 15;
  Timer? _timer;
  bool _isResponding = false;

  late String pickup;
  late String drop;
  late String distance;
  late String fare;
  late String bookingId;
  late String requestId;
  late String rideType;
  late String stopsCount;

  @override
  void initState() {
    super.initState();
    debugPrint('🛑 INCOMING RIDE SCREEN PAYLOAD: ${widget.payload}');
    pickup = _parseString(widget.payload['pickup'], 'Unknown Pickup');
    drop = _parseString(widget.payload['drop'], 'Unknown Drop');
    distance = _parseString(widget.payload['distance'], '0');
    fare = _parseString(widget.payload['fare'], '0');
    bookingId = _parseString(widget.payload['bookingId'], '');
    requestId = _parseString(widget.payload['requestId'], '');
    rideType = _parseString(widget.payload['rideType'], 'Private');
    stopsCount = _parseString(widget.payload['stopsCount'], '0');

    // Timer calculation based on expiresAt
    final expiresAtStr = widget.payload['expiresAt'];
    if (expiresAtStr != null && expiresAtStr.toString().isNotEmpty) {
      final expiresAt = int.tryParse(expiresAtStr.toString()) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final diff = ((expiresAt - now) / 1000).round();
      if (diff > 0) {
        _secondsLeft = diff;
      } else {
        _secondsLeft = 0;
      }
    }

    _startTimer();
  }

  String _parseString(dynamic value, String fallback) {
    if (value == null) return fallback;
    final str = value.toString();
    return str.isEmpty ? fallback : str;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _timer?.cancel();
        if (!_isResponding) {
          _respondToRide('Reject');
        }
      }
    });
  }

  Future<void> _respondToRide(String action) async {
    if (_isResponding) return;
    setState(() => _isResponding = true);
    _timer?.cancel();

    // Pop immediately for a fast, responsive UI
    if (mounted) {
      Navigator.pop(context);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('driver_token') ?? '';
      
      final targetId = requestId.isNotEmpty ? requestId : bookingId;
      if (targetId.isNotEmpty && token.isNotEmpty) {
        await http.put(
          Uri.parse('${ApiConstants.respondToRide}/$targetId/respond'),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
          body: jsonEncode({'action': action}),
        );
      }
    } catch (e) {
      debugPrint('Error responding to ride: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildDashedLine() {
    return Column(
      children: List.generate(
        4,
        (index) => Container(
          width: 2,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 2),
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2126), // Dark background matching mockup
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111315),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade800, width: 1),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Image.asset('assets/logo2.png', width: 40, height: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🚖 New Ride Request',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.yellow.shade800, borderRadius: BorderRadius.circular(4)),
                                    child: Text(rideType, style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  if (stopsCount != '0') ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.red.shade800, borderRadius: BorderRadius.circular(4)),
                                      child: Text('$stopsCount Stop(s)', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ]
                                ],
                              )
                            ],
                          ),
                        ),
                        const Text('now', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.grey, height: 1),
                    const SizedBox(height: 16),

                    // Route (Pickup/Drop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            const Icon(Icons.location_on, color: Colors.greenAccent, size: 28),
                            _buildDashedLine(),
                            const Icon(Icons.location_on, color: Colors.redAccent, size: 28),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('PICKUP', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(pickup, style: const TextStyle(color: Colors.white, fontSize: 14)),
                              const SizedBox(height: 16),
                              const Text('DROP', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(drop, style: const TextStyle(color: Colors.white, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.grey, height: 1),
                    const SizedBox(height: 16),

                    // Details (Distance & Fare)
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                                child: const Icon(Icons.add_road, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('DISTANCE', style: TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text('${distance} km', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.grey.shade800),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                child: const Icon(Icons.currency_rupee, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('FARE', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text('₹$fare', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.grey, height: 1),
                    const SizedBox(height: 16),

                    // Timer
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.amber, size: 28),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Accept within $_secondsLeft sec',
                              style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              'Request will expire automatically',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isResponding ? null : () => _respondToRide('Accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.check_circle, color: Colors.white),
                            label: const Text('ACCEPT', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isResponding ? null : () => _respondToRide('Reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.cancel, color: Colors.white),
                            label: const Text('REJECT', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
    );
  }
}
