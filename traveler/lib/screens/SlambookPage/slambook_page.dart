import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:traveler/models/friend_model.dart';
import 'package:traveler/navigation/drawer.dart';
import 'package:traveler/providers/friends_provider.dart';
import 'package:traveler/providers/auth_provider.dart';
import 'package:traveler/screens/SignInPage/signup_page.dart';

class SlamBookForm extends StatefulWidget {
  const SlamBookForm({super.key});

  @override
  State<SlamBookForm> createState() => _SlamBookFormState();
}

class _SlamBookFormState extends State<SlamBookForm> {
  // Dropdown options
  List<String> dropdownOptions = ["Anemo", "Cryo", "Dendro", "Electro", "Geo", "Hydro", "Pyro"];

  // Initial values
  bool isSingle = false;
  double happinessLevel = 5.0;
  String dropdownValue = "Anemo";
  String selectedMotto = "The limit to one's power is self-destruction.";
  bool result = false;
  bool isVerified = false;

  // Key and controllers
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController nicknameController = TextEditingController();
  TextEditingController ageController = TextEditingController();

  // Submitted values stored in variables
  late String submittedName;
  late String submittedNickname;
  late String submittedAge;
  late double submittedHappinessLevel;
  late bool submittedIsSingle;
  late String submittedDropdownValue;
  late String submittedMotto;

  // Regular expressions to match names and nicknames, learned from CMSC 124 and 141
  final RegExp nameRegex = RegExp(r'^[A-Za-z]+(?: [A-Za-z]+)*$'); // Allows multiple words separated by a space
  final RegExp nicknameRegex = RegExp(r'^[A-Za-z]+(?: [A-Za-z]+){0,4}$'); // Allows one to five words separated by a space

  // Function to validate the name
  bool isValidName(String name) {
    return nameRegex.hasMatch(name);
  }

  // Function to validate the nickname
  bool isValidNickname(String nickname) {
    return nicknameRegex.hasMatch(nickname);
  }

  // Function to reset the form
  void resetForm() {
    // Check if no values were entered
    if (nameController.text.isEmpty &&
        nicknameController.text.isEmpty &&
        ageController.text.isEmpty &&
        !isSingle &&
        happinessLevel == 5.0 &&
        dropdownValue == "Anemo" &&
        selectedMotto == "The limit to one's power is self-destruction.") {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("No values to reset")),
        );
      return;
    }
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text("Record reset")),
      );

    _formKey.currentState?.reset();
    nameController.clear();
    nicknameController.clear();
    ageController.clear();

    setState(() {
      isSingle = false;
      happinessLevel = 5.0;
      dropdownValue = "Anemo";
      selectedMotto = "The limit to one's power is self-destruction.";
      result = false;
    });
    
  }

  // Function that submits the data to be transferred
  void submitForm() async {
    // Check if name already exists in the database
    bool nameExists = await context.read<FriendListProvider>().checkName(nameController.text);
    if (nameExists) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("Name already exists in your friend list")),
        );
      return;
    }

    // Get the name of the current user and compare it to the name entered
    bool userExists = await context.read<UserAuthProvider>().checkUserName(nameController.text);
    if (userExists) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("You cannot add yourself as a friend")),
        );
      return;
    }
    
    // Check if name is valid, multiple words separated by space (e.g. Juan Dela Cruz)
    if (!isValidName(nameController.text)) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("Invalid name. It must start with a letter and have only one space between words.")),
        );
      return;
    }

    // Check if nickname is valid, one to five words separated by space (e.g. Bern, Flame Hashira)
    if (!isValidNickname(nicknameController.text)) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("Invalid nickname. It must start with a letter and it can only be from one to five words.")),
        );
      return;
    }

    // Check if age is a number and greater than 0
    if (int.tryParse(ageController.text) == null || int.parse(ageController.text) <= 0) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("Invalid age. Please enter a number.")),
        );
      return;
    }

    // Validate the form before submission
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text("Record submitted, see results below")),
        );

      setState(() {
        // Store new values in submitted variables
        submittedName = nameController.text;
        submittedNickname = nicknameController.text;
        submittedAge = ageController.text;
        submittedIsSingle = isSingle;
        submittedHappinessLevel = happinessLevel;
        submittedDropdownValue = dropdownValue;
        submittedMotto = selectedMotto;

        // Create a new friend object
        Friend friend = Friend(
          name: submittedName,
          nickname: submittedNickname,
          age: submittedAge,
          isSingle: submittedIsSingle,
          happinessLevel: submittedHappinessLevel,
          vision: submittedDropdownValue,
          motto: submittedMotto,
          isVerified: isVerified,
        );

        // Add friend to firebase
        context.read<FriendListProvider>().addFriend(friend);

        // Return true to showcase summary
        result = true;
      });
    } else {
      setState(() {
        result = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DrawerWidget(),
      appBar: AppBar(
        title: const Text("Traveler Records"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // ===== Heading 1: Welcome to Traveler Records =====
                Column(
                  children: [
                    const SizedBox(height: 10),
                    Center(
                        child: Image.asset("assets/icon.png",
                            height: 150, width: 150)),
                    const Center(
                      child: Text(
                        "Welcome to Traveler Records!",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                        child: Text(
                          "Please fill out the form below to add your friend to the Traveler Records.",
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Divider(color: Colors.blue),
                  ],
                ),

                // ===== Column 2: Form Fields (Name, Nickname, Age, Civil Status) =====
                Column(
                  children: [
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Name",
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      inputFormatters: [
                        NameFormat()
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your name";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: nicknameController,
                      decoration: const InputDecoration(
                        labelText: "Nickname",
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      inputFormatters: [
                        NameFormat()
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your nickname";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: ageController,
                            decoration: const InputDecoration(
                              labelText: "Age",
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter your age";
                              }
                              if (int.tryParse(value) == null) {
                                return "Please enter a number";
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Row(
                          children: [
                            const Text("Are you single?"),
                            const SizedBox(width: 10),
                            Switch(
                              focusColor: Colors.white,
                              activeColor: Colors.blue,
                              value: isSingle,
                              onChanged: (value) {
                                setState(() {
                                  isSingle = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // ===== Column 3: Happiness Level (0 to 10) =====
                Column(
                  children: <Widget>[
                    const Divider(color: Colors.blue),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sentiment_very_dissatisfied_rounded,
                          size: 40,
                          color: Colors.amber[700],
                        ),
                        Icon(
                          Icons.linear_scale_rounded,
                          size: 40,
                          color: Colors.amber[700],
                        ),
                        Icon(
                          Icons.sentiment_very_satisfied_rounded,
                          size: 40,
                          color: Colors.amber[700],
                        ),
                      ],
                    ),
                    const Center(
                      child: Text(
                        "Happiness Level",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                        child: Text(
                          "On a scale of 0 (Unhappy) to 10 (Very Happy). How would you rate your current lifestyle?",
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Slider(
                        value: happinessLevel,
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: happinessLevel.round().toString(),
                        onChanged: (double value) {
                          setState(() {
                            happinessLevel = value;
                          });
                        }),
                    const SizedBox(height: 7),
                    const Divider(color: Colors.blue),
                  ],
                ),
                const SizedBox(height: 10),
                // ===== Column 4: Vision (Dropdown Selection) =====
                Column(
                  children: <Widget>[
                    Center(
                        child: Icon(
                      Icons.star_rounded,
                      size: 40,
                      color: Colors.amber[700],
                    )),
                    const Center(
                      child: Text(
                        "Vision",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                        child: Text(
                          "If you were a Genshin Impact character, which Vision would you have?",
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: SizedBox(
                        height: 60,
                        width: 150,
                        child: DropdownButtonFormField(
                        decoration: const InputDecoration(
                          labelText: "Options",
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        value: dropdownValue,
                        items: dropdownOptions.map((item) {
                          return DropdownMenuItem(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: (newItem) {
                          setState(() {
                            dropdownValue = newItem!;
                          });
                        }
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.blue),
                    const SizedBox(height: 10),
                  ],
                ),
                
                // ===== Column 5: Motto (Radio Selection) =====
                Column(
                  children: <Widget>[
                    Center(
                      child: Icon(Icons.military_tech_rounded, size: 40, color: Colors.amber[700])
                    ),
                    const Center(
                      child: Text(
                        "Motto",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Column(
                      children: <Widget>[
                        RadioListTile(
                          title: const Text("The limit to one's power is self-destruction.", textAlign: TextAlign.justify),
                          value: "The limit to one's power is self-destruction.", // Xiao - Anemo
                          groupValue: selectedMotto,
                          onChanged: (value) {
                            setState(() {
                              selectedMotto = "$value";
                            });
                          },
                          contentPadding: const EdgeInsets.only(left: 10, right: 30),
                        ),
                        RadioListTile(
                          title: const Text("A blade is like a tea-leaf. Only those who sample it many times can appreciate its true qualities.", textAlign: TextAlign.justify),
                          value: "A blade is like a tea-leaf. Only those who sample it many times can appreciate its true qualities.", // Ayaka - Cryo
                          groupValue: selectedMotto,
                          onChanged: (value) {
                            setState(() {
                              selectedMotto = "$value";
                            });
                          },
                          contentPadding: const EdgeInsets.only(left: 10, right: 30),
                        ),
                        RadioListTile(
                          title: const Text("You have to see the world for yourself to appreciate how beautiful it is.", textAlign: TextAlign.justify),
                          value: "You have to see the world for yourself to appreciate how beautiful it is.", // Nahida - Dendro
                          groupValue: selectedMotto,
                          onChanged: (value) {
                            setState(() {
                              selectedMotto = "$value";
                            });
                          },
                          contentPadding: const EdgeInsets.only(left: 10, right: 30),
                        ),
                        RadioListTile(
                          title: const Text("The past cannot be changed, and the future cannot be foretold.", textAlign: TextAlign.justify),
                          value: "The past cannot be changed, and the future cannot be foretold.", // Cyno - Electro
                          groupValue: selectedMotto,
                          onChanged: (value) {
                            setState(() {
                              selectedMotto = "$value";
                            });
                          },
                          contentPadding: const EdgeInsets.only(left: 10, right: 30),
                        ),
                        RadioListTile(
                          title: const Text("Every journey has its final day, don't rush.", textAlign: TextAlign.justify),
                          value: "Every journey has its final day, don't rush.", // Zhongli - Geo
                          groupValue: selectedMotto,
                          onChanged: (value) {
                            setState(() {
                              selectedMotto = "$value";
                            });
                          },
                          contentPadding: const EdgeInsets.only(left: 10, right: 30),
                        ),
                        RadioListTile(
                          title: const Text("Pace yourself before you erase yourself.", textAlign: TextAlign.justify),
                          value: "Pace yourself before you erase yourself.", // Ayato - Hydro
                          groupValue: selectedMotto,
                          onChanged: (value) {
                            setState(() {
                              selectedMotto = "$value";
                            });
                          },
                          contentPadding: const EdgeInsets.only(left: 10, right: 30),
                        ),
                        RadioListTile(
                          title: const Text("Only once you know and respect death can you truly understand the value of life.", textAlign: TextAlign.justify),
                          value: "Only once you know and respect death can you truly understand the value of life.", // Hu Tao - Pyro
                          groupValue: selectedMotto,
                          onChanged: (value) {
                            setState(() {
                              selectedMotto = "$value";
                            });
                          },
                          contentPadding: const EdgeInsets.only(left: 10, right: 30),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // ===== Row 1: Reset and Submit Buttons =====
                Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: resetForm,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Reset"),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: submitForm,
                        icon: const Icon(Icons.send),
                        label: const Text("Submit"),
                      ),
                    ),
                  ),
                ],
              ),
              
              // ===== Conditional Rendering of Summary Upon Submission =====
              if (result) ...[
                const SizedBox(height: 20),
                Divider(color: Colors.green[800]),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Icon(Icons.book_rounded, size: 40, color: Colors.amber[700])),
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
                            Text(submittedName),
                          ],
                        ),
                        TableRow(
                          children: [
                            const Text("Nickname", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(submittedNickname),
                          ],
                        ),
                        TableRow(
                          children: [
                            const Text("Age", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(submittedAge),
                          ],
                        ),
                        TableRow(
                          children: [
                            const Text("Relationship", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(submittedIsSingle ? "Single" : "Taken"),
                          ],
                        ),
                        TableRow(
                          children: [
                            const Text("Happiness", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("$submittedHappinessLevel"),
                          ],
                        ),
                        TableRow(
                          children: [
                            const Text("Vision", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(submittedDropdownValue),
                          ],
                        ),
                        TableRow(
                          children: [
                            const Text("Motto", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(submittedMotto, textAlign: TextAlign.justify),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                    ],
                  ),
                ),
              ],
              ],
            ),
          ),
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
}
