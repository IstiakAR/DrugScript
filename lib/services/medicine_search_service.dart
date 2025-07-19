// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:drugscript/services/ServerBaseURL.dart';

class MedicineSearchService {
  static const String _baseUrl =
      '${ServerConfig.baseUrl}/medicinesearch';

  static Future<List<dynamic>> searchMedicines(String query) async {
    if (query.isEmpty) {
      print('Search query is empty');
      return [];
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['results'] ?? [];
      } else {
        print('Failed to load data: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  static IconData getMedicineTypeIcon(String dosageForm) {
    final form = dosageForm.toLowerCase();

    if (form.contains('tablet') || form.contains('pill')) {
      return Icons.local_pharmacy_rounded;
    } else if (form.contains('syrup') ||
        form.contains('liquid') ||
        form.contains('solution')) {
      return Icons.opacity_rounded;
    } else if (form.contains('injection') || form.contains('syringe')) {
      return Icons.vaccines_rounded;
    } else if (form.contains('cream') ||
        form.contains('ointment') ||
        form.contains('gel')) {
      return Icons.sanitizer_rounded;
    } else if (form.contains('capsule')) {
      return Icons.medication_rounded;
    } else if (form.contains('drop')) {
      return Icons.water_drop_rounded;
    }

    return Icons.medication_rounded;
  }
}
