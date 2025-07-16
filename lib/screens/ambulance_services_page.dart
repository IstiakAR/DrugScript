import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as user_location;
import 'package:geocoding/geocoding.dart'; // For reverse geocoding
import 'package:google_maps_webservice/places.dart';

class AmbulanceServicesPage extends StatefulWidget {
  final String currentAddress;

  const AmbulanceServicesPage({super.key, required this.currentAddress});

  @override
  State<AmbulanceServicesPage> createState() => _AmbulanceServicesPageState();
}

class _AmbulanceServicesPageState extends State<AmbulanceServicesPage> {
  LatLng? userLocation;
  LatLng? destinationLocation;
  String? destinationAddress; // New variable for the address
  GoogleMapController? mapController;
  TextEditingController searchController = TextEditingController();
  List<Prediction> searchResults = [];

  final GoogleMapsPlaces places = GoogleMapsPlaces(
    apiKey: "AIzaSyBc2xx1XkgZKPcrrQl5HVGMZv_xSfdMxXQ",
  );

  // Mock ambulance locations
  List<LatLng> ambulanceLocations = [
    LatLng(23.780636, 90.400000),
    LatLng(23.782000, 90.402000),
    LatLng(23.779000, 90.398000),
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    user_location.Location location = user_location.Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }
    user_location.PermissionStatus permissionGranted =
        await location.hasPermission();
    if (permissionGranted == user_location.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != user_location.PermissionStatus.granted) return;
    }
    var current = await location.getLocation();
    setState(() {
      userLocation = LatLng(current.latitude!, current.longitude!);
    });

    // Center the map on the user's location
    if (userLocation != null && mapController != null) {
      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(userLocation!, 16),
      );
    }
  }

  // Fetch address from coordinates using reverse geocoding
  Future<void> _getDestinationAddress(LatLng pos) async {
    try {
      // Use the Geocoding API to convert coordinates to address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        setState(() {
          destinationAddress =
              "${placemarks[0].street}, ${placemarks[0].locality}, ${placemarks[0].country}";
        });
      } else {
        print("No address found");
      }

      // If address is a Plus Code, fetch detailed address using Places API
      if (destinationAddress == null ||
          destinationAddress!.startsWith("Plus Code")) {
        final result = await places.searchByText(
          "place_id:${pos.latitude},${pos.longitude}",
        );
        if (result.results.isNotEmpty) {
          setState(() {
            destinationAddress = result.results[0].formattedAddress;
          });
        }
      }
    } catch (e) {
      print("Error occurred during reverse geocoding: $e");
    }
  }

  // Fetch search results using Places API
  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults.clear();
      });
      return;
    }

    final response = await places.autocomplete(query);
    if (response.predictions.isNotEmpty) {
      setState(() {
        searchResults = response.predictions;
      });
    }
  }

  void _setDestination(LatLng pos) {
    setState(() {
      destinationLocation = pos;
    });
    _getDestinationAddress(
      pos,
    ); // Fetch the address after setting the destination
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Destination set!")));
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = {};
    if (userLocation != null) {
      // User location marker
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: userLocation!,
          infoWindow: const InfoWindow(title: "Your Location"),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );

      // Ambulance locations markers
      for (int i = 0; i < ambulanceLocations.length; i++) {
        markers.add(
          Marker(
            markerId: MarkerId('ambulance_$i'),
            position: ambulanceLocations[i],
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(title: "Ambulance ${i + 1}"),
          ),
        );
      }

      // Destination marker
      if (destinationLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: destinationLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: const InfoWindow(title: "Destination"),
          ),
        );
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          userLocation == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: userLocation!,
                  zoom: 16,
                ),
                markers: markers,
                circles:
                    userLocation != null
                        ? {
                          Circle(
                            circleId: const CircleId('search_radius'),
                            center: userLocation!,
                            radius: 500, // 500 meters
                            fillColor: const Color.fromARGB(
                              80,
                              58,
                              8,
                              124,
                            ), // 80 for semi-transparent purple
                            strokeColor: Colors.blue,
                            strokeWidth: 2,
                          ),
                        }
                        : {},
                onMapCreated: (controller) {
                  mapController = controller;
                },
                onTap: _setDestination,
              ),
          // Search bar for user input
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search for a location",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          _searchPlaces(searchController.text);
                        },
                      ),
                    ),
                    onChanged: (text) {
                      // Search while typing
                      _searchPlaces(text);
                    },
                  ),
                  // Display search results
                  if (searchResults.isNotEmpty)
                    Column(
                      children:
                          searchResults.map((prediction) {
                            return ListTile(
                              title: Text(prediction.description ?? ""),
                              onTap: () async {
                                var placeDetails = await places
                                    .getDetailsByPlaceId(prediction.placeId!);
                                var location =
                                    placeDetails.result.geometry!.location;
                                _setDestination(
                                  LatLng(location.lat, location.lng),
                                );
                              },
                            );
                          }).toList(),
                    ),
                ],
              ),
            ),
          ),
          // Hint for destination selection
          Positioned(
            top: 110,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.touch_app, color: Colors.pink),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Tap on the map to set your destination",
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Ambulance Service",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_hospital,
                        color: Colors.red,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Quick ambulance assistance at your location.",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (userLocation != null &&
                            destinationLocation != null) {
                          print(
                            "Requesting ambulance from: ${userLocation!.latitude}, ${userLocation!.longitude} to ${destinationLocation!.latitude}, ${destinationLocation!.longitude}",
                          );
                          // TODO: Replace with actual API call or phone dial logic
                        } else {
                          print("Set both pickup and destination.");
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Ambulance requested!")),
                        );
                      },
                      child: const Text(
                        "Call Ambulance",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
