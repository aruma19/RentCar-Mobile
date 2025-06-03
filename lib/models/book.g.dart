// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookAdapter extends TypeAdapter<Book> {
  @override
  final int typeId = 2;

  @override
  Book read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Book(
      id: fields[0] as String,
      carId: fields[1] as String,
      carName: fields[2] as String,
      carMerk: fields[3] as String,
      userName: fields[4] as String,
      nohp: fields[5] as String,
      userId: fields[6] as String,
      rentalDays: fields[7] as int,
      needDriver: fields[8] as bool,
      basePrice: fields[9] as double,
      driverPrice: fields[10] as double,
      totalPrice: fields[11] as double,
      startDate: fields[12] as DateTime,
      endDate: fields[13] as DateTime,
      bookingDate: fields[14] as DateTime,
      createdAt: fields[15] as DateTime?,
      status: fields[16] as String? ?? 'pending', // Default value for backward compatibility
      paymentStatus: fields[17] as String? ?? 'unpaid', // Default value for backward compatibility
      paidAmount: fields[18] as double? ?? 0.0, // Default value for backward compatibility
      paymentDate: fields[19] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Book obj) {
    writer
      ..writeByte(20)  // Total 19 fields (0-18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.carId)
      ..writeByte(2)
      ..write(obj.carName)
      ..writeByte(3)
      ..write(obj.carMerk)
      ..writeByte(4)
      ..write(obj.userName)
      ..writeByte(5)
      ..write(obj.nohp)
      ..writeByte(6)
      ..write(obj.userId)
      ..writeByte(7)
      ..write(obj.rentalDays)
      ..writeByte(8)
      ..write(obj.needDriver)
      ..writeByte(9)
      ..write(obj.basePrice)
      ..writeByte(10)
      ..write(obj.driverPrice)
      ..writeByte(11)
      ..write(obj.totalPrice)
      ..writeByte(12)
      ..write(obj.startDate)
      ..writeByte(13)
      ..write(obj.endDate)
      ..writeByte(14)
      ..write(obj.bookingDate)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.status)
      ..writeByte(17)
      ..write(obj.paymentStatus)
      ..writeByte(18)
      ..write(obj.paidAmount)
      ..writeByte(19)
      ..write(obj.paymentDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}