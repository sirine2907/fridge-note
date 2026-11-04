import 'package:equatable/equatable.dart';

/// The person signed in on this phone.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.color,
    this.email,
    this.isDemo = false,
  });

  final String id;
  final String name;
  final int color;
  final String? email;

  /// True when running against the fake in-memory backend.
  final bool isDemo;

  @override
  List<Object?> get props => [id, name, color, email, isDemo];
}
