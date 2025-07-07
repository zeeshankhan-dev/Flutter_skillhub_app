import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity, // ✅ Ensures full screen background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2D5C85), Color(0xFF8E44AD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Terms and Conditions",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "1. All users must provide accurate and true information during registration.\n\n"
                      "2. Clients must make payments according to the defined progress milestones.\n\n"
                      "3. Professionals must pay commission to SkillHub once they receive payments.\n\n"
                      "4. The app owner is not responsible for disputes between clients and professionals.\n\n"
                      "5. All payments must be recorded in the app. External transactions must be verified.\n\n"
                      "6. Violation of terms may result in account suspension or removal.\n\n"
                      "7. These terms may be updated at any time. Users will be notified of changes.",
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
                SizedBox(height: 20),
                Text(
                  "By using SkillHub, you agree to these terms.",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
