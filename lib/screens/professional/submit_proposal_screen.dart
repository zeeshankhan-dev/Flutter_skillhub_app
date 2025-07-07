import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubmitProposalScreen extends StatefulWidget {
  final String projectId;

  const SubmitProposalScreen({super.key, required this.projectId});

  @override
  _SubmitProposalScreenState createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends State<SubmitProposalScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController bidAmountController = TextEditingController();
  final TextEditingController coverLetterController = TextEditingController();
  bool _isSubmitting = false;

  void _submitProposal() async {
    if (_formKey.currentState!.validate()) {
      String? professionalId = FirebaseAuth.instance.currentUser?.uid;

      if (professionalId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not found! Please log in again.")),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection("users").doc(professionalId).get();

        String professionalName = userSnapshot.exists && userSnapshot.data() != null
            ? (userSnapshot.data() as Map<String, dynamic>)["fullName"] ?? "Unknown Professional"
            : "Unknown Professional";

        DocumentSnapshot projectSnapshot =
        await FirebaseFirestore.instance.collection('projects').doc(widget.projectId).get();
        String projectTitle = projectSnapshot["title"] ?? "Unknown Project";

        await FirebaseFirestore.instance.collection("proposals").add({
          'projectId': widget.projectId,
          'projectTitle': projectTitle,
          'professionalId': professionalId,
          'professionalName': professionalName,
          'bidAmount': double.parse(bidAmountController.text),
          'coverLetter': coverLetterController.text,
          'status': "Pending",
          'submittedAt': Timestamp.now(),
          'clientId': projectSnapshot["clientId"],
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Proposal submitted successfully!")),
        );

        bidAmountController.clear();
        coverLetterController.clear();
      } catch (e) {
        print("ERROR: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to submit proposal. Please try again.")),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Submit Proposal"),
        backgroundColor: Colors.transparent,
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
                        _buildTextField("Bid Amount (PKR)", bidAmountController, Icons.currency_rupee, isNumeric: true),
                        _buildTextField("Cover Letter", coverLetterController, Icons.edit, maxLines: 4),
                        const SizedBox(height: 20),
                        _isSubmitting
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

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
        ),
        onPressed: _submitProposal,
        child: const Text("Submit Proposal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
