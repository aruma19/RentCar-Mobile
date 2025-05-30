import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project_133_165/pages/bookList.dart';
import 'package:project_133_165/pages/helpPage.dart';
import 'package:project_133_165/pages/historyBook.dart';
import 'package:project_133_165/pages/teamMember.dart';
import 'package:project_133_165/widgets/bottom_nav_bar.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/Car.dart'; // import sesuai struktur folder
import 'Login.dart';
import 'detailPage.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 2; // Menyimpan index halaman yang sedang aktif

  // Daftar halaman yang akan ditampilkan berdasarkan bottom navigation
  final List<Widget> _pages = [
    MemberListScreen(), //Halaman Anggota Kelompok
    HistoryBookPage(), //Halaman History Book
    const SizedBox(),// Halaman home dengan daftar menu
    BookListPage(), // Halaman daftar anggota tim
    HelpPage(), // Halaman bantuan
  ];

  /// Mengubah tampilan halaman sesuai index yang diklik
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

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    logindata = await SharedPreferences.getInstance();
    setState(() {
      username = logindata.getString('username') ?? '';
    });
  }

  Future<List<Car>> _fetchCars() async {
    final response = await http.get(Uri.parse('https://example.com/api/cars'));
    if (response.statusCode == 200) {
      final List<dynamic> list = json.decode(response.body)['cars'];
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

    final response =
        await http.get(Uri.parse('https://example.com/api/cars?search=$query'));
    if (response.statusCode == 200) {
      final List<dynamic> list = json.decode(response.body)['cars'];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Hai, $username', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.teal[800],
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _logout,
          color: Colors.white,
        ),
      ),
      body: _selectedIndex == 2
          ? Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari kategori (contoh: sedan)',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => _searchCars(_searchController.text),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: _searchCars,
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Car>>(
                    future: _fetchCars(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                            child:
                                Text('Terjadi kesalahan: ${snapshot.error}'));
                      }

                      final cars = isSearching ? filteredCars : snapshot.data!;
                      return ListView.builder(
                        itemCount: cars.length,
                        itemBuilder: (context, index) =>
                            _buildCarCard(cars[index]),
                      );
                    },
                  ),
                ),
              ],
            )
          : _pages[_selectedIndex], // halaman lain selain dashboard (index 0)
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildCarCard(Car car) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => DetailPage(
                      carId: car.id,
                      carData: {},
                    ))),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Column(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  car.images as String,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(car.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text("Plat Nomor: ${car.plate}"),
                    Text("Harga: ${car.price}"),
                    Text("Kategori: ${car.category}",
                        style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    const Align(
                        alignment: Alignment.centerRight,
                        child: Icon(Icons.arrow_forward_ios, size: 16))
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
