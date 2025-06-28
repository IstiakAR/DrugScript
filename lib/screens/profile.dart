import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class Profile extends StatefulWidget {
  final String? userId; // Add this parameter

  const Profile({super.key, this.userId}); // Accept userId in constructor

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isEditing = false;
  bool _isOtherUser = false;

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
    if (user != null && user.displayName != null && widget.userId == null) {
      _controllers['name']!.text = user.displayName!;
    }
    if (!AppConstants.bloodTypes.contains(_controllers['blood_type']!.text)) {
      _controllers['blood_type']!.text = 'Not specified';
    }
    // If viewing another user's profile, disable editing
    if (widget.userId != null) {
      _isOtherUser = true;
      _isEditing = false;
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
      Map<String, dynamic>? cachedData;
      if (widget.userId != null) {
        // No cache for other users
        cachedData = null;
      } else {
        cachedData = await _apiService.loadCachedProfileOnly();
      }
      if (cachedData != null && mounted) {
        setState(() {
          _updateControllers(cachedData!);
        });
      }
    } catch (e) {
      print('Error loading cached profile: $e');
    }
  }

  Future<void> _fetchUserProfileInBackground() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      Map<String, dynamic>? userData;
      if (widget.userId != null) {
        // Fetch another user's profile
        userData = await _apiService.getUserProfileForUser(widget.userId!);
      } else {
        // Fetch current user's profile
        userData = await _apiService.getUserProfile();
      }
      if (userData != null && mounted) {
        setState(() {
          _updateControllers(userData!);
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
    if (!_isOtherUser) {
      setState(() {
        _isEditing = !_isEditing;
      });
    }
  }

  Future<void> _saveChanges() async {
    // Only allow saving for current user, not other users
    if (_isOtherUser) return;

    try {
      setState(() => _isLoading = true);
      final user = _authService.currentUser;
      
      // Always map "Prefer not to say" to "Other" for backend
      String genderValue = _controllers['gender']!.text.trim();
      if (genderValue.toLowerCase() == 'prefer not to say') {
        genderValue = 'Other';
      }
      
      // Handle age - convert "Not specified" to empty string or a valid age
      String ageValue = _controllers['age']!.text.trim();
      if (ageValue == 'Not specified' || ageValue.isEmpty) {
        ageValue = ''; // Send empty string instead of "Not specified"
      }
      
      // Handle blood type - ensure it's a valid blood type or empty
      String bloodTypeValue = _controllers['blood_type']!.text.trim();
      if (bloodTypeValue == 'Not specified' || !AppConstants.bloodTypes.contains(bloodTypeValue)) {
        bloodTypeValue = ''; // Send empty string instead of "Not specified"
      }
      
      print('Sending profile data:'); // Debug
      print('Age: "$ageValue"');
      print('Blood Type: "$bloodTypeValue"');
      print('Gender: "$genderValue"');
      
      final success = await _apiService.upsertUserProfile(
        name: _controllers['name']!.text.trim().isEmpty
            ? (user?.displayName ?? 'Unknown')
            : _controllers['name']!.text.trim(),
        age: ageValue,
        address: _controllers['address']!.text.trim(),
        gender: genderValue,
        phone: _controllers['phone']!.text.trim(),
        dateOfBirth: _controllers['date_of_birth']!.text.trim(),
        bloodType: bloodTypeValue,
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
    if (!_isOtherUser) {
      setState(() => _isLoading = true);
      await _loadCachedProfile();
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (_isOtherUser) return; // Don't allow date selection for other users

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
      child: _isEditing && isDropdown && !_isOtherUser
          ? DropdownButtonFormField<String>(
              value: options!.contains(controller.text) ? controller.text : null,
              items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
              onChanged: (value) {
                if (value != null) setState(() => controller.text = value);
              },
              decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
            )
          : _isEditing && !_isOtherUser
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
        title: Text(_isOtherUser ? 'Patient Profile' : 'My Profile'),
        actions: [
          if (!_isEditing && !_isLoading && !_isOtherUser)
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
            if (_isOtherUser && !_isLoading)
            IconButton(
              icon: const Icon(Icons.assessment),
              onPressed: () {}, // arguments for report here
              tooltip: 'View Reports',
            ),
          if (_isEditing && !_isLoading && !_isOtherUser) ...[
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
          ] else if (!_isEditing && !_isOtherUser) ...[
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
                  child: _isOtherUser
                    ? // For other users - center content without photo
                    Center(
                        child: Column(
                          children: [
                            _isEditing && !_isOtherUser
                              ? TextField(
                                  controller: _controllers['name'] ?? TextEditingController(),
                                  decoration: const InputDecoration(labelText: 'Name'),
                                )
                              : Text(
                                  _controllers['name']?.text ?? '',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                          ],
                        ),
                      )
                    : // For current user - show photo and email
                    Row(
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
                                _isEditing && !_isOtherUser
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
              if (_isOtherUser)
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
