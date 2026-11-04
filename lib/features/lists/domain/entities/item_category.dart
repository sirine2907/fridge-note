/// Shelf an item belongs to. Decides its icon and tile color.
enum ItemCategory {
  produce('Fruit & veg'),
  dairy('Dairy & eggs'),
  bakery('Bakery'),
  meat('Meat'),
  fish('Fish'),
  drinks('Drinks'),
  frozen('Frozen'),
  pantry('Pantry'),
  snacks('Snacks'),
  household('Household'),
  other('Other');

  const ItemCategory(this.label);

  final String label;

  static ItemCategory fromName(String? name) {
    for (final category in values) {
      if (category.name == name) return category;
    }
    return ItemCategory.other;
  }
}
