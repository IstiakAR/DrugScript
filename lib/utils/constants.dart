import 'package:drugscript/services/ServerBaseURL.dart';

class AppConstants {
  // API Base URL
  static const String baseUrl = ServerConfig.baseUrl;
  
  // API Endpoints
  static const String profileEndpoint = '/profile';
  static const String medicineSearchEndpoint = '/medicinesearch';
  static const String addPrescriptionEndpoint = '/add_prescription';
  
  // App Colors
  static const primaryColor = 0xFF2F2F31;
  static const blueColor = 0xFF0077FF;
  static const greenColor = 0xFF6DCDA3;
  
  // Blood Types
  static const List<String> bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];
  
  // Gender Options
  static const List<String> genderOptions = [
    'Male', 'Female', 'Prefer not to say'
  ];
  
  // Diagnosis Options
  static const List<String> diagnosisOptions = [
    'Cardiovascular',
    'Respiratory',
    'Digestive',
    'Nervous',
    'Musculoskeletal',
    'Integumentary',
    'Endocrine',
    'Urinary',
    'Reproductive',
    'Immune',
    'Psychological',
    'Allergic',
    'Infectious',
    'Cancer',
    'Neurological',
    'Head & Neck',
    'Thorax',
    'Abdomen',
    'Pelvis',
    'Diabetes',
    'Hypertension',
    'Asthma',
    'Arthritis',
    'Anemia',
    'Obesity',
    'Thyroid',
    'Gastrointestinal',
    'Kidney',
    'Liver',
    'Skin',
    'Eye',
    'Ear',
    'Autoimmune',
    'Genetic',
    'Metabolic',
    'Vascular',
    'Blood',
    'Hormonal',
    'Neurological Disorders',
    'Other',
  ];
}
