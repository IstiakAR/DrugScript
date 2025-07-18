import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;

// Shared models for ambulance services

class User {
  final String id;
  final String name;
  final String phoneNumber;
  final String email;
  final UserType type;

  User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.type,
  });
}

enum UserType { patient, driver, admin }

class AmbulanceBookingStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String driverEnRoute = 'driver_en_route';
  static const String driverArrived = 'driver_arrived';
  static const String patientPickedUp = 'patient_picked_up';
  static const String inTransit = 'in_transit';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}

class PaymentMethod {
  static const String cashOnDelivery = 'Cash on Delivery';
  static const String sslCommerzOnline = 'SSLCommerz Online Payment';
  static const String bkashMobile = 'Mobile Banking (bKash)';
  static const String bankTransfer = 'Bank Transfer';
  static const String nagadMobile = 'Mobile Banking (Nagad)';
}

class EmergencyType {
  static const String medicalEmergency = 'Medical Emergency';
  static const String hospitalVisit = 'Hospital Visit';
  static const String doctorAppointment = 'Doctor Appointment';
  static const String patientTransfer = 'Patient Transfer';
  static const String medicalCheckup = 'Medical Checkup';
  static const String accident = 'Accident';
  static const String heartAttack = 'Heart Attack';
  static const String stroke = 'Stroke';
  static const String breathingDifficulty = 'Breathing Difficulty';
  static const String other = 'Other Emergency';
}

class AmbulanceType {
  static const String basicLifeSupport = 'Basic Life Support';
  static const String advancedLifeSupport = 'Advanced Life Support';
  static const String icuAmbulance = 'ICU Ambulance';
  static const String patientTransport = 'Patient Transport';
  static const String emergencyResponse = 'Emergency Response';
}

// Distance calculation utility
class LocationUtils {
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth radius in kilometers

    double lat1Rad = point1.latitude * (math.pi / 180);
    double lat2Rad = point2.latitude * (math.pi / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (math.pi / 180);
    double deltaLngRad =
        (point2.longitude - point1.longitude) * (math.pi / 180);

    double a =
        math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  static int calculateETA(double distanceKm, {double averageSpeedKmh = 30}) {
    return ((distanceKm / averageSpeedKmh) * 60)
        .round(); // Return ETA in minutes
  }
}

// Notification service for real-time updates
class NotificationService {
  static void showBookingNotification(String message) {
    // Implementation for showing notifications
    print('Notification: $message');
  }

  static void playEmergencySound() {
    // Implementation for emergency sound
    print('Playing emergency sound');
  }
}

// Fare calculation utility
class FareCalculator {
  static double calculateBaseFare(String ambulanceType) {
    switch (ambulanceType) {
      case AmbulanceType.basicLifeSupport:
        return 800.0;
      case AmbulanceType.advancedLifeSupport:
        return 1200.0;
      case AmbulanceType.icuAmbulance:
        return 1500.0;
      case AmbulanceType.patientTransport:
        return 600.0;
      case AmbulanceType.emergencyResponse:
        return 1800.0;
      default:
        return 800.0;
    }
  }

  static double calculateDistanceFare(double distanceKm) {
    return distanceKm * 50.0; // ৳50 per kilometer
  }

  static double calculateEmergencyPremium(String emergencyType) {
    switch (emergencyType) {
      case EmergencyType.medicalEmergency:
      case EmergencyType.heartAttack:
      case EmergencyType.stroke:
      case EmergencyType.breathingDifficulty:
        return 200.0; // Emergency premium
      default:
        return 0.0;
    }
  }

  static double calculateTotalFare({
    required String ambulanceType,
    required double distanceKm,
    required String emergencyType,
    double nightPremium = 0.0,
    double peakHourPremium = 0.0,
  }) {
    double baseFare = calculateBaseFare(ambulanceType);
    double distanceFare = calculateDistanceFare(distanceKm);
    double emergencyPremium = calculateEmergencyPremium(emergencyType);

    return baseFare +
        distanceFare +
        emergencyPremium +
        nightPremium +
        peakHourPremium;
  }
}

// Status helper for UI
class StatusHelper {
  static String getStatusDisplayText(String status) {
    switch (status) {
      case AmbulanceBookingStatus.pending:
        return 'Waiting for Driver';
      case AmbulanceBookingStatus.accepted:
        return 'Driver Assigned';
      case AmbulanceBookingStatus.driverEnRoute:
        return 'Driver En Route';
      case AmbulanceBookingStatus.driverArrived:
        return 'Driver Arrived';
      case AmbulanceBookingStatus.patientPickedUp:
        return 'Patient Picked Up';
      case AmbulanceBookingStatus.inTransit:
        return 'In Transit';
      case AmbulanceBookingStatus.completed:
        return 'Completed';
      case AmbulanceBookingStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown Status';
    }
  }
}
