import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import 'job_recommendations_screen.dart';
import 'learning_path_screen.dart';
import 'profile_screen.dart';
import 'resume_scanner_screen.dart';
import 'resume_builder_screen.dart';
import 'certificate_validation_screen.dart';
import 'settings_screen.dart';
import 'support_request_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Widget> _getScreens(String? careerGoal) {
    if (careerGoal != null && careerGoal.isNotEmpty) {
      return [
        const LearningPathScreen(),
        const ProfileScreen(),
      ];
    }
    return [
      const JobRecommendationsScreen(),
      const LearningPathScreen(),
      const ProfileScreen(),
    ];
  }

  List<BottomNavigationBarItem> _getBottomNavItems(String? careerGoal) {
    if (careerGoal != null && careerGoal.isNotEmpty) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_fix_high_outlined),
          activeIcon: Icon(Icons.auto_fix_high),
          label: 'My Roadmap',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }
    return const [
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
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AppAuthProvider>(context);
    final careerGoal = authProvider.userProfile?.careerGoal;
    final screens = _getScreens(careerGoal);
    final navItems = _getBottomNavItems(careerGoal);

    // Ensure index is within bounds after dynamic update
    if (_selectedIndex >= screens.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(_selectedIndex, careerGoal),
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
                  if (careerGoal != null && careerGoal.isNotEmpty)
                    ListTile(
                      leading: Icon(Icons.school_outlined, color: Colors.grey.shade700),
                      title: Text('My Learning Journey',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _selectedIndex = 0);
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ResumeScannerScreen()),
                      );
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ResumeBuilderScreen()),
                      );
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CertificateValidationScreen()),
                      );
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsScreen()),
                      );
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SupportRequestScreen(isSupportOnly: true)),
                      );
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SupportRequestScreen(isSupportOnly: false)),
                      );
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
        children: screens,
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
          items: navItems,
        ),
      ),
    );
  }

  String _getAppBarTitle(int index, String? careerGoal) {
    if (careerGoal != null && careerGoal.isNotEmpty) {
       switch (index) {
        case 0:
          return 'My Roadmap';
        case 1:
          return 'My Profile';
        default:
          return 'Path-X';
      }
    }
    switch (index) {
      case 0:
        return 'Job Recommendations';
      case 1:
        return 'Learning Path';
      case 2:
        return 'My Profile';
      default:
        return 'Path-X';
    }
  }
}
