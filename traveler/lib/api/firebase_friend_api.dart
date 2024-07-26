import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseFriendAPI {
  // Instances of Firebase services
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore db = FirebaseFirestore.instance;
  static final FirebaseStorage storage = FirebaseStorage.instance;

  // Fetches all friends for the current user
  Stream<QuerySnapshot> getAllFriends() {
    if (auth.currentUser == null) {
      print("Error: User is not logged in");
      return Stream.empty();
    }

    print("Fetching friends for user ID: ${auth.currentUser!.uid}");
    return db.collection("users").doc(auth.currentUser!.uid).collection("friends").snapshots();
  }

  // Checks if the friend already exists in the database using name (assuming it is unique)
  Future<bool> checkName(String name) async {
    QuerySnapshot result = await db.collection("users").doc(auth.currentUser!.uid).collection("friends").where("name", isEqualTo: name).limit(1).get();
    return result.docs.isNotEmpty;
  }

  // Adds a friend to the database
  Future<void> addFriend(Map<String, dynamic> friend) async {
    if (auth.currentUser == null) return; // Added null check
    try {
      // Add new document to the "friends" sub-collection and captures the document reference (Friend ID)
      DocumentReference docRef = await db.collection("users").doc(auth.currentUser!.uid).collection("friends").add(friend);
      // Update the new instance of friend with its own document ID for friend.id
      await docRef.update({"id": docRef.id});
    } on FirebaseException catch (e) {
      print("Failed with error: ${e.code}");  // Prompt error message
    }
  }

  // Edits a friend in the database using the friend's ID and new data
  Future<void> editFriend(String id, Map<String, dynamic> friendData) async {
    if (auth.currentUser == null) return; // Added null check
    try {
      // Correctly use the id to get the DocumentReference
      DocumentReference friendRef = db.collection("users").doc(auth.currentUser!.uid).collection("friends").doc(id);
      // Update the document with the new data
      await friendRef.update(friendData);
    } on FirebaseException catch (e) {
      print("Failed with error: ${e.code}");  // Prompt error message
    }
  }

  // Deletes a friend from the database using the friend's ID
  Future<void> deleteFriend(String id) async {
    if (auth.currentUser == null) return; // Added null check
    try {
      // Deletes the friend document with the given ID
      await db.collection("users").doc(auth.currentUser!.uid).collection("friends").doc(id).delete();
    } on FirebaseException catch (e) {
      print("Failed with error: ${e.code}");  // Prompt error message
    }
  }

  // Uploads a friend's picture to Firebase Storage and updates the friend document with the image URL
  Future<String> uploadFriendPicture(String id, File image) async {
    try {
      // Upload image to Firebase Storage
      String fileName = "friends/$id/${DateTime.now().millisecondsSinceEpoch}.png"; // File name = timestamp
      Reference storageRef = storage.ref().child(fileName); // Creates a reference to the file
      UploadTask uploadTask = storageRef.putFile(image);    // Uploads the file to the reference
      TaskSnapshot snapshot = await uploadTask;             // Waits for the upload to complete
      String downloadUrl = await snapshot.ref.getDownloadURL();   // Get the download URL of the uploaded image

      // Update the Firestore user document with the new image URL
      await db.collection("users").doc(auth.currentUser!.uid).collection("friends").doc(id).update({
        "imageUrl": downloadUrl,
      });

      return "Successfully updated user profile!";  // Return message for successful update
    } on FirebaseException catch (e) {
      return "Error in ${e.code}: ${e.message}";  // Return message for error
    }
  }

  // Removes the friend's picture and nulls them in the friend document
  Future<String> removeFriendPicture(String id) async {
    try {
      // Update the Firestore user document with the new image URL
      await db.collection("users").doc(auth.currentUser!.uid).collection("friends").doc(id).update({
        "imageUrl": null,
      });
      return "Successfully removed friend's profile picture!";  // Return message for successful update
    } on FirebaseException catch (e) {
      return "Error in ${e.code}: ${e.message}";  // Return message for error
    }
  }
}
