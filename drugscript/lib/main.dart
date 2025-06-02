import 'package:flutter/material.dart';
import 'medicine_search.dart';
import 'login_page.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DrugScript',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/loginPage',
      routes: {
        '/loginPage' : (context) => const LoginPage(),
        '/homePage': (context) => const HomePage(),
        '/medicineSearch': (context) => const MedicineSearchApp(),
      },
    );
  }
}
