import 'package:hive/hive.dart';

// File ini akan digenerate otomatis oleh build_runner

@HiveType(typeId: 0)
class User {
  @HiveField(0)
  final String email;

  @HiveField(1)
  final String username;

  @HiveField(2)
  final String password;

  User({required this.email, required this.username, required this.password});
}