import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'bookList.dart';
import 'helpPage.dart';
import 'historyBook.dart';
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

  final List<Widget> _pages = [
    FavoritesPage(),
    HistoryBookPage(),
    const SizedBox(),
    BookPage(),
    HelpPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  late SharedPreferences logindata;
  String username = "";
  TextEditingController _searchController = TextEditingController();
  List<Car> filteredCars = [];
  bool isSearching = false;
  Set<String> favoriteCars = {}; // Set untuk menyimpan ID mobil favorit

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadFavorites();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    logindata = await SharedPreferences.getInstance();
    setState(() {
      username = logindata.getString('username') ?? '';
    });
  }

  Future<void> _loadFavorites() async {
    final favoriteIds = await FavoriteService.getFavoriteIds();
    setState(() {
      favoriteCars = favoriteIds;
    });
  }

  Future<void> _toggleFavorite(Car car) async {
    // Show loading state
    setState(() {
      if (favoriteCars.contains(car.id)) {
        favoriteCars.remove(car.id);
      } else {
        favoriteCars.add(car.id);
      }
    });
    
    // Perform the actual toggle operation
    final success = await FavoriteService.toggleFavorite(car);
    
    if (!success) {
      // Revert the change if it failed
      setState(() {
        if (favoriteCars.contains(car.id)) {
          favoriteCars.remove(car.id);
        } else {
          favoriteCars.add(car.id);
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengubah status favorit'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    // Show success feedback
    final isFavorite = favoriteCars.contains(car.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFavorite 
                    ? '${car.nama} ditambahkan ke favorit' 
                    : '${car.nama} dihapus dari favorit'
                ),
              ),
            ],
          ),
          backgroundColor: isFavorite ? Colors.teal[700] : Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Lihat Favorit',
            textColor: Colors.white,
            onPressed: () {
              setState(() {
                _selectedIndex = 0; // Navigate to Favorites page
              });
            },
          ),
        ),
      );
    }
  }

  Future<List<Car>> _fetchCars() async {
    final response = await http.get(Uri.parse(
        'https://6839447d6561b8d882af9534.mockapi.io/api/sewa_mobil/mobil'));
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
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout')),
        ],
      ),
    );

    if (confirm == true) {
      await logindata.clear();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  void _navigateToEditUser() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditUserPage()),
    );
    
    if (result == true) {
      _loadUsername();
    }
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}';
  }

  void _navigateToBooking(Car car) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookListPage(carId: car.id, car: car),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Hai, $username', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal[800],
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _logout,
          color: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _navigateToEditUser,
            color: Colors.white,
            tooltip: 'Edit Profil',
          ),
        ],
      ),
      body: _selectedIndex == 2
          ? Column(
              children: [
                _buildSearchSection(),
                Expanded(
                  child: FutureBuilder<List<Car>>(
                    future: _fetchCars(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.teal,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Terjadi kesalahan: ${snapshot.error}',
                                style: TextStyle(color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      final cars = isSearching ? filteredCars : snapshot.data!;
                      
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
                        onRefresh: () async {
                          await _loadFavorites(); // Reload favorites when refreshing
                          setState(() {});
                        },
                        child: ListView.builder(
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
                    },
                  ),
                ),
              ],
            )
          : _pages[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: IconButton(
                        key: ValueKey(favoriteCars.contains(car.id)),
                        icon: Icon(
                          favoriteCars.contains(car.id) 
                            ? Icons.favorite 
                            : Icons.favorite_border,
                        ),
                        color: favoriteCars.contains(car.id) 
                          ? Colors.red[500] 
                          : Colors.grey[600],
                        onPressed: () => _toggleFavorite(car),
                      ),
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
                          onPressed: () => _navigateToBooking(car),
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