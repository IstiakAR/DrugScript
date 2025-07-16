import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class Profile extends StatefulWidget {
  final String? userId;
  const Profile({super.key, this.userId});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isEditing = false;
  bool _isOtherUser = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Design colors
  final Color _primaryColor = const Color(0xFF5C6BC0);
  final Color _accentColor = const Color(0xFF42A5F5);
  final Color _textPrimary = const Color(0xFF2C3E50);
  final Color _textSecondary = const Color(0xFF7F8C8D);
  final Color _errorColor = const Color(0xFFF44336);
  final Color _successColor = const Color(0xFF4CAF50);
  final Color _cardColor = Colors.white;
  final Color _bgColor = const Color(0xFFF5F7FA);

  final Map<String, String> _placeholders = {
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
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    _placeholders.forEach((key, value) {
      _controllers[key] = TextEditingController();
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
        userData = await _apiService.getUserProfileForUser(widget.userId!);
      } else {
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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> signOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out', style: TextStyle(color: _textPrimary)),
        content: const Text('Are you sure you want to sign out?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _toggleEditMode() {
    if (!_isOtherUser) {
      setState(() {
        _isEditing = !_isEditing;
      });
      
      if (_isEditing) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_isOtherUser) return;

    try {
      setState(() => _isLoading = true);
      final user = _authService.currentUser;
      
      String genderValue = _controllers['gender']!.text.trim();
      if (genderValue.toLowerCase() == 'prefer not to say') {
        genderValue = 'Other';
      }
      
      String ageValue = _controllers['age']!.text.trim();
      if (ageValue == 'Not specified' || ageValue.isEmpty) {
        ageValue = '';
      }
      
      String bloodTypeValue = _controllers['blood_type']!.text.trim();
      if (bloodTypeValue == 'Not specified' || !AppConstants.bloodTypes.contains(bloodTypeValue)) {
        bloodTypeValue = '';
      }
      
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
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });
        _animationController.reverse();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(success ? 'Profile updated successfully' : 'Failed to update profile'),
              ],
            ),
            backgroundColor: success ? _successColor : _errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.all(8),
            duration: const Duration(milliseconds: 300),
          ),
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
      _animationController.reverse();
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (_isOtherUser) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              onSurface: _textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _primaryColor,
              ),
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
      return const SizedBox.shrink();
    }
    final isDropdown = key == 'blood_type' || key == 'gender';
    final options = key == 'blood_type'
        ? AppConstants.bloodTypes
        : key == 'gender'
            ? AppConstants.genderOptions
            : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _isEditing && isDropdown && !_isOtherUser
          ? FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: DropdownButtonFormField<String>(
                  value: options!.contains(controller.text) ? controller.text : null,
                  items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => controller.text = value);
                  },
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: TextStyle(color: _primaryColor, fontWeight: FontWeight.w500),
                    prefixIcon: Icon(icon, color: _primaryColor),
                    border: InputBorder.none,
                  ),
                  icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
                  hint: Text(_placeholders[key]!),
                ),
              ),
            )
          : _isEditing && !_isOtherUser
              ? FadeTransition(
                  opacity: _fadeAnimation,
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: label,
                      labelStyle: TextStyle(color: _primaryColor, fontWeight: FontWeight.w500),
                      prefixIcon: Icon(icon, color: _primaryColor),
                      hintText: _placeholders[key],
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: _primaryColor, width: 2),
                      ),
                    ),
                    inputFormatters: inputFormatters,
                    keyboardType: keyboardType,
                    style: TextStyle(fontSize: 16, color: _textPrimary),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: _primaryColor, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 14,
                                color: _textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.text.isEmpty ? _placeholders[key]! : controller.text,
                              style: TextStyle(
                                fontSize: 16,
                                color: controller.text.isEmpty ? Colors.grey.shade500 : _textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final photoUrl = user?.photoURL;
    final email = user?.email ?? 'No Email';

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isOtherUser ? 'Patient Profile' : 'My Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: _primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isEditing && !_isLoading && !_isOtherUser)
            IconButton(
              icon: Icon(Icons.refresh, color: _primaryColor),
              onPressed: _fetchUserProfileInBackground,
              tooltip: 'Refresh',
            ),
            
          if (!_isEditing && _isLoading)
            Container(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                ),
              ),
            ),
            
          if (_isOtherUser && !_isLoading)
            IconButton(
              icon: Icon(Icons.assessment, color: _primaryColor),
              onPressed: () {},
              tooltip: 'View Reports',
            ),
            
          if (_isEditing && !_isLoading && !_isOtherUser) ...[
            IconButton(
              icon: Icon(Icons.close, color: _primaryColor),
              onPressed: _cancelEdit,
              tooltip: 'Cancel',
            ),
            IconButton(
              icon: Icon(Icons.save, color: _primaryColor),
              onPressed: _saveChanges,
              tooltip: 'Save',
            ),
          ] else if (!_isEditing && !_isOtherUser) ...[
            IconButton(
              icon: Icon(Icons.edit, color: _primaryColor),
              onPressed: _toggleEditMode,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: Icon(Icons.logout, color: _primaryColor),
              onPressed: signOut,
              tooltip: 'Logout',
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchUserProfileInBackground,
            color: _primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _isOtherUser
                            ? _buildOtherUserHeader()
                            : _buildCurrentUserHeader(photoUrl, email),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Personal Information Section
                  _buildSection(
                    title: 'Personal Information',
                    icon: Icons.person_outline,
                    children: [
                      _buildInfoField('Age', 'age', Icons.cake,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          keyboardType: TextInputType.number),
                      _buildInfoField('Gender', 'gender', Icons.people_outline),
                      _buildInfoField('Address', 'address', Icons.home_outlined),
                      _buildInfoField('Phone Number', 'phone', Icons.phone_outlined,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          keyboardType: TextInputType.phone),
                      // Date of Birth with special handling
                      _isEditing
                          ? GestureDetector(
                              onTap: () => _selectDate(context),
                              child: AbsorbPointer(
                                child: FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: TextField(
                                    controller: _controllers['date_of_birth'],
                                    decoration: InputDecoration(
                                      labelText: 'Date of Birth',
                                      labelStyle: TextStyle(color: _primaryColor, fontWeight: FontWeight.w500),
                                      prefixIcon: Icon(Icons.calendar_today_outlined, color: _primaryColor),
                                      suffixIcon: Icon(Icons.event, color: _primaryColor, size: 18),
                                      hintText: 'Not specified',
                                      hintStyle: TextStyle(color: Colors.grey.shade400),
                                      border: UnderlineInputBorder(
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(color: _primaryColor, width: 2),
                                      ),
                                    ),
                                    style: TextStyle(fontSize: 16, color: _textPrimary),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.calendar_today_outlined, color: _primaryColor, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Date of Birth',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _controllers['date_of_birth']?.text.isNotEmpty == true
                                              ? _controllers['date_of_birth']!.text
                                              : 'Not specified',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: _controllers['date_of_birth']?.text.isNotEmpty == true
                                                ? _textPrimary
                                                : Colors.grey.shade500,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Medical Information Section
                  _buildSection(
                    title: 'Medical Information',
                    icon: Icons.medical_services_outlined,
                    children: [
                      _buildInfoField('Blood Type', 'blood_type', Icons.bloodtype_outlined),
                      _buildInfoField('Allergies', 'allergies', Icons.healing_outlined),
                      _buildInfoField('Medical Conditions', 'medical_conditions', Icons.monitor_heart_outlined),
                      _buildInfoField('Emergency Contact', 'emergency_contact', Icons.contact_phone_outlined),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          
          // Loading overlay
          if (_isLoading && _isEditing)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      )
    );
  }

  Widget _buildCurrentUserHeader(String? photoUrl, String email) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (_isEditing && !_isOtherUser) ...[
            // Editing mode header
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    backgroundColor: _primaryColor.withOpacity(0.1),
                    child: photoUrl == null
                        ? Icon(Icons.person, size: 50, color: _primaryColor)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: _accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _fadeAnimation,
              child: TextField(
                controller: _controllers['name'],
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: _primaryColor, fontWeight: FontWeight.w500),
                  hintText: 'Enter your name',
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: _primaryColor, width: 2),
                  ),
                ),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ),
          ],
          if (!_isEditing || _isOtherUser) ...[
            // View mode header
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                backgroundColor: _primaryColor.withOpacity(0.1),
                child: photoUrl == null
                    ? Icon(Icons.person, size: 50, color: _primaryColor)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    _controllers['name']?.text.isNotEmpty == true
                        ? _controllers['name']!.text
                        : 'No Name',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.email_outlined, size: 16, color: _textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 16,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOtherUserHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: _primaryColor.withOpacity(0.1),
              child: Icon(Icons.person, size: 50, color: _primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              _controllers['name']?.text.isNotEmpty == true
                  ? _controllers['name']!.text
                  : 'Patient',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Patient Profile',
                style: TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: _primaryColor),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
  
}
