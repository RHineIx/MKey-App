// FILE: lib/src/ui/widgets/category_input.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhineix_mkey_app/src/notifiers/inventory_notifier.dart';

class CategoryInput extends StatefulWidget {
  final Set<String> initialCategories;
  final Function(Set<String>) onChanged;

  const CategoryInput({
    super.key,
    required this.initialCategories,
    required this.onChanged,
  });

  @override
  State<CategoryInput> createState() => _CategoryInputState();
}

class _CategoryInputState extends State<CategoryInput> {
  late final Set<String> _selectedCategories;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategories = widget.initialCategories;
  }

  void _addCategory(String category) {
    final trimmedCategory = category.trim();
    if (trimmedCategory.isNotEmpty) {
      setState(() {
        _selectedCategories.add(trimmedCategory);
      });
      widget.onChanged(_selectedCategories);
      _textController.clear();
    }
  }

  void _removeCategory(String category) {
    setState(() {
      _selectedCategories.remove(category);
    });
    widget.onChanged(_selectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    final allCategories = context.read<InventoryNotifier>().categories;
    final availableCategories = allCategories.where((c) => !_selectedCategories.contains(c)).toList();

    return InputDecorator(
      decoration: const InputDecoration( // Corrected: Added const
        labelText: 'الفئات',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Categories
          if (_selectedCategories.isNotEmpty)
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _selectedCategories.map((category) {
                return Chip(
                  label: Text(category),
                  onDeleted: () => _removeCategory(category),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            )
          else
            const Text('لا توجد فئات محددة', style: TextStyle(color: Colors.grey)),
          const Divider(height: 24),
          // Input Field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'اكتب فئة جديدة...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: _addCategory,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _addCategory(_textController.text),
              ),
            ],
          ),
          // Available Categories
          if (availableCategories.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('الفئات المقترحة:', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: availableCategories.map((category) {
                return ActionChip(
                  label: Text(category),
                  onPressed: () => _addCategory(category),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            )
          ]
        ],
      ),
    );
  }
}