// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'services/api_service.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}


class _ProfileState extends State<Profile> {
  
  User? user; // Change to nullable
  // ignore: unused_field
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isEditing = false;
  
  // Initialize controllers directly instead of using late
  final TextEditingController _nameController = TextEditingController(text: 'No Name');
  final TextEditingController _bloodTypeController = TextEditingController(text: 'Not specified');
  final TextEditingController _allergiesController = TextEditingController(text: 'None');
  final TextEditingController _emergencyContactController = TextEditingController(text: 'Not specified');
  final TextEditingController _medicalConditionsController = TextEditingController(text: 'None');
  final TextEditingController _ageController = TextEditingController(text: 'Not specified');
  final TextEditingController _addressController = TextEditingController(text: 'Not specified');
  final TextEditingController _phoneController = TextEditingController(text: 'Not specified');
  final TextEditingController _genderController = TextEditingController(text: 'Not specified');
  final TextEditingController _dobController = TextEditingController(text: 'Not specified');
  
  @override
  void initState() {
    super.initState();
    // Get the user and update the name controller if available
    user = FirebaseAuth.instance.currentUser;
    if (user != null && user!.displayName != null) {
      _nameController.text = user!.displayName!;
    }
    
    // Make sure blood type has a valid value from our list
    final validBloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Not specified'];
    if (!validBloodTypes.contains(_bloodTypeController.text)) {
      _bloodTypeController.text = 'Not specified';
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _emergencyContactController.dispose();
    _medicalConditionsController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }
  
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }
  
  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });
    
    // Check for empty fields and restore default values
    if (_nameController.text.trim().isEmpty) {
      _nameController.text = user?.displayName ?? 'No Name';
    }
    
    if (_bloodTypeController.text.trim().isEmpty) {
      _bloodTypeController.text = 'Not specified';
    }
    
    if (_allergiesController.text.trim().isEmpty) {
      _allergiesController.text = 'None';
    }
    
    if (_emergencyContactController.text.trim().isEmpty) {
      _emergencyContactController.text = 'Not specified';
    }
    
    if (_medicalConditionsController.text.trim().isEmpty) {
      _medicalConditionsController.text = 'None';
    }
    
    if (_ageController.text.trim().isEmpty) {
      _ageController.text = 'Not specified';
    }
    
    if (_addressController.text.trim().isEmpty) {
      _addressController.text = 'Not specified';
    }
    
    if (_phoneController.text.trim().isEmpty) {
      _phoneController.text = 'Not specified';
    }
    
    if (_genderController.text.trim().isEmpty) {
      _genderController.text = 'Not specified';
    }
    
    if (_dobController.text.trim().isEmpty) {
      _dobController.text = 'Not specified';
    }
    
    // Save data to FastAPI backend
    final success = await _apiService.updateUserProfile(
      name: _nameController.text,
      bloodType: _bloodTypeController.text,
      allergies: _allergiesController.text,
      emergencyContact: _emergencyContactController.text,
      medicalConditions: _medicalConditionsController.text,
      age: _ageController.text,
      address: _addressController.text,
      phone: _phoneController.text,
      gender: _genderController.text,
      dob: _dobController.text,
    );
    
    setState(() {
      _isLoading = false;
      _isEditing = false;
    });
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }
  
  // Add this method to handle cancellation
  void _cancelEdit() {
    // Reset controllers to their original values
    setState(() {
      // Reset user name if available
      if (user != null && user!.displayName != null) {
        _nameController.text = user!.displayName!;
      } else {
        _nameController.text = 'No Name';
      }
      
      // Reset other fields to default values
      _bloodTypeController.text = 'Not specified';
      _allergiesController.text = 'None';
      _emergencyContactController.text = 'Not specified';
      _medicalConditionsController.text = 'None';
      _ageController.text = 'Not specified';
      _addressController.text = 'Not specified';
      _phoneController.text = 'Not specified';
      _genderController.text = 'Not specified';
      _dobController.text = 'Not specified';
      
      _isEditing = false;
    });
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        // Format date as MM/DD/YYYY
        _dobController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Profile'),
        actions: [
          // Show save/cancel buttons only in edit mode
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelEdit,
              tooltip: 'Cancel',
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
              tooltip: 'Save',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEditMode,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: signOut,
              tooltip: 'Logout',
            ),
          ],
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/homePage'),
        ),
      ),

      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info section
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null ? const Icon(Icons.person, size: 30) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _isEditing 
                            ? TextField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                ),
                              )
                            : Text(
                                _nameController.text,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                          Text(
                            user?.email ?? 'No Email',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Personal Information section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Personal Information',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Age
                    _buildInfoField(
                      'Age',
                      _ageController,
                      Icons.calendar_today,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: TextInputType.number,
                    ),
                    
                    // Gender
                    _buildInfoField(
                      'Gender',
                      _genderController,
                      Icons.person_outline,
                    ),
                    
                    // Address
                    _buildInfoField(
                      'Address',
                      _addressController,
                      Icons.home,
                    ),
                    
                    // Phone
                    _buildInfoField(
                      'Phone Number',
                      _phoneController,
                      Icons.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: TextInputType.phone,
                    ),
                    
                    // Date of Birth
                    _isEditing 
                      ? GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: TextField(
                              controller: _dobController,
                              decoration: InputDecoration(
                                labelText: 'Date of Birth',
                                prefixIcon: Icon(Icons.cake),
                                suffixIcon: Icon(Icons.calendar_today, size: 18),
                              ),
                            ),
                          ),
                        )
                      : ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.cake),
                          title: Text('Date of Birth'),
                          subtitle: Text(_dobController.text),
                        ),
                  ],
                ),
              ),
              
              const Divider(),

              // Medical Information section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Medical Information',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Blood Type
                    _buildInfoField(
                      'Blood Type',
                      _bloodTypeController,
                      Icons.bloodtype,
                    ),
                    
                    // Allergies
                    _buildInfoField(
                      'Allergies',
                      _allergiesController,
                      Icons.warning_amber,
                    ),
                    
                    // Medical Conditions
                    _buildInfoField(
                      'Medical Conditions',
                      _medicalConditionsController,
                      Icons.medical_services,
                    ),
                    
                    // Emergency Contact
                    _buildInfoField(
                      'Emergency Contact',
                      _emergencyContactController,
                      Icons.contact_phone,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
  
  Widget _buildInfoField(String label, TextEditingController controller, IconData icon, {List<TextInputFormatter>? inputFormatters, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _isEditing && label != 'Blood Type' && label != 'Gender'
        ? TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
            ),
            inputFormatters: inputFormatters,
            keyboardType: keyboardType,
          )
        : _isEditing && label == 'Blood Type'
          ? DropdownButtonFormField<String>(
              value: _bloodTypeController.text,
              items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Not specified']
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _bloodTypeController.text = value;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon),
              ),
            )
          : _isEditing && label == 'Gender'
            ? DropdownButtonFormField<String>(
                value: _genderController.text,
                items: ['Male', 'Female', 'Prefer not to say', 'Not specified']
                  .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                  .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _genderController.text = value;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: label,
                  prefixIcon: Icon(icon),
                ),
              )
            : ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(icon),
                title: Text(label),
                subtitle: Text(controller.text),
              ),
    );
  }
}
