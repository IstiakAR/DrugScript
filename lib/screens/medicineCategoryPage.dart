import 'package:flutter/material.dart';

class MedicineCategoryPage extends StatelessWidget {
  const MedicineCategoryPage({super.key});

  final List<Map<String, String>> diseaseCategories = const [
    {'disease': 'Fever', 'image': 'assets/fever.png'},
    {'disease': 'Cold & Cough', 'image': 'assets/cold.png'},
    {'disease': 'Diabetes', 'image': 'assets/diabetes.png'},
    {'disease': 'Blood Pressure', 'image': 'assets/bp.png'},
    {'disease': 'Pain Relief', 'image': 'assets/pain.png'},
    {'disease': 'Skin Care', 'image': 'assets/skin.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Disease Categories"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        itemCount: diseaseCategories.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // Navigate to specific medicine list if needed
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    diseaseCategories[index]['image']!,
                    height: 70,
                    width: 70,
                  ),
                  SizedBox(height: 10),
                  Text(
                    diseaseCategories[index]['disease']!,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
