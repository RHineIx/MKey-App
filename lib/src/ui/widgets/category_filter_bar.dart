// FILE: lib/src/ui/widgets/category_filter_bar.dart
import 'package:flutter/material.dart';

class CategoryFilterBar extends StatelessWidget {
  final List<String> allCategories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  const CategoryFilterBar({
    super.key,
    required this.allCategories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final categoriesToShow = <String>['الكل', ...allCategories];
    if (allCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        itemCount: categoriesToShow.length,
        itemBuilder: (context, index) {
          final category = categoriesToShow[index];
          final isSelected =
              (selectedCategory == null && category == 'الكل') ||
                  (selectedCategory == category);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onCategorySelected(category == 'الكل' ? null : category);
                }
              },
            ),
          );
        },
      ),
    );
  }
}