import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:kwikcabdriver/core/network/app_http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'routes/route_generator.dart';
import 'core/constants/app_colors.dart';
import 'core/network/api_constants.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

/// 🔔 BACKGROUND MESSAGE HANDLER
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

  final emojiRegex = RegExp(r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])');
  final rawTitle = message.notification?.title ?? message.data['title'] ?? 'Notification';
  final title = rawTitle.replaceAll(emojiRegex, '').trim();
  final rawBody = message.notification?.body ?? message.data['body'] ?? message.data['message'] ?? 'You have a new message';
  final body = rawBody.replaceAll(emojiRegex, '').trim();

  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'kwikcab_driver_channel_high',
    'KwikCab Notifications',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    title,
    body,
    platformChannelSpecifics,
  );
}

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase initialize karo using user app's exact keys
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
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    debugPrint('✅ [FCM FOREGROUND] Message received');
    
    // Backend sends data-only messages — read from data map
    final rawTitle = message.data['title'] ?? message.notification?.title ?? 'Notification';
    final rawBody = message.data['body'] ?? message.notification?.body ?? 'You have a new message';
    final imageUrl = message.data['mediaUrl'] ?? message.data['image'] ?? '';

    final emojiRegex = RegExp(r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])');
    final title = rawTitle.replaceAll(emojiRegex, '').trim();
    final body = rawBody.replaceAll(emojiRegex, '').trim();
    
    AndroidNotificationDetails androidDetails;

    if (imageUrl.isNotEmpty) {
      try {
        // Download image for BigPicture style
        final response = await http.get(Uri.parse(imageUrl));
        final bytes = response.bodyBytes;
        final bigPictureStyle = BigPictureStyleInformation(
          ByteArrayAndroidBitmap(bytes),
          contentTitle: title,
          summaryText: body,
        );
        androidDetails = AndroidNotificationDetails(
          'kwikcab_driver_channel_high',
          'KwikCab Notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          styleInformation: bigPictureStyle,
        );
      } catch (_) {
        // If image download fails, fall back to normal
        androidDetails = const AndroidNotificationDetails(
          'kwikcab_driver_channel_high',
          'KwikCab Notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        );
      }
    } else {
      androidDetails = const AndroidNotificationDetails(
        'kwikcab_driver_channel_high',
        'KwikCab Notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
    }

    final platformChannelSpecifics = NotificationDetails(android: androidDetails);
    flutterLocalNotificationsPlugin.show(
      message.hashCode,
      title,
      body,
      platformChannelSpecifics,
    );
  });

  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

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

    final url = Uri.parse(ApiConstants.updateFcmToken);
    await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'fcmToken': fcmToken}),
    );
    debugPrint('✅ [FCM] Token updated automatically on app start');
  } catch (e) {
    debugPrint('⚠️ [FCM] Failed to update token on app start: $e');
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
