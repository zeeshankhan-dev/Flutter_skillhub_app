import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.lock),
            title: Text("Change Password"),
          ),
          ListTile(
            leading: Icon(Icons.language),
            title: Text("Language"),
          ),
          ListTile(
            leading: Icon(Icons.dark_mode),
            title: Text("Dark Mode (Coming Soon)"),
          ),
        ],
      ),
    );
  }
}
