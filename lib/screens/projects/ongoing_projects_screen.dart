import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sh/screens/projects/client_project_tracking_screen.dart';
import 'package:sh/screens/payment/payment_screen.dart';
import 'package:sh/screens/reviews/submit_review_screen.dart';

class OngoingProjectsScreen extends StatefulWidget {
  const OngoingProjectsScreen({super.key});

  @override
  _OngoingProjectsScreenState createState() => _OngoingProjectsScreenState();
}

class _OngoingProjectsScreenState extends State<OngoingProjectsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  void _fetchUserRole() async {
    if (currentUser == null) return;
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("users").doc(currentUser!.uid).get();
    if (userDoc.exists) {
      setState(() {
        userRole = userDoc["role"] ?? "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ongoing Projects"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D5C85), Color(0xFF8E44AD)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(child: _buildOngoingProjectsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildOngoingProjectsList() {
    if (currentUser == null) {
      return const Center(
        child: Text("Please log in first", style: TextStyle(color: Colors.white, fontSize: 16)),
      );
    }
    if (userRole == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    Stream<QuerySnapshot> projectStream = userRole == "Client"
        ? FirebaseFirestore.instance
        .collection("projects")
        .where("clientId", isEqualTo: currentUser!.uid)
        .where("status", whereIn: ["ongoing", "completed"])
        .snapshots()
        : FirebaseFirestore.instance
        .collection("projects")
        .where("professionalId", isEqualTo: currentUser!.uid)
        .where("status", whereIn: ["ongoing", "completed"])
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: projectStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No ongoing projects", style: TextStyle(color: Colors.white, fontSize: 16)),
          );
        }

        var projects = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            var projectData = projects[index];
            String projectId = projectData.id;
            String projectName = projectData["title"] ?? "Untitled Project";
            double progress = projectData["progress"] is num ? projectData["progress"].toDouble() : 0.0;
            String professionalId = projectData["professionalId"] ?? "";
            String clientId = projectData["clientId"] ?? "";
            String projectStatus = projectData["status"] ?? "ongoing";
            bool commissionPaid = projectData.data().toString().contains("commissionPaid")
                ? projectData["commissionPaid"]
                : false;


            String otherUserId = userRole == "Client" ? professionalId : clientId;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection("users").doc(otherUserId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const SizedBox();
                }

                var userData = userSnapshot.data!;
                String otherUserName = userData["fullName"] ?? "Unknown";
                String otherUserProfile = userData["profilePicture"] ?? "";

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.white.withOpacity(0.15),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage: otherUserProfile.isNotEmpty ? NetworkImage(otherUserProfile) : null,
                          backgroundColor: otherUserProfile.isEmpty ? Colors.deepPurple : Colors.transparent,
                          child: otherUserProfile.isEmpty
                              ? Text(
                            otherUserName[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          )
                              : null,
                        ),
                        title: Text(
                          projectName,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Progress: ${progress.toStringAsFixed(1)}%",
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClientProjectTrackingScreen(
                                projectId: projectId,
                                projectTitle: projectName,
                                progress: progress,
                                professionalId: professionalId,
                              ),
                            ),
                          );
                        },
                      ),

                      // ✅ Payment for Clients
                      if (userRole == "Client" && projectStatus == "ongoing")
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _navigateToPaymentScreen(projectId, professionalId, otherUserName);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            icon: const Icon(Icons.payment, color: Colors.white),
                            label: const Text("Make Payment"),
                          ),
                        ),

                      // ✅ Leave Review (Completed Only)
                      if (userRole == "Client" && projectStatus == "completed")
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SubmitReviewScreen(
                                    projectId: projectId,
                                    professionalId: professionalId,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            icon: const Icon(Icons.rate_review, color: Colors.white),
                            label: const Text("Leave Review"),
                          ),
                        ),

                      // ✅ Commission Payment for Professionals
                      if (userRole == "Professional" &&
                          projectStatus == "ongoing" &&
                          progress >= 50 &&
                          commissionPaid == false)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _navigateToCommissionPaymentScreen(projectId);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                            label: const Text("Pay Commission"),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _navigateToPaymentScreen(String projectId, String professionalId, String professionalName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          projectId: projectId,
          receiverId: professionalId,
          receiverName: professionalName,
        ),
      ),
    );
  }

  void _navigateToCommissionPaymentScreen(String projectId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          projectId: projectId,
          receiverId: "admin", // Placeholder
          receiverName: "SkillHub Admin",
          isCommission: true, // Optional flag
        ),
      ),
    );
  }
}
