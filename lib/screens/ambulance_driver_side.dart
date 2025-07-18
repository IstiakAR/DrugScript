import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as user_location;
import 'dart:async';
import 'dart:math';

// Models for Driver Side
class DriverInfo {
  final String id;
  final String name;
  final String phoneNumber;
  final String licenseNumber;
  final double rating;
  final AmbulanceVehicle vehicle;
  bool isOnline;
  LatLng currentLocation;

  DriverInfo({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.licenseNumber,
    required this.rating,
    required this.vehicle,
    required this.isOnline,
    required this.currentLocation,
  });
}

class AmbulanceVehicle {
  final String id;
  final String licensePlate;
  final String type;
  final String model;
  final bool hasOxygen;
  final bool hasDefib;
  final bool hasICU;

  AmbulanceVehicle({
    required this.id,
    required this.licensePlate,
    required this.type,
    required this.model,
    required this.hasOxygen,
    required this.hasDefib,
    required this.hasICU,
  });
}

class PatientBookingRequest {
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
  String status; // pending, accepted, in_progress, completed, cancelled
  final String? medicalNotes;
  final int priority; // 1-5, 1 being highest

  PatientBookingRequest({
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
    this.medicalNotes,
    required this.priority,
  });
}

class TripHistory {
  final String id;
  final PatientBookingRequest booking;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceTraveled;
  final double finalFare;
  final int rating;
  final String? feedback;

  TripHistory({
    required this.id,
    required this.booking,
    required this.startTime,
    this.endTime,
    required this.distanceTraveled,
    required this.finalFare,
    required this.rating,
    this.feedback,
  });
}

class AmbulanceDriverSide extends StatefulWidget {
  final String currentAddress;

  const AmbulanceDriverSide({super.key, required this.currentAddress});

  @override
  State<AmbulanceDriverSide> createState() => _AmbulanceDriverSideState();
}

class _AmbulanceDriverSideState extends State<AmbulanceDriverSide>
    with TickerProviderStateMixin {
  LatLng? driverLocation;
  GoogleMapController? mapController;
  Timer? _locationUpdateTimer;
  Timer? _requestUpdateTimer;
  int _currentIndex = 0;

  // Driver data
  late DriverInfo currentDriver;
  PatientBookingRequest? activeBooking;
  List<PatientBookingRequest> pendingRequests = [];
  List<TripHistory> tripHistory = [];

  // Navigation
  bool isNavigating = false;
  List<LatLng> routePoints = [];

  @override
  void initState() {
    super.initState();
    _initializeDriver();
    _getDriverLocation();
    _startLocationUpdates();
    _startRequestUpdates();
    _loadMockData();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _requestUpdateTimer?.cancel();
    super.dispose();
  }

  void _initializeDriver() {
    currentDriver = DriverInfo(
      id: 'driver_001',
      name: 'Rahman Khan',
      phoneNumber: '+880123456789',
      licenseNumber: 'DL-123456',
      rating: 4.8,
      vehicle: AmbulanceVehicle(
        id: 'amb_001',
        licensePlate: 'DH-1234',
        type: 'Advanced Life Support',
        model: 'Toyota Hiace',
        hasOxygen: true,
        hasDefib: true,
        hasICU: false,
      ),
      isOnline: false,
      currentLocation: LatLng(23.780636, 90.400000),
    );
  }

  Future<void> _getDriverLocation() async {
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
      driverLocation = LatLng(current.latitude!, current.longitude!);
      currentDriver.currentLocation = driverLocation!;
    });

    if (driverLocation != null && mapController != null) {
      mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(driverLocation!, 16),
      );
    }
  }

  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && currentDriver.isOnline) {
        _getDriverLocation();
      }
    });
  }

  void _startRequestUpdates() {
    _requestUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && currentDriver.isOnline) {
        _checkForNewRequests();
      }
    });
  }

  void _checkForNewRequests() {
    // Simulate receiving new requests when online
    final random = Random();
    if (random.nextDouble() < 0.1 && pendingRequests.length < 3) {
      // 10% chance every 5 seconds
      _addMockRequest();
    }
  }

  void _loadMockData() {
    // Add some mock pending requests
    pendingRequests = [
      PatientBookingRequest(
        id: 'req_001',
        patientName: 'Ahmed Hassan',
        phoneNumber: '+880123456701',
        emergencyType: 'Medical Emergency',
        pickupAddress: 'Dhanmondi 27, Dhaka',
        destinationAddress: 'Square Hospital, Dhaka',
        pickupLocation: LatLng(23.781000, 90.401000),
        destinationLocation: LatLng(23.785000, 90.405000),
        requestTime: DateTime.now().subtract(const Duration(minutes: 5)),
        emergencyContact: '+880123456702',
        paymentMethod: 'Cash on Delivery',
        fareEstimate: 850.0,
        status: 'pending',
        medicalNotes: 'Chest pain, needs immediate attention',
        priority: 1,
      ),
      PatientBookingRequest(
        id: 'req_002',
        patientName: 'Fatima Begum',
        phoneNumber: '+880123456703',
        emergencyType: 'Hospital Visit',
        pickupAddress: 'Gulshan 2, Dhaka',
        destinationAddress: 'BIRDEM Hospital, Dhaka',
        pickupLocation: LatLng(23.782000, 90.403000),
        destinationLocation: LatLng(23.787000, 90.407000),
        requestTime: DateTime.now().subtract(const Duration(minutes: 10)),
        emergencyContact: '+880123456704',
        paymentMethod: 'Online Payment',
        fareEstimate: 950.0,
        status: 'pending',
        medicalNotes: 'Diabetes checkup, elderly patient',
        priority: 3,
      ),
    ];

    // Add mock trip history
    tripHistory = [
      TripHistory(
        id: 'trip_001',
        booking: PatientBookingRequest(
          id: 'hist_001',
          patientName: 'Karim Ahmed',
          phoneNumber: '+880123456705',
          emergencyType: 'Emergency',
          pickupAddress: 'Uttara Sector 7',
          destinationAddress: 'United Hospital',
          pickupLocation: LatLng(23.780000, 90.400000),
          destinationLocation: LatLng(23.785000, 90.405000),
          requestTime: DateTime.now().subtract(const Duration(hours: 2)),
          emergencyContact: '+880123456706',
          paymentMethod: 'Cash',
          fareEstimate: 1200.0,
          status: 'completed',
          priority: 1,
        ),
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        endTime: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        distanceTraveled: 12.5,
        finalFare: 1200.0,
        rating: 5,
        feedback: 'Excellent service, very professional',
      ),
    ];
  }

  void _addMockRequest() {
    final random = Random();
    final emergencyTypes = [
      'Medical Emergency',
      'Hospital Visit',
      'Accident',
      'Heart Attack',
    ];
    final names = [
      'Nasir Uddin',
      'Salma Khatun',
      'Rauf Ahmed',
      'Rashida Begum',
    ];

    final newRequest = PatientBookingRequest(
      id: 'req_${DateTime.now().millisecondsSinceEpoch}',
      patientName: names[random.nextInt(names.length)],
      phoneNumber: '+88012345670${random.nextInt(10)}',
      emergencyType: emergencyTypes[random.nextInt(emergencyTypes.length)],
      pickupAddress: 'Random Location ${random.nextInt(100)}',
      destinationAddress: 'Hospital ${random.nextInt(10)}',
      pickupLocation: LatLng(
        23.780636 + (random.nextDouble() - 0.5) * 0.01,
        90.400000 + (random.nextDouble() - 0.5) * 0.01,
      ),
      destinationLocation: LatLng(
        23.785636 + (random.nextDouble() - 0.5) * 0.01,
        90.405000 + (random.nextDouble() - 0.5) * 0.01,
      ),
      requestTime: DateTime.now(),
      emergencyContact: '+88012345671${random.nextInt(10)}',
      paymentMethod: 'Cash on Delivery',
      fareEstimate: 800.0 + (random.nextDouble() * 500),
      status: 'pending',
      priority: random.nextInt(3) + 1,
    );

    setState(() {
      pendingRequests.add(newRequest);
    });

    // Show notification for new request
    if (currentDriver.isOnline) {
      _showNewRequestNotification(newRequest);
    }
  }

  void _showNewRequestNotification(PatientBookingRequest request) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.red, size: 28),
              const SizedBox(width: 8),
              const Text('New Booking Request'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patient: ${request.patientName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text('Emergency: ${request.emergencyType}'),
              const SizedBox(height: 4),
              Text('Pickup: ${request.pickupAddress}'),
              const SizedBox(height: 4),
              Text('Destination: ${request.destinationAddress}'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fare:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '৳${request.fareEstimate.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _declineRequest(request);
              },
              child: const Text('Decline', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _acceptRequest(request);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                'Accept',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleOnlineStatus() {
    setState(() {
      currentDriver.isOnline = !currentDriver.isOnline;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          currentDriver.isOnline
              ? 'You are now online and receiving requests'
              : 'You are now offline',
        ),
        backgroundColor: currentDriver.isOnline ? Colors.green : Colors.orange,
      ),
    );
  }

  void _acceptRequest(PatientBookingRequest request) {
    setState(() {
      request.status = 'accepted';
      activeBooking = request;
      pendingRequests.remove(request);
      _currentIndex = 1; // Switch to navigation tab
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking accepted! Navigate to ${request.patientName}'),
        backgroundColor: Colors.green,
      ),
    );

    _startNavigation();
  }

  void _declineRequest(PatientBookingRequest request) {
    setState(() {
      pendingRequests.remove(request);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking request declined'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _startNavigation() {
    if (activeBooking != null) {
      setState(() {
        isNavigating = true;
      });

      // Simulate navigation to pickup location
      Timer.periodic(const Duration(seconds: 2), (timer) {
        if (activeBooking == null || !isNavigating) {
          timer.cancel();
          return;
        }

        setState(() {
          // Move driver closer to pickup location
          final target = activeBooking!.pickupLocation;
          final current = currentDriver.currentLocation;

          double latDiff = target.latitude - current.latitude;
          double lngDiff = target.longitude - current.longitude;

          if (latDiff.abs() < 0.001 && lngDiff.abs() < 0.001) {
            // Reached pickup location
            timer.cancel();
            isNavigating = false;
            _showPickupArrivalDialog();
          } else {
            // Move closer
            currentDriver.currentLocation = LatLng(
              current.latitude + (latDiff * 0.1),
              current.longitude + (lngDiff * 0.1),
            );
          }
        });
      });
    }
  }

  void _showPickupArrivalDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Arrived at Pickup'),
          content: Text(
            'You have arrived at the pickup location for ${activeBooking!.patientName}',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startRideToDestination();
              },
              child: const Text('Start Ride'),
            ),
          ],
        );
      },
    );
  }

  void _startRideToDestination() {
    if (activeBooking != null) {
      setState(() {
        activeBooking!.status = 'in_progress';
        isNavigating = true;
      });

      // Simulate navigation to destination
      Timer.periodic(const Duration(seconds: 2), (timer) {
        if (activeBooking == null || !isNavigating) {
          timer.cancel();
          return;
        }

        setState(() {
          final target = activeBooking!.destinationLocation;
          final current = currentDriver.currentLocation;

          double latDiff = target.latitude - current.latitude;
          double lngDiff = target.longitude - current.longitude;

          if (latDiff.abs() < 0.001 && lngDiff.abs() < 0.001) {
            // Reached destination
            timer.cancel();
            isNavigating = false;
            _showRideCompletionDialog();
          } else {
            // Move closer
            currentDriver.currentLocation = LatLng(
              current.latitude + (latDiff * 0.1),
              current.longitude + (lngDiff * 0.1),
            );
          }
        });
      });
    }
  }

  void _showRideCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ride Completed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Successfully delivered ${activeBooking!.patientName} to destination',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fare Earned:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '৳${activeBooking!.fareEstimate.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _completeRide();
              },
              child: const Text('Complete Ride'),
            ),
          ],
        );
      },
    );
  }

  void _completeRide() {
    if (activeBooking != null) {
      final trip = TripHistory(
        id: 'trip_${DateTime.now().millisecondsSinceEpoch}',
        booking: activeBooking!,
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
        endTime: DateTime.now(),
        distanceTraveled: 8.5,
        finalFare: activeBooking!.fareEstimate,
        rating: 5,
        feedback: 'Great service!',
      );

      setState(() {
        activeBooking!.status = 'completed';
        tripHistory.insert(0, trip);
        activeBooking = null;
        _currentIndex = 2; // Switch to earnings tab
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambulance Driver'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Switch(
            value: currentDriver.isOnline,
            onChanged: (value) => _toggleOnlineStatus(),
            activeColor: Colors.green,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildRequestsPage(),
          _buildNavigationPage(),
          _buildEarningsPage(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.navigation),
            label: 'Navigate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on),
            label: 'Earnings',
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildRequestsPage() {
    return Column(
      children: [
        // Driver Status Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  currentDriver.isOnline
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.grey.shade400, Colors.grey.shade600],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (currentDriver.isOnline ? Colors.green : Colors.grey)
                    .withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: Text(
                      currentDriver.name.split(' ').map((e) => e[0]).join(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentDriver.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${currentDriver.vehicle.type} • ${currentDriver.vehicle.licensePlate}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.yellow.shade300,
                              size: 18,
                            ),
                            Text(
                              ' ${currentDriver.rating} rating',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      currentDriver.isOnline ? 'ONLINE' : 'OFFLINE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Pending Requests
        Expanded(
          child:
              pendingRequests.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          currentDriver.isOnline
                              ? Icons.hourglass_empty
                              : Icons.power_off,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentDriver.isOnline
                              ? 'No pending requests'
                              : 'Go online to receive requests',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: pendingRequests.length,
                    itemBuilder: (context, index) {
                      final request = pendingRequests[index];
                      return _buildRequestCard(request);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(PatientBookingRequest request) {
    final distance = _calculateDistance(
      currentDriver.currentLocation,
      request.pickupLocation,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getPriorityColor(request.priority),
          width: 2,
        ),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(
                        request.priority,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getEmergencyIcon(request.emergencyType),
                      color: _getPriorityColor(request.priority),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.patientName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        request.emergencyType,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(request.priority),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Priority ${request.priority}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Pickup and Destination
          Row(
            children: [
              Icon(Icons.my_location, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.pickupAddress,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.destinationAddress,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),

          if (request.medicalNotes != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.yellow.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      request.medicalNotes!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Distance, Time, and Fare
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
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
                          fontSize: 14,
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
                  padding: const EdgeInsets.all(8),
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
                        '${(distance * 2).round()} min',
                        style: const TextStyle(
                          fontSize: 14,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Fare',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '৳${request.fareEstimate.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
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

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _declineRequest(request),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Decline'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _acceptRequest(request),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Calling ${request.patientName}...'),
                    ),
                  );
                },
                icon: const Icon(Icons.phone, color: Colors.green),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green.shade50,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationPage() {
    if (activeBooking == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.navigation, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No active booking to navigate',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    Set<Marker> navigationMarkers = {};

    // Driver location
    navigationMarkers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: currentDriver.currentLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: 'Your Location',
          snippet: currentDriver.vehicle.licensePlate,
        ),
      ),
    );

    // Pickup location
    navigationMarkers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: activeBooking!.pickupLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Pickup: ${activeBooking!.patientName}',
          snippet: activeBooking!.pickupAddress,
        ),
      ),
    );

    // Destination location
    navigationMarkers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: activeBooking!.destinationLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: activeBooking!.destinationAddress,
        ),
      ),
    );

    final targetLocation =
        activeBooking!.status == 'accepted'
            ? activeBooking!.pickupLocation
            : activeBooking!.destinationLocation;

    final distance = _calculateDistance(
      currentDriver.currentLocation,
      targetLocation,
    );
    final eta = (distance * 2).round();

    return Column(
      children: [
        // Map
        Expanded(
          flex: 2,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: currentDriver.currentLocation,
              zoom: 16,
            ),
            markers: navigationMarkers,
            onMapCreated: (controller) {
              mapController = controller;
            },
          ),
        ),

        // Navigation Info
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
              // Patient Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      activeBooking!.patientName
                          .split(' ')
                          .map((e) => e[0])
                          .join(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeBooking!.patientName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          activeBooking!.emergencyType,
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
                            'Calling ${activeBooking!.patientName}...',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.phone, color: Colors.green),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Current Destination
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      activeBooking!.status == 'accepted'
                          ? Icons.my_location
                          : Icons.location_on,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeBooking!.status == 'accepted'
                                ? 'Navigate to Pickup'
                                : 'Navigate to Destination',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            activeBooking!.status == 'accepted'
                                ? activeBooking!.pickupAddress
                                : activeBooking!.destinationAddress,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Distance and ETA
              Row(
                children: [
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
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action Button
              if (activeBooking!.status == 'accepted')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showPickupArrivalDialog();
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Mark as Picked Up'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showRideCompletionDialog();
                    },
                    icon: const Icon(Icons.flag),
                    label: const Text('Complete Ride'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsPage() {
    final todayEarnings = tripHistory
        .where((trip) => _isToday(trip.endTime ?? trip.startTime))
        .fold(0.0, (sum, trip) => sum + trip.finalFare);

    final weekEarnings = tripHistory
        .where((trip) => _isThisWeek(trip.endTime ?? trip.startTime))
        .fold(0.0, (sum, trip) => sum + trip.finalFare);

    final monthEarnings = tripHistory
        .where((trip) => _isThisMonth(trip.endTime ?? trip.startTime))
        .fold(0.0, (sum, trip) => sum + trip.finalFare);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Earnings Summary
          const Text(
            'Earnings Summary',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildEarningsCard('Today', todayEarnings, Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEarningsCard(
                  'This Week',
                  weekEarnings,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildEarningsCard('This Month', monthEarnings, Colors.purple),

          const SizedBox(height: 24),

          // Trip Statistics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                const Text(
                  'Trip Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Trips',
                        tripHistory.length.toString(),
                        Icons.local_taxi,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Average Rating',
                        '${currentDriver.rating}',
                        Icons.star,
                        Colors.yellow,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Recent Trips
          const Text(
            'Recent Trips',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (tripHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.history, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No trips completed yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            ...tripHistory.map((trip) => _buildTripHistoryCard(trip)),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(String title, double amount, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.shade400, color.shade600]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '৳${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildTripHistoryCard(TripHistory trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
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
                trip.booking.patientName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '৳${trip.finalFare.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            trip.booking.emergencyType,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.my_location, size: 16, color: Colors.blue),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trip.booking.pickupAddress,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.red),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trip.booking.destinationAddress,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  ...List.generate(
                    5,
                    (index) => Icon(
                      Icons.star,
                      size: 16,
                      color:
                          index < trip.rating
                              ? Colors.orange
                              : Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${trip.rating}/5',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Text(
                _formatDateTime(trip.startTime),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
          if (trip.feedback != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '"${trip.feedback}"',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.green;
      case 5:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getEmergencyIcon(String emergencyType) {
    switch (emergencyType.toLowerCase()) {
      case 'medical emergency':
      case 'emergency':
        return Icons.emergency;
      case 'heart attack':
        return Icons.favorite;
      case 'accident':
        return Icons.car_crash;
      case 'hospital visit':
        return Icons.local_hospital;
      default:
        return Icons.medical_services;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1)));
  }

  bool _isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
