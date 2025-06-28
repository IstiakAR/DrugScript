import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';

class ApiService {
  final AuthService _authService = AuthService();
  
  // Cache keys
  static const String _profileCacheKey = 'user_profile_cache';
  static const String _profileTimestampKey = 'user_profile_timestamp';
  
  // Cache duration (30 days for persistent cache)
  static const Duration _cacheDuration = Duration(days: 30);

  // Auth login method - handles login/register with Firebase token
  Future<Map<String, dynamic>?> authLogin() async {
    try {
      // Get the Firebase ID token
      final idToken = await _authService.getIdToken();
      if (idToken == null) {
        throw Exception('User not authenticated');
      }

      // Make the API call
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/profile/auth-login'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Login successful: ${data['message']}');
        print('Is new user: ${data['is_new_user']}');
        return data;
      } else {
        throw Exception('Login failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Auth login error: $e');
      return null;
    }
  }

  // Clear cache for current user
  Future<void> clearCache() async {
    final user = _authService.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_profileCacheKey}_${user.uid}');
      await prefs.remove('${_profileTimestampKey}_${user.uid}');
    }
  }

  // Save data to persistent cache
  Future<void> _saveToCache(String userId, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(data);
      await prefs.setString('${_profileCacheKey}_$userId', jsonData);
      await prefs.setString('${_profileTimestampKey}_$userId', 
          DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving to cache: $e');
    }
  }

  // Load data from persistent cache
  Future<Map<String, dynamic>?> _loadFromCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString('${_profileCacheKey}_$userId');
      final timestamp = prefs.getString('${_profileTimestampKey}_$userId');
      
      if (jsonData != null) {
        // Check if cache is valid (optional - remove if you want it to never expire)
        if (timestamp != null) {
          final cacheTime = DateTime.parse(timestamp);
          if (DateTime.now().difference(cacheTime) > _cacheDuration) {
            // Cache expired, but we'll still use it if network fails
            print('Cache expired but will be used if network fails');
          }
        }
        return jsonDecode(jsonData);
      }
    } catch (e) {
      print('Error loading from cache: $e');
    }
    return null;
  }

  // Fetch user profile with persistent caching
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _authService.currentUser;
    if (user == null) return null;

    try {
      // Try to fetch from network first
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
        final Map<String, dynamic> rawData = jsonDecode(response.body);
        
        // Convert all numeric values to strings to avoid type errors
        final Map<String, dynamic> processedData = {};
        rawData.forEach((key, value) {
          if (value != null) {
            processedData[key] = value.toString();
          } else {
            processedData[key] = value;
          }
        });
        
        // Cache the response persistently
        await _saveToCache(user.uid, processedData);
        return processedData;
      } else if (response.statusCode != 404) {
        print('Error getting profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Network error fetching profile: $e');
    }
    
    // If we're here, either network failed or returned an error
    // Try to load from persistent cache
    print('Attempting to load profile from offline cache');
    final cachedData = await _loadFromCache(user.uid);
    if (cachedData != null) {
      print('Using cached profile data');
      return cachedData;
    }
    
    // No network and no cache
    return null;
  }

  // New method to load cached data without network request
  Future<Map<String, dynamic>?> loadCachedProfileOnly() async {
    final user = _authService.currentUser;
    if (user == null) return null;
    
    return _loadFromCache(user.uid);
  }

  // Create or update user profile with cache update
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
        "name": name.trim().isEmpty ? null : name.trim(),
        "age": age.trim().isEmpty || age == 'Not specified' ? null : age.trim(),
        "address": address.trim().isEmpty || address == 'Not specified' ? null : address.trim(),
        "phone": phone.trim().isEmpty || phone == 'Not specified' ? null : phone.trim(),
        "date_of_birth": dateOfBirth.trim().isEmpty || dateOfBirth == 'Not specified' ? null : dateOfBirth.trim(),
        "allergies": allergies?.trim().isEmpty == true || allergies == 'None' || allergies == 'Not specified' ? null : allergies?.trim(),
        "medical_conditions": medicalConditions?.trim().isEmpty == true || medicalConditions == 'None' || medicalConditions == 'Not specified' ? null : medicalConditions?.trim(),
        "emergency_contact": emergencyContact.trim().isEmpty || emergencyContact == 'Not specified' ? null : emergencyContact.trim(),
        "gender": gender.trim().isEmpty || gender == 'Not specified' ? null : gender.trim(),
        "blood_type": bloodType.trim().isEmpty || bloodType == 'Not specified' ? null : bloodType.trim(),
      };

      // Remove null values to avoid sending them to the backend
      profileData.removeWhere((key, value) => value == null);
      
      print('Final profile data being sent: $profileData'); // Debug

      // First check if the profile exists
      final existingProfile = await getUserProfile();
      
      // Determine whether to use POST (create) or PUT (update) based on if profile exists
      final Uri uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.profileEndpoint}');
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
        'X-User-ID': user.uid,
      };
      
      final http.Response response;
      if (existingProfile != null) {
        // Profile exists, use PUT to update
        response = await http.put(
          uri,
          headers: headers,
          body: jsonEncode(profileData),
        );
      } else {
        // Profile doesn't exist, use POST to create
        response = await http.post(
          uri,
          headers: headers,
          body: jsonEncode(profileData),
        );
      }

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      // Add this for debugging
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Profile update failed. Data sent: $profileData');
      }

      final success = response.statusCode == 200 || response.statusCode == 201;
      
      // Update cache if successful
      if (success) {
        // Instead of clearing cache, update it with the new data
        final Map<String, dynamic> cacheData = {
          "name": name.trim().isEmpty ? null : name,
          "age": age.trim().isEmpty || age == 'Not specified' ? null : age,
          "address": address.trim().isEmpty || address == 'Not specified' ? null : address,
          "phone": phone.trim().isEmpty || phone == 'Not specified' ? null : phone,
          "date_of_birth": dateOfBirth.trim().isEmpty || dateOfBirth == 'Not specified' ? null : dateOfBirth,
          "allergies": allergies?.trim().isEmpty == true || allergies == 'None' ? null : allergies,
          "medical_conditions": medicalConditions?.trim().isEmpty == true || medicalConditions == 'None' ? null : medicalConditions,
          "emergency_contact": emergencyContact.trim().isEmpty || emergencyContact == 'Not specified' ? null : emergencyContact,
          "gender": gender,
          "blood_type": bloodType
        };
        
        // Filter out null values
        final Map<String, dynamic> filteredData = {};
        cacheData.forEach((key, value) {
          if (value != null) {
            filteredData[key] = value;
          }
        });
        
        // Save to cache
        await _saveToCache(user.uid, filteredData);
      }

      return success;
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

  // Fetch another user's profile (read-only)
  Future<Map<String, dynamic>?> getUserProfileForUser(String userId) async {
    try {
        final response = await http.get(
          Uri.parse('${AppConstants.baseUrl}/profile/public/$userId'),
          headers: {'Content-Type': 'application/json'},
        );
      if (response.statusCode == 200) {
        final Map<String, dynamic> rawData = jsonDecode(response.body);
        final Map<String, dynamic> processedData = {};
        rawData.forEach((key, value) {
          if (value != null) {
            processedData[key] = value.toString();
          } else {
            processedData[key] = value;
          }
        });
        print('Fetched profile for user $userId: $processedData');
        return processedData;
      }
    } catch (e) {
      print('Error fetching profile for user $userId: $e');
    }
    return null;
  }
}