import 'package:firebase_auth/firebase_auth.dart';

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
  final String baseUrl = 'https://fastapi-app-production-6e30.up.railway.app';
  
  Future<String?> _getAuthToken() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return await user.getIdToken(true);
  }
}