import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddressPickerPage extends StatefulWidget {
  final LatLng initialLocation;
  const AddressPickerPage({super.key, required this.initialLocation});

  @override
  State<AddressPickerPage> createState() => _AddressPickerPageState();
}

class _AddressPickerPageState extends State<AddressPickerPage> {
  late LatLng selectedLocation;
  TextEditingController searchController = TextEditingController();
  List<dynamic> suggestions = [];
  final String apiKey =
      'AIzaSyBc2xx1XkgZKPcrrQl5HVGMZv_xSfdMxXQ'; // Replace with your API key

  @override
  void initState() {
    super.initState();
    selectedLocation = widget.initialLocation;
  }

  Future<void> fetchSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() => suggestions = []);
      return;
    }
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey&components=country:bd';
    final response = await http.get(Uri.parse(url));
    print('Autocomplete response: ${response.body}'); // Debug print
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        setState(() {
          suggestions = data['predictions'];
        });
      } else {
        print('Google Places API error: ${data['status']}');
        setState(() {
          suggestions = [];
        });
      }
    } else {
      print('HTTP error: ${response.statusCode}');
      setState(() {
        suggestions = [];
      });
    }
  }

  Future<void> fetchPlaceDetails(String placeId) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final location = data['result']['geometry']['location'];
      setState(() {
        selectedLocation = LatLng(location['lat'], location['lng']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Address")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: "Enter your address",
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (text) => fetchSuggestions(text),
            ),
          ),
          // Suggestions list below the TextField
          if (suggestions.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  return ListTile(
                    title: Text(suggestion['description']),
                    onTap: () async {
                      searchController.text = suggestion['description'];
                      await fetchPlaceDetails(suggestion['place_id']);
                      setState(() {
                        suggestions = [];
                      });
                    },
                  );
                },
              ),
            ),
          Expanded(
            flex: 2,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: selectedLocation,
                zoom: 17.0,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId("selected"),
                  position: selectedLocation,
                ),
              },
              onTap: (LatLng pos) {
                setState(() {
                  selectedLocation = pos;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              child: const Text("Confirm"),
              onPressed: () {
                Navigator.pop(context, selectedLocation);
              },
            ),
          ),
        ],
      ),
    );
  }
}
