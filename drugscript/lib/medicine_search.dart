import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MedicineSearchApp extends StatefulWidget {
  const MedicineSearchApp({super.key});
  @override
  State<MedicineSearchApp> createState() => _MedicineSearchAppState();
}

class _MedicineSearchAppState extends State<MedicineSearchApp> {
  // State variables
  List<dynamic> searchResults = [];
  bool isLoading = false;
  
  // Search function
  Future<void> sendSearchToPython(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://0.0.0.0:5000/search'),  // Use your IP or hostname
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          searchResults = data['results'];
          isLoading = false;
        });
      } else {
        setState(() {
          searchResults = [];
          isLoading = false;
        });
        print('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        searchResults = [];
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 255, 255, 255), // Light blue 100
              Color(0xFFE1F5FE), // Light blue 100
              Color.fromARGB(255, 255, 255, 255), // Light blue 100
              Color(0xFFE1F5FE), // Light blue 100
              Color.fromARGB(255, 255, 255, 255), // Light blue 100
            ],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 50.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search Medicines',
                      hintText: 'Enter medicine name or generic name',
                      prefixIcon: Icon(Icons.search, color: Colors.blue),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    onChanged: (value) {
                      sendSearchToPython(value);
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            isLoading 
              ? Center(child: CircularProgressIndicator()) 
              : Expanded(
                  child: searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 80, color: Colors.blue.withOpacity(0.5)),
                            SizedBox(height: 16),
                            Text(
                              'Search for medicines',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final medicine = searchResults[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 6),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(12),
                              title: Text(
                                medicine['medicine_name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text('${medicine['generic_name']} ${medicine['strength']}'),
                                  SizedBox(height: 2),
                                  Text(
                                    'Manufacturer: ${medicine['manufacturer_name']}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                '৳${medicine['price']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              onTap: () {
                                // You can navigate to a detail page here
                              },
                            ),
                          );
                        },
                      ),
                ),
          ],
        ),
      ),
    );
  }
}