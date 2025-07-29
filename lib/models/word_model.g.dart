// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WordModelAdapter extends TypeAdapter<WordModel> {
  @override
  final int typeId = 1;

  @override
  WordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WordModel(
      id: fields[0] as String,
      word: fields[1] as String,
      definition: fields[2] as String,
      example: fields[3] as String,
      partOfSpeech: fields[4] as String,
      learnedAt: fields[5] as DateTime,
      reviewCount: fields[6] as int,
      masteryLevel: fields[7] as double,
      nextReview: fields[8] as DateTime,
      isFavorite: fields[9] as bool,
      lastSynced: fields[10] as DateTime,
      userId: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, WordModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.word)
      ..writeByte(2)
      ..write(obj.definition)
      ..writeByte(3)
      ..write(obj.example)
      ..writeByte(4)
      ..write(obj.partOfSpeech)
      ..writeByte(5)
      ..write(obj.learnedAt)
      ..writeByte(6)
      ..write(obj.reviewCount)
      ..writeByte(7)
      ..write(obj.masteryLevel)
      ..writeByte(8)
      ..write(obj.nextReview)
      ..writeByte(9)
      ..write(obj.isFavorite)
      ..writeByte(10)
      ..write(obj.lastSynced)
      ..writeByte(11)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
