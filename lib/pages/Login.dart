import 'package:flutter/material.dart';
import 'Dashboard.dart';
import 'Register.dart';
import 'package:hive/hive.dart';
import '../services/HiveService.dart';
import '../services/UserService.dart';
import '../services/FavoriteService.dart';
import '../models/User.dart';
import 'WelcomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  late SharedPreferences logindata;
  late bool newuser;
  bool _isObscure = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    checkIfAlreadyLogin();
  }

  /// **PERBAIKAN: Check existing login dengan UserService yang sudah diperbaiki**
  void checkIfAlreadyLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      logindata = await SharedPreferences.getInstance();
      newuser = (logindata.getBool('login') ?? true);
      
      if (!newuser) {
        // User sudah login, cek apakah data masih valid
        String? savedUsername = logindata.getString('username');
        if (savedUsername != null && savedUsername.isNotEmpty) {
          print('🔍 Checking existing login for: $savedUsername');
          
          try {
            // Pastikan HiveService terinisialisasi
            await HiveService.init();
            print('✅ HiveService initialized');
            
            // Cek apakah user masih ada di Hive
            if (HiveService.passwordExists(savedUsername)) {
              print('✅ User password exists in Hive');
              
              // Initialize UserService dengan user yang ada
              await UserService.initCurrentUser();
              final currentUser = UserService.getCurrentUser();
              
              if (currentUser != null) {
                print('✅ UserService initialized with user: ${currentUser.username}');
                
                // Initialize favorites untuk user
                await FavoriteService.initializeFavoritesForUser(savedUsername);
                print('✅ Favorites initialized');
                
                // Navigate to dashboard
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Dashboard()),
                  );
                }
                return;
              } else {
                print('⚠️ UserService could not initialize user');
              }
            } else {
              print('⚠️ User password not found in Hive');
            }
          } catch (e) {
            print('❌ Error checking existing login: $e');
          }
          
          // Clear invalid login data
          print('🧹 Clearing invalid login data');
          await logindata.clear();
        }
      }
    } catch (e) {
      print('❌ Error in checkIfAlreadyLogin: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// **PERBAIKAN: Login method dengan UserService yang sudah diperbaiki**
  void login() async {
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Username dan password tidak boleh kosong"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔐 Attempting login for user: $username');
      
      // **PERBAIKAN: Gunakan UserService.loginUser yang sudah ada business logic**
      final user = await UserService.loginUser(username, password);
      
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Username atau password salah"),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      print('✅ Login successful for user: ${user.username}');
      
      // **Login berhasil! UserService.loginUser sudah handle semua setup**
      
      // Set SharedPreferences (untuk auto-login check)
      logindata = await SharedPreferences.getInstance();
      await logindata.setBool('login', false);
      await logindata.setString('username', username);
      print('✅ SharedPreferences updated');

      // Initialize favorites untuk user ini (PENTING!)
      await FavoriteService.initializeFavoritesForUser(user.username);
      print('✅ Favorites initialized for user');

      // Debug: Print current user status
      await UserService.printUserDebug();
      await FavoriteService.printFavoritesDebug();

      setState(() {
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text("Login berhasil!"),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Navigate to Dashboard setelah delay singkat
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
      }
        
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Login error: $e');
      if (mounted) {
        String errorMessage = 'Terjadi kesalahan saat login';
        
        // Handle specific error messages
        if (e.toString().contains('Username tidak ditemukan')) {
          errorMessage = 'Username tidak ditemukan';
        } else if (e.toString().contains('Password mismatch')) {
          errorMessage = 'Password salah';
        } else if (e.toString().contains('HiveService')) {
          errorMessage = 'Terjadi kesalahan sistem, coba lagi';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _isLoading ? null : () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WelcomePage()),
            );
          },
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF2C5364)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  "Selamat Datang",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Masuk ke akun Anda",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 40),
                
                // **Show loading state jika sedang check existing login**
                if (_isLoading && usernameController.text.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Memeriksa status login...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Login form
                  TextField(
                    controller: usernameController,
                    style: const TextStyle(color: Colors.white),
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person, color: Colors.white),
                      hintText: 'Username',
                      hintStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white24,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: passwordController,
                    obscureText: _isObscure,
                    style: const TextStyle(color: Colors.white),
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock, color: Colors.white),
                      hintText: 'Password',
                      hintStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white24,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isObscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white,
                        ),
                        onPressed: _isLoading ? null : () {
                          setState(() {
                            _isObscure = !_isObscure;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _isLoading ? Colors.grey : Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: _isLoading ? 0 : 4,
                      ),
                      child: _isLoading 
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                "Logging in...",
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ],
                          )
                        : const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 16, 
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
                    child: Text(
                      "Belum punya akun? Daftar di sini",
                      style: TextStyle(
                        color: _isLoading ? Colors.white38 : Colors.white70,
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                // **Debug info (bisa dihapus di production)**
                if (_isLoading) 
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Sistem sedang menginisialisasi...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}