import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sh/screens/admin/project_list_screen.dart';
import 'package:sh/screens/admin/revenue_detail_screen.dart';
import 'package:sh/screens/admin/user_list_screen.dart';
import 'admin_drawer.dart';
import 'commission_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  double totalRevenue = 0;
  double totalCommission = 0;

  @override
  void initState() {
    super.initState();
    _fetchRevenueAndCommission();
  }

  Future<void> _fetchRevenueAndCommission() async {
    double revenue = 0;
    double commission = 0;

    final revenueSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('isCommission', isEqualTo: false)
        .where('status', isEqualTo: 'Completed')
        .get();

    for (var doc in revenueSnapshot.docs) {
      revenue += (doc['amount'] as num).toDouble();
    }

    final commissionSnapshot = await FirebaseFirestore.instance
        .collection('payments')
        .where('isCommission', isEqualTo: true)
        .where('status', isEqualTo: 'Completed')
        .get();

    for (var doc in commissionSnapshot.docs) {
      commission += (doc['amount'] as num).toDouble();
    }

    setState(() {
      totalRevenue = revenue;
      totalCommission = commission;
    });
  }

  Future<int> getUserCount(String role) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: role)
        .get();
    return snapshot.docs.length;
  }

  Future<int> getProjectCount({String? status}) async {
    Query query = FirebaseFirestore.instance.collection('projects');
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    final snapshot = await query.get();
    return snapshot.docs.length;
  }

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff43cea2), Color(0xff185a9d)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      drawer: const AdminDrawer(), // ✅ Use custom drawer here
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xfff2f2f2), Color(0xffe0f7fa)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchRevenueAndCommission,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Revenue and Commission Cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RevenueDetailsScreen()),
                          );
                        },
                        child: _buildSummaryCard(
                          title: 'Total Revenue',
                          amount: totalRevenue,
                          color: Colors.teal.shade600,
                          icon: Icons.attach_money,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CommissionDetailsScreen()),
                          );
                        },
                        child: _buildSummaryCard(
                          title: 'Total Commission',
                          amount: totalCommission,
                          color: Colors.deepOrange,
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Stats Grid
                  FutureBuilder<List<int>>(
                    future: Future.wait([
                      getUserCount('Client'),
                      getUserCount('Professional'),
                      getProjectCount(),
                      getProjectCount(status: 'ongoing'),
                      getProjectCount(status: 'completed'),
                    ]),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final data = snapshot.data ?? [0, 0, 0, 0, 0];

                      return GridView.count(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildStatCard(
                            title: 'Clients',
                            count: data[0],
                            icon: Icons.people_alt_rounded,
                            color: Colors.indigo,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const UserListScreen(role: 'Client')),
                            ),
                          ),
                          _buildStatCard(
                            title: 'Professionals',
                            count: data[1],
                            icon: Icons.engineering_outlined,
                            color: Colors.green.shade700,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const UserListScreen(role: 'Professional')),
                            ),
                          ),
                          _buildStatCard(
                            title: 'All Projects',
                            count: data[2],
                            icon: Icons.folder_copy_outlined,
                            color: Colors.deepPurple,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProjectListScreen()),
                            ),
                          ),
                          _buildStatCard(
                            title: 'Ongoing',
                            count: data[3],
                            icon: Icons.timelapse_outlined,
                            color: Colors.amber.shade800,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProjectListScreen(status: 'ongoing')),
                            ),
                          ),
                          _buildStatCard(
                            title: 'Completed',
                            count: data[4],
                            icon: Icons.check_circle_outline,
                            color: Colors.teal,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProjectListScreen(status: 'completed')),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// Updated Card Widgets (only design, logic is the same)

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: color.withOpacity(0.3),
      child: Container(
        width: 150,
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              'PKR ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        shadowColor: color.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                count.toString(),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
