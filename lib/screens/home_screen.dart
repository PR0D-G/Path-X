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

  final List<Widget> _screens = [
    const JobRecommendationsScreen(),
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
                  color: const Color(0xFF004B8D), // Mumbai Indians Blue
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
                  (authProvider.userProfile?.displayName != null &&
                          authProvider.userProfile!.displayName!.isNotEmpty)
                      ? authProvider.userProfile!.displayName![0].toUpperCase()
                      : 'P',
                  style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF004B8D)),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading:
                        Icon(Icons.person_outline, color: Colors.grey.shade700),
                    title: Text('My Profile',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
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
                    leading: Icon(Icons.document_scanner_outlined,
                        color: Colors.grey.shade700),
                    title: Text('Scan My Resume',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to scan resume
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.description_outlined,
                        color: Colors.grey.shade700),
                    title: Text('Build Your Resume',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to build resume
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.verified_outlined,
                        color: Colors.grey.shade700),
                    title: Text('Validate/Verify Certificates',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to verify certificates
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.settings_outlined,
                        color: Colors.grey.shade700),
                    title: Text('Settings',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to settings (placeholder)
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.support_agent_outlined,
                        color: Colors.grey.shade700),
                    title: Text('Support',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to support (placeholder)
                    },
                  ),
                  ListTile(
                    leading:
                        Icon(Icons.help_outline, color: Colors.grey.shade700),
                    title: Text('Raise a Request',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to raise request (placeholder)
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: Text('Logout',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500, color: Colors.redAccent)),
              onTap: () async {
                await authProvider.signOut();
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
          selectedItemColor: const Color(0xFF004B8D), // Mumbai Indians Blue
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
