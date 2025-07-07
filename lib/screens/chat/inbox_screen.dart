import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  _InboxScreenState createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Inbox", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
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
            const SizedBox(height: 90),
            Expanded(child: _buildInboxList()),
          ],
        ),
      ),
    );
  }

  Widget _buildInboxList() {
    if (currentUser == null) {
      return const Center(
        child: Text("Please log in first", style: TextStyle(color: Colors.white, fontSize: 16)),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("chats")
          .where("participants", arrayContains: currentUser!.uid)
          .orderBy("lastMessageTime", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No messages yet", style: TextStyle(color: Colors.white, fontSize: 16)),
          );
        }

        var chats = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            var chatData = chats[index];
            List participants = chatData["participants"];
            String otherUserId = participants.firstWhere((id) => id != currentUser!.uid);

            // ✅ Get unread message count for the current user
            int unreadCount = chatData.data().toString().contains("unread_${currentUser!.uid}")
                ? chatData["unread_${currentUser!.uid}"]
                : 0;

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection("users").doc(otherUserId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const SizedBox();
                }

                var userData = userSnapshot.data!;
                String receiverName = userData["fullName"] ?? "Unknown";
                String receiverProfile = userData["profilePicture"] ?? "";
                String lastMessage = chatData.data().toString().contains("lastMessage")
                    ? chatData["lastMessage"]
                    : "No messages yet";

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Colors.white.withOpacity(0.1),
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                  shadowColor: Colors.black26,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundImage: receiverProfile.isNotEmpty ? NetworkImage(receiverProfile) : null,
                      backgroundColor: receiverProfile.isEmpty ? Colors.deepPurple : Colors.transparent,
                      child: receiverProfile.isEmpty
                          ? Text(receiverName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))
                          : null,
                    ),
                    title: Text(
                      receiverName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTimestamp(chatData["lastMessageTime"]),
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.shade400,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      _markMessagesAsRead(chatData.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: chatData.id,
                            receiverId: otherUserId,
                            receiverName: receiverName,
                            receiverProfile: receiverProfile,
                          ),
                        ),
                      );
                    },
                  ),
                );

              },
            );
          },
        );
      },
    );
  }

  void _markMessagesAsRead(String chatId) async {
    DocumentReference chatRef = FirebaseFirestore.instance.collection("chats").doc(chatId);

    await chatRef.update({
      "unread_${currentUser!.uid}": 0, // ✅ Reset unread messages when chat is opened
    });
  }


  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime date = timestamp.toDate();
    return DateFormat('MMM d, hh:mm a').format(date); // e.g., May 18, 03:15 PM
  }


}
