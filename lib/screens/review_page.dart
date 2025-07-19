import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:drugscript/services/ServerBaseURL.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medical Reviews',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF5C6BC0),
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF2C3E50),
          elevation: 0,
          centerTitle: true,
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Color(0xFF5C6BC0),
          unselectedLabelColor: Color(0xFF7F8C8D),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5C6BC0),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF5C6BC0),
            side: const BorderSide(color: Color(0xFF5C6BC0)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const ReviewHomePage(),
    );
  }
}

// Main Review Home Page with Tabs
class ReviewHomePage extends StatefulWidget {
  const ReviewHomePage({super.key});

  @override
  State<ReviewHomePage> createState() => _ReviewHomePageState();
}

class _ReviewHomePageState extends State<ReviewHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color _primaryColor = const Color(0xFF5C6BC0);
  final Color _textPrimary = const Color(0xFF2C3E50);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.rate_review_rounded, color: _primaryColor),
              const SizedBox(width: 8),
              Text(
                'Medical Reviews',
                style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Column(
              children: [
                TabBar(
                  labelColor: _primaryColor,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: _primaryColor,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: [
                    Tab(
                      icon: Icon(Icons.person, color: _primaryColor),
                      text: 'Doctor Reviews',
                    ),
                    Tab(
                      icon: Icon(Icons.local_hospital, color: Colors.grey[600]),
                      text: 'Clinic Reviews',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            DoctorSelectionPage(),
            ClinicSelectionPage(),
          ],
        ),
      ),
    );
  }
}

// Doctor Selection Page
class DoctorSelectionPage extends StatefulWidget {
  const DoctorSelectionPage({super.key});

  @override
  State<DoctorSelectionPage> createState() => _DoctorSelectionPageState();
}

class _DoctorSelectionPageState extends State<DoctorSelectionPage> with AutomaticKeepAliveClientMixin {
  final TextEditingController _doctorIdController = TextEditingController();
  final String _baseUrl = ServerConfig.baseUrl;
  bool _loadingTop = true;
  bool _isError = false;
  List<Map<String, dynamic>> _topDoctors = [];

  // Design colors
  final Color _primaryColor = const Color(0xFF5C6BC0);
  final Color _accentColor = const Color(0xFF42A5F5);
  final Color _textPrimary = const Color(0xFF2C3E50);
  final Color _textSecondary = const Color(0xFF7F8C8D);
  final Color _starColor = const Color(0xFFFFC107);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchTopDoctors();
  }

  @override
  void dispose() {
    _doctorIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchTopDoctors() async {
    setState(() {
      _loadingTop = true;
      _isError = false;
    });
    
    try {
      final uri = Uri.parse('$_baseUrl/doctors/top');
      final user = FirebaseAuth.instance.currentUser;
      final token = user != null ? await user.getIdToken() : null;
      
      final resp = await http.get(
        uri.replace(queryParameters: {'limit': '5'}),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      
      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body);
        setState(() => _topDoctors = List<Map<String, dynamic>>.from(data));
      } else {
        setState(() => _isError = true);
        debugPrint('Failed to load top doctors: ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _isError = true);
      debugPrint('Error fetching top doctors: $e');
    } finally {
      setState(() => _loadingTop = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        color: _primaryColor,
        onRefresh: _fetchTopDoctors,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchCard(),
              const SizedBox(height: 24),
              _buildTopDoctorsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.search, color: _primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Find a Doctor to Review',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Enter the ID of the doctor you want to review',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _doctorIdController,
              decoration: InputDecoration(
                hintText: 'Doctor ID',
                prefixIcon: Icon(Icons.person_outline, color: _primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.rate_review),
                label: const Text('Submit Review'),
                onPressed: () {
                  final doctorId = _doctorIdController.text.trim();
                  if (doctorId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviewPage(
                          subjectId: doctorId,
                          isDoctor: true,
                          displayName: doctorId,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: const [
                            Icon(Icons.info_outline, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Please enter a Doctor ID'),
                          ],
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopDoctorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: _accentColor),
            const SizedBox(width: 8),
            Text(
              'Top Rated Doctors',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _loadingTop
            ? _buildLoadingDoctors()
            : _isError
                ? _buildErrorState()
                : _topDoctors.isEmpty
                    ? _buildEmptyState()
                    : _buildDoctorsList(),
      ],
    );
  }

  Widget _buildLoadingDoctors() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          const Text(
            'Unable to load top doctors',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Please check your connection and try again',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchTopDoctors,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No top doctors found',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to review a doctor!',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _topDoctors.length,
      itemBuilder: (context, index) {
        final doc = _topDoctors[index];
        final docId = doc['subject_id'] ?? 'Unnamed';
        final rating = (doc['average_rating'] as num).toDouble();
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewPage(
                    subjectId: docId,
                    isDoctor: true,
                    displayName: 'Dr. $docId',
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person,
                          size: 32,
                          color: _primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. $docId',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              ...List.generate(
                                5,
                                (i) => Icon(
                                  i < rating.floor()
                                      ? Icons.star
                                      : i < rating
                                          ? Icons.star_half
                                          : Icons.star_border,
                                  color: _starColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: _textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Clinic Selection Page
class ClinicSelectionPage extends StatefulWidget {
  const ClinicSelectionPage({super.key});

  @override
  State<ClinicSelectionPage> createState() => _ClinicSelectionPageState();
}

class _ClinicSelectionPageState extends State<ClinicSelectionPage> with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  final _baseUrl = ServerConfig.baseUrl;

  bool _loadingTop = true;
  bool _isTopError = false;
  List<Map<String, dynamic>> _topClinics = [];

  final List<Clinic> _searchResults = [];
  bool _searching = false;
  bool _searchError = false;
  Timer? _debounce;

  // Design colors
  final Color _primaryColor = const Color(0xFF5C6BC0);
  final Color _accentColor = const Color(0xFF42A5F5);
  final Color _textPrimary = const Color(0xFF2C3E50);
  final Color _textSecondary = const Color(0xFF7F8C8D);
  final Color _starColor = const Color(0xFFFFC107);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchTopClinics();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.length < 2) {
        setState(() => _searchResults.clear());
      } else {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _searching = true;
      _searchError = false;
      _searchResults.clear();
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = user != null ? await user.getIdToken() : null;
      final uri = Uri.parse(
        '$_baseUrl/clinics/_search',
      ).replace(queryParameters: {'q': query, 'limit': '20'});

      final resp = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
      );

      if (resp.statusCode != 200) {
        setState(() => _searchError = true);
        debugPrint('Search error ${resp.statusCode}: ${resp.body}');
      } else {
        final List data = jsonDecode(resp.body);
        setState(() {
          _searchResults.addAll(data.map((e) => Clinic.fromJson(e)));
        });
      }
    } catch (e) {
      setState(() => _searchError = true);
      debugPrint('Search exception: $e');
    } finally {
      setState(() => _searching = false);
    }
  }

  Future<void> _fetchTopClinics() async {
    setState(() {
      _loadingTop = true;
      _isTopError = false;
    });
    
    try {
      final uri = Uri.parse('$_baseUrl/clinics/top');
      final user = FirebaseAuth.instance.currentUser;
      final token = user != null ? await user.getIdToken() : null;
      final resp = await http.get(
        uri.replace(queryParameters: {'limit': '5'}),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      
      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body);
        setState(() => _topClinics = List<Map<String, dynamic>>.from(data));
      } else {
        setState(() => _isTopError = true);
        debugPrint('Failed to load top clinics: ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _isTopError = true);
      debugPrint('Error fetching top clinics: $e');
    } finally {
      setState(() => _loadingTop = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final query = _searchController.text.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        color: _primaryColor,
        onRefresh: _fetchTopClinics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 24),
              
              // Show search results if searching, otherwise show top clinics
              if (query.length >= 2)
                _buildSearchResults()
              else 
                _buildTopClinics(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.search, color: _primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Find a Hospital or Clinic',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Search by name or location',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search hospitals and clinics',
                prefixIcon: Icon(Icons.search, color: _primaryColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults.clear());
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopClinics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, color: _accentColor),
            const SizedBox(width: 8),
            Text(
              'Top Rated Facilities',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _loadingTop
            ? _buildLoadingClinics()
            : _isTopError
                ? _buildErrorState(retry: _fetchTopClinics)
                : _topClinics.isEmpty
                    ? _buildEmptyState()
                    : _buildClinicsList(),
      ],
    );
  }
  
  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.search, color: _accentColor),
            const SizedBox(width: 8),
            Text(
              'Search Results',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _searching
            ? _buildLoadingClinics()
            : _searchError
                ? _buildErrorState(
                    message: 'Search failed. Please try again.',
                    retry: () => _performSearch(_searchController.text),
                  )
                : _searchResults.isEmpty
                    ? _buildEmptyState(message: 'No facilities match your search')
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final clinic = _searchResults[index];
                          return _buildClinicItem(
                            name: clinic.displayName,
                            id: clinic.id,
                            hasRating: false,
                          );
                        },
                      ),
      ],
    );
  }

  Widget _buildClinicsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _topClinics.length,
      itemBuilder: (context, index) {
        final clinic = _topClinics[index];
        final name = clinic['displayName'] ?? clinic['subject_id'] ?? 'Unknown Facility';
        final id = clinic['subject_id'] ?? '';
        final rating = (clinic['average_rating'] as num).toDouble();
        
        return _buildClinicItem(
          name: name,
          id: id,
          rating: rating,
          hasRating: true,
        );
      },
    );
  }
  
  Widget _buildClinicItem({
    required String name,
    required String id,
    double rating = 0,
    required bool hasRating,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReviewPage(
                subjectId: id,
                isDoctor: false,
                displayName: name,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.local_hospital,
                      size: 32,
                      color: _accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                      if (hasRating) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < rating.floor()
                                    ? Icons.star
                                    : i < rating
                                        ? Icons.star_half
                                        : Icons.star_border,
                                color: _starColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: _textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingClinics() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState({String? message, VoidCallback? retry}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            message ?? 'Unable to load facilities',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Please check your connection and try again',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (retry != null)
            ElevatedButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({String? message}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message ?? 'No top facilities found',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message != null
                ? 'Try adjusting your search terms'
                : 'Be the first to review a facility!',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Review Page
class ReviewPage extends StatefulWidget {
  final String subjectId;
  final bool isDoctor;
  final String displayName;

  const ReviewPage({
    super.key,
    required this.subjectId,
    required this.isDoctor,
    required this.displayName,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _reviewCtrl = TextEditingController();
  double _rating = 3.0;
  int _sumRating = 0;
  int _reviewLength = 0;
  List<Review> _reviews = [];
  bool _loading = true;
  bool _submitting = false;
  bool _hasError = false;

  // Design colors
  final Color _primaryColor = const Color(0xFF5C6BC0);
  final Color _textPrimary = const Color(0xFF2C3E50);
  final Color _textSecondary = const Color(0xFF7F8C8D);
  final Color _starColor = const Color(0xFFFFC107);

  final String baseUrl = ServerConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchReviews() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();
      final uri = Uri.parse('$baseUrl/reviews').replace(
        queryParameters: {
          "subject_id": widget.subjectId,
          "is_doctor": widget.isDoctor.toString(),
        },
      );
      
      final resp = await http.get(
        uri,
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );
      
      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body);
        setState(() {
          _reviews = data.map((e) => Review.fromJson(e)).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final token = await user?.getIdToken();

      final body = json.encode({
        "subject_id": widget.subjectId,
        "displayName": widget.displayName,
        "is_doctor": widget.isDoctor,
        "rating": _rating.toInt(),
        "review": _reviewCtrl.text,
        "average_rating": (_sumRating + _rating.toInt()) / (_reviewLength + 1),
      });

      final resp = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (resp.statusCode == 201) {
        _showSuccessDialog();
        _reviewCtrl.clear();
        setState(() => _rating = 3.0);
        _fetchReviews();
      } else {
        _showErrorSnackBar('Failed to submit review. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('An error occurred. Please try again.');
      debugPrint('Error submitting review: $e');
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFF4CAF50),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Thank You!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your review has been submitted successfully.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate review statistics
    if (!_loading && !_hasError && _reviews.isNotEmpty) {
      final total = _reviews.length;
      final sumReview = _reviews.fold(0, (sum, r) => sum + r.rating);
      _sumRating = sumReview;
      _reviewLength = total;
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.displayName),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_hasError)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchReviews,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: _loading
          ? _buildLoadingState()
          : _hasError
              ? _buildErrorState()
              : _buildReviewContent(),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 60,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load reviews',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchReviews,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewContent() {
    final reviews = _reviews;
    final total = reviews.length;
    final avgRating = total > 0
        ? reviews.fold(0, (sum, r) => sum + r.rating) / total
        : 0.0;

    // Prepare the star count breakdown
    final counts = List<int>.filled(5, 0);
    for (var r in reviews) {
      final idx = (r.rating.clamp(1, 5) - 1).toInt();
      counts[idx]++;
    }

    return RefreshIndicator(
      onRefresh: _fetchReviews,
      color: _primaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildReviewForm(),
            const SizedBox(height: 24),
            
            // Reviews header
            Row(
              children: [
                Icon(Icons.reviews, color: _primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Reviews',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Reviews summary
            if (total == 0)
              _buildEmptyReviews()
            else
              _buildReviewsSummary(total, avgRating, counts),
            
            const SizedBox(height: 24),
            
            // Individual reviews
            ...reviews.map((r) => _buildReviewCard(r)),
            
            // Bottom padding
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.rate_review, color: _primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Write a Review',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reviewCtrl,
                decoration: InputDecoration(
                  labelText: 'Your Review',
                  hintText: 'Share your experience...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter a review' : null,
                minLines: 4,
                maxLines: 6,
                maxLength: 500,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Your Rating:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: RatingBar.builder(
                      initialRating: _rating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: false,
                      itemCount: 5,
                      itemSize: 32,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 2),
                      itemBuilder: (ctx, _) => Icon(
                        Icons.star,
                        color: _starColor,
                      ),
                      onRatingUpdate: (r) => setState(() => _rating = r),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _rating.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _submitting
                      ? Container(
                          width: 24,
                          height: 24,
                          padding: const EdgeInsets.all(2.0),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(_submitting ? 'Submitting...' : 'Submit Review'),
                  onPressed: _submitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyReviews() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.star_border,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share your experience!',
            style: TextStyle(color: _textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSummary(int total, double avgRating, List<int> counts) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Average rating display
              Column(
                children: [
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      if (avgRating >= i + 1) {
                        return Icon(Icons.star, size: 20, color: _starColor);
                      }
                      if (avgRating > i && avgRating < i + 1) {
                        return Icon(Icons.star_half, size: 20, color: _starColor);
                      }
                      return Icon(Icons.star_border, size: 20, color: _starColor);
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$total ${total == 1 ? 'review' : 'reviews'}',
                    style: TextStyle(color: _textSecondary),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              
              // Rating breakdown
              Expanded(
                child: Column(
                  children: List.generate(5, (i) {
                    final star = 5 - i;
                    final count = counts[star - 1];
                    final pct = total > 0 ? count / total : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text('$star'),
                          const SizedBox(width: 4),
                          Icon(Icons.star, size: 14, color: _starColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(_primaryColor),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 24,
                            child: Text(
                              count.toString(),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and rating
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: _primaryColor,
                  child: Text(
                    review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // User name and rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < review.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 18,
                              color: _starColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(review.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // More options
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: _textSecondary),
                  onSelected: (v) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          v == 'spam'
                              ? 'Review reported as spam'
                              : 'Review reported as inappropriate',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'inappropriate',
                      child: Text('Report inappropriate content'),
                    ),
                    PopupMenuItem(
                      value: 'spam',
                      child: Text('Report as spam'),
                    ),
                  ],
                ),
              ],
            ),
            
            // Review content
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                review.review,
                style: TextStyle(
                  fontSize: 15,
                  color: _textPrimary,
                  height: 1.5,
                ),
              ),
            ),
            
            // Helpful buttons
            Divider(color: Colors.grey.shade200),
            Row(
              children: [
                Text(
                  'Was this review helpful?',
                  style: TextStyle(
                    fontSize: 14,
                    color: _textSecondary,
                  ),
                ),
                const Spacer(),
                _buildHelpfulButton('Yes', Icons.thumb_up_outlined),
                const SizedBox(width: 8),
                _buildHelpfulButton('No', Icons.thumb_down_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpfulButton(String label, IconData icon) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thank you for your feedback!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.toLocal().year}-${date.toLocal().month.toString().padLeft(2, '0')}-${date.toLocal().day.toString().padLeft(2, '0')}';
  }
}

// Models
class Review {
  final String id;
  final String subjectId;
  final bool isDoctor;
  final String userName;
  final int rating;
  final String review;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.subjectId,
    required this.isDoctor,
    required this.userName,
    required this.rating,
    required this.review,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      subjectId: json['subject_id'] ?? '',
      isDoctor: json['is_doctor'] ?? false,
      userName: json['user_name'] ?? 'Anonymous',
      rating: json['rating'] ?? 0,
      review: json['review'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

class Clinic {
  final String id;
  final String displayName;

  Clinic({required this.id, required this.displayName});

  factory Clinic.fromJson(Map<String, dynamic> json) {
    return Clinic(
      id: json['id'] ?? '',
      displayName: json['name'] ?? 'Unknown Clinic',
    );
  }
}