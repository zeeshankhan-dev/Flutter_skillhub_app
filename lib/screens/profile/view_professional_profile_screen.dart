import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ViewProfessionalProfileScreen extends StatefulWidget {
  final String professionalId;

  const ViewProfessionalProfileScreen({super.key, required this.professionalId});

  @override
  State<ViewProfessionalProfileScreen> createState() => _ViewProfessionalProfileScreenState();
}

class _ViewProfessionalProfileScreenState extends State<ViewProfessionalProfileScreen> {
  Map<String, dynamic>? userData;
  double averageRating = 0.0;
  int totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchAverageRating();
  }

  Future<void> _fetchUserData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(widget.professionalId)
        .get();

    if (userDoc.exists) {
      setState(() {
        userData = userDoc.data() as Map<String, dynamic>;
      });
    }
  }

  Future<void> _fetchAverageRating() async {
    QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
        .collection("reviews")
        .where("professionalId", isEqualTo: widget.professionalId)
        .get();

    if (reviewSnapshot.docs.isNotEmpty) {
      double totalRating = 0.0;
      for (var doc in reviewSnapshot.docs) {
        totalRating += (doc["rating"] as num).toDouble();
      }

      setState(() {
        totalReviews = reviewSnapshot.docs.length;
        averageRating = totalRating / totalReviews;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String? profilePicture = userData?["profilePicture"];
    String fullName = userData?["fullName"] ?? "Unknown User";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Professional Profile"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity, // ✅ Ensures full screen background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2D5C85), Color(0xFF8E44AD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: userData == null
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              /// 🖼️ Profile Picture
              CircleAvatar(
                radius: 50,
                backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                    ? NetworkImage(profilePicture)
                    : null,
                backgroundColor: Colors.white.withOpacity(0.5),
                child: (profilePicture == null || profilePicture.isEmpty)
                    ? Text(
                  fullName[0].toUpperCase(),
                  style: const TextStyle(fontSize: 40, color: Colors.deepPurple),
                )
                    : null,
              ),
              const SizedBox(height: 10),

              /// 👤 Name
              Text(
                fullName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),

              /// ⭐ Rating
              Text(
                totalReviews > 0
                    ? "⭐ ${averageRating.toStringAsFixed(1)}/5 ($totalReviews Reviews)"
                    : "No Ratings Yet",
                style: const TextStyle(fontSize: 16, color: Colors.amber),
              ),
              const SizedBox(height: 20),

              _buildProfileField("Email", userData?["email"] ?? "No Email"),
              _buildProfileField("Phone", userData?["phoneNumber"] ?? "No Phone"),
              _buildProfileField("Skills", userData?["skills"] ?? "Not Provided"),
              _buildProfileField("Hourly Rate", "PKR ${userData?["hourlyRate"] ?? "Not Set"}/hr"),
              _buildProfileField("Portfolio", userData?["portfolio"] ?? "Not Provided"),
              const SizedBox(height: 20),

              _buildReviewsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white70),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Client Reviews",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("reviews")
              .where("professionalId", isEqualTo: widget.professionalId)
              .orderBy("timestamp", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(color: Colors.white);
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text("No reviews yet", style: TextStyle(color: Colors.white70));
            }

            var reviews = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                var review = reviews[index];
                return _buildReviewCard(review);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewCard(QueryDocumentSnapshot review) {
    double rating = (review["rating"] as num).toDouble();
    String feedback = review["feedback"] ?? "";
    Timestamp timestamp = review["timestamp"];
    DateTime date = timestamp.toDate();
    String formattedDate = "${date.day}-${date.month}-${date.year}";
    String clientId = review["clientId"];

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection("users").doc(clientId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox();
        }

        var clientData = snapshot.data!.data() as Map<String, dynamic>;
        String clientName = clientData["fullName"] ?? "Client";

        return Card(
          color: Colors.white.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(clientName,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("⭐ $rating", style: const TextStyle(color: Colors.amber)),
                    Text(formattedDate, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  feedback.isNotEmpty ? feedback : "No feedback",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
