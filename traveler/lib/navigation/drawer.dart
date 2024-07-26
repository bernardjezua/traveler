import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:traveler/providers/friends_provider.dart';
import 'package:traveler/providers/user_provider.dart';

class DrawerWidget extends StatelessWidget {
  const DrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    String? currentRoute = ModalRoute.of(context)?.settings.name;  // Get the current route
    final friendsProvider = context.read<FriendListProvider>();    // Use provider read to fetch friends
    final userProvider = context.read<UserProfileProvider>();      // Get provider read to fetch user

    if (currentRoute == null) {
      print("Error: Current route is null.");
      return const Center(
        child: Text(
          "Error: Route context not found",
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(
            height: 100,
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Center(
                child: Text(
                  "",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Dashboard"),
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != "/dashboard") {
                Navigator.pushReplacementNamed(context, "/dashboard");
              }
              friendsProvider.fetchFriends();
              userProvider.fetchCurrentUser();
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != "/profile") {
                Navigator.pushReplacementNamed(context, "/profile");
              }
              friendsProvider.fetchFriends();
              userProvider.fetchCurrentUser();
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text("Friends"),
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != "/friends") {
                Navigator.pushReplacementNamed(context, "/friends");
              }
              friendsProvider.fetchFriends();
            },
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text("Slambook"),
            onTap: () {
              Navigator.pop(context);
              if (currentRoute != "/slambook") {
                Navigator.pushReplacementNamed(context, "/slambook");
              }
              friendsProvider.fetchFriends();
              userProvider.fetchCurrentUser();
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: const Text("Scan QR"),
            onTap: () {
              if (currentRoute != "/scanQR") {
                Navigator.pushNamed(context, "/scanQR");
              }
              friendsProvider.fetchFriends();
              userProvider.fetchCurrentUser();
            },
          ),
        ],
      ),
    );
  }
}