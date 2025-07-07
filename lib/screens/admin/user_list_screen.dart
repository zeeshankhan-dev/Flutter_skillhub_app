import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserListScreen extends StatefulWidget {
  final String role; // 'Client' or 'Professional'

  const UserListScreen({required this.role, super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  String filterStatus = 'All';

  final Color primaryColor = Colors.teal;
  final Color activeColor = Colors.green;
  final Color inactiveColor = Colors.red;

  void _showDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(data['fullName'] ?? 'User Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📧 Email: ${data['email'] ?? ''}'),
            Text('📱 Phone: ${data['phoneNumber'] ?? ''}'),
            Text('👤 Role: ${data['role'] ?? ''}'),
            Text('✅ Active: ${data['isActive'] == true ? 'Yes' : 'No'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
        ],
      ),
    );
  }

  void _toggleUserStatus(String docId, bool currentStatus) {
    FirebaseFirestore.instance.collection('users').doc(docId).update({
      'isActive': !currentStatus,
    });
  }

  void _deleteUser(String docId) {
    FirebaseFirestore.instance.collection('users').doc(docId).delete();
  }

  Stream<QuerySnapshot> getUserStream() {
    Query ref =
    FirebaseFirestore.instance.collection('users').where('role', isEqualTo: widget.role);
    if (filterStatus == 'Active') {
      ref = ref.where('isActive', isEqualTo: true);
    } else if (filterStatus == 'Inactive') {
      ref = ref.where('isActive', isEqualTo: false);
    }
    return ref.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role} List'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Filter:'),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: filterStatus,
                  style: const TextStyle(fontSize: 14,color: Colors.blueGrey),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      filterStatus = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getUserStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(child: Text('No ${widget.role} found.'));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data()! as Map<String, dynamic>;
                    final isActive = data['isActive'] ?? true;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        leading: Icon(
                          isActive ? Icons.check_circle : Icons.cancel,
                          color: isActive ? activeColor : inactiveColor,
                        ),
                        title: Text(data['fullName'] ?? 'No Name'),
                        subtitle: Text(data['email'] ?? ''),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'details') {
                              _showDetails(context, data);
                            } else if (value == 'toggle') {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(isActive ? 'Deactivate User' : 'Activate User'),
                                  content: Text(
                                      'Are you sure you want to ${isActive ? 'deactivate' : 'activate'} this user?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _toggleUserStatus(doc.id, isActive);
                                      },
                                      child: const Text('Confirm'),
                                    ),
                                  ],
                                ),
                              );
                            } else if (value == 'delete') {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete User'),
                                  content: const Text(
                                      'Are you sure you want to permanently delete this user?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteUser(doc.id);
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'details',
                              child: Text('View Details'),
                            ),
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(isActive ? 'Deactivate' : 'Activate'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete User'),
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
        ],
      ),
    );
  }
}
