import 'package:equatable/equatable.dart';

/// A person who shares a list.
class Member extends Equatable {
  const Member({required this.id, required this.name, required this.color});

  final String id;
  final String name;

  /// Avatar color as an ARGB int.
  final int color;

  static const unknown = Member(id: '', name: 'Someone', color: 0xFF8A8A99);

  String get firstName => name.split(' ').first;

  @override
  List<Object?> get props => [id, name, color];
}
