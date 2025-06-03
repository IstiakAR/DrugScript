import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/homePage');
                },
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                ),
                child: const Icon(Icons.arrow_back),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // Navigator.pushReplacementNamed(context, '/emptyPage');
                },
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                ),
                child: const Icon(Icons.settings, size: 24),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/loginPage');
                },
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                ),
                child: const Icon(Icons.logout, size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
