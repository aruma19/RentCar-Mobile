import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_133_165/pages/WelcomePage.dart';
import 'package:project_133_165/models/User.dart';
import 'package:project_133_165/models/book.dart'; 
import './services/UserService.dart';// Gunakan nama file huruf kecil
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register Adapter untuk User dan Book
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(UserAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(BookAdapter());
  }

  await Hive.openBox('users');
  await Hive.openBox('favorites');
  await Hive.openBox<Book>('bookings');
  await UserService.initCurrentUser();
  runApp(const MainApp());
}


class MainApp extends StatelessWidget {
  const MainApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const WelcomePage(),
      debugShowCheckedModeBanner: false,

    );
  }
}