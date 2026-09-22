// Widget test for the "Delay posting" (scheduled publish) toggle on the
// add/edit product form. Doesn't drive the real showDatePicker/
// showTimePicker dialogs (brittle, not this repo's established widget-test
// style) -- the future-only validation logic (_publishAtError) is simple
// enough that the mandatory manual click-through (see this repo's
// deployment docs) is the right check for that interactive path.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myfriendroze_admin/providers/product_provider.dart';
import 'package:myfriendroze_admin/screens/products/add_product_screen.dart';
import 'package:myfriendroze_admin/widgets/selector_box.dart';

void main() {
  testWidgets(
    'checking "Delay posting" reveals the publish date/time pickers, unchecking hides them',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ProductProvider>(
          create: (_) => ProductProvider(),
          child: const MaterialApp(home: AddProductScreen()),
        ),
      );

      expect(find.text('Publish Date'), findsNothing);
      expect(find.text('Publish Time'), findsNothing);

      // The form is long and scrollable -- "Delay posting" starts off
      // screen, so tap() would silently hit nothing without scrolling it
      // into view first.
      await tester.ensureVisible(find.text('Delay posting'));
      await tester.tap(find.text('Delay posting'));
      await tester.pump();

      expect(find.text('Publish Date'), findsOneWidget);
      expect(find.text('Publish Time'), findsOneWidget);
      expect(find.byType(SelectorBox), findsNWidgets(2));

      await tester.tap(find.text('Delay posting'));
      await tester.pump();

      expect(find.text('Publish Date'), findsNothing);
      expect(find.text('Publish Time'), findsNothing);
    },
  );
}
