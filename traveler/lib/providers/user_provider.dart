import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:traveler/api/firebase_user_api.dart';

class UserProfileProvider with ChangeNotifier {
  final FirebaseUserAPI firebaseService = FirebaseUserAPI();    // Instance of FirebaseUserAPI
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;  // Stream of the current user
  
  // Constructor to fetch the current user
  UserProfileProvider() {
    fetchCurrentUser();
  }

  // Getter for the user stream
  Stream<DocumentSnapshot<Map<String, dynamic>>> get userStream => _userStream;

  // Function to fetch the current user
  void fetchCurrentUser() {
    _userStream = firebaseService.getCurrentUser();
    notifyListeners();
  }

  // Adds slambook info to the user's profile
  void addSlambook(String id, Map<String, dynamic> slambook) async {
    try {
      await firebaseService.addSlambook(id, slambook);
      notifyListeners();
    } catch (e) {
      print("Failed to add slambook: $e");
    }
  }

  // Edits slambook info
  void editSlambook(String id, Map<String, dynamic> slambook) async {
    try {
      await firebaseService.editSlambook(id, slambook);
      notifyListeners();
    } catch (e) {
      print("Failed to edit slambook: $e");
    }
  }

  // Removes slambook info to the user's profile
  void removeSlambook(String id) async {
    try {
      await firebaseService.removeSlambook(id);
      notifyListeners();
    } catch (e) {
      print("Failed to remove slambook: $e");
    }
  }

  // Uploads a profile picture to Firebase Storage and updates the user document with the image URL
  void uploadProfilePicture(String? id, File image) async {
    try {
      await firebaseService.uploadProfilePicture(id!, image);
      notifyListeners();
    } catch (e) {
      print("Failed to update user profile: $e");
    }
  }

  // Removes the profile picture and nulls them in the user document
  void removeProfilePicture(String id) async {
    try {
      await firebaseService.removeProfilePicture(id);
      notifyListeners();
    } catch (e) {
      print("Failed to remove profile picture: $e");
    }
  }
}