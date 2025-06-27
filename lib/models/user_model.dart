class UserModel {
  final String? uid;
  final String? name;
  final String? email;
  final String? photoUrl;
  final String? age;
  final String? address;
  final String? gender;
  final String? phone;
  final String? dateOfBirth;
  final String? bloodType;
  final String? allergies;
  final String? medicalConditions;
  final String? emergencyContact;

  UserModel({
    this.uid,
    this.name,
    this.email,
    this.photoUrl,
    this.age,
    this.address,
    this.gender,
    this.phone,
    this.dateOfBirth,
    this.bloodType,
    this.allergies,
    this.medicalConditions,
    this.emergencyContact,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      name: json['name'],
      email: json['email'],
      photoUrl: json['photo_url'],
      age: json['age'],
      address: json['address'],
      gender: json['gender'],
      phone: json['phone'],
      dateOfBirth: json['date_of_birth'],
      bloodType: json['blood_type'],
      allergies: json['allergies'],
      medicalConditions: json['medical_conditions'],
      emergencyContact: json['emergency_contact'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photo_url': photoUrl,
      'age': age,
      'address': address,
      'gender': gender,
      'phone': phone,
      'date_of_birth': dateOfBirth,
      'blood_type': bloodType,
      'allergies': allergies,
      'medical_conditions': medicalConditions,
      'emergency_contact': emergencyContact,
    };
  }
}
