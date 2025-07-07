import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text(
              "Frequently Asked Questions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text("Q: How to post a project?\nA: Go to 'Post a Project' in the drawer and fill the form."),
            SizedBox(height: 20),
            Text("Q: How to contact support?\nA: Email us at skillhub.support@gmail.com or chat with us at 0349-4678746."),
            SizedBox(height: 20),
            Text("Q: How to reset my password?\nA: Click on 'Forgot Password' on login screen."),
          ],
        ),
      ),
    );
  }
}
