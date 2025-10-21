import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/diary_category_model.dart';

class DiaryCategoryService {
  DiaryCategoryService._();

  static final DiaryCategoryService instance = DiaryCategoryService._();

  static const _categoriesKey = 'diary_categories';
  static const _assignmentsKey = 'diary_category_assignments';
  static const _recentKey = 'diary_category_recent';
  static const _recentLimit = 5;

  Future<List<DiaryCategory>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_categoriesKey);
    if (raw == null) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    final categories = decoded
        .whereType<Map<String, dynamic>>()
        .map(DiaryCategory.fromMap)
        .toList();

    categories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return categories;
  }

  Future<Map<String, String>> getAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_assignmentsKey);
    if (raw == null) {
      return {};
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(key, value as String),
    );
  }

  Future<String?> getCategoryIdForDiary(String diaryId) async {
    final assignments = await getAssignments();
    return assignments[diaryId];
  }

  Future<DiaryCategory> createCategory(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final categories = await getCategories();
    final newCategory = DiaryCategory(
      id: _generateId(),
      name: name,
      createdAt: DateTime.now(),
    );

    categories.insert(0, newCategory);
    await prefs.setString(
      _categoriesKey,
      jsonEncode(categories.map((category) => category.toMap()).toList()),
    );

    await _addRecentCategory(newCategory.id);
    return newCategory;
  }

  Future<void> renameCategory(String categoryId, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final categories = await getCategories();
    final index = categories.indexWhere((category) => category.id == categoryId);
    if (index == -1) {
      return;
    }

    final updated = categories[index]
        .copyWith(name: newName, updatedAt: DateTime.now());
    categories[index] = updated;

    await prefs.setString(
      _categoriesKey,
      jsonEncode(categories.map((category) => category.toMap()).toList()),
    );
  }

  Future<void> deleteCategory(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final categories = await getCategories();
    categories.removeWhere((category) => category.id == categoryId);

    await prefs.setString(
      _categoriesKey,
      jsonEncode(categories.map((category) => category.toMap()).toList()),
    );

    final assignments = await getAssignments();
    assignments.removeWhere((_, value) => value == categoryId);

    await prefs.setString(
      _assignmentsKey,
      jsonEncode(assignments),
    );
  }

  Future<void> assignDiaryToCategory(
    String diaryId,
    String? categoryId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final assignments = await getAssignments();

    if (categoryId == null) {
      assignments.remove(diaryId);
    } else {
      assignments[diaryId] = categoryId;
      await _addRecentCategory(categoryId);
    }

    await prefs.setString(
      _assignmentsKey,
      jsonEncode(assignments),
    );
  }

  Future<List<String>> getRecentCategoryIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_recentKey);
    if (raw == null) {
      return [];
    }

    return raw;
  }

  Future<void> _addRecentCategory(String categoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = List<String>.from(prefs.getStringList(_recentKey) ?? []);

    current.remove(categoryId);
    current.insert(0, categoryId);

    if (current.length > _recentLimit) {
      current.removeRange(_recentLimit, current.length);
    }

    await prefs.setStringList(_recentKey, current);
  }

  String _generateId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomValue = random.nextInt(1 << 32);
    return 'cat_${timestamp}_$randomValue';
  }
}
