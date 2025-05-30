class Car {
  final String id;
  final String nama;
  final String merk;
  final String plat;
  final int year; // ganti dari 'tahun' jadi 'year'
  final String deskripsi;
  final String image;

  Car({
    required this.id,
    required this.nama,
    required this.merk,
    required this.plat,
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
      year: int.parse(json['year']), // ← ubah dari String ke int
      deskripsi: json['deskripsi'],
      image: json['image'], // karena di API hanya 1 string URL
    );
  }
}
