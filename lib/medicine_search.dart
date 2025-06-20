// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'medicine_detail.dart';

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
        Uri.parse('https://fastapi-app-production-6e30.up.railway.app/medicinesearch'),
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
              Color.fromARGB(255, 255, 255, 255),
              Color(0xFFE1F5FE),
              Color.fromARGB(255, 255, 255, 255),
              Color(0xFFE1F5FE),
              Color.fromARGB(255, 255, 255, 255),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 15.0, top: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.blue),
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/homePage');
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(12),
                        shape: const CircleBorder(),
                        elevation: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                        ),
                        child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter medicine name',
                          prefixIcon: Icon(Icons.search, color: Colors.blue),
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey),
                          contentPadding: EdgeInsets.all(12),
                        ),
                        onChanged: (value) {
                          sendSearchToPython(value);
                        },
                        ),
                      ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Expanded(
                    child:
                        searchResults.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: 80,
                                    color: Colors.blue.withOpacity(0.5),
                                  ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(height: 4),
                                        Text(
                                          '${medicine['generic_name']} ${medicine['strength']}',
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Manufacturer: ${medicine['manufacturer_name']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade700,
                                          ),
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
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MedicineDetailPage(
                                            medicine: medicine,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
