import 'package:drugscript/screens/homepage.dart';
import 'package:drugscript/screens/add_prescription.dart';
import 'package:drugscript/screens/medicine_search.dart';
import 'package:drugscript/screens/profile.dart';
import 'package:drugscript/screens/view_prescriptions.dart';
import 'package:drugscript/screens/wrapper.dart';
import 'package:drugscript/screens/report.dart';
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
      routes: {
        '/': (context) => const SplashScreen(),  // Change this to SplashScreen
        '/wrapper': (context) => const Wrapper(),  // Add this route
        '/homePage': (context) => const HomePage(),
        '/medicineSearch': (context) => const MedicineSearchApp(),
        '/profilePage': (context) => const Profile(),
        '/createPrescription': (context) => const AddPrescription(),
        '/report': (context) => const Report(),
        '/viewPrescriptions': (context) => const ViewPrescription(),
        '/scanQrPage': (context) => const ScanQrPage(),
      },
    );
  }
}
