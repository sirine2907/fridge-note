import 'package:fridge_note/features/lists/domain/entities/item_category.dart';
import 'package:fridge_note/features/lists/domain/entities/list_item.dart';
import 'package:fridge_note/features/lists/domain/entities/member.dart';
import 'package:fridge_note/features/lists/domain/entities/shopping_list.dart';
import 'package:fridge_note/features/usuals/domain/entities/usual_item.dart';

const sirine = Member(id: 'sirine', name: 'Sirine', color: 0xFF7360F2);
const anis = Member(id: 'anis', name: 'Anis', color: 0xFF2FB67C);

ListItem milk({String id = 'milk', bool checked = false, int quantity = 2, String name = 'Milk'}) {
  return ListItem(
    id: id,
    listId: 'list',
    name: name,
    category: ItemCategory.dairy,
    quantity: quantity,
    unit: 'L',
    price: 1.15,
    checked: checked,
    position: 1000,
    addedBy: sirine,
    checkedBy: checked ? anis : null,
    updatedAt: DateTime(2026, 11, 4, 10),
  );
}

ShoppingList weeklyList({int itemCount = 2, int leftCount = 1, Member? shopper}) {
  return ShoppingList(
    id: 'list',
    name: 'Weekly groceries',
    store: 'Green Corner Market',
    ownerId: sirine.id,
    members: const [sirine, anis],
    itemCount: itemCount,
    leftCount: leftCount,
    estimatedTotal: 4.6,
    shopper: shopper,
    updatedAt: DateTime(2026, 11, 4, 10),
  );
}

UsualItem eggsUsual({bool favorite = false}) {
  return UsualItem(
    id: 'usual-eggs',
    name: 'Eggs',
    category: ItemCategory.dairy,
    quantity: 12,
    unit: 'pcs',
    price: 0.28,
    favorite: favorite,
    timesBought: 20,
    badge: 'Weekly',
  );
}
