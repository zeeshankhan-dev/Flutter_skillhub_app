import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReceivedPaymentsScreen extends StatefulWidget {
  const ReceivedPaymentsScreen({super.key});

  @override
  _ReceivedPaymentsScreenState createState() => _ReceivedPaymentsScreenState();
}

class _ReceivedPaymentsScreenState extends State<ReceivedPaymentsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Received Payments"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2D5C85), Color(0xFF8E44AD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _buildReceivedPaymentsList(),
      ),
    );
  }

  Widget _buildReceivedPaymentsList() {
    if (currentUser == null) {
      return const Center(
        child: Text("Please log in first", style: TextStyle(color: Colors.white)),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("payments")
          .where("receiverId", isEqualTo: currentUser!.uid)
          .where("isCommission", isEqualTo: false) // ✅ Only show real payments
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No payments received yet.", style: TextStyle(color: Colors.white70)),
          );
        }

        var payments = snapshot.data!.docs;

        return ListView.builder(
          itemCount: payments.length,
          itemBuilder: (context, index) {
            var paymentData = payments[index];
            double amount = (paymentData["amount"] as num).toDouble();
            String senderId = paymentData["senderId"];
            String method = paymentData["method"];
            Timestamp? timestamp = paymentData["timestamp"];
            String projectId = paymentData["projectId"] ?? "";

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection("users").doc(senderId).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const SizedBox();
                }

                var userData = userSnapshot.data!;
                String clientName = userData["fullName"] ?? "Client";

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection("projects").doc(projectId).get(),
                  builder: (context, projectSnapshot) {
                    String projectTitle = "Project";
                    if (projectSnapshot.hasData && projectSnapshot.data!.exists) {
                      projectTitle = projectSnapshot.data!["title"] ?? "Project";
                    }

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white.withOpacity(0.15),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.green,
                          child: Icon(Icons.account_balance_wallet, color: Colors.white),
                        ),
                        title: Text(
                          "PKR ${amount.toStringAsFixed(0)}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Client: $clientName", style: const TextStyle(color: Colors.white70)),
                            Text("Project: $projectTitle", style: const TextStyle(color: Colors.white70)),
                            Text("Method: $method", style: const TextStyle(color: Colors.white70)),
                            Text("Date: ${_formatTimestamp(timestamp)}", style: const TextStyle(color: Colors.white60)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown";
    DateTime date = timestamp.toDate();
    return "${date.day}-${date.month}-${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
