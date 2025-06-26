import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://fastapi-app-production-6e30.up.railway.app';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Helper to get the current user's ID token
  Future<String?> _getAuthToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      return await user.getIdToken(true);
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  // Fetch user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final token = await _getAuthToken();

      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          'X-User-ID': user.uid,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        // Profile not found
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
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final token = await _getAuthToken();

      final response = await http.post(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
          // Alternative: Send user ID in headers instead
          'X-User-ID': user.uid,
        },
        body: jsonEncode({
          "name": name,
          "age": age,
          "address": address,
          "gender": gender,
          "phone": phone,
          "date_of_birth": dateOfBirth,
          "blood_type": bloodType,
          "allergies": allergies,
          "medical_conditions": medicalConditions,
          "emergency_contact": emergencyContact,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print('Error response: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception updating/creating profile: $e');
      return false;
    }
  }

  // Update existing profile (PUT)
  Future<bool> updateUserProfile(Map<String, dynamic> updateFields) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final body = jsonEncode(updateFields);
      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer ${await _getAuthToken()}',
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
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/profile'),
        headers: {
          // 'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );
      return response.statusCode == 204;
    } catch (e) {
      print('Exception deleting profile: $e');
      return false;
    }
  }
}