import 'package:flutter/material.dart';
import 'ambulance_service_hub.dart';

class AmbulanceServicesPage extends StatelessWidget {
  final String currentAddress;

  const AmbulanceServicesPage({super.key, required this.currentAddress});

  @override
  Widget build(BuildContext context) {
    // Redirect to the new comprehensive ambulance service hub
    return AmbulanceServiceHub(currentAddress: currentAddress);
  }
}
