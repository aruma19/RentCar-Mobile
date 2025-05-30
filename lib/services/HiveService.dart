import 'package:hive_flutter/hive_flutter.dart';
import '../models/User.dart';

class HiveService {
  static const String _userBoxName = 'users';
  static const String _favoritesBoxPrefix = 'favorites_';
  static const String _userDataBoxPrefix = 'user_data_';

  // Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserAdapter());
    }
  }

  // User Box Operations
  static Future<Box<User>> getUserBox() async {
    return await Hive.openBox<User>(_userBoxName);
  }

  static Future<Box> getFavoritesBox(String username) async {
    return await Hive.openBox('$_favoritesBoxPrefix$username');
  }

  static Future<Box> getUserDataBox(String username) async {
    return await Hive.openBox('$_userDataBoxPrefix$username');
  }

  // User CRUD Operations
  static Future<void> saveUser(User user) async {
    final box = await getUserBox();
    await box.put(user.username, user);
  }

  static Future<User?> getUser(String username) async {
    final box = await getUserBox();
    return box.get(username);
  }

  static Future<void> updateUser(User user) async {
    user.updatedAt = DateTime.now();
    await saveUser(user);
  }

  static Future<void> deleteUser(String username) async {
    final box = await getUserBox();
    await box.delete(username);
    
    // Also delete related boxes
    try {
      final favBox = await getFavoritesBox(username);
      await favBox.clear();
      await favBox.close();
      
      final userDataBox = await getUserDataBox(username);
      await userDataBox.clear();
      await userDataBox.close();
    } catch (e) {
      print('Error deleting related boxes: $e');
    }
  }

  static Future<List<User>> getAllUsers() async {
    final box = await getUserBox();
    return box.values.toList();
  }

  // Favorites Operations
  static Future<void> addToFavorites(String username, String carId, Map<String, dynamic> carData) async {
    final box = await getFavoritesBox(username);
    await box.put(carId, carData);
  }

  static Future<void> removeFromFavorites(String username, String carId) async {
    final box = await getFavoritesBox(username);
    await box.delete(carId);
  }

  static Future<bool> isFavorite(String username, String carId) async {
    final box = await getFavoritesBox(username);
    return box.containsKey(carId);
  }

  static Future<List<Map<String, dynamic>>> getFavorites(String username) async {
    final box = await getFavoritesBox(username);
    return box.values.cast<Map<String, dynamic>>().toList();
  }

  // User Data Operations (for profile information)
  static Future<void> saveUserData(String username, Map<String, dynamic> userData) async {
    final box = await getUserDataBox(username);
    for (var entry in userData.entries) {
      await box.put(entry.key, entry.value);
    }
    await box.put('updated_at', DateTime.now().toIso8601String());
  }

  static Future<Map<String, dynamic>> getUserData(String username) async {
    final box = await getUserDataBox(username);
    Map<String, dynamic> userData = {};
    
    for (var key in box.keys) {
      userData[key.toString()] = box.get(key);
    }
    
    return userData;
  }

  static Future<void> clearUserData(String username) async {
    final box = await getUserDataBox(username);
    await box.clear();
  }

  // Cleanup Operations
  static Future<void> closeAllBoxes() async {
    await Hive.close();
  }

  static Future<void> clearAll() async {
    await Hive.deleteFromDisk();
  }

  // Utility Methods
  static Future<bool> isBoxOpen(String boxName) async {
    return Hive.isBoxOpen(boxName);
  }

  static Future<void> compactBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      final box = Hive.box(boxName);
      await box.compact();
    }
  }

  // Debug Methods
  static Future<void> printAllBoxes() async {
    print('=== HIVE BOXES DEBUG ===');
    
    // Print user box
    try {
      final userBox = await getUserBox();
      print('User Box: ${userBox.length} entries');
      for (var key in userBox.keys) {
        print('  $key: ${userBox.get(key)}');
      }
    } catch (e) {
      print('Error reading user box: $e');
    }
    
    print('========================');
  }
}