// services/UserService.dart (RentCar)
import 'package:hive/hive.dart';
import '../models/User.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'HiveService.dart';

class UserService {
  static const String _loggedInUserKey = 'logged_in_user';
   
  // Cache untuk current user (untuk akses synchronous)
  static String? _currentUsername;  
  static User? _currentUser;

  // **PERBAIKAN: Helper method untuk check essential boxes**
  static bool _areEssentialBoxesOpen() {
    try {
      return Hive.isBoxOpen('users') && 
             Hive.isBoxOpen('user_objects') && 
             Hive.isBoxOpen('bookings');
    } catch (e) {
      print('❌ Error checking boxes: $e');
      return false;
    }
  }

  // Initialize current user dari SharedPreferences
  static Future<void> initCurrentUser() async {
    try {
      print('🚀 Initializing UserService...');
      
      // **PERBAIKAN: Pastikan HiveService sudah terinisialisasi**
      if (!_areEssentialBoxesOpen()) {
        print('📦 Essential boxes not open, initializing HiveService...');
        await HiveService.init();
      }

      final prefs = await SharedPreferences.getInstance();
      _currentUsername = prefs.getString(_loggedInUserKey);
      
      if (_currentUsername != null) {
        print('👤 Found saved username: $_currentUsername');
        
        // Load user dari Hive
        _currentUser = await HiveService.getUser(_currentUsername!);
        if (_currentUser != null) {
          print('✅ User loaded from Hive: ${_currentUser!.username}');
        } else {
          print('⚠️ User not found in Hive, creating new user object');
          // Jika user tidak ada di Hive, buat user baru
          _currentUser = User(
            username: _currentUsername!,
            nama: '',
            email: '',
            phone: '',
            alamat: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await HiveService.saveUser(_currentUser!);
        }
      } else {
        print('ℹ️ No saved username found');
        _currentUser = null;
      }
    } catch (e) {
      print('❌ Error initializing current user: $e');
      _currentUsername = null;
      _currentUser = null;
    }
  }

  // Get users box menggunakan HiveService
  static Future<Box<User>> getUserBox() async {
    return await HiveService.getUserBox();
  }

  // Get current logged in user (synchronous)
  static User? getCurrentUser() {
    try {
      if (_currentUser != null) {
        return _currentUser;
      }

      if (_currentUsername == null) return null;
      
      if (!_areEssentialBoxesOpen()) {
        print('⚠️ Warning: Essential boxes not open yet');
        return null;
      }
      
      final box = HiveService.getUserBoxSync();
      _currentUser = box.get(_currentUsername);
      return _currentUser;
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }

  // Async version of getCurrentUser
  static Future<User?> getCurrentUserAsync() async {
    try {
      if (_currentUser != null) {
        return _currentUser;
      }

      if (_currentUsername == null) return null;
      
      final box = await HiveService.getUserBox();
      _currentUser = box.get(_currentUsername);
      return _currentUser;
    } catch (e) {
      print('❌ Error getting current user async: $e');
      return null;
    }
  }

  // Set current logged in user
  static Future<void> setCurrentUser(User user) async {
    try {
      print('🔐 Setting current user: ${user.username}');
      
      // **PERBAIKAN: Pastikan HiveService terinisialisasi**
      if (!_areEssentialBoxesOpen()) {
        await HiveService.init();
      }

      // Gunakan HiveService untuk menyimpan user
      await HiveService.saveUser(user);
      
      // Simpan info user yang sedang login di SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_loggedInUserKey, user.username);
      
      // Update cache
      _currentUsername = user.username;
      _currentUser = user;
      
      print('✅ Current user set successfully: ${user.username}');
    } catch (e) {
      print('❌ Error setting current user: $e');
      rethrow;
    }
  }

  // Clear current logged in user (logout)
  static Future<void> clearCurrentUser() async {
    try {
      print('🚪 Clearing current user...');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_loggedInUserKey);
      
      // Clear cache
      _currentUsername = null;
      _currentUser = null;
      
      print('✅ Current user cleared successfully');
    } catch (e) {
      print('❌ Error clearing current user: $e');
    }
  }

  // Check if user is logged in
  static bool isUserLoggedIn() {
    try {
      if (_currentUsername == null) return false;
      if (!_areEssentialBoxesOpen()) return false;
      
      // Check if user exists in Hive
      final userExists = HiveService.getUserBoxSync().containsKey(_currentUsername);
      
      // Check if password exists (untuk validasi ekstra)
      final passwordExists = HiveService.passwordExists(_currentUsername!);
      
      final isLoggedIn = userExists && passwordExists;
      print('🔍 User login check: username=$_currentUsername, userExists=$userExists, passwordExists=$passwordExists, result=$isLoggedIn');
      
      return isLoggedIn;
    } catch (e) {
      print('❌ Error checking if user is logged in: $e');
      return false;
    }
  }

  // Get current user username (untuk FavoriteService)
  static String? getCurrentUsername() {
    return _currentUsername;
  }

  // **BARU: Get current user ID untuk booking system**
  static String? getCurrentUserId() {
    return _currentUsername; // Username sebagai user ID
  }

  // Register new user
  static Future<bool> registerUser(User user) async {
    try {
      print('📝 Registering user: ${user.username}');
      
      final box = await getUserBox();
      
      // Check if username already exists
      if (box.containsKey(user.username)) {
        print('❌ Username already exists: ${user.username}');
        return false;
      }
      
      // Check if password username already exists
      if (HiveService.passwordExists(user.username)) {
        print('❌ Password username already exists: ${user.username}');
        return false;
      }
      
      // Set timestamps
      user.createdAt = DateTime.now();
      user.updatedAt = DateTime.now();
      
      // Save user menggunakan HiveService
      await HiveService.saveUser(user);
      print('✅ User registered successfully: ${user.username}');
      return true;
    } catch (e) {
      print('❌ Error registering user: $e');
      return false;
    }
  }

  // Login user dengan validasi lengkap
  static Future<User?> loginUser(String username, String password) async {
    try {
      print('🔐 Attempting login: $username');
      
      // **PERBAIKAN: Pastikan HiveService terinisialisasi**
      if (!_areEssentialBoxesOpen()) {
        await HiveService.init();
      }

      // Cek password dari box password (existing system) menggunakan HiveService
      if (!HiveService.passwordExists(username)) {
        print('❌ Username not found in password box: $username');
        return null;
      }
      
      String? storedPassword = HiveService.getPassword(username);
      if (storedPassword == null || password != storedPassword) {
        print('❌ Password mismatch for user: $username');
        return null;
      }

      print('✅ Password validated for user: $username');

      // Ambil atau buat User object menggunakan HiveService
      User? user = await HiveService.getUser(username);
      
      if (user == null) {
        print('📝 Creating new User object for: $username');
        // Buat User object baru jika belum ada
        user = User(
          username: username,
          nama: '',
          email: '',
          phone: '',
          alamat: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await HiveService.saveUser(user);
      }
      
      // Set sebagai current user
      await setCurrentUser(user);
      print('✅ Login successful for user: $username');
      return user;
    } catch (e) {
      print('❌ Error during login: $e');
      return null;
    }
  }

  // Update user profile
  static Future<bool> updateUser(User updatedUser) async {
    try {
      print('📝 Updating user: ${updatedUser.username}');
      
      // Update timestamp
      updatedUser.updatedAt = DateTime.now();
      
      // Update menggunakan HiveService
      await HiveService.updateUser(updatedUser);
      
      // Update current user if it's the same user
      if (_currentUsername == updatedUser.username) {
        _currentUser = updatedUser;
        await setCurrentUser(updatedUser);
      }
      
      print('✅ User updated successfully: ${updatedUser.username}');
      return true;
    } catch (e) {
      print('❌ Error updating user: $e');
      return false;
    }
  }

  // Get all users (untuk admin/debugging)
  static Future<List<User>> getAllUsers() async {
    try {
      return await HiveService.getAllUsers();
    } catch (e) {
      print('❌ Error getting all users: $e');
      return [];
    }
  }

  // Delete user
  static Future<bool> deleteUser(String username) async {
    try {
      print('🗑️ Deleting user: $username');
      
      // If deleting current user, logout first
      if (_currentUsername == username) {
        await clearCurrentUser();
      }
      
      // Delete menggunakan HiveService (akan menghapus user dan related data)
      await HiveService.deleteUser(username);
      
      // Delete password juga
      final passwordBox = HiveService.getPasswordBox();
      await passwordBox.delete(username);
      
      print('✅ User deleted successfully: $username');
      return true;
    } catch (e) {
      print('❌ Error deleting user: $e');
      return false;
    }
  }

  // Check if username exists
  static Future<bool> usernameExists(String username) async {
    try {
      final box = await getUserBox();
      final userExists = box.containsKey(username);
      final passwordExists = HiveService.passwordExists(username);
      
      // Username exists jika ada di salah satu box
      return userExists || passwordExists;
    } catch (e) {
      print('❌ Error checking username: $e');
      return false;
    }
  }

  // Get user profile data
  static Future<User?> getUserProfile(String username) async {
    try {
      return await HiveService.getUser(username);
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }

  // Get current user profile
  static Future<User?> getCurrentUserProfile() async {
    if (_currentUsername == null) return null;
    return await getUserProfile(_currentUsername!);
  }

  // Validate current session
  static Future<bool> validateCurrentSession() async {
    try {
      if (_currentUsername == null) {
        print('ℹ️ No current username in cache');
        return false;
      }

      // Check if user still exists in both boxes
      final userExists = await HiveService.getUser(_currentUsername!) != null;
      final passwordExists = HiveService.passwordExists(_currentUsername!);
      
      if (!userExists || !passwordExists) {
        print('⚠️ Session invalid: user or password missing');
        await clearCurrentUser();
        return false;
      }

      print('✅ Session valid for user: $_currentUsername');
      return true;
    } catch (e) {
      print('❌ Error validating session: $e');
      await clearCurrentUser();
      return false;
    }
  }

  // Refresh current user data
  static Future<void> refreshCurrentUser() async {
    try {
      if (_currentUsername == null) return;
      
      _currentUser = await HiveService.getUser(_currentUsername!);
      print('🔄 Current user refreshed: $_currentUsername');
    } catch (e) {
      print('❌ Error refreshing current user: $e');
    }
  }

  // **BARU: Method untuk validasi akses booking**
  static bool canAccessBooking(String bookingUserId) {
    return _currentUsername == bookingUserId;
  }

  // **BARU: Method untuk get safe current user ID**
  static Future<String?> getCurrentUserIdSafe() async {
    await initCurrentUser();
    return getCurrentUserId();
  }

  // Debug methods
  static Future<void> printUserDebug() async {
    try {
      print('🔍 === USER SERVICE DEBUG ===');
      print('Current username: $_currentUsername');
      print('Current user cached: ${_currentUser?.username}');
      print('Is logged in: ${isUserLoggedIn()}');
      
      if (_currentUsername != null) {
        final userInHive = await HiveService.getUser(_currentUsername!);
        final passwordExists = HiveService.passwordExists(_currentUsername!);
        print('User in Hive: ${userInHive?.username}');
        print('Password exists: $passwordExists');
      }
      
      final allUsers = await HiveService.getAllUsers();
      print('Total users in Hive: ${allUsers.length}');
      for (var user in allUsers) {
        print('  - ${user.username} (${user.nama})');
      }
      print('==============================');
    } catch (e) {
      print('❌ Error in user debug: $e');
    }
  }

  // Get user statistics
  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      final allUsers = await HiveService.getAllUsers();
      final passwordBox = HiveService.getPasswordBox();
      
      return {
        'totalUsers': allUsers.length,
        'totalPasswords': passwordBox.length,
        'currentUser': _currentUsername,
        'isLoggedIn': isUserLoggedIn(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error getting user stats: $e');
      return {};
    }
  }
}