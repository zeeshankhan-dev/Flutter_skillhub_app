import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../profile/view_professional_profile_screen.dart';

class FindProfessionalsScreen extends StatefulWidget {
  const FindProfessionalsScreen({super.key});

  @override
  _FindProfessionalsScreenState createState() => _FindProfessionalsScreenState();
}

class _FindProfessionalsScreenState extends State<FindProfessionalsScreen> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Professionals"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D5C85), Color(0xFF8E44AD)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search professionals...",
                  hintStyle: GoogleFonts.poppins(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'Professional')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text("No professionals found",
                            style: TextStyle(color: Colors.white)));
                  }

                  var professionals = snapshot.data!.docs.where((doc) {
                    var name = doc['fullName'].toString().toLowerCase();
                    return name.contains(searchQuery);
                  }).toList();

                  if (professionals.isEmpty) {
                    return const Center(
                        child: Text("No matching professionals found",
                            style: TextStyle(color: Colors.white)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: professionals.length,
                    itemBuilder: (context, index) {
                      var professional = professionals[index];
                      return _buildProfessionalCard(professional);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalCard(QueryDocumentSnapshot professional) {
    String profilePicture = professional['profilePicture'] ?? "";
    String fullName = professional['fullName'] ?? "Unknown Professional";
    String skills = professional['skills'] ?? "No skills provided";
    String hourlyRate = professional['hourlyRate'] ?? "Not set";
    String professionalId = professional.id;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewProfessionalProfileScreen(professionalId: professionalId),
          ),
        );
      },
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white.withOpacity(0.2),
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: profilePicture.isNotEmpty ? NetworkImage(profilePicture) : null,
            backgroundColor: Colors.white,
            child: profilePicture.isEmpty
                ? Text(fullName[0].toUpperCase(),
                style: const TextStyle(fontSize: 20, color: Colors.deepPurple))
                : null,
          ),
          title: Text(fullName,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Skills: $skills", style: const TextStyle(color: Colors.white70)),
              Text("Rate: PKR $hourlyRate/hr", style: const TextStyle(color: Colors.orangeAccent)),
            ],
          ),
        ),
      ),
    );
  }

}
