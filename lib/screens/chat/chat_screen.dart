import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverName;
  final String receiverId;
  final String receiverProfile;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.receiverName,
    required this.receiverId,
    required this.receiverProfile,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    String messageText = _messageController.text.trim();
    _messageController.clear();

    await _firestore.collection("chats").doc(widget.chatId).collection("messages").add({
      "senderId": currentUser.uid,
      "receiverId": widget.receiverId,
      "message": messageText,
      "timestamp": FieldValue.serverTimestamp(),
      "type": "text",
      "status": "sent",
    });

    await _firestore.collection("chats").doc(widget.chatId).set({
      "lastMessage": messageText,
      "lastMessageTime": FieldValue.serverTimestamp(),
      "participants": [currentUser.uid, widget.receiverId],
      "unread_${widget.receiverId}": FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  @override
  void initState() {
    super.initState();
    _markMessagesAsDelivered();
  }

  void _markMessagesAsDelivered() async {
    QuerySnapshot messages = await _firestore
        .collection("chats")
        .doc(widget.chatId)
        .collection("messages")
        .where("receiverId", isEqualTo: _auth.currentUser!.uid)
        .where("status", isEqualTo: "sent")
        .get();

    for (var doc in messages.docs) {
      doc.reference.update({"status": "delivered"});
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime date = timestamp.toDate();
    return DateFormat('MMM d, y \'at\' hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: AppBar(
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7B1FA2), Color(0xFF512DA8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: widget.receiverProfile.isNotEmpty
                    ? NetworkImage(widget.receiverProfile)
                    : null,
                child: widget.receiverProfile.isEmpty
                    ? Text(widget.receiverName[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.receiverName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Segoe UI',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          foregroundColor: Colors.white,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("chats")
                  .doc(widget.chatId)
                  .collection("messages")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet"));
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var message = snapshot.data!.docs[index];
                    bool isMe = message["senderId"] == _auth.currentUser!.uid;
                    String status = message["status"] ?? "sent";

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          gradient: isMe
                              ? const LinearGradient(
                            colors: [Color(0xFF7B1FA2), Color(0xFF512DA8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                              : null,
                          color: isMe ? null : Colors.grey.shade200,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(isMe ? 12 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    message["message"] ?? "Unsupported",
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                if (isMe) _getStatusIcon(status),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(message["timestamp"]),
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.black54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF7B1FA2),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case "sent":
        return const Icon(Icons.check, size: 16, color: Colors.white70);
      case "delivered":
        return const Icon(Icons.done_all, size: 16, color: Colors.white70);
      case "read":
        return const Icon(Icons.done_all, size: 16, color: Colors.lightBlueAccent);
      default:
        return const SizedBox();
    }
  }
}
