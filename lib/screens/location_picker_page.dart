import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:drugscript/screens/address_picker_page.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  GoogleMapController? mapController;
  LatLng selectedLocation = const LatLng(
    23.733348,
    90.392481,
  ); // Default location
  TextEditingController searchController = TextEditingController();

  final List<Map<String, String>> savedAddresses = [
    {
      "title": "অমর একুশে হল, ঢাকা বিশ্ববিদ্যালয়",
      "address": "Secretariat Road, Dhaka",
    },
    {"title": "Shahabuddin road", "address": "Dhaka"},
    {"title": "7Q Shahbagh Road", "address": "Dhaka"},
  ];

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _confirmSelection() {
    final title =
        savedAddresses.isNotEmpty && savedAddresses[0]["title"] != null
            ? savedAddresses[0]["title"]
            : "Unknown Location";
    Navigator.pop(context, title);
  }

  void _searchAddress() {
    final query = searchController.text;
    // Simulate searching for the address (you can implement real search functionality)
    if (query.isNotEmpty) {
      setState(() {
        selectedLocation = LatLng(
          23.8103,
          90.4125,
        ); // Example coordinates (could be replaced)
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Delivery Location")),
      body: Column(
        children: [
          // Option to pick address by searching
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: "Enter your address",
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (text) => _searchAddress(),
            ),
          ),
          // Option to select location on map
          Expanded(
            flex: 2,
            child: GoogleMap(
              onMapCreated: _onMapCreated,
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
          // List of saved addresses
          Expanded(
            flex: 2,
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.my_location),
                  title: const Text("Use my current location"),
                  onTap: _confirmSelection,
                ),
                for (var address in savedAddresses)
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(address["title"]!),
                    subtitle: Text(address["address"]!),
                    trailing: const Icon(Icons.edit),
                    onTap: () => Navigator.pop(context, address["title"]),
                  ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text("Add New Address"),
                  onTap: () async {
                    LatLng? newLocation = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => AddressPickerPage(
                              initialLocation: selectedLocation,
                            ),
                      ),
                    );
                    if (newLocation != null) {
                      setState(() {
                        selectedLocation = newLocation;
                        savedAddresses.add({
                          "title": "Custom Location",
                          "address":
                              "${newLocation.latitude}, ${newLocation.longitude}",
                        });
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
