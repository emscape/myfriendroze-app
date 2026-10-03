import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:myfriendroze_admin/models/product.dart';
import 'package:myfriendroze_admin/providers/product_provider.dart';
import 'package:myfriendroze_admin/screens/products/products_screen.dart';

Product buildProduct({required String id, required String title}) {
  final now = DateTime(2026, 10, 1);
  return Product(
    id: id,
    title: title,
    description: 'A handmade piece',
    price: 40.0,
    weight: 500.0,
    imageUrls: const [],
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeProductProvider extends ProductProvider {
  final List<Product> fakeProducts;

  _FakeProductProvider(this.fakeProducts);

  @override
  List<Product> get products => fakeProducts;

  @override
  void loadProducts() {
    // No-op: this test injects products directly rather than through Firestore.
  }
}

/// ProductsScreen inside a router whose edit route shows which product it
/// was handed, so a test can tell where a tap went.
Widget buildApp(ProductProvider provider) {
  final router = GoRouter(
    initialLocation: '/products',
    routes: [
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductsScreen(),
      ),
      GoRoute(
        path: '/products/add',
        builder: (context, state) {
          final extra = state.extra;
          return Scaffold(
            body: Text(
              extra is Product ? 'Editing ${extra.title}' : 'Adding new',
            ),
          );
        },
      ),
    ],
  );
  return ChangeNotifierProvider<ProductProvider>.value(
    value: provider,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  // The site treats a count of 0 as sold out whatever inStock says (e.g.
  // after "Mark In Stock" on a plant with none left), so the list does too.
  testWidgets('shows SOLD OUT for a plant with a count of 0, even if marked in stock', (
    tester,
  ) async {
    final provider = _FakeProductProvider([
      buildProduct(id: 'p1', title: 'Aloe').copyWith(stockQuantity: 0, inStock: true),
    ]);

    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    expect(find.text('SOLD OUT'), findsOneWidget);
  });

  testWidgets("shows a tracked plant's stock count, including 0", (
    tester,
  ) async {
    final provider = _FakeProductProvider([
      buildProduct(id: 'p1', title: 'Aloe').copyWith(stockQuantity: 0, inStock: false),
      buildProduct(id: 'p2', title: 'Fern').copyWith(stockQuantity: 4),
      buildProduct(id: 'p3', title: 'Blue Mug'),
    ]);

    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    expect(find.text('0 in stock'), findsOneWidget);
    expect(find.text('4 in stock'), findsOneWidget);
    expect(find.textContaining('in stock'), findsNWidgets(2));
  });

  testWidgets('tapping a product card opens that product for editing', (
    tester,
  ) async {
    final provider = _FakeProductProvider([
      buildProduct(id: 'p1', title: 'Blue Mug'),
      buildProduct(id: 'p2', title: 'Green Vase'),
    ]);

    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Green Vase'));
    await tester.pumpAndSettle();

    expect(find.text('Editing Green Vase'), findsOneWidget);
  });

  testWidgets('the card menu still opens its actions instead of editing', (
    tester,
  ) async {
    final provider = _FakeProductProvider([
      buildProduct(id: 'p1', title: 'Blue Mug'),
    ]);

    await tester.pumpWidget(buildApp(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('Mark Sold Out'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.textContaining('Editing'), findsNothing);
  });
}
