import 'dart:convert';
import 'dart:io';

class StorageService {
  // Convert image file to base64
  static Future<String> imageToBase64(File imageFile) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      return base64Encode(imageBytes);
    } catch (e) {
      print('Error converting image to base64: $e');
      return '';
    }
  }

  // Convert base64 to image bytes
  static List<int>? base64ToImageBytes(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      print('Error converting base64 to image bytes: $e');
      return null;
    }
  }
}
