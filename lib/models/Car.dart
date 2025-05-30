class Car {
  final String id;
  final String nama;
  final String merk;
  final String plat;
  final int harga;
  final int kapatsitas_penumpang;
  final int year; // ganti dari 'tahun' jadi 'year'
  final String deskripsi;
  final String image;

  Car({
    required this.id,
    required this.nama,
    required this.merk,
    required this.plat,
    required this.harga,
    required this.kapatsitas_penumpang,
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
      harga: int.parse(json['harga']), // ← ubah dari String ke int
      kapatsitas_penumpang: int.parse(json['kapatsitas_penumpang']), // ← ubah dari String ke int
      year: int.parse(json['year']), // ← ubah dari String ke int
      deskripsi: json['deskripsi'],
      image: json['image'], // karena di API hanya 1 string URL
    );
  }
}
