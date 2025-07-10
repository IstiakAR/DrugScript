import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter/services.dart' show rootBundle;

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

  @override
  void dispose() {
    _doctorIdController.dispose();
    super.dispose();
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
                    builder: (context) => ReviewPage(id: doctorId, isDoctor: true),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a Doctor ID')),
                );
              }
            },
            child: const Text('Go to Doctor Review'),
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
  String? _selectedClinic;
  List<String> _allClinics = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  Future<void> _loadClinics() async {
    try {
      // Load clinics
      final String clinicsString = await rootBundle.loadString('assets/clinics.json');
      final List<dynamic> clinicsJson = json.decode(clinicsString);
      final List<String> privateClinics = clinicsJson
          .where((e) => e is Map && e['Name'] != null)
          .map<String>((e) => e['District'] != null ? '${e['Name']}, ${e['District']}' : e['Name'] as String)
          .toList();

      // Load hospitals
      final String hospitalsString = await rootBundle.loadString('assets/hospitals.json');
      final List<dynamic> hospitalsJson = json.decode(hospitalsString);
      final List<String> hospitals = hospitalsJson.cast<String>();

      // Combine both lists
      setState(() {
        _allClinics = [...privateClinics, ...hospitals];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _allClinics = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Create a TextEditingController for the search field
    final TextEditingController searchController = TextEditingController();
    // Filtered list of clinics
    List<String> filteredClinics = _allClinics;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Direct search field
        TextField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: "Search Hospital/Clinic",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (value) {
            setState(() {
              // Normalize search for chittagong/chattogram
              String normalize(String s) => s.toLowerCase().replaceAll('chittagong', 'chattogram');
              final normalizedQuery = normalize(value);
              
              filteredClinics = _allClinics
                .where((clinic) => normalize(clinic).contains(normalizedQuery))
                .toList();
            });
          },
        ),
        
        const SizedBox(height: 8),
        
        // Display filtered results in a scrollable list
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filteredClinics.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(filteredClinics[index]),
                onTap: () {
                  setState(() {
                    _selectedClinic = filteredClinics[index];
                    searchController.text = filteredClinics[index];
                  });
                  // Directly navigate to review page when a clinic is selected
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReviewPage(id: filteredClinics[index], isDoctor: false),
                    ),
                  );
                },
                selected: _selectedClinic == filteredClinics[index],
              );
            },
          ),
        ),
      ],
      ),
    );
  }
}

class ReviewPage extends StatefulWidget {
  final String id;
  final bool isDoctor;

  const ReviewPage({super.key, required this.id, required this.isDoctor});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _reviewController = TextEditingController();
  double _rating = 3.0;

  // In-memory reviews list (replace with backend in production)
  static final List<Map<String, dynamic>> _reviews = [];

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _submitReview() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _reviews.add({
          'id': widget.id,
          'isDoctor': widget.isDoctor,
          'review': _reviewController.text,
          'rating': _rating,
          'userName': 'User${_reviews.length + 1}',
          'date': DateTime.now().toIso8601String(),
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted!')),
      );
      _reviewController.clear();
      // Optionally reset rating:
      setState(() => _rating = 3.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredReviews = _reviews.where((r) => r['id'] == widget.id && r['isDoctor'] == widget.isDoctor).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDoctor ? 'Review Doctor ${widget.id}' : 'Review Clinic ${widget.id}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _reviewController,
                    decoration: const InputDecoration(labelText: 'Your Review'),
                    validator: (value) => (value == null || value.isEmpty) ? 'Enter a review' : null,
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
                        itemPadding: const EdgeInsets.symmetric(horizontal: 2.0),
                        itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.deepPurple),
                        onRatingUpdate: (rating) => setState(() => _rating = rating),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _submitReview, child: const Text('Submit Review')),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Reviews:', style: TextStyle(fontWeight: FontWeight.bold)),
            // --- Review Summary START ---
            Builder(
              builder: (context) {
                if (filteredReviews.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No reviews yet.', style: TextStyle(color: Colors.grey)),
                  );
                }

                // Calculate average and counts
                final avg = filteredReviews.fold<double>(0.0, (sum, r) => sum + (r['rating'] as double)) / filteredReviews.length;
                final counts = List<int>.filled(5, 0);
                for (var r in filteredReviews) {
                  final idx = ((r['rating'] as double).round()).clamp(1, 5).toInt() - 1; // clamp returns num
                  counts[idx]++;
                }
                final total = filteredReviews.length;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: Average rating
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (i) {
                              if (avg >= i + 1) {
                                return const Icon(Icons.star, color: Colors.blue, size: 20);
                              } else if (avg > i && avg < i + 1) {
                                return const Icon(Icons.star_half, color: Colors.blue, size: 20);
                              } else {
                                return const Icon(Icons.star_border, color: Colors.blue, size: 20);
                              }
                            }),
                          ),
                          const SizedBox(height: 4),
                          Text('$total reviews', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(width: 24),
                      // Right: Star rating breakdown
                      Expanded(
                        child: Column(
                          children: List.generate(5, (index) {
                            final star = 5 - index;
                            final count = counts[star - 1];
                            final percent = total > 0 ? count / total : 0.0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Text('$star', style: const TextStyle(fontSize: 14)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.star, size: 14, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: percent,
                                      backgroundColor: Colors.grey.shade300,
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                                      minHeight: 10,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('$count', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // --- Review Summary END ---
            Expanded(
              child: ListView.builder(
                itemCount: filteredReviews.length,
                itemBuilder: (context, index) {
                  final review = filteredReviews[index];
                  final userName = review['userName'] ?? 'User';
                  final reviewDate = review['date'] != null ? DateTime.tryParse(review['date']) ?? DateTime.now() : DateTime.now();

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: User image, name, 3-dot menu
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.deepPurple[100],
                                child: Text(userName[0], style: const TextStyle(color: Colors.deepPurple)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Row(
                                      children: [
                                        // Violet stars
                                        ...List.generate(5, (i) {
                                          final isFilled = i < (review['rating'] as double).round();
                                          return Icon(isFilled ? Icons.star : Icons.star_border, color: Colors.deepPurple, size: 18);
                                        }),
                                        const SizedBox(width: 8),
                                        Text('${reviewDate.year}-${reviewDate.month.toString().padLeft(2, '0')}-${reviewDate.day.toString().padLeft(2, '0')}',
                                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) {
                                  final message = value == 'inappropriate' ? 'Flagged as inappropriate' : 'Flagged as spam';
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(value: 'inappropriate', child: Text('Flag as inappropriate')),
                                  PopupMenuItem(value: 'spam', child: Text('Flag as spam')),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Review text
                          Text(review['review'] as String),
                          const SizedBox(height: 12),
                          // Was this review helpful?
                          Row(
                            children: [
                              const Text('Was this review helpful?'),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Thanks for your feedback!')),
                                ),
                                child: const Text('Yes'),
                              ),
                              const SizedBox(width: 4),
                              OutlinedButton(
                                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Thanks for your feedback!')),
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
