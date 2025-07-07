import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectListScreen extends StatelessWidget {
  final String? status; // null = all, 'ongoing', 'completed', etc.

  const ProjectListScreen({this.status, super.key});

  @override
  Widget build(BuildContext context) {
    Query projectsQuery = FirebaseFirestore.instance.collection('projects');
    if (status != null) {
      projectsQuery = projectsQuery.where('status', isEqualTo: status);
    }

    final String screenTitle = status == null
        ? 'All Projects'
        : '${status!.capitalize()} Projects';

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 3,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: projectsQuery.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.inbox, size: 50, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      'No projects found.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data()! as Map<String, dynamic>;

                final String title = data['title'] ?? 'No Title';
                final String projectStatus = data['status'] ?? 'N/A';
                final dynamic budget = data['budget'] ?? 'N/A';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade100,
                      child: const Icon(Icons.work, color: Colors.teal),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Text(
                            'Status: ',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            projectStatus.capitalize(),
                            style: TextStyle(
                              color: getStatusColor(projectStatus),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'view') {
                          // TODO: Navigate to project details
                        } else if (value == 'delete') {
                          // TODO: Confirm and delete project
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'view', child: Text('View Details')),
                        const PopupMenuItem(
                            value: 'delete', child: Text('Delete Project')),
                      ],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Budget',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            'PKR $budget',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      // Optional: Quick view details
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// Helper to get status color
Color getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return Colors.green;
    case 'ongoing':
      return Colors.orange;
    case 'pending':
      return Colors.blueGrey;
    default:
      return Colors.grey;
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
}
