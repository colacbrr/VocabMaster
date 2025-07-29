// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      uid: fields[0] as String,
      displayName: fields[1] as String,
      email: fields[2] as String,
      photoURL: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      totalWordsLearned: fields[5] as int,
      streakDays: fields[6] as int,
      dailyGoal: fields[7] as int,
      categoryProgress: (fields[8] as Map).cast<String, int>(),
      achievements: (fields[9] as List).cast<String>(),
      lastStudySession: fields[10] as DateTime,
      xpPoints: fields[11] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.photoURL)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.totalWordsLearned)
      ..writeByte(6)
      ..write(obj.streakDays)
      ..writeByte(7)
      ..write(obj.dailyGoal)
      ..writeByte(8)
      ..write(obj.categoryProgress)
      ..writeByte(9)
      ..write(obj.achievements)
      ..writeByte(10)
      ..write(obj.lastStudySession)
      ..writeByte(11)
      ..write(obj.xpPoints);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
