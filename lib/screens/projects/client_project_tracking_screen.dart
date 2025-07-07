import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClientProjectTrackingScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;
  final String professionalId;
  final double progress;

  const ClientProjectTrackingScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
    required this.professionalId,
    required this.progress,
  });

  @override
  _ClientProjectTrackingScreenState createState() => _ClientProjectTrackingScreenState();
}

class _ClientProjectTrackingScreenState extends State<ClientProjectTrackingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _updateController = TextEditingController();

  double _progress = 0.0;
  String _latestUpdate = "No updates yet.";
  bool _isUpdating = false;
  bool _firstPaymentMade = false;
  bool _secondPaymentMade = false;
  bool _finalPaymentMade = false;
  bool _commissionPaid = false;

  @override
  void initState() {
    super.initState();
    _progress = widget.progress;
    _fetchProgress();
  }

  void _fetchProgress() async {
    try {
      DocumentSnapshot projectSnapshot = await _firestore.collection("projects").doc(widget.projectId).get();

      if (projectSnapshot.exists) {
        setState(() {
          _progress = (projectSnapshot["progress"] is num) ? projectSnapshot["progress"].toDouble() : 0.0;
          _latestUpdate = projectSnapshot["latestUpdate"] ?? "No updates yet.";
          _firstPaymentMade = projectSnapshot["firstPaymentMade"] ?? false;
          _secondPaymentMade = projectSnapshot["secondPaymentMade"] ?? false;
          _finalPaymentMade = projectSnapshot["finalPaymentMade"] ?? false;
          _commissionPaid = projectSnapshot["commissionPaid"] ?? false;
        });
      }
    } catch (e) {
      print("Error fetching progress: $e");
    }
  }

  Future<void> _updateProgress(double newProgress, String updateText) async {
    if (_isUpdating || updateText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid progress update!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      await _firestore.collection("projects").doc(widget.projectId).update({
        "progress": newProgress,
        "latestUpdate": updateText,
        "status": newProgress == 100.0 ? "completed" : "ongoing",
      });

      setState(() {
        _progress = newProgress;
        _latestUpdate = updateText;
        _updateController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newProgress == 100.0 ? "Project marked as completed!" : "Progress updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error updating progress: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update progress."), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  void _markPayment(String type) async {
    await _firestore.collection("projects").doc(widget.projectId).update({
      type: true,
    });
    setState(() {
      if (type == "firstPaymentMade") _firstPaymentMade = true;
      if (type == "secondPaymentMade") _secondPaymentMade = true;
      if (type == "finalPaymentMade") _finalPaymentMade = true;
      if (type == "commissionPaid") _commissionPaid = true;
    });
  }

  Color _getProgressColor() {
    if (_progress < 30) return Colors.redAccent;
    if (_progress < 60) return Colors.orangeAccent;
    if (_progress < 90) return Colors.blueAccent;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    bool isProfessional = FirebaseAuth.instance.currentUser!.uid == widget.professionalId;
    bool isClient = !isProfessional;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text("Tracking: ${widget.projectTitle}"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D5C85), Color(0xFF8E44AD)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Progress Status", style: _sectionTitleStyle()),
                      const SizedBox(height: 10),
                      Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            height: 10,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white30,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          Container(
                            height: 10,
                            width: MediaQuery.of(context).size.width * (_progress / 100),
                            decoration: BoxDecoration(
                              color: _getProgressColor(),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text("Completion: ${_progress.toStringAsFixed(1)}%", style: _infoTextStyle()),
                      const SizedBox(height: 20),
                      Text("Latest Update:", style: _sectionTitleStyle()),
                      const SizedBox(height: 5),
                      Text(_latestUpdate, style: _infoTextStyle()),
                      const SizedBox(height: 20),
                      if (isClient) _buildClientPaymentAlerts(),
                      if (isProfessional) _buildProfessionalCommissionAlert(),
                      const Spacer(),
                      if (isProfessional) _buildProgressUpdateSection(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  TextStyle _sectionTitleStyle() {
    return const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold);
  }

  TextStyle _infoTextStyle() {
    return const TextStyle(color: Colors.white70);
  }

  Widget _buildClientPaymentAlerts() {
    if (_progress >= 90 && !_finalPaymentMade) {
      return _buildAlertBox(
        "Final Payment Due",
        "Final stage! Please pay the remaining 40% to complete the project. Confirm with the professional.",
        "finalPaymentMade",
      );
    } else if (_progress >= 60 && !_secondPaymentMade) {
      return _buildAlertBox(
        "Second Payment Due",
        "Project reached 60%. Pay the second 30% installment to the professional. Coordinate with them.",
        "secondPaymentMade",
      );
    } else if (_progress >= 30 && !_firstPaymentMade) {
      return _buildAlertBox(
        "Initial Payment Due",
        "Project started. Please pay the initial 30% to the professional directly. Contact them for details.",
        "firstPaymentMade",
      );
    }
    return const SizedBox();
  }


  Widget _buildProfessionalCommissionAlert() {
    if (_progress >= 60 && !_commissionPaid) {
      return _buildAlertBox("Commission Fee Due", "Client paid second installment. Please pay your commission to SkillHub via EasyPaisa: 0349-4678746. or Email us at skillhub.support@gmail.com or chat with us at 0349-4678746." , "commissionPaid");
    }
    return const SizedBox();
  }

  Widget _buildAlertBox(String title, String message, String paymentKey) {
    return Card(
      color: Colors.white.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
            const SizedBox(height: 5),
            Text(message, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _markPayment(paymentKey),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Mark as Paid"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProgressUpdateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Update Progress", style: _sectionTitleStyle()),
        const SizedBox(height: 5),
        Slider(
          value: _progress,
          min: 0,
          max: 100,
          divisions: 20,
          label: "${_progress.toStringAsFixed(1)}%",
          onChanged: (value) {
            setState(() {
              _progress = value;
            });
          },
        ),
        TextField(
          controller: _updateController,
          decoration: InputDecoration(
            hintText: "Enter progress update...",
            hintStyle: _infoTextStyle(),
            filled: true,
            fillColor: Colors.white.withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          style: _infoTextStyle(),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _isUpdating
              ? null
              : () => _updateProgress(
            _progress,
            _updateController.text.isEmpty
                ? "Updated progress to $_progress%"
                : _updateController.text,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: _isUpdating
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text("Submit Update"),
        ),
      ],
    );
  }
}
