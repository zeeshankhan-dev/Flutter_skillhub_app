import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final bool isClient;
  const EditProfileScreen({super.key, required this.isClient});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController skillsController = TextEditingController();
  final TextEditingController hourlyRateController = TextEditingController();
  final TextEditingController portfolioController = TextEditingController();

  File? _selectedImage;
  String? _downloadUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection("users").doc(user.uid).get();

      if (userDoc.exists) {
        var data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          nameController.text = data["fullName"] ?? "";
          phoneController.text = data["phoneNumber"] ?? "";
          _downloadUrl = data["profilePicture"];
          if (widget.isClient) {
            companyController.text = data["companyName"] ?? "";
          } else {
            skillsController.text = data["skills"] ?? "";
            hourlyRateController.text = data["hourlyRate"] ?? "";
            portfolioController.text = data["portfolio"] ?? "";
          }
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      Reference ref = FirebaseStorage.instance.ref().child('profile_pictures/$userId.jpg');

      UploadTask uploadTask = ref.putFile(_selectedImage!);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection("users").doc(userId).update({
        "profilePicture": imageUrl,
      });

      setState(() {
        _downloadUrl = imageUrl;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Picture Updated Successfully!")),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image: $e")),
      );
    }
  }

  void _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Map<String, dynamic> updatedData = {
        "fullName": nameController.text.trim(),
        "phoneNumber": phoneController.text.trim(),
        "profilePicture": _downloadUrl,
      };

      if (widget.isClient) {
        updatedData["companyName"] = companyController.text.trim();
      } else {
        updatedData["skills"] = skillsController.text.trim();
        updatedData["hourlyRate"] = hourlyRateController.text.trim();
        updatedData["portfolio"] = portfolioController.text.trim();
      }

      await FirebaseFirestore.instance.collection("users").doc(user.uid).update(updatedData);
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Updated Successfully!")),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D5C85), Color(0xFF8E44AD)],
          ),
        ),
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white.withOpacity(0.2),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _buildProfileImage(),
                    _buildTextField("Full Name", nameController, Icons.person),
                    _buildTextField("Phone Number", phoneController, Icons.phone),
                    if (widget.isClient)
                      _buildTextField("Company Name", companyController, Icons.business),
                    if (!widget.isClient) ...[
                      _buildTextField("Skills", skillsController, Icons.work),
                      _buildTextField("Hourly Rate", hourlyRateController, Icons.attach_money,
                          isNumeric: true),
                      _buildTextField("Portfolio URL", portfolioController, Icons.link),
                    ],
                    const SizedBox(height: 20),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: 50,
            backgroundImage: _selectedImage != null
                ? FileImage(_selectedImage!)
                : (_downloadUrl != null
                ? NetworkImage(_downloadUrl!) as ImageProvider
                : const AssetImage("assets/default_profile.png")),
          ),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: _uploadImage,
          icon: const Icon(Icons.upload, color: Colors.white),
          label: const Text("Upload Image", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon,
      {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          prefixIcon: Icon(icon, color: Colors.white70),
          hintText: label,
          hintStyle: const TextStyle(color: Colors.white70),
        ),
        // validator: (value) => value!.isEmpty ? "$label is required" : null,
      ),
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orangeAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
        ),
        onPressed: _updateProfile,
        child: const Text("Save Changes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
