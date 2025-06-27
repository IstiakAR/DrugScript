import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../utils/constants.dart';

class ApiService {
  final AuthService _authService = AuthService();

  // Helper function to convert UI values to backend-compatible values
  String? _processGender(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'male';
      case 'female':
        return 'female';
      case 'other':
        return 'other';
      case 'not specified':
      default:
        return null;
    }
  }

  String? _processBloodType(String bloodType) {
    if (AppConstants.bloodTypes.contains(bloodType) && bloodType != 'Not specified') {
      return bloodType;
    }
    return null;
  }

  // Fetch user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _authService.currentUser;
    if (user == null) return null;

    try {
      final token = await _authService.getIdToken();

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.profileEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          'X-User-ID': user.uid,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        print('Error getting profile: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception getting profile: $e');
      return null;
    }
  }

  // Create or update user profile
  Future<bool> upsertUserProfile({
    required String name,
    required String age,
    required String address,
    required String gender,
    required String phone,
    required String dateOfBirth,
    required String bloodType,
    String? allergies,
    String? medicalConditions,
    required String emergencyContact,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return false;

    try {
      final token = await _authService.getIdToken();

      final Map<String, dynamic> profileData = {
        "name": name.trim().isEmpty ? null : name,
        "age": age.trim().isEmpty || age == 'Not specified' ? null : age,
        "address": address.trim().isEmpty || address == 'Not specified' ? null : address,
        "phone": phone.trim().isEmpty || phone == 'Not specified' ? null : phone,
        "date_of_birth": dateOfBirth.trim().isEmpty || dateOfBirth == 'Not specified' ? null : dateOfBirth,
        "allergies": allergies?.trim().isEmpty == true || allergies == 'None' ? null : allergies,
        "medical_conditions": medicalConditions?.trim().isEmpty == true || medicalConditions == 'None' ? null : medicalConditions,
        "emergency_contact": emergencyContact.trim().isEmpty || emergencyContact == 'Not specified' ? null : emergencyContact,
      };

      final processedGender = _processGender(gender);
      final processedBloodType = _processBloodType(bloodType);

      if (processedGender != null) {
        profileData["gender"] = processedGender;
      }

      if (processedBloodType != null) {
        profileData["blood_type"] = processedBloodType;
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.profileEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          'X-User-ID': user.uid,
        },
        body: jsonEncode(profileData),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Exception updating/creating profile: $e');
      return false;
    }
  }

  // Update existing profile (PUT)
  Future<bool> updateUserProfile(Map<String, dynamic> updateFields) async {
    final user = _authService.currentUser;
    if (user == null) return false;

    try {
      final body = jsonEncode(updateFields);
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.profileEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Exception updating profile: $e');
      return false;
    }
  }

  // Delete user profile
  Future<bool> deleteUserProfile() async {
    final user = _authService.currentUser;
    if (user == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.profileEndpoint}'),
      );
      return response.statusCode == 204;
    } catch (e) {
      print('Exception deleting profile: $e');
      return false;
    }
  }

  // Search medicines
  Future<List<dynamic>> searchMedicines(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.medicineSearchEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['results'] ?? [];
      } else {
        print('Failed to search medicines: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error searching medicines: $e');
      return [];
    }
  }

  // Create prescription
  Future<bool> createPrescription({
    required String doctorName,
    required String contact,
    required List<String> medicinesSlugs,
    required String image,
    required String date,
    required String diagnosis,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return false;

    try {
      final token = await _authService.getIdToken();

      final Map<String, dynamic> payload = {
        'doctor_name': doctorName,
        'contact': contact,
        'medicines': medicinesSlugs,
        'image': image,
        'date': date,
        'diagnosis': diagnosis,
        'created_by': user.uid,
      };

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.addPrescriptionEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error creating prescription: $e');
      return false;
    }
  }
}