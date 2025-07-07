import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'package:sh/screens/admin/admin_dashboard_screen.dart';
import 'package:sh/screens/dashboard/client_dashboard.dart';
import 'package:sh/screens/dashboard/professional_dashboard.dart';
import 'package:sh/screens/help_support_screen.dart';
import 'package:sh/screens/professional/find_projects_screen.dart';
import 'package:sh/screens/settings_screen.dart';
import 'package:sh/screens/splash_screen.dart';
import 'package:sh/screens/onboarding_screen.dart';
import 'package:sh/screens/auth/login_screen.dart';
import 'package:sh/screens/auth/register_screen.dart';
import 'package:sh/screens/client/post_project_screen.dart';
import 'package:sh/screens/client/find_professionals_screen.dart';

// Background Message Handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔔 Handling background message: ${message.messageId}");
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print("✅ Notifications Permission Granted");
  } else {
    print("❌ Notifications Permission Denied");
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  String? token = await messaging.getToken();
  print("📱 Device FCM Token: $token");

  var androidInitSettings =
      const AndroidInitializationSettings('@mipmap/ic_launcher');
  var iOSInitSettings = const DarwinInitializationSettings();
  var initSettings = InitializationSettings(
      android: androidInitSettings, iOS: iOSInitSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  runApp(const SkillHubApp());
}

class SkillHubApp extends StatefulWidget {
  const SkillHubApp({super.key});

  @override
  State<SkillHubApp> createState() => _SkillHubAppState();
}

class _SkillHubAppState extends State<SkillHubApp> {
  @override
  void initState() {
    super.initState();
    _setupForegroundNotificationListener();
  }

  void _setupForegroundNotificationListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Received foreground message: ${message.notification?.title}");
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'default_channel',
      'General Notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? "New Notification",
      message.notification?.body ?? "You have a new message",
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SkillHub',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
      // SplashScreen handles routing logic
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/client_dashboard': (context) => const ClientDashboard(),
        '/professional_dashboard': (context) => const ProfessionalDashboard(),
        '/admin_dashboard_screen': (context) => const AdminDashboardScreen(),
        '/post_project': (context) => const PostProjectScreen(),
        '/find_professionals': (context) => const FindProfessionalsScreen(),
        '/find_project': (context) => const FindProjectsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/help': (context) => const HelpSupportScreen(),
      },
    );
  }
}
