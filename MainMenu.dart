import 'package:flutter/material.dart';
import 'package:Attendance_App/pages/AddFaceAttendancePage.dart';
import 'package:Attendance_App/pages/ViewAttendanceDataPage.dart';

class Home extends StatefulWidget {
  final String userId;
  final String? role;

  const Home({Key? key, required this.userId, this.role}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    AddFaceAttendancePage(),
    ViewAttendanceDataPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Function to handle logout
  void _handleLogout() {
    // Add your logout logic here, such as clearing user session or navigating to the login screen.
    // For example, you can use Navigator to navigate to the login screen:
    Navigator.pushReplacementNamed(context, '/'); // Replace '/' with your actual login route.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: Colors.black,
        selectedItemColor: Colors.deepOrange,
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            // If the "Logout" button is tapped (index 2), call the _handleLogout function
            _handleLogout();
          } else {
            // If other tabs are tapped, change the selected tab
            _onItemTapped(index);
          }
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(

            icon: Icon(Icons.add_card_outlined),
            label: 'Mark Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Attendance  Data',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.exit_to_app),
            label: 'Logout',
          ), // Added logout button
        ],
      ),
    );
  }
}
