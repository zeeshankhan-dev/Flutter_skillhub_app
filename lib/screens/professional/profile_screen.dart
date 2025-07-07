import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfessionalProfileScreen extends StatefulWidget {
  const ProfessionalProfileScreen({super.key});

  @override
  _ProfessionalProfileScreenState createState() => _ProfessionalProfileScreenState();
}

class _ProfessionalProfileScreenState extends State<ProfessionalProfileScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  double averageRating = 0.0;
  int totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchAverageRating();
  }

  void _fetchUserData() async {
    if (user != null) {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection("users").doc(user!.uid).get();

      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data() as Map<String, dynamic>?;
        });
      }
    }
  }

  void _fetchAverageRating() async {
    if (user == null) return;

    QuerySnapshot reviewSnapshot = await FirebaseFirestore.instance
        .collection("reviews")
        .where("professionalId", isEqualTo: user!.uid)
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D5C85), Color(0xFF8E44AD)],
          ),
        ),
        child: userData == null
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 5),
              _buildProfileHeader(fullName, profilePicture),
              const SizedBox(height: 15),
              _buildRatingSection(),
              const SizedBox(height: 1),
              _buildProfileField("Email", userData?["email"] ?? "No Email"),
              _buildProfileField("Phone", userData?["phoneNumber"] ?? "No Phone"),
              _buildProfileField("Skills", userData?["skills"] ?? "Not Provided"),
              _buildProfileField("Hourly Rate", "PKR ${userData?["hourlyRate"] ?? "Not Set"}"),
              _buildClickableProfileField("Portfolio", userData?["portfolio"] ?? "No Portfolio"),
              const SizedBox(height: 10),
              _buildReviewsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String name, String? profilePicture) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                ? NetworkImage(profilePicture)
                : null,
            backgroundColor: Colors.white.withOpacity(0.5),
            child: (profilePicture == null || profilePicture.isEmpty)
                ? Text(name[0].toUpperCase(),
                style: const TextStyle(
                    fontSize: 40, fontWeight: FontWeight.bold, color: Colors.deepPurple))
                : null,
          ),
        ),
        const SizedBox(height: 10),
        Text(name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Column(
      children: [
        Text(
          totalReviews > 0
              ? "⭐ ${averageRating.toStringAsFixed(1)}/5 ($totalReviews Reviews)"
              : "No Ratings Yet",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
        ),
      ],
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
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                if (value.isNotEmpty && Uri.tryParse(value)?.hasAbsolutePath == true) {
                  final Uri url = Uri.parse(value);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open the portfolio link')),
                    );
                  }
                }
              },
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.lightBlueAccent,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("📢 Client Reviews",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("reviews")
              .where("professionalId", isEqualTo: user!.uid)
              .orderBy("timestamp", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
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
                return _buildReviewCard(reviews[index]);
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
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            title: Text(clientName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
