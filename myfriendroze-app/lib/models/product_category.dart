// Which shop page a product is listed on. `value` is the string stored in
// the product doc's `category` field; the site (astro/src/lib/product-
// mapping.js in the myfriendroze repo) filters its shop pages on exactly
// these strings, so they must not change. `label` is what the admin form
// shows, including each shop page's name on the site.
enum ProductCategory {
  pottery('pottery', "Pottery (you're kiln me)"),
  plant('plant', 'Plant (dd succulents)'),
  other('other', 'Other (the rest of my madness)');

  const ProductCategory(this.value, this.label);

  final String value;
  final String label;

  /// Null for a missing or unrecognised stored value. Products created
  /// before this field existed have no category; the site lists those as
  /// pottery, and the edit form preselects pottery for them.
  static ProductCategory? fromValue(String? value) {
    for (final category in values) {
      if (category.value == value) return category;
    }
    return null;
  }
}
