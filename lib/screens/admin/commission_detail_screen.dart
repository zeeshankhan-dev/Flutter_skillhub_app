import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommissionDetailsScreen extends StatelessWidget {
  const CommissionDetailsScreen({super.key});

  String formatDate(Timestamp timestamp) {
    return DateFormat.yMMMEd().add_jm().format(timestamp.toDate());
  }

  // Cache to avoid multiple Firestore reads
  static final Map<String, String> _userNameCache = {};

  Future<String> getUserName(String userId) async {
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId]!;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final name = doc.data()!['fullName'] ?? 'Unknown User';
        _userNameCache[userId] = name;
        return name;
      }
    } catch (e) {
      print('Error fetching user name for $userId: $e');
    }
    return 'Zeeshan Khan';
  }

  Future<String> getProjectName(String projectId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('projects').doc(projectId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['title'] ?? 'Unknown Project';
      }
    } catch (e) {
      print('Error fetching project title for $projectId: $e');
    }
    return 'Unknown Project';
  }

  Widget statusBadge(String status) {
    final isCompleted = status.toLowerCase() == 'completed';
    final color = isCompleted ? Colors.green.shade600 : Colors.orange.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commission Details'),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('payments')
              .where('isCommission', isEqualTo: true)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No commission payments found.'));
            }

            final docs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final payment = docs[index];
                final amount = payment['amount'];
                final method = payment['method'];
                final status = payment['status'];
                final timestamp = payment['timestamp'] as Timestamp;
                final senderId = payment['senderId'];
                final receiverId = payment['receiverId'];
                final projectId = payment['projectId'];

                return FutureBuilder<List<String>>(
                  future: Future.wait([
                    getUserName(senderId),
                    getUserName(receiverId),
                    getProjectName(projectId),
                  ]),
                  builder: (context, AsyncSnapshot<List<String>> userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final senderName = userSnapshot.data![0];
                    final receiverName = userSnapshot.data![1];
                    final projectName = userSnapshot.data![2];

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.deepOrange.shade50,
                              radius: 26,
                              child: Icon(Icons.account_balance_wallet, color: Colors.deepOrange.shade700, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PKR $amount via $method',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('From: $senderName', style: theme.textTheme.bodyMedium),
                                  Text('To: $receiverName', style: theme.textTheme.bodyMedium),
                                  Text('Project: $projectName', style: theme.textTheme.bodyMedium),
                                  const SizedBox(height: 6),
                                  statusBadge(status),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Date: ${formatDate(timestamp)}',
                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
    );
  }
}
