import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final String adminEmail = "skillhub.support@gmail.com";

  Future<void> _saveFCMToken(String userId) async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        await _saveFCMToken(userCredential.user!.uid);

        String userEmail = emailController.text.trim();

        // ✅ Check for Admin Email first
        if (userEmail.toLowerCase() == adminEmail.toLowerCase()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Welcome Admin!")),
          );
          Navigator.pushReplacementNamed(context, "/admin_dashboard_screen");
        } else {
          // ✅ Fetch role from Firestore for other users
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection("users")
              .doc(userCredential.user!.uid)
              .get();

          String userRole = userDoc["role"] ?? "Client";

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login Successful!")),
          );

          if (userRole == "Client") {
            Navigator.pushReplacementNamed(context, "/client_dashboard");
          } else {
            Navigator.pushReplacementNamed(context, "/professional_dashboard");
          }
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Login failed")),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (emailController.text.isEmpty ||
        !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please enter a valid email"),
            backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Password reset email sent!"),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2D5C85), Color(0xFF8E44AD)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildCustomAppBar("Login"),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Welcome Back!",
                      style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField("Email", emailController, Icons.email, "Enter a valid email", isEmail: true),
                  _buildPasswordField("Password", passwordController, Icons.lock, "Password is required"),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: const Text("Forgot Password?", style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildLoginButton(),
                  _buildSignUpText(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
        ),
        onPressed: _login,
        child: const Text("Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSignUpText() {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.pushNamed(context, "/register"),
        child: const Text("Don't have an account? Sign Up", style: TextStyle(color: Colors.white70)),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, String validationMsg, {bool isEmail = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              prefixIcon: Icon(icon, color: Colors.white70),
            ),
            validator: (value) {
              if (value!.isEmpty) return validationMsg;
              if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return "Enter a valid email";
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, IconData icon, String validationMsg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: !_isPasswordVisible,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.2),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              prefixIcon: Icon(icon, color: Colors.white70),
              suffixIcon: IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value!.isEmpty) return validationMsg;
              return null;
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  PreferredSizeWidget _buildCustomAppBar(String title) {
    return AppBar(
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      centerTitle: true,
      backgroundColor: Colors.deepPurple,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }
}
