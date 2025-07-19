// ignore_for_file: avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as user_location;
import 'package:flutter_google_maps_webservices/places.dart';
import 'dart:async';
import 'dart:math';

// Models for Patient Side
class AmbulanceInfo {
  final String id;
  final String name;
  final String type;
  final double fare;
  final double rating;
  final String driverName;
  final String phoneNumber;
  LatLng currentLocation;
  bool isAvailable; // Made mutable
  final String estimatedArrival;
  final String licensePlate;

  AmbulanceInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.fare,
    required this.rating,
    required this.driverName,
    required this.phoneNumber,
    required this.currentLocation,
    required this.isAvailable,
    required this.estimatedArrival,
    required this.licensePlate,
  });
}

class BookingRequest {
  final String id;
  final String patientName;
  final String phoneNumber;
  final String emergencyType;
  final String pickupAddress;
  final String destinationAddress;
  final LatLng pickupLocation;
  final LatLng destinationLocation;
  final DateTime requestTime;
  final String emergencyContact;
  final String paymentMethod;
  final double fareEstimate;
  final String status; // pending, accepted, in_progress, completed, cancelled
  AmbulanceInfo? assignedAmbulance;

  BookingRequest({
    required this.id,
    required this.patientName,
    required this.phoneNumber,
    required this.emergencyType,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.requestTime,
    required this.emergencyContact,
    required this.paymentMethod,
    required this.fareEstimate,
    required this.status,
    this.assignedAmbulance,
  });
}

class AmbulancePatientSide extends StatefulWidget {
  final String currentAddress;

  const AmbulancePatientSide({super.key, required this.currentAddress});

  @override
  State<AmbulancePatientSide> createState() => _AmbulancePatientSideState();
}

class _AmbulancePatientSideState extends State<AmbulancePatientSide>
    with TickerProviderStateMixin {
  LatLng? userLocation;
  LatLng? destinationLocation;
  String? destinationAddress;
  GoogleMapController? mapController;
  TextEditingController searchController = TextEditingController();
  TextEditingController pickupController = TextEditingController();
  List<Prediction> searchResults = [];
  Timer? _ambulanceUpdateTimer;
  Timer? _trackingTimer;

  // Form controllers
  TextEditingController patientNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emergencyContactController = TextEditingController();

  // State variables
  String selectedEmergencyType = 'Medical Emergency';
  String selectedPaymentMethod = 'Cash on Delivery';
  bool isBookingInProgress = false;
  BookingRequest? currentBooking;
  int _currentIndex = 0;

  final List<String> emergencyTypes = [
    'Medical Emergency',
    'Hospital Visit',
    'Doctor Appointment',
    'Patient Transfer',
    'Medical Checkup',
    'Accident',
    'Heart Attack',
    'Stroke',
    'Breathing Difficulty',
    'Other Emergency',
  ];

  final List<String> paymentMethods = [
    'Cash on Delivery',
    'SSLCommerz Online Payment',
    'Mobile Banking (bKash)',
    'Bank Transfer',
  ];

  final GoogleMapsPlaces places = GoogleMapsPlaces(
    apiKey: "AIzaSyBc2xx1XkgZKPcrrQl5HVGMZv_xSfdMxXQ",
  );

  List<AmbulanceInfo> nearbyAmbulances = [
    AmbulanceInfo(
      id: 'amb_001',
      name: 'Emergency Care 1',
      type: 'Basic Life Support',
      fare: 800.0,
      rating: 4.8,
      driverName: 'Karim Ahmed',
      phoneNumber: '+880123456789',
      currentLocation: LatLng(23.780636, 90.400000),
      isAvailable: true,
      estimatedArrival: '5 mins',
      licensePlate: 'DH-1234',
    ),
    AmbulanceInfo(
      id: 'amb_002',
      name: 'Lifeline Ambulance',
      type: 'Advanced Life Support',
      fare: 1200.0,
      rating: 4.9,
      driverName: 'Rahman Khan',
      phoneNumber: '+880123456790',
      currentLocation: LatLng(23.782000, 90.402000),
      isAvailable: true,
      estimatedArrival: '7 mins',
      licensePlate: 'DH-5678',
    ),
    AmbulanceInfo(
      id: 'amb_003',
      name: 'Metro Emergency',
      type: 'ICU Ambulance',
      fare: 1500.0,
      rating: 4.7,
      driverName: 'Hasibul Islam',
      phoneNumber: '+880123456791',
      currentLocation: LatLng(23.779000, 90.398000),
      isAvailable: false,
      estimatedArrival: '12 mins',
      licensePlate: 'DH-9012',
    ),
  ];

  List<BookingRequest> bookingHistory = [];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _startAmbulanceLocationUpdates();
    pickupController.text = widget.currentAddress;
  }

  @override
  void dispose() {
    _ambulanceUpdateTimer?.cancel();
    _trackingTimer?.cancel();
    searchController.dispose();
    pickupController.dispose();
    patientNameController.dispose();
    phoneController.dispose();
    emergencyContactController.dispose();
    super.dispose();
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

    if (userLocation != null && mapController != null) {
      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(userLocation!, 16),
      );
    }
  }

  void _startAmbulanceLocationUpdates() {
    _ambulanceUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          for (var ambulance in nearbyAmbulances) {
            if (ambulance.isAvailable) {
              final random = Random();
              double latChange = (random.nextDouble() - 0.5) * 0.0005;
              double lngChange = (random.nextDouble() - 0.5) * 0.0005;

              ambulance.currentLocation = LatLng(
                ambulance.currentLocation.latitude + latChange,
                ambulance.currentLocation.longitude + lngChange,
              );
            }
          }
        });
      }
    });
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371;
    double lat1Rad = point1.latitude * (pi / 180);
    double lat2Rad = point2.latitude * (pi / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (pi / 180);
    double deltaLngRad = (point2.longitude - point1.longitude) * (pi / 180);

    double a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLngRad / 2) *
            sin(deltaLngRad / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults.clear();
      });
      return;
    }

    try {
      final response = await places.autocomplete(query);
      if (response.status == "OK" && response.predictions.isNotEmpty) {
        setState(() {
          searchResults = response.predictions;
        });
      } else {
        setState(() {
          searchResults.clear();
        });
      }
    } catch (e) {
      print("Error searching places: $e");
      setState(() {
        searchResults.clear();
      });
    }
  }

  Future<void> _selectSearchResult(Prediction prediction) async {
    try {
      setState(() {
        searchResults.clear();
        searchController.text = prediction.description ?? '';
      });

      var placeDetails = await places.getDetailsByPlaceId(prediction.placeId!);
      if (placeDetails.status == "OK" && placeDetails.result.geometry != null) {
        var location = placeDetails.result.geometry!.location;
        final selectedLocation = LatLng(location.lat, location.lng);

        setState(() {
          destinationLocation = selectedLocation;
          destinationAddress = prediction.description;
        });

        if (mapController != null) {
          await mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(selectedLocation, 16),
          );
        }
      }
    } catch (e) {
      print("Error selecting search result: $e");
    }
  }

  void _requestAmbulance() {
    if (patientNameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        destinationAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all required fields and select destination',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isBookingInProgress = true;
    });

    // Create booking request
    final booking = BookingRequest(
      id: 'booking_${DateTime.now().millisecondsSinceEpoch}',
      patientName: patientNameController.text,
      phoneNumber: phoneController.text,
      emergencyType: selectedEmergencyType,
      pickupAddress: pickupController.text,
      destinationAddress: destinationAddress!,
      pickupLocation: userLocation!,
      destinationLocation: destinationLocation!,
      requestTime: DateTime.now(),
      emergencyContact: emergencyContactController.text,
      paymentMethod: selectedPaymentMethod,
      fareEstimate: _calculateFareEstimate(),
      status: 'pending',
    );

    // Simulate finding nearest ambulance
    Timer(const Duration(seconds: 3), () {
      final availableAmbulances =
          nearbyAmbulances.where((a) => a.isAvailable).toList();
      if (availableAmbulances.isNotEmpty) {
        availableAmbulances.sort((a, b) {
          double distanceA = _calculateDistance(
            userLocation!,
            a.currentLocation,
          );
          double distanceB = _calculateDistance(
            userLocation!,
            b.currentLocation,
          );
          return distanceA.compareTo(distanceB);
        });

        setState(() {
          currentBooking = booking;
          currentBooking!.assignedAmbulance = availableAmbulances.first;
          currentBooking!.assignedAmbulance!.isAvailable = false;
          isBookingInProgress = false;
          _currentIndex = 1; // Switch to tracking tab
        });

        _startTracking();
        bookingHistory.add(currentBooking!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ambulance assigned! ${availableAmbulances.first.name} is on the way.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          isBookingInProgress = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No ambulances available. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _startTracking() {
    _trackingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (currentBooking != null && currentBooking!.assignedAmbulance != null) {
        // Simulate ambulance movement towards pickup location
        setState(() {
          final ambulance = currentBooking!.assignedAmbulance!;
          final target = currentBooking!.pickupLocation;

          double latDiff = target.latitude - ambulance.currentLocation.latitude;
          double lngDiff =
              target.longitude - ambulance.currentLocation.longitude;

          // Move ambulance closer to target
          ambulance.currentLocation = LatLng(
            ambulance.currentLocation.latitude + (latDiff * 0.1),
            ambulance.currentLocation.longitude + (lngDiff * 0.1),
          );
        });

        // Check if ambulance reached pickup location
        double distance = _calculateDistance(
          currentBooking!.assignedAmbulance!.currentLocation,
          currentBooking!.pickupLocation,
        );

        if (distance < 0.1) {
          // Within 100 meters
          _trackingTimer?.cancel();
          setState(() {
            currentBooking = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ambulance has arrived at pickup location!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  double _calculateFareEstimate() {
    if (userLocation == null || destinationLocation == null) return 800.0;

    double distance = _calculateDistance(userLocation!, destinationLocation!);
    double baseFare = 800.0;
    double farePerKm = 50.0;

    return baseFare + (distance * farePerKm);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Ambulance'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildRequestPage(),
          _buildTrackingPage(),
          _buildHistoryPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Request'),
          BottomNavigationBarItem(
            icon: Icon(Icons.my_location),
            label: 'Track',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildRequestPage() {
    Set<Marker> markers = {};

    if (userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: userLocation!,
          infoWindow: const InfoWindow(title: "Pickup Location"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      // Show nearby ambulances
      for (var ambulance in nearbyAmbulances) {
        if (ambulance.isAvailable) {
          markers.add(
            Marker(
              markerId: MarkerId(ambulance.id),
              position: ambulance.currentLocation,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              infoWindow: InfoWindow(
                title: ambulance.name,
                snippet:
                    '${ambulance.type} • ৳${ambulance.fare.toStringAsFixed(0)}',
              ),
            ),
          );
        }
      }

      if (destinationLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: destinationLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: "Destination",
              snippet: destinationAddress ?? "Selected Location",
            ),
          ),
        );
      }
    }

    return Column(
      children: [
        // Map Section
        Expanded(
          flex: 2,
          child:
              userLocation == null
                  ? const Center(child: CircularProgressIndicator())
                  : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: userLocation!,
                      zoom: 16,
                    ),
                    markers: markers,
                    onMapCreated: (controller) {
                      mapController = controller;
                    },
                    onTap: (LatLng position) {
                      setState(() {
                        destinationLocation = position;
                        destinationAddress = "Selected Location";
                      });
                    },
                  ),
        ),

        // Form Section
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search destination...",
                      prefixIcon: const Icon(Icons.search, color: Colors.red),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: _searchPlaces,
                  ),

                  // Search Results
                  if (searchResults.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final prediction = searchResults[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                            ),
                            title: Text(prediction.description ?? ""),
                            dense: true,
                            onTap: () => _selectSearchResult(prediction),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Patient Information
                  const Text(
                    'Patient Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: patientNameController,
                    decoration: InputDecoration(
                      labelText: 'Patient Name *',
                      prefixIcon: const Icon(Icons.person, color: Colors.red),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number *',
                      prefixIcon: const Icon(Icons.phone, color: Colors.red),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: emergencyContactController,
                    decoration: InputDecoration(
                      labelText: 'Emergency Contact',
                      prefixIcon: const Icon(
                        Icons.contact_emergency,
                        color: Colors.red,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // Emergency Type
                  DropdownButtonFormField<String>(
                    value: selectedEmergencyType,
                    decoration: InputDecoration(
                      labelText: 'Emergency Type',
                      prefixIcon: const Icon(
                        Icons.medical_services,
                        color: Colors.red,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items:
                        emergencyTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedEmergencyType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Pickup Address
                  TextField(
                    controller: pickupController,
                    decoration: InputDecoration(
                      labelText: 'Pickup Address',
                      prefixIcon: const Icon(
                        Icons.my_location,
                        color: Colors.red,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Method
                  DropdownButtonFormField<String>(
                    value: selectedPaymentMethod,
                    decoration: InputDecoration(
                      labelText: 'Payment Method',
                      prefixIcon: const Icon(Icons.payment, color: Colors.red),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items:
                        paymentMethods.map((method) {
                          return DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPaymentMethod = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Fare Estimate
                  if (destinationLocation != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Estimated Fare:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '৳${_calculateFareEstimate().toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Request Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isBookingInProgress ? null : _requestAmbulance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          isBookingInProgress
                              ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Requesting Ambulance...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                              : const Text(
                                'Request Ambulance',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingPage() {
    if (currentBooking == null || currentBooking!.assignedAmbulance == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_hospital, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No active ambulance to track',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    Set<Marker> trackingMarkers = {};
    final ambulance = currentBooking!.assignedAmbulance!;

    // Ambulance marker
    trackingMarkers.add(
      Marker(
        markerId: MarkerId(ambulance.id),
        position: ambulance.currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: ambulance.name,
          snippet: 'Driver: ${ambulance.driverName}',
        ),
      ),
    );

    // Pickup location marker
    trackingMarkers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: currentBooking!.pickupLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: "Pickup Location"),
      ),
    );

    double distance = _calculateDistance(
      ambulance.currentLocation,
      currentBooking!.pickupLocation,
    );
    int eta = (distance * 2).round(); // Rough ETA calculation

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Map with live tracking
              SizedBox(
                height: constraints.maxHeight * 0.6, // 60% of available height
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: ambulance.currentLocation,
                    zoom: 16,
                  ),
                  markers: trackingMarkers,
                  onMapCreated: (controller) {
                    mapController = controller;
                  },
                ),
              ),

              // Ambulance Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_hospital,
                            color: Colors.red,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ambulance.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${ambulance.type} • ${ambulance.licensePlate}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
                                  Text(
                                    ' ${ambulance.rating} • ETA: $eta mins',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Driver Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              ambulance.driverName
                                  .split(' ')
                                  .map((e) => e[0])
                                  .join(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ambulance.driverName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Driver • ${ambulance.phoneNumber}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Calling ${ambulance.driverName}...',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.phone, color: Colors.green),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Status and Distance
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Distance',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${distance.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'ETA',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '$eta mins',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Status',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Text(
                                  'En Route',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryPage() {
    if (bookingHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No booking history',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookingHistory.length,
      itemBuilder: (context, index) {
        final booking = bookingHistory[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.emergencyType,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(booking.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      booking.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Patient: ${booking.patientName}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                'From: ${booking.pickupAddress}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                'To: ${booking.destinationAddress}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDateTime(booking.requestTime),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  Text(
                    '৳${booking.fareEstimate.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
