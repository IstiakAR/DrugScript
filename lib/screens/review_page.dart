// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:drugscript/models/clinic_model.dart';
import 'package:drugscript/models/review_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Review App',
      home: ReviewHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ReviewHomePage extends StatelessWidget {
  const ReviewHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Review Type'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Doctor Review'),
              Tab(text: 'Hospital/Clinic Review'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [DoctorSelectionPage(), ClinicSelectionPage()],
        ),
      ),
    );
  }
}

class DoctorSelectionPage extends StatefulWidget {
  const DoctorSelectionPage({super.key});

  @override
  State<DoctorSelectionPage> createState() => _DoctorSelectionPageState();
}

class _DoctorSelectionPageState extends State<DoctorSelectionPage> {
  final TextEditingController _doctorIdController = TextEditingController();
  final String _baseUrl = 'https://fastapi-app-production-6e30.up.railway.app';
  bool _loadingTop = true;
  List<Map<String, dynamic>> _topDoctors = [];


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
    setState(() => _loadingTop = true);
    try {
      final uri = Uri.parse('$_baseUrl/doctors/top'); // adjust endpoint
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
        debugPrint('Failed to load top doctors: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching top doctors: $e');
    } finally {
      setState(() => _loadingTop = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          TextFormField(
            controller: _doctorIdController,
            decoration: const InputDecoration(
              labelText: 'Enter Doctor ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final doctorId = _doctorIdController.text.trim();
              if (doctorId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ReviewPage(
                          subjectId: doctorId,
                          isDoctor: true,
                          displayName: doctorId,
                        ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a Doctor ID')),
                );
              }
            },
            child: const Text('Review A Doctor'),
          ),

          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Top Rated Doctors',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          _loadingTop
              ? const Center(child: CircularProgressIndicator())
              : _topDoctors.isEmpty
              ? const Text('No data')
              : Column(
                children:
                    _topDoctors.map((doc) {
                      return ListTile(
                        title: Text(doc['subject_id'] ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        subtitle: Row(
                          children: [
                            // spread the generated list so you don’t end up with a nested List<Widget>
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < doc['average_rating']
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "( ${doc['average_rating'].toStringAsFixed(1)} )",
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => ReviewPage(
                                      subjectId: doc['subject_id'],
                                      isDoctor: true,
                                      displayName: doc['subject_id'] ?? 'Unnamed',
                                    ),
                              ),
                            ),
                      );
                    }).toList(),
              ),
        ],
      ),
    );
  }
}




class ClinicSelectionPage extends StatefulWidget {
  const ClinicSelectionPage({super.key});

  @override
  State<ClinicSelectionPage> createState() => _ClinicSelectionPageState();
}

class _ClinicSelectionPageState extends State<ClinicSelectionPage> {
  final _controller = TextEditingController();
  final _baseUrl = 'https://fastapi-app-production-6e30.up.railway.app';

  bool _loadingTop = true;
  List<Map<String, dynamic>> _topClinics = [];

  final List<Clinic> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
    _fetchTopClinics(); 
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _controller.text.trim();
    // cancel any pending search
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.length < 2) {
        setState(() => _results.clear());
      } else {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _loading = true;
      _results.clear();
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
        debugPrint('Search error ${resp.statusCode}: ${resp.body}');
        // you could show a SnackBar here if you like
      } else {
        final List data = jsonDecode(resp.body);
        setState(() {
          _results.addAll(data.map((e) => Clinic.fromJson(e)));
        });
      }
    } catch (e) {
      debugPrint('Search exception: $e');
    } finally {
      setState(() => _loading = false);
    }
  }


    // Fetch top 5 clinics just like doctors
  Future<void> _fetchTopClinics() async {
    setState(() => _loadingTop = true);
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
        debugPrint('Failed to load top clinics: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching top clinics: $e');
    } finally {
      setState(() => _loadingTop = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Search Hospital/Clinic',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (query.length < 2)
                      ? (_loadingTop
                          ? const Center(child: CircularProgressIndicator())
                          : _topClinics.isEmpty
                              ? const Center(child: Text('No top hospitals'))
                              : ListView.separated(
                                  itemCount: _topClinics.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (ctx, i) {
                                    final clinic = _topClinics[i];
                                    return ListTile(
                                      title: Text(clinic['displayName'] ?? clinic['subject_id']),
                                      subtitle: Row(
                                        children: [
                                          ...List.generate(
                                            5,
                                            (j) => Icon(
                                              j < clinic['average_rating']
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "( ${clinic['average_rating'].toStringAsFixed(1)} )",
                                            style: const TextStyle(fontSize: 18),
                                          ),
                                        ],
                                      ),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ReviewPage(
                                            subjectId: clinic['subject_id'],
                                            isDoctor: false,
                                            displayName: clinic['displayName'] ?? clinic['subject_id'],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ))
                      : (_results.isEmpty
                          ? const Center(child: Text('No results found'))
                          : ListView.separated(
                              itemCount: _results.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final clinic = _results[i];
                                return ListTile(
                                  title: Text(clinic.displayName),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ReviewPage(
                                        subjectId: clinic.id,
                                        isDoctor: false,
                                        displayName: clinic.displayName,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )),
            ),
          ],
        ),
      ),
    );
  }

}




class ReviewPage extends StatefulWidget {
  final String subjectId; // the clinic or doctor ID
  final bool isDoctor;
  final String displayName; // the human-readable name

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
  int sumRating = 0;
  int reviewLength = 0;
  List<Review> _reviews = [];
  bool _loading = true;
  final String baseUrl = 'https://fastapi-app-production-6e30.up.railway.app';

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _loading = true);
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
      setState(() => _loading = false);
    }
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();

    final body = json.encode({
      "subject_id": widget.subjectId,
      "displayName" : widget.displayName,
      "is_doctor": widget.isDoctor,
      "rating": _rating.toInt(),
      "review": _reviewCtrl.text,
      "average_rating": (sumRating + _rating) / (reviewLength + 1),
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
      _reviewCtrl.clear();
      setState(() => _rating = 3.0);
      _fetchReviews();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Review submitted!')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Submit failed')));
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final reviews = _reviews;
    final total = reviews.length;
    final sumReview = total > 0 ? reviews.map((r) => r.rating).reduce((a, b) => a + b) : 0;
    final avg =
        total > 0
            ? sumReview / total
            : 0.0;
    sumRating = sumReview;
    reviewLength = total;
    
    final counts = List<int>.filled(5, 0);
    for (var r in reviews) {
      final idx = (r.rating.clamp(1, 5) - 1).toInt();
      counts[idx]++;
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.displayName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // -- Review Form --
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _reviewCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Your Review',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter a review' : null,
                    minLines: 5,    // sets the initial height
                    maxLines: 8,    // allows it to grow up to 8 lines
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Rating:'),
                      const SizedBox(width: 8),
                      RatingBar.builder(
                        initialRating: _rating,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: false,
                        itemCount: 5,
                        itemPadding: const EdgeInsets.symmetric(horizontal: 2),
                        itemBuilder:
                            (ctx, _) => const Icon(
                              Icons.star,
                              color: Colors.deepPurple,
                            ),
                        onRatingUpdate: (r) => setState(() => _rating = r),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitReview,
                    child: const Text('Submit Review'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Reviews:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            // -- Summary or empty state --
            if (total == 0) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No reviews yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ] else ...[
              // Summary Row
              Row(
                children: [
                  // average
                  Column(
                    children: [
                      Text(
                        avg.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (i) {
                          if (avg >= i + 1) {
                            return const Icon(Icons.star, size: 20);
                          }
                          if (avg > i && avg < i + 1) {
                            return const Icon(Icons.star_half, size: 20);
                          }
                          return const Icon(Icons.star_border, size: 20);
                        }),
                      ),
                      Text(
                        '$total reviews',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  // breakdown
                  Expanded(
                    child: Column(
                      children: List.generate(5, (i) {
                        final star = 5 - i;
                        final count = counts[star - 1];
                        final pct = count / total;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Text('$star'),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: pct,
                                  backgroundColor: Colors.grey.shade300,
                                  valueColor: AlwaysStoppedAnimation(
                                    Colors.blue,
                                  ),
                                  minHeight: 10,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('$count'),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),
            // -- List of reviews --
            Expanded(
              child: ListView.builder(
                itemCount: total,
                itemBuilder: (ctx, idx) {
                  final r = reviews[idx];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(child: Text(r.userName[0])),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.userName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        ...List.generate(
                                          5,
                                          (i) => Icon(
                                            i < r.rating
                                                ? Icons.star
                                                : Icons.star_border,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${r.createdAt.toLocal().year}-${r.createdAt.toLocal().month.toString().padLeft(2, '0')}-${r.createdAt.toLocal().day.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected:
                                    (v) => ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          v == 'spam'
                                              ? 'Flagged as spam'
                                              : 'Flagged as inappropriate',
                                        ),
                                      ),
                                    ),
                                itemBuilder:
                                    (_) => const [
                                      PopupMenuItem(
                                        value: 'inappropriate',
                                        child: Text('Flag as inappropriate'),
                                      ),
                                      PopupMenuItem(
                                        value: 'spam',
                                        child: Text('Flag as spam'),
                                      ),
                                    ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(r.review),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('Was this review helpful?'),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed:
                                    () => ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      const SnackBar(content: Text('Thanks!')),
                                    ),
                                child: const Text('Yes'),
                              ),
                              const SizedBox(width: 4),
                              OutlinedButton(
                                onPressed:
                                    () => ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      const SnackBar(content: Text('Thanks!')),
                                    ),
                                child: const Text('No'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
