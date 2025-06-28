import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../utils/constants.dart';

class ChatService {
  final AuthService _authService = AuthService();

  Future<List<dynamic>> getMessages() async {
    final token = await _authService.getIdToken();
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/messages/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<bool> sendMessage(String senderId, String content) async {
    final token = await _authService.getIdToken();
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/messages/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'sender_id': senderId, 'content': content}),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<Map<String, dynamic>?> getLatestMessage() async {
    final token = await _authService.getIdToken();
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/messages/latest'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data.isNotEmpty ? data : null;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserDetails(String userId) async {
    final token = await _authService.getIdToken();
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/profile/public/$userId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }
}
