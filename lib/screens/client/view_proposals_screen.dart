import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chat/chat_screen.dart';

class ViewProposalsScreen extends StatefulWidget {
  final String projectId;
  const ViewProposalsScreen({super.key, required this.projectId});

  @override
  _ViewProposalsScreenState createState() => _ViewProposalsScreenState();
}

class _ViewProposalsScreenState extends State<ViewProposalsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Proposals"),
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
          padding: const EdgeInsets.all(20.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("proposals")
                .where("projectId", isEqualTo: widget.projectId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text("No proposals yet!", style: TextStyle(color: Colors.white)));
              }

              var proposals = snapshot.data!.docs;

              var acceptedProposals = proposals.where((doc) => doc["status"] == "Accepted").toList();
              var otherProposals = proposals.where((doc) => doc["status"] != "Accepted").toList();

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 80),
                    if (acceptedProposals.isNotEmpty) ...[
                      _buildSectionTitle("✅ Accepted Proposals", Colors.green),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: acceptedProposals.length,
                        itemBuilder: (context, index) => _buildProposalCard(acceptedProposals[index]),
                      ),
                    ],
                    if (otherProposals.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildSectionTitle("🔸 Pending / Rejected Proposals", Colors.orangeAccent),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: otherProposals.length,
                        itemBuilder: (context, index) => _buildProposalCard(otherProposals[index]),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Text(
          text,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }

  Widget _buildProposalCard(QueryDocumentSnapshot proposal) {
    String status = proposal["status"] ?? "Pending";
    String professionalId = proposal["professionalId"] ?? "";

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
            Text(proposal["professionalName"],
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 5),
            Text(
              "Bid: PKR ${proposal["bidAmount"].toStringAsFixed(0)}",
              style: const TextStyle(color: Colors.orangeAccent),
            ),
            const SizedBox(height: 5),
            Text(proposal["coverLetter"], style: GoogleFonts.poppins(color: Colors.white70)),
            const SizedBox(height: 10),
            _buildStatusBadge(status),
            const SizedBox(height: 10),
            if (status == "Pending")
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text("Accept"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => _acceptProposal(proposal.id, widget.projectId, professionalId),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text("Reject"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => _updateProposalStatus(proposal.id, "Rejected"),
                  ),
                ],
              ),
            if (status == "Accepted")
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text("Chat"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () => _startChat(context, professionalId),
                ),
              ),
          ],
        ),
      ),
    );
  }

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

  void _acceptProposal(String proposalId, String projectId, String professionalId) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      await firestore.collection("projects").doc(projectId).set({
        "status": "ongoing",
        "progress": 0.0,
        "professionalId": professionalId,
        "participants": FieldValue.arrayUnion([professionalId])
      }, SetOptions(merge: true));

      await firestore.collection("proposals").doc(proposalId).update({
        "status": "Accepted",
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Proposal accepted, project is now ongoing!")),
      );
    } catch (e) {
      print("Error accepting proposal: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to accept proposal")),
      );
    }
  }

  void _updateProposalStatus(String proposalId, String newStatus) async {
    DocumentReference proposalRef = FirebaseFirestore.instance.collection('proposals').doc(proposalId);

    await proposalRef.update({'status': newStatus});

    if (newStatus == "Accepted") {
      DocumentSnapshot proposalSnapshot = await proposalRef.get();
      String projectId = proposalSnapshot["projectId"];
      String professionalId = proposalSnapshot["professionalId"];

      DocumentReference projectRef = FirebaseFirestore.instance.collection('projects').doc(projectId);

      DocumentSnapshot projectSnapshot = await projectRef.get();

      if (!projectSnapshot.exists || !projectSnapshot.data().toString().contains("progress")) {
        await projectRef.set({
          'status': 'ongoing',
          'progress': 0.0,
          'professionalId': professionalId,
        }, SetOptions(merge: true));
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Proposal $newStatus successfully!")),
    );
  }

  void _startChat(BuildContext context, String professionalId) async {
    User? client = FirebaseAuth.instance.currentUser;
    if (client == null) return;

    String chatId = _generateChatId(client.uid, professionalId);
    DocumentReference chatRef = FirebaseFirestore.instance.collection("chats").doc(chatId);

    await chatRef.set({"participants": [client.uid, professionalId]}, SetOptions(merge: true));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chatId,
          receiverId: professionalId,
          receiverName: "Professional",
          receiverProfile: "",
        ),
      ),
    );
  }

  String _generateChatId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort();
    return ids.join("_");
  }
}
