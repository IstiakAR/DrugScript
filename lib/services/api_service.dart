import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class Information {
  final String? id;
  final String name;
  final int age;
  final int weight;
  final String bloodGroup;


  Information({
    this.id,
    required this.name,
    required this.age,
    required this.weight,
    required this.bloodGroup,
  });

  factory Information.fromJson(Map<String, dynamic> json) {
    return Information(
      id: json['id'],
      name: json['name'],
      age: json['age'],
      weight: json['weight'],
      bloodGroup: json['blood_group'],
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'name': name,
      'age': age,
      'weight': weight,
      'blood_group': bloodGroup,
    };
    return json;
  }
}


class ApiService {
  // Update this to your FastAPI server address
  final String baseUrl = 'https://fastapi-app-production-6e30.up.railway.app';
  // Use 'http://localhost:8000' for web or iOS simulator
  
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profiles/${user.uid}'),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        // Profile not found, will be created on first save
        return {
          'name': user.displayName ?? 'No Name',
          'blood_type': 'Not specified',
          'allergies': 'None',
          'emergency_contact': 'Not specified',
          'medical_conditions': 'None',
          'age': 'Not specified',
          'address': 'Not specified',
          'phone': 'Not specified',
          'gender': 'Not specified',
          'dob': 'Not specified',
        };
      } else {
        print('Error getting profile: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception getting profile: $e');
      return null;
    }
  }

  // Update user profile data
  Future<bool> updateUserProfile({
    required String name,
    required String bloodType,
    required String allergies,
    required String emergencyContact,
    required String medicalConditions,
    required String age,
    required String address,
    required String phone,
    required String gender,
    required String dob,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/profiles/?user_id=${user.uid}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'blood_type': bloodType,
          'allergies': allergies,
          'emergency_contact': emergencyContact,
          'medical_conditions': medicalConditions,
          'age': age,
          'address': address,
          'phone': phone,
          'gender': gender,
          'dob': dob,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Error updating profile: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception updating profile: $e');
      return false;
    }
  }
}