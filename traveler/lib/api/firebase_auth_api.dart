import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthAPI {
  // Instances of Firebase services
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore db = FirebaseFirestore.instance;
  static final FirebaseStorage storage = FirebaseStorage.instance;

  // Gets the current user's data from Firestore
  Stream<User?> getUserStream() {
    return auth.authStateChanges();
  }

  // Returns the current user
  User? getCurrentUser() {
    return auth.currentUser;
  }

  // Returns the current user's ID
  String? getCurrentUserId() {
    return auth.currentUser?.uid;
  }

  // Gets the current user's name from Firestore
  Future<bool> getCurrentUserName(String name) async {
    try {
      String? userId = getCurrentUserId(); // Get the current user's ID
      if (userId == null) {
        return false; // User is not logged in
      }

      // Fetch the document from User ID
      DocumentSnapshot userDoc = await db.collection("users").doc(userId).get();

      // Check if the document exists and the name matches
      if (userDoc.exists) {
        String currentUserName = userDoc.get("name");
        return currentUserName == name; // Return true if the name matches
      } else {
        return false; // User document does not exist
      }
    } catch (e) {
      return false; // Error occurred
    }
  }

  // Sign in using the username and password, returns a message
  Future<String> signIn(String username, String password) async {
    try {
      // Check if the username exists in Firestore
      final QuerySnapshot result = await db.collection("users").where("username", isEqualTo: username).limit(1).get();

      // If no user is found, return string message
      if (result.docs.isEmpty) {
        return "No user found for that username";
      }

      // Get the user's email
      final userDoc = result.docs.first; // Get the document
      final email = userDoc.get("email"); // Get the email from the document

      // Sign in using the retrieved email and password
      await auth.signInWithEmailAndPassword(email: email, password: password);
      return "Sign in successful";
    } on FirebaseAuthException catch (e) {
      if (e.code == "wrong-password") {
        return "Wrong password provided";  // Return message for wrong password
      }
    } catch (e) {
      return "Sign in failed: $e";  // Return message for other errors
    }
    return "Sign in failed";  // Return message for unknown errors
  }

  // Sign up using the document data, returns a message if successful
  Future<String> signUp(String name, String username, String email, List contact, List<Map<String, dynamic>> slambook, String password) async {
    try {
      // Remove all extra whitespaces from the name (it should be a valid name)
      name = name.replaceAll(RegExp(r"\s+"), " ");

      // Check if the username already exists in firestore
      final QuerySnapshot usernameQuery = await db.collection("users").where("username", isEqualTo: username).limit(1).get();
      if (usernameQuery.docs.isNotEmpty) {
        return "Username already exists. Please choose a different username.";
      }

      // Create a new user with the email and password
      UserCredential credential = await auth.createUserWithEmailAndPassword(email: email, password: password);

      // Check if the user document exists
      if (credential.user != null) {
        // Check if a user document with the UID already exists
        DocumentSnapshot userDoc = await db.collection("users").doc(credential.user!.uid).get();
        if (!userDoc.exists) {
          // Save the user of document data to Firestore
          await saveUserToFirestore(credential.user!.uid, name, username, email, contact, slambook);
          return "Sign up successful";  // Return message for successful sign up
        } else {
          return "User already exists"; // Return message for existing user
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == "email-already-in-use") { // Check if the email is already in use
        return "Account already exists with that email.";
      }
    } catch (e) { // Catch other errors
      return "Sign up failed: $e";
    }
    return "Sign up failed";  // Return message for unknown errors
  }

  // Sign out the current user
  Future<void> signOut() async {
    await auth.signOut(); // Sign out the user
  }

  // Save the user data to firestore
  Future<void> saveUserToFirestore(String uid, String name, String username, String email, List contact, List<Map<String, dynamic>> slambook) async {
    try {
      // Check if the user document exists
      final userDocRef = db.collection("users").doc(uid);

      // Get the document snapshot
      final docSnapshot = await userDocRef.get();

      // If the document does not exist, set the initial data
      if (!docSnapshot.exists) {
        await userDocRef.set({
          "id": uid,
          "name": name,
          "username": username,
          "email": email,
          "contact": contact,
          "slambook": slambook,
        });
      }
    } on FirebaseException catch (e) {
      print(e.message); // Print the error message
    }
  }

  // Sign in with Google
  Future<String> signInWithGoogle() async {
    try {
      // Check if the user is already signed in
      if (auth.currentUser != null) {
        return "User is already signed in";
      }

      await GoogleSignIn().signOut(); // Sign out the user from Google

      // Initiate the Google sign-in flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // If the user cancels the sign-in, return a message
      if (googleUser == null) {
        return "Google sign-in canceled by user";
      }

      // Obtain the Google user's authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential using the obtained token
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Get the Google user's email
      final String googleEmail = googleUser.email;

      // Check if the email exists in Firestore
      final QuerySnapshot result = await db.collection("users").where("email", isEqualTo: googleEmail).limit(1).get();

      // If no user is found, return a message
      if (result.docs.isEmpty) {
        return "No user found for this Google account. Please sign up first.";
      }

      // Sign in with the Google credential
      await FirebaseAuth.instance.signInWithCredential(credential);
      return "Sign in successful";
    } on FirebaseAuthException catch (e) {
      return "Sign in failed: ${e.message}";
    } catch (e) {
      return "Sign in failed: $e";
    }
  }
}