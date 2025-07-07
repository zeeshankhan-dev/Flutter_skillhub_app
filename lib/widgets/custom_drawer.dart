import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sh/screens/profile/edit_profile_screen.dart';
import '../screens/termsandconditions/terms_and_conditions_screen.dart'; // ✅ Import Terms & Conditions Screen

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String fullName = userData["fullName"] ?? "User";
          String role = userData["role"] ?? "Client";
          String profilePicture = userData["profilePicture"] ?? "";

          return Column(
            children: [
              /// ✅ Drawer Header
              UserAccountsDrawerHeader(
                accountName: Text(
                  fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                accountEmail: Text(
                  role,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: profilePicture.isNotEmpty
                      ? NetworkImage(profilePicture)
                      : null,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  child: profilePicture.isEmpty
                      ? Text(fullName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.deepPurple))
                      : null,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2D5C85), Color(0xFF8E44AD)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              /// ✅ Edit Profile
              _buildListTile(Icons.edit, "Edit Profile", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(isClient: role == "Client"),
                  ),
                );
              }),

              const Divider(),

              /// ✅ Dashboard
              _buildListTile(Icons.dashboard, "Dashboard", () {
                Navigator.pushReplacementNamed(
                    context, role == "Client" ? "/client_dashboard" : "/professional_dashboard");
              }),

              /// ✅ Client Features
              if (role == "Client") ...[
                _buildListTile(Icons.add, "Post a Project",
                        () => Navigator.pushNamed(context, "/post_project")),
                _buildListTile(Icons.search, "Find Professionals",
                        () => Navigator.pushNamed(context, "/find_professionals")),
              ],

              const Divider(),

              /// ✅ App Info / Legal
              _buildListTile(Icons.description, "Terms & Conditions", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen()),
                );
              }),

              _buildListTile(Icons.settings, "Settings", () => Navigator.pushNamed(context, "/settings")),
              _buildListTile(Icons.help, "Help & Support", () => Navigator.pushNamed(context, "/help")),

              const Divider(),

              /// ✅ Logout
              _buildListTile(Icons.logout, "Logout", () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, "/login");
              }),
            ],
          );
        },
      ),
    );
  }

  /// Reusable List Tile
  Widget _buildListTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}
