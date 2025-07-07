import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sh/screens/professional/project_details_screen.dart';

class FindProjectsScreen extends StatefulWidget {
  const FindProjectsScreen({super.key});

  @override
  _FindProjectsScreenState createState() => _FindProjectsScreenState();
}

class _FindProjectsScreenState extends State<FindProjectsScreen> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Projects"),
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
                  hintText: "Search projects...",
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
              child: StreamBuilder(
                stream: FirebaseFirestore.instance.collection('projects').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No projects found", style: TextStyle(color: Colors.white)),
                    );
                  }

                  var projects = snapshot.data!.docs.where((doc) {
                    var title = doc['title'].toString().toLowerCase();
                    return title.contains(searchQuery);
                  }).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      var project = projects[index];
                      return _buildProjectCard(project, context);
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

  Widget _buildProjectCard(QueryDocumentSnapshot project, BuildContext context) {
    String title = project['title'] ?? "Untitled Project";
    String budget = project['budget'] ?? "0";
    String deadline = project['deadline'] ?? "No deadline";
    String client = project['client'] ?? "Unknown Client";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailsScreen(projectId: project.id),
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
            backgroundColor: Colors.white,
            child: Icon(Icons.work, color: Colors.deepPurple.shade700),
          ),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Budget: PKR $budget", style: const TextStyle(color: Colors.orangeAccent)),
              Text("Deadline: $deadline", style: const TextStyle(color: Colors.white70)),
              Text("Client: $client", style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
