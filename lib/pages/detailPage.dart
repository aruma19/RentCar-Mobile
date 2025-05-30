import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'Dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailPage extends StatefulWidget {
  final Map<String, dynamic> carData;
  const DetailPage({super.key, required this.carData, required String carId});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  @override
  Widget build(BuildContext context) {
    final car = widget.carData;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Car Detail", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF141E30),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildImage(car['imageUrl']),
            const SizedBox(height: 20),
            Text(
              car['name'],
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF141E30)),
            ),
            const SizedBox(height: 8),
            Text("Plat Nomor: ${car['plateNumber']}", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            Text("Harga Sewa: Rp${car['price']} /hari", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            Text("Tahun: ${car['year']}", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 16),
            const Text("Deskripsi:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              car['description'],
              style: const TextStyle(fontSize: 16, height: 1.5),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/book',
                  arguments: car,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF141E30),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Book Now", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
              color: const Color(0xFF141E30),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          height: 220,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, size: 80, color: Colors.grey),
        ),
      ),
    );
  }
}
