import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../termsandconditions/terms_and_conditions_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  String selectedRole = 'Client';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();
  final TextEditingController hourlyRateController = TextEditingController();
  final TextEditingController portfolioController = TextEditingController();
  final TextEditingController companyController = TextEditingController();

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreedToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please agree to the Terms & Conditions")),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        await _firestore.collection("users").doc(userCredential.user!.uid).set({
          "fullName": nameController.text.trim(),
          "email": emailController.text.trim(),
          "phoneNumber": phoneController.text.trim(),
          "role": selectedRole,
          "skills": selectedRole == "Professional" ? skillsController.text.trim() : "",
          "hourlyRate": selectedRole == "Professional" ? hourlyRateController.text.trim() : "",
          "portfolio": selectedRole == "Professional" ? portfolioController.text.trim() : "",
          "companyName": selectedRole == "Client" ? companyController.text.trim() : "",
          "profilePicture": "",
          "createdAt": Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Successful!")),
        );
        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Registration failed")),
        );
      } finally {
        setState(() => _isLoading = false);
      }
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
        appBar: AppBar(
          title: const Text("Sign Up", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.deepPurple,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
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
                      "Create an Account",
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildRoleSelection(),
                  buildTextField("Full Name", nameController, Icons.person, "Name is required"),
                  buildTextField("Email", emailController, Icons.email, "Enter a valid email", isEmail: true),
                  buildTextField("Phone Number", phoneController, Icons.phone, "Enter a valid phone number", isNumeric: true),
                  buildPasswordField("Password", passwordController, Icons.lock, "Password must be at least 6 characters"),
                  buildPasswordField("Confirm Password", confirmPasswordController, Icons.lock, "Passwords must match", confirmPassword: true),

                  if (selectedRole == "Professional") ...[
                    buildTextField("Skills (e.g., Flutter, Web Design)", skillsController, Icons.work, "Skills are required"),
                    buildTextField("Hourly Rate (PKR)", hourlyRateController, Icons.currency_rupee, "Enter your hourly rate", isNumeric: true),
                    buildTextField("Portfolio Link (Optional)", portfolioController, Icons.link, null), // Optional
                  ],

                  if (selectedRole == "Client") ...[
                    buildTextField("Company/Business Name (Optional)", companyController, Icons.business, null), // Optional
                  ],

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        onChanged: (value) => setState(() => _agreedToTerms = value!),
                        checkColor: Colors.white,
                        activeColor: Colors.orange,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen()),
                            );
                          },
                          child: const Text.rich(
                            TextSpan(
                              text: "I agree to the ",
                              style: TextStyle(color: Colors.white),
                              children: [
                                TextSpan(
                                  text: "Terms & Conditions",
                                  style: TextStyle(
                                    color: Colors.amberAccent,
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildSignUpButton(),
                  _buildLoginText(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("I am a", style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: selectedRole,
          items: ['Client', 'Professional'].map((role) {
            return DropdownMenuItem(value: role, child: Text(role));
          }).toList(),
          onChanged: (value) => setState(() => selectedRole = value!),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.2),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          dropdownColor: Colors.white,
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget buildTextField(
      String label,
      TextEditingController controller,
      IconData icon,
      String? validationMsg, {
        bool isEmail = false,
        bool isNumeric = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: isNumeric
              ? TextInputType.number
              : (isEmail ? TextInputType.emailAddress : TextInputType.text),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.2),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: Icon(icon, color: Colors.white70),
          ),
          validator: (value) {
            if (validationMsg != null && value!.isEmpty) return validationMsg;
            if (isEmail && value!.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return "Enter a valid email";
            return null;
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget buildPasswordField(
      String label,
      TextEditingController controller,
      IconData icon,
      String validationMsg, {
        bool confirmPassword = false,
      }) {
    bool isVisible = confirmPassword ? _isConfirmPasswordVisible : _isPasswordVisible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.2),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: Icon(icon, color: Colors.white70),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  if (confirmPassword) {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  } else {
                    _isPasswordVisible = !_isPasswordVisible;
                  }
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return validationMsg;
            if (!confirmPassword && value.length < 6) return "Password must be at least 6 characters";
            if (confirmPassword && value != passwordController.text) return "Passwords must match";
            return null;
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
        ),
        onPressed: _agreedToTerms ? _register : null,
        child: const Text("Sign Up", style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }

  Widget _buildLoginText() {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text(
          "Already have an account? Log In",
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
