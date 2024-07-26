import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseUserAPI {
  // Instances of Firebase services
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore db = FirebaseFirestore.instance;
  static final FirebaseStorage storage = FirebaseStorage.instance;

  // Function to access current user's document
  Stream<DocumentSnapshot<Map<String, dynamic>>> getCurrentUser() {
    String? id = auth.currentUser!.uid;  // Get the current user's ID
    return db.collection("users").doc(id).snapshots(); // Return the user document
  }

  // Adds slambook info to the user's profile
  Future<String> addSlambook(String id, Map<String, dynamic> slambook) async {
    try {
      // Update the user document with the new slambook info
      await db.collection("users").doc(id).update({
        "slambook": slambook,
      });
      return "Successfully added slambook!";
    } on FirebaseException catch (e) {
      return "Error in ${e.code}: ${e.message}"; // Return error message
    }
  }

  // Remove slambook info to the user's profile
  Future<String> removeSlambook(String id) async {
    try {
      // Update the user document to remove the slambook values but not the document itself
      await db.collection("users").doc(id).update({
        "slambook": FieldValue.delete(),
      });
      return "Successfully removed slambook!";
    } on FirebaseException catch (e) {
      return "Error in ${e.code}: ${e.message}";  // Return error message
    }
  }

  // Edit slambook info
  Future<String> editSlambook(String id, Map<String, dynamic> slambook) async {
    try {
      // Update the user document with the new slambook info
      await db.collection("users").doc(id).update({
        "slambook": slambook,
      });
      return "Successfully updated slambook!";
    } on FirebaseException catch (e) {
      return "Error in ${e.code}: ${e.message}";  // Return error message
    }
  }

  // Uploads a profile picture to Firebase Storage and updates the user document with the image URL
  Future<String> uploadProfilePicture(String id, File image) async {
    try {
      // Upload image to Firebase Storage
      String fileName = 'profile/$id/${DateTime.now().millisecondsSinceEpoch}.png'; // File name = timestamp
      Reference storageRef = storage.ref().child(fileName); // Creates a reference to the file
      UploadTask uploadTask = storageRef.putFile(image);    // Uploads the file to the reference
      TaskSnapshot snapshot = await uploadTask;             // Waits for the upload to complete
      String downloadUrl = await snapshot.ref.getDownloadURL();   // Get the download URL of the uploaded image

      // Update the Firestore user document with the new image URL
      await db.collection("users").doc(id).update({
        "imageUrl": downloadUrl,
      });

      return "Successfully updated user profile!";  // Return message for successful update
    } on FirebaseException catch (e) {
      return "Error in ${e.code}: ${e.message}"; // Return message for error
    }
  }

  // Removes the profile picture and nulls them in the user document
  Future<String> removeProfilePicture(String id) async {
    try {
      // Update the Firestore user document to remove the image URL
      await db.collection("users").doc(id).update({
        "imageUrl": null,
      });
      return "Successfully removed user's profile picture!";  // Return message for successful removal
    } on FirebaseException catch (e) {
      return "Error in ${e.code}: ${e.message}";  // Return message for error
    }
  }
}
