import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
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
  bool _isEditing = false;

  final Map<String, String> _defaultValues = {
    'name': 'No Name',
    'blood_type': 'Not specified',
    'allergies': 'None',
    'emergency_contact': 'Not specified',
    'medical_conditions': 'None',
    'age': 'Not specified',
    'address': 'Not specified',
    'phone': 'Not specified',
    'gender': 'Not specified',
    'date_of_birth': 'Not specified',
  };

  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _defaultValues.forEach((key, value) {
      _controllers[key] = TextEditingController(text: value);
    });
    _initializeUserData();
    _loadProfileDataInBackground();
  }

  void _initializeUserData() {
    final user = _authService.currentUser;
    if (user != null && user.displayName != null) {
      _controllers['name']!.text = user.displayName!;
    }
    if (!AppConstants.bloodTypes.contains(_controllers['blood_type']!.text)) {
      _controllers['blood_type']!.text = 'Not specified';
    }
  }

  void _loadProfileDataInBackground() async {
    await _loadCachedProfile();
    if (mounted) {
      _fetchUserProfileInBackground();
    }
  }

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

  Future<void> _fetchUserProfileInBackground() async {
    if (mounted) setState(() => _isLoading = true);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateControllers(Map<String, dynamic> userData) {
  _controllers.forEach((key, controller) {
    if (key == 'gender') {
      final genderValue = userData[key];
      if (genderValue != null && genderValue == 'Other') {
        controller.text = 'Prefer not to say';
      } else {
        controller.text = genderValue ?? controller.text;
      }
    } else {
      controller.text = userData[key] ?? controller.text;
    }
  });
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) {
      controller.dispose();
    });
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
    try {
      setState(() => _isLoading = true);
      final user = _authService.currentUser;
      // Always map "Prefer not to say" to "Other" for backend
      String genderValue = _controllers['gender']!.text.trim();
      if (genderValue.toLowerCase() == 'prefer not to say') {
        genderValue = 'Other';
      }
      final success = await _apiService.upsertUserProfile(
        name: _controllers['name']!.text.trim().isEmpty
            ? (user?.displayName ?? 'Unknown')
            : _controllers['name']!.text.trim(),
        age: _controllers['age']!.text.trim(),
        address: _controllers['address']!.text.trim(),
        gender: genderValue,
        phone: _controllers['phone']!.text.trim(),
        dateOfBirth: _controllers['date_of_birth']!.text.trim(),
        bloodType: _controllers['blood_type']!.text.trim(),
        allergies: _controllers['allergies']!.text.trim(),
        medicalConditions: _controllers['medical_conditions']!.text.trim(),
        emergencyContact: _controllers['emergency_contact']!.text.trim(),
      );
      print('API call result: $success'); // Debug: confirm API result
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });
        Helpers.showMessage(
          context,
          success ? 'Profile updated successfully' : 'Failed to update profile',
          isError: !success,
        );
      }
    } catch (e, st) {
      print('Exception in _saveChanges: $e');
      print(st);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Helpers.showMessage(
          context,
          'An error occurred while saving.',
          isError: true,
        );
      }
    }
  }

  void _cancelEdit() async {
    setState(() => _isLoading = true);
    await _loadCachedProfile();
    setState(() {
      _isEditing = false;
      _isLoading = false;
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
        _controllers['date_of_birth']!.text = Helpers.formatDate(picked);
      });
    }
  }

  Widget _buildInfoField(String label, String key, IconData icon,
      {List<TextInputFormatter>? inputFormatters, TextInputType? keyboardType}) {
    final controller = _controllers[key];
    if (controller == null) {
      return const SizedBox.shrink(); // or show an error widget
    }
    final isDropdown = key == 'blood_type' || key == 'gender';
    final options = key == 'blood_type'
        ? AppConstants.bloodTypes
        : key == 'gender'
            ? AppConstants.genderOptions
            : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _isEditing && isDropdown
          ? DropdownButtonFormField<String>(
              value: options!.contains(controller.text) ? controller.text : null,
              items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
              onChanged: (value) {
                if (value != null) setState(() => controller.text = value);
              },
              decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
            )
          : _isEditing
              ? TextField(
                  controller: controller,
                  decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
                  inputFormatters: inputFormatters,
                  keyboardType: keyboardType,
                )
              : ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(icon),
                  title: Text(label),
                  subtitle: Text(controller.text),
                ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final photoUrl = user?.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Profile'),
        actions: [
          if (!_isEditing && !_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchUserProfileInBackground,
              tooltip: 'Refresh',
            ),
          if (!_isEditing && _isLoading)
            Container(
              padding: const EdgeInsets.all(10),
              child: const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          if (_isEditing && !_isLoading) ...[
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
          ] else if (!_isEditing) ...[
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
      body: Stack(
        children: [
          SingleChildScrollView(
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
                                    controller: _controllers['name'] ?? TextEditingController(),
                                    decoration: const InputDecoration(labelText: 'Name'),
                                  )
                                : Text(
                                    _controllers['name']?.text ?? '',
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
                      _buildInfoField('Age', 'age', Icons.calendar_today,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          keyboardType: TextInputType.number),
                      _buildInfoField('Gender', 'gender', Icons.person_outline),
                      _buildInfoField('Address', 'address', Icons.home),
                      _buildInfoField('Phone Number', 'phone', Icons.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          keyboardType: TextInputType.phone),
                      // Date of Birth with special handling
                      _isEditing
                          ? GestureDetector(
                              onTap: () => _selectDate(context),
                              child: AbsorbPointer(
                                child: TextField(
                                  controller: _controllers['date_of_birth'],
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
                              subtitle: Text(_controllers['date_of_birth']?.text ?? ''),
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
                      _buildInfoField('Blood Type', 'blood_type', Icons.bloodtype),
                      _buildInfoField('Allergies', 'allergies', Icons.warning_amber),
                      _buildInfoField('Medical Conditions', 'medical_conditions', Icons.medical_services),
                      _buildInfoField('Emergency Contact', 'emergency_contact', Icons.contact_phone),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading && _isEditing)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
