import 'package:drugscript/homepage.dart';
import 'package:drugscript/medicine_search.dart';
import 'package:drugscript/profile.dart';
import 'package:drugscript/wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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


      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),

      initialRoute: '/',

      routes: {
        '/': (context) => Wrapper(),
        '/homePage': (context) => HomePage(),
        '/medicineSearch': (context) => const MedicineSearchApp(),
        '/profilePage': (context) => const Profile(),
      },
    );
  }
}
