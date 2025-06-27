import 'package:drugscript/screens/homepage.dart';
import 'package:drugscript/screens/add_prescription.dart';
import 'package:drugscript/screens/medicine_search.dart';
import 'package:drugscript/screens/profile.dart';
import 'package:drugscript/screens/view_prescriptions.dart';
import 'package:drugscript/screens/wrapper.dart';
import 'package:drugscript/screens/report.dart';
import 'package:drugscript/screens/prescription_details.dart';
import 'package:drugscript/theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        '/': (context) => const Wrapper(),
        '/homePage': (context) => const HomePage(),
        '/medicineSearch': (context) => const MedicineSearchApp(),
        '/profilePage': (context) => const Profile(),
        '/createPrescription': (context) => const AddPrescription(),
        '/report': (context) => const Report(),
        '/viewPrescriptions': (context) => const ViewPrescription(),
        '/prescriptionDetails': (context) => PrescriptionDetails(prescriptionId: ModalRoute.of(context)?.settings.arguments as String,),
      },
    );
  }
}
