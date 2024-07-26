import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:provider/provider.dart';
import 'package:traveler/providers/friends_provider.dart';
import 'package:traveler/models/friend_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traveler/providers/auth_provider.dart';

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({super.key});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  String _scanResult = "";  // Variable to store the scanned result

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scanQRCode()); // Call the scanQRCode function after the frame is rendered
  }

  // Function that scans the QR code (uses the camera)
  Future<void> _scanQRCode() async {
    String scanResult;
    try {
      scanResult = await FlutterBarcodeScanner.scanBarcode("#b3cee5", "Cancel", true, ScanMode.QR);   // Barcode scanner
      if (!mounted) return;  // Check if the scan result is mounted
      setState(() {
        _scanResult = scanResult;
      });
      addFriendFromQR(scanResult);  // Call the addFriendFromQR function
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text("Failed to scan QR code: $e")),
      );
    }
  }

  // Function to add a friend from the scanned QR code
  Future<void> addFriendFromQR(String qrResult) async {
    try {
      final Map<String, dynamic> friendData = jsonDecode(qrResult);

      // Create a new Friend object
      Friend friendqr = Friend(
        name: friendData["name"],
        nickname: friendData["nickname"],
        age: friendData["age"],
        isSingle: friendData["isSingle"],
        happinessLevel: friendData["happinessLevel"].toDouble(),
        vision: friendData["vision"],
        motto: friendData["motto"],
        isVerified: friendData["isVerified"],
        imageUrl: friendData["imageUrl"], // Retrieves the image URL of the friend if available/set by user already
      );

      // Retrieve friends from the provider (Firestore stream)
      final friendsProvider = context.read<FriendListProvider>();  // Instance of FriendListProvider
      final QuerySnapshot querySnapshot = await friendsProvider.firebaseService.getAllFriends().first;  // Retrieves the friends
      final List<QueryDocumentSnapshot> friendDocuments = querySnapshot.docs;  // List of friend documents

      // Check if a friend with the same name exists
      bool friendExists = false;
      String? existingFriendId;

      // Loops through the names of the friend list to check if the friend exists
      for (var doc in friendDocuments) {
        if (doc["name"] == friendqr.name) {
          friendExists = true;        // Set friendExists to true if the friend is found
          existingFriendId = doc.id;  // Get the ID of the existing friend
          break;
        }
      }

      // Compare if the QR code is the same as the current user
      bool userExists = await context.read<UserAuthProvider>().checkUserName(friendqr.name);
      if (userExists) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text("This QR code belongs to the current user")),
          );
        return Navigator.pop(context);
      }

      // If friend already exists, update their data
      if (friendExists && existingFriendId != null) {
        Friend existingFriend = Friend(
          id: existingFriendId,
          name: friendqr.name,
          nickname: friendqr.nickname,
          age: friendqr.age,
          isSingle: friendqr.isSingle,
          happinessLevel: friendqr.happinessLevel,
          vision: friendqr.vision,
          motto: friendqr.motto,
          isVerified: true, // Set friend to verified
          imageUrl: friendqr.imageUrl,  // Set the image URL of the friend if available/set by user
        );

        // Update the friend in Firestore
        friendsProvider.editFriend(existingFriend);
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text("Friend updated successfully!")),
        );
      } else {
        // Change the isVerified status to true and add the friend to Firestore
        friendqr.isVerified = true;
        friendsProvider.addFriend(friendqr);

        // Prompt user that friend was added successfully
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text("Friend added successfully!")),
        );
      }
      // Navigate back to the dashboard
      Navigator.pushNamed(context, "/dashboard");
    } catch (e) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("Failed to scan QR code, try again.")),
      );
      Navigator.pop(context);
      Navigator.pushNamed(context, "/dashboard");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan QR Code"),
      ),
      body: Center(
        child: Text(_scanResult.isEmpty ? "Scanning QR Code" : _scanResult),
        
      ),
    );
  }
}
