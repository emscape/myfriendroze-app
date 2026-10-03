import '../models/product.dart';
import '../models/product_category.dart';

/// Label of the product form's stock count field (plants only).
const stockCountLabel = 'How many in stock';

/// What the product form saves for a stock count.
///
/// Only plants are tracked: pottery and "other" pieces are one of a kind,
/// and the site already marks those sold when they're paid for. A blank
/// field means untracked. The site's checkout refuses more than the count
/// and counts it down after payment (firebase/functions/lib/pricing.js and
/// lib/stockCounts.js in the myfriendroze repo).
class StockUpdate {
  const StockUpdate({this.stockQuantity, this.inStock});

  /// Null: untracked, and any saved count is cleared.
  final int? stockQuantity;

  /// Null: leave the product's in-stock state as it is.
  final bool? inStock;
}

StockUpdate stockUpdateFor(ProductCategory? category, String text) {
  final trimmed = text.trim();
  if (category != ProductCategory.plant || trimmed.isEmpty) {
    return const StockUpdate();
  }
  final count = int.parse(trimmed);
  return StockUpdate(stockQuantity: count, inStock: count > 0);
}

/// The product an edit saves: [update] applied to [product]. A null
/// count clears any saved one; a null inStock leaves it as it was.
Product applyStockUpdate(Product product, StockUpdate update) {
  return product.copyWith(
    stockQuantity: update.stockQuantity,
    clearStockQuantity: update.stockQuantity == null,
    inStock: update.inStock,
  );
}

String? validateStockCount(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  final count = int.tryParse(trimmed);
  if (count == null || count < 0) return 'Enter a whole number, or leave blank';
  return null;
}
