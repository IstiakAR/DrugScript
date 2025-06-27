// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../utils/helpers.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isBackgroundLoading = false;  // Added for background loading
  bool _isEditing = false;
  
  // Initialize controllers with default values
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
    _initializeUserData();
    
    // Load the page immediately and fetch data in background
    _loadProfileDataInBackground();
  }

  void _initializeUserData() {
    final user = _authService.currentUser;
    if (user != null && user.displayName != null) {
      _nameController.text = user.displayName!;
    }
    
    // Ensure blood type has a valid value
    if (!AppConstants.bloodTypes.contains(_bloodTypeController.text)) {
      _bloodTypeController.text = 'Not specified';
    }
  }
  
  // New method to load data in background
  void _loadProfileDataInBackground() async {
    // Load cached data first if available (should be almost instant)
    await _loadCachedProfile();
    
    // Then fetch fresh data from API without blocking UI
    if (mounted) {
      _fetchUserProfileInBackground();
    }
  }
  
  // Load cached profile data
  Future<void> _loadCachedProfile() async {
    try {
      final cachedData = await _apiService.loadCachedProfileOnly();
      if (cachedData != null && mounted) {
        setState(() {
          _updateControllers(cachedData);
        });
      }
    } catch (e) {
      print('Error loading cached profile: $e');
    }
  }
  
  // Fetch fresh data in background
  Future<void> _fetchUserProfileInBackground() async {
    if (mounted) {
      setState(() {
        _isBackgroundLoading = true;
      });
    }

    try {
      final userData = await _apiService.getUserProfile();
      
      if (userData != null && mounted) {
        setState(() {
          _updateControllers(userData);
        });
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isBackgroundLoading = false;
        });
      }
    }
  }
  
  // Helper method to update all controllers
  void _updateControllers(Map<String, dynamic> userData) {
    _nameController.text = userData['name'] ?? _nameController.text;
    _bloodTypeController.text = userData['blood_type'] ?? _bloodTypeController.text;
    _allergiesController.text = userData['allergies'] ?? _allergiesController.text;
    _emergencyContactController.text = userData['emergency_contact'] ?? _emergencyContactController.text;
    _medicalConditionsController.text = userData['medical_conditions'] ?? _medicalConditionsController.text;
    _ageController.text = userData['age'] ?? _ageController.text;
    _addressController.text = userData['address'] ?? _addressController.text;
    _phoneController.text = userData['phone'] ?? _phoneController.text;
    _genderController.text = userData['gender'] ?? _genderController.text;
    _dobController.text = userData['date_of_birth'] ?? _dobController.text;
  }
  
  @override
  void dispose() {
    // ...existing code...
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
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
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
    
    final user = _authService.currentUser;
    final success = await _apiService.upsertUserProfile(
      name: _nameController.text.trim().isEmpty 
          ? (user?.displayName ?? 'Unknown') 
          : _nameController.text.trim(),
      age: _ageController.text.trim(),
      address: _addressController.text.trim(),
      gender: _genderController.text.trim(),
      phone: _phoneController.text.trim(),
      dateOfBirth: _dobController.text.trim(),
      bloodType: _bloodTypeController.text.trim(),
      allergies: _allergiesController.text.trim(),
      medicalConditions: _medicalConditionsController.text.trim(),
      emergencyContact: _emergencyContactController.text.trim(),
    );
    
    setState(() {
      _isLoading = false;
      _isEditing = false;
    });
    
    if (mounted) {
      Helpers.showMessage(
        context,
        success ? 'Profile updated successfully' : 'Failed to update profile',
        isError: !success,
      );
    }
  }
  
  void _cancelEdit() {
    setState(() {
      _initializeUserData();
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
        _dobController.text = Helpers.formatDate(picked);
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final photoUrl = user?.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Profile'),
        actions: [
          // Show refresh button when not editing
          if (!_isEditing && !_isBackgroundLoading) 
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchUserProfileInBackground,
              tooltip: 'Refresh',
            ),
          if (!_isEditing && _isBackgroundLoading)
            Container(
              padding: const EdgeInsets.all(10),
              child: const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
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

      // Don't block the UI with a loading indicator - show content immediately
      body: SingleChildScrollView(
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
                              decoration: const InputDecoration(labelText: 'Name'),
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
                  Text(
                    'Personal Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoField('Age', _ageController, Icons.calendar_today,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType: TextInputType.number,
                  ),
                  _buildInfoField('Gender', _genderController, Icons.person_outline),
                  _buildInfoField('Address', _addressController, Icons.home),
                  _buildInfoField('Phone Number', _phoneController, Icons.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType: TextInputType.phone,
                  ),
                  
                  // Date of Birth with special handling
                  _isEditing 
                    ? GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _dobController,
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth',
                              prefixIcon: Icon(Icons.cake),
                              suffixIcon: Icon(Icons.calendar_today, size: 18),
                            ),
                          ),
                        ),
                      )
                    : ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.cake),
                        title: const Text('Date of Birth'),
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
                  Text(
                    'Medical Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoField('Blood Type', _bloodTypeController, Icons.bloodtype),
                  _buildInfoField('Allergies', _allergiesController, Icons.warning_amber),
                  _buildInfoField('Medical Conditions', _medicalConditionsController, Icons.medical_services),
                  _buildInfoField('Emergency Contact', _emergencyContactController, Icons.contact_phone),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoField(String label, TextEditingController controller, IconData icon, 
      {List<TextInputFormatter>? inputFormatters, TextInputType? keyboardType}) {
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
              value: controller.text,
              items: AppConstants.bloodTypes
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    controller.text = value;
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
                // Normalize the value from controller to ensure it matches dropdown options
                value: _normalizeGenderValue(controller.text),
                items: AppConstants.genderOptions
                  .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                  .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      controller.text = value;
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
  
  // Add this helper method to normalize gender values
  String _normalizeGenderValue(String value) {
    // Convert to lowercase and check
    final lowercaseValue = value.toLowerCase().trim();
    
    // Find matching gender option
    for (final option in AppConstants.genderOptions) {
      if (option.toLowerCase() == lowercaseValue) {
        return option; // Return the properly formatted option
      }
    }
    
    // If no match, return the default value
    return AppConstants.genderOptions.first; // 'Not specified' or whatever is first in the list
  }
}
