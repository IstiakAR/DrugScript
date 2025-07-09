// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'medicine_detail.dart';

class MedicineSearchApp extends StatefulWidget {
  // Add a new parameter to indicate selection mode
  final bool selectionMode;
  
  const MedicineSearchApp({
    super.key,
    this.selectionMode = false, // Default to normal mode (not selection)
  });
  
  @override
  State<MedicineSearchApp> createState() => _MedicineSearchAppState();
}

class _MedicineSearchAppState extends State<MedicineSearchApp> {
  // Rest of your state variables and functions...
  List<dynamic> searchResults = [];
  bool isLoading = false;

  // Search function
  Future<void> sendSearchToPython(String query) async {

    if (query.isEmpty) {
      print('Search query is empty');
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
      appBar: widget.selectionMode ? AppBar(
        title: const Text("Select Medicine"),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ) : null,
      body: SafeArea(
        child: Column(
          children: [
      
      
            if (!widget.selectionMode) // Show this only in regular mode
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 15.0, top: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color.fromARGB(255, 47, 47, 49),
                        size: 25,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      elevation: 10,
                    ),
                  ),
                  Expanded(
                    child: _buildSearchField(),
                  ),
                ],
              ),
            ),
      
      
            if (widget.selectionMode) // Different layout for selection mode
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSearchField(),
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
                                  color: Color.fromARGB(255, 64, 55, 124).withOpacity(0.5),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  widget.selectionMode
                                      ? 'Search for medicines to add'
                                      : 'Search for medicines',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color.fromARGB(255, 64, 55, 124),
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
                                elevation: 1,
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
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '৳${medicine['price']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                      if (widget.selectionMode)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8.0),
                                          child: Icon(
                                            Icons.add_circle_outline,
                                            color: Colors.green,
                                          ),
                                        ),
                                    ],
                                  ),
      
                                  onTap: () {
                                    if (widget.selectionMode) {
                                      // Return the medicine to the prescription screen
                                      Navigator.pop(context, medicine);
                                    } else {
                                      // Navigate to medicine details
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MedicineDetailPage(
                                            medicine: medicine,
                                          ),
                                        ),
                                      );
                                    }
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

  // Extracted widget for better organization
  Widget _buildSearchField() {
    return Card(
      elevation: 0.1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 0,
          vertical: 0,
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: widget.selectionMode ? 'Search medicine to add' : 'Enter medicine name',
            prefixIcon: Icon(Icons.search, color: Color.fromARGB(255, 47, 47, 49)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: const Color.fromARGB(255, 47, 47, 49), width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(color: Colors.blue, width: 0.8),
            ),
            hintStyle: TextStyle(color: const Color.fromARGB(255, 138, 138, 138)),
            contentPadding: EdgeInsets.all(0),
          ),
          onChanged: (value) {
            print('Search query: $value');
            sendSearchToPython(value);
          },
        ),
      ),
    );
  }
}