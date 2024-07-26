import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:traveler/providers/auth_provider.dart';
import 'signin_page.dart';
import 'package:traveler/screens/MainPage/dashboard_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  // Animation controller and animations
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<Color?> _backgroundColorAnimation;

  @override
  void initState() {
    super.initState();
    // Controls the duration of circle animation and reverses upon completion
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Curved animation for the rotation
    _rotationAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Color tween for the background color
    _backgroundColorAnimation = ColorTween(
      begin: const Color(0xFF0642BA),
      end: const Color(0xFF3B9BB3),
    ).animate(_rotationAnimation);
  }

  // Dispose is needed for the animation controller to prevent memory leaks
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Stream<User?> userStream = context.watch<UserAuthProvider>().userStream;  // Watches the user stream
    return FutureBuilder(   // Future builder to display the loading screen
      future: Future.delayed(const Duration(seconds: 4)),   // Displays the loading screen for 4 seconds
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AnimatedBuilder(
            animation: _backgroundColorAnimation,
            builder: (context, child) {
              return Scaffold(
                backgroundColor: _backgroundColorAnimation.value,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: Image.asset("assets/icon.png"),
                      ),
                      const Text(
                        "Traveler",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 75,
                        height: 75,
                        child: AnimatedBuilder(
                          animation: _rotationAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationAnimation.value * 2 * math.pi, // Full rotation
                              child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Positioned(
                                      top: 20,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 20,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 20,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 20,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          return StreamBuilder(
            stream: userStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Text("Error encountered! ${snapshot.error}"),
                  ),
                );
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (!snapshot.hasData) {
                return const SignInPage();  // Will go to the sign-in page if user is not logged in
              }
              // If the user is logged in, display the scaffold containing the streambuilder for the todos
              print("StreamBuilder: User logged in, navigating to DashboardPage.");
              return const DashboardPage();
            },
          );
        }
      },
    );
  }
}
