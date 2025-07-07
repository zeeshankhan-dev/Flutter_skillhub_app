import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sh/screens/professional/submit_proposal_screen.dart';


class ProjectDetailsScreen extends StatelessWidget {
  final String projectId;

  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Project Details"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D5C85), Color(0xFF8E44AD)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection("projects").doc(projectId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text("Project not found!", style: TextStyle(color: Colors.white)));
              }

              var projectData = snapshot.data!.data() as Map<String, dynamic>;

              String title = projectData["title"] ?? "No Title Available";
              String description = projectData["description"] ?? "No Description Available";
              String client = projectData["client"] ?? "Fetching...";
              String budget = projectData["budget"] ?? "N/A";
              String deadline = projectData["deadline"] ?? "No Deadline Set";

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),
                  _buildProjectCard(title, description, budget, deadline, client),
                  const SizedBox(height: 20),
                  _buildApplyButton(context),
                  // ✅ Uncomment the following to show "View Proposals" button for clients
                  // _buildViewProposalsButton(context),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(String title, String description, String budget, String deadline, String client) {
    return Card(
      color: Colors.white.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            Text(description, style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 10),
            _buildDetailRow(Icons.currency_rupee, "Budget: PKR $budget"),
            _buildDetailRow(Icons.calendar_today, "Deadline: $deadline"),
            _buildDetailRow(Icons.person, "Client: ${client == 'Unknown Client' ? 'Fetching...' : client}"),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 16, color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildApplyButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubmitProposalScreen(projectId: projectId),
            ),
          );
        },
        child: const Text("Apply for Project", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

}
