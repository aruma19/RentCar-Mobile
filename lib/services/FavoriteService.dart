// service/FavoriteService.dart (RentCar)
import '../services/HiveService.dart';
import '../services/UserService.dart';
import '../models/Car.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FavoriteService {
  // Get current user ID dari UserService
  static String? getCurrentUserId() {
    return UserService.getCurrentUsername();
  }

  // Get favorite car IDs for current user dari Hive
  static Future<Set<String>> getFavoriteIds() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User tidak login. Silakan login terlebih dahulu.');
      }

      final favoritesBox = await HiveService.getFavoritesBox(userId);
      final favoriteIds = favoritesBox.keys.cast<String>().toSet();
      print('📱 Loaded ${favoriteIds.length} favorite IDs for user: $userId');
      return favoriteIds;
    } catch (e) {
      print('❌ Error getting favorite IDs: $e');
      return <String>{};
    }
  }

  // Get favorite car details by fetching from API
  static Future<List<Car>> getFavoriteCars() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User tidak login. Silakan login terlebih dahulu.');
      }

      // Get favorites from Hive
      final favorites = await HiveService.getFavorites(userId);
      if (favorites.isEmpty) return [];

      List<Car> favoriteCars = [];
      
      for (var favoriteData in favorites) {
        try {
          // Try to create Car from stored data first
          if (favoriteData.containsKey('id') && 
              favoriteData.containsKey('nama') && 
              favoriteData.containsKey('merk')) {
            favoriteCars.add(Car.fromJson(favoriteData));
          }
        } catch (e) {
          print('❌ Error parsing stored car data: $e');
          // If stored data is corrupted, try to fetch from API
          if (favoriteData.containsKey('id')) {
            try {
              final response = await http.get(Uri.parse(
                  'https://6839447d6561b8d882af9534.mockapi.io/api/sewa_mobil/mobil/${favoriteData['id']}'));
              
              if (response.statusCode == 200) {
                final carData = json.decode(response.body);
                favoriteCars.add(Car.fromJson(carData));
              }
            } catch (apiError) {
              print('❌ Error fetching car from API: $apiError');
            }
          }
        }
      }
      
      print('✅ Successfully loaded ${favoriteCars.length} favorite cars for user: $userId');
      return favoriteCars;
    } catch (e) {
      print('❌ Error getting favorite cars: $e');
      return [];
    }
  }

  // Add car to favorites using Hive
  static Future<bool> addToFavorites(Car car) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User tidak login. Silakan login terlebih dahulu.');
      }

      // Check if already in favorites
      if (await isFavorite(car.id)) {
        print('ℹ️ Car ${car.id} already in favorites for user: $userId');
        return false;
      }

      // Add to Hive favorites
      await HiveService.addToFavorites(userId, car.id, car.toJson());
      print('✅ Added car ${car.id} to favorites for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error adding to favorites: $e');
      return false;
    }
  }

  // Remove car from favorites
  static Future<bool> removeFromFavorites(String carId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User tidak login. Silakan login terlebih dahulu.');
      }

      // Check if in favorites
      if (!await isFavorite(carId)) {
        print('ℹ️ Car $carId not in favorites for user: $userId');
        return false;
      }

      // Remove from Hive favorites
      await HiveService.removeFromFavorites(userId, carId);
      print('✅ Removed car $carId from favorites for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error removing from favorites: $e');
      return false;
    }
  }

  // Toggle favorite status
  static Future<bool> toggleFavorite(Car car) async {
    try {
      final isFav = await isFavorite(car.id);
      
      if (isFav) {
        return await removeFromFavorites(car.id);
      } else {
        return await addToFavorites(car);
      }
    } catch (e) {
      print('❌ Error toggling favorite: $e');
      return false;
    }
  }

  // Check if car is favorite using Hive
  static Future<bool> isFavorite(String carId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return false;

      final result = await HiveService.isFavorite(userId, carId);
      return result;
    } catch (e) {
      print('❌ Error checking favorite status: $e');
      return false;
    }
  }

  // Clear all favorites for current user
  static Future<void> clearAllFavorites() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return;

      final favoritesBox = await HiveService.getFavoritesBox(userId);
      await favoritesBox.clear();
      print('✅ Cleared all favorites for user: $userId');
    } catch (e) {
      print('❌ Error clearing favorites: $e');
    }
  }

  // Get favorite count
  static Future<int> getFavoriteCount() async {
    try {
      final favoriteIds = await getFavoriteIds();
      return favoriteIds.length;
    } catch (e) {
      print('❌ Error getting favorite count: $e');
      return 0;
    }
  }

  // Search in favorites
  static Future<List<Car>> searchFavorites(String query) async {
    try {
      final favoriteCars = await getFavoriteCars();
      
      if (query.isEmpty) return favoriteCars;
      
      final searchLower = query.toLowerCase();
      return favoriteCars.where((car) {
        return car.nama.toLowerCase().contains(searchLower) ||
               car.merk.toLowerCase().contains(searchLower) ||
               car.deskripsi.toLowerCase().contains(searchLower);
      }).toList();
    } catch (e) {
      print('❌ Error searching favorites: $e');
      return [];
    }
  }

  // Export favorites (untuk backup)
  static Future<Map<String, dynamic>> exportFavorites() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User tidak login. Silakan login terlebih dahulu.');
      }

      final favorites = await HiveService.getFavorites(userId);
      final favoriteIds = await getFavoriteIds();
      
      return {
        'userId': userId,
        'favoriteIds': favoriteIds.toList(),
        'favoriteData': favorites,
        'exportDate': DateTime.now().toIso8601String(),
        'count': favoriteIds.length,
      };
    } catch (e) {
      print('❌ Error exporting favorites: $e');
      return {};
    }
  }

  // Import favorites (untuk restore)
  static Future<bool> importFavorites(Map<String, dynamic> data) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User tidak login. Silakan login terlebih dahulu.');
      }

      final favoriteData = data['favoriteData'] as List<Map<String, dynamic>>?;
      if (favoriteData == null) return false;

      // Clear existing favorites
      await clearAllFavorites();

      // Add imported favorites
      for (var carData in favoriteData) {
        if (carData.containsKey('id')) {
          await HiveService.addToFavorites(userId, carData['id'], carData);
        }
      }

      print('✅ Imported ${favoriteData.length} favorites for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error importing favorites: $e');
      return false;
    }
  }

  // Check if user is logged in
  static bool isUserLoggedIn() {
    return UserService.isUserLoggedIn() && getCurrentUserId() != null;
  }

  // Initialize favorites for user (dipanggil saat login)
  static Future<void> initializeFavoritesForUser(String userId) async {
    try {
      // Pastikan favorites box untuk user dibuka
      await HiveService.getFavoritesBox(userId);
      print('✅ Initialized favorites for user: $userId');
    } catch (e) {
      print('❌ Error initializing favorites for user: $e');
    }
  }

  // Get all users who have favorites (untuk admin/debugging)
  static Future<List<String>> getAllUsersWithFavorites() async {
    try {
      // Implementasi tergantung bagaimana Hive menyimpan box names
      // Untuk sekarang, return empty list
      return [];
    } catch (e) {
      print('❌ Error getting users with favorites: $e');
      return [];
    }
  }

  // Debug method
  static Future<void> printFavoritesDebug() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        print('🔍 Debug: No user logged in');
        return;
      }

      print('🔍 Debug Favorites for user: $userId');
      final favoriteIds = await getFavoriteIds();
      print('🔍 Favorite IDs: $favoriteIds');
      
      final favorites = await HiveService.getFavorites(userId);
      print('🔍 Favorite data count: ${favorites.length}');
      
      for (var favorite in favorites) {
        print('🔍 Favorite: ${favorite['id']} - ${favorite['nama']}');
      }
    } catch (e) {
      print('❌ Error in debug favorites: $e');
    }
  }
}