import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:traveler/models/friend_model.dart';
import 'package:traveler/api/firebase_friend_api.dart';

class FriendListProvider with ChangeNotifier {
  late Stream<QuerySnapshot> _friendsStream;  // Stream of friends
  var firebaseService = FirebaseFriendAPI();  // Instance of FirebaseFriendAPI

  // Constructor to fetch all friends from the database
  FriendListProvider() {
    fetchFriends();
  }

  // Getter for the friends stream
  Stream<QuerySnapshot> get friend => _friendsStream;

  // Fetches all friends from the database
  void fetchFriends() {
    _friendsStream = firebaseService.getAllFriends();
    notifyListeners();
  }

  // Checks if the friend already exists in the database using name, return firebase
  Future<bool> checkName(String name) async {
    return await firebaseService.checkName(name);
  }

  // Adds a friend to the database
  void addFriend(Friend friend) {
    try {
      firebaseService.addFriend(friend.toJson(friend));
      notifyListeners();
    } catch (e) {
      print("Failed to add friend: $e");
    }
  }

  // Edits a friend in the database
  void editFriend(Friend friend) async {
    if (friend.id == null) {  // Check if the friend ID is null
      return;
    }
    try {
      await firebaseService.editFriend(friend.id!, friend.toJson(friend));  // Update friend
      notifyListeners();
    } catch (e) {
      print("Failed to update friend: $e");
    }
  }

  // Deletes a friend from the database
  void deleteFriend(Friend friend) {
    if (friend.id == null) {  // Check if the friend ID is null
      return;
    }
    try {
      firebaseService.deleteFriend(friend.id!); // Delete friend
      notifyListeners();
    } catch (e) {
      print("Failed to delete friend: $e");
    }
  }
  
  // Uploads a friend's picture to Firebase Storage and updates the friend document with the image URL
  void uploadFriendPicture(String? id, File image) async {
    try {
      await firebaseService.uploadFriendPicture(id!, image);
      notifyListeners();
    } catch (e) {
      print("Failed to upload profile picture: $e");
    }
  }

  // Removes the friend's profile picture and nulls them in the friend document
  void removeFriendPicture(String id) async {
    try {
      await firebaseService.removeFriendPicture(id);
      notifyListeners();
    } catch (e) {
      print("Failed to remove profile picture: $e");
    }
  }
}
