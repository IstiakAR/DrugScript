class MedicineModel {
  final String? medicineName;
  final String? genericName;
  final String? strength;
  final String? categoryName;
  final String? dosageForm;
  final String? unit;
  final String? manufacturerName;
  final String? price;
  final String? indication;
  final String? slug;

  MedicineModel({
    this.medicineName,
    this.genericName,
    this.strength,
    this.categoryName,
    this.dosageForm,
    this.unit,
    this.manufacturerName,
    this.price,
    this.indication,
    this.slug,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) {
    return MedicineModel(
      medicineName: json['medicine_name'],
      genericName: json['generic_name'],
      strength: json['strength'],
      categoryName: json['category_name'],
      dosageForm: json['dosage form'],
      unit: json['unit'],
      manufacturerName: json['manufacturer_name'],
      price: json['price']?.toString(),
      indication: json['indication'],
      slug: json['slug'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicine_name': medicineName,
      'generic_name': genericName,
      'strength': strength,
      'category_name': categoryName,
      'dosage form': dosageForm,
      'unit': unit,
      'manufacturer_name': manufacturerName,
      'price': price,
      'indication': indication,
      'slug': slug,
    };
  }
}
