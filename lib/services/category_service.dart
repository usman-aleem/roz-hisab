/// Guesses a spend category from an item's name so people get a
/// "where did my money go" breakdown WITHOUT having to pick a
/// category by hand every time — that extra tap is exactly the kind
/// of friction that makes people give up on tracking expenses after
/// a few days. Matching is keyword-based and covers common
/// Roman-Urdu/English grocery terms used in Pakistan; anything that
/// doesn't match falls back to "Other" and still counts normally.
class CategoryService {
  static const other = 'Other';

  /// Ordered so more specific keywords are checked first (e.g.
  /// "chicken" before a generic meat catch-all would matter if lists
  /// overlapped — kept simple here since categories don't overlap).
  static const Map<String, List<String>> _keywords = {
    'Vegetables & Fruit': [
      'aloo', 'potato', 'pyaz', 'onion', 'tamatar', 'tomato', 'adrak',
      'ginger', 'lehsan', 'garlic', 'sabzi', 'vegetable', 'saag',
      'palak', 'spinach', 'gajar', 'carrot', 'kheera', 'cucumber',
      'karela', 'bhindi', 'okra', 'matar', 'peas', 'fruit', 'phal',
      'kela', 'banana', 'seb', 'apple', 'santra', 'orange', 'aam',
      'mango', 'anaar', 'pomegranate', 'angoor', 'grapes', 'tarbooz',
      'watermelon', 'nimbu', 'lemon',
    ],
    'Dairy': [
      'doodh', 'milk', 'dahi', 'yogurt', 'lassi', 'makhan', 'butter',
      'ghee', 'cheese', 'paneer', 'cream', 'anda', 'eggs', 'egg',
    ],
    'Meat & Fish': [
      'gosht', 'meat', 'chicken', 'murgh', 'murghi', 'mutton', 'beef',
      'machli', 'fish', 'qeema', 'mince',
    ],
    'Grocery / Kirana': [
      'atta', 'flour', 'chawal', 'rice', 'daal', 'dal', 'chini',
      'sugar', 'namak', 'salt', 'oil', 'tel', 'cooking oil', 'masala',
      'spice', 'chai', 'tea', 'patti', 'coffee', 'besan', 'suji',
      'maida', 'khoya',
    ],
    'Bakery': [
      'bread', 'naan', 'roti', 'bun', 'biscuit', 'cake', 'rusk',
      'toast', 'bakery',
    ],
    'Snacks & Beverages': [
      'chips', 'juice', 'cold drink', 'soda', 'cola', 'pepsi', 'sprite',
      'chocolate', 'candy', 'toffee', 'namkeen', 'chana', 'nimko',
      'ice cream', 'kulfi', 'drink',
    ],
    'Household': [
      'soap', 'sabun', 'detergent', 'surf', 'washing powder', 'dish',
      'brush', 'jhadu', 'broom', 'tissue', 'napkin', 'matchbox',
      'candle', 'battery', 'bulb', 'garbage bag', 'cleaner', 'phenyl',
    ],
    'Personal Care': [
      'shampoo', 'toothpaste', 'brush', 'lotion', 'cream', 'perfume',
      'razor', 'blade', 'sanitary', 'diaper', 'pampers', 'tissue paper',
      'nappy',
    ],
    'Transport': [
      'petrol', 'diesel', 'fuel', 'fare', 'rickshaw', 'taxi', 'uber',
      'careem', 'bus ticket', 'parking',
    ],
    'Medical': [
      'medicine', 'dawai', 'tablet', 'syrup', 'pharmacy', 'doctor',
      'panadol', 'injection',
    ],
  };

  /// Returns a best-guess category name, or [other] if nothing matches.
  static String categorize(String itemName) {
    final n = itemName.trim().toLowerCase();
    if (n.isEmpty) return other;
    for (final entry in _keywords.entries) {
      for (final kw in entry.value) {
        if (n.contains(kw)) return entry.key;
      }
    }
    return other;
  }

  /// Display order for breakdown UI — keeps output stable/predictable
  /// instead of jumping around as amounts change.
  static const List<String> displayOrder = [
    'Grocery / Kirana',
    'Vegetables & Fruit',
    'Dairy',
    'Meat & Fish',
    'Bakery',
    'Snacks & Beverages',
    'Household',
    'Personal Care',
    'Transport',
    'Medical',
    other,
  ];
}
