import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import 'job_recommendations_screen.dart';
import 'learning_path_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  final List<Widget> _screens = [
    const JobRecommendationsScreen(
      assessmentResults: {},
    ),
    const LearningPathScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(_selectedIndex),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                  color: Colors.blue.shade800,
                  image: const DecorationImage(
                    image: NetworkImage(
                        'https://images.unsplash.com/photo-1557683316-973673baf926'), // generic abstract
                    fit: BoxFit.cover,
                    colorFilter:
                        ColorFilter.mode(Colors.black38, BlendMode.darken),
                  )),
              accountName: Text(
                authProvider.userProfile?.displayName ?? 'PathX User',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              accountEmail: Text(
                authProvider.userProfile?.email ?? '',
                style: GoogleFonts.poppins(),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  (authProvider.userProfile?.displayName ?? 'P')[0]
                      .toUpperCase(),
                  style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person_outline, color: Colors.grey.shade700),
              title: Text('Profile',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.settings_outlined, color: Colors.grey.shade700),
              title: Text('Settings',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings (placeholder)
              },
            ),
            ListTile(
              leading: Icon(Icons.support_agent_outlined,
                  color: Colors.grey.shade700),
              title: Text('Support',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                // Navigate to support (placeholder)
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.add_box_outlined, color: Colors.grey.shade700),
              title: Text('Add Features / Course',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                // Navigate to add features (placeholder)
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: Text('Logout',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500, color: Colors.redAccent)),
              onTap: () async {
                setState(() => _isLoading = true);
                await authProvider.signOut();
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ]),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue.shade700,
          unselectedItemColor: Colors.grey.shade500,
          selectedLabelStyle:
              GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.work_outline),
              activeIcon: Icon(Icons.work),
              label: 'Jobs',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school),
              label: 'Learn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return 'Job Recommendations';
      case 1:
        return 'Learning Path';
      default:
        return 'Path-X';
    }
  }
}
