import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:traveler/providers/auth_provider.dart';
import 'signup_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool showSignInErrorMessage = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  heading,
                  usernameField,
                  passwordField,
                  signInButton,
                  const SizedBox(height: 10),
                  signUpButton,
                  signInWithGoogleButton
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget get heading => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      children: [
        Image.asset("assets/icon.png", height: 100, width: 100),
        const SizedBox(height: 10),
        const Text("Sign In To Traveler", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget get usernameField => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: TextFormField(
      controller: usernameController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: "Username",
        prefixIcon: Icon(Icons.person),
      ),
      inputFormatters: [
        UsernameFormat(),
      ],
      onSaved: (value) => setState(() => usernameController.text = value?.toLowerCase() ?? ''),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please enter your username";
        }
        return null;
      },
    ),
  );

  Widget get passwordField => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: TextFormField(
      controller: passwordController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: "Password",
        prefixIcon: Icon(Icons.lock),
      ),
      obscureText: true,
      onSaved: (value) => setState(() => passwordController.text = value ?? ''),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please enter your password";
        }
        return null;
      },
    ),
  );

  Widget get signInButton => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          _formKey.currentState!.save();
          String signInResult = await context.read<UserAuthProvider>().signIn(usernameController.text, passwordController.text);
          if(signInResult.contains("Sign in successful")) {
            ScaffoldMessenger.of(context)
              ..removeCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(signInResult)),
            );
            Navigator.pushReplacementNamed(context, "/dashboard");
          } else {
            ScaffoldMessenger.of(context)
              ..removeCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(content: Text("Username or password is incorrect")),
            );
          }
        }
      },
      child: const Text("Sign In", style: TextStyle(fontSize: 16)),
    ),
  );

  Widget get signInWithGoogleButton => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.grey), // Add border
        ),
      ),
      onPressed: () async {
        String signInResult = await context.read<UserAuthProvider>().signInWithGoogle();
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(signInResult)),
        );
        if (signInResult == "Sign in successful") {
          Navigator.pushReplacementNamed(context, "/dashboard");
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/google_logo.png',
            height: 24.0,
            width: 24.0,
          ),
          const SizedBox(width: 8),
          const Text(
            "Sign In with Google",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );

  Widget get signUpButton => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text("No account yet? "),
      const SizedBox(width: 5),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.grey), // Add border
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SignUpPage(),
            ),
          );
        },
        child: const Text("Sign Up", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    ],
  );
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
