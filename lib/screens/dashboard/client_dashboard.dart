import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sh/screens/client/profile_screen.dart';
import 'package:sh/screens/client/view_proposals_screen.dart';
import '../../widgets/custom_drawer.dart';
import '../chat/inbox_screen.dart';
import '../client/post_project_screen.dart';
import '../payment/payment_history_screen.dart';
import '../projects/ongoing_projects_screen.dart';

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  _ClientDashboardState createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  int _selectedIndex = 0;
  String userName = "";
  String profilePicture = "";
  String companyName = "";

  final List<Widget> _screens = [
    const OngoingProjectsScreen(),
    const InboxScreen(),
    const ClientProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          userName = userDoc["fullName"] ?? "Client";
          profilePicture = userDoc["profilePicture"] ?? "";
          companyName = userDoc["companyName"] ?? "No company name";
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToViewProposals(String projectId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewProposalsScreen(projectId: projectId),
      ),
    );
  }



  void _showProjectSelectionDialog() async {
    String clientId = FirebaseAuth.instance.currentUser!.uid;

    QuerySnapshot projectSnapshot = await FirebaseFirestore.instance
        .collection("projects")
        .where("clientId", isEqualTo: clientId)
        .get();

    if (projectSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No projects found!")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: Colors.blueAccent.withOpacity(0.5), // ✅ Glass effect
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Title
                const Text(
                  "Select a Project",
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),

                // ✅ Project List
                SizedBox(
                  height: 200, // ✅ Limit height for better UX
                  child: ListView(
                    children: projectSnapshot.docs.map((doc) {
                      return Card(
                        color: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.work, color: Colors.white),
                          title: Text(
                            doc["title"],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
                          onTap: () {
                            Navigator.pop(context); // ✅ Close the dialog
                            _navigateToViewProposals(doc.id); // ✅ Navigate with selected projectId
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 10),

                // ✅ Cancel Button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// ✅ Show Drawer ONLY on Dashboard Tab
      drawer: _selectedIndex == 0 ?  CustomDrawer() : null,
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
            title: const Text("Client Dashboard", style: TextStyle(color: Colors.white)),
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
                  const SizedBox(height: 20),
                  _buildAcceptedProfessionalsSection(),

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
              ? Text(userName.isNotEmpty ? userName[0].toUpperCase() : "C",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))
              : null,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hello, $userName!",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            Text("Company: $companyName", style: const TextStyle(fontSize: 14, color: Colors.white70)),
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
        _buildActionCard(Icons.add_circle, "Post Project", () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PostProjectScreen()));
        }),
        _buildActionCard(Icons.work, "Find Professionals", () {
          Navigator.pushNamed(context, '/find_professionals');
        }),
        _buildActionCard(Icons.assignment, "My Projects", () {
          _showProjectSelectionDialog();
        }),
        _buildActionCard(Icons.payment, "Payment History", () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentHistoryScreen()));
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
            Text(label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }


  Widget _buildAcceptedProfessionalsSection() {
    String clientId = FirebaseAuth.instance.currentUser!.uid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "✅ Accepted Professionals",
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("proposals")
              .where("clientId", isEqualTo: clientId)
              .where("status", isEqualTo: "Accepted")
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text("No accepted professionals yet",
                      style: TextStyle(color: Colors.white)));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var proposal = snapshot.data!.docs[index];
                String projectTitle =
                proposal.data().toString().contains("projectTitle")
                    ? proposal["projectTitle"]
                    : "Unknown Project"; // ✅ Handle missing title

                return Card(
                  color: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    title: Text(proposal["professionalName"],
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text("Project: $projectTitle",
                        style: const TextStyle(color: Colors.orangeAccent)),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
