import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../utils/constants.dart';

class ChatService {
  final AuthService _authService = AuthService();

  Future<List<dynamic>> getChannels() async {
    final token = await _authService.getIdToken();
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/channels/'),
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

  Future<Map<String, dynamic>?> getGeneralChannel() async {
    final channels = await getChannels();
    return channels.firstWhere(
      (c) => (c['name']?.toLowerCase() ?? '') == 'general',
      orElse: () => null,
    );
  }

  Future<Map<String, dynamic>?> createChannel(String name, String ownerId) async {
    final token = await _authService.getIdToken();
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/channels/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name, 'owner_id': ownerId}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<bool> deleteChannel(String channelId, String ownerId) async {
    final token = await _authService.getIdToken();
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/channels/$channelId?owner_id=$ownerId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<List<dynamic>> getMessages(String channelId) async {
    final token = await _authService.getIdToken();
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/channels/$channelId/messages'),
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

  Future<bool> sendMessage(String channelId, String senderId, String content) async {
    final token = await _authService.getIdToken();
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/channels/$channelId/messages'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'sender_id': senderId, 'content': content}),
    );
    print('Sending message to channel: $channelId with content: $content');
    print('Response status: ${response.statusCode}');
    return response.statusCode == 200 || response.statusCode == 201;
  }
}
