import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostProjectScreen extends StatefulWidget {
  const PostProjectScreen({super.key});

  @override
  _PostProjectScreenState createState() => _PostProjectScreenState();
}

class _PostProjectScreenState extends State<PostProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();
  String selectedCategory = 'Web Development';
  DateTime? selectedDeadline;
  bool _isLoading = false;

  void _postProject() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in!")),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String clientId = currentUser.uid;

      try {
        DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection("users").doc(clientId).get();
        String clientName = userDoc.exists ? userDoc["fullName"] ?? "Unknown Client" : "Unknown Client";

        await FirebaseFirestore.instance.collection('projects').add({
          'title': titleController.text.trim(),
          'description': descriptionController.text.trim(),
          'budget': budgetController.text.trim(),
          'deadline': selectedDeadline?.toIso8601String(),
          'category': selectedCategory,
          'client': clientName,
          'clientId': clientId,
          'timestamp': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Project Posted Successfully!")),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post a Project"),
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 80),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField("Project Title", titleController, Icons.title),
                        _buildTextField("Project Description", descriptionController, Icons.description, maxLines: 4),
                        _buildCategoryDropdown(),
                        _buildTextField("Budget (PKR)", budgetController, Icons.currency_rupee, isNumeric: true),
                        _buildDeadlinePicker(),
                        const SizedBox(height: 20),
                        _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Colors.white))
                            : _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon,
      {bool isNumeric = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          prefixIcon: Icon(icon, color: Colors.white70),
          hintText: label,
          hintStyle: GoogleFonts.poppins(color: Colors.white70),
        ),
        validator: (value) => value!.isEmpty ? "$label is required" : null,
      ),
    );
  }

  Widget _buildDeadlinePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: Colors.white70),
        title: Text(
          selectedDeadline == null
              ? "Select Deadline"
              : "Deadline: ${selectedDeadline!.toLocal()}".split(' ')[0],
          style: const TextStyle(color: Colors.white),
        ),
        tileColor: Colors.white.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2100),
          );
          if (pickedDate != null) {
            setState(() => selectedDeadline = pickedDate);
          }
        },
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: DropdownButtonFormField<String>(
        value: selectedCategory,
        dropdownColor: Colors.deepPurple,
        items: ["Web Development", "Mobile App", "AI/ML", "Graphics Design"]
            .map((category) => DropdownMenuItem(
          value: category,
          child: Text(category, style: const TextStyle(color: Colors.white)),
        ))
            .toList(),
        onChanged: (value) => setState(() => selectedCategory = value!),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          prefixIcon: const Icon(Icons.category, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
        ),
        onPressed: _postProject,
        child: const Text("Post Project", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
