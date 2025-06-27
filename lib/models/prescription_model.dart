class PrescriptionModel {
  final String? id;
  final String? doctorName;
  final String? contact;
  final List<String>? medicines;
  final String? image;
  final String? date;
  final String? diagnosis;
  final String? createdBy;
  final DateTime? createdAt;

  PrescriptionModel({
    this.id,
    this.doctorName,
    this.contact,
    this.medicines,
    this.image,
    this.date,
    this.diagnosis,
    this.createdBy,
    this.createdAt,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionModel(
      id: json['id'],
      doctorName: json['doctor_name'],
      contact: json['contact'],
      medicines: json['medicines']?.cast<String>(),
      image: json['image'],
      date: json['date'],
      diagnosis: json['diagnosis'],
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctor_name': doctorName,
      'contact': contact,
      'medicines': medicines,
      'image': image,
      'date': date,
      'diagnosis': diagnosis,
      'created_by': createdBy,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
