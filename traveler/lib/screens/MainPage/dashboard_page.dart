import 'package:flutter/material.dart';
import 'package:traveler/navigation/drawer.dart';
import 'package:traveler/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:traveler/providers/friends_provider.dart';
import 'package:traveler/providers/user_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final friendsProvider = context.read<FriendListProvider>(); // Used to fetch friends
    final userProvider = context.read<UserProfileProvider>();   // Used to fetch user

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Page"),
      ),
      drawer: const DrawerWidget(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Image.asset("assets/icon.png", height: 120, width: 120),
            const Text("Welcome to Traveler!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            // Dashboard buttons (2x2), derived from Exercise 2, alternative to drawer in order to fetch friends and user
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/friends");
                      friendsProvider.fetchFriends();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group, color: Colors.white, size: 30),
                        SizedBox(height: 5), 
                        Text("View Friends List", style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/slambook");
                      friendsProvider.fetchFriends();
                      userProvider.fetchCurrentUser();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: const Color(0xFF0642BA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.book, color: Colors.white, size: 30),
                        SizedBox(height: 5), 
                        Text("Add Friend via Form", style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, "/profile");
                      userProvider.fetchCurrentUser();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person, color: Colors.white, size: 30),
                        SizedBox(height: 5), 
                        Text("View Profile", style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/scanQR");
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: const Color(0xFF0642BA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code, color: Colors.white, size: 30),
                        SizedBox(height: 5), 
                        Text("Add Friend via QR", style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ElevatedButton(
                onPressed: () {
                  context.read<UserAuthProvider>().signOut();
                  // Redirect to the sign-in page
                  Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Log Out", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
