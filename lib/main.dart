import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'authentication/screen/auth_screen.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import '_core/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Projeto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: MyColors.brown,
        appBarTheme: AppBarTheme(
          toolbarHeight: 60,
          centerTitle: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusDirectional.vertical(
              bottom: Radius.circular(32),
            ),
          ),
          backgroundColor: MyColors.brown,
        ),
        scaffoldBackgroundColor: MyColors.green,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: MyColors.brown,
        ),
        listTileTheme: ListTileThemeData(
          iconColor: Colors.white,
        ),
      ),
      home: AlterarTelas(),
    );
  }
}

class AlterarTelas extends StatelessWidget {
  const AlterarTelas({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(stream: FirebaseAuth.instance.userChanges(), builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      } else {
        if (snapshot.hasData) {
          return HomeScreen();
        } else {
          return AuthScreen();
        }
      }
    },);
  }
}

