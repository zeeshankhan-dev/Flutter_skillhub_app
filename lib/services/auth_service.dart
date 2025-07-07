import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> registerUser({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String role,
    String? skills,
    String? hourlyRate,
    String? portfolio,
    String? companyName,
  }) async {
    try {
      // Create user in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user data in Firestore
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "fullName": fullName,
        "email": email,
        "phoneNumber": phoneNumber,
        "role": role,
        "skills": skills ?? "",
        "hourlyRate": hourlyRate ?? "",
        "portfolio": portfolio ?? "",
        "companyName": companyName ?? "",
        "createdAt": Timestamp.now(),
      });

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message; // Return error message
    }
  }
}
