import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profile/edit_profile_screen.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  _ClientProfileScreenState createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    if (user != null) {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection("users").doc(user!.uid).get();

      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data() as Map<String, dynamic>?;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String? profilePicture = userData?["profilePicture"];
    String fullName = userData?["fullName"] ?? "Unknown User";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
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
        child: userData == null
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10,),
              /// ✅ **Profile Picture & Name**
              Center(
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                            ? NetworkImage(profilePicture)
                            : null,
                        backgroundColor: Colors.white.withOpacity(0.5),
                        child: profilePicture == null || profilePicture.isEmpty
                            ? Text(
                          fullName[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple),
                        )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      fullName, // ✅ Name Field Added Here!
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              /// ✅ **Profile Details**
              _buildProfileField("Name", fullName), // ✅ Name field added
              _buildProfileField("Email", userData?["email"] ?? "No Email"),
              _buildProfileField("Phone", userData?["phoneNumber"] ?? "No Phone Number"),
              _buildProfileField("Company", userData?["companyName"] ?? "No Company"),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// ✅ **Build Profile Field**
  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
