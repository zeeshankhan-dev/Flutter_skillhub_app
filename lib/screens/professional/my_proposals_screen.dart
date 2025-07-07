import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class MyProposalsScreen extends StatelessWidget {
  const MyProposalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String? professionalId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Proposals"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80), // Space for AppBar
              _buildHeader(),
              const SizedBox(height: 10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("proposals")
                      .where("professionalId", isEqualTo: professionalId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text("No proposals found", style: TextStyle(color: Colors.white)));
                    }

                    var proposals = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: proposals.length,
                      itemBuilder: (context, index) {
                        var proposal = proposals[index];
                        return _buildProposalCard(proposal);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ **Header Title for My Proposals**
  Widget _buildHeader() {
    return const Center(
      child: Text(
        "📌 My Submitted Proposals",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  // ✅ **Proposal Card with Clean UI**
  Widget _buildProposalCard(QueryDocumentSnapshot proposal) {
    String projectTitle = proposal.data().toString().contains("projectTitle")
        ? proposal["projectTitle"]
        : "Unknown Project";
    String status = proposal["status"] ?? "Pending";

    return Card(
      color: Colors.white.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ **Project Title**
            Text(
              projectTitle,
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),

            // ✅ **Bid Amount**
            Row(
              children: [
                const Icon(Icons.currency_rupee, color: Colors.orangeAccent, size: 20),
                const SizedBox(width: 5),
                Text("Bid: PKR ${proposal["bidAmount"]}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
              ],
            ),
            const SizedBox(height: 5),

            // ✅ **Cover Letter**
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.article, color: Colors.white70, size: 18),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    proposal["coverLetter"],
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ✅ **Status Badge**
            _buildStatusBadge(status),
          ],
        ),
      ),
    );
  }

  // ✅ **Status Badge**
  Widget _buildStatusBadge(String status) {
    Color badgeColor = status == "Accepted"
        ? Colors.green
        : status == "Rejected"
        ? Colors.red
        : Colors.orangeAccent;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
