import 'package:flutter/material.dart';

class ClientProjectsScreen extends StatelessWidget {
  const ClientProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Projects")),
      body: const Center(child: Text("List of Projects", style: TextStyle(fontSize: 20))),
    );
  }
}
