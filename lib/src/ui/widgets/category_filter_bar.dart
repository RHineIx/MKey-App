import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/notifiers/inventory_notifier.dart';
import 'package:rhineix_mkey_app/src/ui/widgets/category_edit_dialog.dart';

class CategoryFilterBar extends StatefulWidget {
  final ValueChanged<String?> onCategorySelected;
  const CategoryFilterBar({
    super.key,
    required this.onCategorySelected,
  });

  @override
  State<CategoryFilterBar> createState() => _CategoryFilterBarState();
}

class _CategoryFilterBarState extends State<CategoryFilterBar> {
  String? _editingCategory;

  void _handleRename(BuildContext context, String oldName) async {
    final notifier = context.read<InventoryNotifier>();
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: notifier,
        child: CategoryEditDialog(oldName: oldName),
      ),
    );
    setState(() {
      _editingCategory = null;
    });
    if (newName != null && newName.isNotEmpty && newName != oldName) {
      if (context.mounted) {
        notifier.renameCategory(oldName, newName);
      }
    }
  }

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
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            // Adjust stops to control the fade width
            stops: [0.0, 0.05, 0.95, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          itemCount: categoriesToShow.length,
          itemBuilder: (context, index) {
            final categoryData = categoriesToShow[index];
            final label = categoryData['label']!;
            final value = categoryData['value'];
            final isSelected = selectedCategory == value;
            final isEditing = _editingCategory == value;
            final canEdit = value != null && value != '_uncategorized_';

            final chip = TextButton(
              style: TextButton.styleFrom(
                backgroundColor: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                foregroundColor: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () {
                if(isEditing) {
                  setState(() => _editingCategory = null);
                  return;
                }
                widget.onCategorySelected(value);
              },
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            );

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: GestureDetector(
                onLongPress: canEdit ? () => setState(() => _editingCategory = value) : null,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    chip,
                    if (isEditing && canEdit)
                      Positioned(
                        top: -8,
                        right: -8,
                        child: GestureDetector(
                          onTap: () => _handleRename(context, value),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: kElevationToShadow[2],
                            ),
                            child: const Icon(Symbols.edit, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}