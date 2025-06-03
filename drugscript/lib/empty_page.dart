import 'package:flutter/material.dart';

class EmptyPage extends StatelessWidget {
  const EmptyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0),
          child: ElevatedButton(
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
          ),
        ),
      ),
    );
  }
}
