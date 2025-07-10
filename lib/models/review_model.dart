class Review {
  final String id;
  final String userName;
  final int rating;
  final String review;
  final DateTime createdAt;

  Review({required this.id, required this.userName, required this.rating, required this.review, required this.createdAt});

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    id: json["id"],
    userName: json["user_name"],
    rating: json["rating"],
    review: json["review"],
    createdAt: DateTime.parse(json["created_at"]),
  );
}