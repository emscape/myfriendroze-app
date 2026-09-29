import 'package:flutter/material.dart';

import '../models/product_category.dart';

// Category dropdown for the add/edit product form. Required: with no
// default, a new product can't be saved until a category is chosen, so a
// plant is never silently listed on the pottery page.
class ProductCategoryPicker extends StatelessWidget {
  final ProductCategory? value;
  final ValueChanged<ProductCategory?> onChanged;

  const ProductCategoryPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ProductCategory>(
      value: value,
      decoration: const InputDecoration(labelText: 'Category'),
      hint: const Text('Choose a category'),
      items: ProductCategory.values
          .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
          .toList(),
      onChanged: onChanged,
      validator: (value) =>
          value == null ? 'Please choose a category' : null,
    );
  }
}
