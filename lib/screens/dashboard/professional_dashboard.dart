import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sh/screens/professional/profile_screen.dart';
import 'package:sh/screens/professional/my_accepted_proposals.dart';
import '../../widgets/custom_drawer.dart';
import '../chat/inbox_screen.dart';
import '../payment/received_payments_screen.dart';
import '../professional/my_proposals_screen.dart';
import '../projects/ongoing_projects_screen.dart';
import '../professional/find_projects_screen.dart';

class ProfessionalDashboard extends StatefulWidget {
  const ProfessionalDashboard({super.key});

  @override
  _ProfessionalDashboardState createState() => _ProfessionalDashboardState();
}

class _ProfessionalDashboardState extends State<ProfessionalDashboard> {
  int _selectedIndex = 0;
  String userName = "";
  String profilePicture = "";
  String skills = "";

  final List<Widget> _screens = [
    const OngoingProjectsScreen(),
    const InboxScreen(),
    const ProfessionalProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

      if (userDoc.exists) {
        setState(() {
          userName = userDoc["fullName"] ?? "Professional";
          profilePicture = userDoc["profilePicture"] ?? "";
          skills = userDoc["skills"] ?? "No skills added";
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _selectedIndex == 0 ? const CustomDrawer() : null, // ✅ Sidebar only on Dashboard tab
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardContent(),
          ..._screens,
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.deepPurple,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: "Ongoing"),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: "Inbox"),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2D5C85), Color(0xFF8E44AD)],
        ),
      ),
      child: Column(
        children: [
          AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: Colors.deepPurple,
            elevation: 0,
            title: const Text("Professional Dashboard", style: TextStyle(color: Colors.white)),
            centerTitle: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(),
                  const SizedBox(height: 20),
                  _buildActionCards(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: profilePicture.isNotEmpty ? NetworkImage(profilePicture) : null,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: profilePicture.isEmpty
              ? Text(userName.isNotEmpty ? userName[0].toUpperCase() : "P",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))
              : null,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hello, $userName!",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            Text("Skills: $skills", style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCards() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _buildActionCard(Icons.work, "Find Projects", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FindProjectsScreen()),
          );
        }),
        _buildActionCard(Icons.check_circle, "My Proposals", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyProposalsScreen()),
          );
        }),
        _buildActionCard(Icons.assignment_turned_in, "My Accepted \n  Proposals", () {
          String? professionalId = FirebaseAuth.instance.currentUser?.uid;
          if (professionalId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MyAcceptedProposalsScreen(professionalId: professionalId),
              ),
            );
          }
        }),
        _buildActionCard(Icons.account_balance_wallet, "Received Payments", () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReceivedPaymentsScreen()),
          );
        }),
      ],
    );
  }

  Widget _buildActionCard(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white.withOpacity(0.2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
