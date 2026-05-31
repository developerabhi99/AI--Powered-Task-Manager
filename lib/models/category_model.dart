import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final int colorValue; // Hex color value
  final int iconCodePoint; // Icon code point for custom icons

  CategoryModel({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconCodePoint,
  });

  Color get color => Color(colorValue);
  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'iconCodePoint': iconCodePoint,
    };
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      colorValue: json['colorValue'] as int,
      iconCodePoint: json['iconCodePoint'] as int,
    );
  }

  // Predefined default categories
  static List<CategoryModel> get defaultCategories => [
    CategoryModel(id: 'work', name: 'Work', colorValue: 0xFF70A1FF, iconCodePoint: 0xe1b1), // business
    CategoryModel(id: 'personal', name: 'Personal', colorValue: 0xFF9B5DE5, iconCodePoint: 0xe491), // person
    CategoryModel(id: 'shopping', name: 'Shopping', colorValue: 0xFFF15BB5, iconCodePoint: 0xe59c), // shopping_cart
    CategoryModel(id: 'health', name: 'Health', colorValue: 0xFF05C46B, iconCodePoint: 0xe243), // favorite
    CategoryModel(id: 'study', name: 'Study', colorValue: 0xFFFF9F43, iconCodePoint: 0xe5b7), // school
  ];
}
