import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sh/screens/admin/profile/admin_profile_screen.dart';
import 'package:sh/screens/admin/project_list_screen.dart';
import 'package:sh/screens/admin/revenue_detail_screen.dart';
import 'package:sh/screens/admin/utils/auth_helper.dart';
import '../help_support_screen.dart';
import '../termsandconditions/terms_and_conditions_screen.dart';
import 'commission_detail_screen.dart';

class AdminDrawer extends StatefulWidget {
  const AdminDrawer({super.key});

  @override
  State<AdminDrawer> createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<AdminDrawer> {
  String? _name;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        _name = doc.data()?['fullName'] ?? 'Admin';
        _role = doc.data()?['role'] ?? 'admin';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final firstLetter = _name != null && _name!.isNotEmpty ? _name![0].toUpperCase() : 'A';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff43cea2), Color(0xff185a9d)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                firstLetter,
                style: const TextStyle(fontSize: 24, color: Colors.black),
              ),
            ),
            accountName: Text(_name ?? 'Loading...'),
            accountEmail: Text(_role != null ? _role!.toUpperCase() : ''),
          ),

          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfileScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('All Projects'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectListScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Revenue Details'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RevenueDetailsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.wallet),
            title: const Text('Commission Details'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CommissionDetailsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms & Conditions'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => logout(context),
          ),
        ],
      ),
    );
  }
}
