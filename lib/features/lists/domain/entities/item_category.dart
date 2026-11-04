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

  /// A first guess from the item name, so most items get a nice icon without
  /// the user picking one. They can still change it.
  static ItemCategory guess(String itemName) {
    final name = itemName.toLowerCase();
    for (final entry in _keywords.entries) {
      for (final word in entry.value) {
        if (name.contains(word)) return entry.key;
      }
    }
    return ItemCategory.other;
  }

  static const _keywords = <ItemCategory, List<String>>{
    ItemCategory.dairy: ['milk', 'cheese', 'yogurt', 'yoghurt', 'butter', 'egg', 'cream', 'parmesan', 'mozzarella'],
    ItemCategory.bakery: ['bread', 'baguette', 'croissant', 'bun', 'cake', 'sourdough'],
    ItemCategory.meat: ['chicken', 'beef', 'lamb', 'turkey', 'ham', 'sausage', 'mince'],
    ItemCategory.fish: ['fish', 'salmon', 'tuna', 'shrimp', 'prawn', 'cod'],
    ItemCategory.drinks: ['water', 'juice', 'coffee', 'tea', 'soda', 'lemonade', 'wine', 'beer'],
    ItemCategory.frozen: ['frozen', 'ice cream', 'peas'],
    ItemCategory.snacks: ['chocolate', 'chips', 'crisps', 'cookie', 'biscuit', 'popcorn', 'nachos', 'nuts'],
    ItemCategory.household: ['soap', 'detergent', 'paper', 'towel', 'sponge', 'bin bag', 'toilet', 'shampoo'],
    ItemCategory.pantry: ['rice', 'pasta', 'flour', 'sugar', 'oil', 'salt', 'honey', 'beans', 'granola', 'cereal', 'penne'],
    ItemCategory.produce: [
      'apple', 'banana', 'tomato', 'lemon', 'lime', 'onion', 'garlic', 'potato', 'carrot', 'spinach',
      'lettuce', 'avocado', 'basil', 'cucumber', 'orange', 'berries', 'grape', 'pepper', 'herb',
    ],
  };
}
