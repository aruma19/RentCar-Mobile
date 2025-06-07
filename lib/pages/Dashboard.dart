import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project_133_165/services/UserService.dart';
import 'bookList.dart';
import 'helpPage.dart';
import 'Favorite.dart';
import 'package:project_133_165/widgets/bottom_nav_bar.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/Car.dart';
import '../services/FavoriteService.dart';
import 'Login.dart';
import 'detailPage.dart';
import 'EditUserPage.dart';
import 'BookPage.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  int _selectedIndex = 2;
  late AnimationController _animationController;

  // **PERBAIKAN: Pages dengan currentUserId support**
  List<Widget> _pages = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  late SharedPreferences logindata;
  String username = "";
  String? currentUserId; // **PERBAIKAN: Add currentUserId**
  TextEditingController _searchController = TextEditingController();
  List<Car> filteredCars = [];
  List<Car> allCars = [];
  bool isSearching = false;
  Set<String> favoriteCars = {};
  bool _isLoadingFavorites = false;
  bool _isLoadingCars = true;
  String? _carsError;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initDashboard();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  Future<void> _initDashboard() async {
    await _loadUsername();
    await _initializePages(); // **PERBAIKAN: Initialize pages setelah currentUserId ready**
    await _loadCars();
    await _loadFavorites();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    try {
      logindata = await SharedPreferences.getInstance();
      final savedUsername = logindata.getString('username') ?? '';
      
      // **PERBAIKAN: Double check dengan UserService dan set currentUserId**
      final currentUsername = UserService.getCurrentUsername();
      final userId = UserService.getCurrentUserId();
      
      setState(() {
        username = currentUsername ?? savedUsername;
        currentUserId = userId ?? savedUsername; // **PERBAIKAN: Set currentUserId**
      });
      
      print('👤 Dashboard loaded for user: $username (ID: $currentUserId)');
    } catch (e) {
      print('❌ Error loading username: $e');
    }
  }

  /// **PERBAIKAN: Initialize pages dengan currentUserId**
  Future<void> _initializePages() async {
    if (currentUserId == null) {
      print('⚠️ CurrentUserId is null, cannot initialize pages');
      return;
    }

    setState(() {
      _pages = [
        FavoritesPage(),
        EditUserPage(),
        const SizedBox(), // Home content (dashboard)
        BookPage(currentUserId: currentUserId!), 
        HelpPage(),
      ];
    });
    
    print('✅ Pages initialized with currentUserId: $currentUserId');
  }

  Future<void> _loadCars() async {
    setState(() {
      _isLoadingCars = true;
      _carsError = null;
    });

    try {
      final cars = await _fetchCars();
      setState(() {
        allCars = cars;
        _isLoadingCars = false;
      });
    } catch (e) {
      setState(() {
        _carsError = e.toString();
        _isLoadingCars = false;
      });
    }
  }

  Future<void> _loadFavorites() async {
    if (_isLoadingFavorites) return;
    
    setState(() {
      _isLoadingFavorites = true;
    });

    try {
      // Cek apakah user sudah login
      if (!FavoriteService.isUserLoggedIn()) {
        print('ℹ️ User not logged in, skipping favorites load');
        setState(() {
          favoriteCars = {};
          _isLoadingFavorites = false;
        });
        return;
      }

      final favoriteIds = await FavoriteService.getFavoriteIds();
      setState(() {
        favoriteCars = favoriteIds;
        _isLoadingFavorites = false;
      });
      
      print('✅ Loaded ${favoriteIds.length} favorites for dashboard');
    } catch (e) {
      print('❌ Error loading favorites: $e');
      setState(() {
        favoriteCars = {};
        _isLoadingFavorites = false;
      });
    }
  }

  Future<void> _toggleFavorite(Car car) async {
    // Cek apakah user sudah login
    if (!FavoriteService.isUserLoggedIn()) {
      _showSnackBar(
        'Silakan login terlebih dahulu',
        Colors.red[600]!,
        Icons.login,
        action: SnackBarAction(
          label: 'Login',
          textColor: Colors.white,
          onPressed: () => _logout(),
        ),
      );
      return;
    }

    // Get current favorite status
    bool wasIsFavorite;
    try {
      wasIsFavorite = await FavoriteService.isFavorite(car.id);
    } catch (e) {
      print('❌ Error checking favorite status: $e');
      _showSnackBar(
        'Terjadi kesalahan saat mengecek status favorit',
        Colors.red,
        Icons.error,
      );
      return;
    }

    // Optimistic update
    if (mounted) {
      setState(() {
        if (wasIsFavorite) {
          favoriteCars.remove(car.id);
        } else {
          favoriteCars.add(car.id);
        }
      });
    }
    
    try {
      // Perform the actual toggle operation
      final success = await FavoriteService.toggleFavorite(car);
      
      if (!success) {
        // Revert the change if it failed
        if (mounted) {
          setState(() {
            if (wasIsFavorite) {
              favoriteCars.add(car.id);
            } else {
              favoriteCars.remove(car.id);
            }
          });
        }
        
        _showSnackBar(
          'Gagal mengubah status favorit',
          Colors.red,
          Icons.error,
        );
        return;
      }
      
      // Double check the final status from service
      final finalIsFavorite = await FavoriteService.isFavorite(car.id);
      
      // Update UI to match actual service state
      if (mounted) {
        setState(() {
          if (finalIsFavorite) {
            favoriteCars.add(car.id);
          } else {
            favoriteCars.remove(car.id);
          }
        });
      }
      
      // Show success feedback
      _showSnackBar(
        finalIsFavorite 
          ? '${car.nama} ditambahkan ke favorit' 
          : '${car.nama} dihapus dari favorit',
        finalIsFavorite ? Colors.teal[700]! : Colors.orange[700]!,
        finalIsFavorite ? Icons.favorite : Icons.favorite_border,
        action: SnackBarAction(
          label: 'Lihat Favorit',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        ),
      );
      
    } catch (e) {
      print('❌ Error toggling favorite: $e');
      
      // Revert the optimistic update
      if (mounted) {
        setState(() {
          if (wasIsFavorite) {
            favoriteCars.add(car.id);
          } else {
            favoriteCars.remove(car.id);
          }
        });
      }
      
      String errorMessage = 'Terjadi kesalahan';
      if (e.toString().contains('User tidak login')) {
        errorMessage = 'Silakan login terlebih dahulu';
      }
      
      _showSnackBar(errorMessage, Colors.red, Icons.error);
    }
  }

  void _showSnackBar(String message, Color color, IconData icon, {SnackBarAction? action}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: action,
        ),
      );
    }
  }

  Future<List<Car>> _fetchCars() async {
    final response = await http.get(Uri.parse(
        'https://6839447d6561b8d882af9534.mockapi.io/api/project_tpm/mobil'));
    if (response.statusCode == 200) {
      final List<dynamic> list = json.decode(response.body);
      return list.map((e) => Car.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat data mobil');
    }
  }

  Future<void> _searchCars(String query) async {
    if (query.isEmpty) {
      setState(() {
        isSearching = false;
        filteredCars = [];
      });
      return;
    }

    try {
      final response = await http.get(Uri.parse(
          'https://6839447d6561b8d882af9534.mockapi.io/api/sewa_mobil/mobil?search=$query'));
      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        setState(() {
          filteredCars = list.map((e) => Car.fromJson(e)).toList();
          isSearching = true;
        });
      } else {
        throw Exception('Gagal mencari mobil');
      }
    } catch (e) {
      print('❌ Search error: $e');
      // Fallback to local search
      final searchLower = query.toLowerCase();
      setState(() {
        filteredCars = allCars.where((car) {
          return car.nama.toLowerCase().contains(searchLower) ||
                 car.merk.toLowerCase().contains(searchLower);
        }).toList();
        isSearching = true;
      });
    }
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text('Yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Clear all data
        await logindata.clear();
        await UserService.clearCurrentUser();
        
        // Reset state
        setState(() {
          username = "";
          currentUserId = null; // **PERBAIKAN: Clear currentUserId**
          favoriteCars = {};
        });
        
        print('✅ Logout successful');
        
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } catch (e) {
        print('❌ Error during logout: $e');
      }
    }
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  /// **PERBAIKAN: Navigate to booking dengan currentUserId**
  void _navigateToBooking(Car car) {
    if (currentUserId == null) {
      _showSnackBar(
        'Silakan login terlebih dahulu',
        Colors.red[600]!,
        Icons.login,
        action: SnackBarAction(
          label: 'Login',
          textColor: Colors.white,
          onPressed: () => _logout(),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookListPage(
          carId: car.id, 
          car: car,
          currentUserId: currentUserId!, // **PERBAIKAN: Pass currentUserId**
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    final scrollPosition = _scrollController.hasClients ? _scrollController.offset : 0.0;
    
    await Future.wait([
      _loadCars(),
      _loadFavorites(),
    ]);
    
    // Restore scroll position setelah refresh
    if (_scrollController.hasClients && scrollPosition > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            scrollPosition,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // **PERBAIKAN: Show loading jika currentUserId belum ready**
    if (currentUserId == null || _pages.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.teal[800]),
              const SizedBox(height: 16),
              Text(
                'Memuat dashboard...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          username.isNotEmpty ? 'Hai, $username' : 'Dashboard', 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.teal[800],
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _logout,
          color: Colors.white,
          tooltip: 'Logout',
        ),
        actions: [
          if (_isLoadingFavorites)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          // **PERBAIKAN: Show current user ID in debug mode (optional)**
          if (currentUserId != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Text(
                  'ID: $currentUserId',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _selectedIndex == 2
          ? Column(
              children: [
                _buildSearchSection(),
                Expanded(
                  child: _buildCarsList(),
                ),
              ],
            )
          : _pages.isNotEmpty && _selectedIndex < _pages.length 
              ? _pages[_selectedIndex]
              : const Center(child: Text('Halaman tidak tersedia')),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildCarsList() {
    if (_isLoadingCars) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.teal),
      );
    }

    if (_carsError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Terjadi kesalahan: $_carsError',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadCars,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    final cars = isSearching ? filteredCars : allCars;
    
    if (cars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_car, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'Mobil tidak ditemukan' : 'Tidak ada mobil tersedia',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: cars.length,
        itemBuilder: (context, index) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 100)),
            child: _buildModernCarCard(cars[index], index),
          );
        },
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.teal[800],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari mobil berdasarkan merk...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.teal[700]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[500]),
                        onPressed: () {
                          _searchController.clear();
                          _searchCars('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: (value) {
                setState(() {});
                if (value.isEmpty) {
                  _searchCars('');
                }
              },
              onSubmitted: _searchCars,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCarCard(Car car, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section with gradient overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    child: Image.network(
                      car.image,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.teal[700],
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Gradient overlay
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
                // Favorite button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      key: ValueKey('favorite_${car.id}_${favoriteCars.contains(car.id)}'),
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          favoriteCars.contains(car.id) 
                            ? Icons.favorite 
                            : Icons.favorite_border,
                          key: ValueKey(favoriteCars.contains(car.id)),
                          color: favoriteCars.contains(car.id) 
                            ? Colors.red[500] 
                            : Colors.grey[600],
                        ),
                      ),
                      onPressed: () => _toggleFavorite(car),
                      tooltip: favoriteCars.contains(car.id) 
                        ? 'Hapus dari favorit' 
                        : 'Tambah ke favorit',
                    ),
                  ),
                ),
                // Year badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      car.year.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Content section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Car name and merk
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              car.nama,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              car.merk,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Price
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.teal[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal[200]!),
                        ),
                        child: Text(
                          _formatCurrency(car.harga.toDouble()),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Car specifications
                  Row(
                    children: [
                      _buildSpecItem(Icons.people, '${car.kapasitas_penumpang} Kursi'),
                      const SizedBox(width: 20),
                      _buildSpecItem(Icons.confirmation_number, car.plat),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Description
                  Text(
                    car.deskripsi,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailPage(carId: car.id),
                            ),
                          ),
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text('Detail'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal[700],
                            side: BorderSide(color: Colors.teal[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToBooking(car), // **PERBAIKAN: Method sudah diupdate**
                          icon: const Icon(Icons.event_available, size: 18),
                          label: const Text('Book Sekarang'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal[700],
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}