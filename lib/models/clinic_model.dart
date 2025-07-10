class Clinic {
  final String id;
  final String name;
  final String code;
  final String district;

  Clinic({required this.id, required this.name, required this.code, required this.district});

  factory Clinic.fromJson(Map<String, dynamic> json) => Clinic(
    id: json["id"],
    name: json["name"],
    code: json["code"],
    district: json["district"] ?? "",
  );
  String get displayName => district.isNotEmpty ? "$name, $district" : name;
}