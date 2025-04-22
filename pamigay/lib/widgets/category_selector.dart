import 'package:flutter/material.dart';
import 'package:pamigay/utils/constants.dart';

class CategorySelector extends StatelessWidget {
  final String selectedValue;
  final Function(String) onCategorySelected;
  final List<String> categories;

  const CategorySelector({
    Key? key,
    required this.selectedValue,
    required this.onCategorySelected,
    required this.categories,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: categories.map((category) {
        final bool isSelected = selectedValue == category;
        return Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: InkWell(
            onTap: () => onCategorySelected(category),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? PamigayColors.primary : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
