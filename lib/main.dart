import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_133_165/pages/WelcomePage.dart';
import 'package:project_133_165/pages/Dashboard.dart'; // Import dashboard page Anda
import 'package:project_133_165/models/User.dart';
import 'package:project_133_165/models/book.dart'; 
import './services/UserService.dart';

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
  
  // Initialize UserService
  await UserService.initCurrentUser();
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SplashScreen(), // Ganti ke SplashScreen
      debugShowCheckedModeBanner: false,
    );
  }
}

// Buat SplashScreen untuk cek status login
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      // Tambahkan delay kecil untuk splash effect (opsional)
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Cek apakah user sudah login
      bool isLoggedIn = UserService.isUserLoggedIn();
      
      if (isLoggedIn) {
        // Validasi session untuk memastikan data masih valid
        bool sessionValid = await UserService.validateCurrentSession();
        
        if (sessionValid) {
          print('✅ User is logged in, redirecting to dashboard');
          // User sudah login dan session valid, langsung ke dashboard
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Dashboard()), // Ganti dengan nama dashboard page Anda
            );
          }
        } else {
          print('⚠️ Session invalid, redirecting to welcome page');
          // Session tidak valid, ke welcome page
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WelcomePage()),
            );
          }
        }
      } else {
        print('ℹ️ User not logged in, redirecting to welcome page');
        // User belum login, ke welcome page
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WelcomePage()),
          );
        }
      }
    } catch (e) {
      print('❌ Error checking login status: $e');
      // Jika ada error, default ke welcome page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomePage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo atau icon aplikasi Anda
            Icon(
              Icons.book,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}