class Car {
  final String id;
  final String nama;
  final String merk;
  final String plat;
  final int harga;
  final int kapasitas_penumpang;
  final int year; // ganti dari 'tahun' jadi 'year'
  final String deskripsi;
  final String image;

  Car({
    required this.id,
    required this.nama,
    required this.merk,
    required this.plat,
    required this.harga,
    required this.kapasitas_penumpang,
    required this.year,
    required this.deskripsi,
    required this.image,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'],
      nama: json['nama'],
      merk: json['merk'],
      plat: json['plat'],
      harga: json['harga'] is int
          ? json['harga']
          : int.tryParse(json['harga'].toString()) ?? 0,
      kapasitas_penumpang: json['kapasitas_penumpang'] is int
          ? json['kapasitas_penumpang']
          : int.tryParse(json['kapasitas_penumpang'].toString()) ?? 0,
      year: json['year'] is int
          ? json['year']
          : int.tryParse(json['year'].toString()) ?? 0,
      deskripsi: json['deskripsi'],
      image: json['image'],
    );
  }
}
