import 'package:equatable/equatable.dart';

import 'member.dart';

enum ActivityKind {
  added,
  checked,
  unchecked,
  removed,
  quantity,
  tripStarted,
  tripFinished,
  joined,
  nudged;

  static ActivityKind fromName(String name) {
    for (final kind in values) {
      if (kind.name == name) return kind;
    }
    return ActivityKind.added;
  }
}

/// One line in the "live activity" feed, e.g. "Anis checked off Milk".
class Activity extends Equatable {
  const Activity({
    required this.id,
    required this.listId,
    required this.actor,
    required this.kind,
    required this.itemName,
    required this.at,
  });

  final String id;
  final String listId;
  final Member actor;
  final ActivityKind kind;
  final String itemName;
  final DateTime at;

  String get sentence {
    final who = actor.firstName;
    switch (kind) {
      case ActivityKind.added:
        return '$who added $itemName';
      case ActivityKind.checked:
        return '$who checked off $itemName';
      case ActivityKind.unchecked:
        return '$who put $itemName back';
      case ActivityKind.removed:
        return '$who removed $itemName';
      case ActivityKind.quantity:
        return '$who changed $itemName';
      case ActivityKind.tripStarted:
        return '$who started shopping';
      case ActivityKind.tripFinished:
        return '$who finished the trip';
      case ActivityKind.joined:
        return '$who joined the list';
      case ActivityKind.nudged:
        return '$who sent a nudge to $itemName';
    }
  }

  @override
  List<Object?> get props => [id, listId, actor, kind, itemName, at];
}
