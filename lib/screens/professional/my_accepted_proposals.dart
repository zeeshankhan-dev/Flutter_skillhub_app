import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../chat/chat_screen.dart';

class MyAcceptedProposalsScreen extends StatelessWidget {
  final String professionalId;

  const MyAcceptedProposalsScreen({super.key, required this.professionalId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Accepted Proposals"),
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
        child: Column(
          children: [
            const SizedBox(height: 80),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("proposals")
                    .where("professionalId", isEqualTo: professionalId)
                    .where("status", isEqualTo: "Accepted")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No accepted proposals", style: TextStyle(color: Colors.white)),
                    );
                  }

                  var proposals = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                    itemCount: proposals.length,
                    itemBuilder: (context, index) {
                      var proposal = proposals[index];
                      String projectId = proposal["projectId"] ?? "";
                      String clientId = proposal["clientId"] ?? "";

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection("projects").doc(projectId).get(),
                        builder: (context, projectSnapshot) {
                          String projectTitle = "Loading...";
                          if (projectSnapshot.hasData && projectSnapshot.data!.exists) {
                            var projectData = projectSnapshot.data!.data() as Map<String, dynamic>;
                            projectTitle = projectData["title"] ?? "No Title Available";
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Card(
                              color: Colors.white.withOpacity(0.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 5,
                              child: ListTile(
                                leading: const Icon(Icons.work, color: Colors.white, size: 30),
                                title: Text(
                                  projectTitle,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Text(
                                  "Bid Amount: \PKR ${proposal["bidAmount"]}",
                                  style: const TextStyle(color: Colors.orangeAccent),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.chat, color: Colors.white),
                                  onPressed: () {
                                    _startChat(context, clientId);
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// **✅ Start a Chat When Clicking the Chat Button**
  void _startChat(BuildContext context, String clientId) async {
    String chatId = _generateChatId(professionalId, clientId);
    DocumentReference chatRef = FirebaseFirestore.instance.collection("chats").doc(chatId);

    try {
      // ✅ Ensure chat document is created
      await chatRef.set({
        "chatId": chatId,
        "participants": [professionalId, clientId],
        "lastMessage": "",
        "lastMessageTime": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ✅ Get client details for ChatScreen
      DocumentSnapshot clientSnapshot =
      await FirebaseFirestore.instance.collection("users").doc(clientId).get();
      if (!clientSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Client profile not found!")),
        );
        return;
      }

      String clientName = clientSnapshot["fullName"] ?? "Client";
      String clientProfile = clientSnapshot["profilePicture"] ?? "";

      // ✅ Navigate to ChatScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            receiverId: clientId,
            receiverName: clientName,
            receiverProfile: clientProfile,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start chat: $e")),
      );
    }
  }

  /// **✅ Generate a Unique Chat ID**
  String _generateChatId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort(); // Ensures consistent order
    return ids.join("_");
  }
}
