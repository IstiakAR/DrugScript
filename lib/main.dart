import 'package:drugscript/screens/homepage.dart';
import 'package:drugscript/screens/add_prescription.dart';
import 'package:drugscript/screens/medicine_search.dart';
import 'package:drugscript/screens/profile.dart';
import 'package:drugscript/screens/view_prescriptions.dart';
import 'package:drugscript/screens/wrapper.dart';
import 'package:drugscript/screens/report.dart';
import 'package:drugscript/screens/prescription_details.dart';
import 'package:drugscript/theme/app_theme.dart';
import 'package:drugscript/screens/splash_screen.dart';
import 'package:drugscript/screens/scan_qr_page.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preload SVG assets
  final loader = SvgAssetLoader('assets/logo.svg');
  await svg.cache.putIfAbsent(loader.cacheKey(null), () => loader.loadBytes(null));

  await Firebase.initializeApp();
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
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Page Not Found')),
                body: const Center(child: Text('404 - Page Not Found')),
              ),
            );
        }
      },
    );
  }
}