import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:kwikcabdriver/core/network/app_http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'routes/route_generator.dart';
import 'core/network/api_constants.dart';


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// ─── Notification Channel IDs ───────────────────────────────────────────────
const String _rideChannelId   = 'kwikcab_ride_request';
const String _rideChannelName = 'New Ride Requests';
const String _generalChannelId   = 'kwikcab_driver_channel_high';
const String _generalChannelName = 'KwikCab Notifications';

// ─── Action IDs ─────────────────────────────────────────────────────────────
const String _actionAccept = 'ACCEPT_RIDE';
const String _actionReject = 'REJECT_RIDE';

// ─── Background/terminated action handler (top-level, required) ─────────────
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  final actionId  = notificationResponse.actionId;
  final payload   = notificationResponse.payload ?? '';
  if (payload.isEmpty) return;

  try {
    final data      = jsonDecode(payload) as Map<String, dynamic>;
    final bookingId = data['bookingId'] as String? ?? '';
    final requestId = data['requestId'] as String? ?? '';
    if (bookingId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('driver_token') ?? '';
    if (token.isEmpty) return;

    if (actionId == _actionAccept) {
      final targetId = requestId.isNotEmpty ? requestId : bookingId;
      await http.put(
        Uri.parse('${ApiConstants.respondToRide}/$targetId/respond'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'action': 'Accept'}),
      );
    } else if (actionId == _actionReject) {
      final targetId = requestId.isNotEmpty ? requestId : bookingId;
      await http.put(
        Uri.parse('${ApiConstants.respondToRide}/$targetId/respond'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'action': 'Reject'}),
      );
    }
  } catch (e) {
    debugPrint('⚠️ [NOTIF-ACTION] Error: $e');
  }
}

/// ─── Show a new ride notification with full-screen + action buttons ──────────
Future<void> _showRideNotification({
  required Map<String, dynamic> data,
  required String title,
  required String body,
}) async {
  final bookingId = data['bookingId'] ?? '';
  final pickup    = data['pickup']    ?? '';
  final drop      = data['drop']      ?? '';
  final fare      = data['fare']      ?? '';
  final distance  = data['distance']  ?? '';
  final requestId = data['requestId'] ?? '';

  // Build a richer body string with emojis
  final richBody = [
    if (fare.isNotEmpty) '💰 Fare: ₹$fare',
    if (distance.isNotEmpty) '📏 Distance: ${distance}km',
    if (pickup.isNotEmpty) '🟢 Pickup: $pickup',
    if (drop.isNotEmpty) '🔴 Drop: $drop',
  ].join('\n\n'); // Use double newline for better spacing in BigTextStyle

  final payloadMap = {'bookingId': bookingId, 'requestId': requestId};

  final androidDetails = AndroidNotificationDetails(
    _rideChannelId,
    _rideChannelName,
    channelDescription: 'Incoming ride requests for drivers',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    enableVibration: true,
    // Loop vibration for urgency
    vibrationPattern: Int64List.fromList([0, 500, 300, 500, 300, 500]),
    fullScreenIntent: true,       // ← turns on screen like incoming call
    styleInformation: BigTextStyleInformation(
      richBody,
      contentTitle: '📍 $title',
      summaryText: 'New Ride Request',
    ),
    actions: const [
      AndroidNotificationAction(
        _actionAccept,
        '✅ Accept',
        showsUserInterface: false, // silent accept without opening app
        cancelNotification: true,
      ),
      AndroidNotificationAction(
        _actionReject,
        '❌ Reject',
        showsUserInterface: false, // silent reject without opening app
        cancelNotification: true,
      ),
    ],
  );

  await flutterLocalNotificationsPlugin.show(
    bookingId.hashCode,
    title,
    richBody,
    NotificationDetails(android: androidDetails),
    payload: jsonEncode(payloadMap),
  );
}

/// ─── Show a normal notification (non-ride) ──────────────────────────────────
Future<void> _showGeneralNotification({
  required String title,
  required String body,
  required int id,
  AndroidNotificationDetails? customDetails,
}) async {
  final androidDetails = customDetails ?? const AndroidNotificationDetails(
    _generalChannelId,
    _generalChannelName,
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );
  await flutterLocalNotificationsPlugin.show(
    id,
    title,
    body,
    NotificationDetails(android: androidDetails),
  );
}

/// ─── BACKGROUND MESSAGE HANDLER ─────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCGlmY-ior7xqv_-4PiQcs1CoePb7IDM90",
      appId: "1:335340683871:web:2755bd2b336f7c355bd1ea",
      messagingSenderId: "335340683871",
      projectId: "collegepanel-1027b",
      storageBucket: "collegepanel-1027b.firebasestorage.app",
    ),
  );

  const AndroidInitializationSettings init = AndroidInitializationSettings('@mipmap/ic_launcher');
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: init),
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  final data      = message.data;
  final type      = data['type'] ?? '';
  final rawTitle  = data['title']   ?? message.notification?.title ?? 'Notification';
  final rawBody   = data['body']    ?? message.notification?.body  ?? 'You have a new message';
  final emojiRx   = RegExp(r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])');
  final title     = rawTitle.replaceAll(emojiRx, '').trim();
  final body      = rawBody.replaceAll(emojiRx, '').trim();

  if (type == 'NEW_RIDE_REQUEST') {
    await _showRideNotification(data: data, title: title, body: body);
  } else {
    final imageUrl = data['mediaUrl'] ?? data['image'] ?? '';
    if (imageUrl.isNotEmpty) {
      try {
        final res   = await http.get(Uri.parse(imageUrl));
        final bytes = res.bodyBytes;
        await _showGeneralNotification(
          title: title, body: body, id: message.hashCode,
          customDetails: AndroidNotificationDetails(
            _generalChannelId, _generalChannelName,
            importance: Importance.max, priority: Priority.high,
            playSound: true, enableVibration: true,
            styleInformation: BigPictureStyleInformation(
              ByteArrayAndroidBitmap(bytes),
              contentTitle: title, summaryText: body,
            ),
          ),
        );
        return;
      } catch (_) {}
    }
    await _showGeneralNotification(title: title, body: body, id: message.hashCode);
  }
}

// ─── Globals ─────────────────────────────────────────────────────────────────
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCGlmY-ior7xqv_-4PiQcs1CoePb7IDM90",
      appId: "1:335340683871:web:2755bd2b336f7c355bd1ea",
      messagingSenderId: "335340683871",
      projectId: "collegepanel-1027b",
      storageBucket: "collegepanel-1027b.firebasestorage.app",
    ),
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(
    alert: true, badge: true, sound: true,
  );

  // ── Initialize local notifications ──────────────────────────────────────
  const AndroidInitializationSettings initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: initAndroid),
    onDidReceiveNotificationResponse: (NotificationResponse res) async {
      // Foreground tap on notification body → open app
      if (res.actionId == null && res.payload != null) {
        navigatorKey.currentState?.pushNamed(AppRoutes.home);
      }
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  // ── Create notification channels ────────────────────────────────────────
  final plugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  // Ride request channel – high importance so heads-up appears
  await plugin?.createNotificationChannel(const AndroidNotificationChannel(
    _rideChannelId,
    _rideChannelName,
    description: 'Incoming ride requests',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  ));
  // General channel
  await plugin?.createNotificationChannel(const AndroidNotificationChannel(
    _generalChannelId,
    _generalChannelName,
    description: 'General driver notifications',
    importance: Importance.high,
    playSound: true,
  ));

  // ── Foreground message listener ──────────────────────────────────────────
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    debugPrint('✅ [FCM FOREGROUND] Message received');
    final data     = message.data;
    final type     = data['type'] ?? '';
    final rawTitle = data['title']  ?? message.notification?.title ?? 'Notification';
    final rawBody  = data['body']   ?? message.notification?.body  ?? 'You have a new message';
    final emojiRx  = RegExp(r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])');
    final title    = rawTitle.replaceAll(emojiRx, '').trim();
    final body     = rawBody.replaceAll(emojiRx, '').trim();

    if (type == 'NEW_RIDE_REQUEST') {
      await _showRideNotification(data: data, title: title, body: body);
    } else {
      final imageUrl = data['mediaUrl'] ?? data['image'] ?? '';
      if (imageUrl.isNotEmpty) {
        try {
          final res   = await http.get(Uri.parse(imageUrl));
          final bytes = res.bodyBytes;
          await _showGeneralNotification(
            title: title, body: body, id: message.hashCode,
            customDetails: AndroidNotificationDetails(
              _generalChannelId, _generalChannelName,
              importance: Importance.max, priority: Priority.high,
              playSound: true, enableVibration: true,
              styleInformation: BigPictureStyleInformation(
                ByteArrayAndroidBitmap(bytes),
                contentTitle: title, summaryText: body,
              ),
            ),
          );
          return;
        } catch (_) {}
      }
      await _showGeneralNotification(title: title, body: body, id: message.hashCode);
    }
  });

  _updateFcmTokenOnAppStart();
  runApp(const KwikCabDriverApp());
}

Future<void> _updateFcmTokenOnAppStart() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('driver_token');
    if (token == null) return;
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;
    await http.put(
      Uri.parse(ApiConstants.updateFcmToken),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'fcmToken': fcmToken}),
    );
    debugPrint('✅ [FCM] Token updated automatically on app start');
  } catch (e) {
    debugPrint('⚠️ [FCM] Failed to update token: $e');
  }
}

class KwikCabDriverApp extends StatelessWidget {
  const KwikCabDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'KwikCab Driver',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}



