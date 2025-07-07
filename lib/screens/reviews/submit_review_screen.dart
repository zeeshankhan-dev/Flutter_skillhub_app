import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class SubmitReviewScreen extends StatefulWidget {
  final String projectId;
  final String professionalId;

  const SubmitReviewScreen({
    super.key,
    required this.projectId,
    required this.professionalId,
  });

  @override
  _SubmitReviewScreenState createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends State<SubmitReviewScreen> {
  double _rating = 0.0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  void _submitReview() async {
    if (_rating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a rating"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String clientId = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection("reviews").add({
        "projectId": widget.projectId,
        "professionalId": widget.professionalId,
        "clientId": clientId,
        "rating": _rating,
        "feedback": _feedbackController.text.trim(),
        "timestamp": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Review submitted successfully!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit review: $e"), backgroundColor: Colors.red),
      );
    }

    setState(() {
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Submit Review"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.white.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Rate the Professional:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  Center(
                    child: RatingBar.builder(
                      initialRating: _rating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber, size: 30),
                      onRatingUpdate: (rating) {
                        setState(() {
                          _rating = rating;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Leave a Feedback (Optional):",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _feedbackController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Write your feedback here...",
                      hintStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Submit Review"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
