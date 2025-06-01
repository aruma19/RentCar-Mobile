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
      userId: fields[5] as String,
      rentalDays: fields[6] as int,
      needDriver: fields[7] as bool,
      basePrice: fields[8] as double,
      driverPrice: fields[9] as double,
      totalPrice: fields[10] as double,
      startDate: fields[11] as DateTime,
      endDate: fields[12] as DateTime,
      bookingDate: fields[13] as DateTime,
      createdAt: fields[14] as DateTime?,
      status: fields[15] as String? ?? 'pending', // Default value for backward compatibility
      paymentStatus: fields[16] as String? ?? 'unpaid', // Default value for backward compatibility
      paidAmount: fields[17] as double? ?? 0.0, // Default value for backward compatibility
      paymentDate: fields[18] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Book obj) {
    writer
      ..writeByte(19)  // Total 19 fields (0-18)
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
      ..write(obj.userId)
      ..writeByte(6)
      ..write(obj.rentalDays)
      ..writeByte(7)
      ..write(obj.needDriver)
      ..writeByte(8)
      ..write(obj.basePrice)
      ..writeByte(9)
      ..write(obj.driverPrice)
      ..writeByte(10)
      ..write(obj.totalPrice)
      ..writeByte(11)
      ..write(obj.startDate)
      ..writeByte(12)
      ..write(obj.endDate)
      ..writeByte(13)
      ..write(obj.bookingDate)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.status)
      ..writeByte(16)
      ..write(obj.paymentStatus)
      ..writeByte(17)
      ..write(obj.paidAmount)
      ..writeByte(18)
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