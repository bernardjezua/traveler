/***********************************************************
* Traveler is a mobile slambook application inspired by Genshin Impact that allows users to add, update, and
* delete their friends through a slambook form or a QR code. The slambook form contains Visions (Anemo,
* Cryo, Dendro, etc.) and Mottos that are quotes from various Genshin Impact characters!
*
* Users can also add profile pictures of their accounts and friends. They can verify their friends by 
* scanning a QR code containing their information, preventing any unauthorized modifications to the friend's
* details. However, the profile picture can still be edited regardless of the friend's status.
*
* @author bernardjezua
* @created_date 2023-07-18 02:25
* DO NOT COPY OR USE THE CODE FOR OTHER PURPOSES.
***********************************************************/

import 'package:google_fonts/google_fonts.dart' as gf;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:traveler/providers/auth_provider.dart';
import 'package:traveler/providers/friends_provider.dart';
import 'package:traveler/providers/user_provider.dart';
import 'package:traveler/screens/MainPage/dashboard_page.dart';
import 'package:traveler/screens/MainPage/details_page.dart';
import 'package:traveler/screens/MainPage/friends_page.dart';
import 'package:traveler/screens/SignInPage/home_page.dart';
import 'package:traveler/screens/MainPage/profile_page.dart';
import 'package:traveler/screens/MainPage/scan_qr_page.dart';
import 'package:traveler/screens/SlambookPage/add_profile_info.dart';
import 'package:traveler/screens/SlambookPage/edit_profile_info.dart';
import 'package:traveler/screens/SlambookPage/slambook_page.dart';
import 'package:traveler/screens/SlambookPage/edit_page.dart';
import 'package:traveler/screens/SignInPage/signin_page.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: ((context) => UserAuthProvider())),
        ChangeNotifierProvider(create: ((context) => FriendListProvider())),
        ChangeNotifierProvider(create: ((context) => UserProfileProvider())),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        // Light blue colored theme
        primaryColor: const Color(0xFF0642BA),
        scaffoldBackgroundColor: const Color(0xFFFDFDFD),
        fontFamily: 'SF Pro Text',
        appBarTheme: AppBarTheme(
          color: const Color(0xFF0642BA),
          titleTextStyle: gf.GoogleFonts.montserrat(
            textStyle: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        // Changes the border themes of input fields
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.purple),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        "/": (context) => const HomePage(),
        "/login": (context) => const SignInPage(),
        "/dashboard": (context) => const DashboardPage(),
        "/friends": (context) => const FriendsPage(),
        "/slambook": (context) => const SlamBookForm(),
        "/details": (context) => const FriendSummary(),
        "/edit": (context) => const EditFriend(),
        "/profile": (context) => const ProfilePage(),
        "/addInfo": (context) => const AddProfileInfo(),
        "/editInfo": (context) => const EditProfileInfo(),
        "/scanQR": (context) => const ScanQrPage(),
      },
    );
  }
}