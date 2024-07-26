import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:traveler/models/friend_model.dart';
import 'package:traveler/navigation/drawer.dart';
import 'package:traveler/providers/friends_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class FriendSummary extends StatefulWidget {
  const FriendSummary({super.key});

  @override
  State<FriendSummary> createState() => _FriendSummaryState();
}

class _FriendSummaryState extends State<FriendSummary> {
  PermissionStatus permissionStatus = PermissionStatus.denied;  // Deny permission by default
  File? imageFile;                             // Image file for the friend's picture
  final GlobalKey _qrkey = GlobalKey();        // Key for the QR code
  final ImagePicker _picker = ImagePicker();   // Image picker instance
  Friend? friend;                              // Friend instance
  bool showQRCode = false;  // Flag to show/hide QR code
  bool dirExists = false;   // Flag to check if directory exists

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    friend = ModalRoute.of(context)?.settings.arguments as Friend?; // Retrieves the friend instance from the arguments passed in the Friends Page
    requestPerms(); // Request camera and gallery permissions
  }

  // Function that captures and saves the QR code (PNG) to "FriendQRs" folder
  Future<void> saveQrCode() async {
    try {
      dynamic externalDir = "/storage/emulated/0/Download/FriendQRs";   // External directory path
      RenderRepaintBoundary boundary = _qrkey.currentContext!.findRenderObject() as RenderRepaintBoundary;  // Render the QR code
      var image = await boundary.toImage(pixelRatio: 3.0);    // Convert the QR code to an image

      // Draws a white background and renders the QR Code (image) on it
      final whitePaint = Paint()..color = Colors.white;     // White paint for the background
      final recorder = PictureRecorder();                     // Records the canvas
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()));  // Canvas for the QR code
      canvas.drawRect(Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), whitePaint);  // Draw a white background
      canvas.drawImage(image, Offset.zero, Paint());      // Draw the QR code on the canvas
      final picture = recorder.endRecording();            // Returns the QR code
      final img = await picture.toImage(image.width, image.height);   // Converts the QR code to an image
      ByteData? byteData = await img.toByteData(format: ImageByteFormat.png);   // Converts the image to byte data
      Uint8List pngBytes = byteData!.buffer.asUint8List();  // Converts the byte data to PNG bytes

      // Check for duplicate file name to avoid override
      String fileName = "FriendQRCode_1"; // Default file name
      int i = 1;
      while (await File("$externalDir/$fileName.png").exists()) {
        fileName = "FriendQRCode_$i";   // Increment the file name if it already exists
        i++;
      }

      // Check if directory path exists or not
      dirExists = await Directory(externalDir).exists();
      if (!dirExists) {
        await Directory(externalDir).create(recursive: true);  // Create the directory if it doesn't exist
      }

      // Save the QR code as a PNG file
      final file = await File("$externalDir/$fileName.png").create(); // Create the file
      await file.writeAsBytes(pngBytes); // Converts file to PNG

      if (!mounted) return; // Check if the QR code is saved
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text("QR code saved to gallery")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text("Something went wrong")));
    }
  }

  // Request camera and gallery permissions
  Future<void> requestPerms() async {
    await Permission.camera.request();
  }

  // Function to pick an image from either the camera or gallery
  Future<void> pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);  // Pick an image from the source

    if (pickedFile != null) { // Check if an image is picked
    setState(() {
      imageFile = File(pickedFile.path);
    });

    // Upload the image to Firebase Storage and update Firestore
    final friendId = friend?.id;
    context.read<FriendListProvider>().uploadFriendPicture(friendId, imageFile!);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Friend picture updated")));
    } else {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No image selected")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = friend?.name ?? "N/A";
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      drawer: const DrawerWidget(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 350,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: imageFile != null
                              ? FileImage(File(imageFile!.path))
                              : (friend?.imageUrl != null && friend!.imageUrl!.isNotEmpty
                                  ? NetworkImage(friend!.imageUrl!)
                                  : null),
                          child: imageFile == null && (friend?.imageUrl == null || friend!.imageUrl!.isEmpty)
                              ? const Icon(Icons.person, size: 50, color: Color(0xFF0642BA))
                              : null,
                        ),
                      ),
                      const Divider(color: Colors.blue),
                      const SizedBox(height: 5),
                      if (friend!.isVerified)
                        Center(
                          child: Container(
                            width: 80,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                "Verified",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Container(
                            width: 90,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                "Unverified",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(2),
                        },
                        children: [
                          TableRow(
                            children: [
                              const Text("Name", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(friend?.name ?? "N/A"),
                            ],
                          ),
                          TableRow(
                            children: [
                              const Text("Nickname", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(friend?.nickname ?? "N/A"),
                            ],
                          ),
                          TableRow(
                            children: [
                              const Text("Age", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(friend?.age.toString() ?? "N/A"),
                            ],
                          ),
                          TableRow(
                            children: [
                              const Text("Relationship", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(friend?.isSingle == true ? "Single" : "Taken"),
                            ],
                          ),
                          TableRow(
                            children: [
                              const Text("Happiness", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(friend?.happinessLevel.toString() ?? "N/A"),
                            ],
                          ),
                          TableRow(
                            children: [
                              const Text("Vision", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(friend?.vision ?? "N/A"),
                            ],
                          ),
                          TableRow(
                            children: [
                              const Text("Motto", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(friend?.motto ?? "N/A", textAlign: TextAlign.justify),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.arrow_back),
                              label: const Text("Back"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (!friend!.isVerified)
                            Center(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, "/edit", arguments: friend);
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text("Edit"),
                              ),
                            ),
                          const SizedBox(width: 10),
                          Center(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                if (friend != null) {
                                  _showDeleteConfirmation(context, friend);
                                }
                              },
                              icon: const Icon(Icons.delete),
                              label: const Text("Delete"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 350,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Center(
                        child: Icon(Icons.qr_code, size: 40, color: Colors.amber),
                      ),
                      const Center(
                        child: Text("QR Code", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      const Divider(color: Colors.blue),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                showQRCode = !showQRCode; // Toggles QR code visibility
                              });
                            },
                            icon: const Icon(Icons.qr_code_2),
                            label: Text(showQRCode ? "Hide" : "Generate"),
                          ),
                          const SizedBox(width: 10),
                          if (showQRCode)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: saveQrCode,
                              icon: const Icon(Icons.save),
                              label: const Text("Save to Gallery"),
                            ),
                        ],
                      ),
                      if (showQRCode)
                        Column(children: [
                          const SizedBox(height: 10),
                            Container(
                              decoration: BoxDecoration(
                              border: Border.all(color: Colors.purple, width: 3),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: SizedBox(
                              width: 200.0,
                              height: 200.0,
                              child: RepaintBoundary(
                                key: _qrkey,
                                child: QrImageView(
                                  data: jsonEncode(friend?.toJson(friend!)),
                                  version: QrVersions.auto,
                                  size: 200.0,
                                  gapless: true,
                                  errorStateBuilder: (ctx, err) {
                                    return const Center(child: Text("Something went wrong", textAlign: TextAlign.center));
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text("Add me as a friend via QR code!", style: TextStyle(fontSize: 14), textAlign: TextAlign.center),
                          const SizedBox(height: 5),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: 60.0,
          height: 60.0,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, "/scanQR");
            },
            tooltip: "Scan QR Code",
            child: const Icon(Icons.qr_code_scanner, size: 36.0),
          ),
        ),
      ),
    );
  }

  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Image"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text("Camera"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  pickImage(ImageSource.gallery);
                },
              ),
              if (imageFile != null || friend?.imageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("Remove Picture"),
                onTap: () {
                  Navigator.pop(context);
                  context.read<FriendListProvider>().removeFriendPicture(friend?.id ?? "");
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile picture removed, refresh the page")));
                  // Remove the image file from the state
                  if (imageFile != null) {
                    setState(() {
                      imageFile = null;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}


// Shows a dialog to confirm the deletion of the user's friend
void _showDeleteConfirmation(BuildContext context, friend) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Delete Friend"),
        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text("Are you sure you want to delete your friend?"),
              Text("This action cannot be undone."),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text("Cancel"),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () {
              context.read<FriendListProvider>().deleteFriend(friend!);
              ScaffoldMessenger.of(context)
                ..removeCurrentSnackBar()
                ..showSnackBar(
                const SnackBar(content: Text("Deleted friend")),
              );
              Navigator.pop(context); // Closes the dialog
              Navigator.pop(context); // Closes the details page
            },
          ),
        ],
      );
    },
  );
}