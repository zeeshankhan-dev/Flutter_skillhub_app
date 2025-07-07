import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String projectId;
  final bool isCommission;

  const PaymentScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    required this.projectId,
    this.isCommission = false, // ✅ default to false
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedMethod = "JazzCash";
  bool _isProcessing = false;

  void _confirmPayment() {
    double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnack("Enter a valid amount", isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Payment"),
        content: Text("Pay PKR ${_amountController.text} using $_selectedMethod?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _finalizePayment(amount);
              },
              child: const Text("Confirm")),
        ],
      ),
    );
  }

  Future<void> _finalizePayment(double amount) async {
    setState(() => _isProcessing = true);
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Prevent duplicate commission payment for same project
    if (widget.isCommission) {
      final commissionAlreadyPaid = (await FirebaseFirestore.instance
          .collection("payments")
          .where("senderId", isEqualTo: currentUserId)
          .where("projectId", isEqualTo: widget.projectId)
          .where("isCommission", isEqualTo: true)
          .get())
          .docs
          .isNotEmpty;

      if (commissionAlreadyPaid) {
        _showSnack("Commission for this project has already been paid!", isError: true);
        setState(() => _isProcessing = false);
        return;
      }
    }

    try {
      await FirebaseFirestore.instance.collection("payments").add({
        "senderId": currentUserId,
        "receiverId": widget.receiverId,
        "amount": amount,
        "method": _selectedMethod,
        "projectId": widget.projectId,
        "isCommission": widget.isCommission, // ✅ New flag
        "status": "Completed",
        "timestamp": FieldValue.serverTimestamp(),
      });

      _amountController.clear();
      _showSnack("Payment successful!", isError: false);
    } catch (e) {
      _showSnack("Payment failed: $e", isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final String titleText = widget.isCommission ? "Pay Commission" : "Make Payment";
    final String headingText =
    widget.isCommission ? "Commission To SkillHub" : "Send Payment to:";
    final String receiverDisplay =
    widget.isCommission ? "SkillHub (Owner)" : widget.receiverName;

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2D5C85), Color(0xFF8E44AD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headingText,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      Text(receiverDisplay,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Enter Amount",
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.currency_rupee, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField(
                    value: _selectedMethod,
                    items: ["JazzCash", "Easypaisa"]
                        .map((method) => DropdownMenuItem(value: method, child: Text(method)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedMethod = value.toString()),
                    dropdownColor: Colors.deepPurple,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Select Payment Method",
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.payment, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _confirmPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      child: const Text("Pay Now"),
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
