// service/FavoriteService.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/Car.dart';
import 'dart:convert';

class FavoriteService {
  static const String _favoriteKey = 'favorite_cars';

  // Get favorite car IDs
  static Future<Set<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteList = prefs.getStringList(_favoriteKey) ?? [];
    return favoriteList.toSet();
  }

  // Get favorite car details by fetching from API
  static Future<List<Car>> getFavoriteCars() async {
    try {
      final favoriteIds = await getFavoriteIds();
      if (favoriteIds.isEmpty) return [];

      List<Car> favoriteCars = [];
      
      for (String carId in favoriteIds) {
        try {
          final response = await http.get(Uri.parse(
              'https://6839447d6561b8d882af9534.mockapi.io/api/sewa_mobil/mobil/$carId'));
          
          if (response.statusCode == 200) {
            final carData = json.decode(response.body);
            favoriteCars.add(Car.fromJson(carData));
          }
        } catch (e) {
          print('Error fetching car $carId: $e');
          // Continue with other cars even if one fails
        }
      }
      
      return favoriteCars;
    } catch (e) {
      print('Error getting favorite cars: $e');
      return [];
    }
  }

  // Add car to favorites
  static Future<bool> addToFavorites(Car car) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = await getFavoriteIds();
      
      // Check if already in favorites
      if (favoriteIds.contains(car.id)) {
        return false; // Already in favorites
      }
      
      // Add to favorites
      favoriteIds.add(car.id);
      
      // Save updated favorites
      await prefs.setStringList(_favoriteKey, favoriteIds.toList());
      return true;
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }

  // Remove car from favorites
  static Future<bool> removeFromFavorites(String carId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = await getFavoriteIds();
      
      // Check if in favorites
      if (!favoriteIds.contains(carId)) {
        return false; // Not in favorites
      }
      
      // Remove from favorites
      favoriteIds.remove(carId);
      
      // Save updated favorites
      await prefs.setStringList(_favoriteKey, favoriteIds.toList());
      return true;
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }

  // Toggle favorite status
  static Future<bool> toggleFavorite(Car car) async {
    final favoriteIds = await getFavoriteIds();
    
    if (favoriteIds.contains(car.id)) {
      return await removeFromFavorites(car.id);
    } else {
      return await addToFavorites(car);
    }
  }

  // Check if car is favorite
  static Future<bool> isFavorite(String carId) async {
    final favoriteIds = await getFavoriteIds();
    return favoriteIds.contains(carId);
  }

  // Clear all favorites
  static Future<void> clearAllFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoriteKey);
  }

  // Get favorite count
  static Future<int> getFavoriteCount() async {
    final favoriteIds = await getFavoriteIds();
    return favoriteIds.length;
  }

  // Search in favorites
  static Future<List<Car>> searchFavorites(String query) async {
    final favoriteCars = await getFavoriteCars();
    
    if (query.isEmpty) return favoriteCars;
    
    final searchLower = query.toLowerCase();
    return favoriteCars.where((car) {
      return car.nama.toLowerCase().contains(searchLower) ||
             car.merk.toLowerCase().contains(searchLower) ||
             car.deskripsi.toLowerCase().contains(searchLower);
    }).toList();
  }

  // Export favorites (for backup)
  static Future<Map<String, dynamic>> exportFavorites() async {
    final favoriteIds = await getFavoriteIds();
    
    return {
      'favoriteIds': favoriteIds.toList(),
      'exportDate': DateTime.now().toIso8601String(),
      'count': favoriteIds.length,
    };
  }

  // Import favorites (for restore)
  static Future<bool> importFavorites(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = List<String>.from(data['favoriteIds'] ?? []);
      
      // Save to preferences
      await prefs.setStringList(_favoriteKey, favoriteIds);
      return true;
    } catch (e) {
      print('Error importing favorites: $e');
      return false;
    }
  }
}