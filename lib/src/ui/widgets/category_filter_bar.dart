// FILE: lib/src/ui/widgets/category_filter_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/notifiers/inventory_notifier.dart';

class CategoryFilterBar extends StatelessWidget {
  final ValueChanged<String?> onCategorySelected;

  const CategoryFilterBar({
    super.key,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<InventoryNotifier>();
    final allCategories = notifier.categories;
    final selectedCategory = notifier.selectedCategory;
    final hasUncategorized = notifier.hasUncategorizedItems;

    if (allCategories.isEmpty && !hasUncategorized) {
      return const SizedBox.shrink();
    }

    final List<Map<String, String?>> categoriesToShow = [
      {'label': 'الكل', 'value': null},
      if (hasUncategorized) {'label': 'غير مصنف', 'value': '_uncategorized_'},
      ...allCategories.map((c) => {'label': c, 'value': c}),
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: categoriesToShow.length,
        itemBuilder: (context, index) {
          final categoryData = categoriesToShow[index];
          final label = categoryData['label']!;
          final value = categoryData['value'];

          final isSelected = selectedCategory == value;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              // Added padding to give text more space
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              onSelected: (selected) {
                if (selected) {
                  onCategorySelected(value);
                }
              },
            ),
          );
        },
      ),
    );
  }
}