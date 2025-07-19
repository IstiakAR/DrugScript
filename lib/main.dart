import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

// Local Notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Screens
import 'package:drugscript/screens/homepage.dart';
import 'package:drugscript/screens/add_prescription.dart';
import 'package:drugscript/screens/medicine_search.dart';
import 'package:drugscript/screens/profile.dart';
import 'package:drugscript/screens/review_page.dart';
import 'package:drugscript/screens/view_prescriptions.dart';
import 'package:drugscript/screens/wrapper.dart';
import 'package:drugscript/screens/report.dart';
import 'package:drugscript/screens/prescription_details.dart';
import 'package:drugscript/screens/splash_screen.dart';
import 'package:drugscript/screens/scan_qr_page.dart';
import 'package:drugscript/screens/sharing_history.dart';
import 'package:drugscript/screens/chat_page.dart';
import 'package:drugscript/screens/reminder_page.dart';
import 'package:drugscript/screens/ambulance_services_page.dart';
import 'package:drugscript/screens/medicine_delivery_hub.dart';

import 'package:drugscript/theme/app_theme.dart';

/// Global notification plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preload SVG assets
  final loader = SvgAssetLoader('assets/logo.svg');
  await svg.cache.putIfAbsent(
    loader.cacheKey(null),
    () => loader.loadBytes(null),
  );

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Local Notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/logo1');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'DrugScript',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/profilePage') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (_) => Profile(userId: args?['userId']),
          );
        }
        if (settings.name == '/prescriptionDetails') {
          final prescriptionId = settings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => PrescriptionDetails(prescriptionId: prescriptionId),
          );
        }

        // Handle other routes
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/wrapper':
            return MaterialPageRoute(builder: (_) => const Wrapper());
          case '/homePage':
            return MaterialPageRoute(builder: (_) => const HomePage());
          case '/medicineSearch':
            return MaterialPageRoute(builder: (_) => const MedicineSearchApp());
          case '/createPrescription':
            return MaterialPageRoute(builder: (_) => const AddPrescription());
          case '/report':
            return MaterialPageRoute(builder: (_) => const Report());
          case '/viewPrescriptions':
            return MaterialPageRoute(builder: (_) => const ViewPrescription());
          case '/scanQrPage':
            return MaterialPageRoute(builder: (_) => const ScanQrPage());
          case '/sharingHistory':
            return MaterialPageRoute(builder: (_) => const SharingHistory());
          case '/chatPage':
            return MaterialPageRoute(builder: (_) => const ChatPage());
          case '/reviews':
            return MaterialPageRoute(builder: (_) => const ReviewHomePage());
          case '/reminder':
            return MaterialPageRoute(builder: (_) => const ReminderPage());
          case '/medicineDelivery':
            final currentAddress =
                settings.arguments as String? ?? "Tap to select location";
            return MaterialPageRoute(
              builder:
                  (_) => MedicineDeliveryHub(currentAddress: currentAddress),
            );
          case '/ambulanceServices':
            final currentAddress =
                settings.arguments as String? ?? "Tap to select location";
            return MaterialPageRoute(
              builder:
                  (_) => AmbulanceServicesPage(currentAddress: currentAddress),
            );
        }
        return null;
      },
    );
  }
}
