import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:traveler/providers/auth_provider.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Initialize the form key and variables for the form fields
  final _formKey = GlobalKey<FormState>();
  String? email;
  String? password;
  String? name;
  String? username;
  List<Map<String, dynamic>> slambook = [];
  List<TextEditingController> contactControllers = [];

  // Initialize controllers for required fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    contactControllers.add(TextEditingController());  // Initialize the first contact number controller
  }

  // Dispose the contact number controllers when the widget is removed, to avoid memory leaks
  @override
  void dispose() {
    for (var controller in contactControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(30),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Image.asset("assets/icon.png", width: 100, height: 100),
                ),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Name",
                    hintText: "Enter your name",
                  ),
                  inputFormatters: [
                    NameFormat(),
                  ],
                  onSaved: (value) => name = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your name";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Username",
                    hintText: "Enter your username",
                  ),
                  inputFormatters: [
                    UsernameFormat(),
                  ],
                  onSaved: (value) => username = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a username";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Email",
                    hintText: "Enter a valid email",
                  ),
                  onSaved: (value) => email = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a valid email";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Password",
                    hintText: "Enter your password",
                  ),
                  obscureText: true,
                  onSaved: (value) => password = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a password";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                // Display the list of contact number fields
                ...List.generate(contactControllers.length, (index) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: contactControllers[index],
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                labelText: index == 0 ? "Contact Number" : "Another Contact Number",
                                hintText: "Enter a contact number",
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter a contact number";
                                }
                                return null;
                              },
                            ),
                          ),
                          if (index != 0) // Allow deletion only for non-required fields
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => setState(() {
                                if (contactControllers.length > 1) {
                                  contactControllers.removeAt(index);
                                }
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10), // Space between contact fields
                    ],
                  );
                }),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  onPressed: () => setState(() {
                    // Add a new TextEditingController
                    contactControllers.add(TextEditingController());
                  }),
                  child: const Text("Add Contact"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      // Convert contactControllers to a list of strings
                      List<String> contactNumbers = contactControllers
                          .map((controller) => controller.text)
                          .toList();

                      // Ensure the current user is signed out
                      context.read<UserAuthProvider>().signOut(); 

                      // Sign up the user
                      String signUpResult = await context.read<UserAuthProvider>().signUp(name!, username!, email!, contactNumbers, slambook, password!);
                      ScaffoldMessenger.of(context)
                        ..removeCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(content: Text(signUpResult)),
                      );

                      // Go to dashboard if sign up is successful
                      if(signUpResult == "Sign up successful") {
                        Navigator.pushReplacementNamed(context, "/dashboard");
                      }
                    }
                  },
                  child: const Text("Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Transform name input to title case and remove invalid characters
class NameFormat extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Only allow letters, spaces, and apostrophes
    final newText = newValue.text.replaceAll(RegExp(r"[^a-zA-Z\s\']"), "");

    // Ensure the text starts with a capital or small letter
    if (newText.isNotEmpty && !RegExp(r'^[a-zA-Z]').hasMatch(newText[0])) {
      // If the first character is not a letter, remove it
      return TextEditingValue(
        text: newText.substring(1),
        selection: newValue.selection.copyWith(
          baseOffset: newText.length - 1,
          extentOffset: newText.length - 1,
        ),
      );
    }

    // Capitalize the first letter of each word
    final formattedText = newText.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');

    return TextEditingValue(
      text: formattedText,
      selection: newValue.selection.copyWith(
        baseOffset: formattedText.length,
        extentOffset: formattedText.length,
      ),
    );
  }
}


// Transform input to lowercase and remove invalid characters
class UsernameFormat extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Only allow lowercase letters, digits, '.', and '_'
    final newText = newValue.text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9._]'), '');

    // Ensure the text starts with a letter
    if (newText.isNotEmpty && !RegExp(r'^[a-z]').hasMatch(newText[0])) {
      // If the first character is not a letter, remove it
      return TextEditingValue(
        text: newText.substring(1),
        selection: newValue.selection.copyWith(
          baseOffset: newText.length - 1,
          extentOffset: newText.length - 1,
        ),
      );
    }

    return TextEditingValue(
      text: newText,
      selection: newValue.selection.copyWith(
        baseOffset: newText.length,
        extentOffset: newText.length,
      ),
    );
  }
}
