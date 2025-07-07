import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final CollectionReference users =
  FirebaseFirestore.instance.collection('users');

  Future<void> _updateProfileDialog(String currentName, String currentPhone) async {
    final TextEditingController nameController =
    TextEditingController(text: currentName);
    final TextEditingController phoneController =
    TextEditingController(text: currentPhone);

    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              onPressed: () async {
                final newName = nameController.text.trim();
                final newPhone = phoneController.text.trim();

                if (newName.isNotEmpty && newPhone.isNotEmpty) {
                  await users.doc(uid).update({
                    'fullName': newName,
                    'phoneNumber': newPhone,
                  });
                  Navigator.of(context).pop();
                  setState(() {}); // Refresh
                }
              },
              child: const Text('Update', style: TextStyle(color: Colors.white),),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: users.doc(uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Admin data not found.'));
          }

          final adminData = snapshot.data!.data() as Map<String, dynamic>;
          final fullName = adminData['fullName'] ?? 'Admin';
          final email = adminData['email'] ?? 'No Email';
          final phone = adminData['phoneNumber'] ?? 'No Phone Number';
          final firstLetter =
          fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';

          return Column(
            children: [
              // Top Gradient Header
              Container(
                width: double.infinity,
                height: 230,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.purpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.deepPurple,
                        child: Text(
                          firstLetter,
                          style: const TextStyle(
                            fontSize: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      email,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Profile Info Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow("Full Name", fullName),
                      const SizedBox(height: 10),
                      _infoRow("Email", email),
                      const SizedBox(height: 10),
                      _infoRow("Phone", phone),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit, color: Colors.grey,),
                          label: const Text("Edit Profile", style: TextStyle(color: Colors.white),),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                          ),
                          onPressed: () =>
                              _updateProfileDialog(fullName, phone),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$title: ",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
