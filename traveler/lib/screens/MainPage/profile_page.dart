import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:traveler/providers/auth_provider.dart';
import 'package:traveler/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traveler/navigation/drawer.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  PermissionStatus permissionStatus = PermissionStatus.denied;  // Deny permission by default
  File? imageFile;                             // Image file for the friend's picture      
  final GlobalKey _qrkey = GlobalKey();        // Key for the QR code
  final ImagePicker _picker = ImagePicker();   // Image picker instance
  bool showQRCode = false;  // Flag to show/hide QR code
  bool dirExists = false;   // Flag to check if directory exists

  @override
  void initState() {
    super.initState();  // Initialize the state for changes
    requestPerms();     // Request camera and storage permissions
  }

  // Function that captures and saves the QR code (PNG) to "TravelerQRs" folder
  Future<void> saveQrCode() async {
    try{
      dynamic externalDir = "/storage/emulated/0/Download/TravelerQRs";   // External directory path
      RenderRepaintBoundary boundary = _qrkey.currentContext!.findRenderObject() as RenderRepaintBoundary;  // Render the QR code
      var image = await boundary.toImage(pixelRatio: 3.0);    // Convert the QR code to an image

      // Draws a white background and renders the QR Code (image) on it
      final whitePaint = Paint()..color = Colors.white;   // White paint for the background
      final recorder = PictureRecorder();                   // Records
      final canvas = Canvas(recorder,Rect.fromLTWH(0,0,image.width.toDouble(),image.height.toDouble()));  // Canvas for the QR code
      canvas.drawRect(Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), whitePaint);  // Draw a white background
      canvas.drawImage(image, Offset.zero, Paint());        // Draw the QR code on the canvas
      final picture = recorder.endRecording();              // Returns the QR code
      final img = await picture.toImage(image.width, image.height);   // Converts the QR code to an image
      ByteData? byteData = await img.toByteData(format: ImageByteFormat.png);   // Converts the image to byte data
      Uint8List pngBytes = byteData!.buffer.asUint8List();  // Converts the byte data to PNG bytes

      // Check for duplicate file name to avoid override
      String fileName = "TravelerQRCode_1"; // Default file name
      int i = 1;
      while(await File("$externalDir/$fileName.png").exists()){
        fileName = "TravelerQRCode_$i"; // Increment the file name if it already exists
        i++;
      }

      // Check if directory path exists or not
      dirExists = await File(externalDir).exists();
      // If not, then create the path
      if (!dirExists) {
        await Directory(externalDir).create(recursive: true);  // Create the directory if it doesn't exist
        dirExists = true;
      }

      // Save the QR code as a PNG file
      final file = await File("$externalDir/$fileName.png").create(); // Create the file
      await file.writeAsBytes(pngBytes); // Converts file to PNG

      if (!mounted) return; // Check if the QR code is saved
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text("QR code saved to gallery")));
    } catch (e){
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
    final String userId = context.read<UserAuthProvider>().getUserId()!;
    context.read<UserProfileProvider>().uploadProfilePicture(userId, imageFile!);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile picture updated")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No image selected")));
    }
  }

  @override
  Widget build(BuildContext context) {
    Stream<DocumentSnapshot<Map<String, dynamic>>> userStream = context.watch<UserProfileProvider>().userStream;
    return Scaffold(
      drawer: const DrawerWidget(),
      appBar: AppBar(
        title: const Text("User Profile"),
      ),
      body: SingleChildScrollView(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: userStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text("No Data Available"));
            }
            Map<String, dynamic>? userData = snapshot.data?.data();
            return Column(
              children: [
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => _showImageSourceDialog(userData),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: imageFile != null
                        ? FileImage(File(imageFile!.path))
                        : (userData?["imageUrl"] != null && userData!["imageUrl"]!.isNotEmpty
                            ? NetworkImage(userData["imageUrl"]!)
                            : null),
                    child: imageFile == null && (userData?["imageUrl"] == null || userData!["imageUrl"]!.isEmpty)
                        ? const Icon(Icons.person, size: 50, color: Color(0xFF0642BA))
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Text(userData?["name"] ?? "N/A", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text("@${userData?["username"] ?? "N/A"}", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Card(
                    color: const Color(0xE3E4E3FF),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.email),
                          title: Text(userData?["email"] ?? "N/A"),
                        ),
                        // Generates a list of contact numbers
                        if (userData?["contact"] != null)
                          for (var contact in userData?["contact"])
                            ListTile(
                              leading: const Icon(Icons.phone),
                              title: Text(contact),
                            ),
                        ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: userData?["slambook"]?.isNotEmpty ?? false
                  ? 
                  Column(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: SizedBox(
                        width: 450,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Center(
                                child: Icon(Icons.book_rounded, size: 40, color: Colors.amber),
                              ),
                              const Center(
                                child: Text(
                                  "Summary",
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Divider(color: Colors.blue),
                              Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(1),
                                  1: FlexColumnWidth(2),
                                },
                                children: [
                                  TableRow(
                                    children: [
                                      const Text("Name", style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(userData?["slambook"]["name"] ?? "N/A"),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      const Text("Nickname", style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(userData?["slambook"]["nickname"] ?? "N/A"),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      const Text("Age", style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(userData?["slambook"]["age"].toString() ?? "N/A"),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      const Text("Relationship", style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(userData?["slambook"]["isSingle"] ? "Single" : "Taken"),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      const Text("Happiness", style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(userData?["slambook"]["happinessLevel"].toString() ?? "N/A"),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      const Text("Vision", style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(userData?["slambook"]["vision"] ?? "N/A"),
                                    ],
                                  ),
                                  TableRow(
                                    children: [
                                      const Text("Motto", style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(userData?["slambook"]["motto"] ?? "N/A", textAlign: TextAlign.justify),
                                    ],
                                  ),
                                ],
                              ),
                            const SizedBox(height: 10),
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
                                      Navigator.pushNamed(context, "/editInfo", arguments: userData);
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
                                    if (userData?["slambook"] != null || userData?["slambook"].isNotEmpty) {
                                      _showDeleteConfirmation(context, userData);
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
                        width: 450,
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
                                        showQRCode = !showQRCode; // Toggle QR code visibility
                                      });
                                    },
                                    icon: const Icon(Icons.qr_code_2),
                                    label: Text(showQRCode ? "Hide" : "Generate"),
                                  ),
                                  const SizedBox(width: 10), // Space between buttons
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
                                      width: 220.0,
                                      height: 220.0,
                                      child: RepaintBoundary(
                                        key: _qrkey,
                                        child: QrImageView(
                                          data: jsonEncode({
                                            ...userData!["slambook"],
                                            "imageUrl": userData["imageUrl"],  // Add imageUrl to the slambook map
                                          }),
                                          version: QrVersions.auto,
                                          size: 200.0,
                                          gapless: true,
                                          errorStateBuilder: (ctx, err) {
                                            return const Center(
                                              child: Text(
                                                "Something went wrong",
                                                textAlign: TextAlign.center,
                                              ),
                                            );
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
                    const SizedBox(height: 30),
                    ],
                  )
                  : Card(
                      color: const Color(0xFFFDFDFD),
                      child: ListTile(
                        leading: const Icon(Icons.book),
                        title: const Text("No Slambook Info"),
                        subtitle: const Text("Tap to add info"),
                        onTap: () {
                          Navigator.pushNamed(context, "/addInfo", arguments: userData);
                        },
                    ),
                  ),
                ),
              ],
            );
          },
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

  Future<void> _showImageSourceDialog(userData) async {
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
              if (imageFile != null || (userData?["imageUrl"] ?? "").isNotEmpty) // Check if a profile picture exists
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("Remove Picture"),
                onTap: () {
                  Navigator.pop(context);
                  context.read<UserProfileProvider>().removeProfilePicture(userData?["id"] ?? "");
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile picture removed")));
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

// Shows a dialog to confirm the deletion of the user's slambook info
Future<void> _showDeleteConfirmation(BuildContext context, userData) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Delete Info"),
        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text("Are you sure you want to delete your info?"),
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
              context.read<UserProfileProvider>().removeSlambook(userData?["id"]);
              ScaffoldMessenger.of(context)
                ..removeCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(content: Text("Slambook info successfully deleted")),
                );
              Navigator.pop(context);
            },
          ),
        ],
      );
    },
  );
}