import 'package:equatable/equatable.dart';

import 'member.dart';

enum TripStage { planned, shopping, done }

class ShoppingList extends Equatable {
  const ShoppingList({
    required this.id,
    required this.name,
    required this.store,
    required this.ownerId,
    required this.members,
    required this.itemCount,
    required this.leftCount,
    required this.estimatedTotal,
    this.shopper,
    this.tripStartedAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String store;
  final String ownerId;
  final List<Member> members;
  final int itemCount;

  /// Items that are not checked off yet.
  final int leftCount;
  final double estimatedTotal;

  /// Who is in the shop right now, if anyone.
  final Member? shopper;
  final DateTime? tripStartedAt;
  final DateTime updatedAt;

  int get checkedCount => itemCount - leftCount;

  double get progress => itemCount == 0 ? 0 : checkedCount / itemCount;

  TripStage get stage {
    if (itemCount > 0 && leftCount == 0) return TripStage.done;
    if (shopper != null) return TripStage.shopping;
    return TripStage.planned;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        store,
        ownerId,
        members,
        itemCount,
        leftCount,
        estimatedTotal,
        shopper,
        tripStartedAt,
        updatedAt,
      ];
}
