/// Built-in calorie estimates for common craving labels.
/// Values are rough estimates in kcal.
class CalorieLibrary {
  CalorieLibrary._();

  static const Map<String, int> suggestions = {
    // Fast food
    'kfc': 800,
    'kfc meal': 1050,
    'mcdonalds': 750,
    'burger king': 780,
    'subway footlong': 620,
    'pizza slice': 285,
    'pizza': 900,
    'fried chicken': 450,
    'burger': 550,
    'hot dog': 300,

    // Sri Lankan street food
    'kottu': 700,
    'roti': 200,
    'hoppers': 180,
    'string hoppers': 240,
    'wade': 220,
    'samosa': 250,
    'isso wade': 310,
    'devilled chicken': 480,
    'lamprais': 850,
    'rice and curry': 650,

    // Beverages / desserts
    'bubble tea': 400,
    'milk tea': 350,
    'soft drink': 150,
    'juice': 180,
    'ice cream': 320,
    'cake': 400,
    'chocolate': 250,
    'chips': 280,
    'biscuits': 200,
    'short eats': 350,
  };

  /// Returns calorie suggestion for [label], case-insensitive.
  /// Returns null if no match found.
  static int? getSuggestion(String label) {
    final key = label.toLowerCase().trim();
    return suggestions[key];
  }

  /// Returns entries whose key starts with [prefix], sorted by key.
  static List<MapEntry<String, int>> search(String prefix) {
    final p = prefix.toLowerCase().trim();
    if (p.isEmpty) return [];
    return suggestions.entries
        .where((e) => e.key.contains(p))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }
}
