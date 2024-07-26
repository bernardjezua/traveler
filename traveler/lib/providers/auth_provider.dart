import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:traveler/api/firebase_auth_api.dart';

class UserAuthProvider with ChangeNotifier {
  late FirebaseAuthAPI authService;   // Instance of FirebaseAuthAPI
  late Stream<User?> userStream;      // Stream of the current user
  User? user;

  UserAuthProvider() {
    // Initialize the instance of current user
    authService = FirebaseAuthAPI();
    userStream = authService.getUserStream();
    user = authService.getCurrentUser();
  }

  // Function to fetch the current user
  void fetchUser() {
    userStream = authService.getUserStream();
    notifyListeners();
  }

  // Function to check if the username exists upon adding friend via slambook or QR code
  Future<bool> checkUserName(String name) async {
    return await authService.getCurrentUserName(name);
  }

  // Function to get the current user's ID
  String? getUserId() {
    String? id = authService.getCurrentUserId();
    return id;
  }

  // Function to sign in using the username and password
  Future<String> signIn(String username, String password) async {
    try {
      return await authService.signIn(username, password);
    } catch (e) {
      return "Sign in failed: $e";
    }
  }

  // Function to sign out
  Future<void> signOut() async {
    await authService.signOut();
    notifyListeners();
  }

  // Function to sign up
  Future<String> signUp(String name, String username, String email, List contact, List<Map<String, dynamic>> slambook, String password) async {
    try {
      return await authService.signUp(name, username, email, contact, slambook, password);  // Call the sign up function
    } catch (e) {
      return "Sign up failed: $e";  // Return error message
    }
  }

  // Function to sign in with Google
  Future<String> signInWithGoogle() async {
    try {
      return await authService.signInWithGoogle();
    } catch (e) {
      return "Sign in with Google failed: $e";
    }
  }
}