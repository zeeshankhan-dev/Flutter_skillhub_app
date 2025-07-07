import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  _PaymentHistoryScreenState createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment History"),
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
        child: _buildPaymentHistoryList(),
      ),
    );
  }

  Widget _buildPaymentHistoryList() {
    if (currentUser == null) {
      return const Center(
        child: Text("Please log in first", style: TextStyle(color: Colors.white)),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("payments")
          .where("senderId", isEqualTo: currentUser!.uid)
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No payment history available.", style: TextStyle(color: Colors.white70)),
          );
        }

        var payments = snapshot.data!.docs;

        return ListView.builder(
          itemCount: payments.length,
          itemBuilder: (context, index) {
            var paymentData = payments[index];

            double amount = (paymentData["amount"] as num).toDouble();
            String method = paymentData["method"];
            String status = paymentData["status"];
            Timestamp? timestamp = paymentData["timestamp"];
            String projectId = paymentData["projectId"] ?? "";
            bool isCommission = paymentData["isCommission"] ?? false;

            // For commissions, no need to fetch project title
            if (isCommission) {
              return _buildCommissionCard(amount, method, status, timestamp);
            }

            // For regular payments, show full detail with project title
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection("projects").doc(projectId).get(),
              builder: (context, projectSnapshot) {
                String projectTitle = "Unknown Project";
                if (projectSnapshot.hasData && projectSnapshot.data!.exists) {
                  projectTitle = projectSnapshot.data!["title"] ?? "Unknown Project";
                }

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.white.withOpacity(0.2),
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.payment, color: Colors.white),
                    ),
                    title: Text(
                      "PKR ${amount.toStringAsFixed(0)}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Project: $projectTitle", style: const TextStyle(color: Colors.white70)),
                        Text("Method: $method", style: const TextStyle(color: Colors.white70)),
                        Text("Status: $status", style: const TextStyle(color: Colors.white70)),
                        Text("Type: Client Payment", style: const TextStyle(color: Colors.white70)),
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
  }

  /// ✅ Build Card for Commission Payment
  Widget _buildCommissionCard(double amount, String method, String status, Timestamp? timestamp) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white.withOpacity(0.2),
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const CircleAvatar(
          radius: 25,
          backgroundColor: Colors.redAccent,
          child: Icon(Icons.attach_money, color: Colors.white),
        ),
        title: Text(
          "PKR ${amount.toStringAsFixed(0)}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Method: $method", style: const TextStyle(color: Colors.white70)),
            Text("Status: $status", style: const TextStyle(color: Colors.white70)),
            const Text("Type: Commission", style: TextStyle(color: Colors.white70)),
            Text("Date: ${_formatTimestamp(timestamp)}", style: const TextStyle(color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown";
    DateTime date = timestamp.toDate();
    return "${date.day}-${date.month}-${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
